# Flutter 환경 설정 가이드 (Windows 기준)

## 1. Flutter SDK 다운로드 및 설치

- Flutter 공식 사이트에서 수동 설치  
  → https://docs.flutter.dev/install/manual

- 설치 방법  
  1. 다운로드한 압축 파일을 원하는 위치에 해제 (예: `C:\flutter`)  
  2. `Program Files`처럼 **공백이 포함된 폴더 경로는 사용하지 말 것**



## 2. Android Studio 설치 및 설정

- Android Studio 다운로드 ` 
  → https://developer.android.com/studio

### Android Studio 설정

1. **Flutter 플러그인 설치**  
   - `Settings` > `Plugins` 메뉴에서 Flutter 검색 후 설치  
   - Dart 플러그인은 자동으로 함께 설치됨

2. **SDK Tools 설치**  
   - `More Actions` > `SDK Manager` 클릭  
   - `SDK Tools` 탭으로 이동  
   - `Android SDK Command-line Tools` 항목 체크 후 설치



## 3. 환경 변수 등록 (Path 설정)

1. Windows 검색창에서 `환경 변수 편집` 검색 및 실행  
2. 시스템 변수 영역에서 `Path` 항목 선택 → `편집` 클릭  
3. `새로 만들기` 클릭 후 다음 경로 추가:

```bash
C:\flutter\bin
```



## 4. Flutter Doctor로 설정 확인

### PowerShell 또는 CMD에서 실행:

```bash
flutter doctor
```

- Flutter 개발에 필요한 요소들이 제대로 설치되어 있는지 점검함

- 아래와 같이 [!] Visual Studio 관련 에러가 출력될 수 있음:

![에러 스크린샷](/image.png)

### 해결 방법
1. Visual Studio 설치

2. 설치 도중 워크로드(Workloads) 항목에서 아래 옵션 체크:

    - Desktop development with C++

3. 만약 해당 워크로드가 보이지 않는 경우, 아래 사이트에서 Build Tools만 수동 다운로드 가능  
    → https://visualstudio.microsoft.com/ko/visual-cpp-build-tools/


## 5. 참고 자료
- Flutter 설치 관련 추가 설명은 다음 블로그를 참고할 것:  
    → https://codingapple.com/unit/flutter-install-on-windows-and-mac/?id=19933