#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Achievement Spam Block",
	author = "psychonic",
	description = "Blocks player achievement spam",
	version = "1.ur",
	url = "http://www.sourcemod.net/"
};

new Handle:g_AchievementTimes[MAXPLAYERS+1];
new Handle:g_EarnedAchievements[MAXPLAYERS+1];
new bool:g_AchievementBanned[MAXPLAYERS+1];

new Handle:sm_ach_max_unlocks;
new Handle:sm_ach_rate_limit_max;
new Handle:sm_ach_rate_limit_time;

public OnPluginStart()
{
	HookEvent("achievement_earned", Event_AchievementEarned, EventHookMode_Pre);
	
	for (new i = 1; i < sizeof(g_AchievementTimes); ++i)
	{
		g_AchievementTimes[i] = CreateArray();
		g_EarnedAchievements[i] = CreateArray();
		g_AchievementBanned[i] = false;
	}
	
	sm_ach_max_unlocks = CreateConVar("sm_ach_max_unlocks", "10",
		"Maximum number of achievements that a player can earn during a map before action is taken",
		.hasMin = true, .min = 0.0);
	sm_ach_rate_limit_max = CreateConVar("sm_ach_rate_limit_max", "4",
		"Maximum number of achievements that a player can earn in the last sm_ach_rate_limit_time seconds before action is taken",
		.hasMin = true, .min = 0.0);
	sm_ach_rate_limit_time = CreateConVar("sm_ach_rate_limit_time", "30",
		"Amount of time (in seconds) for achievements to count toward sm_ach_rate_limit_max",
		.hasMin = true, .min = 0.0);
}

public OnClientConnected(client)
{
	ClearArray(g_AchievementTimes[client]);
	ClearArray(g_EarnedAchievements[client]);
	g_AchievementBanned[client] = false;
}

public Action:Event_AchievementEarned(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new client = GetEventInt(hEvent, "player");
	new achievement = GetEventInt(hEvent, "achievement");
	
	if (g_AchievementBanned[client])
	{
		return Plugin_Stop;
	}
	
	if (FindValueInArray(g_EarnedAchievements[client], achievement) > -1)
	{
		AchievementBanClient(client);
		return Plugin_Stop;
	}
	
	PushArrayCell(g_EarnedAchievements[client], achievement);
	
	if (GetArraySize(g_EarnedAchievements[client]) >= GetConVarInt(sm_ach_max_unlocks))
	{
		AchievementBanClient(client);
		return Plugin_Stop;
	}
	
	new time = GetTime();
	new minTime = time - GetConVarInt(sm_ach_rate_limit_time);
	new historyMax = GetConVarInt(sm_ach_rate_limit_max);
	
	PushArrayCell(g_AchievementTimes[client], time);
	
	new totalCnt = GetArraySize(g_AchievementTimes[client]);
	new achCnt = 0;
	for (new i = totalCnt - 1; i >= 0; --i)
	{
		if (GetArrayCell(g_AchievementTimes[client], i) < minTime)
			break;
		
		achCnt++;
	}
	
	if (achCnt >= historyMax)
	{
		AchievementBanClient(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

AchievementBanClient(client)
{
	g_AchievementBanned[client] = true;
}
