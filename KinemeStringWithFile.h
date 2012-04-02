@interface KinemeStringWithFile : QCPatch
{
	QCStringPort *inputFilePath;
	QCBooleanPort	*inputUpdate;

	QCStringPort *outputFileContent;
}
	
+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8;
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8;
- (BOOL)execute:(id)fp8 time:(double)fp12 arguments:(id)fp20;

@end

