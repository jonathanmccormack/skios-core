//
//  SKBHistoryViewMgr.h
//  SKCore
//

//  Copyright (c) 2014 SamKnows. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
//#import <MessageUI/MFMailComposeViewController.h>
//#import "cActionSheet.h"
#import "../tabCells/SKBTestOverviewCell.h"

@class SKATestResults;



@interface SKBHistoryViewMgr : UIView <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate> // , UIActionSheetDelegate>
{
  NSMutableArray *arrTestsList;
  
  SKATestResults* selectedTest;
  
  C_FILTER_NETWORKTYPE currentFilterNetworkType;
  C_FILTER_PERIOD      currentFilterPeriod;
  
  int testHeight;
  int expandedRow;
  
  SKBTestOverviewCell* cell2putBack;
  UIView* view2putBack;
  CGRect originalCellFrame;
  
  NSMutableArray* arrPassiveLabelsAndValues;
  float mPassiveMetricsY;
}

@property (nonatomic, weak) UIView* masterView;
@property (nonatomic, weak) UIViewController* masterViewController;

@property (weak, nonatomic) IBOutlet UITableView *tvTests;
@property (weak, nonatomic) IBOutlet UIButton *btBack;

//@property (nonatomic, strong) cActionSheet* casNetworkType;
//@property (nonatomic, strong) cActionSheet* casPeriod;

+(SKATestResults *) sCreateNewTstToShareExternal;
+(SKATestResults *) sGetTstToShareExternal;

-(void)shareTest:(SKATestResults*)testResult;
- (IBAction)B_Back:(id)sender;
- (IBAction)B_Share:(id)sender;

-(void)intialiseViewOnMasterViewController:(UIViewController*)masterViewController_;
-(void)setColoursAndShowHideElements;
-(void)performLayout;

//@property (weak, nonatomic) IBOutlet UIButton *btNetworkType;
//@property (weak, nonatomic) IBOutlet UIButton *btPeriod;
//@property (weak, nonatomic) IBOutlet UIButton *btGraph;
@property (weak, nonatomic) IBOutlet UIButton *btShare;

//@property (retain, nonatomic) IBOutlet NSLayoutConstraint* backButtonHeightConstraint;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint* shareButtonTopOffsetConstraint;

@end
