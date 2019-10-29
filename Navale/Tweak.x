/*
 * Tweak.x
 * Navale
 *
 * Created by Zachary Thomas Paul <LacertosusThemes@gmail.com> on 4/30/2019.
 * Copyright © 2019 LacertosusDeus <LacertosusThemes@gmail.com>. All rights reserved.
 */
#import <Cephei/HBPreferences.h>
#import "NavaleClasses.h"
#import "iOSPalette/Palette.h"
#import "iOSPalette/UIImage+Palette.h"
#import "ColorFlowAPI.h"
#import "libcolorpicker.h"
#define LD_DEBUG NO
extern CFArrayRef CPBitmapCreateImagesFromData(CFDataRef cpbitmap, void*, int, void*);

  //Vars
  CAGradientLayer *gradientLayer;
  SBFloatingDockPlatterView *floatingDockView;
  SBDockView *dockView;
  UIColor *colorOne;
  UIColor *colorTwo;

  //Prefs
  static BOOL usingFloatingDock;
  static BOOL useColorFlow;
  static NSInteger gradientDirection;
  static CGFloat dockAlpha;
  static NSString *colorOneString;
  static NSString *colorTwoString;

  /*
   * Regular Dock
   */
%group RegularDockHooks
%hook SBDockView
%property (nonatomic, copy) UIColor *primaryColor;
%property (nonatomic, copy) UIColor *secondaryColor;

  -(id)initWithDockListView:(id)arg1 forSnapshot:(BOOL)arg2 {
    if(useColorFlow) {
      [[%c(CFWSBMediaController) sharedInstance] addColorDelegate:self];
    }
    return dockView = %orig;
  }

  -(void)layoutSubviews {
    %orig;

      //Get background view and set alpha
    SBWallpaperEffectView *backgroundView = [self valueForKey:@"_backgroundView"];
    backgroundView.blurView.hidden = YES;
    backgroundView.alpha = dockAlpha;

      //Create gradient layer
    if(!gradientLayer) {
      gradientLayer = [CAGradientLayer layer];
    }

      //Set gradient layer orientation
    if(gradientDirection == verticle) {
      gradientLayer.startPoint = CGPointMake(0.5, 0.0);
      gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    } if(gradientDirection == horizontal) {
      gradientLayer.startPoint = CGPointMake(0.0, 0.5);
      gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    }

    if(self.primaryColor == nil || self.secondaryColor == nil) {
      colorOne = LCPParseColorString(colorOneString, @"#3A7BD5");
      colorTwo = LCPParseColorString(colorTwoString, @"#3A6073");
    } else {
      colorOne = self.primaryColor;
      colorTwo = self.secondaryColor;
    }

    gradientLayer.colors = @[(id)colorOne.CGColor, (id)colorTwo.CGColor];
    gradientLayer.frame = backgroundView.bounds;
    [backgroundView.layer insertSublayer:gradientLayer atIndex:6];
  }

%new
  -(void)songAnalysisComplete:(MPModelSong *)song artwork:(UIImage *)artwork colorInfo:(CFWColorInfo *)colorInfo {
    self.primaryColor = colorInfo.primaryColor;
    self.secondaryColor = colorInfo.secondaryColor;
    [self layoutSubviews];
  }

%new
  -(void)songHadNoArtwork:(MPModelSong *)song {
    self.primaryColor = nil;
    self.secondaryColor = nil;
    [self layoutSubviews];
  }
%end
%end

  /*
   * Floating Dock
   */
%group FloatingDockHooks
%hook SBFloatingDockPlatterView
%property (nonatomic, copy) UIColor *primaryColor;
%property (nonatomic, copy) UIColor *secondaryColor;

  -(id)initWithReferenceHeight:(double)arg1 maximumContinuousCornerRadius:(double)arg2 {
    if(useColorFlow) {
      [[%c(CFWSBMediaController) sharedInstance] addColorDelegate:self];
    }
    return floatingDockView = %orig;
  }

  -(void)layoutSubviews {
    %orig;

      //Get background view and set alpha
    _UIBackdropView *backgroundView = [self valueForKey:@"_backgroundView"];
    backgroundView.backdropEffectView.hidden = YES;
    backgroundView.alpha = dockAlpha;

      //Create gradient layer
    if(!gradientLayer) {
      gradientLayer = [CAGradientLayer layer];
    }

      //Set gradient layer orientation
    if(gradientDirection == verticle) {
      gradientLayer.startPoint = CGPointMake(0.5, 0.0);
      gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    } if(gradientDirection == horizontal) {
      gradientLayer.startPoint = CGPointMake(0.0, 0.5);
      gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    }

    if(self.primaryColor == nil || self.secondaryColor == nil) {
      colorOne = LCPParseColorString(colorOneString, @"#3A7BD5");
      colorTwo = LCPParseColorString(colorTwoString, @"#3A6073");
    } else {
      colorOne = self.primaryColor;
      colorTwo = self.secondaryColor;
    }

    gradientLayer.colors = @[(id)colorOne.CGColor, (id)colorTwo.CGColor];
    gradientLayer.frame = backgroundView.bounds;
    gradientLayer.cornerRadius = [self maximumContinuousCornerRadius];
    [backgroundView.layer insertSublayer:gradientLayer atIndex:0];
  }

%new
  -(void)songAnalysisComplete:(MPModelSong *)song artwork:(UIImage *)artwork colorInfo:(CFWColorInfo *)colorInfo {
    self.primaryColor = colorInfo.primaryColor;
    self.secondaryColor = colorInfo.backgroundColor;
    [self layoutSubviews];
  }

%new
  -(void)songHadNoArtwork:(MPModelSong *)song {
    self.primaryColor = nil;
    self.secondaryColor = nil;
    [self layoutSubviews];
  }
%end
%end

static void updateDock() {
  if(usingFloatingDock) {
    [floatingDockView layoutSubviews];
  } else {
    [dockView layoutSubviews];
  }
}

static void colorsFromWallpaper() {
  UIImage *homeWallpaper;
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/User/Library/SpringBoard/OriginalHomeBackground.cpbitmap"]) {
    NSData *homeData = [NSData dataWithContentsOfFile:@"/User/Library/SpringBoard/OriginalHomeBackground.cpbitmap"];
    CFArrayRef homeArrayRef = CPBitmapCreateImagesFromData((__bridge CFDataRef)homeData, NULL, 1, NULL);
    NSArray *homeArray = (__bridge NSArray*)homeArrayRef;
    homeWallpaper = [[UIImage alloc] initWithCGImage:(__bridge CGImageRef)(homeArray[0])];
    CFRelease(homeArrayRef);
  } else {
    NSData *homeData = [NSData dataWithContentsOfFile:@"/User/Library/SpringBoard/OriginalLockBackground.cpbitmap"];
    CFArrayRef homeArrayRef = CPBitmapCreateImagesFromData((__bridge CFDataRef)homeData, NULL, 1, NULL);
    NSArray *homeArray = (__bridge NSArray*)homeArrayRef;
    homeWallpaper = [[UIImage alloc] initWithCGImage:(__bridge CGImageRef)(homeArray[0])];
    CFRelease(homeArrayRef);
  }

  HBPreferences *preferences = [HBPreferences preferencesForIdentifier:@"com.lacertosusrepo.navaleprefs"];
  [homeWallpaper getPaletteImageColorWithMode:VIBRANT_PALETTE | LIGHT_VIBRANT_PALETTE | DARK_VIBRANT_PALETTE withCallBack:^(PaletteColorModel *recommendColor, NSDictionary *allModeColorDic, NSError *error) {
    [preferences setObject:recommendColor.imageColorString forKey:@"colorOneString"];
  }];
  [homeWallpaper getPaletteImageColorWithMode:MUTED_PALETTE | LIGHT_MUTED_PALETTE | DARK_MUTED_PALETTE withCallBack:^(PaletteColorModel *recommendColor, NSDictionary *allModeColorDic, NSError *error) {
    [preferences setObject:recommendColor.imageColorString forKey:@"colorTwoString"];
  }];

}

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)colorsFromWallpaper, CFSTR("com.lacertosusrepo.navaleprefs-colorsFromWallpaper"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

  HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:@"com.lacertosusrepo.navaleprefs"];
  [preferences registerBool:&usingFloatingDock default:NO forKey:@"usingFloatingDock"];
  [preferences registerBool:&useColorFlow default:NO forKey:@"useColorFlow"];
  [preferences registerInteger:&gradientDirection default:horizontal forKey:@"gradientDirection"];
  [preferences registerFloat:&dockAlpha default:1.0 forKey:@"dockAlpha"];

  [preferences registerObject:&colorOneString default:@"#3A7BD5" forKey:@"colorOneString"];
  [preferences registerObject:&colorTwoString default:@"#3A6073" forKey:@"colorTwoString"];

  [preferences registerPreferenceChangeBlock:^{
    updateDock();
  }];

  if(usingFloatingDock) {
    %init(FloatingDockHooks);
  } else {
    %init(RegularDockHooks);
  }
}