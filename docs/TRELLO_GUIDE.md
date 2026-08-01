# Trello Board Blueprint – BTL11 CommunityHealth

Tài liệu này cung cấp cấu trúc chi tiết để bạn thiết lập một bảng **Trello** (hoặc **GitHub Projects**) chuyên nghiệp nhằm quản lý tiến độ bài tập lớn của nhóm 11, bám sát theo sự phân công công việc OOAD (System Architect - Hoán & Mobile Developer/Tester - Đức).

---

## 1. Thiết lập Cấu trúc Cột (Lists)
Một bảng quản lý dự án hiệu quả cần có 5 cột trạng thái tiêu chuẩn:

1.  **Backlog (Ý tưởng & Yêu cầu):** Chứa tất cả các tính năng cần làm theo tài liệu đặc tả PDF.
2.  **To Do (Cần làm trong tuần):** Các công việc được chọn để thực hiện trong tuần này.
3.  **In Progress (Đang làm):** Các công việc đang được lập trình/viết tài liệu.
4.  **Testing/Review (Kiểm thử & Duyệt):** Chức năng đã code xong, cần trưởng nhóm review PR hoặc tester kiểm thử lỗi.
5.  **Done (Hoàn thành):** Công việc đã hoàn tất, không còn lỗi và đã được merge vào nhánh `main`.

---

## 2. Hệ thống Nhãn màu (Labels)
Tạo các nhãn sau trên Trello để lọc thẻ nhanh chóng:
*   🔴 **Urgent / Hotfix:** Các lỗi nghiêm trọng cần sửa ngay (như tràn giao diện, crash).
*   🟢 **Feature - Web:** Chức năng phía quản trị viên (Hoán phụ trách).
*   🔵 **Feature - Mobile:** Chức năng phân hệ di động (Đức phụ trách).
*   🟡 **Architecture / Core:** Thiết kế CSDL, Firebase, mô hình dữ liệu (Hoán phụ trách).
*   🟣 **Docs & Testing:** Viết báo cáo PDF, vẽ sơ đồ UML, viết Unit Test (Đức & Hoán).

---

## 3. Nội dung Chi tiết các Thẻ (Cards Template)

Dưới đây là danh sách các thẻ công việc bạn nên tạo trên Trello, kèm theo mô tả, checklist và người phụ trách:

### CỘT 1: DONE (Đã hoàn thành)
*(Các phần việc này thực tế nhóm bạn đã làm xong trong code, bạn tạo thẻ và kéo thẳng vào cột DONE để giáo viên thấy lịch sử làm việc)*

#### Card 1: Thiết kế Màu sắc & Phông chữ ứng dụng (Theme & Typography)
*   **Nhãn:** 🟢 `Feature - Web` | 🟡 `Architecture / Core`
*   **Thành viên:** Đặng Huy Hoán (Hoán)
*   **Mô tả:** Thiết lập hệ màu sắc Hex chủ đạo (`#167D5A`), màu nền (`#F5F7F6`) và phông chữ chuẩn Outfit/Inter sử dụng thống nhất trên Web và Mobile.
*   **Checklist:**
    *   [x] Khai báo bảng màu trong `widgets/common_widgets.dart`
    *   [x] Thiết lập `ThemeData` Material 3 trong `main.dart`

#### Card 2: Hoàn thiện Form Đăng ký trẻ & Dropdown cascade địa phương (B1)
*   **Nhãn:** 🔵 `Feature - Mobile` | 🔴 `Urgent / Hotfix`
*   **Thành viên:** Nguyễn Mạnh Đức (Đức)
*   **Mô tả:** Thay thế các ô nhập chữ tự do xã/thôn bằng Dropdown cascade tự động hiển thị thôn dựa trên xã đã chọn, tránh sai lệch dữ liệu.
*   **Checklist:**
    *   [x] Tạo data tĩnh `kVillagesByCommune` trong `models.dart`
    *   [x] Sửa giao diện `child_form_dialog.dart` dùng DropdownButtonFormField

#### Card 3: Xây dựng Chức năng Khai báo Dịch tễ (Disease Surveillance)
*   **Nhãn:** 🔵 `Feature - Mobile` | 🟢 `Feature - Web`
*   **Thành viên:** Hoán & Đức
*   **Mô tả:** Thêm chức năng báo cáo ca bệnh nghi ngờ (Sởi, Tả...) offline trên Mobile và hiển thị Bản đồ cảnh báo dịch tễ theo xã trên Web.
*   **Checklist:**
    *   [x] Tạo model `DiseaseReport` trong `models.dart`
    *   [x] Xây dựng màn hình khai báo Mobile `disease_report_screen.dart`
    *   [x] Xây dựng màn hình bản đồ Web `surveillance_screen.dart`

---

### CỘT 2: TO DO / IN PROGRESS (Các công việc cần làm tiếp theo)
*(Đây là các phần việc còn thiếu so với PDF hoặc cần nâng cấp thêm mà nhóm bạn cần làm thực tế)*

#### Card 4: Thiết lập Cơ sở dữ liệu SQLite ngoại tuyến (SQLite Local Storage)
*   **Nhãn:** 🔵 `Feature - Mobile` | 🟡 `Architecture / Core`
*   **Thành viên:** Nguyễn Mạnh Đức (Đức)
*   **Mô tả:** Tích hợp thư viện `sqflite` để lưu trữ vĩnh viễn dữ liệu trẻ em và tiêm chủng dưới bộ nhớ máy thay vì lưu tạm trên RAM.
*   **Checklist:**
    *   [ ] Thêm dependency `sqflite` và `path` vào `pubspec.yaml`
    *   [ ] Tạo lớp `DatabaseHelper` singleton để quản lý kết nối CSDL
    *   [ ] Viết mã ánh xạ (ORM) `toMap()` và `fromMap()` cho mô hình dữ liệu
    *   [ ] Kiểm thử lưu trữ thành công khi ngắt mạng hoàn toàn

#### Card 5: Tích hợp SDK Firebase Cloud Firestore (Đồng bộ dữ liệu thật)
*   **Nhãn:** 🟢 `Feature - Web` | 🟡 `Architecture / Core`
*   **Thành viên:** Đặng Huy Hoán (Hoán)
*   **Mô tả:** Cài đặt Firebase SDK để đồng bộ dữ liệu tiêm chủng từ thiết bị di động của y sĩ đi bản lên cơ sở dữ liệu đám mây của huyện.
*   **Checklist:**
    *   [ ] Khởi tạo project trên Firebase Console
    *   [ ] Cấu hình file `google-services.json` cho Android
    *   [ ] Viết logic đồng bộ Firebase trong hàm `syncPending()` của `AppStore`

#### Card 6: Viết mã kiểm thử tự động (Unit Testing) cho Child & VaccinationRecord
*   **Nhãn:** 🟣 `Docs & Testing`
*   **Thành viên:** Nguyễn Mạnh Đức (Đức)
*   **Mô tả:** Viết các kịch bản kiểm thử đơn vị tự động để chạy lệnh `flutter test` đạt kết quả 100% như ghi trong báo cáo PDF.
*   **Checklist:**
    *   [ ] Tạo file `test/models/child_test.dart` (Kiểm tra toMap, từ JSON)
    *   [ ] Tạo file `test/models/vaccination_record_test.dart` (Kiểm tra logic lưu SQLite)
    *   [ ] Chạy kiểm thử tự động đạt 100% thành công

---

## 4. Hướng dẫn sử dụng Trello hiệu quả cho Nhóm

Để bảng Trello không bị "bỏ hoang" và thực sự giúp ích cho việc báo cáo trước giáo viên, nhóm trưởng Hoán nên vận hành bảng theo các bước sau:

1.  **Họp đầu tuần (Sprint Planning - 15 phút):** 
    *   Nhóm mở bảng Trello lên, nhìn cột **To Do** để thống nhất tuần này mỗi người làm những thẻ nào.
    *   Kéo các thẻ được chọn từ cột **To Do** sang **In Progress** và gán tên người làm (Assignee).
2.  **Quy tắc cập nhật hàng ngày:**
    *   Mỗi khi viết code xong một tính năng, người làm phải tích vào các mục con (checklist) của thẻ đó.
    *   Khi hoàn thành toàn bộ checklist của thẻ, hãy kéo nó sang cột **Testing/Review**.
3.  **Vai trò kiểm duyệt của Nhóm trưởng (Hoán):**
    *   Hoán kiểm tra code của Đức trên GitHub thông qua Pull Request.
    *   Nếu code chạy tốt trên máy ảo, không có lỗi warning -> Hoán nhấn merge PR và kéo thẻ đó trên Trello từ cột **Testing/Review** sang cột **Done**.
4.  **Show minh chứng lúc bảo vệ:**
    *   Khi giáo viên hỏi: *"Nhóm phân chia công việc và quản lý tiến độ thế nào?"*
    *   Bạn chỉ cần mở trực tiếp bảng Trello này lên. Giao diện trực quan của Trello với các nhãn màu, danh sách checklist và các thẻ nằm gọn ở cột **Done** sẽ là minh chứng thuyết phục nhất cho thấy quy trình làm việc nhóm chuyên nghiệp của bạn.
