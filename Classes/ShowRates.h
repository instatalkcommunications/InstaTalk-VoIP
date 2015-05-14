//
//  ShowRates.h
//  InstaTalk VoIP
//
//  Created by lalit on 3/5/15.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"
@interface ShowRates : UIViewController<UICompositeViewDelegate,UITextFieldDelegate>
{
    IBOutlet UITextField *txtDestination;
     IBOutlet UILabel *lblData;
}
@property (strong) UINavigationBar* navigationBar;
- (IBAction)GetAllRates;
- (IBAction)CheckRate;
- (IBAction)LoadContacts;
@property(nonatomic,retain)IBOutlet UITextField *txtDestination;
@end
