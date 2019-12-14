//
//  ViewController.m
//  camera-calibration
//
//  Created by Takahiro Horikawa on 2016/02/25.
//  Copyright © 2016年 Takahiro Horikawa. All rights reserved.
//

#import "Calibrator.hpp"
#import "CalibrationController.h"
#import "VideoSource.h"
#import "BGRAVideoFrame.h"

@interface CalibrationController ()<VideoSourceDelegate>

@property (strong, nonatomic) VideoSource * videoSource;
@property (nonatomic) Calibrator * calibrator;

@end

@implementation CalibrationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.videoSource = [[VideoSource alloc] initWithPreset:AVCaptureSessionPreset1920x1080];
    self.videoSource.delegate = self;
    // [self.videoSource setPreview:self.imageView];
    [self.videoSource startWithDevicePosition:AVCaptureDevicePositionBack];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *filePath = [directory stringByAppendingPathComponent:[NSString stringWithUTF8String:"camera_parameter.yml"]];
    self.calibrator = new Calibrator([filePath UTF8String]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartPressed:(id)sender {
    self.calibrator->startCapturing();
}

#pragma mark - VideoSourceDelegate
-(void)frameReady:(BGRAVideoFrame) frame
{
    // Start upload new frame to video memory in main thread
    dispatch_sync( dispatch_get_main_queue(), ^{
//        [self.visualizationController updateBackground:frame];
    });
    
    // And perform processing in current thread
    cv::Mat m = self.calibrator->processFrame(frame);
    UIImage* image = [self UIImageFromCVMat:m];
    image = [CalibrationController resizedImage:image width:480 height:240];
    
    // When it's done we query rendering from main thread
    dispatch_async( dispatch_get_main_queue(), ^{
//        NSLog(@"main");
        self.imageView.image = image;
        [self.imageView setNeedsDisplay];
    });
}

+ (UIImage *)resizedImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    [image drawInRect:CGRectMake(0.0, 0.0, width, height)];
    
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

-(UIImage*) UIImageByFrame:(BGRAVideoFrame) frame
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data =
    [NSData dataWithBytes:frame.data length:frame.height*frame.stride];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(
                                        frame.width, frame.height,
                                        8, 4*8, frame.stride,
                                        colorSpace, kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return ret;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat) cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length: cvMat.step.p[0]* cvMat.rows];

    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Little | (
            cvMat.elemSize() == 3? kCGImageAlphaNone : kCGImageAlphaNoneSkipFirst
        );
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(
        cvMat.cols,                 //width
        cvMat.rows,                 //height
        8,                          //bits per component
        8 * cvMat.elemSize(),       //bits per pixel
        cvMat.step[0],              //bytesPerRow
        colorSpace,                 //colorspace
        bitmapInfo,                 // bitmap info
        provider,                   //CGDataProviderRef
        NULL,                       //decode
        false,                      //should interpolate
        kCGRenderingIntentDefault   //intent
    );

    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}


@end
