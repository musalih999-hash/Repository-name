"""NOVA VPN server health agent.

Runs once per invocation; use cron/systemd to repeat it every 5 minutes.
It performs ICMP ping when available, a TCP/UDP reachability probe, and
updates Firestore (default) or MongoDB. A UDP probe confirms local routing,
not a WireGuard handshake; production health should also ingest `wg show`
handshake age from each server exporter.
"""
from __future__ import annotations
import asyncio, json, logging, os, socket, subprocess, time
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from typing import Any

try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("nova-health")

@dataclass
class CheckResult:
    is_active: bool
    ping_ms: int | None
    port_open: bool
    response_ms: int | None
    failure_count: int
    checked_at: str
    error: str | None = None

async def ping_host(host: str, timeout: float) -> int | None:
    """Return ICMP RTT where ping exists; otherwise return TCP DNS latency."""
    started = time.perf_counter()
    try:
        proc = await asyncio.create_subprocess_exec("ping", "-c", "1", "-W", str(max(1, int(timeout))), host, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL)
        code = await asyncio.wait_for(proc.wait(), timeout=timeout + 1)
        return round((time.perf_counter() - started) * 1000) if code == 0 else None
    except (FileNotFoundError, asyncio.TimeoutError):
        try:
            await asyncio.wait_for(asyncio.get_running_loop().getaddrinfo(host, None), timeout=timeout)
            return round((time.perf_counter() - started) * 1000)
        except Exception:
            return None

async def probe_port(host: str, port: int, timeout: float, protocol: str = "udp") -> tuple[bool, int | None]:
    started = time.perf_counter()
    if protocol.lower() == "tcp":
        try:
            reader, writer = await asyncio.wait_for(asyncio.open_connection(host, port), timeout=timeout)
            writer.close(); await writer.wait_closed()
            return True, round((time.perf_counter() - started) * 1000)
        except Exception:
            return False, None
    try:
        loop = asyncio.get_running_loop()
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setblocking(False)
        await asyncio.wait_for(loop.sock_connect(sock, (host, port)), timeout=timeout)
        sock.close()
        return True, round((time.perf_counter() - started) * 1000)
    except Exception:
        return False, None

def read_load(server: dict[str, Any]) -> tuple[int | None, int | None, int | None]:
    """Return (load_percent, active_connections, max_connections).

    Prefer a server-published active_connections/max_connections value. An
    optional metrics_url can expose JSON with those fields.
    """
    active, maximum = server.get("active_connections"), server.get("max_connections")
    if server.get("metrics_url"):
        try:
            import urllib.request
            with urllib.request.urlopen(server["metrics_url"], timeout=2) as response:
                metrics = json.load(response)
            active = metrics.get("active_connections", active)
            maximum = metrics.get("max_connections", maximum)
        except Exception as exc:
            log.warning("metrics failed for %s: %s", server.get("id"), exc)
    if active is None or not maximum:
        return None, active, maximum
    return max(0, min(100, round(active / maximum * 100))), active, maximum

def check_one(server: dict[str, Any], max_failures: int) -> dict[str, Any]:
    host, port = server["endpoint_host"], int(server.get("endpoint_port", os.getenv("WG_DEFAULT_PORT", 51820)))
    timeout = float(os.getenv("PORT_TIMEOUT_SECONDS", "2"))
    async def run() -> CheckResult:
        ping, (open_, response) = await asyncio.gather(ping_host(host, float(os.getenv("PING_TIMEOUT_SECONDS", "2"))), probe_port(host, port, timeout, server.get("probe_protocol", "udp")))
        old_failures = int(server.get("failure_count", 0))
        failures = 0 if open_ and ping is not None else old_failures + 1
        return CheckResult(open_ and ping is not None and failures < max_failures, ping, open_, response, failures, datetime.now(timezone.utc).isoformat(), None if open_ else "endpoint_unreachable")
    result = asyncio.run(run())
    load, active, maximum = read_load(server)
    patch = asdict(result)
    patch.update({"id": server["id"], "load": load, "active_connections": active, "max_connections": maximum, "updated_at": result.checked_at})
    return patch

def load_servers() -> list[dict[str, Any]]:
    path = os.getenv("SERVERS_JSON", "servers.json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data["servers"] if isinstance(data, dict) else data

def write_firestore(rows: list[dict[str, Any]]) -> None:
    import firebase_admin
    from firebase_admin import credentials, firestore
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(os.environ["FIREBASE_SERVICE_ACCOUNT"]))
    db = firestore.client(); collection = os.getenv("FIRESTORE_COLLECTION", "vpn_servers")
    batch = db.batch()
    for row in rows:
        ref = db.collection(collection).document(row["id"]); batch.set(ref, row, merge=True)
    batch.commit()

def write_mongo(rows: list[dict[str, Any]]) -> None:
    from pymongo import MongoClient
    client = MongoClient(os.environ["MONGO_URI"]); coll = client[os.getenv("MONGO_DATABASE", "nova_vpn")][os.getenv("MONGO_COLLECTION", "vpn_servers")]
    for row in rows: coll.update_one({"id": row["id"]}, {"$set": row}, upsert=True)
    client.close()

def rank(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    active = [r for r in rows if r["is_active"]]
    for r in rows: r["tags"] = []
    if active:
        fastest = min(active, key=lambda r: (r.get("ping_ms") or 99999, r.get("load") or 100, r.get("response_ms") or 99999))
        fastest["tags"].append("FASTEST")
        low = sorted(active, key=lambda r: (r.get("ping_ms") or 99999, r.get("response_ms") or 99999))[:3]
        for r in low: r["tags"].append("LOW PING")
    return rows

def main() -> None:
    servers = load_servers(); rows = rank([check_one(s, int(os.getenv("MAX_FAILURES", "2"))) for s in servers])
    target = os.getenv("DATABASE", "firestore").lower()
    if target == "mongo": write_mongo(rows)
    else: write_firestore(rows)
    log.info("checked=%d active=%d fastest=%s", len(rows), sum(r["is_active"] for r in rows), next((r["id"] for r in rows if "FASTEST" in r["tags"]), None))

if __name__ == "__main__": main()
