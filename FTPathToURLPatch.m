#import "FTPathToURLPatch.h"

@implementation FTPathToURLPatch

+(BOOL)isSafe
{
	// defaults to NO.
	// delete this method if using default.
	return YES;
}

+(BOOL)allowsSubpatchesWithIdentifier:(id)identifier
{
	// defaults to YES.
	// delete this method if using default.
	return NO;
}

+(QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier
{
	// defaults to kQCPatchExecutionModeProcessor.
	// delete this method if using default.
	return kQCPatchExecutionModeProcessor;
}

+(QCPatchTimeMode)timeModeWithIdentifier:(id)identifier
{
	// defaults to kQCPatchTimeModeNone.
	// delete this method if using default.
	return kQCPatchTimeModeNone;
}

-(id)initWithIdentifier:(id)identifier
{
	if(self = [super initWithIdentifier:identifier])
	{
		[[self userInfo] setObject:@"Kineme Path to URL" forKey:@"name"];

		[inputPath setStringValue:@"/Library/Desktop Pictures/"];
	}
	return self;
}

-(BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)arguments
{
	NSURL *u = [[NSURL alloc] initFileURLWithPath:[inputPath stringValue]];
	[outputURL setStringValue:[u absoluteString]];
	[u release];

	return YES;
}

@end
