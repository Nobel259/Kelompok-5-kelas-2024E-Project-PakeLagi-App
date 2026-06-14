# PakeLagi App 

Aplikasi mobile untuk membeli dan menjual produk fashion bekas (preloved), dibangun dengan flutter.

## Fitur

- **Landing Page**: Layar masuk yang menakjubkan dengan gambar latar berkualitas tinggi, gradien khusus, dan tombol interaktif.
- **Home Page**: Menampilkan antarmuka belanja modern:
  - Eksplorasi produk multi-kategori.
  - Daftar produk yang dapat digulir secara horizontal.
  - Bilah navigasi mengambang kustom.
  - Integrasi dengan Google Fonts (Playfair Display & Inter).

## Prasyarat

Sebelum memulai, pastikan Anda telah memenuhi persyaratan berikut:
- Flutter SDK terpasang (saluran Stabil).
- Emulator Android, Simulator iOS, atau perangkat fisik.

## Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <your-repository-url>
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Assets Setup**
   Ensure you have the following folder structure and images:
   ```text
   assets/
     └── images/
         └── landing_bg.jpeg  <-- Your landing page background
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

- `lib/landing_page.dart`: Berisi layar masuk awal.
- `lib/main.dart`: Titik masuk aplikasi dan implementasi halaman beranda.
- `assets/`: Direktori untuk gambar dan ikon.
