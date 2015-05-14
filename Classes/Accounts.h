//
//  Accounts.h
//  linphone
//
//  Created by lalit on 12/20/14.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"

@interface Accounts : UIViewController<UICompositeViewDelegate,UIAlertViewDelegate,UIWebViewDelegate>
{
    IBOutlet UILabel *lblBalance;
    IBOutlet UIButton *btnViewCalls;
    IBOutlet UIButton *btnCallerId;
    IBOutlet UIButton *btnCredits;
    IBOutlet UIButton *btnFeedback;
    NSMutableArray *arrAlerts;
    
}

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
- (IBAction)onAboutClick: (id)sender;
- (IBAction)BilledCalls;
- (IBAction)AddCredits;
- (IBAction)Feedback;
- (IBAction)CallerId;
- (IBAction)CheckRates;
- (IBAction)CreateAccount;
@property (strong) UINavigationBar* navigationBar;
- (void)ShowAlert:(NSString*)html;



@end
