#include <sourcemod>
#include <sdktools>
//#include <cstrike>
#include <tf2>

#define TEAM_UNASSIGNED 	0
#define TEAM_SPECTATOR 		1
#define TEAM_REBELS			2 // Team Red
#define TEAM_COMBINE		3 // Team Blue

#define MOD_INVALID			0
#define MOD_CS				1
#define MOD_TF2				2
#define MOD_OTHER			3


new g_Mod = MOD_INVALID;

public Plugin:myinfo = {
	name = "Force Join",
	author = "XeroX",
	description = "Allows Admins to force players to join a randomly selected team",
	version = "1.0",
	url = "http://sammys-zps.com"
};

public OnPluginStart()
{
	RegAdminCmd("sm_forcejoin",Command_ForceJoin,ADMFLAG_CHEATS,"Forces any player whom team is spectator to join a team");
	
}

public OnMapStart()
{
	decl String:ModDir[32];
	GetGameFolderName(ModDir,sizeof(ModDir));
	if(StrEqual(ModDir,"cstrike") || StrEqual(ModDir,"csgo"))
	{
		g_Mod = MOD_CS;
	}
	else if(StrEqual(ModDir,"tf2"))
	{
		g_Mod = MOD_TF2;	
	}
	else g_Mod = MOD_OTHER;
}

public Action:Command_ForceJoin(client, args)
{
	for(new i=1; i<MaxClients; i++)
	{
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(GetClientTeam(i) == TEAM_SPECTATOR)
		{
			new rnd = GetRandomInt(2,3);
			if(g_Mod == MOD_CS)
			{
				//CS_SwitchTeam(i,rnd);
				//CS_RespawnPlayer(i);
			}
			else if(g_Mod == MOD_TF2)
			{
				ChangeClientTeam(i,rnd);
				TF2_RespawnPlayer(i);
			}
			else
			{
				ChangeClientTeam(i,rnd);
				DispatchSpawn(i);
			}
		}
	}
	return Plugin_Handled;
}