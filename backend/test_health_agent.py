import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from health_agent import rank

def test_rank_marks_fastest_and_low_ping():
    rows = rank([
        {"id":"slow", "is_active":True, "ping_ms":80, "response_ms":80, "load":10},
        {"id":"fast", "is_active":True, "ping_ms":20, "response_ms":10, "load":90},
        {"id":"down", "is_active":False, "ping_ms":5, "response_ms":5, "load":1},
    ])
    assert "FASTEST" in next(r for r in rows if r["id"] == "fast")["tags"]
    assert "FASTEST" not in next(r for r in rows if r["id"] == "down")["tags"]
    assert all("LOW PING" in r["tags"] for r in rows[:2])
