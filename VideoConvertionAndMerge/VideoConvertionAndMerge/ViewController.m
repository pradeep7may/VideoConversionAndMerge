//
//  ViewController.m
//  VideoConvertionAndMerge
//
//  Created by Pradeep Kumar Yadav on 14/04/15.
//  Copyright (c) 2015 Pradeep Kumar Yadav. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark IBActions

- (IBAction)convertVideoButtonClicked:(id)sender
{
  NSURL *videoPath = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"part1" ofType:@"mov"]];
  [self convertVideoToMP4:videoPath];
}

- (IBAction)mergeVideoButtonClicked:(id)sender
{
  NSString* path1 = [[NSBundle mainBundle]pathForResource:@"CheeziPuffs"ofType:@"mov"];
  
  NSString* path2 = [[NSBundle mainBundle]pathForResource:@"part1"ofType:@"mov"];
  [self mergeTwoVideosWithFirstFile:path1 secondVideo:path2];
}


#pragma mark ----------- mp4ConversionMethod ------------

-(void)convertVideoToMP4:(NSURL*)videoURL
{
  // Create the asset url with the video file
  AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
  NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];

  // Check if video is supported for conversion or not
  if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality])
    
  {
  //Create Export session
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetLowQuality];
  //Creating temp path to ssave the converted video
    NSString* documentsDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* myDocumentPath= [documentsDirectory stringByAppendingPathComponent:@"temp.mp4"];
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:myDocumentPath];
    //Check if the file already exists then remove the previous file
    if ([[NSFileManager defaultManager]fileExistsAtPath:myDocumentPath])
    {
      [[NSFileManager defaultManager]removeItemAtPath:myDocumentPath error:nil];
    }
    
    exportSession.outputURL = url;
    //set the output file format if you want to make it in other file format (ex .3gp)
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
      
      switch ([exportSession status])
      {
        case AVAssetExportSessionStatusFailed:
        {
          dispatch_sync(dispatch_get_main_queue(), ^{

            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[[exportSession error] localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
          });
          break;
        }
          
        case AVAssetExportSessionStatusCancelled:
          NSLog(@"Export canceled");
          break;
        case AVAssetExportSessionStatusCompleted:
        {
          //Video conversion finished
          NSLog(@"Successful!");
          dispatch_sync(dispatch_get_main_queue(), ^{
            NSString *mp4Path = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@.mp4", @"temp"];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Video converted successfully"
                                                            message:mp4Path
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
          });
        }
          break;
        default:
          break;
      }
    }];
  }
  else
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Video file not supported."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
  }
}


- (void) mergeTwoVideosWithFirstFile:(NSString*)path1 secondVideo:(NSString*)path2
{
  //Create the AVmutable composition to add tracks
  AVMutableComposition* composition = [[AVMutableComposition alloc]init];
  //Create assests url for first video
  AVURLAsset* video1 = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:path1]options:nil];
  //Create assests url for second video
  AVURLAsset* video2 = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:path2]options:nil];
  
  //Create the mutable composition track with video media type. You can also create the tracks depending on your need if you want to merge audio files and other stuffs.
  AVMutableCompositionTrack* composedTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
  //Set the video time ranges of both the videos in composition
  [composedTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, video1.duration)
   ofTrack:[[video1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
   atTime:kCMTimeZero error:nil];
  
  [composedTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, video2.duration)
   ofTrack:[[video2 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
   atTime:video1.duration error:nil];
  
  // Create a temp path to save the video in the documents dir.
  
  NSString* documentsDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  
  NSString* myDocumentPath= [documentsDirectory stringByAppendingPathComponent:@"merge_video.mp4"];
  
  NSURL *url = [[NSURL alloc] initFileURLWithPath: myDocumentPath];
  //Check if the file exists then delete the old file to save the merged video file.
  if([[NSFileManager defaultManager]fileExistsAtPath:myDocumentPath])
  {
    [[NSFileManager defaultManager]removeItemAtPath:myDocumentPath error:nil];
  }
  // Create the export session to merge and save the video 
  AVAssetExportSession*exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
  
  exporter.outputURL=url;
  
  exporter.outputFileType=@"com.apple.quicktime-movie";
  
  exporter.shouldOptimizeForNetworkUse=YES;
  
  [exporter exportAsynchronouslyWithCompletionHandler:^{
   
    switch([exporter status])
    {
      case AVAssetExportSessionStatusFailed:
        NSLog(@"Failed to export video");
        break;
      case AVAssetExportSessionStatusCancelled:
        NSLog(@"export cancelled");
        break;
      case AVAssetExportSessionStatusCompleted:
        //Here you go you have got the merged video :)
        NSLog(@"Merging completed");

        break;
      default:
  
        break;
    }

}];
  
}


@end
