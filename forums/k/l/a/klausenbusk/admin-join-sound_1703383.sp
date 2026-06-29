#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
new Handle:g_hSoundPath;
new Handle:g_hAdminFlag;
new String:SoundPath[PLATFORM_MAX_PATH];
new AdminFlag:FlagID;
new bool:Enabled = false;
new bool:FlagEnabled = false;
new bool:CvarLocked = false;

#define PLUGIN_VERSION "1.5"

public Plugin:myinfo =
{
	name = "Admin Join Sound",
	author = "KK",
	description = "Simple play a sound when a admin join",
	version = PLUGIN_VERSION,
	url = "http://www.attack2.co.cc/"
};



public OnPluginStart()
{
	CreateConVar("sm_adminjs_version", PLUGIN_VERSION, "Admin Join Sound version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT);
	g_hSoundPath = CreateConVar("sm_adminjs_path", "", "What sound to play, without sound/. Can't be changed after it have been set!");
	g_hAdminFlag = CreateConVar("sm_adminjs_flag", "", "What flag a admin need before we should play a song? Blank to play for all admin.");
	HookConVarChange(g_hSoundPath, OnAdminJoinSoundPathChange);
	HookConVarChange(g_hAdminFlag, OnAdminJoinSoundAdminFlagChange);
}

public OnAdminJoinSoundPathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!CvarLocked)
	{	
		PrecacheSound(SoundPath);
		AddFileToDownloadsTable(SoundPath);
		strcopy(SoundPath, PLATFORM_MAX_PATH, newValue);
		CvarLocked = true;
		Enabled = true;
	}
	else if (!StrEqual(newValue, SoundPath))
	{
		SetConVarString(g_hSoundPath, SoundPath);
	}
}

public OnAdminJoinSoundAdminFlagChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (FindFlagByChar(newValue[0], FlagID))
	{
		FlagEnabled = true;
	}
	else
	{
		FlagEnabled = false;
	}
}

public OnClientPostAdminCheck(client)
{
	new AdminId:admin = GetUserAdmin(client);
	if (Enabled && admin != INVALID_ADMIN_ID && !(FlagEnabled && !GetAdminFlag(admin, FlagID)))
	{	
		EmitSoundToAll(SoundPath);
	}
}

