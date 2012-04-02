#import "KinemeFileInfo.h"


@implementation KinemeFileInfo : QCPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProcessor;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[[self userInfo] setObject:@"Kineme File Info" forKey:@"name"];
	}
	return self;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	if( [inputPath wasUpdated] )
	{
		NSString *path = KIExpandPath(self,[inputPath stringValue]);
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		if( [defaultManager fileExistsAtPath: path] )
		{
			[outputExists setBooleanValue: YES];
			NSDictionary *dict = [defaultManager fileAttributesAtPath: path traverseLink:TRUE];
			[outputSize setIndexValue: [[dict objectForKey:NSFileSize] integerValue]];
			[outputCreatedTime setDoubleValue: [[dict objectForKey:NSFileCreationDate] timeIntervalSince1970]];
			[outputModifiedTime setDoubleValue: [[dict objectForKey:NSFileModificationDate] timeIntervalSince1970]];
			[outputType setStringValue: [dict objectForKey:NSFileType]];
		}
		else	// doesn't exist, clear everything
		{
			[outputExists setBooleanValue: FALSE];
			[outputType setStringValue: @""];
			[outputSize setIndexValue: 0];
			[outputCreatedTime setDoubleValue: 0.0];
			[outputModifiedTime setDoubleValue: 0.0];
			//[outputAccessedTime setDoubleValue: 0.0];
		}
		
	}

	return YES;
}

@end
