//
// SourceMod Script
//
// Developed by <eVa>Dog
// May 2008
// http://www.theville.org
//
// Adapted for SourceMod from
// FeuerSturm's AMX dod_adminsentinel script
// 
// Admin Menu adapted from SourceMod team's Wiki
//
// USE:
// sm_enemyvoice   = enable/disable hearing enemy's voicecomm
// sm_talktoserver = enable/disable an admin's ability to talk to whole server
// sm_adminchat    = enable admin only chat - affects ALL admins

// CONSOLE VARIABLES
// If enabled, admins automatically have the plugin turned on when joining
// sv_admin_sentinel_startup = <1|0> 

// DESCRIPTION:
// This plugin lets admins see enemy's teamchat and hear enemy's voicecomm.

//
// CHANGELOG:
// - 05.30.2008 Version 1.0.100
//   Initial Release

// - 05.31.2008 Version 1.0.101
//   Added AdminMenu
//	 Added Command help info
//   Added Talk to entire server feature



#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.102"

#define SPEAK_NORMAL           0
#define SPEAK_MUTED            1
#define SPEAK_ALL              2
#define SPEAK_LISTENALL        4
#define SPEAK_TALKLISTENALL    6

/*
	Set Admin Level to one of these
		ADMFLAG_RESERVATION
		ADMFLAG_GENERIC
		ADMFLAG_KICK
		ADMFLAG_BAN
		ADMFLAG_UNBAN
		ADMFLAG_SLAY
		ADMFLAG_CHANGEMAP
		ADMFLAG_CONVARS
		ADMFLAG_CONFIG
		ADMFLAG_CHAT
		ADMFLAG_VOTE
		ADMFLAG_PASSWORD
		ADMFLAG_RCON
		ADMFLAG_CHEATS
		ADMFLAG_ROOT
		ADMFLAG_CUSTOM1
		ADMFLAG_CUSTOM2
		ADMFLAG_CUSTOM3
		ADMFLAG_CUSTOM4
		ADMFLAG_CUSTOM5
		ADMFLAG_CUSTOM6
*/

#define ADMIN_LEVEL ADMFLAG_CUSTOM1
#define ADMIN_CHAT ADMFLAG_CUSTOM1

new g_EnemyVoice[65]
new g_AdminTalk[65]

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:Cvar_InitState = INVALID_HANDLE
new Handle:Cvar_Alltalk = INVALID_HANDLE


public Plugin:myinfo = 
{
	name = "AdminSentinel",
	author = "<eVa>StrontiumDog ",
	description = "Lets admins monitor all player chat",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_admin_sentinel_version", PLUGIN_VERSION, "AdminSentinel Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	Cvar_InitState = CreateConVar("sv_admin_sentinel_startup", "1", "When enabled, Enemy Voice Comms are automatically on for joining admin", FCVAR_PLUGIN)
	
	Cvar_Alltalk = FindConVar("sv_alltalk")
	HookConVarChange(Cvar_Alltalk, AlltalkChanged)
	
	RegAdminCmd("sm_enemyvoice", admin_enemyvoice, ADMIN_LEVEL, "sm_enemyvoice - toggles on/off enemy voice comm per admin")
	RegAdminCmd("sm_talktoserver", admin_talktoserver, ADMIN_CHAT, "sm_talktoserver - allows an admin to talk to all players on the server")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnClientPostAdminCheck(client)
{
	if (client != 0)
	{
		if (GetUserFlagBits(client) & ADMIN_LEVEL)
		{
			if (GetConVarInt(Cvar_InitState))
			{
				SetClientListeningFlags(client, SPEAK_LISTENALL)
				g_EnemyVoice[client] = 1
				PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm enabled")
			}
		}
		else
		{
			SetClientListeningFlags(client, SPEAK_NORMAL)
			g_EnemyVoice[client] = 0
		}
	}
}

public Action:admin_enemyvoice(client, args)
{

	if(g_EnemyVoice[client] == 1)
	{
		g_EnemyVoice[client] = 0
		SetClientListeningFlags(client, SPEAK_NORMAL)
		PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm disabled")
		return Plugin_Handled
	}
	else if(g_EnemyVoice[client] == 0)
	{
		g_EnemyVoice[client] = 1
		SetClientListeningFlags(client, SPEAK_LISTENALL)
		PrintToChat(client,"\x01\x04[AdminSentinel] Listening to enemy voice comm enabled")
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:admin_talktoserver(client, args)
{	
	if(g_AdminTalk[client] == 1 && g_EnemyVoice[client] == 0)
	{
		g_AdminTalk[client] = 0
		SetClientListeningFlags(client, SPEAK_NORMAL)
		PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is off")
		return Plugin_Handled
	}
	if(g_AdminTalk[client] == 1 && g_EnemyVoice[client] == 1)
	{
		g_AdminTalk[client] = 0
		SetClientListeningFlags(client, SPEAK_LISTENALL)
		PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is off")
		return Plugin_Handled
	}
	else if(g_AdminTalk[client] == 0)
	{
		g_AdminTalk[client] = 1
		SetClientListeningFlags(client, SPEAK_TALKLISTENALL)
		PrintToChat(client,"\x01\x04[AdminSentinel] Talk to Server is on")
		return Plugin_Handled
	}
	return Plugin_Continue
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_enemyvoice",
			TopMenuObject_Item,
			AdminMenu_EnemyVoice,
			player_commands,
			"sm_enemyvoice",
			ADMIN_LEVEL)
			
		AddToTopMenu(hAdminMenu,
			"sm_talktoserver",
			TopMenuObject_Item,
			AdminMenu_AdminVoice,
			player_commands,
			"sm_talktoserver",
			ADMIN_CHAT)
	}
}
 
public AdminMenu_EnemyVoice(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_EnemyVoice[param] == 1) 
		{
			Format(buffer, maxlength, "Turn off Enemy VoiceComm")
		}
		else 
		{
			Format(buffer, maxlength, "Turn on Enemy VoiceComm")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_enemyvoice(param, ADMIN_LEVEL)
	}
}

public AdminMenu_AdminVoice(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_AdminTalk[param] == 1) 
		{
			Format(buffer, maxlength, "Don't talk to all players")
		}
		else 
		{
			Format(buffer, maxlength, "Talk to all players")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_talktoserver(param, ADMIN_CHAT)
	}
}

public AlltalkChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{		
	if (!GetConVarBool(Cvar_Alltalk))
	{
		new numofPlayers = GetClientCount(true)
		
		for (new i = 1; i <= numofPlayers; i++)
		{
			if(g_EnemyVoice[i] == 1)
			{
				SetClientListeningFlags(i, SPEAK_LISTENALL)
				PrintToChat(i,"\x01\x04[AdminSentinel] Listening to enemy voice comm re-enabled")
			}
		}
	}
}
	
	
	
	
	