//
//  WAELogWindowController.m
//  WebArchiveExtractor
//
//  Created by Wevah on 2013-07-30.
//
//

#import "WAELogWindowController.h"

@interface WAELogWindowController ()

@end

@implementation WAELogWindowController {
	IBOutlet NSTextView		*logView;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedController {
	static WAELogWindowController *sharedController;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedController = [[self alloc] initWithWindowNibName:@"LogWindow"];
		[sharedController window];
	});

	return sharedController;
}

- (NSColor *)colorForLogLevel:(WAELogLevel)level {
	switch (level) {
		case WAELogLevelError:
			return [NSColor redColor];
			break;
		case WAELogLevelWarning:
			return [NSColor orangeColor];
			break;
		case WAELogLevelInfo:
			return [NSColor blueColor];
			break;
		case WAELogLevelResult:
			return [NSColor darkGrayColor];
			break;
	}

	return [NSColor controlTextColor];
}

- (void)logMessage:(NSString *)message ofLevel:(WAELogLevel)level {
	NSTextStorage *storage = [logView textStorage];

	NSDictionary *attrs = @{ NSForegroundColorAttributeName: [self colorForLogLevel:level] };
	NSAttributedString *coloredMessage = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", message] attributes:attrs];

	[storage appendAttributedString:coloredMessage];

	[logView displayIfNeeded];
}

- (void)logError:(NSString *)message {
	[self logMessage:message ofLevel:WAELogLevelError];
}

- (void)logWarning:(NSString *)message {
	[self logMessage:message ofLevel:WAELogLevelWarning];
}

- (void)logInfo:(NSString *)message{
	[self logMessage:message ofLevel:WAELogLevelInfo];
}

- (void)logResult:(NSString *)message {
	[self logMessage:message ofLevel:WAELogLevelResult];
}

@end
