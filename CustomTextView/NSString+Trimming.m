//
//  NSString+Trimming.m
//  CustomTextView
//
//  Created by Zacharias Pasternack on 5/25/13.
//  Copyright (c) 2013 Fat Apps, LLC. All rights reserved.
//


#import "NSString+Trimming.h"


@implementation NSString (Trimming)


- (NSArray*) stringsByTrimmingLeadingWhitespace
{
	// Find leading whitespace.
	NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    NSInteger i = 0;
    while( ( i < [self length] ) &&
		  [whitespaceCharacterSet characterIsMember:[self characterAtIndex:i]])
	{
        i++;
    }
	
	// Split into whitespace, the rest.
	NSString* leadingWhitespace = [self substringToIndex:i];
    NSString* trimmedString = [self substringFromIndex:i];
	
	return @[leadingWhitespace, trimmedString];
}


@end
