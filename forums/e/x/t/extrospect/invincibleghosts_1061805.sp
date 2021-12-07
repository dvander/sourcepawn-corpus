////////////////////////////////////////////////////////////////////////////
////////////////////////////// ``` ////////         ////////////////////////
//////////////////////////////   ////////   /////   ////////////////////////
/////////////////////////////   ////////   /////////////////////////////////
////////////////////////////   ////////   //      //////////////////////////
///////////////////////////   ////////    ////   ///////////////////////////
///////////////////////// ,,, ////////          ////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////  I N V I N C I B L E  ////////////////////////////
/////////////////////////////  G H O S T S  ////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//																		  //
//  - Makes infected ghosts invincible (>,<).							  //
//																		  //
//  - This prevents them from being killed by drowning and fall damage.	  //
//																		  //
//  - It's not a huge problem, but it is annoying when it happens; you	  //
//    get a ghost on a ledge or an edge and just as you go to turn 		  //
//    around you fall to your death and have another 30s to wait xP.	  //
//																		  //
//  - With this plugin, any big environmental damage event to a ghost	  //
//    will just cause them to teleport back to the survivors without 	  //
//    getting killed.													  //
//																		  //
////////////////////////////////////////////////////////////////////////////
  

#include <sourcemod>


#define MAX_PLAYERS 32
#define PLUGIN_VERSION "0.4"

#define ZC_SMOKER	1
#define ZC_BOOMER	2
#define ZC_HUNTER	3
#define ZC_SPITTER	4
#define ZC_JOCKEY	5
#define ZC_CHARGER	6
#define ZC_TANK		8


new propinfoghost;

new g_OldHealth[MAX_PLAYERS+1];
new bool:g_IsGhostBuffed[MAX_PLAYERS+1];

new bool:g_IsSwitchedInf[MAX_PLAYERS+1];
new bool:g_HasSpawnTimer[MAX_PLAYERS+1];
new bool:g_IsGhosting[MAX_PLAYERS+1];

new Handle:hResetGhostUse[MAX_PLAYERS+1];
new Handle:hCheckGhostsTimer[MAX_PLAYERS+1];
new Handle:hBuffGhostsTimer[MAX_PLAYERS+1];

new Handle:hHunterHealth;
new Handle:hSmokerHealth;
new Handle:hBoomerHealth;
new Handle:hSpitterHealth;
new Handle:hChargerHealth;
new Handle:hJockeyHealth;

public Plugin:myinfo = 
{
	name = "Invincible Ghosts",
	author = "extrospect",
	description = "Stops infected ghosts dying from fall damage and drowning etc.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116198"
}



public OnPluginStart()
{
	//If the plugin is loaded in a game other than L4D or L4D2 then stop here.
	decl String:gameMod[32];
	GetGameFolderName(gameMod, sizeof(gameMod));
	if(!StrEqual(gameMod, "left4dead", false) && !StrEqual(gameMod, "left4dead2", false))
	{
		SetFailState("Plugin supports L4D & L4D2 only.");
	}
	
	hHunterHealth = FindConVar("z_hunter_health");
	hSmokerHealth = FindConVar("z_gas_health");
	hBoomerHealth = FindConVar("z_exploding_health");
	hSpitterHealth = FindConVar("z_spitter_health");
	hChargerHealth = FindConVar("z_charger_health");
	hJockeyHealth = FindConVar("z_jockey_health");
	
	CreateConVar("l4d2_ig_ver",PLUGIN_VERSION,"Invincible Ghosts version",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookEvent("player_team", Event_SwitchTeam);
	HookEvent("player_hurt", Event_GhostDeath, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_InfSpawned);
	HookEvent("player_first_spawn", Event_InfFirstSpawn);
	HookEvent("ghost_spawn_time", Event_GhostSpawning);
}


//When a player switches to infected, their first ghost doesn't get a
//ghost_spawn_time event and so we need to start automatically checking every 1
//second to see when they become a ghost.
public Action:Event_SwitchTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	new newTeam = GetEventInt(event,"team");
	
	if(newTeam == 3 && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:switchPack;
		hCheckGhostsTimer[client] = CreateDataTimer(1.0, CheckGhost, switchPack);
		
		WritePackCell(switchPack,client);
		WritePackFloat(switchPack,1.0);
		
		g_IsSwitchedInf[client] = true;
	}
}



//When an infected player has died and their spawn timer restarts, this function fires
//and tells us how long til they respawn, we set a timer to 1 second before to begin 
//checking if they are a ghost yet, as soon as they are we then buff them to 20k hp
public Action:Event_GhostSpawning(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId);
	
	//Check if the client was already checking for ghosting due to switching to infected
	if(g_IsSwitchedInf[client])
	{
		//If the client has a ghost check coming cuz they swapped then kill the timer for 
		//it now that we know they won't be ghosting for X seconds 
		if (hCheckGhostsTimer[client] != INVALID_HANDLE)
		{
			KillTimer(hCheckGhostsTimer[client]);
			hCheckGhostsTimer[client] = INVALID_HANDLE;
		}
		//If the client has a ghost buff coming cuz they swapped then kill the timer for 
		//it now that we know they won't be ghosting for X seconds 
		if (hBuffGhostsTimer[client] != INVALID_HANDLE)
		{
			KillTimer(hBuffGhostsTimer[client]);
			hBuffGhostsTimer[client] = INVALID_HANDLE;
		}
		
		g_IsSwitchedInf[client] = false;
	}
	
	g_HasSpawnTimer[client] = true;
	
	if(!IsPlayerValid(client))
	return Plugin_Continue;
	
	new Float:tilSpawn = GetEventInt(event, "spawntime") - 4.0;
	
	new Handle:checkPack;
	hCheckGhostsTimer[client] = CreateDataTimer(tilSpawn, CheckGhost, checkPack);
		
	WritePackCell(checkPack,client);
	WritePackFloat(checkPack,0.25);

	return Plugin_Continue;
}



//This starts a repeating timer which checks whether the client is a ghost yet
//and then buffs their hp to 20000 once they are.
public Action:CheckGhost(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	new Float:loopTime = ReadPackFloat(pack);
	
	hBuffGhostsTimer[client] = CreateTimer(loopTime, BuffGhost, client, TIMER_REPEAT);
	
	hCheckGhostsTimer[client] = INVALID_HANDLE;
}



//This function is a repeating timer which checks whether the client is a ghost yet, if not
//then it carries on looping, otherwise it buff's their HP to 20k to make them 'invincible'
public Action:BuffGhost(Handle:timer, any:client)
{
	if(!IsPlayerValid(client))
	{
		hBuffGhostsTimer[client] = INVALID_HANDLE;
		return Plugin_Stop
	}
	else
	{
		if(IsPlayerSpawnGhost(client))
		{
			SetEntityHealth(client,20000);
			g_IsGhostBuffed[client] = true;
			g_OldHealth[client] = GetClientHealth(client);
			
			if(g_IsSwitchedInf[client])
			g_IsSwitchedInf[client] = false;
			
			if(g_HasSpawnTimer[client])
			g_HasSpawnTimer[client] = false;
			
			g_IsGhosting[client] = true;
						
			hBuffGhostsTimer[client] = INVALID_HANDLE;
			
			return Plugin_Stop;
		}
		else if(IsPlayerAlive(client))
		{
			hBuffGhostsTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		else
		{
			return Plugin_Continue;
		}
	}
}


//When player_hurt is fired, check if it was an infected ghost that got hurt & if so
//then teleport them back to the survs, set a timer to release use & flag them to be re-buffed
public Action:Event_GhostDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId);
	
	if(!IsPlayerValid(client) || !IsPlayerSpawnGhost(client) || !g_IsGhostBuffed[client])
	return Plugin_Continue;
	
	new String:weapon[64] = "";
	GetEventString(event,"weapon",weapon,sizeof(weapon));
	
	g_OldHealth[client] = GetClientHealth(client);
	
	if(StrEqual(weapon,""))
	{	
		ClientCommand(client,"+use");
	}
	
	hResetGhostUse[client] = CreateTimer(0.1,ResetGhostUse,client);
	
	g_IsGhostBuffed[client] = false;
	
	return Plugin_Continue;
}


//This just resets the ghost's 20k hp and releases use so they only teleport once [or twice >,<]
public Action:ResetGhostUse(Handle:timer, any:client)
{
	ClientCommand(client,"-use");
	
	if(IsPlayerValid(client) && IsPlayerSpawnGhost(client))
	{
		SetEntityHealth(client,20000);
		g_IsGhostBuffed[client] = true;
		g_OldHealth[client] = GetClientHealth(client);
	}
	
	hResetGhostUse[client] = INVALID_HANDLE;
}


//When a player dies check if they were a ghost and, if so, then start a repeating timer
//to check when they are a ghost again [for when a ghost manages to die or gets slayed -
//they dont get proper ghost_spawn_time events sometimes as a result]
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId);
	
	if(!IsPlayerValid(client))
	return Plugin_Continue;
	
	//If the dead client was a ghosting infected then start checking for them becoming a
	//ghost again after a delay which is based upon the # of players on the infected team.
	if(g_IsGhosting[client])
	{
		new infCount = GetInfectedCount();
		
		new Float:delay = 0.0;
		
		if(infCount == 2)
		{
			delay = 4.0;
		}
		else if(infCount == 3)
		{
			delay = 6.0;
		}
		else if(infCount > 3)
		{
			delay = 8.0;
		}
		else
		{
			delay = 2.0;
		}
		
		CreateTimer(delay, DeadGhostSpawnTimeCheck, client);
	}
	
	g_IsGhosting[client] = false;
	g_IsGhostBuffed[client] = false;
	g_IsSwitchedInf[client] = false;
	return Plugin_Continue;
}


//Gets the number of players currently on the infected team (both living and dead + including bots)
GetInfectedCount()
{
	new count;
	
	new i;
	i++;
	
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3)
			{
				count++;
			}
		}
		
		i++;
	}
	
	return count;
}



//If the player to be checked is still valid then start the repeating timer to
//check if they're a ghost and buff them accordingly by initiating the checkghost timer
public Action:DeadGhostSpawnTimeCheck(Handle:timer, any:client)
{
	if(!IsPlayerValid(client))
	return Plugin_Continue;
	
	if(g_HasSpawnTimer[client])
	return Plugin_Continue;
	
	new Handle:deadPack;
	hCheckGhostsTimer[client] = CreateDataTimer(0.6, CheckGhost, deadPack);
	
	WritePackCell(deadPack,client);
	WritePackFloat(deadPack,0.4);
	
	return Plugin_Continue;
}


//When a valid player spawns, buff them if they're a ghost, otherwise set their health
//back to the value defined for their current class by the console variables in OnPluginStart()
public Action:Event_InfSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId);
	
	if(!IsPlayerValid(client))
	return Plugin_Continue;
	
	if(IsPlayerSpawnGhost(client))
	{
		SetEntityHealth(client,20000);
		g_IsGhostBuffed[client] = true;
		g_OldHealth[client] = GetClientHealth(client);
		
		g_IsGhosting[client] = true;
	}
	else
	{
		new class;
		class = GetEntProp(client,Prop_Send,"m_zombieClass");
		
		new health = 100;
		
		if(class == ZC_HUNTER)
		{
			health = GetConVarInt(hHunterHealth);
		}
		if(class == ZC_SMOKER)
		{
			health = GetConVarInt(hSmokerHealth);
		}
		if(class == ZC_BOOMER)
		{
			health = GetConVarInt(hBoomerHealth);
		}
		if(class == ZC_SPITTER)
		{
			health = GetConVarInt(hSpitterHealth);
		}
		if(class == ZC_CHARGER)
		{
			health = GetConVarInt(hChargerHealth);
		}
		if(class == ZC_JOCKEY)
		{
			health = GetConVarInt(hJockeyHealth);
		}
		if(class == ZC_TANK)
		{
			g_IsGhostBuffed[client] = false;
			g_IsGhosting[client] = false;
			
			return Plugin_Continue;
		}
			
		SetEntityHealth(client,health);		
		
		g_IsGhostBuffed[client] = false;
		g_IsGhosting[client] = false;
	}
	
	return Plugin_Continue;
}


//Buff ghosts on their first spawn at the start of a campaign (this is usually a problem area for inf ghosts dying)
//This only works on players who join into infected, anyone who switches has to be sorted by the teamswitch stuff above
public Action:Event_InfFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId);
	
	if(!IsPlayerValid(client) || !IsPlayerSpawnGhost(client))
	return Plugin_Continue;
	
	//Check if the client was already checking for ghosting due to switching to infected
	if(g_IsSwitchedInf[client])
	{
		//If the client has a ghost check coming cuz they swapped then kill the timer for 
		//it now that we know they won't be ghosting for X seconds 
		if (hCheckGhostsTimer[client] != INVALID_HANDLE)
		{
			KillTimer(hCheckGhostsTimer[client]);
			hCheckGhostsTimer[client] = INVALID_HANDLE;
		}
		//If the client has a ghost buff coming cuz they swapped then kill the timer for 
		//it now that we know they won't be ghosting for X seconds 
		if (hBuffGhostsTimer[client] != INVALID_HANDLE)
		{
			KillTimer(hBuffGhostsTimer[client]);
			hBuffGhostsTimer[client] = INVALID_HANDLE;
		}
		
		g_IsSwitchedInf[client] = false;
	}
	
	SetEntityHealth(client,20000);
	g_IsGhostBuffed[client] = true;
	g_OldHealth[client] = GetClientHealth(client);
	
	g_IsGhosting[client] = true;
	
	return Plugin_Continue;
}



//Checks that the player is ingame, on infected and not a bot
bool:IsPlayerValid(client)
{
	if(client == 0)
	return false;
	if(!IsClientInGame(client))
	return false;
	else if(IsFakeClient(client))
	return false;
	else if(GetClientTeam(client) != 3)
	return false;
	else
	return true;
}


//Checks if the player is currently a ghost
bool:IsPlayerSpawnGhost(client)
{
	if(GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}



//Timer kills for OnClientDisconnect
public OnClientDisconnect(client)
{
	//If the client has a ghost check coming but has left then kill the timer for it
	if (hCheckGhostsTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hCheckGhostsTimer[client]);
		hCheckGhostsTimer[client] = INVALID_HANDLE;
	}
	//If the client has a ghost buff coming but has left then kill the timer for it
	if (hBuffGhostsTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hBuffGhostsTimer[client]);
		hBuffGhostsTimer[client] = INVALID_HANDLE;
	}
	//If the client needs use(-) applying but has left then kill the timer for it
	if (hResetGhostUse[client] != INVALID_HANDLE)
	{
		KillTimer(hResetGhostUse[client]);
		hResetGhostUse[client] = INVALID_HANDLE;
	}
	g_OldHealth[client] = 0;
	g_IsGhostBuffed[client] = false;
	g_IsSwitchedInf[client] = false;
	g_HasSpawnTimer[client] = false;
}