package com.byteberg.kids_learning

import android.os.Bundle
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity(), InstallStateUpdatedListener {

    private lateinit var appUpdateManager: AppUpdateManager
    private val TAG = "InAppUpdate"
    private val FLEXIBLE_UPDATE_REQUEST_CODE = 100
    private val IMMEDIATE_UPDATE_REQUEST_CODE = 101

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        appUpdateManager = AppUpdateManagerFactory.create(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        flutterEngine.dartExecutor.binaryMessenger.also { messenger ->
            io.flutter.plugin.common.MethodChannel(messenger, "com.byteberg.kids_learning/update")
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "checkForUpdate" -> checkForUpdate(result)
                        "triggerFlexibleUpdate" -> triggerFlexibleUpdate(result)
                        "triggerImmediateUpdate" -> triggerImmediateUpdate(result)
                        "completeFlexibleUpdate" -> completeFlexibleUpdate(result)
                        else -> result.notImplemented()
                    }
                }
        }
    }

    private fun checkForUpdate(result: io.flutter.plugin.common.MethodChannel.Result) {
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo

        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            val updateAvailability = appUpdateInfo.updateAvailability()
            val immediateAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
            val flexibleAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)

            val updateInfo = mapOf(
                "updateAvailable" to (updateAvailability == com.google.android.play.core.install.model.UpdateAvailability.UPDATE_AVAILABLE),
                "immediateAllowed" to immediateAllowed,
                "flexibleAllowed" to flexibleAllowed,
                "availableVersionCode" to appUpdateInfo.availableVersionCode(),
                "stability" to appUpdateInfo.installStatus()
            )

            result.success(updateInfo)
        }

        appUpdateInfoTask.addOnFailureListener { e ->
            Log.e(TAG, "Failed to check for update: ${e.message}")
            result.error("UPDATE_CHECK_FAILED", e.message, null)
        }
    }

    private fun triggerFlexibleUpdate(result: io.flutter.plugin.common.MethodChannel.Result) {
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo

        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.updateAvailability() == com.google.android.play.core.install.model.UpdateAvailability.UPDATE_AVAILABLE &&
                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                
                appUpdateManager.startUpdateFlowForResult(
                    appUpdateInfo,
                    AppUpdateType.FLEXIBLE,
                    this,
                    FLEXIBLE_UPDATE_REQUEST_CODE
                )
                result.success(true)
            } else {
                result.success(false)
            }
        }

        appUpdateInfoTask.addOnFailureListener { e ->
            Log.e(TAG, "Failed to start flexible update: ${e.message}")
            result.error("FLEXIBLE_UPDATE_FAILED", e.message, null)
        }
    }

    private fun triggerImmediateUpdate(result: io.flutter.plugin.common.MethodChannel.Result) {
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo

        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.updateAvailability() == com.google.android.play.core.install.model.UpdateAvailability.UPDATE_AVAILABLE &&
                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                
                appUpdateManager.startUpdateFlowForResult(
                    appUpdateInfo,
                    AppUpdateType.IMMEDIATE,
                    this,
                    IMMEDIATE_UPDATE_REQUEST_CODE
                )
                result.success(true)
            } else {
                result.success(false)
            }
        }

        appUpdateInfoTask.addOnFailureListener { e ->
            Log.e(TAG, "Failed to start immediate update: ${e.message}")
            result.error("IMMEDIATE_UPDATE_FAILED", e.message, null)
        }
    }

    private fun completeFlexibleUpdate(result: io.flutter.plugin.common.MethodChannel.Result) {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                appUpdateManager.completeUpdate()
                result.success(true)
            } else {
                result.success(false)
            }
        }.addOnFailureListener { e ->
            Log.e(TAG, "Failed to complete flexible update: ${e.message}")
            result.error("COMPLETE_UPDATE_FAILED", e.message, null)
        }
    }

    override fun onResume() {
        super.onResume()
        
        // Check if a flexible update download is complete
        appUpdateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                // Flexible update is downloaded, complete it
                appUpdateManager.completeUpdate()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == FLEXIBLE_UPDATE_REQUEST_CODE) {
            when (resultCode) {
                RESULT_OK -> {
                    Log.d(TAG, "Flexible update initiated successfully")
                    appUpdateManager.registerListener(this)
                }
                RESULT_CANCELED -> {
                    Log.d(TAG, "Update flow canceled by user")
                }
                else -> {
                    if (resultCode != -100) { // -100 is ActivityResult.RESULT_IN_PROGRESS
                        Log.e(TAG, "Update flow failed with result code: $resultCode")
                    }
                }
            }
        } else if (requestCode == IMMEDIATE_UPDATE_REQUEST_CODE) {
            when (resultCode) {
                RESULT_OK -> {
                    Log.d(TAG, "Immediate update completed successfully")
                }
                RESULT_CANCELED -> {
                    Log.d(TAG, "Update flow canceled by user")
                }
                else -> {
                    Log.e(TAG, "Immediate update flow failed with result code: $resultCode")
                }
            }
        }
    }

    override fun onStateUpdate(state: InstallState) {
        when (state.installStatus()) {
            InstallStatus.DOWNLOADING -> {
                val bytesDownloaded = state.bytesDownloaded()
                val totalBytes = state.totalBytesToDownload()
                if (totalBytes > 0) {
                    val progress = (bytesDownloaded * 100 / totalBytes).toInt()
                    Log.d(TAG, "Download progress: $progress%")
                }
            }
            InstallStatus.DOWNLOADED -> {
                Log.d(TAG, "Update downloaded successfully")
            }
            InstallStatus.FAILED -> {
                Log.e(TAG, "Update failed with error code: ${state.installErrorCode()}")
                appUpdateManager.unregisterListener(this)
            }
            InstallStatus.INSTALLED -> {
                Log.d(TAG, "Update installed successfully")
                appUpdateManager.unregisterListener(this)
            }
            else -> {
                Log.d(TAG, "Install state updated: ${state.installStatus()}")
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        appUpdateManager.unregisterListener(this)
    }
}
