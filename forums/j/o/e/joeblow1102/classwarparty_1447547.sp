//#define DEBUG

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

new red_class;
new red_captain;
new String:red_captain_name[MAX_NAME_LENGTH];
new bool:red_skip;

new blu_class;
new blu_captain;
new String:blu_captain_name[MAX_NAME_LENGTH];
new bool:blu_skip;

new bool:waitingForPlayers;
new bool:setupRound;

new Handle:voteMenu;
new Handle:hudCountdownTimer;
new Handle:startCWPTimer;

new gameState;
new String:currentMap[64];

new l_Team;

new countdownSeconds;

#define GAME_STATE_DISABLED 0
#define GAME_STATE_CAPTAIN 1
#define GAME_STATE_PLAYING 2
#define GAME_STATE_WAIT_FOR_PLAYERS 3

#define CWP_VERSION_STRING "Class War Party 0.6.0"
#define CWP_VERSION "0.6.0"

#define CAPTAIN_STATE_TIME 30

new String:CLASS_STRINGS[10][10] = {"Random", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};
new CLASS_ORDER[10] = {1, 3, 7, 4, 6, 9, 5, 2, 8, 0};
new red_votes[10];
new blu_votes[10];

public Plugin:myinfo =
{
    name = "Class War Party",
    author = "Justin Moy",
    description = "Single class vs. single class battles determined by a random player on each team",
    version = CWP_VERSION,
    url = "http://justinmoy.com"
};

public OnPluginStart()
{
    RegAdminCmd("cwp_enable", cwp_enable, ADMFLAG_GENERIC, "Enable Class War Party");
    RegAdminCmd("cwp_disable", cwp_disable, ADMFLAG_GENERIC, "Disable Class War Party");
    RegAdminCmd("cwp_state", cwp_state, ADMFLAG_GENERIC, "Checks Class War Party state");
    
    HookEvent("teamplay_round_active", Event_TeamplayRoundActive, EventHookMode_Post);
    HookEvent("arena_round_start", Event_ArenaRoundStart, EventHookMode_Post);
    
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    gameState = GAME_STATE_DISABLED;
    waitingForPlayers = false;
    determineSetupRound();
    
    voteMenu = CreateMenu(classMenuHandler);
    SetMenuTitle(voteMenu, "Vote on your team's class");
    for (new i = 0; i < 10; i++)
    {
        AddMenuItem(voteMenu, CLASS_STRINGS[CLASS_ORDER[i]], CLASS_STRINGS[CLASS_ORDER[i]]);
    }
    SetMenuExitButton(voteMenu, false);
    
    hudCountdownTimer = CreateHudSynchronizer();
}

/* Administration and console commands */
public Action:cwp_enable(client, args)
{
    if (gameState != GAME_STATE_DISABLED)
    {
        ReplyToCommand(client, "Class War Party: already enabled");
        return Plugin_Handled;
    }

    PrintToChatAll("Class War Party enabled");
    ReplyToCommand(client, "Class War Party: enabled");

    gameState = GAME_STATE_CAPTAIN;
    ServerCommand("mp_restartgame 1");
    return Plugin_Handled;
}

public Action:cwp_disable(client, args)
{
    if (gameState == GAME_STATE_DISABLED)
    {
        ReplyToCommand(client, "Class War Party: already disabled");
        return Plugin_Handled;
    }

    PrintToChatAll("Class War Party cancelled");
    ReplyToCommand(client, "Class War Party: cancelled");

    gameState = GAME_STATE_DISABLED;
    countdownSeconds = 0;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        changeMoveType(i, MOVETYPE_WALK);
    }
    return Plugin_Handled;
}

public Action:cwp_state(client, args)
{
    switch (gameState)
    {
        case GAME_STATE_DISABLED:
            ReplyToCommand(client, "Class War Party state: GAME_STATE_DISABLED");
        case GAME_STATE_CAPTAIN:
            ReplyToCommand(client, "Class War Party state: GAME_STATE_CAPTAIN");
        case GAME_STATE_PLAYING:
            ReplyToCommand(client, "Class War Party state: GAME_STATE_PLAYING");
        case GAME_STATE_WAIT_FOR_PLAYERS:
            ReplyToCommand(client, "Class War Party state: GAME_STATE_WAIT_FOR_PLAYERS");
    }
    
    return Plugin_Handled;
}

/* Map start and initialization */
public OnMapStart()
{
    waitingForPlayers = true;
    determineSetupRound();

    if (gameState != GAME_STATE_DISABLED)
        gameState = GAME_STATE_CAPTAIN;
}

determineSetupRound()
{
    setupRound = false;
    GetCurrentMap(currentMap, 64);
    
    if (!strncmp(currentMap, "cp_", 3))
    {
        new bool:allRed = true;
        new iEnt = -1;
        while ((iEnt = FindEntityByClassname(iEnt, "team_control_point")) != -1)
        {
            // check if all control points are red
            if (GetEntProp(iEnt, Prop_Send, "m_iTeamNum") != 2)
            {
                allRed = false;
            }
        }
        
        setupRound = allRed;
    }
    else if (!strncmp(currentMap, "pl_", 3))
    {
        setupRound = true;
    }
    
    #if defined DEBUG
        PrintToServer("[CWP_DEBUG] Determining setup round of %s to be %i", currentMap, setupRound);
    #endif

    startCWPTimer = INVALID_HANDLE;
}

/* Round start handlers and execution function */
public Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    waitingForPlayers = false;
    
    if (gameState != GAME_STATE_DISABLED)
    {    
        #if defined DEBUG
            PrintToServer("[CWP_DEBUG] Inside function ArenaRoundStart");
        #endif

        gameState = GAME_STATE_CAPTAIN;
        roundActive();
    }    
}

public Event_TeamplayRoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (waitingForPlayers)
    {
        waitingForPlayers = false;
        return;
    }    

    if (gameState != GAME_STATE_DISABLED)
    {  
        #if defined DEBUG
            PrintToServer("[CWP_DEBUG] Inside function EventTeamplayRoundActive");
        #endif

        gameState = GAME_STATE_CAPTAIN;
        roundActive();
    }    
}

roundActive()
{
    if (gameState == GAME_STATE_CAPTAIN)
    {
        
        #if defined DEBUG
            PrintToServer("[CWP_DEBUG] Inside function roundActive");
        #endif

        // choosing captains could change the game state
        // if there aren't enough players on either team
        chooseCaptains();
    }    
    
    if (gameState == GAME_STATE_CAPTAIN)
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            changeMoveType(i, MOVETYPE_NONE);
        }

        countdownSeconds = CAPTAIN_STATE_TIME;
        
        blu_class = 0;
        red_class = 0;
        
        blu_skip = false;
        red_skip = false;

        for (new i = 0; i < 10; i++)
        {
            blu_votes[i] = 0;
            red_votes[i] = 0;
        }

        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                l_Team = GetClientTeam(i);
                if ((TFTeam:l_Team == TFTeam_Blue && i == blu_captain) ||
                    (TFTeam:l_Team == TFTeam_Red && i == red_captain))
                {
                    displayCaptainPanel(i);
                }
                else {
                    displayNotCaptainPanel(i, l_Team);
                }
            }
        }
        
        if (setupRound)
            addTime(CAPTAIN_STATE_TIME);
        
        if (startCWPTimer == INVALID_HANDLE)
            startCWPTimer = CreateTimer(1.0, startCWP, _, TIMER_REPEAT);
    }
}

/* Player management and properties */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid"),
        client = GetClientOfUserId(userid);

    switch (gameState)
    {
        case GAME_STATE_DISABLED:
            changeMoveType(client, MOVETYPE_WALK);
        case GAME_STATE_CAPTAIN:
            changeMoveType(client, MOVETYPE_NONE);
        case GAME_STATE_PLAYING:
        {
            changeMoveType(client, MOVETYPE_WALK);
            enforceClass(client);
        }
    }
}

changeMoveType(client, MoveType:moveType)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && GetEntityMoveType(client) != moveType)
        SetEntityMoveType(client, moveType);      
}

// given a particular user, make sure they are the correct class
enforceClass(client)
{
    if (client >= 1 && IsClientInGame(client) && IsPlayerAlive(client))
    {
        new class = int:TF2_GetPlayerClass(client);
        l_Team = GetClientTeam(client);

        new expected_class;
        if (TFTeam:l_Team == TFTeam_Blue)
            expected_class = blu_class;
        else if (TFTeam:l_Team == TFTeam_Red)
            expected_class = red_class;

        if (expected_class < 1 || expected_class > 9)
            return;

        if (class != expected_class)
        {
            PrintToChat(client, "Class changed to match team");
            TF2_SetPlayerClass(client, TFClassType:expected_class);
            TF2_RespawnPlayer(client);
        }
    }    
}

/* Menu creators and handlers, Panel creators and handlers */
public captainPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        switch (param2)
        {
            case 1:
                DisplayMenu(voteMenu, param1, countdownSeconds);
            case 2: 
            {
                l_Team = GetClientTeam(param1);
                if (TFTeam:l_Team == TFTeam_Blue && param1 == blu_captain)
                {
                    blu_skip = true;
                }
                else if (TFTeam:l_Team == TFTeam_Red && param1 == red_captain)
                {
                    red_skip = true;
                }
            }
        } 
    }    
}

public classMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        l_Team = GetClientTeam(param1);

        #if defined DEBUG
            PrintToServer("Player %i on team %i voted %i", param1, l_Team, param2);
        #endif

        if (TFTeam:l_Team == TFTeam_Blue)
        {
            if (param1 == blu_captain)
            {
                blu_class = CLASS_ORDER[param2];
                PrintToChatAll("Blu captain is ready");
            }
            else
            {
                blu_votes[param2]++;
            }
        }
        else if (TFTeam:l_Team == TFTeam_Red)
        {
            if (param1 == red_captain)
            {
                red_class = CLASS_ORDER[param2];
                PrintToChatAll("Red captain is ready");
            }
            else
            {
                red_votes[param2]++;
            }
        }
    }    
}

addPanelHeader(Handle:panel)
{
    SetPanelTitle(panel, CWP_VERSION_STRING);
    DrawPanelText(panel, "by Justin Moy (justinmoy.com)");
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER | ITEMDRAW_RAWLINE);
}

displayCaptainPanel(client)
{
    new Handle:panel = CreatePanel();
    addPanelHeader(panel);
    
    DrawPanelText(panel, "You are your team's captain. You hold great responsibility.");
    DrawPanelText(panel, "When the round begins, your team will spawn as the class you select");
    
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER | ITEMDRAW_RAWLINE);
    DrawPanelText(panel, "Nobody wants to see another Heavy vs. Heavy class war party");
    
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER | ITEMDRAW_RAWLINE);
    DrawPanelItem(panel, "Ready to choose");
    DrawPanelItem(panel, "I'm not worthy");
    
    SendPanelToClient(panel, client, captainPanelHandler, countdownSeconds);
    CloseHandle(panel);
}

displayNotCaptainPanel(client, team)
{
    new Handle:panel = CreatePanel();
    addPanelHeader(panel);
    
    decl String:msg[MAX_NAME_LENGTH + 30];
    
    if (TFTeam:team == TFTeam_Blue)
    {
        Format(msg, sizeof(msg), "%s is your team captain.", blu_captain_name);
    }
    else if (TFTeam:team == TFTeam_Red)
    {
        Format(msg, sizeof(msg), "%s is your team captain.", red_captain_name);
    }
    else {
        return;
    }
    
    DrawPanelText(panel, msg);
    DrawPanelText(panel, "When the round starts, you will spawn as the class they select.");
    DrawPanelText(panel, "If they aren't up to the task, you can vote for your team's class.");
    
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER | ITEMDRAW_RAWLINE);
    DrawPanelText(panel, "Nobody wants to see another Heavy vs. Heavy class war party");
    
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER | ITEMDRAW_RAWLINE);
    DrawPanelItem(panel, "Ready to vote");
    DrawPanelItem(panel, "My vote is no good here");
    
    SendPanelToClient(panel, client, captainPanelHandler, countdownSeconds);
    CloseHandle(panel);
}

/* Handle the countdown HUD, handle the captain vote, and each team's class selection */
public Action:startCWP(Handle:timer)
{
    #if defined DEBUG
        PrintToServer("[CWP_DEBUG] Inside function startCWP");
    #endif

    if ((red_class != 0 || red_skip) && (blu_class != 0 || blu_skip))
    {
        if (gameState == GAME_STATE_CAPTAIN && setupRound)
            setTime(55);
        countdownSeconds = 0;
    }

    if (countdownSeconds > 0)
    {
        switch(countdownSeconds)
        {
            case 1:
                EmitSoundToAll("vo/announcer_begins_1sec.wav");
            case 2:
                EmitSoundToAll("vo/announcer_begins_2sec.wav");
            case 3:
                EmitSoundToAll("vo/announcer_begins_3sec.wav");
            case 4:
                EmitSoundToAll("vo/announcer_begins_4sec.wav");
            case 5:
                EmitSoundToAll("vo/announcer_begins_5sec.wav");
        }
        SetHudTextParams(-1.0, 0.10, 1.0, 255, 0, 0, 255);
        decl String:msg[50];
        Format(msg, sizeof(msg), "Class selection time remaining: %i seconds", countdownSeconds);
        
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                ShowSyncHudText(i, hudCountdownTimer, msg);
            }
        }
        countdownSeconds--;
        return Plugin_Continue;
    }
    
    startCWPTimer = INVALID_HANDLE;

    for (new i = 1; i <= MaxClients; i++)
    {
        changeMoveType(i, MOVETYPE_WALK);
    }
    
    if (gameState == GAME_STATE_DISABLED)
        return Plugin_Stop;

    EmitSoundToAll("vo/announcer_am_roundstart03.wav");
    new red_vote_amount = 0;
    new blu_vote_amount = 0;
    
    new red_same = 0;
    new blu_same = 0;
    
    new String:red_decision[25] = "selected by vote";
    new String:blu_decision[25] = "selected by vote";
    
    if (red_class != 0)
    {
        red_vote_amount = MaxClients;
        red_decision = "selected by captain";
    }

    if (blu_class != 0)
    {
        blu_vote_amount = MaxClients;
        blu_decision = "selected by captain";
    }

    // Hopefully, I remembered the unknown-length string, choose a random character problem
    // If so, I deserved whatever grade I received in my Algorithms class
    // If not, I definitely deserved whatever grade I received in my Algorithms class
    for (new i = 0; i < 10; i++)
    {
        new blu_vote_count = blu_votes[i];
        new red_vote_count = red_votes[i];

        #if defined DEBUG
            PrintToServer("[CWP_DEBUG] %s vote: Blue - %i, Red - %i", CLASS_STRINGS[CLASS_ORDER[i]], blu_vote_count, red_vote_count);
        #endif
        
        if (blu_vote_count > blu_vote_amount)
        {
            blu_class = CLASS_ORDER[i];
            blu_vote_amount = blu_vote_count;
            blu_same = 1;
        }
        else if (blu_vote_count == blu_vote_amount && blu_vote_amount != 0)
        {
            blu_same++;
            new randomInt = GetRandomInt(1, blu_same);
            if (randomInt == 1)
                blu_class = CLASS_ORDER[i];
        }
        
        if (red_vote_count > red_vote_amount)
        {
            red_class = CLASS_ORDER[i];
            red_vote_amount = red_vote_count;
            red_same = 1;
        }
        else if (red_vote_count == red_vote_amount && red_vote_amount != 0)
        {
            red_same++;
            new randomInt = GetRandomInt(1, red_same);
            if (randomInt == 1)
                red_class = CLASS_ORDER[i];
        }
    }
    
    if (blu_class == 0)
    {
        blu_class = GetRandomInt(1, 9);
    
        #if defined DEBUG
            PrintToServer("[CWP_DEBUG] Picking random class for blu: (%i)", blu_class);
        #endif
            
        blu_decision = "selected randomly";
    }
    if (red_class == 0)
    {
        red_class = GetRandomInt(1, 9);
        
        #if defined DEBUG
            PrintToServer("[CWP_DEBUG] Picking random class for red: (%i)", red_class);
        #endif
            
        red_decision = "selected randomly";
    }
        
    // let's try to eliminate any race conditions by putting this last
    gameState = GAME_STATE_PLAYING;

    decl String:red_msg[70];
    decl String:blu_msg[70];
    
    Format(red_msg, sizeof(red_msg), "Red class %s: %s", red_decision, CLASS_STRINGS[red_class]);
    Format(blu_msg, sizeof(blu_msg), "Blu class %s: %s", blu_decision, CLASS_STRINGS[blu_class]);
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            l_Team = GetClientTeam(i);
            if (TFTeam:l_Team == TFTeam_Blue)
            {
                PrintToChat(i, blu_msg);
            }
            else if (TFTeam:l_Team == TFTeam_Red)
            {
                PrintToChat(i, red_msg);
            }
            enforceClass(i);
        }
    }
    
    return Plugin_Stop;
}

chooseCaptains()
{
    #if defined DEBUG
        PrintToServer("[CWP_DEBUG] Inside function chooseCaptains");
    #endif

    new red_players = 0;
    new blu_players = 0;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            l_Team = GetClientTeam(i);
            if (TFTeam:l_Team == TFTeam_Blue)
            {
                blu_players++;
                new randomInt = GetRandomInt(1, blu_players);
                if (randomInt == 1)
                    blu_captain = i;
            }
            else if (TFTeam:l_Team == TFTeam_Red)
            {
                red_players++;
                new randomInt = GetRandomInt(1, red_players);
                if (randomInt == 1)
                    red_captain = i;
            }
        }
    }
    
    if (blu_players == 0 || red_players == 0)
    {
        gameState = GAME_STATE_WAIT_FOR_PLAYERS;
        return;
    }
    
    GetClientName(blu_captain, blu_captain_name, sizeof(blu_captain_name));
    GetClientName(red_captain, red_captain_name, sizeof(red_captain_name));
}

/* Functions te add time to the game clock and set the game clock's time
   Taken from AddTime by bl4nk (modified by belledesire, modified by joeblow1102 for use) */
addTime(time)
{
    #if defined DEBUG
        PrintToServer("[CWP_DEBUG] Adding %i seconds to game clock", time);
    #endif

    new bool:bEntityFound = false;

    new entityTimer = MaxClients+1;
    while((entityTimer = FindEntityByClassname(entityTimer, "team_round_timer")) != -1)
    {
        bEntityFound = true;

        if (!strncmp(currentMap, "pl_", 3))
        {
            decl String:buffer[32];
            Format(buffer, sizeof(buffer), "0 %i", time);

            SetVariantString(buffer);
            AcceptEntityInput(entityTimer, "AddTeamTime");
        }
        else
        {
            SetVariantInt(time);
            AcceptEntityInput(entityTimer, "AddTime");
        }
    }

    if (!bEntityFound)
    {
        new Handle:timelimit = FindConVar("mp_timelimit");
        SetConVarFloat(timelimit, GetConVarFloat(timelimit) + (time / 60.0));
        CloseHandle(timelimit);
    }
}

setTime(time)
{
    new bool:bEntityFound = false;
    new entityTimer = MaxClients+1;
    while((entityTimer = FindEntityByClassname(entityTimer, "team_round_timer")) != -1)
    {
        bEntityFound = true;

        SetVariantInt(time);
        AcceptEntityInput(entityTimer, "SetTime");
    }
    
    if (!bEntityFound)
    {
        new Handle:timelimit = FindConVar("mp_timelimit");
        SetConVarFloat(timelimit, time / 60.0);
        CloseHandle(timelimit);
    }
}