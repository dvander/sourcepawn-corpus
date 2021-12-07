#include <sourcemod>
#include <sdktools>
#include <cstrike>
#define MAX_TRIES 8 //максимально попыток
public Plugin:myinfo =
{
	name = "AntiDDos",
	author = "Evil Night",
	description = "Blocks ddos with command 'buy'",
	version = "1.3",
	url = ""
};
new ICant[MAXPLAYERS+1], DDosTries[MAXPLAYERS+1];
public OnPluginStart() 
{
	RegConsoleCmd("buy", AntiDDos);
	PrintToServer("ANTI-DDOS by Evil Night was loaded!");
	CreateTimer(0.1, CounterDDos, _, TIMER_REPEAT);
}
public Action:CounterDDos(Handle:timer)
{
	for(new i = 1; i < GetMaxClients()+1; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(ICant[i] > 0)
		{
			ICant[i]--;
			if(ICant[i]<= 0) DDosTries[i]=0;
		}
	}
	return Plugin_Handled;
}
public OnClientPutInServer(client) {
	DDosTries[client]=0;
	ICant[client]=0;
}
public Action:AntiDDos(client, args) {
	if(client == 0) return Plugin_Handled;
	if(!IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR || !IsPlayerAlive(client)) 
	{
		KickClient(client, "[AntiDDos] ANTI-DDOS");
		return Plugin_Handled;
	}
	if(DDosTries[client] >= MAX_TRIES) 
	{
		KickClient(client, "[AntiDDos] ANTI-DDOS");
		return Plugin_Handled;
	}
	if(ICant[client] > 0)
	{
		DDosTries[client]++;
		return Plugin_Handled;
	}
	ICant[client]=3;
	DDosTries[client]=0;
	return Plugin_Continue;
}