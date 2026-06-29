#include <sourcemod>

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:g_hGamemode;

public Plugin:myinfo = 
{
	name = "L4D Away",
	author = "Ivailosp",
	description = "L4D Away",
	version = "0.0.2",
	url = "N/A"
};

public OnPluginStart()
{
	g_hGamemode = FindConVar("mp_gamemode");
	RegConsoleCmd("sm_away", Away);
	cvarAnnounce = CreateConVar("sm_away_announce","1");
	AutoExecConfig(true, "sm_away");
}

public Action:Away(client, args){
{	
						
	if(GetClientTeam(client) == 2)
	{
		SetConVarString(g_hGamemode,"coop");
		FakeClientCommand(client, "go_away_from_keyboard");
		CreateTimer(0.05, TimerAway, client);
	}
	else
	{
		FakeClientCommand(client, "go_away_from_keyboard");
	}
	CloseHandle(g_hGamemode);
	}
}

public Action:TimerAway(Handle:timer, any:client)
{
	SetConVarString(g_hGamemode,"versus");
}

public OnClientPutInServer(client)
{
	if (client) 
	{
		if (GetConVarBool(cvarAnnounce))
			CreateTimer(30.0, TimerAnnounce, client);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		PrintToChat(client, "\x04[SM]\x03 Type !away if you need to go AFK.");
	}
}