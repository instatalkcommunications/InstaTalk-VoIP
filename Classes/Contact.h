//
//  Contact.h
//  linphone
//
//  Created by lalit on 1/14/15.
//
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *numbers;
@property (nonatomic, strong) UIImage *photo;

@end
