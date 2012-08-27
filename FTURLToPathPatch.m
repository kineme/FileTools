#import "FTURLToPathPatch.h"

@implementation FTURLToPathPatch

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
		[[self userInfo] setObject:@"Kineme URL to Path" forKey:@"name"];

		[inputURL setStringValue:@"file:///Library/Desktop%20Pictures/"];
	}
	return self;
}

-(BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)arguments
{
	NSURL *u = [[NSURL alloc] initWithString:[inputURL stringValue]];
	NSString *p = @"";
	if([u isFileURL])
	{
		p = (NSString *)CFURLCopyPath((CFURLRef)u);
		p = [p stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
	}
	[outputPath setStringValue:p];
	[u release];

	return YES;
}

@end
