//
//  ViewController.m
//  Live Photos
//
//  Created by ioshero on 1/23/16.
//  Copyright © 2016 ioshero. All rights reserved.
//

#import "ViewController.h"
#import "Live_Photos-Swift.h"
#import "SVProgressHUD.h"

@import Photos;
@import PhotosUI;
@import MobileCoreServices;

@interface ViewController () <PHLivePhotoViewDelegate>

@property (strong, nonatomic) NSURL *photoURL;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSArray *arrayNames;
@property (assign, nonatomic) NSInteger convetCount;
@property (strong, nonatomic) IBOutlet UILabel *labelPath;

@property BOOL livePhotoIsAnimating;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)loadData
{
    self.convetCount = 0;
    
    BOOL success;
    NSError* error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0]:nil;
    NSString *filePath = [basePath stringByAppendingPathComponent:@"Resource.plist"];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:&error];
    }
    
    NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:@"Resource" ofType:@"plist"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:filePath error:&error];
    if (!success) {
        NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    if (!success) {
        NSCAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    [SVProgressHUD show];
    
    self.arrayNames = [[NSMutableArray alloc] initWithArray:[NSMutableArray arrayWithContentsOfFile:filePath]];
    for (int i = 0 ; i < self.arrayNames.count ; i ++)
    {
        NSString *name = [self.arrayNames objectAtIndex:i];
        NSURL *videoURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"mp4"];
        [self loadVideo:name WithVideoURL:videoURL];
    }
}

- (NSURL*)getLivePhotURL:(NSString *)fileName {
    
    // find Documents directory
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    
    // append a file name to it
    documentsURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    return documentsURL;
}

- (NSString *)getOutPutPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *outputPath = [path stringByAppendingString:@"/"];
    
    return outputPath;
}

- (void)loadVideo:(NSString*)name WithVideoURL:(NSURL*)videoURL
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration) / 2, asset.duration.timescale);
    
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:time]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        NSData *data = UIImagePNGRepresentation([UIImage imageWithCGImage:image]);
        if (image && data)
        {
            NSURL *imageURL = [self getLivePhotURL:name];
            [data writeToURL:imageURL atomically:YES];
            
            NSString *imagePath = [imageURL path];
            NSString *moviePath = [videoURL path];
            NSString *outputPath = [self getOutPutPath];
            NSString *assetIdentifier = [NSUUID UUID].UUIDString;
            
            NSString *videoName = [NSString stringWithFormat:@"%@.MOV", name];
            NSString *imageName = [NSString stringWithFormat:@"%@.JPG", name];
            
            if ([[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:nil])
            {
                [[NSFileManager defaultManager] removeItemAtPath:[outputPath stringByAppendingString:imageName] error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:[outputPath stringByAppendingString:videoName] error:nil];
            }
        
            JPEG *jpeg = [[JPEG alloc] initWithPath:imagePath];
            [jpeg write:[outputPath stringByAppendingString:imageName] assetIdentifier:assetIdentifier];
            
            QuickTimeMov *mov = [[QuickTimeMov alloc] initWithPath:moviePath];
            [mov write:[outputPath stringByAppendingString:videoName] assetIdentifier:assetIdentifier];
            
            self.convetCount ++;
            if (self.convetCount == self.arrayNames.count)
            {
                [SVProgressHUD dismiss];
                self.labelPath.text = outputPath;
                NSLog(@"%@", outputPath);
            }
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)convertAction:(id)sender {
    [self loadData];
}

@end
