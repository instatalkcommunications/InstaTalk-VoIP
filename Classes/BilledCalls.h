//
//  BilledCalls.h
//  linphone
//
//  Created by lalit on 12/24/14.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"
#import <AddressBook/AddressBook.h>
#import "Contact.h"
#import "OrderedDictionary.h"

@interface BilledCalls : UITableViewController<UICompositeViewDelegate>
{
    NSMutableArray *arrCalls;

}
@property (strong) UINavigationBar* navigationBar;
+ (NSString *)nameForContactWithPhoneNumber:(NSString *)phoneNumber;
+ (UIImage *)photoForContactWithPhoneNumber:(NSString *)phoneNumber;
//- (void)loadData;
@end
