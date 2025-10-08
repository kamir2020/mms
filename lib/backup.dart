/*
package com.example.app_mms

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_mms/usb"
    private val ACTION_USB_PERMISSION = "com.example.app_mms.USB_PERMISSION"
    private var permissionResultCallback: MethodChannel.Result? = null
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestUsbPermission" -> {
                    permissionResultCallback = result
                    requestUsbPermission()
                }

                "simulateSerialResponse" -> {
                    // For testing purposes
                    val simulatedData = "SN=LC22C103391"
                    handleSerialData(simulatedData)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestUsbPermission() {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList = usbManager.deviceList.values

        if (deviceList.isEmpty()) {
            println("❌ No USB devices connected")
            permissionResultCallback?.error("NO_DEVICE", "No USB devices found", null)
            return
        }

        for (device in deviceList) {
            println("🔍 Device found: ${device.deviceName}, VID=${device.vendorId}, PID=${device.productId}")
            if (device.vendorId == 4292 && device.productId == 60000) { // CP2102N
                if (usbManager.hasPermission(device)) {
                    println("✅ Already has permission for ${device.deviceName}")
                    permissionResultCallback?.success(true)
                    return
                }

                val permissionIntent = PendingIntent.getBroadcast(
                    this,
                    0,
                    Intent(ACTION_USB_PERMISSION),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )

                println("🔐 Requesting permission for ${device.deviceName}")
                usbManager.requestPermission(device, permissionIntent)
                return
            }
        }

        println("❌ CP2102N device not found (VID: 4292, PID: 60000)")
        permissionResultCallback?.error("DEVICE_NOT_FOUND", "CP2102N not found", null)
    }

    // This can be called when you receive serial data from the USB input stream
    private fun handleSerialData(response: String) {
        val sondeId = extractSondeId(response)
        if (sondeId != null) {
            println("✅ Extracted Sonde ID: $sondeId")

            // Send it to Flutter on the main thread
            Handler(Looper.getMainLooper()).post {
                methodChannel.invokeMethod("onSondeIdReceived", sondeId)
            }
        } else {
            println("❌ Sonde ID not found in response: $response")
        }
    }

    // Regex extractor for Sonde ID (e.g., SN=LC22C103391)
    private fun extractSondeId(response: String): String? {
        val regex = Regex("SN=(LC[0-9A-Za-z]+)")
        val match = regex.find(response)
        return match?.groupValues?.get(1)
    }

    companion object {
        var flutterCallback: MethodChannel.Result? = null

        fun onPermissionResult(granted: Boolean) {
            flutterCallback?.apply {
                if (granted) success(true)
                else error("PERMISSION_DENIED", "User denied USB permission", null)
            }
            flutterCallback = null
        }
    }
}

 */