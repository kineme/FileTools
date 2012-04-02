#import <QuickLook/QuickLook.h>
#import "KinemeQuickLookPatch.h"


typedef struct
{
	NSString *filename;
	CGSize	size;
	BOOL iconMode;
	BOOL useQL;
	QCImagePort *outputImage;
	QCBooleanPort *outputDone;
} ThreadSettings;

@implementation KinemeQuickLookPatch : QCPatch

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
	if(self=[super initWithIdentifier:fp8])
	{
		[inputWidth setDoubleValue: 128.];
		[inputHeight setDoubleValue: 128.];
		[inputIconMode setBooleanValue: YES];
		[[self userInfo] setObject:@"Kineme QuickLook" forKey:@"name"];
	}
	
	return self;
}

-(void)cleanup:(QCOpenGLContext*)context
{
	[renderThread cancel];
	[renderThread release];
	renderThread = nil;
}

-(void)disable:(QCOpenGLContext*)context
{
	[renderThread cancel];
	[renderThread release];
	renderThread = nil;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	NSString *path = KIExpandPath(self,[inputPath stringValue]);
	[outputDone setBooleanValue: NO];
	if([path length] == 0)
	{
		[outputImage setImageValue: nil];
		return YES;
	}
	
	ThreadSettings *settings = (ThreadSettings*)malloc(sizeof(ThreadSettings));
	settings->filename = [path retain];
	settings->outputImage = [outputImage retain];
	settings->outputDone = [outputDone retain];
	settings->size.width = [inputWidth doubleValue];
	settings->size.height = [inputHeight doubleValue];
	settings->iconMode = [inputIconMode booleanValue];
	settings->useQL = ![inputSkipQuickLook booleanValue];
	
	NSValue *settingsValue = [NSValue valueWithPointer: settings];
	
	// _generateImageFromSettings frees settings (and releases path)
	if([inputAsynchronous booleanValue])
	{
		if([renderThread isExecuting])
		{
			[renderThread cancel];
			[renderThread release];
		}
		renderThread = [[NSThread allocWithZone:NULL] initWithTarget: self selector: @selector(_generateImageFromSettings:) object: settingsValue];
		[renderThread start];
		//[NSThread detachNewThreadSelector: @selector(_generateImageFromSettings:) toTarget: self withObject:settings];
	}
	else
		[self _generateImageFromSettings: settingsValue];
	
	return YES;
}

-(void)_generateImageFromSettings:(NSValue*)settingsValue
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:NULL] init];
	ThreadSettings *settings = [settingsValue pointerValue];
	QCImage *img;
	CGImageRef thumbnail = NULL;
	if(settings->useQL)
	{
		NSMutableDictionary *options = [[NSMutableDictionary allocWithZone:NULL] init];
		if(settings->iconMode)
			[options setObject: (id)kCFBooleanTrue forKey: (NSString*)kQLThumbnailOptionIconModeKey];
		// scale is dumb -- just set the size directly....
		//	[options setObject:[NSNumber numberWithDouble:[inputScale doubleValue]] forKey: (NSString*)kQLThumbnailOptionScaleFactorKey];
		
		thumbnail =	QLThumbnailImageCreate(NULL,
										   (CFURLRef)[NSURL fileURLWithPath: settings->filename], 
										   settings->size,
										   (CFDictionaryRef)options);
		[options release];
	}

	if(thumbnail)
	{
		img = [[QCImage allocWithZone:NULL] initWithCGImage: thumbnail options: nil];
		CGImageRelease(thumbnail);
	}
	else	// QL failed, or user requested a QL bypass (finder-only icons)
	{
		NSImage *icon = [[[NSWorkspace sharedWorkspace] iconForFile: settings->filename] retain];
		/* NSWorkspace gives us an NSImage with lots of reps inside in no particular order.  So we have
		 to iterate over all of them, and select the largest.  With the largest, we then resample it to be the user's
		 desired size.  A bit roundabout, but it works :)
		 */
		/*NSArray *reps = [icon representations];
		float max = -INFINITY;//[[reps objectAtIndex: 0] size].width;
		NSImageRep *biggest = nil;
		for(NSImageRep *rep in reps)
		{
			if(biggest == nil || [rep size].width > max)
			{
				biggest = rep;
				max = [rep size].width;
			}
		}*/

		// QC resizing doesn't work in 64bit mode (for whatever reason), so we resize manually using NSImage.. blah.
		NSImage *tmp = [[NSImage allocWithZone:NULL] initWithSize: NSSizeFromCGSize(settings->size)];
		[tmp lockFocus];
		NSSize iconSize = [icon size];
		NSRect bounds = NSMakeRect(0, 0, iconSize.width, iconSize.height);
		[icon drawInRect:NSMakeRect(0, 0, settings->size.width, settings->size.height) fromRect:bounds   operation: NSCompositeSourceOver fraction: 1.0];
		[tmp unlockFocus];
		img = [[QCImage allocWithZone:NULL] initWithNSImage:tmp options:nil];
		[tmp release];
				
		[icon release];
		
		// This Crashes in 64bit mode (Leopard and Snow Leopard)
		//QCImage *tmp = [[QCImage allocWithZone:NULL] initWithNSBitmapImageRep: biggest options: nil];
		//img = [tmp createScaledImageByX: settings->size.width/[biggest size].width Y: settings->size.height/[biggest size].height];
		//[tmp release];		
	}
	
	if([[NSThread currentThread] isCancelled] == FALSE)
	{
		[settings->outputImage setImageValue: img];
		[settings->outputDone setBooleanValue: YES];
	}
	[img release];
	[settings->filename release];
	[settings->outputImage release];
	[settings->outputDone release];
	free(settings);
	[pool drain];
}

@end
