@interface KinemeStructureFromFile : QCPatch
{
	QCStringPort	*inputFile;
	QCBooleanPort	*inputSignal;
	
	QCStructurePort	*outputStructure;	
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end