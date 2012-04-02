#include "stdio.h"

#import "KinemeFileType.h"


@implementation KinemeFileType

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
}
	
+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return FALSE;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[[self userInfo] setObject:@"Kineme File Type" forKey:@"name"];
	}
	return self;
}

- (BOOL)execute:(id)openglcontext time:(double)time arguments:(id)arguments
{
	if( [inputFilePath wasUpdated] )
	{
		NSURL *fileURL;
		if( [[inputFilePath stringValue] compare:@"file://" options:0 range:NSMakeRange(0,7)] == NSOrderedSame )
			fileURL=[NSURL URLWithString: [inputFilePath stringValue]];
		else
		{
			NSString *expandedPath = KIExpandPath(self,[inputFilePath stringValue]);
			if(!expandedPath)
				return YES;
			fileURL=[NSURL fileURLWithPath:expandedPath isDirectory:NO];
		}

		[outputUTI setStringValue:@""];
		
		FSRef ref;
		
		// Declares a Launch Services item information record. You need this data structure later to get extension and type information for a file.
		LSItemInfoRecord outInfo;
		
		CFURLRef cfURLRef = (CFURLRef)fileURL;
		
		// Get the FSRef for the URL
		if (CFURLGetFSRef(cfURLRef, &ref) == TRUE)
		{
			outInfo.extension = NULL;
			
			// Calls the Launch Services function to obtain the extension and type information for the file.
			// The function LSCopyItemInfoForRef fills the outInfo data structure with the requested information.
			if (LSCopyItemInfoForRef(&ref, kLSRequestExtension|kLSRequestTypeCreator, &outInfo) == noErr)
			{
				CFStringRef itemUTI = NULL;
				
				// Checks to see if the file has an extension. 
				// If it does, the code creates a Uniform Type Identifier (UTI) for the extension
				// by calling the function UTTypeCreatePreferredIdentifierForTag.
				// The Uniform Type Identifier is specified as a CFString object. 
				if (outInfo.extension != NULL) 
				{
					itemUTI = UTTypeCreatePreferredIdentifierForTag (kUTTagClassFilenameExtension,outInfo.extension, NULL);
					CFRelease(outInfo.extension);
				}
				else  
				{
					// If the file does not have an extension, the code creates a UTI from the file type.
					// The file type must first be converted to a CFString object by calling the function UTCreateStringForOSType. 
					// Then you can call the function UTTypeCreatePreferredIdentifierForTag to create a UTI.
					CFStringRef typeString = UTCreateStringForOSType(outInfo.filetype);
					itemUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, typeString, NULL);
					CFRelease( typeString );
				}
				
				// Checks to make sure a UTI was created.
				if (itemUTI != NULL) 
				{
					[outputUTI setStringValue:(NSString *)itemUTI];
					// Releases the UTI, which is specified as a CFString object.
					CFRelease (itemUTI); 
				}
			}
		}
	}

	return YES;
}
	
@end
