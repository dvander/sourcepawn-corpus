#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "ScoreBar",
	author = "Neidermeyer",
	description = "Quake3-style scorebar showing best player and clients score in deathmatch and team scores in team deathmatch",
	version = "1.0",
	url = "http://sfc.my1.ru/forum/38-384-1"
};

new Handle:SBar;
new Handle:teamPlay;

new PlayersScores[MAXPLAYERS+1];
new defaultClient;

public void OnPluginStart()
{
	SBar = CreateConVar("ScoreBar", "1", "Enable ScoreBar");
	teamPlay = FindConVar("mp_teamplay");
	
	HookEvent("player_death", Event_PlayerDied);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", Event_PlayerDisconnect); 
	HookEvent("player_team", Event_PlayerChangedTeam);
}

public void OnClientPutInServer(int client)
{
	defaultClient = client;
}

public void OnClientDisconnect(int client)
{
	initiateUpdate();
	if (client == defaultClient){
		if (GetConVarInt(teamPlay) == 0 && GetClientCount(true) != 0){
			for (new player = 1; player <= MaxClients; player++)
			{
				if (IsClientInGame(player) && IsClientAuthorized(player))
				{
					defaultClient = player;
					break;
				}
			}
		}
	}
}

public void Event_PlayerChangedTeam(Event event, const char[] name, bool dontBroadcast)
{
    initiateUpdate();
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    initiateUpdate();
}

public void Event_PlayerDied(Event event, const char[] name, bool dontBroadcast)
{
    initiateUpdate();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    initiateUpdate();
}

public void initiateUpdate()
{
	if (GetConVarInt(SBar) == 1){
		CreateTimer(0.3, updateScores);   //cause scores do not seem to be updated instantly
	}	
}

public Action updateScores(Handle timer)
{
	if (GetConVarInt(teamPlay) == 0 && GetClientCount(true) > 1){ //Free for all, requires 2 players or more
		new max = GetClientFrags(defaultClient);
		new second = 0;
		new clmax = defaultClient;		
		new clsecond = defaultClient;
		
		//Getting two first players
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsClientAuthorized(client))
			{
				PlayersScores[client] = GetClientFrags(client);
				if (PlayersScores[client] > max){
					second = max;
					clsecond = clmax;
					max = PlayersScores[client];
					clmax = client;
					} else if (PlayersScores[client] >= second && client != clmax){
					second = PlayersScores[client];
					clsecond = client;
				}					
			}
		}
		decl color[4] = {255, 220, 0, 150};
		
		decl String:maxname[255];
		GetClientName(clmax, maxname, 255);
		
		decl String:secondname[255];
		GetClientName(clsecond, secondname, 255);
		
		//Printing first and their own position to everyone
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && client != clmax)
			{
				SetHudTextParamsEx(-1.0, 0.01, 999.0, color, color, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 255, "№1: %s with %d frags", maxname, max);		
				
				//Special for spectators	
				if (GetClientTeam(client) == 1)
				{ 
					SetHudTextParamsEx(-1.0, 0.05, 999.0, color, color, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, 254, "№2: %s with %d frags", secondname, second);
				}else  //For non-spectators
				{			
					SetHudTextParamsEx(-1.0, 0.05, 999.0, color, color, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, 254, "You are №%d with %d frags", getPlrPos(client), GetClientFrags(client));
				}
			}
		}		
		
		//For the first player
		if (IsClientInGame(clmax) && !IsFakeClient(clmax) && IsClientAuthorized(clmax))
		{
			SetHudTextParamsEx(-1.0, 0.01, 999.0, color, color, 0, 0.0, 0.0, 0.0);
			ShowHudText(clmax, 255, "№1: %s with %d frags", maxname, max);
			
			SetHudTextParamsEx(-1.0, 0.05, 999.0, color, color, 0, 0.0, 0.0, 0.0);
			ShowHudText(clmax, 254, "№2: %s with %d frags", secondname, second);
		}		
		
		//For team deathmatch
		}else if (GetConVarInt(teamPlay) == 1){	 
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
			{
				SetHudTextParamsEx(-1.0, 0.01, 999.0, {255, 0, 0, 150}, {255, 0, 0, 150}, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 255, "№1: Team Rebels  (score %d)", GetTeamScore(3));
				
				SetHudTextParamsEx(-1.0, 0.05, 999.0, {0, 0, 255, 150}, {0, 0, 255, 150}, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 254, "№2: Team Combine (score %d)", GetTeamScore(2));
			}
		}
	}
	return Plugin_Stop; 
}

public int getPlrPos(int client) //Thanks to EasSidezz for this (https://forums.alliedmods.net/showthread.php?t=295000)
{
	new frags = GetClientFrags(client);
	new curPos = 1;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if(GetClientFrags(i) > frags) curPos++;
		}
	}
	return curPos;
}