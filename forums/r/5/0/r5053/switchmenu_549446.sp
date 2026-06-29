/*include includes :) */
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
/* #include <cstrike> */

/* register Switch after death Player array */
new plswitchad[64]

/* register ints */

new modcstrike = 0

/* register Death match int. */
new game_dm;

/* Define Team id's */
new TEAM_1 = 3
new TEAM_2 = 2
new TEAM_spec = 1

/* define Plugin version */
#define PLUGIN_VERSION "0.2.4"

/* Create Handles */
new Handle:hTopMenu = INVALID_HANDLE;
new Handle:g_CvarDM

/* Register Strings */
new String:modfolder[32]

/* Create Plugin info */
public Plugin:myinfo = 
{
	name = "Teamswitch Menu",
	author = "R-Hehl",
	description = "Menu to switch players",
	version = PLUGIN_VERSION,
	url = "http://www.compactaim.de/"
};
public GetOtherTeam(team)
{
	if(team == TEAM_2)
		return TEAM_1;
	else
		return TEAM_2;
}
public OnClientPostAdminCheck(client)
{
	plswitchad[client]=0;
}
public OnPluginStart()
{
	/* load menu translations */ 
	LoadTranslations("common.phrases");
	/* Create Convar to identify plugin version */
	CreateConVar("sm_switch_menu_version", PLUGIN_VERSION, "Switch Player Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	detectmod()
	Setteamidformod()
	g_CvarDM = CreateConVar("sm_switch_event", "1", "0 = Switch on Round End, 1 = Switch After Death", 0, true, 0.0, true, 1.0);
	/* Set Game Mod */
	game_dm = GetConVarInt(g_CvarDM)
	/* Hook Player Death and Round end for switch after death function */
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	HookConVarChange(g_CvarDM, OnsweventChange)
	/* Register Console Command for menu opening */
	RegAdminCmd("sm_swmenu", Menu_swp, ADMFLAG_GENERIC, "Switches Player Menu");
	RegAdminCmd("sm_swadmenu", Menu_swpad, ADMFLAG_GENERIC, "Switches Player After Death Menu");
	RegAdminCmd("sm_swteams", swteams, ADMFLAG_GENERIC, "Switches The Team's");
	RegAdminCmd("sm_swspec", Menu_swspec, ADMFLAG_GENERIC, "Switche Player to Spectator");
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

}
detectmod()
{
GetGameFolderName(modfolder,sizeof(modfolder))
}
Setteamidformod()
{
if (strcmp(modfolder, "insurgency", true) == 0)
	{
	TEAM_1 = 1
	TEAM_2 = 2
	TEAM_spec = 3
	}
else if (strcmp(modfolder, "cstrike", true) == 0)
	{
modcstrike = 1
	}
	
	
}
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}

	/* Save the Handle */
	hTopMenu = topmenu;

	new TopMenuObject:fun_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	AddToTopMenu(hTopMenu, 
		"sm_swmenuad",
		TopMenuObject_Item,
		AdminMenu_swad,
		fun_commands,
		"sm_swmenuad",
		ADMFLAG_GENERIC);
	AddToTopMenu(hTopMenu, 
		"sm_swmenu",
		TopMenuObject_Item,
		AdminMenu_sw,
		fun_commands,
		"sm_swmenu",
		ADMFLAG_GENERIC);
	AddToTopMenu(hTopMenu, 
		"sm_swteams",
		TopMenuObject_Item,
		AdminMenu_teams,
		fun_commands,
		"sm_swteams",
		ADMFLAG_GENERIC);
	AddToTopMenu(hTopMenu, 
		"sm_swspec",
		TopMenuObject_Item,
		AdminMenu_swspec,
		fun_commands,
		"sm_swspec",
		ADMFLAG_GENERIC);
	AddToTopMenu(hTopMenu, 
		"sm_scrambleteams",
		TopMenuObject_Item,
		AdminMenu_scramble,
		fun_commands,
		"sm_scrambleteams",
		ADMFLAG_GENERIC);
}
/* menu handles */
public AdminMenu_scramble(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Scramble Teams");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ServerCommand("mp_scrambleteams 1")
	}
}
public AdminMenu_swspec(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch Player to Spectator");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Menu_swspec(param,param);
	}
}
public AdminMenu_teams(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch Teams");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		swteams(param,param);
	}
}
public AdminMenu_sw(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch Player Team");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Menu_swp(param,param);
	}
}
public AdminMenu_swad(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch Player on Death");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Menu_swpad(param,param);
	}
}
/* comand fuction's */
public Action:swteams(client, args)
{
	new String:whoname[64];
	GetClientName(client, whoname, 64);
	PrintToChatAll("%s has switched the Teams",whoname)
	new maxplayers
	maxplayers = GetMaxClients()
	for (new i=1; i<=maxplayers; i++)
	{
		if (IsClientConnected(i))
		{
		if (modcstrike == 1)
		{
		/* CS_SwitchTeam(i, GetOtherTeam(GetClientTeam(i))); */
		}
		else
		{
		ChangeClientTeam(i, GetOtherTeam(GetClientTeam(i)));
		}
		plswitchad[i]=0
		}
	}
}
/* Menus */
public Action:Menu_swpad(client, args)
{
	new Handle:menu = CreateMenu(MenuHandlerswad)
	SetMenuTitle(menu, "Switch Player")
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			decl String:name[65];
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name)
		}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
 
	return Plugin_Handled
}
public Action:Menu_swspec(client, args)
{
	new Handle:menu = CreateMenu(MenuHandlerswspec)
	SetMenuTitle(menu, "Switch Player to Spectator")
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			decl String:name[65];
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name)
		}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
 
	return Plugin_Handled
}
public Action:Menu_swp(client, args)
{
	new Handle:menu = CreateMenu(MenuHandlerswp)
	SetMenuTitle(menu, "Switch Player")
	/* List all players */
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			decl String:name[65];
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name)
		}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
 
	return Plugin_Handled
}

/*Menu handlers*/
public MenuHandlerswp(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[64]
		GetMenuItem(menu, param2, info, sizeof(info))
		PrintToConsole(param1, "You selected item: %s", info)
		new maxplayers, target = -1
		maxplayers = GetMaxClients()
		for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientConnected(i))
		{
			continue
		}
		decl String:other[64]
		GetClientName(i, other, sizeof(other))
		if (StrEqual(info, other))
		{
			target = i
		}
	}
		
		if (modcstrike == 1)
		{
		/* CS_SwitchTeam(target, GetOtherTeam(GetClientTeam(target))); */
		}
		else
		{
		ChangeClientTeam(target, GetOtherTeam(GetClientTeam(target)));
		}
		new String:tgtname[64];
		new String:whoname[64];
		GetClientName(target, tgtname, 64);
		GetClientName(param1, whoname, 64);
		PrintToChatAll("%s 's team is now switched by %s",tgtname ,whoname)
		Menu_swp(param1,param1);
	}  
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
public MenuHandlerswspec(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[64]
		GetMenuItem(menu, param2, info, sizeof(info))
		new maxplayers, target = -1
		maxplayers = GetMaxClients()
		for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientConnected(i))
		{
			continue
		}
		decl String:other[64]
		GetClientName(i, other, sizeof(other))
		if (StrEqual(info, other))
		{
			target = i
		}
	}
		
		if (modcstrike == 1)
		{
		/* CS_SwitchTeam(target, TEAM_spec); */
		}
		else
		{
		ChangeClientTeam(target, TEAM_spec);
		}
		new String:tgtname[64];
		new String:whoname[64];
		GetClientName(target, tgtname, 64);
		GetClientName(param1, whoname, 64);
		PrintToChatAll("%s 's is now switched to spectator by %s",tgtname ,whoname)
		Menu_swspec(param1,param1);
	}  
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
public MenuHandlerswad(Handle:menu, MenuAction:action, param1, param2)
{
	new maxplayers, target = -1
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
	new String:info[64]
	GetMenuItem(menu, param2, info, sizeof(info))
	maxplayers = GetMaxClients()
	for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientConnected(i))
		{
			continue
		}
		decl String:other[64]
		GetClientName(i, other, sizeof(other))
		if (StrEqual(info, other))
		{
			target = i
		}
	}
 	PrintToChatAll("%s 's team will be switched after death",info)
 	plswitchad[target]=1;
 	Menu_swpad(param1,param1);
	} 
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
/*events handles */

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (game_dm != 0)
	{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	if (plswitchad[victim] == 1)
	{
		
		if (modcstrike == 1)
		{
		/* CS_SwitchTeam(victim, GetOtherTeam(GetClientTeam(victim))); */
		}
		else
		{
		ChangeClientTeam(victim, GetOtherTeam(GetClientTeam(victim)));
		}
		plswitchad[victim]=0
	}
}
}
public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (game_dm == 0)
	{
	new maxplayers
	maxplayers = GetMaxClients()
	for (new i=1; i<=maxplayers; i++)
	{
		if (IsClientConnected(i))
		{
			if (plswitchad[i] == 1)
			{
			if (modcstrike == 1)
			{
			/* CS_SwitchTeam(i, GetOtherTeam(GetClientTeam(i))); */
			}
			else
			{
			ChangeClientTeam(i, GetOtherTeam(GetClientTeam(i)));
			}
			plswitchad[i]=0
			}
		}
	}
}
}

public OnsweventChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
game_dm = StringToInt(newVal)
}