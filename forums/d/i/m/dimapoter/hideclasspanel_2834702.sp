/**
 * vim: set ts=4 :
 * =============================================================================
 * Hide Class Panel
 * Skips model (class) picker window after selecting team
 *
 * Copyright (C) 2004-2077 Dimmskii
 * =============================================================================
 *
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
//#include <cstrike>
#include <bitbuffer>
#undef REQUIRE_PLUGIN

public Plugin myinfo =
{
	name = "Hide Class Panel",
	author = "Dimmskii",
	description = "Skips model (class) picker window after selecting team",
	version = "1.0.0",
	url = "http://quaker.pro/"
};

public OnPluginStart()
{
	AddCommandListener(Command_JoinTeam, "jointeam");
	HookUserMessage(GetUserMessageId("VGUIMenu"), Umsg_VGUIMenu, true);
}

public Action:Umsg_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {
	decl String:strName[256]=""; 
	BfReadString(bf, strName, sizeof(strName), true);
	
	if(StrEqual(strName, "class_ter") || StrEqual(strName, "class_ct")) 
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;  
}

public Action:Command_JoinTeam(int client, const char[] command, int args)
{
	if(args > 0)
	{
		char strArg1[128];
		GetCmdArg(1, strArg1, sizeof(strArg1));
		
		int iTeamJoin = StringToInt(strArg1);
		//int iTeamLeave = GetClientTeam(client);
		
		if(iTeamJoin==2 || iTeamJoin==3)
		{
			ClientCommand(client, "joinclass 0");
		}
	}
	
	return Plugin_Continue;
}
