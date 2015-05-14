//
//  WebView.m
//  linphone
//
//  Created by lalit on 1/14/15.
//
//

#import "WebViewNew.h"
#import "MBProgressHUD.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
@interface WebViewNew ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    
}
@end

@implementation WebViewNew
@synthesize login,credit,callId;
-(void)setBusyCursorNew:(BOOL) busyFlag :(NSString *) message{
    
    if(busyFlag){
        self->HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self->HUD.color = [UIColor colorWithRed:207.0f/255.0f green:76.0f/255.0f blue:41.0f/255.0f alpha:0.8];
        self->HUD.labelText = message;
        self->HUD.delegate = self;
        self->HUD.detailsLabelText = @"Tap to cancel";
        [self->HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hudWasCancelled)]];
        [self->HUD show:true];
        
    }else {
        
            [self->HUD hide:YES];
    }
}
- (void)hudWasCancelled {
    if(HUD)
        [self->HUD hide:YES];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    if(self->HUD)
    {
        [self->HUD removeFromSuperview];
        self->HUD = nil;
   }
}
-(void)layoutNavigationBar{
    self.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, self.topLayoutGuide.length + 44);
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self layoutNavigationBar];
}

-(void)backButtonPressed
{
    [[PhoneMainView instance] popCurrentView];
}
-(void)viewDidAppear:(BOOL)animated
{
    login = false;
    credit = false;
    callId = false;
    wview.scalesPageToFit = YES;
    //[wview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    NSString *fullURL = @"";
   
    NSString *ttle = [[PhoneMainView instance] webViewType];
   
    if([ttle isEqualToString:@"Feedback"])
    {
        self.navigationItem.title = @"Feedback";
        fullURL = @"";
    }
    else if([ttle isEqualToString:@"Credits"])
    {
        self.navigationItem.title = @"Add Credits";
        fullURL = @"";
    }
    else if([ttle isEqualToString:@"CallerId"])
    {
        self.navigationItem.title = @"Manage CallerId";
        fullURL = @"";
    }
    else if([ttle isEqualToString:@"AllRates"])
    {
        self.navigationItem.title = @"Check Call Rates";
        fullURL = @"";
    }
    else if([ttle isEqualToString:@"Account"])
    {
        self.navigationItem.title = @"Create VoIP account";
        fullURL = @"";
    }
    
    [self setBusyCursorNew:true :@"Preparing View"];
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [wview loadRequest:requestObj];
    
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [[UINavigationBar appearance] setBarTintColor:[LINPHONE_MAIN_COLOR adjustHue:5.0f/180.0f saturation:0.0f brightness:0.0f alpha:0.0f]];
    
    [self.navigationController.view setBackgroundColor:[UIColor clearColor]];
    //[[UINavigationBar appearance] setTranslucent:YES];
    [self.view addSubview:_navigationBar];
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolsbar_background.png"] forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *_backButton = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonPressed)];
    self.navigationItem.leftBarButtonItem = _backButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    float ver = [[NSUserDefaults standardUserDefaults] floatForKey:@"appversion"];
    
    if (!ver || ver != [version floatValue]) {
        [[NSUserDefaults standardUserDefaults] setFloat:[version floatValue] forKey:@"appversion"];
        [self ClearCache];
    }
}

-(void)ClearCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        
        if([[cookie domain] isEqualToString:@""]) {
            
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

-(NSString*)GetUserName{
    NSString *username = @"";
    
    LinphoneCore *lc=[LinphoneManager getLc];
    if (linphone_core_is_network_reachable(lc)) {
       
        LinphoneProxyConfig *cfg=NULL;
        
        linphone_core_get_default_proxy(lc,&cfg);
        if (cfg){
            const char *identity=linphone_proxy_config_get_identity(cfg);
            LinphoneAddress *addr=linphone_address_new(identity);
            if (addr){
                username =  [NSString stringWithCString:linphone_address_get_username(addr) encoding:[NSString defaultCStringEncoding]];
            }
        }
    }
        return username;
}
-(NSString*)GetUserPassword
{
    NSString *password = @"";
    LinphoneCore *lc=[LinphoneManager getLc];
    LinphoneAuthInfo *ai;
    const MSList *elem=linphone_core_get_auth_info_list(lc);
    if (elem && (ai=(LinphoneAuthInfo*)elem->data)){
        password = [NSString stringWithCString:linphone_auth_info_get_passwd(ai) encoding:[NSString defaultCStringEncoding]];
        
    }
    
    return password;
}
-(void)webViewDidStartLoad:(UIWebView *)webView {
 
}

-(void)LoginUserFeedback
{
    if(!login)
    {
       NSString *tmpStr = @"";
       tmpStr = @"";
       NSString *userName = [NSString stringWithFormat:@"$('#username').val('%@');",[self GetUserName]];
       NSString *password =  [NSString stringWithFormat:@"$('#passwd').val('%@');",[self GetUserPassword]];
        
       tmpStr = [NSString stringWithFormat:@"%@%@%@",tmpStr,userName,password];
       tmpStr = [NSString stringWithFormat:@"%@%@",tmpStr,@"$('form#clientLogin').submit();"];
          [self setBusyCursorNew:true :@"Preparing View"];
       [wview stringByEvaluatingJavaScriptFromString:tmpStr];
       
       login = true;
    }
}
-(void)LoginUser
{
    if(!login)
    {
        NSString *tmpStr = @"";
        //tmpStr = @"$('a').each(function(){var hrf= $(this).attr('href');if(hrf =='#login'){$(this).trigger('click');}});";
        tmpStr = @"$('a[href=\"#login\"]').trigger('click');";
        NSString *userName = [NSString stringWithFormat:@"$('#UserName').val('%@');",[self GetUserName]];
        NSString *password =  [NSString stringWithFormat:@"$('#Password').val('%@');",[self GetUserPassword]];
        
        tmpStr = [NSString stringWithFormat:@"%@%@%@",tmpStr,userName,password];
        tmpStr = [NSString stringWithFormat:@"%@%@",tmpStr,@"$('form#formLogin').submit();"];
          [self setBusyCursorNew:true :@"Preparing View"];
        [wview stringByEvaluatingJavaScriptFromString:tmpStr];
        
        login = true;
    }
}
-(void)AddCredits
{
    if(login && !credit)
    {
        //$('.addCredits').trigger('click');
        NSString *tmpStr = @"window.location = '';";
          [self setBusyCursorNew:true :@"Preparing View"];
        [wview stringByEvaluatingJavaScriptFromString:tmpStr];
        
        credit = true;
    }
}
-(void)ShowChangeCallerId
{
    if(login && !credit)
    {
        NSString *tmpStr = @"window.location = '';";
        
        [wview stringByEvaluatingJavaScriptFromString:tmpStr];
        
       
        
        credit = true;
        
    }
    else if(login && credit && !callId)
    {
        NSString *tmpStr1 = @"$('a[href=\"#changeCLI\"]').trigger('click');";
        [wview stringByEvaluatingJavaScriptFromString:tmpStr1];
        callId = true;
    }
}
- (void)webViewDidFinishLoad:(UIWebView *)WebView;
{
    [self setBusyCursorNew:false :@"Preparing View"];
    NSString *ttle = [[PhoneMainView instance] webViewType];
    
    if([ttle isEqualToString:@"Credits"])
    {
       if(login)
            [self AddCredits];
        else
            [self LoginUser];
       
    }
    else if([ttle isEqualToString:@"Feedback"])
    {
        [self LoginUserFeedback];
    }
    else if([ttle isEqualToString:@"CallerId"])
    {
        if(login)
            [self ShowChangeCallerId];
        else
            [self LoginUser];
    }
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"WebViewNew"
                                                                content:@"WebViewNew"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar: @"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
}
- (void)viewWillDisappear:(BOOL)animated
{
    if([wview isLoading])
    {
        [wview stopLoading];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
