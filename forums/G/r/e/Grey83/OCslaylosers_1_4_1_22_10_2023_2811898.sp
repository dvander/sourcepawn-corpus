/**
 * Slays losers on round timer end AND round end (default)
 * (didnt plant and time was up, didnt touch / rescue all hostage when time was up)
 * (bomb exploded or defused triggers this round end!)
 *
 * OR:
 *
 * Slay losers on objectives lost/completed ONLY
 * (such as bomb explode, defuse, and all hostages rescued)
 * If bomb wasnt planted then this will not do anything.
 *
 * Admins can be immune to the slay
 */

#pragma semicolon 1

#include <colors>

#pragma newdecls required

#include <sdktools_functions>

static const char
	PL_NAME[]	= "Slay Losers",
	PL_VER[]	= "1.4.1_22.10.2023 (rewritten by Grey83)",

	SLAY_MSG[]	= "Counter Terrorists have been slayed for not completing the objectives";

enum
{
	CS_TEAM_NONE,
	CS_TEAM_SPECTATOR,
	CS_TEAM_T,
	CS_TEAM_CT
};

bool
	bEnable,
	bImmunity,
	bTime,
	bLose,
	bHostage,

	bHostageTouched,
	bCanSlay;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Slays losers on timer round end and or objectives lost",
	author		= "DarkEnergy - Ownz and Frezzy",
	url			= "www.ownageclan.com"
}

public void OnPluginStart()
{
	LoadTranslations("slaylosers.phrases");

	CreateConVar("oc_slaylosers_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("slaylosers_enabled", "1", "Is this plugin enabled, the master on off switch", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Enable);
	CVarChange_Enable(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("slaylosers_admin_immunity", "1", "Admins should not be slayed", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Immunity);
	bImmunity = cvar.BoolValue;

	cvar = CreateConVar("slaylosers_slay_objectives", "0", "Slay losers if an objective is completed (bomb, defuse, all hostages)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Lose);
	CVarChange_Lose(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("slaylosers_slay_round_timer", "1", "Slay losers if round timer is up (didnt plant and time was up etc)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Time);
	CVarChange_Time(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("slaylosers_skipiftouchedhostage", "1", "CTs should not be slayed if they touched a hostage", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Hostage);
	bHostage = cvar.BoolValue;

	AutoExecConfig(true, "slaylosers");

	HookEvent("round_start", Event_Start, EventHookMode_PostNoCopy);		// before freezetime
	HookEvent("round_freeze_end", Event_Start, EventHookMode_PostNoCopy);	// after freezetime
	HookEvent("hostage_follows", Event_Hostage, EventHookMode_PostNoCopy);
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
	EventHookToggle();
}

public void CVarChange_Immunity(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bImmunity = cvar.BoolValue;
}

public void CVarChange_Lose(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bLose = cvar.BoolValue;
	EventHookToggle();
}

public void CVarChange_Time(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bTime = cvar.BoolValue;
	EventHookToggle();
}

public void CVarChange_Hostage(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bHostage = cvar.BoolValue;
}

void EventHookToggle()
{
	static bool hooked_time, hooked_lose;

	if(!bEnable)
	{
		if(hooked_time)
			UnhookEvent("round_end", Event_Time);

		if(hooked_lose)
		{
			UnhookEvent("bomb_defused", Event_Lose, EventHookMode_PostNoCopy);
			UnhookEvent("bomb_exploded", Event_Lose, EventHookMode_PostNoCopy);
			UnhookEvent("hostage_rescued_all", Event_Lose, EventHookMode_PostNoCopy);
		}
		hooked_time = hooked_lose = false;

		return;
	}

	if(bTime != hooked_time)
	{
		if((hooked_time ^= true))
			HookEvent("round_end", Event_Time);
		else UnhookEvent("round_end", Event_Time);
	}

	if(bLose != hooked_lose)
	{
		if((hooked_lose ^= true))
		{
			HookEvent("bomb_defused", Event_Lose, EventHookMode_PostNoCopy);
			HookEvent("bomb_exploded", Event_Lose, EventHookMode_PostNoCopy);
			HookEvent("hostage_rescued_all", Event_Lose, EventHookMode_PostNoCopy);
		}
		else
		{
			UnhookEvent("bomb_defused", Event_Lose, EventHookMode_PostNoCopy);
			UnhookEvent("bomb_exploded", Event_Lose, EventHookMode_PostNoCopy);
			UnhookEvent("hostage_rescued_all", Event_Lose, EventHookMode_PostNoCopy);
		}
	}
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	if(name[6] == 'f') bCanSlay = true;
	else bHostageTouched = bCanSlay = false;
}

public void Event_Hostage(Event event, const char[] name, bool dontBroadcast)
{
	bHostageTouched = true;
}

public void Event_Time(Event event, const char[] name, bool dontBroadcast)
{
	int winner = GetEventInt(event, "winner");
	if(winner < CS_TEAM_T)
		return;

	if(winner == CS_TEAM_T && bHostage && bHostageTouched) //do not slay CT if CTs touched a hostage
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
			CPrintToChat(i, "%t%t", "[Slay Losers]", "Counter Terrorists have been spared for touching at least one hostage");
		return;
	}

	CreateTimer(0.1, SlayTeam, winner == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT);
}

public void Event_Lose(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, SlayTeam, name[5] == 'e' ? CS_TEAM_CT : CS_TEAM_T);
}

public Action SlayTeam(Handle timer, int team)
{
	if(!bCanSlay)	// avoid slaying right after round starts, if bomb explodes 0.1 seconds before a new round
		return Plugin_Stop;

	int i = 1, clients[MAXPLAYERS], alive, num;
	for(; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(!IsFakeClient(i) || IsClientReplay(i) || IsClientSourceTV(i))
			clients[num++] = i;

		if(GetClientTeam(i) == team && IsPlayerAlive(i)
		&& (!bImmunity || GetUserAdmin(i) == INVALID_ADMIN_ID))
		{
			alive++;
			ForcePlayerSuicide(i);
		}
	}

	if(alive)	// выводим текст только если было кого наказывать
	{
		i = 0;
		for(int start = team == CS_TEAM_T ? 8 : 0; i < num; i++) CPrintToChat(clients[i], "%t%t", "[Slay Losers]", SLAY_MSG[start]);
	}

	bCanSlay = false;
	return Plugin_Stop;
}