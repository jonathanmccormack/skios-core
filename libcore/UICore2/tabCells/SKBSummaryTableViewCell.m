//
//  SKBSummaryTableViewCell.m
//  SKCore
//
//  Created by Pete Cole on 30/09/2014.
//  Copyright (c) 2014 SamKnows. All rights reserved.
//

#import "SKBSummaryTableViewCell.h"

@implementation SKBSummaryTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  
    [super setSelected:NO animated:NO];
}

-(void)prepareWithTopLeftImage:(UIImage*)inTopLeftImage TopLeftTitle:(NSString*)inTopLeftTitle LeftAverageValue:(NSString*)inLeftAverageValue LeftAverageUnits:(NSString*)inLeftAverageUnits RightBestValue:(NSString*)inRightBestValue RightBestUnits:(NSString*)inRightBestUnits
{
  if (inTopLeftImage == nil) {
    self.topLeftImage.hidden = YES;
  } else {
    self.topLeftImage.hidden = NO;
    self.topLeftImage.image = inTopLeftImage;
  }
  
  self.topTitleLabel.text = inTopLeftTitle;
  self.leftAverageValueLabel.text = inLeftAverageValue;
  self.leftAverageUnitsLabel.text = inLeftAverageUnits;
  self.rightBestValueLabel.text = inRightBestValue;
  self.rightBestUnitsLabel.text = inRightBestUnits;
 
  //http://stackoverflow.com/questions/18878258/uitableviewcell-show-white-background-and-cannot-be-modified-on-ios7
  self.backgroundColor = [UIColor clearColor];
}

@end