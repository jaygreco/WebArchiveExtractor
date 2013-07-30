//
//  Exctractor.m
//  ExtractorAction
//
//  Created by Vitaly Davidenko on 12/10/06.
//  Copyright 2006 Vitaly Davidenko.
//
//  Apple Public Source License
//  http://www.opensource.apple.com/apsl/
//
//	Updated and refactored by Rob Rohan on 2007-09-18

#import "Extractor.h"

static NSString* composeEntryPointPath(NSString* packagePath, NSString* indexName)
{
	return [packagePath stringByAppendingPathComponent:indexName];
}

extern NSXMLDocumentContentKind WAEXMLDocumentKindFromString(NSString *str) {
	if ([str isEqualToString:@"HTML"])
		return NSXMLDocumentHTMLKind;
	else if ([str isEqualToString:@"XML"])
		return NSXMLDocumentXMLKind;
	else if ([str isEqualToString:@"XHTML"])
		return NSXMLDocumentXHTMLKind;
	else if ([str isEqualToString:@"Text"])
		return NSXMLDocumentTextKind;

	return NSXMLDocumentXHTMLKind;
}

@interface Extractor ()

/**
 parse WebArchive (can be main archive, or subframeArchives)
 added by Robert Covington to handle archives with subframeArchives
 */
-(void)parseWebArchive:(WebArchive *) archiveToParse;

/**
 * add resource to resource table
 */
- (void)addResource:(WebResource *) resource;

/**
 * private method
 * extract resource to existing packagePath (using outputResource)
 * (packagePath the same as path of extractResources message)
 */
- (void)extractResource:(WebResource *)resource packageURL:(NSURL *)url;

/**
 * protected method
 * write resource data to filePath
 * Parent directory of filePath should exists
 */
- (void)outputResource:(WebResource *)resource fileURL:(NSURL *)filePath packageURL:(NSURL *)packageURL;

@end

@implementation Extractor {
	WebResource		*m_mainResource;
	NSMutableSet	*m_resources;

	//in m_resourceLookupTable HTML resource can be stored with relative or
	//absolute path m_resourceLookupTable contains several keys for each resource
	// (as least 2: absolute and relative paths)
	NSMutableDictionary		*m_resourceLookupTable;
}


- (id) init
{
	if (self = [super init]) {

		//default to XHTML if there is nothing else
		_contentKind = NSXMLDocumentXHTMLKind;
		
		m_resources = [NSMutableSet set];
		m_resourceLookupTable = [NSMutableDictionary dictionary];
	}

	return self;
}

- (void)loadWebArchiveAtURL:(NSURL *)webArchiveURL {
	[m_resources removeAllObjects];
	[m_resourceLookupTable removeAllObjects];
	
	NSData *webArchiveContent = [NSData dataWithContentsOfURL:webArchiveURL];
	WebArchive *archive = [[WebArchive alloc] initWithData:webArchiveContent];

	/* Added method parseWebArchive to more easily deal with subframeArchives in a looping fashion
	 Deal with main resource first...may or may not cover it all - Robert Covington artlythere@kagi.com
	 12/12/11
	 */
	
	[self parseWebArchive:archive];
	
	/*
	 Check for SubFrameArchives - catches anything left over...some sites using frames will
	 invoke this and otherwise would generate only a single HTML index file
	 - Robert Covington artlythere@kagi.com 12/12/11
	 */
	
	NSArray * subArchives = [archive subframeArchives];

	if (subArchives) {
		for (WebArchive *nuArchive in [archive subframeArchives])
			[self parseWebArchive:nuArchive];
	}
}  /* end method */


- (void)parseWebArchive:(WebArchive *) archiveToParse
{
	/* Added method parseWebArchive to more easily deal with subframeArchives in a looping fashion
	 - Robert Covington artlythere@kagi.com
	 12/12/11
	 */
	m_mainResource = [archiveToParse mainResource];
	[self addResource:m_mainResource];

	for (WebResource *resource in [archiveToParse subresources])
		[self addResource:resource];
}


- (void)addResource:(WebResource *)resource
{
	[m_resources addObject:resource];

	//url of resource
	NSURL* url = [resource URL];
	NSString* absoluteString = [url absoluteString];
	NSString* path = [url path];

	if(path != nil) {
		//NSLog(@"resource url absoluteString = %s\n", [absoluteString cString] );
		m_resourceLookupTable[absoluteString] = resource;

		//NSLog(@"resource url path = %s\n", [path cString] );
		m_resourceLookupTable[path] = resource;

		//BOOL isFile = [url isFileURL];
		//if (isFile)
		//{
		//todo
		//}
	}
}

- (NSURL *)extractResourcesToURL:(NSURL *)url withUniqueDirectoryName:(BOOL)uniqueName {
	NSFileManager * fm = [NSFileManager defaultManager];

	if (uniqueName) {
		NSURL *dirURL = [url URLByDeletingLastPathComponent];
		NSString *archiveName = [url lastPathComponent];

		NSUInteger i = 0;
		NSString *dirNameFormat = [archiveName stringByAppendingString:@"-%ld"];

		while ([url checkResourceIsReachableAndReturnError:nil]) {
			//[self logWarning:[NSString stringWithFormat:NSLocalizedString(@"folder exists", @"folder already exists: 1 name"), url] ];
			url  = [dirURL URLByAppendingPathComponent:[NSString stringWithFormat: dirNameFormat, i++]];
		}
	}

	NSNumber *isDirectory;

	if ([url checkResourceIsReachableAndReturnError:nil] && [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil] && [isDirectory boolValue]) {
		if (![fm removeItemAtURL:url error:nil]) {
			NSLog(NSLocalizedString(@"cannot delete", @"cannot delete file - path first param"), [url path]);
			return nil;
		}
	}

	if (![fm createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:nil]) {
		NSLog(NSLocalizedString(@"cannot create", @"cannot create file - path first param"), [url path]);
		return nil;
	}

	for (WebResource *resource in m_resources)
		[self extractResource:resource packageURL:url];

	return [url URLByAppendingPathComponent:[self entryFileName]];
}

- (NSURL *)extractResourcesToURL:(NSURL *)url {
	return [self extractResourcesToURL:url withUniqueDirectoryName:NO];
}

- (void) extractResource:(WebResource *)resource packageURL:(NSURL *)packageURL
{
	NSFileManager * fm = [NSFileManager defaultManager];

	NSURL *url = [resource URL];
	NSString * urlPath = [url path];
	if ([urlPath isEqual:@"/"])
		urlPath = @"/__index.html";

	NSURL *fileURL = [packageURL URLByAppendingPathComponent:urlPath];
	
	NSURL *parent = [fileURL URLByDeletingLastPathComponent];
	if (![parent checkResourceIsReachableAndReturnError:nil])
		[fm createDirectoryAtURL:parent withIntermediateDirectories:YES attributes:nil error:nil];
	
	[self outputResource:resource fileURL:fileURL packageURL:packageURL];

}

- (void) outputResource:(WebResource *)resource
			   fileURL:(NSURL *)fileURL
			packageURL:(NSURL *)packageURL
{
	if (resource == m_mainResource) {
		NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[m_mainResource textEncodingName]));
		
		NSString * source = [[NSString alloc] initWithData:[resource data]
												   encoding:encoding];

		NSLog(
			  NSLocalizedString(@"resource encoding is", @"Resource encoding"),
			  [resource textEncodingName]
			  );
		
		NSError * err = nil;
		NSXMLDocument * doc = [NSXMLDocument alloc];
		doc = [doc initWithXMLString: source options: NSXMLDocumentTidyHTML error: &err];

		/*
		 Returns the kind of document content for output.
		 - (NSXMLDocumentContentKind)documentContentKind

		 Discussion
		 Most of the differences among content kind have to do with the handling of content-less
		 tags such as <br>. The valid NSXMLDocumentContentKind constants are
		 NSXMLDocumentXMLKind, NSXMLDocumentXHTMLKind, NSXMLDocumentHTMLKind,
		 and NSXMLDocumentTextKind.
		 */
		[doc setDocumentContentKind:[self contentKind]];

		if (doc)	{
			//process images
			err = nil;

			NSArray* images = [doc nodesForXPath:@"descendant::node()[@src] | descendant::node()[@href]"
										   error: &err];
			if (err) {
				NSLog(@"%@",
					  NSLocalizedString(
												 @"cannot execute xpath",
												 @"Xpath execute error"
												 )
					  );
			} else {
				//int i;
				//for (i = 0; i < [images count]; i++) {
				for (NSXMLElement * link in images) {
					NSXMLNode * href = [link attributeForName: @"href"];

					if (!href)
						href = [link attributeForName: @"src"];

					if (href) {
						NSString * hrefValue = [href objectValue];
						WebResource * res = m_resourceLookupTable[hrefValue];
						
						if (res) {
							//NSLog(@"%@", [[[res URL] path] substringFromIndex:1]);

							/* NSLog(@"%@",
							 [NSString stringWithFormat:@"%@%@", [self URLPrepend], [[[res URL] path] substringFromIndex:1]]
							 ); */

							//[href setObjectValue: [[[res URL] path] substringFromIndex:1] ];
							[href setObjectValue: [NSString stringWithFormat:@"%@%@", [self URLPrepend], [[[res URL] path] substringFromIndex:1]]];
						}
					}
				}
			}

			//NSString * filePathXHtml = composeEntryPointPath(packageURL, [self entryFileName]);
			NSURL *fileURLXHtml = [packageURL URLByAppendingPathComponent:[self entryFileName]];
			[doc setCharacterEncoding: @"UTF-8"];

			if (![[doc XMLDataWithOptions:NSXMLDocumentXHTMLKind] writeToURL:fileURLXHtml atomically:NO]) {
				NSLog(
					  NSLocalizedString(
												 @"cannot write xhtml",
												 @"xhtml file error"
												 ),
					  fileURL
					  );
			}
		} else {
			NSLog(
				  NSLocalizedString(
											 @"error code",
											 @"extractor error. error code first param"
											 ),
				  [[err userInfo] valueForKey:NSLocalizedDescriptionKey]
				  );
		}
	} else {
		if (![[resource data] writeToURL:fileURL atomically:NO]) {
			NSLog(
				  NSLocalizedString(
											 @"cannot write xhtml",
											 @"xhtml file error"
											 ),
				  fileURL
				  );
		}
	}
}


@end
