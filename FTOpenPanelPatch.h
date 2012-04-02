@interface FTOpenPanelPatch : QCPatch
{
	QCBooleanPort *inputStartSignal;
	QCStringPort *inputInitialURL;
	QCStringPort *inputTitle;
	QCStringPort *inputMessage;
	QCStringPort *inputPrompt;
	QCStringPort *inputAllowedFileTypes;
	QCBooleanPort *inputCanChooseFiles;
	QCBooleanPort *inputCanChooseDirectories;
	QCBooleanPort *inputAllowsMultipleSelection;

	QCBooleanPort *outputOKSignal;
	QCBooleanPort *outputCancelSignal;
	QCStructurePort *outputSelectedURLs;


	bool allowed;
	NSOpenPanel *openPanel;
}

+(BOOL)allowsSubpatchesWithIdentifier:(id)identifier;
-(id)initWithIdentifier:(id)identifier;
-(void)disable:(QCOpenGLContext*)context;
-(BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)arguments;

@end
