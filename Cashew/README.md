<h1 align="center" style="font-size:28px; line-height:1"><b>Cashew - Nhóm 11</b></h1>
<p align="center"><b>Dự án Quản lý Chi tiêu Cá nhân - Phiên bản Tùy biến Nhóm 11 (Tích hợp VNĐ)</b></p>

---

## 📌 Báo cáo thực hiện - Nhóm 11

### 1. Thông tin dự án
- **Đề tài**: Triển khai & Tùy biến ứng dụng Quản lý Chi tiêu từ mã nguồn mở Cashew
- **Đơn vị thực hiện**: **Nhóm 11**
- **Repository**: [https://github.com/LoudlyDawn2108/Cashew](https://github.com/LoudlyDawn2108/Cashew)

---

### 2. Danh mục các file mã nguồn đã chỉnh sửa (Chi tiết)

| File mã nguồn | Nội dung chỉnh sửa | Mục đích |
| :--- | :--- | :--- |
| [`budget/lib/struct/languageMap.dart`](budget/lib/struct/languageMap.dart) | Đổi `globalAppName = "Cashew - Nhóm 11"`, cấu hình `supportedLocales` ưu tiên `vi`, `startLocale = Locale("vi")`. | Cá nhân hóa tên ứng dụng và hiển thị Tiếng Việt mặc định. |
| [`budget/lib/main.dart`](budget/lib/main.dart) | Cập nhật `title: 'Cashew - Nhóm 11'`, loại bỏ wrapper `DevicePreview` gây xung đột web. | Đồng bộ tiêu đề ứng dụng và tối ưu chạy toàn màn hình trên Web. |
| [`budget/lib/struct/defaultPreferences.dart`](budget/lib/struct/defaultPreferences.dart) | Đặt giá trị mặc định `"username": "Nhóm 11"`, `"locale": "vi"`, `"hasOnboarded": true`. | Hiển thị lời chào "Xin chào Nhóm 11" ngay khi mở app lần đầu. |
| [`budget/lib/pages/aboutPage.dart`](budget/lib/pages/aboutPage.dart) | Thêm khối UI nổi bật: **"Dự án Quản lý Chi tiêu - Nhóm 11"**, **"Thực hiện bởi: NHÓM 11"**, **"Ứng dụng Quản lý Chi tiêu Cá nhân (VNĐ)"**. | Minh chứng bản quyền thực hiện của Nhóm 11 trong trang Giới thiệu. |
| [`budget/lib/functions.dart`](budget/lib/functions.dart) | Đưa `'vnd'` lên đầu danh sách `popularCurrencies`, sửa `getDevicesDefaultCurrencyCode()` trả về `'vnd'`. | Tích hợp và ưu tiên đơn vị tiền tệ Việt Nam Đồng (VNĐ - ₫). |
| [`budget/lib/database/initializeDefaultDatabase.dart`](budget/lib/database/initializeDefaultDatabase.dart) | Đặt tài khoản ngân hàng mặc định ban đầu (`defaultWallet`) dùng `currency: 'vnd'` và `decimals: 0`. | Tự động tạo ví tiền tệ VNĐ không có số thập phân lẻ (`₫0` thay vì `₫0.00`). |
| [`budget/lib/pages/addWalletPage.dart`](budget/lib/pages/addWalletPage.dart) | Thiết lập `selectedDecimals = 0` khi người dùng chọn loại tiền tệ là `vnd`. | Đảm bảo các ví tiền tệ VNĐ mới tạo luôn chuẩn format 0 số thập phân. |
| [`budget/web/index.html`](budget/web/index.html) | Đổi thẻ `<title>` thành `Cashew - Nhóm 11`, cập nhật thẻ meta `apple-mobile-web-app-title`. | Hiển thị tên nhóm trên tab trình duyệt web. |
| [`budget/web/manifest.json`](budget/web/manifest.json) | Đổi `"name"` và `"short_name"` thành `Cashew - Nhóm 11`. | Định danh PWA Web của nhóm. |
| [`budget/pubspec.yaml`](budget/pubspec.yaml) | Nâng cấp `carousel_slider: ^5.0.0`, `home_widget: ^0.7.0`, `intl: ^0.19.0`, gỡ `device_preview`. | Tương thích môi trường Flutter 3.24.5 / Web. |
| [`packages/.../pubspec.yaml`](budget/packages/) | Nới rộng SDK constraint `<4.0.0` cho `sliding_sheet` và `implicitly_animated_reorderable_list`. | Khắc phục cảnh báo và lỗi biên dịch thư viện nội bộ. |
| [`serve.py`](serve.py) | Tạo script máy chủ Python HTTP tùy chỉnh kèm header `Cross-Origin-Opener-Policy` và `Cross-Origin-Embedder-Policy`. | Phục vụ ứng dụng Web mượt mà, hỗ trợ WebAssembly và CanvasKit. |

---

### 3. Hướng dẫn khởi chạy ứng dụng

#### 👉 Cách 1: Chạy trực tiếp chế độ Debug / Development (Hỗ trợ Hot Restart)
```bash
cd budget
# Cài đặt thư viện phụ thuộc
flutter pub get

# Khởi chạy trên trình duyệt Google Chrome
flutter run -d chrome
# Hoặc cố định cổng:
flutter run -d chrome --web-port=8080
```
> Khi đang chạy, bạn có thể nhấn phím `r` trong terminal để Hot Restart ứng dụng ngay lập tức!

#### 👉 Cách 2: Chạy bản Release tối ưu hóa tốc độ cao (Khuyên dùng)
```bash
# 1. Build bản Web Release
cd budget
flutter build web --release

# 2. Khởi chạy máy chủ HTTP
cd ..
python3 serve.py 8088

# 3. Mở trình duyệt truy cập:
# http://localhost:8088/
```

---

### 4. Minh chứng kết quả kiểm thử (Screenshots)
Toàn bộ ảnh chụp màn hình kiểm thử đầy đủ các chức năng được lưu tại thư mục [`screenshots/`](screenshots/):

| STT | Chức năng kiểm thử | File ảnh minh chứng |
| :---: | :--- | :--- |
| 1 | **Trang chủ & Nhận diện Nhóm 11** | [`screenshots/01_home_screen.png`](screenshots/01_home_screen.png) |
| 2 | **Thêm chi tiêu mới** | [`screenshots/02_add_transaction.png`](screenshots/02_add_transaction.png), [`screenshots/03_choose_category.png`](screenshots/03_choose_category.png) |
| 3 | **Nhập tiền tệ VNĐ (₫75,000)** | [`screenshots/04_enter_amount_vnd.png`](screenshots/04_enter_amount_vnd.png) |
| 4 | **Cập nhật số dư & Danh sách giao dịch** | [`screenshots/05_home_with_balance.png`](screenshots/05_home_with_balance.png), [`screenshots/06_transactions_list.png`](screenshots/06_transactions_list.png) |
| 5 | **Sửa giao dịch chi tiêu** | [`screenshots/07_edit_transaction.png`](screenshots/07_edit_transaction.png), [`screenshots/08_after_edit.png`](screenshots/08_after_edit.png) |
| 6 | **Xóa giao dịch chi tiêu & reset số dư** | [`screenshots/09_delete_dialog.png`](screenshots/09_delete_dialog.png), [`screenshots/10_after_delete.png`](screenshots/10_after_delete.png), [`screenshots/11_home_after_delete.png`](screenshots/11_home_after_delete.png) |
| 7 | **Trang Giới thiệu & Bản quyền Nhóm 11** | [`screenshots/12_about_screen.png`](screenshots/12_about_screen.png), [`screenshots/13_about_team.png`](screenshots/13_about_team.png) |

---




<div align="center">
  <a href="https://cashewapp.web.app/">
    <img alt="Icon" src="promotional/icons/icon.png" width="150px" >
  </a>
</div>


<br />

<div align="center">
  <a href="https://apps.apple.com/us/app/cashew-expense-budget-tracker/id6463662930">
    <img alt="iOS App Store Badge" src="promotional/store-banners/app-store-badge.png" height="60px">
  </a>
  <a href="https://play.google.com/store/apps/details?id=com.budget.tracker_app">
    <img alt="Google Play Badge" src="promotional/store-banners/google-play-badge.png" height="60px">
  </a>
  <a href="https://github.com/jameskokoska/Cashew/releases/">
    <img alt="GitHub Badge" src="promotional/store-banners/github-badge.png" height="60px">
  </a>
  <a href="https://budget-track.web.app/">
    <img alt="PWA Badge" src="promotional/store-banners/pwa-badge.png" height="60px">
  </a>
</div>

<h3 align="center" style="font-size:28px; line-height:1">
  <a href="https://github.com/jameskokoska/Cashew/issues/725">🚀 Cashew Beta Testing</a>
</h3>

---

<br />

<a href="https://cashewapp.web.app/">
  <div align="center">
    <img width="95%" src="promotional/GitHub/SocialPreviewGitHub.png" alt="Promo banner">
  </div>
</a>

<br />

Cashew is a full-fledged, feature-rich application designed to empower users in managing their finances effectively. Built using Flutter - with Drift's SQL package, and Firebase - this app offers a seamless and intuitive user experience across various devices. Development started in September 2021.

---

## Features

<a href="https://www.youtube.com/watch?v=Oar9pkc7BSc&t=235s">
  <div align="center">
    <img width="80%" src="promotional/youtube-promo/thumbnail-oss.png" alt="Review Video">
  </div>
</a>
<p align="center">
  Cashew was featured on <a href="https://www.youtube.com/watch?v=Oar9pkc7BSc&t=235s">YouTube</a> on 'The Best Free and Open Source Apps in 2024!' (and in the thumbnail!)
</p>

<br />

<a href="https://www.youtube.com/watch?v=NYZd7IKn1oY&t=536s">
  <div align="center">
    <img width="80%" src="promotional/youtube-promo/thumbnail-year-best.png" alt="Review Video">
  </div>
</a>
<p align="center">
  Cashew was featured on <a href="https://www.youtube.com/watch?v=NYZd7IKn1oY&t=536s">YouTube</a> on 'The Best Apps of 2023!'
</p>

<br>

<a href="https://www.youtube.com/watch?v=2MwWmqcn--s&t=261s">
  <div align="center">
    <img width="80%" src="promotional/youtube-promo/thumbnail.png" alt="Review Video">
  </div>
</a>
<p align="center">
  Cashew was featured on <a href="https://www.youtube.com/watch?v=2MwWmqcn--s&t=261s">YouTube</a> on 'Top Android Apps! (November 2023)'
</p>

<br>

<div align="center">
  <img width="80%" src="promotional/play-store-feature/play-store-feature.png" alt="Play Store Feature">
</div>
<p align="center">
  Cashew was featured on <a href="https://play.google.com/store/apps/editorial?id=mc_apps_new_on_play_fcp">Google Play's Editorial 'New Apps We Love'</a> (November 2023)!
</p>

<br>

<a href="https://github.com/nyas1/Material-You-app-list?tab=readme-ov-file#-economy:~:text=MDY%20Celenganku-,MDY%20Cashew,-MDY%20Allowance%20FOSS">
  <div align="center">
    <img width="80%" src="promotional/material-apps-feature/material-apps-feature.png" alt="Material Apps List Feature">
  </div>
</a>
<p align="center">
  Cashew was featured in the <a href="https://github.com/nyas1/Material-You-app-list?tab=readme-ov-file#-economy:~:text=MDY%20Celenganku-,MDY%20Cashew,-MDY%20Allowance%20FOSS">Material You Apps List</a>!
</p>

## Release

Check out the [official website](https://cashewapp.web.app/)!

This application is available on the [App Store](https://apps.apple.com/us/app/cashew-expense-budget-tracker/id6463662930), [Google Play](https://play.google.com/store/apps/details?id=com.budget.tracker_app), [GitHub](https://github.com/jameskokoska/Cashew/releases/) and as a [Web App (PWA)](https://budget-track.web.app/).

### Changelog

Changes and progress about development is all heavily documented in GitHub [commits](https://github.com/jameskokoska/Cashew/commits/main) and in the [changelog](https://github.com/jameskokoska/Cashew/blob/main/budget/lib/widgets/showChangelog.dart)

## Key Features

### 💸 Budget Management

- Custom Budgets and Time Periods: Set up personalized budgets with flexible time periods, such as monthly, weekly, daily, or any custom time period that suits your financial planning needs. A custom time period is useful if you plan on setting a one-time travel budget!
- Added Budgets: Selectively add transactions to specific budgets, allowing you to focus on specific expense categories.
- Category Spending Limits per Budget: Set limits for each category within a budget, ensuring responsible spending.
- Past Budget History Viewing: Analyze your spending habits over time by accessing past budget history, enabling comparison and tracking of financial progress.
- Goals: Create spending and saving goals and put transactions towards different purchases or savings. Track your progress towards achieving your financial goals.

### 💰 Transaction Management

- Support for Different Transaction Types: Categorize transactions effectively based on types such as upcoming, subscription, repeating, debts (borrowed), and credit (lent). Each type behaves in certain ways in the interface. Pay your upcoming transactions when you're ready, or mark your lent out transactions as collected.
- Custom Categories: Create personalized categories to organize transactions according to your unique spending habits. Search through multiple icons and select the default option as expenses or income when adding transactions.
- Custom Titles: Automatically assign transactions with the same name to specific categories, saving time and ensuring consistency. These titles are stored in memory and popup when you add another transaction with a similar name.
- Search and Filters: Easily search and filter transactions based on various criteria such as date, category, amount, or custom tags, enabling quick access to information.
- Easy Editing: Long-press and swipe to select multiple budgets, edit accordingly as needed or delete multiple at once.

### 💱 Financial Flexibility

- Multiple Currencies and Accounts: Manage finances across different currencies and accounts with up-to-date conversion rates for accurate calculations and effortless currency conversions. The interface shows the original amount added and the converted amount to the selected account.
- Switch Accounts and Currencies with Ease: On the homepage, easily select a different account and currency and everything will be converted automatically in an instant.

### 🔒 Enhanced Security and Accessibility

- Biometric Lock: Secure budget data using biometric authentication, adding an extra layer of privacy.
- Google Login: Conveniently log in to the app using your Google account, ensuring a streamlined and hassle-free authentication process.

### 🎨 User Experience and Design

- Material You Design: Enjoy a visually appealing and modern interface, following the principles of Material You design for a delightful user experience.
- Custom Accent Color: Personalize the app by selecting a custom accent color that suits your style, or follow that of the system.
- Light and Dark Mode: Seamlessly switch between light and dark themes to optimize visibility and reduce eye strain.
- Customizable Home Screen: Tailor the home screen layout and widgets to display the financial information that matters most to you, providing a personalized and efficient dashboard.
- Detailed Graph Visuals: Gain valuable insights into spending patterns through detailed and interactive graphs, visualizing financial data at a glance.
- Beautiful Adaptive UI: A responsive user interface that adapts flawlessly to both web and mobile platforms, providing an immersive and consistent user experience across devices.

### ☁ Backup and Syncing

- Cross-Device Sync: Keep budget data synchronized across all devices, ensuring access to financial information wherever you go.
- Google Drive Backup: Safeguard budget data by utilizing Google Drive's backup functionality, allowing easy restoration of data if needed.

### 💿 Smart Automation

- Notifications: Stay informed about important financial events and receive timely reminders for budget goals, transactions, and upcoming due dates.
- Import CSV Files: Seamlessly import financial data by uploading CSV files, facilitating a smooth transition from other applications or platforms.
- Import Google Sheets: Seamlessly import Google Sheets tables, quickly importing many transactions from a spreadsheet.
- App Links: Automatically create transactions with pre-filled data using app linking (documentation below)

## Automation

See the `Automation` section on the FAQ website for information on how to add transactions automatically: https://cashewapp.web.app/faq.html#automation

## Bundled Packages

This repository contains, bundled in, modified versions of the discontinued packages listed below. They can be found in the folder `/budget/packages`

- https://pub.dev/packages/implicitly_animated_reorderable_list
- https://pub.dev/packages/sliding_sheet

## Translations

The translations are available here: https://docs.google.com/spreadsheets/d/1QQqt28cmrby6JqxLm-oxUXCuM3alniLJ6IRhcPJDOtk/edit?usp=sharing. If you would like to help translate, please reach out on email: dapperappdeveloper@gmail.com

### To Update Translations

1. Run `budget\assets\translations\generate-translations.py`
2. Restart the application

## Developer Notes

### Pull Requests and Contributions

Unfortunately, I am currently not accepting contributions due to licensing and credits. Since this application turns some profits, I want to avoid any muddy water when it comes to compensation for contributions. You are free to submit an [issue](https://github.com/jameskokoska/Cashew/issues) and I can consider it!

### Android Release

- To build an app-bundle Android release, run `flutter build appbundle --release`

Note: required Android SDK.

### iOS Release

- To build an IPA iOS release, run `flutter build ipa`

Note: requires MacOS.

### Firebase Deployment

- To deploy to firebase, run `firebase deploy`

Note: required Firebase.

### GitHub release

- Create a tag for the current version specified in `pubspec.yaml`
- `git tag <version>`
- Push the tag
- `git push origin <version>`
- Create the release and upload binaries
- https://github.com/jameskokoska/Cashew/releases/new

### Scripts

`deploy_and_build_windows.bat`

- Deploy to Firebase and build the apk and appbundle

`open_release_builds.bat`

- Opens the location of the built apk and appbundle

`update_translations.bat`

- Downloads the latest version of Cashew translations. Runs `budget\assets\translations\generate-translations.py`

### Develop Wirelessly on Android

- `adb tcpip 5555`
- `adb connect <IP>`
- Get the phone's IP by going to `About Phone` > `Status Information` > `IP Address`

### Migrate Database

1. Make any database changes to the schema and tables
2. Bump the schema version
   - Change `int schemaVersionGlobal = ...+1` in `tables.dart`
3. Make sure you are in application root directory
   - `cd .\budget\`
4. Generate database code
   - Run `dart run build_runner build`
5. Export the new schema
   - Generate schema dump for the newly created schema
   - Replace `[schemaVersion]` in the command below with the value of `schemaVersionGlobal`
   - Run `dart run drift_dev schema dump lib\database\tables.dart drift_schemas//drift_schema_v[schemaVersion].json`
   - Read more: https://drift.simonbinder.eu/docs/advanced-features/migrations/#exporting-the-schema
6. Generate step-by-step migrations
   - Run `dart run drift_dev schema steps drift_schemas/ lib\database\schema_versions.dart`
7. Implement migration strategy
   - Edit `await stepByStep(...)` function in `tables.dart` and add the migration strategy for the new version migration

### Get Platform

- Use `getPlatform()` from `functions.dart`
- Since `Platform` is not supported on web, we must create a wrapper and always use this to determine the current platform

### Push Route

- If we want to navigate to a new page, stick to `pushRoute(context, page)` function from `functions.dart`
- It handles the platform routing and `PageRouteBuilder`

### Wallets vs. Accounts

- `Wallets` have been been renamed to `Accounts` on the front-end but internally, the name `Wallet` is still used.

### Objectives vs. Goals

- `Objectives` have been been renamed to `Goals` on the front-end but internally, the name `Objectives` is still used.

### Long Term Loans

- Long term loans create a goal. However, the goals total is not used. Instead the total of the goal is calculated by totalling the proper polarity of transactions of the opposite type. For example, if it was a loan of 100$ lent out, the initial transaction would be 100$ of negative polarity (expense) and that would be the total of the goal. When a payment is made, it is made in the opposite (positive) polarity (income) and added to the total 'paid back'. We can easily find how much is remaining by taking the difference (or the addition including polarities).
