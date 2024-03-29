#pragma semicolon 1
#pragma newdecls required
#include <dhooks>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Ain File Download Blocker",
	author = "Russianeer",
	description = "Blocks the server navigation files from being downloaded by the client.",
	version = "1.0",
	url = "http://www.sourcemod.net/",
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("ainfile-blocker");
	if(!hGamedata)
	{
		SetFailState("Could not read ainfile-blocker.txt");
	}

	Handle hDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Ignore);
	if(!hDetour)
	{
		SetFailState("Failed to setup detour handle.");
	}

	if(!DHookSetFromConf(hDetour, hGamedata, SDKConf_Signature, "OnResourcePrecachedFullPath"))
	{
		SetFailState("Failed to find CDownloadListGenerator::OnResourcePrecached(FullPath) signature.");
	}
	delete hGamedata;

	DHookAddParam(hDetour, HookParamType_CharPtr);
	DHookAddParam(hDetour, HookParamType_CharPtr);

	if(!DHookEnableDetour(hDetour, false, Detour_OnResourcePrecachedFullPath))
	{
		SetFailState("Failed to detour CDownloadListGenerator::OnResourcePrecached(FullPath).");
	}
}

public MRESReturn Detour_OnResourcePrecachedFullPath(Handle hParams)
{
	char sFile[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 2, sFile, sizeof(sFile));

	// Don't let clients download .ain files.
	int len = strlen(sFile);
	if(len > 3 && strcmp(sFile[len-4], ".ain", false) == 0)
	{
		//DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}