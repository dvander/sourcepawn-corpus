#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required


//this original plugin made by benjamin1995
//me (superhalflifekid) updated this and change how it worked



//arrays keep track of player upgrades
bool ShouldGiveHealth[MAXPLAYERS+1];
bool ShouldGiveArmor[MAXPLAYERS+1];
bool ShouldGiveSpeed[MAXPLAYERS+1];
int PlayerKills[MAXPLAYERS+1];



public Plugin myinfo =
{
	name = "Powerups",
	author = "benjamin1995 (updated by superhalflifekid)",
	description = "You got Powerups",
	version = "2.0",
	url = "http://www.bfs-server.de"
};




//Initation:
public void OnPluginStart()
{
   	//hook Events:
	HookEvent("player_death", EventDeath);
	HookEvent("player_spawn", EventSpawn, EventHookMode_Pre);
	
	
	//convar to see version
	CreateConVar("Powerup_version", "2.0", "PowerUp Version", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}





//Give health powerup
public Action HealthPowerup(Handle Timer, any client)
{
	if (IsClientConnected(client) && !IsFakeClient(client)) //check if player connected and not bot
	{
		if (ShouldGiveHealth[client] && IsPlayerAlive(client)) //check to see if player not die
		{
			char sname[64];
			GetClientName(client, sname, 64);	
			
			PrintToChatAll("\x04%s got a Health Powerup +200hp.\x04", sname);
		
			int ClientHealth = GetClientHealth(client);
			SetEntityHealth(client, ClientHealth + 200);
			
			ShouldGiveHealth[client] = false;
		}
	}
	
  	return Plugin_Handled;
}




//Give armor powerup
public Action ArmorPowerup(Handle Timer, any client)
{
	if (IsClientConnected(client) && !IsFakeClient(client)) //check if player connected and not bot
	{
		if (ShouldGiveArmor[client] && IsPlayerAlive(client)) //check to see if player not die
		{
			char sname[64];
			GetClientName(client, sname, 64);	
			
			
			PrintToChatAll("\x04%s got a Armor Powerup +200.\x04", sname);
		
			int ClientArmor = GetEntProp(client, Prop_Data, "m_ArmorValue");
			SetEntProp(client, Prop_Data, "m_ArmorValue", ClientArmor+200);
			
			ShouldGiveArmor[client] = false;
		}
	}
	
  	return Plugin_Handled;
}


//Give speed powerup
public Action SpeedPowerup(Handle Timer, any client)
{
	if (IsClientConnected(client) && !IsFakeClient(client)) //check if player connected and not bot
	{
		if (ShouldGiveSpeed[client] && IsPlayerAlive(client)) //check to see if player not die
		{
			char sname[64];
			GetClientName(client, sname, 64);	
			
			PrintToChatAll("\x04%s got a Speed Powerup +33%.\x04", sname);
		
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.25);
			
			ShouldGiveSpeed[client] = false;
		}
	}
	
  	return Plugin_Handled;
}





//Death:
//keep track of player kills. if kill high enough, give upgrade
public Action EventDeath(Event event, const char[] name, bool dontBroadcast)
{
	//get killer client index
	int client = GetClientOfUserId(event.GetInt("attacker"));
	
	
	if (IsClientConnected(client) && !IsFakeClient(client)) //check if player connected and not bot
	{
		PlayerKills[client] += 1;
		
		if (PlayerKills[client] == 3)
		{
			ShouldGiveHealth[client] = true;
			CreateTimer(0.5, HealthPowerup, client);
		}
		
		if (PlayerKills[client] == 6)
		{
			ShouldGiveArmor[client] = true;
			CreateTimer(0.5, ArmorPowerup, client);
		}
		
		if (PlayerKills[client] == 9)
		{
			ShouldGiveSpeed[client] = true;
			CreateTimer(0.5, SpeedPowerup, client);
		}
		
	}
	
	

	return Plugin_Continue;
}



//Spawn:
//remove kills and clear upgrades. all arrays cleared
public Action EventSpawn(Event event, const char[] name, bool dontBroadcast)
{
	//get client index
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	
	//reset all variables
	ShouldGiveHealth[client] = false;
	ShouldGiveArmor[client] = false;
	ShouldGiveSpeed[client] = false;
	
	PlayerKills[client] = 0;
	
	
	return Plugin_Continue;
}

