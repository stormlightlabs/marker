{
  description = "Marker - Flutter Android APK build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/4100e830e085863741bc69b156ec4ccd53ab5be0";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        lib = pkgs.lib;
        jdk = pkgs.jdk17;
        flutter = pkgs.flutter;

        # Android SDK composition with all versions required by AGP/Flutter.
        # We pin exact versions rather than "latest" for reproducibility.
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "9.0";
          platformToolsVersion = "36.0.2";
          buildToolsVersions = [
            "35.0.0"
            "35.0.1"
            "36.0.0"
          ];
          platformVersions = [
            "36"
            "35"
            "34"
          ];
          includeSources = false;
          includeSystemImages = false;
          includeEmulator = false;
          includeNDK = true;
          ndkVersions = [ "28.2.13676358" ];
          includeCmake = true;
          cmakeVersions = [ "4.1.2" ];
          useGoogleAPIs = false;
          extraLicenses = [
            "android-sdk-license"
            "android-sdk-preview-license"
          ];
        };

        androidSdk = androidComposition.androidsdk;
        androidSdkRoot = "${androidSdk}/libexec/android-sdk";

        # Filter source to exclude build artifacts, caches, and generated files
        # that contain absolute paths or are not needed for the build.
        src = lib.cleanSourceWith {
          src = self;
          filter =
            name: type:
            let
              baseName = baseNameOf (toString name);
              path = toString name;
            in
            !(
              # Exclude build artifacts and caches
              baseName == ".dart_tool"
              || baseName == "build"
              || baseName == ".android"
              || baseName == ".gradle"
              || baseName == ".pub-cache"
              || baseName == "node_modules"
              # Exclude generated directories in android/
              || (type == "directory" && lib.hasPrefix "android/app/build" path)
              || (type == "directory" && lib.hasPrefix "android/.gradle" path)
              || (type == "directory" && lib.hasPrefix "android/build" path)
              # Exclude IDE files
              || baseName == ".idea"
              || baseName == ".vscode"
              # Exclude generated local.properties (we create our own)
              || baseName == "local.properties"
              # Exclude other platform build dirs
              || baseName == "macos"
              || baseName == "windows"
              || baseName == "linux"
              || baseName == "web"
            );
        };

        # The APK is built as a Fixed-Output Derivation (FOD) because the
        # Flutter and Gradle toolchains download dependencies from the network
        # (pub.dev, Maven Central, Google repositories) during the build.
        # The output hash pins the result, giving us reproducibility.
        marker-android = pkgs.stdenv.mkDerivation {
          pname = "marker-android";
          version = "1.0.0";
          inherit src;

          nativeBuildInputs = [
            flutter
            jdk
            androidSdk
            pkgs.git
            pkgs.python3
          ];

          patchPhase = ''
            runHook prePatch

            # Patch pubspec.yaml with dependency overrides needed for the
            # nixpkgs Flutter version (meta/test_api/matcher pin mismatch).
            python3 <<PYEOF
          import sys

          with open("pubspec.yaml") as f:
              content = f.read()

          if "nix-flutter-overrides" not in content:
              lines = content.split('\n')
              new_lines = []
              in_overrides = False
              added = False
              for line in lines:
                  if line.strip() == "dependency_overrides:":
                      in_overrides = True
                  if in_overrides and not added:
                      if line.strip().startswith("code_forge:") or line.strip().startswith("flutter:"):
                          new_lines.append("  meta: ^1.18.0  # nix-flutter-overrides")
                          new_lines.append("  test_api: ^0.7.12  # nix-flutter-overrides")
                          new_lines.append("  matcher: ^0.12.16+1  # nix-flutter-overrides")
                          added = True
                  new_lines.append(line)

              with open("pubspec.yaml", "w") as f:
                  f.write('\n'.join(new_lines))

              print("Patched pubspec.yaml with Nix Flutter dependency overrides")
          else:
              print("pubspec.yaml already patched")
          PYEOF

            # Patch onReorderItem -> onReorder for Flutter <= 3.41.9 compatibility.
            # The upstream project was written against a newer Flutter where the
            # parameter was renamed; nixpkgs Flutter still uses the old name.
            if grep -q "onReorderItem:" lib/features/bookmarks/presentation/bookmarks_screen.dart 2>/dev/null; then
              sed -i 's/onReorderItem:/onReorder:/g' lib/features/bookmarks/presentation/bookmarks_screen.dart
              echo "Patched onReorderItem -> onReorder"
            fi

            runHook postPatch
          '';

          buildPhase = ''
            runHook preBuild

            export HOME=$TMPDIR
            export ANDROID_SDK_ROOT=${androidSdkRoot}
            export ANDROID_HOME=$ANDROID_SDK_ROOT
            export JAVA_HOME=${jdk.home}
            export FLUTTER_ROOT=${flutter}

            # Point Gradle to the Nix-provided aapt2 so it does not try to
            # download its own copy from Maven.
            AAPT2_PATH="$(ls -d "$ANDROID_SDK_ROOT/build-tools/"*/ | sort -V | tail -n1)aapt2"
            export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$AAPT2_PATH"

            # Generate local.properties for the Android build.
            mkdir -p android
            cat > android/local.properties <<LOCALPROP
            flutter.sdk=${flutter}
            sdk.dir=$ANDROID_SDK_ROOT
            ndk.dir=$ANDROID_SDK_ROOT/ndk/28.2.13676358
            cmake.dir=$(echo "$ANDROID_SDK_ROOT/cmake/"*/ | head -n1)
            LOCALPROP

            # Fetch Dart dependencies and build the release APK.
            flutter pub get
            flutter build apk --release

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp build/app/outputs/flutter-apk/app-release.apk $out/marker.apk
            runHook postInstall
          '';

          # FOD: the build downloads Dart and Maven dependencies, so we pin the
          # output hash. When dependencies change, update this hash by running:
          #   nix build .#default
          # and copying the "got" hash from the error message.
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-lae9zbZvm/+KEHMMUSAn48P+pQagQTZj05ahjdM88Tw=";

          meta = {
            description = "Marker Android APK";
            license = lib.licenses.mit;
            platforms = lib.platforms.linux;
          };
        };

        # Convenience script that copies the built APK into the current directory.
        copyApkScript = pkgs.writeShellScriptBin "copy-marker-apk" ''
          set -euo pipefail
          OUTDIR="''${1:-$PWD/build/apk}"
          mkdir -p "$OUTDIR"
          cp ${marker-android}/marker.apk "$OUTDIR/marker.apk"
          echo "Copied APK to: $OUTDIR/marker.apk"
        '';

      in
      {
        packages = {
          default = marker-android;
          apk = marker-android;
        };

        apps = {
          default = {
            type = "app";
            program = "${copyApkScript}/bin/copy-marker-apk";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "marker-dev";

          buildInputs = [
            jdk
            flutter
            androidSdk
            pkgs.git
            pkgs.dart
            copyApkScript
          ];

          shellHook = ''
            export ANDROID_SDK_ROOT=${androidSdkRoot}
            export ANDROID_HOME=$ANDROID_SDK_ROOT
            export JAVA_HOME=${jdk.home}
            export FLUTTER_ROOT=${flutter}
            export PATH="${flutter}/bin:${jdk}/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

            # Add cmake to PATH
            CMAKE_DIR="$(echo "$ANDROID_SDK_ROOT/cmake/"*/bin 2>/dev/null | head -n1)"
            if [ -d "$CMAKE_DIR" ]; then
              export PATH="$CMAKE_DIR:$PATH"
            fi

            # Add NDK to PATH
            NDK_DIR="$ANDROID_SDK_ROOT/ndk/28.2.13676358"
            if [ -d "$NDK_DIR" ]; then
              export PATH="$NDK_DIR:$PATH"
              export ANDROID_NDK_ROOT="$NDK_DIR"
            fi

            # aapt2 override for Gradle
            AAPT2_PATH="$(ls -d "$ANDROID_SDK_ROOT/build-tools/"*/ | sort -V | tail -n1)aapt2"
            export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$AAPT2_PATH"

            echo "Marker dev shell ready!"
            echo "Flutter: $(flutter --version | head -n1)"
            echo "Android SDK: $ANDROID_SDK_ROOT"
            echo "Java: $JAVA_HOME"
            echo ""
            echo "Commands:"
            echo "  nix build .#default        - Build the APK (hermetic, reproducible)"
            echo "  nix run .#default          - Copy APK to build/apk/"
            echo "  flutter build apk          - Build interactively (impure, for dev)"
          '';
        };
      }
    );
}
