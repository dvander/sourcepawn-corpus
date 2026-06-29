//Hud Custom Message 1.2 [With HUD]

#include <sourcemod>
#include <sdktools>
new Handle:Title
new Handle:MessageTime

public Plugin:myinfo =
{
	name = "Custom Messages",
	author = "[GR]Nick_6893{A}",
	description = "Make a custom hud message using console.",
	version = "1.2",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	RegAdminCmd("sm_mess", Command_Mess,  ADMFLAG_RCON, "Makes a message in the center of screen.");
	Title = CreateConVar("sm_mess_title", "Console", "Sets up the word/words before the colon.");
	MessageTime = CreateConVar("sm_mess_time", "3.5", "Sets up the time for the message to show.");
}

public Action:Command_Mess(Client, Arguments)
{
	if(Arguments < 1)
	{
		PrintToConsole(Client, "[SM] Usage: sm_mess <message>");
		return Plugin_Handled;
	}

	decl AllPlayers;
	AllPlayers = GetMaxClients();
	for(new A = 1; A <= AllPlayers; A++)
	{
		if(IsClientConnected(A) && IsClientInGame(A))
		{
			new String:Header[75];
			new String:Message[85];
			new messtime = GetConVarInt(MessageTime);
			GetConVarString(Title, Header, 75);
			GetCmdArgString(Message, 85);
			SetHudTextParams(-1.0, 0.3, float(messtime), 255, 255, 255, 255, 0, float(messtime), 0.3, 0.3);
			ShowHudText(A, -1, "%s: %s", Header, Message);
		}
	}
	return Plugin_Handled;
}





	
