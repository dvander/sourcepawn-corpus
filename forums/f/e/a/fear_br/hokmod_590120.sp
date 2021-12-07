/**
 * =============================================================================
 * HS or Kill Game Mod (HoK Mod)
 *
 * Wrote by F.E.A.R <emersonkfuri at gmail dot com>
 * Messages revision by SiRG
 * HoK Mod (C) 2008 F.E.A.R. All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Version 20080226
 */

#include <sourcemod>
#include <sdktools>

#define HOKMODVERSION "20080226"

public Plugin:myinfo =
{
	name = "HoK Mod",
	author = "F.E.A.R. <emersonkfuri@gmail.com>",
	description = "HS or Kill Game",
	version = HOKMODVERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("hokmod.phrases.txt")
	CreateConVar("hok_allowflashbang", "1", "Allow kills with flashbang", _, true, 0.0, true, 1.0)
	CreateConVar("hok_allowhegrenade", "1", "Allow kills with hegrenade", _, true, 0.0, true, 1.0)
	CreateConVar("hok_allowknife", "1", "Allow kills with knife", _, true, 0.0, true, 1.0)
	CreateConVar("hok_allowsmokegrenade", "1", "Allow kills with smoke grenade", _, true, 0.0, true, 1.0)
	CreateConVar("hok_autoshowhelp", "1", "Shows HoK Help to users automatically", _, true, 0.0, true, 1.0)
	CreateConVar("hok_enabled", "1", "Enable/Disable HoK Mod", FCVAR_NOTIFY, true, 0.0, true ,1.0)
	CreateConVar("hok_tkpunish", "1", "Punish TK with slay", _, true, 0.0, true, 1.0)
	CreateConVar("hok_version", HOKMODVERSION, "HoK Mod Version", FCVAR_REPLICATED, true, StringToFloat(HOKMODVERSION), true, StringToFloat(HOKMODVERSION))
	AutoExecConfig(true, "hokmod")
	HookEvent("player_death", HoK_Event_PlayerDeath, EventHookMode_Post)
	HookEvent("server_cvar", HoK_Event_ServercVar, EventHookMode_Post)
	RegConsoleCmd("say", HoK_userChat)
	RegConsoleCmd("say_team", HoK_userChat)
}

// Log plugin unload and warn users
public OnPluginEnd()
{
	LogMessage("[HoK] %t", "Mod Off")
	PrintToChatAll("[HoK] %t", "Mod Off")
	PrintHintTextToAll("[HoK] %t", "Mod Off")
}

// Displays help to new users
public OnClientPostAdminCheck(client)
{
	if ( GetConVarInt(FindConVar("hok_enabled")) && GetConVarInt(FindConVar("hok_autoshowhelp")) ) HoK_ShowHelp(client) 
}

// Core event for plugin
public Action:HoK_Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// HoK Mod is enabled?
	if ( GetConVarInt(FindConVar("hok_enabled")) )
	{
		new attackerId = GetEventInt(event, "attacker")
		new attacker = GetClientOfUserId(attackerId)
		// Attacker is alive?
		if ( IsPlayerAlive(attacker) )
		{
			new victimId = GetEventInt(event, "userid")
			// Was suicide?
			if ( attackerId != victimId )
			{
				new attackerTeam = GetClientTeam(attacker)
				decl String:attackerName[64]
				GetClientName(attacker, attackerName, sizeof(attackerName))
				new victim = GetClientOfUserId(victimId)
				new victimTeam = GetClientTeam(victim)
				// Was TK?
				if ( attackerTeam == victimTeam )
				{
					if ( GetConVarInt(FindConVar("hok_tkpunish")) )
					{
						ForcePlayerSuicide(attacker)
						PrintToChatAll("[HoK] %t", "Punishment for tk", attackerName)
						return Plugin_Continue
					}
				}
				else
				{
					// Weapons allowed in settings
					decl String:weapon[64]
					GetEventString(event, "weapon", weapon, sizeof(weapon))
					if ( StrEqual(weapon, "flashbang") )
					{
						if ( GetConVarInt(FindConVar("hok_allowflashbang")) )
						{
							return Plugin_Continue
						}
					}
					else if ( StrEqual(weapon, "hegrenade") )
					{
						if ( GetConVarInt(FindConVar("hok_allowhegrenade")) )
						{
							return Plugin_Continue
						}
					}
					else if ( StrEqual(weapon, "knife") )
					{
						if ( GetConVarInt(FindConVar("hok_allowknife")) )
						{
							return Plugin_Continue
						}
					}
					else if( StrEqual(weapon, "smokegrenade_projectile") )
					{
						if ( GetConVarInt(FindConVar("hok_allowsmokegrenade")) )
						{
							return Plugin_Continue
						}
					}
					if ( GetEventBool(event, "headshot") )
					{
						return Plugin_Continue
					}
					// Punishing player
					decl String:victimName[64]
					GetClientName(victim, victimName, sizeof(victimName))
					ForcePlayerSuicide(attacker)
					PrintToChatAll("[HoK] %t", "Punishment for no headshot", attackerName, victimName)
				}
			}
		}
	}
	return Plugin_Continue
}

// If conVar hok_enabled has change, log it and warn users
public HoK_Event_ServercVar(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:cVarName[64]
	GetEventString(event, "cvarname", cVarName, sizeof(cVarName))
	decl String:cVarValue[64]
	GetEventString(event, "cvarvalue", cVarValue, sizeof(cVarValue))
	if ( StrEqual(cVarName, "hok_enabled") )
	{
		if ( StringToInt(cVarValue) )
		{
			LogMessage("[HoK] %t", "Mod On")
			PrintToChatAll("[HoK] %t", "Mod On")
			PrintHintTextToAll("[HoK] %t", "Mod On running version", HOKMODVERSION)
			if ( GetConVarInt(FindConVar("hok_autoshowhelp")) ) HoK_ShowHelpToAll()
		}
		else if ( ! StringToInt(cVarValue) )
		{
			LogMessage("[HoK] %t", "Mod Off")
			PrintToChatAll("[HoK] %t", "Mod Off")
			PrintHintTextToAll("[HoK] %t", "Mod Off")
		}
	}
}

// Based on basechat.sp::Handler_DoNothing()
public HoK_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{

}

// Based on basechat.sp::SendPanelToAll()
HoK_SendPanel(client, String:title[], String:message[])
{
	new Handle:HoK_Panel = CreatePanel()
	SetPanelTitle(HoK_Panel, title)
	DrawPanelText(HoK_Panel, "------------------------")
	DrawPanelItem(HoK_Panel, "", ITEMDRAW_SPACER);
	DrawPanelText(HoK_Panel, message)
	DrawPanelItem(HoK_Panel, "", ITEMDRAW_SPACER);
	DrawPanelText(HoK_Panel, "------------------------")
	SetPanelCurrentKey(HoK_Panel, 10)
	DrawPanelItem(HoK_Panel, "Close", ITEMDRAW_CONTROL)
	SendPanelToClient(HoK_Panel, client, HoK_DoNothing, 10)
	CloseHandle(HoK_Panel)
}

// Displays about panel
HoK_ShowAbout(client)
{
	decl String:aboutTitle[256]
	Format(aboutTitle, sizeof(aboutTitle), "%t", "About Mod Title")
	decl String:aboutMessage[256]
	Format(aboutMessage, sizeof(aboutMessage), "%t", "About Mod", HOKMODVERSION)
	HoK_SendPanel(client, aboutTitle, aboutMessage)
}

// Displays help panel
HoK_ShowHelp(client)
{
	decl String:helpTitle[256]
	Format(helpTitle, sizeof(helpTitle), "%t", "Mod Help Title")
	decl String:helpMessage[256]
	Format(helpMessage, sizeof(helpMessage), "%t", "Mod Help")
	HoK_SendPanel(client, helpTitle, helpMessage)
}

// Displays help panel to all valid users
HoK_ShowHelpToAll()
{
	for(new client=1; client <= GetMaxClients(); client++) if( IsClientInGame(client) && ! IsFakeClient(client) ) HoK_ShowHelp(client)
}

// Displays rules panel 
HoK_ShowRules(client)
{
	decl String:rulesTitle[256]
	Format(rulesTitle, sizeof(rulesTitle), "%t", "Mod Rules Title")
	decl String:rulesMessage[256]
	Format(rulesMessage, sizeof(rulesMessage), "%t", "Mod Rules")
	HoK_SendPanel(client, rulesTitle, rulesMessage)
}

// Displays settings panel
HoK_ShowSettings(client)
{
	new hok_knife = GetConVarInt(FindConVar("hok_allowknife"))
	new hok_allowflashbang = GetConVarInt(FindConVar("hok_allowflashbang"))
	new hok_allowhegrenade = GetConVarInt(FindConVar("hok_allowhegrenade"))
	new hok_allowsmokegrenade = GetConVarInt(FindConVar("hok_allowsmokegrenade"))
	new hok_tkpunish = GetConVarInt(FindConVar("hok_tkpunish"))
	decl String:settingsTitle[256]
	Format(settingsTitle, sizeof(settingsTitle), "%t", "Mod Settings Title")
	decl String:settingsMessage[256]
	Format(settingsMessage, sizeof(settingsMessage), "%t", "Mod Settings", hok_knife, hok_allowflashbang, hok_allowhegrenade, hok_allowsmokegrenade, hok_tkpunish)
	decl String:settingsNo[256]
	Format(settingsNo, sizeof(settingsNo), "%t", "Mod Settings No")
	ReplaceString(settingsMessage, sizeof(settingsMessage), "0", settingsNo)
	decl String:settingsYes[256]
	Format(settingsYes, sizeof(settingsYes), "%t", "Mod Settings Yes")
	ReplaceString(settingsMessage, sizeof(settingsMessage), "1", settingsYes)
	HoK_SendPanel(client, settingsTitle, settingsMessage)
}

// Listen to users commands
public Action:HoK_userChat(client, args)
{
	if ( GetConVarInt(FindConVar("hok_enabled")) )
	{
		decl String:clientText[16];
		GetCmdArgString(clientText, sizeof(clientText))
		if ( IsChatTrigger() ) return Plugin_Continue
		ReplaceString(clientText, sizeof(clientText), "\"", "")
		if ( StrEqual(clientText, "!hok_about", false) ) HoK_ShowAbout(client)
		else if ( StrEqual(clientText, "!hok_help", false) ) HoK_ShowHelp(client)
		else if ( StrEqual(clientText, "!hok_rules", false) ) HoK_ShowRules(client)
		else if ( StrEqual(clientText, "!hok_settings", false) ) HoK_ShowSettings(client)
	}
	return Plugin_Continue
}
