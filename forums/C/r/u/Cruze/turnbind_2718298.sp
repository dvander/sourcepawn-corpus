#include <sourcemod>

int g_iTurnBind[MAXPLAYERS+1], g_iCD[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "Turnbind Restrictor",
    author = "Cruze",
    description = "Kicks the player if player uses turn bind for more than 15 seconds.",
    version = "1.2",
    url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnClientPostAdminCheck(int client)
{
	g_iTurnBind[client] = 15;
	if(!IsFakeClient(client))
	{
		CreateTimer(1.0, Timer_CheckTurnBind, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_CheckTurnBind(Handle timer, int client)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	int buttons = GetClientButtons(client)
	if(buttons & IN_LEFT || buttons & IN_RIGHT)
	{
		DisplayMSG(client);
		g_iTurnBind[client]--;
	}
	else
	{
		g_iTurnBind[client] = 15;
	}
	if(g_iTurnBind[client] <= 0)
	{
		KickClient(client, "You have been kicked for using turnbinds");
	}
	return Plugin_Continue;
}

void DisplayMSG(int client)
{
	if(g_iCD[client] <= GetTime())
	{
		g_iCD[client] = GetTime()+5;
		PrintToChat(client, "[SM] Usage of +left or +right is not allowed. Disable or be kicked in %d seconds.", g_iTurnBind[client]);
	}
}