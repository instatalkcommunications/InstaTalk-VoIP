/* LinphoneAppDelegate.m
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */                                                                           

#import "PhoneMainView.h"
#import "linphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"
#import "Appirater.h"
#include "LinphoneManager.h"
#include "linphone/linphonecore.h"
#import "GAI.h"
#import <CommonCrypto/CommonHMAC.h>
@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super init];
    if(self != nil) {
        self->startedInBackground = FALSE;
    }
    return self;
}
-(void)InitializeGA{
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 120;
    
    // Optional: set Logger to VERBOSE for debug information.
    //[[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GoogleAnalyticsId];
}
+(void)RateUS
{
    [Appirater rateApp];
}
+(NSString*)RateURL
{
    return [Appirater GetRateURL];
}
- (void)dealloc {
	[super dealloc];
}
+(NSDate *)toGlobalTime: (NSDate *)date
{
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate: date];
    return [NSDate dateWithTimeInterval: seconds sinceDate: date];
}
+(NSString*)FormatPhoneNumber:(NSString*)number{
    
    number = [[FastAddressBook normalizePhoneNumber:number] stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    NSRange range = [number rangeOfString:@"^0*" options:NSRegularExpressionSearch];
    number= [number stringByReplacingCharactersInRange:range withString:@""];
    
    NSCharacterSet *myCharset = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    NSString *newString = [number stringByTrimmingCharactersInSet:[myCharset invertedSet]];

    return newString;
}
+(NSTimeInterval)GetTimeStamp
{
   return [[LinphoneAppDelegate toGlobalTime:[NSDate date]] timeIntervalSince1970];
}
+(NSString*)SignRequest:(NSString*)parms
{
    const char *cKey  = [@"" cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [parms cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    
    return hash;
}
#pragma mark - 


// Based on code from http://developer.apple.com/mac/library/documentation/Security/Conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html
+ (BOOL)extractIdentity:(SecIdentityRef *)outIdentity
{
    SecTrustRef outTrust;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"" ofType:@"p12"];
    NSData *inPKCS12Data = [NSData dataWithContentsOfFile:path];
    
    OSStatus securityError = errSecSuccess;
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:@"" forKey:(id)kSecImportExportPassphrase];
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((CFDataRef)inPKCS12Data,(CFDictionaryRef)optionsDictionary,&items);
    if (securityError == 0) {
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failed with error code %d",(int)securityError);
        return NO;
    }
    return YES;
}
- (void)applicationDidEnterBackground:(UIApplication *)application{
	Linphone_log(@"%@", NSStringFromSelector(_cmd));
	[[LinphoneManager instance] enterBackgroundMode];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
	
    if (call){
		/* save call context */
		LinphoneManager* instance = [LinphoneManager instance];
		instance->currentCallContextBeforeGoingBackground.call = call;
		instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);
    
		const LinphoneCallParams* params = linphone_call_get_current_params(call);
		if (linphone_call_params_video_enabled(params)) {
			linphone_call_enable_camera(call, false);
		}
	}
    
    if (![[LinphoneManager instance] resignActive]) {

    }
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));

    if( startedInBackground ){
        startedInBackground = FALSE;
        [[PhoneMainView instance] startUp];
        [[PhoneMainView instance] updateStatusBar:nil];
    }
    LinphoneManager* instance = [LinphoneManager instance];
    
    [instance becomeActive];
    
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    if (call){
        if (call == instance->currentCallContextBeforeGoingBackground.call) {
            const LinphoneCallParams* params = linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(params)) {
                linphone_call_enable_camera(
                                            call,
                                            instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
            }
            instance->currentCallContextBeforeGoingBackground.call = 0;
        } else if ( linphone_call_get_state(call) == LinphoneCallIncomingReceived ) {
            [[PhoneMainView  instance ] displayIncomingCall:call];
            // in this case, the ringing sound comes from the notification.
            // To stop it we have to do the iOS7 ring fix...
            [self fixRing];
        }
    }
}

- (UIUserNotificationCategory*)getMessageNotificationCategory {
    
    UIMutableUserNotificationAction* reply = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    reply.identifier = @"reply";
    reply.title = NSLocalizedString(@"Reply", nil);
    reply.activationMode = UIUserNotificationActivationModeForeground;
    reply.destructive = NO;
    reply.authenticationRequired = YES;
    
    UIMutableUserNotificationAction* mark_read = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    mark_read.identifier = @"mark_read";
    mark_read.title = NSLocalizedString(@"Mark Read", nil);
    mark_read.activationMode = UIUserNotificationActivationModeBackground;
    mark_read.destructive = NO;
    mark_read.authenticationRequired = NO;
    
    NSArray* localRingActions = @[mark_read, reply];
    
    UIMutableUserNotificationCategory* localRingNotifAction = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
    localRingNotifAction.identifier = @"incoming_msg";
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

    return localRingNotifAction;
}

- (UIUserNotificationCategory*)getCallNotificationCategory {
    UIMutableUserNotificationAction* answer = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    answer.identifier = @"answer";
    answer.title = NSLocalizedString(@"Answer", nil);
    answer.activationMode = UIUserNotificationActivationModeForeground;
    answer.destructive = NO;
    answer.authenticationRequired = YES;
    
    UIMutableUserNotificationAction* decline = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    decline.identifier = @"decline";
    decline.title = NSLocalizedString(@"Decline", nil);
    decline.activationMode = UIUserNotificationActivationModeBackground;
    decline.destructive = YES;
    decline.authenticationRequired = NO;
    
    
    NSArray* localRingActions = @[decline, answer];
    
    UIMutableUserNotificationCategory* localRingNotifAction = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
    localRingNotifAction.identifier = @"incoming_call";
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

    return localRingNotifAction;
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    UIApplication* app= [UIApplication sharedApplication];
    UIApplicationState state = app.applicationState;
    
    if( [app respondsToSelector:@selector(registerUserNotificationSettings:)] ){
        /* iOS8 notifications can be actioned! Awesome: */
        UIUserNotificationType notifTypes = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
       
        NSSet* categories = [NSSet setWithObjects:[self getCallNotificationCategory], [self getMessageNotificationCategory], nil];
        UIUserNotificationSettings* userSettings = [UIUserNotificationSettings settingsForTypes:notifTypes categories:categories];
        [app registerUserNotificationSettings:userSettings];
        [app registerForRemoteNotifications];
    } else {
        NSUInteger notifTypes = UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeNewsstandContentAvailability;
        [app registerForRemoteNotificationTypes:notifTypes];
    }

	LinphoneManager* instance = [LinphoneManager instance];
    BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
    BOOL start_at_boot   = [instance lpConfigBoolForKey:@"start_at_boot_preference"];


    if (state == UIApplicationStateBackground)
    {
        // we've been woken up directly to background;
        if( !start_at_boot || !background_mode ) {
            // autoboot disabled or no background, and no push: do nothing and wait for a real launch
			/*output a log with NSLog, because the ortp logging system isn't activated yet at this time*/
			NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
            return YES;
        }

    }
	bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[LinphoneLogger log:LinphoneLoggerWarning format:@"Background task for application launching expired."];
		[[UIApplication sharedApplication] endBackgroundTask:bgStartId];
	}];

    [[LinphoneManager instance]	startLibLinphone];
    // initialize UI
    [self.window makeKeyAndVisible];
    [RootViewManager setupWithPortrait:(PhoneMainView*)self.window.rootViewController];
    [[PhoneMainView instance] startUp];
    [[PhoneMainView instance] updateStatusBar:nil];



	NSDictionary *remoteNotif =[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif){
		[LinphoneLogger log:LinphoneLoggerLog format:@"PushNotification from launch received."];
		[self processRemoteNotification:remoteNotif];
	}
    if (bgStartId!=UIBackgroundTaskInvalid) [[UIApplication sharedApplication] endBackgroundTask:bgStartId];

    [self InitializeGA];
    [Appirater setAppId:@YOUR_APP_STORE_ID];
    
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater appLaunched:YES];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *scheme = [[url scheme] lowercaseString];
    if ([scheme isEqualToString:@"linphone-config"] || [scheme isEqualToString:@"linphone-config"]) {
        NSString* encodedURL = [[url absoluteString] stringByReplacingOccurrencesOfString:@"linphone-config://" withString:@""];
        self.configURL = [encodedURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIAlertView* confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remote configuration",nil)
                                                        message:NSLocalizedString(@"This operation will load a remote configuration. Continue ?",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No",nil)
                                              otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        confirmation.tag = 1;
        [confirmation show];
        [confirmation release];
    } else {
        if([[url scheme] isEqualToString:@"sip"]) {
            // Go to Dialer view
            DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
            if(controller != nil) {
                [controller setAddress:[url absoluteString]];
            }
        }
    }
	return YES;
}

- (void)fixRing{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        // iOS7 fix for notification sound not stopping.
        // see http://stackoverflow.com/questions/19124882/stopping-ios-7-remote-notification-sound
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    }
}

- (void)processRemoteNotification:(NSDictionary*)userInfo{
	if ([LinphoneManager instance].pushNotificationToken==Nil){
		[LinphoneLogger log:LinphoneLoggerLog format:@"Ignoring push notification we did not subscribed."];
		return;
	}
	
	NSDictionary *aps = [userInfo objectForKey:@"aps"];
	
    if(aps != nil) {
        NSDictionary *alert = [aps objectForKey:@"alert"];
        if(alert != nil) {
            NSString *loc_key = [alert objectForKey:@"loc-key"];
			/*if we receive a remote notification, it is probably because our TCP background socket was no more working.
			 As a result, break it and refresh registers in order to make sure to receive incoming INVITE or MESSAGE*/
			LinphoneCore *lc = [LinphoneManager getLc];
			if (linphone_core_get_calls(lc)==NULL){ //if there are calls, obviously our TCP socket shall be working
				linphone_core_set_network_reachable(lc, FALSE);
				[LinphoneManager instance].connectivity=none; /*force connectivity to be discovered again*/
                [[LinphoneManager instance] refreshRegisters];
				if(loc_key != nil) {
					if([loc_key isEqualToString:@"IM_MSG"]) {
						[[PhoneMainView instance] addInhibitedEvent:kLinphoneTextReceived];
						[[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
					} else if([loc_key isEqualToString:@"IC_MSG"]) {
						//it's a call
						NSString *callid=[userInfo objectForKey:@"call-id"];
						if (callid)
							[[LinphoneManager instance] enableAutoAnswerForCallId:callid];
						else
							[LinphoneLogger log:LinphoneLoggerError format:@"PushNotification: does not have call-id yet, fix it !"];

						[self fixRing];
					}
				}
			}
        }
    }
}
+(NSString*)RoundSecondsToMinutes:(NSString*)sec
{
    int seconds = [sec intValue];
    
    NSUInteger remainder = (seconds % 60);
    
    if (remainder > 0)
        seconds = seconds + (60-remainder);
    
    //20 secs = 20 + (60-20) = 60
    //70 secs = 70 + (60-10) = 120
    
    return [NSString stringWithFormat:@"%d",seconds/60];
}
+(NSString*)dateWithJSONString:(NSString*)dateStr
{
    
    float timezoneoffset = ([[NSTimeZone systemTimeZone] secondsFromGMT]);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; // here we create NSDateFormatter object for change the Format of date..
    [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss.SSS"]; //// here set format of date which is in your output date (means above str with format)
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"IST"]];
    NSDate *date = [dateFormatter dateFromString: dateStr];
    
    [dateFormatter setDateFormat:@"MMMM dd, yyyy HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    
    NSString* formatedDate = [dateFormatter stringFromDate:[date dateByAddingTimeInterval:timezoneoffset]];
    return  formatedDate;
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);

	[self processRemoteNotification:userInfo];
}

- (LinphoneChatRoom*)findChatRoomForContact:(NSString*)contact {
    MSList* rooms = linphone_core_get_chat_rooms([LinphoneManager getLc]);
    const char* from = [contact UTF8String];
    while (rooms) {
        const LinphoneAddress* room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom*)rooms->data);
        char* room_from = linphone_address_as_string_uri_only(room_from_address);
        if( room_from && strcmp(from, room_from)== 0){
            return rooms->data;
        }
        rooms = rooms->next;
    }
    return NULL;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    Linphone_log(@"%@ - state = %ld", NSStringFromSelector(_cmd), (long)application.applicationState);

    [self fixRing];

    if([notification.userInfo objectForKey:@"callId"] != nil) {
        BOOL auto_answer = TRUE;

        // some local notifications have an internal timer to relaunch themselves at specified intervals
        if( [[notification.userInfo objectForKey:@"timer"] intValue] == 1 ){
            [[LinphoneManager instance] cancelLocalNotifTimerForCallId:[notification.userInfo objectForKey:@"callId"]];
            auto_answer = [[LinphoneManager instance] lpConfigBoolForKey:@"autoanswer_notif_preference"];
        }
        if(auto_answer)
        {
            [[LinphoneManager instance] acceptCallForCallId:[notification.userInfo objectForKey:@"callId"]];
        }
    } else if([notification.userInfo objectForKey:@"from"] != nil) {
        NSString *remoteContact = (NSString*)[notification.userInfo objectForKey:@"from"];
        // Go to ChatRoom view
        [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
        ChatRoomViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE], ChatRoomViewController);
        if(controller != nil) {
            LinphoneChatRoom*room = [self findChatRoomForContact:remoteContact];
            [controller setChatRoom:room];
        }
    } else if([notification.userInfo objectForKey:@"callLog"] != nil) {
        NSString *callLog = (NSString*)[notification.userInfo objectForKey:@"callLog"];
        // Go to HistoryDetails view
        [[PhoneMainView instance] changeCurrentView:[HistoryViewController compositeViewDescription]];
        HistoryDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[HistoryDetailsViewController compositeViewDescription] push:TRUE], HistoryDetailsViewController);
        if(controller != nil) {
            [controller setCallLogId:callLog];
        }
    }
}

// this method is implemented for iOS7. It is invoked when receiving a push notification for a call and it has "content-available" in the aps section.
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
    LinphoneManager* lm = [LinphoneManager instance];
	
	if (lm.pushNotificationToken==Nil){
		[LinphoneLogger log:LinphoneLoggerLog format:@"Ignoring push notification we did not subscribed."];
		return;
	}

    // save the completion handler for later execution.
    // 2 outcomes:
    // - if a new call/message is received, the completion handler will be called with "NEWDATA"
    // - if nothing happens for 15 seconds, the completion handler will be called with "NODATA"
    lm.silentPushCompletion = completionHandler;
    [NSTimer scheduledTimerWithTimeInterval:15.0 target:lm selector:@selector(silentPushFailed:) userInfo:nil repeats:FALSE];

	LinphoneCore *lc=[LinphoneManager getLc];
	// If no call is yet received at this time, then force Linphone to drop the current socket and make new one to register, so that we get
	// a better chance to receive the INVITE.
	if (linphone_core_get_calls(lc)==NULL){
		linphone_core_set_network_reachable(lc, FALSE);
		lm.connectivity=none; /*force connectivity to be discovered again*/
		[lm refreshRegisters];
	}
}


#pragma mark - PushNotification Functions

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), deviceToken);
    [[LinphoneManager instance] setPushNotificationToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
    [[LinphoneManager instance] setPushNotificationToken:nil];
}

#pragma mark - User notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    if( [[UIDevice currentDevice].systemVersion floatValue] >= 8){

        LinphoneCore* lc = [LinphoneManager getLc];
        [LinphoneLogger log:LinphoneLoggerLog format:@"%@", NSStringFromSelector(_cmd)];
        if( [notification.category isEqualToString:@"incoming_call"]) {
            if( [identifier isEqualToString:@"answer"] ){
                // use the standard handler
                [self application:application didReceiveLocalNotification:notification];
            } else if( [identifier isEqualToString:@"decline"] ){
                LinphoneCall* call = linphone_core_get_current_call(lc);
                if( call ) linphone_core_decline_call(lc, call, LinphoneReasonDeclined);
            }
        } else if( [notification.category isEqualToString:@"incoming_msg"] ){
            if( [identifier isEqualToString:@"reply"] ){
                // use the standard handler
                [self application:application didReceiveLocalNotification:notification];
            } else if( [identifier isEqualToString:@"mark_read"] ){
                NSString* from = [notification.userInfo objectForKey:@"from"];
                LinphoneChatRoom* room = linphone_core_get_or_create_chat_room(lc, [from UTF8String]);
                if( room ){
                    linphone_chat_room_mark_as_read(room);
                    [[PhoneMainView instance] updateApplicationBadgeNumber];
                }
            }
        }
    }
    completionHandler();
}


- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    completionHandler();
}

#pragma mark - Remote configuration Functions (URL Handler)


- (void)ConfigurationStateUpdateEvent: (NSNotification*) notif {
    LinphoneConfiguringState state = [[notif.userInfo objectForKey: @"state"] intValue];
       if (state == LinphoneConfiguringSuccessful) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneConfiguringStateUpdate
                                                  object:nil];
        [_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];

        UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success",nil)
                                                        message:NSLocalizedString(@"Remote configuration successfully fetched and applied.",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
        [[PhoneMainView instance] startUp];
    }
    if (state == LinphoneConfiguringFailed) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneConfiguringStateUpdate
                                                  object:nil];
        [_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure",nil)
                                                        message:NSLocalizedString(@"Failed configuring from the specified URL." ,nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
        
    }
}


- (void) showWaitingIndicator {
    _waitingIndicator = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fetching remote configuration...",nil) message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *progress= [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 60, 30, 30)];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        [_waitingIndicator setValue:progress forKey:@"accessoryView"];
        [progress setColor:[UIColor blackColor]];
    } else {
        [_waitingIndicator addSubview:progress];
    }
    [progress startAnimating];
    [progress release];
    [_waitingIndicator show];

}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 1) && (buttonIndex==1))  {
        [self showWaitingIndicator];
        [self attemptRemoteConfiguration];
    }
}

- (void)attemptRemoteConfiguration {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ConfigurationStateUpdateEvent:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];
    linphone_core_set_provisioning_uri([LinphoneManager getLc] , [configURL UTF8String]);
    [[LinphoneManager instance] destroyLibLinphone];
    [[LinphoneManager instance] startLibLinphone];

}


@end
