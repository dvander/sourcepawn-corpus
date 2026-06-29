/*
* Forced Spawn Be-gone
* 
* Set up:
* =====================================
*  We all know it. Finale on Dead Air is a joke. Survivors camping the fence
*   , smokers spawnining in open view and boomers behind the air plane to
*   be shot 2 seconds later.
*  There is no logical reason (if you ask me) why the infected HAVE to
*   spawn.
*  Hence Forced Spawn Be-gone were born.
*  Enjoy boomer spawns that doesn't include "fuck I spawned in fire" or
*   "wth I spawned miles away".
* 
*  A big thank you and shout out to mi123645 for helping develop and test 
*   this plugin.
* 
* Plugin Description:
* =====================================
*  Disable forced spawn, for the infected, on finals
* 
* Known Problems / Things to Notice:
* =====================================
*  Upon tank spawn, while the director is still assign the tank to a player
*   the plugin will stop ghost players. Will start ghost people once again
*   the tank player have been put in the tank role.
*  Reason for this is because otherwise the director will not select a
*   player to become the tank.
* 
*  Pressing E (use), while in ghost mode, will not bring you to a survivor
*   but rather a place where the director believes you should spawn.
* 
* Changelog:
* =====================================
*  Legend: 
*   + Added 
*   - Removed 
*   ~ Fixed or changed
* 
* Version 0.93
* -----------------
*  + Team versus support added
*  + Added queue timeout to prevent plugin being stuck in a gamemode,
*     l4d_fsb_queuetimeout
*  ~ Fixed CTPR ent finding
*  ~ Fixed gamemode detection
*  ~ Fixed the enable cvar, works now even if you disable/enable the 
*     plugin while in finale
*  ~ Various code changes
* 
* Version 0.92b
* -----------------
*  ~ Fixed return script error upon new map
*  ~ Removed allowbots from IsValidClient
* 
* Version 0.92a
* -----------------
*  ~ Fixed mistype in l4d_fsb_bommer
*  ~ Fixed IsValidClass in RemoveFromQueue
*  ~ Various code changes
* 
* Version 0.92
* -----------------
*  ~ Fixed bots spawning and players not spawning while changing gamemode
*  ~ Fixed compatible issues with L4D Director Enforcer by DDR Khat
*  ~ Fixed compatible issues with Infected Bots by mi123645
*  ~ Fixed finale detection, now using netprops
* 
* Version 0.91
* -----------------
*  + Each zombie class can now be allowed/disallowed from re-ghosting
*  ~ Fixed not resetting probably after finals
* 
* Version 0.90
* -----------------
*  Initial release
* 
* Credits/ Thanks:
* =====================================
*  mi123645
*   For helping out test and develop this plugin
* 
*  AtomicStryker
*   Stole his function of finding "CTerrorPlayerResource"
* 
*  Everyone else on AlliedModders board for reports and finding bugs.
*  
* - Mr. Zero
*/

// ***********************************************************************
// PREPROCESSOR
// ***********************************************************************
#pragma semicolon 1

// ========================================================
// Includes
// ========================================================
#include <sourcemod>

// ***********************************************************************
// CONSTANTS
// ***********************************************************************
#define PLUGIN_VERSION 		"0.93"
#define TEAM_INFECTED		3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_TANK	5

// ========================================================
// Plugin Info
// ========================================================
public Plugin:myinfo = 
{
	name = "Forced Spawn Be-gone",
	author = "mi123645 & Mr. Zero",
	description = "Disable forced spawn, for the infected, on finals",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=106476"
}

// ***********************************************************************
// VARIABLES
// ***********************************************************************
new g_iCTPRentindex;
new bool:g_bIsEnabled;
new bool:g_bIsEnabledCvar = true;
new bool:g_bIsVersus;
new bool:g_bIsTeamVersus;
new bool:g_bInQueue[MAXPLAYERS+1];
new bool:g_bHaveSpawned[MAXPLAYERS+1];
new bool:g_bIsSelectingTank;
new Float:g_fQueueTimeout = 2.5;
new Handle:g_hEnable;
new Handle:g_hBoomerCanGhost;
new Handle:g_hSmokerCanGhost;
new Handle:g_hHunterCanGhost;
new Handle:g_hQueueTimeout;
new Handle:g_hGamemode;
new Handle:g_hSelectionTime;

// Plugin compatible
// Infected bots
new bool:g_bIsIBOnServer;
// L4D Director Enforcer
new Handle:g_hL4DDEEnableCvar;

// ***********************************************************************
// FUNCTIONS
// ***********************************************************************

public OnPluginStart()
{
	g_hEnable 				= CreateConVar("l4d_fsb_enable"				,"1"	,"Sets whether the plugin is active or not",FCVAR_PLUGIN);
	g_hBoomerCanGhost 		= CreateConVar("l4d_fsb_boomer"				,"1"	,"Sets whether boomers are allowed to ghost",FCVAR_PLUGIN);
	g_hSmokerCanGhost 		= CreateConVar("l4d_fsb_smoker"				,"1"	,"Sets whether smokers are allowed to ghost",FCVAR_PLUGIN);
	g_hHunterCanGhost 		= CreateConVar("l4d_fsb_hunter"				,"0"	,"Sets whether hunters are allowed to ghost",FCVAR_PLUGIN);
	g_hQueueTimeout 		= CreateConVar("l4d_fsb_queuetimeout"		,"2.5"	,"If a player is still in queue to respawn as ghost, after this much time, ignore him and reset gamemode",FCVAR_PLUGIN);
	CreateConVar("l4d_fsb_version",PLUGIN_VERSION,"Forced Spawn Be-gone Version",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true,"ForcedSpawnBegone");
	
	HookConVarChange(g_hEnable, CvarChanged_Enable);
	HookConVarChange(g_hQueueTimeout, CvarChanged_QueueTimeout);
	
	g_hGamemode 		= FindConVar("mp_gamemode");
	g_hSelectionTime 	= FindConVar("director_tank_lottery_selection_time");
	
	HookEvent("player_spawn",Event_PlayerSpawned);
	HookEvent("player_death",Event_PlayerDeath);
	HookEvent("tank_spawn",Event_TankSpawn);
	HookEvent("round_start",Event_RoundStart);
}

public OnAllPluginsLoaded()
{
	new Handle:temp = FindConVar("l4d_infectedbots_version");
	if(temp != INVALID_HANDLE){g_bIsIBOnServer = true;}
	
	temp = FindConVar("l4dde_enable");
	if(temp != INVALID_HANDLE){g_hL4DDEEnableCvar = temp;}
}

public CvarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[]){g_bIsEnabledCvar = GetConVarBool(g_hEnable);}
public CvarChanged_QueueTimeout(Handle:convar, const String:oldValue[], const String:newValue[]){g_fQueueTimeout = StringToFloat(newValue);}
public OnMapStart(){RoundReset(true);}
public Event_RoundStart(Handle:event, const String:name[], bool:dB){RoundReset();}
public Event_PlayerSpawned(Handle:event, const String:name[], bool:dB){decl client;client = GetClientOfUserId(GetEventInt(event, "userid"));AddToQueue(client);}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dB){decl client;client = GetClientOfUserId(GetEventInt(event, "userid"));g_bHaveSpawned[client] = false;}
public Event_TankSpawn(Handle:event, const String:name[], bool:dB){g_bIsSelectingTank = true;CreateTimer(GetConVarFloat(g_hSelectionTime),TankSpawnTimer);}
public Action:TankSpawnTimer(Handle:timer){g_bIsSelectingTank = false;}

public bool:OnClientConnect(client, String:rejectmsg[],maxlen)
{
	g_bHaveSpawned[client] = false;
	g_bInQueue[client] = false;
	
	if(!g_bIsEnabled || g_bIsIBOnServer || !IsFinale() || !IsFakeClient(client))
		return true;
	
	decl String:name[10];
	GetClientName(client, name, sizeof(name));
	
	if(StrContains(name, "smoker", false) == -1 && StrContains(name, "boomer", false) == -1 && StrContains(name, "hunter", false) == -1)
		return true;
	
	if(!AnyoneInQueue() || IsClientInKickQueue(client))
		return true;
	
	KickClient(client,"[FSB] Kicking bot...");
	
	return false;
}

RoundReset(bool:NewMap = false)
{
	g_bIsEnabled = false;
	
	if(NewMap)
	{
		g_bIsVersus = false;
		g_bIsTeamVersus = false;
		decl String:GameMode[10];
		GetConVarString(g_hGamemode, GameMode, sizeof(GameMode));
		
		if(StrContains(GameMode, "versus", false) == -1){return;}
		
		g_bIsVersus = true;
		if(StrContains(GameMode, "team", false) != -1){g_bIsTeamVersus = true;}
	}
	
	if(!g_bIsVersus){return;}
	
	g_iCTPRentindex = -1;
	for (new i;i <= GetMaxEntities(); i++)
	{
		if(!IsValidEntity(i)){continue;}
		
		decl String:netclass[64];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		if(!StrEqual(netclass, "CTerrorPlayerResource")){continue;}
		
		g_iCTPRentindex = i;
		break;
	}
	
	if(g_iCTPRentindex == -1){return;}
	
	g_bIsSelectingTank = false;
	for(new i=1;i<MAXPLAYERS+1;i++)
	{
		g_bHaveSpawned[i] = false;
		g_bInQueue[i] = false;
	}
	
	g_bIsEnabled = true;
}

AddToQueue(client)
{
	if(!g_bIsEnabled || !g_bIsEnabledCvar || g_bIsSelectingTank || g_bHaveSpawned[client] || !IsFinale() || !IsValidClient(client) || !IsValidClass(client)){return;}
	
	SetCoop();
	g_bInQueue[client] = true;
	g_bHaveSpawned[client] = true;
	
	CreateTimer(0.1,InQueue,client,TIMER_REPEAT);
	CreateTimer(g_fQueueTimeout,QueueTimeout,client,TIMER_FLAG_NO_MAPCHANGE);
}

public Action:QueueTimeout(Handle:timer, any:client){g_bInQueue[client] = false;}

public Action:InQueue(Handle:timer, any:client)
{
	if(!g_bIsEnabledCvar || g_bIsSelectingTank || !g_bInQueue[client] || !IsValidClient(client) || GetEntProp(client,Prop_Send,"m_isGhost",1) == 1)
	{
		RemoveFromQueue(client);
		return Plugin_Stop;
	}
		
	SetEntProp(client,Prop_Send,"m_isCulling",1,1);
	ClientCommand(client,"+use");
	
	return Plugin_Continue;
}

RemoveFromQueue(client)
{
	g_bInQueue[client] = false;
	SetVersus();
	
	if(!IsValidClient(client)){return;}
	
	SetEntProp(client,Prop_Send,"m_isCulling",0,1);
	ClientCommand(client,"-use");
}

SetCoop()
{
	if(AnyoneInQueue()){return;}
	if(g_hL4DDEEnableCvar != INVALID_HANDLE){SetConVarBool(g_hL4DDEEnableCvar,false);}
	SetConVarString(g_hGamemode,"coop");
}

SetVersus()
{
	if(!g_bIsSelectingTank)
	{
		if(AnyoneInQueue()){return;}
	}
	if(g_bIsTeamVersus)
	{
		SetConVarString(g_hGamemode,"teamversus");
	}
	else
	{
		SetConVarString(g_hGamemode,"versus");
	}
	if(g_hL4DDEEnableCvar != INVALID_HANDLE){SetConVarBool(g_hL4DDEEnableCvar,true);}
}

bool:AnyoneInQueue()
{
	for(new i=1;i<MaxClients+1;i++)
	{
		if(g_bInQueue[i])
		{
			return true;
		}
	}
	return false;
}

bool:IsValidClient(client)
{
	if(client == 0)
		return false;
	
	if(!IsClientInGame(client))
		return false;
	
	if(IsFakeClient(client))
		return false;
	
	if(GetClientTeam(client) != TEAM_INFECTED)
		return false;
	
	return true;
}

bool:IsValidClass(client)
{
	new class = GetEntProp(client,Prop_Send,"m_zombieClass");
	
	if(class == ZOMBIECLASS_TANK)
		return false;
	
	if(class == ZOMBIECLASS_SMOKER && !GetConVarBool(g_hSmokerCanGhost))
		return false;
	
	if(class == ZOMBIECLASS_BOOMER && !GetConVarBool(g_hBoomerCanGhost))
		return false;
	
	if(class == ZOMBIECLASS_HUNTER && !GetConVarBool(g_hHunterCanGhost))
		return false;
	
	return true;
}

bool:IsFinale()
{
	if(GetEntProp(g_iCTPRentindex,Prop_Send,"m_isFinale"))
		return true;
	
	return false;
}