#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "CS:GO/CSS AutoStrafe", 
	author = "Josh", 
	description = "Provides an autostrafe jump.", 
	version = "1.0.1", 
	url = "https://bitbucket.org/JoshuaHawking/cs-go-cs-s-autostrafe"
};

// Globals
bool g_bStrafeEnabled[MAXPLAYERS + 1];
float g_flLastGain[MAXPLAYERS + 1];

float g_flSidespeed = 400.0;

public void OnPluginStart()
{
	RegAdminCmd("sm_autostrafe", Cmd_ToggleStrafe, ADMFLAG_CHEATS, "Toggles autostrafe.")
	
	// Check whether it's CSS or CS:GO
	if(GetEngineVersion() == Engine_CSGO)
	{
		g_flSidespeed = 450.0;
	}
	else if(GetEngineVersion() == Engine_CSS)
	{
		g_flSidespeed = 400.0;
	}
	else
	{
		LogMessage("Warning: Unsupported game for autostrafer.")
	}
}

public OnClientConnected(int client)
{
	// Disable on connecting
	g_bStrafeEnabled[client] = false;
}

// Toggle command
public Action Cmd_ToggleStrafe(int client, int args)
{
	if (client <= 0)
	{
		PrintToChat(client, "Cannot call this command from the console!")
		return Plugin_Handled;
	}
	
	// Toggle
	g_bStrafeEnabled[client] = !g_bStrafeEnabled[client]
	
	// Alert user
	char szMessage[256];
	FormatEx(szMessage, sizeof(szMessage), "[SM] Autostrafe: %s", (g_bStrafeEnabled[client] ? "ON" : "OFF"))
	PrintToChat(client, szMessage)
	
	// Log toggle
	LogAction(client, -1, "%N toggled their autostrafe (%s)", client, (g_bStrafeEnabled[client] ? "ON" : "OFF"))
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (IsFakeClient(client))
		return Plugin_Continue;
	
	if (g_bStrafeEnabled[client])
	{
		ApplyAutoStrafe(client, buttons, vel, angles)
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

ApplyAutoStrafe(int client, int &buttons, float vel[3], float angles[3])
{
	// If they are currently on the ground, or on a ladder, disable the autostrafe
	if (GetEntityFlags(client) & FL_ONGROUND || GetEntityMoveType(client) & MOVETYPE_LADDER)
		return;
	
	// If they are currently pushing buttons, disable the autostrafe
	if (buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_FORWARD || buttons & IN_BACK)
	{
		return;
	}
	
	float flVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", flVelocity);
	
	float flYVel = RadToDeg(ArcTangent2(flVelocity[1], flVelocity[0]));
	
	float flDiffAngle = NormalizeAngle(angles[1] - flYVel);
	
	vel[1] = g_flSidespeed;
	
	if (flDiffAngle > 0.0)
		vel[1] = -g_flSidespeed;
	
	// Check whether the player has tried to move their mouse more than the strafer
	float flLastGain = g_flLastGain[client];
	float flAngleGain = RadToDeg(ArcTangent(vel[1] / vel[0]));
	
	// This check tells you when the mouse player movement is higher than the autostrafer one, and decide to put it or not
	if (!((flLastGain < 0.0 && flAngleGain < 0.0) || (flLastGain > 0.0 && flAngleGain > 0.0))) 
		angles[1] -= flDiffAngle;
	
	g_flLastGain[client] = flAngleGain;
}

// Stocks
public float NormalizeAngle(float angle)
{
	float temp = angle;
	
	while (temp <= -180.0)
	{
		temp += 360.0;
	}
	
	while (temp > 180.0)
	{
		temp -= 360.0;
	}
	
	return temp;
} 