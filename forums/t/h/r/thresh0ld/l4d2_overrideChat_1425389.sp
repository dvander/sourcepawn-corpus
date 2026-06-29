#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "0.1"

new bool:isOverriden[MAXPLAYERS+1] = false;
new overrideClients[MAXPLAYERS+1] = -1;
new Handle:g_hVersion = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Chat Override",
	author = "SPOONMAN",
	description = "Override a player's chat and replace it with you're own version :P",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1425389#post1425389"
}

public OnPluginStart()
{
	g_hVersion = CreateConVar("sm_ochat_version", PLUGIN_VERSION, "Chat Override Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_ochat", Command_OverrideSelect, "Display's the Override menu", FCVAR_PLUGIN|FCVAR_SPONLY);
	RegConsoleCmd("sm_ochatp", Command_OverrideChat, "Override Client's Chat (TYPE = PUBLIC)", FCVAR_PLUGIN|FCVAR_SPONLY);
	RegConsoleCmd("sm_ochatt", Command_OverrideChat, "Override Client's Chat (TYPE = TEAM)", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	SetConVarString(g_hVersion, PLUGIN_VERSION);
}

public OnClientDisconnect(client)
{
	LogMessage("Removing Overide for Client %N", client);
	RemoveOverrideForClient(client);
}

public RemoveOverrideForClient(client)
{
	if (IsFakeClient(client)) return;
		
	isOverriden[client] = false;
	
	for (new i = 0; i < sizeof(overrideClients); i++)
	{
		if (overrideClients[0] == client)
		{
			overrideClients[0] = -1;
		}
	}
}

public Action:Command_OverrideSelect(client, args)
{
	if (!CheckAdminFlags(client, ADMFLAG_BAN))
	{
		PrintToChat(client, "You are not permitted to execute this command");
		return Plugin_Handled;
	}
	DisplayMenu_OverrideChat(client, MH_OverrideSelection, "Select Target To Override");
	return Plugin_Handled;
}

public Action:Command_OverrideChat(client, args)
{	
	if (!CheckAdminFlags(client, ADMFLAG_BAN))
	{
		PrintToChat(client, "You are not permitted to execute this command");
		return Plugin_Handled;
	}
	
	//Check first if the client has a currently selected target, continue otherwise
	new String:sCommand[255];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	new String:sBuffer[512];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
		
	if (overrideClients[client] > -1)
	{
		new targetTeam = GetClientTeam(overrideClients[client]);
		
		if (StrEqual(sCommand, "sm_ochatp"))
		{
			if (targetTeam == 1)
			{
				CPrintToChatAll("{default}%N :   {default}%s", overrideClients[client], sBuffer);
			}
			else if (targetTeam == 2)
			{
				CPrintToChatAll("{blue}%N{default} :  %s", overrideClients[client], sBuffer);
			}			
			else if (targetTeam == 3)
			{
				CPrintToChatAll("{red}%N{default} :   %s", overrideClients[client], sBuffer);
			}
		}
		else if (StrEqual(sCommand, "sm_ochatt"))
		{
			new String:teamName[255];
			new String:msg[MAX_MESSAGE_LENGTH];
			
			if (targetTeam == 1)
			{
				Format(teamName, sizeof(teamName), "Spectator");
			}
			else if (targetTeam == 2)
			{
				Format(teamName, sizeof(teamName), "Survivor");
			}
			else if (targetTeam == 3)
			{
				Format(teamName, sizeof(teamName), "Infected");
			}
			
			//Prepare the message
			Format(msg, sizeof(msg), "(%s) {red}%N {default}:  %s", teamName, overrideClients[client], sBuffer);
			
			for (new i = 1; i < MaxClients; i++)
			{
				if (IsClientConnected(i) && !IsFakeClient(i) && (GetClientTeam(i) == targetTeam))
				{
					CPrintToChat(i, msg);
				}
			}
			
			//Display the message to the overrider
			CPrintToChat(client, "{olive}[OVERRIDE]: %s", msg);
		}
	}
	else
	{
		PrintToChat(client, "No target client selected. Type !ochat in chat window to select target.");
	}
	
	return Plugin_Handled;
}

public DisplayMenu_OverrideChat(client, MenuHandler:menuHandler, const String:menuTitle[])
{
	//PrintToChatAll("Client %N = %i", client, client);
	new Handle:menu = CreateMenu(menuHandler);
	SetMenuTitle(menu, menuTitle);
		
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			new String:name[MAX_NAME_LENGTH];
			new String:clientIndex[255];
			
			GetClientName(i, name, sizeof(name));
			IntToString(i, clientIndex, sizeof(clientIndex));
			
			AddMenuItem(menu, clientIndex, name);
		}
	}
	
	AddMenuItem(menu, "clear", "Clear Selection");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public MH_OverrideSelection(Handle:menu, MenuAction:action, client, itemIndex)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:selectedClient[32];
		new bool:found = GetMenuItem(menu, itemIndex, selectedClient, sizeof(selectedClient));
			
		if (StrEqual(selectedClient, "clear"))
		{
			CPrintToChat(client, "{olive}[CHAT OVERRIDE]: {green}Successfully Cleared Target : {blue}%N", overrideClients[client]);
			isOverriden[overrideClients[client]] = false;
			overrideClients[client] = -1;
			return;
		}

		new selectedClientIndex = StringToInt(selectedClient);
		
		if (!IsClientConnected(selectedClientIndex)) return;		
		
		if (!CanUserTarget(client, selectedClientIndex))
		{
			PrintToConsole(client, "You cannot target this client.");
			PrintToChat(client, "You cannot target this client.");
			return;
		}
		
		//Ok, activate the menu handler
		if (found)
		{
			if (IsClientConnected(selectedClientIndex) && !IsFakeClient(selectedClientIndex))
			{
				if (isOverriden[selectedClientIndex])
				{
					CPrintToChat(client, "{olive}[CHAT OVERRIDE]: {green}Chat Override DE-ACTIVATED {blue}%N", selectedClientIndex);
					overrideClients[client] = -1;
					isOverriden[selectedClientIndex] = false;
				}
				else
				{
					CPrintToChat(client, "{olive}[CHAT OVERRIDE]: {green}Chat Override ACTIVATED for {blue}%N", selectedClientIndex);
					overrideClients[client] = selectedClientIndex;
					isOverriden[selectedClientIndex] = true;
				}
			}
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %N's menu was cancelled.  Reason: %d", client, itemIndex);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock bool:CheckAdminFlags(client, flags)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		new count, found;
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				count++;
				
				if (GetAdminFlag(admin, AdminFlag:i))
				{
					found++;
				}
			}
		}
		
		if (count == found)
		{
			return true;
		}
	}
	
	return false;
}