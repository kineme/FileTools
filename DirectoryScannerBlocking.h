@interface DirectoryScannerBlocking : QCPatch
{
	QCStringPort		*inputPath;
	QCBooleanPort		*inputScanSignal;
	QCBooleanPort		*inputFollowLinks;
	QCBooleanPort		*inputIncludeInvisible;
	QCIndexPort			*inputMaxDepth;
	
	QCIndexPort			*inputFileTypes;
	QCStringPort		*inputFileTypeCustom;
	
	QCStructurePort		*outputFileList;
}

- (id)initWithIdentifier:(id)fp8;

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end