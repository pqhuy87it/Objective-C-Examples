//
//  FaceDetectionComponent.m
//  DemoFaceDetection
//
//  Created by Phineas.Huang on 16/03/2018.
//  Copyright © 2018 sunxiaoshan. All rights reserved.
//

// Reference : https://www.icapps.com/blog/face-detection-core-image-live-video

#import "FaceDetectionComponent.h"

#define FACE_LAYER @"FaceLayer"
#define ENABLE_DEBUG_MODE 0

#import <AVFoundation/AVFoundation.h>

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface FaceDetectionComponent()
<
AVCaptureVideoDataOutputSampleBufferDelegate
>

@property (nonatomic) BOOL isUsingFrontFacingCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CIDetector *_faceDetector;
@property (strong, nonatomic) UIView *previewView;

@end

@implementation FaceDetectionComponent

#pragma mark - Class function

+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity
                          frameSize:(CGSize)frameSize
                       apertureSize:(CGSize)apertureSize {
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;

    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }

    CGRect videoBox;
    videoBox.size = size;
    if (size.width < frameSize.width) {
        videoBox.origin.x = (frameSize.width - size.width) / 2;
    } else {
        videoBox.origin.x = (size.width - frameSize.width) / 2;
    }

    if (size.height < frameSize.height) {
        videoBox.origin.y = (frameSize.height - size.height) / 2;
    } else {
        videoBox.origin.y = (size.height - frameSize.height) / 2;
    }

    return videoBox;
}

#pragma mark - Basic function

- (instancetype)initWithPreviewView:(UIView *)previewView {
    self = [super init];
    if (self) {
        self.previewView = previewView;
        [self setupData];
    }
    return self;
}

- (void)setupData {
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     CIDetectorAccuracyLow, CIDetectorAccuracy,
                                     nil];
    self._faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                      context:nil
                                      options:detectorOptions];
}

- (void)setupAVCapture {
    NSError *error = nil;

    // Select device
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    } else {
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    }

    AVCaptureDevice *device = [self findFrontCamera];
    if (nil == device) {
        self.isUsingFrontFacingCamera = NO;
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }

    // get the input device
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        session = nil;
        [self teardownAVCapture];
        if ([_delegate respondsToSelector:@selector(FaceDetectionComponentError:error:)]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate FaceDetectionComponentError:weakSelf error:error];
            });
        }
        return;
    }

    // add the input to the session
    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }

    // Make a video data output
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];

    // We want RGBA, both CoreGraphics and OpenGL work well with 'RGBA'
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.videoDataOutput setVideoSettings:rgbOutputSettings];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked

    self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];

    if ([session canAddOutput:self.videoDataOutput]) {
        [session addOutput:self.videoDataOutput];
    }

    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];

    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    self.previewLayer.backgroundColor = [[UIColor blackColor] CGColor];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    CALayer *rootLayer = [self.previewView layer];
    [rootLayer setMasksToBounds:YES];
    [self.previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:self.previewLayer];
    [session startRunning];
}

- (AVCaptureDevice *)findFrontCamera {
    AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionFront;
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            self.isUsingFrontFacingCamera = YES;
            return d;
        }
    }
    return nil;
}

- (void)teardownAVCapture {
    self.videoDataOutput = nil;
    if (self.videoDataOutputQueue) {
        self.videoDataOutputQueue = nil;
    }
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
}

- (UIImage *)getBorderImage {
#if( ENABLE_DEBUG_MODE )
    return [self getImageWithColor:[UIColor yellowColor]];
#else
    return self.borderImage;
#endif
}

- (void)drawFaces:(NSArray *)features
      forVideoBox:(CGRect)clearAperture
      orientation:(UIDeviceOrientation)orientation {
    NSArray *sublayers = [NSArray arrayWithArray:[self.previewLayer sublayers]];
    NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
    NSInteger featuresCount = [features count], currentFeature = 0;

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    for (CALayer *layer in sublayers) {
        if ([[layer name] isEqualToString:FACE_LAYER]) {
            [layer setHidden:YES];
        }
    }

    if (featuresCount == 0 || [self getBorderImage] == nil) {
        [CATransaction commit];
        if ([_delegate respondsToSelector:@selector(FaceDetectionComponentIsNoDetectedFace:)]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate FaceDetectionComponentIsNoDetectedFace:weakSelf];
            });
        }
        return;
    }

    CGSize parentFrameSize = [self.previewView frame].size;
    NSString *gravity = [self.previewLayer videoGravity];
    BOOL isMirrored = [self.previewLayer.connection isVideoMirrored];
    CGRect previewBox = [FaceDetectionComponent videoPreviewBoxForGravity:gravity
                                                        frameSize:parentFrameSize
                                                     apertureSize:clearAperture.size];

    for (CIFaceFeature *ff in features) {
        CGRect faceRect = [ff bounds];

        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;

        CGFloat widthScaleBy = previewBox.size.width / clearAperture.size.height;
        CGFloat heightScaleBy = previewBox.size.height / clearAperture.size.width;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;

        if (isMirrored) {
            faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
        } else {
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
        }

        CALayer *featureLayer = nil;

        while (!featureLayer && (currentSublayer < sublayersCount)) {
            CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
            if ([[currentLayer name] isEqualToString:FACE_LAYER]) {
                featureLayer = currentLayer;
                [currentLayer setHidden:NO];
            }
        }

        if (featureLayer == nil) {
            featureLayer = [[CALayer alloc] init];
            featureLayer.contents = (__bridge id)[self getBorderImage].CGImage;
            [featureLayer setName:FACE_LAYER];
            [self.previewLayer addSublayer:featureLayer];
            featureLayer = nil;
        }
        [featureLayer setFrame:faceRect];

        switch (orientation) {
            case UIDeviceOrientationPortrait:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
                break;
            case UIDeviceOrientationLandscapeRight:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
                break;
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationFaceDown:
            default:
                break; // leave the layer in its last known orientation
        }
        currentFeature++;
    }

    [CATransaction commit];

    if ([_delegate respondsToSelector:@selector(FaceDetectionComponentIsDetectedFace:)]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate FaceDetectionComponentIsDetectedFace:weakSelf];
        });
    }
}

- (NSNumber *)exifOrientation:(UIDeviceOrientation)orientation {
    int exifOrientation;
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT            = 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT            = 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };

    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (self.isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (self.isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    return [NSNumber numberWithInt:exifOrientation];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate function

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
    if (attachments) {
        CFRelease(attachments);
    }
    
    // make sure your device orientation is not locked.
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];

    NSDictionary *imageOptions = nil;

    imageOptions = [NSDictionary dictionaryWithObject:[self exifOrientation:curDeviceOrientation]
                                               forKey:CIDetectorImageOrientation];

    NSArray *features = [self._faceDetector featuresInImage:ciImage
                                                    options:imageOptions];

    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self drawFaces:features
            forVideoBox:cleanAperture
            orientation:curDeviceOrientation];
    });
}

#pragma mark - Debug

- (UIImage *)getImageWithColor:(UIColor *)color {
    CGRect r = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(r.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, r);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

@end


