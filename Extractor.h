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

extern NSXMLDocumentContentKind WAEXMLDocumentKindFromString(NSString *str);

@interface Extractor : NSObject 

+ (NSURL *)extractWebArchiveAtURL:(NSURL *)webArchiveURL entryFileName:(NSString *)entryName contentKind:(NSXMLDocumentContentKind)contentKind URLPrepend:(NSString *)URLPrepend;
+ (NSURL *)extractWebArchiveAtURL:(NSURL *)webArchiveURL;

// load web archive file
- (void)loadWebArchiveAtURL:(NSURL *)webArchiveURL;

// extract to directory
- (NSURL *)extractResourcesToURL:(NSURL *)url withUniqueDirectoryName:(BOOL)uniqueName;
- (NSURL *)extractResourcesToURL:(NSURL *)url;

@property (copy)	NSString	*entryFileName;
@property (assign)	NSXMLDocumentContentKind contentKind;
@property (copy)	NSString	*URLPrepend;

@end
