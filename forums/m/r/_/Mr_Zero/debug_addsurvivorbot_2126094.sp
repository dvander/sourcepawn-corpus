/* Includes */
#include <sourcemod>
#include <sdktools>

/* Plugin Information */
public Plugin:myinfo = 
{
	name		= "Debug - Add Survivor Bot",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Adds Survivor bots on command",
	version		= "1.0.0",
	url		= "mrzerodk@gmail.com"
}

/* Globals */

#define SURVIVOR_BOT_CLASSNAME "survivorbot"
#define SURVIVOR_BOT_NAME "survivorbot"
#define SURVIVOR_BOT_KICK_DELAY 1.0
#define SURVIVOR_BOT_KICK_REASON "Survivor bot is leaving"

/* Plugin Functions */
public OnPluginStart()
{
	AddCommandListener(SpawnBot_Command, "gimmebot")
}

public Action:SpawnBot_Command(client, const String:command[], argc)
{
	CreateSurvivorBot()
	return Plugin_Handled
}

public Action:KickSurvivorBot_Timer(Handle:timer, any:userid)
{
	new bot = GetClientOfUserId(userid)
	if (bot > 0 && IsClientConnected(bot))
	{
		KickClient(bot, SURVIVOR_BOT_KICK_REASON)
	}
	
	return Plugin_Stop
}

static CreateSurvivorBot()
{
	new bot = CreateFakeClient(SURVIVOR_BOT_NAME)
	if (bot <= 0)
	{
		return -1
	}
	
	ChangeClientTeam(bot, 2)
	
	if (DispatchKeyValue(bot, "classname", SURVIVOR_BOT_CLASSNAME) && DispatchSpawn(bot))
	{
		CreateTimer(SURVIVOR_BOT_KICK_DELAY, KickSurvivorBot_Timer, GetClientUserId(bot), TIMER_FLAG_NO_MAPCHANGE)
	}
	else
	{
		KickClient(bot, SURVIVOR_BOT_KICK_REASON)
		bot = -1
	}
	
	return bot
}