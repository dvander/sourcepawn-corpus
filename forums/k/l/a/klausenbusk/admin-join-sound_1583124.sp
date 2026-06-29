#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new String:SoundPath[PLATFORM_MAX_PATH];
new bool:Enabled = false;

#define PLUGIN_VERSION "1.7"

public Plugin:myinfo =
{
	name = "Admin Join Sound",
	author = "KK",
	description = "Simple play a sound when a admin join",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=170497"
};


public OnPluginStart()
{
	CreateConVar("sm_adminjs_version", PLUGIN_VERSION, "Admin Join Sound version.", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_CHEAT);
	new Handle:hSoundPath = CreateConVar("sm_adminjs_path", "", "What sound to play, without sound/.");
	HookConVarChange(hSoundPath, OnAdminJoinSoundPathChange);
}

public OnAdminJoinSoundPathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(SoundPath, PLATFORM_MAX_PATH, newValue);

	decl String:DownloadPath[PLATFORM_MAX_PATH];
	Format(DownloadPath, PLATFORM_MAX_PATH, "sound/%s", SoundPath);
	Enabled = FileExists(DownloadPath, true);
	OnMapStart(); // Add to DownloadTable and Precache..
}

public OnMapStart()
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

