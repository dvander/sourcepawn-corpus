#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[ZR] No Alone Infection",
	author = "DSASDFGH @ AM",
	description = "",
	version = "1.1",
	url = ""
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	// You can change this value to set minimum players required for allow start infection 
	if(fnGetPlaying() < 2)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

stock fnGetPlaying()
{
	new iPlaysNum;
	iPlaysNum = 0;
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i))
		{
			iPlaysNum++;
		}
	}
	
	return iPlaysNum;
}