#pragma semicolon 1

#undef MAXPLAYERS
#define MAXPLAYERS	8

enum
{
	S_Deaths,
	S_Frags,

	S_Total
};

StringMap
	g_hScore;
bool
	g_bKPoD;
int
	g_iScore[S_Total];
char
	g_sSteamID[MAXPLAYERS+1][64];	// https://github.com/alliedmodders/sourcemod/pull/1696

public Plugin myinfo =
{
	name		= "Scoreboard Tweaks",
	version		= "1.1.0 (rewritten by Grey83)",
	description	= "Remembers scores for reconnecting players and resets them on a new round",
	author		= "Dysphie",
	url			= "https://forums.alliedmods.net/showthread.php?t=340780"
}

public void OnPluginStart()
{
	ConVar cvar = FindConVar("sv_kill_player_on_disconnect");
	if(cvar)
	{
		cvar.AddChangeHook(CVarChange);
		g_bKPoD = cvar.BoolValue;
	}

	g_hScore = new StringMap();

	HookEvent("nmrih_reset_map", Event_MapReset, EventHookMode_Pre);

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		GetClientAuthId(i, AuthId_Steam2, g_sSteamID[i], sizeof(g_sSteamID[]));
}

public void CVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bKPoD = cvar.BoolValue;
}

public void OnMapStart()
{
	g_hScore.Clear();
}

public void OnMapEnd()
{
	g_hScore.Clear();
}

public void Event_MapReset(Event event, const char[] name, bool dontBroadcast)
{
	g_hScore.Clear();

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		SetClientScore(i, S_Deaths);
		SetClientScore(i, S_Frags);
	}
}

public void OnClientAuthorized(int client, const char[] auth)	// Client Steam2 id, if available, else engine auth id.
{
	if(IsFakeClient(client) || !g_hScore.GetArray(auth, g_iScore, S_Total))
		return;

	FormatEx(g_sSteamID[client], sizeof(g_sSteamID[]), auth);

	SetClientScore(client, S_Frags, g_iScore[S_Frags] + GetClientFrags(client));
	SetClientScore(client, S_Deaths, g_iScore[S_Deaths] + GetClientDeaths(client));
}

public void OnClientDisconnect(int client)
{
	if(g_sSteamID[client][0] && IsClientInGame(client))
	{
		g_iScore[S_Frags]	= GetClientFrags(client);
		g_iScore[S_Deaths]	= GetClientDeaths(client);

		// The server will kill them, but we are early, so manually add to the death count
		if(g_bKPoD && IsPlayerAlive(client)) g_iScore[S_Deaths]++;

		g_hScore.SetArray(g_sSteamID[client], g_iScore, S_Total);
	}

	g_sSteamID[client][0] = 0;
}

stock void SetClientScore(int client, int type, int value = 0)
{
	SetEntProp(client, Prop_Data, type == S_Frags ? "m_iFrags" : "m_iDeaths", value);
}