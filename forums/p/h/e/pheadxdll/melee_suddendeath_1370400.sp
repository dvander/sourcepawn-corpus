#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <melee>

#define PLUGIN_VERSION "0.1.1"

new Handle:g_hEnabled;
new Handle:g_hClass;
new Handle:g_hChance;

new TFClassType:g_SuddenDeathClass;
static const String:g_strClassName[][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

new bool:g_bSuddenDeath;
new bool:g_bBefore;

public Plugin:myinfo = 
{
	name = "Melee Sudden Death",
	author = "linux_lover",
	description = "Forces melee & classes during sudden death!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("melee_suddendeath_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("melee_suddendeath", "1", "0/1 - Enable melee in sudden death");
	g_hClass = CreateConVar("melee_suddendeath_class", "heavy", "Force a class during sudden death. Leave blank to disable. Acceptable values: scout, soldier, pyro, demo/demoman, heavy, engineer/engy, medic, sniper, spy, random.");
	g_hChance = CreateConVar("melee_suddendeath_chance", "1.0", "Set a chance that melee mode will be enforced during suddendeath.");
	
	HookEvent("teamplay_broadcast_audio", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	g_bSuddenDeath = false;
	g_bBefore = false;
}

public OnConfigsExecuted()
{
	if(GetConVarInt(g_hEnabled))
	{
		new Handle:hCvar = FindConVar("mp_stalemate_enable");
		SetConVarInt(hCvar, 1);
		CloseHandle(hCvar);
	}
}


public Action:Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarFloat(g_hChance) >= GetRandomFloat())
	{
		decl String:strAudio[25];
		GetEventString(event, "sound", strAudio, sizeof(strAudio));
		if(GetEventInt(event, "team") == 2 && strcmp(strAudio, "Game.SuddenDeath") == 0)
		{			
			g_SuddenDeathClass = TFClass_Unknown;
			
			new String:strClass[40];	
			GetConVarString(g_hClass, strClass, sizeof(strClass));
			TrimString(strClass);
			if(strcmp(strClass, "random") == 0)
			{
				g_SuddenDeathClass = TFClassType:GetRandomInt(1, 9);
			}else if(!StrEqual(strClass, ""))
			{
				g_SuddenDeathClass = TF2_GetClass(strClass);
			}

			if(g_SuddenDeathClass != TFClass_Unknown)
			{
				PrintToChatAll("\x04 Melee mode w/ \x01%s\x04 for sudden death!", g_strClassName[_:g_SuddenDeathClass]);
			}else{
				PrintToChatAll("\x04 Melee mode activated for sudden death!");
			}
			
			if(GetMeleeMode())
			{
				g_bBefore = true;
			}else{
				g_bBefore = false;
				SetMeleeMode(true);
			}
			
			g_bSuddenDeath = true;
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bSuddenDeath)
	{		
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(g_SuddenDeathClass != TFClass_Unknown)
			{
				if(TF2_GetPlayerClass(client) != g_SuddenDeathClass)
				{
					TF2_SetPlayerClass(client, g_SuddenDeathClass);
					TF2_RespawnPlayer(client);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bSuddenDeath)
	{
		if(!g_bBefore)
		{
			g_bSuddenDeath = false;
			SetMeleeMode(false);
		}
		
		g_bSuddenDeath = false;
		g_bBefore = false;
	}
	
	return Plugin_Continue;
}