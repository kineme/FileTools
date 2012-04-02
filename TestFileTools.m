#import "SkankySDK/SkankySDK-TestCase.h"

#import "KinemeFileType.h"
#import "ImageDownloaderBlockingPatch.h"
#import "DirectoryScannerBlocking.h"


@interface TestFileTools : SkankySDK_TestCase
{
}
@end


@implementation TestFileTools

-(void)testFileType
{
	KinemeFileType *kft = [[KinemeFileType alloc] initWithIdentifier:nil];
	GHAssertNotNil(kft,@"kft");

	// check nil string input
	KISetPatchInputValue(kft,@"inputFilePath",nil);
	GHAssertTrue([kft execute:context time:0 arguments:nil],@"execute");
	GHAssertEqualObjects(@"",[[kft valueForKey:@"outputUTI"] value],@"UTI");

	// check unix path string input, jpeg output
	[self setInputValue:@"/Library/Desktop Pictures/Classic Aqua Blue.jpg" forPort:@"inputFilePath" onPatch:kft];
	GHAssertTrue([kft execute:context time:0 arguments:nil],@"execute");
	GHAssertEqualObjects(@"public.jpeg",[[kft valueForKey:@"outputUTI"] value],@"UTI");
	
	// check unix path string input (invalid; %20 isn't a valid unix path escape)
	[self setInputValue:@"/Library/Desktop%20Pictures/Classic%20Aqua%20Blue.jpg" forPort:@"inputFilePath" onPatch:kft];
	GHAssertTrue([kft execute:context time:0 arguments:nil],@"execute");
	GHAssertEqualObjects(@"",[[kft valueForKey:@"outputUTI"] value],@"UTI");
	
	// check local URL string input
	[self setInputValue:@"file://localhost/Library/Desktop%20Pictures/Classic%20Aqua%20Blue.jpg" forPort:@"inputFilePath" onPatch:kft];
	GHAssertTrue([kft execute:context time:0 arguments:nil],@"execute");
	GHAssertEqualObjects(@"public.jpeg",[[kft valueForKey:@"outputUTI"] value],@"UTI");
	
	[kft release];
}



// ============================================================================

- (void)testDirectoryScanner
{
	DirectoryScannerBlocking *dsb = [[DirectoryScannerBlocking alloc] initWithIdentifier:nil];
	GHAssertNotNil(dsb,@"dsb");

	// make sure the default port values generate some output
	{
		[self setInputValue:[NSNumber numberWithBool:YES] forPort:@"inputScanSignal" onPatch:dsb];
		[self executePatch:dsb];
		QCStructure *s = [self getOutputForPort:@"outputFileList" onPatch:dsb];
		GHAssertNotNil(s,@"s");
		GHAssertEquals([s count],(NSUInteger)23,@"Default inputPathString (/Library/Desktop Pictures) should have 23 images at depth 0.");
	}

	{
		[self setInputValue:[NSNumber numberWithInteger:1] forPort:@"inputMaxDepth" onPatch:dsb];
		[self executePatch:dsb];
		QCStructure *s = [self getOutputForPort:@"outputFileList" onPatch:dsb];
		GHAssertNotNil(s,@"s");
		GHAssertEquals([s count],(NSUInteger)122,@"Default inputPathString (/Library/Desktop Pictures) should have 122 images at depth 1 (including the \".thumbnails\" folder).");
	}

	{
		[self setInputValue:[NSNumber numberWithBool:NO] forPort:@"inputIncludeInvisible" onPatch:dsb];
		[self executePatch:dsb];
		QCStructure *s = [self getOutputForPort:@"outputFileList" onPatch:dsb];
		GHAssertNotNil(s,@"s");
		GHAssertEquals([s count],(NSUInteger)99,@"Default inputPathString (/Library/Desktop Pictures) should have 99 images at depth 1 (not including the \".thumbnails\" folder).");
	}

	// @@@ test inputFollowLinks
	// @@@ test inputFileTypes
	// @@@ test inputFileTypeCustom
	// @@@ validate structure output

	[self autoTestEachPortForPatch:dsb forSampleSize:10000];

	[dsb release];
}

// ============================================================================

-(void)imageDownloaderBlockingTest:(NSString *)name withPath:(NSString *)path async:(bool)async proxy:(bool)proxy x:(int)x y:(int)y exif:(bool)hasEXIF exifX:(int)exifX exifY:(int)exifY
{
	SLog(@"%@",name);

	ImageDownloaderBlockingPatch *idb = [[ImageDownloaderBlockingPatch alloc] initWithIdentifier:nil];
	GHAssertNotNil(idb,@"idb");

	[self setInputValue:[NSNumber numberWithBool:async] forPort:@"inputAsynchronous"        onPatch:idb];
	[self setInputValue:[NSNumber numberWithBool:proxy] forPort:@"inputUseProxyCache"       onPatch:idb];
	[self setInputValue:[NSNumber numberWithInt:x]      forPort:@"inputProxyThresholdWidth" onPatch:idb];
	

	[self setInputValue:path forPort:@"inputURL" onPatch:idb];
	GHAssertTrue([idb execute:context time:0 arguments:nil],@"execute");
	
	if(async)
		sleep(1);
	
	GHAssertEqualObjects([NSNumber numberWithBool:TRUE],[[idb valueForKey:@"outputFinished"] value],@"Finished");
	QCImage *img = [[idb valueForKey:@"outputImage"] imageValue];
	GHAssertNotNil(img,@"Image");
	NSRect b = [img bounds];
	GHAssertTrue( b.origin.x == 0 && b.origin.y == 0 && b.size.width == x && b.size.height == y, @"Image Dimensions");
	QCStructure *exif = [[idb valueForKey:@"outputEXIFData"] structureValue];
	GHAssertNotNil(exif,@"EXIFData");
	if(hasEXIF)
	{
		GHAssertEqualObjects([NSNumber numberWithInt:exifX],[exif memberForKey:@"PixelWidth"],@"EXIFData PixelWidth");
		GHAssertEqualObjects([NSNumber numberWithInt:exifY],[exif memberForKey:@"PixelHeight"],@"EXIFData PixelHeight");
	}
	else
		GHAssertEquals([exif count],(NSUInteger)0,@"EXIFData count");

	[idb release];
}

-(void)testImageDownloaderBlocking
{
	[self imageDownloaderBlockingTest:@"Async Off, Proxy Off, bad.png" withPath:@"file://localhost/validPathThatDoesNotExist"                            async:NO  proxy:NO  x:32   y:32  exif:NO  exifX:0    exifY:0  ];
	[self imageDownloaderBlockingTest:@"Async Off, Proxy Off"          withPath:@"file://localhost/Library/Desktop%20Pictures/Classic%20Aqua%20Blue.jpg" async:NO  proxy:NO  x:1024 y:768 exif:YES exifX:1024 exifY:768];
	[self imageDownloaderBlockingTest:@"Async Off, Proxy On,  bad.png" withPath:@"file://localhost/validPathThatDoesNotExist"                            async:NO  proxy:YES x:32   y:32  exif:NO  exifX:0    exifY:0  ];
	[self imageDownloaderBlockingTest:@"Async Off, Proxy On"           withPath:@"file://localhost/Library/Desktop%20Pictures/Classic%20Aqua%20Blue.jpg" async:NO  proxy:YES x:256  y:192 exif:YES exifX:1024 exifY:768];
	[self imageDownloaderBlockingTest:@"Async On,  Proxy Off, bad.png" withPath:@"file://localhost/validPathThatDoesNotExist"                            async:YES proxy:NO  x:32   y:32  exif:NO  exifX:0    exifY:0  ];
	[self imageDownloaderBlockingTest:@"Async On,  Proxy Off"          withPath:@"file://localhost/Library/Desktop%20Pictures/Classic%20Aqua%20Blue.jpg" async:YES proxy:NO  x:1024 y:768 exif:YES exifX:1024 exifY:768];
	[self imageDownloaderBlockingTest:@"Async On,  Proxy On,  bad.png" withPath:@"file://localhost/validPathThatDoesNotExist"                            async:YES proxy:YES x:32   y:32  exif:NO  exifX:0    exifY:0  ];
	[self imageDownloaderBlockingTest:@"Async On,  Proxy On"           withPath:@"file://localhost/Library/Desktop%20Pictures/Classic%20Aqua%20Blue.jpg" async:YES proxy:YES x:256  y:192 exif:YES exifX:1024 exifY:768];

	[self imageDownloaderBlockingTest:@"Non-image URL, bad.png"        withPath:@"http://news.bbcimg.co.uk/"                                             async:NO  proxy:NO  x:32   y:32  exif:NO  exifX:0    exifY:0  ];
}

@end
