/* 
 * Description:
 * This is a basic plugin to respawn the target player, it also supports @all/@red/@blue/@bots targeting. 
 * It will also be in the sm admin menu for any admin with the kick flag.
 * You can easily hide chat notification if you want to ;-)
 *
 * Console Command
 * sm_rplayer: 				Respawns the target player(s) to their team's spawn point.
 * 
 * ConVars:
 * sm_rplayer_enable: 		Enable/Disable Respawn Player Plugin. 	0/1 	Default: "1" - On
 * sm_rplayer_chat_notify: 	Respawn chat notifications. 			0/1/2	Default: "1" - Notify to target
 * sm_rplayer_log: 			Enable/Disable Respawn Actions Logging.	0/1/2 	Default: "1" - Logging to Separate File
 * 
 * Changelog:
 * Version 1.0 (18/07/09) /Starman2098
 * - Initial Release (plugin won't work)
 *
 * Version 1.1 (23/07/09) /Zuko
 * - Added ConVar: sm_rplayer_enable 
 * - Added ConVar: sm_rplayer_chat_notify 
 * - Added ConVar: sm_rplayer_log 
 * - Added Multi-Language Support (with Polish translation)
 * 
 * 
 * Original plugin author: Starman2098 / http://www.starman2098.com 
 * Thanks goes to psychonic ;-)
 */
 
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify = INVALID_HANDLE;
new Handle:g_Cvar_Log = INVALID_HANDLE;

new String:logFile[256];

#define PLUGIN_VERSION	"1.1"

public Plugin:myinfo = 
{
	name = "[TF2] Respawn Player",
	author = "Zuko",
	description = "Lets an admin respawn a player.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("rplayer_version", PLUGIN_VERSION, "Respawn Player Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_PluginEnable = CreateConVar("sm_rplayer_enable", "1", "0 = Off | 1 = On -- Enable/Disable Respawn Player Plugin");
	g_Cvar_ChatNotify = CreateConVar("sm_rplayer_chat_notify", "1", "0 = Off | 1 = Target | 2 = All -- Respawn Chat Notifications");
	g_Cvar_Log = CreateConVar("sm_rplayer_log", "1", "0 = Off | 1 = Separate File | 2 = SM Logs -- Respawn Actions Logging");
	RegAdminCmd("sm_rplayer", Command_Rplayer, ADMFLAG_KICK, "sm_rplayer <user id | name>");
	
	LoadTranslations("common.phrases")
	LoadTranslations("rplayer.phrases")
	
	AutoExecConfig(true, "plugin.rplayer");
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/respawnplayer.log");
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

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
	GetCmdArg(1, target, sizeof(target));
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] %T", "PluginUsage", LANG_SERVER);
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

PerformRespawnPlayer(client,target)
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
			PrintToChat(target, "[SM] %T", "SpawnPhrase1", LANG_SERVER, client);
		case 2:
			PrintToChatAll("[SM] %T", "SpawnPhrase2", LANG_SERVER, client, target);
	}
	ReplyToCommand(client, "[SM] %T", "SpawnPhrase3", LANG_SERVER, target);
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
	
	AddTargetsToMenu(menu, client, true, true)
	
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
