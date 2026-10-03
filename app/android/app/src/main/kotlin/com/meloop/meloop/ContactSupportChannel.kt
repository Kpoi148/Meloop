package com.meloop.meloop

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Patterns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Opens user-controlled drafts only. No storage, attachments or sending API. */
class ContactSupportChannel(private val activity: Activity) {
    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "meloop/contact_support")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openPrivacyPolicy" -> {
                        val value = call.arguments as? String
                        val uri = value?.let { Uri.parse(it) }
                        if (value == null || uri == null || uri.scheme != "https" || uri.host.isNullOrEmpty()
                            || uri.userInfo != null || value.any { it.isWhitespace() }) {
                            result.error("invalid_policy", "Expected a published HTTPS URL.", null)
                        } else {
                            result.success(open(Intent(Intent.ACTION_VIEW, uri)))
                        }
                    }
                    "openEmailDraft" -> {
                        val recipient = call.argument<String>("recipient")
                        val subject = call.argument<String>("subject")
                        val body = call.argument<String>("body")
                        if (recipient == null || !Patterns.EMAIL_ADDRESS.matcher(recipient).matches()
                            || subject == null || body == null) {
                            result.error("invalid_draft", "Expected email draft fields.", null)
                        } else {
                            val uri = Uri.parse("mailto:${Uri.encode(recipient, "@")}" +
                                "?subject=${Uri.encode(subject)}&body=${Uri.encode(body)}")
                            val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                                putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                                putExtra(Intent.EXTRA_SUBJECT, subject)
                                putExtra(Intent.EXTRA_TEXT, body)
                            }
                            result.success(open(intent))
                        }
                    }
                    "readTechnicalDetails" -> {
                        try {
                            @Suppress("DEPRECATION")
                            val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
                            val version = info.versionName
                                ?: throw IllegalStateException("App version unavailable.")
                            result.success(mapOf(
                                "appVersion" to version,
                                "androidVersion" to Build.VERSION.RELEASE,
                                "deviceModel" to Build.MODEL
                            ))
                        } catch (_: Exception) {
                            result.error("details_unavailable", "Technical details unavailable.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun open(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }
}
