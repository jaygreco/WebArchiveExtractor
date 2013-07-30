//
//  WAELogWindowController.h
//  WebArchiveExtractor
//
//  Created by Wevah on 2013-07-30.
//
//

#import <Cocoa/Cocoa.h>

typedef enum : NSInteger {
	WAELogLevelInfo,
	WAELogLevelWarning,
	WAELogLevelError,
	WAELogLevelResult
} WAELogLevel;

@interface WAELogWindowController : NSWindowController

+ (instancetype)sharedController;

- (void)logMessage:(NSString *)message ofLevel:(WAELogLevel)level;
- (void)logError:(NSString *)message;
- (void)logWarning:(NSString *)message;
- (void)logInfo:(NSString *)message;
- (void)logResult:(NSString *)message;

@end
