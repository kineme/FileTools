#import "DirectoryScannerBlocking.h"

#pragma mark Directory Scanning Junk

NSString *resolveAlias(NSString *path, Boolean *folder);
int inspectAndAddFile(NSString *filePath, NSMutableArray *fullArray, bool includeInvisible, CFStringRef type);

void scanPath(NSString*path, NSMutableArray*fullArray, BOOL follow, int depth, bool includeInvisible, CFStringRef type)
{
	if(depth < 0)
		return;

	NSString *pname;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// force trailing slash
	if([path characterAtIndex:[path length]-1] != '/')
		path = [NSString stringWithFormat:@"%@/",path];

	if(!includeInvisible)
	{
		// if the folder is invisible, don't traverse its contents.

		FSRef fileRef;
		CFDictionaryRef values = NULL;
		CFStringRef attrs[] = { kLSItemIsInvisible };
		CFArrayRef attrNames = CFArrayCreate(NULL, (const void**)attrs, 1, NULL);
		
		if (FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &fileRef, nil) == noErr)
			if( LSCopyItemAttributes(&fileRef, kLSRolesViewer, attrNames, &values) == noErr)
				if(values != NULL)
				{
					if(CFDictionaryGetValue(values, kLSItemIsInvisible) == kCFBooleanTrue)
					{
						CFRelease(values);
						CFRelease(attrNames);
						[pool drain];
						return;
					}
					CFRelease(values);
				}

		CFRelease(attrNames);
	}

	NSFileManager *defaultManager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *direnum = [defaultManager enumeratorAtPath:path];
	
	if(direnum == nil)
	{
		// this happens if the supplied path is an alias...
		//NSLog(@"direnum failed for %@\n",path);
		Boolean folder = FALSE;
		// if file is an alias, resolve it, otherwise inspect it.
		NSString *destination;
		if( (destination = resolveAlias(path, &folder)) != nil )
		{
			//NSLog(@"   * Alias resolved to %@ which %s a folder",destination,folder?"is":"is not");
			if(folder && follow)
				scanPath(destination, fullArray, follow, depth, includeInvisible, type);
			else	// not a folder, inspect file
				inspectAndAddFile(destination, fullArray, includeInvisible, type);
		}
		else
			inspectAndAddFile(path, fullArray, includeInvisible, type);

	}
	
	while(pname = [direnum nextObject])
	{
		//NSLog(@"%@%@",path,pname);
		NSString *dirFileType = [[direnum fileAttributes] fileType];
		if( dirFileType == NSFileTypeDirectory)
		{
			//if(recursive == FALSE)
			// we trap directories here, because we need to limit depth.
			[direnum skipDescendents];
			scanPath([NSString stringWithFormat:@"%@/%@", path, pname], fullArray, follow, depth-1, includeInvisible, type);
			inspectAndAddFile([NSString stringWithFormat:@"%@/%@",path,pname], fullArray, includeInvisible, type);
		}
		else if( dirFileType == NSFileTypeSymbolicLink)
		{
			// if symlink is a file, use it. if it's a directory, follow it if we're in recursive mode
			NSDirectoryEnumerator *symenum = [defaultManager enumeratorAtPath:[NSString stringWithFormat:@"%@%@",path,pname] ];
			NSString *symFileType = [[symenum directoryAttributes] fileType];
			if( symFileType == NSFileTypeDirectory && follow)
			{
				//NSLog(@"   * symlink is a directory... going to walk %@ %@\n",pname, path);
				scanPath([NSString stringWithFormat:@"%@/%@",path,pname], fullArray, follow, depth-1, includeInvisible, type);
			}
			else if( symFileType == NSFileTypeRegular)
			{
				//NSLog(@"   * symlink is a file... going to inspect\n");
				inspectAndAddFile([NSString stringWithFormat:@"%@/%@",path,pname],fullArray, includeInvisible, type);
			}
			
		}
		else if( dirFileType == NSFileTypeRegular)
		{
			Boolean folder = FALSE;
			// if file is an alias, resolve it, otherwise inspect it.
			NSString *destination;
			if( (destination = resolveAlias([NSString stringWithFormat:@"%@/%@",path, pname],&folder)) != nil )
			{
				//NSLog(@"   * Alias resolved to %@ which %s a folder",destination,folder?"is":"is not");
				if(folder && follow)
					scanPath(destination, fullArray, follow, depth-1, includeInvisible, type);
				else	// not a folder, inspect file
					inspectAndAddFile(destination, fullArray, includeInvisible, type);
			}
			else
				inspectAndAddFile([NSString stringWithFormat:@"%@/%@",path, pname], fullArray, includeInvisible, type);
		}
		// other types that we ignore here: Sockets, Char Specials, Block Specials, and Unknowns
	}
	
	[pool drain];
}

int inspectAndAddFile(NSString *filePath, NSMutableArray *fullArray, bool includeInvisible, CFStringRef type)
{
	CFStringRef itemUTI = NULL;
	FSRef fileRef;
	Boolean	isDirectory;
	BOOL metadataMatch = FALSE;	// did metadata match?
	bool visible = YES;
	
	if(filePath == nil)
		return 0;
	//NSLog(@"   * inspectAndAddFile: %@ (%@)\n",filePath,[filePath pathExtension]);
	
	itemUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(CFStringRef)[filePath pathExtension],NULL);
	NSString *lsUTI=nil, *lsType=nil, *lsCreator=nil, *lsKind=nil;
	if (FSPathMakeRef((const UInt8 *)[filePath fileSystemRepresentation], &fileRef, &isDirectory) == noErr)
	{
		CFDictionaryRef values = NULL;
		CFStringRef attrs[] = { kLSItemContentType,kLSItemFileType,kLSItemFileCreator,kLSItemDisplayKind,kLSItemIsInvisible };
		CFArrayRef attrNames = CFArrayCreate(NULL, (const void**)attrs, 5, NULL);
		
		if( LSCopyItemAttributes(&fileRef, kLSRolesViewer, attrNames, &values) == noErr)
		{
			if(values != NULL)
			{
				if(!includeInvisible)
				{
					if(CFDictionaryGetValue(values, kLSItemIsInvisible) == kCFBooleanTrue)
						visible=NO;
				}
				
				CFTypeRef uti = CFDictionaryGetValue(values, kLSItemContentType);
				if(uti != NULL)
				{
					lsUTI = [(NSString *)uti retain];
					if(UTTypeConformsTo(uti, type))
						metadataMatch = TRUE;
				}

				lsType    = [(NSString*)CFDictionaryGetValue(values, kLSItemFileType) retain];
				lsCreator = [(NSString*)CFDictionaryGetValue(values, kLSItemFileCreator) retain];
				lsKind    = [(NSString*)CFDictionaryGetValue(values, kLSItemDisplayKind) retain];

				CFRelease(values);
			}
		}
		
		CFRelease(attrNames);
	}
	
	//NSLog(@"      * Obtained UTI: %@ (meta match: %i)\n",itemUTI,metadataMatch);
	
	int fileAdded=0;
	if(	visible && (
		metadataMatch == TRUE ||
		UTTypeConformsTo(itemUTI, type) == TRUE ||
		// .dv's aren't recognized as movies on Tiger (fixed on Leopard, so this check doesn't hurt)
		(type == kUTTypeMovie && [[filePath pathExtension] caseInsensitiveCompare:@"dv"] == NSOrderedSame ) 
		))
	{
		//NSLog(@"         * Adding item (%@)...\n",filePath);
		NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
		
		[fileDict
			setValue:[NSString stringWithFormat:@"%@",[filePath lastPathComponent]]
			forKey:@"name"];
		[fileDict 
			setValue:[NSString stringWithFormat:@"%@",filePath]
			forKey:@"path"];
		NSURL *fileURL = [NSURL fileURLWithPath:[fileDict objectForKey:@"path"]];
		[fileDict
			setObject:[fileURL absoluteString]
			forKey:@"url"];

		[fileDict setObject:(lsUTI?lsUTI:(NSString*)itemUTI) forKey:@"uti"];
		if(lsType)
			[fileDict setObject:lsType forKey:@"type"];
		if(lsCreator)
			[fileDict setObject:lsCreator forKey:@"creator"];
		if(lsKind)
			[fileDict setObject:lsKind forKey:@"kind"];
			
		NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		[fileDict setObject:[attrs objectForKey:NSFileSize] forKey:@"size"];
		[fileDict setObject:[NSNumber numberWithInteger:[[attrs fileModificationDate] timeIntervalSince1970]] forKey:@"modified"];
		[fileDict setObject:[NSNumber numberWithInteger:[[attrs fileCreationDate] timeIntervalSince1970]] forKey:@"created"];

		[fullArray addObject:fileDict];
		[fileDict release];
		fileAdded=1;
	}
	[lsUTI release];
	[lsType release];
	[lsCreator release];
	[lsKind release];
	CFRelease(itemUTI);
	return fileAdded;
}

NSString *resolveAlias(NSString *filePath, Boolean *folder)
{
	unsigned char	pathBuffer[4096];
	FSRef	fsRef;
	
	if([filePath length] == 0)
		return nil;
		
	//NSLog(@"resolveAlias: %@",filePath);
	
	if( FSPathMakeRef((const UInt8*)[filePath UTF8String], &fsRef,NO) == noErr )
	{
		Boolean isAlias = FALSE;
		if( FSResolveAliasFile(&fsRef, TRUE, folder, &isAlias) == noErr && isAlias)
		{
			FSRefMakePath(&fsRef, pathBuffer, 4096);
			return [NSString stringWithUTF8String:(const char*)pathBuffer];
		}
	}
	else
	{
		//NSLog(@"FSPathMakeRef failed for %@\n",filePath);
		// this fails when mutliple alises are in one path, so we prune and rebuild here
		return [NSString stringWithFormat:@"%@/%@",
				resolveAlias([filePath stringByDeletingLastPathComponent], folder),
				[filePath lastPathComponent]
			];
	}
	return nil;
}



@implementation DirectoryScannerBlocking : QCPatch

#pragma mark QCPatch methods

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
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
	if(self = [super initWithIdentifier:fp8])
	{
		[inputPath setStringValue: @"/Library/Desktop Pictures/"];
		[inputIncludeInvisible setBooleanValue:YES];
		[inputFileTypes setMaxIndexValue: 7];
		[[self userInfo] setObject:@"Kineme Directory Scanner (Blocking)" forKey:@"name"];
	}

	return self;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	NSString *inputPathString = KIExpandPath(self,[inputPath stringValue]);
	// NSLog(@"scanning @ %f", time);
	if([inputPathString length] == 0)
		return YES;
	if([inputPath wasUpdated] || ([inputScanSignal wasUpdated] && [inputScanSignal booleanValue]) || 
	   [inputFileTypes wasUpdated] || [inputFollowLinks wasUpdated] || [inputMaxDepth wasUpdated]
	   || [inputIncludeInvisible wasUpdated]
	   || [inputFileTypeCustom wasUpdated]
	   )
	{
		// scan!
		NSMutableArray *fullArray = [[NSMutableArray alloc] init];

		NSUInteger depth = [inputMaxDepth indexValue];
		bool includeInvisible = [inputIncludeInvisible booleanValue];
		BOOL followLinks = [inputFollowLinks booleanValue];
		
		NSString *type = [inputFileTypeCustom stringValue];
		if([type length])
			scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, (CFStringRef)type);
		else
		switch([inputFileTypes indexValue])
		{
			default:
			case 0:	// images only
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeImage);
				break;
			case 1: // movies only
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeMovie);
				break;
			case 2:	// movies and images
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeImage);
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeMovie);
				break;
			case 3: // Audio
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeAudio);
				break;
			case 4: // Folders
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeDirectory);
				break;
			case 5: // anything
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeData);
				break;
			case 6: // Compositions
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, (CFStringRef)@"com.apple.quartz-composer-composition");				
				break;
			case 7: // compositions, images, and movies
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, (CFStringRef)@"com.apple.quartz-composer-composition");				
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeImage);
				scanPath(inputPathString, fullArray, followLinks, depth, includeInvisible, kUTTypeMovie);
				break;
				
		}
		
		QCStructure *fullStruct = [[QCStructure alloc] initWithArray: fullArray];
		[fullArray release];
		[outputFileList setStructureValue: fullStruct];
		[fullStruct release];
	}
	
	return YES;
}

@end
