#import <UIKit/UIKit.h>
#import <UnityAds/UnityAds.h>

// 🔴 你的專屬 ID (保持不變)
NSString *const myGameId = @"5059216";
NSString *const myAdUnitId = @"test0318";

// ==========================================
// 🌟 新增功能：專屬的廣告聯絡人 (適應新版 SDK)
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
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

// 1. 初始化成功的回報
- (void)initializationComplete {
    NSLog(@"[IPA918] 🟢 Unity Ads 初始化成功！正在幫你預先下載廣告...");
    // 初始化成功後，馬上呼叫 load 準備廣告
    [UnityAds load:myAdUnitId loadDelegate:self];
}

// 2. 初始化失敗的回報
- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 Unity Ads 初始化失敗: %@", message);
}

// 3. 廣告影片下載完成的回報
- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] 🟢 廣告影片已經下載完畢，隨時可以發射！ ID: %@", placementId);
}

// 4. 廣告影片下載失敗的回報
- (void)unityAdsAdFailedToLoad:(NSString *)placementId
                     withError:(UnityAdsLoadError)error
                   withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告下載失敗: %@", message);
}

// 5. 各種播放狀態的回報 (⚠️ 這裡完美修正了 withFinishState ！)
- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    NSLog(@"[IPA918] 🎬 廣告順利播完啦！可以發獎勵了！");
}
- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告播放發生錯誤: %@", message);
}
- (void)unityAdsShowStart:(NSString *)placementId {
    NSLog(@"[IPA918] 🎬 廣告開始播放");
}
- (void)unityAdsShowClick:(NSString *)placementId {
    NSLog(@"[IPA918] 👆 用戶點擊了廣告");
}
@end

// ==========================================
// 🚀 原有功能：攔截 App 啟動與畫面載入 (保留原本的 5 秒倒數邏輯)
// ==========================================

%hook UIApplication
// App 啟動時，第一時間喚醒 Unity Ads SDK
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    %orig; 
    
    NSLog(@"[IPA918] 啟動 Unity Ads 引擎...");
    [UnityAds initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
    
    return YES;
}
%end

%hook UIViewController
// 攔截 App 的畫面載入
- (void)viewDidAppear:(BOOL)animated {
    %orig; 
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[IPA918] ⏱️ 畫面載入完畢，開始倒數 5 秒...");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"[IPA918] 🎯 5 秒時間到！嘗試強制彈出廣告 ID: %@", myAdUnitId);
            [UnityAds show:self placementId:myAdUnitId showDelegate:[UnityAdsHelper sharedInstance]];
            
        });
    });
}
%end
