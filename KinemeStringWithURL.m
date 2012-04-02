#include "stdio.h"

#import "KinemeStringWithURL.h"

	
@implementation KinemeStringWithURL

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
		[[self userInfo] setObject:@"Kineme String With URL" forKey:@"name"];
	}
	return self;
}

- (BOOL)execute:(id)openglcontext time:(double)time arguments:(id)arguments
{
	if([inputURL wasUpdated] || ([inputUpdate wasUpdated] && [inputUpdate booleanValue]))
	{
		NSData *d = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [inputURL stringValue]]];
		if(d)
		{
			NSString *s = [[NSString alloc] initWithData: d encoding: NSUTF8StringEncoding];
			if(s == nil)	// UTF8 fails for some ascii string (foundation bug?)
				s = [[NSString alloc] initWithData: d encoding: NSASCIIStringEncoding];
			[outputURLContent setStringValue: s];
			[d release];
			[s release];
		}
	}

	return YES;
}
	
@end
