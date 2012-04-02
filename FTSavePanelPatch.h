@interface FTSavePanelPatch : QCPatch
{
	QCBooleanPort *inputStartSignal;
	QCStringPort *inputInitialURL;
	QCStringPort *inputInitialFilename;
	QCStringPort *inputTitle;
	QCStringPort *inputMessage;
	QCStringPort *inputPrompt;
	QCStringPort *inputNameFieldLabel;
	QCStringPort *inputAllowedFileTypes;
	QCBooleanPort *inputCanCreateDirectories;

	QCBooleanPort *outputOKSignal;
	QCBooleanPort *outputCancelSignal;
	QCStringPort *outputSelectedURL;


	bool allowed;
	NSSavePanel *savePanel;
}

+(BOOL)allowsSubpatchesWithIdentifier:(id)identifier;
-(id)initWithIdentifier:(id)identifier;
-(void)disable:(QCOpenGLContext*)context;
-(BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)arguments;

@end
