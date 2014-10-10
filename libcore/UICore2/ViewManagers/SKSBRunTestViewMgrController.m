//
//  SKSBRunTestViewMgrController.m
//  SKCore
//

//  Copyright (c) 2014 SamKnows. All rights reserved.
//

#import "SKSBRunTestViewMgrController.h"
#import "UIWelcomeView.h"
#import "SKTestResultsSharer.h"

#include <math.h>

#define C_SHARE_BUTTON_HEIGHT   ([cTabController sGet_GUI_MULTIPLIER] * 40)
#define C_SHARE_BUTTON_WIDTH   ([cTabController sGet_GUI_MULTIPLIER] * 40)

@interface SKSBRunTestViewMgrController()
@property SKATestResults* mpTestResult;
  // This may NOT be allocated locally, or it can get auto-released before we've finished using it!
@property SKTestResultsSharer *mpSharer;
@end

@implementation SKSBRunTestViewMgrController

@synthesize mpTestResult;
@synthesize mpSharer;

#pragma mark ProgressView

-(void) viewDidLoad {
  [super viewDidLoad];
  
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  if (![prefs objectForKey:Prefs_LastTestSelection])
  {
    self.testTypes2Execute = CTTBM_CLOSESTTARGET | CTTBM_DOWNLOAD | CTTBM_UPLOAD | CTTBM_LATENCYLOSSJITTER;
    [prefs setInteger:self.testTypes2Execute forKey:Prefs_LastTestSelection];
  }
  self.testTypes2Execute = (int)[prefs integerForKey:Prefs_LastTestSelection];
  
  [self intialiseViewOnMasterView];
  
  // The main background view...
  //self.view.backgroundColor = [UIColor clearColor];
  ((UIViewWithGradient*)self.view).innerColor = [cTabController sGetInnerColor];
  ((UIViewWithGradient*)self.view).outerColor = [cTabController sGetOuterColor];
  
  // The progress/splash background view...
  //SK_ASSERT(self.vC1 != nil);
  //SK_ASSERT(self.vC1 != self.view);
  //self.vC1.backgroundColor = [UIColor clearColor];
//  self.vC1.innerColor = [UIColor colorWithRed:0.0/255.0 green:159.0/255.0 blue:227.0/255.0 alpha:1];
  //self.vC1.outerColor = [UIColor colorWithRed:37.0/255.0 green:82.0/255.0 blue:164.0/255.0 alpha:1];
 
  [self View_OnLoadTweakControls];
}

-(void) setIsRunning:(BOOL)value {
  isRunning = value;
}

-(void)resetProgressView
{
  self.vProgressView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0);
  self.vProgressView.backgroundColor = [UIColor blackColor];
  self.vProgressView.hidden = NO;
  self.vProgressView.alpha = 0.3;
}

-(void)setProgressView:(float)time_
{
  float totalProgress;
  
  if (!isRunning) return;
  
  if (time_ <= 0) time_ = C_GUI_UPDATE_INTERVAL;
  
  if (self.numberOfTests2Execute != 0)
  {
    totalProgress = (progressDownload < 0 ? 0 : progressDownload) + (progressUpload < 0 ? 0 : progressUpload) + (progressLatencyLoss < 0 ? 0 : progressLatencyLoss);
    totalProgress /= self.numberOfTests2Execute;
  }
  else
    totalProgress = 0;
  
  [UIView animateWithDuration:C_GUI_UPDATE_INTERVAL animations:^{
    self.vProgressView.frame = CGRectMake(0, self.view.bounds.size.height * (1 - totalProgress), self.view.bounds.size.width, self.view.bounds.size.height * totalProgress);
  }];
}

#pragma mark ViewController

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if ([[SKAAppDelegate getAppDelegate] isActivated] == NO)
  {
    [self SKSafePerformSegueWithIdentifier:@"segueActivate" sender:self];
    return;
  }
}

- (void)intialiseViewOnMasterView
{
  self.tvCurrentResults.delegate = self;
  self.tvCurrentResults.dataSource = self;
  
  showPassiveMetrics = NO;
  self.vProgressView.hidden = YES;
  [self.tmActivityIndicator setActivityIndicatorViewStyle:TYMActivityIndicatorViewStyleLarge];
  self.tmActivityIndicator.hidesWhenStopped = NO;
  
  //[self.tmActivityIndicator sizeToFit];
  self.tmActivityIndicator.activityOwner = self;
  
  self.networkType = [SKGlobalMethods getNetworkTypeString];
  self.appDelegate = (SKAAppDelegate*)[UIApplication sharedApplication].delegate;
  
  //self.btShare = [[UIButton alloc] initWithFrame:CGRectMake([cTabController sGet_GUI_MULTIPLIER] * 12, 20, C_SHARE_BUTTON_WIDTH, C_SHARE_BUTTON_HEIGHT)];
  //[self.btShare addTarget:self action:@selector(B_Share:) forControlEvents:UIControlEventTouchUpInside];
  //[self.btShare setImage:[UIImage imageNamed:@"share-button"] forState:UIControlStateNormal];
  self.btShare.alpha = 0;
  //[self.view addSubview:self.btShare];
  
  dataStart = 0;
  dataEnd = 0;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(statusChanged:)
                                               name:@"StatusChanged"
                                             object:nil];
  
  [self prepareResultsArray];
  
  progressDownload = -1;
  progressUpload = -1;
  progressLatencyLoss = -1;
  
  layoutCurrent = 1;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStatusChanged:) name:kReachabilityChangedNotification object:nil];
  
  self.internetReachability = [Reachability reachabilityForInternetConnection];
  [self.internetReachability startNotifier];
  
  self.wifiReachability = [Reachability reachabilityForLocalWiFi];
  //    [self.wifiReachability startNotifier];

}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void) adjustViewSizesOnStartOrOnDidRotate {
 
  // We MUST ensure that the main "dial" preserves a square aspect ratio, or it doesn't look good!
  // Ensure the central element is given a square aspect ratio!
  CGRect theFrame = self.tmActivityIndicator.frame;
  if (theFrame.size.width != theFrame.size.height) {
    CGFloat wh = fmin(theFrame.size.width, theFrame.size.height);
    theFrame.size.height = wh;
    theFrame.size.width = wh;
   
    // Keep it centered!
    theFrame.origin.x = (self.view.frame.size.width / 2.0) - (wh / 2.0);
    
    self.tmActivityIndicator.frame = theFrame;
  }
 
  // Tweak to ensure the table view isn't too high, as this doesn't work too well when auto-scaling to iPad!
  theFrame = self.tvCurrentResults.frame;
  theFrame.origin.y = self.casStatusView.frame.origin.y + self.casStatusView.frame.size.height + 10;
  theFrame.size.height = self.view.frame.size.height - theFrame.origin.y;
  self.tvCurrentResults.frame = theFrame;
}

// The following is called AFTER viewWillAppear!
-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
 
  // We MUST ensure that the main "dial" preserves a square aspect ratio, or it doesn't look good!
  [self adjustViewSizesOnStartOrOnDidRotate];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  
  // At this point, the views will have been AUTO-SCALED by the storyboard post rotation.
  
  // We MUST ensure that the main "dial" preserves a square aspect ratio, or it doesn't look good!
  [self adjustViewSizesOnStartOrOnDidRotate];
}

-(void)View_OnLoadTweakControls
{
  //[self setIsRunning:NO];
  
  self.btSelectTests.hidden = ![self.appDelegate enableTestsSelection];
  
  [self.casStatusView initialize];
  
  //[self.tmActivityIndicator layoutSubviews];
  [self.tmActivityIndicator displayReset:NSLocalizedString(@"Start",nil)];
  //[self.tmActivityIndicator setNeedsLayout];
  
  [self.casStatusView setText:NSLocalizedString(@"Ready to run",nil) forever:YES];
  //self.lClosest.font = [UIFont fontWithName:@"Roboto-Light" size:[cTabController sGet_GUI_MULTIPLIER] * 12];
  self.lClosest.text = NSLocalizedString(@"Press the Start button",nil);
  self.tvCurrentResults.hidden = YES;
  
  [self updateRadioType];

  // TODO - does this even make sense?!
  //historyViewMgr = (SKHistoryViewMgr*)((cTabOption*)[cTabController globalInstance].arrOptions[1]).view;
}

BOOL sbHaveAlreadyAskedUserAboutDataCapExceededSinceButtonPress1 = NO;

-(BOOL) checkIfTestWillExceedDataCapForTestType:(TestType)type {
  
  // If we're currently WiFi, there is nothing to run!
  if ([SKAAppDelegate getIsUsingWiFi]) {
    return NO;
  }
  
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  
  int64_t dataUsed = [[prefs objectForKey:Prefs_DataUsage] longLongValue];
  
  int64_t dataAllowed = [[prefs objectForKey:Prefs_DataCapValueBytes] longLongValue];
  
  // For all selected tests, add-up the expected amount of data to use.
  // And if data consumed + expected data > dataAllowed, present a warning to the user!
  
  int64_t dataWillBeUsed = 0;
  
  // TODO - add-in the correct value here!
  for (NSDictionary *testDict in [SKAAppDelegate getAppDelegate].schedule.tests) {
    NSString *thisTestType = [testDict objectForKey:@"type"];
    
    NSArray *params = testDict[@"params"];
    int theCount = (int)params.count;
    
    int paramIndex;
    for (paramIndex=0; paramIndex<theCount; paramIndex++)
    {
      NSDictionary *theParam = params[paramIndex];
      
      int64_t thisTestBytes = 0;
      if (theParam[@"numberOfPackets"]) {
        NSString *theValue = theParam[@"numberOfPackets"];
        thisTestBytes += [theValue longLongValue] * 16;
      } else if (theParam[@"warmupmaxbytes"]) {
        NSString *theValue = theParam[@"warmupmaxbytes"];
        thisTestBytes += [theValue longLongValue];
      } else if (theParam[@"transfermaxbytes"]) {
        NSString *theValue = theParam[@"transfermaxbytes"];
        thisTestBytes += [theValue longLongValue];
      }
      
      if (thisTestBytes <= 0) {
        continue;
      }
      
      switch (type) {
        case ALL_TESTS:
          dataWillBeUsed += thisTestBytes;
          break;
        case DOWNLOAD_TEST:
          if ([thisTestType isEqualToString:@"downstreamthroughput"]) {
            dataWillBeUsed += thisTestBytes;
          }
          break;
        case UPLOAD_TEST:
          if ([thisTestType isEqualToString:@"upstreamthroughput"]) {
            dataWillBeUsed += thisTestBytes;
          }
          break;
        case LATENCY_TEST:
          if ([thisTestType isEqualToString:@"latency"]) {
            dataWillBeUsed += thisTestBytes;
          }
          break;
        case JITTER_TEST:
          if ([thisTestType isEqualToString:@"jitter"]) {
            dataWillBeUsed += thisTestBytes;
          }
          break;
        default:
          SK_ASSERT(false);
          break;
      }
    }
  }
  
  // The value of "dataWillBeUsed" is generally *MUCH* higher than the *actually* used value.
  // e.g. 40+MB, compared to 4MB. The reason is that the value is from SCHEDULE.xml (see the above logic),
  // where transfermaxbytes specifies the absolute maximum that a test is allowed to use; in practise,
  // the test runs for a capped amount of time (also in the schedule data - transfermaxtime)
  // and processes far less data that the defined maximum number of bytes to use.
  
  if ((dataUsed + dataWillBeUsed) > dataAllowed)
  {
    // Data cap exceeded - but only ask the user if they want to continue, if the app is configured
    // to work like that...
    
    if ([[SKAAppDelegate getAppDelegate] isDataCapEnabled] == YES) {
      
      return YES;
    }
  }
  
  return NO;
}

-(BOOL) checkIfTestsHaveExceededDataCap {
  // If we're currently WiFi, there is nothing to test against!
  if ([SKAAppDelegate getIsUsingWiFi]) {
    return NO;
  }
  
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  
  int64_t dataUsed = [[prefs objectForKey:Prefs_DataUsage] longLongValue];
  
  int64_t dataAllowed = [[prefs objectForKey:Prefs_DataCapValueBytes] longLongValue];
  
  if (dataUsed > dataAllowed)
  {
    // Data cap already exceeded - but only ask the user if they want to continue, if the app is configured
    // to work like that...
    
    if ([[SKAAppDelegate getAppDelegate] isDataCapEnabled] == YES) {
      
      return YES;
    }
  }
  
  return NO;
}

-(BOOL) getIsConnected {
  return [[SKAAppDelegate getAppDelegate] getIsConnected];
}

- (void)reachabilityStatusChanged:(NSNotification*)notification
{
  [self updateRadioType];
}

- (void)setConnectionStatus
{
  SKAAppDelegate* appDelegate = (SKAAppDelegate*)[UIApplication sharedApplication].delegate;
  
  if (appDelegate.connectionStatus == NONE)
  {
    
    NSLog(@"------------------ conn status");
    
    if (nil != autoTest)
    {
      [autoTest stopTheTests];
    }
    [self setIsRunning:NO];
    
    [self setEndDataUsage];
    [self cancelCurrentTests];
    [self.tmActivityIndicator stopAnimating];
  }
  else
    NSLog(@"Connection !!!!!");
}

-(void) selfRunTestAfterUserApprovedToDataCapChecks {
  
  [self fillPassiveMetrics];
  SKAAppDelegate *appDelegate = (SKAAppDelegate*)[UIApplication sharedApplication].delegate;
  
  if ([appDelegate getIsConnected])
  {
    self.networkType = [SKGlobalMethods getNetworkTypeString];
    [self setConnectionStatus];
    if ([self.appDelegate getIsConnected])
    {
      [self setStartDataUsage];
      [self createDefaultResults];
      
      SK_ASSERT([NSThread isMainThread]);
      
      [self setIsRunning:YES];
      
      autoTest = [[SKAAutotest alloc] initAndRunWithAutotestManagerDelegateWithBitmask:self.appDelegate autotestObserverDelegate:self TestsToExecuteBitmask:self.testTypes2Execute isContinuousTesting:self.continuousTesting];
    }
    else
    {
      [self setIsRunning:NO];
    }
  }
  else
  {
    [self setIsRunning:NO];
    
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:nil
                               message:NSLocalizedString(@"Offline_message", nil)
                              delegate:nil
                     cancelButtonTitle:NSLocalizedString(@"MenuAlert_OK",nil)
                     otherButtonTitles: nil];
    
    [alert show];
    [self restoreButton];
    
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value = nil;
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value = nil;
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value = nil;
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value = nil;
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value = nil;
    
    [self updateTableAnimated];
  }
}

-(void)updateRadioType
{
  if ([[SKAAppDelegate getAppDelegate] getIsConnected] == NO) {
    [self.tmActivityIndicator setTopInfo:NSLocalizedString(@"No connection",nil)];
  } else {
    connectionStatus = [SKAAppDelegate getAppDelegate].connectionStatus;
    
    if (connectionStatus == WIFI) {
      [self.tmActivityIndicator setTopInfo:NSLocalizedString(@"NetworkTypeMenu_WiFi",nil)];
    } else {
      [self.tmActivityIndicator setTopInfo:[SKGlobalMethods getNetworkTypeLocalized:[SKGlobalMethods getNetworkType]]];
    }
  }
}

//#if TARGET_IPHONE_SIMULATOR
//int sbSimulatorFakeConnectionToggle = 0;
//#endif // TARGET_IPHONE_SIMULATOR
-(void)selectedOption:(int)optionTag from:(cActionSheet*)sender WithState:(int)state {
  
  if ([self.appDelegate enableTestsSelection] == NO)
  {
    SK_ASSERT(false);
    return;
  }
  
  switch (optionTag) {
    case C_DOWNLOAD_TEST:
      if (state == 1) {
        self.testTypes2Execute |= CTTBM_DOWNLOAD;
      } else {
        self.testTypes2Execute &= ~CTTBM_DOWNLOAD;
      }
    case C_UPLOAD_TEST:
      if (state == 1) {
        self.testTypes2Execute |= CTTBM_UPLOAD;
      } else {
        self.testTypes2Execute &= ~CTTBM_UPLOAD;
      }
      break;
    case C_LATENCY_TEST:
      if (state == 1) {
        self.testTypes2Execute |= CTTBM_LATENCYLOSSJITTER;
      } else {
        self.testTypes2Execute &= ~CTTBM_LATENCYLOSSJITTER;
      }
      break;
    case C_JITTER_TEST:
      SK_ASSERT(false);
      //       if (state == 1) {
      //         self.testTypes2Execute |= CTTBM_LATENCYLOSSJITTER;
      //       } else {
      //         self.testTypes2Execute &= ~CTTBM_LATENCYLOSSJITTER;
      //       }
      break;
    default:
      SK_ASSERT(false);
      break;
  }
 
  // And save the updated preferences!
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setInteger:self.testTypes2Execute forKey:Prefs_LastTestSelection];
  [prefs synchronize];
}

-(void)buttonPressed
{
  if (isRunning)
  {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Tests_Running_Title", nil)
                          message:NSLocalizedString(@"Tests_Running_Message", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"MenuAlert_Cancel",nil)
                          otherButtonTitles:NSLocalizedString(@"MenuAlert_OK",nil),nil];
    
    alert.tag = ACTION_CANCEL_CONFIRMATION;
    [alert show];
    return;
  }
  
  if ((self.testTypes2Execute & ~CTTBM_CLOSESTTARGET) == 0) {
    // No tests selected!
    [self B_SelectTests:self];
    return;
  }
 
  // Assert at least one test selected!
  SK_ASSERT ((self.testTypes2Execute & ~CTTBM_CLOSESTTARGET) != 0);
  
  self.tvCurrentResults.hidden = NO;
  
  latencySUM = 0;
  latencyCNT = 0;
  
  [self resetProgressView];
  
  for (int i = 0; i < C_NUMBER_OF_TESTS; i++) {
    ((SKATestOverviewMetrics*)testResultsArray[i]).value = nil;
  }
  
  self.numberOfTests2Execute = 0;
  if (self.testTypes2Execute & CTTBM_DOWNLOAD) {
    progressDownload = 0;
    self.numberOfTests2Execute ++;
  } else {
    progressDownload = -1;
  }
  
  if (self.testTypes2Execute & CTTBM_UPLOAD) {
    self.numberOfTests2Execute ++;
    progressUpload = 0;
  } else {
    progressUpload = -1;
  }
  if (self.testTypes2Execute & CTTBM_LATENCYLOSSJITTER) {
    self.numberOfTests2Execute ++;
    progressLatencyLoss = 0;
  } else {
    progressLatencyLoss = -1;
  }
  
  if (self.numberOfTests2Execute == 0)
  {
    // Should never happen - should be picked-up earlier in this method!
    SK_ASSERT(false);
    [self B_SelectTests:self];
    return;
  }
  
  //    if (layoutCurrent == 1)
  //    {
  //      [UIView animateWithDuration:0.3 animations:^{
  //        [self layout2];
  //      }];
  //    }
  
  [self showTargets];
  
  [self.tmActivityIndicator displayReset:@""];
  [self.tmActivityIndicator startAnimating];
  [UIView animateWithDuration:0.3 animations:^{
    
    self.btSelectTests.alpha = 0;
    
  }];
  
  TestType GRunTheTestWithThisType = ALL_TESTS; //###
  
  if ([self checkIfTestsHaveExceededDataCap]) {
    
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Data_Exceeded", nil)
                               message:NSLocalizedString(@"Data_Exceed_Msg", nil)
                              delegate:nil
                     cancelButtonTitle:NSLocalizedString(@"MenuAlert_Cancel",nil)
                     otherButtonTitles:NSLocalizedString(@"MenuAlert_OK",nil),nil];
    [alert setTag:ACTION_ALREADY_EXCEEDED_PRESS_OK_TO_CONTINUE];
    [alert setDelegate:self];
    [alert show];
    
    return;
  }
  
  if ([self checkIfTestWillExceedDataCapForTestType:GRunTheTestWithThisType]) {
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Data_Might_Be_Exceeded", nil)
                               message:NSLocalizedString(@"Data_Exceed_Msg", nil)
                              delegate:nil
                     cancelButtonTitle:NSLocalizedString(@"MenuAlert_Cancel",nil)
                     otherButtonTitles:NSLocalizedString(@"MenuAlert_OK",nil),nil];
    [alert setTag:ACTION_WILL_BE_EXCEEDED_PRESS_OK_TO_CONTINUE];
    [alert setDelegate:self];
    [alert show];
    
    return;
  }
  
  [self selfRunTestAfterUserApprovedToDataCapChecks];
  
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  
  switch (alertView.tag) {
    case ACTION_CANCEL_CONFIRMATION:
      if (buttonIndex == alertView.cancelButtonIndex) {
        return;
      }
      // OK button pressed - try to stop the tests!
      if (!isRunning) return;
      [self setIsRunning:NO];
      [self stopTestFromAlertResponse:YES];
      //            [autoTest stopTheTests]; //HG - already done in [self stopTestFromAlertResponse:YES];
      autoTest = nil;
      [self restoreButton];
      return;
    case ACTION_ALREADY_EXCEEDED_PRESS_OK_TO_CONTINUE:
    case ACTION_WILL_BE_EXCEEDED_PRESS_OK_TO_CONTINUE:
      if (buttonIndex == alertView.cancelButtonIndex) {
        [self restoreButton];
        return;
      }
      [self selfRunTestAfterUserApprovedToDataCapChecks];
      return;
  }
}

-(void)restoreButton
{
  [self.tmActivityIndicator stopAnimating];
  [self.tmActivityIndicator displayReset:NSLocalizedString(@"Start",nil)];
  [self.tmActivityIndicator setAngle:0];
  
  if ([self.appDelegate enableTestsSelection])
    [UIView animateWithDuration:0.3 animations:^{
      self.btSelectTests.alpha = 1;
    }];
}

//- (BOOL)testIsIncluded:(NSString*)type //DUPLICATION !!!!!!!!!!
//{
//    if (self.testType == ALL_TESTS)
//    {
//        return YES;
//    }
//    else
//    {
//        if (self.testType == DOWNLOAD_TEST && [type isEqualToString:@"downstreamthroughput"])
//        {
//            return YES;
//        }
//        else if (self.testType == UPLOAD_TEST && [type isEqualToString:@"upstreamthroughput"])
//        {
//            return YES;
//        }
//        else if (self.testType == LATENCY_TEST && [type isEqualToString:@"latency"])
//        {
//            return YES;
//        }
//        else if (self.testType == JITTER_TEST && [type isEqualToString:@"jitter"])
//        {
//            return YES;
//        }
//        else {
//            //SK_ASSERT(false);
//        }
//
//    }
//
//    return NO;
//}

#pragma mark - Autotest Delegate Methods

// CLOSEST TARGET /////////////////////////////////////////////////

- (void)aodClosestTargetTestDidStart
{
  [self.lClosest setText:NSLocalizedString(@"TEST_Label_Finding_Best_Target", nil)];
  [self showTargets];
}

- (void)aodClosestTargetTestDidFail
{
#ifdef DEBUG
  NSLog(@"DEBUG: %s", __FUNCTION__);
#endif // DEBUG
  [self stopTestFromAlertResponse:NO];
  [self setIsRunning:NO];
  [self.lClosest setText:NSLocalizedString(@"TEST_Label_Closest_Failed", nil)];
}

- (void)aodClosestTargetTestDidSucceed:(NSString*)target
{
  [SKAAppDelegate setClosestTarget:target];
  
  NSString *closest = [NSString stringWithFormat:@"%@ %@",
                       NSLocalizedString(@"TEST_Label_Closest_Target", nil),
                       [self.appDelegate.schedule getClosestTargetName:target]];
  
  [self.lClosest setText:closest];
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_TARGET]).value = [self.appDelegate.schedule getClosestTargetName:target];
  
  [self.tvCurrentResults reloadData];
  //TODO: Also on fail. Also for other fails.
}

// LATENCY //////////////////////////////////////////////////////

- (void)aodLatencyTestDidFail:(NSString*)message
{
  [self stopTestFromAlertResponse:NO];
  [self setIsRunning:NO];
  
  [self setErrorMessage];
}

- (void)aodLatencyTestDidSucceed:(SKLatencyTest*)latencyTest
{
  double latency = latencyTest.latency;
  double packetLoss = latencyTest.packetLoss;
  double jitter = latencyTest.jitter;
  
  [self.tmActivityIndicator setAngle:0];
  
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value = [NSString stringWithFormat:@"%.0f ms", latency];
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value = [NSString stringWithFormat:@"%.0f %%", packetLoss];
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value = [NSString stringWithFormat:@"%.0f ms", jitter];
  
  [SKHistoryViewMgr sGetTstToShareExternal].latency = latency;
  [SKHistoryViewMgr sGetTstToShareExternal].loss = packetLoss;
  [SKHistoryViewMgr sGetTstToShareExternal].jitter = jitter;
  
  [self updateTableAnimated];
}

- (void)aodLatencyTestUpdateStatus:(LatencyStatus)status
{
  //TODO: To be deleted ???
  //NSLog(@"aodLatencyTestUpdateStatus");
}

- (void)aodLatencyTestWasCancelled
{
  NSLog(@"**** %s", __FUNCTION__);
  
  //    NSIndexPath *ixp = [self getIndexPathForTest:@"latency"];
  //    SKALatencyTestCell *cell = (SKALatencyTestCell*)[self.tableView cellForRowAtIndexPath:ixp];
  //
  //    if (nil != cell)
  //    {
  //        cell.lblLatencyResult.hidden = NO;
  //        cell.lblLossResult.hidden = NO;
  //        cell.lblJitterResult.hidden = NO;
  //        cell.latencyProgressView.hidden = YES;
  //        cell.lossProgressView.hidden = YES;
  //        cell.jitterProgressView.hidden = YES;
  //        cell.lblLatencyResult.text = [SKTransferOperation getStatusCancelled];
  //        cell.lblLossResult.text = [SKTransferOperation getStatusFailed];
  //        cell.lblJitterResult.text = [SKTransferOperation getStatusFailed];
  //    }
  //
  //    [self updateResultsArray:[NSNumber numberWithBool:NO] key:@"HIDE_LABEL" testType:@"latency"];
  //    [self updateResultsArray:[NSNumber numberWithBool:YES] key:@"HIDE_SPINNER" testType:@"latency"];
  //    [self updateResultsArray:[SKTransferOperation getStatusCancelled] key:@"RESULT_1" testType:@"latency"];
  //    [self updateResultsArray:[SKTransferOperation getStatusCancelled] key:@"RESULT_2" testType:@"latency"];
}

-(void)aodLatencyTestDidStart
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.casStatusView setText:NSLocalizedString(@"Latency / Loss testing",nil) forever:YES];
    [self.tmActivityIndicator setUnitMeasurement:NSLocalizedString(@"Graph_Suffix_Ms",nil) measurement:NSLocalizedString(@"Test_Latency",nil)];
    if (((self.testTypes2Execute & CTTBM_DOWNLOAD) != 0) || ((self.testTypes2Execute & CTTBM_UPLOAD) != 0))
      [self.tmActivityIndicator displayReset:@"0"];
    
    [self.tmActivityIndicator.arrLabels removeAllObjects];
    [self.tmActivityIndicator.arrLabels addObject:@"0"];
    [self.tmActivityIndicator.arrLabels addObject:@"100"];
    [self.tmActivityIndicator.arrLabels addObject:@"200"];
    [self.tmActivityIndicator.arrLabels addObject:@"300"];
    [self.tmActivityIndicator.arrLabels addObject:@"400"];
    [self.tmActivityIndicator.arrLabels addObject:@"500"];
    [self.tmActivityIndicator.arrLabels addObject:@"600"];    });
}

- (void)aodLatencyTestUpdateProgress:(float)progress latency:(float)latency_
{
  latencySUM += latency_;
  latencyCNT++;
  
  float latencyAVG = latencySUM / latencyCNT;
  
  progressLatencyLoss = progress/100.0F;
  
  if (CACurrentMediaTime() - self.timeOfLastUIUpdate > C_GUI_UPDATE_INTERVAL)
  {
    self.timeOfLastUIUpdate = CACurrentMediaTime();
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.tmActivityIndicator setCurrentResult:[NSString stringWithFormat:@"%.00f", latencyAVG]];
      
      if (latencyAVG <= 100.0)
        [self.tmActivityIndicator setAngle:45.0 * latencyAVG / 100.0];
      else if (latencyAVG <= 200.0)
        [self.tmActivityIndicator setAngle:45.0 + 45.0 * (latencyAVG - 100.0) / 100.0];
      else if (latencyAVG <= 300.0)
        [self.tmActivityIndicator setAngle:90.0 + 45.0 * (latencyAVG - 200.0) / 100.0];
      else if (latencyAVG <= 400.0)
        [self.tmActivityIndicator setAngle:135.0 + 45.0 * (latencyAVG - 300.0) / 100.0];
      else if (latencyAVG <= 500.0)
        [self.tmActivityIndicator setAngle:180.0 + 45.0 * (latencyAVG - 400.0) / 100.0];
      else if (latencyAVG <= 600.0)
        [self.tmActivityIndicator setAngle:225.0 + 45.0 * (latencyAVG - 500.0) / 100.0];
      else
        [self.tmActivityIndicator setAngle:270.0];
      
      [self setProgressView:0];
    });
  }
}

// TRANSFER //////////////////////////////////////////////////////

- (void)aodTransferTestDidStart:(BOOL)isDownstream
{
  dispatch_async(dispatch_get_main_queue(),
                 ^{
                   [self.tmActivityIndicator displayReset:@"0.00"];
                   
                   if (isDownstream)
                   {
                     [self.casStatusView setText:@"Download testing" forever:YES];
                     [self.tmActivityIndicator.arrLabels removeAllObjects];
                     [self.tmActivityIndicator.arrLabels addObject:@"0"];
                     [self.tmActivityIndicator.arrLabels addObject:@"1"];
                     [self.tmActivityIndicator.arrLabels addObject:@"2"];
                     [self.tmActivityIndicator.arrLabels addObject:@"5"];
                     [self.tmActivityIndicator.arrLabels addObject:@"10"];
                     [self.tmActivityIndicator.arrLabels addObject:@"30"];
                     [self.tmActivityIndicator.arrLabels addObject:@"100"];
                     
                     [self.tmActivityIndicator setUnitMeasurement:NSLocalizedString(@"Graph_Suffix_Mbps",nil) measurement:NSLocalizedString(@"Test_Download",nil)];
                   }
                   else
                   {
                     [self.casStatusView setText:@"Upload testing" forever:YES];
                     [self.tmActivityIndicator.arrLabels removeAllObjects];
                     [self.tmActivityIndicator.arrLabels addObject:@"0"];
                     [self.tmActivityIndicator.arrLabels addObject:@"0.5"];
                     [self.tmActivityIndicator.arrLabels addObject:@"1"];
                     [self.tmActivityIndicator.arrLabels addObject:@"1.5"];
                     [self.tmActivityIndicator.arrLabels addObject:@"2"];
                     [self.tmActivityIndicator.arrLabels addObject:@"5"];
                     [self.tmActivityIndicator.arrLabels addObject:@"10"];
                     [self.tmActivityIndicator setUnitMeasurement:NSLocalizedString(@"Graph_Suffix_Mbps",nil) measurement:NSLocalizedString(@"Test_Upload",nil)];
                   }
                 });
}

- (void)aodTransferTestDidUpdateProgress:(float)progress isDownstream:(BOOL)isDownstream bitrate1024Based:(double)bitrate1024Based
{
  dispatch_async(dispatch_get_main_queue(),
                 ^{
                   if (isDownstream)
                   {
                     progressDownload = progress/100.0F;
                   }
                   else
                   {
                     progressUpload = progress/100.0F;
                   }
                   
                   if (CACurrentMediaTime() - self.timeOfLastUIUpdate > C_GUI_UPDATE_INTERVAL)
                   {
                     self.timeOfLastUIUpdate = CACurrentMediaTime();
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                       [self.tmActivityIndicator setCurrentResult:[NSString stringWithFormat:@"%.02f", bitrate1024Based]];
                       
                       if (isDownstream)
                       {
                         if (bitrate1024Based <= 1)
                           [self.tmActivityIndicator setAngle:45.0 * bitrate1024Based];
                         else if (bitrate1024Based <= 2)
                           [self.tmActivityIndicator setAngle:45.0 + 45.0 * (bitrate1024Based - 1)];
                         else if (bitrate1024Based <= 5)
                           [self.tmActivityIndicator setAngle:90.0 + 45.0 * (bitrate1024Based - 2) / 3.0];
                         else if (bitrate1024Based <= 10)
                           [self.tmActivityIndicator setAngle:135.0 + 45.0 * (bitrate1024Based - 5) / 5.0];
                         else if (bitrate1024Based <= 30)
                           [self.tmActivityIndicator setAngle:180.0 + 45.0 * (bitrate1024Based - 10) / 20.0];
                         else if (bitrate1024Based <= 100)
                           [self.tmActivityIndicator setAngle:225.0 + 45.0 * (bitrate1024Based - 30) / 70.0];
                         else
                           [self.tmActivityIndicator setAngle:270.0];
                       }
                       else
                       {
                         if (bitrate1024Based <= 0.5)
                           [self.tmActivityIndicator setAngle:45.0 * bitrate1024Based / 0.5];
                         else if (bitrate1024Based <= 1)
                           [self.tmActivityIndicator setAngle:45.0 + 45.0 * (bitrate1024Based - 0.5)];
                         else if (bitrate1024Based <= 1.5)
                           [self.tmActivityIndicator setAngle:90.0 + 45.0 * (bitrate1024Based - 1) / 0.5];
                         else if (bitrate1024Based <= 2)
                           [self.tmActivityIndicator setAngle:135.0 + 45.0 * (bitrate1024Based - 1.5) / 0.5];
                         else if (bitrate1024Based <= 5)
                           [self.tmActivityIndicator setAngle:180.0 + 45.0 * (bitrate1024Based - 2) / 3.0];
                         else if (bitrate1024Based <= 10)
                           [self.tmActivityIndicator setAngle:225.0 + 45.0 * (bitrate1024Based - 5) / 5.0];
                         else
                           [self.tmActivityIndicator setAngle:270.0];
                       }
                       
                       [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
                       NSLog(@"Bitrate: %f", bitrate1024Based);
                       
                       [self setProgressView:0];
                     });
                   }
                 });
}

-(void)setErrorMessage
{
  //    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value = @"#";
  //    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value = @"#";
  //    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value = @"#";
  //    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value = @"#";
  //    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value = @"#";
  [self.casStatusView setText:NSLocalizedString(@"Error",nil) forever:YES];
  [self updateTableAnimated];
}

- (void)aodTransferTestDidFail:(BOOL)isDownstream
{
  SK_ASSERT(false);
  
  dispatch_async(dispatch_get_main_queue(), ^{
    
    [self stopTestFromAlertResponse:NO];
    [self setIsRunning:NO];
    
    [self setErrorMessage];
  });
}

-(void)updateTableAnimated
{
  for (SKASimpleResultCell2 *cell in self.tvCurrentResults.visibleCells)
  {
    [cell updateDisplay];
  }
  
  //    [self.tvCurrentResults reloadData];
  [self.tvCurrentResults beginUpdates];
  [self.tvCurrentResults endUpdates];
}

- (void)aodTransferTestDidCompleteTransfer:(SKHttpTest*)httpTest Bitrate1024Based:(double)bitrate1024Based
//- (void)aodTransferTestDidCompleteTransfer:(SKHttpTest*)httpTest Bitrate:(double)bitrate
{
  dispatch_async(dispatch_get_main_queue(),
                 ^{
                   BOOL isDownstream = httpTest.isDownstream;
                   
                   [self.tmActivityIndicator setAngle:0];
                   
                   if (isDownstream) //Download test
                   {
                     ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value = [SKATestOverviewCell2 get3digitsNumber: bitrate1024Based];
                     [SKHistoryViewMgr sGetTstToShareExternal].downloadSpeed = bitrate1024Based;
                     progressDownload = 1;
                   }
                   else
                   {
                     ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value = [SKATestOverviewCell2 get3digitsNumber: bitrate1024Based];
                     [SKHistoryViewMgr sGetTstToShareExternal].uploadSpeed = bitrate1024Based;
                     progressUpload = 1;
                   }
                   
                   [self setProgressView:0.2];
                   [self updateTableAnimated];
                 });
}

// ALL TESTS COMPLETE

- (void)aodAllTestsComplete
{
  dispatch_async(dispatch_get_main_queue(),
                 ^{
                   [self restoreButton];
                   
                   [UIView animateWithDuration:1.0 animations:^{
                     [self resetProgressView];
                     [self.casStatusView setText:NSLocalizedString(@"Tests executed",nil) forever:YES];
                     self.lClosest.text = NSLocalizedString(@"Press the Start button to run again",nil);
                    
                     if ([self.mpTestResult.network_type isEqualToString:@"mobile"])
                     {
                       // Only show if NETWORK!
                       self.btShare.alpha = 1;
                       self.btShare.userInteractionEnabled = YES;
                     } else {
                       self.btShare.alpha = 0;
                       self.btShare.userInteractionEnabled = NO;
                     }
                   }];
                   
                   [self setIsRunning:NO];
                   [self setEndDataUsage];
                   //
                   SK_ASSERT([NSThread isMainThread]);
                   [self updateTableAnimated];
                   
                   [[NSNotificationCenter defaultCenter]
                    postNotificationName:@"TestListNeedsUpdate"
                    object:self];
                 });
}

- (void)cancelCurrentTests
{
  
}

- (void)calculateDataUsed
{
  //int64_t totalData = dataEnd - dataStart;
  //NSLog(@"Total Data Used : %d", totalData);
}

#pragma mark - Actions

- (void)stopTestFromAlertResponse:(BOOL)fromAlertResponse {
  
  if ([((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value isEqualToString:@"r"])
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value = nil;
  if ([((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value isEqualToString:@"r"])
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value = nil;
  if ([((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value isEqualToString:@"r"])
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value = nil;
  if ([((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value isEqualToString:@"r"])
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value = nil;
  if ([((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value isEqualToString:@"r"])
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value = nil;
  
  if (nil != autoTest)
  {
    [autoTest stopTheTests];
  }
  
  [self restoreButton];
  
  if (progressDownload > 0) progressDownload = 0;
  if (progressUpload > 0) progressUpload = 0;
  if (progressLatencyLoss > 0) progressLatencyLoss = 0;
  
  [UIView animateWithDuration:1.0 animations:^{
    [self resetProgressView];
  }];
  
  //TODO: If cancelled or error
  [self.casStatusView setText:NSLocalizedString(@"Tests canceled",nil) forever:YES];
  self.lClosest.text = NSLocalizedString(@"Press the Start button to run again",nil);
  
  [self setIsRunning:NO];
  [self setEndDataUsage];
  //
  SK_ASSERT([NSThread isMainThread]);
  [self updateTableAnimated];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:@"TestListNeedsUpdate"
   object:self];
  
  [self cancelCurrentTests];
}

- (void)setStartDataUsage
{
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  
  dataStart = 0;
  
  if ([prefs valueForKey:Prefs_DataUsage])
  {
    NSNumber *num = [prefs objectForKey:Prefs_DataUsage];
    dataStart = [num longLongValue];
  }
  else
  {
    [prefs setValue:[NSNumber numberWithLongLong:0] forKey:Prefs_DataUsage];
    [prefs synchronize];
  }
}

- (void)setEndDataUsage
{
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  
  dataEnd = 0;
  
  if ([prefs valueForKey:Prefs_DataUsage])
  {
    NSNumber *num = [prefs objectForKey:Prefs_DataUsage];
    dataEnd = [num longLongValue];
  }
  
  [self calculateDataUsed];
}

- (void)createDefaultResults
{
  //    NSArray *tests = appDelegate.schedule.tests;
  //
  //    if (nil != tests)
  //    {
  //        NSMutableArray *tmpArray = [NSMutableArray array];
  //
  //        for (int j=0; j<[tests count]; j++)
  //        {
  //            NSDictionary *dict = [tests objectAtIndex:j];
  //
  //            NSString *type = [dict objectForKey:@"type"];
  //
  //            if (![type isEqualToString:@"closestTarget"] && [self testIsIncluded:type])
  //            {
  //                NSString *displayName = [dict objectForKey:@"displayName"];
  //
  //                NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
  //                [tmpDict setObject:type forKey:@"TYPE"];
  //                [tmpDict setObject:@"" forKey:@"RESULT_1"];
  //                [tmpDict setObject:@"" forKey:@"RESULT_2"];
  //                [tmpDict setObject:displayName forKey:@"DISPLAY_NAME"];
  //                [tmpDict setObject:[NSNumber numberWithFloat:0] forKey:@"PROGRESS"];
  //                [tmpDict setObject:[NSNumber numberWithBool:NO] forKey:@"HIDE_SPINNER"];
  //                [tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"HIDE_LABEL"];
  //                [tmpDict setObject:[SKLatencyOperation getIdleStatus] forKey:@"STATUS"];
  //
  //                float height = 100.0F;
  //                if ( ([type isEqualToString:@"downstreamthroughput"]) ||
  //                    ([type isEqualToString:@"upstreamthroughput"]) ) {
  //                    height = 59.0F;
  //                } else {
  //                    // Latency/loss/jitter!
  //                    if ([[SKAAppDelegate getAppDelegate] getIsJitterSupported]) {
  //                        height = 150;
  //                    }
  //                }
  //
  //                // SKAInformationCell - 49, SKATransferTestCell - 59, SKALatencyTestCell - 100!
  //                [tmpDict setObject:[NSNumber numberWithFloat:height] forKey:@"HEIGHT"];
  //
  //
  //                [tmpArray addObject:tmpDict];
  //            }
  //        }
  //
  //        self.resultsArray = tmpArray;
  //    }
}

-(void)aodDidStartTargetTesting
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.casStatusView setText:NSLocalizedString(@"Target Selection",nil) forever:YES];
  });
}

- (void)aodDidFinishAnotherTarget:(int)targetId withLatency:(double)latency withBest:(int)bestId
{
  //    SKATargetCell2* targetCell;
  //    NSLog(@"Target: %d", targetId);
  //
  //    for (int ti = 0; ti < self.tvTargets.visibleCells.count; ti++) {
  //        targetCell = [self.tvTargets.visibleCells objectAtIndex:ti];
  //        if (ti == bestId)
  //            [targetCell setColor:[UIColor redColor]];
  //        else
  //            [targetCell setColor:[UIColor lightGrayColor]];
  //    }
}


-(void)showTargets
{
}

-(void)hideTargets
{
}

-(void)activate
{
  [self reachabilityStatusChanged:nil];
}

-(void)deactivate
{
}

#pragma mark TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.tvCurrentResults) {
    return C_NUMBER_OF_PASSIVE_METRICS + 1; //1 for the test results cell
  }
  
  return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  int activeRowHeight;
  int passiveRowHeight;
  
  if (tableView == self.tvCurrentResults)
  {
    activeRowHeight = [cTabController sGet_GUI_MULTIPLIER] * 95;
    passiveRowHeight = [cTabController sGet_GUI_MULTIPLIER] * 18;
    
    switch (indexPath.row) {
      case 0:
        return (progressDownload < 0 && progressUpload < 0 && progressLatencyLoss < 0 ? 0 : activeRowHeight);
        break;
      default:
        return (showPassiveMetrics ? passiveRowHeight : 0);
        break;
    }
  }
  
  return 110; //Error
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.tvCurrentResults)
  {
    if (indexPath.row == 0)
    {
      SKATestOverviewCell2 *cell;
      static NSString *CellIdentifier = @"SKATestOverviewCell2";
      
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        
        cell = [[SKATestOverviewCell2 alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
      }
      
      [cell initCell];
      
      [cell setResultDownload:[testResultsArray objectAtIndex:indexPath.row + C_DOWNLOAD_TEST] upload:[testResultsArray objectAtIndex:indexPath.row + C_UPLOAD_TEST] latency:[testResultsArray objectAtIndex:indexPath.row + C_LATENCY_TEST] loss:[testResultsArray objectAtIndex:indexPath.row + C_LOSS_TEST] jitter:[testResultsArray objectAtIndex:indexPath.row + C_JITTER_TEST]];
      
      if ([self getIsConnected] == NO)
      {
        cell.ivNetworkType = nil;
      }
      else {
        if (connectionStatus == WIFI) {
          cell.ivNetworkType.image = [UIImage imageNamed:@"swifi"];
        }
        else {
          cell.ivNetworkType.image = [UIImage imageNamed:@"sgsm"];
        }
      }
      
      return cell;
    }
    else
    {
      SKASimpleResultCell2 *cell;
      static NSString *CellIdentifier = @"SKASimpleResultCell2";
      
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        
        cell = [[SKASimpleResultCell2 alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
      }
      
      [cell initCell];
      
      [cell setMetrics:[testResultsArray objectAtIndex:indexPath.row + C_NUMBER_OF_TESTS - 1 ]];
      
      return cell;
    }
  } else {
    SK_ASSERT(false);
  }
  //    else if (tableView == self.tvTargets)
  //    {
  //        NSString *targetName;
  //        SKATargetCell2 *cell;
  //        static NSString *CellIdentifier = @"SKATargetCell2";
  //
  //        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  //        if (cell == nil) {
  //
  //            cell = [[SKATargetCell2 alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  //        }
  //
  //        targetName = [self.appDelegate.schedule getClosestTargetName:((NSString*)[autoTest.targetTest.targets objectAtIndex:indexPath.row])];
  //        [cell setTarget:((NSString*)[autoTest.targetTest.targets objectAtIndex:indexPath.row]) withName:targetName];
  //        [cell startActivityAnimation];
  //        return cell;
  //    }
  
  return nil;
}

-(void)prepareResultsArray
{
  SKATestOverviewMetrics* tr0;
  
  //TODO: Proper number of elements
  
  testResultsArray = [[NSMutableArray alloc] initWithCapacity:C_NUMBER_OF_METRICS];
  for (int i = 0; i < C_NUMBER_OF_METRICS; i++) {
    
    tr0 = [[SKATestOverviewMetrics alloc] initWithMetricsNumber:i];
    
    [testResultsArray addObject:tr0];
  }
  return;
}

-(void)fillPassiveMetrics
{
  [UIView animateWithDuration:0.3 animations:^{
    self.btShare.alpha = 0;
  }];
  
  mpTestResult = [SKHistoryViewMgr sCreateNewTstToShareExternal];
  mpTestResult.testDateTime = [NSDate date];
  mpTestResult.downloadSpeed = -1;
  mpTestResult.uploadSpeed = -1;
  mpTestResult.latency = -1;
  mpTestResult.loss = -1;
  mpTestResult.jitter = -1;
  
  mpTestResult.device = self.appDelegate.deviceModel;
  mpTestResult.os = [[UIDevice currentDevice] systemVersion];
  mpTestResult.carrier_name = self.appDelegate.carrierName;
  mpTestResult.country_code = self.appDelegate.countryCode;
  //    mpTestResult.iso_country_code;
  mpTestResult.network_code = self.appDelegate.networkCode;
  
  if ([self getIsConnected] == NO)
    mpTestResult.network_type = @"";
  else
  {
    if (connectionStatus == WIFI)
    {
      mpTestResult.network_type = @"network";
      mpTestResult.radio_type = @"";
    }
    else
    {
      mpTestResult.network_type = @"mobile";
      mpTestResult.radio_type = [SKGlobalMethods getNetworkTypeLocalized:[SKGlobalMethods getNetworkType]];
    }
  }
  
  if ((self.testTypes2Execute & CTTBM_DOWNLOAD) != 0)
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value = @"r";
  else
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_DOWNLOAD_TEST]).value = nil;
  
  if ((self.testTypes2Execute & CTTBM_UPLOAD) != 0)
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value = @"r";
  else
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_UPLOAD_TEST]).value = nil;
  
  if ((self.testTypes2Execute & CTTBM_LATENCYLOSSJITTER) != 0)
  {
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value = @"r";
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value = @"r";
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value = @"r";
  }
  else
  {
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LATENCY_TEST]).value = nil;
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_LOSS_TEST]).value = nil;
    ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_JITTER_TEST]).value = nil;
  }
  
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_CARRIER_NAME]).value = self.appDelegate.carrierName;
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_CARRIER_COUNTRY]).value = self.appDelegate.countryCode;
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_CARRIER_NETWORK]).value = self.appDelegate.networkCode;
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_CARRIER_ISO]).value = self.appDelegate.isoCode;
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_PHONE]).value = self.appDelegate.deviceModel;
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_OS]).value = [[UIDevice currentDevice] systemVersion];
  ((SKATestOverviewMetrics*)[testResultsArray objectAtIndex:C_NUMBER_OF_TESTS + C_PM_TARGET]).value = @"*";
  
  showPassiveMetrics = YES;
  [self updateTableAnimated];
}

- (IBAction)B_SelectTests:(id)sender {
  
 self.casTestTypes = [[cActionSheet alloc] initOnView:self.view withDelegate:self mainTitle:NSLocalizedString(@"MenuAlert_OK",nil)];
 [self.casTestTypes addOption:NSLocalizedString(@"Test_Download",nil) withImage:nil andTag:C_DOWNLOAD_TEST andState:((self.testTypes2Execute & CTTBM_DOWNLOAD) == CTTBM_DOWNLOAD)];
 [self.casTestTypes addOption:NSLocalizedString(@"Test_Upload",nil) withImage:nil andTag:C_UPLOAD_TEST andState:((self.testTypes2Execute & CTTBM_UPLOAD) == CTTBM_UPLOAD)];
 [self.casTestTypes addOption:NSLocalizedString(@"Latency / Loss / Jitter",nil) withImage:nil andTag:C_LATENCY_TEST andState:((self.testTypes2Execute & CTTBM_LATENCYLOSSJITTER) == CTTBM_LATENCYLOSSJITTER)];
  
  [self.casTestTypes expand];
}

-(void)selectedMainButtonFrom:(cActionSheet *)sender
{
}

- (IBAction)B_Share:(id)sender
{
  SK_ASSERT(mpTestResult != nil);
  mpSharer = [[SKTestResultsSharer alloc] initWithViewController:self];
  [mpSharer shareTest:mpTestResult];
}

@end


