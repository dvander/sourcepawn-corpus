/*
	Revision 1.0.3
	---
	Added cvar sm_fly_notify, which issues admin notifications if this is used as an admin plugin.
	Added cvar sm_fly_commands, which lets users set their own chat triggers to access fly.
	Improved auth logic.	
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.3"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hOverride = INVALID_HANDLE;
new Handle:g_hFlag = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;

new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bPublic, bool:g_bNotify, String:g_sOverride[32], g_iFlag, String:g_sChatCommands[16][32], g_iNumCommands;

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bAccess[MAXPLAYERS + 1];
new bool:g_bFlying[MAXPLAYERS + 1];
new bool:g_bPaused[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Fly Command",
	author = "Twisted|Panda",
	description = "Provides the !fly&/fly command, which allows the player to soar like a severely injured eagle.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_fly_version", PLUGIN_VERSION, "Fly Command: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_fly_enabled", "1", "Enables/disables the ability to use the sm_fly command.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hOverride = CreateConVar("sm_fly_override", "Command_Fly", "The override checked for access to use the sm_fly command. Set to \"\" to allow anyone to use the command.", FCVAR_NONE);
	HookConVarChange(g_hOverride, OnSettingsChange);
	g_hFlag = CreateConVar("sm_fly_flag", "b", "The flag to check if a user does not have access to the provided override. Set to \"\" to allow anyone to use the command.", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnSettingsChange);
	g_hNotify = CreateConVar("sm_fly_notify", "1", "If enabled (and a valid override/flag is set), the plugin will spit notifications and logs about sm_fly usage.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hNotify, OnSettingsChange);
	g_hChatCommands = CreateConVar("sm_fly_commands", "!fly, /fly", "The chat triggers available to clients to access fly.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);
	AutoExecConfig(true, "sm_fly");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	RegConsoleCmd("sm_fly", Command_Fly);
	
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

	decl String:_sTemp[192];
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	GetConVarString(g_hOverride, g_sOverride, sizeof(g_sOverride));
	GetConVarString(g_hFlag, _sTemp, sizeof(_sTemp));
	g_iFlag = ReadFlagString(_sTemp);	
	g_bNotify = GetConVarInt(g_hNotify) ? true : false;
	g_bPublic = (StrEqual(g_sOverride, "") || !g_iFlag) ? true : false;
	GetConVarString(g_hChatCommands, _sTemp, sizeof(_sTemp));
	g_iNumCommands = ExplodeString(_sTemp, ", ", g_sChatCommands, 16, 32);
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					g_bAccess[i] = g_bPublic ? true : CheckCommandAccess(i, g_sOverride, g_iFlag);
				}
			}
		}

		g_bLateLoad = false;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_bEnabled)
	{
		if(g_bAlive[client] && g_iTeam[client] >= 2 && g_bFlying[client])
		{
			if(buttons & IN_SPEED)
			{
				new Float:_fVelocity[3];
				SetEntityMoveType(client, MOVETYPE_NONE);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVelocity);
				g_bPaused[client] = true;
			}
			else if(g_bPaused[client])
			{
				g_bPaused[client] = false;
				SetEntityMoveType(client, MOVETYPE_FLY);	
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = g_bAccess[client] = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		g_bAccess[client] = g_bPublic ? true : CheckCommandAccess(client, g_sOverride, g_iFlag);
	}
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && g_bFlying[i])
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
				g_bFlying[i] = g_bPaused[i] = false;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1)
			return Plugin_Continue;

		g_bAlive[client] = true;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] == 1)
		{
			g_bAlive[client] = false;
			if(g_bFlying[client])
				g_bFlying[client] = g_bPaused[client] = false;
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_bAlive[client] = false;
		if(g_bFlying[client])
			g_bFlying[client] = g_bPaused[client] = false;
	}

	return Plugin_Continue;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled && client > 0)
	{
		decl String:_sText[192];
		GetCmdArgString(_sText, 192);
		StripQuotes(_sText);

		if(g_bAccess[client] && g_iTeam[client] >= 2)
		{
			for(new i = 0; i < g_iNumCommands; i++)
			{
				if(StrEqual(_sText, g_sChatCommands[i], false))
				{
					g_bPaused[client] = false;
					if(g_bFlying[client])
					{
						new Float:_fVelocity[3];
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVelocity);
						SetEntityMoveType(client, MOVETYPE_WALK);
					}
					else
						SetEntityMoveType(client, MOVETYPE_FLY);
					
					g_bFlying[client] = !g_bFlying[client];
			
					if(!g_bPublic && g_bNotify)
					{
						ShowActivity2(client, "[SM] ", "%N %s his/her flying state.", client, g_bFlying[client] ? "enabled" : "disabled");
						LogAction(client, -1, "%L %s his/her flying state.", client, g_bFlying[client] ? "enabled" : "disabled");
					}
					return Plugin_Stop;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Fly(client, argc)
{
	if(g_bEnabled && client > 0)
	{
		if(g_bAccess[client] && g_iTeam[client] >= 2)
		{
			g_bPaused[client] = false;
			if(g_bFlying[client])
			{
				new Float:_fVelocity[3];
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVelocity);
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			else
				SetEntityMoveType(client, MOVETYPE_FLY);
			
			g_bFlying[client] = !g_bFlying[client];
			
			if(!g_bPublic && g_bNotify)
			{
				ShowActivity2(client, "[SM] ", "%N %s his/her flying state.", client, g_bFlying[client] ? "enabled" : "disabled");
				LogAction(client, -1, "%L %s his/her flying state.", client, g_bFlying[client] ? "enabled" : "disabled");
			}
		}
	}
	return Plugin_Handled;
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hFlag)
	{
		g_iFlag = ReadFlagString(newvalue);
		g_bPublic = (StrEqual(g_sOverride, "") || !g_iFlag) ? true : false;
	}
	else if(cvar == g_hOverride)
	{
		strcopy(g_sOverride, sizeof(g_sOverride), newvalue);
		g_bPublic = (StrEqual(g_sOverride, "") || !g_iFlag) ? true : false;
	}
	else if(cvar == g_hNotify)
		g_bNotify = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
}