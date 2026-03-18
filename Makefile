# 🌟 修改這裡：刪掉 arm64e，只留 arm64
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

UnityAdsTweak_FRAMEWORKS = UIKit Foundation WebKit AVFoundation CoreMedia

UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -framework UnityAds -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
