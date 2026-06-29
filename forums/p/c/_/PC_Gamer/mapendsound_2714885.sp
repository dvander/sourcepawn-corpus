#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define SOUNDWIN "/misc/your_team_won.mp3"
#define SOUNDLOSE "/misc/your_team_lost.mp3"
#define SOUNDSONG "/ui/gamestartup1.mp3"

public Plugin myinfo = 
{
	name = "Map End Sound",
	author = "PC Gamer",
	description = "Plays a win or lose sound when the map ends",
	version = "1.0",
	url = "http://www.alliedmods.net"
};

public void OnPluginStart()
{
	HookEvent("teamplay_win_panel", Event_GameOver);
	HookEvent("arena_win_panel", Event_GameOver);
}

public void OnMapStart()
{
	PrecacheSound(SOUNDWIN);
	PrecacheSound(SOUNDLOSE);
	PrecacheSound(SOUNDSONG);
}

public Action Event_GameOver(Handle event, const char[] name, bool dontBroadcast)
{
	int gameover = GetEventInt(event, "game_over");
	int winningteam = GetEventInt(event, "winning_team");

	if (gameover == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			int playerteam = GetClientTeam(i);
			
			if (!IsFakeClient(i) && IsClientInGame(i) && playerteam == winningteam)
			{
				EmitSoundToClient(i, SOUNDWIN);
				CreateTimer(9.0, Timer_Song, i);				
			}
			
			if (!IsFakeClient(i) && IsClientInGame(i) && playerteam >1 && playerteam != winningteam)
			{
				EmitSoundToClient(i, SOUNDLOSE);
				CreateTimer(9.0, Timer_Song, i);			
			}

			if (!IsFakeClient(i) && IsClientInGame(i) && playerteam <2)
			{
				EmitSoundToClient(i, SOUNDSONG);
			}			
		}
	}
}

public Action Timer_Song(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		EmitSoundToClient(client, SOUNDSONG);
	}
}