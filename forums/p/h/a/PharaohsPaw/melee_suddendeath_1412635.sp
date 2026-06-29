#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include "melee.inc"

#define PLUGIN_VERSION "0.1-pp1"

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
	/* making sure mp_stalemate_enable is on is a good idea
	 * *IF* whatever the current map is is one that you WANT
	 * going into stalemate - this may or may not be desirable
	 * to you or work very well on all types of maps - like cp
	 * maps and others with their own round/mini-round timers.
	 * Always forcing mp_stalemate_enable on, if for some reason
	 * there happens to be an mp_timelimit in effect on the map
	 * (perhaps because a default one is set in the global
	 * server.cfg, etc.), can cause a cp or other type map to go
	 * into stalemate when it is completely unexpected (going by the
	 * round/mini-round timer at the top of the screen, not by
	 * mp_timelimit which is otherwise ignored in many non-ctf maps).
	 *
	 * Since we have a plugin "enable" cvar which defines whether this
	 * plugin is even supposed to be active or not, why not use the
	 * value of this cvar to control whether we set mp_stalemate_enable
	 * to 1 or not?  This way we get per-map configurability (via the
	 * map-specific .cfg file) of not only whether we want sudden death
	 * melee behavior on this map, but also whether we want
	 * mp_stalemate_enable enabled AT ALL.  Otherwise mp_stalemate_enable
	 * will *ALWAYS* be set on if this plugin is loaded, even when the
	 * map-specific .cfg file explicitly turns it off!
	 */
	if (GetConVarInt(g_hEnabled) == 1)
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
