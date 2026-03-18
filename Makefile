ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak
# 🌟 魔法檔案保留，維持 Swift 引擎運作
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 把會報錯的 CoreAudioTypes 拔掉，換成 AVFoundation 跟 CoreMedia 保底
UnityAdsTweak_FRAMEWORKS = UIKit Foundation WebKit AVFoundation CoreMedia

UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks
# 🌟 連結兩大核心庫
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -framework UnityAds -framework UnitySwiftProtobuf -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
