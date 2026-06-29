#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <multicolors>

bool g_bMatchStarted;

public Plugin myinfo = 
{
    name = "Competitive Handler",
    author = "Armin",
    description = "A Plugin that executes configs.",
    version = "1.0",
    url = "http://nerp.cf/"
};

public void OnPluginStart()
{
    AddCommandListener(OnJoinTeam, "jointeam");
}

public void OnMapStart()
{
	g_bMatchStarted = false;
	CreateTimer( 0.1, Timer_DrawText, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

public Action OnJoinTeam(int client, const char[] command, int numArgs)
{
    if (!IsClientInGame(client) || numArgs < 1) return Plugin_Continue;

    if (GetAlivePlayersTeamCount(CS_TEAM_T) == 5 && GetAlivePlayersTeamCount(CS_TEAM_CT) == 5)
	{
		ServerCommand("mp_restartgame 1");
		ServerCommand("mp_warmup_pausetimer 0");
		ServerCommand("mp_warmup_end");
		ServerCommand("exec sourcemod/comp/live.cfg");
		
		g_bMatchStarted = true;
    }

    return Plugin_Continue;
}

int GetAlivePlayersTeamCount(int team)
{
    int iCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (GetClientTeam(i) != team)
            continue;

        iCount++;
    }

    return iCount;
}

public Action Timer_DrawText( Handle timer )
{
	int currPlayers = GetAlivePlayersTeamCount( CS_TEAM_CT ) + GetAlivePlayersTeamCount( CS_TEAM_T );
	int total = 10;
	
	char buffer[256];
	Format( buffer, sizeof( buffer ), "\t<font size='22'>Welcome to <font color='#FF0000'>YourServer!</font></font>\n" );
	Format( buffer, sizeof( buffer ), "%s\t<font size='20'><font color='#FF0000'>%i</font>/<font color='#00FF00'>%i</font> Players connected.\n", buffer, currPlayers, total );
	
	PrintHintTextToAll( buffer );
	
	if( g_bMatchStarted )
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}