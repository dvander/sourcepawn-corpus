#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:h_cvarWarnings;
new String:KillerList[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
new String:VictimList[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
new KilledBy[MAXPLAYERS+1];
new Warnings[MAXPLAYERS+1];
new ACCOUNT_OFFSET;

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "Simple CS:GO TK Menu: Warn, Cash Steal",
	author = "Sheepdude",
	description = "Displays a TK Menu that lets TK victims steal cash",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

public OnPluginStart()
{
	h_cvarWarnings = CreateConVar("sm_tkwarnmenu_warnings", "3", "How many warnings until a client is kicked", 0, true, 1.0);
	ACCOUNT_OFFSET = FindSendPropOffs("CCSPlayer", "m_iAccount");
	HookEventEx("player_death", PlayerDeathEvent);
}

public OnMapStart()
{
	for(new i = 0; i <= MAXPLAYERS; i++)
		Warnings[i] = 0;
}

public OnClientDisconnect(client)
{
	Warnings[client] = 0;
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
	AddMenuItem(menu, "1", "Warn");
	AddMenuItem(menu, "2", "Steal 25\% Cash");
	AddMenuItem(menu, "3", "Slay");
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
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x03 %s\x01 has forgiven\x03 %s\x01 for team killing.", VictimList[param1], KillerList[param1]);
		else if(param2 == 1)
		{
			Warnings[KilledBy[param1]]++;
			PrintToChat(KilledBy[param1], "\x01\x0B\x04[TKMenu]\x03 %s\x01 has given you a warning, after %i warnings you will be kicked. (Currently %i)", VictimList[param1], GetConVarInt(h_cvarWarnings), Warnings[KilledBy[param1]]);
			if(Warnings[KilledBy[param1]] > GetConVarInt(h_cvarWarnings) && IsClientInGame(KilledBy[param1]))
				KickClient(KilledBy[param1]);
		}
		else if(param2 == 2 && IsClientInGame(param1) && IsClientInGame(KilledBy[param1]))
		{
			new KillerMoney = GetEntData(KilledBy[param1], ACCOUNT_OFFSET, 4);
			new VictimMoney = GetEntData(param1, ACCOUNT_OFFSET, 4);
			new difference = RoundToFloor(KillerMoney * 0.25);
			SetEntData(KilledBy[param1], ACCOUNT_OFFSET, KillerMoney - difference, 4, true);
			if(VictimMoney + difference > 16000)
				SetEntData(param1, ACCOUNT_OFFSET, 16000, 4, true);
			else
				SetEntData(param1, ACCOUNT_OFFSET, VictimMoney + difference, 4, true);
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x03 %s\x01 stole \x05$%d\x01 from\x03 %s\x01 for team killing.", VictimList[param1], difference, KillerList[param1]);
		}
		else if(param2 == 3 && IsClientInGame(KilledBy[param1]))
		{
			CreateTimer(0.0, Slay, KilledBy[param1], TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x03 %s\x01 was slain for team killing\x03 %s\x01.", KillerList[param1], VictimList[param1]);
		}
	}
}

public Action:Slay(Handle:timer, any:client)
{
	ForcePlayerSuicide(client);
}