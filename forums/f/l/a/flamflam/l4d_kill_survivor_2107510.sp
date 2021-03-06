#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
	{
		name = "[L4D] Kill for Survivors",
		author = "Danny & FlamFlam",
		description = "use the !kill command in chat",
		version = PLUGIN_VERSION,
		url = ""
	}

	public OnPluginStart()
	{
		RegConsoleCmd("sm_explode", Kill_Me);
		RegConsoleCmd("sm_kill", Kill_Me);
	}


	// kill
	public Action:Kill_Me(client, args)
	{
		if (GetClientTeam(client) == 2)
		{
		ForcePlayerSuicide(client);
		}
		else
		{
		PrintToChat(client, "You have to be a Survivor")
		}
	}

	//Timed Message
	public bool:OnClientConnect(client, String:rejectmsg[], maxlen)

	{
		CreateTimer(60.0, Timer_Advertise, client);
		return true;
	}

	public Action:Timer_Advertise(Handle:timer, any:client)

	{
		if(IsClientInGame(client))
		PrintHintText(client, "Type in chat !kill to kill yourself");
		else if (IsClientConnected(client))
		CreateTimer(60.0, Timer_Advertise, client);
	}