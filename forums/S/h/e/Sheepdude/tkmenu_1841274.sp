#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new String:KillerList[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
new String:VictimList[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
new KilledBy[MAXPLAYERS+1];
new ACCOUNT_OFFSET;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Simple CS:GO TK Menu: Cash Steal",
	author = "Sheepdude",
	description = "Displays a TK Menu that lets TK victims steal cash",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

public OnPluginStart()
{
	ACCOUNT_OFFSET = FindSendPropOffs("CCSPlayer", "m_iAccount");
	HookEventEx("player_death", PlayerDeathEvent);
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new killer = GetClientOfUserId(GetEventInt(event,"attacker"));
	GetClientName(killer, KillerList[victim], sizeof(KillerList[]));
	GetClientName(victim, VictimList[victim], sizeof(VictimList[]));
	KilledBy[victim] = killer;
	if(victim > 0 && victim <= MaxClients && killer > 0 && killer <= MaxClients && GetClientTeam(victim) == GetClientTeam(killer) && victim != killer && !IsFakeClient(victim))
	{
		doTKMenu(victim);
	}
}

public doTKMenu(victim)
{
	decl String:menuTitle[64];
	Format(menuTitle, sizeof(menuTitle), "You were killed by %s, choose an action:", KillerList[victim]);
	new Handle:menu = CreateMenu(handleTKVoteMenu);
	SetMenuTitle(menu, menuTitle);
	AddMenuItem(menu, "0", "Forgive");
	AddMenuItem(menu, "1", "Steal 25\% Cash");
	AddMenuItem(menu, "2", "Slay");
	DisplayMenu(menu, victim, MENU_TIME_FOREVER);
}

public handleTKVoteMenu(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(param2 == 0)
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s has forgiven %s for team killing.", VictimList[param1], KillerList[param1]);
		else if(param2 == 1 && IsClientInGame(param1) && IsClientInGame(KilledBy[param1]))
		{
			new KillerMoney = GetEntData(KilledBy[param1], ACCOUNT_OFFSET, 4);
			new VictimMoney = GetEntData(param1, ACCOUNT_OFFSET, 4);
			new difference = RoundToFloor(KillerMoney * 0.25);
			SetEntData(KilledBy[param1], ACCOUNT_OFFSET, KillerMoney - difference, 4, true);
			if(VictimMoney + difference > 16000)
				SetEntData(param1, ACCOUNT_OFFSET, 16000, 4, true);
			else
				SetEntData(param1, ACCOUNT_OFFSET, VictimMoney + difference, 4, true);
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s stole \x05$%d\x01 from %s for team killing.", VictimList[param1], difference, KillerList[param1]);
		}
		else if(param2 == 2 && IsClientInGame(KilledBy[param1]))
		{
			CreateTimer(0.0, Slay, KilledBy[param1], TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s was slain for team killing %s.", KillerList[param1], VictimList[param1]);
		}
	}
}

public Action:Slay(Handle:timer, any:client)
{
	ForcePlayerSuicide(client);
}