//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// Swaps Allies and Axis Teams at Round End
// Additional round code added by Psychocoder
// Fix for failures when plugin is enabled for some maps and not others. by Regor Tejmar
//
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.400"

new Handle:g_Cvar_BonusRound = INVALID_HANDLE;
new Handle:g_Cvar_Swapteams = INVALID_HANDLE;

new g_teamchange = 0;  // Always Initialize Variable -- Regor Tejmar
new g_rounds = 0;      // Always Initialize Variable -- Regor Tejmar

public Plugin:myinfo = 
{
	name = "DoDS Swapteams",
	author = "<eVa>Dog, changes by Psychoder and Regor Tejmar",
	description = "Swap teams at round end for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_swapteams_version", PLUGIN_VERSION, "Version of sm_dod_swapteams", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Swapteams = CreateConVar("sm_dod_swapteams", "0", "Enables/Disables sm_dod_swapteams  <0 to disable | # of rounds>", FCVAR_PLUGIN);
	g_Cvar_BonusRound = FindConVar("dod_bonusroundtime");
	
	HookEvent("dod_round_win", PlayerRoundWinEvent);
	HookEvent("player_team", ChangeTeam, EventHookMode_Pre);
}

public OnEventShutdown()
{
	UnhookEvent("dod_round_win", PlayerRoundWinEvent);
	UnhookEvent("player_team", ChangeTeam, EventHookMode_Pre);
}

//Added by psychocoder
public OnMapStart () 
{ 
    g_rounds=0; 
}

public PlayerRoundWinEvent(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new plugin_rounds=GetConVarInt(g_Cvar_Swapteams); 
    if(plugin_rounds != 0)
    { 
	//Added by Regor Tejmar -- Only increment g_rounds if plugin is enabled.
		g_rounds+=1;
		//Added by psychocoder
        if (plugin_rounds<=g_rounds) // If g_rounds is too high change too RT
        { 
            new Float:delay = float(GetConVarInt(g_Cvar_BonusRound)); 
            PrintToChatAll("\x01\x04[SM] Teams will be swapped in %i seconds", GetConVarInt(g_Cvar_BonusRound));
            g_rounds=0; 
            if (delay > 0) 
            { 
                CreateTimer(delay, DelayedSwitch, 0, 0); 
            } 
            else 
            { 
                ChangeTeams(); 
            } 
        }
        else
        {
            PrintToChatAll("\x01\x04[SM] Teams will be swapped in %i round(s)", plugin_rounds-g_rounds);
        }
    }
	else
	//Added by Regor Tejmar -- Reset round count if plugin is disabled.
	{
		g_rounds=0;
	}
}


public Action:ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_teamchange == 1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:DelayedSwitch(Handle:timer)
{
	ChangeTeams();
}

public Action:ChangeTeams()
{
	g_teamchange = 1;
	SetConVarInt(FindConVar("mp_limitteams"), 20);
	
	for (new client=1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && (GetClientTeam(client) == 2))
		{
			ChangeClientTeam(client, 1);
			ChangeClientTeam(client, 3);
			ShowVGUIPanel(client, "class_ger", INVALID_HANDLE, false);
		}
		else if (IsClientInGame(client) && (GetClientTeam(client) == 3))
		{
			ChangeClientTeam(client, 1);
			ChangeClientTeam(client, 2);
			ShowVGUIPanel(client, "class_us", INVALID_HANDLE, false);
		}
	}
	
	SetConVarInt(FindConVar("mp_limitteams"), 1);
	g_teamchange = 0;
			
	return Plugin_Handled;
}