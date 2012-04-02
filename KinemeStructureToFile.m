#import "KinemeStructureToFile.h"

@implementation KinemeStructureToFile : QCPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeConsumer;
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
		[inputFile setStringValue:@"~/Desktop/Structure.plist"];
		[[self userInfo] setObject:@"Kineme Structure To File" forKey:@"name"];
	}
	return self;
}


- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	if([inputWriteSignal wasUpdated] &&  [inputWriteSignal booleanValue] && [inputStructure structureValue] != nil)
	{
		NSString *path = KIExpandPath(self,[inputFile stringValue]);
		if([path length] != 0)
		{
			NSMutableData *data = [NSMutableData new];
			NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[[inputStructure structureValue] encodeWithCoder:coder];
			[coder finishEncoding];
			[coder release];
			[data writeToFile:path atomically:NO];
			[data release];
		}
	}
	
	return YES;
}

@end
