//
//  ScreensaverView.m
//  Screensaver
//
//  Created by austin on 09.04.26.
//

#if __has_include(<ScreenSaver/ScreenSaver.h>)
#import <ScreenSaver/ScreenSaver.h>
#import <AVFoundation/AVFoundation.h>

@interface ScreensaverView : ScreenSaverView
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) id loopObserver;
@end

@implementation ScreensaverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        [self setupVideoIfAvailable];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    [self.player play];
}

- (void)stopAnimation
{
    [self.player pause];
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    self.playerLayer.frame = self.bounds;
}

- (void)dealloc
{
    if (self.loopObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.loopObserver];
    }
}

- (void)setupVideoIfAvailable
{
    NSURL *url = [self resolvedVideoURL];
    if (url == nil) {
        return;
    }

    self.wantsLayer = YES;

    self.player = [AVPlayer playerWithURL:url];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.playerLayer];

    __weak typeof(self) weakSelf = self;
    self.loopObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                    object:self.player.currentItem
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(__unused NSNotification *note) {
                    [weakSelf.player seekToTime:kCMTimeZero];
                    [weakSelf.player play];
                }];

    [self.player play];
}

- (NSURL *)resolvedVideoURL
{
    NSString *sharedPath = @"/Users/Shared/TinWallpaper/currentVideo.mp4";
    if ([[NSFileManager defaultManager] fileExistsAtPath:sharedPath]) {
        return [NSURL fileURLWithPath:sharedPath];
    }

    NSString *path = [@"~/Library/Application Support/TinWallpaper/selectedVideoURL.txt"
        stringByExpandingTildeInPath];
    NSString *value = [NSString stringWithContentsOfFile:path
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 0) {
        if ([trimmed hasPrefix:@"/"]) {
            NSURL *fileURL = [NSURL fileURLWithPath:trimmed];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
                return fileURL;
            }
        }

        NSURL *url = [NSURL URLWithString:trimmed];
        if (url != nil) {
            if (url.isFileURL) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                    return url;
                }
            } else {
                return url;
            }
        }
    }

    NSString *legacyManagedPath = [@"~/Library/Application Support/TinWallpaper/currentVideo.mp4"
        stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:legacyManagedPath]) {
        return [NSURL fileURLWithPath:legacyManagedPath];
    }

    return nil;
}

@end
#endif
