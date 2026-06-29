//added counts for headshots and kills that will reset after a bit.

#include <sourcemod>
#pragma semicolon 1
#define VERSION "0.9.5"
#define MAX_PLAYERS 256

public Plugin:myinfo = {
	name = "L4D Broadcast",
	author = "Voiderest",
	description = "Displays extra info for kills and friendly fire.",
	version = VERSION,
	url = "N/A"
}

new Handle:broadcast=INVALID_HANDLE;
new Handle:broadcast_ply=INVALID_HANDLE;
new Handle:kill_timers[MAX_PLAYERS+1][2];
new kill_counts[MAX_PLAYERS+1][2];

public OnPluginStart() {
	//create new cvars
	broadcast = CreateConVar("l4d_broadcast_kill", "1", "0: Off. 1: On. 2: Headshots only.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,2.0);
	broadcast_ply = CreateConVar("l4d_broadcast_ff", "3", "0: Off 1: Console 2: Console + Hint 3: Those involved only.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,3.0);
	
	//hook events
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Post);
	HookEvent("player_death", Event_Player_Death, EventHookMode_Pre);
	
	AutoExecConfig(true,"l4d_broadcast");
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker =  GetClientOfUserId(attacker_userid);
	new bool:headshot = GetEventBool(event, "headshot");
	
	if (attacker == 0 || GetClientTeam(attacker) == 1)
	{
		return Plugin_Continue;
	}
	
	printkillinfo(attacker_userid, attacker, headshot);
	
	return Plugin_Continue;
}

printkillinfo(attacker_userid, attacker, bool:headshot)
{
	new intbroad=GetConVarInt(broadcast);
	new murder;
	
	if ((intbroad >= 1) && headshot)
	{
		murder = kill_counts[attacker_userid][0];
		
		if(murder>1)
		{
			PrintCenterText(attacker, "HEADSHOT! +%d", murder);
			KillTimer(kill_timers[attacker_userid][0]);
		}
		else
		{
			PrintCenterText(attacker, "HEADSHOT!");
		}
		
		kill_timers[attacker_userid][0] = CreateTimer(5.0, KillCountTimer, (attacker_userid*10));
		kill_counts[attacker_userid][0] = murder+1;
	}
	else if (intbroad == 1)
	{
		murder = kill_counts[attacker_userid][1];
		
		if(murder>=1)
		{
			PrintCenterText(attacker, "KILL! +%d", murder);
			KillTimer(kill_timers[attacker_userid][1]);
		}
		else
		{
			PrintCenterText(attacker, "KILL!");
		}
		
		kill_timers[attacker_userid][1] = CreateTimer(5.0, KillCountTimer, ((attacker_userid*10)+1));
		kill_counts[attacker_userid][1] = murder+1;
	}
}

public Action:KillCountTimer(Handle:timer, any:info) {
	new id=info-(info%10);
	info=info-id;
	id=id/10;
	
	kill_counts[id][info]=0;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attacker_userid);

	//Kill everything if...
	if (attacker == 0 || client == 0 || GetClientTeam(attacker) != GetClientTeam(client) || GetConVarInt(broadcast_ply) == 0) {
		return Plugin_Continue;
	}
	
	new String:hit[32];
	switch (GetEventInt(event, "hitgroup"))
	{
		case 1:
		{
			hit="'s head";
		}
		case 2:
		{
			hit="'s chest";
		}
		case 3:
		{
			hit="'s stomach";
		}
		case 4:
		{
			hit="'s left arm";
		}
		case 5:
		{
			hit="'s right arm";
		}
		case 6:
		{
			hit="'s left leg";
		}
		case 7:
		{
			hit="'s right leg";
		}
		default:
		{}
	}
	
	new String:buf[128];
	Format(buf, 128, "%N hit %N%s.", attacker, client, hit);
	PrintToServer(buf);
	if (GetConVarInt(broadcast_ply) == 2)
	{
		PrintToTeam(GetClientTeam(attacker), buf);
	}
	if (GetConVarInt(broadcast_ply) >= 2)
	{
		PrintHintText(attacker, "You hit %N%s.", client, hit);
		ReplaceString(hit, 32, "'s", "r");
		PrintToChat(client, "%N hit you%s.", attacker, hit);
	}
	else
	{
		PrintToConsole(attacker, "You hit %N%s.", client, hit);
		ReplaceString(hit, 32, "'s", "r");
		PrintToConsole(client, "%N hit you%s.", attacker, hit);
	}
	
	return Plugin_Continue;
}

public PrintToTeam(team, const String:msg[])
{
	for(new i = 1; i < GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i))
		{
			PrintToConsole(i, msg);
		}
	}
}
