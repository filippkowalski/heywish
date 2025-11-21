package com.wishlists.gifts

import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CLIPBOARD_CHANNEL = "com.wishlists.gifts/clipboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getClipboardImage" -> {
                    getClipboardImage(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getClipboardImage(result: MethodChannel.Result) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        if (!clipboard.hasPrimaryClip()) {
            println("⚠️ No content in clipboard")
            result.success(null)
            return
        }

        val clipData = clipboard.primaryClip
        if (clipData == null || clipData.itemCount == 0) {
            println("⚠️ Empty clipboard")
            result.success(null)
            return
        }

        val item = clipData.getItemAt(0)

        // Check if clipboard has an image URI
        if (item.uri != null) {
            try {
                val uri = item.uri
                println("✅ Found image URI in clipboard: $uri")

                // Read image from URI
                val inputStream = contentResolver.openInputStream(uri)
                val bitmap = BitmapFactory.decodeStream(inputStream)
                inputStream?.close()

                if (bitmap != null) {
                    // Save to temp directory
                    val fileName = "clipboard_${System.currentTimeMillis()}.jpg"
                    val tempFile = File(cacheDir, fileName)

                    FileOutputStream(tempFile).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }

                    println("✅ Clipboard image saved to: ${tempFile.absolutePath}")
                    result.success(tempFile.absolutePath)
                } else {
                    println("❌ Failed to decode image from URI")
                    result.success(null)
                }
            } catch (e: Exception) {
                println("❌ Error reading clipboard image: ${e.message}")
                result.success(null)
            }
        } else {
            println("⚠️ No image URI in clipboard")
            result.success(null)
        }
    }
}
