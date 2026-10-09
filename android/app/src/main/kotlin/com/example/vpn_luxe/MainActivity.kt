package com.example.vpn_luxe

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin

class MainActivity : FlutterActivity() {
    private var killSwitchEnabled = true

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        OpenVPNFlutterPlugin.connectWhileGranted(requestCode == 24 && resultCode == RESULT_OK)
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vpn_luxe/wireguard").setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(true)
                "connect" -> { VpnService.prepare(this)?.let { startActivityForResult(it, 1001) }; result.success(null) }
                "disconnect" -> result.success(null)
                "setKillSwitch" -> { killSwitchEnabled = call.argument<Boolean>("enabled") ?: true; result.success(null) }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vpn_luxe/openvpn").setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(true)
                "connect" -> {
                    val config = call.argument<String>("config")
                    require(!config.isNullOrBlank()) { "OpenVPN config is empty" }
                    // Production: pass this exact .ovpn text to the selected OpenVPN Android SDK.
                    // The SDK must own the VpnService, permission flow, and certificate handling.
                    result.success(null)
                }
                "disconnect" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }
}
