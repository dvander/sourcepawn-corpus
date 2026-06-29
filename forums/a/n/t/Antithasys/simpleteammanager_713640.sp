/* Simple Team Manager
 *  By Antithasys
 *  http://www.mytf2.com
 *
 * Description:
 *			Manages players and their team
 *			Admin menu integration
 *			Allows admins/donators to swap their teams (clears force)*
 *			Allows admins to move players to a team (forced\unforced)*
 *			Allows admins to scramble the teams*
 *			*Works with Simple Team Balancer (if installed)
 *
 * 1.0.1
 * Fixed incorrectly respawning the wrong player
 * 
 * 1.0.0
 * Created #define for use with STB.  Default is 0 (or not to work with STB)
 --You can set this to 1 and compile yourself.  It's set to 0 so it will compile on forums.
 --If you have STB installed, you should run with set to 1 otherwise you will have issues with the balancer
 * Added moveplayer command to move a player to any team
 * Allowed moveplayer command to be ran from console
 * Rearranged moveplayer menu to place forced arg at end
 * Respawned players after a move or swap
 * Made forced arg reliant on the precense of STB
 * Depreciated swapplayer command
 * Added option to scramble teams at round end
 --This will scramble the teams 1 second before the end of mp_bonusroundtime
 --This will not scramble if the time left in the map is less than 60 seconds it will not run
 * Fixed scramble code moving spectators, unassigned players, and fake clients
 * Fixed enabled cvar not disabling the respective commands
 *
 * 0.9.0
 * Initial Release
 *
 * Future Updates:
 *			Add log activity
 */
 
// Set this to 1 if you want it to work with Simple Team Balancer.  If you do, you have to compile yourself
#define USE_STB 0

#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <tf2>
#include <adminmenu>

#if USE_STB
	#include <simpleteambalancer>
#endif

#define PLUGIN_VERSION "1.0.1"
#define MAX_STRING_LEN 64
#define SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3
#define VOTE_YES "##YES##"
#define VOTE_NO "##NO##"

new Handle:stm_enabled = INVALID_HANDLE;
new Handle:stm_logactivity = INVALID_HANDLE;
new Handle:stm_adminflag_swapteam = INVALID_HANDLE;
new Handle:stm_adminflag_moveplayer = INVALID_HANDLE;
new Handle:stm_adminflag_scramble = INVALID_HANDLE;
new Handle:stm_scrambledelay = INVALID_HANDLE;
new Handle:stm_voteenabled = INVALID_HANDLE;
new Handle:stm_votewin = INVALID_HANDLE;
new Handle:stm_votedelay = INVALID_HANDLE;
new Handle:stm_mp_bonusroundtime = INVALID_HANDLE;
new Handle:ghAdminMenu = INVALID_HANDLE;
new Handle:Timer = INVALID_HANDLE;
#if USE_STB
new Handle:stm_stb_version = INVALID_HANDLE;
#endif
new bool:QueuedPlayers[MAXPLAYERS + 1];
new bool:ForcedPlayers[MAXPLAYERS + 1];
new bool:IsEnabled = true;
new bool:VoteEnabled = true;
new bool:IsHooked = false;
new bool:LogActivity = true;
new bool:ScrambleRoundEnd = false;
#if USE_STB
new bool:UseSTB = false;
#endif
new PlayersTeam[MAXPLAYERS + 1];
new votedelay, lastvotetime;
new Float:scrambledelay, Float:votewin;

public Plugin:myinfo =
{
	name = "Simple Team Manager",
	author = "Antithasys",
	description = "Manages players and thier team.",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("stm_version", PLUGIN_VERSION, "Simple Team Manager Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	stm_enabled = CreateConVar("stm_enabled", "1", "Enable or Disable Simple Team Manager", _, true, 0.0, true, 1.0);
	stm_logactivity = CreateConVar("stm_logactivity", "0", "Enable or Disable the disaplying of events in the log", _, true, 0.0, true, 1.0);
	stm_adminflag_swapteam = CreateConVar("stm_adminflag_swapteam", "a", "Admin flag to use for the swapteam command.  Must be a in char format.");
	stm_adminflag_moveplayer = CreateConVar("stm_adminflag_moveplayer", "c", "Admin flag to use for the moveplayer command.  Must be a in char format.");
	stm_adminflag_scramble = CreateConVar("stm_adminflag_scramble", "c", "Admin flag to use for the scrambleteam command.  Must be a in char format.");
	stm_scrambledelay = CreateConVar("stm_scrambledelay", "15", "Delay to scramble teams");
	stm_voteenabled = CreateConVar("stm_voteenabled", "1", "Enable or Disable voting to scramble the teams", _, true, 0.0, true, 1.0);
	stm_votewin = CreateConVar("stm_votewin", "0.45", "Win percentage vote must win by", _, true, 0.0, true, 1.0);
	stm_votedelay = CreateConVar("stm_votedelay", "600", "Delay before another vote can be cast");
	stm_mp_bonusroundtime = FindConVar("mp_bonusroundtime");
	RegConsoleCmd("sm_swapteam", Command_SwapTeam, "sm_swapteam <[0]instant/[1]queued>: Swaps your team to the other team");
	RegConsoleCmd("sm_moveplayer", Command_MovePlayer, "sm_moveplayer <name/#userid> <team[number/name]> <[0]instant/[1]ondeath> <[0]unforced/[1]forced>: Moves a player to the specified team");
	RegConsoleCmd("sm_scrambleteams", Command_ScrambleTeams, "sm_scrambleteams: <[0]now/[1]roundend> Scrambles the current teams");
	RegConsoleCmd("sm_votescramble", Command_VoteScramble, "sm_votescramble: Starts a vote to scramble the teams");
	HookConVarChange(stm_enabled, ConVarSettingsChanged);
	HookConVarChange(stm_logactivity, ConVarSettingsChanged);
	HookConVarChange(stm_scrambledelay, ConVarSettingsChanged);
	HookConVarChange(stm_voteenabled, ConVarSettingsChanged);
	HookConVarChange(stm_votewin, ConVarSettingsChanged);
	HookConVarChange(stm_votedelay, ConVarSettingsChanged);	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
	LoadTranslations ("simpleteammanager.phrases");
	LoadTranslations ("common.phrases");
	AutoExecConfig(true, "plugin.simpleteammanager");
}

public OnConfigsExecuted()
{
	IsEnabled = GetConVarBool(stm_enabled);
	LogActivity = GetConVarBool(stm_logactivity);
	scrambledelay = GetConVarFloat(stm_scrambledelay);
	votedelay = GetConVarInt(stm_votedelay);
	votewin = GetConVarFloat(stm_votewin);
	lastvotetime = RoundFloat(GetEngineTime());
	ScrambleRoundEnd = false;
	if (IsEnabled && !IsHooked) {
		if (!HookEventEx("player_death", HookPlayerDeath, EventHookMode_Post)
			|| !HookEventEx("player_team", HookPlayerChangeTeam, EventHookMode_Post)
			|| !HookEventEx("teamplay_round_win", HookRoundEnd, EventHookMode_Post)) {
			SetFailState("Could not hook an event.");
			IsHooked = false;
			return;
		}
		IsHooked = true;
		LogAction(0, -1, "[STM] Simple Team Manager is loaded and enabled.");
	} else {
		LogAction(0, -1, "[STM] Simple Team Manager is loaded and disabled.");
	}
	if (IsEnabled && LogActivity)
		LogAction(0, -1, "[STM] Log Activity ENABLED.");
	else
		LogAction(0, -1, "[STM] Log Activity DISABLED.");
}

#if USE_STB
public OnAllPluginsLoaded()
{
	stm_stb_version = FindConVar("simpleteambalancer_version");
	if (stm_stb_version == INVALID_HANDLE) {
		UseSTB = false;
		LogAction(0, -1, "[STM] NOT using Simple Team Balancer");
	} else {
		UseSTB = true;
		LogAction(0, -1, "[STM] Using Simple Team Balancer");
	}
}
#endif

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		ghAdminMenu = INVALID_HANDLE;
#if USE_STB
	if (StrEqual(name, "simpleteambalancer")) {
		stm_stb_version = INVALID_HANDLE;
		UseSTB = false;
	}
#endif
}

/* COMMANDS */

public Action:Command_SwapTeam(client, args)
{
	if (!IsEnabled)
		return Plugin_Handled;
	if (client == 0) {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "PlayerLevelCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	decl String:flags[MAX_STRING_LEN];
	GetConVarString(stm_adminflag_swapteam, flags, MAX_STRING_LEN);
	if (!IsValidAdmin(client, flags)) {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "RestrictedCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	new team = GetClientTeam(client);
	if (team == TEAM_RED)
		PlayersTeam[client] = TEAM_BLUE;
	else if (team == TEAM_BLUE)
		PlayersTeam[client] = TEAM_RED;
	else {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "InValidTeam", LANG_SERVER);
		return Plugin_Handled;
	}
	if (GetCmdArgs()) {
		decl String:arg[MAX_STRING_LEN];
		GetCmdArg(1, arg, MAX_STRING_LEN);
		new wantsque = StringToInt(arg);
		if (wantsque && !QueuedPlayers[client]) {
			QueuedPlayers[client] = true;
			ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "PlayerQueue", LANG_SERVER);
		} else if (!wantsque)
			MovePlayer(client, client, ForcedPlayers[client]);
	} else {
		new Handle:swapmodemenu = BuildSwapModeMenu(client);
		DisplayMenu(swapmodemenu, client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public Action:Command_MovePlayer(client, args)
{
	if (!IsEnabled)
		return Plugin_Handled;
	decl String:flags[MAX_STRING_LEN];
	GetConVarString(stm_adminflag_moveplayer, flags, MAX_STRING_LEN);
	if (!IsValidAdmin(client, flags)) {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "RestrictedCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	new Handle:menutodisplay = INVALID_HANDLE;
	new cmdargs = GetCmdArgs();
	if (cmdargs == 0) {
		menutodisplay = BuildPlayerMenu();
		DisplayMenu(menutodisplay, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	decl String:player[MAX_STRING_LEN];
	GetCmdArg(1, player, MAX_STRING_LEN);
	new playerindex = FindTarget(client, player, true, true);
	if (playerindex == -1 || !IsClientInGame(playerindex)){
		menutodisplay = BuildPlayerMenu();
		DisplayMenu(menutodisplay, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	if (cmdargs >= 2) {
		decl String:team[MAX_STRING_LEN];
		GetCmdArg(2, team, MAX_STRING_LEN);
		if (StrContains(team, "red", false) != -1)
			PlayersTeam[playerindex] = TEAM_RED;
		if (StrContains(team, "blu", false) != -1)
			PlayersTeam[playerindex] = TEAM_BLUE;
		if (StrContains(team, "spec", false) != -1)
			PlayersTeam[playerindex] = SPECTATOR;
		if (PlayersTeam[playerindex] == 0) {
			new newteam = StringToInt(team);
			if (IsValidTeam(newteam))
				PlayersTeam[playerindex] = newteam;
			else
				menutodisplay = BuildTeamMenu(playerindex);
		}
		if (cmdargs < 3 && menutodisplay == INVALID_HANDLE) {
			if (!IsClientObserver(playerindex))
				menutodisplay = BuildSwapModeMenu(playerindex);
			else
				MovePlayer(client, playerindex, ForcedPlayers[playerindex]);
		}
	} else
		menutodisplay = BuildTeamMenu(playerindex);
	if (cmdargs >= 3) {
		decl String:swapmode[MAX_STRING_LEN];
		GetCmdArg(3, swapmode, MAX_STRING_LEN);
		new wantsque = StringToInt(swapmode);
		if (wantsque) {
			QueuedPlayers[playerindex] = true;
			ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "PlayerQueue", LANG_SERVER);
		} else
			QueuedPlayers[playerindex] = false;
#if USE_STB
		if (cmdargs < 4)
			menutodisplay = BuildForceModeMenu(playerindex);
#endif
	}
#if USE_STB
	if (cmdargs >= 4) {
		decl String:playerforced[MAX_STRING_LEN];
		GetCmdArg(4, playerforced, MAX_STRING_LEN);
		new forcehim = StringToInt(playerforced);
		if (forcehim)
			ForcedPlayers[playerindex] = true;
		else
			ForcedPlayers[playerindex] = false;
	}
#endif
	if (menutodisplay == INVALID_HANDLE) {
		if (!IsPlayerAlive(playerindex))
			MovePlayer(client, playerindex, ForcedPlayers[playerindex]);
		else {
			if (!QueuedPlayers[playerindex])
				MovePlayer(client, playerindex, ForcedPlayers[playerindex]);
		}
	} else
		DisplayMenu(menutodisplay, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action:Command_ScrambleTeams(client, args)
{
	if (!IsEnabled)
		return Plugin_Handled;
	decl String:flags[MAX_STRING_LEN];
	GetConVarString(stm_adminflag_scramble, flags, MAX_STRING_LEN);
	if (!IsValidAdmin(client, flags)) {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "RestrictedCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	new Handle:menutodisplay = INVALID_HANDLE;
	new cmdargs = GetCmdArgs();
	if (cmdargs == 0) {
		menutodisplay = BuildScrambleMenu();
		DisplayMenu(menutodisplay, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	decl String:roundend[MAX_STRING_LEN];
	GetCmdArg(1, roundend, MAX_STRING_LEN);
	if (StringToInt(roundend))
		ScrambleRoundEnd = true;
	else
		PrepScramble();
	return Plugin_Handled;
}

public Action:Command_VoteScramble(client, args)
{
	if (!VoteEnabled || !IsEnabled)
		return Plugin_Handled;
	if (IsVoteInProgress()) {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "VoteInProgress", LANG_SERVER);
		return Plugin_Handled;
	}
	new votetime = RoundFloat(GetEngineTime());
	if (votetime - lastvotetime <= votedelay) {
		ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "ScrambleTime", LANG_SERVER);
		return Plugin_Handled;
	}
	lastvotetime = votetime;
	new Handle:menu = CreateMenu(Menu_VoteScramble);
	SetMenuTitle(menu, "Scramble Teams?");
	AddMenuItem(menu, VOTE_YES, "Yes");
	AddMenuItem(menu, VOTE_NO, "No");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
	return Plugin_Handled;
}

/* HOOKED EVENTS */

public HookPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[MAX_STRING_LEN];
	GetEventString(event, "weapon", weapon, MAX_STRING_LEN);
	if (StrEqual(weapon, "world", false)) {
		CleanUp(client);
		return;
	}
	if (QueuedPlayers[client])
		MovePlayer(client, client, ForcedPlayers[client]);
	return;
}

public HookPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (QueuedPlayers[client])
		CleanUp(client);
	return;
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new timeleft;
	GetMapTimeLeft(timeleft);
	if (ScrambleRoundEnd && timeleft >= 60) {
		if (Timer != INVALID_HANDLE) {
			Timer = INVALID_HANDLE;
			CloseHandle(Timer);
		}
		new Float:delay = GetConVarFloat(stm_mp_bonusroundtime);
		delay -= 1.0;
		Timer = CreateTimer(delay, Timer_ScrambleTeams, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:flags[MAX_STRING_LEN];
	GetConVarString(stm_adminflag_swapteam, flags, MAX_STRING_LEN);
	if (!IsValidAdmin(client, flags)) {
		CreateTimer (60.0, Timer_WelcomeAdvert, client);
	}
}

public OnClientDisconnect(client)
{
	CleanUp(client);
}

/* TIMER FUNCTIONS */

public Action:Timer_ScrambleTeams(Handle:timer, any:client)
{
	TeamScramble();
	Timer = INVALID_HANDLE;
}

public Action:Timer_WelcomeAdvert(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
		PrintToChat (client, "\x01\x04[STM]\x01 %T", "SwapTeamMsg", LANG_SERVER);
	return Plugin_Handled;
}

/* STOCK FUNCTIONS */

stock CleanUp(client)
{
	QueuedPlayers[client] = false;
	ForcedPlayers[client] = false;
	PlayersTeam[client] = 0;
}

stock MovePlayer(client, player, bool:forced)
{
	if (!IsValidTeam(PlayersTeam[player])) {
		PrintToChat(client, "\x01\x04[STM]\x01 %T", "InValidTeam", LANG_SERVER);
		return;
	}
	decl String:playername[MAX_STRING_LEN];
	GetClientName(player, playername, MAX_STRING_LEN);
#if USE_STB
	if (UseSTB) {
		if (forced)
			STB_MovePlayerForced(player, PlayersTeam[player]);
		else
			STB_MovePlayerUnForced(player, PlayersTeam[player]);
	} else {
		ChangeClientTeam(player, PlayersTeam[player]);
		TF2_RespawnPlayer(player);
	}
#else
	ChangeClientTeam(player, PlayersTeam[player]);
	TF2_RespawnPlayer(player);
#endif
	if (client == player)
		PrintToChat(client, "\x01\x04[STM]\x01 %T", "PlayerSwitched1", LANG_SERVER);
	else {
		PrintToChat(client, "\x01\x04[STM]\x01 %T", "PlayerSwitched3", LANG_SERVER, playername);
		PrintToChat(client, "\x01\x04[STM]\x01 %T", "PlayerSwitched2", LANG_SERVER);
	}
	CleanUp(player);
	return;
}

stock PrepScramble(Float:delay = 0.0)
{
	if (delay == 0)
		delay = scrambledelay;
	if (Timer != INVALID_HANDLE) {
		Timer = INVALID_HANDLE;
		CloseHandle(Timer);
	}
	PrintCenterTextAll("[STM] %T", "Scramble", LANG_SERVER);
	Timer = CreateTimer(delay, Timer_ScrambleTeams, _, TIMER_FLAG_NO_MAPCHANGE);
}

stock TeamScramble()
{
	decl players[MAXPLAYERS];
	new max_clients = GetMaxClients();
	new count, i, bool:team;
	for(i = 1; i <= max_clients; i++) {
		if(IsClientInGame(i) && IsValidTeam(i) && !IsFakeClient(i)) {
			players[count++] = i;
		}
	}
	SortIntegers(players, count, Sort_Random);
	for(i = 0; i < count; i++) {
#if USE_STB
		if (UseSTB)
			STB_MovePlayerUnForced(players[i], team ? TEAM_RED : TEAM_BLUE);
#else
		ChangeClientTeam(players[i], team ? TEAM_RED : TEAM_BLUE);
#endif
		if (!ScrambleRoundEnd)
			TF2_RespawnPlayer(players[i]);
		CleanUp(players[i]);
		team = !team;
    }
	ScrambleRoundEnd = false;
}

stock bool:IsValidTeam(team)
{
	if (team == TEAM_RED || team == TEAM_BLUE || team == SPECTATOR)
		return true;
	return false;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags) {
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) {
		return true;
	}
	return false;
}

/* CONSOLE VARIABLE CHANGE EVENT */

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == stm_enabled) {
		if (StringToInt(newValue) == 0) {
			if (IsHooked) {
				UnhookEvent("player_death", HookPlayerDeath, EventHookMode_Post);
				UnhookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Post);
				UnhookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
			}
			IsHooked = false;
			IsEnabled = false;
			LogAction(0, -1, "[STM] Simple Team Manager is loaded and disabled.");
		} else {
			if (!IsHooked) {
				if (!HookEventEx("player_death", HookPlayerDeath, EventHookMode_Post)
				|| !HookEventEx("player_team", HookPlayerChangeTeam, EventHookMode_Post)
				|| !HookEventEx("teamplay_round_win", HookRoundEnd, EventHookMode_Post)) {
					SetFailState("Could not hook an event.");
					IsHooked = false;
					return;
				}
				IsHooked = true;
			}
			LogAction(0, -1, "[STM] Simple Team Manager is loaded and enabled.");
			if (LogActivity)
				LogAction(0, -1, "[STM] Log Activity ENABLED.");
			else
				LogAction(0, -1, "[STM] Log Activity DISABLED.");
		}
	} 
	else if (convar == stm_logactivity) {
		if (StringToInt(newValue) == 0) {
			LogActivity = false;
			LogAction(0, -1, "[STM] Log Activity DISABLED.");
		} else {
			LogActivity = true;
			LogAction(0, -1, "[STM] Log Activity ENABLED.");
		}
	}
	else if (convar == stm_scrambledelay)
		scrambledelay = StringToFloat(newValue);
	else if (convar == stm_votewin)
		votewin = StringToFloat(newValue);
	else if (convar == stm_votedelay)
		votedelay = StringToInt(newValue);
	else if (convar == stm_voteenabled) {
		if (StringToInt(newValue) == 0)
			VoteEnabled = false;
		else
			VoteEnabled = true;
	}
}

/* MENU CODE */

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == ghAdminMenu)
		return;
	ghAdminMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(ghAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	new TopMenuObject:server_commands = FindTopMenuCategory(ghAdminMenu, ADMINMENU_SERVERCOMMANDS);
 	if (player_commands == INVALID_TOPMENUOBJECT)
		return;
		
	AddToTopMenu(ghAdminMenu, 
		"moveplayer",
		TopMenuObject_Item,
		AdminMenu_MovePlayer,
		player_commands,
		"moveplayer",
		ADMFLAG_BAN);
		
	AddToTopMenu(ghAdminMenu,
		"scrambleteams",
		TopMenuObject_Item,
		AdminMenu_Scrambleteams,
		server_commands,
		"scrambleteams",
		ADMFLAG_BAN);
}
 
public AdminMenu_MovePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Move Player");
	else if (action == TopMenuAction_SelectOption){
		new Handle:playermenu = BuildPlayerMenu();
		DisplayMenu(playermenu, param, MENU_TIME_FOREVER);
	}
}

public AdminMenu_Scrambleteams(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Scramble Teams");
	else if (action == TopMenuAction_SelectOption) {
		new Handle:scramblemenu = BuildScrambleMenu();
		DisplayMenu(scramblemenu, param, MENU_TIME_FOREVER);
	}
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		new Handle:teammenu = BuildTeamMenu(GetClientOfUserId(StringToInt(selection)));
		DisplayMenu(teammenu, param1, MENU_TIME_FOREVER);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && ghAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(ghAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

public Menu_SelectTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new team;
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		decl String:sindex[MAX_STRING_LEN];
		if (SplitString(selection, "A", sindex, MAX_STRING_LEN) != -1)
			team = TEAM_RED;
		else if (SplitString(selection, "B", sindex, MAX_STRING_LEN) != -1)
			team = TEAM_BLUE;
		else {
			SplitString(selection, "C", sindex, MAX_STRING_LEN);
			team = SPECTATOR;
		}
		new playerindex = StringToInt(sindex);
		PlayersTeam[playerindex] = team;
		new Handle:swapmodemenu = BuildSwapModeMenu(playerindex);
		DisplayMenu(swapmodemenu, param1, MENU_TIME_FOREVER);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && ghAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(ghAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

public Menu_SwapMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		decl String:sindex[MAX_STRING_LEN];
		if (SplitString(selection, "A", sindex, MAX_STRING_LEN) == -1)
			SplitString(selection, "B", sindex, MAX_STRING_LEN);
		new playerindex = StringToInt(sindex);
		if (StrContains(selection, "A", true) != -1)
			QueuedPlayers[playerindex] = false;
		else if (StrContains(selection, "B", true) != -1)
			QueuedPlayers[playerindex] = true;
#if USE_STB
		decl String:flags[MAX_STRING_LEN];
		GetConVarString(stm_adminflag_moveplayer, flags, MAX_STRING_LEN);
		if (UseSTB && IsValidAdmin(playerindex, flags)) {
			new Handle:forcemodemenu = BuildForceModeMenu(playerindex);
			DisplayMenu(forcemodemenu, param1, MENU_TIME_FOREVER);
		} else if (!QueuedPlayers[playerindex])
			MovePlayer(param1, playerindex, ForcedPlayers[playerindex]);
#else
		if (!QueuedPlayers[playerindex])
			MovePlayer(param1, playerindex, ForcedPlayers[playerindex]);
#endif
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack 
		&& ghAdminMenu != INVALID_HANDLE 
		&& GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(ghAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

#if USE_STB
public Menu_ForceMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		decl String:sindex[MAX_STRING_LEN];
		if (SplitString(selection, "A", sindex, MAX_STRING_LEN) == -1)
			SplitString(selection, "B", sindex, MAX_STRING_LEN);
		new playerindex = StringToInt(sindex);
		if (StrContains(selection, "A", true) != -1)
			ForcedPlayers[playerindex] = false;
		else if (StrContains(selection, "B", true) != -1)
			ForcedPlayers[playerindex] = true;
		if (!QueuedPlayers[playerindex])
			MovePlayer(param1, playerindex, ForcedPlayers[playerindex]);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack 
		&& ghAdminMenu != INVALID_HANDLE 
		&& GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(ghAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}
#endif

public Menu_VoteScramble(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_VoteEnd) {
		new winning_votes, total_votes;
		GetMenuVoteInfo(param2, winning_votes, total_votes);
		if (param1 == 0) {
			if (float(total_votes) / float(winning_votes) < votewin) {
				PrintToChatAll("\x01\x04[STM]\x01 %T", "VoteScramble2", LANG_SERVER, winning_votes, total_votes);
				return;
			}
			PrintCenterTextAll("[STM] %T", "Scramble", LANG_SERVER);
			PrintToChatAll("\x01\x04[STM]\x01 %T", "VoteScramble1", LANG_SERVER, winning_votes, total_votes);
			PrepScramble();
		}
		if (param1 == 1) {
			PrintToChatAll("\x01\x04[STM]\x01 %T", "VoteScramble2", LANG_SERVER, winning_votes, total_votes);
		}
	}
	if (action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_ScrambleTeams(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		if (StrEqual(selection, "NOW", false))
			PrepScramble();
		else
			ScrambleRoundEnd = true;
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && ghAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(ghAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

stock Handle:BuildScrambleMenu()
{
	new Handle:menu = CreateMenu(Menu_ScrambleTeams);
	SetMenuTitle(menu, "Select When to Scramble:");
	AddMenuItem(menu, "NOW", "Instantly");
	AddMenuItem(menu, "END", "At Round End");
	SetMenuExitBackButton(menu, false);
	return menu;
}

stock Handle:BuildSwapModeMenu(player)
{
	new Handle:menu = CreateMenu(Menu_SwapMode);
	decl String:optionA[MAX_STRING_LEN];
	decl String:optionB[MAX_STRING_LEN];
	Format(optionA, MAX_STRING_LEN, "%iA", player);
	Format(optionB, MAX_STRING_LEN, "%iB", player);
	SetMenuTitle(menu, "Select When to Swap:");
	AddMenuItem(menu, optionA, "Instantly (Kills)");
	if (!IsClientObserver(player))
		AddMenuItem(menu, optionB, "Queue on next death");
	SetMenuExitBackButton(menu, false);
	return menu;
}

#if USE_STB
stock Handle:BuildForceModeMenu(player)
{
	new Handle:menu = CreateMenu(Menu_ForceMode);
	decl String:optionA[MAX_STRING_LEN];
	decl String:optionB[MAX_STRING_LEN];
	Format(optionA, MAX_STRING_LEN, "%iA", player);
	Format(optionB, MAX_STRING_LEN, "%iB", player);
	SetMenuTitle(menu, "Select Force Mode:");
	AddMenuItem(menu, optionA, "UnForced");
	AddMenuItem(menu, optionB, "Forced");
	SetMenuExitBackButton(menu, false);
	return menu;
}
#endif

stock Handle:BuildTeamMenu(player)
{
	new Handle:menu = CreateMenu(Menu_SelectTeam);
	decl String:optionA[MAX_STRING_LEN];
	decl String:optionB[MAX_STRING_LEN];
	decl String:optionC[MAX_STRING_LEN];
	Format(optionA, MAX_STRING_LEN, "%iA", player);
	Format(optionB, MAX_STRING_LEN, "%iB", player);
	Format(optionC, MAX_STRING_LEN, "%iC", player);
	SetMenuTitle(menu, "Select Team:");
	AddMenuItem(menu, optionA, "Red");
	AddMenuItem(menu, optionB, "Blue");
	AddMenuItem(menu, optionC, "Spectator");
	SetMenuExitBackButton(menu, false);
	return menu;
}

stock Handle:BuildPlayerMenu()
{
	new Handle:menu = CreateMenu(Menu_SelectPlayer);
	AddTargetsToMenu(menu, 0, true, false);
	SetMenuTitle(menu, "Select A Player:");
	SetMenuExitBackButton(menu, true);
	return menu;
}