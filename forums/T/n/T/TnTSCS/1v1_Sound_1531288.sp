/* 
* Requested plugin - http://forums.alliedmods.net/showthread.php?t=163581
* Requested by Trident
* 
* 
* CREDITS
* 		*	XARiUS, Otstrel.Ru Team for code sample from knife fight
* 		*	Dr!fter for code sample for sound.txt and precaching
*  */

#include <sourcemod>
#include <sdktools>
#include <smlib/clients>
#include <smlib/teams>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#define MAX_FILE_LEN 256

new Handle:g_CvarSoundName = INVALID_HANDLE;

new String:OneVsOneSound[PLATFORM_MAX_PATH];
new String:soundName[MAX_FILE_LEN];
new bool:HasSound = false;

public Plugin:myinfo = 
{
	name = "1v1_Sound",
	author = "TnTSCS aKa ClarKKent",
	description = "Plays a sound when 1v1 occurs",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=163581"
}

public OnPluginStart()
{
	// Create Plugin ConVars
	CreateConVar("sm_1v1_Sound_version_build",SOURCEMOD_VERSION, "The version of SourceMod that '1v1_Sound' was compiled with.", FCVAR_PLUGIN);
	CreateConVar("sm_1v1_Sound_version", PLUGIN_VERSION, "The version of '1v1_Sound'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	g_CvarSoundName = CreateConVar("sm_1v1_Sound_path", "admin_plugin/actions/rumble.mp3", "Sound to play when 1v1 occurs");
	
	// Execute the config file
	AutoExecConfig(true, "1v1_Sound.plugin");
	
	HookEvent("player_death", OnPlayerDeath);
	
	GetConVarString(g_CvarSoundName, soundName, sizeof(soundName));
	
	
	// All sound stuff credit goes to Dr!fter :)
	decl String:buffer[MAX_FILE_LEN];
	
	if (strcmp(soundName, ""))
	{
		PrecacheSound(soundName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", soundName);
		AddFileToDownloadsTable(buffer);
	}	
	PrecacheSound(soundName, true);
	
	LoadSound();
}

public OnMapStart()
{	
	if(HasSound)
	{
		PrecacheSound(OneVsOneSound, true);
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 1/2 second to check just in case a nade kills the last 2-n players
	CreateTimer(0.5, t_CheckStatus);
	
}

public Action:t_CheckStatus(Handle:timer)
{
	new CtCount = Team_GetClientCount(3, CLIENTFILTER_ALIVE);
	new TCount = Team_GetClientCount(2, CLIENTFILTER_ALIVE);
	
	if(CtCount == 1 && TCount == 1)
	{
		LogMessage("1v1 playing sound");
		PrintToChatAll("1v1 playing sound");
		if (strcmp(soundName, ""))
		{
			// Thanks to code sample from the knifefight plugin by XARiUS, Otstrel.Ru Team
			new players[MaxClients];
			new total = 0;
			for (new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					players[total++] = i;
				}
			}
			
			if(total)
			{
				EmitSound(players, total, soundName, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			}
		}
	}
}

LoadSound() // using the exact same as weapon_restrict.smx by Dr!fter
{
	HasSound = false;
	new Handle:kv = CreateKeyValues("OneVsOneSounds");
	new String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "configs/1v1_sound.txt");
	if(FileExists(file))
	{
		FileToKeyValues(kv, file);
		if(KvJumpToKey(kv, "sounds", false))
		{
			new String:dtfile[PLATFORM_MAX_PATH];
			KvGetString(kv, "OneVsOne", dtfile, sizeof(dtfile), "");
			if(FileExists(dtfile) && strlen(dtfile) > 0)
			{
				AddFileToDownloadsTable(dtfile);
				if(StrContains(dtfile, "sound/", false) == 0)
				{
					ReplaceStringEx(dtfile, sizeof(dtfile), "sound/", "", -1, -1, false);
					strcopy(OneVsOneSound, PLATFORM_MAX_PATH, dtfile);
				}
				PrecacheSound(OneVsOneSound, true);
				if(IsSoundPrecached(OneVsOneSound))
				{
					HasSound = true;
				}
				else
				{
					LogError("Failed to precache restrict sound please make sure path is correct in %s and sound is in the sounds folder", file);
				}
			}
			else
			{
				LogError("Sound %s dosnt exist", dtfile);
			}
		}
		else
		{
			LogError("sounds key missing from %s");
		}
	}
	else
	{
		LogError("File %s dosnt exist", file);
	}
	CloseHandle(kv);
}