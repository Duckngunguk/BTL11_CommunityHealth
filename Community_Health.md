\# BÀI TẬP LỚN CUỐI KỲ \- BÁO CÁO MẪU HOÀN CHỈNH (QUY TRÌNH OOAD)  
\# BTL11 \- **COMMUNITY HEALTH: SỔ TAY TIÊM CHỦNG NGOẠI TUYẾN VÀ GIÁM SÁT DỊCH BỆNH**

\*\*Học phần:\*\* CSE441 \- Phát triển ứng dụng di động (Flutter)    
\*\*Học kỳ / Năm học:\*\* Học kỳ Hè \- Năm học 2025-2026    
\*\*Giảng viên hướng dẫn:\*\* TS. Kiều Tuấn Dũng  
\*\*Phương pháp tiếp cận:\*\* Phân tích & Thiết kế Hướng đối tượng (Object-Oriented Analysis & Design \- OOAD)    
\*\*Nhóm thực hiện:\*\* Nhóm 11 (Lớp CSE441\_01)  

\---

\#\# 📌 THÔNG TIN ĐỊNH DANH DỰ ÁN

\* \*\*Tên đề tài:\*\* **COMMUNITY HEALTH: SỔ TAY TIÊM CHỦNG NGOẠI TUYẾN VÀ GIÁM SÁT DỊCH BỆNH**  
\* \*\*Mã đề tài:\*\* BTL11  
\* \*\*Link GitHub Repository:\*\* \[**https://github.com/Duckngunguk/BTL11\_CommunityHealth\]**  
\* \*\*Link Video Báo cáo OBS Studio (YouTube Unlisted):\*\* \[https://youtu.be/example\_towerhub\_demo\](https://youtu.be/example\_towerhub\_demo)  
\* \*\*Link File Release APK:\*\* \[https://github.com/tlu-cse441-2026/towerhub\_app/releases/tag/v1.0.0\](https://github.com/tlu-cse441-2026/towerhub\_app/releases/tag/v1.0.0)

\---

\#\# 👨‍💻 BẢNG PHÂN CÔNG NHIỆM VỤ & ĐÓNG GÓP THÀNH VIÊN (OOAD ROLES)

| 1 | 2351170595 | Đặng Huy Hoán | Trưởng nhóm  | (System Architect)	Phân tích yêu cầu, thiết kế kiến trúc hệ thống, xây dựng cơ sở dữ liệu, tích hợp Firebase và chức năng đồng bộ dữ liệu, hoàn thành mô hình dữ liệu, chức năng đăng nhập, đồng bộ dữ liệu trực tuyến và ngoại tuyến |	50%  
| 2 | 2351160511 | Nguyễn Mạnh Đức | Thành viên | (Mobile Developer)  – Tester, Xây dựng giao diện Flutter, phát triển chức năng tìm kiếm trẻ em, quản lý hồ sơ tiêm chủng, kiểm thử ứng dụng, hoàn thiện giao diện, cơ sở dữ liệu SQLite, chức năng tra cứu và quản lý lịch sử tiêm chủng | 50%   
\---

**\#\# 🎯 PHẦN 1: TỔNG QUAN & XÁC ĐỊNH YÊU CẦU (REQUIREMENT ENGINEERING \- OOA)**

\#\#\# 1.1 Khảo sát Hiện trạng & Phát biểu Bài toán

### **Bối cảnh thực tế**

Tại nhiều xã vùng sâu, vùng xa hoặc các trạm y tế địa phương, công tác quản lý thông tin tiêm chủng vẫn được thực hiện bằng sổ giấy hoặc các tệp Excel rời rạc. Điều này gây ra nhiều khó khăn trong quá trình theo dõi, thống kê và quản lý dữ liệu.

Bên cạnh đó, điều kiện cơ sở hạ tầng mạng tại một số khu vực chưa ổn định, dẫn đến việc cán bộ y tế không thể truy cập hệ thống trực tuyến để cập nhật dữ liệu ngay lập tức.

Trong nhiều trường hợp, thông tin về trẻ em, lịch sử tiêm chủng và kế hoạch tiêm vaccine bị thất lạc hoặc không được đồng bộ đầy đủ giữa các đơn vị y tế.

\#\#\# 1.2 Phân tích Tác nhân Hệ thống (Actors Identification)

## **Tác nhân 1: Cán bộ y tế (Health Worker)**

Đây là đối tượng sử dụng chính của hệ thống.

### **Vai trò**

- Quản lý hồ sơ trẻ em.  
- Quản lý lịch sử tiêm chủng.  
- Tra cứu thông tin bằng mã QR.  
- Cập nhật dữ liệu ngoại tuyến.  
- Đồng bộ dữ liệu lên hệ thống trung tâm.

### **Chức năng**

- Đăng nhập hệ thống.  
- Tìm kiếm trẻ em.  
- Quét mã QR.  
- Thêm thông tin tiêm chủng.  
- Theo dõi lịch tiêm tiếp theo.  
- Đồng bộ dữ liệu.

---

## **Tác nhân 2: Phụ huynh (Parent)**

Đây là đối tượng được cung cấp thông tin về quá trình tiêm chủng của trẻ.

### **Vai trò**

- Theo dõi thông tin sức khỏe của trẻ.  
- Kiểm tra lịch tiêm.  
- Nhận thông báo nhắc lịch tiêm.

### **Chức năng**

- Xem thông tin tiêm chủng.  
- Kiểm tra lịch tiêm tiếp theo.  
- Nhận thông báo từ hệ thống.

---

## **Tác nhân 3: Quản trị viên (Administrator)**

Đây là người quản lý toàn bộ hệ thống.

### **Vai trò**

- Quản lý tài khoản người dùng.  
- Quản lý dữ liệu tiêm chủng.  
- Theo dõi số liệu thống kê.

### **Chức năng**

- Thêm, sửa và xóa dữ liệu.  
- Quản lý danh mục vắc-xin.  
- Theo dõi tình trạng đồng bộ dữ liệu.  
- Xuất báo cáo thống kê.

\#\#\# 1.3 Danh sách Use Cases & Sơ đồ Use Case Tổng thể (Use Case Diagram)

usecaseDiagram  
actor HealthWorker as "Cán bộ y tế"   
actor Parent as "Phụ huynh"   
actor Admin as "Quản trị viên"   
rectangle CommunityHealth  {   
usecase UC1 as "Đăng nhập"   
usecase UC2 as "Tìm kiếm trẻ em"   
usecase UC3 as "Quét mã QR"   
usecase UC4 as "Xem hồ sơ"   
usecase UC5 as "Ghi nhận tiêm chủng"   
usecase UC6 as "Xem lịch sử tiêm"   
usecase UC7 as "Đồng bộ dữ liệu"   
usecase UC8 as "Quản lý lịch tiêm"   
usecase UC9 as "Nhận thông báo"   
}  
HealthWorker \--\> UC1   
HealthWorker \--\> UC2   
HealthWorker \--\> UC3   
HealthWorker \--\> UC4   
HealthWorker \--\> UC5   
HealthWorker \--\> UC6 HealthWorker \--\> UC7   
HealthWorker \--\> UC8

Parent \--\> UC4   
Parent \--\> UC6   
Parent \--\> UC9

Admin \--\> UC1   
Admin \--\> UC7   
Admin \--\> UC8   
Admin \--\> UC9 

\#\#\# 1.4 Mô tả Chi tiết Use Case Trọng tâm (Use Case Specification)

# **1.4 Mô tả chi tiết Use Case trọng tâm (Use Case Specification)**

## **Use Case ID: UC05 – Ghi nhận thông tin tiêm chủng ngoại tuyến**

### **Tác nhân chính**

- Cán bộ y tế.

---

### **Mục tiêu**

Cho phép cán bộ y tế cập nhật thông tin tiêm chủng ngay cả khi thiết bị không có kết nối Internet.

---

### **Tiền điều kiện**

- Người dùng đã đăng nhập vào hệ thống.  
- Hồ sơ trẻ em đã tồn tại trong cơ sở dữ liệu.  
- Thiết bị có thể hoạt động ở chế độ ngoại tuyến.

---

### **Hậu điều kiện**

- Dữ liệu được lưu vào SQLite.  
- Trạng thái đồng bộ được đặt thành `pending`.  
- Dữ liệu sẽ tự động đồng bộ với Firebase khi có mạng.

---

### **Luồng xử lý chính**

**Bước 1:** Cán bộ y tế tìm kiếm trẻ em.

**Bước 2:** Hệ thống hiển thị hồ sơ của trẻ.

**Bước 3:** Người dùng lựa chọn loại vắc-xin.

**Bước 4:** Người dùng nhập số lô thuốc, ngày tiêm và các phản ứng sau tiêm.

**Bước 5:** Hệ thống lưu dữ liệu vào SQLite.

**Bước 6:** Hệ thống đánh dấu trạng thái `pending`.

**Bước 7:** Khi thiết bị có kết nối Internet, hệ thống tự động đồng bộ dữ liệu lên Firebase.

## **Biểu đồ tuần tự (Sequence Diagram)**

![][image1]

\#\# 🔬 PHẦN 2: PHÂN TÍCH HƯỚNG ĐỐI TƯỢNG (OBJECT-ORIENTED ANALYSIS \- OOA)

\#\#\# **2.1 Trích xuất thực thể nghiệp vụ (Domain Entity Discovery)**

Dựa trên yêu cầu nghiệp vụ của hệ thống **Community Health – Sổ tay tiêm chủng ngoại tuyến và giám sát dịch bệnh**, nhóm xác định được năm thực thể chính như sau:

### **1\. Child:** Lưu trữ thông tin định danh của trẻ em và phụ huynh.

### **2\. `VaccinationRecord:`** Lưu trữ thông tin về các lần tiêm chủng.

### **3\. `VaccineSchedule:`** Lưu trữ lịch tiêm chủng tiêu chuẩn.

### **4\. `SyncBatch:`** Lưu trữ thông tin đồng bộ dữ liệu giữa thiết bị và máy chủ.

### **5\. `Notification:`** Lưu trữ các thông báo liên quan đến lịch tiêm chủng.

\#\#\# 2.2 Biểu đồ Trạng thái Đối tượng (State Machine Diagram)

Vòng đời và sự chuyển dịch trạng thái của đối tượng \`VaccinationRecord \`:

\`\`\`mermaid  
stateDiagram-v2   
\[\*\] \--\> SearchChild : Tìm kiếm thông tin trẻ em   
SearchChild \--\> ViewProfile : Xem hồ sơ trẻ em   
ViewProfile \--\> AddVaccination : Thêm thông tin tiêm chủng AddVaccination \--\> SaveLocal : Lưu dữ liệu vào SQLite   
SaveLocal \--\> PendingSync : Chờ kết nối mạng   
PendingSync \--\> Synced : Đồng bộ lên Firebase   
PendingSync \--\> SyncFailed : Đồng bộ thất bại   
SyncFailed \--\> PendingSync : Thử lại   
Synced \--\> Notification : Gửi thông báo nhắc lịch   
Notification \--\> \[\*\]  
\`\`\`  
\---

\#\# 📐 PHẦN 3: THIẾT KẾ HƯỚNG ĐỐI TƯỢNG & KIẾN TRÚC (OOD & ARCHITECTURE)

\#\#\# 3.1 Thiết kế Kiến trúc Tầng (Clean Layered Architecture)

\`\`\`text  
\+------------------------------------------------------+  
|                  PRESENTATION LAYER                  |  
|------------------------------------------------------|  
| LoginScreen                                          |  
| HomeScreen                                           |  
| SearchChildScreen                                    |  
| VaccinationScreen                                    |  
\+------------------------------------------------------+  
                         │  
                         ▼  
\+------------------------------------------------------+  
|                BUSINESS LOGIC LAYER                 |  
|------------------------------------------------------|  
| AuthenticationService                                  |   
ChildSearchService                                        |  
| VaccinationService                                      |   
| ScheduleService                                          |   
| SyncService                                                 |   
| NotificationService                                     |   
| QRCodeService                                          |  
\+------------------------------------------------------+  
                         │  
                         ▼  
\+------------------------------------------------------+  
|                 REPOSITORY LAYER                     |  
|------------------------------------------------------|  
| ChildRepository                                      |  
| VaccinationRepository                                |  
| ScheduleRepository                                   |  
\+------------------------------------------------------+  
                         │  
                         ▼  
\+------------------------------------------------------+  
|                    DATA LAYER                        |  
|------------------------------------------------------|  
| SQLite Database                                      |  
| Firebase Firestore                                   |  
| Firebase Cloud Messaging                             |  
\+------------------------------------------------------+

\#\#\# 3.2 Sơ đồ Lớp Thiết kế Chi tiết (Detailed Design Class Diagram)

\`\`\`mermaid  
classDiagram

    class Child {  
        \+String id  
        \+String qrCode  
        \+String fullName  
        \+DateTime dateOfBirth  
        \+String gender  
        \+String motherName  
        \+String motherPhone  
        \+String village  
        \+String commune  
        \+String district  
        \+DateTime lastSyncAt  
        \+toMap()  
        \+fromMap()  
    }

    class VaccinationRecord {  
        \+String id  
        \+String childId  
        \+String vaccineId  
        \+String vaccineName  
        \+int doseNumber  
        \+String lotNumber  
        \+String administeredBy  
        \+String reactions  
        \+DateTime administeredAt  
        \+String syncStatus  
        \+toMap()  
        \+fromMap()  
    }

    class VaccineSchedule {  
        \+String id  
        \+String vaccineName  
        \+int doseNumber  
        \+int ageMonths  
        \+int toleranceDays  
        \+String description  
    }

    class ChildRepository {  
        \+insertChild()  
        \+getAllChildren()  
        \+searchChild()  
        \+insertSampleData()  
    }

    class VaccinationRepository {  
        \+insertVaccination()  
        \+getVaccinationsByChild()  
        \+insertSampleVaccinations()  
    }

    class DatabaseHelper {  
        \+database  
        \+initDatabase()  
        \+createDatabase()  
    }

    DatabaseHelper \--\> ChildRepository  
    DatabaseHelper \--\> VaccinationRepository

    ChildRepository \--\> Child  
    VaccinationRepository \--\> VaccinationRecord

    Child \--\> VaccinationRecord  
    VaccineSchedule \--\> VaccinationRecord  
\`\`\`

\#\#\# 3.3 Biểu đồ Tuần tự (Sequence Diagram)

Luồng tìm kiếm trẻ em và ghi nhận thông tin tiêm chủng :

\`\`\`mermaid  
sequenceDiagram

    autonumber

    actor Worker as 👨‍⚕️ Cán bộ y tế

    participant App as 📱 Mobile App

    participant SQLite as 💾 SQLite

    participant Firebase as 🔥 Firebase

    Worker-\>\>App: Tìm kiếm trẻ em

    App-\>\>SQLite: Truy vấn dữ liệu

    SQLite--\>\>App: Trả về kết quả

    Worker-\>\>App: Nhập thông tin tiêm chủng

    App-\>\>SQLite: Lưu dữ liệu ngoại tuyến

    App-\>\>Firebase: Đồng bộ dữ liệu

    Firebase--\>\>App: Xác nhận thành công

    App--\>\>Worker: Hiển thị kết quả  
\`\`\`

\#\#\# 3.4 Mẫu Thiết kế Áp dụng (Design Patterns Applied)

| Design Pattern | Nơi áp dụng trong Mã nguồn | Mục đích Kỹ thuật |  
|:---|:---|:---|  
| \*\*Repository Pattern\*\* | \`lib/repositories/child\_repository.dart \` | Quản lý dữ liệu trẻ em.  
| \*\*Repository Pattern \*\* | \`lib/repositories/vaccination\_repository.dart \` | Quản lý dữ liệu tiêm chủng.  
| \*\*Singleton Pattern\*\* | \`DatabaseHelper.instance \` | Duy trì một kết nối cơ sở dữ liệu duy nhất.  
| \*\*Factory Pattern\*\* | \`Child.fromMap() \` | Chuyển đổi dữ liệu từ SQLite sang đối tượng.  
| \*\*Observer Pattern\*\* | \`Firebase Cloud Messaging (FCM)  \` | Theo dõi sự thay đổi và gửi thông báo.  
| \*\*MVC Pattern\*\* | \`Model – Repository – Screen \` | Phân chia giao diện, dữ liệu và xử lý nghiệp vụ.

\---

\#\# 🗄️ PHẦN 4: THIẾT KẾ CƠ SỞ DỮ LIỆU & GIAO DIỆN (DATABASE & UI DESIGN)

\#\#\# 4.1 Ánh xạ Đối tượng \- Cơ sở Dữ liệu (ORM / Document Data Mapping)

\`\`\`dart  
// lib/models/VaccinationRecord.dart \- Đóng gói Đảo ngược JSON Mapping  
Map\<String, dynamic\> toMap() {  
  return {  
    'id': id,  
    'childId': childId,  
    'vaccineId': vaccineId,  
    'vaccineName': vaccineName,  
    'doseNumber': doseNumber,  
    'lotNumber': lotNumber,  
    'administeredBy': administeredBy,  
    'reactions': reactions,  
    'administeredAt': administeredAt.toIso8601String(),  
    'syncStatus': syncStatus,  
  };  
}  
\`\`\`

\#\#\# 4.2 Thiết kế Giao diện Luồng Người dùng (UI Navigation Flow)

\---

\#\# 💻 PHẦN 5: CÀI ĐẶT MÃ NGUỒN & QUẢN LÝ TRẠNG THÁI (IMPLEMENTATION)

\#\#\# 5.1 Hiện thực hóa Lớp Thực thể Đối tượng (\`VaccinationRecord \` Class)

\`\`\`dart  
// lib/models/VaccinationRecord.dart  
class VaccinationRecord {   
final String id;   
final String childId;   
final String vaccineName;   
final int doseNumber;   
final String syncStatus; 

const VaccinationRecord({   
required this.id,   
required this.childId,   
required this.vaccineName,   
required this.doseNumber,   
required this.syncStatus,   
}); 

bool get isSynced \=\> syncStatus \== "success"; } 

\#\#\# 5.2 Quản lý Trạng thái Bất đồng bộ Đối tượng (\`VaccinationNotifier \`)

\`\`\`dart  
// lib/state/VaccinationNotifier.dart  
class VaccinationNotifier   
extends ChangeNotifier {   
List\<VaccinationRecord\> records \= \[\];   
Future\<void\> loadData() async {   
records \=   
await VaccinationRepository()   
.getVaccinations();   
notifyListeners();   
} 

Future\<void\> addRecord(   
VaccinationRecord record,   
) async {   
await VaccinationRepository()   
.insertVaccination(record); 

await loadData();   
}   
} 

\#\# 🧪 PHẦN 6: KIỂM THỬ ĐỐI TƯỢNG & ĐẢM BẢO CHẤT LƯỢNG (TESTING & QA)

\#\#\# 6.1 Kiểm thử Đơn vị Lớp Đối tượng (Class-Level Unit Testing)  
Kiểm thử lớp Child   
\`\`\`bash  
flutter test test/models/child\_test.dart  
\`\`\`  
\`\`\`text  
00:03 \+3: All tests passed\!   
\- Test 1: Kiểm tra chuyển đổi dữ liệu bằng hàm toMap() (PASSED)   
\- Test 2: Kiểm tra khởi tạo đối tượng bằng hàm fromMap() (PASSED)   
\- Test 3: Kiểm tra tính toàn vẹn của dữ liệu sau khi chuyển đổi (PASSED)   
\`\`\`  
Kiểm thử lớp VaccinationRecord  
\`\`\`bash  
flutter test test/models/vaccination\_record\_test.dart   
\`\`\`  
\`\`\`text  
00:02 \+3: All tests passed\!  
\- Test 1: Kiểm tra việc lưu dữ liệu vào SQLite (PASSED)  
\- Test 2: Kiểm tra quá trình đồng bộ dữ liệu với Firebase (PASSED)  
\- Test 3: Kiểm tra trạng thái đồng bộ (PASSED)  
\`\`\`

\#\#\# 6.2 Kiểm tra Tuân thủ Chuẩn Mã nguồn (\`dart analyze\`)  
\`\`\`text  
Analyzing btl11\_communityhealth...  
No issues found\!  
(0 errors, 0 warnings, 0 lints)

\`\`\`

\#\#\# 6.3 Ma trận Kiểm thử Thủ công (Manual Test Matrix)

| STT | Kịch bản Test | Dữ liệu đầu vào | Kết quả Thực tế | Trạng thái |  
|:---:|:---|:---|:---|:---:|  
| 1 | Tìm kiếm trẻ em | Nguyễn Văn An  | Hiển thị thông tin trẻ em | PASS |  
| 2 | Đồng bộ dữ liệu | Bật kết nối Internet | Dữ liệu được gửi lên Firebase | PASS |

\---

\#\# 📜 PHẦN 7: MINH CHỨNG PHÁT TRIỂN & TRUNG THỰC HỌC THUẬT (GIT LOG)

\#\#\# 7.1 Thống kê Lịch sử Commits (\`git log \--oneline\`)  
\`\`\`text  
\* 7f8a9b0 (HEAD \-\> main, origin/main) feat(sos): implement geospatial floor SOS dispatcher  
\* 3e2d1c0 feat(market): add hyperlocal group-buying realtime progress bar  
\* 5b6c7d8 fix(ui): fix RenderFlex overflow on financial dashboard small screen  
\* 1a2b3c4 feat(auth): integrate Zalo SDK 1-Click Login flow  
\* 9f8e7d6 test(unit): add unit tests for SLA timer and profile entity  
\`\`\`

\---

\#\# 📝 PHẦN 8: TỔNG KẾT & HƯỚNG PHÁT TRIỂN (CONCLUSION)

\#\#\# 8.1 Kết quả Đạt được theo Quy trình OOAD  
1\. \*\*Phân tích OOAD chuẩn mực:\*\* Trích xuất đúng 5 thực thể cốt lõi, xây dựng Use Case & Sequence Diagrams hoàn chỉnh.  
2\. \*\*Kiến trúc Clean Layered:\*\* Đóng gói đối tượng sạch sẽ, phân tách Presentation, Domain và Data.  
3\. \*\*Chất lượng mã nguồn:\*\* 0 Lints warnings, pass 100% Unit Tests tự động.

\#\#\# 8.2 Hạn chế & Định hướng Mở rộng  
\* \*Hạn chế:\* Chưa tích hợp cổng thanh toán trực tiếp VNPay/MoMo cho hóa đơn nước/điện.  
\* \*Hướng phát triển:\* Mở rộng Lớp Đối tượng \`VehiclePassport\` để tích hợp AI Camera nhận diện biển số xe tự động ra vào hầm.

\---  
\*\*Đại diện Nhóm 11 xác nhận:\*\*    
\*(Ký và ghi rõ họ tên)\*    
\*\*Đặng Huy Hoán (Trưởng nhóm) \- \*\*Nguyễn Mạnh Đức\*\*

[image1]: <data:image/png;base64,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>