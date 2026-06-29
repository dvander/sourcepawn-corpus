/*
botdropbomb.sp

Description:
	Drop the Bomb Plugin for SourceMod.  Lets players tell nearby bots to drop the bomb so they can complete their objectives.
	
Credits:
	Thanks to everyone in the scripting forum.  You guys have been super supportive of all my questions.

Versions:
	1.0
		* Initial Release
		
	1.1
		* Added an admin command sm_dropbomb
		

*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Bot, drop the bomb",
	author = "dalto",
	description = "Lets players tell nearby bots to drop the bomb so they can complete their objectives.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Global Variables
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hDropWeapon = INVALID_HANDLE;

public OnPluginStart()
{
	// Create the CVARs
	CreateConVar("sm_bot_drop_bomb_version", PLUGIN_VERSION, "Bot, drop the bomb Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Load the gamedata file
	hGameConf = LoadGameConfigFile("botdropbomb.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/botdropbomb.games.txt not loadable");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hDropWeapon = EndPrepSDKCall();

	RegConsoleCmd("say", CommandSay);
	RegConsoleCmd("say_team", CommandSay);
	RegAdminCmd("sm_dropbomb", CommandDropBomb, ADMFLAG_GENERIC);
}

public Action:CommandSay(client, args)
{
	if(client < 1 || client > GetMaxClients() || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}	

	// Get the command argument
	new String:buffer[20];
	decl String:buffer2[20];
	
	for(new i = 0; i < args; i++)
	{
		GetCmdArg(i + 1, buffer2, sizeof(buffer2));
		if(buffer[0] == 0)
		{
			buffer = buffer2;
		} else {
			Format(buffer, sizeof(buffer), "%s %s", buffer, buffer2);
		}
	}
		
	if(strcmp(buffer, "drop the bomb") == 0)
	{
		new team = GetClientTeam(client);
		new Float:clientVec[3];
		GetClientAbsOrigin(client, clientVec);
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsClientInGame(i) && IsFakeClient(i) && GetPlayerWeaponSlot(i, 4) != -1 && GetClientTeam(i) == team)
			{
				new Float:botVec[3];
				GetClientAbsOrigin(i, botVec);
				if(GetVectorDistance(clientVec, botVec) < 750)
				{
					SDKCall(hDropWeapon, i, GetPlayerWeaponSlot(i, 4), false, false);
				}
			}
		}
	}	
	return Plugin_Continue;
}

public Action:CommandDropBomb(client, args)
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && GetPlayerWeaponSlot(i, 4) != -1)
		{
			SDKCall(hDropWeapon, i, GetPlayerWeaponSlot(i, 4), false, false);
		}
	}

	return Plugin_Handled;
}