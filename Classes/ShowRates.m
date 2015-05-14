//
//  ShowRates.m
//  InstaTalk VoIP
//
//  Created by lalit on 3/5/15.
//
//

#import "ShowRates.h"
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
@interface ShowRates ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
     ASIFormDataRequest *request;
}
@end

@implementation ShowRates
@synthesize txtDestination;
-(void)setBusyCursorNew:(BOOL) busyFlag :(NSString *) message{
    
    if(busyFlag){
        self->HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self->HUD.color = [UIColor colorWithRed:207.0f/255.0f green:76.0f/255.0f blue:41.0f/255.0f alpha:0.8];
        self->HUD.labelText = message;
        self->HUD.delegate=self;
        //self->HUD.detailsLabelText = @"Tap to cancel";
        //[self->HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hudWasCancelled)]];
        [self->HUD show:true];
        
    }else {
        if(HUD)
            [self->HUD hide:YES];
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
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [txtDestination resignFirstResponder];
}
- (void)hudWasCancelled {
    if(HUD)
        [self->HUD hide:YES];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    if(HUD)
    {
        [HUD removeFromSuperview];
        HUD = nil;
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
   // [[PhoneMainView instance] popCurrentView];
    [[PhoneMainView instance] popToView:[Accounts compositeViewDescription]];
}
-(void)viewDidAppear:(BOOL)animated
{
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [[UINavigationBar appearance] setBarTintColor:[LINPHONE_MAIN_COLOR adjustHue:5.0f/180.0f saturation:0.0f brightness:0.0f alpha:0.0f]];
    self.navigationItem.title = @"Call Rates";
    [self.navigationController.view setBackgroundColor:[UIColor clearColor]];
   // [[UINavigationBar appearance] setTranslucent:YES];
    [self.view addSubview:_navigationBar];
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolsbar_background.png"] forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *_backButton = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonPressed)];
    self.navigationItem.leftBarButtonItem = _backButton;
}
- (IBAction)GetAllRates{
    [[PhoneMainView instance] changeCurrentView:[WebViewNew compositeViewDescription] push:TRUE];
    [PhoneMainView instance].webViewType = @"AllRates";
}
- (void) requestFinished:(ASIFormDataRequest *)request1
{
    [self setBusyCursorNew:false :@""];
    NSString *responseString = [request1 responseString];
    responseString = [request1 responseString];
    
    if(request1.tag==1)
    {
        SBJsonParser *parser = [[SBJsonParser alloc] init] ;
        @try {
            NSDictionary *item = [parser objectWithString:responseString];
            NSString *Location = [item objectForKey:@"Location"];
            NSString *Cost = [item objectForKey:@"Cost"];
            lblData.numberOfLines = 2;
            lblData.lineBreakMode = NSLineBreakByWordWrapping;
            lblData.text = [NSString stringWithFormat:@"Location: %@\nCost: %.2f ¢/min\nLocation: %@",Location,[Cost floatValue]*100,Location];
            
            if([Cost length]<=0)
                 lblData.text= @"Destination number not supported";
        }
        @catch (NSException *exception) {
            lblData.text= @"Destination number not supported";
        }
        
    }
}
- (IBAction)CheckRate{
    lblData.text=@"";
    [self GetCallRates];
}
-(void)GetCallRates{
     txtDestination.text = [LinphoneAppDelegate FormatPhoneNumber:txtDestination.text];
    if([txtDestination.text length]>2)
    {
        LinphoneCore *lc=[LinphoneManager getLc];
        if (linphone_core_is_network_reachable(lc)) {
            [self setBusyCursorNew:true :@"Fetching call rate..."];
            SecIdentityRef myIdentity;
            [LinphoneAppDelegate extractIdentity:&myIdentity];
            
            NSString *timestamp = [NSString stringWithFormat:@"%f",[LinphoneAppDelegate GetTimeStamp]];
            NSString *Parms = [NSString stringWithFormat:@"%@%@",timestamp,txtDestination.text];
            NSString *Signature = [LinphoneAppDelegate SignRequest:Parms];
            
            
            NSString *url = [NSString stringWithFormat:@""];
            request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
            
            // In this case, we have no need to add extra certificates, just the one inside the indentity will be used
            [request setValidatesSecureCertificate:YES];
            [request setClientCertificateIdentity:myIdentity];
            [request setPostValue:txtDestination.text forKey:@"mob"];
            [request setPostValue:timestamp forKey:@"t"];
            [request setPostValue:Signature forKey:@"h"];
            [request setRequestMethod:@"POST"];
            [request setTag:1];
            [request setDelegate:self];
            [request setTimeOutSeconds:30];
            [request startAsynchronous];
        }
    }
    
    [txtDestination resignFirstResponder];
}
- (IBAction)LoadContacts
{
    [ContactSelection setSelectionMode:ContactSelectionModePhone];
    //[ContactSelection setAddAddress:[addressField text]];
    [ContactSelection setSipFilter:nil];
    [ContactSelection setNameOrEmailFilter:nil];
    [ContactSelection enableEmailFilter:TRUE];
    ContactsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE], ContactsViewController);
    if(controller != nil) {
        
    }
}
#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"ShowRates"
                                                                content:@"ShowRates"
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 30)];
    txtDestination.leftView = paddingView;
    txtDestination.leftViewMode = UITextFieldViewModeAlways;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
