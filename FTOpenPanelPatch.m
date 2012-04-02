#import "FTOpenPanelPatch.h"

@implementation FTOpenPanelPatch

+(BOOL)allowsSubpatchesWithIdentifier:(id)identifier
{
	return NO;
}

-(id)initWithIdentifier:(id)identifier
{
	if(self = [super initWithIdentifier:identifier])
	{
		[[self userInfo] setObject:@"Kineme Open Panel" forKey:@"name"];

		// set default input port values here.
		[inputTitle setStringValue:@"Open"];
		[inputPrompt setStringValue:@"Open"];
		[inputCanChooseFiles setBooleanValue:YES];

		// only allow the window to actually activate if we're in the QC Editor or a QuartzBuilder application, so we don't spam users totally unexpectedly (from Finder, for example).
		if([[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey] isEqualToString:@"com.apple.QuartzComposer.editor"])
			allowed=YES;
		else if(objc_getClass("RunnerController") && objc_getClass("RunnerWindow") && objc_getClass("RunnerView") && objc_getClass("QBParameterView"))
			allowed=YES;
	}
	return self;
}

-(void)disable:(QCOpenGLContext*)context
{
	if(openPanel)
	{
		[openPanel release];
		openPanel=nil;
	}
}

-(BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)arguments
{
	if(!allowed)
		return YES;


	[outputOKSignal setBooleanValue:NO];
	[outputCancelSignal setBooleanValue:NO];

	if([inputStartSignal wasUpdated] && [inputStartSignal booleanValue])
		[self performSelectorOnMainThread:@selector(showOpenPanel) withObject:nil waitUntilDone:NO];

	return YES;
}

- (void)showOpenPanel
{
	if(openPanel)
		[openPanel makeKeyAndOrderFront:self];
	else
	{
		openPanel = [[NSOpenPanel alloc] init];
		[openPanel setTitle:[inputTitle stringValue]];
		[openPanel setMessage:[inputMessage stringValue]];
		[openPanel setPrompt:[inputPrompt stringValue]];
		[openPanel setCanChooseFiles:[inputCanChooseFiles booleanValue]];
		[openPanel setCanChooseDirectories:[inputCanChooseDirectories booleanValue]];
		[openPanel setAllowsMultipleSelection:[inputAllowsMultipleSelection booleanValue]];
		[openPanel setAllowsOtherFileTypes:NO];

		NSString *dir=nil;
		NSURL *url = [NSURL URLWithString:[inputInitialURL stringValue]];
		if([url isFileURL])
			dir = [url path];

		NSArray *types = nil;
		NSString *typestr = [[inputAllowedFileTypes stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
		if([typestr length])
			types = [typestr componentsSeparatedByString:@","];

		[openPanel
			beginForDirectory:dir
			file:nil
			types:types
			modelessDelegate:self
			didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
			contextInfo:NULL];
	}
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	switch(returnCode)
	{
		case NSOKButton:
			[outputOKSignal setBooleanValue:YES];
			NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:10];
			for(NSURL *u in [panel URLs])
				[a addObject:[u absoluteString]];
			QCStructure *s = [[QCStructure alloc] initWithArray:a];
			[a release];
			[outputSelectedURLs setStructureValue:s];
			[s release];
			break;
		case NSCancelButton:
			[outputCancelSignal setBooleanValue:YES];
			break;
	}

	[panel release];
	openPanel=nil;
}

@end
