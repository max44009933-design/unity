#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>

// ==========================================
// 🔴 配置區 (正式上線賺錢版)
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; // 原本的啟動廣告
NSString *const myInterstitialId = @"Interstitial_iOS"; // 🌟 新增：返回時的插頁廣告

static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;
static BOOL isInterstitialReady = NO; // 🌟 新增：追蹤返回廣告是否就緒

// ==========================================
// 🛠️ 抓取頂層畫面神器 (播放廣告必備)
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

// ==========================================
// 🌟 廣告助手 + 無敵防護雷達
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)tryShowReturnInterstitial; // 🌟 新增：嘗試播放返回廣告
- (void)startRadar;
- (void)scanAndWipe:(UIView *)view; 
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

// --- 🌟 冷卻時間檢查邏輯 (修改為 60 分鐘) ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 60 分鐘 = 3600 秒
    if (currentTime - lastShowTime >= 3600) {
        return YES;
    }
    
    int remainingMins = (3600 - (currentTime - lastShowTime)) / 60;
    NSLog(@"[IPA918] ⏳ 返回廣告冷卻中... 剩餘約 %d 分鐘", remainingMins);
    return NO;
}

- (void)recordInterstitialShowTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    [defaults setDouble:currentTime forKey:@"IPA918_LastReturnAdTime"];
    [defaults synchronize];
}

// --- UnityAds 廣告邏輯 (靜默除錯) ---
- (void)initializationComplete {
    NSLog(@"[IPA918] ✅ UnityAds 初始化成功！");
    // 同時預載兩種廣告
    [UnityAds load:myAdUnitId loadDelegate:self];
    [UnityAds load:myInterstitialId loadDelegate:self]; 
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 UnityAds 初始化失敗: %@", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] ✅ 廣告下載完成: %@", placementId);
    
    if ([placementId isEqualToString:myAdUnitId]) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; 
    } else if ([placementId isEqualToString:myInterstitialId]) {
        isInterstitialReady = YES; // 返回廣告準備就緒
    }
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告載入失敗 (%@): %@", placementId, message);
    if ([placementId isEqualToString:myAdUnitId]) {
        isAdReadyToShow = NO;
    } else if ([placementId isEqualToString:myInterstitialId]) {
        isInterstitialReady = NO;
    }
}

// 原本的 10 秒啟動廣告邏輯
- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            NSLog(@"[IPA918] 🎬 啟動條件達成，開始播放首頁廣告！");
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        }
    }
}

// 🌟 新增：返回時觸發的廣告邏輯
- (void)tryShowReturnInterstitial {
    // 1. 先檢查是否過了 60 分鐘冷卻期
    if ([self canShowReturnInterstitial]) {
        // 2. 檢查廣告載好了沒
        if (isInterstitialReady) {
            UIViewController *topController = getTopViewController();
            if (topController) {
                NSLog(@"[IPA918] 🎬 觸發背景返回廣告！");
                [UnityAds show:topController placementId:myInterstitialId showDelegate:self];
            }
        } else {
            NSLog(@"[IPA918] ⏳ 返回廣告尚未 Ready，嘗試重新載入...");
            [UnityAds load:myInterstitialId loadDelegate:self];
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    NSLog(@"[IPA918] 💰 廣告播放完畢: %@", placementId);
    
    // 如果播放的是返回廣告，紀錄時間並重新載入下一檔
    if ([placementId isEqualToString:myInterstitialId]) {
        NSLog(@"[IPA918] ⏱️ 記錄播放時間，啟動 60 分鐘冷卻機制");
        [self recordInterstitialShowTime];
        isInterstitialReady = NO;
        [UnityAds load:myInterstitialId loadDelegate:self]; // 先把下一檔拉下來備用
    }
}

- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告播放失敗 (%@): %@", placementId, message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

// --- 🎯 無敵防護雷達：默默粉碎隱形觸控牆 ---
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
                
                UIView *shield = view;
                while (shield.superview) {
                    UIView *parent = shield.superview;
                    NSString *parentClass = NSStringFromClass([parent class]);
                    
                    if ([parent isKindOfClass:[UIWindow class]]) break;
                    if (parent == parent.window.rootViewController.view) break;
                    if ([parentClass containsString:@"Unity"]) break;
                    if ([parentClass containsString:@"Transition"]) break;
                    if ([parentClass containsString:@"DropShadow"]) break;
                    
                    shield = parent;
                }
                
                NSLog(@"[IPA918] 🎯 默默拔除外掛警告窗！");
                shield.hidden = YES;
                shield.userInteractionEnabled = NO;
                shield.alpha = 0.0;
                shield.frame = CGRectMake(-9999, -9999, 1, 1); 
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
// 🚀 核心注入點
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！等待啟動...");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"[IPA918] 📢 啟動廣播到達！");
        
        // 🌟 啟動雷達防護
        [[UnityAdsHelper sharedInstance] startRadar];
        
        // 🌟 初始化廣告
        [UnityAds initialize:myGameId testMode:NO initializationDelegate:[UnityAdsHelper sharedInstance]];
        
        // 🌟 10 秒倒數播放
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTenSecondTimerExpired = YES; 
            if (isAdReadyToShow) {
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            }
        });
        
    }];
    
    // 2. 🌟 新增：監聽 App 從背景切換回前景
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[IPA918] 🔄 玩家從背景返回遊戲！");
        [[UnityAdsHelper sharedInstance] tryShowReturnInterstitial];
    }];
}
