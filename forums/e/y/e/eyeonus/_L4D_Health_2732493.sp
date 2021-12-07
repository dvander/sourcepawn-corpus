#define PLUGIN_VERSION		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D] Health
*	Author	:	JOSHE GATITO SPARTANSKII >>>
*	Descr.	:	HP of survivor to set in the round. 
*	Link	:	https://github.com/JosheGatitoSpartankii09

========================================================================================
	Change Log:
	
1.1 (13-01-2021) - eyeonus
	- Removed L4D1-only restriction
	- Added auto-generation of config file

1.0 (10-05-2019)
	- Initial release
	
========================================================================================
	Description:
	HP of survivor to set in the round. 

	Commands:
	Nothing.

	Settings (ConVars):
	"l4d_health_control" - HP of survivor to set
	
	Credits:
	My Friend Alex Dragokas for code
	
======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <sourcemod>

#define TEAM_SURVIVOR 2
#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_ConVarHP;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D] Health",
	author = "JOSHE GATITO SPARTANSKII, eyeonus",
	description = "HP of survivor to set in the round.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2651124"
}

public void OnPluginStart()
{
	CreateConVar("[L4D] Health", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD); 
	
	g_ConVarHP = CreateConVar("l4d_health_control", "200", "HP of survivor to set", CVAR_FLAGS);
	
	AutoExecConfig(true, "[L4D] Health");
	
	HookEvent("player_spawn", PlayerSpawn);
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{ 
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);
	
	if (client != 0) {
	    if (GetClientTeam(client) == TEAM_SURVIVOR) { 
            CreateTimer(0.1, Timer_HP, UserId, TIMER_FLAG_NO_MAPCHANGE);
		}
	}	
} 

public Action Timer_HP(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client != 0) {
		SetEntProp(client, Prop_Send, "m_iMaxHealth", g_ConVarHP.IntValue);
		SetEntProp(client, Prop_Send, "m_iHealth", g_ConVarHP.IntValue);
	}
}