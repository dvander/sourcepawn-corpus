/*
 * Set Soldiers Rage Amount
 * 
 * Plugin allows admins to set rage amount.
 *
 * Commands:
 * sm_setrage	- Usage: <#userid|name> <amount>	Set rage amount for given player
 * sm_rgme		- Usage: <amount>					Set rage for you
 * sm_autorage	- Usage: <#userid|name> <amount>	Set auto-rage for given player
 *
 * ConVars:
 * setuber_version 			- Plugin Version
 * sm_setrage_enable 		- Enable/Disable Plugin				(0 = Off | 1 = On)					Default: "1"
 * sm_setrage_chat_notify 	- Chat Notifications 				(0 = Off | 1 = Target | 2 = All) 	Default: "1"
 * sm_autorage_chat_notify 	- Chat Notifications for Auto-Rage 	(0 = Off | 1 = Target | 2 = All) 	Default: "1"
 *
 * Changelog:
 * Version 1.0 (05.08.2009)
 * - Initial Release
 *
 * Zuko / #hlds.pl @ Qnet / zuko.isports.pl /
 */
 
#include <sourcemod>
#include <colors>
#include <sdktools>

new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify_AutoRage = INVALID_HANDLE;

new bool:autorage_enabled[MAXPLAYERS+1] = false;
new Float:rage_amount[MAXPLAYERS+1] = 0.0;

/* Choose your access flag */
#define _ADMIN_FLAG_ ADMFLAG_KICK
/* * */

#define PLUGIN_VERSION		"1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Set Soldier Rage Amount",
	author = "Zuko",
	description = "Set Soldier Rage Amount.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("setrage_version", PLUGIN_VERSION, "Set Rage Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Cvar_PluginEnable = CreateConVar("sm_setrage_enable", "1", "Enable/Disable Plugin", _, true, 0.0, true, 1.0);
	g_Cvar_ChatNotify = CreateConVar("sm_setrage_chat_notify", "1", "Chat Notifications", _, true, 0.0, true, 2.0);
	g_Cvar_ChatNotify_AutoRage = CreateConVar("sm_autorage_chat_notify", "1", "Chat Notifications For Auto-Rage",	_, true, 0.0, true, 2.0);
	
	RegAdminCmd("sm_setrage", Command_SetRage, _ADMIN_FLAG_, "sm_setrage <#userid|name> <amount>");
	RegAdminCmd("sm_rgme", Command_SetRageMe, _ADMIN_FLAG_, "sm_rgme <amount>");
	RegAdminCmd("sm_autorage", Command_AutoRage, _ADMIN_FLAG_, "sm_autorage <#userid|name> <amount>");

	LoadTranslations("common.phrases");
	LoadTranslations("setrage.phrases");
	
	AutoExecConfig(true, "plugin.setrage");
	
	/* Hook Events */
	HookEvent("player_spawn", EventPlayerSpawn);
}

public OnClientPostAdminCheck(client)
{
	autorage_enabled[client] = false;
	rage_amount[client] = 0.0;
}

public OnClientDisconnect(client)
{
	autorage_enabled[client] = false;
	rage_amount[client] = 0.0;
}

 /* SetUber on Me */
public Action:Command_SetRageMe(client, args)
{
	new Float:nRage;
	new iAmount;
	
	decl String:amount[10]
	
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %t", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] %t", "PluginUsage_SetRage_Me", LANG_SERVER);
		return Plugin_Handled;	
	}
	else
	{
		GetCmdArg(1, amount, sizeof(amount));
		nRage = StringToFloat(amount);
		iAmount = StringToInt(amount);
	}
	
	if (nRage < 0)
	{
		nRage = 0.0;
		ReplyToCommand(client, "[SM] %t", "RageAmount1", LANG_SERVER);
	}
	
	if (nRage > 100)
	{
		nRage = 100.0;
		ReplyToCommand(client, "[SM] %t", "RageAmount2", LANG_SERVER);
	}
	
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (GetEntProp(client, Prop_Send, "m_iClass") == 3)
		{
			TF_SetRageAmount(client, nRage);
			ReplyToCommand(client, "[SM] %t", "RageSetOnMe", LANG_SERVER, iAmount);
		}
		else
		ReplyToCommand(client, "[SM] %t", "MustBeSoldier2", LANG_SERVER);
	}
	return Plugin_Handled;
}
/* >>> end of SetUber on Me */

/* SetUber */
public Action:Command_SetRage(client, args)
{
	new Float:nRage;
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
		nRage = StringToFloat(amount);
		iAmount = StringToInt(amount);
	}

	if (nRage < 0)
	{
		nRage = 0.0;
		ReplyToCommand(client, "[SM] %t", "RageAmount1", LANG_SERVER);
	}
	
	if (nRage > 100)
	{
		nRage = 100.0;
		ReplyToCommand(client, "[SM] %t", "RageAmount2", LANG_SERVER);
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
		if (GetEntProp(client, Prop_Send, "m_iClass") == 3)
		{
			TF_SetRageAmount(target_list[i], nRage);
		
			switch(GetConVarInt(g_Cvar_ChatNotify))
			{
				case 0:
					return Plugin_Continue;
				case 1:
					CPrintToChat(target_list[i], "{lightgreen} [SM] %T", "RagePhrase1", LANG_SERVER, client, iAmount);
				case 2:
					CPrintToChatAll("{lightgreen}[SM] %T", "RagePhrase2", LANG_SERVER, client, target_list[i], iAmount);
			}
			ReplyToCommand(client, "[SM] %T", "RagePhrase3", LANG_SERVER, target_list[i], iAmount);
		}
		else
		ReplyToCommand(client, "[SM] %t", "MustBeSoldier", LANG_SERVER)
	}	
	return Plugin_Handled;
}
/* >>> end of SetUber on Me */

/* AutoSetUber */
public Action:Command_AutoRage(client, args)
{
	new Float:nRage;
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
		ReplyToCommand(client, "[SM] %t", "PluginUsage_AutoRage", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, amount, sizeof(amount));
		nRage = StringToFloat(amount);
		iAmount = StringToInt(amount);
	}

	if (nRage < 0)
	{
		nRage = 0.0;
		ReplyToCommand(client, "[SM] %t", "RageAmount1", LANG_SERVER);
	}
	
	if (nRage > 100)
	{
		nRage = 100.0;
		ReplyToCommand(client, "[SM] %t", "RageAmount2", LANG_SERVER);
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
		if (GetEntProp(client, Prop_Send, "m_iClass") == 3)
		{
			if (IsClientConnected(target_list[i]) && IsClientInGame(target_list[i]))
			{
				autorage_enabled[target_list[i]] = true;
				rage_amount[target_list[i]] = nRage;
				
				if (IsPlayerAlive(target_list[i]))
				{
					TF_SetRageAmount(target_list[i], nRage);
				}
				if (client == target_list[i])
				{
					if (nRage == 0.0)
					{
						ReplyToCommand(client, "[SM] %t", "AutoRageReply1", LANG_SERVER);
					}
					else
					ReplyToCommand(client, "[SM] %t", "AutoRageReply2", LANG_SERVER, iAmount);
				}
				else if (nRage == 0.0)
				{
					ReplyToCommand(client, "[SM] %t", "AutoRageReply3", LANG_SERVER, target_list[i]);
				}
				else
				ReplyToCommand(client, "[SM] %t", "AutoRageReply4", LANG_SERVER, target_list[i], iAmount);
					
				switch(GetConVarInt(g_Cvar_ChatNotify_AutoRage))
				{
					case 0:
						return Plugin_Continue;
					case 1:
					{
						if (client == target_list[i])
						{	
							if (nRage == 0.0)
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoRagePhrase4", LANG_SERVER);
							}
							else
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoRagePhrase3", LANG_SERVER);
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoRagePhrase3a", LANG_SERVER, iAmount);
							}
						}
						else
						{
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoRagePhrase1", LANG_SERVER, client);
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoRagePhrase1a", LANG_SERVER, iAmount);
						}
					}
					case 2:
					{
						if (nRage == 0.0)
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoRagePhrase5", LANG_SERVER, client, target_list[i]);
						}
						else
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoRagePhrase2", LANG_SERVER, client, target_list[i]);
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoRagePhrase2a", LANG_SERVER, iAmount);
						}
					}
				}
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "MustBeSoldier", LANG_SERVER);
		}
	}	
	return Plugin_Handled;
}
/* >>> end of AutoSetUber */

/* Events */
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:RageAmount = 0.0;
	
	if (GetEntProp(client, Prop_Send, "m_iClass") == 3)
	{
		if (autorage_enabled[client] == true)
		{
			RageAmount = rage_amount[client];
			if (RageAmount == 0.0)
			{
				autorage_enabled[client] = false;
				return Plugin_Handled;
			}
			else
			{
				TF_SetRageAmount(client, RageAmount)
			}
		}
	}
	else
	{
		autorage_enabled[client] = false;
		rage_amount[client] = 0.0;
	}
	return Plugin_Continue;
}
/* >>> end of Events */

stock TF_SetRageAmount(client, Float:rageamount)
{
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rageamount);
}