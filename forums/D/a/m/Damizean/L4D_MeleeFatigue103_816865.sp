/* ========================================================
 * L4D Melee Fatigue
 * ========================================================
 *
 * Created by Damizean
 * --------------------------------------------------------
 *
 * This plugin forces the game to reset the melee fatigue 
 * penalty whenever a melee hit lands upon another player and
 * or an entity, effectively disabling melee fatigue.
 * 
 * The segment of code for vote management is extracted from the
 * [Rebellious Spanish!] Server plugin (RSS) created by me, and
 * based upon DDRKhat's code for vote management.
 */

// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1            // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// Constants to determine the current poll status. If a poll is running, you shouldn't
// come here.
enum Vote_States
{
    VOTE_START    = 0,
    VOTE_YES      = 1,
    VOTE_NO       = 2,
    VOTE_PASSED   = 3,
    VOTE_FAILED   = 4,
    VOTE_APPLY    = 5
};

// Variables that define wich team can vote. This is used to determine the potential
// clients.
#define VOTE_EVERYONE    1
#define VOTE_SURVIVOR    2
#define VOTE_INFECTED    3

// Other stuff
#define VOTE_TIMER_END       0
#define VOTE_TIMER_APPLY     1

// *********************************************************************************
// VARS
// *********************************************************************************
new Handle:Melee_EnableCvar     = INVALID_HANDLE;
new Handle:Melee_GameModeCvar   = INVALID_HANDLE;
new bool:Melee_Enabled          = false;
new Melee_PreviousState         = -1;
new Melee_FatigueVarOffset      = 0;
new Melee_Iterator              = 0;

new Handle:Vote_MeleeVoteCvar   = INVALID_HANDLE;
new Vote_MeleeVoteState         = -1;
new bool:Vote_Enabled           = false;
new bool:Vote_InProgress        = false;
new bool:Vote_AllowVote         = false;
new bool:Vote_Custom            = false;
new Handle:Vote_Timer           = INVALID_HANDLE;
new Vote_Clients[8];
new Vote_PotentialClients       = 0;
new Vote_ResultsYes             = 0;
new Vote_ResultsNo              = 0;
new Vote_Results                = 0;
new Function:Vote_Callback;
new String:Vote_Issue[128];
new String:Vote_Positive[128];

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = "L4D Melee Fatigue",
    author      = "Damizean",
    description = "Plugin to enable/disable melee fatigue on L4D game servers.",
    version     = "1.0.3",
    url         = "elgigantedeyeso@gmail.com"
};

// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ GAME EVENTS ]====================================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
// Upon plugin start, create the proper con-vars to be able to control
// the melee fatigue of the game.
// ------------------------------------------------------------------------
public OnPluginStart()
{
    decl String:strModName[50]; GetGameFolderName(strModName, sizeof(strModName));
    if(!StrEqual(strModName, "left4dead", false)) SetFailState("This plugin is Left 4 Dead only. It won't work on other games.");
    
    // Crate the melee controller cvar and find the game mode cvar.
    Melee_EnableCvar   = CreateConVar("sm_l4d_meleefatigue",      "0", "Enables/disables Melee Fatigue (0 - Disabled / 1 - Enabled)", FCVAR_PLUGIN);
    Vote_MeleeVoteCvar = CreateConVar("sm_l4d_meleefatigue_vote", "0", "Enables/disables users to disable the fatigue (0 - Disabled / 1 - Enabled)", FCVAR_PLUGIN);
    Melee_GameModeCvar = FindConVar("mp_gamemode");
    
    // Hook the cvars.
    HookConVarChange(Melee_EnableCvar,   Melee_ManageCvars);
    HookConVarChange(Melee_GameModeCvar, Melee_ManageCvars);
    
    // Determine the melee fatigue variable offset
    Melee_FatigueVarOffset = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
    
    // Hook console commands that control the vote management.
    RegConsoleCmd("callvote", Vote_CallVote);
    RegConsoleCmd("vote",     Vote_Vote);
    
    // Hook all vote events to the proper callback handles
    HookEvent("vote_started", Vote_Event_Start, EventHookMode_PostNoCopy);
    HookEvent("vote_ended",   Vote_Event_End, EventHookMode_PostNoCopy);
    HookEvent("vote_passed",  Vote_Event_End, EventHookMode_PostNoCopy);
    HookEvent("vote_failed",  Vote_Event_End, EventHookMode_PostNoCopy);
    
    // Autoexec config
    AutoExecConfig(true, "L4D_MeleeFatigue");
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
// Whenever the configuration file has been executed, re-hook the events.
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
    // If the configuration changed to something else than the default
    if (Melee_PreviousState != -1) SetConVarInt(Melee_EnableCvar, Melee_PreviousState);
    if (Vote_MeleeVoteState != -1) SetConVarInt(Vote_MeleeVoteCvar, Vote_MeleeVoteState);
    
    // Determine the game mode and check if it's worthy to activate.
    if (GetConVarInt(Melee_EnableCvar) == 0 && Melee_GameMode() == 1)
        Melee_Enabled = true;
}

// ------------------------------------------------------------------------
// OnMapStart()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public OnMapStart()
{
    // Once the map starts, players are able to start votes
    // again.
    Vote_Enabled = true;
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// Store the current value to use on next map change.
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Disable melee on map end and retrieve the enabled value for next map.
    Melee_Enabled = false;
    Melee_PreviousState = GetConVarInt(Melee_EnableCvar);
    
    // Disable the vote manager so no possible vote is able to be called and
    // retrieve the current state.
    Vote_Enabled = false;
    Vote_MeleeVoteState = GetConVarInt(Vote_MeleeVoteCvar);
    
    // If there was one in process, make sure to shut down
    // the timer so it isn't fired.
    if (Vote_InProgress == true && Vote_Custom == true && Vote_Timer != INVALID_HANDLE)
        KillTimer(Vote_Timer);
    Vote_Timer = INVALID_HANDLE;
    
    // Reset all other values
    Vote_InProgress = false;
    Vote_Custom     = false;
    Vote_AllowVote  = false;
    Vote_ResultsYes = 0;
    Vote_ResultsNo  = 0;
    Vote_Results    = 0;
}

// ------------------------------------------------------------------------
// OnGameFrame()
// ------------------------------------------------------------------------
// Not exactly the best idea, but seeing no melee event is fired while missing
// this seems to be the last resort.
// ------------------------------------------------------------------------
public OnGameFrame()
{
    if (Melee_Enabled == false) return;
    
    // Iterate through all the clients
    for (Melee_Iterator=1; Melee_Iterator<=MaxClients; Melee_Iterator++) {
        // If it's not connected, not on the survivor team or not alive, skip.
        if (!IsClientInGame(Melee_Iterator))    continue;
        if (!IsPlayerAlive(Melee_Iterator))     continue;
        if (GetClientTeam(Melee_Iterator) != 2) continue;        
        
        // Once alive, if the player is using the melee, reset
        // the fatigue.
        if (GetClientButtons(Melee_Iterator) & IN_ATTACK2)
            SetEntData(Melee_Iterator, Melee_FatigueVarOffset, 0, 4);
    }
}

// ------------------------------------------------------------------------
// Melee_ManageCvars()
// ------------------------------------------------------------------------
// This method manages the cvars and hooks/unhooks the events as they're
// needed by the game mode.
// ------------------------------------------------------------------------
public Melee_ManageCvars(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    // Determine if it's worthy to enable on this game mode.
    if (GetConVarInt(Melee_EnableCvar) == 0 && Melee_GameMode() == 1)
        Melee_Enabled = true;
    else
        Melee_Enabled = false;
}

// ------------------------------------------------------------------------
// Melee_GameMode()
// ------------------------------------------------------------------------
// This method determines the current game mode, and whenever the melee
// fatigue control really needs to be hooked.
// ------------------------------------------------------------------------
public Melee_GameMode()
{
    // Retrieve game mode
    new String:strGameMode[16]; GetConVarString(Melee_GameModeCvar, strGameMode, sizeof(strGameMode));
    
    // Determine if it's worthy to hook the melee events.
    if (StrEqual(strGameMode, "coop")) return 0;
    return 1;
}

// ------------------------------------------------------------------------
// Vote_Create()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public bool:Vote_Create(Client, Team, const String:strIssue[], const String:strResultsIfPositive[], Function:Callback)
{
    // If the vote is still disabled or there's one already in course, exit.
    if (Vote_Enabled == false)   return false;
    if (Vote_InProgress == true) return false;

    // Startup the vote manager
    Vote_InProgress = true;
    Vote_Custom     = true;
    Vote_AllowVote  = false;
    Vote_ResultsYes = 0;
    Vote_ResultsNo  = 0;
    Vote_Results    = 0;
    
    // Configure the potential clients to vote
    Vote_PotentialClients = 0;
    for (new i=1; i<=MaxClients; i++) {
        // Determine if it's a potential client
        if (!IsClientConnected(i)) continue;
        if (!IsClientInGame(i)) continue;
        if (IsFakeClient(i)) continue;
        if (Team == VOTE_SURVIVOR && GetClientTeam(i) != 2) continue;
        if (Team == VOTE_INFECTED && GetClientTeam(i) != 3) continue;
        
        // It is a potential client, add the client ID onto the list.
        Vote_Clients[Vote_PotentialClients] = i;
        Vote_PotentialClients++;
    }

    // Retrieve the callback and the messages
    Vote_Callback = Callback;
    strcopy(Vote_Issue, sizeof(Vote_Issue), strIssue);
    strcopy(Vote_Positive, sizeof(Vote_Positive), strResultsIfPositive);

    // Done. Fire vote start event with the vote settings and update the
    // parameters.
    new Handle:hEvent = CreateEvent("vote_started");
    SetEventString(hEvent, "issue", "#L4D_TargetID_Player");
    SetEventString(hEvent, "param1", Vote_Issue);
    SetEventInt(hEvent, "team", 0);
    SetEventInt(hEvent, "initiator", 0);
    FireEvent(hEvent);
    Vote_Update();

    // Create timer to finish the vote in case the vote hasn't ended.
    Vote_Timer = CreateTimer(20.0, Vote_TimerTick, VOTE_TIMER_END);
    
    // Let the callback know it's started, in case it wants to do something.
    Call_StartFunction(INVALID_HANDLE, Vote_Callback);
    Call_PushCell(VOTE_START);
    Call_PushCell(0);
    Call_Finish();

    // Allow players to vote from this point onwards and we're done.
    Vote_AllowVote = true;
    if (Client != 0) FakeClientCommand(Client, "vote Yes");
    return true;
}

// ------------------------------------------------------------------------
// Vote_Update()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Vote_Update()
{
    // Update the votes
    new Handle:hEvent = CreateEvent("vote_changed");
    SetEventInt(hEvent,"yesVotes", Vote_ResultsYes);
    SetEventInt(hEvent,"noVotes", Vote_ResultsNo);
    SetEventInt(hEvent,"potentialVotes", Vote_PotentialClients);
    FireEvent(hEvent);

    // Check if the votes ended
    if ((Vote_ResultsYes+Vote_ResultsNo) == Vote_PotentialClients) Vote_End();
}


// ------------------------------------------------------------------------
// Vote_End()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Vote_End()
{
    // At this point, player isn't allowed to vote anymore.
    Vote_AllowVote = false;
    
    // Destroy the vote timer in case it hasn't ticked before the end of the
    // vote was fired.
    if (Vote_Timer != INVALID_HANDLE)
        KillTimer(Vote_Timer);

    // Determine the results
    Vote_Results = Vote_ResultsYes-Vote_ResultsNo;
    
    // Fire and event to show if the vote succeeded or not.
    new Handle:hEvent;
    if (Vote_Results)
    {   
        // Fire the vote passed event
        hEvent = CreateEvent("vote_passed");
        SetEventString(hEvent,"details", "#L4D_TargetID_Player");
        SetEventString(hEvent,"param1", Vote_Positive);
        SetEventInt(hEvent,"team",0);
        FireEvent(hEvent);
        
        // Tell the callback the vote passed
        Call_StartFunction(INVALID_HANDLE, Vote_Callback);
        Call_PushCell(VOTE_PASSED);
        Call_PushCell(Vote_Results);
        Call_Finish();
    }
    else
    {
        // Fire the vote failed event
        hEvent = CreateEvent("vote_failed");
        SetEventInt(hEvent,"team",0);
        FireEvent(hEvent);
        
        // Tell the callback the vote failed.
        Call_StartFunction(INVALID_HANDLE, Vote_Callback);
        Call_PushCell(VOTE_FAILED);
        Call_PushCell(Vote_Results);
        Call_Finish();
    }
}


// ------------------------------------------------------------------------
// Vote_TimerTick()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Action:Vote_TimerTick(Handle:hTimer, any:Value)
{
    // On the timer tick, reset the handle to the timer so
    // the other methods won't kill the wrong timer.
    Vote_Timer = INVALID_HANDLE;
    
    // Depending on the given value, perform an action or another:
    switch(Value)
    {
        case VOTE_TIMER_END:
        {
            Vote_End();
        }
        case VOTE_TIMER_APPLY:
        {
            // In case it's not a custom vote, don't summon
            // the callback
            if (Vote_Custom == true)
            {
                // Tell the callback it can finally apply the changes
                Call_StartFunction(INVALID_HANDLE, Vote_Callback);
                Call_PushCell(VOTE_APPLY);
                Call_PushCell(Vote_Results);
                Call_Finish();
            }

            // Reset all the values.
            Vote_InProgress = false;
            Vote_Custom     = false;
            Vote_AllowVote  = false;
            Vote_ResultsYes = 0;
            Vote_ResultsNo  = 0;
            Vote_Results    = 0;
        }
    }
}


// ------------------------------------------------------------------------
// Vote_CallVote()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Action:Vote_CallVote(Client, Args)
{
    // If there's a vote in progress, or it's forbidden to
    // start a vote, ignore.
    if (Vote_Enabled == false) return Plugin_Handled;
    if (Vote_InProgress == true) return Plugin_Handled;
    
    // Determine if the player wants to vote the status of the
    // melee fatigue.
    if (GetConVarInt(Vote_MeleeVoteCvar) == 1)
    {
        new String:strArgument[64]; GetCmdArg(1, strArgument, sizeof(strArgument));
        
        // Determine what the user wants to vote.
        if (StrEqual(strArgument, "EnableMeleeFatigue", false))
        {
            Vote_Create(Client, VOTE_EVERYONE, "Enable melee fatigue?", "Enabling melee fatigue...", Vote_EnableMeleeFatigue);
            return Plugin_Handled;
        } else if (StrEqual(strArgument, "DisableMeleeFatigue", false)) {
            Vote_Create(Client, VOTE_EVERYONE, "Disable melee fatigue?", "Disabling melee fatigue...", Vote_DisableMeleeFatigue);
            return Plugin_Handled;
        }
    }
    
    // Keep with the native.
    return Plugin_Continue;
}


// ------------------------------------------------------------------------
// Vote_Vote()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Action:Vote_Vote(Client, Args)
{
    // In case the player is voting on a custom poll process,
    // manually response to the poll system with their input.
    if (Vote_InProgress == true && Vote_Custom == true)
    {
        // In case the player isn't allowed to cast a vote, ignore.
        if (Vote_AllowVote == false) return Plugin_Handled;
        
        // If the client voted already, don't count his vote.
        new bool:VotedAlready = true;
        for (new i=0; i<Vote_PotentialClients; i++)
            if (Vote_Clients[i] == Client) 
            {
                Vote_Clients[i] = 0;
                VotedAlready = false;
                break;
            }
        if (VotedAlready == true) return Plugin_Handled;

        // If not, get the vote casted by the player and fire
        // the proper event.
        new String:strArgument[8]; GetCmdArg(1, strArgument, 8);

        if (StrEqual(strArgument,"Yes",true) == true)
        {
            // Fire a "yes" vote event.
            new Handle:hEvent = CreateEvent("vote_cast_yes");
            SetEventInt(hEvent,"team", 0);
            SetEventInt(hEvent,"entityid", 0);
            FireEvent(hEvent);
            
            // Update the counter
            Vote_ResultsYes++;
        }
        else
        {
            // Fire a "no" vote event.
            new Handle:hEvent = CreateEvent("vote_cast_no");
            SetEventInt(hEvent,"team", 0);
            SetEventInt(hEvent,"entityid", 0);
            FireEvent(hEvent);
            
            // Update the counter
            Vote_ResultsNo++;
        }
        
        // Done, update the settings of the vote and determine if 
        // the vote finished,
        Vote_Update();
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Vote_Event_Start()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Action:Vote_Event_Start(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    // If it's a native vote, activate the in progress flag.
    Vote_InProgress = true;

    // Continue with the event..
    return Plugin_Continue;
}


// ------------------------------------------------------------------------
// Vote_Event_End()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Action:Vote_Event_End(Handle:hEvent, const String:name[], bool:dontBroadcast)
{    
    // Create a timer to execute the callback with the given results (in case
    // it's a custom vote) and clean the variables afterwards.
    Vote_Timer = CreateTimer(5.0, Vote_TimerTick, VOTE_TIMER_APPLY);
}

// ------------------------------------------------------------------------
// Vote_EnableMeleeFatigue()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Vote_EnableMeleeFatigue(Vote_States:State, Param)
{
    if (State == VOTE_APPLY)
    {
        // If the vote wasn't successful, exit.
        if (!Param) return;
        
        // Change the convar.
        SetConVarInt(Melee_EnableCvar, 1);
    }
}

// ------------------------------------------------------------------------
// Vote_DisableMeleeFatigue()
// ------------------------------------------------------------------------
// <Description>
// ------------------------------------------------------------------------
public Vote_DisableMeleeFatigue(Vote_States:State, Param)
{
    if (State == VOTE_APPLY)
    {
        // If the vote wasn't successful, exit.
        if (!Param) return;
        
        // Execute the given command.
        SetConVarInt(Melee_EnableCvar, 0);
    }
}