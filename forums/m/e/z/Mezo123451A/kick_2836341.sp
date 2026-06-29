#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// ArrayList to store banned Steam IDs
ArrayList g_BannedPlayers;

public Plugin myinfo = 
{
	name = "Simple Kick Menu",
	author = "Mezo123451A",
	description = "Simple menu to kick players",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	// Initialize the banned players array
	g_BannedPlayers = new ArrayList(32); // 32 is the max length of a SteamID string
	
	RegAdminCmd("sm_k", Command_KickMenu, ADMFLAG_KICK, "Opens a menu to kick players");
	RegAdminCmd("sm_b", Command_BanMenu, ADMFLAG_BAN, "Opens a menu to ban players");
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	// Hook player connections to check for banned players
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	char steamId[32];
	event.GetString("networkid", steamId, sizeof(steamId));
	
	// If this SteamID is in our banned list, reject the connection
	if (g_BannedPlayers.FindString(steamId) != -1)
	{
		char clientName[64];
		event.GetString("name", clientName, sizeof(clientName));
		
		// Kick the player if they're banned
		int userId = event.GetInt("userid");
		CreateTimer(0.1, Timer_KickBannedPlayer, userId);
		
		// Notify admins
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && CheckCommandAccess(i, "sm_b", ADMFLAG_BAN))
			{
				PrintToChat(i, "[SM] Banned player %s tried to connect.", clientName);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_KickBannedPlayer(Handle timer, any userId)
{
	int client = GetClientOfUserId(userId);
	if (client)
	{
		KickClient(client, "You are banned from this server");
	}
	return Plugin_Stop;
}

public Action Command_Say(int client, const char[] command, int argc)
{
	char text[192];
	GetCmdArgString(text, sizeof(text));
	
	// Remove quotes
	StripQuotes(text);
	
	// Check if the command is !k or !b
	if ((StrEqual(text, "!k") && CheckCommandAccess(client, "sm_k", ADMFLAG_KICK)) ||
		(StrEqual(text, "!b") && CheckCommandAccess(client, "sm_b", ADMFLAG_BAN)))
	{
		// Block the message from being displayed
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Command_KickMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	DisplayKickMenu(client);
	return Plugin_Handled;
}

void DisplayKickMenu(int client)
{
	Menu menu = new Menu(KickMenuHandler);
	menu.SetTitle("Select a player to kick:");
	
	char name[MAX_NAME_LENGTH];
	char userid[12];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			menu.AddItem(userid, name);
		}
	}
	
	if (menu.ItemCount == 0)
	{
		menu.AddItem("", "No players available", ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int KickMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char userid[12];
			menu.GetItem(param2, userid, sizeof(userid));
			
			int target = GetClientOfUserId(StringToInt(userid));
			
			if (target == 0)
			{
				PrintToChat(param1, "[SM] Player no longer available.");
				DisplayKickMenu(param1);
				return 0;
			}
			
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			
			KickClient(target, "Kicked by admin");
			
			// Only notify admins about the kick
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && CheckCommandAccess(i, "sm_k", ADMFLAG_KICK))
				{
					PrintToChat(i, "[SM] %N has kicked %s", param1, name);
				}
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_BanMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	DisplayBanMenu(client);
	return Plugin_Handled;
}

void DisplayBanMenu(int client)
{
	Menu menu = new Menu(BanMenuHandler);
	menu.SetTitle("Select a player to ban:");
	
	char name[MAX_NAME_LENGTH];
	char userid[12];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			menu.AddItem(userid, name);
		}
	}
	
	if (menu.ItemCount == 0)
	{
		menu.AddItem("", "No players available", ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int BanMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char userid[12];
			menu.GetItem(param2, userid, sizeof(userid));
			
			int target = GetClientOfUserId(StringToInt(userid));
			
			if (target == 0)
			{
				PrintToChat(param1, "[SM] Player no longer available.");
				DisplayBanMenu(param1);
				return 0;
			}
			
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			
			// Get the player's SteamID
			char steamId[32];
			GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId));
			
			// Add to banned list
			g_BannedPlayers.PushString(steamId);
			
			KickClient(target, "Banned by admin");
			
			// Only notify admins about the ban
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && CheckCommandAccess(i, "sm_b", ADMFLAG_BAN))
				{
					PrintToChat(i, "[SM] %N has banned %s until server restart", param1, name);
				}
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}
