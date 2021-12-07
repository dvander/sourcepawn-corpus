#include <sourcemod>
#pragma semicolon 1
#define VERSION "0.9"

public Plugin:myinfo = {
	name = "L4D Broadcast",
	author = "Voiderest",
	description = "Displays extra info for kills and friendly fire.",
	version = VERSION,
	url = "N/A"
}

new Handle:broadcast=INVALID_HANDLE;
new Handle:broadcast_ply=INVALID_HANDLE;

public OnPluginStart() {
	//create new cvars
	broadcast = CreateConVar("l4d_broadcast_kill", "0", "0: Off. 1: On. 2: Headshots only.",FCVAR_REPLICATED|FCVAR_CHEAT|FCVAR_NOTIFY,true,0.0,true,2.0);
	broadcast_ply = CreateConVar("l4d_broadcast_ff", "2", "0: Console 1: Console + Hint 2: Those involved only.",FCVAR_REPLICATED|FCVAR_CHEAT|FCVAR_NOTIFY,true,0.0,true,2.0);
	
	//hook events
	HookEvent("infected_death", Event_Infected_Death, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Post);
}

public Action:Event_Infected_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker =  GetClientOfUserId(attacker_userid);
	new headshot = GetEventBool(event, "headshot");
	
	if (attacker == 0)
	{
		return Plugin_Continue;
	}
	
	new String:extra[32]=".";
	if (headshot)
	{
		extra=" with a headshot.";
		PrintCenterText(attacker, "HEADSHOT!");
	}
	else
	{
		PrintCenterText(attacker, "KILL!");
	}
	
	if (GetConVarInt(broadcast) == 0 || (GetConVarInt(broadcast) == 2 && !headshot))
	{
		return Plugin_Continue;
	}
	else
	{
		
		new String:buf[128];
		Format(buf, 128, "%N killed an infected%s", attacker, extra);
		PrintToTeam(GetClientTeam(attacker), buf);
	}
	
	return Plugin_Continue;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attacker_userid);

	//PrintToServer("Type is %d.",);
	if (attacker == 0 || client == 0) {
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
	
	if (GetClientTeam(attacker) != GetClientTeam(client)) {
		return Plugin_Continue;
	}
	new String:buf[128];
	Format(buf, 128, "%N hit %N%s.", attacker, client, hit);
	PrintToServer(buf);
	if (GetConVarInt(broadcast_ply) == 1)
	{
		PrintToTeam(GetClientTeam(attacker), buf);
	}
	if (GetConVarInt(broadcast_ply) >= 1)
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
