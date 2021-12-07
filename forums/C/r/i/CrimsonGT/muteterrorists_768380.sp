/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Mute Terrorists Timer",
	author = "Crimson",
	description = "Silences all terrorists for a short duration",
	version = "1.0.0",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	RegConsoleCmd("muteterrorists", Command_MuteTerrorists);
}

public Action:Command_MuteTerrorists(client, args)
{
	new String:sDuration[6];
	GetCmdArg(1, sDuration, sizeof(sDuration));

	new Float:flDuration = StringToFloat(sDuration);

	CreateTimer(flDuration, Timer_UnmuteTerrorists);
	ServerCommand("sm_mute @t");
	LogMessage("[SM] Muted Terrorists Team for %f Seconds", flDuration);
	
	return Plugin_Handled;
}

public Action:Timer_UnmuteTerrorists(Handle:hndl)
{
	ServerCommand("sm_unmute @t");
	LogMessage("[SM] Unmuted Terrorists Team");
}