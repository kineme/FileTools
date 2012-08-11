#import "ImageDownloaderBlockingPatch.h"
#import <OpenGL/CGLMacro.h>
#import <CommonCrypto/CommonDigest.h>

@implementation ImageDownloaderBlockingPatch : QCPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProcessor;
}
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return NO;
}
+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeNone;
}


- (id)initWithIdentifier:(id)fp8
{
	if( self = [super initWithIdentifier:fp8])
	{
		[inputInterpolation setMaxIndexValue: 1];
	}

	return self;
}

- (BOOL)execute:(id)glContext time:(double)time arguments:(id)arguments
{
	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:[NSURL URLWithString:[inputURL stringValue]], @"URL",
																	glContext, @"context",
																	[NSNumber numberWithInt:[inputProxyThresholdWidth indexValue] * [inputUseProxyCache booleanValue]], @"width",
																	[NSNumber numberWithInt:[inputInterpolation indexValue] * [inputUseProxyCache booleanValue]], @"interpolate", nil];
	[outputFinished setBooleanValue: FALSE];
	if([inputAsynchronous booleanValue])
	{
		[NSThread detachNewThreadSelector:@selector(_asyncLoadThread:) toTarget:self withObject:args];
	}
	else	// synchronous load
		[self _asyncLoadThread:args];

	return YES;
}






- (QCImage *)requestImage:(NSURL *)url proxyWidth:(int)width interpolation:(int)interpolate properties:(NSMutableDictionary*)properties
{
	QCImage *outImage = nil;
	BOOL usingProxy = FALSE;	// we track this for enabling/disabling colorcorrection (cached versions are already corrected, otherwise they aren't)

		NSError *error=nil;
		NSData *data;
		if(width)	// proxy stuff
		{
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Proxy path");
			// look for on-disk proxy
			NSData *urlData = [[url absoluteString] dataUsingEncoding: NSUTF8StringEncoding];
			unsigned char digest[20];	// 160 bits of sha digest
			CC_SHA1([urlData bytes], [urlData length], digest);
			NSString *proxyFile = [NSString stringWithFormat:
				@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x-%i-%i.png",
				//@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x-%i.jpg",
				digest[0],digest[1],digest[2],digest[3],digest[4],
				digest[5],digest[6],digest[7],digest[8],digest[9],
				digest[10],digest[11],digest[12],digest[13],digest[14],
				digest[15],digest[16],digest[17],digest[18],digest[19], width, interpolate];
			NSString *proxyExifFile = [NSString stringWithFormat:@"%@.exif", proxyFile];	// blahblah-width-int.png.exif
			
			NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
		
			cachePath = [cachePath stringByAppendingPathComponent:
					[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
					
			// typically, this only happens once ever -- so we can reliably expect if to fail all of the time.
			//   tell GCC about it for slightly better reordering/hinting
			NSFileManager *defaultManager = [NSFileManager defaultManager];
			if( __builtin_expect([defaultManager fileExistsAtPath: cachePath] == NO, 0) )
			{	// no cache folder, make it
				//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Creating Cache folder [%@]", cachePath);
				[defaultManager createDirectoryAtPath: cachePath attributes:nil];
			}
			NSString *cacheImagePath = [cachePath stringByAppendingPathComponent: proxyFile];
			NSString *cacheExifPath = [cachePath stringByAppendingPathComponent: proxyExifFile];
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Proxy file: %@", cacheImagePath);
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Proxy EXIF file: %@", cacheExifPath);
			if([defaultManager fileExistsAtPath: cacheImagePath] == NO)
			{
				//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  No Proxy file...  inspecting size...");
				data = [NSData dataWithContentsOfURL: url];
				
				// get EXIF info stuff
				{
					if([data length])
					{
						CGImageSourceRef isr = CGImageSourceCreateWithData((CFDataRef)data, nil);
						if(isr)
						{
							//NSLog(@"isr exists!");
							CFDictionaryRef d = CGImageSourceCopyPropertiesAtIndex(isr, 0, nil);
							[properties addEntriesFromDictionary:(NSDictionary *)d];
							CFRelease(d);
							CFRelease(isr);
						}
						else
						{
							//NSLog(@"isr fail!");
						}
					}

					//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  EXIF Properties: %@", properties);
					NSString *error;
					NSData *exifData = [NSPropertyListSerialization 
										dataFromPropertyList: properties
										format: kCFPropertyListBinaryFormat_v1_0
										errorDescription: &error];
					[exifData writeToFile: cacheExifPath atomically: NO];
				}
				
				CIImage *sourceImage = [[CIImage alloc] initWithData: data];
				CIFilter *scale;
				//if([sourceImage size].width > width)	// resize if it's big enough
				if([sourceImage extent].size.width > width)	// resize if it's big enough
				{
					//float aspect = [sourceImage extent].size.width / [sourceImage extent].size.height;
					if(interpolate)	// lanczos scaling -- nice, but slower (also introduces a 1-pixel border sometimes?)
					{
						scale = [CIFilter filterWithName:@"CILanczosScaleTransform"];
						[scale setValue: sourceImage forKey:@"inputImage"];
						[scale setValue: [NSNumber numberWithDouble:width/[sourceImage extent].size.width] forKey:@"inputScale"];
						[scale setValue: [NSNumber numberWithDouble: 1.0] forKey:@"inputAspectRatio"];
						//outImage = [[QCImage alloc] initWithCIImage: [scale valueForKey:@"outputImage"] options:nil];
					}
					else	// affine scaling -- bilinear maybe?
					{
						NSAffineTransform *transform = [NSAffineTransform transform];
						[transform scaleBy: width/[sourceImage extent].size.width ];
						scale = [CIFilter filterWithName:@"CIAffineTransform"];
						[scale setValue: sourceImage forKey:@"inputImage"];
						[scale setValue: transform forKey:@"inputTransform"];
						//outImage = [[QCImage alloc] initWithCIImage:[scale valueForKey:@"outputImage"] options:nil];
					}
					outImage = [[QCImage alloc] initWithCIImage:[scale valueForKey:@"outputImage"] options:nil];
					
					[outImage setMetadata:url forKey:@"dataURL" shouldForward:NO];
					[outImage setMetadata:[NSNumber numberWithUnsignedInt:[data length]] forKey:@"dataSize" shouldForward:NO];
					// Passing the image through CoreImage cooks the colorspace -- go figure.  This makes it match again...
					[outImage setMetadata:[NSNumber numberWithBool: FALSE] forKey:@"disableColorMatching" shouldForward:NO];
					[outImage setMetadata:[NSNumber numberWithInt:0] forKey:@"textureTarget" shouldForward:YES];
					[outImage setMetadata:[NSNumber numberWithInt:0] forKey:@"textureLevels" shouldForward:YES];
					[self saveCIImage: [scale valueForKey:@"outputImage"] toFile: cacheImagePath];
					[sourceImage release];
					return outImage;
				}
				[sourceImage release];
				//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Proxy Handling Completed.");
			}
			else	// proxy file exists, just load that.
			{
				//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Found proxy file.  Using as data source...");
				data = [NSData dataWithContentsOfFile: cacheImagePath];
				// load cached exif info, if any
				NSString *error;
				NSData *exifFileData = [[NSData alloc] initWithContentsOfFile: cacheExifPath];
				[properties addEntriesFromDictionary:
					[NSPropertyListSerialization 
						propertyListFromData: exifFileData
						mutabilityOption: NSPropertyListImmutable
						format: NULL
						errorDescription: &error]];
				[exifFileData release];
				
				usingProxy = TRUE;
			}
		}
		else	// non-proxied version.  use raw url data
		{
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Non-Proxy Path");
			data = [NSData dataWithContentsOfURL: url];

			if([data length])
			{
				// read EXIF info
				CGImageSourceRef isr = CGImageSourceCreateWithData((CFDataRef)data, nil);
				if(isr)
				{
					if(CGImageSourceGetCount(isr)>0)
					{
						//NSLog(@"isr2 exists!");
						CFDictionaryRef d = CGImageSourceCopyPropertiesAtIndex(isr, 0, nil);
						[properties addEntriesFromDictionary: (NSDictionary*)d];
						CFRelease(d);
					}
					CFRelease(isr);
				}
			}
			else
			{
				//NSLog(@"isr2 fail");
			}
		}

		if(![data length])
		{
//			NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  NSData: len %08x",[data length]);
//			NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  NSError: %08x",error);

			NSBundle *thisBundle=[NSBundle bundleForClass:[self class]];
			NSString *path=[thisBundle pathForResource:@"bad" ofType:@"png"];
			if(!path)
			{
				NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  can't find bad.png");
				return NO;
			}
			//NSURL *errorURL=[NSURL fileURLWithPath:path];
			data=[NSData dataWithContentsOfFile: path options:0 error:&error];
		}

		{
			//NSAssert(data,@"ImageDownloaderBlockingCache::requestImageUsingCache()  data == 0");
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  Creating QCImage...");
			outImage=[[QCImage alloc] initWithData:data options:nil];
			if(!outImage)
			{
				NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"bad" ofType:@"png"];
				data=[NSData dataWithContentsOfFile: path options:0 error:&error];
				outImage=[[QCImage alloc] initWithData:data options:nil];
			}
			[outImage setMetadata:url forKey:@"dataURL" shouldForward:NO];
			[outImage setMetadata:[NSNumber numberWithUnsignedInt:[data length]] forKey:@"dataSize" shouldForward:NO];
			if(usingProxy)	// cached versions don't need color matching
				[outImage setMetadata:[NSNumber numberWithBool:TRUE] forKey:@"disableColorMatching" shouldForward:NO];
			[outImage setMetadata:[NSNumber numberWithInt:0] forKey:@"textureTarget" shouldForward:YES];
			[outImage setMetadata:[NSNumber numberWithInt:0] forKey:@"textureLevels" shouldForward:YES];
			//NSAssert(outImage,@"ImageDownloaderBlockingCache::requestImageUsingCache()  outImage == 0");
			
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache()  QCImage Created (0x%08x)",outImage);

			// cast is to silence a gcc warning -- initWithImage conflicts with a CoreImage message
			//NSLog(@"ImageDownloaderBlockingCache::requestImageUsingCache(%@)  estimated size: %lu",url,[c estimatedSize]);

		}

	return outImage;
}


- (void) saveCIImage:(CIImage*)img toFile:(NSString*)file
{
	NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc] 
		//					 initWithCIImage: img];	// leopard-only.  kills rest of this function :)
		initWithBitmapDataPlanes: NULL
		pixelsWide: [img extent].size.width//newSize.width 
		pixelsHigh: [img extent].size.height//newSize.height
		bitsPerSample: 8
		samplesPerPixel: 4
		hasAlpha: YES
		isPlanar: NO
		colorSpaceName: NSDeviceRGBColorSpace
		bytesPerRow: 0
		bitsPerPixel: 0];

	// Create an NSGraphicsContext that draws into the NSBitmapImageRep. (This capability is new in Tiger.)
	NSGraphicsContext *nsContext = [NSGraphicsContext 
		graphicsContextWithBitmapImageRep: bmp];

	// Save the previous graphics context and state, and make our bitmap context current.
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: nsContext];

	// Get a CIContext from the NSGraphicsContext, and use it to draw the CIImage into the NSBitmapImageRep.
	CGPoint point;
	point.x = 0;
	point.y = 0;
	[[nsContext CIContext] drawImage: img atPoint: point fromRect: [img extent]];

	// Restore the previous graphics context and state.
	[NSGraphicsContext restoreGraphicsState];
	
	 [[bmp representationUsingType: NSPNGFileType properties: nil] 
		writeToFile: file atomically:NO];
	[bmp release];
}



-(void)_asyncLoadThread:(NSDictionary*)context
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSURL *url = [context objectForKey:@"URL"];
	
	NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
	QCImage *image;
	
	image = [self requestImage: url 
			        proxyWidth: [[context objectForKey:@"width"] intValue]
			     interpolation: [[context objectForKey:@"interpolate"] intValue]
				    properties: properties];
	
	QCStructure *exif = [[QCStructure alloc] initWithDictionary: properties];
	[outputEXIFData setStructureValue: exif];
	[exif release];
	[properties release];
	
	[outputImage setImageValue:image];
	[image release];
	[outputFinished setBooleanValue: TRUE];
	
	[pool drain];
}

@end
