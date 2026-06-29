int TEAM_RED = 2;
int TEAM_BLUE = 3;

ConVar g_cUnbalanceLimit;

public Plugin myinfo =
{
    name = "[TF2] Stuck in spectate fix",
    author = "Fraeven and Rowedahelicon",
    description = "Corrects unassigned/spectate glitch when players join a team simultaneously",
    version = "1.0",
    url = "https://www.scg.wtf"
}

public void OnPluginStart()
{
    AddCommandListener(Command_JoinTeam, "jointeam");
    g_cUnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
}

public Action Command_JoinTeam(int client, const char[] command, int argc)
{
    if (GetConVarInt(g_cUnbalanceLimit) == 0)
    {
        return Plugin_Continue;
    }

    char new_team_string[64];
    GetCmdArg(1, new_team_string, 64);

    int new_team;
    if (StrEqual(new_team_string, "red", false))
    {
        new_team = TEAM_RED;
    }
    else if (StrEqual(new_team_string, "blue", false))
    {
        new_team = TEAM_BLUE;
    }
    else
    {
        return Plugin_Continue;
    }

    if (TeamsWouldBeUnbalanced(client, new_team))
    {
        //PrintToServer("Teams would be unbalanced, stopping jointeam %s for %N", new_team_string, client);
        ShowVGUIPanel(client, "team", _, true);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public bool TeamsWouldBeUnbalanced(int client, int new_team)
{
    int red_count, blue_count = 0;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!IsClientInGame(c)) {
            continue;
        }

        // Count the team for the current player as the team they're attempting to join
        if (c == client)
        {
            if (new_team == TEAM_RED)
            {
                red_count++;
            }
            else if (new_team == TEAM_BLUE)
            {
                blue_count++;
            }
        }
        else
        {
            if (GetClientTeam(c) == TEAM_RED)
            {
                red_count++;
            }
            else if (GetClientTeam(c) == TEAM_BLUE)
            {
                blue_count++;
            }
        }
    }

    int difference = new_team == TEAM_RED ? red_count - blue_count : blue_count - red_count;
    return difference > GetConVarInt(g_cUnbalanceLimit);
}