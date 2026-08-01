# ĐẶC TẢ THIẾT KẾ FIGMA - BTL11 COMMUNITYHEALTH

Tài liệu này đóng vai trò là đặc tả kỹ thuật thiết kế (Figma Design Specification) thay thế cho tệp Figma trực tiếp, cung cấp đầy đủ thông số kỹ thuật hệ thống thiết kế (Design System), kích thước, khoảng cách, mã màu và hướng dẫn chi tiết để dựng lại giao diện trên Figma.

---

## 1. CẤU TRÚC FILE FIGMA (PAGES)

File Figma được tổ chức thành 6 trang (Pages) như sau:

| Tên Trang | Mô Tả Nội Dung |
| :--- | :--- |
| **01. Cover** | Màn hình bìa dự án: Tên BTL11 - CommunityHealth, danh sách thành viên, trạng thái. |
| **02. Design System** | Khai báo Color Styles, Text Styles, Spacing, Border Radius, và Shadows. |
| **03. Components** | Các thành phần dùng chung (Buttons, Inputs, Cards, Badges, Navigation) với Variants. |
| **04. Mobile Screens** | Các khung hình Mobile (Login, Home, Children, Detail, Record, Sync, Settings). |
| **05. Web Screens** | Các khung hình Desktop/Web (Dashboard, Coverage, Plan, Catalog, Login Web). |
| **06. Prototype** | Sơ đồ luồng tương tác (Connections, Transitions, Triggers) giữa các màn hình. |

---

## 2. KÍCH THƯỚC KHUNG HÌNH (FRAME DIMENSIONS)

Các màn hình được thiết kế dựa trên các kích thước chuẩn sau:

*   **Mobile (Phone):** `390 × 844 px` (iPhone 13/14 Pro tương đương)
*   **Tablet:** `768 × 1024 px` (iPad Mini/Air tương đương, hỗ trợ hiển thị 2 cột)
*   **Desktop/Web:** `1440 × 1024 px` (MacBook Pro 14" tương đương, tỷ lệ 16:10)

---

## 3. HỆ THỐNG THIẾT KẾ (DESIGN SYSTEM)

### 3.1. Bảng Màu Thống Nhất (Color Palette)

| Loại Màu | Tên Style | Mã Màu HEX | Sử Dụng |
| :--- | :--- | :--- | :--- |
| **Chủ đạo** | Primary Green | `#167D5A` | Tiêu đề chính, Button chính, trạng thái active. |
| **Thứ cấp** | Light Green | `#EAF7F1` | Nền Badge, Icon nền, Card nổi bật, nút phụ. |
| **Nền tảng** | Background | `#F5F7F6` | Màu nền của toàn bộ màn hình Scaffold. |
| **Bề mặt** | Surface | `#FFFFFF` | Nền các thẻ Card, AppBar, Bottom Navigation. |
| **Chữ chính** | Text Primary | `#1F2937` | Văn bản quan trọng, tiêu đề, nhãn trường nhập liệu. |
| **Chữ phụ** | Text Secondary | `#6B7280` | Phụ đề, chú thích nhỏ, nhãn trạng thái inactive. |
| **Thành công**| Success Green | `#18794E` | Trạng thái "Đã tiêm đủ", "Đã đồng bộ" (nền `#E5F5EC`). |
| **Cảnh báo** | Warning Orange| `#8A5D00` | Trạng thái "Sắp đến lịch", "Chờ đồng bộ" (nền `#FFF3CD`). |
| **Lỗi** | Error Red | `#B42318` | Trạng thái "Trễ lịch", lỗi nhập liệu (nền `#FFE9E7`). |
| **Viền** | Border Color | `#D9E0DC` | Đường viền các Input Field, đường gạch phân cách. |

### 3.2. Typography (Hệ Thống Phông Chữ)
Sử dụng phông chữ **Outfit** hoặc **Inter** làm mặc định (Google Fonts):

*   **Headline Large (Web Title):** Bold, `28 px` (Line-height: `36 px`)
*   **Headline Medium (Mobile Welcome):** Bold, `24 px` (Line-height: `32 px`)
*   **Title Large (Card Title):** Bold, `20 px` (Line-height: `28 px`)
*   **Title Medium (List Title):** Semi-bold, `16 px` (Line-height: `24 px`)
*   **Body Large:** Medium/Regular, `16 px` (Line-height: `24 px`)
*   **Body Medium:** Regular, `14 px` (Line-height: `20 px`)
*   **Caption/Subtext:** Regular, `12 px` (Line-height: `16 px`)
*   **Button Text:** Bold/Semi-bold, `14 px` (Line-height: `20 px`)

### 3.3. Các Quy Tắc Khoảng Cách & Bo Góc (Spacing & Border Radius)
*   **Border Radius (Bo góc):**
    *   `14 px` cho Input Fields, Dropdowns, và Buttons.
    *   `18 px` hoặc `20 px` cho các Card chứa nội dung chính.
    *   `999 px` (Tròn tuyệt đối) cho các Status Badge (Pills), Avatar và Switch.
*   **Spacing Grid:** Sử dụng hệ số của 4 làm Grid cơ bản:
    *   `8 px` hoặc `12 px` cho khoảng cách giữa các phần tử nhỏ trong card.
    *   `14 px` hoặc `16 px` cho khoảng cách giữa các thẻ Card trong danh sách.
    *   `24 px` cho Padding lề của trang Web/Tablet, `16 px` cho Mobile.

---

## 4. CHI TIẾT CÁC COMPONENT FIGMA VÀ VARIANT

Mỗi component được thiết kế dưới dạng Figma Component với các biến thể (Variants):

### 4.1. Button Component
*   **Filled Button:** Nền `#167D5A`, chữ trắng `#FFFFFF`, chiều cao `50 px`, bo góc `14 px`, Text `14 px Bold`.
    *   *Variant (State):* Default, Pressed/Hover (Tối hơn `#105e43`), Disabled (Nền `#E0E0E0`, chữ `#9E9E9E`).
*   **Outlined Button:** Viền `#167D5A` dày `1.5 px`, nền trong suốt, chữ `#167D5A`.
    *   *Variant (State):* Default, Pressed/Hover (Nền `#EAF7F1`), Disabled (Viền `#E0E0E0`, chữ `#9E9E9E`).
*   **Tonal Icon Button (Nút tông nhạt):** Nền `#EAF7F1`, chữ và icon `#167D5A`.

### 4.2. Input Field & Dropdown Component
*   **Text Field:** Nền `#FFFFFF`, viền `#D9E0DC` dày `1 px`, bo góc `14 px`, chiều cao `56 px`, có Label thu nhỏ ở góc trên hoặc Placeholder.
    *   *Variant (State):* Active/Focused (Viền `#167D5A` dày `1.6 px`), Error (Viền `#B42318`).
*   **Dropdown Menu:** Cấu trúc tương tự Text Field nhưng có thêm Icon mũi tên chỉ xuống (`expand_more`) ở bên phải.

### 4.3. Card & List Item
*   **Profile Card:** Nền `#FFFFFF`, không bóng đổ (`elevation: 0`), viền nhẹ hoặc trơn, bo góc `18 px`. Bên trong chứa Avatar nhạt, tiêu đề to, thông tin liên lạc và nút chuyển tiếp.
*   **Urgent Card (Cảnh báo):** Nền hồng nhạt `#FFF0EF`, viền `#FFE9E7` nếu cần, bo góc `18 px`.

### 4.4. Navigation Elements
*   **Bottom Navigation Bar (Mobile):** Chiều cao `80 px`, nền `#FFFFFF`, viền trên nhạt `#EAEAEA`. Chứa 4 biểu tượng (Trang chủ, Trẻ em, Đồng bộ, Cài đặt). Trạng thái Active có vòng tròn nền bo nhẹ bao quanh biểu tượng.
*   **Navigation Rail (Web/Desktop):** Rộng `72 px` (khi thu nhỏ) hoặc `256 px` (khi mở rộng). Nền `#FFFFFF`. Logo và tiêu đề ở trên, các nút chức năng ở giữa, nút đăng xuất ở dưới.

### 4.5. Status Badge (Pills)
*   **Đã tiêm đủ:** Nền `#E5F5EC`, chữ `#18794E` Bold, cỡ chữ `12 px`.
*   **Sắp đến lịch:** Nền `#FFF3CD`, chữ `#8A5D00` Bold, cỡ chữ `12 px`.
*   **Trễ lịch:** Nền `#FFE9E7`, chữ `#B42318` Bold, cỡ chữ `12 px`.

---

## 5. HƯỚNG DẪN DỰNG LẠI TRÊN FIGMA (RECREATING GUIDE)

### Bước 1: Thiết lập trang Design System (02. Design System)
1.  Tạo bảng mã màu: Sử dụng các khối hình vuông `80x80 px`, gán mã HEX ở trên và đặt tên màu thành các Style tương ứng.
2.  Tạo Typography Styles: Tạo các khối Text mẫu, thiết lập font `Outfit` hoặc `Inter` với kích thước và độ dày quy định trong mục 3.2, lưu lại thành Text Styles (ví dụ: `H1 - Web Title`, `H2 - Mobile Title`, vv.).
3.  Tạo thư viện Icon: Import các icon từ thư viện Material Design Icons của Google (dạng SVG vector) bao gồm: `health_and_safety`, `groups`, `verified`, `warning`, `event_available`, `cloud_done`, `cloud_off`, `sync`, `settings`, `vaccines`, `place`, `cake`.

### Bước 2: Dựng các Components (03. Components)
1.  **Button:** Viết dòng chữ "Button", bấm `Shift + A` để tạo Auto Layout. Đặt padding: ngang `24 px`, dọc `14 px`. Đặt nền `#167D5A`, màu chữ trắng, bo góc `14 px`. Tạo Component (`Ctrl + Alt + K`) và thêm các Variants cho trạng thái Hover và Disabled.
2.  **Status Pill:** Viết chữ "Đã tiêm đủ", bấm `Shift + A`. Đặt padding ngang `10 px`, dọc `5 px`, bo góc `999 px`. Thiết lập màu nền `#E5F5EC` và màu chữ `#18794E`.
3.  **Input Field:** Tạo khung Auto Layout chiều cao `56 px`, chiều rộng `366 px`, căn lề trái, padding `16 px`, viền `#D9E0DC`, bo góc `14 px`. Thêm biểu tượng icon bên trái và chữ label bên trong.

### Bước 3: Dựng các màn hình Mobile (04. Mobile Screens)
1.  Tạo Frame kích thước `390 × 844 px` đặt tên là `Mobile_Login`.
    *   Bên trong đặt logo hình tròn chứa icon `health_and_safety` màu xanh ở trên.
    *   Tạo tiêu đề "Đăng nhập CommunityHealth".
    *   Kéo các Component Input Field (Tên đăng nhập, Mật khẩu) và 2 Button chính ("Vào Mobile App" và "Mở Web Admin").
    *   Đặt khoảng cách cách lề trái phải (Padding) là `24 px`.
2.  Tạo Frame `Mobile_Home` (`390 × 844 px`).
    *   Sử dụng Auto Layout hướng dọc (Vertical).
    *   Thêm Header chào hỏi dạng Gradient (`#167D5A` sang `#24A875`) bo góc `24 px` chứa nút tìm kiếm nhanh.
    *   Thêm lưới Grid 2x2 gồm 4 Stat Cards tông màu khác nhau thể hiện số liệu (Tổng trẻ, Trễ lịch, Sắp đến lịch, Chờ đồng bộ).
    *   Thêm danh sách Card "Cần ưu tiên" ở dưới với avatar chữ cái đầu tiên của trẻ.
    *   Đặt Bottom Navigation Bar ở cuối Frame (Fixed position).

### Bước 4: Dựng các màn hình Web Admin (05. Web Screens)
1.  Tạo Frame kích thước `1440 × 1024 px` đặt tên là `Web_Dashboard`.
    *   Kéo Navigation Rail đặt cố định ở mép trái (chiều rộng `256 px`).
    *   Mép phải là vùng nội dung chính. Tạo Header cao `72 px` màu trắng chứa thanh tiêu đề "Tổng quan", chuông thông báo và avatar người dùng.
    *   Bên dưới là khu vực hiển thị lưới Stat Cards (4 cột ngang).
    *   Dưới Stat Cards chia làm 2 cột: cột trái là biểu đồ thanh ngang "Tỷ lệ phủ theo xã", cột phải là danh sách "Cảnh báo trễ lịch".
2.  Tạo Frame `Web_Coverage` (`1440 × 1024 px`).
    *   Vùng nội dung chính chứa bảng số liệu `DataTable`.
    *   Thiết kế bảng số liệu với các hàng phân tách bằng đường kẻ mờ `#EAEAEA`. Cột tỷ lệ phủ chứa một thanh ProgressBar màu xanh lá hoặc đỏ tương ứng.

### Bước 5: Thiết lập Prototype (06. Prototype)
1.  Chọn Button "Vào Mobile App" trên màn hình đăng nhập, kéo dây nối tương tác đến màn hình `Mobile_Home` (Trigger: `On tap`, Transition: `Instant` hoặc `Push`).
2.  Chọn Button "Mở Web Admin" trên màn hình đăng nhập, kéo dây nối tương tác đến màn hình `Web_Dashboard` (Trigger: `On tap`, Transition: `Instant`).
3.  Thiết lập các nút chuyển tiếp ở Bottom Navigation (Mobile) và Navigation Rail (Web) để chuyển giữa các trang tương ứng khi click.
