@interface KinemeQuickLookPatch : QCPatch
{
	QCStringPort	*inputPath;
	QCNumberPort	*inputWidth;
	QCNumberPort	*inputHeight;
	QCBooleanPort	*inputIconMode;
	QCBooleanPort	*inputSkipQuickLook;
	QCBooleanPort	*inputAsynchronous;

	QCImagePort		*outputImage;
	QCBooleanPort	*outputDone;
	NSThread		*renderThread;
}

- (id)initWithIdentifier:(id)fp8;

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
-(void)_generateImageFromSettings:(NSValue*)settings;
@end
