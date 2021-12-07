#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Team = INVALID_HANDLE;
new Handle:gH_RTeam = INVALID_HANDLE;
new Handle:gH_Class = INVALID_HANDLE;

new bool:gB_Enabled;
new gI_Team;
new bool:gB_RTeam;
new gI_Class;

public Plugin:myinfo = 
{
	name = "Autojoin",
	author = "xNos",
	description = "Force the players to join team after connect",
	version = PLUGIN_VERSION,
	url = "not gamex"
}

public OnPluginStart()
{
	gH_Enabled = CreateConVar("sm_autojoin_enable", "1", "Enable/Disable forcing", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Team = CreateConVar("sm_autojoin_team", "2", "Teams joinning the players 1/2/3", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	gH_RTeam = CreateConVar("sm_autojoin_random", "0", "Random teams joining the players 0/1", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Class = CreateConVar("sm_autojoin_class", "6", "Class joinning the players 1/2/3/4/6", FCVAR_PLUGIN, true, 0.0, true, 6.0);
	
	gB_Enabled = GetConVarBool(gH_Enabled);
	gI_Team = GetConVarInt(gH_Team);
	gB_RTeam = GetConVarBool(gH_RTeam);
	gI_Class = GetConVarInt(gH_Class);
	
	HookConVarChange(gH_Enabled, OnConVarChanged);
	HookConVarChange(gH_Team, OnConVarChanged);
	HookConVarChange(gH_RTeam, OnConVarChanged);
	HookConVarChange(gH_Team, OnConVarChanged);
	
	AutoExecConfig();
	
	CreateConVar("sm_autojoin_version", PLUGIN_VERSION, "Autojoin version.", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = bool:StringToInt(newVal);
	}
	
	else if(cvar == gH_Team)
	{
		gI_Team = StringToInt(newVal);
	}
	
	else if(cvar == gH_RTeam)
	{
		gB_RTeam = bool:StringToInt(newVal);
	}
	
	else if(cvar == gH_Class)
	{
		gI_Class = StringToInt(newVal);
	}
}

public OnClientPutInServer(client)
{
	if(gB_Enabled)
	{
		CreateTimer(0.1, Autojoin, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Autojoin(Handle:timer, any:serial)
{
	if(gB_Enabled)
	{
		new client = GetClientFromSerial(serial);
		
		if(IsValidClient(client))
		{
			FakeClientCommand(client, "joingame");
			
			CreateTimer(0.1, AutoJoin1, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Handled;
}

public Action:AutoJoin1(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	
	if(!gB_RTeam)
	{
		FakeClientCommand(client,"jointeam %d", gI_Team);
	}
	
	else
	{
		FakeClientCommand(client,"jointeam %d", GetRandomInt(2,3));
	}
	
	FakeClientCommand(client,"joinclass %s", gI_Class);
	
	return Plugin_Stop;
}

/**
* Checks if client is valid, ingame and safe to use.
*
* @param client			Client index.
* @param alive			Check if the client is alive.
* @return				True if the user is valid.
*/
stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}
