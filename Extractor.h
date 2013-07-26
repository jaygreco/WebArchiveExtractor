//
//  Exctractor.h
//  ExtractorAction
//
//  Created by Vitaly Davidenko on 12/10/06.
//  Copyright 2006 Vitaly Davidenko.
//
//  Apple Public Source License
//  http://www.opensource.apple.com/apsl/
//
//	Updated and refactored by Rob Rohan on 2007-09-18

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface Extractor : NSObject 

+ (void)extractWebArchiveAtURL:(NSURL *)webArchiveURL toURL:(NSURL *)url;


// load web archive file
- (void)loadWebArchiveAtURL:(NSURL *)webArchiveURL;

// extract to directory
- (NSURL *)extractResourcesToURL:(NSURL *)url;

@property (copy)	NSString	*entryFileName;
@property (assign)	int			contentKind;
@property (copy)	NSString	*URLPrepend;

@end
