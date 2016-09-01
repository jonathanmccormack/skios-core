//
//  SKKitTestDownload.m
//  SKKit
//
//  Created by Pete Cole on 26/01/2015.
//  Copyright (c) 2015 SamKnows. All rights reserved.
//

#import "SKKitTest.h"

#import "../../skios-core/libcore/SKCore.h"
#import "../../skios-core/libcore/TestCore/SKClosestTargetTest.h"
#import "../../skios-core/libcore/TestCore/SKJHttpTest.h"

// Without this call, we can't use Swift classes from our objective C.
// The file is AUTO-GENERATED and is under the build folder, you won't find it in the project area!
// Note that *only* swift code marked with @objc is put in this file...
//#import <SKKit/SKKit-Swift.h>

//
// Test: Download
//
@interface SKKitTestDownload () <SKHttpTestDelegate>
@property SKHttpTest *mpDownloadTest;
@property double mLatestBitrateMbps1024Based;

@end

@implementation SKKitTestDownload

@synthesize mpDownloadTest;
@synthesize mProgressBlock;
@synthesize mLatestBitrateMbps1024Based;

- (instancetype)initWithDownloadTestDescriptor:(SKKitTestDescriptor_Download*)downloadTest {
  self = [super init];
  
  if (self) {
#ifdef _DEBUG
    NSLog(@"DEBUG: SKKitTestDownload - init");
#endif // _DEBUG
    
    mpDownloadTest = [[SKHttpTest alloc]
                      initWithTarget:downloadTest.mTarget
                      port:(int)downloadTest.mPort
                      file:downloadTest.mFile
                      isDownstream:YES
                      warmupMaxTime:downloadTest.mWarmupMaxTimeSeconds*1000000.0
                      warmupMaxBytes:0
                      TransferMaxTimeMicroseconds:downloadTest.mTransferMaxTimeSeconds*1000000.0
                      transferMaxBytes:0
                      nThreads:(int)downloadTest.mNumberOfThreads
                      HttpTestDelegate:self];
  }
  return self;
}

-(void)dealloc {
#ifdef DEBUG
  NSLog(@"DEBUG: SKKitTestDownload - dealloc");
#endif // DEBUG
  
  mpDownloadTest = nil;
}

- (void) start:(TSKDownloadTestProgressUpdate)progressBlock {
  self.mProgressBlock = progressBlock;
  [mpDownloadTest startTest];
}

// MARK: pragma SKKitTestProtocol

- (void) cancel {
  [mpDownloadTest cancel];
}

-(SKKitTestType) getTestType {
  return SKKitTestType_Download;
}

-(NSDictionary*) getTestResultsDictionary {
  SK_ASSERT(mpDownloadTest.outputResultsDictionary != nil);
  return mpDownloadTest.outputResultsDictionary;
}

-(NSString*) getTestResultValueString { // e.g. 17.2 Mbps
  
  if (mLatestBitrateMbps1024Based < 0) {
    return @"Failed";
  }
  
  return [SKGlobalMethods bitrateMbps1024BasedToString:mLatestBitrateMbps1024Based];
}


// TODO - capture data into a supplied JSON saver instance class, which must be extracted
// as a class from SKAppBehaviourDelegate ... and exported as a public SKKit class.
//-(void) saveToJSON {
//  NSLog(@"Download json: %@", mpDownloadTest.outputResultsDictionary);
//}

// MARK: pragma SKHttpTestDelegate

- (void)htdUpdateStatus:(TransferStatus)status
               threadId:(NSUInteger)threadId {
  
  switch (status) {
    case FAILED:
#ifdef DEBUG
  NSLog(@"DEBUG: SKKitTestDownload - failed!");
#endif // DEBUG
      mLatestBitrateMbps1024Based = -1.0;
      mProgressBlock(100.0, -1.0);
      break;
    case CANCELLED:
    case INITIALIZING:
    case WARMING:
    case TRANSFERRING:
    case COMPLETE:
    case FINISHED:
    case IDLE:
    default:
      break;
  }
}

- (void)htdUpdateDataUsage:(NSUInteger)totalBytes
                     bytes:(NSUInteger)bytes
                  progress:(float)progress {
  [[SKAppBehaviourDelegate sGetAppBehaviourDelegate] amdDoUpdateDataUsage:(int)bytes];
}

- (void)htdDidUpdateTotalProgressPercent:(float)progress0To100Percent BitrateMbps1024Based:(double)bitrateMbps1024Based {
  // We must NOT allow the test to complete until htdDidCompleteHttpTest is called;
  // as only at that point is the output result available.
  if (progress0To100Percent >= 99) {
    progress0To100Percent = 99;
  }
  
  mLatestBitrateMbps1024Based = bitrateMbps1024Based;
  
  mProgressBlock(progress0To100Percent, bitrateMbps1024Based);
}

- (void)htdDidCompleteHttpTest:(double)bitrateMbps1024Based
            ResultIsFromServer:(BOOL)resultIsFromServer
               TestDisplayName:(NSString *)testDisplayName
{
  mLatestBitrateMbps1024Based = bitrateMbps1024Based;

  mProgressBlock(100.0, bitrateMbps1024Based);
}

@end
