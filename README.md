# CommunityHealth Flutter UI

Giao diện Flutter mẫu cho bài tập lớn **Sổ tay Tiêm chủng Ngoại tuyến & Giám sát Dịch tễ Vùng sâu**.

## Màn hình đã có

### Mobile App
- Đăng nhập cán bộ y tế.
- Trang chủ với thống kê và trạng thái đồng bộ.
- Tìm kiếm, lọc danh sách trẻ.
- Chi tiết hồ sơ và lịch sử tiêm.
- Ghi nhận mũi tiêm mới với trạng thái `pending`.
- Cảnh báo khi chọn vaccine khác lịch đề xuất.
- Màn hình đồng bộ thủ công.
- Cài đặt cơ bản.

### Web Admin
- Dashboard tỷ lệ phủ vaccine.
- Bảng tỷ lệ theo xã và chi tiết từng vaccine.
- Danh sách trẻ trễ lịch.
- Lập kế hoạch tiêm lưu động và tính số liều dự kiến.
- Danh mục lịch vaccine.

## Cách chạy

Máy cần cài Flutter SDK bản stable hiện hành. Mã giao diện sử dụng Material 3 và các theme-data API hiện tại.

```bash
flutter create community_health_app
```

Sao chép thư mục `lib`, `test`, tệp `pubspec.yaml` và `analysis_options.yaml` của bộ mã nguồn này vào dự án vừa tạo, sau đó chạy:

```bash
flutter pub get
flutter run
```

Chạy Web Admin trên Chrome:

```bash
flutter run -d chrome
```

## Tài khoản demo

- Tên đăng nhập: `healthworker.demo`
- Mật khẩu: `123456`

Trong giao diện đăng nhập, chọn **Mobile App** hoặc **Web Admin** để chuyển phân hệ.

## Lưu ý triển khai thật

Bản hiện tại tập trung vào UI và dữ liệu giả lập trong bộ nhớ. Khi triển khai chức năng thật, thay `AppStore` bằng repository sử dụng:

- `sqflite` cho dữ liệu offline.
- `mobile_scanner` cho QR.
- `connectivity_plus` và `workmanager` cho đồng bộ.
- Firebase Auth, Firestore và FCM cho backend.
