/**
* DoD:S All Chat by Root
*
* Description:
*   Provides a support to relay chat messages of dead players, spectators or a team chat to alive players.
*
* Version 3.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ SEMICOLON ]=============================================================
#pragma semicolon 1

// ====[ CONSTANTS ]=============================================================
#define PLUGIN_NAME        "DoD:S All Chat"
#define PLUGIN_VERSION     "3.0"

#define MAX_MESSAGE_LENGTH 256
#define DOD_MAXPLAYERS     33

// ====[ VARIABLES ]=============================================================
new	Handle:allchat_enable = INVALID_HANDLE,
	Handle:allchat_team   = INVALID_HANDLE,
	String:message[MAX_MESSAGE_LENGTH],
	bool:targets[DOD_MAXPLAYERS + 1], bool:IsTeamChat;

// ====[ PLUGIN ]================================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Provides a support to relay messages of dead players, spectators or a team chat",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
};


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ------------------------------------------------------------------------------ */
public OnPluginStart()
{
	// Create ConVars
	CreateConVar("dod_allchat_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	allchat_enable = CreateConVar("dod_allchat",  "1", "Whether or not enable All Chat plugin",                                         FCVAR_PLUGIN, true, 0.0, true, 1.0);
	allchat_team   = CreateConVar("dod_teamchat", "1", "Determines who can see team messages:\n0 = All players\n1 = Only team members", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Hook only enable ConVar value changes
	HookConVarChange(allchat_enable, OnConVarChange);

	// Manually trigger OnConVarChange to hook all the stuff
	OnConVarChange(allchat_enable, "0", "1");

	// Create and exec plugin's config
	AutoExecConfig(true, "dod_allchat");
}

/* OnConVarChange()
 *
 * When convar's value is changed.
 * --------------------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	switch (StringToInt(newValue))
	{
		case true:
		{
			HookUserMessage(GetUserMessageId("SayText"), SayTextHook);
			HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
		}
		case false:
		{
			UnhookUserMessage(GetUserMessageId("SayText"), SayTextHook);
			UnhookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
		}
	}
}

/* SayTextHook()
 *
 * Hooks SayText user message to process targets which will receive a message.
 * --------------------------------------------------------------------------- */
public Action:SayTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	// Fill global message string
	BfReadString(bf, message, sizeof(message));
	for (new i = 0; i < playersNum; i++)
	{
		targets[players[i]] = false;
	}
}

/* Event_PlayerSay()
 *
 * Hooks SayText user message to process targets which will receive a message.
 * --------------------------------------------------------------------------- */
public Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We can not rely only on UserMessage because this event can fired more than once for the same chat messages under certain conditions
	// This will result in duplicate messages
	new clients[MaxClients], numClients, client, i;

	// Get message author
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Team chat and convar value is initialized
	if (IsTeamChat && GetConVarBool(allchat_team))
	{
		// Then send this message to all team mates
		for (i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && targets[i])
			{
				clients[numClients++] = i;
			}

			// Ignore other clients if team not matches
			targets[i] = false;
		}
	}
	else // Nope. Relay all chat messages
	{
		for (i = 1; i <= MaxClients; i++)
		{
			// To all clients (including team messages)
			if (IsClientInGame(i) && targets[i])
			{
				clients[numClients++] = i;
			}

			// Ignore author of message
			targets[i] = false;
		}
	}

	// Start message broadcasting for specified clients
	new Handle:SayText = StartMessage("SayText", clients, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	// Check if user message is valid
	if (SayText != INVALID_HANDLE)
	{
		// Write author index in bitbuffer
		BfWriteByte(SayText, client);

		// Write message from SayTextHook
		BfWriteString(SayText, message);

		// And colorize author's nickname
		BfWriteByte(SayText, -1);

		// End a message (like close handle), otherwise all PrintToChat natives will not work!
		EndMessage();
	}
}

/* Command_Say()
 *
 * When the chat message is received in global chat.
 * ------------------------------------------------------------------------------ */
public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	// When player is saying something, make sure all clients will receive a message
	for (new target = 1; target <= MaxClients; target++)
	{
		targets[target] = true;
	}

	// Does "say" command was used?
	if (StrEqual(command, "say", false))
	{
		IsTeamChat = false;
	}
	else
	{
		// Nope, that was definitely a team chat
		IsTeamChat = true;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}