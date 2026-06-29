#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:h_iProtectTime;
new Handle:h_bProtectEnable;
new String:KillerList[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
new String:VictimList[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
new KilledBy[MAXPLAYERS+1];
new ACCOUNT_OFFSET;
new iVictim;

#define PLUGIN_VERSION "1.2.1"

public Plugin:myinfo =
{
	name = "Simple CS:GO TK Menu + Round Start Protection",
	author = "Sheepdude, [W]atch [D]ogs",
	description = "Displays a TK Menu that lets TK victims steal cash",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

public OnPluginStart()
{
	h_bProtectEnable = CreateConVar("tk_round_protect_enable", "1", "Enable / Disable round protection", _, true, 0.0, true, 1.0);
	h_iProtectTime = CreateConVar("tk_round_protect_time", "10", "Round protection time in seconds", _, true, 1.0);
	
	ACCOUNT_OFFSET = FindSendPropOffs("CCSPlayer", "m_iAccount");
	HookEventEx("player_death", PlayerDeathEvent);
	HookEvent("round_start", OnRoundStart);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(h_bProtectEnable))
		return Plugin_Continue;
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
	}
	CreateTimer(GetConVarFloat(h_iProtectTime), RemoveProtection, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
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
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
			{
				doTKMenu(i, victim);
			}
		}
	}
}

public doTKMenu(client, victim)
{
	decl String:menuTitle[64], String:sVictim[8];
	Format(menuTitle, sizeof(menuTitle), "Team Killer! %s were killed by %s, choose an action:", VictimList[victim], KillerList[victim]);
	IntToString(victim, sVictim, sizeof(sVictim));
	
	new Handle:menu = CreateMenu(handleTKVoteMenu);
	SetMenuTitle(menu, menuTitle);
	AddMenuItem(menu, sVictim, "Just Respawn Victim");
	AddMenuItem(menu, sVictim, "Give 25\% Cash of Killer to Victim - Respawn Victim");
	AddMenuItem(menu, sVictim, "Slay Killer - Respawn Victim");
	AddMenuItem(menu, sVictim, "Kick Killer - Respawn Victim");
	AddMenuItem(menu, sVictim, "Ban Killer - Respawn Victim");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleTKVoteMenu(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:sItem[8];
		GetMenuItem(menu, param2, sItem, sizeof(sItem));
		new victim = StringToInt(sItem);
		if(param2 == 0)
		{
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s was respawned by admin", VictimList[victim]);
			CS_RespawnPlayer(victim);
		}
		else if(param2 == 1 && IsClientInGame(victim) && IsClientInGame(KilledBy[victim]))
		{
			new KillerMoney = GetEntData(KilledBy[victim], ACCOUNT_OFFSET, 4);
			new VictimMoney = GetEntData(victim, ACCOUNT_OFFSET, 4);
			new difference = RoundToFloor(KillerMoney * 0.25);
			SetEntData(KilledBy[victim], ACCOUNT_OFFSET, KillerMoney - difference, 4, true);
			if(VictimMoney + difference > 16000)
				SetEntData(victim, ACCOUNT_OFFSET, 16000, 4, true);
			else
				SetEntData(victim, ACCOUNT_OFFSET, VictimMoney + difference, 4, true);
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s stole \x05$%d\x01 from %s for team killing.", VictimList[victim], difference, KillerList[victim]);
			CS_RespawnPlayer(victim);
		}
		else if(param2 == 2 && IsClientInGame(KilledBy[victim]) && IsClientInGame(victim))
		{
			CreateTimer(0.0, Slay, KilledBy[victim], TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s was slain for team killing %s.", KillerList[victim], VictimList[victim]);
			CS_RespawnPlayer(victim);
		}
		else if(param2 == 3 && IsClientInGame(KilledBy[victim]) && IsClientInGame(victim))
		{
			KickClient(KilledBy[victim], "Kicked By Admin. Reason: Team Killing");
			PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s was kicked for team killing %s.", KillerList[victim], VictimList[victim]);
			CS_RespawnPlayer(victim);
		}
		else if(param2 == 4 && IsClientInGame(KilledBy[victim]) && IsClientInGame(victim))
		{
			new Handle:hmenu = CreateMenu(MenuHandler_BanTimeList);
			
			SetMenuTitle(hmenu, "Ban Team-Killer");
		
			AddMenuItem(hmenu, "0", "Permanent");
			AddMenuItem(hmenu, "10", "10 Minutes");
			AddMenuItem(hmenu, "30", "30 Minutes");
			AddMenuItem(hmenu, "60", "1 Hour");
			AddMenuItem(hmenu, "240", "4 Hours");
			AddMenuItem(hmenu, "1440", "1 Day");
			AddMenuItem(hmenu, "10080", "1 Week");
			
			iVictim = victim;
		
			DisplayMenu(hmenu, param1, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler_BanTimeList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		BanClient(KilledBy[iVictim], StringToInt(info), BANFLAG_AUTHID, "Team Killing", "Banned By Admin. Reason: Team Killing");
		PrintToChatAll("\x01\x0B\x04[TKMenu]\x01 %s was banned for team killing %s.", KillerList[iVictim], VictimList[iVictim]);
		CS_RespawnPlayer(iVictim);
	}
}

public Action:Slay(Handle:timer, any:client)
{
	ForcePlayerSuicide(client);
}

public Action:RemoveProtection(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		}
	}
}