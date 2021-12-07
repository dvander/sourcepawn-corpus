#pragma semicolon 1
#pragma dynamic 32767*30
#include <sourcemod>
//#define DEBUG 1
#include <inflate>

#define PLUGIN_VERSION "1.0"

#define SPFILE_MAGIC 0x53504646

public Plugin:myinfo = 
{
	name = "File Reader",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Reads information out of .smx plugin files",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	RegServerCmd("sm_unloaded_plugins", SrvCmd_UnloadedPlugins, "Lists all plugins in the /plugins folder which are not loaded.");
}

public Action:SrvCmd_UnloadedPlugins(args)
{
	decl String:sBasePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBasePath, sizeof(sBasePath), "plugins/");
	
	ProcessPluginsInFolders(sBasePath);
	
	return Plugin_Handled;
}

stock ProcessPluginsInFolders(String:sPath[])
{
	new Handle:hDir = OpenDirectory(sPath);
	
	new FileType:iFileType, Handle:hPlugin;
	decl String:sBuffer[PLATFORM_MAX_PATH];
	decl String:sName[64], String:sDescription[256], String:sAuthor[64], String:sVersion[64], String:sURL[128];
	while(ReadDirEntry(hDir, sBuffer, sizeof(sBuffer), iFileType))
	{
		if(iFileType == FileType_File)
		{
			hPlugin = FindPluginByFile(sBuffer);
			if(hPlugin == INVALID_HANDLE)
			{
				Format(sBuffer, sizeof(sBuffer), "%s%s", sPath, sBuffer);
				if(GetMyInfoOfPlugin(sBuffer, sName, sizeof(sName), sDescription, sizeof(sDescription), sAuthor, sizeof(sAuthor), sVersion, sizeof(sVersion), sURL, sizeof(sURL)))
				{
					// Adjust the output as you like.
					PrintToServer("name = \"%s\"", sName);
					PrintToServer("description = \"%s\"", sDescription);
					PrintToServer("author = \"%s\"", sAuthor);
					PrintToServer("version = \"%s\"", sVersion);
					PrintToServer("url = \"%s\"", sURL);
				}
			}
		}
		else if(iFileType == FileType_Directory)
		{
			if(sBuffer[0] != '.' && !StrEqual(sBuffer, "disabled"))
			{
				Format(sBuffer, sizeof(sBuffer), "%s%s/", sPath, sBuffer);
				ProcessPluginsInFolders(sBuffer);
			}
		}
	}
	
	CloseHandle(hDir);
}

stock bool:GetMyInfoOfPlugin(String:sPath[], String:sName[], namelength,
							 String:sDescription[], descriptionlength, 
							 String:sAuthor[], authorlength, 
							 String:sVersion[], versionlength, 
							 String:sURL[], urllength)
{
	if(!FileExists(sPath))
		ThrowError("File %s not found.", sPath);
	
	new Handle:hFile = OpenFile(sPath, "rb");
	
	new iHeader[24];
	ReadFile(hFile, iHeader, 24, 1);
	
	new iMagic = ReadArrLE(iHeader, 0, 4);
	
	if(iMagic != SPFILE_MAGIC)
		SetFailState("Invalid file format.");
	
	//new iVersion = ReadArrLE(iHeader, 4, 2);
	new iCompression = ReadArrLE(iHeader, 6, 1);
	new iDiskSize = ReadArrLE(iHeader, 7, 4);
	new iImageSize = ReadArrLE(iHeader, 11, 4);
	new iSections = ReadArrLE(iHeader, 15, 1);
	new iStringTab = ReadArrLE(iHeader, 16, 4);
	new iDataOffs = ReadArrLE(iHeader, 20, 4);
	new iData[iImageSize];
	
	for(new i=0;i<24;i++)
		iData[i] = iHeader[i];
	
	// File is compressed
	if(iCompression == 1)
	{
		//PrintToServer("File is compressed.");
		new b[1];
		for(new i=0;i<(iDataOffs-24);i++)
		{
			ReadFile(hFile, b, 1, 1);
			iData[i+24] = b[0];
		}
		FileSeek(hFile, 2, SEEK_CUR);
		
		new iUncompressedSize = iImageSize-iDataOffs;
		//PrintToServer("Uncompressed size: %d", iUncompressedSize);
		
		new iCompressedSize = iDiskSize-iDataOffs;
		//PrintToServer("Compressed size: %d", iCompressedSize);
		
		new iCompressedData[iCompressedSize];
		ReadFile(hFile, iCompressedData, iCompressedSize, 1);
		
		new iUncompressedData[iUncompressedSize];
		new iLen1 = iCompressedSize, iLen2 = iUncompressedSize;
		new iErr = UncompressBinary(iCompressedData, iLen1, iUncompressedData, iLen2);
		if(iErr)
			ThrowError("Decompression failed.");
		//PrintToServer("succeeded uncompressing %d bytes", iLen2);
		//if(iLen1 < iCompressedSize)
		//	PrintToServer("%d compressed bytes unused", iCompressedSize-iLen1);
		
		for(new i=0;i<iLen2;i++)
		{
			iData[i+iDataOffs] = iUncompressedData[i];
		}
	}
	else
	{
		//PrintToServer("File is NOT compressed.");
		
		new t[1];
		for(new i=0;i<iImageSize;i++)
		{
			t[0] = 0;
			if(ReadFile(hFile, t, 1, 1) == -1)
				ThrowError("Failed to read file.");
			iData[i+24] = t[0];
		}
		
	}
	
	CloseHandle(hFile);
	
	// read section list
	decl String:sSection[64];
	new iNameOffs, iSectionDataOffs, iSectionSize;
	
	new iPubVars[3], iStringBase;
	new iDataSection[3];
	for(new i=0; i<iSections; i++)
	{
		iNameOffs = ReadArrLE(iData, 24+i*12, 4);
		iSectionDataOffs = ReadArrLE(iData, 24+i*12+4, 4);
		iSectionSize = ReadArrLE(iData, 24+i*12+8, 4);
		ReadArrString(iData, iImageSize, (iStringTab+iNameOffs), sSection, sizeof(sSection));
		//PrintToServer("Section %d (%s): nameoffs: %d, dataoffs: %d, size: %d", i, sSection, iNameOffs, iSectionDataOffs, iSectionSize);
		
		if(StrEqual(sSection, ".pubvars"))
		{
			iPubVars[0] = iNameOffs;
			iPubVars[1] = iSectionDataOffs;
			iPubVars[2] = iSectionSize;
		}
		else if(StrEqual(sSection, ".data"))
		{
			iDataSection[0] = iNameOffs;
			iDataSection[1] = iSectionDataOffs;
			iDataSection[2] = iSectionSize;
		}
		else if(StrEqual(sSection, ".names"))
		{
			iStringBase = iSectionDataOffs;
		}
	}
	
	new iPubvarsAddress, iPubvarsNameOffs, String:sPublic[256];
	new iMyInfoAddress = -1;
	//PrintToServer("Num pubvars: %d", iPubVars[2]/8);
	for(new p=0;p<(iPubVars[2]/8);p++)
	{
		iPubvarsAddress = ReadArrLE(iData, iPubVars[1]+p*8, 4);
		iPubvarsNameOffs = ReadArrLE(iData, iPubVars[1]+p*8+4, 4);
		ReadArrString(iData, iImageSize, (iStringBase+iPubvarsNameOffs), sPublic, sizeof(sPublic));
		
		if(StrEqual(sPublic, "myinfo"))
			iMyInfoAddress = iPubvarsAddress;
		//PrintToServer("Pubvar %d: address: %d, nameoffs: %d, name: %s", p, iPubvarsAddress, iPubvarsNameOffs, sPublic);
	}
	
	// This plugin didn't specify a Plugin:myinfo var?
	if(iMyInfoAddress == -1)
		return false;
	
	new iDataDataSize = ReadArrLE(iData, iDataSection[1], 4);
	//new iDataMemSize = ReadArrLE(iData, iDataSection[1]+4, 4);
	new iDataDataOffs = ReadArrLE(iData, iDataSection[1]+8, 4);
	
	//PrintToServer("%d bytes of data in datasection (%d, %d)", iDataDataSize, iDataMemSize, iDataDataOffs);
	
	new iDataBase = iDataSection[1]+iDataDataOffs;
	
	//PrintToServer("Listing Strings:");
	new iDataContent[iDataDataSize];
	
	for(new i=0;i<iDataDataSize;i++)
	{
		iDataContent[i] = iData[iDataBase+i];
		//ReadArrString(iData, iImageSize, iDataBase+s, sString, sizeof(sString));
		//s += strlen(sString);
		//if(sString[0] != '\0')
		//	PrintToServer("%s", sString);
	}
	
	new nameOffset = ReadArrLE(iDataContent, iMyInfoAddress, 4);
	new descriptionOffset = ReadArrLE(iDataContent, iMyInfoAddress+4, 4);
	new authorOffset = ReadArrLE(iDataContent, iMyInfoAddress+8, 4);
	new versionOffset = ReadArrLE(iDataContent, iMyInfoAddress+12, 4);
	new urlOffset = ReadArrLE(iDataContent, iMyInfoAddress+16, 4);
	
	ReadArrString(iDataContent, iDataDataSize, nameOffset, sName, namelength);
	ReadArrString(iDataContent, iDataDataSize, descriptionOffset, sDescription, descriptionlength);
	ReadArrString(iDataContent, iDataDataSize, authorOffset, sAuthor, authorlength);
	ReadArrString(iDataContent, iDataDataSize, versionOffset, sVersion, versionlength);
	ReadArrString(iDataContent, iDataDataSize, urlOffset, sURL, urllength);
	
	return true;
}

stock ReadArrLE(iArr[], offset, length)
{
	new iRet = 0;
	for(new i=length-1;i>=0;i--)
	{
		iRet <<= 8;
		iRet |= iArr[offset+i];
	}
	return iRet;
}

stock ReadArrString(iArr[], maxlen, offset, String:sBuffer[], length)
{
	new bool:bDone = false;
	new i=0;
	while(!bDone)
	{
		if(iArr[offset+i] != '\0')
			sBuffer[i] = iArr[offset+i++];
		else
			bDone = true;
		
		if((offset+i) > maxlen)
			bDone = true;
		
		if(i >= length)
		{
			i--;
			bDone = true;
		}
	}
	sBuffer[i] = '\0';
}