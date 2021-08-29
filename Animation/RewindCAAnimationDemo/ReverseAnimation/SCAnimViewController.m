//
//  SCAnimViewController.m
//  ReverseAnimation
//
//  Created by Michal Inger on 20/05/2014.
//  Copyright (c) 2014 StringCode Ltd. All rights reserved.
//

#import "SCAnimViewController.h"

@interface SCAnimViewController ()

@property (weak, nonatomic) IBOutlet UIView *animContainer;
@property (weak, nonatomic) IBOutlet UIView *animee;

@end

@implementation SCAnimViewController {
    CFTimeInterval _pausedTime;
    CFTimeInterval _addedTime;
}

#define animDuration 10;

- (void)rewindResumeLayer:(CALayer *)layer {

    CFTimeInterval pausedTime = [layer timeOffset];
    NSLog(@"Paused time %f",pausedTime);

    layer.speed = -1.0;
    NSLog(@"Layer time after speed - 1.0 : %f", [layer convertTime:CACurrentMediaTime() fromLayer:nil]);

    layer.timeOffset = 5.0;
    NSLog(@"Layer time after timeOffset 0.0 : %f", [layer convertTime:CACurrentMediaTime() fromLayer:nil]);

    layer.beginTime = 0.0;
    NSLog(@"Layer time after beginTime 0.0 : %f", [layer convertTime:CACurrentMediaTime() fromLayer:nil]);

    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = _addedTime;
    NSLog(@"Layer time after beginTime : %f", [layer convertTime:CACurrentMediaTime() fromLayer:nil]);
}

- (void)resumeLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

- (void)pauseLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    _pausedTime = pausedTime;
}
- (void)addAnimation {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    animation.fromValue = @(self.animee.bounds.size.height/2);
    animation.toValue = @(CGRectGetMaxY(self.view.bounds)-self.animee.bounds.size.height/2);
    animation.fillMode = kCAFillModeBoth;
    animation.removedOnCompletion = NO;
    animation.delegate = self;
    animation.duration = animDuration;
    
    [self.animee.layer addAnimation:animation forKey:@"position.y"];
    _addedTime = [self.animContainer.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    NSLog(@"Added anim time %f",_addedTime);
}

- (void)setCurrentOffSet:(NSNumber *)currentOffSet {
    self.animContainer.layer.timeOffset = _pausedTime + [currentOffSet floatValue] * animDuration;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    CALayer *layer = self.animContainer.layer;
    NSLog(@"Layer time after finished : %f", [layer convertTime:CACurrentMediaTime() fromLayer:nil]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Layer time after finished + 2 : %f", [layer convertTime:CACurrentMediaTime() fromLayer:nil]);

    });
}

- (IBAction)startAnimation:(id)sender {
    [self.animee.layer removeAllAnimations];
    self.animContainer.layer.speed = 1.0;
    [self addAnimation];
}

- (IBAction)pauseAnimation:(id)sender {
    [self pauseLayer:self.animContainer.layer];
}

- (IBAction)offsetAnimationToMiddle:(id)sender {
    [self setCurrentOffSet:@(0.5)];
}

- (IBAction)resumeAnimaiton:(id)sender {
    [self resumeLayer:self.animContainer.layer];
}

- (IBAction)rewindAnimation:(id)sender {
    [self rewindResumeLayer:self.animContainer.layer];
}

@end
