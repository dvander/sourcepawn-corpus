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
#pragma semicolon 1 
 
int warnings[MAXPLAYERS+1]; 
int roundwarnings[MAXPLAYERS+1]; 

ConVar sm_warn_maxwarnings_enabled = null;
ConVar sm_warn_maxwarnings = null;
ConVar sm_warn_maxwarnings_reset = null;
ConVar sm_warn_banduration = null;
ConVar sm_warn_maxroundwarnings = null;
 
public Plugin myinfo =
{
	name = "Simple Warnings",
	author = "Potatoz",
	description = "Allows Admins to warn players",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};


public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_warn", Command_Warn, ADMFLAG_BAN);
	
	RegAdminCmd("sm_resetwarnings", Command_ResetWarnings, ADMFLAG_ROOT);
	RegConsoleCmd("sm_warnings", Command_Warnings);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	sm_warn_maxwarnings_enabled = CreateConVar("sm_warn_maxwarnings_enabled", "1", "Enable automatic ban after max amount of warnings reached? 1 = Enabled 0 = Disabled, Default = 1");
	sm_warn_maxwarnings = CreateConVar("sm_warn_maxwarnings", "0", "Max amount of total warnings before banning a player (if enabled), 0 = Disabled, Default = 0");
	sm_warn_maxwarnings_reset = CreateConVar("sm_warn_maxwarnings_reset", "1", "Reset warnings after automatic ban? 1 = Enabled 0 = Disabled, Default = 1");
	sm_warn_banduration = CreateConVar("sm_warn_banduration", "15", "How long shall a player be banned after recieving max amount of warnings (in minutes)? Default = 15");
	sm_warn_maxroundwarnings = CreateConVar("sm_warn_maxroundwarnings", "3", "Max amount of warnings in a single round before banning a player (if enabled), Default = 3");
	AutoExecConfig(true, "plugin_simplewarnings");
}

public OnClientPutInServer(int client) 
{
	if(warnings[client] > 0)
    CreateTimer(1.0, WarningsNotify, client);
}

public OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{ 
    for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			roundwarnings[i] = 0;
		}
	}
}  

public Action WarningsNotify(Handle timer, any client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (CheckCommandAccess(i, "PRINT_ONLY_TO_ADMIN", ADMFLAG_GENERIC, true)) {
				if(i != client) PrintToChat(i, " \x07* WARNING:\x01 Player\x07 %N\x01 has \x07%d \x01warning(s) on record.", client, warnings[client]);
			}
		}
	}
}

public Action Command_Warn(int client, int args)
{
	if(args < 2) {
	ReplyToCommand(client, "[SM] Usage: sm_warn <name|#userid> [reason]");
	return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int target = FindTarget(client, arg1);
	if (target == -1)
		return Plugin_Handled;
	
	if(target == client) {
	PrintToChat(client, " \x07*\x01 You can't warn yourself!");
	return Plugin_Handled;
	}
	
	warnings[target]++;
	roundwarnings[target]++;
	PrintToChat(client, " \x07*\x01 You have warned \x07%N \x01for reason: %s", target, arg2);
	PrintToChat(target, " \x07*\x01 You have been warned by \x07%N \x01for reason: %s", client, arg2);
	PrintToChat(target, " \x07*\x01 You currently have \x07%d \x01warning(s).", warnings[target]);
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (CheckCommandAccess(i, "PRINT_ONLY_TO_ADMIN", ADMFLAG_GENERIC, true)) {
				if(i != client) PrintToChat(i, " \x07* %N\x01 has warned \x07%N \x01for reason: %s", client, target, arg2);
			}
		}
	}
	
	LogAction(client, target, "\"%N\" warned \"%N\" (reason: %s)", client, target, arg2);
	
	if(GetConVarInt(sm_warn_maxwarnings_enabled) == 1) {
		if(roundwarnings[target] >= GetConVarInt(sm_warn_maxroundwarnings)) 
		{
			if(GetConVarInt(sm_warn_maxwarnings_reset) == 1) 
			{
				warnings[target] = 0;
				roundwarnings[target] = 0;
			}
			
			BanClient(target, GetConVarInt(sm_warn_banduration), BANFLAG_AUTO, "S-WARN: Too many Warnings", "Too many warnings in one round.");
		} 
		else if(warnings[target] >= GetConVarInt(sm_warn_maxwarnings) && GetConVarInt(sm_warn_maxwarnings) != 0) 
		{
			if(GetConVarInt(sm_warn_maxwarnings_reset) == 1) 
			{
				warnings[target] = 0;
				roundwarnings[target] = 0;
			}
			
			BanClient(target, GetConVarInt(sm_warn_banduration), BANFLAG_AUTO, "S-WARN: Too many Warnings", "Too many total warnings.");
		}
	} 
	
	return Plugin_Handled;
}

public Action Command_ResetWarnings(int client, int args)
{
	if(args < 1) {
	ReplyToCommand(client, "[SM] Usage: sm_resetwarnings <name|#userid>");
	return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = FindTarget(client, arg1);
	if (target == -1)
		return Plugin_Handled;
	
	PrintToChat(client, " \x07*\x01 You have reset \x07%N \x01warning(s).", target);
	PrintToChat(target, " \x07* %N \x01 has reset your warning(s)", client);
	warnings[target] = 0;
	roundwarnings[target] = 0;
	
	return Plugin_Handled;
}

public Action Command_Warnings(int client, int args)
{
	if(args < 1) {
	ReplyToCommand(client, "[SM] Usage: sm_warnings <name|#userid>");
	return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = FindTarget(client, arg1);
	if (target == -1)
		return Plugin_Handled;
	
	PrintToChat(client, " \x07* %N\x01 has \x07%d \x01warning(s) on record.", target, warnings[target]);
	
	return Plugin_Handled;
}