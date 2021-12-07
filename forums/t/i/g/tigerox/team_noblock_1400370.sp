#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION	"2.0"

#define COLLISION_GROUP_INTERACTIVE_DEBRIS	3	// Collides with everything except other interactive debris or debris
#define COLLISION_GROUP_INTERACTIVE	4			// Collides with everything except interactive debris or debris
#define COLLISION_GROUP_PLAYER	5				// Players!

/* This can be modified to match your particular game */
#define NOBLOCK_RADIUS	6400.0
	

public Plugin:myinfo =
{
	name        = "Team Only Noblock",
	author      = "TigerOx",
	description = "Prevents collisions with teammates.",
	version     = PL_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?p=1400370"
}


new OFFSET_COLLISION_GROUP;

// Player data
new g_ClientList[2][MAXPLAYERS+1];
new g_ClientTeam[MAXPLAYERS+1];
new g_ClientGroup[2][MAXPLAYERS+1];

// Meta data
new g_ClientIndex[MAXPLAYERS+1] = {-1,...};
new g_ClientListTail[2];


public OnPluginStart()
{
	CreateConVar("sm_team_noblock", PL_VERSION, "Team Only Noblock", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	OFFSET_COLLISION_GROUP = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	// Hook player events
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("player_team", EventPlayerTeam, EventHookMode_Post);
}



// Events
public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_ClientIndex[client] < 0 && (g_ClientTeam[client] = GetClientTeam(client)) > 1)
	{
		AddClient(client);
	}
}

public EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client, team;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Check for team change
	if(g_ClientIndex[client] >= 0 && (team = GetEventInt(event, "team")) != g_ClientTeam[client])
	{
		RemoveClient(client);
		
		// Team swap, update client data
		if(team > 1)
		{
			g_ClientTeam[client] = team;
			AddClient(client);
		}
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_ClientIndex[client] >= 0)
	{
		RemoveClient(client);
	}
}

public OnClientDisconnect(client)
{
	if(g_ClientIndex[client] >= 0)
	{
		RemoveClient(client);
	}
}



// Client data functions
AddClient(client)
{
	decl team;
	
	// Align with client data
	team = g_ClientTeam[client] - 2;
	
	// Reset collision group
	g_ClientGroup[team][client] = COLLISION_GROUP_PLAYER;
	
	// Add to client list
	g_ClientIndex[client] = g_ClientListTail[team];
	g_ClientList[team][g_ClientIndex[client]] = client;
	g_ClientListTail[team]++;
}

RemoveClient(client)
{
	decl i, team;
	
	// Align with client data
	team = g_ClientTeam[client] - 2;
	
	g_ClientListTail[team]--;
	
	// Remove from client list
	for(i = g_ClientIndex[client]; i < g_ClientListTail[team]; i++)
	{
		g_ClientList[team][i] = g_ClientList[team][i+1];
		g_ClientIndex[g_ClientList[team][i]] = i;
	}
	
	g_ClientIndex[client] = -1;
}



// OnGameFrame
public OnGameFrame()
{
	static team = 0;
	decl i, j, group;
	decl Float:absOrigin[MAXPLAYERS+1][3];
	
	// Alternate team noblock checks
	team ^= 1;
	
	// Store alive players locations
	for(i = 0; i < g_ClientListTail[team]; i++)
	{
		GetClientAbsOrigin(g_ClientList[team][i], absOrigin[g_ClientList[team][i]]);
	}
		
	// Collision check
	for(i = 0; i < g_ClientListTail[team]; i++)
	{
		// Set default collison group
		group = COLLISION_GROUP_INTERACTIVE;
			
		// Check for imminent collisions with teammates
		for(j = 0; j < i; j++)
		{
			(GetVectorDistance(absOrigin[g_ClientList[team][i]], absOrigin[g_ClientList[team][j]], true) < NOBLOCK_RADIUS) &&
			
			// There is a teammate close by, unblock
			(group = COLLISION_GROUP_INTERACTIVE_DEBRIS) &&
			
			// Break
			(j = g_ClientListTail[team]);
		}
		// Skip checking self
		for(j++; j < g_ClientListTail[team]; j++)
		{
			(GetVectorDistance(absOrigin[g_ClientList[team][i]], absOrigin[g_ClientList[team][j]], true) < NOBLOCK_RADIUS) &&
			(group = COLLISION_GROUP_INTERACTIVE_DEBRIS) &&
			
			// Break
			(j = g_ClientListTail[team]);
		}
		
		// Check for collision group change
		(g_ClientGroup[team][g_ClientList[team][i]] != group) &&
		(g_ClientGroup[team][g_ClientList[team][i]] = group) &&
			
		// Set clients new collision group
		SetEntData(g_ClientList[team][i], OFFSET_COLLISION_GROUP, group, 1, true);
	}
}
