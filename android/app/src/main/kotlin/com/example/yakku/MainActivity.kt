package com.example.yakku

import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORY_CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "channel call: ${call.method}")
                if (call.method != "shareToStory") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val imagePath = call.argument<String>("imagePath")
                val appId = call.argument<String>("appId")
                Log.d(TAG, "args: imagePath=$imagePath appId=$appId")
                if (imagePath.isNullOrEmpty() || appId.isNullOrEmpty()) {
                    result.error("bad_args", "imagePath and appId are required", null)
                    return@setMethodCallHandler
                }
                shareToInstagramStory(imagePath, appId, result)
            }
    }

    /** Opens Instagram's Story composer with the PNG at [imagePath] as background. */
    private fun shareToInstagramStory(
        imagePath: String,
        appId: String,
        result: MethodChannel.Result,
    ) {
        try {
            val file = File(imagePath)
            Log.d(TAG, "file exists=${file.exists()} size=${file.length()} path=${file.absolutePath}")
            if (!file.exists()) {
                result.error("missing_file", "Story image not found: $imagePath", null)
                return
            }
            if (!isInstagramInstalled()) {
                Log.w(TAG, "Instagram package not visible/installed")
                result.success("notInstalled")
                return
            }
            val uri = FileProvider.getUriForFile(this, "$packageName.storyfileprovider", file)
            Log.d(TAG, "content uri=$uri")
            val intent = Intent(STORY_ACTION).apply {
                setDataAndType(uri, "image/png")
                setPackage(INSTAGRAM_PACKAGE)
                putExtra("source_application", appId)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val resolved = intent.resolveActivity(packageManager)
            Log.d(TAG, "resolved activity=$resolved")
            if (resolved == null) {
                result.error(
                    "no_handler",
                    "Instagram has no activity for $STORY_ACTION (image/png)",
                    null,
                )
                return
            }
            // Explicit grant as well: some devices ignore the intent flag alone.
            grantUriPermission(INSTAGRAM_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            Log.d(TAG, "startActivity returned")
            result.success("opened")
        } catch (e: Exception) {
            Log.e(TAG, "shareToInstagramStory failed", e)
            result.error("share_failed", "${e.javaClass.simpleName}: ${e.message}", null)
        }
    }

    private fun isInstagramInstalled(): Boolean =
        try {
            packageManager.getPackageInfo(INSTAGRAM_PACKAGE, PackageManager.PackageInfoFlags.of(0))
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }

    private companion object {
        const val TAG = "YakkuStoryShare"
        const val STORY_CHANNEL = "com.example.yakku/instagram_story"
        const val STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
        const val INSTAGRAM_PACKAGE = "com.instagram.android"
    }
}
