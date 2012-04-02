#import "KinemeTextFileWriter.h"


@implementation KinemeTextFileWriter : QCPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeConsumer;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return NO;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[[self userInfo] setObject:@"Kineme Text File Writer" forKey:@"name"];
		
		[inputMode setMaxIndexValue:1];
	}
	return self;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	// write on rising edge
	if([inputSignal wasUpdated] && [inputSignal booleanValue])
	{
		NSString *path = KIExpandPath(self,[inputFile stringValue]);
		if([path length] != 0)
		{
			NSString *text = [inputText stringValue];
			switch([inputMode indexValue])
			{
				case 0: // Overwrite
				{
					[text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
					break;
				}
				case 1: // Append
				{
					NSFileHandle *fp = [NSFileHandle fileHandleForWritingAtPath:path];
					[fp seekToEndOfFile];
					[fp writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
					[fp closeFile];
					break;
				}
			}
		}
	}
	
	return YES;
}

@end
