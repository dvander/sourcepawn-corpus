#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "ForceBattle",
	author = "Kage, from FeuerSturm's Move dead to Spec",
	description = "Force Battle Timer",
	version = PLUGIN_VERSION,
	url = "http://www.69threalism.com"
}

new Handle:ForceBattle = INVALID_HANDLE
new Handle:WarmupTime = INVALID_HANDLE
new Handle:LiveTime = INVALID_HANDLE
new Handle:GameTimer = INVALID_HANDLE
new g_Started = 0, g_Live = 0
new Float:g_EndTime = 0.0

public OnPluginStart()
{
	ForceBattle = CreateConVar("sm_forcebattle", "0", "<1/0> = enable/disable Force Battle Timer",FCVAR_PLUGIN)
	WarmupTime = CreateConVar("sm_fbwarmuptime", "5", "<#> = time in minutes for warmup",FCVAR_PLUGIN)
	LiveTime = CreateConVar("sm_fblivetime", "20", "<#> = time in minutes for live round",FCVAR_PLUGIN)
	RegAdminCmd("sm_fbstart", cmdfbStart, 0)
	RegAdminCmd("sm_fbcancel", cmdfbCancel, 0)
	RegAdminCmd("sm_fblive", cmdfbLive, 0)
	RegAdminCmd("sm_fbtime", cmdfbTime, 0)
	RegConsoleCmd("say", ChatTrigger)
	LoadTranslations("forcebattle.txt")
}

public OnMapStart()
{
	g_Live = 0
	g_Started = 0
}

public Action:ChatTrigger(client, args)
{
	if(args > 1 || GetConVarInt(ForceBattle) == 0)
	{
		return Plugin_Continue
	}
	decl String:trigger[16]
	GetCmdArg(0,trigger,sizeof(trigger))
	if(strcmp(trigger, "!start") == 0)
	{
		cmdfbStart(client, 0)
		return Plugin_Handled
	}
	else if(strcmp(trigger, "!time") == 0)
	{
		cmdfbTime(client, 0)
		return Plugin_Handled
	}
	else if(strcmp(trigger, "!cancel") == 0)
	{
		cmdfbCancel(client, 0)
		return Plugin_Handled
	}
	else if(strcmp(trigger, "!live") == 0)
	{
		cmdfbLive(client, 0)
		return Plugin_Handled
	}
	else
	{
		return Plugin_Continue
	}
}

public Action:cmdfbStart(client, args)
{
	if(g_Started == 0 && g_Live == 0 && GetConVarInt(ForceBattle) == 1)
	{
		g_Started = 1
		decl String:message[256]
		Format(message, sizeof(message), "%t", "FBStart")
		PrintHintTextToAll(message)
		new Float:warmuptimer = (GetConVarFloat(WarmupTime)*60.0)
		g_EndTime = GetGameTime() + warmuptimer
		GameTimer = CreateTimer(warmuptimer, TimerLive, _, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:cmdfbTime(client, args)
{
	if(g_Started == 1 || g_Live == 1)
	{
		decl String:message[256]
		new Timeleft = RoundToCeil(g_EndTime - GetGameTime())
		if((Timeleft / 60) < 1)
		{
			Format(message, sizeof(message), "%t", "FBSecondsLeft",(Timeleft))
		}
		else
		{
			Format(message, sizeof(message), "%t", "FBMinutesLeft",(Timeleft / 60)+1)
		}
		PrintHintTextToAll(message)
	}
}

public Action:cmdfbLive(client, args)
{
	if(g_Started == 1 && g_Live == 0)
	{
		if(GameTimer != INVALID_HANDLE)
		{
			if(CloseHandle(GameTimer))
			{
				GameTimer = INVALID_HANDLE
			}
		}
		g_Live = 1
		decl String:message[256]
		Format(message, sizeof(message), "%t", "FBLive")
		PrintHintTextToAll(message)
		new Float:livetimer = (GetConVarFloat(LiveTime)*60.0)
		g_EndTime = GetGameTime() + livetimer
		GameTimer = CreateTimer(livetimer, TimerEnd, _, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:cmdfbCancel(client, args)
{
	if(g_Started == 1 || g_Live == 1)
	{
		if(GameTimer != INVALID_HANDLE)
		{
			if(CloseHandle(GameTimer))
			{
				GameTimer = INVALID_HANDLE
			}
		}
		g_Live = 0
		g_Started = 0
		decl String:message[256]
		Format(message, sizeof(message), "%t", "FBCancel")
		PrintHintTextToAll(message)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:TimerEnd(Handle:timer)
{
	g_Live = 0
	g_Started = 0
	decl String:message[256]
	Format(message, sizeof(message), "%t", "FBEnd")
	PrintHintTextToAll(message)
	return Plugin_Handled
}

public Action:TimerLive(Handle:timer)
{
	if(g_Started == 1 && g_Live == 0)
	{
		g_Live = 1
		decl String:message[256]
		Format(message, sizeof(message), "%t", "FBLive")
		PrintHintTextToAll(message)
		new Float:livetimer = (GetConVarFloat(LiveTime)*60.0)
		g_EndTime = GetGameTime() + livetimer
		GameTimer = CreateTimer(livetimer, TimerEnd, _, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Handled
	}
	return Plugin_Handled
}