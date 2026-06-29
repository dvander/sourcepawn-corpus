#pragma semicolon 1

#include <sourcemod.inc>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <left4downtown>
#include <timers.inc>

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

#define TEAM_SPECTATOR          1 
#define TEAM_SURVIVOR           2 
#define TEAM_INFECTED           3
#define FLAG_SPECTATOR          (1 << TEAM_SPECTATOR)
#define FLAG_SURVIVOR           (1 << TEAM_SURVIVOR)
#define FLAG_INFECTED           (1 << TEAM_INFECTED)

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

#define BREV_SI                 1
#define BREV_CI                 2
#define BREV_FF                 4
#define BREV_RANK               8
//#define BREV_???              16
#define BREV_PERCENT            32
#define BREV_ABSOLUTE           64

#define CONBUFSIZE              1024
#define CONBUFSIZELARGE         4096

#define CHARTHRESHOLD           160         // detecting unicode stuff


/**
* Issues:
*  - Add damage received from common
*/

/*
Changelog
---------
0.2c
- added console output table for more stats, fixed it's display
- fixed console display to always display each player on the survivor team

0.1
- fixed common MVP ranks being messed up.
- finally worked in PluginEnabled cvar
- made FF tracking switch to enabled automatically if brevity flag 4 is unset
- fixed a bug that caused FF to always report as "no friendly fire" when tracking was disabled
- adjusted formatting a bit
- made FF stat hidden by default
- made convars actually get tracked (doh)
- added friendly fire tracking (sm_survivor_mvp_trackff 1/0)
- added brevity-flags cvar for changing verbosity of MVP report (sm_survivor_mvp_brevity bitwise, as shown)
- discount FF damage before match is live if RUP is active.
- fixed problem with clients disconnecting before mvp report
- improved consistency after client reconnect (name-based)
- fixed mvp stats double showing in scavenge (round starts)
- now shows if MVP is a bot
- cleaned up code
- fixed for scavenge, now shows stats for every scavenge round
- fixed damage/kills getting recorded for infected players, skewing MVP stats
- added rank display for non-MVP clients
*/
/*
Brevity flags:
1       leave out SI stats
2       leave out CI stats
4       leave out FF stats
8       leave out rank notification
16   (reserved)
32      leave out percentages
64      leave out absolutes

*/

public Plugin:myinfo =
{
    name = "Survivor MVP notification",
    author = "Tabun, Artifacial",
    description = "Shows MVP for survivor team at end of round",
    version = "0.3",
    url = "https://github.com/alexberriman/l4d2_survivor_mvp"
};


new     Handle:     hPluginEnabled =    INVALID_HANDLE;

new     Handle:     hCountTankDamage =  INVALID_HANDLE;         // whether we're tracking tank damage for MVP-selection
new     Handle:     hCountWitchDamage = INVALID_HANDLE;         // whether we're tracking witch damage for MVP-selection
new     Handle:     hTrackFF =          INVALID_HANDLE;         // whether we're tracking friendly-fire damage (separate stat)
new     Handle:     hBrevityFlags =     INVALID_HANDLE;         // how verbose/brief the output should be:
new     Handle:     hRUPActive =        INVALID_HANDLE;         // whether the ready up mod is active
new     Handle:     hTeamSize =         INVALID_HANDLE;         // amount of players in team

new     bool:       bCountTankDamage;
new     bool:       bCountWitchDamage;
new     bool:       bTrackFF;
new                 iBrevityFlags;
new     bool:       bRUPActive;

new     Handle:     hGameMode = INVALID_HANDLE;
new     String:     sGameMode[24] = "\0";

new     String:     sClientName[MAXPLAYERS + 1][64];            // which name is connected to the clientId?

// Basic statistics
new                 iGotKills[MAXPLAYERS + 1];                  // SI kills             track for each client
new                 iGotCommon[MAXPLAYERS + 1];                 // CI kills
new                 iDidDamage[MAXPLAYERS + 1];                 // SI only              these are a bit redundant, but will keep anyway for now
new                 iDidDamageAll[MAXPLAYERS + 1];              // SI + tank + witch
new                 iDidDamageTank[MAXPLAYERS + 1];             // tank only
new                 iDidDamageWitch[MAXPLAYERS + 1];            // witch only
new                 iDidFF[MAXPLAYERS + 1];                     // friendly fire damage

// Detailed statistics
new                 iDidDamageClass[MAXPLAYERS + 1][ZC_TANK + 1];   // si classes
new                 timesPinned[MAXPLAYERS + 1][ZC_TANK + 1];   // times pinned
new                 totalPinned[MAXPLAYERS + 1];                // total times pinned
new                 pillsUsed[MAXPLAYERS + 1];                  // total pills eaten
new                 boomerPops[MAXPLAYERS + 1];                 // total boomer pops
new                 damageReceived[MAXPLAYERS + 1];             // Damage received

// Tank stats
new                tankSpawned = false;                        // When tank is spawned
new                 commonKilledDuringTank[MAXPLAYERS + 1];     // Common killed during the tank
new                 ttlCommonKilledDuringTank = 0;              // Common killed during the tank
new                 siDmgDuringTank[MAXPLAYERS + 1];            // SI killed during the tank
new                 ttlSiDmgDuringTank = 0;                     // Total SI killed during the tank
new                tankThrow;                                  // Whether or not the tank has thrown a rock
new                 rocksEaten[MAXPLAYERS + 1];                 // The amount of rocks a player 'ate'.
new                 rockIndex;                                  // The index of the rock (to detect how many times we were rocked)
new                 ttlPinnedDuringTank[MAXPLAYERS + 1];        // The total times we were pinned when the tank was up


new                 iTotalKills;                                // prolly more efficient to store than to recalculate
new                 iTotalCommon;
new                 iTotalDamage;
new                 iTotalDamageTank;
new                 iTotalDamageWitch;
new                 iTotalDamageAll;
new                 iTotalFF;

new                 iRoundNumber;
new                 bInRound;
new                 bPlayerLeftStartArea;                       // used for tracking FF when RUP enabled

new     String:     sConsoleBuf[CONBUFSIZE];                    // used for spamming table of stats to console
new     String:     sDetailedConsoleBuf[CONBUFSIZE];            // used for detailed table of stats to console
new     String:     sTankConsoleBuf[CONBUFSIZE];                // used for spamming tank table of stats to console
new     String:     sTmpString[MAX_NAME_LENGTH];                // just used because I'm not going to break my head over why string assignment parameter passing doesn't work

/*
*      Natives
*      =======
*/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("SURVMVP_GetMVP", Native_GetMVP);
    CreateNative("SURVMVP_GetMVPDmgCount", Native_GetMVPDmgCount);
    CreateNative("SURVMVP_GetMVPKills", Native_GetMVPKills);
    CreateNative("SURVMVP_GetMVPDmgPercent", Native_GetMVPDmgPercent);
    CreateNative("SURVMVP_GetMVPCI", Native_GetMVPCI);
    CreateNative("SURVMVP_GetMVPCIKills", Native_GetMVPCIKills);
    CreateNative("SURVMVP_GetMVPCIPercent", Native_GetMVPCIPercent);
    
    return APLRes_Success;
}

// simply return current round MVP client
public Native_GetMVP(Handle:plugin, numParams)
{
    new client = findMVPSI();
    return _:client;
}

// return damage percent of client
public Native_GetMVPDmgPercent(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new Float: dmgprc = client && iTotalDamageAll > 0 ? (float(iDidDamageAll[client]) / float(iTotalDamageAll)) * 100 : 0.0;
    return _:dmgprc;
}

// return damage of client
public Native_GetMVPDmgCount(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new dmg = client && iTotalDamageAll > 0 ? iDidDamageAll[client] : 0;
    return _:dmg;
}

// return SI kills of client
public Native_GetMVPKills(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new dmg = client && iTotalKills > 0 ? iGotKills[client] : 0;
    return _:dmg;
}

// simply return current round MVP client (Common)
public Native_GetMVPCI(Handle:plugin, numParams)
{
    new client = findMVPCommon();
    return _:client;
}

// return common kills for client
public Native_GetMVPCIKills(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new dmg = client && iTotalCommon > 0 ? iGotCommon[client] : 0;
    return _:dmg;
}

// return CI percent of client
public Native_GetMVPCIPercent(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new Float: dmgprc = client && iTotalCommon > 0 ? (float(iGotCommon[client]) / float(iTotalCommon)) * 100 : 0.0;
    return _:dmgprc;
}


/*
*      init
*      ====
*/

public OnPluginStart()
{
    // Round triggers
    //HookEvent("door_close", DoorClose_Event);
    //HookEvent("finale_vehicle_leaving", FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start", EventHook:ScavRoundStart);
    HookEvent("player_left_start_area", PlayerLeftStartArea);
    HookEvent("pills_used", pillsUsedEvent);
    HookEvent("boomer_exploded", boomerExploded);
    HookEvent("charger_carry_end", chargerCarryEnd);
    HookEvent("jockey_ride", jockeyRide);
    HookEvent("lunge_pounce", hunterLunged);
    HookEvent("choke_start", smokerChoke);
    HookEvent("tank_killed", tankKilled);
    HookEvent("tank_spawn", tankSpawn);
    HookEvent("ability_use", abilityUseEvent);
    //HookEvent("tank_frustrated", tankFrustrated);
    
    // Catching data
    HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    HookEvent("infected_hurt" ,InfectedHurt_Event, EventHookMode_Post);
    HookEvent("infected_death", InfectedDeath_Event, EventHookMode_Post);
    
    // check gamemode (for scavenge fix)
    hGameMode = FindConVar("mp_gamemode");
    
    // Cvars
    hPluginEnabled =    CreateConVar("sm_survivor_mvp_enabled", "1", "Enable display of MVP at end of round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    hCountTankDamage =  CreateConVar("sm_survivor_mvp_counttank", "0", "Damage on tank counts towards MVP-selection if enabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    hCountWitchDamage = CreateConVar("sm_survivor_mvp_countwitch", "0", "Damage on witch counts towards MVP-selection if enabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    hTrackFF =          CreateConVar("sm_survivor_mvp_showff", "0", "Track Friendly-fire stat.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    hBrevityFlags =     CreateConVar("sm_survivor_mvp_brevity", "4", "Flags for setting brevity of MVP report (hide 1:SI, 2:CI, 4:FF, 8:rank, 32:perc, 64:abs).", FCVAR_PLUGIN, true, 0.0);
    
    hTeamSize =         FindConVar("survivor_limit");
    
    bCountTankDamage =  GetConVarBool(hCountTankDamage);
    bCountWitchDamage = GetConVarBool(hCountWitchDamage);
    bTrackFF =          GetConVarBool(hTrackFF);
    iBrevityFlags =     GetConVarInt(hBrevityFlags);
    
    
    
    // for now, force FF tracking on:
    bTrackFF = true;
    
    HookConVarChange(hCountTankDamage, ConVarChange_CountTankDamage);
    HookConVarChange(hCountWitchDamage, ConVarChange_CountWitchDamage);
    HookConVarChange(hTrackFF, ConVarChange_TrackFF);
    HookConVarChange(hBrevityFlags, ConVarChange_BrevityFlags);
    
    if (!(iBrevityFlags & BREV_FF)) { bTrackFF = true; } // force tracking on if we're showing FF
    
    // RUP?
    hRUPActive = FindConVar("l4d_ready_enabled");
    if (hRUPActive != INVALID_HANDLE)
    {
        // hook changes for this, and set state appropriately
        bRUPActive = GetConVarBool(hRUPActive);
        HookConVarChange(hRUPActive, ConVarChange_RUPActive);
    } else {
        // not loaded
        bRUPActive = false;
    }
    bPlayerLeftStartArea = false;
    
    // Commands
    RegConsoleCmd("sm_mvp", SurvivorMVP_Cmd, "Prints the current MVP for the survivor team");
    RegConsoleCmd("sm_mvpme", ShowMVPStats_Cmd, "Prints the client's own MVP-related stats");
    
    RegConsoleCmd("say", Say_Cmd);
    RegConsoleCmd("say_team", Say_Cmd);
}

/*
public OnPluginEnd()
{
// nothing
}
*/

public OnClientPutInServer(client)
{
    decl String:tmpBuffer[64];
    GetClientName(client, tmpBuffer, sizeof(tmpBuffer));
    
    // if previously stored name for same client is not the same, delete stats & overwrite name
    if (strcmp(tmpBuffer, sClientName[client], true) != 0)
    {
        iGotKills[client] = 0;
        iGotCommon[client] = 0;
        iDidDamage[client] = 0;
        iDidDamageAll[client] = 0;
        iDidDamageWitch[client] = 0;
        iDidDamageTank[client] = 0;
        iDidFF[client] = 0;
        
        
        //@todo detailed statistics - set to 0
        for (new siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) {
            iDidDamageClass[client][siClass] = 0;
            timesPinned[client][siClass] = 0;
        }
        pillsUsed[client] = 0;
        boomerPops[client] = 0;
        damageReceived[client] = 0;
        totalPinned[client] = 0;
        commonKilledDuringTank[client] = 0;
        siDmgDuringTank[client] = 0;
        rocksEaten[client] = 0;
        ttlPinnedDuringTank[client] = 0;
        
        // store name for later reference
        strcopy(sClientName[client], 64, tmpBuffer);
    }
}

/*
*      convar changes
*      ==============
*/

public ConVarChange_CountTankDamage(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    bCountTankDamage = StringToInt(newValue) != 0;
}
public ConVarChange_CountWitchDamage(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    bCountWitchDamage = StringToInt(newValue) != 0;
}
public ConVarChange_TrackFF(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    //if (StringToInt(newValue) == 0) { bTrackFF = false; } else { bTrackFF = true; }
    // for now, disable FF tracking toggle (always on)
}
public ConVarChange_BrevityFlags(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    iBrevityFlags = StringToInt(newValue);
    if (!(iBrevityFlags & BREV_FF)) { 
        bTrackFF = true; 
    } // force tracking on if we're showing FF
}

public ConVarChange_RUPActive(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    bRUPActive = StringToInt(newValue) != 0;
}

/*
*      map load / round start/end
*      ==========================
*/

public Action:PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
    // if RUP active, now we can start tracking FF
    bPlayerLeftStartArea = true;
}

public OnMapStart()
{
    bPlayerLeftStartArea = false;
    // get gamemode string for scavenge fix
    GetConVarString(hGameMode, sGameMode, sizeof(sGameMode));
}

public OnMapEnd()
{
    iRoundNumber = 0;
    bInRound = false;
}

public ScavRoundStart(Handle:event)
{
    // clear mvp stats
    new i, maxplayers = MaxClients;
    for (i = 1; i <= maxplayers; i++)
    {
        iGotKills[i] = 0;
        iGotCommon[i] = 0;
        iDidDamage[i] = 0;
        iDidDamageAll[i] = 0;
        iDidDamageWitch[i] = 0;
        iDidDamageTank[i] = 0;
        iDidFF[i] = 0;
        
        //@todo detailed statistics - set to 0
        for (new siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) {
            iDidDamageClass[i][siClass] = 0;
            timesPinned[i][siClass] = 0;
        }
        pillsUsed[i] = 0;
        boomerPops[i] = 0;
        damageReceived[i] = 0;
        totalPinned[i] = 0;
        commonKilledDuringTank[i] = 0;
        siDmgDuringTank[i] = 0;
        rocksEaten[i] = 0;
        ttlPinnedDuringTank[i] = 0;
    }
    iTotalKills = 0;
    iTotalCommon = 0;
    iTotalDamage = 0;
    iTotalDamageTank = 0;
    iTotalDamageWitch = 0;
    iTotalDamageAll = 0;
    iTotalFF = 0;
    ttlSiDmgDuringTank = 0;
    ttlCommonKilledDuringTank = 0;
    tankThrow = false;
    
    bInRound = true;
    tankSpawned = false;
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    bPlayerLeftStartArea = false;
    
    if (!bInRound)
    {
        bInRound = true;
        iRoundNumber++;
    }
    
    // clear mvp stats
    new i, maxplayers = MaxClients;
    for (i = 1; i <= maxplayers; i++)
    {
        iGotKills[i] = 0;
        iGotCommon[i] = 0;
        iDidDamage[i] = 0;
        iDidDamageAll[i] = 0;
        iDidDamageWitch[i] = 0;
        iDidDamageTank[i] = 0;
        iDidFF[i] = 0;
        
        //@todo detailed statistics init to 0
        for (new siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) {
            iDidDamageClass[i][siClass] = 0;
            timesPinned[i][siClass] = 0;
        }
        pillsUsed[i] = 0;
        boomerPops[i] = 0;
        damageReceived[i] = 0;
        totalPinned[i] = 0;
        commonKilledDuringTank[i] = 0;
        siDmgDuringTank[i] = 0;
        rocksEaten[i] = 0;
        ttlPinnedDuringTank[i] = 0;
    }
    iTotalKills = 0;
    iTotalCommon = 0;
    iTotalDamage = 0;
    iTotalDamageAll = 0;
    iTotalFF = 0;
    ttlSiDmgDuringTank = 0;
    ttlCommonKilledDuringTank = 0;
    iTotalDamageTank = 0;
    tankThrow = false;
    
    tankSpawned = false;
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StrEqual(sGameMode, "scavenge", false))
    {
        if (bInRound)
        {
            if (GetConVarBool(hPluginEnabled))
                CreateTimer(2.0, delayedMVPPrint);   // shorter delay for scavenge.
            bInRound = false;
        }
    }
    else
    {
        // versus or other
        if (bInRound)
        {
            // only show / log stuff when the round is done "the first time"
            if (GetConVarBool(hPluginEnabled))
                CreateTimer(4.0, delayedMVPPrint);
            bInRound = false;
        }
    }
    
    tankSpawned = false;
}


/*
*      cmds / reports
*      ==============
*/

public Action:Say_Cmd(client, args)
{
    if (!client) { return Plugin_Continue; }
    
    decl String:sMessage[MAX_NAME_LENGTH];
    GetCmdArg(1, sMessage, sizeof(sMessage));
    
    if (StrEqual(sMessage, "!mvp") || StrEqual(sMessage, "!mvpme")) { return Plugin_Handled; }
    
    return Plugin_Continue;
}

public Action:SurvivorMVP_Cmd(client, args)
{
    decl String:printBuffer[1024];
    new String:strLines[8][192];
    
    printBuffer = GetMVPString();
    PrintConsoleReport(client);
    
    // PrintToChat has a max length. Split it in to individual lines to output separately
    new intPieces = ExplodeString(printBuffer, "\n", strLines, sizeof(strLines), sizeof(strLines[]));
    
    if (client && IsClientConnected(client))
    {
        for (new i = 0; i < intPieces; i++) {
            PrintToChat(client, "\x01%s", strLines[i]);
        }
    }
    else
    {
        PrintToServer("\x01%s", printBuffer);
    }
}

public Action:ShowMVPStats_Cmd(client, args)
{
    // show mvp in this round
    if (client && IsClientConnected(client))
    {
        decl String:printBuffer[1024];
        decl String:tmpBuffer[512];
        
        printBuffer = "";
        
        if (!(iBrevityFlags & BREV_SI))
        {
            if (iTotalDamageAll > 0)
            {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] You - SI: (\x05%d \x01dmg,\x05 %d \x01kills)\n", iDidDamageAll[client], iGotKills[client]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] You - SI: (dmg \x04%2.0f%%\x01, kills \x04%.0f%%\x01)\n", (float(iDidDamageAll[client]) / float(iTotalDamageAll)) * 100, (float(iGotKills[client]) / float(iTotalKills)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] You - SI: (\x05%d \x01dmg [\x04%.0f%%\x01],\x05 %d \x01kills [\x04%.0f%%\x01])\n", iDidDamageAll[client], (float(iDidDamageAll[client]) / float(iTotalDamageAll)) * 100, iGotKills[client], (float(iGotKills[client]) / float(iTotalKills)) * 100);
                }
                StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
            }
            else
            {
                StrCat(printBuffer, sizeof(printBuffer), "\x01[You] SI: (nada)\n");
            }
        }
        
        if (!(iBrevityFlags & BREV_CI))
        {
            if (iTotalCommon > 0)
            {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] You - CI: (\x05%d \x01common)\n", iGotCommon[client]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] You - CI: (\x04%.0f%%\x01)\n", (float(iGotCommon[client]) / float(iTotalCommon)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] You - CI: (\x05%d \x01common [\x04%.0f%%\x01])\n", iGotCommon[client], (float(iGotCommon[client]) / float(iTotalCommon)) * 100);
                }
                StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
            }
        }
        
        PrintToChat(client, "\x01%s", printBuffer);
        
        // leave this like so for now. might let brevityflags block this too.
        if (!(iBrevityFlags & BREV_FF) && bTrackFF) {
            PrintToChat(client, "\x01You - FF: (\x05%d \x01friendly dmg [\x04%.0f%%\x01])\n", iDidFF[client], (float(iDidFF[client]) / float(iTotalFF)) * 100);
        }
        
    }
}

public Action:delayedMVPPrint(Handle:timer)
{
    decl String:printBuffer[1024];
    decl String:tmpBuffer[512];
    new String:strLines[8][192];
    
    printBuffer = GetMVPString();
    PrintToServer("\x01%s", printBuffer);
    
    // PrintToChatAll has a max length. Split it in to individual lines to output separately
    new intPieces = ExplodeString(printBuffer, "\n", strLines, sizeof(strLines), sizeof(strLines[]));
    for (new i = 0; i < intPieces; i++) {
        PrintToChatAll("\x01%s", strLines[i]);
    }
    
    PrintConsoleReport(0); // to all
    
    // also find the three non-mvp survivors and tell them they sucked
    // tell them they sucked with SI
    if (iTotalDamageAll > 0 && !(iBrevityFlags & BREV_RANK) && !(iBrevityFlags & BREV_SI))
    {
        new mvp_SI = findMVPSI();
        new mvp_SI_losers[3];
        mvp_SI_losers[0] = findMVPSI(int:mvp_SI);                                                   // second place
        mvp_SI_losers[1] = findMVPSI(int:mvp_SI, int:mvp_SI_losers[0]);                             // third
        mvp_SI_losers[2] = findMVPSI(int:mvp_SI, int:mvp_SI_losers[0], int:mvp_SI_losers[1]);       // fourth
        
        for (new i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_SI_losers[i]) && !IsFakeClient(mvp_SI_losers[i])) {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] Your rank - SI: #\x03%d \x01(\x05%d \x01dmg,\x05 %d \x01kills)", (i + 2), iDidDamageAll[mvp_SI_losers[i]], iGotKills[mvp_SI_losers[i]]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] Your rank - SI: #\x03%d \x01(dmg \x04%.0f%%\x01, kills \x04%.0f%%\x01)", (i + 2), (float(iDidDamageAll[mvp_SI_losers[i]]) / float(iTotalDamageAll)) * 100, (float(iGotKills[mvp_SI_losers[i]]) / float(iTotalKills)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] Your rank - SI: #\x03%d \x01(\x05%d \x01dmg [\x04%.0f%%\x01],\x05 %d \x01kills [\x04%.0f%%\x01])", (i + 2), iDidDamageAll[mvp_SI_losers[i]], (float(iDidDamageAll[mvp_SI_losers[i]]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI_losers[i]], (float(iGotKills[mvp_SI_losers[i]]) / float(iTotalKills)) * 100);
                }
                PrintToChat(mvp_SI_losers[i], "\x01%s", tmpBuffer);
            }
        }
    }
    
    // tell them they sucked with Common
    if (iTotalCommon > 0 && !(iBrevityFlags & BREV_RANK) && !(iBrevityFlags & BREV_CI))
    {
        new mvp_CI = findMVPCommon();
        new mvp_CI_losers[3];
        mvp_CI_losers[0] = findMVPCommon(int:mvp_CI);                                                   // second place
        mvp_CI_losers[1] = findMVPCommon(int:mvp_CI, int:mvp_CI_losers[0]);                             // third
        mvp_CI_losers[2] = findMVPCommon(int:mvp_CI, int:mvp_CI_losers[0], int:mvp_CI_losers[1]);       // fourth
        
        for (new i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_CI_losers[i]) && !IsFakeClient(mvp_CI_losers[i])) {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] Your rank - CI: #\x03%d \x01(\x05%d \x01kills)", (i + 2), iGotCommon[mvp_CI_losers[i]]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] Your rank - CI: #\x03%d \x01(kills \x04%.0f%%\x01)", (i + 2), (float(iGotCommon[mvp_CI_losers[i]]) / float(iTotalCommon)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] Your rank - CI: #\x03%d \x01(\x05%d \x01kills [\x04%.0f%%\x01])", (i + 2), iGotCommon[mvp_CI_losers[i]], (float(iGotCommon[mvp_CI_losers[i]]) / float(iTotalCommon)) * 100);
                }
                PrintToChat(mvp_CI_losers[i], "\x01%s", tmpBuffer);
            }
        }
    }
    
    // tell them they were better with FF (I know, I know, losers = winners)
    if (iTotalFF > 0 && bTrackFF && !(iBrevityFlags & BREV_RANK) && !(iBrevityFlags & BREV_FF))
    {
        new mvp_FF = findLVPFF();
        new mvp_FF_losers[3];
        mvp_FF_losers[0] = findLVPFF(int:mvp_FF);                                                   // second place
        mvp_FF_losers[1] = findLVPFF(int:mvp_FF, int:mvp_FF_losers[0]);                             // third
        mvp_FF_losers[2] = findLVPFF(int:mvp_FF, int:mvp_FF_losers[0], int:mvp_FF_losers[1]);       // fourth
        
        for (new i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_FF_losers[i]) && !IsFakeClient(mvp_FF_losers[i])) {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] Your rank - FF: #\x03%d \x01(\x05%d \x01dmg)", (i + 2), iDidFF[mvp_FF_losers[i]]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] Your rank - FF: #\x03%d \x01(dmg \x04%.0f%%\x01)", (i + 2), (float(iDidFF[mvp_FF_losers[i]]) / float(iTotalFF)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] Your rank - FF: #\x03%d \x01(\x05%d \x01dmg [\x04%.0f%%\x01])", (i + 2), iDidFF[mvp_FF_losers[i]], (float(iDidFF[mvp_FF_losers[i]]) / float(iTotalFF)) * 100);
                }
                PrintToChat(mvp_FF_losers[i], "\x01%s", tmpBuffer);
            }
        }
    }
}

/**
* When an entity is created (which we use to track rocks)
* don't actually need this
*/
public OnEntityCreated(entity, const String:classname[])
{ 
    if(! tankThrow) {
        return;
    }
    
    if(StrEqual(classname, "tank_rock", true))  {
        rockIndex = entity;
        tankThrow = true;
    }
}

/**
* When an entity has been destroyed (i.e. when a rock lands on someone)
*/
public OnEntityDestroyed(entity)
{   
    // The rock has been destroyed
    if (rockIndex == entity) {
        tankThrow = false;
    }
}

/**
* When an infected uses their ability
*/
public Action:abilityUseEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:ability[32];
    GetEventString(event, "ability", ability, 32);
    
    // If tank is throwing a rock
    if(StrEqual(ability, "ability_throw", true)) {
        tankThrow = true;
    }
}

/**
* Track pill usage
*/
public pillsUsedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    pillsUsed[client]++;
}

/**
* Track boomer pops
*/
public boomerExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
    // We only want to track pops where the boomer didn't bile anyone
    new bool:biled = GetEventBool(event, "splashedbile");
    if (! biled) {
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (attacker == 0 || ! IsClientInGame(attacker)) {
            return;
        }
        boomerPops[attacker]++;
    }
}


/**
* Track when someone gets charged (end of charge for level, or if someone shoots you off etc.)
*/
public chargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_CHARGER]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/**
* Track when someone gets jockeyed.
*/
public jockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_JOCKEY]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/** 
* Track when someone gets huntered.
*/
public hunterLunged(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_HUNTER]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/**
* Track when someone gets smoked (we track when they start getting smoked, because anyone can get smoked)
*/
public smokerChoke(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_SMOKER]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/**
* When the tank spawns
*/
public tankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    tankSpawned = true;
}

/**
* When the tank is killed
*/
public tankKilled(Handle:event, const String:name[], bool:dontBroadcast) {
    tankSpawned = false;
}

/**
* Output the console report.

* This seems like a really ineffective method of doing this. For some reason, it isn't outputting
* the entire string to the console (and when I try to increase the buffer size I get an error). I
* need to ask some of the other developers about this, but for the mean time the workaround I've 
* used (breaking the output up in to a range of different data values) should suffice. 
* 
* This method also shouldn't be this long. Should be broken up in to a range of smaller methods.
*/
public PrintConsoleReport(client)
{
    /**
    * Let's prepare the basic information.
    */
    decl String:bufBasicHeader[CONBUFSIZE];
    decl String:bufBasic[CONBUFSIZELARGE];
    
    Format(bufBasicHeader, CONBUFSIZE, "\n");
    Format(bufBasicHeader, CONBUFSIZE, "%s| Basic Statistics                                                                                                                       |\n", bufBasicHeader);
    Format(bufBasicHeader, CONBUFSIZE, "%s|----------------------|----------|---------|----------|----------|---------|--------|--------|------------------------------------------|\n", bufBasicHeader);
    Format(bufBasicHeader, CONBUFSIZE, "%s| Name                 | Damage   | Percent | SI Kills | Commons  | Percent | Tank   | Witch  | FF                                       |\n", bufBasicHeader);
    Format(bufBasicHeader, CONBUFSIZE, "%s|----------------------|----------|---------|----------|----------|---------|--------|--------|------------------------------------------|", bufBasicHeader);
    Format(bufBasic, CONBUFSIZELARGE, "%s", sConsoleBuf);
    Format(bufBasic, CONBUFSIZELARGE, "%s|----------------------------------------------------------------------------------------------------------------------------------------|\n", bufBasic);
    
    /**
    * Let's prepare the detailed information.
    */
    decl String:bufDetailedHeader[CONBUFSIZE];
    decl String:bufDetailed[CONBUFSIZELARGE];
    
    Format(bufDetailedHeader, CONBUFSIZELARGE, "\n");
    Format(bufDetailedHeader, CONBUFSIZELARGE, "%s| Detailed Stats (pops = boomers killed before booming anyone | pinned = time pinned by SI | damage done to SI classes)                  |\n", bufDetailedHeader);
    Format(bufDetailedHeader, CONBUFSIZELARGE, "%s|----------------------|----------|---------|----------|----------|----------|---------|----------|----------|---------|-----------------|\n", bufDetailedHeader);
    Format(bufDetailedHeader, CONBUFSIZELARGE, "%s| Name                 | Pinned   | Pills   | DamageRec| Smoker   | Hunter   | Boomer  | Spitter  | Charger  | Jockey  | Pops            |\n", bufDetailedHeader);
    Format(bufDetailedHeader, CONBUFSIZELARGE, "%s|----------------------|----------|---------|----------|----------|----------|---------|----------|----------|---------|-----------------|", bufDetailedHeader);
    Format(bufDetailed, CONBUFSIZELARGE, "%s", sDetailedConsoleBuf);
    Format(bufDetailed, CONBUFSIZELARGE, "%s|----------------------------------------------------------------------------------------------------------------------------------------|\n", bufDetailed);
    
    /**
    * Let's prepare the tank statistics
    */
    decl String:bufTank[CONBUFSIZELARGE];
    decl String:bufTankHeader[CONBUFSIZE];
    
    Format(bufTankHeader, CONBUFSIZELARGE, "\n");
    Format(bufTankHeader, CONBUFSIZELARGE, "%s| Tank stats - Damage dealt while tank was up                                                                                            |\n", bufTankHeader);
    Format(bufTankHeader, CONBUFSIZELARGE, "%s|----------------------|-----------|----------|----------|----------|---------|----------|--------|--------------------------------------|\n", bufTankHeader);
    Format(bufTankHeader, CONBUFSIZELARGE, "%s| Name                 | Damage    | Percent  | Common   | Percent  | SI      | Percent  | Rocked | Pinned                               |\n", bufTankHeader);
    Format(bufTankHeader, CONBUFSIZELARGE, "%s|----------------------|-----------|----------|----------|----------|---------|----------|--------|--------------------------------------|", bufTankHeader);
    Format(bufTank, CONBUFSIZELARGE, "%s", sTankConsoleBuf);
    Format(bufTank, CONBUFSIZELARGE, "%s|----------------------------------------------------------------------------------------------------------------------------------------|\n", bufTank);
    
    // If we're not the only client (I'm assuming) loop through and output.
    if (!client)
    {
        for(new i = 1; i <= MaxClients; i++)
        {
            if(IsClientAndInGame(i))
            {
                //VFormat(buffer, sizeof(buffer), format, 2);
                PrintToConsole(i, bufBasicHeader);
                PrintToConsole(i, bufBasic);
                
                PrintToConsole(i, bufDetailedHeader);
                PrintToConsole(i, bufDetailed);
                
                // If the tank spawned during the round, let's output the tank details (and only if the tank isn't up)
                if (!tankSpawned) 
                {
                    PrintToConsole(i, bufTankHeader);
                    PrintToConsole(i, bufTank);
                }
            }
        }
    } else 
    {
        if(IsClientAndInGame(client))
        {
            PrintToConsole(client, bufBasicHeader);
            PrintToConsole(client, bufBasic);
            
            PrintToConsole(client, bufDetailedHeader);
            PrintToConsole(client, bufDetailed);
            
            // If the tank spawned during the round, let's output the tank details
            if (!tankSpawned)  
            {
                PrintToConsole(client, bufTankHeader);
                PrintToConsole(client, bufTank);
            }
        }
    }
}


/*
*      track damage/kills
*      ==================
*/

public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new zombieClass = 0;
    
    // Victim details
    new victimId = GetEventInt(event, "userid");
    new victim = GetClientOfUserId(victimId);
    
    // Attacker details
    new attackerId = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attackerId);
    
    // Misc details
    new damageDone = GetEventInt(event, "dmg_health");
    
    // no world damage or flukes or whatevs, no bot attackers, no infected-to-infected damage
    if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker))
    {
        // If a survivor is attacking infected
        if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_INFECTED)
        {
            zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
            
            // Increment the damage for that class to the total
            iDidDamageClass[attacker][zombieClass] += damageDone;
            //PrintToConsole(attacker, "Attacked: %d - Dmg: %d", zombieClass, damageDone);
            //PrintToConsole(attacker, "Total damage for %d: %d", zombieClass, iDidDamageClass[attacker][zombieClass]);
            
            // separately store SI and tank damage
            if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
            {
                // If the tank is up, let's store separately
                if (tankSpawned) {
                    siDmgDuringTank[attacker] += damageDone;
                    ttlSiDmgDuringTank += damageDone;
                }
                
                iDidDamage[attacker] += damageDone;
                iDidDamageAll[attacker] += damageDone;
                iTotalDamage += damageDone;
                iTotalDamageAll += damageDone;
            }
            else if (zombieClass == ZC_TANK && damageDone != 5000) // For some reason the last attacker does 5k damage?
            {
                // We want to track tank damage even if we're not factoring it in to our mvp result
                iDidDamageTank[attacker] += damageDone;
                iTotalDamageTank += damageDone;
                
                // If we're factoring it in, include it in our overall damage
                if (bCountTankDamage)
                {
                    iDidDamageAll[attacker] += damageDone;
                    iTotalDamageAll += damageDone;
                }
            }
        }
        
        // Otherwise if friendly fire
        else if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_SURVIVOR && bTrackFF)                // survivor on survivor action == FF
        {
            if (!bRUPActive || GetEntityMoveType(victim) != MOVETYPE_NONE || bPlayerLeftStartArea) {
                // but don't record while frozen in readyup / before leaving saferoom
                iDidFF[attacker] += damageDone;
                iTotalFF += damageDone;
            }
        }
        
        // Otherwise if infected are inflicting damage on a survivor
        else if (GetClientTeam(attacker) == TEAM_INFECTED && GetClientTeam(victim) == TEAM_SURVIVOR) {
            zombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
            
            // If we got hit by a tank, let's see what type of damage it was
            // If it was from a rock throw
            if (tankThrow && zombieClass == ZC_TANK && damageDone == 24) {
                rocksEaten[victim]++;
            }
            damageReceived[victim] += damageDone;
        }
    }
}

/** 
* When the infected are hurt (i.e. when a survivor hurts an SI)
* We want to use this to track damage done to the witch.
*/
public InfectedHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // catch damage done to witch
    new victimEntId = GetEventInt(event, "entityid");
    
    if (IsWitch(victimEntId))
    {
        new attackerId = GetEventInt(event, "attacker");
        new attacker = GetClientOfUserId(attackerId);
        new damageDone = GetEventInt(event, "amount");
        
        // no world damage or flukes or whatevs, no bot attackers
        if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
        {
            // We want to track the witch damage regardless of whether we're counting it in our mvp stat
            iDidDamageWitch[attacker] += damageDone;
            iTotalDamageWitch += damageDone;
            
            // If we're counting witch damage in our mvp stat, lets add the amount of damage done to the witch
            if (bCountWitchDamage) 
            {
                iDidDamageAll[attacker] += damageDone;
                iTotalDamageAll += damageDone;
            }
        }
    }
}

public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get the victim details
    new zombieClass = 0;
    new victimId = GetEventInt(event, "userid");
    new victim = GetClientOfUserId(victimId);
    
    // Get the attacker details
    new attackerId = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attackerId);
    
    // no world kills or flukes or whatevs, no bot attackers
    if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
    {
        zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        
        // only SI, not the tank && only player-attackers
        if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
        {
            // store kill to count for attacker id
            iGotKills[attacker]++;
            iTotalKills++;
        }
    }
    
    /**
    * Are we tracking the tank? 
    * This is a secondary measure. For some reason when I test locally in PM, the
    * tank_killed event is triggered, but when I test in a custom config, it's not.
    * Hopefully this should fix it.
    */
    if (victimId && IsClientAndInGame(victim)) {
        zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (zombieClass == ZC_TANK) {
            tankSpawned = false;
        }
    }
}

// Was the zombie a hunter?
public bool:isHunter(zombieClass) {
    return zombieClass == ZC_HUNTER;
}

public InfectedDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attackerId = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attackerId);
    
    if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
    {
        // If the tank is up, let's store separately
        if (tankSpawned) {
            commonKilledDuringTank[attacker]++;
            ttlCommonKilledDuringTank++;
        }
        
        iGotCommon[attacker]++;
        iTotalCommon++;
        // if victimType > 2, it's an "uncommon" (of some type or other) -- do nothing with this ftpresent.
    }
}



/*
*      MVP string & 'sorting'
*      ======================
*/

String: GetMVPString()
{
    decl String:printBuffer[1024];
    decl String:tmpBuffer[512];
    
    decl String:tmpName[64];
    decl String:mvp_SI_name[64];
    decl String:mvp_Common_name[64];
    decl String:mvp_FF_name[64];
    
    printBuffer = "";
    new mvp_SI = 0;
    new mvp_Common = 0;
    new mvp_FF = 0;
    
    // calculate MVP per category:
    //  1. SI damage & SI kills + damage to tank/witch
    //  2. common kills
    
    // SI MVP
    if (!(iBrevityFlags & BREV_SI))
    {
        mvp_SI = findMVPSI();
        if (mvp_SI > 0)
        {
            // get name from client if connected -- if not, use sClientName array
            if (IsClientConnected(mvp_SI))
            {
                GetClientName(mvp_SI, tmpName, sizeof(tmpName));
                if (IsFakeClient(mvp_SI))
                {
                    StrCat(tmpName, 64, " \x01[BOT]");
                }
            } else {
                strcopy(tmpName, 64, sClientName[mvp_SI]);
            }
            mvp_SI_name = tmpName;
        } else {
            mvp_SI_name = "(nobody)";
        }
    }
    
    // Common MVP
    if (!(iBrevityFlags & BREV_CI))
    {
        mvp_Common = findMVPCommon();
        if (mvp_Common > 0)
        {
            // get name from client if connected -- if not, use sClientName array
            if (IsClientConnected(mvp_Common))
            {
                GetClientName(mvp_Common, tmpName, sizeof(tmpName));
                if (IsFakeClient(mvp_Common))
                {
                    StrCat(tmpName, 64, " \x01[BOT]");
                }
            } else {
                strcopy(tmpName, 64, sClientName[mvp_Common]);
            }
            mvp_Common_name = tmpName;
        } else {
            mvp_Common_name = "(nobody)";
        }
    }
    
    // FF LVP
    if (!(iBrevityFlags & BREV_FF) && bTrackFF)
    {
        mvp_FF = findLVPFF();
        if (mvp_FF > 0)
        {
            // get name from client if connected -- if not, use sClientName array
            if (IsClientConnected(mvp_FF))
            {
                GetClientName(mvp_FF, tmpName, sizeof(tmpName));
                if (IsFakeClient(mvp_FF))
                {
                    StrCat(tmpName, 64, " \x01[BOT]");
                }
            } else {
                strcopy(tmpName, 64, sClientName[mvp_FF]);
            }
            mvp_FF_name = tmpName;
        } else {
            mvp_FF_name = "(nobody)";
        }
    }
    
    // report
    
    if (mvp_SI == 0 && mvp_Common == 0 && !(iBrevityFlags & BREV_SI && iBrevityFlags & BREV_CI))
    {
        Format(tmpBuffer, sizeof(tmpBuffer), "MVP: (not enough action yet)\n");
        StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
    }
    else
    {
        if (!(iBrevityFlags & BREV_SI))
        {
            if (mvp_SI > 0)
            {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] SI:\x03 %s \x01(\x05%d \x01dmg,\x05 %d \x01kills)\n", mvp_SI_name, iDidDamageAll[mvp_SI], iGotKills[mvp_SI]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] SI:\x03 %s \x01(dmg \x04%2.0f%%\x01, kills \x04%.0f%%\x01)\n", mvp_SI_name, (float(iDidDamageAll[mvp_SI]) / float(iTotalDamageAll)) * 100, (float(iGotKills[mvp_SI]) / float(iTotalKills)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] SI:\x03 %s \x01(\x05%d \x01dmg[\x04%.0f%%\x01],\x05 %d \x01kills [\x04%.0f%%\x01])\n", mvp_SI_name, iDidDamageAll[mvp_SI], (float(iDidDamageAll[mvp_SI]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI], (float(iGotKills[mvp_SI]) / float(iTotalKills)) * 100);
                }
                StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
            }
            else
            {
                StrCat(printBuffer, sizeof(printBuffer), "[MVP] SI: \x03(nobody)\x01\n");
            }
        }
        
        if (!(iBrevityFlags & BREV_CI))
        {
            if (mvp_Common > 0)
            {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] CI:\x03 %s \x01(\x05%d \x01common)\n", mvp_Common_name, iGotCommon[mvp_Common]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] CI:\x03 %s \x01(\x04%.0f%%\x01)\n", mvp_Common_name, (float(iGotCommon[mvp_Common]) / float(iTotalCommon)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] CI:\x03 %s \x01(\x05%d \x01common [\x04%.0f%%\x01])\n", mvp_Common_name, iGotCommon[mvp_Common], (float(iGotCommon[mvp_Common]) / float(iTotalCommon)) * 100);
                }
                StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
            }
        }
    }
    
    // FF
    if (!(iBrevityFlags & BREV_FF) && bTrackFF)
    {
        if (mvp_FF == 0)
        {
            Format(tmpBuffer, sizeof(tmpBuffer), "LVP - FF: no friendly fire at all!\n");
            StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
        }
        else
        {
            if (iBrevityFlags & BREV_PERCENT) {
                Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] FF:\x03 %s \x01(\x05%d \x01dmg)\n", mvp_FF_name, iDidFF[mvp_FF]);
            } else if (iBrevityFlags & BREV_ABSOLUTE) {
                Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] FF:\x03 %s \x01(\x04%.0f%%\x01)\n", mvp_FF_name, (float(iDidFF[mvp_FF]) / float(iTotalFF)) * 100);
            } else {
                Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] FF:\x03 %s \x01(\x05%d \x01dmg [\x04%.0f%%\x01])\n", mvp_FF_name, iDidFF[mvp_FF], (float(iDidFF[mvp_FF]) / float(iTotalFF)) * 100);
            }
            StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
        }
    }
    
    
    /**
    * Build the console buffers
    */
    
    // Clear the buffers
    sConsoleBuf = "";
    sDetailedConsoleBuf = "";
    sTankConsoleBuf = "";
    
    // Some constants
    new const max_name_len = 20;
    new const s_len = 15;
    
    // Basic statistics data values
    decl String:name[MAX_NAME_LENGTH];
    decl String:sikills[s_len], String:sidamage[s_len], String:cikills[s_len];
    decl String:siprc[s_len], String:ciprc[s_len];
    decl String:tankdmg[s_len], String:witchdmg[s_len], String:ff[s_len];
    
    // Detailed statistics data values
    decl String:pillUsage[s_len], String:boomPops[s_len], String:dmgReceived[s_len], String:pinned[s_len];
    decl String:tankDmg[s_len], String:hunterDmg[s_len], String:jockeyDmg[s_len], String:chargerDmg[s_len], String:smokerDmg[s_len], String:spitterDmg[s_len], String:boomerDmg[s_len], String:witchDmg[s_len];
    
    // Tank statistics data values
    decl String:siDuringTank[s_len], String:commonDuringTank[s_len], String:dmgToTank[s_len], String:tankPercentage[s_len], String:commonPercent[s_len], String:siPercent[s_len], String:rocksAte[s_len], String:ttlPinned[s_len];
    
    new teamCount = GetConVarInt(hTeamSize);
    new i;  // tmp clientid
    new mpv_done[4];
    new mvp_losers[3];
    
    // Let's iterate through the players
    for (new j = 1; j <= teamCount; j++)
    {
        /*
        try and sort a list by MVP SI; then by MVP CI,
        if neither's available, just walk through the survivors
        */
        if (mvp_SI) {
            switch (j) {
                case 1: { i = mvp_SI; }
                case 2: { i = mvp_losers[j - 2] = findMVPSI(int:mvp_SI); }
                case 3: { i = mvp_losers[j - 2] = findMVPSI(int:mvp_SI, int:mvp_losers[0]); }
                case 4: { i = mvp_losers[j - 2] = findMVPSI(int:mvp_SI, int:mvp_losers[0], int:mvp_losers[1]); }
            }
            if (!i) { i = getSurvivor(mpv_done); }
        } else if (mvp_Common) {
            switch (j) {
                case 1: { i = mvp_Common; }
                case 2: { i = mvp_losers[j - 2] = findMVPCommon(int:mvp_Common); }
                case 3: { i = mvp_losers[j - 2] = findMVPCommon(int:mvp_Common, int:mvp_losers[0]); }
                case 4: { i = mvp_losers[j - 2] = findMVPCommon(int:mvp_Common, int:mvp_losers[0], int:mvp_losers[1]); }
            }
            if (!i) { i = getSurvivor(mpv_done); }
        } else {
            i = getSurvivor(mpv_done);
        }
        
        mpv_done[j - 1] = i;    // track so we can fall back on 'getSurvivor' approach on empty stats
        
        if (IsClientAndInGame(i) && IsClientConnected(i)) {
            GetClientName(i, name, sizeof(name));
            if (IsFakeClient(i)) { StrCat(name, sizeof(name), " [BOT]"); }
        } else {
            strcopy(name, sizeof(name), sClientName[i]);
        }
        stripUnicode(name);
        name = sTmpString;
        name[max_name_len] = 0;                     // terminates name at max length
        
        
        /**
        * Let's output a range of basic statistics
        */
        Format(sidamage,    s_len, "%8d",   iDidDamageAll[i]);
        Format(siprc,       s_len, "%7.1f", (float(iDidDamageAll[i]) / float(iTotalDamageAll)) * 100 );
        Format(sikills,     s_len, "%8d",   iGotKills[i]);
        Format(cikills,     s_len, "%8d",   iGotCommon[i]);
        Format(ciprc,       s_len, "%7.1f", (float(iGotCommon[i]) / float(iTotalCommon)) * 100 );
        Format(tankdmg,     s_len, "%6d",   tankSpawned ? 0 : iDidDamageTank[i]);
        Format(witchdmg,    s_len, "%6d",   iDidDamageWitch[i]);
        Format(ff,          s_len, "%6d",   iDidFF[i]);
        
        // Format the basic stats
        Format(sConsoleBuf, CONBUFSIZE,
        "%s| %20s | %8s | %7s | %8s | %8s | %7s | %6s | %6s | %6s                                   |\n",
        sConsoleBuf, name, sidamage, siprc, sikills, cikills, ciprc, tankdmg, witchdmg, ff
        );
        
        
        /**
        * Let's format the detailed statistics and add it to our console output string.
        */
        Format(tankDmg, s_len, "%6d",   iDidDamageClass[i][ZC_TANK]);
        Format(smokerDmg, s_len, "%8d",   iDidDamageClass[i][ZC_SMOKER]);
        Format(hunterDmg, s_len, "%8d",   iDidDamageClass[i][ZC_HUNTER]);
        Format(chargerDmg, s_len, "%8d",   iDidDamageClass[i][ZC_CHARGER]);
        Format(jockeyDmg, s_len, "%7d",   iDidDamageClass[i][ZC_JOCKEY]);
        Format(spitterDmg, s_len, "%8d",   iDidDamageClass[i][ZC_SPITTER]);
        Format(boomerDmg, s_len, "%7d",   iDidDamageClass[i][ZC_BOOMER]);
        Format(pillUsage, s_len, "%7d", pillsUsed[i]);
        Format(boomPops, s_len, "%5d", boomerPops[i]);
        Format(dmgReceived, s_len, "%8d", damageReceived[i]);
        Format(pinned, s_len, "%8d", totalPinned[i]);
        Format(witchDmg, s_len, "%6d", iDidDamageClass[i][ZC_WITCH]);
        
        Format(sDetailedConsoleBuf, CONBUFSIZE,
        "%s| %20s | %8s | %7s | %8s | %8s | %8s | %7s | %8s | %8s | %7s | %5s           |\n",
        sDetailedConsoleBuf, name, pinned, pillUsage, dmgReceived, smokerDmg, hunterDmg, boomerDmg, spitterDmg, chargerDmg, jockeyDmg, boomPops
        );
        
        /**
        * Let's format our tank statistics
        */
        
        Format(dmgToTank, s_len, "%9d", iDidDamageTank[i]);
        Format(commonDuringTank, s_len, "%8d", commonKilledDuringTank[i]);
        Format(siDuringTank, s_len, "%7d", siDmgDuringTank[i]);
        Format(tankPercentage,  s_len, "%7.1f", (float(iDidDamageTank[i]) / float(iTotalDamageTank)) * 100 );
        Format(commonPercent,  s_len, "%7.1f", (float(commonKilledDuringTank[i]) / float(ttlCommonKilledDuringTank)) * 100 );
        Format(siPercent,  s_len, "%7.1f", (float(siDmgDuringTank[i]) / float(ttlSiDmgDuringTank)) * 100 );
        Format(rocksAte, s_len, "%6d", rocksEaten[i]);
        Format(ttlPinned, s_len, "%6d", ttlPinnedDuringTank[i]);
        
        Format(sTankConsoleBuf, CONBUFSIZE,
        "%s| %20s | %9s | %8s | %8s | %8s | %7s | %8s | %6s | %8s                             | \n",
        sTankConsoleBuf, name, dmgToTank, tankPercentage, commonDuringTank, commonPercent, siDuringTank, siPercent, rocksAte, ttlPinned
        );
        
        //| Name                 | Damage    | Percent  | Common   | Percent  | SI      | Percent  | Rocked | Pinned                             |
        
    }
    
    return printBuffer;
}


findMVPSI(excludeMeA = 0, excludeMeB = 0, excludeMeC = 0)
{
    new i, maxIndex = 0;
    for(i = 1; i < sizeof(iDidDamageAll); i++)
    {
        if(iDidDamageAll[i] > iDidDamageAll[maxIndex]  && i != excludeMeA && i != excludeMeB && i != excludeMeC)
            maxIndex = i;
    }
    return maxIndex;
}

findMVPCommon(excludeMeA = 0, excludeMeB = 0, excludeMeC = 0)
{
    new i, maxIndex = 0;
    for(i = 1; i < sizeof(iGotCommon); i++)
    {
        if(iGotCommon[i] > iGotCommon[maxIndex] && i != excludeMeA && i != excludeMeB && i != excludeMeC)
            maxIndex = i;
    }
    return maxIndex;
}

findLVPFF(excludeMeA = 0, excludeMeB = 0, excludeMeC = 0)
{
    new i, maxIndex = 0;
    for(i = 1; i < sizeof(iDidFF); i++)
    {
        if(iDidFF[i] > iDidFF[maxIndex]  && i != excludeMeA && i != excludeMeB && i != excludeMeC)
            maxIndex = i;
    }
    return maxIndex;
}


/*
*      general functions
*      =================
*/


stock bool:IsClientAndInGame(index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool:IsSurvivor(client)
{
    return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

stock bool:IsInfected(client)
{
    return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

stock bool:IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

stock getSurvivor(exclude[4])
{
    for(new i=1; i <= MaxClients; i++) {
        if (IsSurvivor(i)) {
            new tagged = false;
            // exclude already tagged survs
            for (new j=0; j < 4; j++) {
                if (exclude[j] == i) { tagged = true; }
            }
            if (!tagged) {
                return i;
            }
        }
    }
    return 0;
}

public stripUnicode(String:testString[MAX_NAME_LENGTH])
{
    new const maxlength = MAX_NAME_LENGTH;
    //strcopy(testString, maxlength, sTmpString);
    sTmpString = testString;
    
    new uni=0;
    new currentChar;
    new tmpCharLength = 0;
    //new iReplace[MAX_NAME_LENGTH];      // replace these chars
    
    for (new i=0; i < maxlength - 3 && sTmpString[i] != 0; i++)
    {
        // estimate current character value
        if ((sTmpString[i]&0x80) == 0) // single byte character?
        {
            currentChar=sTmpString[i]; tmpCharLength = 0;
        } else if (((sTmpString[i]&0xE0) == 0xC0) && ((sTmpString[i+1]&0xC0) == 0x80)) // two byte character?
        {
            currentChar=(sTmpString[i++] & 0x1f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i] & 0x3f); 
            tmpCharLength = 1;
        } else if (((sTmpString[i]&0xF0) == 0xE0) && ((sTmpString[i+1]&0xC0) == 0x80) && ((sTmpString[i+2]&0xC0) == 0x80)) // three byte character?
        {
            currentChar=(sTmpString[i++] & 0x0f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i++] & 0x3f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i] & 0x3f);
            tmpCharLength = 2;
        } else if (((sTmpString[i]&0xF8) == 0xF0) && ((sTmpString[i+1]&0xC0) == 0x80) && ((sTmpString[i+2]&0xC0) == 0x80) && ((sTmpString[i+3]&0xC0) == 0x80)) // four byte character?
        {
            currentChar=(sTmpString[i++] & 0x07); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i++] & 0x3f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i++] & 0x3f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i] & 0x3f);
            tmpCharLength = 3;
        } else 
        {
            currentChar=CHARTHRESHOLD + 1; // reaching this may be caused by bug in sourcemod or some kind of bug using by the user - for unicode users I do assume last ...
            tmpCharLength = 0;
        }
        
        // decide if character is allowed
        if (currentChar > CHARTHRESHOLD)
        {
            uni++;
            // replace this character // 95 = _, 32 = space
            for (new j=tmpCharLength; j >= 0; j--) {
                sTmpString[i - j] = 95; 
            }
        }
    }
}

/*
stock bool:IsCommonInfected(iEntity)
{
if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
{
decl String:strClassName[64];
GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
return StrEqual(strClassName, "infected");
}
return false;
}
*/