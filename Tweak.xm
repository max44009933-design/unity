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
// 📺 UnityAds 接口
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

// ==========================================
// 🔴 配置區 
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 
static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

// ==========================================
// 🛠️ 輔助工具
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
// 🌟 核心助手
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
- (void)initializationFailed:(int)e withMessage:(NSString *)m { showDebugAlert(@"🔴 初始化失敗", m); }
- (void)unityAdsAdLoaded:(NSString *)p { isAdReadyToShow = YES; [self tryTriggerBulldozeShow]; }
- (void)unityAdsAdFailedToLoad:(NSString *)p withError:(int)e withMessage:(NSString *)m { isAdReadyToShow = NO; }
- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *top = getTopViewController();
        Class unityCls = NSClassFromString(@"UnityAds");
        if (top && unityCls) [unityCls show:top placementId:myAdUnitId showDelegate:self];
    }
}
- (void)unityAdsShowComplete:(NSString *)p withFinishState:(int)s { showDebugAlert(@"🎬 測試成功", @"廣告順利播放！"); }
- (void)unityAdsShowFailed:(NSString *)p withError:(int)e withMessage:(NSString *)m { showDebugAlert(@"🔴 播放失敗", m); }
- (void)unityAdsShowStart:(NSString *)p {}
- (void)unityAdsShowClick:(NSString *)p {}

- (void)startRadar {
    [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                for (UIView *subview in window.subviews) {
                    NSString *txt = [UnityAdsHelper extractAllTextFromView:subview];
                    if ([txt containsString:@"WARNING"] && [txt containsString:@"tampered with"]) {
                        subview.hidden = YES;
                        [subview removeFromSuperview];
                    }
                }
            }
        });
    }];
}

+ (NSString *)extractAllTextFromView:(UIView *)view {
    NSMutableString *fullText = [NSMutableString string];
    if ([view isKindOfClass:[UILabel class]]) [fullText appendFormat:@"%@ ", ((UILabel *)view).text];
    for (UIView *subview in view.subviews) [fullText appendString:[self extractAllTextFromView:subview]];
    return fullText;
}
@end

// ==========================================
// 🚀 注入點
// ==========================================
%ctor {
    // 1. 綁定不死神盾
    struct rebind_msg h[] = {
        {"exit", (void *)my_exit, (void **)&orig_exit},
        {"kill", (void *)my_kill, (void **)&orig_kill}
    };
    rebind_symbols(h, 2);
    
    // 🌟 核心路徑修改：指向根目錄 ( / )
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *frameworkPath = [bundlePath stringByAppendingPathComponent:@"UnityAds.framework/UnityAds"];
    void *handle = dlopen(frameworkPath.UTF8String, RTLD_NOW);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[UnityAdsHelper sharedInstance] startRadar];
        Class unityCls = NSClassFromString(@"UnityAds");
        if (unityCls) {
            [unityCls initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
        } else {
            showDebugAlert(@"🔴 致命錯誤", @"根目錄找不到 UnityAds.framework！請檢查 ESign 設定。");
        }
        
        dispatch_after(dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            isTenSecondTimerExpired = YES; 
            [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
        }));
    }];
}
