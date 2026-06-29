#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Float:g_vAngles[MAXPLAYERS+1][3];

public OnPluginStart()
{
	RegConsoleCmd("sm_angles", Command_Angles);
}

public Action:Command_Angles(client, args)
{
	decl Float:vAngles[3];
	GetClientEyeAngles(client, vAngles);
	
	ReplyToCommand(client, "PlayerRunCmd Angles: %f %f %f", g_vAngles[client][0], g_vAngles[client][1], g_vAngles[client][2]);
	ReplyToCommand(client, "ClientEyeAngles Angles: %f %f %f", vAngles[0], vAngles[1], vAngles[2]);
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	g_vAngles[client][0] = angles[0];
	g_vAngles[client][1] = angles[1];
	g_vAngles[client][2] = angles[2];
	return Plugin_Continue;
}