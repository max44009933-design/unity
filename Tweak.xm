#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "fishhook.h" // 🌟 引入底層 Hook 庫防護

// ==========================================
// 🛡️ 不死神盾：沒收遊戲的自殺權力
// ==========================================
static void (*orig_exit)(int);
void my_exit(int s) { NSLog(@"[IPA918] 🛡️ 攔截到 exit(%d)，強行裝死中...", s); }

static int (*orig_kill)(pid_t, int);
int my_kill(pid_t p, int s) { NSLog(@"[IPA918] 🛡️ 攔截到 kill，拒絕自殺！"); return 0; }

// ==========================================
// 🔴 配置區 
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 

static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

// ==========================================
// 🛠️ 抓取頂層畫面 & 彈窗提示神器
// ==========================================
static UIViewController *getTopViewController() {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [[UIApplication sharedApplication] windows].firstObject;
    }
    
    UIViewController *topController = keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
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
// 🌟 廣告助手 + 你的無敵防護雷達
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)startRadar;
- (void)scanAndWipe:(UIView *)view; // 宣告掃描方法
@end

@implementation UnityAdsHelper

+ (instancetype)sharedInstance {
    static UnityAdsHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[UnityAdsHelper alloc] init];
    });
    return sharedInstance;
}

// --- UnityAds 廣告邏輯 ---
- (void)initializationComplete {
    [UnityAds load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 初始化失敗", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    isAdReadyToShow = YES;
    [self tryTriggerBulldozeShow]; 
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 廣告載入失敗", [NSString stringWithFormat:@"單元: %@\n原因: %@", placementId, message]);
    isAdReadyToShow = NO;
}

- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        } else {
            showDebugAlert(@"🔴 播放失敗", @"找不到最頂層的畫面來播放廣告");
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    showDebugAlert(@"🎬 測試成功", @"廣告順利播放完畢！");
}
- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 播放失敗", message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

// --- 🎯 你的無敵防護雷達：動態偵測 + 粉碎隱形觸控牆 ---
- (void)startRadar {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    NSArray *windows = [[UIApplication sharedApplication].windows copy];
                    for (UIWindow *window in windows) { 
                        NSString *windowClass = NSStringFromClass([window class]);
                        if ([windowClass containsString:@"Remote"] || 
                            [windowClass containsString:@"Keyboard"] || 
                            [windowClass containsString:@"TextEffects"] || 
                            [windowClass containsString:@"Host"] || 
                            [windowClass containsString:@"Secure"]) {
                            continue; 
                        }
                        [self scanAndWipe:window]; 
                    }
                } @catch (NSException *e) {}
            });
        }];
    });
}

- (void)scanAndWipe:(UIView *)view {
    @try {
        if (!view || view.hidden) return; 

        NSString *txt = nil;
        if ([view isKindOfClass:[UILabel class]]) txt = ((UILabel *)view).text;
        else if ([view isKindOfClass:[UIButton class]]) txt = ((UIButton *)view).titleLabel.text;

        if (txt && txt.length > 0) {
            if ([txt containsString:@"tampered"] || [txt containsString:@"injected"] || 
                [txt isEqualToString:@"Understood"] || [txt isEqualToString:@"WARNING"]) {
                
                // 🌟 觸控失靈修復：一路往上找，找出外掛的「全螢幕隱形玻璃」！
                UIView *shield = view;
                while (shield.superview) {
                    UIView *parent = shield.superview;
                    NSString *parentClass = NSStringFromClass([parent class]);
                    
                    // 🛑 邊界防護：碰到遊戲的核心畫布或系統母體，立刻停止，保護遊戲本體！
                    if ([parent isKindOfClass:[UIWindow class]]) break;
                    if (parent == parent.window.rootViewController.view) break;
                    if ([parentClass containsString:@"Unity"]) break;
                    if ([parentClass containsString:@"Transition"]) break;
                    if ([parentClass containsString:@"DropShadow"]) break;
                    
                    shield = parent;
                }
                
                NSLog(@"[IPA918] 🎯 抓到自定義警告窗！粉碎隱形玻璃！");
                // 🌟 將外掛的隱形玻璃徹底連根拔起！解放底層的遊戲觸控！
                shield.hidden = YES;
                shield.userInteractionEnabled = NO;
                shield.alpha = 0.0;
                shield.frame = CGRectMake(-9999, -9999, 1, 1); // 丟到畫面外
                [shield removeFromSuperview];
            }
        }
        
        NSArray *subs = [view.subviews copy];
        for (UIView *sub in subs) {
            [self scanAndWipe:sub];
        }
    } @catch (NSException *e) {}
}

@end

// ==========================================
// 🚀 核心注入點：監聽系統啟動廣播
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！綁定不死神盾...");
    
    // 1. 綁定不死神盾
    struct rebind_msg h[] = {
        {"exit", (void *)my_exit, (void **)&orig_exit},
        {"kill", (void *)my_kill, (void **)&orig_kill}
    };
    rebind_symbols(h, 2);
    
    // 2. 監聽「App 啟動完成」的系統廣播
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"[IPA918] 📢 收到啟動廣播！開始執行 UnityAds 邏輯");
        
        // 🌟 啟動你的無敵彈窗抹除雷達
        [[UnityAdsHelper sharedInstance] startRadar];
        
        // 1. 初始化 UnityAds
        [UnityAds initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
        
        // 2. 開始 10 秒倒數計時，時間到播放廣告
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTenSecondTimerExpired = YES; 
            
            if (!isAdReadyToShow) {
                showDebugAlert(@"⏱️ 10秒到了", @"廣告正在努力下載中，如果一直沒出來可能是網路或後台設定問題。");
            } else {
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            }
        });
        
    }];
}
