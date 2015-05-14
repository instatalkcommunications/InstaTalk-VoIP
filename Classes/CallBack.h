//
//  CallBack.h
//  InstaTalk VoIP
//
//  Created by lalit on 3/3/15.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"

@interface CallBack : UIViewController<UICompositeViewDelegate,UITextFieldDelegate,UIAlertViewDelegate>
{
    IBOutlet UIButton *btnVerifyNumber;
    IBOutlet UITextView *lblNote;
    NSString *myUserName;
    IBOutlet UILabel *lblMyNumber;
    IBOutlet UIButton *btnInitiateCallback;
    IBOutlet UITextField *txtDestination;
}
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
- (IBAction)WhatsThis;
- (IBAction)VerifyNumber;
- (IBAction)ContactLookup;
- (IBAction)InitiateCallBack;
@property (strong) UINavigationBar* navigationBar;
@property(nonatomic,retain)IBOutlet UITextField *txtDestination;
@end
