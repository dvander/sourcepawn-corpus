#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION "1.01"



public Plugin:myinfo = 
{
	name = "Self-Mute",
	author = "Otokiru ,edit 93x",
	description = "Self Mute Player Voice",
	version = PLUGIN_VERSION,
	url = "www.xose.net"
}

//====================================================================================================
//==== CREDITS: Otokiru (Idea+Source) // TF2MOTDBackpack (PlayerList Menu)
//====================================================================================================

public OnPluginStart() 
{	
	LoadTranslations("common.phrases");
	CreateConVar("sm_selfmute_version", PLUGIN_VERSION, "Version of Self-Mute", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_sm", selfMute, 0, "Mute player by typing !selfmute [playername]");
	RegAdminCmd("sm_selfmute", selfMute, 0, "Mute player by typing !sm [playername]");
	RegAdminCmd("sm_su", selfUnmute, 0, "Unmute player by typing !su [playername]");
	RegAdminCmd("sm_selfunmute", selfUnmute, 0, "Unmute player by typing !selfunmute [playername]");
	RegAdminCmd("sm_cm", checkmute, 0, "Check who you have self-muted");
	RegAdminCmd("sm_checkmute", checkmute, 0, "Check who you have self-muted");
}

//====================================================================================================

public OnClientPutInServer(client)
{
	new maxplayers = GetMaxClients();
	for (new id = 1; id <= maxplayers ; id++){
		if (id != client && IsClientInGame(id))
		{
			SetListenOverride(id, client, Listen_Yes);
		}
	}
}


public Action:selfMute(client, args)
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
	
	decl String:arg2[10];
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	
	
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	
	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	} 
	
	
	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && iClient >0) 
		{
			muteTargetedPlayer(client, iClient);
		}
	}
	
	return Plugin_Handled;
}





stock DisplayMuteMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_MuteMenu);
	SetMenuTitle(menu, "Choose a player to mute");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MuteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			new target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new userid = StringToInt(info);
			
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

public muteTargetedPlayer(client, target)
{
	SetListenOverride(client, target, Listen_No);
	decl String:chkNick[256];
	GetClientName(target, chkNick, sizeof(chkNick));
	PrintToChat(client, "\x04[Self-Mute]\x01 You have self-muted:\x04 %s", chkNick);
}

//====================================================================================================




public Action:selfUnmute(client, args)
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
	
	decl String:arg2[10];
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	
	
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	
	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}
	
	
	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if(IsClientInGame(iClient) && iClient > 0)
		{
			unMuteTargetedPlayer(client, iClient);
		}
	}
	
	return Plugin_Handled;
}











stock DisplayUnMuteMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_UnMuteMenu);
	SetMenuTitle(menu, "Choose a player to unmute");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_UnMuteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			new target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new userid = StringToInt(info);
			
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

public unMuteTargetedPlayer(client, target)
{
	SetListenOverride(client, target, Listen_Yes);
	decl String:chkNick[256];
	GetClientName(target, chkNick, sizeof(chkNick));
	PrintToChat(client, "\x04[Self-Mute]\x01 You have self-unmuted:\x04 %s", chkNick);
}

//====================================================================================================

public Action:checkmute(client, args)
{
	if (client == 0)
	{
		PrintToChat(client, "\x04[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}
	
	new maxplayers = GetMaxClients();
	decl String:nickNames[9216];
	Format(nickNames, sizeof(nickNames), "No players found.");
	new bool:firstNick = true;
	
	for (new id = 1; id <= maxplayers ; id++){
		if (id != client && IsClientInGame(id)){
			new ListenOverride:override = GetListenOverride(client, id);
			if(override == Listen_No){
				if(firstNick){
					firstNick = false;
					Format(nickNames, sizeof(nickNames), "");
				} else
				Format(nickNames, sizeof(nickNames), "%s, ", nickNames);
				decl String:chkNick[256];
				GetClientName(id, chkNick, sizeof(chkNick));
				Format(nickNames, sizeof(nickNames), "%s%s", nickNames,chkNick);
			}
		}
	}
	
	PrintToChat(client, "\x04[Self-Mute]\x01 List of self-muted:\x04 %s", nickNames);
	Format(nickNames, sizeof(nickNames), "");
	
	//PrintToChat(client, "%i", GetListenOverride(client, GetClientOfUserId(218)));
	
	return Plugin_Handled;
}
