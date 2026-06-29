#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <autoexecconfig>
#include <sdkhooks>
#include <sdktools>
#include <emitsoundany>

new Handle:g_hKillerSound = INVALID_HANDLE;
new String:g_sKillerSound[PLATFORM_MAX_PATH];
new Handle:g_hVictimSound = INVALID_HANDLE;
new String:g_sVictimSound[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "TOG Custom Death Sounds",
	author = "That One Guy",
	description = "Play custom sounds upon death for both the killer and victim",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togcustomdeathsounds");
	AutoExecConfig_CreateConVar("tcds_version", PLUGIN_VERSION, "TOG Custom Death Sounds: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hKillerSound = AutoExecConfig_CreateConVar("tcds_killersound", "", "File path to sound that the killer will hear. Leave blank for none.", FCVAR_PLUGIN);
	HookConVarChange(g_hKillerSound, OnCVarChange);
	GetConVarString(g_hKillerSound, g_sKillerSound, sizeof(g_sKillerSound));
	
	g_hVictimSound = AutoExecConfig_CreateConVar("tcds_victimsound", "", "File path to sound that the victim will hear. Leave blank for none.", FCVAR_PLUGIN);
	HookConVarChange(g_hVictimSound, OnCVarChange);
	GetConVarString(g_hVictimSound, g_sVictimSound, sizeof(g_sVictimSound));
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hKillerSound)
	{
		GetConVarString(g_hKillerSound, g_sKillerSound, sizeof(g_sKillerSound));
	}
	else if(hCVar == g_hVictimSound)
	{
		GetConVarString(g_hVictimSound, g_sVictimSound, sizeof(g_sVictimSound));
	}
}

public OnMapStart()
{
	decl String:sFullPath[PLATFORM_MAX_PATH], String:sRelPath[PLATFORM_MAX_PATH];
	
	if(!StrEqual(g_sKillerSound, "", false))
	{
		strcopy(sFullPath, sizeof(sFullPath), g_sKillerSound);
		strcopy(sRelPath, sizeof(sRelPath), g_sKillerSound);
		
		if(StrContains(sFullPath, "sound/", false) == 0) //if already full path
		{
			ReplaceString(sRelPath, sizeof(sRelPath), "sound/", "", false);
		}
		else
		{
			Format(sFullPath, sizeof(sFullPath), "sound/%s", sFullPath);
		}

		if (FileExists(sFullPath))
		{
			LogToGame("Precaching sound: %s", sRelPath);
			LogMessage("Precaching sound: %s", sRelPath);
			PrecacheSound(sRelPath, true); //PrecacheSoundAny(sRelPath);
			LogToGame("Adding %s to downloads table", sFullPath);
			LogMessage("Adding %s to downloads table", sFullPath);
			AddFileToDownloadsTable(sFullPath);
		}
		else
		{
			LogError("File does not exist! %s", sFullPath);
		}
	}
	
	if(!StrEqual(g_sVictimSound, "", false))
	{
		strcopy(sFullPath, sizeof(sFullPath), g_sVictimSound);
		strcopy(sRelPath, sizeof(sRelPath), g_sVictimSound);
		
		if(StrContains(sFullPath, "sound/", false) == 0) //if already full path
		{
			ReplaceString(sRelPath, sizeof(sRelPath), "sound/", "", false);
		}
		else
		{
			Format(sFullPath, sizeof(sFullPath), "sound/%s", sFullPath);
		}

		if (FileExists(sFullPath))
		{
			LogToGame("Precaching sound: %s", sRelPath);
			LogMessage("Precaching sound: %s", sRelPath);
			PrecacheSound(sRelPath, true); //PrecacheSoundAny(sRelPath);
			LogToGame("Adding %s to downloads table", sFullPath);
			LogMessage("Adding %s to downloads table", sFullPath);
			AddFileToDownloadsTable(sFullPath);
		}
		else
		{
			LogError("File does not exist! %s", sFullPath);
		}
	}
}

public Event_PlayerDeath(Handle:hEvent,const String:sName[],bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iKiller = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(iVictim == iKiller)
	{
		return;
	}
	
	if(!IsValidClient(iVictim))
	{
		return;
	}
	
	if(!IsValidClient(iKiller))
	{
		return;
	}

	if(!StrEqual(g_sKillerSound, "", false))
	{
		EmitSoundToClientAny(iKiller, g_sKillerSound);
	}
	
	if(!StrEqual(g_sVictimSound, "", false))
	{
		EmitSoundToClientAny(iKiller, g_sVictimSound);
	}
}

bool:IsValidClient(client, bool:bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}