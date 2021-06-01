//
//  ViewController.m
//  DemoFaceDetection
//
//  Created by Phineas.Huang on 16/03/2018.
//  Copyright © 2018 sunxiaoshan. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "FaceDetectionComponent.h"

@interface ViewController ()
<
UIGestureRecognizerDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate
>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (nonatomic, strong) FaceDetectionComponent *faceDetectionComponent;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.faceDetectionComponent = [[FaceDetectionComponent alloc] initWithPreviewView:self.previewView];
    [self.faceDetectionComponent setupAVCapture];
    [self.faceDetectionComponent setBorderImage:[UIImage imageNamed:@"border"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
