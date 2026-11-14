# WorkNote - Ứng Dụng Quản Lý Công Việc Thông Minh Bằng Giọng Nói & Văn Bản Cho iPhone

**WorkNote** là ứng dụng iOS chuẩn Dribbble Mobile UX (SwiftUI) giúp bạn ghi chú, tổ chức và quản lý công việc hàng ngày một cách trực quan bằng văn bản hoặc ghi âm giọng nói. Dự án được cấu hình chuẩn Swift Package Manager tương thích hoàn hảo với bộ công cụ **[xtool](https://github.com/xtool-org/xtool)**, cho phép biên dịch và nạp trực tiếp lên iPhone từ môi trường Windows/Linux mà không bắt buộc dùng Xcode trên macOS.

---

## 🚀 Các Tính Năng Đã Hoàn Thiện Trong Dự Án

1. **Đăng nhập & Đồng bộ đám mây Supabase (0đ Free Tier)**:
   - Tích hợp **Supabase Auth** (Đăng ký / Đăng nhập tài khoản bằng Email & Mật khẩu).
   - Hỗ trợ chế độ dùng thử **Offline Guest** không bắt buộc phải đăng nhập.
   - Đồng bộ dữ liệu công việc và file âm thanh lên Supabase Cloud Database (`tasks` table) & Storage Bucket (`voice-recordings`).

2. **Ghi chú công việc bằng văn bản**:
   - Nhập tiêu đề, nội dung mô tả chi tiết công việc.
   - Thiết lập mức độ ưu tiên: **Cao (Đỏ)**, **Vừa (Cam)**, **Thấp (Xanh)**.
   - Gắn nhãn danh mục: **Công việc**, **Cá nhân**, **Học tập**, **Họp hành**, **Khác**.
   - Thiết lập ngày giờ hạn chót (Deadline).

2. **Ghi âm toàn bộ nội dung công việc (Voice Recording)**:
   - Ghi âm chất lượng cao chuẩn AAC `.m4a` qua `AVAudioRecorder`.
   - Hiển thị sóng âm động thời gian thực (**Real-time Audio Waveform**) khi đang nói.
   - Tự động lưu trữ an toàn trong thư mục tài liệu của ứng dụng.

3. **Bóc băng chuyển giọng nói thành chữ (Speech-to-Text)**:
   - Tích hợp công nghệ nhận diện giọng nói gốc của Apple (`Speech` framework).
   - Tự động nhận diện tiếng Việt (`vi-VN`) khi bạn nói và điền trực tiếp vào tiêu đề/ghi chú mà không cần gõ phím.

4. **Trình phát lại âm thanh thông minh (Audio Player)**:
   - Nghe lại bản ghi âm với thanh trượt điều khiển (Scrubber slider).
   - Hỗ trợ đổi tốc độ nghe: **1.0x**, **1.5x**, **2.0x**.
   - Nút tua nhanh / tua lùi 5 giây.

5. **Theo dõi trạng thái hoàn thành (Done / Undone)**:
   - Phân loại trực quan giữa công việc **Đã làm xong** và **Chưa làm xong**.
   - Bộ lọc tab: **Tất cả**, **Cần làm**, **Đã xong**.
   - Thao tác quẹt (Swipe actions) nhanh trên danh sách để đánh dấu hoàn thành hoặc xoá việc.
   - Bảng thống kê tổng quan (Dashboard) hiển thị: Tổng việc, việc còn lại, việc hoàn thành kèm thanh tỷ lệ tiến độ (%).

6. **Tìm kiếm & Bộ lọc linh hoạt**:
   - Tìm kiếm nhanh theo từ khóa trong tiêu đề, ghi chú hoặc nội dung bóc băng ghi âm.
   - Lọc nhanh theo danh mục dạng thanh trượt ngang.

---

## 📁 Cấu Trúc Dự Án

```
D:\VoiceTodo\
├── Package.swift               # Cấu hình SwiftPM Target & Dependencies
├── xtool.yml                   # Cấu hình BundleID & build của xtool
├── .gitignore                  # Bỏ qua các file cache, build, ipa
├── Support/
│   └── Info.plist              # Quyền truy cập Microphone & Speech Recognition
└── Sources/
    └── VoiceTodo/
        ├── VoiceTodoApp.swift  # Điểm khởi chạy ứng dụng (@main)
        ├── Models/
        │   └── TaskItem.swift  # Model dữ liệu công việc, mức độ ưu tiên, nhãn
        ├── Services/
        │   ├── AudioRecorderService.swift     # Xử lý ghi âm & sóng âm
        │   ├── AudioPlayerService.swift       # Xử lý phát lại & tốc độ nghe
        │   ├── SpeechRecognitionService.swift # Tự động bóc băng giọng nói
        │   └── TaskManager.swift              # Quản lý & lưu trữ danh sách (JSON)
        └── Views/
            ├── MainTaskListView.swift         # Màn hình danh sách chính & Dashboard
            ├── NewTaskSheet.swift             # Màn hình tạo việc (Gõ / Ghi âm)
            ├── TaskDetailView.swift           # Màn hình chi tiết & trình phát audio
            ├── TaskRowView.swift              # Hàng hiển thị từng công việc
            └── Components/
                └── AudioWaveformView.swift    # Component sóng âm & thẻ thống kê
```

---

## 🛠 Hướng Dẫn Sử Dụng `xtool` Trên Windows Để Nạp Vào iPhone

`xtool` cho phép bạn biên dịch ứng dụng SwiftPM thành tệp `.ipa` và nạp vào iPhone cắm qua cổng USB. Trên Windows, `xtool` chạy thông qua **WSL 2 (Ubuntu)**.

### Bước 1: Cài đặt WSL 2 & Ubuntu (Nếu máy chưa có)
Mở PowerShell (Run as Administrator):
```powershell
wsl --install -d Ubuntu
```
Khởi động lại máy nếu được yêu cầu, sau đó mở Ubuntu và đặt username/password.

### Bước 2: Cài đặt công cụ USB Passthrough trên Windows
Để Ubuntu trong WSL nhận diện được iPhone cắm qua dây cáp USB, cài đặt `usbipd-win`:
```powershell
winget install dorssel.usbipd-win
```

### Bước 3: Cài đặt công cụ giao tiếp iOS trên Ubuntu
Trong cửa sổ dòng lệnh Ubuntu WSL:
```bash
sudo apt update
sudo apt install -y usbmuxd libimobiledevice-utils
```

### Bước 4: Cài đặt Swift Toolchain trên Ubuntu
Tải và cài đặt Swift 6.0+ dành cho Ubuntu theo hướng dẫn chính thức từ [swift.org/install/linux](https://swift.org/install/linux). Kiểm tra bằng lệnh:
```bash
swift --version
```

### Bước 5: Tải và cài đặt `xtool`
Trong terminal Ubuntu WSL:
```bash
curl -fL "https://github.com/xtool-org/xtool/releases/latest/download/xtool-$(uname -m).AppImage" -o xtool
chmod +x xtool
sudo mv xtool /usr/local/bin/
```
Kiểm tra cài đặt:
```bash
xtool --help
```

### Bước 6: Cấu hình `xtool` và kết nối Apple Developer Account
Chạy trình hướng dẫn thiết lập của `xtool`:
```bash
xtool setup
```
Làm theo hướng dẫn trên màn hình:
1. Đăng nhập tài khoản Apple ID (hoặc tài khoản Apple Developer miễn phí).
2. Cung cấp đường dẫn đến SDK Darwin/Xcode (tệp `.xip` tải từ Apple Developer trang web).

### Bước 7: Kết nối iPhone và nạp ứng dụng
1. Cắm iPhone vào máy tính qua cáp Lightning / Type-C. Trên iPhone, chọn **Tin cậy máy tính này (Trust this computer)**.
2. Trên PowerShell Windows, chia sẻ kết nối iPhone sang WSL:
   ```powershell
   usbipd list
   usbipd bind --busid <BUSID_CỦA_IPHONE>
   usbipd attach --wsl --busid <BUSID_CỦA_IPHONE>
   ```
3. Trong Ubuntu WSL, truy cập thư mục dự án ở ổ D:
   ```bash
   cd /mnt/d/VoiceTodo
   ```
4. Chạy lệnh phát triển & nạp trực tiếp lên máy:
   ```bash
   xtool dev
   ```
   Ứng dụng sẽ được biên dịch, ký số (codesign) và tự động cài đặt lên màn hình chính iPhone của bạn!

---

## 💡 Gợi Ý Thêm Các Tính Năng Đắt Giá Cho Ứng Dụng

Để nâng tầm ứng dụng từ một to-do list cơ bản thành một trợ lý công việc đắc lực, bạn có thể cân nhắc tích hợp thêm các tính năng sau:

1. **AI Trích Xuất Đầu Việc Tự Động (AI Speech-to-Task / Action Items)**:
   - Khi bạn nói một đoạn dài (ví dụ: *"Chiều mai 3h nhớ gọi cho anh Nam bàn hợp đồng rồi 5h ghé siêu thị mua sữa"*), AI sẽ tự động phân tích và chia nhỏ đoạn ghi âm thành 2-3 công việc cụ thể kèm thời gian tương ứng.
2. **Thông Báo & Nhắc Việc Định Giờ (Local Push Notifications)**:
   - Đặt thông báo đẩy reo chuông báo nhắc việc khi đến hạn chót (Deadline), giúp không bao giờ bị quên việc.
3. **Widget Màn Hình Khoá & Màn Hình Chính (iOS Lock Screen / Home Screen Widget)**:
   - Hiển thị 3 việc cần làm gấp nhất ngay ngoài màn hình khóa iPhone bằng `WidgetKit`.
   - Một nút bấm widget "Ghi âm nhanh" để mở app và ghi âm ngay lập tức.
4. **Phím Tắt Siri (Siri Shortcuts)**:
   - Ra lệnh cho Siri: *"Hey Siri, ghi việc vào VoiceTodo"* để tạo nhanh công việc khi đang lái xe hoặc bận tay.
5. **Đồng Bộ Đám Mây (iCloud Sync / CloudKit)**:
   - Tự động đồng bộ các ghi chú công việc và file ghi âm qua tài khoản iCloud để bạn có thể xem trên iPad hoặc sao lưu khi đổi điện thoại.
6. **Bảo Mật Bằng Face ID / Touch ID**:
   - Đặt khóa vân tay/khuôn mặt cho các ghi chú công việc nhạy cảm liên quan đến tài chính hoặc hợp đồng kinh doanh.
7. **Chia Sẻ Hoặc Xuất Báo Cáo (Export / Share Sheet)**:
   - Xuất danh sách công việc đã làm trong ngày/tuần thành file PDF hoặc gửi qua Zalo/Email cho sếp hoặc đồng nghiệp.
