#pragma semicolon 1

#include <adminmenu>
#include <sdktools>
#include <teamsmanagementinterface>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.4.0"

//Flags : (used for menus)
#define	REMOVE_TEAMLESS		(1<<0)
#define	REMOVE_SPECTATORS	(1<<1)
#define	REMOVE_TERRORISTS	(1<<2)
#define	REMOVE_CTS			(1<<3)

public Plugin:myinfo =
{
	name = "Teams Management Commands",
	author = "RedSword / Bob Le Ponge",
	description = "Allow various Teams Management related commands.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Better use of interface
#define TMC_PRIORITY 100
enum TM_Reason
{
	REASON_ADMIN = 1
};

//Cvars
new Handle:g_tmc;
new Handle:g_tmc_verbose_global;
new Handle:g_tmc_verbose_indiv;
new Handle:g_tmc_verbose_clan;
new Handle:g_tmc_log;
new Handle:g_tmc_sound;
new Handle:g_tmc_fadeColor;
new Handle:g_tmc_required_value;
new Handle:g_tmc_required_team;

//actions CVars

new Handle:g_tmc_allow_scramble_fair;
new Handle:g_tmc_allow_scramble_unfair;
new Handle:g_tmc_allow_scramble_specific;
new Handle:g_tmc_allow_team_prevent;
new Handle:g_tmc_allow_team_cancel;
new Handle:g_tmc_allow_switch_indiv;
new Handle:g_tmc_allow_switch_spec;
new Handle:g_tmc_allow_switch_clan;
new Handle:g_tmc_allow_switch_clan_menu;

//Menu
#define ADMINMENU_TEAMSMANAGEMENT		"TeamsManagementCat"
#define ADMINMENU_TEAMSMANAGEMENT_STR	"Teams Management"
new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:obj_teamsmanagementcmds = INVALID_TOPMENUOBJECT;

//Vars
new String:g_szPlayerTeamPrefix[ MAXPLAYERS + 1 ][ 5 ]; //doesn't look like a 6th element is needed, PrintTo probably do a sizeof

//Multi-mod allowance
new bool:g_bIsCSS;

//==== Forwards

public OnPluginStart()
{
	//Allow multiples mod
	decl String:szBuffer[ 16 ];
	GetGameFolderName( szBuffer, sizeof(szBuffer) );
	
	g_bIsCSS = StrEqual( szBuffer, "cstrike", false );
	
	//CVARs
	CreateConVar("teamsmanagementcommandsversion", PLUGIN_VERSION, "Teams Management Commands version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_tmc = CreateConVar("teamsmanagementcommands", "1", "Is the plugin enabled ? 0=No, 1=Yes. Def. 1", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Seeing action
	g_tmc_verbose_global = CreateConVar("tmc_verbose_global", "1", "Show globals Teams Management to everyone ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_tmc_verbose_indiv = CreateConVar("tmc_verbose_indiv", "1", "Show individual Teams Management to everyone ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_tmc_verbose_clan = CreateConVar("tmc_verbose_clan", "1", "Show clan Teams Management to everyone ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_tmc_log = CreateConVar("tmc_log", "1", "Should the plugin log ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	//Sounds
	g_tmc_sound = CreateConVar( "tmc_sound", "1", "Ask TMI to play a sound when teams are scrambled? 1=Yes, 0=No. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		
	//Fade
	g_tmc_fadeColor = CreateConVar( "tmc_fade", "1", "Fade-in players screens when teams are scrambled. 0 = disabled, 1 = enabled. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//3rd mode
	g_tmc_required_value = CreateConVar( "tmc_required_value", "1", "If CVar 'ats' value is '3', then a team will have X players. Min 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 1.0, true, 64.0 );
	g_tmc_required_team = CreateConVar( "tmc_required_team", "1", "If CVar 'ats' value is '3', then specified team will have an exact number of players. 0 = terro, 1 = CTs.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		
	//Menu allow
	g_tmc_allow_scramble_fair = CreateConVar( "tmc_allow_scramble_fair", "1", "Allow fair teams scramble ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_tmc_allow_scramble_unfair = CreateConVar( "tmc_allow_scramble_unfair", "1", "Allow unfair teams scramble ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_tmc_allow_scramble_specific = CreateConVar( "tmc_allow_scramble_specific", "1", "Allow specific teams scramble ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		
	g_tmc_allow_team_prevent = CreateConVar( "tmc_allow_team_prevent", "1", "Allow to prevent teams scramble ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_tmc_allow_team_cancel = CreateConVar( "tmc_allow_team_cancel", "1", "Allow to cancel teams scramble ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		
	g_tmc_allow_switch_indiv = CreateConVar( "tmc_allow_changeteam", "1", "Allow a single person to change team ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	g_tmc_allow_switch_spec = CreateConVar( "tmc_allow_spec", "1", "Allow switching to spec (instant) ? 1=Yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		
	if ( g_bIsCSS )
	{
		g_tmc_allow_switch_clan = CreateConVar( "tmc_allow_clanchangeteam", "0", "Allow to change clan's members' team ? 1=Yes, 0=No (default).", 
			FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		g_tmc_allow_switch_clan_menu = CreateConVar( "tmc_allow_clanchangeteam_menu", "1", "Allow to change clan's members' team through menu ? 1=Yes (default).", 
			FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	}
	
	//Config
	AutoExecConfig( true, "teamsmanagementcommands" );
		
	//Commands
	RegAdminCmd("sm_scramble_fair", Command_ScrambleFair, ADMFLAG_BAN, "sm_scramble_fair");
	RegAdminCmd("sm_scramble_unfair", Command_ScrambleUnfair, ADMFLAG_BAN, "sm_scramble_unfair");
	RegAdminCmd("sm_scramble_specificteam", Command_ScrambleSpecificTeam, ADMFLAG_BAN, "sm_scramble_specificteam");
	
	RegAdminCmd("sm_tm_prevent", Command_TeamPrevent, ADMFLAG_BAN, "sm_tm_prevent");
	RegAdminCmd("sm_tm_cancel", Command_TeamCancel, ADMFLAG_BAN, "sm_tm_cancel");
	
	RegAdminCmd("sm_teamt", Command_SetTeamTerro, ADMFLAG_BAN, "sm_teamt <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_teamct", Command_SetTeamCT, ADMFLAG_BAN, "sm_teamct <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_teamspec", Command_SetTeamSpec, ADMFLAG_BAN, "sm_teamspec <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_changeteam", Command_ChangeTeam, ADMFLAG_BAN, "sm_changeteam <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_cteam", Command_ChangeTeam, ADMFLAG_BAN, "sm_cteam <#userid|name|[aimedTarget]>"); //shortcut
	RegAdminCmd("sm_cancelchangeteam", Command_CancelChangeTeam, ADMFLAG_BAN, "sm_cancelchangeteam <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_ccteam", Command_CancelChangeTeam, ADMFLAG_BAN, "sm_cancelchangeteam <#userid|name|[aimedTarget]>"); //shortcut
	
	if ( g_bIsCSS )
	{
		//The following ALL fails with tags having quotes in them
		RegAdminCmd("sm_clanteamt", Command_ClanSetTeamTerro, ADMFLAG_BAN, "sm_clanteamt <tag>");
		RegAdminCmd("sm_clanteamct", Command_ClanSetTeamCT, ADMFLAG_BAN, "sm_clanteamct <tag>");
		RegAdminCmd("sm_clanteamspec", Command_ClanSetTeamSpec, ADMFLAG_BAN, "sm_clanteamspec <tag>");
		RegAdminCmd("sm_clanchangeteam", Command_ClanChangeTeam, ADMFLAG_BAN, "sm_clanchangeteam <tag>");
		RegAdminCmd("sm_clancancelchangeteam", Command_ClanCancelChangeTeam, ADMFLAG_BAN, "sm_clancancelchangeteam <tag>");
	}
	
	//Translation file
	LoadTranslations("common.phrases");
	LoadTranslations("adminmenu.phrases");
	LoadTranslations("teamsmanagementcommands.phrases");
	
	//Menu
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuCreated(topmenu);
		OnAdminMenuReady(topmenu);
	}
}
public OnClientDisconnect(client)
{
	g_szPlayerTeamPrefix[ client ][ 0 ] = '\0';
}
public OnTeamsManagementExecutedRequest( const Handle:plugin, 
	const reasonId,
	const priority, 
	const TeamsManagementType:type,
	const actionId, 
	const any:customValue, 
	const flags)
{
	//No need to check plugin; wherever it is from we need to clean name's prefixes
	if ( TeamsManagementType:type == TeamsManagementType:TMT_TEAMS )
	{
		for ( new i = 1; i <= MaxClients; ++i )
		{
			g_szPlayerTeamPrefix[ i ][ 0 ] = '\0';
		}
	}
	else if ( TeamsManagementType:type == TeamsManagementType:TMT_INDIVIDUALS &&
		customValue >= 1 && 
		customValue <= MAXPLAYERS )
	{
		if ( customValue >= 1 && customValue <= MAXPLAYERS )
		{
			g_szPlayerTeamPrefix[ customValue ][ 0 ] = '\0';
		}
	}
}
public OnTeamsManagementAbandonedRequest( const Handle:plugin, 
	const reasonId,
	const priority, 
	const TeamsManagementType:type,
	const actionId, 
	const any:customValue, 
	const flags)
{
	if ( plugin == GetMyHandle() &&
		TeamsManagementType:type == TeamsManagementType:TMT_INDIVIDUALS &&
		customValue >= 1 && 
		customValue <= MAXPLAYERS )
	{
		if ( customValue >= 1 && customValue <= MAXPLAYERS )
		{
			g_szPlayerTeamPrefix[ customValue ][ 0 ] = '\0';
		}
	}
}

//===== Menu

//OnMenuCreated --> Add categories
public OnAdminMenuCreated(Handle:topmenu)
{
	new String:szBuffer[32] = ADMINMENU_TEAMSMANAGEMENT;
	
	//Create category if it doesn't exist
	if ((obj_teamsmanagementcmds = FindTopMenuCategory(topmenu, szBuffer)) == INVALID_TOPMENUOBJECT)
	{
		obj_teamsmanagementcmds = AddToTopMenu(topmenu,
			szBuffer,
			TopMenuObject_Category,
			TeamsManagementCategoryHandler,
			INVALID_TOPMENUOBJECT,
			"TeamsManagementOverride",
			ADMFLAG_BAN,
			ADMINMENU_TEAMSMANAGEMENT_STR);
	}
}

//Seems required (http://wiki.alliedmods.net/Admin_Menu_(SourceMod_Scripting))
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

//OnMenuReady --> Add sub-categories
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the category */
	new TopMenuObject:teamsmanagement_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_TEAMSMANAGEMENT);

	if (teamsmanagement_commands != INVALID_TOPMENUOBJECT)
	{
		//Scrambles
		AddToTopMenu(hTopMenu,
			"sm_scramble_fair",
			TopMenuObject_Item,
			AdminMenu_ScrambleFair,
			teamsmanagement_commands,
			"sm_scramble_fair",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_scramble_unfair",
			TopMenuObject_Item,
			AdminMenu_ScrambleUnfair,
			teamsmanagement_commands,
			"sm_scramble_unfair",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_scramble_specificteam",
			TopMenuObject_Item,
			AdminMenu_ScrambleSpecificTeam,
			teamsmanagement_commands,
			"sm_scramble_specificteam",
			ADMFLAG_BAN);
		
		//Single player team
		AddToTopMenu(hTopMenu,
			"sm_tm_prevent",
			TopMenuObject_Item,
			AdminMenu_TeamPrevent,
			teamsmanagement_commands,
			"sm_tm_prevent",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_tm_cancel",
			TopMenuObject_Item,
			AdminMenu_TeamCancel,
			teamsmanagement_commands,
			"sm_tm_cancel",
			ADMFLAG_BAN);
		
		AddToTopMenu(hTopMenu,
			"sm_teamt",
			TopMenuObject_Item,
			AdminMenu_SetTeamTerro,
			teamsmanagement_commands,
			"sm_teamt",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_teamct",
			TopMenuObject_Item,
			AdminMenu_SetTeamCT,
			teamsmanagement_commands,
			"sm_teamct",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_teamspec",
			TopMenuObject_Item,
			AdminMenu_SetTeamSpec,
			teamsmanagement_commands,
			"sm_teamspec",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_changeteam",
			TopMenuObject_Item,
			AdminMenu_ChangeTeam,
			teamsmanagement_commands,
			"sm_changeteam",
			ADMFLAG_BAN);
		AddToTopMenu(hTopMenu,
			"sm_cancelchangeteam",
			TopMenuObject_Item,
			AdminMenu_CancelChangeTeam,
			teamsmanagement_commands,
			"sm_cancelchangeteam",
			ADMFLAG_BAN);
		
		//Clan team
		if ( g_bIsCSS )
		{
			AddToTopMenu(hTopMenu,
				"sm_clanteamt",
				TopMenuObject_Item,
				AdminMenu_ClanSetTeamTerro,
				teamsmanagement_commands,
				"sm_clanteamt",
				ADMFLAG_BAN);
			AddToTopMenu(hTopMenu,
				"sm_clanteamct",
				TopMenuObject_Item,
				AdminMenu_ClanSetTeamCT,
				teamsmanagement_commands,
				"sm_clanteamct",
				ADMFLAG_BAN);
			AddToTopMenu(hTopMenu,
				"sm_clanteamspec",
				TopMenuObject_Item,
				AdminMenu_ClanSetTeamSpec,
				teamsmanagement_commands,
				"sm_clanteamspec",
				ADMFLAG_BAN);
			AddToTopMenu(hTopMenu,
				"sm_clanchangeteam",
				TopMenuObject_Item,
				AdminMenu_ClanChangeTeam,
				teamsmanagement_commands,
				"sm_clanchangeteam",
				ADMFLAG_BAN);
			AddToTopMenu(hTopMenu,
				"sm_clancancelchangeteam",
				TopMenuObject_Item,
				AdminMenu_ClanCancelChangeTeam,
				teamsmanagement_commands,
				"sm_clancancelchangeteam",
				ADMFLAG_BAN);
		}
	}
}

public TeamsManagementCategoryHandler(Handle:topmenu, 
						TopMenuAction:action,
						TopMenuObject:object_id,
						param,
						String:buffer[],
						maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		if (object_id == INVALID_TOPMENUOBJECT)
		{
			FormatEx(buffer, maxlength, "%T:", "Admin Menu", param);
		}
		else if (object_id == obj_teamsmanagementcmds)
		{
			FormatEx(buffer, maxlength, ADMINMENU_TEAMSMANAGEMENT_STR);
		}
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == obj_teamsmanagementcmds)
		{
			FormatEx(buffer, maxlength, ADMINMENU_TEAMSMANAGEMENT_STR);
		}
	}
}

//==== AdminMenu CMD
public AdminMenu_ScrambleFair(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ScrambleFair", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_ScrambleFair(param, 0);
	}
}
public AdminMenu_ScrambleUnfair(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ScrambleUnfair", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_ScrambleUnfair(param, 0);
	}
}
public AdminMenu_ScrambleSpecificTeam(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ScrambleSpecificTeam", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_ScrambleSpecificTeam(param, 0);
	}
}
public AdminMenu_TeamPrevent(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu TeamPrevent", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_TeamPrevent(param, 0);
	}
}
public AdminMenu_TeamCancel(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu TeamCancel", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_TeamCancel(param, 0);
	}
}

//Since 1.1
public AdminMenu_SetTeamTerro(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu TeamTerro 11", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		menu_SetTeamTerro(param);
	}
}
menu_SetTeamTerro(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SetTeamTerro);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu TeamTerro 11", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addPlayersToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_SetTeamTerro(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		if (GetClientOfUserId(StringToInt(info)) == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_teamt #%s", info);
			FakeClientCommand(param1, cmd);
		}
		
		menu_SetTeamTerro(param1);
	}
}
public AdminMenu_SetTeamCT(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu TeamCT 11", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		menu_SetTeamCT(param);
	}
}
menu_SetTeamCT(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SetTeamCT);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu TeamCT 11", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addPlayersToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_SetTeamCT(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		if (GetClientOfUserId(StringToInt(info)) == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_teamct #%s", info);
			FakeClientCommand(param1, cmd);
		}
		
		menu_SetTeamCT(param1);
	}
}
//Since 1.4.0
public AdminMenu_SetTeamSpec(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu TeamSpec 14", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		menu_SetTeamSpec(param);
	}
}
menu_SetTeamSpec(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SetTeamSpec);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu TeamSpec 14", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addPlayersToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_SetTeamSpec(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		if (GetClientOfUserId(StringToInt(info)) == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_teamspec #%s", info);
			FakeClientCommand(param1, cmd);
		}
		
		menu_SetTeamSpec(param1);
	}
}
public AdminMenu_ChangeTeam(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ChangeTeam 11", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		menu_ChangeTeam(param);
	}
}
menu_ChangeTeam(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ChangeTeam);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu ChangeTeam 11", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addPlayersToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_ChangeTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		if (GetClientOfUserId(StringToInt(info)) == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_changeteam #%s", info);
			FakeClientCommand(param1, cmd);
		}
		
		menu_ChangeTeam(param1);
	}
}
public AdminMenu_CancelChangeTeam(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu CancelChangeTeam 11", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//Create a new func that creates the menu and call it, so we can call it too in the handler to make the menu not disappear
		menu_CancelChangeTeam(param);
	}
}
menu_CancelChangeTeam(client)
{
	new Handle:menu = CreateMenu(MenuHandler_CancelChangeTeam);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu CancelChangeTeam 11", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addPlayersToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_CancelChangeTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		if (GetClientOfUserId(StringToInt(info)) == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_cancelchangeteam #%s", info);		
			FakeClientCommand(param1, cmd);
		}
		
		menu_CancelChangeTeam(param1);
	}
}
//Since 1.3 (clans)
public AdminMenu_ClanSetTeamTerro(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ClanTeamTerro 13", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//Create a new func that creates the menu and call it, so we can call it too in the handler to make the menu not disappear
		menu_ClanSetTeamTerro(param);
	}
}
menu_ClanSetTeamTerro(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ClanSetTeamTerro);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu ClanTeamTerro 13", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addClansToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_ClanSetTeamTerro(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has clan tag
		
		FromMenu_ClanSetTeamTerroWithId(param1, info, sizeof(info));
		
		menu_ClanSetTeamTerro(param1);
	}
}
public AdminMenu_ClanSetTeamCT(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ClanTeamCT 13", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//Create a new func that creates the menu and call it, so we can call it too in the handler to make the menu not disappear
		menu_ClanSetTeamCT(param);
	}
}
menu_ClanSetTeamCT(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ClanSetTeamCT);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu ClanTeamCT 13", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addClansToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_ClanSetTeamCT(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has clan tag
		
		FromMenu_ClanSetTeamCTWithId(param1, info, sizeof(info));
		
		menu_ClanSetTeamCT(param1);
	}
}
//Since 1.4.0 (spec)
public AdminMenu_ClanSetTeamSpec(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ClanTeamSpec 14", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//Create a new func that creates the menu and call it, so we can call it too in the handler to make the menu not disappear
		menu_ClanSetTeamSpec(param);
	}
}
menu_ClanSetTeamSpec(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ClanSetTeamSpec);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu ClanTeamSpec 14", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addClansToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_ClanSetTeamSpec(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has clan tag
		
		FromMenu_ClanSetTeamSpecWithId(param1, info, sizeof(info));
		
		menu_ClanSetTeamSpec(param1);
	}
}
public AdminMenu_ClanChangeTeam(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ClanChangeTeam 13", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//Create a new func that creates the menu and call it, so we can call it too in the handler to make the menu not disappear
		menu_ClanChangeTeam(param);
	}
}
menu_ClanChangeTeam(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ClanChangeTeam);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu ClanChangeTeam 13", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addClansToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_ClanChangeTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has clan tag
		
		FromMenu_ClanChangeTeamWithId(param1, info, sizeof(info));
		
		menu_ClanChangeTeam(param1);
	}
}
public AdminMenu_ClanCancelChangeTeam(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "AdminMenu ClanCancelChangeTeam 13", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//Create a new func that creates the menu and call it, so we can call it too in the handler to make the menu not disappear
		menu_ClanCancelChangeTeam(param);
	}
}
menu_ClanCancelChangeTeam(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ClanCancelChangeTeam);
	
	decl String:title[100];
	FormatEx(title, sizeof(title), "%T:", "AdminMenu ClanCancelChangeTeam 13", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	addClansToMenu(menu, REMOVE_TEAMLESS | REMOVE_SPECTATORS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_ClanCancelChangeTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has clan tag
		
		FromMenu_ClanCancelChangeTeamWithId(param1, info, sizeof(info));
		
		menu_ClanCancelChangeTeam(param1);
	}
}


//===== AdminAction CMD & verbose

public Action:Command_ScrambleFair(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_scramble_fair ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
		
	if ( RequestTeamsManagement( any:REASON_ADMIN,
		TMC_PRIORITY,
		TeamsManagementType:TMT_TEAMS,
		1,
		0,
		( GetConVarInt( g_tmc_fadeColor ) == 1 ? FTMI_FADE : 0 ) | ( GetConVarInt( g_tmc_sound ) == 1 ? FTMI_SOUND : 0 ) ) )
	{
		if (GetConVarInt(g_tmc_verbose_global))
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ScrambleFair");
		else
			ReplyToCommand(client, "[SM] %t", "ScrambleFair");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" triggered a fair Teams Scramble", client);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "F_Scramble");
	}
	
	return Plugin_Handled;
}

public Action:Command_ScrambleUnfair(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_scramble_unfair ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if ( RequestTeamsManagement( any:REASON_ADMIN,
		TMC_PRIORITY,
		TeamsManagementType:TMT_TEAMS,
		2,
		0,
		( GetConVarInt( g_tmc_fadeColor ) == 1 ? FTMI_FADE : 0 ) | ( GetConVarInt( g_tmc_sound ) == 1 ? FTMI_SOUND : 0 ) ) )
	{
		if (GetConVarInt(g_tmc_verbose_global))
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ScrambleUnfair");
		else
			ReplyToCommand(client, "[SM] %t", "ScrambleUnfair");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" triggered an unfair Teams Scramble", client);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "F_Scramble");
	}
	
	return Plugin_Handled;
}

public Action:Command_ScrambleSpecificTeam(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_scramble_specific ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if ( RequestTeamsManagement( any:REASON_ADMIN,
		TMC_PRIORITY,
		TeamsManagementType:TMT_TEAMS,
		3,
		GetConVarInt( g_tmc_required_value ) | ( GetConVarInt( g_tmc_required_team ) << 8 ),
		( GetConVarInt( g_tmc_fadeColor ) == 1 ? FTMI_FADE : 0 ) | ( GetConVarInt( g_tmc_sound ) == 1 ? FTMI_SOUND : 0 ) ) )
	{
		decl String:szBuffer[ 12 ];
		getTeamNameConditionalLowerCase( GetConVarInt( g_tmc_required_team ) + 2, szBuffer, sizeof( szBuffer ) );
		
		if (GetConVarInt(g_tmc_verbose_global))
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ScrambleSpecificTeam", "\x04", szBuffer, "\x01", "\x04", GetConVarInt( g_tmc_required_value ), "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ScrambleSpecificTeam", "", szBuffer, "", "", GetConVarInt( g_tmc_required_value ), "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" triggered Teams Scramble (specific teams)", client);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "F_Scramble");
	}
	
	return Plugin_Handled;
}

public Action:Command_TeamPrevent(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_team_prevent ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if ( RequestTeamsManagement( any:REASON_ADMIN,
		TMC_PRIORITY,
		TeamsManagementType:TMT_TEAMS,
		0,
		0,
		0 ) )
	{
		if (GetConVarInt(g_tmc_verbose_global))
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamPrevent");
		else
			ReplyToCommand(client, "[SM] %t", "TeamPrevent");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" did prevent Teams Management", client);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "F_TeamPrevent");
	}
	
	return Plugin_Handled;
}

public Action:Command_TeamCancel(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_team_cancel ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if ( CancelTeamsManagement( TeamsManagementType:TMT_TEAMS,
		TMC_PRIORITY ) )
	{
		if (GetConVarInt(g_tmc_verbose_global))
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamCancel");
		else
			ReplyToCommand(client, "[SM] %t", "TeamCancel");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" did cancel at least one Teams Management", client);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "F_TeamCancel");
	}
	
	return Plugin_Handled;
}

public Action:Command_SetTeamTerro(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_indiv ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	decl String:targetArg[ MAX_NAME_LENGTH ];
	new targetId;
	
	if (args < 1) //If no arg; check target aimed at
	{
		targetId = GetClientAimTarget(client);
	}
	else if (args < 2)
	{
		GetCmdArg(1, targetArg, sizeof(targetArg));
		targetId = FindTarget(client, targetArg);
	}
	
	if (targetId < 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_teamt|say !teamt> <#userid|name|[aimedTarget]>");
		return Plugin_Handled;
	}
	else if (GetClientTeam(targetId) > 1) //T or CT to T
	{
		if ( RequestTeamsManagement( any:REASON_ADMIN,
			TMC_PRIORITY,
			TeamsManagementType:TMT_INDIVIDUALS,
			2,
			targetId,
			0 ) )
		{
			if (GetConVarInt(g_tmc_verbose_indiv))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamTerro 11", "\x04", targetId, "\x01");
			else
				ReplyToCommand(client, "[SM] %t", "TeamTerro 11", "", targetId, "");
			
			if (GetConVarInt(g_tmc_log))
				LogAction(client, targetId, "\"%L\" made \"%L\" be terrorist for the next round", client, targetId);
			
			decl String:szTeamBufferPrefix[ 6 ];
			getTeamNameConditionalLowerCase( 2, szTeamBufferPrefix, 4 );
			szTeamBufferPrefix[ 3 ] = '\0';
			Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
			g_szPlayerTeamPrefix[ targetId ] = szTeamBufferPrefix;
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "F_TeamChange 11");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SetTeamCT(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_indiv ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	decl String:targetArg[ MAX_NAME_LENGTH ];
	new targetId;
	
	if (args < 1) //If no arg; check target aimed at
	{
		targetId = GetClientAimTarget(client);
	}
	else if (args < 2)
	{
		GetCmdArg(1, targetArg, sizeof(targetArg));
		targetId = FindTarget(client, targetArg);
	}
	
	if (targetId < 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_teamct|say !teamct> <#userid|name|[aimedTarget]>");
		return Plugin_Handled;
	}
	else if (GetClientTeam(targetId) > 1) //T or CT to T
	{
		if ( RequestTeamsManagement( any:REASON_ADMIN,
			TMC_PRIORITY,
			TeamsManagementType:TMT_INDIVIDUALS,
			3,
			targetId,
			0 ) )
		{
			if (GetConVarInt(g_tmc_verbose_indiv))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamCT 11", "\x04", targetId, "\x01");
			else
				ReplyToCommand(client, "[SM] %t", "TeamCT 11", "", targetId, "");
			
			if (GetConVarInt(g_tmc_log))
				LogAction(client, targetId, "\"%L\" made \"%L\" be CT for the next round", client, targetId);
			
			decl String:szTeamBufferPrefix[ 6 ];
			getTeamNameConditionalLowerCase( 3, szTeamBufferPrefix, 4 );
			szTeamBufferPrefix[ 3 ] = '\0';
			Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
			g_szPlayerTeamPrefix[ targetId ] = szTeamBufferPrefix;
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "F_TeamChange 11");
		}
	}
	
	return Plugin_Handled;
}

//1.4.0 (specs)
public Action:Command_SetTeamSpec(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_indiv ) || !GetConVarBool( g_tmc_allow_switch_spec ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	decl String:targetArg[ MAX_NAME_LENGTH ];
	new targetId;
	
	if (args < 1) //If no arg; check target aimed at
	{
		targetId = GetClientAimTarget(client);
	}
	else if (args < 2)
	{
		GetCmdArg(1, targetArg, sizeof(targetArg));
		targetId = FindTarget(client, targetArg);
	}
	
	if (targetId < 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_teamspec|say !teamspec> <#userid|name|[aimedTarget]>");
		return Plugin_Handled;
	}
	else if (GetClientTeam(targetId) > 1) //T or CT to T
	{
		if ( RequestTeamsManagement( any:REASON_ADMIN,
			TMC_PRIORITY,
			TeamsManagementType:TMT_INDIVIDUALS,
			0, //Cancel possible switch
			targetId,
			0 ) )
		{
			ChangeClientTeam( targetId, 1 );
			
			if (GetConVarInt(g_tmc_verbose_indiv))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamSpec 14", "\x04", targetId, "\x01");
			else
				ReplyToCommand(client, "[SM] %t", "TeamSpec 14", "", targetId, "");
			
			if (GetConVarInt(g_tmc_log))
				LogAction(client, targetId, "\"%L\" switched \"%L\" to Spec", client, targetId);
			
			g_szPlayerTeamPrefix[ targetId ][ 0 ] = '\0';
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "F_TeamChange 11");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_ChangeTeam(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_indiv ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	decl String:targetArg[ MAX_NAME_LENGTH ];
	new targetId;
	
	if (args < 1) //If no arg; check target aimed at
	{
		targetId = GetClientAimTarget(client);
	}
	else if (args < 2)
	{
		GetCmdArg(1, targetArg, sizeof(targetArg));
		targetId = FindTarget(client, targetArg);
	}
	
	if (targetId < 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_changeteam|say !changeteam|say !cteam> <#userid|name|[aimedTarget]>");
		return Plugin_Handled;
	}
	else if (GetClientTeam(targetId) > 1) //T or CT to T
	{
		new iTeam = GetClientTeam(targetId);
		if ( RequestTeamsManagement( any:REASON_ADMIN,
			TMC_PRIORITY,
			TeamsManagementType:TMT_INDIVIDUALS,
			iTeam == 2 ? 3 : 2,
			targetId,
			0 ) )
		{
			decl String:szBuffer[ 12 ];
			getTeamNameConditionalLowerCase( iTeam, szBuffer, sizeof(szBuffer) );
			
			if (GetConVarInt(g_tmc_verbose_indiv))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamChange 11", "\x04", targetId, "\x01", "\x04", szBuffer, "\x01");
			else
				ReplyToCommand(client, "[SM] %t", "TeamChange 11", "", targetId, "", "", szBuffer, "");
			
			if (GetConVarInt(g_tmc_log))
				LogAction(client, targetId, "\"%L\" changed \"%L\"'s team the next round (was %s)", client, targetId, iTeam == 2 ? "Terro" : "CT");
			
			decl String:szTeamBufferPrefix[ 6 ];
			szBuffer[ 3 ] = '\0';
			FormatEx( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szBuffer );
			g_szPlayerTeamPrefix[ targetId ] = szTeamBufferPrefix;
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "F_TeamChange 11");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_CancelChangeTeam(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_indiv ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	decl String:targetArg[ MAX_NAME_LENGTH ];
	new targetId;
	
	if (args < 1) //If no arg; check target aimed at
	{
		targetId = GetClientAimTarget(client);
	}
	else if (args < 2)
	{
		GetCmdArg(1, targetArg, sizeof(targetArg));
		targetId = FindTarget(client, targetArg);
	}
	
	if (targetId < 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_changeteam|say !changeteam|say !cteam> <#userid|name|[aimedTarget]>");
		return Plugin_Handled;
	}
	else if (GetClientTeam(targetId) > 1) //T or CT to T
	{
		if ( RequestTeamsManagement( any:REASON_ADMIN,
			TMC_PRIORITY,
			TeamsManagementType:TMT_INDIVIDUALS,
			0,
			targetId,
			0 ) )
		{
			decl String:szBuffer[ 12 ];
			getTeamNameConditionalLowerCase( GetClientTeam(targetId), szBuffer, sizeof( szBuffer ) );
			
			if (GetConVarInt(g_tmc_verbose_indiv))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "TeamChangeCancel 11", "\x04", targetId, "\x01");
			else
				ReplyToCommand(client, "[SM] %t", "TeamChangeCancel 11", "", targetId, "");
			
			if (GetConVarInt(g_tmc_log))
				LogAction(client, targetId, "\"%L\" canceled \"%L\"'s Team's Management", client, targetId);
			
			g_szPlayerTeamPrefix[ targetId ][ 0 ] = '\0';
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "F_TeamChangeCancel 11");
		}
	}
	
	return Plugin_Handled;
}
//Clan related ; since 1.3
//clan tag method : The 4 first will fail if there are quotes in the clan tag
public Action:Command_ClanSetTeamTerro(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	decl String:szTag[ 13 ];
	GetCmdArg(1, szTag, sizeof(szTag));
	
	decl String:szTmpTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			CS_GetClientClanTag( i, szTmpTag, sizeof(szTmpTag) );
			
			if ( StrEqual( szTag, szTmpTag ) )
			{
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					2,
					i,
					0 ) )
				{
					
					decl String:szTeamBufferPrefix[ 6 ];
					getTeamNameConditionalLowerCase( 2, szTeamBufferPrefix, 4 );
					szTeamBufferPrefix[ 3 ] = '\0';
					Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
					g_szPlayerTeamPrefix[ i ] = szTeamBufferPrefix;
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamTerro 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamTerro 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" be terrorists for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}
public Action:Command_ClanSetTeamCT(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	decl String:szTag[ 13 ];
	GetCmdArg(1, szTag, sizeof(szTag));
	
	decl String:szTmpTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			CS_GetClientClanTag( i, szTmpTag, sizeof(szTmpTag) );
			
			if ( StrEqual( szTag, szTmpTag ) )
			{
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					3,
					i,
					0 ) )
				{
					
					decl String:szTeamBufferPrefix[ 6 ];
					getTeamNameConditionalLowerCase( 3, szTeamBufferPrefix, 4 );
					szTeamBufferPrefix[ 3 ] = '\0';
					Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
					g_szPlayerTeamPrefix[ i ] = szTeamBufferPrefix;
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamCT 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamCT 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" be CTs for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}
public Action:Command_ClanSetTeamSpec(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan ) || !GetConVarBool( g_tmc_allow_switch_spec ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	decl String:szTag[ 13 ];
	GetCmdArg(1, szTag, sizeof(szTag));
	
	decl String:szTmpTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			CS_GetClientClanTag( i, szTmpTag, sizeof(szTmpTag) );
			
			if ( StrEqual( szTag, szTmpTag ) )
			{
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					0,
					i,
					0 ) )
				{
					ChangeClientTeam( i, 1 );
					
					g_szPlayerTeamPrefix[ i ][ 0 ] = '\0';
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamSpec 14", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamSpec 14", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" switched players with clan tag \"%s\" to Specs", client, szTag);
	}
	
	return Plugin_Handled;
}
public Action:Command_ClanChangeTeam(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	decl String:szTag[ 13 ];
	GetCmdArg(1, szTag, sizeof(szTag));
	
	decl String:szTmpTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) )
		{
			new iTeam = GetClientTeam( i );
			if ( iTeam > 1 )
			{
				CS_GetClientClanTag( i, szTmpTag, sizeof(szTmpTag) );
				
				if ( StrEqual( szTag, szTmpTag ) )
				{
					if ( RequestTeamsManagement( any:REASON_ADMIN,
						TMC_PRIORITY,
						TeamsManagementType:TMT_INDIVIDUALS,
						iTeam == 2 ? 3 : 2,
						i,
						0 ) )
					{
						
						decl String:szTeamBufferPrefix[ 6 ];
						getTeamNameConditionalLowerCase( iTeam == 2 ? 3 : 2, szTeamBufferPrefix, 4 );
						szTeamBufferPrefix[ 3 ] = '\0';
						Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
						g_szPlayerTeamPrefix[ i ] = szTeamBufferPrefix;
						
						++willBeSwitchedCount;
					}
					
					++matchedCount;
				}
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamChange 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamChange 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" change team for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}
public Action:Command_ClanCancelChangeTeam(client, args)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	decl String:szTag[ 13 ];
	GetCmdArg(1, szTag, sizeof(szTag));
	
	decl String:szTmpTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			CS_GetClientClanTag( i, szTmpTag, sizeof(szTmpTag) );
			
			if ( StrEqual( szTag, szTmpTag ) )
			{
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					0,
					i,
					0 ) )
				{
					g_szPlayerTeamPrefix[ i ][ 0 ] = '\0';
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChangeCancel 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamChangeCancel 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamChangeCancel 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" NOT change team for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}
//cl_clanid method; used with the menus and not with commands
public Action:FromMenu_ClanSetTeamTerroWithId(client, String:szTagId[], sizeTagId)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan_menu ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	
	decl String:szTmpTagId[ 13 ];
	
	decl String:szTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			GetClientInfo( i, "cl_clanid", szTmpTagId, sizeof(szTmpTagId) );
			
			if ( StrEqual( szTagId, szTmpTagId ) )
			{
				if ( !matchedCount )
				{
					CS_GetClientClanTag( i, szTag, sizeof(szTag) );
				}
				
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					2,
					i,
					0 ) )
				{
					
					decl String:szTeamBufferPrefix[ 6 ];
					getTeamNameConditionalLowerCase( 2, szTeamBufferPrefix, 4 );
					szTeamBufferPrefix[ 3 ] = '\0';
					Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
					g_szPlayerTeamPrefix[ i ] = szTeamBufferPrefix;
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamTerro 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamTerro 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" be terrorists for the next round", client, szTag);
		
	}
	
	return Plugin_Handled;
}
public Action:FromMenu_ClanSetTeamCTWithId(client, String:szTagId[], sizeTagId)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan_menu ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	
	decl String:szTmpTagId[ 13 ];
	
	decl String:szTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			GetClientInfo( i, "cl_clanid", szTmpTagId, sizeof(szTmpTagId) );
			
			if ( StrEqual( szTagId, szTmpTagId ) )
			{
				if ( !matchedCount )
				{
					CS_GetClientClanTag( i, szTag, sizeof(szTag) );
				}
				
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					3,
					i,
					0 ) )
				{
					
					decl String:szTeamBufferPrefix[ 6 ];
					getTeamNameConditionalLowerCase( 2, szTeamBufferPrefix, 4 );
					szTeamBufferPrefix[ 3 ] = '\0';
					Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
					g_szPlayerTeamPrefix[ i ] = szTeamBufferPrefix;
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamCT 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamCT 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" be CTs for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}
//Since 1.4.0 (spec)
public Action:FromMenu_ClanSetTeamSpecWithId(client, String:szTagId[], sizeTagId)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan_menu ) || !GetConVarBool( g_tmc_allow_switch_spec ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	
	decl String:szTmpTagId[ 13 ];
	
	decl String:szTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) &&
				GetClientTeam( i ) > 1 )
		{
			GetClientInfo( i, "cl_clanid", szTmpTagId, sizeof(szTmpTagId) );
			
			if ( StrEqual( szTagId, szTmpTagId ) )
			{
				if ( !matchedCount )
				{
					CS_GetClientClanTag( i, szTag, sizeof(szTag) );
				}
				
				if ( RequestTeamsManagement( any:REASON_ADMIN,
					TMC_PRIORITY,
					TeamsManagementType:TMT_INDIVIDUALS,
					0, //Do nothing (cancel possible switch)
					i,
					0 ) )
				{
					ChangeClientTeam( i, 1 );
					
					g_szPlayerTeamPrefix[ i ][ 0 ] = '\0';
					
					++willBeSwitchedCount;
				}
				
				++matchedCount;
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamSpec 14", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamSpec 14", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" switched players with clan tag \"%s\" to Specs", client, szTag);
	}
	
	return Plugin_Handled;
}
public Action:FromMenu_ClanChangeTeamWithId(client, String:szTagId[], sizeTagId)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan_menu ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	
	decl String:szTmpTagId[ 13 ];
	
	decl String:szTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) )
		{
			new iTeam = GetClientTeam( i );
			if ( iTeam > 1 )
			{
				GetClientInfo( i, "cl_clanid", szTmpTagId, sizeof(szTmpTagId) );
				
				if ( StrEqual( szTagId, szTmpTagId ) )
				{
					if ( !matchedCount )
					{
						CS_GetClientClanTag( i, szTag, sizeof(szTag) );
					}
					
					if ( RequestTeamsManagement( any:REASON_ADMIN,
						TMC_PRIORITY,
						TeamsManagementType:TMT_INDIVIDUALS,
						iTeam == 2 ? 3 : 2,
						i,
						0 ) )
					{
						
						decl String:szTeamBufferPrefix[ 6 ];
						getTeamNameConditionalLowerCase( iTeam == 2 ? 3 : 2, szTeamBufferPrefix, 4 );
						szTeamBufferPrefix[ 3 ] = '\0';
						Format( szTeamBufferPrefix, sizeof(szTeamBufferPrefix), "[%s]", szTeamBufferPrefix );
						g_szPlayerTeamPrefix[ i ] = szTeamBufferPrefix;
						
						++willBeSwitchedCount;
					}
					
					++matchedCount;
				}
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamChange 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamChange 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" change team for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}
public Action:FromMenu_ClanCancelChangeTeamWithId(client, String:szTagId[], sizeTagId)
{
	if ( !GetConVarBool( g_tmc ) || !GetConVarBool( g_tmc_allow_switch_clan_menu ) )
	{
		ReplyToCommand(client, "[SM] %t", "DisabledOption");
		return Plugin_Handled;
	}
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new matchedCount;
	new willBeSwitchedCount;
	
	decl String:szTmpTagId[ 13 ];
	
	decl String:szTag[ 13 ];
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) )
		{
			new iTeam = GetClientTeam( i );
			if ( iTeam > 1 )
			{
				GetClientInfo( i, "cl_clanid", szTmpTagId, sizeof(szTmpTagId) );
				
				if ( StrEqual( szTagId, szTmpTagId ) )
				{
					if ( !matchedCount )
					{
						CS_GetClientClanTag( i, szTag, sizeof(szTag) );
					}
					
					if ( RequestTeamsManagement( any:REASON_ADMIN,
						TMC_PRIORITY,
						TeamsManagementType:TMT_INDIVIDUALS,
						0,
						i,
						0 ) )
					{
						g_szPlayerTeamPrefix[ i ][ 0 ] = '\0';
						
						++willBeSwitchedCount;
					}
					
					++matchedCount;
				}
			}
		}
	}
	
	if ( !matchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "No matching clients");
	}
	else if ( !willBeSwitchedCount )
	{
		ReplyToCommand(client, "[SM] %t", "F_ClanTeamChange 13");
	}
	else
	{
		if ( GetConVarInt( g_tmc_verbose_clan ) )
			ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "ClanTeamChangeCancel 13", "\x04", willBeSwitchedCount, "\x01", "\x04", szTag, "\x01", "\x04", matchedCount, "\x01");
		else
			ReplyToCommand(client, "[SM] %t", "ClanTeamChangeCancel 13", "", willBeSwitchedCount, "", "", szTag, "", "", matchedCount, "");
		
		if (GetConVarInt(g_tmc_log))
			LogAction(client, -1, "\"%L\" made players with clan tag \"%s\" NOT change team for the next round", client, szTag);
	}
	
	return Plugin_Handled;
}

// ===== Privates

getTeamNameConditionalLowerCase(any:teamId, String:szBuffer[ ], any:size)
{
	//Team name
	GetTeamName( teamId, szBuffer, size );
	
	//Lower cases
	if ( strlen( szBuffer ) > 3 ) //4+ chars = lower
		for ( new i = 1; i < size; ++i )
			szBuffer[ i ] = CharToLower( szBuffer[ i ] );
}

addPlayersToMenu(Handle:menu, flags)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+20];//12+5+1(' ')+1('(')+1(')')
	
	decl iTeam;
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		//Normal checks
		if (!IsClientInGame(i)			|| 
				IsClientInKickQueue(i))
			continue;
		
		iTeam = GetClientTeam(i);
		
		//Flag checks
		if (flags & REMOVE_TEAMLESS && iTeam == 0)
			continue;
			
		if (flags & REMOVE_SPECTATORS && iTeam == 1)
			continue;
			
		if (flags & REMOVE_TERRORISTS && iTeam == 2)
			continue;
			
		if (flags & REMOVE_CTS && iTeam == 3)
			continue;
		
		IntToString(GetClientUserId(i), user_id, sizeof(user_id));
		GetClientName(i, name, sizeof(name));
		FormatEx(display, sizeof(display), "%s%s (%s)", g_szPlayerTeamPrefix[ i ], name, user_id);
		AddMenuItem(menu, user_id, display);
	}
}
addClansToMenu(Handle:menu, flags)
{
	//Reset clan list
	decl String:szClans[ MAXPLAYERS - 1 ][ 13 ];//YEAH -1, DONT TELL ME SOURCETV HAS A CLAN K?
	new clanCount;
	
	decl String:szTmpClan[ 13 ];
	decl String:szTmpClanId[ 32 ];
	
	decl iTeam;
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame( i))
		{
			//Normal checks
			if (!IsClientInGame(i) || IsClientInKickQueue(i))
				continue;
			
			iTeam = GetClientTeam(i);
			
			//Flag checks
			if (flags & REMOVE_TEAMLESS && iTeam == 0)
				continue;
				
			if (flags & REMOVE_SPECTATORS && iTeam == 1)
				continue;
				
			if (flags & REMOVE_TERRORISTS && iTeam == 2)
				continue;
				
			if (flags & REMOVE_CTS && iTeam == 3)
				continue;
			
			CS_GetClientClanTag( i, szTmpClan, sizeof(szTmpClan) );
			
			if ( !stringExistInArray( szClans, clanCount, szTmpClan ) )
			{
				strcopy( szClans[ clanCount++ ], sizeof(szClans[]), szTmpClan );
				GetClientInfo( i, "cl_clanid", szTmpClanId, sizeof(szTmpClanId) );
				AddMenuItem(menu, szTmpClanId, szTmpClan);
			}
		}
	}
}
//crappy way to see if the string is already in the array
//since there is usually not that many clans in a server I guess its fine
bool:stringExistInArray(String:strArray[][], sizeArray, String:szString[])
{
	for ( new i; i < sizeArray; ++i )
	{
		if ( StrEqual( strArray[ i ], szString ) )
			return true;
	}
	return false;
}