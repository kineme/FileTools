@interface KinemeFileInfo : QCPatch
{
	QCStringPort	*inputPath;
	
	QCBooleanPort	*outputExists;
	QCStringPort	*outputType;
	QCIndexPort		*outputSize;
	QCNumberPort	*outputCreatedTime;
	QCNumberPort	*outputModifiedTime;
	//QCNumberPort	*outputAccessedTime;	// not exported via Cocoa... :(	
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end