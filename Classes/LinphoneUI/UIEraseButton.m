/* UIEraseButton.m
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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

#import "UIEraseButton.h"


@implementation UIEraseButton

@synthesize addressField;


#pragma mark - Lifecycle Functions

- (void)initUIEraseButton {
	[self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
}

- (id)init {
    self = [super init];
    if (self) {
		[self initUIEraseButton];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self initUIEraseButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
		[self initUIEraseButton];
	}
    return self;
}	

- (void)dealloc {
    [super dealloc];
	[addressField release];
}


#pragma mark - Action Functions

-(void) touchDown:(id) sender {
  	if ([addressField.text length] > 0) {
        @try {
            
            
            UITextRange *selectedRange = [addressField selectedTextRange];
            // here you will have to check whether the user has actually selected something
            UITextPosition* beginning = addressField.beginningOfDocument;
            UITextPosition* start = selectedRange.start;
            //UITextPosition* end = selectedRange.end;
            
            const NSInteger location = [addressField offsetFromPosition:beginning toPosition:start];
            
            NSString *newString = [addressField.text stringByReplacingCharactersInRange:NSMakeRange(location-1, 1) withString:@""];
            //[addressField setText:[addressField.text substringToIndex:[addressField.text length]-1]];
            [addressField setText:newString];
            
            [self selectTextInTextField:addressField range:NSMakeRange(location-1, 0)];
            
        }
        @catch (NSException *exception) {
            
        }
    }
}
- (void)selectTextInTextField:(UITextField *)textField range:(NSRange)range {
    UITextPosition *from = [textField positionFromPosition:[textField beginningOfDocument] offset:range.location];
    UITextPosition *to = [textField positionFromPosition:from offset:range.length];
    [textField setSelectedTextRange:[textField textRangeFromPosition:from toPosition:to]];
}

#pragma mark - UILongTouchButtonDelegate Functions

- (void)onRepeatTouch {
}

- (void)onLongTouch {
    [addressField setText:@""];
}

@end
