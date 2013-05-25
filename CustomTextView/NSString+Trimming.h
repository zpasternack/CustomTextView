//
//  NSString+Trimming.h
//  CustomTextView
//
//  Created by Zacharias Pasternack on 5/25/13.
//  Copyright (c) 2013 Fat Apps, LLC. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface NSString (Trimming)

- (NSArray*) stringsByTrimmingLeadingWhitespace;
// Returns array, [0] is leading whitespace characters, [1] is remainder of string.

@end
