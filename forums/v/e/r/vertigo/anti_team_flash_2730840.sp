#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2.4"

Handle g_hEnabled = INVALID_HANDLE;
Handle g_hTeam = INVALID_HANDLE;
Handle g_hDeceased = INVALID_HANDLE;
Handle g_hSpectator = INVALID_HANDLE;
Handle g_hOwner = INVALID_HANDLE;
Handle g_hDisable = INVALID_HANDLE;
Handle g_hOverride = INVALID_HANDLE;
Handle g_hLife = INVALID_HANDLE;
Handle g_hEntities = INVALID_HANDLE;
Handle g_hTimerDisable = INVALID_HANDLE;

bool g_bEnabled, g_bTeam, g_bDead, g_bSpec, g_bOwner, g_bDisable, g_bOverride, g_bLateLoad, g_bAlive[MAXPLAYERS + 1];
float g_fDisable, g_fLife;
int g_iTeam[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Anti Team Flash",
	author = "Twisted|Panda (Orig: SAMURAI16/Kigen), Vertigo", //New syntax + optimized code
	description = "Provides a variety of options for preventing the flash on a flashbang.",
	version = PLUGIN_VERSION,
	url = "vertigocss@gmail.com"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_anti_team_flash_version", PLUGIN_VERSION, "CSS Anti Team Flash: Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_anti_team_flash", "1", "Enables/disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hTeam = CreateConVar("css_anti_team_flash_team", "1", "If enabled, players will be unable to team flash their teammates.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDeceased = CreateConVar("css_anti_team_flash_dead", "1", "If disabled, flashbangs will flash dead players.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpectator = CreateConVar("css_anti_team_flash_spec", "1", "If disabled, flashbangs will flash spectators.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hOwner = CreateConVar("css_anti_team_flash_owner", "0", "If disabled, flashbangs will flash their owners.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDisable = CreateConVar("css_anti_team_flash_time", "0.0", "The number of seconds from round_freeze_end for plugin functionality to end. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hOverride = CreateConVar("css_anti_team_flash_none", "0", "If enabled, normal functionality of the plugin stops. Flashbangs will not explode, and will be deleted after css_anti_team_flash_life seconds.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hLife = CreateConVar("css_anti_team_flash_life", "2.0", "If enabled and css_anti_team_flash_none is enabled, this is the lifetime of the flashbang before it is deleted.", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "anti_team_flash");

	HookEvent("flashbang_detonate", Event_OnFlashExplode, EventHookMode_Post);
	HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_freeze_end", Event_OnFreezeEnd);
	HookEvent("round_end", Event_OnRoundEnd);

	HookConVarChange(g_hEnabled, OnSettingsChange);
	HookConVarChange(g_hTeam, OnSettingsChange);
	HookConVarChange(g_hDeceased, OnSettingsChange);
	HookConVarChange(g_hSpectator, OnSettingsChange);
	HookConVarChange(g_hOwner, OnSettingsChange);
	HookConVarChange(g_hDisable, OnSettingsChange);
	HookConVarChange(g_hOverride, OnSettingsChange);
	HookConVarChange(g_hLife, OnSettingsChange);

	g_hEntities = CreateArray(2);
}

public void OnPluginEnd()
{
	ClearArray(g_hEntities);
}

public void OnConfigsExecuted()
{
	if(g_bEnabled && g_bLateLoad)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
		
		g_bLateLoad = false;
	}
}

public void OnMapEnd()
{
	if(g_bEnabled)
	{
		if(g_hTimerDisable != INVALID_HANDLE && CloseHandle(g_hTimerDisable)) g_hTimerDisable = INVALID_HANDLE;
		ClearArray(g_hEntities);
	}
}

public void OnMapStart()
{
	Void_SetDefaults();
}

public void OnClientDisconnect(int client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(g_bEnabled)
	{
		if(StrEqual(classname, "flashbang_projectile")) CreateTimer(0.1, Timer_Create, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_OnFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bDisable = false;
		ClearArray(g_hEntities);
		if(g_fDisable) g_hTimerDisable = CreateTimer(g_fDisable, Timer_Flash, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		if(g_fDisable && g_hTimerDisable != INVALID_HANDLE && CloseHandle(g_hTimerDisable)) g_hTimerDisable = INVALID_HANDLE;
	}
}

public Action Event_OnFlashExplode(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		if(GetArraySize(g_hEntities)) RemoveFromArray(g_hEntities, 0);
	}

	return Plugin_Continue;
}

public Action Event_OnFlashPlayer(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_bDisable) return Plugin_Continue;
		if(!g_bAlive[client])
		{
			if(g_bSpec && g_iTeam[client] <= CS_TEAM_SPECTATOR || g_bDead && g_iTeam[client] >= CS_TEAM_T) SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
		}
		else
		{
			int _iData[2];
			if(GetArraySize(g_hEntities) == 0) return Plugin_Continue;
			GetArrayArray(g_hEntities, 0, _iData);
			if(g_iTeam[client] == _iData[1])
			{
				if(!g_bOwner && _iData[0] == client) return Plugin_Continue;
				if(g_bTeam) SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
			}
		}
	}

	return Plugin_Continue;
}

public Action Event_OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client)) return Plugin_Continue;			
		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] == CS_TEAM_SPECTATOR) g_bAlive[client] = false;
	}
	
	return Plugin_Continue;
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR) return Plugin_Continue;			
		g_bAlive[client] = true;
	}
	
	return Plugin_Continue;
}

public Action Event_OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client)) return Plugin_Continue;			
		g_bAlive[client] = false;
	}
	
	return Plugin_Continue;
}

public Action Timer_Flash(Handle timer)
{
	g_bDisable = true;
	g_hTimerDisable = INVALID_HANDLE;
}

public Action Timer_Destroy(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
}

public Action Timer_Create(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		if(g_bOverride)
		{
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);  
			CreateTimer((g_fLife - 0.1), Timer_Destroy, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			int _iData[2];
			_iData[0] = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
			_iData[1] = (_iData[0] > 0) ? g_iTeam[_iData[0]] : 0;
			PushArrayArray(g_hEntities, _iData);
		}
	}
}

void Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bTeam = GetConVarInt(g_hTeam) ? true : false;
	g_bDead = GetConVarInt(g_hDeceased) ? true : false;
	g_bSpec = GetConVarInt(g_hSpectator) ? true : false;
	g_bOwner = GetConVarInt(g_hOwner) ? true : false;
	g_fDisable = GetConVarFloat(g_hDisable);
	g_bOverride = GetConVarInt(g_hOverride) ? true : false;
	g_fLife = GetConVarFloat(g_hLife);
	g_bDisable = false;
}

public void OnSettingsChange(Handle cvar, const char[] oldvalue, const char[] newvalue)
{
	if(cvar == g_hEnabled) g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hTeam) g_bTeam = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDeceased) 	g_bDead = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSpectator) g_bSpec = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hOwner) g_bOwner = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDisable)
	{
		g_fDisable = StringToFloat(newvalue);
		g_bDisable = false;
		if(g_fDisable) g_hTimerDisable = CreateTimer(g_fDisable, Timer_Flash, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(cvar == g_hOverride) g_bOverride = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hLife) g_fLife = StringToFloat(newvalue);
}