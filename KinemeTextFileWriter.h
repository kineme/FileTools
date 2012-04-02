@interface KinemeTextFileWriter : QCPatch
{	
	QCStringPort	*inputText;
	QCStringPort	*inputFile;
	QCIndexPort		*inputMode;
	QCBooleanPort	*inputSignal;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end