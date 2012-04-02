@interface KinemeStructureToFile : QCPatch
{
    QCStructurePort	*inputStructure;
	QCStringPort	*inputFile;
	QCBooleanPort	*inputWriteSignal;
}

- (id)initWithIdentifier:(id)fp8;

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end