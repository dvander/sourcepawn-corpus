/*  SM ExoJump Boots Giver
 *
 *  Copyright (C) 2019 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>


public Plugin myinfo =
{
	name = "SM ExoJump Boots Giver",
	author = "Franc1sco franug",
	description = "",
	version = "1.0.3",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_exojump", Command_ExoJump, ADMFLAG_BAN);
	RegAdminCmd("sm_bumpmine", Command_BumpMine, ADMFLAG_BAN);
}

//weapon_bumpmine

public Action Command_BumpMine(int client, int args)
{

	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Use: sm_bumpmine <#userid|name>");
		return Plugin_Handled;
	}


	char strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 

	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToCommand(client, "client not found");
		return Plugin_Handled; 
	} 

	// Apply to all targets 
	int mine;
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) 
		{
			mine = GivePlayerItem(iClient, "weapon_bumpmine");
			if (IsValidEdict(mine))
				EquipPlayerWeapon(iClient, mine);
				
			ReplyToCommand(client, "Player %N received bump mine", iClient);
		} 
	}

	return Plugin_Handled;
}

public Action Command_ExoJump(int client, int args)
{

	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Use: sm_exojump <#userid|name> <0-1>");
		return Plugin_Handled;
	}


	char strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	char strEnable[32]; GetCmdArg(2, strEnable, sizeof(strEnable)); 
	
	int enable = StringToInt(strEnable);
	
	if(enable > 1 || enable < 0)
	{
		ReplyToCommand(client, "[SM] Use: sm_exojump <#userid|name> <0-1>");
		return Plugin_Handled;
	}

	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToCommand(client, "client not found");
		return Plugin_Handled; 
	} 

	// Apply to all targets 
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) 
		{
			SetEntProp(iClient, Prop_Send, "m_passiveItems", enable, 1, 1);
			ReplyToCommand(client, "Player %N %s exojump", iClient, enable==1?"received":"removed");
		} 
	}

	return Plugin_Handled;
}
