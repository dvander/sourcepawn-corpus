#include <sourcemod>
#include <timers>
#include <menus>
#include <halflife>
#include <string>

#define VOTE_TIME_REMAINING 300.0 // 5 minutes before map end
#define VOTE_DURATION 45          // Voting result delay
#define MAX_MAPS 5
#define VOTE_CHECK_INTERVAL 30.0

new Handle:g_VoteMenu = INVALID_HANDLE;
new String:g_MapChoices[MAX_MAPS][PLATFORM_MAX_PATH];
new String:g_MapCleanNames[MAX_MAPS][PLATFORM_MAX_PATH];
new g_NumChoices = 0;
new bool:g_VoteCalled = false;
new String:g_NextMap[PLATFORM_MAX_PATH];
new g_Votes[MAX_MAPS + 1]; // +1 for extend
new Handle:g_VoteTimer = INVALID_HANDLE;
new String:g_CurrentMap[PLATFORM_MAX_PATH];

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
        if (cleanName[0] >= 'a' && cleanName[0] <= 'z')
        {
            cleanName[0] = cleanName[0] - ('a' - 'A');
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

    if (g_VoteMenu != INVALID_HANDLE && IsValidHandle(g_VoteMenu))
    {
        CloseHandle(g_VoteMenu);
        g_VoteMenu = INVALID_HANDLE;
    }

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

    if (g_VoteTimer != INVALID_HANDLE && IsValidHandle(g_VoteTimer))
    {
        CloseHandle(g_VoteTimer);
        g_VoteTimer = INVALID_HANDLE;
    }
    g_VoteTimer = CreateTimer(float(VOTE_DURATION), Timer_EndVote);
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
                return 0;
            }
        }
        if (StrEqual(selection, "extend"))
        {
            g_Votes[g_NumChoices]++;
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
    g_VoteTimer = INVALID_HANDLE;

    int highestVotes = -1, winnerIndex = -1, tieCount = 0, totalVotes = 0;
    int voteCount[MAX_MAPS + 1];

    for (int i = 0; i < g_NumChoices + 1; i++)
    {
        voteCount[i] = g_Votes[i];
        totalVotes += voteCount[i];
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
        return Plugin_Stop;
    }

    strcopy(g_NextMap, sizeof(g_NextMap), g_MapChoices[winnerIndex]);

    // Build results string
    int sorted[MAX_MAPS + 1];
    for (int i = 0; i < g_NumChoices; i++) sorted[i] = i;

    // Sort top 3 with votes
    for (int i = 0; i < g_NumChoices - 1; i++)
    {
        for (int j = i + 1; j < g_NumChoices; j++)
        {
            if (g_Votes[sorted[j]] > g_Votes[sorted[i]])
            {
                int tmp = sorted[i];
                sorted[i] = sorted[j];
                sorted[j] = tmp;
            }
        }
    }

    PrintToChatAll("\x04[MapVote] \x01Next map is %s", g_MapCleanNames[winnerIndex]);

    int shown = 0;
    for (int i = 0; i < g_NumChoices && shown < 3; i++)
    {
        int idx = sorted[i];
        if (g_Votes[idx] > 0)
        {
            float perc = float(g_Votes[idx]) / float(totalVotes) * 100.0;
            PrintToChatAll("[%.0f%%] %s", perc, g_MapCleanNames[idx]);
            shown++;
        }
    }

    return Plugin_Stop;
}

void ExtendCurrentMap(int minutes)
{
    Handle cvar = FindConVar("mp_timelimit");
    if (cvar != INVALID_HANDLE)
    {
        SetConVarInt(cvar, GetConVarInt(cvar) + minutes);
    }
}

public void OnMapEnd()
{
    if (g_NextMap[0] != '\0')
    {
        ForceChangeLevel(g_NextMap, "Vote Result");
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
    g_NextMap[0] = '\0';

    if (g_VoteMenu != INVALID_HANDLE && IsValidHandle(g_VoteMenu))
    {
        CloseHandle(g_VoteMenu);
        g_VoteMenu = INVALID_HANDLE;
    }

    if (g_VoteTimer != INVALID_HANDLE && IsValidHandle(g_VoteTimer))
    {
        CloseHandle(g_VoteTimer);
        g_VoteTimer = INVALID_HANDLE;
    }

    CreateTimer(VOTE_CHECK_INTERVAL, Timer_CheckTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnPluginEnd()
{
    if (g_VoteMenu != INVALID_HANDLE && IsValidHandle(g_VoteMenu))
    {
        CloseHandle(g_VoteMenu);
    }
    if (g_VoteTimer != INVALID_HANDLE && IsValidHandle(g_VoteTimer))
    {
        CloseHandle(g_VoteTimer);
    }
}
