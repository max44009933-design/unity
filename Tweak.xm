#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h> 
#import "fishhook.h" 

// ==========================================
// 🛡️ 不死神盾
// ==========================================
static void (*orig_exit)(int);
void my_exit(int s) { NSLog(@"[IPA918] 🛡️ 攔截到 exit(%d)", s); }
static int (*orig_kill)(pid_t, int);
int my_kill(pid_t p, int s) { NSLog(@"[IPA918] 🛡️ 攔截到 kill"); return 0; }

// ==========================================
// 📺 宣告 UnityAds 接口
// ==========================================
@interface UnityAds : NSObject
+ (void)initialize:(NSString *)gameId testMode:(BOOL)testMode initializationDelegate:(id)delegate;
+ (void)load:(NSString *)placementId loadDelegate:(id)delegate;
+ (void)show:(UIViewController *)viewController placementId:(NSString *)placementId showDelegate:(id)delegate;
@end

@protocol UnityAdsInitializationDelegate <NSObject>
- (void)initializationComplete;
- (void)initializationFailed:(int)error withMessage:(NSString *)message;
@end
@protocol UnityAdsLoadDelegate <NSObject>
- (void)unityAdsAdLoaded:(NSString *)placementId;
- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(int)error withMessage:(NSString *)message;
@end
@protocol UnityAdsShowDelegate <NSObject>
- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(int)state;
- (void)unityAdsShowFailed:(NSString *)placementId withError:(int)error withMessage:(NSString *)message;
- (void)unityAdsShowStart:(NSString *)placementId;
- (void)unityAdsShowClick:(NSString *)placementId;
@end

NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 
static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

// ==========================================
// 🛠️ 畫面抓取 & 彈窗
// ==========================================
static UIViewController *getTopViewController() {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) { keyWindow = window; break; }
                }
            }
        }
    }
    if (!keyWindow) keyWindow = [[UIApplication sharedApplication] windows].firstObject;
    UIViewController *topController = keyWindow.rootViewController;
    while (topController.presentedViewController) topController = topController.presentedViewController;
    return topController;
}

static void showDebugAlert(NSString *title, NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = getTopViewController();
        if (top) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"了解" style:UIAlertActionStyleDefault handler:nil]];
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// ==========================================
// 🌟 廣告助手
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)startRadar;
@end

@implementation UnityAdsHelper
+ (instancetype)sharedInstance {
    static UnityAdsHelper *i = nil; static dispatch_once_t o;
    dispatch_once(&o, ^{ i = [[self alloc] init]; }); return i;
}
- (void)initializationComplete {
    Class unityCls = NSClassFromString(@"UnityAds");
    if (unityCls) [unityCls load:myAdUnitId loadDelegate:self];
}
- (void)initializationFailed:(int)error withMessage:(NSString *)message { showDebugAlert(@"🔴 初始化失敗", message); }
- (void)unityAdsAdLoaded:(NSString *)placementId { isAdReadyToShow = YES; [self tryTriggerBulldozeShow]; }
- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(int)error withMessage:(NSString *)message { showDebugAlert(@"🔴 廣告載入失敗", message); isAdReadyToShow = NO; }
- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        Class unityCls = NSClassFromString(@"UnityAds");
        if (topController && unityCls) [unityCls show:topController placementId:myAdUnitId showDelegate:self];
    }
}
- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(int)state { showDebugAlert(@"🎬 測試成功", @"廣告順利播放完畢！"); }
- (void)unityAdsShowFailed:(NSString *)placementId withError:(int)error withMessage:(NSString *)message { showDebugAlert(@"🔴 播放失敗", message); }
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

- (void)startRadar {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (UIWindow *window in [UIApplication sharedApplication].windows) {
                    for (UIView *subview in window.subviews) {
                        NSMutableString *fullText = [NSMutableString string];
                        if ([subview isKindOfClass:[UILabel class]]) [fullText appendFormat:@"%@ ", ((UILabel *)subview).text];
                        else if ([subview isKindOfClass:[UITextView class]]) [fullText appendFormat:@"%@ ", ((UITextView *)subview).text];
                        
                        if ([fullText containsString:@"WARNING"] && [fullText containsString:@"tampered with"]) {
                            subview.hidden = YES; [subview removeFromSuperview];
                        }
                    }
                }
            });
        }];
    });
}
@end

// ==========================================
// 🚀 核心注入點：雙重載入 + 終極診斷
// ==========================================
%ctor {
    struct rebind_msg h[] = {
        {"exit", (void *)my_exit, (void **)&orig_exit},
        {"kill", (void *)my_kill, (void **)&orig_kill}
    };
    rebind_symbols(h, 2);
    
    // 定位根目錄的 UnityAds.framework
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *frameworkDir = [bundlePath stringByAppendingPathComponent:@"UnityAds.framework"];
    NSString *binaryPath = [frameworkDir stringByAppendingPathComponent:@"UnityAds"];

    // 🌟 嘗試 A：使用官方 NSBundle 載入
    NSBundle *uBundle = [NSBundle bundleWithPath:frameworkDir];
    NSError *loadError = nil;
    BOOL bundleLoaded = [uBundle loadAndReturnError:&loadError];

    // 🌟 嘗試 B：使用底層 dlopen 暴力載入
    void *handle = dlopen(binaryPath.UTF8String, RTLD_NOW | RTLD_GLOBAL);
    const char *dlErrorC = dlerror();
    NSString *dlErrorStr = dlErrorC ? [NSString stringWithUTF8String:dlErrorC] : @"無報錯";

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [[UnityAdsHelper sharedInstance] startRadar];
        Class unityCls = NSClassFromString(@"UnityAds");
        
        if (unityCls) {
            // ✅ 載入成功！開始播放廣告
            [unityCls initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                isTenSecondTimerExpired = YES; 
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            });
            
        } else {
            // ❌ 載入失敗！印出底層真實死因
            NSString *diagMsg = [NSString stringWithFormat:@"[Bundle狀態]: %@\n[Bundle錯誤]: %@\n\n[dlopen指標]: %p\n[dlopen錯誤]: %@",
                                 bundleLoaded ? @"成功" : @"失敗",
                                 loadError ? loadError.localizedDescription : @"無",
                                 handle,
                                 dlErrorStr];
            showDebugAlert(@"🔴 底層載入失敗診斷", diagMsg);
        }
    });
}
