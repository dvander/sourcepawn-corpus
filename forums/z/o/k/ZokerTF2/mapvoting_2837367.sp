#include <sourcemod>
#include <timers>
#include <menus>
#include <halflife>
#include <string>

#define VOTE_TIME_REMAINING 300.0 // 5 minutes before map end
#define VOTE_DURATION 10          // Voting period in seconds (integer)
#define MAX_MAPS 5                // Number of maps to show in vote
#define VOTE_CHECK_INTERVAL 30.0  // How often to check time

new Handle:g_VoteMenu = INVALID_HANDLE;
new String:g_MapChoices[MAX_MAPS][PLATFORM_MAX_PATH];
new String:g_MapCleanNames[MAX_MAPS][PLATFORM_MAX_PATH];
new g_NumChoices = 0;
new bool:g_VoteCalled = false;
new String:g_NextMap[PLATFORM_MAX_PATH];
new bool:g_HasVotedMap = false;
new g_Votes[MAX_MAPS + 1]; // +1 for "extend"
new Handle:g_VoteTimer = INVALID_HANDLE;
new Handle:g_FallbackTimer = INVALID_HANDLE;
new String:g_CurrentMap[PLATFORM_MAX_PATH];
new bool:g_VoteInProgress = false;

void LoadMapCycle()
{
    g_NumChoices = 0;
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));

    char mapcyclePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, mapcyclePath, sizeof(mapcyclePath), "../../cfg/mapcycle.txt");
    Handle file = OpenFile(mapcyclePath, "r");
    if (file == INVALID_HANDLE)
    {
        PrintToServer("[MapVote] Could not open mapcycle.txt!");
        return;
    }

    char line[PLATFORM_MAX_PATH];
    ArrayList maps = CreateArray(PLATFORM_MAX_PATH);

    while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
    {
        TrimString(line);
        if (line[0] != '\0' && line[0] != '/' && line[0] != ';' && !StrEqual(line, g_CurrentMap, false))
        {
            maps.PushString(line);
        }
    }
    CloseHandle(file);

    int totalMaps = maps.Length;
    if (totalMaps == 0)
    {
        PrintToServer("[MapVote] No valid maps found in mapcycle.txt!");
        CloseHandle(maps);
        return;
    }

    for (int i = 0; i < MAX_MAPS && totalMaps > 0; i++)
    {
        int idx = GetRandomInt(0, totalMaps - 1);
        maps.GetString(idx, g_MapChoices[i], sizeof(g_MapChoices[]));

        char cleanName[PLATFORM_MAX_PATH];
        strcopy(cleanName, sizeof(cleanName), g_MapChoices[i]);
        int pos = FindCharInString(cleanName, '_');
        if (pos != -1)
        {
            strcopy(cleanName, sizeof(cleanName), cleanName[pos + 1]);
        }
        else
        {
            strcopy(cleanName, sizeof(cleanName), cleanName);
        }
        strcopy(g_MapCleanNames[i], sizeof(g_MapCleanNames[]), cleanName);

        maps.Erase(idx);
        totalMaps--;
        g_NumChoices++;
    }
    CloseHandle(maps);
}

void ShowVoteMenu()
{
    if (g_NumChoices == 0)
    {
        PrintToServer("[MapVote] No maps to show!");
        return;
    }

    PrintToChatAll("\x04[MapVote] \x01Map voting has started!");

    if (g_VoteMenu != INVALID_HANDLE) CloseHandle(g_VoteMenu);
    g_VoteMenu = CreateMenu(VoteMenuHandler);
    SetMenuTitle(g_VoteMenu, "Vote for the next map:");
    for (int i = 0; i < g_NumChoices; i++)
    {
        AddMenuItem(g_VoteMenu, g_MapChoices[i], g_MapCleanNames[i]);
    }
    AddMenuItem(g_VoteMenu, "extend", "Extend Current Map");
    SetMenuExitButton(g_VoteMenu, false);
    SetMenuPagination(g_VoteMenu, MENU_NO_PAGINATION);
    SetMenuOptionFlags(g_VoteMenu, MENUFLAG_BUTTON_EXIT);

    for (int i = 0; i <= MAX_MAPS; i++)
    {
        g_Votes[i] = 0;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            DisplayMenu(g_VoteMenu, client, VOTE_DURATION);
        }
    }

    if (g_FallbackTimer != INVALID_HANDLE) CloseHandle(g_FallbackTimer);
    g_FallbackTimer = CreateTimer(120.0, Timer_EndVote); // Fallback after 2 mins
    g_VoteInProgress = true;
}

public int VoteMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select && IsClientInGame(client))
    {
        char selection[PLATFORM_MAX_PATH];
        GetMenuItem(menu, param2, selection, sizeof(selection));
        for (int i = 0; i < g_NumChoices; i++)
        {
            if (StrEqual(selection, g_MapChoices[i]))
            {
                g_Votes[i]++;
                if (g_VoteTimer == INVALID_HANDLE) g_VoteTimer = CreateTimer(90.0, Timer_EndVote); // Extend to 90 sec
                return 0;
            }
        }
        if (StrEqual(selection, "extend"))
        {
            g_Votes[g_NumChoices]++;
            if (g_VoteTimer == INVALID_HANDLE) g_VoteTimer = CreateTimer(90.0, Timer_EndVote); // Extend to 90 sec
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    return 0;
}

public Action Timer_EndVote(Handle timer)
{
    if (!g_VoteInProgress) return Plugin_Stop;
    g_VoteInProgress = false;
    if (g_VoteTimer != INVALID_HANDLE) CloseHandle(g_VoteTimer);
    if (g_FallbackTimer != INVALID_HANDLE) CloseHandle(g_FallbackTimer);

    int totalVotes = 0;
    for (int i = 0; i < g_NumChoices + 1; i++)
        totalVotes += g_Votes[i];

    int highestVotes = -1, winnerIndex = -1, tieCount = 0;
    int voteCount[MAX_MAPS + 1];
    for (int i = 0; i < g_NumChoices + 1; i++)
    {
        voteCount[i] = g_Votes[i];
        if (voteCount[i] > highestVotes)
        {
            highestVotes = voteCount[i];
            winnerIndex = i;
            tieCount = 1;
        }
        else if (voteCount[i] == highestVotes)
        {
            tieCount++;
        }
    }

    if (totalVotes == 0)
    {
        PrintToChatAll("\x04[MapVote] \x01No votes were cast. Map will continue as normal.");
        return Plugin_Stop;
    }

    if (tieCount > 1)
    {
        int rand = GetRandomInt(1, tieCount);
        int count = 0;
        for (int i = 0; i < g_NumChoices + 1; i++)
        {
            if (voteCount[i] == highestVotes)
            {
                count++;
                if (count == rand)
                {
                    winnerIndex = i;
                    break;
                }
            }
        }
    }

    if (winnerIndex == g_NumChoices)
    {
        PrintToChatAll("\x04[MapVote] \x01The map has been extended by 10 minutes!");
        ExtendCurrentMap(10);
    }
    else
    {
        g_HasVotedMap = true;
        strcopy(g_NextMap, sizeof(g_NextMap), g_MapChoices[winnerIndex]);

        char capName[PLATFORM_MAX_PATH];
        strcopy(capName, sizeof(capName), g_MapCleanNames[winnerIndex]);
        capName[0] = CharToUpper(capName[0]);
        for (int j = 1; j < strlen(capName); j++) capName[j] = CharToLower(capName[j]);

        float percent = (float(voteCount[winnerIndex]) / float(totalVotes)) * 100.0;
        PrintToChatAll("\x04[MapVote] \x01%s won with %.0f%% of the vote!", capName, percent);
    }

    return Plugin_Stop;
}

void ExtendCurrentMap(int minutes)
{
    Handle cvar = FindConVar("mp_timelimit");
    if (cvar != INVALID_HANDLE)
        SetConVarInt(cvar, GetConVarInt(cvar) + minutes);
}

public void OnMapEnd()
{
    if (g_HasVotedMap)
    {
        ForceChangeLevel(g_NextMap, "Vote Result");
        g_HasVotedMap = false;
        g_NextMap[0] = '\0';
    }
}

public Action Timer_CheckTime(Handle timer)
{
    if (g_VoteCalled) return Plugin_Stop;

    int timeleft;
    GetMapTimeLeft(timeleft);
    if (timeleft > 0 && timeleft <= VOTE_TIME_REMAINING)
    {
        g_VoteCalled = true;
        ShowVoteMenu();
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void OnMapStart()
{
    LoadMapCycle();
    g_VoteCalled = false;
    g_HasVotedMap = false;
    g_NextMap[0] = '\0';
    g_VoteInProgress = false;

    if (g_VoteTimer != INVALID_HANDLE) CloseHandle(g_VoteTimer);
    if (g_FallbackTimer != INVALID_HANDLE) CloseHandle(g_FallbackTimer);
    CreateTimer(VOTE_CHECK_INTERVAL, Timer_CheckTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnPluginEnd()
{
    if (g_VoteMenu != INVALID_HANDLE) CloseHandle(g_VoteMenu);
    if (g_VoteTimer != INVALID_HANDLE) CloseHandle(g_VoteTimer);
    if (g_FallbackTimer != INVALID_HANDLE) CloseHandle(g_FallbackTimer);
}