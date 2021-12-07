#include <sourcemod>
#include <sdkhooks>
new Handle:vEnable;
new any:KillStreakCount[MAXPLAYERS+1];
new highest;
new highester;
public Plugin:myinfo =
{
	name = "Killstreak for each killed",
	author = "Dr_Newbie, Death Ringer fix by YoNer",
	description = "",
	version = "8b",
	url = "http://www.sourcemod.net/"
};
public OnPluginStart()
{
	vEnable = CreateConVar("sm_ks_drn", "1", "");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_win_panel", fw_TeamplayWinPanel, EventHookMode_Pre)
}
public Action:fw_TeamplayWinPanel(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	for(new iclient = 0; iclient <= MAXPLAYERS; iclient++) {
		KillStreakCount[iclient] = 0;
	}
	SetEventInt(hEvent, "killstreak_player_1", highester);
	SetEventInt(hEvent, "killstreak_player_1_count", highest);
	highester = 0;
	highest = 0;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(vEnable))
	{
		new attackerr = GetClientOfUserId(GetEventInt(event, "attacker"));
		new users = GetClientOfUserId(GetEventInt(event, "userid"));
		new assisterr = GetClientOfUserId(GetEventInt(event, "assister"));
//		decl String:deathf[32];
//		IntToString(GetEventInt(event, "death_flags"),deathf,sizeof(deathf));
//		PrintToConsole(users,deathf);
		if(attackerr != users && IsValidClient(attackerr) == true && IsValidClient(users) == true)
		{
			new nowks = GetEntProp(attackerr, Prop_Send, "m_nStreaks");
			if(nowks < KillStreakCount[attackerr])
				KillStreakCount[attackerr] = INVALID_HANDLE;
			KillStreakCount[attackerr] += 1;
			KillStreakCount[users] = INVALID_HANDLE;
			if( KillStreakCount[attackerr] >= 999 )
				KillStreakCount[attackerr] = 999;
			if( KillStreakCount[attackerr] < 0 )
				KillStreakCount[attackerr] = INVALID_HANDLE;
			SetEntProp(attackerr, Prop_Send, "m_nStreaks", KillStreakCount[attackerr]);
			SetEventInt(event, "kill_streak_wep", KillStreakCount[attackerr]);
			SetEventInt(event, "kill_streak_total", KillStreakCount[attackerr]);	
			
	
			
			if (GetEventInt(event, "death_flags") != 32)
			{
				SetEntProp(users, Prop_Send, "m_nStreaks", 0);
			}	
			if( highest < KillStreakCount[attackerr] ) {
				highester = attackerr;
				highest = KillStreakCount[attackerr];
			}
			if(IsValidClient(assisterr) == true && attackerr != assisterr)
			{
				new nowksas = GetEntProp(assisterr, Prop_Send, "m_nStreaks");
				if(nowksas < KillStreakCount[assisterr])
					KillStreakCount[assisterr] = INVALID_HANDLE;
				KillStreakCount[assisterr] = nowksas+1;
				if( KillStreakCount[assisterr] >= 999 )
					KillStreakCount[assisterr] = 999;
				if( KillStreakCount[assisterr] < 0 )
					KillStreakCount[assisterr] = INVALID_HANDLE;
				SetEntProp(assisterr, Prop_Send, "m_nStreaks", KillStreakCount[assisterr]);
				if( highest < KillStreakCount[assisterr] ) {
					highester = assisterr;
					highest = KillStreakCount[assisterr];
				}
			}
		}else
		{
			if (GetEventInt(event, "death_flags") != 32)
			{	
				if( IsValidClient(attackerr) )
					SetEntProp(attackerr, Prop_Send, "m_nStreaks", 0);
				if( IsValidClient(users) )
					SetEntProp(users, Prop_Send, "m_nStreaks", 0);
			}
		}
	}
}
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}