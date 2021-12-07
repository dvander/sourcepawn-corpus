#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name = "SM Bots aim to head",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

ConVar cv_hs;

public void OnPluginStart()
{
	cv_hs = FindConVar("mp_damage_headshot_only");
	
	if(cv_hs == null)
		SetFailState("Game not supported.");
		
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
        SendConVarValue(client, cv_hs, "1");
}