#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.11"

/* ChangeLog
1.00	Proof of Concept for ZombieSpy's Carrier/Infeced Comunication suggestion, http://www.zombiepanic.org/forums/showthread.php?t=12787
1.10	Added handeling for Client 0
1.11	Replaced PrintToChat with ReplyToCommand
*/

public Plugin:myinfo = {
	name = "Infected Chat",
	author = "Will2Tango",
	description = "Proof of concept: Allows Carrier and Infected Survivors to Communicate.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1212614"
}

new Handle:secretmsg = INVALID_HANDLE;
new IsInfectedOffset = -1;

public OnPluginStart()
{
	CreateConVar("sm_infectedchat_version", PLUGIN_VERSION, "Infected Chat Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	secretmsg = CreateConVar("sm_infected_chat", "1", "Enable Infected Chat.");
	RegConsoleCmd("sm_infchat", Command_InfectedMessage, "Chat to Infected or Carrier.", FCVAR_PLUGIN);
	IsInfectedOffset = FindSendPropInfo("CHL2MP_Player", "m_IsInfected");	//Thank you Sammy-ROCK (Pills Cure)
	HookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy);
}

public NewRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(30.0, TellCarrier);
}

public Action:Command_InfectedMessage(client, args)
{
	if (!GetConVarBool(secretmsg))
	{
		ReplyToCommand(client, "This command has been dissabled.");
		return Plugin_Handled;
	}
	else if(args < 1 || client == 0)
	{
		ReplyToCommand(client, "Usage !infchat <message> \nNote: you can only use this command as the Carrier or Infected.");
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) == 2 && GetEntData(client, IsInfectedOffset))
	{
		new String:clientName[64], String:message[192];
		GetCmdArgString(message, sizeof(message));
		GetClientName(client, clientName, sizeof(clientName));
		
		PrintToChat(client, "\x04%s\x01: !infchat %s.", clientName, message);
		
		for (new p = 1; p <= MaxClients; p++)
		{
			if (IsClientInGame(p) && GetClientTeam(p) == 3)
			{
				decl String:attWeapon[32];
				GetClientWeapon(p, attWeapon, sizeof(attWeapon));
				if (StrEqual("weapon_carrierarms",attWeapon))
				{
					PrintToChat(p, "\x04[Infected-%s]\x01: %s", clientName, message);
				}
			}	
		}
	}
	else if(GetClientTeam(client) == 3)
	{
		new String:clientName[64], String:message[192];
		GetCmdArgString(message, sizeof(message));
		GetClientName(client, clientName, sizeof(clientName));
		
		PrintToChat(client, "\x04%s\x01: !infchat %s", clientName, message);
		
		decl String:attWeapon[32];
		GetClientWeapon(client, attWeapon, sizeof(attWeapon));
		
		if (StrEqual("weapon_carrierarms",attWeapon))
		{		
			for (new p = 1; p <= MaxClients; p++)
			{
				if (IsClientInGame(p) && GetClientTeam(p) == 2 && GetEntData(p, IsInfectedOffset))
				{
					PrintToChat(p, "\x04[Carrier-%s]\x01: %s \nTo reply say !infchat <message> in chat.)", clientName, message);
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:TellCarrier(Handle:timer)
{
	for (new p = 1; p <= MaxClients; p++)
	{
		if (IsClientInGame(p) && GetClientTeam(p) == 3)
		{
			decl String:attWeapon[32];
			GetClientWeapon(p, attWeapon, sizeof(attWeapon));
			if (StrEqual("weapon_carrierarms",attWeapon))
			{
				PrintToChat(p, "\x04[Infected Chat]\x01 If you Infect a Survivor you can message them by saying \x04!infchat <message>\x01 in chat.");
			}
		}	
	}
	return Plugin_Stop;
}