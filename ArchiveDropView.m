//
//  Apple Public Source License
//  http://www.opensource.apple.com/apsl/
//
//  Created by Vitaly Davidenko on 12/10/06.
//  Copyright 2006 Vitaly Davidenko.
//
//	Updated and refactored by Rob Rohan on 2007-09-18

#import "ArchiveDropView.h"
#import "Extractor.h"
#import "OutputType.h"

static void logMessage(NSTextView* log, NSColor* color, NSString* message)
{
	[log setEditable:YES];
	
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: [log typingAttributes]];
	[dict setValue:color forKey:NSForegroundColorAttributeName];
	[log setTypingAttributes:dict];
	[log insertText: message ];
	[log insertText: @"\n" ];
	[log setEditable:NO];
	[log displayIfNeeded];
}

@implementation ArchiveDropView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		// Add initialization code here
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
		
		//set the drop target image
		[self setImage:[NSImage imageNamed:@"extract_archive"]];
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	NSRect ourBounds = [self bounds];
    NSImage *image = [self image];
	NSPoint p = { .x = round((ourBounds.size.width - [image size].width) / 2.0), .y = round((ourBounds.size.height - [image size].height) / 2.0) };
    [super drawRect:rect];
	[image drawAtPoint:p fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

////////////////////////////////////////////////////////////////

- (void)logError:(NSString*) message
{
	logMessage(logOutput, [NSColor redColor], message);
}

- (void)logWarning:(NSString*) message
{
	logMessage(logOutput, [NSColor orangeColor], message);
}

- (void)logInfo:(NSString*) message
{
	logMessage(logOutput, [NSColor blueColor], message);
}

- (void)logResult:(NSString*) message
{
	logMessage(logOutput, [NSColor darkGrayColor], message);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	[logOutput selectAll:self];
	[logOutput insertText:@""];
    NSPasteboard *pboard = [sender draggingPasteboard];
	
	///////////////////////////////////
	// This probably shouldn't be here
	
	//get the user defined index name
	NSString * indexFileName = [[userDefaults values] valueForKey:@"WAEIndexName"];
	if (indexFileName == nil || [indexFileName length] == 0)
		indexFileName = @"index.html";
	
	//get the user selected output type
	//HACK alert. I need to figure out a better way to do this. I thought the User
	//types from the select box would get an object, but it only returns a string :-/
	NSString * outputType = [[userDefaults values] valueForKey:@"WAEOutputType"];
	int type = NSXMLDocumentXHTMLKind;
	if ( [outputType isEqualToString:@"HTML"] )
		type = NSXMLDocumentHTMLKind;
	else if ( [outputType isEqualToString:@"XML"] )
		type = NSXMLDocumentXMLKind;
	else if ( [outputType isEqualToString:@"XHTML"] )
		type = NSXMLDocumentXHTMLKind;
	else if ( [outputType isEqualToString:@"Text"] )
		type = NSXMLDocumentTextKind;
	
	NSString * URLPrepend = [[userDefaults values] valueForKey:@"WAEURLOffset"];
	if (URLPrepend == nil || [URLPrepend length] == 0) {
		URLPrepend = @"";
	}
	///////////////////////////////////
	
	NSDictionary *options = @{ NSPasteboardURLReadingFileURLsOnlyKey: @YES, NSPasteboardURLReadingContentsConformToTypesKey: @[@"com.apple.webarchive"] };
	NSArray *fileURLs = [pboard readObjectsForClasses:@[[NSURL class]] options:options];

	for (NSURL *fileURL in fileURLs) {
		[self logInfo:[NSString stringWithFormat: NSLocalizedStringFromTable(@"processing", @"InfoPlist", @"processing file: 1 name"), [fileURL path]] ];
		
		NSURL *dirURL = [fileURL URLByDeletingLastPathComponent];
		NSNumber *isWritable;
		[dirURL getResourceValue:&isWritable forKey:NSURLIsWritableKey error:nil];

		if ([isWritable boolValue])
		{
			NSString *archiveName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
			NSURL *outputURL = [dirURL URLByAppendingPathComponent:archiveName];
			
			NSUInteger i = 0;
			NSString *dirNameFormat = [archiveName stringByAppendingString:@"-%i"];
			
			while([outputURL checkResourceIsReachableAndReturnError:nil])
			{
				[self logWarning:[NSString stringWithFormat: NSLocalizedStringFromTable(@"folder exists", @"InfoPlist", @"folder already exists: 1 name"), outputURL] ];
				outputURL  = [dirURL URLByAppendingPathComponent:[NSString stringWithFormat: dirNameFormat, i++]];
			}

			Extractor * extr = [[Extractor alloc] init];
			[extr loadWebArchiveAtURL:fileURL];
			[extr setEntryFileName:indexFileName];
			[extr setContentKind: type];
			[extr setURLPrepend: URLPrepend];
			NSURL *mainResourceURL = [extr extractResourcesToURL:outputURL];

			[self logResult:[NSString stringWithFormat: NSLocalizedStringFromTable(@"extract success", @"InfoPlist", @"extract success 1=folder name 2=main file"), outputURL, [mainResourceURL path]]];
		}
	}
	
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    //NSDragOperation sourceDragMask;
	
    //sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];

	NSDictionary *options = @{ NSPasteboardURLReadingFileURLsOnlyKey: @YES, NSPasteboardURLReadingContentsConformToTypesKey: @[@"com.apple.webarchive"] };
	
    if ( [pboard canReadObjectForClasses:@[[NSURL class]] options:options] )
		return NSDragOperationCopy;
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender 
{
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender 
{
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	//[self setNeedsDisplay:YES];
}

@end
