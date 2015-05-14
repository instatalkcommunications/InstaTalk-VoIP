//
//  Accounts.m
//  linphone
//
//  Created by lalit on 12/20/14.
//
//

#import "Accounts.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import "ASIHTTPRequest.h"
#import "SBJson.h"
#import "WebViewNew.h"
#import "BilledCalls.h"
#import "LinphoneAppDelegate.h"
#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"
#import "HIQCache.h"

@interface Accounts ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    ASIFormDataRequest *request;
    HIQCache *hiqCache;
}
@end

@implementation Accounts
@synthesize navigationController;

-(void)viewDidAppear:(BOOL)animated
{
    const MSList* list = linphone_core_get_proxy_config_list([LinphoneManager getLc]);
    if(list != NULL) {
        LinphoneProxyConfig *config = (LinphoneProxyConfig*) list->data;
        if(config) {
            [self registrationUpdate:linphone_proxy_config_get_state(config)];
        }
        else{
            lblBalance.text = @"Account not configured!";
            btnCallerId.enabled = false;
            btnCredits.enabled = false;
            btnViewCalls.enabled = false;
        }
    }
    else{
        lblBalance.text = @"Account not configured!";
        btnCallerId.enabled = false;
        btnCredits.enabled = false;
        btnViewCalls.enabled = false;
    }
     [self GetAlert];
}

- (void)viewDidLoad {
    [super viewDidLoad];
     hiqCache = [[HIQCache alloc] init];
    
    btnCallerId.enabled = false;
    btnCredits.enabled = false;
    btnViewCalls.enabled = false;
    btnFeedback.enabled=false;
    self.navigationItem.title = @"Accounts";
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [[UINavigationBar appearance] setBarTintColor:[LINPHONE_MAIN_COLOR adjustHue:5.0f/180.0f saturation:0.0f brightness:0.0f alpha:0.0f]];
    
    [self.navigationController.view setBackgroundColor:[UIColor clearColor]];
    self.title = @"Accounts";
    //[[UINavigationBar appearance] setTranslucent:YES];
    [self.view addSubview:_navigationBar];
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolsbar_background.png"] forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStylePlain target:self action:@selector(AboutClick:)];
    self.navigationItem.rightBarButtonItem = buttonItem;
    [buttonItem release];

   
       
}
-(void)layoutNavigationBar{
    self.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, self.topLayoutGuide.length + 40);
}

- (IBAction)AboutClick: (id)sender {
    [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
   
    [self layoutNavigationBar];
}
-(void)GetBalance
{
    
        //[request cancel];
        //[request clearDelegatesAndCancel];
        NSString *username = @"";//[[LinphoneManager instance] lpConfigStringForKey:@"username_preference"];
   
    LinphoneCore *lc=[LinphoneManager getLc];
     if (linphone_core_is_network_reachable(lc)) {
    LinphoneProxyConfig *cfg=NULL;
    
    linphone_core_get_default_proxy(lc,&cfg);
    if (cfg){
        const char *identity=linphone_proxy_config_get_identity(cfg);
        LinphoneAddress *addr=linphone_address_new(identity);
        if (addr){
            username =  [NSString stringWithCString:linphone_address_get_username(addr) encoding:[NSString defaultCStringEncoding]];
            lblBalance.text = @"Your balance: $...";
            SecIdentityRef myIdentity;
            [LinphoneAppDelegate extractIdentity:&myIdentity];
            
            NSString *timestamp = [NSString stringWithFormat:@"%f",[LinphoneAppDelegate GetTimeStamp]];
            
            NSString *Parms = [NSString stringWithFormat:@"%@%@",timestamp,username];
            NSString *Signature = [LinphoneAppDelegate SignRequest:Parms];
            
            NSString *url = [NSString stringWithFormat:@""];
            request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
            
            // In this case, we have no need to add extra certificates, just the one inside the indentity will be used
            [request setValidatesSecureCertificate:YES];
            [request setClientCertificateIdentity:myIdentity];
            [request setPostValue:Signature forKey:@"h"];
            [request setPostValue:timestamp forKey:@"t"];
            [request setPostValue:username forKey:@"user"];
            [request setRequestMethod:@"POST"];
            [request setTag:1];
            [request setDelegate:self];
            [request setTimeOutSeconds:30];
            [request startAsynchronous];
            }
        }
     }
}


-(void)GetAlert
{
    LinphoneCore *lc=[LinphoneManager getLc];
    if (linphone_core_is_network_reachable(lc)) {
    
                   NSString *url = [NSString stringWithFormat:@""];
                request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
                
                // In this case, we have no need to add extra certificates, just the one inside the indentity will be used
    
                [request setRequestMethod:@"GET"];
                [request setTag:0];
                [request setDelegate:self];
                [request setTimeOutSeconds:15];
                [request startAsynchronous];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) requestFinished:(ASIFormDataRequest *)request1
{
    NSString *responseString = [request1 responseString];
    
    [self setBusyCursorNew:false :@""];
    
    if(request1.tag==0)
    {
        if([responseString length]>0)
        {
            SBJsonParser *parser = [[SBJsonParser alloc] init] ;
            NSArray *arr = [parser objectWithString:responseString];
            arrAlerts = [[NSMutableArray alloc] init];
            
            @try
            {
                NSString *strAlerts = @"";
                
                for(NSDictionary *item in arr)
                {
                    NSString *strId = [item valueForKey:@"id"];
                    NSString *strData = [item valueForKey:@"data"];
                    NSString *data = [hiqCache GetCacheDataForKey:strId];
                    
                    if(data==nil)
                    {
                        if([strData length]>0)
                        {
                            [arrAlerts addObject:strId];
                            strAlerts = [NSString stringWithFormat:@"%@%@",strAlerts,strData];
                        }
                    }
                }
                
                if([arrAlerts count]>0)
                    [self ShowAlert:strAlerts];
                
            }
            @catch(NSException *ex){
                
            }
        }
    }
    else if(request1.tag==1)
    {
        SBJsonParser *parser = [[SBJsonParser alloc] init] ;
        
        NSObject *item = [parser objectWithString:responseString];
        
        @try
        {
            
            lblBalance.text = [NSString stringWithFormat:@"Your balance: $%.2f",[[item valueForKey:@"balance"] floatValue]];
            
        }
        @catch(NSException *ex){
        
        }
        
    }
    else if(request1.tag==2)
    {
        @try
        {
            if([responseString isEqualToString:@"notset"])
            {
                UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Alert!"
                                                                           message:@"You have not configured VoIP account in this app. To configure please go to the settings and run assistant. If you do not have a VoIP account, then register by clicking the Create VoIP Account button in account screen"
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"Ok"
                                                                 otherButtonTitles:nil];
                
                [InitiateCallBack show];
                [InitiateCallBack release];
            }
            else
            {
                UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"+%@",responseString]
                                                                           message:@"This number will be shown to the person receiving your calls, click 'Change' to verify/change it to your personal number and set it as your Caller Id\n\nNote: By default, this number will be same as your VoIP account number."
                                                                          delegate:self
                                                                 cancelButtonTitle:@"Cancel"
                                                                 otherButtonTitles:@"Change", nil];
                InitiateCallBack.tag =1;
                [InitiateCallBack show];
                [InitiateCallBack release];
            }
            
        }
        @catch(NSException *ex){
            
        }
    }
}

- (void) requestFailed:(ASIFormDataRequest *) request1
{
    NSError *error = [request1 error];
    NSLog(@"%@", error);
     [self setBusyCursorNew:false :@""];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
   // [scrlView setContentSize:CGSizeMake(scrlView.contentSize.width,2000)];
}
- (IBAction)onAboutClick: (id)sender {
    [[PhoneMainView instance] changeCurrentView:[SettingsViewController compositeViewDescription] push:TRUE];
    
}
- (IBAction)RateUs: (id)sender {
    [LinphoneAppDelegate RateUS];
    
}
- (IBAction)CheckRates
{
    [[PhoneMainView instance] changeCurrentView:[ShowRates compositeViewDescription] push:TRUE];
}
- (IBAction)CallerId{
    [self GetMyNumber];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger cancelIndex = [alertView cancelButtonIndex];
    
    if(alertView.tag==1)
    {
        
        if (cancelIndex != -1 && cancelIndex == buttonIndex)
        {
            
        }
        else
        {
            [[PhoneMainView instance] changeCurrentView:[WebViewNew compositeViewDescription] push:TRUE];
            [PhoneMainView instance].webViewType = @"CallerId";
        }
    }
    else if(alertView.tag==0){
        if (cancelIndex != -1 && cancelIndex == buttonIndex)
        {
            
        }
        else
        {
            if([arrAlerts count]>0)
            {
                for(NSString *item in arrAlerts)
                {
                   [hiqCache cacheURLData:item:@""];
                }
            }
        }
    }
}
-(void)setBusyCursorNew:(BOOL) busyFlag :(NSString *) message{
    
    if(busyFlag){
        self->HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self->HUD.color = [UIColor colorWithRed:207.0f/255.0f green:76.0f/255.0f blue:41.0f/255.0f alpha:0.8];
        self->HUD.labelText = message;
        self->HUD.delegate = self;
        [self->HUD show:true];
        
    }else {
        if(HUD!=nil)
        [self->HUD hide:YES];
    }
}
- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    
    HUD = nil;
}
- (void)hudWasCancelled {
    [self->HUD hide:YES];
    [request cancel];
    [request clearDelegatesAndCancel];
}

-(void)GetMyNumber{
   
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
                
                SecIdentityRef myIdentity;
                [LinphoneAppDelegate extractIdentity:&myIdentity];
                
                
                NSString *timestamp = [NSString stringWithFormat:@"%f",[LinphoneAppDelegate GetTimeStamp]];
                NSString *Parms = [NSString stringWithFormat:@"%@%@",timestamp,username];
                NSString *Signature = [LinphoneAppDelegate SignRequest:Parms];
                
                [self setBusyCursorNew:true :@"Fetching your Caller Id..."];
                NSString *url = [NSString stringWithFormat:@""];
                request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
                
                // In this case, we have no need to add extra certificates, just the one inside the indentity will be used
                [request setValidatesSecureCertificate:YES];
                [request setClientCertificateIdentity:myIdentity];
                [request setPostValue:Signature forKey:@"h"];
                [request setPostValue:timestamp forKey:@"t"];
                [request setPostValue:username forKey:@"user"];
                [request setRequestMethod:@"POST"];
                [request setTag:2];
                [request setDelegate:self];
                [request setTimeOutSeconds:30];
                [request startAsynchronous];
                
            }
        }
        else{
            UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Alert!"
                                                                       message:@"You have not configured VoIP account in this app. To configure please go to the settings and run assistant. If you do not have a VoIP account, then register by clicking the Create VoIP Account button in account screen"
                                                                      delegate:nil
                                                             cancelButtonTitle:@"Ok"
                                                             otherButtonTitles:nil];
           
            [InitiateCallBack show];
            [InitiateCallBack release];
        }
    }
}
- (IBAction)BilledCalls {
   [[PhoneMainView instance] changeCurrentView:[BilledCalls compositeViewDescription] push:TRUE];
}
- (IBAction)AddCredits {
    [[PhoneMainView instance] changeCurrentView:[WebViewNew compositeViewDescription] push:TRUE];
    [PhoneMainView instance].webViewType = @"Credits";
}
- (IBAction)Feedback {
    [[PhoneMainView instance] changeCurrentView:[WebViewNew compositeViewDescription] push:TRUE];
    [PhoneMainView instance].webViewType = @"Feedback";
}
- (IBAction)CreateAccount
{
    [[PhoneMainView instance] changeCurrentView:[WebViewNew compositeViewDescription] push:TRUE];
    [PhoneMainView instance].webViewType = @"Account";
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
     
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
}
- (void)registrationUpdateEvent:(NSNotification*)notif {
    //NSString* message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey: @"state"] intValue]];
}
- (void)registrationUpdate:(LinphoneRegistrationState)state {
    switch (state) {
        case LinphoneRegistrationOk: {
            //[waitView setHidden:true];
            [self GetBalance];
            btnCallerId.enabled = true;
            btnCredits.enabled = true;
            btnViewCalls.enabled = true;
            btnFeedback.enabled=true;
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:kLinphoneRegistrationUpdate
                                                          object:nil];
            break;
        }
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared:  {
            btnCallerId.enabled = false;
            btnCredits.enabled = false;
            btnViewCalls.enabled = false;
            btnFeedback.enabled=false;
             lblBalance.text = @"Account not configured!";
            break;
        }
        case LinphoneRegistrationFailed: {
            btnCallerId.enabled = false;
            btnCredits.enabled = false;
            btnViewCalls.enabled = false;
            btnFeedback.enabled=false;
             lblBalance.text = @"Registration Failed!";
            break;
        }
        case LinphoneRegistrationProgress: {
            btnCallerId.enabled = false;
            btnCredits.enabled = false;
            btnViewCalls.enabled = false;
            btnFeedback.enabled=false;
            lblBalance.text = @"Registration in progress...";
            break;
        }
        default:
            break;
    }
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Accounts"
                                                                content:@"Accounts"
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

- (void)dealloc {
    
   
   
   
    [super dealloc];
}


- (void)ShowAlert:(NSString*)html {
   
    UIWebView *webView = [[UIWebView alloc] init];
    [webView setFrame:CGRectMake(0,0,200,150)];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    [webView loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:nil];
    webView.delegate = self;
    [webView setBackgroundColor:[UIColor clearColor]];
    [webView setOpaque:NO];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!" message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Don't show again", nil];
    [av setValue:webView forKey:@"accessoryView"];
    av.tag=0;
    av.delegate=self;
    [av show];
}

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}



@end