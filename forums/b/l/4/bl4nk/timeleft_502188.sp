/**
 * timeleft.sp
 * Display time remaining for map
 *
 * Version 1.1
 * - Abandoned hungarian notation
 * - Added thetime
 * - New Cvar: sm_timeleft_interval: Displays "timeleft" every x seconds
 *
 * Version 1.0
 * - Plugin standards cleanup
 * - New Cvar: sm_timeleft_show: Displays "timeleft" to all or just player.
 *
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Timeleft",
	author = "ferret",
	description = "Display time remaining for map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Float:g_fStartTime;
new Handle:g_Cvar_TimeleftShow = INVALID_HANDLE;
new Handle:g_Cvar_TimeleftInterval = INVALID_HANDLE;
new Handle:g_Cvar_MpTimelimit = INVALID_HANDLE;

new Handle:g_Timer_TimeShow = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.timeleft");

	CreateConVar("sm_timeleft_version", PLUGIN_VERSION, "TimeLeft Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_TimeleftShow = CreateConVar("sm_timeleft_show", "1", "Display timeleft to all players? (0 off, 1 on, def. 1)", 0, true, 0.0, true, 1.0);	
	g_Cvar_TimeleftInterval = CreateConVar("sm_timeleft_interval", "0.0", "Display timeleft every x seconds. Default 0.", 0, true, 0.0, true, 1800.0);
	g_Cvar_MpTimelimit = FindConVar("mp_timelimit");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsSay);
	RegConsoleCmd("say_team", Command_Say);
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	HookConVarChange(g_Cvar_TimeleftInterval, ConVarChange_TimeleftInterval);
}

public ConVarChange_TimeleftInterval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:newval = StringToFloat(newValue);
	
	if (newval < 1.0 && g_Timer_TimeShow != INVALID_HANDLE)
	{
		KillTimer(g_Timer_TimeShow);		
		return;
	}
	
	if (g_Timer_TimeShow != INVALID_HANDLE)
	{
		KillTimer(g_Timer_TimeShow);
		g_Timer_TimeShow = CreateTimer(newval, Timer_DisplayTimeleft, _, TIMER_REPEAT);
	}
	else
		g_Timer_TimeShow = CreateTimer(newval, Timer_DisplayTimeleft, _, TIMER_REPEAT);
}

public Action:Timer_DisplayTimeleft(Handle:timer)
{
	new mins, secs;
	new timeleft = RoundToNearest(GetTimeLeft());
		
	mins = timeleft / 60;
	secs = timeleft % 60;		

	PrintToChatAll("[SM] %T %d:%02d", "Timeleft", LANG_SERVER, mins, secs);
}

public Action:Command_Say(client, args)
{
	decl String:text[192];
	new startidx = 0;
	GetCmdArgString(text, sizeof(text));
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}	

	if (strcmp(text[startidx], "timeleft", false) == 0)
	{
		new mins, secs;
		new timeleft = RoundToNearest(GetTimeLeft());
		
		mins = timeleft / 60;
		secs = timeleft % 60;		
		
		if(GetConVarInt(g_Cvar_TimeleftShow))
			PrintToChatAll("[SM] %t %d:%02d", "Timeleft", mins, secs);
		else
			PrintToChat(client,"[SM] %t %d:%02d", "Timeleft", mins, secs);
		
	}
	else if (strcmp(text[startidx], "thetime", false) == 0)
	{
		decl String:ctime[64];
		FormatTime(ctime, 64, "%m/%d/%Y - %H:%M:%S");
		
		if(GetConVarInt(g_Cvar_TimeleftShow))
			PrintToChatAll("[SM] %T %s", "Thetime", LANG_SERVER, ctime);
		else
			PrintToChat(client,"[SM] %t %s", "Thetime", ctime);
	}
	
	return Plugin_Continue;
}

public Action:Command_InsSay(client, args)
{
	decl String:text[192];
	new startidx = 0;
	GetCmdArgString(text, sizeof(text));
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}	

	if (strcmp(text[startidx+4], "timeleft", false) == 0)
	{
		new mins, secs;
		new timeleft = RoundToNearest(GetTimeLeft());
		
		mins = timeleft / 60;
		secs = timeleft % 60;		
		
		if(GetConVarInt(g_Cvar_TimeleftShow))
			PrintToChatAll("[SM] Timeleft %d:%02d", mins, secs);
		else
			PrintToChat(client,"[SM] Timeleft %d:%02d", mins, secs);
		
	}
	else if (strcmp(text[startidx+4], "thetime", false) == 0)
	{
		decl String:ctime[64];
		FormatTime(ctime, 64, "%m/%d/%Y - %H:%M:%S");
		
		if(GetConVarInt(g_Cvar_TimeleftShow))
			PrintToChatAll("[SM] The time is %s", ctime);
		else
			PrintToChat(client,"[SM] The time is %s", ctime);
	}
	
	return Plugin_Continue;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reason = GetEventInt(event, "reason");
	if(reason == 16)
	{
		g_fStartTime = GetEngineTime();		
	}	
}

public OnMapStart()
{
	g_fStartTime = GetEngineTime();
}

Float:GetTimeLeft()
{
	new Float:fLimit = GetConVarFloat(g_Cvar_MpTimelimit);
	new Float:fElapsed = GetEngineTime() - g_fStartTime;
	
	return (fLimit*60.0) - fElapsed;
}