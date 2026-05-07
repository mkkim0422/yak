# Firebase 통합 계획서 (V2 출시 전 외부 작업)

본 문서는 V1.0 → V2.0 전환 시 Firebase Auth + Firestore + FCM 통합을
위한 외부 의존성과 작업 순서를 정리합니다. V1.0 코드는 Firebase 미통합
상태로 정상 동작하며, 본 문서는 외부 작업이 완료된 시점에 켜질 수 있도록
인터페이스 설계만 보유합니다.

## 외부 의존성 (선장님 작업 — 코드 수정 X)

### 1. Firebase Console
1. https://console.firebase.google.com 에서 새 프로젝트 생성
2. Android 앱 추가:
   - 패키지명: `kr.co.sphinfo.alyak.alyak`
   - 앱 닉네임: `알약 Android`
   - 디버그 SHA-1 인증서 등록 (추후 release SHA-1도 추가)
3. `google-services.json` 다운로드 → `android/app/` 배치
4. 기능 활성화:
   - Authentication: Email/Password, Google 로그인
   - Firestore: 데이터베이스 생성 (asia-northeast3 = 서울 리전)
   - Cloud Messaging: 자동 활성화
   - Crashlytics: 자동 활성화
   - Analytics: 자동 활성화

### 2. Google Cloud Console (Google 로그인용)
1. OAuth 동의 화면 구성 (한국어 / 외부 / 의료 정보 X)
2. OAuth 클라이언트 ID 생성 (Android, SHA-1 등록)
3. Firebase Console과 자동 연동

### 3. AdMob (광고용 V2)
1. https://admob.google.com 계정 생성
2. 새 앱 등록 → Android, 패키지명 일치
3. 광고 단위 생성:
   - 배너 (홈 / 멤버 화면용)
   - 전면 (영양제 추가 후 3-5회 빈도용)
4. AppMob App ID + Ad Unit ID 추출
5. `android/app/src/main/AndroidManifest.xml`의 application 태그 안에
   `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"
     android:value="ca-app-pub-XXXXX~XXXXX" />` 추가

### 4. 앱 서명 (출시 시 1회)
1. `keytool -genkey -v -keystore alyak-upload.keystore ...`로 업로드 키
   생성, 비밀번호 안전 보관
2. `android/key.properties`에 키 정보 (gitignore)
3. `android/app/build.gradle`에 signingConfigs 설정
4. Google Play Console에서 App Signing 활성화 (권장)

### 5. Google Play Console
1. 개발자 계정 등록 (1회 $25)
2. 새 앱 생성 — 앱 이름 "알약", 카테고리 "건강/피트니스"
3. Data Safety 섹션 작성 (본 README 참조)
4. 콘텐츠 등급 — 광고 포함 12세+
5. 개인정보 처리방침 URL 등록 (예: GitHub Pages 또는 운영 사이트)

## V2 코드 작업 (외부 작업 후)

### A. pubspec.yaml에 추가
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_messaging: ^15.1.3
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
  google_sign_in: ^6.2.1
  google_mobile_ads: ^5.1.0
  share_plus: ^10.0.0
```

### B. android/app/build.gradle (Kotlin DSL)
```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")        // Firebase
    id("com.google.firebase.crashlytics")        // Crashlytics
    id("dev.flutter.flutter-gradle-plugin")
    id("kotlin-android")
}
```

### C. android/build.gradle (Project)
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}
```

### D. main.dart에 추가
```dart
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### E. lib/core/analytics/analytics_service.dart
`NoopAnalyticsService` → `_FirebaseAnalyticsImpl`로 교체. 인터페이스 그대로.

### F. lib/core/ads/ad_policy.dart
`NoopAdSlot` → google_mobile_ads `BannerAd` 래핑한 실 위젯으로 교체.

### G. 새 파일 — lib/core/firebase/auth_service.dart
- 익명 로그인 (둘러보기 모드)
- 구글 로그인
- 이메일/비밀번호 로그인
- 자동 로그인
- 로그아웃 + 계정 삭제

### H. 새 파일 — lib/core/firebase/firestore_sync_service.dart
- users/{uid}/family/{memberId} 문서 단위
- offline persistence 활성화
- updatedAt 기반 last-write-wins
- 익명 → 로그인 시 마이그레이션

### I. 새 파일 — lib/core/firebase/fcm_service.dart
- FCM 토큰 → Firestore users/{uid}.fcmToken
- 검진 1년 후 알림은 Cloud Function 트리거

## 시간 예상 (V2 외부+코드)

- 외부 (Console / 키 생성): 1-2일
- 코드 통합: 4-6일
- 테스트 / 디버깅: 2-3일
- 합계: 1-2주

## V1 → V2 마이그레이션 보장

- DataExportService.schemaVersion = 1 (현재)
- V2 schemaVersion = 2 (Firestore 동기 + 추가 필드)
- 사용자가 V1 → V2 업데이트 시:
  1. 첫 진입에서 로그인 화면 노출
  2. 로그인 후 SecureStorage 로컬 데이터를 Firestore로 1회 업로드
  3. 이후 Stream 구독으로 실시간 동기

본 문서는 V2 마이그레이션 시 작성된 코드와 연결됩니다.
