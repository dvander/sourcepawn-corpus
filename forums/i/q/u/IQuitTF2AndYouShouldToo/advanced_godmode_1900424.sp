// Required includes
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

// Set strict semicolon mode
#pragma semicolon 1

// Define plugin version
#define PLUGIN_VERSION "1.2"

// God Mode/Buddha Mode Booleans
new bool:g_bIsBuddhaOn[MAXPLAYERS + 1];
new bool:g_bIsGodOn[MAXPLAYERS + 1];

// ConVar Handle
new Handle:h_ConVarEnabled = INVALID_HANDLE;

// Plugin information
public Plugin:myinfo =
{
	name = "God Mode for Admins Advanced",
	author = "abrandnewday",
	description = "Adds in God Mode and Buddha Mode, as well as allowing players to spawn with God Mode!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=165383"
}

// Event: Plugin has loaded
public OnPluginStart()
{
	// Register the Plugin Version ConVar
	CreateConVar("sm_advancedgod_version", PLUGIN_VERSION, "God Mode for Admins Advanced Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	// Register & hook the change of the Public God Mode on Spawn ConVar
	h_ConVarEnabled = CreateConVar("sm_godmodeonspawn_enabled", "0.0", "Enable/Disable Public God Mode on Spawn [0 = Disabled / 1 = Enabled]",  0, true, 0.0, true, 1.0);
	HookConVarChange(h_ConVarEnabled, ConVarEnabledChanged);
	
	// Register public commands
	RegConsoleCmd("sm_mortal", Command_Mortal, "Usage: sm_mortal");
	
	// Register admin commands
	RegAdminCmd("sm_god", Command_God, ADMFLAG_CHEATS, "Usage: sm_god [target]");
	RegAdminCmd("sm_buddha", Command_Buddha, ADMFLAG_CHEATS, "Usage: sm_buddha [target]");
	
	// Hook events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_class", Event_PlayerSpawn);
}

// Function: Configs have been executed
public OnConfigsExecuted()
{
	// Check if the "God Mode on Spawn" ConVar is enabled
	if (GetConVarBool(h_ConVarEnabled))
	{
		// Print message to the console
		PrintToServer("[SM] Players will spawn with God Mode.");
	}
	
	// Otherwise
	else
	{
		// Print message to the console
		PrintToServer("[SM] Players will not spawn with God Mode.");
	}
}

// Event: Plugin has been unloaded/disabled
public OnPluginEnd()
{
	// For all the clients in the game
	for (new i=1; i<=MaxClients; i++)
	{
		// Check if they are valid clients and are alive
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			// If they are all valid clients and alive, make them mortal
			if (g_bIsGodOn[i] == true)
			{
				// Make all clients mortal
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				g_bIsGodOn[i] = false;
			}
		}
	}
}

// Function: Public God Mode on Spawn ConVar has been changed
public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	// Check if the "God Mode on Spawn" ConVar is enabled
	if (GetConVarBool(h_ConVarEnabled))
	{
		// Print message to the console
		PrintToServer("[SM] Players will spawn with God Mode.");
	}
	
	// Check if the "God Mode on Spawn" ConVar is disabled
	else if (!GetConVarBool(h_ConVarEnabled))
	{
		// Print message to the console
		PrintToServer("[SM] Players will not spawn with God Mode.");
		
		// Then, for all the clients in the game
		for (new i=1; i<=MaxClients; i++)
		{
			// Check if the clients are valid clients and are alive, and if they have God Mode enabled
			if (IsValidClient(i) && IsPlayerAlive(i) && g_bIsGodOn[i] == true)
			{
				// Make all clients mortal
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				g_bIsGodOn[i] = false;
			}
		}
	}
}

// Event: Player has spawned
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Check if the "God Mode on Spawn" ConVar is enabled
	if(GetConVarBool(h_ConVarEnabled))
	{
		// If the client is valid and alive, and does not have God Mode on
		if (IsValidClient(client) && IsPlayerAlive(client) && g_bIsGodOn[client] == false)
		{
			// Enable God Mode on the client
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			g_bIsGodOn[client] = true;
			PrintToChat(client, "[SM] You have spawned with God Mode on. To disable God Mode, say !mortal");
		}
	}
}

// Command: Mortal Mode
public Action:Command_Mortal(client, args)
{
	// Check if God Mode or Buddha Mode is on.
	// I added Buddha Mode incase an admin enables Buddha on a player via the command, and they want to make themselves mortal
	if (g_bIsGodOn[client] == true || g_bIsBuddhaOn[client] == true)
	{
		// Make the client mortal
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		g_bIsGodOn[client] = false;
		g_bIsBuddhaOn[client] = false;
		PrintToChat(client, "[SM] You are now mortal");
	}
	// Otherwise, if God Mode or Buddha Mode isn't on
	else
	{
		// Inform the client that they don't have God Mode or Buddha Mode enabled
		PrintToChat(client, "[SM] Unable to make yourself mortal - You aren't in God Mode or Buddha Mode");
	}
	return Plugin_Handled;
}

// Command: God Mode
// Thanks to minimoney1 for showing me how to set this command up so that you can use it with or without a target,
// instead of having to code in one command for enabling/disabling God Mode on just yourself, and a second command for enabling/disabling God Mode on a target.
public Action:Command_God(client, args)
{
	if (args < 1)
	{
		if (g_bIsGodOn[client] == false)
		{
			ReplyToCommand(client, "[SM] God Mode: Enabled");
			g_bIsGodOn[client] = true;
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[SM] God Mode: Disabled");
			g_bIsGodOn[client] = false;
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			
			return Plugin_Handled;
		}
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (g_bIsGodOn[target_list[i]] == false)
		{
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
			g_bIsGodOn[target_list[i]] = true;
		}
		else
		{
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			g_bIsGodOn[target_list[i]] = false;
		}
		if (!tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "%s God Mode on %s.", g_bIsGodOn[target_list[i]] ? "Enabled" : "Disabled", target_list[i]);
		}
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%s God Mode on %t.", g_bIsGodOn[target_list[0]] ? "Enabled" : "Disabled", target_name);
	}
	return Plugin_Handled;
}

// Command: Buddha Mode
// Thanks to minimoney1 for showing me how to set this command up so that you can use it with or without a target,
// instead of having to code in one command for enabling/disabling Buddha Mode on just yourself, and a second command for enabling/disabling Buddha Mode on a target.
public Action:Command_Buddha(client, args)
{
	// If no target is specified
	if (args < 1)
	{
		// Check if the player doesn't have Buddha Mode on
		if (g_bIsBuddhaOn[client] == false)
		{
			// Give the player Buddha Mode
			ReplyToCommand(client, "[SM] Buddha Mode: Enabled");
			g_bIsBuddhaOn[client] = true;
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			
			return Plugin_Handled;
		}
		// Otherwise, if the player does have Buddha Mode on
		else
		{
			// Make the player mortal
			ReplyToCommand(client, "[SM] Buddha Mode: Disabled");
			g_bIsBuddhaOn[client] = false;
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			
			return Plugin_Handled;
		}
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		// Check if the target doesn't have Buddha Mode on
		if (g_bIsGodOn[target_list[i]] == false)
		{
			// Give the target Buddha Mode
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			g_bIsBuddhaOn[target_list[i]] = true;
		}
		
		// Otherwise, if the target does have Buddha Mode on
		else
		{
			// Make the target mortal
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			g_bIsBuddhaOn[target_list[i]] = false;
		}

		// Showing the activity to the admin
		if (!tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "%s Buddha Mode on %s.", g_bIsGodOn[target_list[i]] ? "Enabled" : "Disabled", target_list[i]);
		}
	}

	// Showing the activity to the admin
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%s Buddha Mode on %t.", g_bIsGodOn[target_list[0]] ? "Enabled" : "Disabled", target_name);
	}
	return Plugin_Handled;
}

// Function: Is Client Valid?
stock bool:IsValidClient(client)
{
	if (client <= 0)
	{
		return false;
	}
	if (client > MaxClients)
	{
		return false;
	}
	return IsClientInGame(client);
}

