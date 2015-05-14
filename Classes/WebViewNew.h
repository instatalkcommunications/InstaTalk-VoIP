//
//  WebView.h
//  linphone
//
//  Created by lalit on 1/14/15.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"
@interface WebViewNew : UIViewController<UIWebViewDelegate, UICompositeViewDelegate>
{
    IBOutlet UIWebView *wview;
}
@property (strong) UINavigationBar* navigationBar;
@property(nonatomic,assign)BOOL login;
@property(nonatomic,assign)BOOL credit;
@property(nonatomic,assign)BOOL callId;
-(NSString*)GetUserPassword;
-(NSString*)GetUserName;
@end
