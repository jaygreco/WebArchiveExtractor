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
#import "WAELogWindowController.h"


@interface ArchiveDropView ()

@property (assign,getter=isHighlighted)	BOOL	highlighted;
@property (assign)						BOOL	drawsDottedBorder;

@end

@implementation ArchiveDropView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		// Add initialization code here
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
		
		//set the drop target image
		[self setImage:[NSImage imageNamed:@"extract_archive"]];
		_drawsDottedBorder = YES;
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	
	if (self.drawsDottedBorder) {
		NSRect borderRect = NSInsetRect(bounds, 2.0, 2.0);
		NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:16.0 yRadius:16.0];
		CGFloat dash[] = { 16.0, 8.0 };
		[border setLineDash:dash count:sizeof(dash) / sizeof(dash[0]) phase:8.0];
		[border setLineWidth:4.0];
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.3] set];
		[border stroke];
	}

    NSImage *image = [self image];
	NSPoint p = { .x = round((bounds.size.width - [image size].width) / 2.0), .y = round((bounds.size.height - [image size].height) / 2.0) };
    [super drawRect:rect];

	NSImage *finalImage = image;
	
	if (self.highlighted) {
		finalImage = [image copy];
		[finalImage lockFocus];
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
		NSRectFillUsingOperation(bounds, NSCompositeSourceAtop);
		[finalImage unlockFocus];
	}

	[finalImage drawAtPoint:p fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	[logOutput selectAll:self];
	[logOutput insertText:@""];
    NSPasteboard *pboard = [sender draggingPasteboard];	

	NSDictionary *options = @{ NSPasteboardURLReadingFileURLsOnlyKey: @YES, NSPasteboardURLReadingContentsConformToTypesKey: @[@"com.apple.webarchive"] };
	NSArray *fileURLs = [pboard readObjectsForClasses:@[[NSURL class]] options:options];

	WAELogWindowController *logController = [WAELogWindowController sharedController];

	for (NSURL *fileURL in fileURLs) {
		[logController logInfo:[NSString stringWithFormat: NSLocalizedString(@"processing", @"processing file: 1 name"), [fileURL path]] ];
		
		NSURL *dirURL = [fileURL URLByDeletingLastPathComponent];
		NSNumber *isWritable;
		[dirURL getResourceValue:&isWritable forKey:NSURLIsWritableKey error:nil];
		
		if ([isWritable boolValue]) {			
			NSURL *mainResourceURL = [Extractor extractWebArchiveAtURL:fileURL];
			
			[logController logResult:[NSString stringWithFormat: NSLocalizedString(@"extract success", @"extract success 1=folder name 2=main file"), [[mainResourceURL path] stringByDeletingLastPathComponent], [mainResourceURL path]]];
		}
	}
	
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard = [sender draggingPasteboard];

	NSDictionary *options = @{ NSPasteboardURLReadingFileURLsOnlyKey: @YES, NSPasteboardURLReadingContentsConformToTypesKey: @[@"com.apple.webarchive"] };
	
    if ( [pboard canReadObjectForClasses:@[[NSURL class]] options:options] ) {
		self.highlighted = YES;
		[self setNeedsDisplay:YES];
		return NSDragOperationCopy;
	}
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender 
{
	self.highlighted = NO;
	[self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender 
{
	self.highlighted = NO;
	[self setNeedsDisplay:YES];
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
