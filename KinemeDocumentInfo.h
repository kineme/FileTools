@interface KinemeDocumentInfo : QCPatch
{
	QCStringPort *outputCurrentDirectory;
	QCStringPort *outputDocumentDisplayName;
	QCStringPort *outputDocumentModificationDate;
	QCStringPort *outputDocumentFileName;
	QCStringPort *outputDocumentFileURL;
	QCBooleanPort *outputDocumentIsEdited;
}
	
+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8;
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8;
- (BOOL)execute:(id)fp8 time:(double)fp12 arguments:(id)fp20;

@end

