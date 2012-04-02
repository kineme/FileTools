#import "KinemeStructureFromFile.h"


@implementation KinemeStructureFromFile : QCPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
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
		[[self userInfo] setObject:@"Kineme Structure From File" forKey:@"name"];
	}
	return self;
}


- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	if([inputSignal wasUpdated] && [inputSignal booleanValue] && [[inputFile stringValue] length] > 0)
	{
		QCStructure *structure = nil;
		NSString *path = KIExpandPath(self,[inputFile stringValue]);
		NSData *data = [NSData dataWithContentsOfFile:path];
		if(!data)
		{
			[outputStructure setStructureValue:nil];
			return YES;
		}

		@try
		{
			NSKeyedUnarchiver *coder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			structure = [[QCStructure alloc] initWithCoder:coder];
			[coder finishDecoding];
			[coder release];
		}
		@catch(NSException *exception)
		{
			// KeyedUnarchival failed, so this might be an NSDictionary-stored-as-plist

			NSDictionary *fileDict = (NSDictionary *)
				[NSPropertyListSerialization propertyListFromData:data
					mutabilityOption:NSPropertyListImmutable
					format:NULL
					errorDescription:nil];

			structure = [[QCStructure alloc] initWithDictionary:fileDict];
		}
		[outputStructure setStructureValue:structure];
		[structure release];
	}
	
	return YES;
}

@end
