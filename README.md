## 📌 I. Yêu cầu trước khi chạy (Prerequisites)

### Backend (Python)

- Anaconda / Miniconda
- Python 3.10 (môi trường `f5tts`)
- Đã cài dependencies cho server TTS
- Có `ref_audio.wav` và `ref_text.txt` đặt cùng thư mục `server.py`

### Frontend (Flutter)

- Flutter SDK (stable)
- Android Studio + Android SDK + Emulator
- Đã chấp nhận Android licenses:
  ```bash
  flutter doctor --android-licenses
  ```

### Ngrok

- Đã cài ngrok
- Mở ngrok
- Chạy: ngrok http 5000
- 📌 Lấy URL dạng: https://xxxx.ngrok-free.dev

---

## 🔁 II. Chạy lại toàn bộ hệ thống (DEV MODE)

### 🧩 A. Backend – TTS Server

```bash
conda activate f5tts
cd path/to/Cuoi_ki
python server.py
```

Giữ terminal này luôn mở.

---

### 🧩 B. Public API bằng Ngrok

Mở terminal của ngrok:

```bash
ngrok http 5000
```

Sao chép URL dạng:

```
https://xxxx.ngrok-free.dev
```

---

### 🧩 C. Frontend – Flutter App

```bash
cd tts_mobile_app
flutter clean
flutter pub get
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

Ứng dụng sẽ gọi API TTS.
