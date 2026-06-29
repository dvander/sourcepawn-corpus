#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION  "1.0.3"

public Plugin:myinfo = 
{
	name = "Scout Multi-Jump",
	author = "[GNC] Matt",
	description = "Multiple scout double jumps.",
	version = PLUGIN_VERSION,
	url = "http://www.mattsfiles.com"
}

new Handle:TimerHandle = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hLimit = INVALID_HANDLE;
new dashoffset;
new g_iLimit = 1;
new g_bEnabled = false;
new bool:g_baEnabled[MAXPLAYERS + 1];
new g_iaLimit[MAXPLAYERS + 1];
new bool:g_bWasOnGround[MAXPLAYERS + 1];
new bool:g_bTimerEnabled = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	dashoffset = FindSendPropInfo("CTFPlayer", "m_iAirDash");
	CreateConVar("sm_scoutmultijump_version", PLUGIN_VERSION, "Scout Multi-Jump Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_smj_global_enabled", "0", "Enable/Disable Scout Multi-Jump", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, cvarEnabledTimer);
	g_hLimit = CreateConVar("sm_smj_global_limit", "0", "Amount of double jumps allowed. 0 = Unlimited.", FCVAR_PLUGIN);
	HookConVarChange(g_hLimit, cvarLimit);
	
	RegAdminCmd("sm_smj_enable", cmdPlayerEnable, ADMFLAG_SLAY, "Enable Scout Multi-Jump on one or more players.");
	RegAdminCmd("sm_smj_disable", cmdPlayerDisable, ADMFLAG_SLAY, "Disable Scout Multi-Jump on one or more players.");
	RegAdminCmd("sm_smj_limit", cmdPlayerLimit, ADMFLAG_SLAY, "Amount of double jumps allowed for one or more players. -1 = Use Global, 0 = Unlimited.");
	
	HookEvent("player_changeclass", eventPlayerChangeClass);
	
	initArrays();
}

public OnClientDisconnect(client)
{
	g_baEnabled[client] = false;
	g_iaLimit[client] = 2;
	handleTimer();
}

public initArrays()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		g_baEnabled[i] = false;
		g_iaLimit[i] = 2;
	}
}

public Action:eventPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	handleTimer();
}

public Action:cmdPlayerEnable(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04[SMJ]\x01 Syntax: sm_smj_enable target_name");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		g_baEnabled[target_list[i]] = true;
	}
 
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SMJ] ", "Scout Multi-Jumping enabled for %t.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SMJ] ", "Scout Multi-Jumping enabled for %s.", target_name);
	}
	
	handleTimer();
	return Plugin_Handled;
}

public Action:cmdPlayerDisable(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04[SMJ]\x01 Syntax: sm_smj_disable target_name");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		g_baEnabled[target_list[i]] = false;
	}
 
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SMJ] ", "Scout Multi-Jumping disabled for %t.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SMJ] ", "Scout Multi-Jumping disabled for %s.", target_name);
	}

	handleTimer();
	return Plugin_Handled;
}

public Action:cmdPlayerLimit(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x04[SMJ]\x01 Syntax: sm_smj_limit target_name limit");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_NAME_LENGTH];
	new String:arg2[3];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new l_iLimit = StringToInt(arg2);
	
	if(l_iLimit < -1 || l_iLimit > 255)
	{
		ReplyToCommand(client, "\x04[SMJ]\x01 Limit out of range.");
		return Plugin_Handled;
	}
	
	l_iLimit = (l_iLimit - 1) * -1;
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		g_iaLimit[target_list[i]] = l_iLimit;
	}
 
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SMJ] ", "Jump limit of %t set to %s.", target_name, arg2);
	}
	else
	{
		ShowActivity2(client, "[SMJ] ", "Jump limit of %s set to %s.", target_name, arg2);
	}
 
	return Plugin_Handled;
}

public handleTimer()
{
	new bool:needed = isTimerNeeded();
	if(needed && !g_bTimerEnabled)
	{
		EnableTimer();
	}
	else if(!needed && g_bTimerEnabled)
	{
		DisableTimer();
	}
}

public bool:isTimerNeeded()
{
	for(new i = 1; i <= MaxClients; i++)
		if(g_baEnabled[i])
			return true;
	
	if(g_bEnabled)
		return true;
	
	return false;
}

public EnableTimer()
{
	TimerHandle = CreateTimer(0.1, timerJump, _, TIMER_REPEAT);
	g_bTimerEnabled = true;
}

public DisableTimer()
{
	CloseHandle(TimerHandle);
	TimerHandle = INVALID_HANDLE;
	g_bTimerEnabled = false;
}

public cvarEnabledTimer(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new oldv = StringToInt(oldVal);
	new newv = StringToInt(newVal);
	
	if(oldv == 0 && newv == 1)
		g_bEnabled = true;
	
	if(oldv == 1 && newv == 0)
		g_bEnabled = false;
	
	handleTimer();
}

public cvarLimit(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iLimit = StringToInt(newVal);
	g_iLimit = (g_iLimit - 1) * -1;
}

public Action:timerJump(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_bEnabled || g_baEnabled[i])
		{
			new l_iLimit;
			if(g_iaLimit[i] == 2)
				l_iLimit = g_iLimit;
			else
				l_iLimit = g_iaLimit[i];
				
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(l_iLimit == 1)
				{
					SetEntData(i, dashoffset, 0);
				}
				else if(GetEntityFlags(i) & FL_ONGROUND)
				{
					g_bWasOnGround[i] = true;
				}
				else if (g_bWasOnGround[i])
				{
					g_bWasOnGround[i] = false;
					SetEntData(i, dashoffset, l_iLimit);
				}
			}
		}
	}
}

