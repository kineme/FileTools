# Kineme FileTools

Kineme FileTools is a Quartz Composer plugin that provides patches for file input and output, as well as structure loading and saving.

   - File Info - Provides information about a file, such as its size, type, and creation date.
   - File Type - Provides the UTI of a specified file.
   - String With File - Reads a file's contents into a String.
   - String With URL - Reads a URL's contents into a String.
   - Structure From File - Reads a QCStructure from a plist file.
   - Structure To File - Saves a structure to a plist.
   - Text File Writer - Saves a string to a file.
   - Open File - Pops up a file/directory "Open" panel.
   - Save File - Pops up a file "Save" panel.

For more Quartz Composer plugins and compositions, plus community forums, go to [kineme.net](http://kineme.net). 

## How to get it

Download or clone it [from GitHub](https://github.com/kineme/FileTools). 

## How to install it

   1. Install the [QCPatch Xcode Template](https://github.com/kineme/QCPatchXcodeTemplate), a.k.a. Quartz Composer unofficial API, a.k.a. SkankySDK. 
   2. Build FileTools.xcodeproj. This will create the file ~/Library/Graphics/Quartz Composer Patches/FileTools.plugin. 
   3. Restart Quartz Composer. The patches will show up under the Kineme FileTools category. 

## How to run the unit tests

   1. Download [GHUnit](http://github.com/gabriel/gh-unit) and place GHUnit.framework in /Library/Frameworks/. 
   2. Set the Active Target to Tests. 
   3. Build and Run. 

## License

Kineme FileTools is released under the MIT License. 
