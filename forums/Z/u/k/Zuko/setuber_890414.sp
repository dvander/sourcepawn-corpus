/*
 * Set Uber Charge Amount
 * 
 * Plugin allows admins to set uber charge amount.
 *
 * Commands:
 * sm_setuber	- Usage: <#userid|name> <amount>	Set über amount for given player
 * sm_sume		- Usage: <amount>					Set über for you
 * sm_autouber	- Usage: <#userid|name> <amount>	Set auto-über for given player
 *
 * ConVars:
 * setuber_version 			- Plugin Version
 * sm_setuber_enable 		- Enable/Disable Plugin				(0 = Off | 1 = On)					Default: "1"
 * sm_setuber_chat_notify 	- Chat Notifications 				(0 = Off | 1 = Target | 2 = All) 	Default: "1"
 * sm_autouber_chat_notify 	- Chat Notifications for Auto-Über 	(0 = Off | 1 = Target | 2 = All) 	Default: "1"
 *
 * Changelog:
 * Version 1.0 (05.08.2009)
 * - Initial Release
 *
 * Version 1.1 (27.08.2009)
 * - Fixed sm_setuber command targeting
 * - Added sm_sume command
 * - Minor changes in translations
 *
 * Version 1.2 (14.09.2009)
 * - Added sm_autouber
 * - Added colors to transaltions
 * - Minor fixes
 * - Minor changes in translations
 *
 * Version 1.3 (07.01.2010)
 * - Targeting bug fix
 *
 * Zuko / #hlds.pl @ Qnet / zuko.isports.pl /
 */
 
#include <sourcemod>
#include <colors>
#include <sdktools>

new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify_AutoUber = INVALID_HANDLE;

new bool:autouber_enabled[MAXPLAYERS+1] = false;
new Float:uber_amount[MAXPLAYERS+1] = 0.0;

/* Choose your access flag */
#define _ADMIN_FLAG_ ADMFLAG_KICK
/* * */

#define PLUGIN_VERSION		"1.3"

public Plugin:myinfo = 
{
	name = "[TF2] Set Uber Charge Amount",
	author = "Zuko",
	description = "Set Uber Charge Amount.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("setuber_version", PLUGIN_VERSION, "Set Uber Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Cvar_PluginEnable = CreateConVar("sm_setuber_enable", "1", "Enable/Disable Plugin", _, true, 0.0, true, 1.0);
	g_Cvar_ChatNotify = CreateConVar("sm_setuber_chat_notify", "1", "Chat Notifications", _, true, 0.0, true, 2.0);
	g_Cvar_ChatNotify_AutoUber = CreateConVar("sm_autouber_chat_notify", "1", "Chat Notifications For Auto-Uber",	_, true, 0.0, true, 2.0);
	
	RegAdminCmd("sm_setuber", Command_SetUber, _ADMIN_FLAG_, "sm_setuber <#userid|name> <amount>");
	RegAdminCmd("sm_sume", Command_SetUberMe, _ADMIN_FLAG_, "sm_sume <amount>");
	RegAdminCmd("sm_autouber", Command_AutoUber, _ADMIN_FLAG_, "sm_autouber <#userid|name> <amount>");
	
	
	LoadTranslations("common.phrases");
	LoadTranslations("setuber.phrases");
	
	AutoExecConfig(true, "plugin.setuber");
	
	/* Hook Events */
	HookEvent("player_spawn", EventPlayerSpawn);
}

public OnClientPostAdminCheck(client)
{
	autouber_enabled[client] = false;
	uber_amount[client] = 0.0;
}

public OnClientDisconnect(client)
{
	autouber_enabled[client] = false;
	uber_amount[client] = 0.0;
}

 /* SetUber on Me */
public Action:Command_SetUberMe(client, args)
{
	new Float:nUber;
	new iAmount;
	
	decl String:amount[10]
	
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %t", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] %t", "PluginUsage_SetUber_Me", LANG_SERVER);
		return Plugin_Handled;	
	}
	else
	{
		GetCmdArg(1, amount, sizeof(amount));
		nUber = StringToFloat(amount);
		iAmount = StringToInt(amount);
	}
	
	if (nUber < 0)
	{
		nUber = 0.0;
		ReplyToCommand(client, "[SM] %t", "UberAmount1", LANG_SERVER);
	}
	
	if (nUber > 100)
	{
		nUber = 100.0;
		ReplyToCommand(client, "[SM] %t", "UberAmount2", LANG_SERVER);
	}
	
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
		{
			TF_SetUberLevel(client, nUber);
			ReplyToCommand(client, "[SM] %t", "UberSetOnMe", LANG_SERVER, iAmount);
		}
		else
		ReplyToCommand(client, "[SM] %t", "MustBeMedic2", LANG_SERVER);
	}
	return Plugin_Handled;
}
/* >>> end of SetUber on Me */

/* SetUber */
public Action:Command_SetUber(client, args)
{
	new Float:nUber;
	new iAmount;
	
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %t", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
		
	decl String:target[MAXPLAYERS], String:amount[10], String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] %t", "PluginUsage", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, amount, sizeof(amount));
		nUber = StringToFloat(amount);
		iAmount = StringToInt(amount);
	}

	if (nUber < 0)
	{
		nUber = 0.0;
		ReplyToCommand(client, "[SM] %t", "UberAmount1", LANG_SERVER);
	}
	
	if (nUber > 100)
	{
		nUber = 100.0;
		ReplyToCommand(client, "[SM] %t", "UberAmount2", LANG_SERVER);
	}
	
	if (target[client] == -1)
	{
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (GetEntProp(target_list[i], Prop_Send, "m_iClass") == 5)
		{
			TF_SetUberLevel(target_list[i], nUber);
		
			switch(GetConVarInt(g_Cvar_ChatNotify))
			{
				case 0:
					return Plugin_Continue;
				case 1:
					CPrintToChat(target_list[i], "{lightgreen} [SM] %T", "UberPhrase1", LANG_SERVER, client, iAmount);
				case 2:
					CPrintToChatAll("{lightgreen}[SM] %T", "UberPhrase2", LANG_SERVER, client, target_list[i], iAmount);
			}
			ReplyToCommand(client, "[SM] %T", "UberPhrase3", LANG_SERVER, target_list[i], iAmount);
		}
		else
		ReplyToCommand(client, "[SM] %t", "MustBeMedic", LANG_SERVER)
	}	
	return Plugin_Handled;
}
/* >>> end of SetUber on Me */

/* AutoSetUber */
public Action:Command_AutoUber(client, args)
{
	new Float:nUber;
	new iAmount;
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %t", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
		
	decl String:target[MAXPLAYERS], String:amount[10], String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] %t", "PluginUsage_AutoUber", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, amount, sizeof(amount));
		nUber = StringToFloat(amount);
		iAmount = StringToInt(amount);
	}

	if (nUber < 0)
	{
		nUber = 0.0;
		ReplyToCommand(client, "[SM] %t", "UberAmount1", LANG_SERVER);
	}
	
	if (nUber > 100)
	{
		nUber = 100.0;
		ReplyToCommand(client, "[SM] %t", "UberAmount2", LANG_SERVER);
	}
		
	if (target[client] == -1)
	{
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			MAX_TARGET_LENGTH,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (GetEntProp(target_list[i], Prop_Send, "m_iClass") == 5)
		{
			if (IsClientConnected(target_list[i]) && IsClientInGame(target_list[i]))
			{
				autouber_enabled[target_list[i]] = true;
				uber_amount[target_list[i]] = nUber;
				
				if (IsPlayerAlive(target_list[i]))
				{
					TF_SetUberLevel(target_list[i], nUber);
				}
				if (client == target_list[i])
				{
					if (nUber == 0.0)
					{
						ReplyToCommand(client, "[SM] %t", "AutoUberReply1", LANG_SERVER);
					}
					else
					ReplyToCommand(client, "[SM] %t", "AutoUberReply2", LANG_SERVER, iAmount);
				}
				else if (nUber == 0.0)
				{
					ReplyToCommand(client, "[SM] %t", "AutoUberReply3", LANG_SERVER, target_list[i]);
				}
				else
				ReplyToCommand(client, "[SM] %t", "AutoUberReply4", LANG_SERVER, target_list[i], iAmount);
					
				switch(GetConVarInt(g_Cvar_ChatNotify_AutoUber))
				{
					case 0:
						return Plugin_Continue;
					case 1:
					{
						if (client == target_list[i])
						{	
							if (nUber == 0.0)
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoUberPhrase4", LANG_SERVER);
							}
							else
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoUberPhrase3", LANG_SERVER);
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoUberPhrase3a", LANG_SERVER, iAmount);
							}
						}
						else
						{
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoUberPhrase1", LANG_SERVER, client);
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoUberPhrase1a", LANG_SERVER, iAmount);
						}
					}
					case 2:
					{
						if (nUber == 0.0)
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoUberPhrase5", LANG_SERVER, client, target_list[i]);
						}
						else
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoUberPhrase2", LANG_SERVER, client, target_list[i]);
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoUberPhrase2a", LANG_SERVER, iAmount);
						}
					}
				}
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "MustBeMedic", LANG_SERVER);
		}
	}	
	return Plugin_Handled;
}
/* >>> end of AutoSetUber */

/* Events */
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:UberAmount = 0.0;
	
	if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
	{
		if (autouber_enabled[client] == true)
		{
			UberAmount = uber_amount[client];
			if (UberAmount == 0.0)
			{
				autouber_enabled[client] = false;
				return Plugin_Handled;
			}
			else
			{
				TF_SetUberLevel(client, UberAmount)
			}
		}
	}
	else
	{
		autouber_enabled[client] = false;
		uber_amount[client] = 0.0;
	}
	return Plugin_Continue;
}
/* >>> end of Events */

stock TF_SetUberLevel(client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}