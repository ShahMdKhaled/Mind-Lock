package com.example.mindlock

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class MindLockDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d("MindLock", "Device Admin Enabled")
        Toast.makeText(context, "MindLock Uninstall Protection Enabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d("MindLock", "Device Admin Disabled")
        Toast.makeText(context, "MindLock Uninstall Protection Disabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        // Here we could add logic to warn the user or check if the 1-month lock is active
        return "Are you sure you want to disable MindLock protection? Your focus progress will be lost."
    }
}
