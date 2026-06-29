#include <sourcemod>

int g_iTurnBind[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "Turnbind Restrictor",
    author = "Cruze",
    description = "Kicks the player if player uses turn bind for more than 15 seconds.",
    version = "1.1",
    url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	AddCommandListener(TurnBindOn, "+left");
	AddCommandListener(TurnBindOn, "+right");
	
	AddCommandListener(TurnBindOff, "-left");
	AddCommandListener(TurnBindOff, "-right");
}

public void OnClientPutInServer(int client)
{
	g_iTurnBind[client] = -1;
}

public Action TurnBindOn(int client, const char[] command, int argc)
{
	if(g_iTurnBind[client])
	{
		return Plugin_Continue;
	}
	
	g_iTurnBind[client] = 15;
	CreateTimer(1.0, Timer_CheckTurnBind, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	PrintToChat(client, "[SM] Usage of +left or +right is not allowed. Disable or be kicked in 15 seconds.");
	return Plugin_Continue;
}

public Action Timer_CheckTurnBind(Handle timer, int client)
{
	if(!client || g_iTurnBind[client] == -1)
	{
		return Plugin_Stop;
	}
	if(g_iTurnBind[client])
	{
		g_iTurnBind[client]--;
	}
	else
	{
		KickClient(client, "You've been kicked for using turnbinds.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action TurnBindOff(int client, const char[] command, int argc)
{
	g_iTurnBind[client] = -1;
}