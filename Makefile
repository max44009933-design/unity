ARCHS = arm64 arm64e
# 【修正 1】把支援版本從 11.0 提高到 14.0，解決 arm64e 的警告
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak
UnityAdsTweak_FILES = Tweak.xm

# 【修正 2】在 CFLAGS 加上 -F 參數，告訴編譯器去哪裡找 Headers！
UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -framework UnityAds

include $(THEOS_MAKE_PATH)/tweak.mk
