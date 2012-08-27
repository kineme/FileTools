/*
 *  RenderImage.m
 *  RenderImage
 *
 *  Created by Christopher Wright on 1/10/09.
 *  Copyright (c) 2009 Kosada Incorporated. All rights reserved.
 *
 */

#import "PDFRendererPatch.h"
//#import "QCImage.h"

@implementation PDFRendererPatch : QCPatch

+ (int)executionModeWithIdentifier:(id)fp8
{
	return 0;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return NO;
}

+ (int)timeModeWithIdentifier:(id)fp8
{
	return 0;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[inputWidth setIndexValue: 800];
		[inputHeight setIndexValue: 600];
		[inputPageNumber setIndexValue: 1];
	}

	return self;
}

- (id)attributes
{
	NSMutableDictionary *at = [[[super attributes] mutableCopy] autorelease];
	[at setObject:@"Kineme PDF Renderer" forKey:@"name"];
	return at;
}

/*- (BOOL)setup:(QCOpenGLContext *)context
{
	return YES;
}
- (void)cleanup:(QCOpenGLContext *)context
{
}

- (void)enable:(QCOpenGLContext *)context
{
}
- (void)disable:(QCOpenGLContext *)context
{
}*/


- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	if([inputPath stringValue] && [inputWidth indexValue] && [inputHeight indexValue])
	{
		CFURLRef url;
		url = CFURLCreateWithFileSystemPath (NULL, (CFStringRef)[inputPath stringValue], kCFURLPOSIXPathStyle, 0);
		
		if(!url)
			return YES;
		
		CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
		
		int count = CGPDFDocumentGetNumberOfPages(document);
		unsigned int width = [inputWidth indexValue];
		unsigned int height = [inputHeight indexValue];

		if(count)
		{
			[outputPageCount setIndexValue: count];
			[inputPageNumber setMaxIndexValue: count];
			// render specified page
			CGPDFPageRef page;
			
			page = CGPDFDocumentGetPage (document, [inputPageNumber indexValue]);
			
			CGRect artbox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
			CGRect rect;
			if([inputPreserveAspect booleanValue])
			{
				double aspect = artbox.size.width/artbox.size.height;
				double outAspect = (double)width/(double)height;
				
				//NSLog(@"pdf size: %fx%f (%f)", artbox.size.width, artbox.size.height, aspect);
				
				if(aspect > outAspect)	// too wide, width gets trimmed
					width = height * aspect;
				else if (aspect < outAspect)	// too tall, height gets trimmed
					height = width / aspect;
				
				//NSLog(@"new size: %fx%f (%f vs. %f)", (double)width, (double)height, (double)width/(double)height, aspect);
				
			}
			rect = CGRectMake(0, 0, width, height);			
			
			// calloc, since we need a clear context (otherwise, small contexts get garbage left in them)
			void *data = calloc(width * height * 4, 1);
			CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

			CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width*4, colorSpace, kCGImageAlphaPremultipliedFirst);
			CGColorSpaceRelease(colorSpace);

			/* cook the transform to fill the context
			   Note:  CGPDFPageGetDrawingTransform does NOT upscale! ("for historical reasons") -- this makes uniform up/down scaling rather
			   aggravating...
			   sample code that shouldn't suck, but does (only down-scales):
			
			   CGAffineTransform m = CGPDFPageGetDrawingTransform (page, kCGPDFMediaBox, rect, 0, [inputPreserveAspect booleanValue]);
			   CGContextConcatCTM(ctx, m);*/			
			
			CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
			CGContextScaleCTM(ctx, rect.size.width / artbox.size.width, rect.size.height / artbox.size.height);
			CGContextTranslateCTM(ctx, -artbox.origin.x, -artbox.origin.y);
			
			CGContextDrawPDFPage(ctx, page);
			
			CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
			
			CGContextRelease(ctx);
			
			QCImage *img = [[QCImage alloc] initWithCGImage: cgImage options: nil];
			[outputImage setImageValue: img];
			[img release];
			
			CGImageRelease(cgImage);
			free(data);
		}
		
		CFRelease(url);
		CGPDFDocumentRelease(document);
	}

	return YES;
}

@end
