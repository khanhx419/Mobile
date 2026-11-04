package com.th3.english

import android.app.*
import android.content.*
import android.os.Build
import java.util.Calendar

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val enabled = context.getSharedPreferences("reminder", Context.MODE_PRIVATE).getBoolean("enabled", false)
        if (intent.action == "com.th3.english.PRACTICE" && enabled) notify(context)
        schedule(context)
    }
    companion object {
        fun schedule(context: Context) {
            val prefs = context.getSharedPreferences("reminder", Context.MODE_PRIVATE)
            val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = PendingIntent.getBroadcast(context, 31,
                Intent(context, ReminderReceiver::class.java).setAction("com.th3.english.PRACTICE"),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            alarm.cancel(pending)
            if (!prefs.getBoolean("enabled", false)) return
            val next = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, prefs.getInt("hour", 20))
                set(Calendar.MINUTE, prefs.getInt("minute", 0))
                set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DATE, 1)
            }
            // Inexact daily alarm; no exact-alarm special permission needed.
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
        }
        fun notify(context: Context) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
                NotificationChannel("daily", "Nhắc luyện tiếng Anh", NotificationManager.IMPORTANCE_DEFAULT))
            val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, "daily") else Notification.Builder(context)
            val notification = builder.setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("English Flow · Đến giờ luyện tập")
                .setContentText("Dành vài phút luyện phát âm và giữ chuỗi ngày học của bạn.")
                .setContentIntent(open).setAutoCancel(true).build()
            if (Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED) manager.notify(31, notification)
        }
    }
}
