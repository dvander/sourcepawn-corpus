#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>

#define CS_TEAM_CT    3  
#define PLUGIN_VERSION "1.0"

new Handle:secondlife_blocktime = INVALID_HANDLE;
new Handle:secondlife_enabled = INVALID_HANDLE;
new Handle:secondlife_respawns = INVALID_HANDLE;

new iTimeUp = 0;
new iRespawnClient[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Second Life",
	author = "tooti",
	description = "You get a Second life when you die",
	version = PLUGIN_VERSION,
	url = "http://fractial-gaming.de"
}

public OnPluginStart()
{
	CreateConVar("sm_secondlife_version", PLUGIN_VERSION, "Secondlife Version, dont touch it :3", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	secondlife_enabled = CreateConVar("sm_secondlife_enabled", "1", "Can this Plugin do his Work?", _,true, 0.0, true , 1.0);
	secondlife_blocktime = CreateConVar("sm_secondlife_blocktime", "10.0", "The time until the Respawn is blocked");
	secondlife_respawns = CreateConVar("sm_secondlife_respawns", "1", "The Magical Number how often Clients can respawn until the time is Up!");
 	HookEvent("player_death", PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public OnClientConnected(client)
{
	if(IsClientConnected(client) && !IsFakeClient(client))
	{
		iRespawnClient[client] = 0;
	}
}
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new IsOn = GetConVarInt(secondlife_enabled);
	new respawns = GetConVarInt(secondlife_respawns);
	
	if((IsOn) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client && IsClientInGame(client) && (GetClientTeam(client) > 0) && GetClientTeam(client)== 3)
		{
			if(iTimeUp != 1 && iRespawnClient[client] != (respawns))
			{
				CreateTimer(0.1, Timer_Respawn, GetClientSerial(client));
				iRespawnClient[client]++;
				PrintToChat(client,"\x03[Second-Life] \x04You've got a Second Life!");
			}
		}
	}	
	return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		iRespawnClient[i] = 0;
	}
	iTimeUp = 0;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:respawntime = GetConVarFloat(secondlife_blocktime);
	CreateTimer(respawntime, TimeUp);
}  

public Action:TimeUp(Handle:timer)
{
	iTimeUp = 1;
	PrintToChatAll("\x03[Second-Life] \x04Respawn-Time is UP!");
}

public Action:Timer_Respawn(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (!client)
	{
		return Plugin_Continue;
	}
	 
	new String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if(StrEqual(GameName, "cstrike"))
	{
		CS_RespawnPlayer(client);
	}
	else if(StrEqual(GameName, "tf"))
	{
		TF2_RespawnPlayer(client);
	}
	return Plugin_Handled;
} 