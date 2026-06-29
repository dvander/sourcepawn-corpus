#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdktools_functions>

#if defined MAXPLAYERS
    #undef MAXPLAYERS
    #define MAXPLAYERS 64
#endif

new Handle:hTVEnabled;
new Handle:RestartTimers = INVALID_HANDLE;
new Handle:hMaxPlayers;
#define MAX_PLAYERS_DEFAULT "10"
new OffsetAccount; // MONEY OFFSET
new bool:bPubChatMuted[MAXPLAYERS+1]=false;
new bool:bTeamChatMuted[MAXPLAYERS+1]=false;
new bool:bMuted[MAXPLAYERS+1][MAXPLAYERS+1];
new Float:fLastMessage[MAXPLAYERS+1];
new bool:bAuthed[MAXPLAYERS+1];
new Handle:hBotQuota = INVALID_HANDLE;

// Current match stuff
enum MatchState
{
    MS_Pre_Setup = 0,
    MS_Setup,
    MS_Before_First_Half, // This is only used if the map changes.
    MS_Live_First_Half,
    MS_Before_Second_Half, // Always used.
    MS_Live_Second_Half,
    MS_Before_Overtime_First_Half,
    MS_Live_Overtime_First_Half,
    MS_Before_Overtime_Second_Half,
    MS_Live_Overtime_Second_Half,
    MS_Post_Match,
};

new MatchState:gMatchState = MS_Pre_Setup;
new TeamAScore; // Team A goes CT first.
new TeamBScore; // Team B goes T first.
// Keep in mind team A and B are always randomized / captains.
// In the case of captains, it is still random which captains will be on which team, A or B.
new CurrentRound = 0;
new String:MatchMap[32] = ""; // Map name.
enum RuleType
{
    Rules_PUG = 0,
    Rules_CGS,
};
new RuleType:Ruleset = Rules_PUG;
#define ROUNDS_HALF_PUG 15
#define ROUNDS_HALF_CGS 11
#define ROUNDS_OVERTIME_HALF_PUG 5
#define ROUNDS_OVERTIME_HALF_CGS 1  
#define MAX_ROUNDS 50 // We won't exceed 50 rounds for now.
new Handle:hMatchDamage[MAX_ROUNDS]; // Vector of all the damage.
new Handle:hMatchKills[MAX_ROUNDS]; // Vector of all the kills.
new bool:CaptainMode = false;
new bool:BunnyHopMode = false;
#define MAX_MAPS 50 // For now.
new String:MapNames[MAX_MAPS][32]; // Loaded OnPluginStart()
#define TEAM_A 0
#define TEAM_B 1
#define TEAM_COUNT 2
#define TEAM_CAPTAIN 0
new String:TeamPlayers[TEAM_COUNT][5][24]; // Steam ID's. Cached before map change.
new bool:RoundCounterOn = false;

//Clients
new bool:bReady[MAXPLAYERS+1];
new String:clientUsername[MAXPLAYERS+1][24];
new readyUpTime[MAXPLAYERS+1];
new notReadyTime[MAXPLAYERS+1];
new bool:FirstSpawn[MAXPLAYERS+1] = true;
new bool:AutoDmg[MAXPLAYERS+1] = false;
new bool:bDisconnecting[MAXPLAYERS+1] = true;

OnAllReady()
{
/*
enum MatchState
{
    MS_Pre_Setup = 0,
    MS_Setup_Up,
    MS_Before_First_Half, // This is only used if the map changes.
    MS_Live_First_Half,
    MS_Before_Second_Half, // Always used.
    MS_Live_Second_Half,
    MS_Before_Overtime_First_Half,
    MS_Live_Overtime_First_Half,
    MS_Before_Overtime_Second_Half,
    MS_Live_Overtime_Second_Half,
    MS_Post_Match,
};
*/
    if(gMatchState == MS_Pre_Setup)
    {
        StartMatchSetup();
    }
    else if(gMatchState == MS_Before_First_Half)
    {
        StartFirstHalf();
    }
    else if(gMatchState == MS_Before_Second_Half)
    {
        StartSecondHalf();
    }
    else if(gMatchState == MS_Before_Overtime_First_Half)
    {
        StartOTFirstHalf();
    }
    else if(gMatchState == MS_Before_Overtime_Second_Half)
    {
        StartOTSecondHalf();
    }
}

PartialNameClient(const String:matchText[])
{
    new Client = 0;
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(ValidClient(x) && !IsSourceTV(x))
        {
            new String:clName[32];
            GetClientName(x, clName, 32);
            if(StrContains(clName, matchText, false)>=0)
            {
                if(Client!=0)
                {
                    return -1; // -1 == multiple
                }
                else
                {
                    Client = x;
                }
            }
        }
    }
    return Client;
}

CSLTeam(client)
{
    if(!ValidClient(client) || IsSourceTV(client))
    {
        return -1;
    }
    new String:steamID[24];
    GetClientAuthString(client, steamID, 24);
    return CSLTeamOfSteam(steamID);
}

CSLTeamOfSteam(const String:steamID[])
{
    for(new x=0;x<5;x++)
    {
        if(StrEqual(steamID, TeamPlayers[TEAM_A][x]))
        {
            return TEAM_A;
        }        
    }
    for(new x=0;x<5;x++)
    {
        if(StrEqual(steamID, TeamPlayers[TEAM_B][x]))
        {
            return TEAM_B;
        }        
    }
    return -1;
}

bool:AllowBots()
{
    return false; // Temp.
}

ClientDefaults(client)
{
    fLastMessage[client] = 0.0;
    AutoDmg[client] = false;
    FirstSpawn[client] = true;
    if(ValidClient(client)) {
        GetClientName(client, clientUsername[client], 24);
    }
    bAuthed[client] = false;
    bReady[client] = false;
    readyUpTime[client] = 0;
    notReadyTime[client] = 0;
    bDisconnecting[client] = true;
    bPubChatMuted[client] = false;
    bTeamChatMuted[client] = false;
    for(new x=0;x<=MAXPLAYERS;x++)
    {
        bMuted[client][x] = false;
    }
}

Kick(client, String:format[], any:...)
{
    if(!ValidClient(client))
    {
        return;
    }
    new String:reason[256];
    VFormat(reason, sizeof(reason), format, 3);
    if(StrEqual(reason,""))
    {
        KickClient(client);
    }
    else
    {
        KickClient(client,"%s",reason);
    }
    PrintToServer("KICK (%d): %s",client,reason);
}

bool:ReadyUpState()
{
    if(gMatchState==MS_Pre_Setup || gMatchState==MS_Before_First_Half || gMatchState==MS_Before_Second_Half
    || gMatchState==MS_Before_Overtime_First_Half || gMatchState==MS_Before_Overtime_Second_Half)
    {
        return true;
    }
    return false;
}

ChangeCvar(const String:cvarName[], const String:newValue[])
{
    new Handle:hVar = FindConVar(cvarName);
    new oldFlags = GetConVarFlags(hVar);
    new newFlags = oldFlags;
    newFlags &= ~FCVAR_NOTIFY;
    SetConVarFlags(hVar, newFlags);
    SetConVarString(hVar, newValue);
    SetConVarFlags(hVar, oldFlags);
}

EnterReadyUpState()
{
    // Just a hack for freeze time.
    ChangeCvar("mp_freezetime", "3");
    ChangeCvar("mp_buytime", "999");
    ChangeCvar("mp_forcecamera", "0");
    for(new x=0;x<=MAXPLAYERS;x++)
    {
        notReadyTime[x] = GetTime();
        bReady[x] = false;
    }
}

public Action:WarmUpSpawner(Handle:timer)
{
    if(ReadyUpState())
    {
        DeleteBomb();
        for(new x=1;x<=MAXPLAYERS;x++)
        {
            if(ValidClient(x) && !IsSourceTV(x) && GetClientTeam(x)>=CS_TEAM_T && !IsPlayerAlive(x))
            {
                // Is it warm up?
                if(ReadyUpState())
                {
                    CS_RespawnPlayer(x);
                }
            }
        }
    }
}

public Action:OneSecCheck(Handle:timer)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(ValidClient(x) && !IsFakeClient(x))
        {
            if(ReadyUpState())
            {
                if(bAuthed[x] && !bReady[x] && notReadyTime[x] + 120 <= GetTime())
                {
                    Kick(x, "You must ready up within 2 minutes");
                    continue;
                }            
                new Handle:hBuffer = StartMessageOne("KeyHintText", x);
                new String:tmptext[256];
                Format(tmptext, 256, "READY: ");
                new String:optComma[32] = "";
                for(new y=1;y<=MAXPLAYERS;y++)
                {
                    if(ValidClient(y) && !IsSourceTV(y))
                    {
                        if(bReady[y])
                        {
                            new String:plName[32];
                            new String:plNameTrun[24];
                            GetClientName(y, plName, 32);
                            if(strlen(plName)>7)
                            {
                                for(new z=0;z<4;z++)
                                {
                                    plNameTrun[z] = plName[z];
                                }
                                plNameTrun[4] = '.';
                                plNameTrun[5] = '.';
                                plNameTrun[6] = '.';
                            }
                            else
                            {
                                Format(plNameTrun, 20, "%s", plName);
                            }
                            Format(tmptext, 256, "%s%s%s", tmptext, optComma, plNameTrun);
                            Format(optComma, 32, ", ");
                        }
                    }
                }
                
                BfWriteByte(hBuffer, 1); 
                BfWriteString(hBuffer, tmptext); 
                EndMessage();
            }
        }
    }
    return Plugin_Continue;
}

// This function checks if a STEAMID is valid.
// AS VALVE UPDATES THEIR STANDARDS CHANGE THIS
bool:BadSteamId(const String:steamID[])
{
    if(!AllowBots() && StrEqual(steamID,"BOT"))
        return true;
        
    return false; // It's good.
}

bool:ValidClient(client,bool:check_alive=false)
{
    if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
    {
        if(check_alive && !IsPlayerAlive(client))
        {
            return false;
        }
        return true;
    }
    return false;
}

public Action:MapDelayed(Handle:timer)
{
    ChangeMatchState(MS_Before_First_Half);
    new String:curmap[32];
    GetCurrentMap(curmap, 32);
    if(!StrEqual(curmap, MatchMap))
    {
        ForceChangeLevel(MatchMap, "Setting up match");
    }
}

TeamSize(teamCSL)
{
    new i = 0;
    for(new x=0;x<5;x++)
    {
        if(!StrEqual(TeamPlayers[teamCSL][x],""))
        {
            i++;
        }
    }
    return i;
}

TeamSizeActive(teamCSL)
{
    new i = 0;
    for(new x=0;x<5;x++)
    {
        if(!StrEqual(TeamPlayers[teamCSL][x],""))
        {
            new cAtX = ClientOfSteamId(TeamPlayers[teamCSL][x]);
            if(ValidClient(cAtX))
            {
                i++;
            }
        }
    }
    return i;
}

AddSteamToTeam(const String:steamID[], teamNum)
{
    // If the team is full, look for a disconnect. They are going to be replaced and will probably be penelized.
    new TeamCount = TeamSize(teamNum);
    if(TeamCount<5)
    {
        for(new x=0;x<5;x++)
        {
            if(StrEqual(TeamPlayers[teamNum][x],""))
            {
                Format(TeamPlayers[teamNum][x], 24, "%s", steamID);
                return;
            }
        }
    }
    else
    {
        // Sorry, whoever left is bound to cry if they were trying to come back :(
        for(new x=0;x<5;x++)
        {
            new ClientAt = ClientOfSteamId(TeamPlayers[teamNum][x]);
            if(!ValidClient(ClientAt))
            {
                Format(TeamPlayers[teamNum][x], 24, "%s", steamID);
                return;
            }
        }
    }    
}

StartFirstHalf()
{
    // Record.
    // Map.
    ServerCommand("tv_record %d_%s\n", GetTime(), MatchMap);
    if(!CaptainMode)
    {
        // Go through each person (random order), if they aren't on a team assign them to the team lacking players, or random.
        new bool:ClientIterated[MAXPLAYERS+1] = false;
        for(new i=1;i<=MAXPLAYERS;i++)
        {
            new RandClient = GetRandomInt(1,MAXPLAYERS);
            while(ClientIterated[RandClient])
            {
                RandClient = GetRandomInt(1,MAXPLAYERS);
            }
            ClientIterated[RandClient] = true;
            if(!ValidClient(RandClient) || IsSourceTV(RandClient))
            {
                continue;
            }
            new String:steamID[24];
            GetClientAuthString(RandClient, steamID, 24);
            if(CSLTeam(RandClient)!=-1)
            {
                continue; // Already on a team, on a group likely.
            }
            // Now put them on a team.
            new TeamACount = TeamSizeActive(TEAM_A);
            new TeamBCount = TeamSizeActive(TEAM_B);
            if(TeamACount < TeamBCount)
            {
                AddSteamToTeam(steamID, TEAM_A);
            }
            else if(TeamBCount < TeamACount)
            {
                AddSteamToTeam(steamID, TEAM_B);
            }
            else
            {
                new RandTeam = GetRandomInt(TEAM_A, TEAM_B);
                AddSteamToTeam(steamID, RandTeam);
            }
        }
    }
    /*
    else
    {
        Later
    }    
    */
    // Clear scores just incase.
    TeamAScore = 0;
    TeamBScore = 0;
    // Team A goes T first
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(ValidClient(x) && !IsSourceTV(x))
        {
            new Team = CSLTeam(x);
            if(Team==TEAM_A)
            {
                CS_SwitchTeam(x, CS_TEAM_T);
            }
            else if(Team==TEAM_B)
            {
                CS_SwitchTeam(x, CS_TEAM_CT);
            }
            else
            {
                Kick(x, "Sorry, you aren't supposed to be here");
            }
        }        
    }

    ChangeMatchState(MS_Live_First_Half);
    
    PrintToChatAll("[PUG] Starting the first half...");
    EnforceMatchCvars();
    ServerCommand("mp_restartgame 1\n");
    RestartTimers = CreateTimer(2.0, RestartSecondTime);
}

public Action:RestartSecondTime(Handle:timer)
{
    ServerCommand("mp_restartgame 5\n");
    RestartTimers = CreateTimer(6.0, RestartThirdTime)
}

public Action:RestartThirdTime(Handle:timer)
{
    ServerCommand("mp_restartgame 5\n");
    PrintToChatAll("[PUG] Next round is live.");
    RestartTimers = CreateTimer(4.5, LiveMessageTimer);
}

public Action:LiveMessageTimer(Handle:timer)
{
    RestartTimers = INVALID_HANDLE;
    PrintCenterTextAll("MATCH IS LIVE!");
    RoundCounterOn = true;
    PrintToChatAll("[PUG] Match is live!");
}

bool:TeamsSetup()
{
    if(gMatchState>=MS_Live_First_Half && gMatchState<MS_Post_Match)
    {
        return true;
    }
    return false;
}

EnforceMatchCvars(bool:ot = false)
{
    ChangeCvar("mp_freezetime", "8");
    ChangeCvar("mp_forcecamera", "1");
    ChangeCvar("mp_buytime", "15");
    if(BunnyHopMode)
    {
        ChangeCvar("sv_enablebunnyhopping", "1");
    }
    else
    {
        ChangeCvar("sv_enablebunnyhopping", "0");
    }
    if(Ruleset==Rules_PUG)
    {
        ChangeCvar("mp_roundtime", "1.75");
    }
    else if(Ruleset==Rules_CGS)
    {
        ChangeCvar("mp_roundtime", "1.50");
    }
    if(ot)
    {
        if(Ruleset==Rules_PUG)
        {
            ChangeCvar("mp_startmoney", "8000");
        }
        else if(Ruleset==Rules_CGS)
        {
            ChangeCvar("mp_startmoney", "16000");
        }
    }
    else
    {
        if(Ruleset==Rules_PUG)
        {
            ChangeCvar("mp_startmoney", "800");
        }
        else if(Ruleset==Rules_CGS)
        {
            ChangeCvar("mp_startmoney", "8000");
        }
    }
}

StartSecondHalf()
{
    ChangeMatchState(MS_Live_Second_Half);
    EnforceMatchCvars();
    PrintToChatAll("[PUG] Starting the second half...");
    ServerCommand("mp_restartgame 1\n");
    RestartTimers = CreateTimer(2.0, RestartSecondTime);
}

StartOTFirstHalf()
{
    ChangeMatchState(MS_Live_Overtime_First_Half);

    PrintToChatAll("[PUG] Starting the first half of overtime...");
    EnforceMatchCvars(true);
    ServerCommand("mp_restartgame 1\n");
    RestartTimers = CreateTimer(2.0, RestartSecondTime);
}

StartOTSecondHalf()
{
    ChangeMatchState(MS_Live_Overtime_Second_Half);

    PrintToChatAll("[PUG] Starting the second half of overtime...");
    EnforceMatchCvars(true);
    ServerCommand("mp_restartgame 1\n");
    RestartTimers = CreateTimer(2.0, RestartSecondTime);
}

// BUG: Votes dont continue if failed.
TryStartMatch()
{
    // Are we on the correct map?
    new String:curmap[32];
    GetCurrentMap(curmap, 32);
    if(!StrEqual(curmap, MatchMap))
    {
        PrintToChatAll("[PUG] Map is changing in 5 seconds, brace yourselves.");
        CreateTimer(5.0, MapDelayed);
    }
    else
    {
        StartFirstHalf();
    }                                                                                                   
}

RulesCSL()
{
    PrintToChatAll("[PUG] Ruleset will be: PUG");
    Ruleset = Rules_PUG;
    TeamVote();
}

SetMatchMap(const String:mapname[])
{
    PrintToChatAll("[PUG] Map will be: %s", mapname);
    Format(MatchMap, 32, mapname);
    TryStartMatch();
}

public Handle_MapVote(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    } else if (action == MenuAction_VoteEnd) {
        new String:map[32];
        GetMenuItem(menu, param1, map, sizeof(map));
        if(StrEqual(map,"Random"))
        {
            SetMatchMap(MapNames[GetRandomInt(0, GetMapCount()-1)]);        
        }
        else
        {
            SetMatchMap(map);
        }
    }
    else if(action==MenuAction_VoteCancel)
    {
        // Choose a random map.
        SetMatchMap(MapNames[GetRandomInt(0, GetMapCount()-1)]);
    }
}

StartMapVote()
{
    // Choose a rule set.
    if (IsVoteInProgress())
    {
        CancelVote();
    }
 
    new Handle:menu = CreateMenu(Handle_MapVote);
    SetMenuTitle(menu, "Vote for the map");
    // Random order.
    new bool:bShowed[MAX_MAPS];
    for(new x=0;x<GetMapCount();x++)
    {        
        new Rand = GetRandomInt(0, GetMapCount()-1);
        while(bShowed[Rand])
        {
            Rand = GetRandomInt(0, GetMapCount()-1);
        } 
        bShowed[Rand] = true;
        AddMenuItem(menu, MapNames[Rand], MapNames[Rand]);
    }
    SetMenuExitButton(menu, false);
    VoteMenuToAll(menu, 15);
}

BHopOn()
{
    PrintToChatAll("[PUG] Bunnyhopping will be enabled.");
    BunnyHopMode = true;
    StartMapVote();
}

BHopOff()
{
    PrintToChatAll("[PUG] Bunnyhopping will be disabled.");
    BunnyHopMode = false;
    StartMapVote();
}

public Handle_BHopVote(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    } else if (action == MenuAction_VoteEnd) {
        // 0 = Off
        // 1 = On
        if(param1 == 0)
        {
            BHopOff();
        }
        else
        {
            BHopOn();
        }
    }
    else if(action==MenuAction_VoteCancel)
    {
        BHopOff();
    }
}

BHopVote()
{
    if(IsVoteInProgress())
    {
        CancelVote();
    }
 
    new Handle:menu = CreateMenu(Handle_BHopVote);
    SetMenuTitle(menu, "Vote for bunny hopping");
    AddMenuItem(menu, "off", "Off");
    AddMenuItem(menu, "on", "On");
    SetMenuExitButton(menu, false);
    VoteMenuToAll(menu, 15);
}

TeamsRandom()
{
     CaptainMode = false;
     BHopVote();
}

/*public Handle_TeamVote(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    } else if (action == MenuAction_VoteEnd) {
        // 0 = Random
        // 1 = Captains
        if(param1 == 0)
        {
            TeamsRandom();
        }
        else
        {
            TeamsCaptains();
        }
    }
}*/

TeamVote()
{
    // For now random teams.
    TeamsRandom();
    /*// Choose a team set.
    if (IsVoteInProgress())
    {
        CancelVote();
    }
 
    new Handle:menu = CreateMenu(Handle_TeamVote);
    SetMenuTitle(menu, "Vote for team sorting");
    AddMenuItem(menu, "rand", "Random");
    AddMenuItem(menu, "capt", "Captains");
    SetMenuExitButton(menu, false);
    VoteMenuToAll(menu, 15);*/
}

RulesCGS()
{
    PrintToChatAll("[PUG] Ruleset will be: CGS");
    Ruleset = Rules_CGS;
    TeamVote();
}

public Handle_RulesVote(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    } else if (action == MenuAction_VoteEnd) {
        // 0 = CSL
        // 1 = Pug
        if(param1 == 0)
        {
            RulesCSL();
        }
        else
        {
            RulesCGS();
        }
    }
    else if(action==MenuAction_VoteCancel)
    {
        RulesCSL();
    }
}

StartRulesVote()
{
    // Choose a rule set.
    if (IsVoteInProgress())
    {
        CancelVote();
    }
 
    new Handle:menu = CreateMenu(Handle_RulesVote);
    SetMenuTitle(menu, "Vote for rule set");
    AddMenuItem(menu, "csl", "CSL (15 Round Halves, $800)");
    AddMenuItem(menu, "cgs", "CGS (9 Round Halves, $8000)");
    SetMenuExitButton(menu, false);
    VoteMenuToAll(menu, 15);
}

ChangeMatchState(MatchState:newState)
{
    gMatchState = newState;
    
    if(ReadyUpState())
    {
        EnterReadyUpState();
    }
}

StartMatchSetup()
{
    // Vote for rule set.
    PrintToChatAll("[PUG] Starting match setup and votes.");
    ChangeMatchState(MS_Setup);
    StartRulesVote();
}

public Action:SayTeamHook(client,args)
{
    return SayHook(client, args, true);
}

public Action:SayPubHook(client,args)
{
    return SayHook(client, args, false);
}

ReadyUp(client) {
    new String:plName[32];
    GetClientName(client, plName, 32);
    bReady[client] = true;
    readyUpTime[client] = GetTime();
    PrintToChatAll("[PUG] %s is now ready.", plName);
    // If this is the last ready up.
    new bool:bStillMore = false;
    new PlCount = 0;
    for(new a=1;a<=MAXPLAYERS;a++)
    {
        if(ValidClient(a) && !IsSourceTV(a))
        {
            PlCount++;
            if(!bReady[a])
            {
                bStillMore = true;
            }
        }
    }
    if(!bStillMore)
    {
        if(PlCount == GetConVarInt(hMaxPlayers))
        {
            OnAllReady();
        }
        else
        {
            new NeedPl = GetConVarInt(hMaxPlayers) - PlCount;
            PrintToChatAll("[PUG] Still waiting on %d players...", NeedPl);
        }
    }
}

public Action:SayHook(client,args,bool:team)
{
    if(!client)
        return Plugin_Continue; // Don't block the server ever.
    
    decl String:ChatText[256];
    GetCmdArgString(ChatText,256);
    StripQuotes(ChatText);
    new String:Words[100][256];
    new WordCount = ExplodeString(ChatText, " ", Words, 100, 256);
    new bool:bHookMessage = false;
    new bool:bCommand = true;

    if(StrEqual(Words[0],"/ready", false))
    {
        if(!ReadyUpState())
        {
            PrintToChat(client, "[PUG] You don't need to ready up right now.");
            bHookMessage = true; 
        }
        else
        {
            if(bReady[client])
            {
                PrintToChat(client,"[PUG] You are already ready.");
                bHookMessage = true;
            }
            else
            {
                ReadyUp(client);
            }
        }
    }
    else if(StrEqual(Words[0], "/mute", false))
    {
        bHookMessage = true;
        new String:fullSecond[256];
        Format(fullSecond, 256, "%s", Words[1]);
        for(new x=2;x<WordCount;x++)
        {
            Format(fullSecond, 256, "%s %s", fullSecond, Words[x]);
        }
        if(StrEqual(fullSecond,""))
        {
            PrintToChat(client, "[PUG] Syntax: /mute <part of name>");
        }
        else
        {
            new cl = PartialNameClient(fullSecond);
            if(cl==-1)
            {
                PrintToChat(client, "[PUG] Be more specific, multiple matches.");
            }
            else if(cl==0)
            {
                PrintToChat(client, "[PUG] No matches for \"%s\".", fullSecond);
            }
            else
            {
                if(client==cl)
                {
                    PrintToChat(client, "[PUG] You can't mute yourself.");
                }
                else if(IsPlayerMuted(client, cl))
                {
                    PrintToChat(client, "[PUG] Player already muted.");
                }
                else
                {
                    PrintToChat(client, "[PUG] Player muted.");
                    bMuted[client][cl] = true;
                }
            }
        }
    }
    else if(StrEqual(Words[0], "/unmute", false))
    {
        bHookMessage = true;
        new String:fullSecond[256];
        Format(fullSecond, 256, "%s", Words[1]);
        for(new x=2;x<WordCount;x++)
        {
            Format(fullSecond, 256, "%s %s", fullSecond, Words[x]);
        }
        if(StrEqual(fullSecond,""))
        {
            PrintToChat(client, "[PUG] Syntax: /unmute <part of name>");
        }
        else
        {
            new cl = PartialNameClient(fullSecond);
            if(cl==-1)
            {
                PrintToChat(client, "[PUG] Be more specific, multiple matches.");
            }
            else if(cl==0)
            {
                PrintToChat(client, "[PUG] No matches for \"%s\".", fullSecond);
            }
            else
            {
                if(client==cl)
                {
                    PrintToChat(client, "[PUG] You can't mute yourself.");
                }
                else if(!IsPlayerMuted(client, cl))
                {
                    PrintToChat(client, "[PUG] Player isn't muted.");
                }
                else
                {
                    PrintToChat(client, "[PUG] Player unmuted.");
                    bMuted[client][cl] = false;
                }
            }
        }        
    }
    else if(StrEqual(Words[0], "/chat", false))
    {
        bHookMessage = true;
        if(IsPubChatMuted(client))
        {
            bPubChatMuted[client] = false;
            PrintToChat(client, "[PUG] Public chat unmuted");
        }
        else
        {
            bPubChatMuted[client] = true;
            PrintToChat(client, "[PUG] Public chat muted.");
        }
    }
    else if(StrEqual(Words[0], "/teamchat", false))
    {
        bHookMessage = true;
        if(IsTeamChatMuted(client))
        {
            bTeamChatMuted[client] = false;
            PrintToChat(client, "[PUG] Team chat unmuted.");
        }
        else
        {
            bTeamChatMuted[client] = true;
            PrintToChat(client, "[PUG] Team chat muted.");
        }
    }
    else if(StrEqual(Words[0], "/notready", false))
    {
        if(!bReady[client])
        {
            PrintToChat(client, "[PUG] You already are not ready.");
            bHookMessage = true;
        }
        else
        {
            new curTime = GetTime();
            if(readyUpTime[client] + 15 > curTime)
            {
                PrintToChat(client, "[PUG] You must wait 15 seconds between ready commands.");
                bHookMessage = true;
            }
            else
            {
                bReady[client] = false;
                new String:plName[32];
                GetClientName(client, plName, 32);
                PrintToChatAll("[PUG] %s is no longer ready.", plName);
                notReadyTime[client] = GetTime();
            }
        }
    }
    else if(StrEqual(Words[0], "/autodmg",false))
    {
        if(AutoDmg[client])
        {
            AutoDmg[client] = false;
            PrintToChat(client, "[PUG] Auto /dmg has been toggled off.");
        }
        else
        {
            AutoDmg[client] = true;
            PrintToChat(client, "[PUG] Auto /dmg has been toggled on.");
        }
    }
    else if(StrEqual(Words[0], "/dmg", false))
    {
        if(!MatchLive())
        {
            PrintToChat(client, "[PUG] You can't use this now.");
            bHookMessage = true;
        }
        else
        {
            if(IsPlayerAlive(client))
            {
                PrintToChat(client, "[PUG] You must be dead to use this.");
                bHookMessage = true;
            }
            else
            {
                PrintDmgReport(client);
            }
        }
    }
    else if(StrEqual(Words[0], "/help", false))
    {
        PrintToChat(client, "[PUG] Commands: /ready, /help, /dmg, /autodmg");
        bHookMessage = true;
    }
    else
    {
        bCommand = false;
    }
    new bool:bCanChat = (fLastMessage[client] + 0.5 <= GetEngineTime());
    if(!bCommand && !bHookMessage && team && IsTeamChatMuted(client))
    {
        PrintToChat(client, "[PUG] You can't team chat until you re-enable it with /teamchat.");
        return Plugin_Handled;
    }
    if(!bCommand && !bHookMessage && !team && IsPubChatMuted(client))
    {
        PrintToChat(client, "[PUG] You can't public chat until you re-enable it with /chat.");
        return Plugin_Handled;
    }
    if(!bHookMessage && bCanChat)
    {
        fLastMessage[client] = GetEngineTime();
        ChatMsg(client, team, ChatText);
    }
    return Plugin_Handled;
}

public Action:RespawnCheck(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if(ReadyUpState() && ValidClient(client) && !IsSourceTV(client) && !IsPlayerAlive(client))
    {
        CS_RespawnPlayer(client);
    }    
}

LogKillLocalStats(const String:steamAttacker[], const String:steamVictim[], const String:weapon[], bool:headshot)
{
    if(!MatchLive())
    {
        return;
    }
    if(CurrentRound<1)
    {
        return;
    }
    // Create a new array.
    new Handle:newArray = CreateArray(24);
    PushArrayString(newArray, steamAttacker);
    PushArrayString(newArray, steamVictim);
    PushArrayString(newArray, weapon);
    PushArrayCell(newArray, headshot);
}

LogKill(attacker, victim, const String:weapon[], bool:headshot)
{
    if(MatchLive())
    {
        new String:steamAttacker[24];
        new String:steamVictim[24];
        GetClientAuthString(attacker, steamAttacker, 24);
        GetClientAuthString(victim, steamVictim, 24);
        LogKillLocalStats(steamAttacker, steamVictim, weapon, headshot);
    }
}

public Action:DeathCallback(Handle:event, const String:name[], bool:dontBroadcast)
{    
    new userid = GetEventInt(event, "userid");
    CreateTimer(2.0, RespawnCheck, userid);
    new client = GetClientOfUserId(userid);
    new attacker_userid = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attacker_userid);
    new String:weapon[64];
    GetEventString(event, "weapon", weapon, 64);
    new bool:Headshot = (GetEventInt(event, "headshot")==0)?false:true;
    if(ValidClient(client))
    {
        if(attacker==client || attacker==0)
        {
            LogKill(client, client, weapon, false);
        }
        else if(ValidClient(attacker))
        {
            LogKill(attacker, client, weapon, Headshot);
        }
    }
    
    if(MatchLive() && AutoDmg[client])
    {
        PrintDmgReport(client);
    }
    
    return Plugin_Continue;
}

public Action:RoundStartCallback(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(RoundCounterOn == true)
    {
        CurrentRound++;
        // Create an array here.
        hMatchDamage[CurrentRound] = CreateArray();
        hMatchKills[CurrentRound] = CreateArray();
        // Who is winning?
        if(TeamAScore>TeamBScore)
        {
            // Is team A ct or t?
            if(CSTeamToCSL(CS_TEAM_CT) == TEAM_A)
            {
                // They are CT's.
                PrintToChatAll("[PUG] Round %d. CT's winning %d - %d", CurrentRound, TeamAScore, TeamBScore);
            }
            else
            {
                PrintToChatAll("[PUG] Round %d. T's winning %d - %d", CurrentRound, TeamAScore, TeamBScore);
            }
        }
        else if(TeamBScore>TeamAScore)
        {
            if(CSTeamToCSL(CS_TEAM_CT) == TEAM_B)
            {
                // They are CT's.
                PrintToChatAll("[PUG] Round %d. CT's winning %d - %d", CurrentRound, TeamBScore, TeamAScore);
            }
            else
            {
                PrintToChatAll("[PUG] Round %d. T's winning %d - %d", CurrentRound, TeamBScore, TeamAScore);
            }
        }
        else
        {
            PrintToChatAll("[PUG] Round %d. Tie game, %d - %d", CurrentRound, TeamAScore, TeamBScore);
        }
    }
    return Plugin_Continue;
}

public Action:RoundEndCallback(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(ReadyUpState()) // sept 24, 2012 - this might fix the round end nonsense
    {
        return Plugin_Continue;
    }
    
    //new reason = GetEventInt(event, "reason");
    new winner = GetEventInt(event, "winner");
    if(RoundCounterOn == true)
    {
        if(winner==CS_TEAM_T)
        {
            new CSLT = CSTeamToCSL(CS_TEAM_T);
            if(CSLT == TEAM_A)
            {
                TeamAScore++;
            }
            else
            {
                TeamBScore++;
            }
        }
        else if(winner==CS_TEAM_CT)
        {
            new CSLCT = CSTeamToCSL(CS_TEAM_CT);
            if(CSLCT == TEAM_A)
            {
                TeamAScore++;
            }
            else
            {
                TeamBScore++;
            }
        }
        
        // Is this CSL or CGS rules?
        // Check score first, if there is a winner call WinLegit or whatever.
        // Are we in overtime?
        // Check for a winner, then check for transitioning stuff. If there is a winner, no need to go to Half, etc...
        if(gMatchState >= MS_Before_Overtime_First_Half && gMatchState!=MS_Post_Match)
        {
            // If CSL, overtime start score is 15-15
            // Otherwise, 9 - 9
            if(Ruleset==Rules_PUG)
            {
                if(TeamAScore >= 21)
                {
                    MatchWinOT(TEAM_A);
                    return Plugin_Continue;
                }
                else if(TeamBScore >= 21)
                {
                    MatchWinOT(TEAM_B);
                    return Plugin_Continue;
                }
                else if(TeamAScore == 20 && TeamBScore == 20)
                {
                    // Tie.
                    MatchTieOT();
                    return Plugin_Continue;
                }
            }
            else if(Ruleset==Rules_CGS)
            {
                if(TeamAScore >= 13)
                {
                    MatchWinOT(TEAM_A);
                    return Plugin_Continue;
                }
                else if(TeamBScore >= 13)
                {
                    MatchWinOT(TEAM_B);
                    return Plugin_Continue;
                }
                else if(TeamAScore == 12 && TeamBScore == 12)
                {
                    // Tie.
                    MatchTieOT();
                    return Plugin_Continue;
                }
            }
        }
        else if(gMatchState!=MS_Post_Match)
        {
            if(Ruleset==Rules_PUG)
            {
                // Check of score >=16.
                if(TeamAScore>=16)
                {
                    MatchWin(TEAM_A);
                }
                else if(TeamBScore>=16)
                {
                    MatchWin(TEAM_B);
                }
            }
            else if(Ruleset==Rules_CGS)
            {
                // Check of score >=10.
                if(TeamAScore>=10)
                {
                    MatchWin(TEAM_A);
                }
                else if(TeamBScore>=10)
                {
                    MatchWin(TEAM_B);
                }
            }
        }
        
        // Now do our checks for transitions.
        if(Ruleset==Rules_PUG)
        {
            if(CurrentRound==15)
            {
                // Go to second half.
                TransSecondHalfWarmup();
                return Plugin_Continue;
            }
            else if(CurrentRound==30)
            {
                // Previous checks allow for no use of ==15, ==15
                TransOTFirstHalfWarmup();
                return Plugin_Continue;
            }
            else if(CurrentRound==35)
            {
                TransOTSecondHalfWarmup();
                return Plugin_Continue;
            }
        }
        else if(Ruleset==Rules_CGS)
        {
            if(CurrentRound==9)
            {
                // Go to second half.
                TransSecondHalfWarmup();
                return Plugin_Continue;
            }
            else if(CurrentRound==18)
            {
                // Previous checks allow for no use of ==15, ==15
                TransOTFirstHalfWarmup();
                return Plugin_Continue;
            }
            else if(CurrentRound==21)
            {
                TransOTSecondHalfWarmup();
                return Plugin_Continue;
            }
        }
    }
    return Plugin_Continue;
}

MoveAfterTrans()
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(ValidClient(x) && !IsSourceTV(x))
        {
            new cslTeam = CSLTeam(x);
            if(cslTeam!=TEAM_A && cslTeam!=TEAM_B)
            {
                continue; // Should we kick him? Probably not. This shouldn't happen.
            }
            else
            {
                new csTeam = CSLToCSTeam(cslTeam);
                new curTeam = GetClientTeam(x);
                if(curTeam!=csTeam)
                {
                    CS_SwitchTeam(x, csTeam);
                }
            } 
        }
    }
}

TransSecondHalfWarmup()
{
    // All stop the round counter.
    RoundCounterOn = false;
    // Change state.
    ChangeMatchState(MS_Before_Second_Half);
    // Move them.
    MoveAfterTrans();
}

TransOTFirstHalfWarmup()
{
    RoundCounterOn = false;
    ChangeMatchState(MS_Before_Overtime_First_Half);
    MoveAfterTrans();
}

TransOTSecondHalfWarmup()
{
    RoundCounterOn = false;
    ChangeMatchState(MS_Before_Overtime_Second_Half);
    MoveAfterTrans();
}

public Action:ReduceToOneHundred(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if(ValidClient(client) && ReadyUpState() && IsPlayerAlive(client))
    {
        if(GetClientHealth(client)>100)
        {
            SetEntityHealth(client, 100);
        }
    }
}

public Action:SpawnCallback(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    if(!ValidClient(client) || IsSourceTV(client))
    {
        return Plugin_Continue;
    }
    if(ReadyUpState())
    {
        if(FirstSpawn[client])
        {
            FirstSpawn[client] = false;
            PrintToChat(client, "[PUG] Welcome! Please /ready up and type /help if you need help.");
        }
        else if(!bReady[client])
        {
            PrintToChat(client, "[PUG] Type /ready in chat when you are ready.");
        }
        if(GetMoney(client)!=16000)
        {
            SetMoney(client, 16000);
        }
        
        if(!bReady[client] && IsFakeClient(client)) {
            ReadyUp(client);
        }
        
        // Spawn protection.
        SetEntityHealth(client, 500);
        CreateTimer(2.0, ReduceToOneHundred, userid);
    }
    else
    {
        if(FirstSpawn[client])
        {
            PrintToChat(client, "[PUG] Welcome! Match is LIVE, type /help for help.");
            FirstSpawn[client] = false;
        }
    }
    return Plugin_Continue;
}

PrintDmgReport(client)
{
    // Get current round.
    new OurTeam = GetClientTeam(client);
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(ValidClient(x) && !IsSourceTV(x) && GetClientTeam(x)!=OurTeam)
        {
            new Handle:dmgRound = hMatchDamage[CurrentRound];
            new dmgSize = GetArraySize(dmgRound);
            new dmgTo = 0;
            new dmgHits = 0;
            new String:clName[24];
            GetClientName(x, clName, 24);
            for(new y=0;y<dmgSize;y++)
            {
                new String:Att[24];
                new String:Vic[24];
                new Handle:singleDmg = GetArrayCell(dmgRound, y);
                GetArrayString(singleDmg, 0, Att, 24);
                GetArrayString(singleDmg, 1, Vic, 24);
                new dM = GetArrayCell(singleDmg, 2);
                new IndAtt = ClientOfSteamId(Att);
                new IndVic = ClientOfSteamId(Vic);
                if(ValidClient(IndAtt) && ValidClient(IndVic) && IndAtt==client && IndVic==x)
                {
                    dmgTo+=dM;
                    dmgHits++;
                }
            }
            PrintToChat(client, "[PUG] %s - Damage Given: %d (%d hits)", clName, dmgTo, dmgHits);
        }
    }
    
}

LogDmg(Attacker, Victim, Dmg)
{
    if(!MatchLive())
    {
        return;
    }
    if(CurrentRound<1)
    {
        return;
    }
    new String:AttackerSteam[24];
    new String:VictimSteam[24];
    GetClientAuthString(Attacker, AttackerSteam, 24);
    GetClientAuthString(Victim, VictimSteam, 24);
    // Create a new array.
    new Handle:newArray = CreateArray(24);
    PushArrayString(newArray, AttackerSteam);
    PushArrayString(newArray, VictimSteam);
    PushArrayCell(newArray, Dmg);
    PushArrayCell(hMatchDamage[CurrentRound], newArray);
}

public Action:HurtCallback(Handle:event, const String:name[], bool:dontBroadcast)
{
    // userid, attacker, dmg_health
    new VictimUserid = GetEventInt(event, "userid");
    new AttackerUserid = GetEventInt(event, "attacker");
    new VictimIndex = GetClientOfUserId(VictimUserid);
    new AttackerIndex = GetClientOfUserId(AttackerUserid);
    new Dmg = GetEventInt(event, "dmg_health");
    if(VictimIndex>0 && AttackerIndex>0 && ValidClient(VictimIndex) && ValidClient(AttackerIndex) && AttackerIndex!=VictimIndex)
    {
        LogDmg(AttackerIndex, VictimIndex, Dmg);        
    }
    return Plugin_Continue;
}

SetMoney(client, money)
{
    if(ValidClient(client) && !IsSourceTV(client))
    {
        SetEntData(client, OffsetAccount, money);
    }
}

GetMoney(client)
{
    if(ValidClient(client) && !IsSourceTV(client))
    {
        return GetEntData(client, OffsetAccount);
    }
    return 0;
}

#define CS_TEAM_T 2
#define CS_TEAM_CT 3
#define CS_TEAM_SPEC 1
#define CS_TEAM_AUTO 0

public Action:HookSpectate(client, const String:command[], argc) 
{
    PrintCenterText(client, "CSL: You can't join spectator.");
    return Plugin_Handled;
}

OurAutojoin(client)
{
    // Which team are we supposed to be on?
    // Have the teams been setup yet?
    if(TeamsSetup())
    {
        new MyTeam = CSLTeam(client);
        if(MyTeam!=-1)
        {
            // Join the team we are on.
            if(GetClientTeam(client)!=CSLToCSTeam(MyTeam))
            {
                CS_SwitchTeam(client, CSLToCSTeam(MyTeam));
            }
        }
        else
        {
            // Find a team for us.
            // What team has less active players?
            new String:steamID[24];
            GetClientAuthString(client, steamID, 24);
            new APTeamA = TeamSizeActive(TEAM_A);
            new APTeamB = TeamSizeActive(TEAM_B);
            if(APTeamA<APTeamB)
            {
                // Team A
                AddSteamToTeam(steamID, TEAM_A);
            }
            else if(APTeamB<APTeamA)
            {
                // Team B
                AddSteamToTeam(steamID, TEAM_B);
            }
            else
            {
                // Random
                new RandTeam = GetRandomInt(TEAM_A, TEAM_B);
                AddSteamToTeam(steamID, RandTeam);
            }
            MyTeam = CSLTeam(client);
            if(MyTeam!=-1)
            {
                // Join the team we are on.
                if(GetClientTeam(client)!=CSLToCSTeam(MyTeam))
                {
                    CS_SwitchTeam(client, CSLToCSTeam(MyTeam));
                }
            }
        }
    }
}

TryGoT(client)
{
    if(TeamsSetup())
    {
        new MyTeam = CSLTeam(client);
        if(MyTeam!=-1)
        {
            // Join the team we are on.
            if(CSLToCSTeam(MyTeam)!=CS_TEAM_T)
            {
                PrintCenterText(client, "[PUG] You are on Team %s, they are currently Counter-Terrorist.", ((MyTeam==TEAM_A)?"A":"B"));
            }
            if(GetClientTeam(client)!=CSLToCSTeam(MyTeam))
            {
                CS_SwitchTeam(client, CSLToCSTeam(MyTeam));
            }
        }
        else
        {
            // They clearly want to be a Terrorist, which team is T?
            new TCSL = CSTeamToCSL(CS_TEAM_T);
            new CTCSL = CSTeamToCSL(CS_TEAM_CT);
            new ATCount = TeamSizeActive(TCSL);
            new ACTCount = TeamSizeActive(CTCSL);
            new String:steamID[24];
            GetClientAuthString(client, steamID, 24);
            if(ATCount <= ACTCount)
            {
                // Let them, and add them to the team.
                AddSteamToTeam(steamID, TCSL);
                if(GetClientTeam(client)!=CS_TEAM_T)
                {
                    CS_SwitchTeam(client, CS_TEAM_T);
                }
            }
            else
            {
                // They gotta go CT, add em and tell em the bad news :(
                PrintCenterText(client, "CSL: Sorry, you have been forced to Team %s, the Counter-Terrorists.", ((CTCSL==TEAM_A)?"A":"B"));
                AddSteamToTeam(steamID, CTCSL);
                if(GetClientTeam(client)!=CS_TEAM_CT)
                {
                    CS_SwitchTeam(client, CS_TEAM_CT);
                }
            }
        }
    }
}

CSLToCSTeam(cslTeam)
{
/*
    MS_Before_First_Half, // This is only used if the map changes.
    MS_Live_First_Half,
    MS_Before_Second_Half, // Always used. Team A is CT B is T
    MS_Live_Second_Half,    // Team A is CT team B is T
    MS_Before_Overtime_First_Half, // Team A is T, Team B is CT
    MS_Live_Overtime_First_Half, // Team A is T, Team B is CT
    MS_Before_Overtime_Second_Half, // Team A is CT, Team B is T
    MS_Live_Overtime_Second_Half, // Team A is CT, Team B is T
*/
    // This might need an edit when captains come along?
    if(gMatchState==MS_Live_First_Half)
    {
        if(cslTeam==TEAM_A)
        {
            return CS_TEAM_T;
        }
        else
        {
            return CS_TEAM_CT;
        }
    }
    else if(gMatchState==MS_Before_Second_Half || gMatchState==MS_Live_Second_Half)
    {
        if(cslTeam==TEAM_A)
        {
            return CS_TEAM_CT;
        }
        else
        {
            return CS_TEAM_T;
        }
    }
    else if(gMatchState==MS_Before_Overtime_First_Half || gMatchState==MS_Live_Overtime_First_Half)
    {
        if(cslTeam==TEAM_A)
        {
            return CS_TEAM_T;
        }
        else
        {
            return CS_TEAM_CT;
        }
    }
    else if(gMatchState==MS_Before_Overtime_Second_Half || gMatchState==MS_Live_Overtime_Second_Half)
    {
        if(cslTeam==TEAM_A)
        {
            return CS_TEAM_CT;
        }
        else
        {
            return CS_TEAM_T;
        }
    }
    else
    {
        return -1;
    }
}

CSTeamToCSL(csTeam)
{
    if(CSLToCSTeam(TEAM_A) == csTeam)
    {
        return TEAM_A;
    }
    else
    {
        return TEAM_B;
    }
}

TryGoCT(client)
{
    if(TeamsSetup())
    {
        new MyTeam = CSLTeam(client);
        if(MyTeam!=-1)
        {
            // Join the team we are on.
            if(CSLToCSTeam(MyTeam)!=CS_TEAM_CT)
            {
                PrintCenterText(client, "[PUG] You are on Team %s, they are currently Terrorist.", ((MyTeam==TEAM_A)?"A":"B"));
            }
            if(GetClientTeam(client)!=CSLToCSTeam(MyTeam))
            {
                CS_SwitchTeam(client, CSLToCSTeam(MyTeam));
            }
        }
        else
        {
            // They clearly want to be a Counter-Terrorist, which team is CT?
            new TCSL = CSTeamToCSL(CS_TEAM_T);
            new CTCSL = CSTeamToCSL(CS_TEAM_CT);
            new ATCount = TeamSizeActive(TCSL);
            new ACTCount = TeamSizeActive(CTCSL);
            new String:steamID[24];
            GetClientAuthString(client, steamID, 24);
            if(ACTCount <= ATCount)
            {
                // Let them, and add them to the team.
                AddSteamToTeam(steamID, CTCSL);
                if(GetClientTeam(client)!=CS_TEAM_CT)
                {
                    CS_SwitchTeam(client, CS_TEAM_CT);
                }
            }
            else
            {
                // They gotta go CT, add em and tell em the bad news :(
                PrintCenterText(client, "CSL: Sorry, you have been forced to Team %s, the Terrorists.", ((TCSL==TEAM_A)?"A":"B"));
                AddSteamToTeam(steamID, TCSL);
                if(GetClientTeam(client)!=CS_TEAM_T)
                {
                    CS_SwitchTeam(client, CS_TEAM_T);
                }
            }
        }
    }
}

public Action:HookJoinTeam(client, const String:command[], argc) 
{
    // Destined team
    new String:firstParam[16];
    GetCmdArg(1, firstParam, 16);
    StripQuotes(firstParam);
    new firstParamNumber = StringToInt(firstParam);
    if(!ValidClient(client) || IsFakeClient(client) || IsSourceTV(client))
    {
        return Plugin_Continue;        
    }

    if(firstParamNumber == CS_TEAM_SPEC)
    {
        // No.
        PrintCenterText(client, "CSL: You can't join spectator.");
        return Plugin_Handled;
    }
    else if(firstParamNumber == CS_TEAM_T)
    {
        if(TeamsSetup())
            TryGoT(client);
        else
            return Plugin_Continue;
    }
    else if(firstParamNumber == CS_TEAM_CT)
    {
        if(TeamsSetup())
            TryGoCT(client);
        else
            return Plugin_Continue;
    }
    else // Autojoin, our own version.
    {
        if(TeamsSetup())
            OurAutojoin(client);
        else
            return Plugin_Continue;
    }
    return Plugin_Handled;
}

public Action:HookBuy(client, const String:command[], argc) 
{
    // Destined team
    new String:firstParam[16];
    GetCmdArg(1, firstParam, 16);
    StripQuotes(firstParam);
    if(ReadyUpState())
    {
        if(StrEqual(firstParam,"flashbang") || StrEqual(firstParam,"hegrenade") || StrEqual(firstParam,"smokegrenade"))
        {
            PrintCenterText(client, "CSL: No grenades during warm up.");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

ClearMatch()
{
    ServerCommand("tv_stoprecord\n"); // Leet, MIRITE?!
    if(RestartTimers!=INVALID_HANDLE)
    {
        CloseHandle(RestartTimers);
    }
    RoundCounterOn = false;
    ChangeMatchState(MS_Pre_Setup);
    TeamAScore = 0;
    TeamBScore = 0;
    CurrentRound = 0;
    Format(MatchMap, 32, "");
    for(new x=0;x<MAX_ROUNDS;x++)
    {
        if(hMatchDamage[x]!=INVALID_HANDLE)
        {
            // How big is the array?
            new s = GetArraySize(hMatchDamage[x]);
            for(new y=0;y<s;y++)
            {
                new Handle:aAt = GetArrayCell(hMatchDamage[x], y);
                CloseHandle(aAt);
            }
            CloseHandle(hMatchDamage[x]);
            hMatchDamage[x] = INVALID_HANDLE;
        }
        if(hMatchKills[x]!=INVALID_HANDLE)
        {
            new s = GetArraySize(hMatchKills[x]);
            for(new y=0;y<s;y++)
            {
                new Handle:aAt = GetArrayCell(hMatchKills[x], y);
                CloseHandle(aAt);
            }
            CloseHandle(hMatchKills[x]);
            hMatchKills[x] = INVALID_HANDLE;
        }
    }
    Ruleset = Rules_PUG;
    CaptainMode = false;
    BunnyHopMode = false;
    for(new x=0;x<TEAM_COUNT;x++)
    {
        Format(TeamPlayers[x][0], 24, "");
        Format(TeamPlayers[x][1], 24, "");
        Format(TeamPlayers[x][2], 24, "");
        Format(TeamPlayers[x][3], 24, "");
        Format(TeamPlayers[x][4], 24, "");
    }
}

GetMapCount()
{
    new mapCount = 0;
    for(new x=0;x<MAX_MAPS;x++)
    {
        if(!StrEqual(MapNames[x],""))
        {
            mapCount++;
        }
    }
    return mapCount;
}

AddToOurMaps(const String:mapName[])
{
    for(new x=0;x<MAX_MAPS;x++)
    {
        if(StrEqual(MapNames[x],""))
        {
            Format(MapNames[x], 32, mapName);
            break;
        }
    }
}

LoadMapsDir()
{
    // Build path and look for .bsp files.
    new String:mapsDir[1024];
    BuildPath(Path_SM, mapsDir, 1024, "../../maps/");
    new String:path[1024];
    new Handle:dir = OpenDirectory(mapsDir);
    new FileType:type;
    while(ReadDirEntry(dir, path, sizeof(path), type))
    {
        if(type == FileType_File && StrContains(path, ".bsp") != -1)
        {
            // How many dots in the path?
            new len = strlen(path);
            new periods = 0;
            for(new x=0;x<len;x++)
            {
                if(path[x]=='.')
                {
                    periods++;
                }
            }
            if(periods==1)
            {
                ReplaceString(path, 1024, ".bsp", "", false);
                AddToOurMaps(path);
            }
        }
    }
    CloseHandle(dir);
}

GoPostgame(winning_team, bool:forfeit = false)
{
    RoundCounterOn = false;
    // Send stats?
    ChangeMatchState(MS_Post_Match);
        
    // TODO
    new bool:tie=(winning_team==-1)?true:false;
    if(tie)
    {
        forfeit = false; // Just incase?
    }
    
    // Show everyone their stats page.
    
    ClearMatch();
}

MatchWinForfeit(winning_team)
{
    PrintToChatAll("[PUG] %s wins due to forfeit", (winning_team==TEAM_A)?"Team A":"Team B");
    GoPostgame(winning_team, true);
}

MatchWin(winning_team)
{
    // Was the winning_team T or CT?
    new WinningScore = (winning_team==TEAM_A)?TeamAScore:TeamBScore;
    new LosingScore = (winning_team==TEAM_A)?TeamBScore:TeamAScore;
    PrintToChatAll("[PUG] Match is over, %s wins the match %d - %d",(winning_team==TEAM_A)?"Team A":"Team B", WinningScore, LosingScore);
    
    GoPostgame(winning_team);
}

MatchWinOT(winning_team)
{
    // Was the winning_team T or CT?
    new WinningScore = (winning_team==TEAM_A)?TeamAScore:TeamBScore;
    new LosingScore = (winning_team==TEAM_A)?TeamBScore:TeamAScore;
    PrintToChatAll("[PUG] Overtime is over, %s wins the match %d - %d",(winning_team==TEAM_A)?"Team A":"Team B", WinningScore, LosingScore);
    
    GoPostgame(winning_team);
}

MatchTieOT()
{
    PrintToChatAll("[PUG] Match ends in a tie, %d - %d", TeamAScore, TeamBScore);
    GoPostgame(-1);
}

DeleteBomb()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            new iWeapon = GetPlayerWeaponSlot(i, 4);
            
            if (iWeapon != -1 && IsValidEdict(iWeapon))
            {
                decl String:szClassName[64];
                GetEdictClassname(iWeapon, szClassName, sizeof(szClassName));
                
                if (StrEqual(szClassName, "weapon_c4"))
                {
                    RemovePlayerItem(i, iWeapon);
                    RemoveEdict(iWeapon);
                }
            }
        }
    }

}

bool:IsPubChatMuted(client)
{
    return bPubChatMuted[client];
}

bool:IsTeamChatMuted(client)
{
    return bTeamChatMuted[client];
}

bool:IsPlayerMuted(client, player)
{
    return bMuted[client][player];
}

TryTranslatePlace(const String:input[], String:output[], maxlen)
{
    new bool:bOtherCheck = false;
    if(StrEqual(input, "CTSpawn"))
    {
        Format(output, maxlen, "CT Spawn");
    }
    else if(StrEqual(input, "TSpawn"))
    {
        Format(output, maxlen, "T Spawn")
    }
    else
    {
        bOtherCheck = true;
    }
    if(!bOtherCheck)
    {
        return;
    }
    new len=strlen(input);
    // Clear the output.
    Format(output, maxlen, "");
    new bool:bPrevHadSpace = true;
    new bool:bPrevWasIndi = true;
    for(new x=0;x<len;x++)
    {
        if(input[x]==' ')
        {
            bPrevWasIndi = false;
            if(bPrevHadSpace)
            {
                bPrevHadSpace = false;
            }
            else
            {
                Format(output, maxlen, "%s ", output);
                bPrevHadSpace = true;
            }
        }
        else if( (input[x]>='A' && input[x]<='Z') || (input[x]>='1' && input[x]<='9'))
        {
            if(bPrevWasIndi)
            {
                Format(output, maxlen, "%s%c", output, input[x]);
                bPrevHadSpace = false;
            }
            else
            {
                if(bPrevHadSpace)
                {
                    Format(output, maxlen, "%s%c", output, input[x]);
                    bPrevHadSpace = false;
                }
                else
                {
                    Format(output, maxlen, "%s %c", output, input[x]);
                    bPrevHadSpace = true;
                }
            }
            bPrevWasIndi = true;
        }
        else
        {
            bPrevWasIndi = false;
            if(bPrevHadSpace)
            {
                bPrevHadSpace = false;
            }
            Format(output, maxlen, "%s%c", output, input[x]);
        }
    }
}

ChatMsg(client, bool:team, const String:chatMsg[])
{
    if(!ValidClient(client))
    {
        return;
    }
    new cTeam = GetClientTeam(client);
    if(cTeam<CS_TEAM_T || cTeam>CS_TEAM_CT)
    {
        return;
    }
    new String:cTeamName[32];
    if(cTeam == CS_TEAM_T)
    {
        Format(cTeamName, 32, "Terrorist");
    }
    else
    {
        Format(cTeamName, 32, "Counter-Terrorist");
    }
    new bool:bAlive = IsPlayerAlive(client);
    new String:fullChat[250];
    new String:sPlaceName[64];
    new String:sNewPlaceName[64];
    new String:plName[64];
    GetClientName(client, plName, 64);
    GetEntPropString(client, Prop_Data, "m_szLastPlaceName", sPlaceName, 64);
    TryTranslatePlace(sPlaceName, sNewPlaceName, 64);
    if(bAlive)
    {
        if(team)
        {
            if(StrEqual(sNewPlaceName, ""))
            {
                Format(fullChat, 250, "\x01(%s) \x03%s\x01 : %s", cTeamName, plName, chatMsg);
            }
            else
            {
                Format(fullChat, 250, "\x01(%s) \x03%s\x01 @ \x04%s\x01 : %s", cTeamName, plName, sNewPlaceName, chatMsg);    
            }
        }
        else
        {
            Format(fullChat, 250, "\x03%s\x01 : %s", plName, chatMsg);
        }
    }
    else
    {
        if(team)
        {
            Format(fullChat, 250, "\x01*DEAD*(%s) \x03%s\x01 : %s", cTeamName, plName, chatMsg);
        }
        else
        {
            Format(fullChat, 250, "\x01*DEAD* \x03%s\x01 : %s", plName, chatMsg);
        }
    }
    
    // Console friendly.
    // But first clean it up a bit ;]
    new String:fullChatClean[250];
    Format(fullChatClean, 250, "%s", fullChat);
    ReplaceString(fullChatClean, 250, "\x01", "");
    ReplaceString(fullChatClean, 250, "\x02", "");
    ReplaceString(fullChatClean, 250, "\x03", "");
    ReplaceString(fullChatClean, 250, "\x04", "");
    PrintToServer("%s", fullChatClean);
    
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(!ValidClient(x) || IsFakeClient(x))
        {
            continue;
        }
        new bool:bForMe = true;
        if(team && GetClientTeam(x) != cTeam)
        {
            bForMe = false;
        }
        if(!bAlive)
        {
            if(IsPlayerAlive(x))
            {
                bForMe = false;
            }
        }
        if(IsPlayerMuted(x, client))
        {
            bForMe = false;
        }
        if(team && IsTeamChatMuted(x))
        {
            bForMe = false;
        }
        if(!team && IsPubChatMuted(x))
        {
            bForMe = false;
        }
        if(bForMe)
        {
            new Handle:hBuffer = StartMessageOne("SayText2", x);
            BfWriteByte(hBuffer, client);
            BfWriteByte(hBuffer, true);
            BfWriteString(hBuffer, fullChat);
            EndMessage();
        }
    }
}

public OnPluginStart()
{
    ServerCommand("exec server_pug.cfg\n");
    OffsetAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
    hMaxPlayers = CreateConVar("sv_maxplayers", MAX_PLAYERS_DEFAULT, "Match size.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
    CreateConVar("sm_pug_version", "0.1", "PUG Plugin Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    hTVEnabled = FindConVar("tv_enable");
    hBotQuota = FindConVar("bot_quota");
    SetConVarInt(hBotQuota, 0);
    
    //SetConVarInt(hTVEnabled, 1);
    ClearMatch();
    new Handle:hTagsCvar = FindConVar("sv_tags");
    new oldFlags = GetConVarFlags(hTagsCvar);
    new newFlags = oldFlags;
    newFlags &= ~FCVAR_NOTIFY;
    SetConVarFlags(hTagsCvar, newFlags);
    //new Handle:hTVName = FindConVar("tv_name");
    //SetConVarString(hTVName, "CSL SourceTV");
    //new Handle:hTVTrans = FindConVar("tv_transmitall");
    CreateTimer(4.0, WarmUpSpawner, _, TIMER_REPEAT);
    //SetConVarInt(hTVTrans, 1);
    LoadMapsDir();
    HookEvent("player_spawn",SpawnCallback);
    HookEvent("player_death",DeathCallback);
    HookEvent("player_hurt",HurtCallback);
    HookEvent("round_start",RoundStartCallback);
    HookEvent("round_end",RoundEndCallback);
    AddCommandListener(HookJoinTeam, "jointeam");
    AddCommandListener(HookSpectate, "spectate");
    AddCommandListener(HookBuy, "buy");
    for(new x=0;x<MAXPLAYERS+1;x++) //[0-64]
    {
        ClientDefaults(x);
    }
    // Hooks
    RegConsoleCmd("say",SayPubHook);
    RegConsoleCmd("say_team",SayTeamHook);
    CreateTimer(1.0, OneSecCheck, _, TIMER_REPEAT);
}

enum ConnAction
{
    ConnAction_Connect_NonMember = 0,
    ConnAction_Connect_Member,
    ConnAction_Disconnect,
};

bool:MatchLive()
{
    if(gMatchState == MS_Live_First_Half || gMatchState == MS_Live_Second_Half || gMatchState == MS_Live_Overtime_First_Half || gMatchState == MS_Live_Overtime_Second_Half)
    {
        return true;
    }
    return false;
}

public T_NoCallback(Handle:owner,Handle:hndl,const String:error[],any:data)
{
    // pst... it's quiet... too quiet? maybe log errors?
}

public StatsCallback(Handle:owner,Handle:hndl,const String:error[],any:data)
{
    new client=GetClientOfUserId(data);
    if(!ValidClient(client))
    {
        return;
    }
    if(hndl!=INVALID_HANDLE)
    {
        SQL_Rewind(hndl);
        if(!SQL_FetchRow(hndl))
        {
            PrintToChat(client, "[PUG] Sorry, username doesn't exist.");
        }
        else
        {
            new steamid;
            SQL_FieldNameToNum(hndl, "steamid", steamid);
            new String:steam[24];
            SQL_FetchString(hndl, steamid, steam, 24);
            new String:fullURL[192];
            Format(fullURL, 192, "http://thecsleague.com/stats.php?steam=%s", steam);
            ShowMOTDPanel(client, "Stats", fullURL, MOTDPANEL_TYPE_URL);
        }
    }
}
        
StartAuth(client)
{
    if(!ValidClient(client) || IsSourceTV(client))
    {
        return;        
    }
    if(!AllowBots() && IsFakeClient(client))
    {
        Kick(client,"No bots!"); // No bots stupid.    
        return;
    }
    notReadyTime[client] = GetTime();
    // Make sure they are a customer.
    decl String:steamID[24];
    GetClientAuthString(client, steamID, 24);
    if(BadSteamId(steamID))
    {
        Kick(client,"Your STEAMID isn't valid.");
        return;
    }

    notReadyTime[client] = GetTime();
    // Is the match already live? If it is put this person on a team etc...
    // TODO: This will need to be changed once we have a captain mode.
    if(TeamsSetup())
    {
        OurAutojoin(client);
    }  
}

bool:IsSourceTV(client)
{
    if(!ValidClient(client))
        return false;
    decl String:plName[64];
    GetClientName(client, plName, 64);
    if(IsFakeClient(client) && ( StrEqual(plName,"SourceTV") || StrEqual(plName,"CSL SourceTV") ))
    {
        return true;
    }
    return false;
}

public OnClientPutInServer(client)
{
    ClientDefaults(client);
    if(IsSourceTV(client))
        return; // Don't auth the SourceTV dude! :P
    new cCount = GetClientCount();
    if(GetConVarInt(hTVEnabled)==1)
        cCount -= 1;
    if(cCount>GetConVarInt(hMaxPlayers))
    {
        Kick(client, "Sorry, this match is full");
        return;
    }
    StartAuth(client);
}

ClientOfSteamId(const String:steamID[])
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        if(ValidClient(x) && !IsSourceTV(x))
        {
            new String:mySteam[24];
            GetClientAuthString(x, mySteam, 24);
            if(StrEqual(steamID, mySteam))
            {
                return x;
            }
        }
    }
    return 0;
}

TeamOfSteamId(const String:steamID[])
{
    // Return of -1 indicates none yet.
    for(new x=0;x<TEAM_COUNT;x++)
    {
        for(new y=0;y<5;y++)
        {
            if(StrEqual(steamID, TeamPlayers[x][y]))
            {
                return x;
            }
        }
    }
    return -1;
}

public OnClientDisconnect(client)
{
    bDisconnecting[client] = true;
    
    new bool:specialCase = false;
    
    if(IsFakeClient(client) && !IsSourceTV(client)) {
        specialCase = true;
    }
    
    if(IsSourceTV(client))
        return;

    if(MatchLive())
    {
        new String:steamID[24];
        GetClientAuthString(client, steamID, 24);
        new TeamAB = TeamOfSteamId(steamID);
        if(TeamAB==-1)
        {
            return; // They we're on a team yet.
        }
        // Is anyone else on their team still there? If not, the match has been forfeited.
        new bool:AnyOnline = false;
        for(new x=0;x<5;x++)
        {
            new cOfSteam = ClientOfSteamId(TeamPlayers[TeamAB][x]);
            if(ValidClient(cOfSteam) && client!=cOfSteam)
            {
                AnyOnline = true;
            }    
        }
        if(!AnyOnline && !specialCase)
        {
            MatchWinForfeit( (TeamAB==TEAM_A) ? TEAM_B : TEAM_A );
        }
    }
    /*else
    {
        // TODO: If we are picking teams? 
    }*/
}

public OnMapStart()
{
    ServerCommand("mp_do_warmup_period 0");
    ServerCommand("mp_maxrounds 999999");
    ServerCommand("bot_quota 0");
    ServerCommand("bot_kick");
}