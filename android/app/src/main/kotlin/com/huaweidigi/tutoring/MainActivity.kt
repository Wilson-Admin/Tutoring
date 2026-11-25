package com.huaweidigi.tutoring

import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        hideSystemNavigationBar()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // 當 App 重新獲得焦點（例如從背景切回、關閉對話框或鍵盤收起）時，確保導覽列維持自動隱藏策略
        if (hasFocus) {
            hideSystemNavigationBar()
        }
    }

    private fun hideSystemNavigationBar() {
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)

        // 設定行為：從螢幕邊緣滑動時暫時顯示透明系統列，約 2~3 秒未操作即自動隱藏
        windowInsetsController.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE

        // 隱藏下方系統導覽列（保留上方狀態列）
        windowInsetsController.hide(WindowInsetsCompat.Type.navigationBars())
    }
}