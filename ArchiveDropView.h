/* ArchiveDropView */
//
//  Apple Public Source License
//  http://www.opensource.apple.com/apsl/
//
//  Created by Vitaly Davidenko on 12/10/06.
//  Copyright 2006 Vitaly Davidenko.
//
//	Updated and refactored by Rob Rohan on 2007-09-18

#import <Cocoa/Cocoa.h>

@interface ArchiveDropView : NSView
{
    IBOutlet NSTextView *logOutput;
	IBOutlet NSUserDefaultsController *userDefaults;
}

@property (copy)	NSImage	*image;

@end
