@interface KinemeFileType : QCPatch
{
	QCStringPort *inputFilePath;

	QCStringPort *outputUTI;
}
	
+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8;
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8;
- (BOOL)execute:(id)fp8 time:(double)fp12 arguments:(id)fp20;

@end

