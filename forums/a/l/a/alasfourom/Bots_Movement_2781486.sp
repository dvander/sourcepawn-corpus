#include <sourcemod>
#include <sdktools>


public Plugin myinfo = {
	name = "Bots Movement",
	author = "Platinum",
	description = "Allowing Players To Control Bots Movements",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
}

public void OnPluginStart() 
{
	RegAdminCmd("sm_stop", Command_Stop, ADMFLAG_SLAY, "Force Bots To Stop");
	RegAdminCmd("sm_move", Command_Move, ADMFLAG_SLAY, "Force Bots To Move");
}

public Action Command_Stop(int client, int args)
{
	SetConVarInt(FindConVar("sb_stop"), 1);
	PrintToChatAll("\x04[Bots Movements] \x01Admin \x03%N\x01, has forced the bots to \x05STOP\x01.", client);
	return Plugin_Handled;
}

public Action Command_Move(int client, int args)
{
	SetConVarInt(FindConVar("sb_stop"), 0);
	PrintToChatAll("\x04[Bots Movements] \x01Admin \x03%N\x01, has forced the bots to \x05MOVE\x01.", client);
	return Plugin_Handled;
}

public void OnMapStart()
{
	CreateTimer(3.0, UnstickOff);
	CreateTimer(60.0, UnstickOn);
}

public Action UnstickOff(Handle timer)
{
	SetConVarInt(FindConVar("sb_unstick"), 0);
	return Plugin_Handled;
}

public Action UnstickOn(Handle timer)
{
	SetConVarInt(FindConVar("sb_unstick"), 1);
	return Plugin_Handled;
}