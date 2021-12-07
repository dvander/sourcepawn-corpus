#include	<sourcemod>
	
public Plugin:myinfo = 
{
	name = "Reticle",
	author = "Mrs. Nesbitt",
	description = "An aiming reticle designed for Goldeneye: Source",
	url = ""
};

public OnClientPutInServer(client)
{
	forward OnGameFrame(1.0, Reticle, client, TIMER_REPEAT);
}

public Action:Reticle(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		SetHudTextParams(-1.0, -1.0, 0.5, 148,13,8,255, 0, 6.0, 0.1, 0.2);
		ShowHudText(client, -1, "∙");
	}
}