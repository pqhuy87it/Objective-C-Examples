//
//  FaceDetectionComponent.h
//  DemoFaceDetection
//
//  Created by Phineas.Huang on 16/03/2018.
//  Copyright © 2018 sunxiaoshan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FaceDetectionComponent;
@protocol FaceDetectionComponentDelegate<NSObject>

- (void)FaceDetectionComponentIsDetectedFace:(FaceDetectionComponent *)component;
- (void)FaceDetectionComponentIsNoDetectedFace:(FaceDetectionComponent *)component;
- (void)FaceDetectionComponentError:(FaceDetectionComponent *)component error:(NSError *)error;

@end

@interface FaceDetectionComponent : NSObject

@property (weak, nonatomic) id<FaceDetectionComponentDelegate> delegate;
@property (nonatomic, strong) UIImage *borderImage;

- (instancetype)initWithPreviewView:(UIView *)previewView;
- (void)setupAVCapture;
- (void)setBorderImage:(UIImage *)image;

@end
