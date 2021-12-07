#include <sourcemod>

new g_iOffsetCloak;
new bool:g_bCloaked[MAXPLAYERS+1];

public OnPluginStart()
{
	RegAdminCmd("sm_cloak", Command_Cloak, ADMFLAG_SLAY);
	
	g_iOffsetCloak = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
}

public OnClientDisconnect(client)
{
	g_bCloaked[client] = false;
}

public Action:Command_Cloak(client, args)
{
	if(client && IsClientInGame(client))
	{
		g_bCloaked[client] = ~g_bCloaked[client];
		ReplyToCommand(client, "\x04[Cloak]\x01 %s", g_bCloaked[client] ? "On" : "Off");
	}
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && g_bCloaked[i] && IsPlayerAlive(i))
		{
			SetEntDataFloat(i, g_iOffsetCloak, 100.0);
		}
	}
}