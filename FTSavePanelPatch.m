#import "FTSavePanelPatch.h"

@implementation FTSavePanelPatch

+(BOOL)allowsSubpatchesWithIdentifier:(id)identifier
{
	return NO;
}


-(id)initWithIdentifier:(id)identifier
{
	if(self = [super initWithIdentifier:identifier])
	{
		[[self userInfo] setObject:@"Kineme Save Panel" forKey:@"name"];

		// set default input port values here.
		[inputTitle setStringValue:@"Save"];
		[inputPrompt setStringValue:@"Save"];
		[inputNameFieldLabel setStringValue:@"Save As:"];

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
	if(savePanel)
	{
		[savePanel release];
		savePanel=nil;
	}
}

-(BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)arguments
{
	if(!allowed)
		return YES;


	[outputOKSignal setBooleanValue:NO];
	[outputCancelSignal setBooleanValue:NO];

	if([inputStartSignal wasUpdated] && [inputStartSignal booleanValue])
		[self performSelectorOnMainThread:@selector(showSavePanel) withObject:nil waitUntilDone:NO];

	return YES;
}

- (void)showSavePanel
{
	if(savePanel)
		[savePanel makeKeyAndOrderFront:self];
	else
	{
		savePanel = [[NSSavePanel alloc] init];
		[savePanel setTitle:[inputTitle stringValue]];
		[savePanel setMessage:[inputMessage stringValue]];
		[savePanel setPrompt:[inputPrompt stringValue]];
		[savePanel setNameFieldLabel:[inputNameFieldLabel stringValue]];
		[savePanel setCanCreateDirectories:[inputCanCreateDirectories booleanValue]];

		[savePanel setAllowsOtherFileTypes:NO];

		NSString *dir=nil;
		NSURL *url = [NSURL URLWithString:[inputInitialURL stringValue]];
		if([url isFileURL])
			dir = [url path];

		NSArray *types = nil;
		NSString *typestr = [[inputAllowedFileTypes stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
		if([typestr length])
			types = [typestr componentsSeparatedByString:@","];
		[savePanel setAllowedFileTypes:types];

		[savePanel
			beginSheetForDirectory:dir
			file:[inputInitialFilename stringValue]
			modalForWindow:nil
			modalDelegate:self
			didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
			contextInfo:NULL];
	}
}

- (void)savePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	switch(returnCode)
	{
		case NSOKButton:
			[outputOKSignal setBooleanValue:YES];
			[outputSelectedURL setStringValue:[[panel URL] absoluteString]];
			break;
		case NSCancelButton:
			[outputCancelSignal setBooleanValue:YES];
			break;
	}

	[panel release];
	savePanel=nil;
}

@end
