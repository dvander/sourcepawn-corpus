/* 
 * Description:
 * This is a basic plugin to respawn the target player. Now you can also set auto respawn after death, it supports @all/@red/@blue/@bots (and targeting. 
 * It will also be in the sm admin menu for any admin with the kick flag.
 * You can easily hide chat notification if you want to ;-)
 * You can change ADMIN FLAG in "#define _ADMIN_FLAG_" 
 *
 * Console Commands
 * sm_rp: 						Respawns the target player(s) to their team's spawn point.
 * sm_autorespawn:				Automatic respawn player(s) after death (with defined delay Between 0-30 / -1 Disable (Normal Respawn Times))
 * sm_rme:						Respawn Admin
 * 
 * ConVars:
 * sm_respawner_enable: 			Enable/Disable Respawn Player Plugin. 	0-Disable | 1-Enable 					Default: "1" - Enable
 * sm_respawner_chat_notify: 		Respawn chat notifications. 			0-Off | 1-Target | 2-All				Default: "1" - Notify to target
 * sm_autorespawn_chat_notify:	Auto Respawn chat notifications. 		0-Off | 1-Target | 2-All				Default: "1" - Notify to target
 * sm_respawner_log: 				Enable/Disable Respawn Actions Logging.	0-Off | 1-Separate File | 2-SM Logs 	Default: "1" - Logging to Separate File
 * 
 * Changelog:
 * Version 1.0 (18/07/09) /Starman2098 (Approved but does not work :X)
 * - Initial Release (plugin does not work)
 *
 * Version 1.1 (23/07/09)
 * - Added ConVar: sm_rplayer_enable 
 * - Added ConVar: sm_rplayer_chat_notify 
 * - Added ConVar: sm_rplayer_log 
 * - Added Multi-Language Support (with Polish translation)
 *
 * Version 1.2 (08/08/09)
 * - Added Autorespawn
 * - Added Colors to Phrases 
 *
 * Version 1.3 (11/08/09)
 * - Fixed sm_autorplayer filtered to alive players
 * - Fixed Menu (show only alive players)
 * - Changed colors in phrases
 * - Added sm_rme command
 *
 * Version 1.4 (13/08/09)
 * - Added checks for round start/end (sm_autorplayer don't respawn player when round ends)
 * - Another Menu fix
 * - sm_rme command fix
 *
 * Version 1.5 (17/08/09)
 * - Added checking if player is spectator
 *
 * Version 1.6 (20/21.08.2009)
 * - Changed commands names
 * - Redone some functions
 * - Redone phrases
 *
 * TODO:
 * - Requests ;-)
 * - Fixing bugs ;D
 *
 *
 * Plugin based on [TF2] Respawn Player by Starman2098 / http://www.starman2098.com
 *
 * Thanks goes to psychonic ;-)
 *
 * Zuko / hlds.pl @ Qnet / zuko.isports.pl /
 *
 */
 
#include <sourcemod>
#include <tf2>
#include <colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify_AutoRespawn = INVALID_HANDLE;
new Handle:g_Cvar_Log = INVALID_HANDLE;

new bool:autorespawn_enabled[MAXPLAYERS+1] = false;
new Float:respawn_delay[MAXPLAYERS+1] = -1.0;

new bool:SuddenDeathMode
new bool:RoundIsActive

new String:logFile[256];
new PlayerTeam

#define PLUGIN_VERSION	"1.6"

#define _ADMIN_FLAG_ ADMFLAG_KICK

public Plugin:myinfo = 
{
	name = "[TF2] Respawner",
	author = "Zuko",
	description = "Lets an admin respawn a player or set autorespawn.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("respawner_version", PLUGIN_VERSION, "Respawn Player Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_PluginEnable = 					CreateConVar("sm_respawner_enable", 			"1", "Enable/Disable Respawn Player Plugin", 	_, true, 0.0, true, 1.0);
	g_Cvar_ChatNotify = 					CreateConVar("sm_respawner_chat_notify", 	"1", "Respawn Chat Notifications", 				_, true, 0.0, true, 2.0);
	g_Cvar_ChatNotify_AutoRespawn = 		CreateConVar("sm_autorespawn_chat_notify", 	"1", "Auto Respawn Chat Notifications",		 	_, true, 0.0, true, 2.0);
	g_Cvar_Log = 								CreateConVar("sm_respawner_log", 			"1", "Respawn Actions Logging", 				_, true, 0.0, true, 2.0);
	
	RegAdminCmd("sm_rp", 			Command_Rplayer, 			_ADMIN_FLAG_, "sm_rp <#userid | name>");
	RegAdminCmd("sm_rme", 			Command_RespawnMe, 			_ADMIN_FLAG_, "Respawn yourself");
	
	RegConsoleCmd("sm_autorespawn", Command_AutoRplayer, "sm_autorespawn <#userid | name> <delay>");
	
	LoadTranslations("common.phrases");
	LoadTranslations("respawner.phrases");
	
	AutoExecConfig(true, "plugin.respawner");
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/respawner.log");
	
	/* Hook Events */
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", EventRoundWon, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
		
	/*Menu Handler */
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnClientPostAdminCheck(client)
{
	autorespawn_enabled[client] = false;
	respawn_delay[client] = -1.0;
}

 /* Respawn Me */
public Action:Command_RespawnMe(client, args)
{
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
	
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		PlayerTeam = GetClientTeam(client);
		if (PlayerTeam != 1)
		{
			if (!IsPlayerAlive(client))
			{
				TF2_RespawnPlayer(client);
				CPrintToChat(client, "{lightgreen}[SM] %T", "RespawnMe", LANG_SERVER);
				return Plugin_Handled;
			}
			else
			ReplyToCommand(client, "[SM] %T", "YouAreAlive", LANG_SERVER);
		}
		else 
		ReplyToCommand(client, "[SM] %T", "YouAreOnSpectator", LANG_SERVER);
	}
	return Plugin_Handled;
}
/* >>> end of Respawn Me */

/* Respawn */
public Action:Command_Rplayer(client, args)
{
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
	
	decl String:target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] %T", "PluginUsage_RP", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
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
			COMMAND_FILTER_DEAD,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		PerformRespawnPlayer(client,target_list[i]);
	}	
	return Plugin_Handled;
}

PerformRespawnPlayer(client, target)
{	
	PlayerTeam = GetClientTeam(target);
	if (PlayerTeam != 1)
	{
		if (GetConVarInt(g_Cvar_PluginEnable) == 0)
		{
			ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		}
	
		if (IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(target);
	
			switch(GetConVarInt(g_Cvar_Log))
			{
				case 0:
					return;
				case 1:
					LogToFile(logFile, "%T", "PluginLog", LANG_SERVER, client, target);
				case 2:
					LogAction(client, target, "%T", "PluginLog", LANG_SERVER, client, target);
			}
			switch(GetConVarInt(g_Cvar_ChatNotify))
			{
				case 0:
					return;
				case 1:
					CPrintToChat(target, "{lightgreen}[SM] %T", "SpawnPhrase1", LANG_SERVER, client);
				case 2:
					CPrintToChatAll("{lightgreen}[SM] %T", "SpawnPhrase2", LANG_SERVER, client, target);
			}
			ReplyToCommand(client, "[SM] %T", "SpawnPhrase3", LANG_SERVER, target);
		}
	}
	else 
	ReplyToCommand(client, "[SM] %T", "YouAreOnSpectator", LANG_SERVER);
}
/* >>> end of Respawn */

/* Auto Respawn */
public Action:Command_AutoRplayer(client, args)
{
	new Float:nDelay;
	new iDelay;
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
		
	decl String:target[MAXPLAYERS];
	decl String:delay[10];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] %T", "PluginUsage_AutoRespawn", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, delay, sizeof(delay));
		nDelay = StringToFloat(delay);
		iDelay = StringToInt(delay);
	}

	if (nDelay < -1)
	{
		ReplyToCommand(client, "[SM] %T", "RespawnDelay1", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if (nDelay > 30)
	{
		ReplyToCommand(client, "[SM] %T", "RespawnDelay2", LANG_SERVER);
		return Plugin_Handled;
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
		if (!SuddenDeathMode && IsClientConnected(target_list[i]) && IsClientInGame(target_list[i]))
		{
			PlayerTeam = GetClientTeam(target_list[i]);
			if (PlayerTeam != 1)
			{
				autorespawn_enabled[target_list[i]] = true;
				respawn_delay[target_list[i]] = nDelay;
				if (!IsPlayerAlive(target_list[i]))
				{
					TF2_RespawnPlayer(target_list[i]);
				}
				
				if (client == target_list[i])
				{
					if (nDelay == 0.0)
					{
					ReplyToCommand(client, "[SM] %T", "RespawnDelay6", LANG_SERVER);
					}
					else if (nDelay == -1.0)
					{
						ReplyToCommand(client, "[SM] %T", "RespawnDelay3", LANG_SERVER);
					}
					else
					ReplyToCommand(client, "[SM] %T", "RespawnDelay5", LANG_SERVER, iDelay);
				}
				else if (nDelay == 0.0)
				{
					ReplyToCommand(client, "[SM] %T", "RespawnDelay7", LANG_SERVER, target_list[i]);
				}
				else
				ReplyToCommand(client, "[SM] %T", "RespawnDelay4", LANG_SERVER, target_list[i], iDelay);
				
				switch(GetConVarInt(g_Cvar_ChatNotify_AutoRespawn))
				{
					case 0:
						return Plugin_Continue;
					case 1:
					{
						if (client == target_list[i])
						{	
							if (nDelay == -1.0)
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase4", LANG_SERVER);
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase4a", LANG_SERVER);
							}
							else
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase3", LANG_SERVER);
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase3a", LANG_SERVER, iDelay);
							}
						}
						else
						{
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase1", LANG_SERVER, client);
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase1a", LANG_SERVER, iDelay);
						}
					}
					case 2:
					{
						if (nDelay == -1.0)
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase5", LANG_SERVER, client, target_list[i], iDelay);
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase5a", LANG_SERVER);
						}
						else
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase2", LANG_SERVER, client, target_list[i]);
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase2a", LANG_SERVER, iDelay);
						}
					}
				}
			}
			else
			ReplyToCommand(client, "[SM] %T", "YouAreOnSpectator", LANG_SERVER);
		}
	}	
	return Plugin_Handled;
}

/* Respawn Timer */
public Action:SpawnPlayerTimer(Handle:timer, any:client)
{
	if (!SuddenDeathMode && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
	return Plugin_Continue;
}
/* >>> end of Respawn Timer */

/* Events */
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new Float:RespawnTime = 0.0;
	
	if ((autorespawn_enabled[client] == true) && (!SuddenDeathMode) && (RoundIsActive == true))
	{
		RespawnTime = respawn_delay[client];
		if (respawn_delay[client] == -1)
		{
			return Plugin_Handled;
		}
		else
		{
			CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE)
		}
	}
	return Plugin_Continue;
}

public Action:EventSuddenDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	SuddenDeathMode = true;
	return Plugin_Continue;
}

public EventRoundWon(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundIsActive = false;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundIsActive = true;
}
/* >>> end of events */
/* >>> end of Auto Respawn */

/* Disconnect? */
public OnClientDisconnect(client)
{
	autorespawn_enabled[client] = false;
	respawn_delay[client] = -1.0;
}

/* Menu */
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
			"sm_rplayer",
			TopMenuObject_Item,
			AdminMenu_Particles, 
			player_commands,
			"sm_rplayer",
			ADMFLAG_KICK)
	}
}
 
public AdminMenu_Particles( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "RespawnPlayer", LANG_SERVER)
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param)
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players)
	
	decl String:title[100]
	Format(title, sizeof(title),"%T", "ChoosePlayer", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu(menu, client, true, false)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));

			if ((target) == 0)
			{
				PrintToChat(param1, "[SM] %T", "Player no longer available", LANG_SERVER);
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "[SM] %T", "Unable to target", LANG_SERVER);
			}
			else
			{                     
				PerformRespawnPlayer(param1, target);
				if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
				{
					DisplayPlayerMenu(param1);
				}
			}
		}
	}
}
/* >>> end of Menu */
/* EOF */