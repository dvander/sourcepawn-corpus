#include <sourcemod>

#define PLUGIN_VERSION	"2.5"
#define TEAM_SPEC	1

/*
 * Changelog:
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

//Globals
new Handle:g_SpecList[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Handle:g_CvarSpecLimit = INVALID_HANDLE;
new Handle:g_CvarPlayers = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "Spectate Time",
	author = "TigerOx",
	description = "Kicks spectators if they exceed the spectate time.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=88600"
};

public OnPluginStart()
{												
	CreateConVar("sm_spectime", PLUGIN_VERSION, "Spectate Time Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarSpecLimit = CreateConVar("sm_spectimelimit", "180", "Maximum allowed spectating time in seconds.", _, true, 15.0, true, 600.0);
	g_CvarPlayers = CreateConVar("sm_specplayerlimit", "10", "Number of players required to start spectate kick.");
	
	HookEvent("player_team", OnPlayerTeam);
}

public OnClientConnected(iClient)
{
	if(IsFakeClient(iClient) || g_SpecList[iClient] != INVALID_HANDLE)
		return;
	
	g_SpecList[iClient] = CreateTimer(GetConVarFloat(g_CvarSpecLimit),KickSpec,iClient);
}
	
public Action:OnPlayerTeam(Handle:event,const String:name[],bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!iClient || IsFakeClient(iClient))
		return;
	
	new iTeam = GetEventInt(event,"team");

	if(iTeam == TEAM_SPEC)
	{
		if(g_SpecList[iClient] == INVALID_HANDLE)
		{
			g_SpecList[iClient] = CreateTimer(GetConVarFloat(g_CvarSpecLimit),KickSpec,iClient);
		}
	}
	else if(g_SpecList[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_SpecList[iClient])
		g_SpecList[iClient] = INVALID_HANDLE;
	}	
}

public Action:KickSpec(Handle:timer, any:iClient)
{
	g_SpecList[iClient] = INVALID_HANDLE;
	
	if(!IsClientConnected(iClient) || (GetUserFlagBits(iClient) & ReadFlagString("s")))
		return;
	
	if(GetClientCount(true) >= GetConVarInt(g_CvarPlayers))
	{
		KickClient(iClient, "%s", "Spectating too long!");
		LogAction(iClient, -1, "%L was spectating too long, kicked!", iClient);	
	}
	else g_SpecList[iClient] = CreateTimer(GetConVarFloat(g_CvarSpecLimit),KickSpec,iClient);
}

public OnClientDisconnect_Post(iClient)
{
	if(g_SpecList[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_SpecList[iClient]);
		g_SpecList[iClient] = INVALID_HANDLE;
	}
}