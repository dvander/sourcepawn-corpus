#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "GoD-Tony edit by Mekz"
#define PLUGIN_VERSION "1.3"

#define MAX_EDICTS 2048

EngineVersion g_Game;
float g_fCmdTime[MAXPLAYERS+1];
int g_iSoundEnts[MAX_EDICTS];
int g_iNumSounds;
bool disabled[MAXPLAYERS + 1];
ConVar g_cvAutoStopMusicConnect;
ConVar cPrefix2;
char g_zsTag2[64];

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


public Plugin myinfo = 
{
	name = "[CS:GO / CSS] Stop Music",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	CreateConVar("sm_stopmusic_version", PLUGIN_VERSION, "Stop Map Music");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_togglemusic", Command_ToggleMusic, "Toggles map music");
	RegConsoleCmd("sm_stopmusic", Command_StopMusic, "Toggles map music");
	RegConsoleCmd("sm_music", Command_ToggleMusic, "Toggles map music");
	RegConsoleCmd("sm_playmusic", Command_PlayMusic, "Toggles map music");
	g_cvAutoStopMusicConnect = CreateConVar("stopmusic_autostopmusicconnect", "1", "Enable Auto StopMusic on Connect");
	cPrefix2 = CreateConVar("stopmusic_prefix", "Music", ".");
	
	AutoExecConfig(true, "plugin.stopmusic");
	
	CreateTimer(0.1, Post_Start, _, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	cPrefix2.GetString(g_zsTag2, sizeof(g_zsTag2));
}
public void OnClientDisconnect_Post(int client)
{
	g_fCmdTime[client] = 0.0;
	disabled[client] = true;
}

public void OnClientConnect_Post(int client)
{
	g_fCmdTime[client] = 0.0;
	if (g_cvAutoStopMusicConnect != null)
	{
		disabled[client] = true;
	}
	disabled[client] = false;
}

public Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_iNumSounds = 0;
	
	UpdateSounds();
	CreateTimer(0.1, Post_Start);
}

public void OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "ambient_generic", false))
	{
		return;
	}
	char sSound[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));	
	int len = strlen(sSound);
	if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
	{
		g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
	}
	
	else
	{
		return;
	}
	
	int ent = -1;
	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(!disabled[i] || !IsClientInGame(i)){ continue; }
		for (int u = 0; u <= g_iNumSounds; u++)
		{
			ent = EntRefToEntIndex(g_iSoundEnts[u]);
			if (ent != INVALID_ENT_REFERENCE){
				GetEntPropString(ent, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, ent, SNDCHAN_STATIC, sSound);
			}
		}
	}
}

UpdateSounds()
{
	char sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
		
		int len = strlen(sSound);
		if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
		{
			g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
		}
	}
}

public Action Post_Start(Handle timer)
{
	if(GetClientCount() <= 0)
	{
		return Plugin_Continue;
	}
	
	char sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	for(int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(!disabled[i] || !IsClientInGame(i)){ continue; }
		for (int u = 0; u <= g_iNumSounds; u++)
		{
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE)
			{
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
	return Plugin_Continue;
}

public Action Command_ToggleMusic(int client, int args)
{
	// Prevent this command from being spammed.
	if (!client || g_fCmdTime[client] > GetGameTime())
		return Plugin_Handled;
	
	if(disabled[client])
	{
		PrintToChat(client, "[\x02%s\x01] \x03ToggleMusic\x01: \x04Enabled", g_zsTag2);
		PrintToChat(client, "[\x02%s\x01] You can play/stop music on again command: \x04!togglemusic", g_zsTag2);
		disabled[client] = false;
		return Plugin_Handled;
	}
	
	g_fCmdTime[client] = GetGameTime() + 5.0;
	
	PrintToChat(client, " [\x02%s\x01] \x03ToggleMusic\x01: \x04Disabled", g_zsTag2);
	PrintToChat(client, " [\x02%s\x01] You can play/stop music on again command: \x04!togglemusic", g_zsTag2);
	disabled[client] = true;
	// Run StopSound on all ambient sounds in the map.
	char sSound[PLATFORM_MAX_PATH], entity;
	
	for (int i = 0; i <= g_iNumSounds; i++)
	{
		entity = EntRefToEntIndex(g_iSoundEnts[i]);
		
		if (entity != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
			Client_StopSound(client, entity, SNDCHAN_STATIC, sSound);
		}
	}
	return Plugin_Handled;
}

public Action Command_StopMusic(int client, int args)
{
		disabled[client] = true;
		PrintToChat(client, " [\x02%s\x01] \x03StopMusic\x01: \x04Enabled", g_zsTag2);
		PrintToChat(client, " [\x02%s\x01] You can play music on command: \x04!playmusic", g_zsTag2);
		return Plugin_Handled;
}

public Action Command_PlayMusic(int client, int args)
{
		disabled[client] = false;
		PrintToChat(client, " [\x02%s\x01] \x03PlayMusic\x01: \x04Enabled", g_zsTag2);
		PrintToChat(client, " [\x02%s\x01] You can stop music on command: \x04!stopmusic", g_zsTag2);
		return Plugin_Handled;
}

stock bool Client_StopSound(int client, entity, channel, const char[] name)
{
	EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}