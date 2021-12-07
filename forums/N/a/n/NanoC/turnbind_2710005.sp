#include <sourcemod>
#include <multicolors>

bool g_bTurnBind[MAXPLAYERS+1] = {false, ...};

public Plugin myinfo =
{
    name = "Turnbind Restrictor",
    author = "Cruze, Nano",
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
	g_bTurnBind[client] = false;
}

public Action TurnBindOn(int client, const char[] command, int argc)
{
	if(IsClientInGame(client))
	{
		g_bTurnBind[client] = true;
		CPrintToChat(client, "{green}[SM] {default}Usage of {green}+left or +right {default}is not allowed. Disable or be kicked in {darkred}15 seconds.");
		CreateTimer(15.0, Timer_CheckTurnBind, GetClientUserId(client));
	}
	return Plugin_Handled;
}

public Action TurnBindOff(int client, const char[] command, int argc)
{
	if(IsClientInGame(client))
	{
		g_bTurnBind[client] = false;
	}
	return Plugin_Handled;
}

public Action Timer_CheckTurnBind(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) 
	{
		return;
	}
	
	if(!g_bTurnBind[client])
	{
		CPrintToChat(client, "{green}[SM]{default} You weren't kicked because you disabled {green}+right/+left.");
		return;
	}

	CPrintToChatAll("{green}[SM]{default} Player {green}%N{default} were kicked because he used {darkred}turnbinds", client);
	KickClient(client, "You were kicked for using turnbinds.");
}