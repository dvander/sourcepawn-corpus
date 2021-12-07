#pragma semicolon 1

#include <clientprefs>
#include <sdktools>
#include <adminmenu>

#define TEAMBANS_VERSION "0.3"

public Plugin:myinfo = 
{
	name = "Team Ban",
	author = "Azelphur",
	description = "Ban players from a team",
	version = TEAMBANS_VERSION,
	url = "http://www.azelphur.com"
};

new Handle:g_hCookie;
new Handle:g_hAdminMenu;
new Handle:g_hcvarDisabled;
new Handle:g_hcvarVersion;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_hCookie = RegClientCookie("TeamBan_BanMask", "The team banmask.", CookieAccess_Private); // Simple bitmask to determine banned teams, 1<<teamindex
	AddCommandListener(Command_Jointeam, "jointeam");
	RegAdminCmd("sm_teamban", Command_Teamban, ADMFLAG_BAN, "sm_teamban <name|#userid> <team> - Bans a player from a team, opens menu if player not specified."); // Create sm_teamban command
	RegAdminCmd("sm_teamunban", Command_Teamunban, ADMFLAG_BAN, "sm_teamunban <name|#userid> <team> - Unbans a player from a team, opens menu if player not specified."); // Create sm_teamunban command

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	g_hcvarDisabled = CreateConVar("sm_teamban_disable", "0", "Bitflags for allowed teams to ban");
	g_hcvarVersion = CreateConVar("sm_teambans_version", TEAMBANS_VERSION, "Current version of Team Bans", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
		AttachAdminMenu();
	}
}

public OnConfigsExecuted()
{
	// hax for busted a2s_rules response on linux (Ninja'd from hlstats by psychonic)
	if (GuessSDKVersion() != SOURCE_SDK_EPISODE2VALVE)
		return;
	decl String:szBuffer[128];
	GetConVarString(g_hcvarVersion, szBuffer, sizeof(szBuffer));
	SetConVarString(g_hcvarVersion, szBuffer);
	//
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get the team name of the team the person is trying to join
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetClientTeam(client);
	// Get the players banned team mask
	decl String:szBanMask[16];
	GetClientCookie(client, g_hCookie, szBanMask, sizeof(szBanMask));
	new iBanMask = StringToInt(szBanMask);
	
	// Is the player banned from this team? block it.
	if (1<<iTeam & iBanMask)
	{
		decl String:szTeamName[16];
		GetTeamName(iTeam, szTeamName, sizeof(szTeamName));
		PrintToChat(client, "[SM] You are banned from %s", szTeamName);
		for (new i = GetTeamCount()-1; i > 0; i--)
		{
			if (!(1<<i & iBanMask))
			{
				ChangeClientTeam(client, i);
				break;
			}
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hAdminMenu = INVALID_HANDLE;
	}
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == g_hAdminMenu)
	{
		return;
	}
	g_hAdminMenu = topmenu;
	AttachAdminMenu();
}

AttachAdminMenu()
{
	/* If the category is third party, it will have its own unique name. */
	new TopMenuObject:player_commands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		/* Error! */
		return;
	}
 
	AddToTopMenu(g_hAdminMenu, 
		"sm_teamban",
		TopMenuObject_Item,
		AdminMenu_Teamban,
		player_commands,
		"sm_teamban",
		ADMFLAG_BAN);
}
 
public AdminMenu_Teamban(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Team Ban");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayTeambanMenu(param);
	}
}

DisplayTeambanMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Teamban);
	
	SetMenuTitle(hMenu, "Team ban player");
	SetMenuExitBackButton(hMenu, true);
	
	AddTargetsToMenu(hMenu, client);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Teamban(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			DisplayTeambanTypeMenu(param1, target);
		}
	}
}

DisplayTeambanTypeMenu(client, target)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Teambantype);
	
	decl String:szTitle[100];
	Format(szTitle, sizeof(szTitle), "Team ban %N", target);
	SetMenuTitle(hMenu, szTitle);
	SetMenuExitBackButton(hMenu, true);

	// Get targets team ban bitmask
	decl String:szBanMask[16];
	GetClientCookie(target, g_hCookie, szBanMask, sizeof(szBanMask));
	new iBanMask = StringToInt(szBanMask);
	
	decl String:szTeam[16];
	decl String:szInfo[100];
	for (new i = 1; i < GetTeamCount(); i++)
	{
		GetTeamName(i, szTeam, sizeof(szTeam));
		Format(szInfo, sizeof(szInfo), "%d %d", GetClientUserId(target), i);
		if (1<<i & iBanMask)
		{
			Format(szTitle, sizeof(szTitle), "Unban from %s", szTeam);
			AddMenuItem(hMenu, szInfo, szTitle);
		}
		else if (TeamEnabled(i))
		{
			Format(szTitle, sizeof(szTitle), "Ban from %s", szTeam);
			AddMenuItem(hMenu, szInfo, szTitle);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Teambantype(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE)
		{
			DisplayTeambanMenu(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[64];
		decl String:infos[2][32];
		new userid, iTeam;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		ExplodeString(info, " ", infos, sizeof(infos), sizeof(infos[]));
		userid = StringToInt(infos[0]);
		iTeam = StringToInt(infos[1]);
		new target;

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			// Get targets team ban bitmask
			decl String:szBanMask[16];
			GetClientCookie(target, g_hCookie, szBanMask, sizeof(szBanMask));
			new iBanMask = StringToInt(szBanMask);
			if (1<<iTeam & iBanMask)
			{
				// Unban them from the team
				iBanMask &= ~ 1<<iTeam;
				IntToString(iBanMask, szBanMask, sizeof(szBanMask));
				SetClientCookie(target, g_hCookie, szBanMask);
				
				decl String:szTeam[16];
				GetTeamName(iTeam, szTeam, sizeof(szTeam));
				ShowActivity(param1, "Unbanned %N from %s", target, szTeam);
			}
			else
			{
				iBanMask |= 1<<iTeam;
				IntToString(iBanMask, szBanMask, sizeof(szBanMask));
				SetClientCookie(target, g_hCookie, szBanMask);
				// Check if they are on the team they are banned from, if so move them to the highest available team.
				if (GetClientTeam(target) == iTeam)
				{
					for (new i = GetTeamCount()-1; i > 0; i--)
					{
						if (!(1<<i & iBanMask))
						{
							ChangeClientTeam(target, i);
							break;
						}
					}
				}
				decl String:szTeam[16];
				GetTeamName(iTeam, szTeam, sizeof(szTeam));
				ShowActivity(param1, "Banned %N from %s", target, szTeam);
			}
		}
	}
}


public Action:Command_Teamban(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teamban <#userid|name> <team>");
		return Plugin_Handled;
	}

	decl String:szArgs[256];
	GetCmdArgString(szArgs, sizeof(szArgs));

	decl String:szArg[65];
	new iLen = BreakString(szArgs, szArg, sizeof(szArg));

	new target = FindTarget(client, szArg, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	BreakString(szArgs[iLen], szArg, sizeof(szArg));
	new iTeam = GetIndexFromTeam(szArg);
	if (iTeam == -1)
	{
		ReplyToCommand(client, "[SM] Error: %s is not a valid team name", szArg);
		return Plugin_Handled;
	}

	// Get targets team ban bitmask
	decl String:szBanMask[16];
	GetClientCookie(target, g_hCookie, szBanMask, sizeof(szBanMask));
	new iBanMask = StringToInt(szBanMask);
	// Check if they are already banned
	if (1<<iTeam & iBanMask)
	{
		ReplyToCommand(client, "[SM] Error: %N is already banned from %s", target, szArg);
		return Plugin_Handled;
	}
	if (!TeamEnabled(iTeam))
	{
		ReplyToCommand(client, "[SM] Error: Banning from %s is disabled", szArg);
		return Plugin_Handled;
	}

	
	// Ban them from the team
	iBanMask |= 1<<iTeam;
	IntToString(iBanMask, szBanMask, sizeof(szBanMask));
	SetClientCookie(target, g_hCookie, szBanMask);
	
	// Check if they are on the team they are banned from, if so move them to the highest available team.
	if (GetClientTeam(target) == iTeam)
	{
		for (new i = GetTeamCount()-1; i > 0; i--)
		{
			if (!(1<<i & iBanMask))
			{
				ChangeClientTeam(target, i);
				break;
			}
		}
	}
	decl String:szTeam[16];
	GetTeamName(iTeam, szTeam, sizeof(szTeam));
	ShowActivity(client, "Banned %N from %s", target, szTeam);
	return Plugin_Handled;
}

public Action:Command_Teamunban(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teamunban <#userid|name> <team>");
		return Plugin_Handled;
	}

	decl String:szArgs[256];
	GetCmdArgString(szArgs, sizeof(szArgs));

	decl String:szArg[65];
	new iLen = BreakString(szArgs, szArg, sizeof(szArg));

	new target = FindTarget(client, szArg, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	BreakString(szArgs[iLen], szArg, sizeof(szArg));
	new iTeam = GetIndexFromTeam(szArg);
	if (iTeam == -1)
	{
		ReplyToCommand(client, "[SM] Error: %s is not a valid team name", szArg);
		return Plugin_Handled;
	}

	// Get targets team ban bitmask
	decl String:szBanMask[16];
	GetClientCookie(target, g_hCookie, szBanMask, sizeof(szBanMask));
	new iBanMask = StringToInt(szBanMask);
	// Check if they are already banned
	if (!(1<<iTeam & iBanMask))
	{
		ReplyToCommand(client, "[SM] Error: %N is not banned from %s", target, szArg);
		return Plugin_Handled;
	}
	
	// Unban them from the team
	iBanMask &= ~ 1<<iTeam;
	IntToString(iBanMask, szBanMask, sizeof(szBanMask));
	SetClientCookie(target, g_hCookie, szBanMask);
	
	decl String:szTeam[16];
	GetTeamName(iTeam, szTeam, sizeof(szTeam));
	ShowActivity(client, "Unbanned %N from %s", target, szTeam);
	return Plugin_Handled;
}


public Action:Command_Jointeam(client, const String:command[], args)
{
	// Get the team name of the team the person is trying to join
	decl String:szTeam[16];
	GetCmdArg(1, szTeam, sizeof(szTeam));
	// Convert team name into an index
	new iTeam = GetIndexFromTeam(szTeam);
	// If we don't know what the team name is, bail out
	if (iTeam == -1)
	{
		return Plugin_Continue;
	}
	
	// Get the players banned team mask
	decl String:szBanMask[16];
	GetClientCookie(client, g_hCookie, szBanMask, sizeof(szBanMask));
	new iBanMask = StringToInt(szBanMask);
	
	// Is the player banned from this team? block it.
	if (1<<iTeam & iBanMask)
	{
		decl String:szTeamName[16];
		GetTeamName(iTeam, szTeamName, sizeof(szTeamName));
		PrintToChat(client, "[SM] You are banned from %s", szTeamName);
		// If they arn't on any teams, put them on one otherwise the menu bugs out
		if (GetClientTeam(client) == 0)
		{
			for (new i = GetTeamCount()-1; i > 0; i--)
			{
				if (!(1<<i & iBanMask))
				{
					ChangeClientTeam(client, i);
					break;
				}
			}
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

GetIndexFromTeam(const String:team[])
{
	// Convert a team name (eg CT to a team index eg 1)
	if (IsStringNumeric(team))
		return StringToInt(team);
	decl String:szTeam[16];
	for (new i = 1; i < GetTeamCount(); i++)
	{
		GetTeamName(i, szTeam, sizeof(szTeam));
		if (StrEqual(szTeam, team, false))
				return i;
	}
	return -1;
}

IsStringNumeric(const String:numeric[])
{
	for (new i = 0; i < strlen(numeric); i++)
	{
		if (!IsCharNumeric(numeric[i]))
		{
			return false;
		}
	}
	return true;
}

TeamEnabled(iTeam)
{
	new iDisabled = GetConVarInt(g_hcvarDisabled);
	if (1<<iTeam & iDisabled)
		return false;
	return true;
}
