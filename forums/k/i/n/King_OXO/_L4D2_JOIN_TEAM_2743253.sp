// This is a simple switch menu and players panel to help with team switching and spectator control during a game.
//
// The ideas and basis for the team/player swapping capabilites comes from the TeamSWITCH plugin by SkyDavid (djromero)
// Players panel concept and some of the code comes from l4d_teamspanel by OtterNas3
// Spectator control concept and some of the code comes from SpecStaysSpec by DieTeetasse
//
// This plugin requires "l4d2_bwa_teams_panel.txt" to be in the ...Sourcemod/gamedata folder

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define STEAMID_LENGTH 32

const TEAM_NONE = 0;
const TEAM_SPECTATOR = 1;
const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;

const GM_UNKNOWN = 0;
const GM_COOP = 1;
const GM_VERSUS = 2;
const GM_SCAVENGE = 3;

const MAXPLAYERS_PLUSONE = MAXPLAYERS + 1;

const ACTIVE_SECONDS     = 60;

const L4D_UNPAUSE_DELAY = 5;

new MAX_SURVIVORS = 0;
new MAX_INFECTED = 0;

new String:logFilePath[PLATFORM_MAX_PATH];

// top menu
new Handle:hTopMenu = INVALID_HANDLE;

new adminSwitchPlayer1 = -1;
new adminSwitchPlayer2 = -1;
new bool:adminIsSwap = false;

// SDK call handles
new Handle:gConf = INVALID_HANDLE;
new Handle:sdkSetPlayerSpec = INVALID_HANDLE;
new Handle:sdkTakeOverBot = INVALID_HANDLE;

new DEBUG = 0;
new bool:hasLastMap = false;
new iInitialAllTalk = 0;
new bool:isGamePaused = false;

new bool:allowPause = false;

new String:TeamNames[][] = {
"NONE",
"SPEC",
"SURV",
"INFC"
};

new String:ProperTeamNames[][] = {
"None",
"Spectator",
"Survivor",
"Infected"
};

new String:CommandText[][] = {
"Switch a Player",
"Swap Two Players",
"Unscramble Teams",
"Swap Both Teams",
"Pause Game",
"Unpause Game",
"View Current Teams",
"View Last Map Teams",
"Debugging Options"
};

// Arrays to retrieve player info
new PlayerTeam[MAXPLAYERS_PLUSONE];
new bool:PlayerBot[MAXPLAYERS_PLUSONE];
new String:PlayerSteamID[MAXPLAYERS_PLUSONE][STEAMID_LENGTH];
new String:PlayerName[MAXPLAYERS_PLUSONE][MAX_NAME_LENGTH];

// Arrays to store the player info from the end of the last round
new LR_PlayerTeam[MAXPLAYERS_PLUSONE];
new bool:LR_PlayerBot[MAXPLAYERS_PLUSONE];
new String:LR_PlayerSteamID[MAXPLAYERS_PLUSONE][STEAMID_LENGTH];
new String:LR_PlayerName[MAXPLAYERS_PLUSONE][MAX_NAME_LENGTH];
//new LR_Scores[3];

new tmp_PlayerTeam[MAXPLAYERS_PLUSONE];
new bool:tmp_PlayerBot[MAXPLAYERS_PLUSONE];
new String:tmp_PlayerSteamID[MAXPLAYERS_PLUSONE][STEAMID_LENGTH];
new String:tmp_PlayerName[MAXPLAYERS_PLUSONE][MAX_NAME_LENGTH];

new Handle:specTimer[MAXPLAYERS_PLUSONE] = { INVALID_HANDLE, ... };
new Handle:allowpubs;
new Handle:selectTeamFromPanel;
new Handle:cv_PrintMsgType;
new PrintMsgType = 0;
new Handle:showClientID;
new lastTimestamp = 0;
new Handle:cv_enablepause;

#define PLUGIN_VERSION "1.2.3"

const PRINT_NONE = 0;
const PRINT_SIMPLE = 1;
const PRINT_VERBOSE = 2;

public Plugin:myinfo = {
    name = "Join Team",
    author = "DarkWob",
    description = "Shows players on each team and spectators",
    version = PLUGIN_VERSION,
    url = "n/a"
};

public OnPluginStart() {

    decl String: game_name[64];
    GetGameFolderName(game_name, sizeof(game_name));

    if ((!StrEqual(game_name, "left4dead2", false)) && (!StrEqual(game_name, "left4dead", false)))
    {
        SetFailState("Use this in Left 4 Dead 1 or 2 only.");
    }

    BuildPath(Path_SM, logFilePath, sizeof(logFilePath), "logs/l4d2_bwa_teams_panel.log");

    LogActivity(0, "PluginStarted:TeamsPanel");

    //gConf = LoadGameConfigFile("l4d2_bwa_functions");
    gConf = LoadGameConfigFile("l4d2_bwa_teams_panel");

    if(gConf == INVALID_HANDLE)
    {
        //ThrowError("Could not load gamedata/l4d2_bwa_functions.txt");
        ThrowError("Could not load gamedata/l4d2_bwa_teams_panel.txt");
    }

    LoadTranslations("common.phrases");

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    sdkSetPlayerSpec = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    sdkTakeOverBot = EndPrepSDKCall();

    //RegConsoleCmd("aboutpanel", Show_About);

    // Shows panel with current team members, index, and teams they are on
    //RegConsoleCmd("teams", ShowCurrTeamPanel);

    // Show panel with team members as of the end of the last round
    RegConsoleCmd("lastteams", ShowLastRoundTeamPanel);

    // Join various teams directly, team must have open slot
    RegConsoleCmd("joinspec", JoinSpectatorTeam);
    RegConsoleCmd("sm_afk", JoinSpectatorTeam);
    RegConsoleCmd("sm_idle", JoinSpectatorTeam);
    RegAdminCmd("joinsurvivor", JoinSurvivorTeam, ADMFLAG_RESERVATION);
    RegAdminCmd("sm_sur", JoinSurvivorTeam, ADMFLAG_RESERVATION);
    RegAdminCmd("sm_survivor", JoinSurvivorTeam, ADMFLAG_RESERVATION);
    RegAdminCmd("joininfected", JoinInfectedTeam, ADMFLAG_RESERVATION);
    RegAdminCmd("sm_inf", JoinInfectedTeam, ADMFLAG_RESERVATION);
    RegAdminCmd("sm_infected", JoinInfectedTeam, ADMFLAG_RESERVATION);

    RegConsoleCmd("jointeam", JoinTeam);
    RegConsoleCmd("sm_join", JoinTeam);
    RegConsoleCmd("sm_teams", JoinTeam);

    // Swap teams with another player with their consent
    RegAdminCmd("swap", SwapWithMe, ADMFLAG_ROOT);

    // Shows the menu with the join commands, swap command, and view team panel command
    RegConsoleCmd("switchmenu", SwitchMenu);

    RegAdminCmd("sm_switchplayer", Command_SwitchPlayer, ADMFLAG_GENERIC, "sm_switchplayer <playerindex> [1=Spectator;2=Survivor;3=Infected]");
    RegAdminCmd("sm_swapplayers", Command_SwapPlayers, ADMFLAG_GENERIC, "sm_swapplayers <playerindex1> <playerindex2>");
    RegAdminCmd("sm_unscramble", Command_Unscramble, ADMFLAG_ROOT, "Unscramble the teams");
    RegAdminCmd("sm_swapteams", Command_SwapTeams, ADMFLAG_GENERIC, "Swap ALL Infected with ALL Survivors");
    RegAdminCmd("sm_pause", Command_PauseGame, ADMFLAG_ROOT, "Pause the game");
    RegAdminCmd("sm_unpause", Command_UnpauseGame, ADMFLAG_ROOT, "Unpause the game");
    RegAdminCmd("sm_debugpanel", Command_Debug, ADMFLAG_ROOT, "sm_debug [0 = Off|1 = PrintToChat|2 = LogToFile|3 = PrintToChat AND LogToFile]");

    CreateConVar("l4d2_plp_version", PLUGIN_VERSION, "Players Panel Version Information", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    allowpubs = CreateConVar("l4d2_BwA_TeamPanel_AllowPubs", "1", "Allow public access to commands [0 = No|1 = Yes]", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    selectTeamFromPanel = CreateConVar("l4d2_BwA_SelectTeam_From_Panel", "0", "Allow players to press 1,2 or 3 to select Spectator, Survivor or Infected from the Team Panel [0 = No|1 = Yes]", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cv_PrintMsgType = CreateConVar("l4d2_BwA_Print_Chat_MsgType", "2", "Determine the type and frequency of information printed to the in game chat [0 = none|1 = simple messages|2 = verbose color coded messages]", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 2.0);
    showClientID = CreateConVar("l4d2_BwA_Show_ClientID", "1", "Show the clientid next to the player name in the panel [0 = No|1 = Yes]", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cv_enablepause = CreateConVar("l4d2_BwA_TeamPanel_EnablePause", "1", "Enable/Disable this plugins pause feature (default = 1) [0 = disabled|1 = enabled]", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);

    AddCommandListener( Client_Pause, "pause");
    AddCommandListener( Client_Pause, "setpause");
    AddCommandListener( Client_Pause, "unpause");

    HookEvent("round_end", Round_End, EventHookMode_Pre);

    if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(hTopMenu);
    }

}

public OnConfigsExecuted() {

    PrintMsgType = GetConVarInt(cv_PrintMsgType);

}

stock OppositeTeam(team) {

    switch (team)
    {
        case TEAM_SPECTATOR:
        {
            return TEAM_SPECTATOR;
        }
        case TEAM_SURVIVOR:
        {
            return TEAM_INFECTED;
        }
        case TEAM_INFECTED:
        {
            return TEAM_SURVIVOR;
        }
    }

    return TEAM_NONE;

}

public OnLibraryRemoved(const String:name[]) {

    if (StrEqual(name, "adminmenu"))
    {
        LogActivity(0, "OnLibraryRemoved:AdminMenu");

        hTopMenu = INVALID_HANDLE;
    }
}

public OnAdminMenuReady(Handle:topmenu) {

    LogActivity(0, "OnAdminMenuReady:Begin");

    // Check ..
    if (topmenu == hTopMenu) return;

    // We save the handle
    hTopMenu = topmenu;

    new TopMenuObject:switch_menu = AddToTopMenu(hTopMenu, "BwASwitchMenu", TopMenuObject_Category, Admin_TopSwitchMenu, INVALID_TOPMENUOBJECT);

    // now we add the function ...
    if (switch_menu != INVALID_TOPMENUOBJECT)
    {
        LogActivity(0, "OnAdminMenuReady:Add Menu Items");

        AddToTopMenu(hTopMenu, "bwaswitchplayer", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwaswitchplayer", ADMFLAG_GENERIC, "0");
        AddToTopMenu(hTopMenu, "bwaswapplayers", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwaswapplayers", ADMFLAG_GENERIC, "1");
        AddToTopMenu(hTopMenu, "bwaunscramble", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwaunscramble", ADMFLAG_ROOT, "2");
        AddToTopMenu(hTopMenu, "bwaswapteams", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwaswapteams", ADMFLAG_GENERIC, "3");
        AddToTopMenu(hTopMenu, "bwapause", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwapause", ADMFLAG_ROOT, "4");
        AddToTopMenu(hTopMenu, "bwaunpause", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwaunpause", ADMFLAG_ROOT, "5");
        AddToTopMenu(hTopMenu, "bwacurrteams", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwacurrteams", ADMFLAG_ROOT, "6");
        AddToTopMenu(hTopMenu, "bwalastteams", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwalastteams", ADMFLAG_ROOT, "7");
        AddToTopMenu(hTopMenu, "bwadebugpanel", TopMenuObject_Item, Admin_SwitchPlayer, switch_menu, "bwadebugpanel", ADMFLAG_ROOT, "8");

    }
}

// Format very top level admin menu entry
public Admin_TopSwitchMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {

    LogActivity(0, "Admin_SwitchMenu");

    switch (action)
    {
        case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "BwA Switch Menu and Game Control");
        }
    }

}

// Handle the switch menu items (switch player/swap players)
public Admin_SwitchPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {

    LogActivity(0, "Admin_SwitchPlayer");

    adminSwitchPlayer1 = -1;
    adminSwitchPlayer2 = -1;

    new String:mnuinfo[MAX_NAME_LENGTH];
    GetTopMenuInfoString(topmenu, object_id, mnuinfo, sizeof(mnuinfo));

    new index = StringToInt(mnuinfo);

    switch(action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, CommandText[index]);
        }
        case TopMenuAction_SelectOption:
        {
            if (index == 0) { Admin_ChoosePlayerMenu(param, false); }
            else if (index == 1) { Admin_ChoosePlayerMenu(param, true); }
            else if (index == 2) { Command_Unscramble(param, 0); }
            else if (index == 3) { Command_SwapTeams(param, 0); }
            else if (index == 4) { Command_PauseGame(param, 0); }
            else if (index == 5) { Command_UnpauseGame(param, 0); }
            else if (index == 6) { ShowCurrTeamPanel(param, 0); }
            else if (index == 7) { ShowLastRoundTeamPanel(param, 0); }
            else if (index == 8) { ShowDebugMenu(param); }
        }
    }
}

// Show the menu to select a player to switch their team, or the first player to swap teams with another
Admin_ChoosePlayerMenu(client, bool:isswap) {

    decl String:title[100];

    // Save for later
    adminIsSwap = isswap;

    if (adminIsSwap)
    {
        Format(title, sizeof(title), "Swap players");
    }
    else
    {
        Format(title, sizeof(title), "Switch player");
    }

    new Handle:menu = CreateMenu(Admin_MnuHdlr_ChoosePlayer);
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);

}

// Select a player to switch their team, or the first player to swap teams with another
public Admin_MnuHdlr_ChoosePlayer(Handle:menu, MenuAction:action, param1, param2) {

    LogActivity(0, "Admin_MnuHdlr_ChoosePlayer");

    switch (action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
            {
                DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
            }
        }
        case MenuAction_Select:
        {
            decl String:info[32];

            GetMenuItem(menu, param2, info, sizeof(info));
            new target = GetClientOfUserId(StringToInt(info));

            if (target == 0)
            {
                PrintToChat(param1, "Player no longer available");
            }
            else if (!CanUserTarget(param1, target))
            {
                PrintToChat(param1, "Unable to target");
            }
            else
            {
                if (adminIsSwap)
                {
                    Admin_ChooseSwapPlayerMenu(param1, target);
                }
                else
                {
                    Admin_SwitchPlayerTeamMenu(param1, target);
                }
            }
        }
    }

}

Admin_ChooseSwapPlayerMenu(client, target) {

    LogActivity(0, "Admin_ChooseSwapPlayerMenu");

    adminSwitchPlayer1 = target;

    decl String:title[MAX_NAME_LENGTH];
    Format(title, sizeof(title), "Swap %N with:", target);

    new Handle:menu = CreateMenu(Admin_MnuHdlr_ChooseSwapPlayer);
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    GetPlayerTeams();

    new String:mnuinfo[8];
    new String:name[MAX_NAME_LENGTH];

    new team = GetClientTeam(adminSwitchPlayer1);

    for (new j = 1; j <= 3; j++)
    {
        // Skip anyone on the same team
        if (j == team) { continue; }

        for (new i = 1; i <= MaxClients; i++)
        {
            // Store the client index in the menu info
            IntToString(i, mnuinfo, 8)

            if ( (PlayerTeam[i] == j) && (!PlayerBot[i]) )
            {
                Format(name, sizeof(name),  "[%s]  %s", TeamNames[PlayerTeam[i]], PlayerName[i]);
                AddMenuItem(menu, mnuinfo, name);
            }
        }
    }

    DisplayMenu(menu, client, MENU_TIME_FOREVER);

}

public Admin_MnuHdlr_ChooseSwapPlayer(Handle:menu, MenuAction:action, param1, param2) {

    LogActivity(0, "Admin_MnuHdlr_ChooseSwapPlayer");

    switch(action)
    {
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                Admin_ChoosePlayerMenu(param1, true);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Select:
        {
            decl String:mnuinfo[8];

            GetMenuItem(menu, param2, mnuinfo, sizeof(mnuinfo));

            adminSwitchPlayer2 = StringToInt(mnuinfo);

            PerformSwap(param1, adminSwitchPlayer1, adminSwitchPlayer2);
        }
    }

}

Admin_SwitchPlayerTeamMenu(client, target) {

    LogActivity(0, "Admin_SwitchPlayerTeamMenu");

    adminSwitchPlayer1 = target;

    decl String:title[MAX_NAME_LENGTH];
    Format(title, sizeof(title), "Switch %N to:", target);

    new Handle:menu = CreateMenu(Admin_MnuHdlr_SwitchPlayerTeam);
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    new team = GetClientTeam(target);

    AddMenuItem(menu, "1", "Spectators", GetMenuEnabledFlag(team != TEAM_SPECTATOR));
    AddMenuItem(menu, "2", "Survivors", GetMenuEnabledFlag(team != TEAM_SURVIVOR));
    if ( GameHasInfected()) { AddMenuItem(menu, "3", "Infected", GetMenuEnabledFlag( team != TEAM_INFECTED ) ); }

    DisplayMenu(menu, client, MENU_TIME_FOREVER);

}

public Admin_MnuHdlr_SwitchPlayerTeam(Handle:menu, MenuAction:action, param1, param2) {

    LogActivity(0, "Admin_MnuHdlr_SwitchPlayerTeam");

    switch (action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                Admin_ChoosePlayerMenu(param1, false);
            }
        }
        case MenuAction_Select:
        {
            decl String:info[32];

            GetMenuItem(menu, param2, info, sizeof(info));

            PerformSwitch(param1, adminSwitchPlayer1, StringToInt(info), false);
        }
    }
}

ShowDebugMenu(client) {

    new Handle:menu = CreateMenu(Admin_MnuHdlr_DebugOpts);

    decl String:title[100];
    Format(title, sizeof(title), "Debugging Options");

    SetMenuTitle(menu, title);

    decl String:name[64];

    Format(name, sizeof(name),  "Debugging Off");
    AddMenuItem(menu, "0", name);

    Format(name, sizeof(name),  "Print Debug Info to Chat");
    AddMenuItem(menu, "1", name);

    Format(name, sizeof(name),  "Log Debug Info to File");
    AddMenuItem(menu, "2", name);

    DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public Admin_MnuHdlr_DebugOpts(Handle:menu, MenuAction:action, param1, param2) {

    switch (action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
            {
                DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
            }
        }
        case MenuAction_Select:
        {
            decl String:info[32];

            GetMenuItem(menu, param2, info, sizeof(info));
            new debugopt = StringToInt(info);

            if (debugopt < 0) debugopt = 0;
            if (debugopt > 2) debugopt = 2;

            DEBUG = debugopt;

            if (PrintMsgType == PRINT_SIMPLE)
            {
                PrintToChatAll("Server Debugging has been set to: %d", DEBUG);
            }
            else if (PrintMsgType == PRINT_VERBOSE)
            {
                PrintToChatAll("\x03[JBTP]\x01 Server Debugging has been set to: \x05%d", DEBUG);
            }

            LogActivity(0, "Admin_MnuHdlr_DebugOpts: %d", DEBUG);
        }
    }

}

public OnMapStart() {

    LogActivity(0, "OnMapStart");

    GetMaxValues();

    hasLastMap = (!IsFirstMap());

    lastTimestamp = GetTime();

}

public Action:Command_SwapTeams(client, args) {

    SwapTeams();

    return Plugin_Handled;

}

public Action:Command_Unscramble(client, args) {

    if (!hasLastMap)
    {
        ReplyToCommand(client, "[JBTP] Cannot call unscramble until after the first map.");
        return Plugin_Handled;
    }

    Unscramble();

    return Plugin_Handled;

}

Unscramble() {

    // Get last round players - move to temp ones for manipulation
    for (new i = 1; i <= MaxClients; i++)
    {
        // Get new correct team
        tmp_PlayerTeam[i] = OppositeTeam(LR_PlayerTeam[i]);
        tmp_PlayerBot[i] = LR_PlayerBot[i];
        tmp_PlayerSteamID[i] = LR_PlayerSteamID[i];
        tmp_PlayerName[i] = LR_PlayerName[i];
    }

    GetMaxValues();
    GetPlayerTeams();

    new speccount = 0;
    new survcount = 0;
    new infcount = 0;

    new movetospec[MaxClients];
    new movetosurv[MaxClients];
    new movetoinf[MaxClients];

    for (new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
        {
            new String:steamId[STEAMID_LENGTH];
            GetClientAuthId(i, AuthIdType:AuthId_Steam2, steamId, STEAMID_LENGTH);

            for (new j = 1; j <= MaxClients; j++)
            {
                if (StrEqual(tmp_PlayerSteamID[j], steamId))
                {
                    // Found em in the last round players
                    new currteam = GetClientTeam(i);

                    // Already on the right team? Do nothing
                    if (currteam == tmp_PlayerTeam[j]) { continue; }

                    switch(tmp_PlayerTeam[j])
                    {
                        case TEAM_SPECTATOR:
                        {
                            speccount++;
                            movetospec[speccount] = i;
                        }
                        case TEAM_SURVIVOR:
                        {
                            survcount++;
                            movetosurv[survcount] = i;
                        }
                        case TEAM_INFECTED:
                        {
                            infcount++;
                            movetoinf[infcount] = i;
                        }
                    }
                }
            }
        }
    }

    // Nothing to do? Exit.
    if ((speccount == 0) && (survcount == 0) && (infcount == 0)) { return; }

    //Move spectators first
    for (new i = 1; i <= speccount; i++)
    {
        PerformSwitch(i, movetospec[i], TEAM_SPECTATOR, true);
    }

    // See how much space is left
    new survslots = MAX_SURVIVORS - TeamCount(TEAM_SURVIVOR);
    new infslots = MAX_INFECTED - TeamCount(TEAM_INFECTED);

    new max = infcount;

    for (new i = max; i >= 1; i--)
    {
        if (infslots == 0) { break; }
        PerformSwitch(i, movetoinf[i], TEAM_INFECTED, true);
        infslots--;
        infcount--;
    }

    max = survcount;

    for (new i = max; i >= 1; i--)
    {
        if (survslots == 0) { break; }
        PerformSwitch(i, movetosurv[i], TEAM_SURVIVOR, true);
        survslots--;
        survcount--;
    }

    while ((infcount > 0) && (survcount > 0))
    {
        PerformSwap (0, movetosurv[survcount], movetoinf[infcount]);
        survcount--;
        infcount--;
    }

}

SwapTeams() {

    GetMaxValues();

    new survcount = 0;
    new infcount = 0;

    new movetosurv[MaxClients];
    new movetoinf[MaxClients];

    for (new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
        {
            new currteam = GetClientTeam(i);

            switch(currteam)
            {
                case TEAM_SURVIVOR:
                {
                    survcount++;
                    movetoinf[survcount] = i;
                }
                case TEAM_INFECTED:
                {
                    infcount++;
                    movetosurv[infcount] = i;
                }
            }
        }
    }

    while ((infcount > 0) && (survcount > 0))
    {
        PerformSwap (0, movetosurv[infcount], movetoinf[survcount]);
        survcount--;
        infcount--;
    }

    // See how much space is left
    new survslots = MAX_SURVIVORS - TeamCount(TEAM_SURVIVOR);
    new infslots = MAX_INFECTED - TeamCount(TEAM_INFECTED);

    new max = survcount;

    for (new i = max; i >= 1; i--)
    {
        if (infslots == 0) { break; }
        PerformSwitch(i, movetoinf[i], TEAM_INFECTED, true);
        infslots--;
        infcount--;
    }

    max = infcount;

    for (new i = max; i >= 1; i--)
    {
        if (survslots == 0) { break; }
        PerformSwitch(i, movetosurv[i], TEAM_SURVIVOR, true);
        survslots--;
        survcount--;
    }

}

stock FirstHumanSurvivor() {

    for (new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == TEAM_SURVIVOR) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            return i;
        }
    }

    return -1;
}

public OnMapEnd() {

    hasLastMap = true;

    // Save the settings for the end of round
    for (new i = 1; i <= MaxClients; i++)
    {
        LR_PlayerTeam[i] = tmp_PlayerTeam[i];
        LR_PlayerBot[i] = tmp_PlayerBot[i];
        LR_PlayerSteamID[i] = tmp_PlayerSteamID[i];
        LR_PlayerName[i] = tmp_PlayerName[i];
    }

}

stock bool:IsFirstMap() {

    decl String:mapname[128];
    GetCurrentMap(mapname, sizeof(mapname));

    return (StrContains(mapname, "m1_", false) != -1);
}

public Action:Round_End(Handle:event, String:event_name[], bool:dontBroadcast) {

    LogActivity(0, "Round_End");

    GetPlayerTeams();

    // Save the settings for the end of round
    for (new i = 1; i <= MaxClients; i++)
    {
        if (specTimer[i] != INVALID_HANDLE) {
            KillTimer(specTimer[i]);
            specTimer[i] = INVALID_HANDLE;
        }

        tmp_PlayerTeam[i] = PlayerTeam[i];
        tmp_PlayerBot[i] = PlayerBot[i];
        tmp_PlayerSteamID[i] = PlayerSteamID[i];
        tmp_PlayerName[i] = PlayerName[i];
    }

    return Plugin_Continue;

}

public OnClientAuthorized(client, const String:auth[]) {

    new now = GetTime();

    // Only move spectators for the first ACTIVE_SECONDS of round
    if ((now - lastTimestamp) > ACTIVE_SECONDS) return;

    new index = Get_LR_SpectatorIndex(auth);

    if (index == -1) return;

    specTimer[index] = CreateTimer(1.0, Timer_MoveToSpec, client, TIMER_REPEAT);
}

public OnClientDisconnect(client) {

    new String:steamId[STEAMID_LENGTH];

    GetClientAuthId(client, AuthIdType:AuthId_Steam2, steamId, STEAMID_LENGTH);

    new index = Get_LR_SpectatorIndex(steamId);

    if (index == -1) return;

    if (specTimer[index] == INVALID_HANDLE) return;

    KillTimer(specTimer[index]);
    specTimer[index] = INVALID_HANDLE;

}

public Action:Timer_MoveToSpec(Handle:timer, any:client) {

    if (!IsClientInGame(client)) return Plugin_Continue;

    new String:auth[STEAMID_LENGTH];

    GetClientAuthId(client, AuthIdType:AuthId_Steam2, auth, STEAMID_LENGTH);

    new index = Get_LR_SpectatorIndex(auth);

    if (index == -1) return Plugin_Stop;

    specTimer[index] = INVALID_HANDLE;

    new team = GetClientTeam(client);

    if (team == TEAM_SPECTATOR ) { return Plugin_Stop; }

    ChangeClientTeam(client, TEAM_SPECTATOR);

    if (PrintMsgType == PRINT_SIMPLE)
    {
        PrintToChatAll("Found %s on %s team. Moved them back to spectator.", LR_PlayerName[index], ProperTeamNames[team]);
    }
    else if (PrintMsgType == PRINT_VERBOSE)
    {
        PrintToChatAll("\x03[JBTP]\x01 Found \x04%s\x01 on \x04%s\x01 team. Moved them back to \x04Spectator.", LR_PlayerName[index], ProperTeamNames[team]);
    }

    return Plugin_Stop;
}

// Get Index of last round
Get_LR_SpectatorIndex(const String:SteamId[]) {

    for (new i = 1; i <= MaxClients; i++)
    {
        if ((LR_PlayerTeam[i] == TEAM_SPECTATOR) &&  StrEqual(LR_PlayerSteamID[i], SteamId))
        {
            return i;
        }
    }

    return -1;

}

stock GetMaxValues() {

    MAX_SURVIVORS =  GetConVarInt(FindConVar("survivor_limit"));
    MAX_INFECTED =  GameHasInfected() ? GetConVarInt(FindConVar("z_max_player_zombies")) : 0;
}

stock bool:IsTeamFull(team) {

    LogActivity(0, "IsTeamFull: \x04%s", ProperTeamNames[_:team]);

    if (team == TEAM_SPECTATOR) { return false; }

    GetMaxValues();

    new count = TeamCount(team);

    if (team == TEAM_INFECTED)
    {
        LogActivity(0, "IsTeamFull \x04Infected\x01 Count: \x05%d\x01  Max: \x05%d\x01", count, MAX_INFECTED);
        return (count >= MAX_INFECTED);
    }
    else
    {
        LogActivity(0, "IsTeamFull \x04Survivor\x01 Count: \x05%d\x01  Max: \x05%d\x01", count, MAX_SURVIVORS);
        return (count >= MAX_SURVIVORS);
    }

}

stock bool:IsTeamEmpty(team) {

    LogActivity(0, "IsTeamEmpty: \x04%s", ProperTeamNames[team]);

    // we see if there are any players on the team
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if ( (IsClientConnected(i)) && (!IsFakeClient(i)) && (GetClientTeam(i)==team) )
            {
                return false;
            }
        }
    }

    return true;

}

stock TeamCount(team) {

    new count = 0;

    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if ( (IsClientConnected(i)) && (!IsFakeClient(i)) && (GetClientTeam(i) == team) )
            {
                count++;
            }
        }
    }

    return count;

}

stock bool:CanSwap(client) {

    LogActivity(client, "CanSwap");

    new team = GetClientTeam(client);

    switch (team)
    {
        case TEAM_SURVIVOR:
        {
            if ( (GetGameMode() == GM_VERSUS) || (GetGameMode() == GM_SCAVENGE) )
            {
                return !(IsTeamEmpty(TEAM_INFECTED) && IsTeamEmpty(TEAM_SPECTATOR));
            }
            else
            {
                return !(IsTeamEmpty(TEAM_SPECTATOR));
            }
        }
        case TEAM_INFECTED:
        {
            return !(IsTeamEmpty(TEAM_SURVIVOR) && IsTeamEmpty(TEAM_SPECTATOR));
        }
        case TEAM_SPECTATOR:
        {
            if ( (GetGameMode() == GM_VERSUS) || (GetGameMode() == GM_SCAVENGE) )
            {
                return !(IsTeamEmpty(TEAM_INFECTED) && IsTeamEmpty(TEAM_SURVIVOR));
            }
            else
            {
                return !(IsTeamEmpty(TEAM_SURVIVOR));
            }
        }
    }

    return false;

}

stock bool:GameHasInfected() {

    LogActivity(0, "GameHasInfected");

    new gm = GetGameMode();

    return ( (gm == GM_VERSUS) || (gm == GM_SCAVENGE) );

}

GetMenuEnabledFlag(bool:enabled) {

    LogActivity(0, "GetMenuEnabledFlag");

    if ( enabled )
    {
        return ITEMDRAW_DEFAULT;
    }
    else
    {
        return ITEMDRAW_DISABLED;
    }

}

// Get players/teams/steamid/bots and store in arrays
GetPlayerTeams() {

    LogActivity(0, "GetPlayerTeams()");

    GetMaxValues();

    //Calculate who is on what team
    for (new i = 1; i <= MaxClients; i++)
    {
        LogActivity(0, "GetPlayerTeams: Player# \x04%d", i);

        // Set defaults
        PlayerTeam[i] = TEAM_NONE;
        PlayerBot[i] = false;
        PlayerSteamID[i] = "";
        PlayerName[i] = "";

        if (IsClientConnected(i) && IsClientInGame(i))
        {
            new team = GetClientTeam(i);

            GetClientName(i, PlayerName[i], MAX_NAME_LENGTH);

            if ( (team == TEAM_SPECTATOR) || (team == TEAM_SURVIVOR) || (team == TEAM_INFECTED) )
            {
                PlayerTeam[i] = team;

                if (IsFakeClient(i))
                {
                    LogActivity(0, "GetPlayerTeams: \x04Bot");
                    PlayerBot[i] = true;
                }
                else
                {
                    LogActivity(0, "GetPlayerTeams: GetSteamID");
                    GetClientAuthId(i, AuthIdType:AuthId_Steam2, PlayerSteamID[i], STEAMID_LENGTH);
                }
            }
        }
    }

}

// General game type - need to know if there are two teams or not
GetGameMode() {

    new String:gamemodecvar[16];
    GetConVarString(FindConVar("mp_gamemode"), gamemodecvar, sizeof(gamemodecvar));

    // Versus or Team Versus
    if (StrContains(gamemodecvar, "versus", false) != -1)
    {
        return GM_VERSUS;
    }
    // Scavenge, Team Scavenge
    else if (StrContains(gamemodecvar, "scavenge", false) != -1)
    {
        return GM_SCAVENGE;
    }
    //Campaign
    else if (StrContains(gamemodecvar, "coop", false) != -1)
    {
        return GM_COOP;
    }
    return GM_UNKNOWN;

}

public Action:Command_PauseGame(client, args) {

    if(!GetConVarBool(cv_enablepause)) { return Plugin_Handled; }

    if (isGamePaused) return Plugin_Handled;

    allowPause = true;
    SetConVarInt(FindConVar("sv_pausable"), 1); //Ensure sv_pausable is set to 1
    FakeClientCommand(client, "setpause"); //Send pause command
    SetConVarInt(FindConVar("sv_pausable"), 0); //Reset sv_pausable back to 0
    allowPause = false;

    iInitialAllTalk = GetConVarInt(FindConVar("sv_alltalk"));
    SetConVarInt(FindConVar("sv_alltalk"), 1);

    if (PrintMsgType == PRINT_SIMPLE)
    {
        PrintToChatAll("The game has been paused, and AllTalk is now on.");
    }
    else if (PrintMsgType == PRINT_VERBOSE)
    {
        PrintToChatAll("\x03[JBTP]\x01 \x04%N\x01 has paused the game, and AllTalk is now on.", client);
    }

    isGamePaused = true;

    return Plugin_Handled;

}

public Action:Command_UnpauseGame(client, args) {

    if(!GetConVarBool(cv_enablepause)) { return Plugin_Handled; }

    if (!isGamePaused) return Plugin_Handled;

    if (PrintMsgType == PRINT_SIMPLE)
    {
        PrintToChatAll("%N has unpaused the game", client);
    }
    else if (PrintMsgType == PRINT_VERBOSE)
    {
        PrintToChatAll("\x03[JBTP]\x01 \x04%N\x01 has unpaused the game", client);
    }

    CreateTimer(1.0, UnPauseCountDown, client, TIMER_REPEAT);

    return Plugin_Handled;
}

public Action:UnPauseCountDown(Handle:timer, any:client) {

    static Countdown = L4D_UNPAUSE_DELAY-1;

    if (Countdown <= 0)
    {
        Countdown = L4D_UNPAUSE_DELAY-1;

        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChatAll("Game is now live!");
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChatAll("\x03[JBTP]\x01 Game is now live!");
        }

        allowPause = true;
        SetConVarInt(FindConVar("sv_pausable"), 1);
        FakeClientCommand(client, "unpause");
        SetConVarInt(FindConVar("sv_pausable"), 0);
        allowPause = false;

        SetConVarInt(FindConVar("sv_alltalk"), iInitialAllTalk);

        isGamePaused = false;
        return Plugin_Stop;
    }

    if (PrintMsgType == PRINT_SIMPLE)
    {
        PrintToChatAll("Game is live in %d seconds...", Countdown);
    }
    else if (PrintMsgType == PRINT_VERBOSE)
    {
        PrintToChatAll("\x03[JBTP]\x01 Game is going live in %d seconds...", Countdown);
    }

    Countdown--;

    return Plugin_Continue;
}

// This blocks the pause/unpause that happens when clients open developer console
public Action:Client_Pause(client, const String:command[], argc)  {

    if(!GetConVarBool(cv_enablepause)) { return Plugin_Continue; }

    if(allowPause) { return Plugin_Continue; }

    return Plugin_Handled;
}

public Action:Show_About(client, args) {

    PrintToChatAll("\x03Jesters\x01 \x04-=BwA=- Team Panel and Switchmenu Plugin\x01. Version \x05%s", PLUGIN_VERSION);

}

public Action:ShowCurrTeamPanel(client, args) {

    LogActivity(client, "ShowCurrTeamPanel");

    GetPlayerTeams();

    BuildPlayerPanel(client, false);

    return Plugin_Handled;

}

public Action:ShowLastRoundTeamPanel(client, args) {

    LogActivity(client, "ShowLastRoundTeamPanel");

    if (!hasLastMap)
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChatAll("There was no last round.");
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 There was no last round to verify against. Please wait until the entire first round has been played to call this function.");
        }
        return Plugin_Handled;
    }

    for (new i = 1; i <= MaxClients; i++)
    {
        PlayerTeam[i] = LR_PlayerTeam[i];
        PlayerBot[i] = LR_PlayerBot[i];
        PlayerSteamID[i] = LR_PlayerSteamID[i];
        PlayerName[i] = LR_PlayerName[i];
    }

    BuildPlayerPanel(client, true);

    return Plugin_Handled;

}

// Show the teams panel to a player
BuildPlayerPanel(client, bool:isLastround) {

    new speccount = 0;
    new survcount = 0;
    new infcount = 0;
    new nonecount = 0;

    new survbotcount = 0;
    new infbotcount = 0;
    new specbotcount = 0;

    new bool:showid = GetConVarBool(showClientID);

    LogActivity(client, "BuildPlayerPanel: Maxclients = \x04%d", MaxClients);

    //Calculate the numbers of each team
    for (new i = 1; i <= MaxClients; i++)
    {
        switch(PlayerTeam[i])
        {
            case TEAM_SPECTATOR:
            {
                if (PlayerBot[i]) { specbotcount++; } else { speccount++; }
            }
            case TEAM_SURVIVOR:
            {
                if (PlayerBot[i]) { survbotcount++; } else { survcount++; }
            }
            case TEAM_INFECTED:
            {
                if (PlayerBot[i]) { infbotcount++; } else { infcount++; }
            }
            default:
            {
                nonecount++;
            }
        }
    }

    GetMaxValues();

    new Handle:playerpanel = CreatePanel();

    new String:text[MAX_NAME_LENGTH];
    if (isLastround)
    {
        Format(text, sizeof(text), "Team Info - Current");
    }
    else
    {
        Format(text, sizeof(text), "Team Info - Last Map");
    }

    SetPanelTitle(playerpanel, text);
    DrawPanelText(playerpanel, " \n");

    new totalrealplayers = speccount + survcount + infcount;

    LogActivity(client, "BuildPlayerPanel: Total = %d, Specs = %d, Survs = %d, Inf = %d", totalrealplayers, speccount, survcount, infcount);

    //Draw Spectators Title Line
    Format(text, sizeof(text), "Spectators (%d of %d)\n", speccount, MaxClients - (MAX_SURVIVORS + MAX_INFECTED));

    DrawPanelItem(playerpanel, text, GetMenuEnabledFlag(GetConVarBool(selectTeamFromPanel)));

    // Draw Spectator Player Names
    new count = 0;

    LogActivity(client, "BuildPlayerPanel: Draw Spectator Player Names");

    for (new j = 1; j <= MaxClients; j++)
    {
        if (PlayerTeam[j] == TEAM_SPECTATOR)
        {
            count++;

            if (PlayerBot[j] || !showid)
            {
                Format(text, sizeof(text), "%d. %s", count, PlayerName[j]);
                DrawPanelText(playerpanel, text);
            }
            else
            {
                Format(text, sizeof(text), "%d. %s (%d)", count, PlayerName[j], j);
                DrawPanelText(playerpanel, text);
            }
        }
    }

    DrawPanelText(playerpanel, " \n");

    //Draw Survivors Title Line
    Format(text, sizeof(text), "Survivors (%d of %d)\n", survcount, MAX_SURVIVORS);
    DrawPanelItem(playerpanel, text, GetMenuEnabledFlag(GetConVarBool(selectTeamFromPanel)));

    // Draw Survivor Player Names
    count = 0;

    LogActivity(client, "BuildPlayerPanel: Draw Survivor Player Names");

    for (new j = 1; j <= MaxClients; j++)
    {
        if (PlayerTeam[j] == TEAM_SURVIVOR)
        {
            count++;

            new String:name[MAX_NAME_LENGTH + 1];

            if (IsClientInGame(j) && IsPlayerAlive(j))
            {
                Format(name, sizeof(name), "%s", PlayerName[j]);
            }
            else
            {
                Format(name, sizeof(name), "%s*", PlayerName[j]);
            }

            if (PlayerBot[j] || !showid)
            {
                Format(text, sizeof(text), "%d. %s", count, name);
                DrawPanelText(playerpanel, text);
            }
            else
            {
                Format(text, sizeof(text), "%d. %s (%d)", count, name, j);
                DrawPanelText(playerpanel, text);
            }
        }
    }

    DrawPanelText(playerpanel, " \n");

    //Draw Infected Title Line if versus
    if ( GameHasInfected() )
    {
        LogActivity(client, "BuildPlayerPanel: Draw Infected Player Names");

        //Draw Infected Title Line
        Format(text, sizeof(text), "Infected (%d of %d)\n", infcount, MAX_INFECTED);

        // Draw Infected Player Names
        DrawPanelItem(playerpanel, text, GetMenuEnabledFlag(GetConVarBool(selectTeamFromPanel)));

        count = 0;

        for (new j = 1; j <= MaxClients; j++)
        {
            if (PlayerTeam[j] == TEAM_INFECTED)
            {
                count++;

                if (PlayerBot[j])
                {
                    Format(text, sizeof(text), "%d. %s", count, PlayerName[j]);
                    DrawPanelText(playerpanel, text);
                }
                else
                {
                    if(showid)
                    {
                        if(GetEntProp(j, Prop_Send, "m_zombieClass") == 8)
                        {
                            Format(text, sizeof(text), "%d. %s (%d) [Tank]", count, PlayerName[j], j);
                        }
                        else
                        {
                            Format(text, sizeof(text), "%d. %s (%d)", count, PlayerName[j], j);
                        }
                    }
                    else
                    {
                        if(GetEntProp(j, Prop_Send, "m_zombieClass") == 8)
                        {
                            Format(text, sizeof(text), "%d. %s [Tank]", count, PlayerName[j]);
                        }
                        else
                        {
                            Format(text, sizeof(text), "%d. %s", count, PlayerName[j]);
                        }
                    }
                    DrawPanelText(playerpanel, text);
                }
            }
        }

        //Draw Total connected Players & Draw Final
        DrawPanelText(playerpanel, " \n");
    }

    Format(text, sizeof(text), "Connected: %d/%d", totalrealplayers, MaxClients);
    DrawPanelText(playerpanel, text);

    //DrawPanelText(playerpanel, " \n");

    //Format(text, sizeof(text), "MaxClients: %d", MaxClients);
    //DrawPanelText(playerpanel, text);
    //Format(text, sizeof(text), "MAX_SURVIVORS: %d", MAX_SURVIVORS);
    //DrawPanelText(playerpanel, text);
    //Format(text, sizeof(text), "MAX_INFECTED: %d", MAX_INFECTED);
    //DrawPanelText(playerpanel, text);

    //Send Panel to client
    SendPanelToClient(playerpanel, client, PlayerPanelHandler, 30);
    CloseHandle(playerpanel);
}

public PlayerPanelHandler(Handle:TeamPanel, MenuAction:action, param1, param2) {

    if (action == MenuAction_Select)
    {
        if (GetConVarBool(selectTeamFromPanel))
        {
            switch(param2)
            {
                case TEAM_SPECTATOR:
                {
                    LogActivity(param1, "JoinSpectatorTeam");
                    PerformSwitch(param1, param1, TEAM_SPECTATOR, false);
                }
                case TEAM_SURVIVOR:
                {
                    LogActivity(param1, "JoinSurvivorTeam");
                    PerformSwitch(param1, param1, TEAM_SURVIVOR, false);
                }
                case TEAM_INFECTED:
                {
                    LogActivity(param1, "JoinInfectedTeam");
                    PerformSwitch(param1, param1, TEAM_INFECTED, false);
                }
            }
        }
    }

}

public Action:JoinSpectatorTeam(client, args) {

    if (! GetConVarBool(allowpubs)) { return Plugin_Handled; }

    LogActivity(client, "JoinSpectatorTeam");

    PerformSwitch(client, client, TEAM_SPECTATOR, false);
    return Plugin_Handled;

}

public Action:JoinInfectedTeam(client, args) {

    if (! GetConVarBool(allowpubs)) { return Plugin_Handled; }

    LogActivity(client, "JoinInfectedTeam");

    PerformSwitch(client, client, TEAM_INFECTED, false);
    return Plugin_Handled;

}

public Action:JoinSurvivorTeam(client, args) {

    if (! GetConVarBool(allowpubs)) { return Plugin_Handled; }

    LogActivity(client, "JoinSurvivorTeam");

    PerformSwitch(client, client, TEAM_SURVIVOR, false);
    return Plugin_Handled;

}

stock CreateRandomInt(min, max) {

    SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0 * float(max)));
    return GetRandomInt(min, max);

}

public Action:JoinTeam(client, args) {

    LogActivity(client, "JoinTeam");

    GetMaxValues();

    // See how much space is left on the teams
    new survslots = MAX_SURVIVORS - TeamCount(TEAM_SURVIVOR);
    new infslots = MAX_INFECTED - TeamCount(TEAM_INFECTED);

    if (survslots > infslots)
    {
        PerformSwitch(client, client, TEAM_SURVIVOR, false);
        return Plugin_Handled;
    }

    if (infslots > survslots)
    {
        PerformSwitch(client, client, TEAM_INFECTED, false);
        return Plugin_Handled;
    }

    // Equal slots if we got here
    if (survslots == 0)
    {
        PrintToChat(client, "There are no open team slots to join.");
        return Plugin_Handled;
    }

    return Plugin_Handled;

}

public Action:Command_Debug(client, args) {

    if (args < 1)
    {
        ReplyToCommand(client, "\x03[JBTP]\x01 Usage: \x04sm_debug\x01 [0 = Off|1 = On]");
        return Plugin_Handled;
    }

    decl String:arg[MAX_NAME_LENGTH];
    GetCmdArg(1, arg, sizeof(arg));

    DEBUG = StringToInt(arg);

    LogActivity(client, "Command_Debug: %d", DEBUG);

    return Plugin_Handled;

}

public Action:Command_SwitchPlayer(client, args) {

    if (args < 2)
    {
        ReplyToCommand(client, "\x03[JBTP]\x01 Cannot switch without a player and a team");
        return Plugin_Continue;
    }

    decl String:argclient[8], String:argteam[8];

    GetCmdArg(1, argclient, sizeof(argclient));
    GetCmdArg(2, argteam, sizeof(argteam));

    new player = StringToInt(argclient);
    new team = StringToInt(argteam);

    LogActivity(client, "Command_SwitchPlayer: %N to %s", player, ProperTeamNames[team]);

    PerformSwitch(client, player, team, false);

    return Plugin_Handled;

}

stock bool:IsValidPlayerIndex(clientid) {

    return ( (clientid > 0) && (clientid <= MaxClients) );

}

stock bool:IsValidPlayer(clientid) {

    return (IsClientInGame(clientid) && IsClientConnected(clientid) && !IsFakeClient(clientid));

}

bool PerformSwitch(client, target, team, bool:silent) {

    LogActivity(client, "PerformSwitch %i to %d", target, ProperTeamNames[team]);

    if (!IsValidPlayerIndex(target))
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "Player %i is not a valid target.", target);
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 Player Index \x05%i\x01 is not a valid target and was out of range.", target);
        }
        return false;
    }

    // Check if player is still valid ...
    if (!IsValidPlayer(target))
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "Player %i is not connected or in the game anymore.", target);
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 Player Index \x05%i\x01 is not connected or in the game anymore.", target);
        }
        return false;
    }

    // If teams are the same ...
    if (GetClientTeam(target) == team)
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "Player %N is already on the %s team.", target, ProperTeamNames[team]);
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 Player \x04%N\x01 is already on the \x04%s\x01 team.", target, ProperTeamNames[team]);
        }
        return false;
    }

    // We check if target team is full...
    if (IsTeamFull(team))
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "%s team is already full.", ProperTeamNames[team]);
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 The \x04%s\x01 team is already full.", ProperTeamNames[team]);
        }
        return false;
    }

    // If player was on infected ....
    if (GetClientTeam(target) == TEAM_INFECTED)
    {
        // ... and he wasn't a tank ...
        new String:iClass[100];

        GetClientModel(target, iClass, sizeof(iClass));

        if (StrContains(iClass, "hulk", false) == -1)
        {
            ForcePlayerSuicide(target);
        }
    }

    // If target is survivors
    if (team == TEAM_SURVIVOR)
    {
        LogActivity(client, "PerformSwitch Change To \x04Survivors");

        // first we switch to spectators ..
        ChangeClientTeam(target, TEAM_SPECTATOR);

        int bot;
        bool findBot;

        // Search for an empty bot
        for (bot = 1; bot <= MaxClients; bot++)
        {
            if (!IsClientInGame(bot))
                continue;

            if (!IsFakeClient(bot))
                continue;

            if (GetClientTeam(bot) != TEAM_SURVIVOR)
                continue;

            findBot = true;

            break;
        }

        if (!findBot)
            return false;

        LogActivity(client, "PerformSwitch SDK calls - bot Index: %d   bot Name: %N   target Index: %d   target Name: %N", bot, bot, target, target);

        // force player to spec humans
        SDKCall(sdkSetPlayerSpec, bot, target);

        LogActivity(client, "PerformSwitch SDK calls - target: %d", target);

        // force player to take over bot
        SDKCall(sdkTakeOverBot, target, true);

    }
    else // We change it's team ...
    {
        ChangeClientTeam(target, team);
    }

    if (!silent)
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChatAll("%N has been moved to the %s team.", target, ProperTeamNames[team]);
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChatAll("\x03[JBTP]\x01 \x04%N\x01 has been moved to the \x04%s\x01 team.", target, ProperTeamNames[team]);
        }
    }

    return true;

}

public Action:Command_SwapPlayers(client, args) {

    if (args < 2)
    {
        PrintToChat(client, "\x03[JBTP]\x01 Cannot swap without two player id's");
        return Plugin_Continue;
    }

    decl String:arg1[4], String:arg2[4];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    new swapplayer1 = StringToInt(arg1);
    new swapplayer2 = StringToInt(arg2);

    LogActivity(client, "SwapPlayers \x05(%d)\x04%N\x01 and \x05(%d)\x04%N", swapplayer1, swapplayer1, swapplayer2, swapplayer2 );

    // If client 1 and 2 are the same ...
    if (swapplayer1 == swapplayer2)
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChatAll("Can't swap this player with himself.");
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 Can't swap this player with himself.");
        }
        return Plugin_Continue;
    }

    // Check if 1st player is still valid ...
    if ( (!IsClientConnected(swapplayer1)) || (!IsClientInGame(swapplayer1)))
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "First player is not available anymore.");
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 First player is not available anymore.");
        }
        return Plugin_Continue;
    }

    // Check if 2nd player is still valid ....
    if ((!IsClientConnected(swapplayer2)) || (!IsClientInGame(swapplayer2)))
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "Second player is not available anymore.");
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 Second player is not available anymore.");
        }
        return Plugin_Continue;
    }

    PerformSwap(client, swapplayer1, swapplayer2);

    return Plugin_Continue;

}

PerformSwap (client, swapplayer1, swapplayer2) {

    // get the teams of each player
    new team1 = GetClientTeam(swapplayer1);
    new team2 = GetClientTeam(swapplayer2);

    LogActivity(client, "PerformSwap \x04%N\x01 and \x04%N", swapplayer1, swapplayer2);

    // If both players are on the same team ...
    if (team1 == team2)
    {
        if (PrintMsgType == PRINT_SIMPLE)
        {
            PrintToChat(client, "Can't swap players that are on the same team!");
        }
        else if (PrintMsgType == PRINT_VERBOSE)
        {
            PrintToChat(client, "\x03[JBTP]\x01 Players \x04%N\x01 and \x04%N\x01 are on the same team and cannot be swapped.", swapplayer1, swapplayer2);
        }
        return;
    }

    // Just in case survivor's team becomes empty (copied from Downtown1's L4d Ready up plugin)
    // if ((FindConVar("sb_all_bot_team") != INVALID_HANDLE) { SetConVarInt(FindConVar("sb_all_bot_team"), 1); }

    LogActivity(client, "PerformSwap:PerformSwitch \x04%N\x01 and \x04%N\x01 to \x04Spectator", swapplayer1, swapplayer2);

    // first we move both clients to spectators
    PerformSwitch(client, swapplayer1, TEAM_SPECTATOR, true);
    PerformSwitch(client, swapplayer2, TEAM_SPECTATOR, true);

    LogActivity(client, "PerformSwap:PerformSwitch \x04%N\x01 to \x04%s", swapplayer1, ProperTeamNames[team2]);

    PerformSwitch(client, swapplayer1, team2, (PrintMsgType < PRINT_VERBOSE));

    LogActivity(client, "PerformSwap:PerformSwitch \x04%N\x01 to \x04%s", swapplayer2, ProperTeamNames[team1]);

    PerformSwitch(client, swapplayer2, team1, (PrintMsgType < PRINT_VERBOSE));

    //LogActivity(client, "ResetConVar 'sb_all_bot_team'");

    // Just in case survivor's team becomes empty
    //if ((FindConVar("sb_all_bot_team") != INVALID_HANDLE) { ResetConVar(FindConVar("sb_all_bot_team")); }

    if (PrintMsgType == PRINT_SIMPLE)
    {
        PrintToChatAll("%N has been swapped with %N", swapplayer1, swapplayer2);
    }
    else if (PrintMsgType == PRINT_VERBOSE)
    {
        PrintToChatAll("\x03[JBTP]\x01 \x04%N\x01 has been swapped with \x04%N", swapplayer1, swapplayer2);
    }
    return;

}

public Action:SwitchMenu(client, args) {

    if (! GetConVarBool(allowpubs)) { return Plugin_Handled; }

    new Handle: menu = CreateMenu(SwitchMenu_MenuHandler);

    SetMenuTitle(menu, "Switch Options");

    new String:mnuinfo[8];

    IntToString(TEAM_SPECTATOR, mnuinfo, sizeof(mnuinfo))
    AddMenuItem( menu, mnuinfo, "Switch to Spectator", GetMenuEnabledFlag( !IsTeamFull(TEAM_SPECTATOR) && !(GetClientTeam(client) == TEAM_SPECTATOR) ) );

    IntToString(TEAM_SURVIVOR, mnuinfo, sizeof(mnuinfo))
    AddMenuItem( menu, mnuinfo, "Switch to Survivor", GetMenuEnabledFlag( !IsTeamFull(TEAM_SURVIVOR) && !(GetClientTeam(client) == TEAM_SURVIVOR) ) );

    IntToString(TEAM_INFECTED, mnuinfo, sizeof(mnuinfo))
    AddMenuItem(menu, mnuinfo, "Switch to Infected", GetMenuEnabledFlag( GameHasInfected() && !IsTeamFull(TEAM_INFECTED) && !(GetClientTeam(client) == TEAM_INFECTED) ) );

    IntToString(4, mnuinfo, sizeof(mnuinfo))
    AddMenuItem(menu, mnuinfo, "Swap teams with someone", GetMenuEnabledFlag(CanSwap(client)) );

    IntToString(5, mnuinfo, sizeof(mnuinfo))
    AddMenuItem(menu, mnuinfo, "View Current Teams Info");

    IntToString(6, mnuinfo, sizeof(mnuinfo))
    AddMenuItem(menu, mnuinfo, "View Last Round Teams Info", GetMenuEnabledFlag( hasLastMap));

    DisplayMenu(menu, client, 30);

    return Plugin_Handled;

}

public SwitchMenu_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {

    switch(action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Select:
        {
            decl String:item1[64];

            GetMenuItem(menu, param2, item1, sizeof(item1));

            LogActivity(0, "SwitchMenu:MenuAction_Select: %s", item1);

            switch (StringToInt(item1))
            {
                case TEAM_SPECTATOR:
                {
                    PerformSwitch(param1, param1, TEAM_SPECTATOR, false);
                }
                case TEAM_SURVIVOR:
                {
                    PerformSwitch(param1, param1, TEAM_SURVIVOR, false);
                }
                case TEAM_INFECTED:
                {
                    PerformSwitch(param1, param1, TEAM_INFECTED, false);
                }
                case 4:
                {
                    SwapWithMe(param1, 0);
                }
                case 5:
                {
                    ShowCurrTeamPanel(param1, 0);
                }
                case 6:
                {
                    ShowLastRoundTeamPanel(param1, 0);
                }
            }
        }
    }

}

public Action:SwapWithMe(client, args) {

    if (! GetConVarBool(allowpubs)) { return Plugin_Handled; }

    LogActivity(client, "SwapWithMe %N", client);

    new Handle: menu = CreateMenu(SwapWithMe_MenuHandler);

    SetMenuTitle(menu, "Players to Swap With");

    new team = GetClientTeam(client);

    GetPlayerTeams();

    new String:mnuinfo[8];
    new String:name[MAX_NAME_LENGTH];

    for (new j = 1; j <= 3; j++)
    {
        if (j == team) { continue; }

        for (new i = 1; i <= MaxClients; i++)
        {
            // Store the client index in the menu info
            IntToString(i, mnuinfo, 4)

            if ( (PlayerTeam[i] == j) && (!PlayerBot[i]) )
            {
                Format(name, sizeof(name),  "[%s]  %s", TeamNames[PlayerTeam[i]], PlayerName[i]);
                AddMenuItem(menu, mnuinfo, name);
            }
        }
    }

    DisplayMenu(menu, client, 30);

    return Plugin_Handled;

}

public SwapWithMe_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {

    switch(action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Select:
        {
            decl String:mnuinfo[64];

            GetMenuItem(menu, param2, mnuinfo, sizeof(mnuinfo));

            LogActivity(0, "SwapWithMe:MenuAction_Select: %s", mnuinfo);

            // mnuinfo is the client index from the menu choice
            AskSwapWithMe(param1, StringToInt(mnuinfo));
        }
    }

}

AskSwapWithMe(client, clientToAsk) {

    new Handle: menu = CreateMenu(AskSwapWithMe_MenuHandler);

    SetMenuTitle(menu, "Swap Teams with %N? [ 1 = Yes, 0 = No ]", client);

    LogActivity(client, "AskSwapWithMe:Swap with %N", client);

    decl String:menuinf[8], String:mnutext[MAX_NAME_LENGTH];

    IntToString(client, menuinf, sizeof(menuinf));

    new team = GetClientTeam(client);

    LogActivity(client, "AskSwapWithMe:Swap to %s", ProperTeamNames[team]);

    Format(mnutext,    sizeof(mnutext), "Yes - I will swap to %s", ProperTeamNames[team]);
    AddMenuItem(menu, menuinf, mnutext)

    DisplayMenu(menu, clientToAsk, 30);

}

// Param1 is client agreeing to swap, param2 contains mnuinfo of original client asking to swap
public AskSwapWithMe_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {

    switch(action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_Select:
        {
            decl String:mnuinfo[8];

            GetMenuItem(menu, param2, mnuinfo, sizeof(mnuinfo));

            new origclienttoswap = StringToInt(mnuinfo);

            LogActivity(param1, "AskSwapWithMe:MenuAction_Select: Swap %N with %N, ID1 = %d, ID2 = %d", origclienttoswap, param1, origclienttoswap, param1);

            PerformSwap(param1, param1, origclienttoswap);
        }
    }

}

void LogActivity(client, const String:msg[], any:...) {

    switch (DEBUG)
    {
        case 1: // Print to chat
        {
            new String:message[MAX_NAME_LENGTH + 255];
            Format(message, sizeof(message), "\x03[JBTP]\x01 ");

            new String:formattedmsg[255];
            VFormat(formattedmsg, sizeof(formattedmsg), msg, 3);

            StrCat(message, sizeof(message), formattedmsg)

            PrintToChatAll(message);
        }
        case 2: // Log to file
        {
            new String:message[MAX_NAME_LENGTH + 255];
            Format(message, sizeof(message), "[JBTP] %N: ", client);

            new String:formattedmsg[255];
            VFormat(formattedmsg, sizeof(formattedmsg), msg, 3);

            StrCat(message, sizeof(message), formattedmsg)

            LogToFileEx(logFilePath, message);
        }
        case 3: // Both
        {
            new String:formattedmsg[255];
            VFormat(formattedmsg, sizeof(formattedmsg), msg, 2);

            new String:chatmsg[MAX_NAME_LENGTH + 255];
            Format(chatmsg, sizeof(chatmsg), "\x03[JBTP]\x01 ");

            StrCat(chatmsg, sizeof(chatmsg), formattedmsg);

            PrintToChatAll(chatmsg);

            new String:logmsg[MAX_NAME_LENGTH + 255];
            Format(logmsg, sizeof(logmsg), "[JBTP] ");

            StrCat(logmsg, sizeof(logmsg), formattedmsg);

            LogToFileEx(logFilePath, logmsg);
        }
    }

} 