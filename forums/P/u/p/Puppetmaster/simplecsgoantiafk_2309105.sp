#include <sourcemod> 
#include <cstrike>
#include <clientprefs>
#include <sdktools>


#define PLUGIN_VERSION "0.0.8"

float positions[320][3];
float positionsTemp[320][3];

int times[320];

//convars
ConVar sm_simplecsgoantiafk_kicktype
ConVar sm_simplecsgoantiafk_dm
ConVar sm_simplecsgoantiafk_time

//begin
public Plugin:myinfo =
{
	name = "SimpleCSGOAntiAFK",
	author = "Puppetmaster",
	description = "SimpleCSGOAntiAFK Addon",
	version = PLUGIN_VERSION,
	url = "https://gamingzoneservers.com/"
};

//called at start of plugin, sets everything up.
public OnPluginStart()
{
	sm_simplecsgoantiafk_kicktype = CreateConVar("sm_simplecsgoantiafk_kicktype", "1", "Sets whether to kick to spec (1) or to kick out of match (2)")
	sm_simplecsgoantiafk_dm = CreateConVar("sm_simplecsgoantiafk_dm", "0", "Sets whether the game is deathmatch 0 or 1")
	sm_simplecsgoantiafk_time = CreateConVar("sm_simplecsgoantiafk_time", "20", "Sets the time of the check in seconds after the start of the round")
	HookEvent("round_poststart", Event_RoundStart) //new round

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre) //The following are times to check
	HookEvent("bomb_defused", Event_BombDefused) //bomb gets defused
	HookEvent("bomb_exploded", Event_BombExploded) //bomb went off
	HookEvent("weapon_reload", Event_WeaponReload) //someone reloads
}



public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast) //new
{
	checkPositions();
	return Plugin_Continue;
}

public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast){
	int gameType;
	gameType = GetConvar2();
	if(gameType != 0) {
		CreateTimer((GetConvar3()), Timer_AntiAFK_DM, _, TIMER_REPEAT);
	}
	else{
		updatePositions();	
	}
	return Plugin_Continue;
}

//event is called every time a player dies.
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	checkPositions();
	return Plugin_Continue;
}

public Action:Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{	
	checkPositions();
	return Plugin_Continue;
}

public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{	
	checkPositions();
	return Plugin_Continue;
}

public Action:Timer_AntiAFK(Handle:timer)
{
	checkPositions();
	return Plugin_Continue;
}

public Action:Timer_AntiAFK_DM(Handle:timer)
{
	updatePositions();
	return Plugin_Continue;
}

public Action:Timer_AntiAFKWarning(Handle:timer)
{
	checkPositionsWarning();
	return Plugin_Continue;
}

public updatePositions(){
	PrintToServer("New Round, Getting players positions for AFK checking");
	new maxclients = GetMaxClients()
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			GetClientEyePosition(i, positions[i]);
			times[i] = GetTime();
		}
	}


	CreateTimer((GetConvar3()), Timer_AntiAFK);
	CreateTimer((GetConvar3()/2), Timer_AntiAFKWarning);
}

public checkPositions(){
	new maxclients = GetMaxClients()
	int kickType;
	decl String:name1[64];
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			GetClientEyePosition(i, positionsTemp[i]);
			if(positionsTemp[i][0] == positions[i][0]) //heavily nested so that additional logic checks will not be done unless atleast the first bit is done
			{
				if(positionsTemp[i][1] == positions[i][1] && positionsTemp[i][2] == positions[i][2] && GetTime() > times[i]+20 && IsPlayerAlive(i) && GetClientTeam(i) > 1 && !IsFakeClient(i) && !IsClientSourceTV(i)) //move to spec after 20 seconds of afk
				{
					kickType = GetConvar() //load the convar kick type
					if(kickType == 1)
					{
						ChangeClientTeam(i, 1); //move to spec
						GetClientName(i, name1, sizeof(name1));
						PrintToChatAll("Player %s moved to spectator for being AFK too long.", name1);
						PrintToServer("Player %s moved to spectator for being AFK too long.", name1);
					}
					else
					{
						GetClientName(i, name1, sizeof(name1));
						PrintToChatAll("Player %s was kicked for being AFK too long.", name1);
						PrintToServer("Player %s was kicked for being AFK too long.", name1);
						KickClientEx(i, "Kicked for being AFK too long.");
					}
				}
			}
		}
	}
}

public checkPositionsWarning(){
	new maxclients = GetMaxClients()
	int kickType;
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			GetClientEyePosition(i, positionsTemp[i]);
			if(positionsTemp[i][0] == positions[i][0]) //heavily nested so that additional logic checks will not be done unless atleast the first bit is done
			{
				if(positionsTemp[i][1] == positions[i][1] && positionsTemp[i][2] == positions[i][2] && GetTime() > times[i]+9 && IsPlayerAlive(i) && GetClientTeam(i) > 1 && !IsFakeClient(i) && !IsClientSourceTV(i)) //move to spec after 20 seconds of afk
				{
					//tell player they will be kicked in 10 seconds
					kickType = GetConvar() //load the convar kick type
					if(kickType == 1)
					{
						PrintToChat(i, "You will be moved to spectator if you do not move soon.");
					}
					else
					{
						PrintToChat(i, "You will be kicked if you do not move soon.");
					}
				}
			}
		}
	}
}

public int GetConvar()
{
	char buffer[128]
 
	sm_simplecsgoantiafk_kicktype.GetString(buffer, 128)
 
	return StringToInt(buffer)
}

public int GetConvar2()
{
	char buffer[128]
 
	sm_simplecsgoantiafk_dm.GetString(buffer, 128)
 
	return StringToInt(buffer)
}

public float GetConvar3()
{
	char buffer[128]
 
	sm_simplecsgoantiafk_time.GetString(buffer, 128)
 
	return StringToFloat(buffer)
}
