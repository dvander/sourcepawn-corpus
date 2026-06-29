#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION "1.03"

bool MuteStatus[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Self-Mute",
	author = "Otokiru ,edit 93x, Accelerator",
	description = "Self Mute Player Voice",
	version = PLUGIN_VERSION,
	url = "www.xose.net"
}

//====================================================================================================
//==== CREDITS: Otokiru (Idea+Source) // TF2MOTDBackpack (PlayerList Menu)
//====================================================================================================

public void OnPluginStart() 
{	
	LoadTranslations("common.phrases");
	CreateConVar("sm_selfmute_version", PLUGIN_VERSION, "Version of Self-Mute", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_sm", selfMute, "Mute player by typing !selfmute [playername]");
	RegConsoleCmd("sm_selfmute", selfMute, "Mute player by typing !sm [playername]");
	RegConsoleCmd("sm_su", selfUnmute, "Unmute player by typing !su [playername]");
	RegConsoleCmd("sm_selfunmute", selfUnmute, "Unmute player by typing !selfunmute [playername]");
	RegConsoleCmd("sm_cm", checkmute, "Check who you have self-muted");
	RegConsoleCmd("sm_checkmute", checkmute, "Check who you have self-muted");
}

//====================================================================================================

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
	
	float fClientTime = GetClientTime(client);
	for (int id = 1; id <= MaxClients; id++)
	{
		if (fClientTime <= 180.0)
		{
			MuteStatus[id][client] = false;
			MuteStatus[client][id] = false;
			continue;
		}
		if (id != client && IsClientInGame(id))
		{
			if (MuteStatus[id][client])
			{
				SetListenOverride(id, client, Listen_No);
			}
			if (MuteStatus[client][id])
			{
				SetListenOverride(client, id, Listen_No);
			}
		}
	}
}

public Action selfMute(int client, int args)
{
	if(client == 0)
	{
		PrintToChat(client, "\x04[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}
	
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] Use: !sm [playername]");
		DisplayMuteMenu(client);
		return Plugin_Handled;
	}
	
	char arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}
	
	for (int i = 0; i < TargetCount; i++) 
	{ 
		if (TargetList[i] > 0 && TargetList[i] != client && IsClientInGame(TargetList[i])) 
		{
			muteTargetedPlayer(client, TargetList[i]);
		}
	}
	return Plugin_Handled;
}

stock void DisplayMuteMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_MuteMenu);
	SetMenuTitle(menu, "Choose a player to mute");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_MuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);
			
			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "\x04[SM] Player no longer available");
			}
			else
			{
				muteTargetedPlayer(param1, target);
			}
		}
	}
}

public void muteTargetedPlayer(int client, int target)
{
	SetListenOverride(client, target, Listen_No);
	PrintToChat(client, "\x04[Self-Mute]\x01 You have self-muted:\x04 %N", target);
	MuteStatus[client][target] = true;
}

//====================================================================================================

public Action selfUnmute(int client, int args)
{
	if(client == 0)
	{
		PrintToChat(client, "\x04[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}
	
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] Use: !su [playername]");
		DisplayUnMuteMenu(client);
		return Plugin_Handled;
	}
	
	char arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}
	
	for (int i = 0; i < TargetCount; i++) 
	{ 
		if(TargetList[i] > 0 && TargetList[i] != client && IsClientInGame(TargetList[i]))
		{
			unMuteTargetedPlayer(client, TargetList[i]);
		}
	}
	return Plugin_Handled;
}

stock void DisplayUnMuteMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_UnMuteMenu);
	SetMenuTitle(menu, "Choose a player to unmute");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_UnMuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);
			
			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "\x04[SM] Player no longer available");
			}
			else
			{
				unMuteTargetedPlayer(param1, target);
			}
		}
	}
}

public void unMuteTargetedPlayer(int client, int target)
{
	SetListenOverride(client, target, Listen_Yes);
	PrintToChat(client, "\x04[Self-Mute]\x01 You have self-unmuted:\x04 %N", target);
	MuteStatus[client][target] = false;
}

//====================================================================================================

public Action checkmute(int client, int args)
{
	if (client == 0)
	{
		PrintToChat(client, "\x04[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}
	
	char nickNames[256];
	Format(nickNames, sizeof(nickNames), "No players found.");
	bool firstNick = true;
	
	for (int id = 1; id <= MaxClients; id++)
	{
		if (IsClientInGame(id))
		{
			if(GetListenOverride(client, id) == Listen_No)
			{
				if(firstNick)
				{
					firstNick = false;
					Format(nickNames, sizeof(nickNames), "%N", id);
				}
				else
					Format(nickNames, sizeof(nickNames), "%s, %N", nickNames, id);
			}
		}
	}
	
	PrintToChat(client, "\x04[Self-Mute]\x01 List of self-muted:\x04 %s", nickNames);
	
	return Plugin_Handled;
}
