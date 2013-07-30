//
//  WAEAppDelegate.m
//  WebArchiveExtractor
//
//  Created by Wevah on 2013-07-23.
//
//

#import "WAEAppDelegate.h"
#import "Extractor.h"

@implementation WAEAppDelegate

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	Extractor *extractor = [[Extractor alloc] init];
	[extractor loadWebArchiveAtURL:[NSURL fileURLWithPath:filename]];
	return YES;
}

@end
