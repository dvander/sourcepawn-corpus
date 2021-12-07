#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4.3"

public Plugin:myinfo = 
{
	name = "sexy",
	author = "ivailosp",
	description = "huh",
	version = PLUGIN_VERSION,
	url = ""
};

new Handle:surv_l;
new Handle:z_l ;

public OnPluginStart()
{
	surv_l = FindConVar("survivor_limit");
	z_l = FindConVar("z_max_player_zombies");
	HookEvent("round_start", Event_RoundStart);
//	CreateTimer(0.4, CheckSurvivorBot, 0);

	HookEvent("round_start", Event_RoundStart);
 
}
 
 
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	
	SetConVarBounds(surv_l , ConVarBound_Upper, true, 20.0);
	SetConVarBounds(z_l , ConVarBound_Upper, true, 20.0);
	
	ServerCommand("exec server");
	CreateTimer(5, CheckSurvivorBot, 0);
}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			if(IsFakeClient(i) && !IsClientInKickQueue(i)){
				KickClient(i);
			}
	}
}

public Action:CheckSurvivorBot(Handle:timer,any:client)
{
	if (GetTeamClientCount(2) >= 4 && GetTeamClientCount(2) <= 10 )
	{
		ServerCommand("sb_add");
		
	}
	if(GetTeamClientCount(2) < 10)
		CreateTimer(0.1, CheckSurvivorBot, 0);
}