public Plugin:myinfo =
{ 
	name = "Bonus Round Time Extend", 
	author = "Mr. Random", 
	description = "Create cvars to extend bonusroundtime beyond 15 sec.", 
	version = "1.0", 
	url = ":(" 
}

new Handle:gBonusRoundTime = INVALID_HANDLE;
new Int:bonustime = 0;

ConVar g_cvTime;


public OnPluginStart() {
	CreateTimer(1.0, UpdateCvar, _, TIMER_REPEAT);
	gBonusRoundTime = FindConVar("mp_bonusroundtime");
	g_cvTime = CreateConVar("bonus_time", "15", "The length of bonus round time");
	if (gBonusRoundTime != INVALID_HANDLE) 
	{ 
		SetConVarBounds(gBonusRoundTime, ConVarBound_Upper, true, g_cvTime.FloatValue);
		ServerCommand("sm_cvar","mp_bonusroundtime",g_cvTime.FloatValue);
		 
	}
	else
	{
		PrintToServer("Cvar failed to be acquired");
		//somehow tell sourcemod the plugin has crashed.
	}
}
public Action UpdateCvar(Handle timer)
{
	bonustime = g_cvTime.IntValue;
	if (gBonusRoundTime != INVALID_HANDLE)
	{
		SetConVarBounds(gBonusRoundTime, ConVarBound_Upper, true, g_cvTime.FloatValue);
		ServerCommand("mp_bonusroundtime %d", bonustime);
	}
}