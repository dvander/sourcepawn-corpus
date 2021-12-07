#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new Handle:g_hSoundPath;
new String:SoundPath[PLATFORM_MAX_PATH];
new bool:Enabled = false;

#define PLUGIN_VERSION "1.7"

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
	HookConVarChange(g_hSoundPath, OnAdminJoinSoundPathChange);
}

public OnAdminJoinSoundPathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:DownloadPath[PLATFORM_MAX_PATH];
	Format(DownloadPath, PLATFORM_MAX_PATH, "sound/%s", newValue);
	if (FileExists(DownloadPath) || FileExists(DownloadPath, true))
	{
		Enabled = true;
	}
}

public OnConfigsExecuted()
{
	if (Enabled)
	{
		decl String:DownloadPath[PLATFORM_MAX_PATH];
		Format(DownloadPath, PLATFORM_MAX_PATH, "sound/%s", SoundPath);
		AddFileToDownloadsTable(DownloadPath);
		PrecacheSound(SoundPath);
	}
}

public OnClientPostAdminCheck(client)
{
	if (Enabled && CheckCommandAccess(client, "AdminJoinSound", ADMFLAG_GENERIC))
	{
		EmitSoundToAll(SoundPath);
	}
}

