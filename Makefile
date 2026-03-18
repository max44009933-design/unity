ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak
# 🌟 魔法檔案保留，維持 Swift 引擎運作
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 基礎框架
UnityAdsTweak_FRAMEWORKS = UIKit Foundation WebKit AVFoundation CoreMedia

UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks
# 🌟 【關鍵修改】刪掉 -framework UnitySwiftProtobuf，只留下 UnityAds
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -framework UnityAds -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
