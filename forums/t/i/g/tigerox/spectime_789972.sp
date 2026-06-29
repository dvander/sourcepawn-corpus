#include <sourcemod>

#define PLUGIN_VERSION	"3.2"
#define TEAM_SPEC	1

/*
 * Changelog:
[*]01-01-2012 : Version 3.2
 * Fixed another case where non spectators are kicked.
[*]20-12-2011 : Version 3.1
 * Fixed rare case where non spectators are kicked.
[*]18-12-2011 : Version 3.0
 * Updated admin immunity checking.
 * Recoded spectator detection.
 * Fixed missing url in plugin info.
[*]30-10-2010 : Version 2.5
 * Fixed [SM] Native "GetUserFlagBits" reported: Client 13 is not connected in KickSpec()
[*]24-10-2010 : Version 2.4
 * Recoded. Much more efficient.
 * Fixed a condition where multiple timers could be set on a spectator.
[*]18-08-2009 : Version 2.3
 * Changed kick protect to admin flag 's'.
 * Added min player kick limit. Players will start getting kicked once the minimum is reached.
[*]28-03-2009 : Version 2.0
 * Changed to track spectate time over mapchanges.
 * Added logging of spectate kick.
 * Small bug fixes.
[*]27-03-2009 : Version 1.0
 * Initial Release
 * Compiled for Sourcemod 1.2
**/

//Cvars
new Handle:g_CvarSpecLimit = INVALID_HANDLE;
new Handle:g_CvarPlayers = INVALID_HANDLE;

//Spectator Data
new Handle:g_SpecList[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new bool:g_SpecKickImmunity[MAXPLAYERS +1];

public Plugin:myinfo = 
{
	name = "Spectate Time",
	author = "TigerOx",
	description = "Kicks spectators if they exceed the spectate time.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=88600"
}

public OnPluginStart()
{												
	CreateConVar("sm_spectime", PLUGIN_VERSION, "Spectate Time Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarSpecLimit = CreateConVar("sm_spectimelimit", "180", "Maximum allowed spectating time in seconds.", _, true, 15.0, true, 600.0);
	g_CvarPlayers = CreateConVar("sm_specplayerlimit", "0", "Number of players required to start spectate kick.");
	
	HookEvent("player_team", OnPlayerTeam);
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	new flags = GetUserFlagBits(client);
	
	if(flags & ADMFLAG_ROOT || flags & ADMFLAG_CUSTOM5 || CheckCommandAccess(client, "sm_speckick_immunity", ADMFLAG_CUSTOM5, false))
	{
		g_SpecKickImmunity[client] = true;
		
		if(g_SpecList[client] != INVALID_HANDLE)
		{
			CloseHandle(g_SpecList[client]);
			g_SpecList[client] = INVALID_HANDLE;
		}
	}
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	g_SpecKickImmunity[client] = false;
	
	//Start spectate kick. (OnClientConnected)
	g_SpecList[client] = CreateTimer(GetConVarFloat(g_CvarSpecLimit), SpecKick, client);
}

public Action:OnPlayerTeam(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client || IsFakeClient(client) || g_SpecKickImmunity[client])
	{
		return;
	}
	
	new team = GetEventInt(event,"team");

	if(team == TEAM_SPEC)
	{
		if(g_SpecList[client] == INVALID_HANDLE)
		{
			g_SpecList[client] = CreateTimer(GetConVarFloat(g_CvarSpecLimit), SpecKick, client);
		}
	}
	else if(g_SpecList[client] != INVALID_HANDLE)
	{
		CloseHandle(g_SpecList[client]);
		g_SpecList[client] = INVALID_HANDLE;
	}	
}

public Action:SpecKick(Handle:timer, any:client)
{
	g_SpecList[client] = INVALID_HANDLE;
	
	if(GetClientCount(true) >= GetConVarInt(g_CvarPlayers))
	{
		KickClient(client, "%s", "Spectating too long");
		LogAction(client, -1, "%L was spectating too long, kicked", client);	
	}
	else g_SpecList[client] = CreateTimer(GetConVarFloat(g_CvarSpecLimit), SpecKick, client);

	return Plugin_Stop;
}

public OnClientDisconnect(client)
{
	if (g_SpecList[client] != INVALID_HANDLE)
	{
		CloseHandle(g_SpecList[client]);
		g_SpecList[client] = INVALID_HANDLE;
	}
}
