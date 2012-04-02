@interface ImageDownloaderBlockingPatch : QCPatch
{
    QCStringPort *inputURL;
	
	QCBooleanPort	*inputAsynchronous;
	QCBooleanPort	*inputUseProxyCache;
	QCIndexPort		*inputProxyThresholdWidth;
	QCIndexPort		*inputInterpolation;

	QCImagePort		*outputImage;
	QCBooleanPort	*outputFinished;
	QCStructurePort	*outputEXIFData;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8;
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8;
+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8;

- (id)initWithIdentifier:(id)fp8;

- (BOOL)execute:(id)fp8 time:(double)fp12 arguments:(id)fp20;
- (void)_asyncLoadThread:(NSDictionary*)context;
- (void)saveCIImage:(CIImage*)img toFile:(NSString*)file;

- (QCImage *)requestImage:(NSURL *)url proxyWidth:(int)width interpolation:(int)interpolate properties:(NSMutableDictionary*)properties NS_RETURNS_RETAINED;
@end