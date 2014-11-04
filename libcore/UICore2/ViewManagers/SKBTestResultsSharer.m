//
//  SKBTestResultsSharer.m
//  SKCore
//
//  Created by Pete Cole on 07/10/2014.
//  Copyright (c) 2014 SamKnows. All rights reserved.
//

#import "SKBTestResultsSharer.h"

@interface SKBTestResultsSharer()
@property (nonatomic, strong) cActionSheet* casShare;
@property (nonatomic, strong) SKATestResults* selectedTest;

@property (nonatomic, strong) UIViewController* masterViewController;
@end


@implementation SKBTestResultsSharer

@synthesize selectedTest;

- (instancetype)initWithViewController:(UIViewController*)inViewController
{
  self = [super init];
  if (self) {
    self.masterViewController = inViewController;
  }
  return self;
}

-(void)shareTest:(SKATestResults*)testResult
{
  selectedTest = testResult;
  
  self.casShare = [[cActionSheet alloc] initOnView:self.masterViewController.view withDelegate:self mainTitle:sSKCoreGetLocalisedString(@"MenuAlert_Cancel")];
  
  if ([[SKAAppDelegate getAppDelegate] isFacebookExportSupported]) {
    [self.casShare addOption:@"Facebook" withImage:[UIImage imageNamed:@"share-facebook"] andTag:C_SHARE_FACEBOOK];
  }
  
  if ([[SKAAppDelegate getAppDelegate] isTwitterExportSupported]) {
    [self.casShare addOption:@"Twitter" withImage:[UIImage imageNamed:@"share-twitter"] andTag:C_SHARE_TWITTER];
  }
  
  if ([MFMailComposeViewController canSendMail]) {
    [self.casShare addOption:@"Email" withImage:[UIImage imageNamed:@"share-mail"] andTag:C_SHARE_MAIL];
  }
  
  [self.casShare addOption:@"Save" withImage:[UIImage imageNamed:@"share-save"] andTag:C_SHARE_SAVE];
  
  [self.casShare expand];
}

-(void)selectedOption:(int)optionTag from:(cActionSheet*)sender WithState:(int)state {
  
  if (sender == self.casShare)
  {
    UIImage* imageToShare = [SKATestResults generateSocialShareImage:selectedTest];
    
    switch (optionTag) {
      case C_SHARE_FACEBOOK:
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
          SLComposeViewController*fvc = [SLComposeViewController
                                         composeViewControllerForServiceType:SLServiceTypeFacebook];
          [fvc setInitialText:[selectedTest getTextForSocialMedia:(NSString*)SLServiceTypeFacebook]];
          [fvc addImage:imageToShare];
          [self.masterViewController presentViewController:fvc animated:YES completion:nil];
        }
        break;
      case C_SHARE_TWITTER:
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
          SLComposeViewController*fvc = [SLComposeViewController
                                         composeViewControllerForServiceType:SLServiceTypeTwitter];
          [fvc setInitialText:[selectedTest getTextForSocialMedia:(NSString*)SLServiceTypeTwitter]];
          [fvc addImage:imageToShare];
          [self.masterViewController presentViewController:fvc animated:YES completion:nil];
        }
        break;
      case C_SHARE_MAIL:
        
        [self sendMailWithImage:imageToShare];
        
        break;
      case C_SHARE_SAVE:
        
        UIImageWriteToSavedPhotosAlbum(imageToShare, nil, nil, nil);
        
        break;
      default:
        break;
    }
  }
}

-(void)selectedMainButtonFrom:(cActionSheet*)sender {
}


- (void)sendMailWithImage:(UIImage *)image
{
  if ([MFMailComposeViewController canSendMail])
  {
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    if (mailController != nil) {
      mailController.mailComposeDelegate = self;
      NSData *imageData =  UIImageJPEGRepresentation(image, 0.97f);
      [mailController addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"NetworkTestResult.jpg"];
      [mailController setSubject:@""];
      [mailController setMessageBody:@"" isHTML:NO];
      [self.masterViewController presentViewController:mailController animated:YES completion:nil];
    }
    else
    {
      //Do something like show an alert
    }
  }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
  
  [controller dismissViewControllerAnimated:YES completion:nil];
}
@end

///

