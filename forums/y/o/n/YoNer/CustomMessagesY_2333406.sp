//Hud Custom Message 1.2b [With HUD]

#include <sourcemod>
#include <sdktools>
new Handle:Title
new Handle:MessageTime

public Plugin:myinfo =
{
	name = "Custom Messages",
	author = "[GR]Nick_6893{A} mod by YoNer",
	description = "Make a custom hud message using console.",
	version = "1.2b",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	RegAdminCmd("sm_mess", Command_Mess,  ADMFLAG_RCON, "Makes a message in the center of screen.");

}

public Action:Command_Mess(Client, Arguments)
{
	if(Arguments < 2)
	{
		PrintToConsole(Client, "[SM] Usage: sm_mess <time> <message>");
		return Plugin_Handled;
	}

	decl AllPlayers;
	AllPlayers = GetMaxClients();
	for(new A = 1; A <= AllPlayers; A++)
	{
		if(IsClientConnected(A) && IsClientInGame(A))
		{
			new String:argTime[11];
			GetCmdArg(1, argTime, sizeof(argTime));
			new Float:messtime = StringToFloat(argTime)
			new String:Message[86+11];
			GetCmdArgString(Message, sizeof(Message));
			ReplaceStringEx(Message,sizeof(Message),argTime,"", -1, -1, false);
			SetHudTextParams(-1.0, 0.3, messtime, 255, 255, 255, 255, 0, messtime, 0.3, 0.3);
			ShowHudText(A, -1, "%s", Message);
		}
	}
	return Plugin_Handled;
}





	
