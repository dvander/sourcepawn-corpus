#include <sourcemod>

#define PLUGIN_NAME "YADB Speed Announcer"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "ATRanko"
#define HAMMER_TO_KILOMETER 0.0686
#define HAMMER_TO_MILES 0.0426

new Handle:g_hCvarSpeedAnnounceMode, g_iCvarSpeedAnnounceMode;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Announces rocket speed to client",
	version = PLUGIN_VERSION,
	url = "http://www.steamcommunity.com/id/at-09-ranko"
}

public OnPluginStart()
{
	RegServerCmd("tf_dodgeball_announce_speed", SpeedAnnounce)
	g_hCvarSpeedAnnounceMode = CreateConVar("sm_dodgeball_speedannounce", "1", "Enable Speed Announcing, 1 to all, 2 to client only, 0 to disable.", _, true, 0.0, true, 2.0);
	g_iCvarSpeedAnnounceMode = GetConVarInt(g_hCvarSpeedAnnounceMode);
	HookConVarChange(g_hCvarSpeedAnnounceMode, OnConVarChange);
	
}

public OnConVarChange(Handle:hConvar, const String:OldValue[], const String:NewValue[])
{
	g_iCvarSpeedAnnounceMode = GetConVarInt(g_hCvarSpeedAnnounceMode);
}

public Action:SpeedAnnounce(iArgs)
{
	if(iArgs != 3)
	{
		PrintToServer("Usage: tf_dodgeball_announce_speed @dead @speed @name")
		return Plugin_Handled;
	}
	new String:strBuffer[32], String:strRocketName[64];
	GetCmdArg(1, strBuffer, sizeof(strBuffer)); new iDead = StringToInt(strBuffer, 10);
	GetCmdArg(2, strBuffer, sizeof(strBuffer)); new Float:fSpeed = StringToFloat(strBuffer); fSpeed *= HAMMER_TO_KILOMETER; new iSpeed = RoundToNearest(fSpeed);
	GetCmdArg(3, strRocketName, sizeof(strRocketName));
	if(!IsClientInGame(iDead))
		return Plugin_Handled;
	
	switch(g_iCvarSpeedAnnounceMode)
	{
		case 0: return Plugin_Handled;
		case 1: AnnounceToAll(iDead, iSpeed, strRocketName);
		case 2: AnnounceToClient(iDead, iSpeed, strRocketName);
		default: return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:AnnounceToAll(iDead, iSpeed, String:strRocketName[])
{
	new String:strDeadName[MAX_NAME_LENGTH], String:strDeadColour[32];
	GetClientName(iDead, strDeadName, sizeof(strDeadName));
	FindTeamColour(iDead, strDeadColour, sizeof(strDeadColour));
	
	PrintToChatAll("\x070FFF0F[Dodgeball] %s%s \x07FFFFFFwas killed by a %s travelling at %d KPH!", strDeadColour, strDeadName, strRocketName, iSpeed);
	return Plugin_Handled;
}

public Action:AnnounceToClient(iDead, iSpeed, String:strRocketName[])
{
	PrintToChat(iDead, "\x070FFF0F[Dodgeball] \x07FFFFFFYou were killed by a %s travelling at %d KPH!",strRocketName, iSpeed);
	return Plugin_Handled;
}

stock FindTeamColour(iClient, String:strBuffer[], MaxLength)
{
	switch (GetClientTeam(iClient))
	{
		case 0: Format(strBuffer, MaxLength, "\0x7FFFFFF");
		case 2: Format(strBuffer, MaxLength, "\x07B8383B");
		case 3: Format(strBuffer, MaxLength, "\x075885A2");
		default: Format(strBuffer, MaxLength, "\x07FFFFFF");
	}
	
}