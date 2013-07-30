//
//  WAEAppDelegate.m
//  WebArchiveExtractor
//
//  Created by Wevah on 2013-07-23.
//
//

#import "WAEAppDelegate.h"
#import "Extractor.h"
#import "WAELogWindowController.h"

@implementation WAEAppDelegate

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {	
	//NSURL *mainResourceURL =
	[Extractor extractWebArchiveAtURL:[NSURL fileURLWithPath:filename]];
	return YES;
}

- (IBAction)showLogWindow:(id)sender {
	[[WAELogWindowController sharedController] showWindow:sender];
}

- (IBAction)openDocument:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowedFileTypes:@[ @"com.apple.webarchive" ]];
	[panel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[Extractor extractWebArchiveAtURL:[panel URL]];
		}
	}];
}

@end
