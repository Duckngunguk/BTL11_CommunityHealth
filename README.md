# CommunityHealth - Sổ Tay Tiêm Chủng & Giám Sát Dịch Tễ Ngoại Tuyến

Hệ thống quản lý tiêm chủng ngoại tuyến (Offline-First) và giám sát dịch tễ vùng cao, phục vụ Cán bộ Y tế xã/bản, Phụ huynh học sinh và Quản trị viên. Dự án được phát triển bằng Flutter với ứng dụng Android và cổng quản trị Web.

---

## 🚀 Kiến Trúc Hệ Thống (Architecture)

Hệ thống được phát triển theo mô hình **Offline-First** nhằm thích ứng tốt nhất với môi trường vùng sâu, vùng xa có kết nối internet không ổn định:
1. **Local Database (SQLite Helper)**: Lưu trữ cục bộ hồ sơ trẻ, lịch sử tiêm chủng, cấp phát thuốc, báo dịch và nhật ký hệ thống ngoại tuyến trên Android.
2. **Cloud Database (Firebase Firestore)**: Đồng bộ hai chiều bất đồng bộ dữ liệu tiêm chủng, duyệt phê duyệt tài khoản cán bộ đăng ký mới từ mobile, lưu trữ audit log hoạt động.
3. **Local Cache Encryption (Secure Storage)**: Lưu trữ bảo mật các danh mục vắc-xin, phác đồ điều trị và kế hoạch tiêm lưu động bền vững trên thiết bị.

---

## ✨ Các Chức Năng Chính

### 📱 1. Ứng Dụng Di Động (Mobile App)
* **Đăng ký / Đăng nhập phân quyền**: Dành cho Cán bộ Y tế và Phụ huynh. Hỗ trợ quy trình phê duyệt tài khoản từ Admin.
* **Quét mã QR Sổ tiêm**: Nhận diện thông tin trẻ nhanh chóng trên thực địa để hỗ trợ điền phiếu báo dịch.
* **Báo dịch ngoại tuyến**: Tạo báo cáo ca dịch nghi ngờ kèm GPS thiết bị (giả lập định vị thực địa), triệu chứng và hình ảnh.
* **Đồng bộ thủ công & tự động**: Bảng điều khiển đồng bộ và hiển thị banner trạng thái số bản ghi ngoại tuyến chờ đồng bộ.
* **Quản lý danh sách Phụ huynh**: Giao diện hiển thị danh sách phụ huynh thôn bản làm chủ đạo để thuận tiện liên hệ.

### 💻 2. Cổng Quản Trị (Web Admin)
* **Dashboard Tổng quan**: Thống kê số lượng trẻ đã tiêm, trễ lịch, kế hoạch phát lệnh, tỷ lệ bao phủ theo biểu đồ.
* **Bản đồ dịch tễ & Tỷ lệ bao phủ**:
  * Bản đồ hiển thị tình hình dịch bệnh và mật độ bao phủ vắc-xin của các xã.
  * Tích hợp thống kê biểu đồ cột tỷ lệ phủ vắc-xin chi tiết.
* **Lập kế hoạch tiêm lưu động**: Tự động tính số liều dự phóng dựa trên số trẻ trễ lịch tại xã mục tiêu, phân công cán bộ y tế và lưu kế hoạch lâu dài.
* **Cấu hình & Cài đặt hệ thống (Web-style)**:
  * Quản lý thông tin hành chính cơ sở y tế.
  * Cấu hình tần suất đồng bộ đám mây và nút sao lưu CSDL SQLite (Backup), dọn dẹp bộ nhớ đệm (Cache).
  * Slider thay đổi chỉ tiêu bao phủ vắc-xin mục tiêu toàn huyện (tự động cập nhật vùng cảnh báo đỏ trên bản đồ).
* **Xuất báo cáo**: Hỗ trợ xuất dữ liệu ra file Excel/CSV và tạo báo cáo PDF hoàn chỉnh.
* **Nhật ký hệ thống**: Lưu vết toàn bộ hoạt động đăng nhập, tạo kế hoạch, phê duyệt tài khoản y tế.

---

## 🛠️ Hướng Dẫn Cài Đặt & Chạy Dự Án

### Yêu cầu hệ thống:
* **Flutter SDK**: Bản Stable (v3.22.0 trở lên).
* **Lưu trữ**: SQLite trên Android; Web dùng dữ liệu fallback/Firestore.

### Các lệnh cài đặt:
1. Tải các gói phụ thuộc (Dependencies):
   ```powershell
   flutter pub get
   ```

2. Khởi chạy phân hệ di động (Mobile App):
   ```powershell
   flutter run -d <android-device-id>
   ```

3. Khởi chạy cổng quản trị Admin (Web Admin):
   ```powershell
   flutter run -d chrome
   # Hoặc dùng entry point Admin độc lập:
   flutter run -t lib/main_admin.dart -d chrome
   ```

*(Gợi ý: Sử dụng file script `run_3_roles.bat` trong thư mục gốc của dự án để khởi chạy nhanh cả 3 phân hệ kiểm thử).*

---

## 🔑 Tài Khoản Kiểm Thử (Demo Accounts)

Hệ thống đã được nạp sẵn dữ liệu demo (SQLite trên Android, dữ liệu fallback trên Web):

| Vai trò | Tên đăng nhập | Mật khẩu | Phân hệ tương ứng |
| :--- | :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin.demo` | `123456` | Web Admin (`main.dart` hoặc `main_admin.dart`) |
| **Cán bộ Y tế xã** | `healthworker.demo` | `123456` | Mobile App (`main.dart`) |
| **Phụ huynh** | `parent.demo` | `123456` | Mobile App (`main.dart`) |
| **Tài khoản chờ duyệt** | `healthworker.nam` | `123456` | Sử dụng để test tính năng phê duyệt của Admin |
