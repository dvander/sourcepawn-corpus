#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
new Handle:g_hSoundPath;
new Handle:g_hSoundPath2;
new String:SoundPath[PLATFORM_MAX_PATH];
new String:SoundPath2[PLATFORM_MAX_PATH];
new bool:Enabled = false;
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
	g_hSoundPath2 = CreateConVar("sm_adminjs_path", "", "What sound to play, without sound/. Can't be changed after it have been set!");
	HookConVarChange(g_hSoundPath, OnAdminJoinSoundPathChange);
	HookConVarChange(g_hSoundPath2, OnAdminJoinSoundPathChange);
}

public OnAdminJoinSoundPathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!CvarLocked)
	{	
		strcopy((convar == g_hSoundPath? SoundPath : SoundPath2), PLATFORM_MAX_PATH, newValue);
		PrecacheSound((convar == g_hSoundPath? SoundPath : SoundPath2));

		decl String:DownloadPath[PLATFORM_MAX_PATH];
		Format(DownloadPath, PLATFORM_MAX_PATH, "sound/%s", (convar == g_hSoundPath? SoundPath : SoundPath2));
		AddFileToDownloadsTable(DownloadPath);

		CvarLocked = true;
		Enabled = true;
	}
	else if (!StrEqual(newValue, (convar == g_hSoundPath? SoundPath : SoundPath2)))
	{
		SetConVarString(convar, (convar == g_hSoundPath? SoundPath : SoundPath2));
	}
}

public OnClientPostAdminCheck(client)
{
	new AdminId:admin = GetUserAdmin(client);
	if (Enabled && admin != INVALID_ADMIN_ID)
	{	
		EmitSoundToAll(SoundPath);
	}
}

public OnClientDisconnect(client)
{
	new AdminId:admin = GetUserAdmin(client);
	if (Enabled && admin != INVALID_ADMIN_ID)
	{	
		EmitSoundToAll(SoundPath2);
	}
}