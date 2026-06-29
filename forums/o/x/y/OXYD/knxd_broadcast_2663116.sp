//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <colors>

#define PLUGIN_AUTHOR "KENOXYD"
#define PLUGIN_VERSION "1.00"

public Plugin:myinfo = 
{
	name = "Admin Broadcast",
	author = PLUGIN_AUTHOR,
	description = "Broadcast Command",
	version = PLUGIN_VERSION,
	url = "https://hellhounds.ro"
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public void OnPluginStart()
{
	RegAdminCmd("sm_bc", Command_BroadCast, ADMFLAG_SLAY, "sm_bc <message> - sends broadcast to all players");
	RegAdminCmd("sm_broadcast", Command_BroadCast, ADMFLAG_SLAY, "sm_broadcast <message> - sends broadcast to all players");
	RegAdminCmd("sm_shout", Command_BroadCast, ADMFLAG_SLAY, "sm_shout <message> - sends broadcast to all players");
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Action Command_BroadCast(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, " \x02[★ GO ★] \x04Usage: sm_broadcast <message>");
		return Plugin_Handled;	
	}
	
	char text[192];
	GetCmdArgString(text, sizeof(text));

	SendBroadCast(client, text);
	
	return Plugin_Handled;		
}

void SendBroadCast(int client, const char[] message)
{
	char nameBuf[MAX_NAME_LENGTH];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		FormatActivitySource(client, i, nameBuf, sizeof(nameBuf));
		
		PrintToChat(i, " \x02[★ GO ★] \x04%s", message);
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////