/*
	Original Credits: - FLOOR_MASTER's PERMAMUTE Plugin
	- Source: http://forums.alliedmods.net/showthread.php?p=630159
	
	Updates:
	v1.1.3 - Fixed an issue that prevented players from speaking.
	v1.1.4 - Removed the unncessary code that lead to the issue in v1.1.3 to begin with.
	v1.1.5 - Fixed an issue that would cause persistant punishments to not be applied.
		   - Fixed an issue where sm_extendedmute_hidden was not functioning properly.
	v1.1.6 - Fixed an issue where permanant punishments were not applied and caused all punishments to be removed.
	v1.1.7 - Changed ProcessCookies() into a timer to reduce the chance of other plugins interfering.
	v1.2.0 - Hopefully resolved any future issues with clients accidently having their punishments not applied.
		   - Added sm_estatus, which allows administrators to check the status of a player without checking the menu.
	v1.2.1 - Added a method for ending extended mutes without the affected client from having to reconnect.
	v1.2.2 - Fixed an error stemming from improper checks in ProcessCookies();
	v1.2.2-B - DarthNinja: Fixed GetClientAuthString using "client" instead of "target" on lines 626 and 682.
*/

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.2.2-B"

#define CVAR_VERSION		0
#define CVAR_HIDDEN			1
#define CVAR_DEFAULT		2
#define CVAR_NUM_CVARS		3

#define COOKIE_MUTE			0
#define COOKIE_GAG			1
#define COOKIE_MUTE_LENGTH	2
#define COOKIE_GAG_LENGTH	3
#define COOKIE_NUM_COOKIES  4

//ADMFLAG_CHEATS
//ADMFLAG_RCON
#define PERMANANT_FLAG ADMFLAG_RCON
//ADMFLAG_CONVARS
//ADMFLAG_CHAT
#define COMMAND_FLAG ADMFLAG_CHAT

new Handle:g_Cvars[CVAR_NUM_CVARS];
new Handle:g_Cookies[COOKIE_NUM_COOKIES];
new Handle:g_Admin = INVALID_HANDLE;
new Handle:g_Activity = INVALID_HANDLE;

new g_Targets[MAXPLAYERS + 1];
new Handle:g_Handles[MAXPLAYERS+1][2];

enum PCommType {
	PCommType_PMute = 0,
	PCommType_PUnMute,
	PCommType_PGag,
	PCommType_PUnGag,
	PCommType_PSilence,
	PCommType_PUnSilence,
	PCommType_NumTypes
};

public Plugin:myinfo = {
	name = "Extended Mute",
	author = "Twisted|Panda (Orig: FLOOR_MASTER)",
	description = "Allows the extended gag/mute/silence punishment of players for a definable period of time.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_Cvars[CVAR_VERSION] = CreateConVar("sm_extendedmute_version", PLUGIN_VERSION, "Extended Mute Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvars[CVAR_HIDDEN] = CreateConVar("sm_extendedmute_hidden", "1", "If enabled, Extended Mute will not process the console messages the administrator commands.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvars[CVAR_DEFAULT] = CreateConVar("sm_extendedmute_default", "60", "The default number of minutes a player will be muted/gagged/silenced for.", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "sm_extendedmute");
	
	g_Activity = FindConVar("sm_show_activity");
	g_Cookies[COOKIE_MUTE] = RegClientCookie("Extended_Mute", "Extended Mute: Mute Status", CookieAccess_Protected);
	g_Cookies[COOKIE_GAG] = RegClientCookie("Extended_Gag", "Extended Mute: Gag Status", CookieAccess_Protected);
	g_Cookies[COOKIE_MUTE_LENGTH] = RegClientCookie("Extended_Mute_Length", "Extended Mute: Mute Length", CookieAccess_Protected);
	g_Cookies[COOKIE_GAG_LENGTH] = RegClientCookie("Extended_Gag_Length", "Extended Mute: Gag Length", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Status, 0, "Extended Mute Status");

	RegAdminCmd("sm_emute", Command_MuteExtended, COMMAND_FLAG, "sm_emute <player> - Mute a player for an extended periord of time.");
	RegAdminCmd("sm_eunmute", Command_UnMuteExtended, COMMAND_FLAG, "sm_eunmute <player> - Restores a player's ability to use voice.");
	RegAdminCmd("sm_egag", Command_GagExtended, COMMAND_FLAG, "sm_egag <player> - Gag a player for an extended period of time.");
	RegAdminCmd("sm_eungag", Command_UnGagExtended, COMMAND_FLAG, "sm_eungag <player> - Restores a player's ability to use chat.");
	RegAdminCmd("sm_esilence", Command_SilenceExtended, COMMAND_FLAG, "sm_esilence <player> - Silence a player for an extended period of time.");
	RegAdminCmd("sm_eunsilence", Command_UnSilenceExtended, COMMAND_FLAG, "sm_eunsilence <player> - Restores a player's ability to use voice and chat.");
	RegAdminCmd("sm_estatus", Command_StatusExtended, COMMAND_FLAG, "sm_estatus <player> - Prints information concerning a player's extended mute status.");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);

	if (!PluginExists("basecomm.smx"))
		SetFailState("This plugin requires basecomm.smx. Please load basecomm and then try loading this plugin again.");
}

public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		for(new i = 0; i <= 1; i++)
		{
			if(g_Handles[client][i] != INVALID_HANDLE)
			{
				CloseHandle(g_Handles[client][i]);
				g_Handles[client][i] = INVALID_HANDLE;
			}
		}
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		g_Admin = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_Admin)
		return;

	g_Admin = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(g_Admin, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands == INVALID_TOPMENUOBJECT)
		return;

	AddToTopMenu(g_Admin, "sm_emute", TopMenuObject_Item, AdminMenu_PMute, player_commands, "sm_emute", COMMAND_FLAG);
}

public AdminMenu_PMute(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Extended Mute: Player");
		}
		case TopMenuAction_SelectOption: 
		{
			DisplayPMutePlayerMenu(param);
		}
	}
}

stock DisplayPMutePlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PMutePlayer);

	decl String:title[100];
	Format(title, sizeof(title), "Extended Mute Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, client, true, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_PMutePlayer(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack && g_Admin != INVALID_HANDLE)
				DisplayTopMenu(g_Admin, client, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			decl String:info[32];

			GetMenuItem(menu, param2, info, sizeof(info));
			new userid = StringToInt(info);
			new target = GetClientOfUserId(userid);

			if (!target)
				PrintToChat(client, "[Extended Mute] %t", "Player no longer available");
			else if (!CanUserTarget(client, target))
				PrintToChat(client, "[Extended Mute] %t", "Unable to target");
			else
			{
				g_Targets[client] = target;
				DisplayPMuteTypesMenu(client, target);
			}
		}
	}
}

stock DisplayPMuteTypesMenu(client, target)
{
	new Handle:menu = CreateMenu(MenuHandler_PMuteTypes);

	decl String:title[100];
	Format(title, sizeof(title), "Choose Type:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	decl String:cookie[8];
	new bool:silenced = true;

	GetClientCookie(target, g_Cookies[COOKIE_MUTE], cookie, sizeof(cookie));
	if (!strcmp(cookie, "1"))
		AddMenuItem(menu, "1", "Remove Extended Mute");
	else
	{
		AddMenuItem(menu, "0", "Issue Extended Mute");
		silenced = false;
	}

	GetClientCookie(target, g_Cookies[COOKIE_GAG], cookie, sizeof(cookie));
	if (!strcmp(cookie, "1"))
		AddMenuItem(menu, "3", "Remove Extended Gag");
	else
	{
		AddMenuItem(menu, "2", "Issue Extended Gag");
		silenced = false;
	}

	if (silenced)
		AddMenuItem(menu, "5", "Remove Extended Silence");
	else
		AddMenuItem(menu, "4", "Issue Extended Silence");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	if (action == CookieMenuAction_DisplayOption)
		Format(buffer, maxlen, "Extended Mute Status");
	else if (action == CookieMenuAction_SelectOption)
		CreateMenuStatus(client);
}

public MenuHandler_PMuteTypes(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel: 
		{
			if (param1 == MenuCancel_ExitBack && g_Admin != INVALID_HANDLE)
				DisplayTopMenu(g_Admin, client, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			decl String:info[32];

			GetMenuItem(menu, param2, info, sizeof(info));
			new PCommType:type = PCommType:StringToInt(info);

			PerformExtendedAction(client, g_Targets[client], type, GetConVarInt(g_Cvars[CVAR_DEFAULT]));
		}
	}
}

stock CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64], String:cookie[3], String:length[32], timeLeft;

	Format(text, sizeof(text), "Extended Mute Status");
	SetMenuTitle(menu, text);

	GetClientCookie(client, g_Cookies[COOKIE_MUTE], cookie, sizeof(cookie));
	if (!strcmp(cookie, "1"))
	{
		AddMenuItem(menu, "Extended_Mute", "Currently Muted:", ITEMDRAW_DISABLED);
		GetClientCookie(client, g_Cookies[COOKIE_MUTE_LENGTH], length, sizeof(length));
		timeLeft = StringToInt(length);
		if(timeLeft == 0)
			AddMenuItem(menu, "Extended_Mute", "~ Permanent", ITEMDRAW_DISABLED);
		else
		{
			timeLeft -= GetTime();
			Format(length, sizeof(length), "~ Expires in %d Minutes", RoundToCeil(float(timeLeft) / 60.0));
			AddMenuItem(menu, "Extended_Mute", length, ITEMDRAW_DISABLED);
		}
	}
	else
		AddMenuItem(menu, "Extended_Mute", "You are currently not muted.", ITEMDRAW_DISABLED);

	GetClientCookie(client, g_Cookies[COOKIE_GAG], cookie, sizeof(cookie));
	if (!strcmp(cookie, "1"))
	{
		AddMenuItem(menu, "Extended_Gag", "Currently Gagged:", ITEMDRAW_DISABLED);
		GetClientCookie(client, g_Cookies[COOKIE_GAG_LENGTH], length, sizeof(length));
		timeLeft = StringToInt(length);
		if(timeLeft == 0)
			AddMenuItem(menu, "Extended_Mute", "~ Permanent", ITEMDRAW_DISABLED);
		else
		{
			timeLeft -= GetTime();
			Format(length, sizeof(length), "~ Expires in %d Minutes", RoundToCeil(float(timeLeft) / 60.0));
			AddMenuItem(menu, "Extended_Mute", length, ITEMDRAW_DISABLED);
		}
	}
	else
		AddMenuItem(menu, "Extended_Gag", "You are currently not gagged.", ITEMDRAW_DISABLED);

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}

public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch (action)
	{
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
				{
					ShowCookieMenu(client);
				}
			}
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	g_Handles[client][COOKIE_MUTE] = INVALID_HANDLE;
	g_Handles[client][COOKIE_GAG] = INVALID_HANDLE;
	CreateTimer(0.0, CheckCookies, client, TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client)
{
	for(new i = 0; i <= 1; i++)
	{
		if(g_Handles[client][i] != INVALID_HANDLE)
		{
			CloseHandle(g_Handles[client][i]);
			g_Handles[client][i] = INVALID_HANDLE;
		}
	}
}

public Action:CheckCookies(Handle:timer, any: client)
{
	if (AreClientCookiesCached(client))
		CreateTimer(0.0, ProcessCookies, client, TIMER_FLAG_NO_MAPCHANGE);
	else if(IsClientInGame(client))
		CreateTimer(5.0, CheckCookies, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ProcessCookies(Handle:timer, any:client)
{
	if(client && IsClientInGame(client))
	{
		new clientId = GetClientUserId(client);
		new length, time;
		decl String:cookie[32];

		GetClientCookie(client, g_Cookies[COOKIE_MUTE], cookie, sizeof(cookie));
		if (StrEqual(cookie, "1")) 
		{
			GetClientCookie(client, g_Cookies[COOKIE_MUTE_LENGTH], cookie, sizeof(cookie));
			length = StringToInt(cookie);
			time = GetTime();
			if (!length || length > time)
			{
				Format(cookie, sizeof(cookie), "sm_mute #%d", clientId);
				ExtendedMuteCommand(cookie);

				length -= time;
				GetMapTimeLeft(time);
				if(length > 0 && length < time)
					g_Handles[client][COOKIE_MUTE] = CreateTimer(float(length), ExtendedMuteExpire, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
				PerformExtendedAction(0, client, PCommType_PUnMute, 0);
		}

		GetClientCookie(client, g_Cookies[COOKIE_GAG], cookie, sizeof(cookie));
		if (StrEqual(cookie, "1")) 
		{
			GetClientCookie(client, g_Cookies[COOKIE_GAG_LENGTH], cookie, sizeof(cookie));
			length = StringToInt(cookie);
			time = GetTime();
			if (!length || length > time)
			{
				Format(cookie, sizeof(cookie), "sm_gag #%d", clientId);
				ExtendedMuteCommand(cookie);

				length -= time;
				GetMapTimeLeft(time);
				if(length > 0 && length < time)
					g_Handles[client][COOKIE_GAG] = CreateTimer(float(length), ExtendedGagExpire, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
				PerformExtendedAction(0, client, PCommType_PUnGag, 0);
		}
	}
}

public Action:Command_MuteExtended(client, args) 
{
	if (args < 2) 
		ReplyToCommand(client, "[SM] Usage: sm_emute <player> <length>");
	else
	{
		decl String:target[64], String:buffer[64];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, buffer, sizeof(buffer));
		new time = StringToInt(buffer);
		if(!time && client && !(GetUserFlagBits(client) & (PERMANANT_FLAG|ADMFLAG_ROOT)))
			ReplyToCommand(client, "[SM] You do not have permission to permanently mute!");
		else
			TargetExtendedAction(client, PCommType_PMute, target, time);
	}

	return Plugin_Handled;
}

public Action:Command_UnMuteExtended(client, args) 
{
	if (args < 1)
		ReplyToCommand(client, "[Extended Mute] Usage: sm_eunmute <player>");
	else
	{
		decl String:target[64];
		GetCmdArg(1, target, sizeof(target));

		TargetExtendedAction(client, PCommType_PUnMute, target, 0);
	}

	return Plugin_Handled;
}

public Action:Command_GagExtended(client, args) 
{
	if (args < 2) 
		ReplyToCommand(client, "[SM] Usage: sm_egag <player> <length>");
	else
	{
		decl String:target[64], String:buffer[64];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, buffer, sizeof(buffer));
		new time = StringToInt(buffer);
		if(!time && client && !(GetUserFlagBits(client) & (PERMANANT_FLAG|ADMFLAG_ROOT)))
			ReplyToCommand(client, "[SM] You do not have permission to permanently gag!");
		else
			TargetExtendedAction(client, PCommType_PGag, target, time);
	}

	return Plugin_Handled;
}

public Action:Command_UnGagExtended(client, args) 
{
	if (args < 1) 
		ReplyToCommand(client, "[Extended Mute] Usage: sm_eungag <player>");
	else
	{
		decl String:target[64];
		GetCmdArg(1, target, sizeof(target));

		TargetExtendedAction(client, PCommType_PUnGag, target, 0);
	}
}

public Action:Command_SilenceExtended(client, args) 
{
	if (args < 2) 
		ReplyToCommand(client, "[SM] Usage: sm_esilence <player> <length>");
	else
	{
		decl String:target[64], String:buffer[64];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, buffer, sizeof(buffer));
		new time = StringToInt(buffer);
		if(!time && client && !(GetUserFlagBits(client) & (PERMANANT_FLAG|ADMFLAG_ROOT)))
			ReplyToCommand(client, "[SM] You do not have permission to permanently silence!");
		else
			TargetExtendedAction(client, PCommType_PSilence, target, time);
	}

	return Plugin_Handled;
}

public Action:Command_UnSilenceExtended(client, args) 
{
	if (args < 1) 
		ReplyToCommand(client, "[Extended Mute] Usage: sm_eunsilence <player>");
	else
	{
		decl String:target[64];
		GetCmdArg(1, target, sizeof(target));

		TargetExtendedAction(client, PCommType_PUnSilence, target, 0);
	}

	return Plugin_Handled;
}

public Action:Command_StatusExtended(client, args) 
{
	if (args < 1) 
		ReplyToCommand(client, "[Extended Mute] Usage: sm_estatus <player>");
	else
	{
		decl String:target[64];
		GetCmdArg(1, target, sizeof(target));

		decl String:clientName[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml)) <= 0) 
			ReplyToTargetError(client, target_count);
		else
		{
			for (new i = 0; i < target_count; i++)
			{
				if(target_list[i] && IsClientInGame(target_list[i]))
				{
					decl String:isMuted[3];
					GetClientCookie(target_list[i], g_Cookies[COOKIE_MUTE], isMuted, sizeof(isMuted));
					new muteFlag = StringToInt(isMuted);

					decl String:isGagged[3];
					GetClientCookie(target_list[i], g_Cookies[COOKIE_GAG], isGagged, sizeof(isGagged));
					new gagFlag = StringToInt(isGagged);

					decl String:muteLength[32];
					if(muteFlag)
					{
						GetClientCookie(target_list[i], g_Cookies[COOKIE_MUTE_LENGTH], muteLength, sizeof(muteLength));
						new muteLeft = StringToInt(muteLength);
						if(muteLeft == 0)
							Format(muteLength, sizeof(muteLength), "Permanent");
						else
						{
							muteLeft -= GetTime();
							if(muteLeft > 0)
								Format(muteLength, sizeof(muteLength), "%d Minutes Remaining", (muteLeft / 60));
						}
					}
				
					decl String:gagLength[32];
					if(gagFlag)
					{
						GetClientCookie(target_list[i], g_Cookies[COOKIE_GAG_LENGTH], gagLength, sizeof(gagLength));
						new gagLeft = StringToInt(gagLength);
						if(gagLeft == 0)
							Format(gagLength, sizeof(gagLength), "Permanent");
						else
						{
							gagLeft -= GetTime();
							if(gagLeft > 0)
								Format(gagLength, sizeof(gagLength), "%d Minutes Remaining", (gagLeft / 60));
						}
					}

					if(muteFlag && gagFlag)
						ReplyToCommand(client, "[Extended Mute] %N is silenced! (Mute: %s, Gag: %s)", target_list[i], muteLength, gagLength);
					else if(muteFlag)
						ReplyToCommand(client, "[Extended Mute] %N is muted! (%s)", target_list[i], muteLength);
					else if(gagFlag)
						ReplyToCommand(client, "[Extended Mute] %N is gagged! (%s)", target_list[i], gagLength);
					else
						ReplyToCommand(client, "[Extended Mute] %N does not have an extended mute against him/her.", target_list[i]);
				}
			}
		}
	}

	return Plugin_Handled;
}

void:TargetExtendedAction(client, PCommType:type, const String:target_string[], length)
{
	decl String:clientName[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, 0, clientName, sizeof(clientName), tn_is_ml)) <= 0) 
	{
		ReplyToTargetError(client, target_count);
		return;
	}

	for (new i = 0; i < target_count; i++)
		if(target_list[i] && IsClientInGame(target_list[i]))
			PerformExtendedAction(client, target_list[i], type, length);
}

void:PerformExtendedAction(client, target, PCommType:type, length)
{
	decl String:cmd[32], String:time[16], String:cookie[3];
	if(length == 0)
		IntToString(length, time, sizeof(time));
	else
		IntToString(((length * 60) + GetTime()), time, sizeof(time));
	
	new clientId = GetClientUserId(target);
	switch (type) 
	{
		case PCommType_PMute:
		{
			Format(cmd, sizeof(cmd), "sm_mute #%d", clientId);
			ExtendedMuteCommand(cmd);
			
			GetClientAuthString(target, cmd, sizeof(cmd));
			if(client && IsClientInGame(client))
			{
				decl String:adminSteam[32];
				GetClientAuthString(client, adminSteam, sizeof(adminSteam));
			
				ExtendedMuteLog("%N (%s) has issued an extended mute on %N (%s) for %d minutes.", client, adminSteam, target, cmd, length);
			}
			else
				ExtendedMuteLog("Console has issued an extended mute on %N (%s) for %d minutes.", target, cmd, length);

			if(client)
				ShowActivity2(client, "[SM] ", "Muted %N for %d minutes.", target, length);

			GetClientCookie(target, g_Cookies[COOKIE_MUTE], cookie, sizeof(cookie));
			if (!StrEqual(cookie, "1"))
			{
				SetClientCookie(target, g_Cookies[COOKIE_MUTE], "1");
				SetClientCookie(target, g_Cookies[COOKIE_MUTE_LENGTH], time);
			}
			else
				SetClientCookie(target, g_Cookies[COOKIE_MUTE_LENGTH], time);

			if(length > 0)
			{
				new tempTime;
				length *= 60;
				
				GetMapTimeLeft(tempTime);
				if(length < tempTime)
					g_Handles[client][COOKIE_MUTE] = CreateTimer(float(length), ExtendedMuteExpire, target, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		case PCommType_PUnMute:
		{
			Format(cmd, sizeof(cmd), "sm_unmute #%d", clientId);
			ExtendedMuteCommand(cmd);
			
			GetClientCookie(target, g_Cookies[COOKIE_MUTE], cookie, sizeof(cookie));
			if (StrEqual(cookie, "1"))
			{
				GetClientAuthString(target, cmd, sizeof(cmd));
				ExtendedMuteLog("[Expired] Extended Mute: %N (%s)", target, cmd);
				
				SetClientCookie(target, g_Cookies[COOKIE_MUTE], "0");
				SetClientCookie(target, g_Cookies[COOKIE_MUTE_LENGTH], "");
				
				if (client)
					ShowActivity2(client, "[Extended Mute] ", "Removed the extended mute for %N", target);
			}
		}
		case PCommType_PGag:
		{
			Format(cmd, sizeof(cmd), "sm_gag #%d", clientId);
			ExtendedMuteCommand(cmd);
			
			GetClientAuthString(target, cmd, sizeof(cmd));
			if(client && IsClientInGame(client))
			{
				decl String:adminSteam[32];
				GetClientAuthString(client, adminSteam, sizeof(adminSteam));
			
				ExtendedMuteLog("%N (%s) has issued an extended gag on %N (%s) for %d minutes.", client, adminSteam, target, cmd, length);
			}
			else
				ExtendedMuteLog("Console has issued an extended gag on %N (%s) for %d minutes.", target, cmd, length);

			if(client)
				ShowActivity2(client, "[SM] ", "Gagged %N for %d minutes.", target, length);

			GetClientCookie(target, g_Cookies[COOKIE_GAG], cookie, sizeof(cookie));
			if (!StrEqual(cookie, "1"))
			{
				SetClientCookie(target, g_Cookies[COOKIE_GAG], "1");
				SetClientCookie(target, g_Cookies[COOKIE_GAG_LENGTH], time);
			}
			else
				SetClientCookie(target, g_Cookies[COOKIE_GAG_LENGTH], time);
				
			if(length > 0)
			{
				new tempTime;
				length *= 60;
				
				GetMapTimeLeft(tempTime);
				if(length < tempTime)
					g_Handles[client][COOKIE_GAG] = CreateTimer(float(length), ExtendedGagExpire, target, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		case PCommType_PUnGag:
		{
			Format(cmd, sizeof(cmd), "sm_ungag #%d", clientId);
			ExtendedMuteCommand(cmd);

			GetClientCookie(target, g_Cookies[COOKIE_GAG], cookie, sizeof(cookie));
			if (StrEqual(cookie, "1"))
			{
				GetClientAuthString(target, cmd, sizeof(cmd));
				ExtendedMuteLog("[Expired] Extended Gag: %N (%s)", target, cmd);
				
				SetClientCookie(target, g_Cookies[COOKIE_GAG], "0");
				SetClientCookie(target, g_Cookies[COOKIE_GAG_LENGTH], "");
				
				if (client)
					ShowActivity2(client, "[Extended Mute] ", "Removed the extended gag for %N", target);
			}
		}
		case PCommType_PSilence: 
		{
			PerformExtendedAction(client, target, PCommType_PMute, length);
			PerformExtendedAction(client, target, PCommType_PGag, length);
		}
		case PCommType_PUnSilence:
		{
			PerformExtendedAction(client, target, PCommType_PUnMute, length);
			PerformExtendedAction(client, target, PCommType_PUnGag, length);
		}
	}
}

void:ExtendedMuteLog(const String:format[], any:...)
{
	decl String:f_sBuffer[256], String:f_sPath[256];
	VFormat(f_sBuffer, sizeof(f_sBuffer), format, 2);
	BuildPath(Path_SM, f_sPath, sizeof(f_sPath), "logs/ExtendedMute.log");
	LogMessage("%s", f_sBuffer);
	LogToFileEx(f_sPath, "%s", f_sBuffer);
}

void:ExtendedMuteCommand(const String:format[])
{
	if(GetConVarInt(g_Cvars[CVAR_HIDDEN]))
	{
		new g_Temp = GetConVarInt(g_Activity);
		ServerCommand("sm_show_activity 0; %s; sm_show_activity %d", format, g_Temp);
	}
	else
		ServerCommand(format);
}

public Action:ExtendedMuteExpire(Handle:timer, any:client)
{
	if(client && IsClientInGame(client))
	{
		decl String:cookie[32];
		GetClientCookie(client, g_Cookies[COOKIE_MUTE], cookie, sizeof(cookie));
		if (StrEqual(cookie, "1"))
			PerformExtendedAction(0, client, PCommType_PUnMute, 0);

		g_Handles[client][COOKIE_MUTE] = INVALID_HANDLE;
	}
}

public Action:ExtendedGagExpire(Handle:timer, any:client)
{
	if(client && IsClientInGame(client))
	{
		decl String:cookie[32];
		GetClientCookie(client, g_Cookies[COOKIE_GAG], cookie, sizeof(cookie));
		if (StrEqual(cookie, "1")) 
			PerformExtendedAction(0, client, PCommType_PUnGag, 0);
			
		g_Handles[client][COOKIE_GAG] = INVALID_HANDLE;
	}
}

bool:PluginExists(const String:plugin_name[])
{
	new Handle:iter = GetPluginIterator();
	new Handle:plugin = INVALID_HANDLE;
	decl String:name[64];

	while (MorePlugins(iter))
	{
		plugin = ReadPlugin(iter);
		GetPluginFilename(plugin, name, sizeof(name));
		if (StrEqual(name, plugin_name))
		{
			CloseHandle(iter);
			return true;
		}
	}

	CloseHandle(iter);
	return false;
}