#pragma semicolon 1

#include <sourcemod>
#include <smlib>

new victimID[MAXPLAYERS+1];
new String:Weapon[64];
new bool:killed[MAXPLAYERS+1] = true;
new playertokill[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "CS Assasin Display",
	author = "Arkarr",
	description = "Display HUD message.",
	version = "1.0",
	url = "http://www.sourcemod.com"
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnSpawn, EventHookMode_Post);
	HookEvent("player_death", OnDeath, EventHookMode_Post);
}

public OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && IsPlayerAlive(client))
		CreateTimer(1.0, DisplayMessageTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(playertokill[killer] == victim)
	{
		killed[killer] = true;
	}
	
	if(killer == victim)
	{
		killed[killer] = true;
	}
}

public Action:DisplayMessageTimer(Handle:timer, any:client)
{
	if(client > 0 && IsPlayerAlive(client) && IsClientConnected(client))
	{
		if(killed[client] == true)
		{
			victimID[client] = Math_GetRandomInt(1, GetClientCount());
			
			do
			{
				DisplayMessage(client, victimID[client]); 
				return Plugin_Handled;
			}while(IsPlayerAlive(victimID[client]) && IsClientInGame(victimID[client]) && victimID[client] != client);
		}
		else
		{
			DisplayMessage(client, victimID[client]); 
		}
	}
	return Plugin_Continue;
}

stock DisplayMessage(client, victim)
{
	if(client > 0 && IsPlayerAlive(client) && victim > 0 && IsPlayerAlive(victim))
	{
		decl String:AssName[100];
		GetClientWeapon(victim, Weapon, sizeof(Weapon));
		GetClientName(victim, AssName, sizeof(AssName));
		decl String:szText[250]; 
		Format(szText, sizeof(szText), "============ASSASSIN============\nPlayer to kill %s\nHis actual weapon : %s", AssName, Weapon); 
		
		Client_PrintKeyHintText(client, szText); 
		playertokill[client] = victim;
		killed[client] = false;
	}
} 