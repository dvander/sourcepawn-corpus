#include <sourcemod>
#include <cstrike>

#define GAME_HL2MP 	1
#define GAME_CSS	2
#define GAME_CSGO	3
#define	GAME_DODS	4
#define	GAME_TF2	5

enum Cvars
{
	Handle:Spectator,
	Handle:Team2,
	Handle:Team3
};
new g_Cvars[Cvars];

enum Status
{
	bool:Spectator,
	bool:Team2,
	bool:Team3
};
new g_Status[Status];

new pGame;

public Plugin:myinfo =
{
	name = "Block Team Chat",
	author = "Sidezz",
	description = "Disable a/many teams text chat",
	version = "1.0",
	url = "www.coldcommunity.com"
}

public OnPluginStart()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "hl2mp", false))
		pGame = GAME_HL2MP;
	else if(StrEqual(game, "cstrike", false))
		pGame = GAME_CSS;
	else if(StrEqual(game, "csgo", false))
		pGame = GAME_CSGO;
	else if(StrContains(game, "dod", false) != -1)
		pGame = GAME_DODS;
	else if(StrContains(game, "tf", false) != -1)
		pGame = GAME_TF2;
		

	g_Cvars[Spectator] = CreateConVar("sm_spectatorchat_disabled", "0", "Disable text chat from spectators");
	g_Cvars[Team2] = CreateConVar("sm_team2_disabled", "0", "Disable text chat from spectators");
	g_Cvars[Team3] = CreateConVar("sm_team3_disabled", "0", "Disable text chat from spectators");

	HookConVarChange(g_Cvars[Spectator], onConfigChanged);
	HookConVarChange(g_Cvars[Team2], onConfigChanged);
	HookConVarChange(g_Cvars[Team3], onConfigChanged);

	AddCommandListener(blockTeamChat, "say");
	AddCommandListener(blockTeamChat, "say_team");
}

public onConfigChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	cvarConfig();
}

cvarConfig()
{
	g_Status[Spectator] = GetConVarBool(g_Cvars[Spectator]);
	g_Status[Team2] = GetConVarBool(g_Cvars[Team2]);
	g_Status[Team3] = GetConVarBool(g_Cvars[Team3]);
}

public Action:blockTeamChat(client, const String:command[], argc)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		if(!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			if(GetClientTeam(client) <= 1)
			{
				//Block Text:
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
} 