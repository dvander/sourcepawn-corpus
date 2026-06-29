#include <sourcemod>
#include <sdktools>
#include <cstrike>


#define TEAMRATIO 2.0 // How much Ts for every CT



new bool:morect;
new bool:morett;

public Plugin:myinfo = 
{
	name = "SM franug team ratio balancer",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
}


public OnPluginStart()
{
	HookEvent("round_end",Event_RoundEnded);
}

public Action:Event_RoundEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	morect = false;
	morett = false;
	
	new aleatorio;
	while(!Balanced())
	{
		aleatorio = 0;
		if(morect)
		{
			aleatorio = GetRandomPlayer(CS_TEAM_T);
			
			//for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) PrintToConsole(i, "CTs change and change %i", aleatorio);
			
			if(aleatorio > 0) CS_SwitchTeam(aleatorio, CS_TEAM_CT);
			else break;
		}
		else if(morett)
		{
			aleatorio = GetRandomPlayer(CS_TEAM_CT);
			
			//for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) PrintToConsole(i, "TTs change and change %i", aleatorio);
			
			if(aleatorio > 0) CS_SwitchTeam(aleatorio, CS_TEAM_T);
			else break;
		}
	}
}

Balanced()
{
	new Float:CTs = float(GetTeamClientCount(CS_TEAM_CT));
	new Float:Ts = float(GetTeamClientCount(CS_TEAM_T));
	
	new Float:balancer = (Ts / CTs);
	
	//for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) PrintToConsole(i, "CTS %f \nTTs %f \nTotal %f", CTs, Ts, balancer);
	
	if(balancer == TEAMRATIO) return true;
	
	if(balancer < TEAMRATIO)
	{
		if(morect) return true;
		morett = true;
		morect = false;
		//for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) PrintToConsole(i, "TTs needed");
	}
	else
	{
		if(morett) return true;
		morett = false;
		morect = true;
		//for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) PrintToConsole(i, "CTs needed");
		
	}
	
	return false;
	
}

GetRandomPlayer(team)
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == team)
			clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
} 