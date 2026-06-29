#include <sourcemod.inc>
#include <regex.inc>
#pragma semicolon 1
#define PL_VERSION "1.0.1"

/*
Changelog:

1.1.1 (8/22/10)
Fixed bug with applying bounty increment for surviving the round.

1.1 (8/16/10)
Changed HP award time to player_spawn rather than round_start (this accomodates for Deathmatch servers).
Added admin command to put a bounty on a player.

1.0.1 (8/14/10)
Fixed bug with limit of 0 not being infinity.
Fixed bug with loading bounty specifications from health-bounties.ini
Changed health-bounties.ini specification so that each kill count results in an increment of the specified bounty.

1.0 (8/14/10)
Initial Release

*/

public Plugin:myinfo =
{
    name = "Health Bounty",
    author = "Steell",
    description = "Bounty system where the payout is extra health on the next round.",
    version = PL_VERSION,
    url = "http://madcastgaming.com/"
};

//Array to store the bounties for each player on the server.
new bounties[MAXPLAYERS];

//Array to store the kill streak for each player on the server.
new kill_streaks[MAXPLAYERS];

//Array to store the rewards for each player, to be awarded at the beginning of a round.
new rewards[MAXPLAYERS];

//Determines whether the kill bounties are definied in health_bounties.ini
new bool:using_file = false;

//ADT Array storing the bounties definited in health_bounties.ini
new Handle:file_bounties = INVALID_HANDLE;

/*
 * CVARS
 */
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_bomb = INVALID_HANDLE;
new Handle:cvar_bonus = INVALID_HANDLE;
new Handle:cvar_display = INVALID_HANDLE;
new Handle:cvar_headshot = INVALID_HANDLE;
new Handle:cvar_hostie = INVALID_HANDLE;
new Handle:cvar_kills = INVALID_HANDLE;
new Handle:cvar_round = INVALID_HANDLE;
new Handle:cvar_start = INVALID_HANDLE;
new Handle:cvar_limit = INVALID_HANDLE;
 
/*
 * PLUGIN INITIALIZATION
 */
public OnPluginStart()
{
    CreateConVar(
        "sm_healthbounty_version",
        PL_VERSION,
        "Health Bounty Version",
        FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED
    );
    
    cvar_enabled = CreateConVar(
        "sm_healthbounty",
        "1",
        "Disable or enable the health bounty plugin.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_bomb = CreateConVar(
        "sm_healthbounty_bomb",
        "5",
        "How much the bounty goes up by to the player who planted the bomb if the bomb explodes",
        0, true, 0.0
    );
    
    cvar_bonus = CreateConVar(
        "sm_healthbounty_bonus",
        "10",
        "Health added to player's bounty per kill. Ignored if health_bounties.ini is in use",
        0, true, 0.0
    );
    
    cvar_display = CreateConVar(
        "sm_healthbounty_display",
        "1",
        "1 - Print to chat, 2 - Print to center, 0 - Disable",
        0, true, 0.0, true, 2.0
    );
    
    cvar_headshot = CreateConVar(
        "sm_healthbounty_headshot",
        "5",
        "Headshot bonus - amount of extra health added to the bounty if the bounty is killed by a headshot.",
        0, true, 0.0
    );
    
    cvar_hostie = CreateConVar(
        "sm_healthbounty_hostie",
        "10",
        "How much the bounty should go up by whent he player rescues hostages",
        0, true, 0.0
    );
    
    cvar_kills = CreateConVar(
        "sm_healthbounty_kills",
        "5",
        "Minimum kill streak required before a bounty is placed on a player. Ignored if health_bounties.ini is in use.",
        0, true, 0.0
    );
    
    cvar_round = CreateConVar(
        "sm_healthbounty_round",
        "5",
        "Money to add to the bounty if the player survives the round.",
        0, true, 0.0
    );
    
    cvar_start = CreateConVar(
        "sm_healthbounty_startamount",
        "50",
        "Starting bounty amount once sm_bounty_kills is reached. Ignored if health_bounties.ini is in use.",
        0, true, 0.0
    );
    
    cvar_limit = CreateConVar(
        "sm_healthbounty_limit",
        "0",
        "Highest amount that a bounty can be. 0 = No limit",
        0, true, 0.0
    );
    
    AutoExecConfig();
    
    if (GetConVarBool(cvar_enabled))
        HookEvents();
    
    HookConVarChange(cvar_enabled, ToggleEnabled);
    file_bounties = CreateArray();
    
    RegAdminCmd(
        "sm_healthbounty_set",
        Command_SetBounty, 
        ADMFLAG_KICK, 
        "Sets a bounty on a client."
    );
}

Reset()
{
    ResetArray(bounties, sizeof(bounties));
    ResetArray(kill_streaks, sizeof(kill_streaks));
    ResetArray(rewards, sizeof(rewards));
}

public OnMapStart()
{
    using_file = ReloadFile();
}

public OnMapEnd()
{
    Reset();
}

bool:ReloadFile()
{
    ClearHandleArray(file_bounties);
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/health-bounties.ini");
    new Handle:file = OpenFile(path, "rt");
    if (file == INVALID_HANDLE)
    {
        LogMessage("health-bounties.ini not found.");
        return false;
    }
    
    decl String:line[255];
    decl String:killBuffer[255];
    decl String:bountyBuffer[255];
    new kill, bounty;
    new Handle:trie;
    new Handle:re = CompileRegex("^\\s*(\"[0-9]+\")\\s*(\"[0-9]+\")"); //"
    new lineCounter = 0;
    while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
    {
        if (SimpleRegexMatch(line, "^\\s*[;(//)].*$") > 0 || SimpleRegexMatch(line, "^\\s*$") > 0)
        {
            lineCounter++;
            continue;
        }
        if (SimpleRegexMatch(line, "^\\s*(\"[0-9]+\"\\s*){2}([;(//)].*)?\\s*$") > 0)
        {
            MatchRegex(re, line);
            GetRegexSubString(re, 1, killBuffer, sizeof(killBuffer));
            GetRegexSubString(re, 2, bountyBuffer, sizeof(bountyBuffer));
            StripQuotes(killBuffer);
            StripQuotes(bountyBuffer);
            kill = StringToInt(killBuffer);
            bounty = StringToInt(bountyBuffer);
            
            trie = CreateTrie();
            SetTrieValue(trie, "kills", kill);
            SetTrieValue(trie, "bounty", bounty);
            PushArrayCell(file_bounties, trie);
            
            lineCounter++;
        }
        else
        {
            ClearHandleArray(file_bounties);
            CloseHandle(file);
            CloseHandle(re);
            LogError("File Error: invalid syntax of health-bounties.ini on line %i", lineCounter);
            return false;
        }
    }
    CloseHandle(file);
    CloseHandle(re);
    SortADTArrayCustom(file_bounties, SortBountyArray); 
    return GetArraySize(file_bounties) > 0;
}

public ToggleEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    if (!StrEqual(oldVal, newVal))
    {
        if (StringToInt(newVal) == 1)
            HookEvents();
        else
        {
            Reset();
            UnhookEvents();
        }
    }
}

HookEvents()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("bomb_exploded", Event_BombExploded);
    HookEvent("bomb_defused", Event_BombDefused);
    HookEvent("hostage_rescued", Event_HostageRescued);
    HookEvent("round_end", Event_RoundEnd);
    //HookEvent("round_start", Event_RoundStart);
}

UnhookEvents()
{
    UnhookEvent("player_death", Event_PlayerDeath);
    UnhookEvent("player_spawn", Event_PlayerSpawn);
    UnhookEvent("bomb_exploded", Event_BombExploded);
    UnhookEvent("bomb_defused", Event_BombDefused);
    UnhookEvent("hostage_rescued", Event_HostageRescued);
    UnhookEvent("round_end", Event_RoundEnd);
    //UnhookEvent("round_start", Event_RoundStart);
}

/*
 * EVENTS
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new hsBonus = GetEventBool(event, "headshot") ? GetConVarInt(cvar_headshot) : 0;
    
    if (IsValidKill(attacker, victim))
    {
        kill_streaks[victim] = 0;
        if (bounties[victim] > 0)
        {
            DisplayCollectedMessage(attacker, victim, bounties[victim], hsBonus > 0);
            AddToBounty(victim, hsBonus);
            rewards[attacker] += bounties[victim];
            bounties[victim] = 0;
        }
        
        kill_streaks[attacker]++;
        //PrintToChat(attacker, "Streak: %i", kill_streaks[attacker]);
        UpdateBounty(attacker);
    }
}

public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
    new planter = GetClientOfUserId(GetEventInt(event, "userid"));
    if (bounties[planter] > 0)
    {
        new amt = GetConVarInt(cvar_bomb);
        AddToBounty(planter, amt);
        DisplayBombExplodeMessage(planter, amt);
    }
}

public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
    new defuser = GetClientOfUserId(GetEventInt(event, "userid"));
    if (bounties[defuser] > 0)
    {
        new amt = GetConVarInt(cvar_bomb);
        AddToBounty(defuser, amt);
        DisplayBombDefuseMessage(defuser, amt);
    }
}

public Event_HostageRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
    new rescuer = GetClientOfUserId(GetEventInt(event, "userid"));
    if (bounties[rescuer] > 0)
    {
        new amt = GetConVarInt(cvar_hostie);
        AddToBounty(rescuer, amt);
        DisplayHostieMessage(rescuer, amt);
    }
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new amt = GetConVarInt(cvar_round);
    for (new i = i; i <= MaxClients; i++)
    {
        if (bounties[i] > 0 && IsPlayerAlive(i))
        {
            AddToBounty(i, amt);
            DisplayRoundSurvivalMessage(i, amt);
        }        
    }
}

/*public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 0; i < MaxClients; i++)
    {
        if (rewards[i] > 0 && IsPlayerAlive(i))
        {
            RewardBounty(i, rewards[i]);
            rewards[i] = 0;
        }
    }
}*/

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (rewards[client] > 0)
    {
        RewardBounty(client, rewards[client]);
        rewards[client] = 0;
    }
}

public OnClientDisconnect(client)
{
    bounties[client] = 0;
    kill_streaks[client] = 0;
    rewards[client] = 0;
}

public Action:Command_SetBounty(client, args)
{
    if (args == 0)
    {
        PrintToConsole(client, "Usage: sm_healthbounty_set <name> <amt>");
        return Plugin_Handled;
    }
    decl String:nameBuffer[MAX_NAME_LENGTH];
    GetCmdArg(1, nameBuffer, sizeof(nameBuffer));
    
    new target = -1;
    decl String:other[MAX_NAME_LENGTH];
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            GetClientName(i, other, sizeof(other));
            if (StrEqual(nameBuffer, other))
            {
                target = i;
                break;
            }
        }
    }
    
    if (target == -1)
    {
        PrintToConsole(client, "Could not find any player with the name: \"%s\"", nameBuffer);
        return Plugin_Handled;
    }
    
    decl String:bountyBuffer[64];
    GetCmdArg(2, bountyBuffer, sizeof(bountyBuffer));
    new bounty = StringToInt(bountyBuffer);
    ShowActivity2(client, "[SM]", "Placed a bounty of %i HP on %s's head.", bounty, nameBuffer);
    bounties[target] = StringToInt(bountyBuffer);
    DisplayFirstBountyMessage(target);
    
    return Plugin_Handled;
}



/*
 * DISPLAY UTILITIES
 */
DisplayCollectedMessage(attacker, victim, amt, bonus)
{
    decl String:msg[255];
    decl String:attackerName[MAX_NAME_LENGTH];
    decl String:victimName[MAX_NAME_LENGTH];
    GetClientName(attacker, attackerName, sizeof(attackerName));
    GetClientName(victim, victimName, sizeof(victimName));
    Format(msg, sizeof(msg), "%s has taken %s's bounty of %i HP.", attackerName, victimName, amt);
    DisplayMessage(msg, "");
    if (bonus)
        PrintToChat(attacker, "\x03You received an extra %i HP bonus on your collected bounty for killing %s with a headshot.", GetConVarInt(cvar_headshot), victimName);
}

DisplayBombExplodeMessage(bounty, amt)
{
    DisplayBountyUpdateMessage(bounty, amt, "bomb detonation");
}

DisplayBombDefuseMessage(bounty, amt)
{
    DisplayBountyUpdateMessage(bounty, amt, "defusing the bomb");
}

DisplayHostieMessage(bounty, amt)
{
    DisplayBountyUpdateMessage(bounty, amt, "rescuing a hostage");
}

DisplayRoundSurvivalMessage(bounty, amt)
{
    DisplayBountyUpdateMessage(bounty, amt, "surviving the round");
}

DisplayKillMessage(bounty, amt)
{
    DisplayBountyUpdateMessage(bounty, amt, "kill");
}

DisplayFirstBountyMessage(bounty)
{
    decl String:msg1[255];
    decl String:bountyName[MAX_NAME_LENGTH];
    GetClientName(bounty, bountyName, sizeof(bountyName));
    Format(msg1, sizeof(msg1), "%s has a bounty of %i HP", bountyName, bounties[bounty]);
    DisplayMessage(msg1, "");
}

DisplayBountyUpdateMessage(bounty, amt, const String:reason[])
{
    decl String:msg1[255];
    decl String:msg2[255];
    decl String:bountyName[MAX_NAME_LENGTH];
    GetClientName(bounty, bountyName, sizeof(bountyName));
    Format(msg1, sizeof(msg1), "%s now has a bounty of %i HP", bountyName, bounties[bounty]);
    Format(msg2, sizeof(msg2), " (%i HP awarded for %s)", amt, reason); 
    DisplayMessage(msg1, msg2);
}

DisplayMessage(const String:msg1[], const String:msg2[])
{
    switch (GetConVarInt(cvar_display))
    {
    case 1:
        PrintToChatAll("\x03%s%s", msg1, msg2);
    case 2:
        PrintCenterTextAll(msg1);
    }
}

/*
 * GENERAL UTILITIES
 */
UpdateBounty(attacker)
{
    if (using_file)
    {
        new killCount, bounty, old;
        new Handle:trie;
        for (new i = 0; i < GetArraySize(file_bounties); i++)
        {
            trie = GetArrayCell(file_bounties, i);
            GetTrieValue(trie, "kills", killCount);
            if (kill_streaks[attacker] == killCount)
            {
                GetTrieValue(trie, "bounty", bounty);
                old = bounties[attacker];
                if (old != bounty)
                {
                    //PrintToChat(attacker, "Bounty: %i", bounty);
                    AddToBounty(attacker, bounty);
                    DisplayKillMessage(attacker, bounty);
                }
                break;
            }
        }
    }
    else
    {
        if (bounties[attacker] > 0)
        {
            new amt = GetConVarInt(cvar_bonus);
            AddToBounty(attacker, amt);
            DisplayKillMessage(attacker, amt);
        }
        else if (kill_streaks[attacker] == GetConVarInt(cvar_kills))
        {
            AddToBounty(attacker, GetConVarInt(cvar_start));
            DisplayFirstBountyMessage(attacker);
        }
    }
}

AddToBounty(client, amount)
{
    new limit = GetConVarInt(cvar_limit);
    bounties[client] += amount;
    if (limit > 0 && bounties[client] >= limit)
        bounties[client] = limit;
}

RewardBounty(client, amt)
{
    SetEntityHealth(client, GetClientHealth(client) + amt);
}

IsValidKill(attacker, victim)
{
    return victim != 0 && attacker != 0 && victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker);
}

ClearHandleArray(Handle:arr)
{
    for (new i = 0; i < GetArraySize(arr); i++)
        CloseHandle(GetArrayCell(arr, i));
    ClearArray(arr);
}

ResetArray(any:arr[], size)
{
    for (new i = 0; i < size; i ++)
        arr[i] = 0;
}

public SortBountyArray(index1, index2, Handle:arr, Handle:hndl)
{
    new kill1, kill2;
    GetTrieValue(GetArrayCell(arr, index1), "kills", kill1);
    GetTrieValue(GetArrayCell(arr, index2), "kills", kill2);
    if (kill1 < kill2)
        return -1;
    if (kill1 == kill2)
        return 0;
    else
        return 1;
}

/*PrintArray(Handle:arr)
{
    new Handle:trie = INVALID_HANDLE;
    new kills, bounty;
    for (new i = 0; i < GetArraySize(arr); i++)
    {
        trie = GetArrayCell(arr, i);
        GetTrieValue(trie, "kills", kills);
        GetTrieValue(trie, "bounty", bounty);
        LogMessage("Kills: %i, Bounty: %i", kills, bounty);
    }
}*/