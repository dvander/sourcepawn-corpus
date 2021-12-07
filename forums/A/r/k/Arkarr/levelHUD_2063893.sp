#include <sourcemod>
#include <morecolors>
#include <clientprefs>

new exp[MAXPLAYERS+1] = 0;
new level[MAXPLAYERS+1] = 1;
new exp_need[MAXPLAYERS+1] = 10;

new Handle:Cookie_Level;
new Handle:Cookie_Exp;
new Handle:Cookie_ExpNeeded;

public OnPluginStart()
{
	RegConsoleCmd("sm_rs", SetScoreTo0);
	RegConsoleCmd("sm_resetscore", SetScoreTo0);
	RegConsoleCmd("sm_restartscore", SetScoreTo0);
	
	SetHudTextParams(0.41, 0.85, 0.5, 0, 255, 0, 200);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	Cookie_Level = RegClientCookie("HUDLevel_level", "Store level", CookieAccess_Protected);
	Cookie_Exp = RegClientCookie("HUDLevel_exp", "Store exp", CookieAccess_Protected);
	Cookie_ExpNeeded = RegClientCookie("HUDLevel_expneeded", "Store exp needed", CookieAccess_Protected);
}

public OnClientPutInServer(client)
{
	decl String:sCookie_Level[11];
	decl String:sCookie_Exp[11];
	decl String:sCookie_ExpNeeded[11];
	
	GetClientCookie(client, Cookie_Exp, sCookie_Exp, sizeof(sCookie_Exp));
	GetClientCookie(client, Cookie_Level, sCookie_Level, sizeof(sCookie_Level));
	GetClientCookie(client, Cookie_ExpNeeded, sCookie_ExpNeeded, sizeof(sCookie_ExpNeeded));
	
	exp[client] = StringToInt(sCookie_Exp);
	level[client] = StringToInt(sCookie_Level);
	exp_need[client] = StringToInt(sCookie_ExpNeeded);
	
	ShowHudText(client, -1, "[ Level : %i | Exp : %i/%i ]", level[client] , exp[client] , exp_need[client] );
	CreateTimer(0.50, RefreshStat, GetClientSerial(client), TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	decl String:sCookie_Level[11];
	decl String:sCookie_Exp[11];
	decl String:sCookie_ExpNeeded[11];		
				
	IntToString(exp[client], sCookie_Exp, sizeof(sCookie_Exp));
	IntToString(exp_need[client], sCookie_ExpNeeded, sizeof(sCookie_ExpNeeded));
	IntToString(level[client], sCookie_Level, sizeof(sCookie_Level));

	SetClientCookie(client, Cookie_Exp, sCookie_Exp);
	SetClientCookie(client, Cookie_Level, sCookie_Level);
	SetClientCookie(client, Cookie_ExpNeeded, sCookie_ExpNeeded);
}

public Action:SetScoreTo0(client, args)
{
	if(client > 0 && client < MAXPLAYERS && IsClientInGame(client))
	{
		exp[client] = 0;
		level[client] = 0;
		exp_need[client] = 0;
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(killer != victim)
	{
		exp[killer]+= 5;
		if(exp[killer] > exp_need[killer])
		{
			exp[killer] -= exp_need[killer];
			exp_need[killer] += 7;
			level[killer]++;
		}
	}
	
	return Plugin_Continue;
}

public Action:RefreshStat(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if(client == 0)
	{
		return Plugin_Continue;
	}
	
	ShowHudText(client, -1, "[ Level : %i | Exp : %i/%i ]", level[client] , exp[client] , exp_need[client] );
	
	return Plugin_Handled;
}
	