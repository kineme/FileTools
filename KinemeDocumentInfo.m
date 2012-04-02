#include "stdio.h"

#import "KinemeDocumentInfo.h"
	
@implementation KinemeDocumentInfo

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProcessor;
}
	
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return FALSE;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[[self userInfo] setObject:@"Kineme Document Info" forKey:@"name"];
	}
	return self;
}

- (BOOL)execute:(id)openglcontext time:(double)time arguments:(id)arguments
{
	NSDocumentController *sdc=[NSDocumentController sharedDocumentController];

//	NSDocument *d=[sdc currentDocument];

	[outputCurrentDirectory setStringValue:[sdc currentDirectory]];

	unsigned c=[[sdc documents] count];

	if( c>0 )
	{
		NSDocument *d=[[sdc documents] objectAtIndex:0];

//	NSFileManager *f=[NSFileManager defaultManager];
//  seems to always return /
//	[outputFileContent setStringValue:[f currentDirectoryPath]];
//	[outputFileContent setStringValue:  [NSString stringWithFormat:@"hi %u",c]  ];

		[outputDocumentDisplayName setStringValue:[d displayName]];
		[outputDocumentModificationDate setStringValue:[[d fileModificationDate] description]];
		[outputDocumentFileName setStringValue:[d fileName]];
		[outputDocumentFileURL setStringValue:[[d fileURL] absoluteString]];
		[outputDocumentIsEdited setBooleanValue:[d isDocumentEdited]];
	}

	return YES;
}
	
@end
