{
  description = "Marker - Flutter Android build environment and APK builder";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        # Java version required by the project (Java 17)
        jdk = pkgs.jdk17;

        # Android SDK composition with the exact versions Flutter 3.41.9 expects
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "latest";
          platformToolsVersion = "latest";
          buildToolsVersions = [ "36.0.0" "35.0.1" ];
          platformVersions = [ "36" "35" "34" ];
          includeSources = false;
          includeSystemImages = false;
          includeEmulator = false;
          includeNDK = true;
          ndkVersions = [ "28.2.13676358" ];
          includeCmake = true;
          cmakeVersions = [ "latest" ];
          useGoogleAPIs = false;
          extraLicenses = [
            "android-sdk-license"
            "android-sdk-preview-license"
          ];
        };

        androidSdk = androidComposition.androidsdk;
        androidPlatformTools = androidComposition.platform-tools;

        # Flutter from nixpkgs
        flutter = pkgs.flutter;

        # Android SDK root path
        androidSdkRoot = "${androidSdk}/libexec/android-sdk";

        # Script to patch the project source for compatibility with nixpkgs Flutter
        patchMarkerSource = pkgs.writeShellScriptBin "patch-marker-source" ''
          set -euo pipefail
          PROJECT_ROOT="''${1:-$(pwd)}"
          cd "$PROJECT_ROOT"

          # Patch pubspec.yaml for dependency overrides
          PUBSPEC="pubspec.yaml"
          if [ -f "$PUBSPEC" ] && ! grep -q "# nix-flutter-overrides" "$PUBSPEC" 2>/dev/null; then
            ${pkgs.python3}/bin/python3 <<PYEOF
          with open("$PUBSPEC") as f:
              lines = f.readlines()

          new_lines = []
          in_overrides = False
          added = False
          for line in lines:
              if line.strip() == "dependency_overrides:":
                  in_overrides = True
              if in_overrides and not added and line.strip().startswith("code_forge:"):
                  new_lines.append("  meta: ^1.18.0  # nix-flutter-overrides\n")
                  new_lines.append("  test_api: ^0.7.12  # nix-flutter-overrides\n")
                  new_lines.append("  matcher: ^0.12.16+1  # nix-flutter-overrides\n")
                  added = True
              new_lines.append(line)

          with open("$PUBSPEC", "w") as f:
              f.writelines(new_lines)

          print("Patched pubspec.yaml with Nix Flutter dependency overrides")
          PYEOF
          fi

          # Patch onReorderItem -> onReorder for Flutter <= 3.41.9 compatibility
          BOOKMARKS_SCREEN="lib/features/bookmarks/presentation/bookmarks_screen.dart"
          if [ -f "$BOOKMARKS_SCREEN" ]; then
            if grep -q "onReorderItem:" "$BOOKMARKS_SCREEN" 2>/dev/null; then
              sed -i 's/onReorderItem:/onReorder:/g' "$BOOKMARKS_SCREEN"
              echo "Patched $BOOKMARKS_SCREEN: onReorderItem -> onReorder"
            fi
          fi
        '';

        # Build script that can be run with `nix run .#build-android`
        buildAndroidScript = pkgs.writeShellScriptBin "build-marker-android" ''
          set -euo pipefail

          PROJECT_ROOT="''${1:-$(pwd)}"
          cd "$PROJECT_ROOT"

          if [ ! -f pubspec.yaml ]; then
            echo "Error: No pubspec.yaml found in $PROJECT_ROOT"
            echo "Please run this from the project root or pass the project path as an argument."
            exit 1
          fi

          export HOME="''${HOME:-/tmp}"

          # Copy Android SDK to a writable temp directory because AGP may try to
          # auto-download missing components during the build.
          echo "=== Setting up writable Android SDK ==="
          TMPDIR="''${TMPDIR:-/tmp}"
          WRITABLE_SDK="$TMPDIR/android-sdk"
          cp -r "${androidSdkRoot}" "$WRITABLE_SDK"
          chmod -R +w "$WRITABLE_SDK"
          export ANDROID_SDK_ROOT="$WRITABLE_SDK"
          export ANDROID_HOME="$ANDROID_SDK_ROOT"
          export JAVA_HOME="${jdk.home}"
          export FLUTTER_ROOT="${flutter}"
          export PATH="${flutter}/bin:${jdk}/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

          # Add cmake to path if available
          CMAKE_DIR="$(echo "$ANDROID_SDK_ROOT/cmake/"*/bin 2>/dev/null | head -n1)"
          if [ -d "$CMAKE_DIR" ]; then
            export PATH="$CMAKE_DIR:$PATH"
          fi

          # Add NDK to path
          NDK_DIR="$ANDROID_SDK_ROOT/ndk/28.2.13676358"
          if [ -d "$NDK_DIR" ]; then
            export PATH="$NDK_DIR:$PATH"
            export ANDROID_NDK_ROOT="$NDK_DIR"
          fi

          # Setup aapt2 override for Gradle (use single latest build-tools)
          AAPT2_PATH="$(ls -d "$ANDROID_SDK_ROOT/build-tools/"*/ | sort -V | tail -n1)aapt2"
          export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$AAPT2_PATH"

          echo "=== Marker Android Build ==="
          echo "Project: $PROJECT_ROOT"
          echo "Flutter: $(${flutter}/bin/flutter --version | head -n1)"
          echo "Android SDK: $ANDROID_SDK_ROOT"
          echo "Java: $JAVA_HOME"
          echo ""

          # Patch source for nixpkgs Flutter compatibility
          ${patchMarkerSource}/bin/patch-marker-source "$PROJECT_ROOT"

          # Generate local.properties
          mkdir -p android
          cat > android/local.properties <<EOF
          flutter.sdk=${flutter}
          sdk.dir=$ANDROID_SDK_ROOT
          ndk.dir=$NDK_DIR
          cmake.dir=$(echo "$ANDROID_SDK_ROOT/cmake/"*/ | head -n1)
          EOF

          echo "=== Running flutter pub get ==="
          ${flutter}/bin/flutter pub get

          echo ""
          echo "=== Building Android APK ==="
          ${flutter}/bin/flutter build apk --release

          APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
          if [ -f "$APK_PATH" ]; then
            echo ""
            echo "=== Build successful ==="
            echo "APK: $PROJECT_ROOT/$APK_PATH"
            ls -lh "$APK_PATH"
          else
            echo "Build may have succeeded but APK not found at expected path: $APK_PATH"
            exit 1
          fi
        '';

        # A script that copies the APK to a specified output directory
        buildAndCopyApk = pkgs.writeShellScriptBin "build-marker-apk" ''
          set -euo pipefail
          OUTDIR="''${1:-$PWD/build/apk}"
          ${buildAndroidScript}/bin/build-marker-android "$(pwd)"
          mkdir -p "$OUTDIR"
          cp build/app/outputs/flutter-apk/app-release.apk "$OUTDIR/marker.apk"
          echo "Copied APK to: $OUTDIR/marker.apk"
        '';

      in
      {
        packages = {
          default = buildAndroidScript;
          build-android = buildAndroidScript;
          build-apk = buildAndCopyApk;
        };

        apps = {
          default = {
            type = "app";
            program = "${buildAndroidScript}/bin/build-marker-android";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "marker-dev";

          buildInputs = [
            jdk
            flutter
            androidSdk
            androidPlatformTools
            pkgs.git
            pkgs.dart
            buildAndroidScript
            patchMarkerSource
          ];

          shellHook = ''
            export ANDROID_SDK_ROOT=${androidSdkRoot}
            export ANDROID_HOME=$ANDROID_SDK_ROOT
            export JAVA_HOME=${jdk.home}
            export FLUTTER_ROOT=${flutter}
            export PATH="${flutter}/bin:${jdk}/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

            # Add cmake to path
            CMAKE_DIR="$(echo "$ANDROID_SDK_ROOT/cmake/"*/bin 2>/dev/null | head -n1)"
            if [ -d "$CMAKE_DIR" ]; then
              export PATH="$CMAKE_DIR:$PATH"
            fi

            # Add NDK to path
            NDK_DIR="$ANDROID_SDK_ROOT/ndk/28.2.13676358"
            if [ -d "$NDK_DIR" ]; then
              export PATH="$NDK_DIR:$PATH"
              export ANDROID_NDK_ROOT="$NDK_DIR"
            fi

            # Setup aapt2 override for Gradle (use single latest build-tools)
            AAPT2_PATH="$(ls -d "$ANDROID_SDK_ROOT/build-tools/"*/ | sort -V | tail -n1)aapt2"
            export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$AAPT2_PATH"

            # Generate local.properties if it doesn't exist
            if [ ! -f android/local.properties ]; then
              mkdir -p android
              cat > android/local.properties <<EOF
            flutter.sdk=${flutter}
            sdk.dir=$ANDROID_SDK_ROOT
            ndk.dir=$NDK_DIR
            cmake.dir=$(echo "$ANDROID_SDK_ROOT/cmake/"*/ | head -n1)
            EOF
              echo "Generated android/local.properties"
            fi

            echo "Marker dev shell ready!"
            echo "Flutter: $(flutter --version | head -n1)"
            echo "Android SDK: $ANDROID_SDK_ROOT"
            echo "Java: $JAVA_HOME"
            echo ""
            echo "Commands:"
            echo "  patch-marker-source        - Patch source for Nix Flutter compatibility"
            echo "  flutter build apk          - Build the Android APK"
            echo "  build-marker-android       - Full build script with progress output"
            echo "  nix run .#build-apk        - Build and copy APK to build/apk/"
          '';
        };
      });
}
