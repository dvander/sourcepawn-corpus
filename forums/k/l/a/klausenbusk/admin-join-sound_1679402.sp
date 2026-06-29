#include <sourcemod>
#include <sdktools>
new Handle:g_hSoundPath;
new String:SoundPath[PLATFORM_MAX_PATH];
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
	g_hSoundPath = CreateConVar("sm_adminjs_path", "", "What sound to play, without sound/. Locked after first chang, to prevent people to download multi sound.");
	HookConVarChange(g_hSoundPath, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (FileExists(newValue, false) || FileExists(newValue, true))
	{
		if(!CvarLocked)
		{
			strcopy(SoundPath, PLATFORM_MAX_PATH, newValue);
			PrecacheSound(SoundPath);
			decl String:DownloadPath[PLATFORM_MAX_PATH];
			Format(DownloadPath, sizeof(DownloadPath), "sound/%s", SoundPath);
			AddFileToDownloadsTable(DownloadPath);
			CvarLocked = true;
			Enabled = true;
		}
	}
	else
	{
		Enabled = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if (Enabled && GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		// plugin enabled and client is admin :)
		EmitSoundToAll(SoundPath);
	}
}

