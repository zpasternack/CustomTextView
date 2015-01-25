//
//  ZPTextView.m
//  CustomTextView
//
//  Created by Zacharias Pasternack on 5/25/13.
//  Copyright (c) 2013-2015 Fat Apps, LLC. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// * Neither the name Fat Apps, LLC nor the
// names of its contributors may be used to endorse or promote products
// derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "ZPTextView.h"
#import "NSString+Trimming.h"


@interface ZPTextView ()
{
	unichar lastCharacterInserted;
	unichar lastCharacterWhichCausedInsertion;
	BOOL insertingText;
	BOOL justInsertedBrace;
}
@end


@implementation ZPTextView


#pragma mark - Initialization


- (id) initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer*)aTextContainer
{
	self = [super initWithFrame:frameRect textContainer:aTextContainer];
	if( self ) {
		[self setup];
	}
	return self;
}


- (id) initWithCoder:(NSCoder*)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if( self ) {
		[self setup];
	}
	return self;
}


#pragma mark - NSText


// We call replaceChractersInRange all over the place, and that does an end-run around
// Undo, unless you first call shouldChangeTextInRange:withString (it does the Undo stuff).
// Rather than sprinkle those all over the place, do it once here.

- (void) replaceCharactersInRange:(NSRange)range withString:(NSString*)aString
{
	if( [self shouldChangeTextInRange:range replacementString:aString] ) {
		[super replaceCharactersInRange:range withString:aString];
	}
}


#pragma mark - NSTextView


- (void) insertText:(id)insertString
{
	if( insertingText ) {
		[super insertText:insertString];
		return;
	}
	
	// We setup undo for basically every character, except for stuff we insert.
	// So, start grouping.
	[[self undoManager] beginUndoGrouping];
	
	insertingText = YES;
	
	BOOL insertedText = NO;
	NSRange selection = [self selectedRange];
	if( selection.length > 0 ) {
		insertedText = [self didHandleInsertOfString:insertString withSelection:selection];
	}
	else {
		insertedText = [self didHandleInsertOfString:insertString];
	}
	
	if( !insertedText ) {
		[super insertText:insertString];
	}
	
	insertingText = NO;
	
	// End undo grouping.
	[[self undoManager] endUndoGrouping];
}


- (NSArray*) readablePasteboardTypes
{
	// This prevents pasting of rich text.
    return @[NSPasteboardTypeString];
}


#pragma mark - Private Methods


- (BOOL) didHandleInsertOfString:(NSString*)string
{
	if( [string length] == 0 ) return NO;
	
	unichar character = [string characterAtIndex:0];
	
	if( character == '(' || character == '[' || character == '{' || character == '\"' )
	{
		// (, [, {, ", ` : insert that, and end character.
		unichar startCharacter = character;
		unichar endCharacter;
		switch( startCharacter ) {
			case '(': endCharacter = ')'; break;
			case '[': endCharacter = ']'; break;
			case '{': endCharacter = '}'; break;
			case '\"': endCharacter = '\"'; break;
		}
		
		if( character == '\"' ) {
			// Double special case for quote. If the character immediately to the right
			// of the insertion point is a number, we're done.  That way if you type,
			// say, 27", it works as you expect.
			NSRange selectionRange = [self selectedRange];
			if( selectionRange.location > 0 ) {
				unichar lastChar = [[self string] characterAtIndex:selectionRange.location - 1];
				if( [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:lastChar] ) {
					return NO;
				}
			}
			
			// Special case for quote, if we autoinserted that.
			// Type through it and we're done.
			if( lastCharacterInserted == '\"' ) {
				lastCharacterInserted = 0;
				lastCharacterWhichCausedInsertion = 0;
				[self moveRight:nil];
				return YES;
			}
		}
		
		NSString* replacementString = [NSString stringWithFormat:@"%c%c", startCharacter, endCharacter];
		
		[self insertText:replacementString];
		[self moveLeft:nil];
		
		// Remember the character, so if the user deletes it we remember to also delete the
		// one we inserted.
		lastCharacterInserted = endCharacter;
		lastCharacterWhichCausedInsertion = startCharacter;
		
		if( lastCharacterWhichCausedInsertion == '{' ) {
			justInsertedBrace = YES;
		}
		
		return YES;
	}
	else if( character == ')' || character == ']' || character == '}' || character == '\"' ) {
		if( lastCharacterInserted == character ) {
			// We recently inserted one of these.  Just type through it; don't insert anything.
			// But then forget we did that.
			lastCharacterInserted = 0;
			lastCharacterWhichCausedInsertion = 0;
			[self moveRight:nil];
			return YES;
		}
	}
	else if( character == NSTabCharacter ) {
		// If hit tab, and the next character is the last character inserted, type through it.
		NSInteger nextIndex = [self selectedRange].location;
		NSString* fullText = [self string];
		if( nextIndex < [fullText length] ) {
			unichar nextChar = [fullText characterAtIndex:nextIndex];
			if( nextChar == lastCharacterInserted ) {
				lastCharacterInserted = 0;
				lastCharacterWhichCausedInsertion = 0;
				[self moveRight:nil];
				return YES;
			}
		}
	}
	else if( character == NSNewlineCharacter || character == NSCarriageReturnCharacter || character == NSTabCharacter ) {
		// Do code formatting stuff.
		return [self handleCodeFormatting:character];
	}
	
	return NO;
}


- (BOOL) didHandleInsertOfString:(NSString*)string withSelection:(NSRange)range
{
	unichar character = [string characterAtIndex:0];
	
	justInsertedBrace = NO;
	
	if( character == '(' || character == '[' || character == '{' || character == '<' ||
			character == '\"' || character == '`' )
	{
		// (, [, {, <, ", ` : surround selection with (), [], {}, <>, "", ``.
		unichar startCharacter = character;
		unichar endCharacter;
		switch( startCharacter ) {
			case '(': endCharacter = ')'; break;
			case '[': endCharacter = ']'; break;
			case '{': endCharacter = '}'; break;
			case '\'': endCharacter = '\''; break;
			case '\"': endCharacter = '\"'; break;
			case '<': endCharacter = '>'; break;
			case '`': endCharacter = '`'; break;
		}
		NSString* startString = [NSString stringWithFormat:@"%c", startCharacter];
		NSString* endString = [NSString stringWithFormat:@"%c", endCharacter];
		[self replaceCharactersInRange:NSMakeRange( range.location, 0 )
							withString:startString];
		[self replaceCharactersInRange:NSMakeRange( range.location + range.length + 1, 0 )
							withString:endString];
		[self moveRight:nil];
		[self moveRight:nil];
		return YES;
	}
	else if( character == '{' ) {
		justInsertedBrace = YES;
	}
	
	return NO;
}


- (BOOL) handleCodeFormatting:(unichar)characterEntered;
{
	NSString* wholeText = [self string];
	
	// Get current line.
	NSRange selection = [self selectedRange];
	if( selection.location == 0 ) return NO;
	
	selection.location--;
	selection.length++;
	unichar aChar = [wholeText characterAtIndex:selection.location];
	while( aChar != NSNewlineCharacter && aChar != NSCarriageReturnCharacter && selection.location > 0) {
		selection.location--;
		selection.length++;
		aChar = [wholeText characterAtIndex:selection.location];
	}
	if( aChar == NSNewlineCharacter || aChar == NSCarriageReturnCharacter) {
		selection.location++;
		selection.length--;
	}
	
	NSString* lastLine = [wholeText substringWithRange:selection];
	
	NSArray* strings = [lastLine stringsByTrimmingLeadingWhitespace];
	NSString* leadingWhitespace = strings[0];
    lastLine = strings[1];
	
	if( [lastLine length] == 0 ) return NO;
	
	[self insertNewlineIgnoringFieldEditor:nil];
	[self insertText:leadingWhitespace];
	
	// If the last line ended with a {, add an additional tab, and a buncha other stuff.
	if( justInsertedBrace ) {
		// Indent us in one more level.
		[self insertText:[NSString stringWithFormat:@"%c", NSTabCharacter]];
		
		// Remember where we are.
		NSUInteger curPosition = [self selectedRange].location;
		
		// Insert return.
		[self insertText:[NSString stringWithFormat:@"%c", NSCarriageReturnCharacter]];
		
		// Insert close brace, indented.
		[self insertText:leadingWhitespace];
		
		// Go back.
		NSRange currentRange = NSMakeRange( curPosition, 0 );
		[self setSelectedRange:currentRange];
		
		justInsertedBrace = NO;
	}
	
	return YES;
}


- (void) setup
{
	[self setFont:[NSFont fontWithName:@"Menlo" size:14.0]];
	[self setTextContainerInset:NSMakeSize( 20.0, 20.0 )];
}

@end
