//
//  BilledCalls.m
//  linphone
//
//  Created by lalit on 12/24/14.
//
//

#import "BilledCalls.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "MBProgressHUD.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import "CallDetail.h"
#import "LinphoneAppDelegate.h"
#import "NSString+UnformattedPhoneNumber.h"
@interface BilledCalls ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    ASIFormDataRequest *request;
}
@end

@implementation BilledCalls

+ (NSArray *)allContactsFromAddressBook {
    static NSMutableArray *contacts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        contacts = [[NSMutableArray alloc] init];

        CFErrorRef *error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);

        __block BOOL accessGranted = NO;
        if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
            // Semaphore is used for blocking until response
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;
                dispatch_semaphore_signal(sema);
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        else { // we're on iOS 5 or older
            accessGranted = YES;
        }
        if (accessGranted) {
            NSArray *allPeople = ( NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
            for (id person in allPeople) {
                Contact *contact = [[Contact alloc] init];
                NSString *firstName = @"";
                NSString *lastName = @"";
                // Get the name of the contact
                firstName = ( NSString*)ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonFirstNameProperty);
                lastName = ( NSString*)ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonLastNameProperty);
                [contact setName:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
                // Get the photo of the contact
                CFDataRef imageData = ABPersonCopyImageData((__bridge ABRecordRef)(person));
                UIImage *image = [UIImage imageWithData:(__bridge NSData *)imageData];
                [contact setPhoto:image];
                // Get all phone numbers of the contact
                NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonPhoneProperty);
                // If the contact has multiple phone numbers, iterate on each of them
                NSInteger phoneNumberCount = ABMultiValueGetCount(phoneNumbers);
                for (int i = 0; i < phoneNumberCount; i++) {
                    NSString *phoneNumberFromAB = [( NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, i) unformattedPhoneNumber];
                    [tempArray addObject:phoneNumberFromAB];
                }
                CFRelease(phoneNumbers);
                [contact setNumbers:tempArray];
                [contacts addObject:contact];
            }
        }
        CFRelease(addressBook);
    });
    return contacts;
}

+ (Contact *)findContactWithPhoneNumber:(NSString *)phoneNumber {
    NSArray *contacts = [BilledCalls allContactsFromAddressBook];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY numbers CONTAINS[cd] %@", phoneNumber];
    NSArray *filteredArray = [contacts filteredArrayUsingPredicate:predicate];
    Contact *matchedContact = [filteredArray lastObject];
    return matchedContact;
}

+ (NSString *)nameForContactWithPhoneNumber:(NSString *)phoneNumber {
    return [[BilledCalls findContactWithPhoneNumber:phoneNumber] name];
}

+ (UIImage *)photoForContactWithPhoneNumber:(NSString *)phoneNumber {
    return [[BilledCalls findContactWithPhoneNumber:phoneNumber] photo];
}

-(void)setBusyCursorNew:(BOOL) busyFlag :(NSString *) message{
    
    if(busyFlag){
        self->HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self->HUD.color = [UIColor colorWithRed:207.0f/255.0f green:76.0f/255.0f blue:41.0f/255.0f alpha:0.8];
        self->HUD.labelText = message;
        self->HUD.delegate=self;
        self->HUD.detailsLabelText = @"Tap to cancel";
        [self->HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hudWasCancelled)]];
        [self->HUD show:true];
        
    }else {
        
        [self->HUD hide:YES];
    }
}
- (void)hudWasCancelled {
    [self->HUD hide:YES];
    [request cancel];
    [request clearDelegatesAndCancel];

}
- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    HUD = nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Last 20 billed calls";
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
-(void)viewDidAppear:(BOOL)animated
{
    const MSList* list = linphone_core_get_proxy_config_list([LinphoneManager getLc]);
    if(list != NULL) {
        LinphoneProxyConfig *config = (LinphoneProxyConfig*) list->data;
        if(config) {
            
            [self registrationUpdate:linphone_proxy_config_get_state(config)];
        }
    }
}

-(void)layoutNavigationBar{
    self.navigationBar.frame = CGRectMake(0, self.tableView.contentOffset.y, self.tableView.frame.size.width, self.topLayoutGuide.length + 44);
    self.tableView.contentInset = UIEdgeInsetsMake(self.navigationBar.frame.size.height, 0, 0, 0);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //no need to call super
    [self layoutNavigationBar];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self layoutNavigationBar];
}



-(void)backButtonPressed
{
    [[PhoneMainView instance] popCurrentView];
}
-(void)GetBalance
{
    
    //[request cancel];
    //[request clearDelegatesAndCancel];
    NSString *username = @"";//[[LinphoneManager instance] lpConfigStringForKey:@"username_preference"];
    
    LinphoneCore *lc=[LinphoneManager getLc];
    if (linphone_core_is_network_reachable(lc)) {
        [self setBusyCursorNew:true :@"Fetching call logs..."];
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
                
                NSString *url = [NSString stringWithFormat:@""];
                request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
                [request setValidatesSecureCertificate:YES];
                [request setClientCertificateIdentity:myIdentity];
                [request setRequestMethod:@"POST"];
                [request setPostValue:Signature forKey:@"h"];
                [request setPostValue:timestamp forKey:@"t"];
                [request setPostValue:username forKey:@"user"];
                [request setPostValue:@"20" forKey:@"limit"];
                [request setTag:1];
                [request setDelegate:self];
                [request setTimeOutSeconds:30];
                [request startAsynchronous];
            }
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) requestFinished:(ASIHTTPRequest *)request1
{
    NSString *responseString = [request1 responseString];
    responseString = [request1 responseString];
    [self setBusyCursorNew:false :@"Fetching logs..."];
    
    if(request1.tag==1)
    {
        SBJsonParser *parser = [[SBJsonParser alloc] init] ;
        
        NSArray *arr = [parser objectWithString:responseString];
        arrCalls = [[NSMutableArray alloc] init];
        
        for(NSDictionary *item in arr)
        {
            NSString *name = [BilledCalls nameForContactWithPhoneNumber:[item objectForKey:@"callednum"]];
            NSString *num = [NSString stringWithFormat:@"+%@",[item objectForKey:@"callednum"]];
            [item setValue:num forKey:@"callednum"];
            
            name = [name stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            [item setValue:name forKey:@"callerip"];
            [arrCalls addObject:item];
        
        }
             [self.tableView reloadData];
    }
    
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"BilledCalls"
                                                                content:@"BilledCalls"
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
- (void) requestFailed:(ASIHTTPRequest *) request1
{
    NSError *error = [request1 error];
    NSLog(@"%@", error);
    [self setBusyCursorNew:false :@"Fetching logs..."];
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
            break;
        }
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared:  {
            //[waitView setHidden:true];
            break;
        }
        case LinphoneRegistrationFailed: {
            //[waitView setHidden:true];
            
            break;
        }
        case LinphoneRegistrationProgress: {
            //[waitView setHidden:false];
            break;
        }
        default:
            break;
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [arrCalls count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier=@"Cell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] ;
    }
    
    // Configure the cell...
    CallDetail *detail = [[CallDetail alloc]initWithDictionary:[arrCalls objectAtIndex:indexPath.row]];
    
    if (detail.callerip.length>0)
        cell.textLabel.text = [NSString stringWithFormat:@"%@",detail.callerip];
    else
        cell.textLabel.text = [NSString stringWithFormat:@"%@",detail.callednum];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Date: %@\nDuration: %@ min\nCost: $%.4f",[LinphoneAppDelegate dateWithJSONString:detail.callstart],[LinphoneAppDelegate RoundSecondsToMinutes:detail.billseconds],[detail.debit floatValue]];
    cell.detailTextLabel.numberOfLines = 4;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    // ***********   Using a custom image for a UITableViewCell's accessoryView and having it respond to UITableViewDelegate
    UIImage *image = [UIImage imageNamed:@"billedcallscall.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    CGRect frame = CGRectMake(0.0, 0.0, 27.0, 24.0);
    
    button.frame = frame;   // match the button's size with the image size
    [button setBackgroundImage:image forState:UIControlStateNormal];
    
    // set the button's target to this table view controller so we can interpret touch events and map that to a NSIndexSet
    [button addTarget:self action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = indexPath.row;
    cell.backgroundColor = [UIColor clearColor];
    cell.accessoryView = button;
    
    //***********************************************
    
    return cell;
}
#pragma mark - accessoryButtonTapped
- (void) accessoryButtonTapped:(UIButton *)button {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:button.tag];
    
    [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark - accessoryButtonTappedForRowWithIndexPath
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    CallDetail *detail = [[CallDetail alloc]initWithDictionary:[arrCalls objectAtIndex:indexPath.row]];
    [self ClickedRow:detail.callednum];
}
-(void)ClickedRow:(NSString*)address
{
    NSString* displayName =[BilledCalls nameForContactWithPhoneNumber:[address stringByReplacingOccurrencesOfString:@"+" withString:@""]];
    displayName = [displayName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    
    
    if(displayName.length > 1) {
        // Go to dialer view
        DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
        if(controller != nil) {
            [controller call:address displayName:displayName];
        }
    }
}
/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
