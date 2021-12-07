#pragma semicolon 1
#pragma newdecls required
#include <dhooks>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Nav File Download Blocker",
	author = "Russianeer",
	description = "Blocks the server navigation files from being downloaded by the client.",
	version = "1.0",
	url = "http://www.sourcemod.net/",
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("navfile-blocker");
	if (!hGamedata)
		SetFailState("Could not read navfile-blocker.txt");

	Handle hDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_Ignore);
	if (!hDetour)
		SetFailState("Failed to setup detour handle.");

	if (!DHookSetFromConf(hDetour, hGamedata, SDKConf_Signature, "OnResourcePrecachedFullPath"))
		SetFailState("Failed to find CDownloadListGenerator::OnResourcePrecached(FullPath) signature.");
	delete hGamedata;

	DHookAddParam(hDetour, HookParamType_CharPtr);

	if (!DHookEnableDetour(hDetour, false, Detour_OnResourcePrecachedFullPath))
		SetFailState("Failed to detour CDownloadListGenerator::OnResourcePrecached(FullPath).");
}

MRESReturn Detour_OnResourcePrecachedFullPath(Handle hReturn, Handle hParams)
{
	char sFile[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, sFile, sizeof(sFile));

	// Don't let clients download .nav files.
	int len = strlen(sFile);
	if (len > 3 && strcmp(sFile[len-4], ".nav", false) == 0)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}
