#pragma semicolon 1
#include <sourcemod>
#include <bzip2>
#include <regex>

#define VERSION 		"0.0.1"

new String:g_sPath[PLATFORM_MAX_PATH] = "maps/";
new Handle:g_hDefaultMapsArray = INVALID_HANDLE;
new g_iCompressionLevel = 9;

public Plugin:myinfo =
{
	name 		= "tAutoMapDecompression",
	author 		= "Thrawn",
	description = "Decompress bz2 compressed maps.",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tautomapdecompression_version", VERSION, "Decompress bz2 compressed maps.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_compressmaps", Command_CompressMaps, ADMFLAG_ROOT);
	RegAdminCmd("sm_decompressmaps", Command_DecompressMaps, ADMFLAG_ROOT);
}

public Action:Command_CompressMaps(client,args) {
	CheckForUncompressedMaps();

	return Plugin_Handled;
}

public Action:Command_DecompressMaps(client,args) {
	CheckForCompressedMaps();

	return Plugin_Handled;
}

public CheckForUncompressedMaps() {
	new Handle:hDir = OpenDirectory(g_sPath);

	if(hDir == INVALID_HANDLE) {
		LogError("Could not open directory %s for reading", g_sPath);
		return;
	}

	new Handle:hRegEx = CompileRegex("(.*)\\.bsp$", PCRE_CASELESS);

	new String:sEntry[PLATFORM_MAX_PATH];
	new FileType:ftEntry;
	while(ReadDirEntry(hDir, sEntry, sizeof(sEntry), ftEntry)) {
		if(ftEntry != FileType_File)continue;

		if(MatchRegex(hRegEx, sEntry) > 0) {
			new String:sMap[PLATFORM_MAX_PATH];
			GetRegexSubString(hRegEx, 1, sMap, sizeof(sMap));
			if(IsDefaultMap(sMap))continue;

			Format(sMap, sizeof(sMap), "%s%s.bsp.bz2", g_sPath, sMap);
			if(!FileExists(sMap)) {
				new String:sIn[PLATFORM_MAX_PATH];
				Format(sIn, sizeof(sIn), "%s%s", g_sPath, sEntry);
				LogMessage("Compressing %s", sIn);
				BZ2_CompressFile(sIn, sMap, g_iCompressionLevel, Compressed_Map);
				break;
			}
		}
	}

	CloseHandle(hRegEx);
	CloseHandle(hDir);
}

public bool:IsDefaultMap(const String:sMap[]) {
	if(g_hDefaultMapsArray == INVALID_HANDLE) {
		g_hDefaultMapsArray = CreateArray(128);

		new String:sDefaultMap[PLATFORM_MAX_PATH];
		new Handle:hMapFile = OpenFile("maplist.txt", "r");
		if(hMapFile == INVALID_HANDLE) {
			LogError("Could not open maplist.txt");
			return true;
		}

		while(ReadFileLine(hMapFile, sDefaultMap, sizeof(sDefaultMap))) {
			TrimString(sDefaultMap);
			PushArrayString(g_hDefaultMapsArray, sDefaultMap);
		}

		CloseHandle(hMapFile);
		LogMessage("Recreated default maps array (size: %i)", GetArraySize(g_hDefaultMapsArray));
	}

	if(FindStringInArray(g_hDefaultMapsArray, sMap) != -1)return true;
	return false;
}


public CheckForCompressedMaps() {
	new Handle:hDir = OpenDirectory(g_sPath);

	if(hDir == INVALID_HANDLE) {
		LogError("Could not open directory %s for reading", g_sPath);
		return;
	}

	new Handle:hRegEx = CompileRegex("(.*)\\.bsp\\.bz2$", PCRE_CASELESS);

	new String:sEntry[PLATFORM_MAX_PATH];
	new FileType:ftEntry;
	while(ReadDirEntry(hDir, sEntry, sizeof(sEntry), ftEntry)) {
		if(ftEntry != FileType_File)continue;

		if(MatchRegex(hRegEx, sEntry) > 0) {
			new String:sMap[PLATFORM_MAX_PATH];
			GetRegexSubString(hRegEx, 1, sMap, sizeof(sMap));
			Format(sMap, sizeof(sMap), "%s%s.bsp", g_sPath, sMap);
			if(!FileExists(sMap)) {
				new String:sIn[PLATFORM_MAX_PATH];
				Format(sIn, sizeof(sIn), "%s%s", g_sPath, sEntry);
				LogMessage("Decompressing %s", sIn);
				BZ2_DecompressFile(sIn, sMap, Decompressed_Map);
				break;
			}
		}
	}

	CloseHandle(hRegEx);
	CloseHandle(hDir);
}

public Decompressed_Map(BZ_Error:iError, String:sIn[], String:sOut[], any:data) {
	if(iError == BZ_OK) {
		LogMessage("%s successfully decompressed", sIn);
		CheckForCompressedMaps();
	} else {
		LogBZ2Error(iError);
	}
}

public Compressed_Map(BZ_Error:iError, String:sIn[], String:sOut[], any:data) {
	if(iError == BZ_OK) {
		LogMessage("%s successfully compressed", sIn);
		CheckForUncompressedMaps();
	} else {
		LogBZ2Error(iError);
	}
}