#include "stdio.h"

#import "KinemeStringWithFile.h"

	
@implementation KinemeStringWithFile

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
}
	
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return FALSE;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[[self userInfo] setObject:@"Kineme String With File" forKey:@"name"];
	}
	return self;
}	

- (BOOL)execute:(id)openglcontext time:(double)time arguments:(id)arguments
{
	if( [inputFilePath wasUpdated] || ([inputUpdate wasUpdated] && [inputUpdate booleanValue]))
	{
		// manual retain/release is faster than roundtrip through an autorelease pool
		NSString *path = KIExpandPath(self,[inputFilePath stringValue]);
		NSData *d = [[NSData alloc] initWithContentsOfFile: path];
		if(d)
		{
			NSString *s = [[NSString alloc] initWithData: d encoding: NSUTF8StringEncoding];
			if(s == nil)	// UTF8 fails for some ascii string (foundation bug?)
				s = [[NSString alloc] initWithData: d encoding: NSASCIIStringEncoding];
			[outputFileContent setStringValue:s];
			[d release];
			[s release];
		}
	}

	return YES;
}
	
@end
