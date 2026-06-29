/*                                                        
 * 		    Copyright (C) 2018 Adam "Potatoz" Ericsson
 * 
 * 	This program is free software: you can redistribute it and/or modify it
 * 	under the terms of the GNU General Public License as published by the Free
 * 	Software Foundation, either version 3 of the License, or (at your option) 
 * 	any later version.
 *
 * 	This program is distributed in the hope that it will be useful, but WITHOUT 
 * 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * 	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * 	See http://www.gnu.org/licenses/. for more information
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma semicolon 1

#define VERSION "1.0"

bool IsMapConfigured;
int team_blocked = 0;
Handle blockedteam;

KeyValues kv;

public Plugin:myinfo =
{
    name = "blockteam",
    author = "Potatoz",
    description = "",
    version = VERSION,
    url = ""
};


public OnPluginStart()
{
	RegAdminCmd("sm_blockteam", Command_BlockTeam, ADMFLAG_ROOT);
	AddCommandListener(Command_JoinTeam, "jointeam");	
	
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/blockteam_config.cfg");
	kv = new KeyValues("blockteam_config");
	kv.ImportFromFile(buffer);
}

public OnConfigsExecuted()
{	
	blockedteam = FindConVar("mp_humanteam");
	IsMapConfigured = false;
	Parse_MapConfig();
}

public void OnMapStart()
{
	if(!IsMapConfigured)
	{
		blockedteam = FindConVar("mp_humanteam");
		
		int ctspawns = 0;
		int tspawns = 0;
		
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, "info_player_counterterrorist")) != -1) 
			ctspawns++;
		
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "info_player_terrorist")) != -1)
			tspawns++;
		
		if(tspawns > 0 && ctspawns == 0 
		|| tspawns > ctspawns)
		{
			team_blocked = 3;
			SetConVarString(blockedteam, "t", true, false);
		}
		else if(ctspawns > 0 && tspawns == 0
		|| ctspawns > tspawns)
		{
			team_blocked = 2;
			SetConVarString(blockedteam, "ct", true, false);
		}
	}
}

public Action Command_JoinTeam(int client, char[] command, int args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
		
	char teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new target_team = StringToInt(teamString);
	new current_team = GetClientTeam(client);

	if(target_team == current_team)
		return Plugin_Handled;
	else if(target_team == team_blocked) 
	{
		if(team_blocked == 2 && current_team != 3)
			ChangeClientTeam(client, 3);
		else if(team_blocked == 3 && current_team != 2)
			ChangeClientTeam(client, 2);
		return Plugin_Handled;
	}
	else 
	{
		if(IsPlayerAlive(client))
			ForcePlayerSuicide(client);
		
		ChangeClientTeam(client, target_team);
		return Plugin_Handled;
	}
}

public Action Command_BlockTeam(int client, int args)
{		
	if(args != 1)
	{
		if(IsMapConfigured)
		{
			Parse_MapConfig();
			
			if(team_blocked == 0)
				PrintToChat(client, " \x07* This map has already been configured to allow all teams");
			else if(team_blocked == 2)
				PrintToChat(client, " \x07* This map has already been configured to block T");
			else if(team_blocked == 3)
				PrintToChat(client, " \x07* This map has already been configured to block CT");
				
			PrintToChat(client, " \x06* \x01Overwrite team-block with: \x06sm_blockteam <CT/T/NONE>");
		} else if(team_blocked == 2 || team_blocked == 3) {
			if(team_blocked == 2)
				PrintToChat(client, " \x07* This map has been automatically set to block T");
			else if(team_blocked == 3)
				PrintToChat(client, " \x07* This map has been automatically set to block CT");
			
			PrintToChat(client, " \x06* \x01Overwrite team-block with: \x06sm_blockteam <CT/T/NONE>");
		} else PrintToChat(client, " \x06* \x01Usage: \x06sm_blockteam <CT/T/NONE>");
		
		return Plugin_Handled;
	}
	
	if(IsFakeClient(client)) return Plugin_Handled;

	char buffer[PLATFORM_MAX_PATH];
	
	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	kv.JumpToKey(sMapName, true);

	GetCmdArgString(buffer, sizeof(buffer));

	if(StrEqual(buffer, "CT", false))
	{
		team_blocked = 3;
		SetConVarString(blockedteam, "t", true, false);
		Format(buffer, sizeof(buffer), "CT");
	}
	else if(StrEqual(buffer, "T", false))
	{
		team_blocked = 2;
		SetConVarString(blockedteam, "ct", true, false);
		Format(buffer, sizeof(buffer), "T");
	}
	else if(StrEqual(buffer, "NONE", false))
	{
		team_blocked = 0;
		SetConVarString(blockedteam, "any", true, false);
		Format(buffer, sizeof(buffer), "NONE");
	}
	else 
	{
		PrintToChat(client, " \x06* \x01Usage: \x06sm_blockteam <CT/T/NONE>");
		return Plugin_Handled;
	}
	
	if(StrEqual(buffer, "NONE", false))
		PrintToChat(client, " \x06* \x01No longer blocking entry to any specific team on \x06%s", sMapName);
	else
		PrintToChat(client, " \x06* \x01Now blocking entry to \x06%s \x01on \x06%s", buffer, sMapName);

	kv.SetString("team_blocked", buffer);
	kv.Rewind();

	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/blockteam_config.cfg");
	kv.ExportToFile(buffer);
	
	
	Parse_MapConfig();
	
	return Plugin_Handled;
}

Parse_MapConfig()
{
	char sConfig[PLATFORM_MAX_PATH], sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/blockteam_config.cfg");

	KeyValues hConfig = new KeyValues("blockteam_config");
	
	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvJumpToKey(hConfig, sMapName))
		{
			new String:sTeamBlocked[6];
			KvGetString(hConfig, "team_blocked", sTeamBlocked, sizeof(sTeamBlocked));
			if(StrEqual(sTeamBlocked, "T", false)) 
			{
				SetConVarString(blockedteam, "ct", true, false);
				team_blocked=2;
			}
			else if(StrEqual(sTeamBlocked, "CT", false)) 
			{
				SetConVarString(blockedteam, "t", true, false);
				team_blocked=3;
			}
			else if(StrEqual(sTeamBlocked, "NONE", false)) 
			{
				SetConVarString(blockedteam, "any", true, false);
				team_blocked=0;
			}
			
			IsMapConfigured = true;
		}
		else
		{
			if (!(team_blocked > 0))
			{
				team_blocked = 0;
				SetConVarString(blockedteam, "any", true, false);
			}
			
			IsMapConfigured = false;
		}
	}
	
	CloseHandle(hConfig);
}