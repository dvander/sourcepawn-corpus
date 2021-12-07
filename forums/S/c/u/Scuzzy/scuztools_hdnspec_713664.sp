/*
 * [Hidden:Source] ScuzTools Hidden Color Trail v1.0 
 *
 * Description:
 *  Makes Subject 617 visible to the spectator team as a color trail which also tells them the health of the hidden.  Green=good, yellow/orange=not so good, red=almost dead.
 *
 * Changelog
 *  v1.0.0
 *   Initial release.
 *  v1.0.1
 *   Moved max client call to mapstart.
 *  v1.0.2
 *   Reorganized Clean Client to try and fix trail bug.

 */

#define PLUGIN_VERSION		"1.0.2"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

const TEAM_SPEC = 1;
const TEAM_IRIS = 2;
const TEAM_HIDDEN = 3;

new g_iBeamSprite;
new g_maxplayers=0;
new Handle:g_TaggedTimers[MAXPLAYERS+1];

new hdnColor[4] = {0, 0, 0, 255};


public Plugin:myinfo = 
{
	name = "ScuzTools Hidden Color Trail v1.0",
	author = "[o-t] Scuzzy",
	description = "See the Hidden while in Spec Mode as a health-color coded trail.",
	version = PLUGIN_VERSION,
	url = "http://forums.oldtimersclan.com/"
};

public OnPluginStart()
{

	CreateConVar(
		"scuztools_hdnspec_version",
		PLUGIN_VERSION,
		"H:SM - Hidden Spectator Color Trail",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	HookEvent("game_round_start", Event_Round_Start);
	HookEvent("player_team", PlayerTeam, EventHookMode_Post);

	// Initialize the timers array.
	for (new i=1; i<=g_maxplayers; i++)
	{
		g_TaggedTimers[i]=INVALID_HANDLE;
	}

	hdnColor[3]=255;  
	return true;
}

public OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/crystal_beam1.vmt");

	// Pull the maximum number of clients for this server.
	g_maxplayers = GetMaxClients();


}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast){

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client<1)
	{
		return;
	}

	if (IsClientConnected (client) && IsClientInGame (client) && !IsFakeClient (client))
	{
		new team = GetEventInt(event, "team");

		if (team==TEAM_HIDDEN)
		{
			// In Overrun they may already have a timer.
			if (g_TaggedTimers[client]==INVALID_HANDLE)
			{
				// Player is now a hidden and doesn't have a tag
				HTagClient(client);				
			}
		}
		else
		{
			if (g_TaggedTimers[client]!=INVALID_HANDLE)
			{
				KillTimer(g_TaggedTimers[client]);
				g_TaggedTimers[client]=INVALID_HANDLE;
			}
		}
	}

}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	for (new i=1; i<=g_maxplayers; i++)
	{


		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			//PrintToServer("Event_Round_Start: Found client and is ok: %L", i);

			new team = GetClientTeam(i);
			if ((g_TaggedTimers[i]!=INVALID_HANDLE) && (team!=TEAM_HIDDEN))
			{ 
				// It's a player with a tag, but not a hidden.
				//PrintToServer("Event_Round_Start: Timer Destroyed for Target: %L", i);
				KillTimer(g_TaggedTimers[i]);
				g_TaggedTimers[i]=INVALID_HANDLE;
				// Clean out all possible attachments from the last round.
				TE_CleanClient(i);

			}
			else if ((g_TaggedTimers[i]==INVALID_HANDLE) && (team==TEAM_HIDDEN))
			{ 
				// It's a player without a tag and is a hidden.
				HTagClient(i);
			}
		}
		else
		{
			// Make sure nothing squeeked by, kill it if this person has a timer.
			if (g_TaggedTimers[i]!=INVALID_HANDLE)
			{
				//PrintToServer("Event_Round_Start: Timer Destroyed for Target: %L", i);
				KillTimer(g_TaggedTimers[i]);
				g_TaggedTimers[i]=INVALID_HANDLE;
				// Clean out all possible attachments from the last round.
				TE_CleanClient(i);

			}
		}
	}
}

public OnClientDisconnect(client)
{
	if (client<1)
		return true;

	if (g_TaggedTimers[client] != INVALID_HANDLE)
	{
		//PrintToServer("OnClientDisconnect: Timer Destroyed for Target: %L", client);
		KillTimer(g_TaggedTimers[client]);
		g_TaggedTimers[client]=INVALID_HANDLE;
	}
	
	return true;
}


HTagClient(target)
{
	//PrintToServer("HTagClient: Timer Created for Target: %L", target);
	g_TaggedTimers[target] = CreateTimer(2.0, Timer_HTagged, target, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return;
}

public Action:Timer_HTagged(Handle:timer, any:client)
{

	if (client<1)
	{
		//PrintToServer("Timer_HTagged: Client is less then 1");
		return Plugin_Handled;
	}

	new health=0;
	new value=0;
	new team=0;

	//PrintToServer("Timer_HTagged: Event Fired.  %L", client);

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		// We do not remove the tag because if this is an ovr map we want the
		// trail to remain when they respawn again.  If the game is in elimination
		// mode the timer will be destroyed at the start of the next round.
		//PrintToServer("Timer_HTagged: Client Not In Game or Dead.  %L", client);
		return Plugin_Handled;
	}

	for (new i=1; i<=g_maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			team = GetClientTeam(i);

			if (team==TEAM_SPEC || !IsPlayerAlive(i))
			{
				//PrintToServer("Timer_HTagged: Spec %L, Sending Trail.  %L", i, client);
				
				health=GetClientHealth(client);

				// Set the color based on the palette spectrum for Green->Yellow->Orange->Red;
				if (health > 50)
				{
					value = 255 - ((health - 50) * 5);
					//PrintToServer("Value is in > 50 and is: %d", value);
					hdnColor[0] = value;
					hdnColor[1] = 255;				
					hdnColor[2] = 0;
				}
				else
				{
					value = 255 - (health * 5);
					//PrintToServer("Value is in < 50 and is: %d", value);
					hdnColor[0] = 255;
					hdnColor[1] = 0;	
					hdnColor[2]= value;


				}

				TE_SetupBeamFollow(client,g_iBeamSprite, 0, 2.0, 20.0, 1.0, 0, hdnColor);
				TE_SendToClient(i);
			}
		}
	}

	return Plugin_Handled;
}


public TE_CleanClient(client)
{
    TE_SetupKillPlayerAttachments(client);
    TE_SendToClient(client);
}

stock TE_SetupKillPlayerAttachments(player)
{
    TE_Start("KillPlayerAttachments");
    TE_WriteNum("m_nPlayer",player);
}

