/**
 * Credits to psychonic - https://forums.alliedmods.net/showthread.php?t=161586 for example with TF2
 * 
 * 
 * 
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION		"1.0.0.0"

new bool:PlayerIsAdmin[MAXPLAYERS+1] = {false, ...};
new bool:AdminInGame = false;

public Plugin:myinfo =
{
	name = "CS:GO Vote Control",
	author = "TnTSCS aKa ClarkKent",
	description = "Gives admins more control over the CS:GO voting system",
	version = PLUGIN_VERSION,
	url = "http://www.dhgamers.com"
};

public OnPluginStart()
{
	AddCommandListener(callvote, "callvote");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}
	
	return APLRes_Success;
}

public OnClientPostAdminCheck(client)
{
	PlayerIsAdmin[client] = CheckCommandAccess(client, "allow_votes", ADMFLAG_VOTE);
}

public Action:callvote(client, const String:cmd[], argc)
{
	AdminInGame = false;
	
	/* Player isn't admin, let's see if the vote is allowed */
	if (!PlayerIsAdmin[client])
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && PlayerIsAdmin[i])
			{
				AdminInGame = true;
				break;
			}
		}
	}
	
	if (AdminInGame)
	{
		/* There's an admin in the game, do not allow non-admins to vote */
		PrintToChat(client, "Voting is not allowed right now.");
		return Plugin_Handled;
	}
	
	new String:votereason[50];
	new String:buffer[50];
	new bool:allowed;
	
	GetCmdArg(1, votereason, sizeof(votereason));
	if (StrEqual(votereason, "restartgame", false))
	{
		allowed = CheckCommandAccess(client, "allow_restartggame", ADMFLAG_GENERIC);
		Format(buffer, sizeof(buffer), "restart the game.");
	}
	else if (StrEqual(votereason, "changelevel", false))
	{
		allowed = CheckCommandAccess(client, "allow_changelevel", ADMFLAG_CHANGEMAP);
		Format(buffer, sizeof(buffer), "change the map.");
	}
	else if (StrEqual(votereason, "swapteams", false))
	{
		allowed = CheckCommandAccess(client, "allow_swapteams", ADMFLAG_KICK);
		Format(buffer, sizeof(buffer), "swap the teams.");
	}
	else if (StrEqual(votereason, "scrambleteams", false))
	{
		allowed = CheckCommandAccess(client, "allow_scrambleteams", ADMFLAG_KICK);
		Format(buffer, sizeof(buffer), "scramble the teams.");
	}
	else if (StrEqual(votereason, "kick", false))
	{
		allowed = CheckCommandAccess(client, "allow_kick", ADMFLAG_KICK);
		Format(buffer, sizeof(buffer), "kick a player.");
	}
	else if (StrEqual(votereason, "surrender", false))
	{
		allowed = CheckCommandAccess(client, "allow_surrender", ADMFLAG_GENERIC);
		Format(buffer, sizeof(buffer), "surrender.");
	}
	
	if (!allowed)
	{
		PrintToChat(client, "You're not allowed to %s", buffer);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
