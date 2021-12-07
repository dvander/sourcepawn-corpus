/*
DESCRIPTION
	This plugin will keep track of players money when they leave a team or disconnect.
	If they go into spectate with less cash than mp_startmoney, then their cash will be restored
	when they join a team again.
		
	If they disconnect and then reconnect during the same map, their money will be restored to 
	what it was before they disconnected.
		
CREDITS
	databomb for help with Array stuff to restore money after a player reconnects during the same map
	
CHANGELOG
	Version 1.0
		Initial release
	
	Version 1.1 - 1.3
		Trial and error with arrays (my learning time)
		
	Version 1.4
		Finally figured out array's so that players who leave and rejoin during the same map have their cash restored
	
	Version 1.4a
		Removed handle for timer - no need (thanks for advice databomb)
		
	Version 1.5
		Changed from using array to using Trie due to KyleS' suggestion - thanks ;)
	
	Version 1.6
		Fixed reported bug where player could join spectator team before map changes, then join spectator team on next map change then join a team and retain money from previous map.
		
		
TO DO:
	Nothing really, this is just a plugin to keep people from spectate hop to get money...
	if you want a plugin that does more, use exvel's "Save Scores" plugin - http://forums.alliedmods.net/showthread.php?t=74975
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.6"

public Plugin:myinfo = 
{
	name = "No Spec Hop Cash",
	author = "TnTSCS aka ClarkKent",
	description = "Prevents players from receiving mp_startmoney by spectate hopping",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=157593"
}

// Set globals
new Handle:h_Trie;

new bool:JustJoined[MAXPLAYERS+1];
new bool:PlayerSpec[MAXPLAYERS+1];

new StartMoney;
new PlayersCashAmount[MAXPLAYERS+1];

public OnPluginStart()
{
	// Create my ConVars
	CreateConVar("sm_nospeccash_buildversion",SOURCEMOD_VERSION, "The version of SourceMod that 'No Spec Hop Cash' was built on", FCVAR_PLUGIN);
	CreateConVar("sm_nospeccash_version", PLUGIN_VERSION, "The version of 'No Spec Hop Cash' ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new Handle:hRandom;// KyleS hates handles
	
	HookConVarChange((hRandom = FindConVar("mp_startmoney")), OnSMoneyChanged);
	StartMoney = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles.
	
	// Hook the player_team event
	HookEvent("player_team", TeamChanged);
	
	// Load translation file
	LoadTranslations("NoSpecHopCash.phrases");
	
	h_Trie = CreateTrie();
}

public OnSMoneyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StartMoney = GetConVarInt(cvar);
}

public TeamChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Stop processing if player disconnected, see OnClientDisconnect
	if (GetEventBool(event,"disconnect"))
	{
		return;
	}
	
	// Retrieve Client ID
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	//Check to see if a player is joining the game for the first time during this map
	if (JustJoined[client])
	{
		//After a player joins for the first time and picks a team, they are marked as NOT JustJoined
		JustJoined[client] = false;
		return;
	}
	
	// Retrieve the TeamID of the client
	new clientteam = GetEventInt(event,"team");
	
	switch (clientteam)
	{
		// No team
		case 0:
		{
			return;
		}
		
		// Spectator team
		case 1:
		{			
			// Get Player's cash
			PlayersCashAmount[client] = GetPlayersCash(client);
			
			// Only store cash when player is going to spectate IF their current cash is less than the mp_startmoney
			// As long as they don't disconnect and their money is > mp_startmoney, the game will handle the cash amount
			if (PlayersCashAmount[client] < StartMoney)
			{
				// Advise them their cash will be restored later
				PrintToChat(client,"\x04[\x03SpecHopCash\x04]\x01 %t", "Saved", PlayersCashAmount[client]);
				
				//Set player as being in spectate
				PlayerSpec[client] = true;
			}
		}
		
		// Terrorist or CT
		default:
		{
			// If player is NOT marked as spectate they must be joining for the first time or just switching teams
			if (!PlayerSpec[client])
			{
				return;
			}
			
			// Player joined a team from spectator team, mark as no longer in spectate
			PlayerSpec[client] = false;	
			
			// Create timer to set player's cash to saved value
			// For whatever reason, a timer is needed when a player goes from spectate to a team - otherwise, they'll get the mp_startmoney amount
			CreateTimer(0.1, t_SetCash, GetClientSerial(client));
		}
	}
}

public Action:t_SetCash(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return;
	}
	
	// Make sure client is still in game
	if (IsClientInGame(client))
	{
		/* Set the cash of the player to that which they had when they left the team (or disconnected)
		** Notify the user their money has been reset
		** Clear the timer */
		SetPlayersCash(client, PlayersCashAmount[client]);
		PrintToChat(client,"\x04[\x03SpecHopCash\x04]\x01 %t", "Restored", PlayersCashAmount[client]);
	}
}

public OnMapStart()
{
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
	
	for (new i = 1; i <=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PlayersCashAmount[i] = StartMoney;
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	// Do not process if client is a BOT
	if (!IsFakeClient(client))
	{
		new cash;
		
		// Retrieve the value of the Trie, if it exists and store that value in the cash variable
		if (GetTrieValue(h_Trie, auth, cash))
		{
			PlayersCashAmount[client] = cash;
			
			JustJoined[client] = false;
			PlayerSpec[client] = true;
		}
	}
}

public OnClientDisconnect(client)
{
	// IsClientInGame is needed to do any client specific stuff - also, make sure it's not a bot disconnecting
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		// Get and store the client's SteamID
		decl String:authString[20];
		authString[0] = '\0';
		GetClientAuthString(client, authString, 20);
		
		// Store player's current cash value when they disconnect
		new playerCash = GetPlayersCash(client);
		
		// Add/Update the value of the Trie to the variable playerCash,
		// the true flag will overwrite the value if one already exists
		SetTrieValue(h_Trie, authString, playerCash, true);
		
		PlayersCashAmount[client] = 0;
	}
}

public GetPlayersCash(client)
{
	// Return the value of the player's money
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

public SetPlayersCash(client, amount)
{
	// Set the player's money to the amount specified
	SetEntProp(client, Prop_Send, "m_iAccount", amount);
}