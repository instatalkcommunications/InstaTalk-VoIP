//
//  CallBack.m
//  InstaTalk VoIP
//
//  Created by lalit on 3/3/15.
//
//

#import "CallBack.h"
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

@interface CallBack ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    ASIFormDataRequest *request;
}
@end

@implementation CallBack


@synthesize navigationController,txtDestination;

-(void)viewDidAppear:(BOOL)animated
{
    const MSList* list = linphone_core_get_proxy_config_list([LinphoneManager getLc]);
    if(list != NULL) {
        LinphoneProxyConfig *config = (LinphoneProxyConfig*) list->data;
        if(config) {
           // [self registrationUpdate:linphone_proxy_config_get_state(config)];
        }
    }
    
     [self GetMyNumber];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [txtDestination resignFirstResponder];
}
- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.navigationItem.title = @"Request a Callback";
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [[UINavigationBar appearance] setBarTintColor:[LINPHONE_MAIN_COLOR adjustHue:5.0f/180.0f saturation:0.0f brightness:0.0f alpha:0.0f]];
    
    [self.navigationController.view setBackgroundColor:[UIColor clearColor]];
   //[[UINavigationBar appearance] setTranslucent:YES];
    [self.view addSubview:_navigationBar];
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolsbar_background.png"] forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"?", nil) style:UIBarButtonItemStylePlain target:self action:@selector(WhatsThis)];
    self.navigationItem.rightBarButtonItem = buttonItem;
    [buttonItem release];
    
    //lblNote.text = @"Low on data pack OR fedup of slow network? try Callback. It does not require internet for calling!.\n\nOnce you enter the destination number and click Initiate Callback button, the applicable call rates will first be displayed. Once you confirm, the system will first connect you on your verified number. Upon getting connected, do wait for a few secs, the system will connect to the destination number.\n\n*Note: You will be charged for both the calls i.e. call to your number and call to the destination number.";
    
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
                           //[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelNumberPad)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
                           nil];
    [numberToolbar sizeToFit];
    //txtDestination.inputAccessoryView = numberToolbar;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapped:)];
    
    [lblNote addGestureRecognizer:tap];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 30)];
    txtDestination.leftView = paddingView;
    txtDestination.leftViewMode = UITextFieldViewModeAlways;
}
- (void)textTapped:(UITapGestureRecognizer *)recognizer
{
    [txtDestination resignFirstResponder];
}
-(void)cancelNumberPad{
    [txtDestination resignFirstResponder];
    txtDestination.text = @"";
}

-(void)doneWithNumberPad{
    //NSString *numberFromTheKeyboard = addressField.text;
    [txtDestination resignFirstResponder];
}
-(void)setBusyCursorNew:(BOOL) busyFlag :(NSString *) message{
    
    if(busyFlag){
        self->HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self->HUD.color = [UIColor colorWithRed:207.0f/255.0f green:76.0f/255.0f blue:41.0f/255.0f alpha:0.8];
        self->HUD.labelText = message;
        self->HUD.delegate=self;
        [self->HUD show:true];
        
    }else {
        
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
    btnInitiateCallback.enabled = false;
    lblMyNumber.text=@"loading...";
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
                myUserName = username;
            
        
                SecIdentityRef myIdentity;
                [LinphoneAppDelegate extractIdentity:&myIdentity];
                
                [self setBusyCursorNew:true :@"Fetching your verified number..."];
                
                
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
        else
             lblMyNumber.text=@"Account not set";
    }
}
-(void)StartCallBack{
   
    
    NSString *username = @"";
    NSString *password = @"";
    LinphoneCore *lc=[LinphoneManager getLc];
    
    if (linphone_core_is_network_reachable(lc)) {
        [self setBusyCursorNew:true :@"Initiating callback..."];
        LinphoneProxyConfig *cfg=NULL;
        
        linphone_core_get_default_proxy(lc,&cfg);
        if (cfg)
        {
         
            const char *identity=linphone_proxy_config_get_identity(cfg);
            LinphoneAddress *addr=linphone_address_new(identity);
            if (addr){
                username =  [NSString stringWithCString:linphone_address_get_username(addr) encoding:[NSString defaultCStringEncoding]];
            }
            
            LinphoneAuthInfo *ai;
            const MSList *elem=linphone_core_get_auth_info_list(lc);
            if (elem && (ai=(LinphoneAuthInfo*)elem->data)){
                password = [NSString stringWithCString:linphone_auth_info_get_passwd(ai) encoding:[NSString defaultCStringEncoding]];;
            }
            
            
            SecIdentityRef myIdentity;
            [LinphoneAppDelegate extractIdentity:&myIdentity];
            
            NSString *timestamp = [NSString stringWithFormat:@"%f",[LinphoneAppDelegate GetTimeStamp]];
            NSString *Parms = [NSString stringWithFormat:@"%@%@%@",timestamp,username,lblMyNumber.text];
            NSString *Signature = [LinphoneAppDelegate SignRequest:Parms];
            NSString *url = [NSString stringWithFormat:@""];
            request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
            
            
            [request setValidatesSecureCertificate:YES];
            [request setClientCertificateIdentity:myIdentity];
            [request setPostValue:Signature forKey:@"h"];//h= hmacSha1Digest(timeStamp + username+fromMob, "secretkeyyy")
            [request setPostValue:timestamp forKey:@"t"];
            [request setPostValue:username forKey:@"user"];
            [request setPostValue:password forKey:@"pass"];
            
            [request setPostValue:lblMyNumber.text forKey:@"from"];
            [request setPostValue:txtDestination.text forKey:@"to"];
            [request setRequestMethod:@"POST"];
            [request setTag:3];
            [request setDelegate:self];
            [request setTimeOutSeconds:30];
            [request startAsynchronous];
        }
    }
}
-(void)GetCallRates{
    
    
    [txtDestination resignFirstResponder];
    txtDestination.text = [LinphoneAppDelegate FormatPhoneNumber:txtDestination.text];
    if([txtDestination.text length]>2)
    {
        
        LinphoneCore *lc=[LinphoneManager getLc];
        if (linphone_core_is_network_reachable(lc)) {
            [self setBusyCursorNew:true :@"Fetching call rates..."];
            SecIdentityRef myIdentity;
            [LinphoneAppDelegate extractIdentity:&myIdentity];
            
            
            NSString *url = [NSString stringWithFormat:@""];
            request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
            
            // In this case, we have no need to add extra certificates, just the one inside the indentity will be used
            [request setValidatesSecureCertificate:YES];
            [request setClientCertificateIdentity:myIdentity];
            [request setPostValue:lblMyNumber.text forKey:@"from"];
            [request setPostValue:txtDestination.text forKey:@"to"];
            
            [request setRequestMethod:@"POST"];
            [request setTag:2];
            [request setDelegate:self];
            [request setTimeOutSeconds:30];
            [request startAsynchronous];
        }
    }
}
- (void) requestFinished:(ASIFormDataRequest *)request1
{
     [self setBusyCursorNew:false :@""];
    NSString *responseString = [request1 responseString];
    responseString = [request1 responseString];
    
    if(request1.tag==1)
    {
        //SBJsonParser *parser = [[SBJsonParser alloc] init] ;
        
        //NSObject *item = [parser objectWithString:responseString];
        
        
        @try
        {
          if([responseString isEqualToString:@"notset"])
          {
              lblMyNumber.text = @"Account not set";
              btnVerifyNumber.hidden = true;
              btnInitiateCallback.enabled = false;
              UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Alert!"
                                                                         message:@"You have not configured VoIP account in this app. To configure please go to the settings and run assistant. If you do not have a VoIP account, then register by clicking the Create VoIP Account button in account screen"
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Ok"
                                                               otherButtonTitles:nil];
              
              [InitiateCallBack show];
              [InitiateCallBack release];
          }
          else if([responseString isEqualToString:[NSString stringWithFormat:@"1%@",myUserName]])
          {
              lblMyNumber.text = @"";
              btnVerifyNumber.hidden = false;
              btnInitiateCallback.enabled = false;
              UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Your number is not verified!"
                                                                         message:[NSString stringWithFormat:@"Please verify your mobile number by clicking the verify number to start using the callback feature."]
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Ok"
                                                               otherButtonTitles:nil];
              [InitiateCallBack show];
              [InitiateCallBack release];
          }
          else
          {
              lblMyNumber.text = responseString;
              btnVerifyNumber.hidden = true;
              btnInitiateCallback.enabled = true;
          }
            
        }
        @catch(NSException *ex){
            btnInitiateCallback.enabled = false;
        }
        
    }
    else if(request1.tag==2)
    {
        SBJsonParser *parser = [[SBJsonParser alloc] init] ;
        
        NSDictionary *item = [parser objectWithString:responseString];
        
        @try {
            NSString *total=@"";
            NSString *to=@"";
            NSString *from=@"";
            NSString *toRate=@"";
            NSString *fromRate=@"";
            
            for (NSString* key in item) {
                if([key isEqualToString:@"total"])
                    total = [NSString stringWithFormat:@"%.2f ¢/min",[[item objectForKey:key] floatValue]*100];
                else if ([key rangeOfString:@"to#" options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    to = [key stringByReplacingOccurrencesOfString:@"to#" withString:@""];
                    toRate = [NSString stringWithFormat:@"%.2f ¢/min",[[item objectForKey:key] floatValue]*100];
                }
                else if ([key rangeOfString:@"from#" options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    from = [key stringByReplacingOccurrencesOfString:@"from#" withString:@""];
                    fromRate = [NSString stringWithFormat:@"%.2f ¢/min",[[item objectForKey:key] floatValue]*100];
                }
            }
            
            
            if([item count]>0)
            {
                UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Confirm!"
                                                                       message:[NSString stringWithFormat:@"The rates applicable are as under\n\nFrom %@: %@\nTo %@: %@\nTotal: %@",from,fromRate,to,toRate,total]
                                                                      delegate:self
                                                             cancelButtonTitle:@"Cancel"
                                                             otherButtonTitles:@"Start Callback", nil];
                InitiateCallBack.tag =1;
                [InitiateCallBack show];
                [InitiateCallBack release];
            
            }
            else
            {
                UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Destination not supported!"
                                                                           message:[NSString stringWithFormat:@"Sorry! the callback between your number and the destination number is currently not supported."]
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"Ok"
                                                                 otherButtonTitles:nil];
                [InitiateCallBack show];
                [InitiateCallBack release];
            }
        }
        @catch (NSException *exception) {
            UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Destination not supported!"
                                                                       message:[NSString stringWithFormat:@"Sorry! the callback between your number and the destination number is currently not supported."]
                                                                      delegate:nil
                                                             cancelButtonTitle:@"Ok"
                                                             otherButtonTitles:nil];
            [InitiateCallBack show];
            [InitiateCallBack release];
        }
        
    }
    else if(request1.tag==3)
    {
        SBJsonParser *parser = [[SBJsonParser alloc] init] ;
        
        NSDictionary *item = [parser objectWithString:responseString];
        NSString *success = [item objectForKey:@"status"];
        NSString *desc = [item objectForKey:@"desp"];
        if([success isEqualToString:@"success"])
        {
            UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                       message:desc
                                                                      delegate:nil
                                                             cancelButtonTitle:@"Ok"
                                                             otherButtonTitles:nil];
            [InitiateCallBack show];
            [InitiateCallBack release];
        }
        else if([success isEqualToString:@"failed"])
        {
            UIAlertView* InitiateCallBack = [[UIAlertView alloc] initWithTitle:@"Callback failed!"
                                                                       message:desc
                                                                      delegate:nil
                                                             cancelButtonTitle:@"Ok"
                                                             otherButtonTitles:nil];
            [InitiateCallBack show];
            [InitiateCallBack release];
        }
        //NSString *callLimit = [item objectForKey:@"callLimit"];
    }
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==1)
    {
        NSInteger cancelIndex = [alertView cancelButtonIndex];
        if (cancelIndex != -1 && cancelIndex == buttonIndex)
        {
            
        }
        else
        {
            //start callback
            [self StartCallBack];
        }
    }
}
#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //[textField performSelector:@selector() withObject:nil afterDelay:0];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == txtDestination) {
        [txtDestination resignFirstResponder];
    }
    return YES;
}
- (void) requestFailed:(ASIFormDataRequest *) request1
{
    [self setBusyCursorNew:false :@""];
    NSError *error = [request1 error];
    NSLog(@"%@", error);
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
   // [[NSNotificationCenter defaultCenter] addObserver:self                                             selector:@selector(registrationUpdateEvent:)                                                 name:kLinphoneRegistrationUpdate object:nil];
    
    
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
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self                                                    name:kLinphoneRegistrationUpdate                                                  object:nil];
}
- (void)registrationUpdateEvent:(NSNotification*)notif {
    //NSString* message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey: @"state"] intValue]];
}
- (void)registrationUpdate:(LinphoneRegistrationState)state {
    switch (state) {
        case LinphoneRegistrationOk: {
            //[self GetBalance];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:kLinphoneRegistrationUpdate
                                                          object:nil];
            break;
        }
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared:  {
            
            //lblBalance.text = @"Account not configured!";
            break;
        }
        case LinphoneRegistrationFailed: {
           
            //lblBalance.text = @"Registration Failed!";
            break;
        }
        case LinphoneRegistrationProgress: {
            //lblBalance.text = @"Registration in progress...";
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
        compositeDescription = [[UICompositeViewDescription alloc] init:@"CallBack"
                                                                content:@"CallBack"
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

- (IBAction)WhatsThis {
    UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"What is Callback"
                                                    message:@"Callback is a service where you do not require internet to have a voice call except for initializing the call. When you are low on your data pack or your internet is slow, then you can use this service. This service connects you to your desired destination number via PSTN (regular calls)"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [error show];
    [error release];
}

- (IBAction)VerifyNumber {
    [[PhoneMainView instance] changeCurrentView:[WebViewNew compositeViewDescription] push:TRUE];
    [PhoneMainView instance].webViewType = @"CallerId";
}

- (IBAction)ContactLookup {
    [ContactSelection setSelectionMode:ContactSelectionModePhone];
    //[ContactSelection setAddAddress:[addressField text]];
    [ContactSelection setSipFilter:nil];
    [ContactSelection setNameOrEmailFilter:nil];
    [ContactSelection enableEmailFilter:TRUE];
    ContactsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE], ContactsViewController);
    if(controller != nil) {
        
    }
}

- (IBAction)InitiateCallBack {
    [self GetCallRates];
}
- (void)dealloc {
    [btnVerifyNumber release];
    [txtDestination release];
    [btnInitiateCallback release];
    [lblNote release];
    [lblMyNumber release];
    [super dealloc];
}
@end



