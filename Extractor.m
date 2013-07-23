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

@implementation Extractor

- (id) init
{
	if (self = [super init]) {

		//default to XHTML if there is nothing else
		_contentKind = NSXMLDocumentXHTMLKind;
	}

	return self;
}

- (void)loadWebArchiveAtURL:(NSURL *)webArchiveURL {
	if (m_resources)
	{
		[m_resources removeAllObjects];
		[m_resourceLookupTable removeAllObjects];
	}
	else
	{
		m_resources = [NSMutableSet set];
		m_resourceLookupTable = [NSMutableDictionary dictionary];
	}

	NSData * webArchiveContent = [NSData dataWithContentsOfURL:webArchiveURL];
	WebArchive * archive = [[WebArchive alloc] initWithData:webArchiveContent];


	/* Added method parseWebArchive to more easily deal with subframeArchives in a looping fashion
	 Deal with main resource first...may or may not cover it all - Robert Covington artlythere@kagi.com
	 12/12/11
	 */

	[self parseWebArchive:archive ];

	/*
	 Check for SubFrameArchives - catches anything left over...some sites using frames will
	 invoke this and otherwise would generate only a single HTML index file
	 - Robert Covington artlythere@kagi.com 12/12/11
	 */

	NSArray * subArchives = [archive subframeArchives];

	if (subArchives)
	{
		int i;
		for (i=0; i<[subArchives count]; i++)
		{
			WebArchive *nuArchive = subArchives[i];
			if (nuArchive)
			{
				[self parseWebArchive:nuArchive];
			}
		}

	}  /* end subArchive processing */
}  /* end method */

-(void) loadWebArchive:(NSString*) pathToWebArchive
{
	[self loadWebArchiveAtURL:[NSURL fileURLWithPath:pathToWebArchive]];
}  /* end method */


-(void) parseWebArchive:(WebArchive *) archiveToParse
{
	/* Added method parseWebArchive to more easily deal with subframeArchives in a looping fashion
	 - Robert Covington artlythere@kagi.com
	 12/12/11
	 */
	m_mainResource = [archiveToParse mainResource];
	[self addResource:m_mainResource];

	NSArray * subresources = [archiveToParse subresources];
	if (subresources)
	{
		WebResource* resource;
		int i;
		for (i=0; i<[subresources count]; i++)
		{
			resource = (WebResource*) subresources[i];
			[self addResource:resource];
		}
	}
}


-(void) addResource:(WebResource *)resource
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

- (NSURL *)extractResourcesToURL:(NSURL *)url {
	NSFileManager * fm = [NSFileManager defaultManager];
	NSNumber *isDirectory = nil;

	if ([url checkResourceIsReachableAndReturnError:nil] && [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil] && [isDirectory boolValue])
	{
		if (![fm removeItemAtURL:url error:nil])
		{
			NSLog(
				  NSLocalizedStringFromTable(
											 @"cannot delete",
											 @"InfoPlist",
											 @"cannot delete file - path first param"
											 ),
				  [url path]
				  );
			return nil;
		}
	}

	if (![fm createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:nil])
	{
		NSLog(
			  NSLocalizedStringFromTable(
										 @"cannot create",
										 @"InfoPlist",
										 @"cannot create file - path first param"
										 ),
			  [url path]
			  );
		return nil;
	}

	for (WebResource *resource in m_resources)
		[self extractResource:resource packageURL:url];

	return [url URLByAppendingPathComponent:[self entryFileName]];
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
			  NSLocalizedStringFromTable(@"resource encoding is", @"InfoPlist", @"Resource encoding"),
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
					  NSLocalizedStringFromTable(
												 @"cannot execute xpath",
												 @"InfoPlist",
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

			if (![[doc XMLDataWithOptions: NSXMLDocumentXHTMLKind] writeToURL:fileURLXHtml atomically:NO]) {
				NSLog(
					  NSLocalizedStringFromTable(
												 @"cannot write xhtml",
												 @"InfoPlist",
												 @"xhtml file error"
												 ),
					  fileURL
					  );
			}
		} else {
			NSLog(
				  NSLocalizedStringFromTable(
											 @"error code",
											 @"InfoPlist",
											 @"extractor error. error code first param"
											 ),
				  [[err userInfo] valueForKey:NSLocalizedDescriptionKey]
				  );
		}
	} else {
		if (![[resource data] writeToURL:fileURL atomically:NO]) {
			NSLog(
				  NSLocalizedStringFromTable(
											 @"cannot write xhtml",
											 @"InfoPlist",
											 @"xhtml file error"
											 ),
				  fileURL
				  );
		}
	}
}


@end
