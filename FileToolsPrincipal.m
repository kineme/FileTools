#import "DirectoryScannerBlocking.h"
#import "FTOpenPanelPatch.h"
#import "FTPathToURLPatch.h"
#import "FTSavePanelPatch.h"
#import "FTURLToPathPatch.h"
#import "FileToolsPrincipal.h"
#import "ImageDownloaderBlockingPatch.h"
#import "KinemeDocumentInfo.h"
#import "KinemeFileInfo.h"
#import "KinemeFileType.h"
#import "KinemeQuickLookPatch.h"
#import "KinemeStringWithFile.h"
#import "KinemeStringWithURL.h"
#import "KinemeStructureFromFile.h"
#import "KinemeStructureToFile.h"
#import "KinemeTextFileWriter.h"
#import "PDFRendererPatch.h"

@implementation FileToolsPlugin
+ (void)registerNodesWithManager:(QCNodeManager*)manager
{
	// new patch class names should begin with "FT"
	KIRegisterPatch(DirectoryScannerBlocking);
	KIRegisterPatch(FTOpenPanelPatch);
	KIRegisterPatch(FTPathToURLPatch);
	KIRegisterPatch(FTSavePanelPatch);
	KIRegisterPatch(FTURLToPathPatch);
	KIRegisterPatch(ImageDownloaderBlockingPatch);
	KIRegisterPatch(KinemeDocumentInfo);
	KIRegisterPatch(KinemeFileInfo);
	KIRegisterPatch(KinemeFileType);
	KIRegisterPatch(KinemeQuickLookPatch);
	KIRegisterPatch(KinemeStringWithFile);
	KIRegisterPatch(KinemeStringWithURL);
	KIRegisterPatch(KinemeStructureFromFile);
	KIRegisterPatch(KinemeStructureToFile);
	KIRegisterPatch(KinemeTextFileWriter);
	KIRegisterPatch(PDFRendererPatch);
}
@end
