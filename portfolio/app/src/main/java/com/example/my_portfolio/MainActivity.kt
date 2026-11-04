package com.example.my_portfolio

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Button
import android.widget.ImageView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Kích hoạt giao diện tràn viền (Edge-to-Edge) hiện đại
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)

        // Tự động căn lề theo thanh trạng thái (Status Bar) và thanh điều hướng (Navigation Bar)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { view, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        // Khởi tạo các View từ file layout
        val imgAvatar = findViewById<ImageView>(R.id.imgAvatar)
        val btnGitHub = findViewById<Button>(R.id.btnGitHub)
        val btnLinkedIn = findViewById<Button>(R.id.btnLinkedIn)
        val btnFacebook = findViewById<Button>(R.id.btnFacebook)
        val btnEmail = findViewById<Button>(R.id.btnEmail)
        val btnPhone = findViewById<Button>(R.id.btnPhone)

        // Sự kiện khi bấm vào ảnh đại diện (Hiển thị lời chào)
        imgAvatar.setOnClickListener {
            Toast.makeText(this, "Xin chào! Cảm ơn bạn đã ghé thăm Portfolio của tôi!", Toast.LENGTH_SHORT).show()
        }

        // 1. Implicit Intent: Mở trang web GitHub cá nhân
        btnGitHub.setOnClickListener {
            openUrl("https://github.com/khanhx419")
        }

        // 2. Implicit Intent: Mở trang cá nhân LinkedIn
        btnLinkedIn.setOnClickListener {
            openUrl("https://www.linkedin.com/in/l%C3%AA-tu%E1%BA%A5n-khanh-063a39391/")
        }

        // 3. Implicit Intent: Mở trang cá nhân Facebook
        btnFacebook.setOnClickListener {
            openUrl("https://www.facebook.com/khanh.letuan.7528")
        }

        // 4. Implicit Intent: Mở ứng dụng Email gửi thư liên hệ
        btnEmail.setOnClickListener {
            sendEmail(
                recipient = "khanhx419@gmail.com",
                subject = "Liên hệ hợp tác từ Portfolio App"
            )
        }

        // 5. Implicit Intent: Mở màn hình quay số điện thoại
        btnPhone.setOnClickListener {
            dialPhoneNumber("036455xxxx")
        }
    }

    /**
     * Hàm mở một trang web hoặc ứng dụng mạng xã hội bằng Implicit Intent (ACTION_VIEW).
     * Hệ thống Android sẽ tự động tìm trình duyệt hoặc app thích hợp (Chrome, Edge, GitHub app,...)
     * để mở đường dẫn (URL).
     */
    private fun openUrl(url: String) {
        try {
            // Khởi tạo Intent với hành động ACTION_VIEW và truyền dữ liệu Uri của trang web
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            // Bắt ngoại lệ nếu thiết bị không có trình duyệt nào được cài đặt
            Toast.makeText(this, "Không tìm thấy trình duyệt phù hợp để mở liên kết!", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * Hàm gửi email bằng Implicit Intent (ACTION_SENDTO với giao thức mailto:).
     * Chỉ những ứng dụng hỗ trợ gửi email (như Gmail, Outlook, Yahoo Mail,...) mới nhận Intent này.
     */
    private fun sendEmail(recipient: String, subject: String) {
        try {
            val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
                // Scheme 'mailto:' đảm bảo chỉ có các ứng dụng email được khởi chạy
                data = Uri.parse("mailto:$recipient")
                // Truyền tiêu đề email mặc định
                putExtra(Intent.EXTRA_SUBJECT, subject)
            }
            startActivity(emailIntent)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "Không tìm thấy ứng dụng Email nào trên thiết bị!", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * Hàm mở trình quay số điện thoại bằng Implicit Intent (ACTION_DIAL).
     * Lưu ý: ACTION_DIAL chỉ mở bàn phím số có sẵn số điện thoại, không tự động thực hiện cuộc gọi
     * nên KHÔNG cần xin quyền nguy hiểm CALL_PHONE ở runtime.
     */
    private fun dialPhoneNumber(phoneNumber: String) {
        try {
            val dialIntent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$phoneNumber")
            }
            startActivity(dialIntent)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "Không thể mở ứng dụng gọi điện thoại!", Toast.LENGTH_SHORT).show()
        }
    }
}