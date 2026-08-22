name: Build Tweak
on: [push, workflow_dispatch]

jobs:
  build:
    runs-on: macos-14
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          brew install ldid dpkg

      - name: Install Theos and iOS SDKs
        run: |
          git clone --recursive https://github.com/theos/theos.git $HOME/theos
          echo "THEOS=$HOME/theos" >> $GITHUB_ENV
          curl -fsSL https://github.com/theos/sdks/archive/master.zip -o sdks.zip
          unzip -q sdks.zip
          mkdir -p $HOME/theos/sdks
          cp -r sdks-master/*.sdk $HOME/theos/sdks/
          rm -rf sdks.zip sdks-master

      - name: Auto-fix macro in Tweak.xm
        run: |
          python3 -c "with open('Tweak.xm', 'r') as f: c = f.read(); open('Tweak.xm', 'w').write(c.replace('%orig', '(%orig)'))"

      - name: Create Build Files
        run: |
          cat << 'EOF' > Makefile
          TARGET := iphone:clang:latest:14.0
          ARCHS = arm64
          INSTALL_TARGET_PROCESSES = Twitter

          include $(THEOS)/makefiles/common.mk

          TWEAK_NAME = XNotForMe
          XNotForMe_FILES = Tweak.xm
          XNotForMe_CFLAGS = -fobjc-arc

          include $(THEOS_MAKE_PATH)/tweak.mk
          EOF

          cat << 'EOF' > control
          Package: com.n3d1117.xnotforme
          Name: XNotForMe
          Version: 1.0.0
          Architecture: iphoneos-arm64
          Description: Remove For You tab
          Maintainer: n3d1117
          Author: n3d1117
          Section: Tweaks
          EOF

      - name: Compile Tweak
        run: |
          make package FINALPACKAGE=1

      - name: Upload Output Files
        uses: actions/upload-artifact@v4
        with:
          name: XNotForMe-Compiled
          path: |
            .theos/obj/*.dylib
            .theos/obj/debug/*.dylib
            packages/*.deb
