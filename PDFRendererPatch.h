/*
 *  RenderImage.h
 *  RenderImage
 *
 *  Created by Christopher Wright on 1/10/09.
 *  Copyright (c) 2009 Kosada Incorporated. All rights reserved.
 *
 */

@interface PDFRendererPatch : QCPatch
{
	QCStringPort	*inputPath;
	QCIndexPort		*inputWidth;
	QCIndexPort		*inputHeight;
	QCBooleanPort	*inputPreserveAspect;
	QCIndexPort		*inputPageNumber;
	
	QCImagePort		*outputImage;
	QCIndexPort		*outputPageCount;
}

- (id)initWithIdentifier:(id)fp8;

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end