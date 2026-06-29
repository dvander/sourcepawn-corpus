#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "[TF2] Last Alive Crits", 
	author = "Drixevel", 
	description = "", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	//Get the team of the client.
	TFTeam team = TF2_GetClientTeam(client);
	
	//Get the amount of players on that team who are alive.
	int count;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == team)
			count++;
	
	//Count is 1 so it's only them alive, give them crits.
	if (count == 1)
	{
		result = true;
		return Plugin_Changed;
	}
	
	//Count isn't 1 therefore go about business as usual.
	return Plugin_Continue;
}