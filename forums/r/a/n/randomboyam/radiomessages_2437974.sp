#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

new ExplosionTime, LastBombPlanner, LastSaper;
new bool:BombBeepInProgress = false;
new bool:BombBeginDefuse = false;
new Handle:Timer1 = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "AutoRadioMessage",
	author = "anacron",
	description = ":)",
	version = "1.0",
	url = "http://anacron.pl"
}
public OnPluginStart()
{
	HookEvent("round_end",Event_round_end,EventHookMode_Post);
	HookEvent("player_hurt",EVENT_player_hurt,EventHookMode_Post);
	HookEvent("player_death",EVENT_player_death,EventHookMode_Post);
	HookEvent("bomb_beginplant",EVENT_bomb_beginplant,EventHookMode_Post);
	HookEvent("bomb_begindefuse",EVENT_bomb_begindefuse,EventHookMode_Post);
	HookEvent("bomb_planted",EVENT_bomb_planted,EventHookMode_Post);
	HookEvent("bomb_beep",EVENT_bomb_beep,EventHookMode_Post);
	PrecacheSound("bot/stop_it.wav",true);
	RegConsoleCmd("takepoint", RestrictRadio);
	RegConsoleCmd("regroup", RestrictRadio);
	RegConsoleCmd("go", RestrictRadio);
	RegConsoleCmd("fallback", RestrictRadio);
	RegConsoleCmd("followme", RestrictRadio);
	RegConsoleCmd("sticktog", RestrictRadio);
	RegConsoleCmd("getinpos", RestrictRadio);
	RegConsoleCmd("stormfront", RestrictRadio);
	RegConsoleCmd("report", RestrictRadio);
	RegConsoleCmd("roger", RestrictRadio);
	RegConsoleCmd("sectorclear", RestrictRadio);
	RegConsoleCmd("inposition", RestrictRadio);
	RegConsoleCmd("reportingin", RestrictRadio);
	RegConsoleCmd("negative", RestrictRadio);
	RegConsoleCmd("enemyspot", RestrictRadio);
	CreateConVar("sm_autoradio","1.0","Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnMapStart()
{
	PrecacheSound("bot/stop_it.wav",true);
}
public Event_round_end(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(Timer1 != INVALID_HANDLE)
	{
		CloseHandle(Timer1);
		Timer1 = INVALID_HANDLE;
	}
}
public EVENT_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	if (victim != attacker)
	{
		if(attacker != 0)
		{
			if(GetClientTeam(victim) == GetClientTeam(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker))
			{
				EmitSoundToClient(attacker,"bot/stop_it.wav");
			}
		}
	}
}
public EVENT_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new victim_team = GetClientTeam(victim);
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	if(attacker != 0)
	{
		new attacker_team = GetClientTeam(attacker);
		if(victim_team != attacker_team && IsPlayerAlive(attacker) && !IsFakeClient(attacker))
		{
			FakeClientCommand(attacker,"enemydown");
		}
	}
}
public EVENT_bomb_beginplant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(LastBombPlanner != client)
	{
		LastBombPlanner = client;
		if(IsPlayerAlive(client) && !IsFakeClient(client))
		{
			FakeClientCommand(client,"coverme");
		}
	}
}
public EVENT_bomb_begindefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	BombBeginDefuse = true;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(LastSaper != client)
	{
		LastSaper = client;
		if(IsPlayerAlive(client) && !IsFakeClient(client))
		{
			FakeClientCommand(client,"needbackup");
		}
	}
}
public EVENT_bomb_abortdefuse()
{
	BombBeginDefuse = false;
}
public EVENT_bomb_planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new mp_c4timer = GetConVarInt(FindConVar("mp_c4timer"));
	ExplosionTime = GetTime() + mp_c4timer;
	Timer1 = CreateTimer(3.0,HoldPos,_,TIMER_FLAG_NO_MAPCHANGE); 
}
public Action:HoldPos(Handle:timer)
{
	if(IsPlayerAlive(LastBombPlanner) && !IsFakeClient(LastBombPlanner))
	{
		FakeClientCommand(LastBombPlanner,"holdpos");
	}
}
public EVENT_bomb_beep(Handle:event, const String:name[], bool:dontBroadcast)
{
	new timebeep = GetTime();
	new time2explosion = ExplosionTime - timebeep;
	if (time2explosion <= 5 && !BombBeepInProgress && !BombBeginDefuse)
	{
		BombBeepInProgress = true;
		if(IsPlayerAlive(LastBombPlanner) && !IsFakeClient(LastBombPlanner))
		{
			FakeClientCommand(LastBombPlanner,"getout");
		}
		else
		{
			new client = 0;
			new bool:message = false;
			while(!message || client <= MaxClients)
			{
				if(GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client) && !IsFakeClient(client))
				{
					message = true;
					FakeClientCommand(client,"getout");
				}
				client++;
			}
		}
	}	
}
public Action:RestrictRadio(client,args)
{
	return Plugin_Handled;
}
