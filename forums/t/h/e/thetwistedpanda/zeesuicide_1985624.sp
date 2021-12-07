#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombiereloaded>
#include <morecolors>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.4"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hWeaponHuman = INVALID_HANDLE;
new Handle:g_hWeaponZombie = INVALID_HANDLE;
new Handle:g_hSuicideZombie = INVALID_HANDLE;
new Handle:g_hMethod = INVALID_HANDLE;
new Handle:g_hSuicideRespawn = INVALID_HANDLE;
new Handle:g_hSuicideLocation = INVALID_HANDLE;
new Handle:g_hRespawnDelay = INVALID_HANDLE;

new bool:g_bEnabled, bool:g_bSuicideZombie, bool:g_bSuicideRespawn, bool:g_bZombies;
new g_iMethod, g_iSuicideLocation;
new String:g_sWeaponHuman[64], String:g_sWeaponZombie[64];
new Float:g_fRespawnDelay;

new bool:g_bRespawning[MAXPLAYERS + 1];
new g_iLastAttacker[MAXPLAYERS + 1];
new g_iTotalDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new Handle:g_hTimer_Respawn[MAXPLAYERS + 1] = {INVALID_HANDLE, ... };

public Plugin:myinfo =
{
	name = "ZeeSuicide",
	author = "Panduh",
	description = "Provides kill credit for any player that suicides and support for respawning any human that dies as a zombie.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("zee_suicide_version", PLUGIN_VERSION, "ZeeSuicide: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hEnabled = CreateConVar("zee_suicide_enabled", "1.0", "Enables / Disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	
	g_hWeaponHuman = CreateConVar("zee_suicide_weapon_human", "zombie_claws_of_death", "The weapon used when a human commits suicide. Zombies will use the weapon their killer holds.", FCVAR_NONE);
	HookConVarChange(g_hWeaponHuman, OnSettingsChange);
	
	g_hWeaponZombie = CreateConVar("zee_suicide_weapon_zombie", "prop_physics", "The weapon used when a zombie commits suicide and a valid weapon or attacker cannot be found.", FCVAR_NONE);
	HookConVarChange(g_hWeaponZombie, OnSettingsChange);
	
	g_hMethod = CreateConVar("zee_suicide_mode", "1", "Determines detecting functioanlity. (-1 = Last Attacker, 0 = Single Highest Damage, 1 = Most Damage)", FCVAR_NONE, true, -1.0, true, 1.0);
	HookConVarChange(g_hMethod, OnSettingsChange);
	
	g_hSuicideZombie = CreateConVar("zee_suicide_detect_zombies", "0.0", "If enabled, the plugin will look for suicides made by Zombies as well as Humans.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSuicideZombie, OnSettingsChange);
	
	g_hSuicideRespawn = CreateConVar("zee_suicide_respawn_as_zombie", "1.0", "If enabled, the plugin will respawn any Human that suicides as a Zombie.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSuicideRespawn, OnSettingsChange);
	
	g_hSuicideLocation = CreateConVar("zee_suicide_respawn_location", "2.0", "Determines the respawn location for the new zombie. (0 = Spawn, 1 = Random Zombie, 2 = Closest Zombie, 3 = Farthest Zombie)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hSuicideLocation, OnSettingsChange);
	AutoExecConfig(true, "zee_suicide");

	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);
	
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bSuicideZombie = GetConVarBool(g_hSuicideZombie);
	g_iMethod = GetConVarInt(g_hMethod);
	GetConVarString(g_hWeaponHuman, g_sWeaponHuman, sizeof(g_sWeaponHuman));
	GetConVarString(g_hWeaponZombie, g_sWeaponZombie, sizeof(g_sWeaponZombie));
	g_bSuicideRespawn = GetConVarBool(g_hSuicideRespawn);
	g_iSuicideLocation = GetConVarBool(g_hSuicideLocation);
}

public OnAllPluginsLoaded()
{
	if(g_hRespawnDelay == INVALID_HANDLE)
	{
		g_hRespawnDelay = FindConVar("zr_respawn_delay");
		if(g_hRespawnDelay == INVALID_HANDLE)
		{
			HookConVarChange(g_hRespawnDelay, OnSettingsChange);
			g_fRespawnDelay = GetConVarFloat(g_hRespawnDelay);
		}
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hSuicideZombie)
		g_bSuicideZombie = bool:StringToInt(newvalue);
	else if(cvar == g_hMethod)
		g_iMethod = StringToInt(newvalue);
	else if(cvar == g_hWeaponHuman)
		strcopy(g_sWeaponHuman, sizeof(g_sWeaponHuman), newvalue);
	else if(cvar == g_hWeaponZombie)
		strcopy(g_sWeaponZombie, sizeof(g_sWeaponZombie), newvalue);
	else if(cvar == g_hSuicideRespawn)
		g_bSuicideRespawn = bool:StringToInt(newvalue);
	else if(cvar == g_hSuicideLocation)
		g_iSuicideLocation = StringToInt(newvalue);
	else if(cvar == g_hRespawnDelay)
		g_fRespawnDelay = StringToFloat(newvalue);
}

public OnMapStart()
{
	if(g_bEnabled)
	{
		g_bZombies = false;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			g_bRespawning[i] = false;
			if(IsClientInGame(i))
			{
				if(g_hTimer_Respawn[i] != INVALID_HANDLE && CloseHandle(g_hTimer_Respawn[i]))
					g_hTimer_Respawn[i] = INVALID_HANDLE;
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_bRespawning[client] = false;
		
		if(g_iMethod == -1)
			g_iLastAttacker[client] = 0;
		else
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				g_iTotalDamage[client][i] = 0;
				g_iTotalDamage[i][client] = 0;
			}
		}
		
		if(g_hTimer_Respawn[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Respawn[client]))
			g_hTimer_Respawn[client] = INVALID_HANDLE;
	}
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bZombies = false;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			g_bRespawning[i] = false;
			if(IsClientInGame(i))
			{
				if(g_hTimer_Respawn[i] != INVALID_HANDLE && CloseHandle(g_hTimer_Respawn[i]))
					g_hTimer_Respawn[i] = INVALID_HANDLE;
			}
		}
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(g_iMethod == -1)
					g_iLastAttacker[i] = 0;
				else
				{				
					for(new j = 1; j <= MaxClients; j++)
					{
						g_iTotalDamage[j][i] = 0;
						g_iTotalDamage[i][j] = 0;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || GetClientTeam(client) <= 1)
			return Plugin_Continue;

		if(g_iMethod == -1)
			g_iLastAttacker[client] = 0;
		else
		{
			for(new i = 1; i <= MaxClients; i++)
				g_iTotalDamage[client][i] = 0;
		}
		
		if(g_bRespawning[client])
		{
			g_bRespawning[client] = false;
			if(g_bZombies)
			{
				switch(g_iSuicideLocation)
				{
					case 1:
					{
						new iZombies, iZombieArray[MaxClients + 1];
						for(new i = 1; i <= MaxClients; i++)
							if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
								iZombieArray[iZombies++] = i;
							
						decl Float:fOrigin[3];
						GetClientAbsOrigin(iZombieArray[GetRandomInt(0, (iZombies - 1))], fOrigin);
						TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);	
					}
					case 2:
					{
						new iClosest, Float:fHighest = 9999999.0, Float:fDistance;
						decl Float:fOrigin[3], Float:fPosition[3];
						GetClientAbsOrigin(client, fOrigin);
						for(new i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
							{
								GetClientAbsOrigin(i, fPosition);
								if((fDistance = GetVectorDistance(fOrigin, fPosition)) < fHighest)
								{
									iClosest = i;
									fHighest = fDistance;
								}
							}
						}
						
						GetClientAbsOrigin(iClosest, fOrigin);
						TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);								
					}
					case 3:
					{
						new iFarthest, Float:fHighest, Float:fDistance;
						decl Float:fOrigin[3], Float:fPosition[3];
						GetClientAbsOrigin(client, fOrigin);
						for(new i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
							{
								GetClientAbsOrigin(i, fPosition);
								if((fDistance = GetVectorDistance(fOrigin, fPosition)) > fHighest)
								{
									iFarthest = i;
									fHighest = fDistance;
								}
							}
						}
						
						GetClientAbsOrigin(iFarthest, fOrigin);
						TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);								
					}
				}
			}
		}
		
		if(g_hTimer_Respawn[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Respawn[client]))
			g_hTimer_Respawn[client] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!attacker || attacker > MaxClients)
			return Plugin_Continue;

		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || !IsClientInGame(attacker) || attacker == client)
			return Plugin_Continue;

		switch(g_iMethod)
		{
			case -1:
				g_iLastAttacker[client] = attacker;
			case 0:
				g_iTotalDamage[client][attacker] = GetEventInt(event, "dmg_health");
			case 1:
				g_iTotalDamage[client][attacker] += GetEventInt(event, "dmg_health");
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if((!attacker || attacker == client || attacker > MaxClients) && IsClientInGame(client))
		{
			decl Float:fOrigin[3], Float:fPosition[3], iArray[MaxClients + 1];
			new iZombies, iClosest, Float:fHighest = 99999999.0, Float:fCurrent;
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
				{
					iArray[iZombies++] = i;

					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPosition);
					if((fCurrent = GetVectorDistance(fOrigin, fPosition)) < fHighest)
					{
						fHighest = fCurrent;
						iClosest = i;
					}
				}
			}
			

			if(iZombies)
			{
				new iTeam = GetClientTeam(client);
				if(iTeam == CS_TEAM_CT)
				{
					if(!iClosest)
						iClosest = iArray[GetRandomInt(0, (iZombies - 1))];

					SetEventInt(event, "attacker", iClosest ? GetClientUserId(iClosest) : client);
					SetEventString(event, "weapon", g_sWeaponHuman);
					
					if(iClosest)
						SetEntProp(iClosest, Prop_Data, "m_iFrags", (GetClientFrags(iClosest) + 1));
					
					if(g_bSuicideRespawn)
					{
						if(iClosest)
						{
							CPrintToChat(iClosest, "{olive}[ZR] {default}Your infection managed to spread to {blue}%N{default} prior to his/her death!", client);
							CPrintToChat(client, "{olive}[ZR] {default}The infection spread from {red}%N{default} prior to death! Zombifying in %.1f seconds!", iClosest, g_fRespawnDelay);
						}
						g_hTimer_Respawn[client] = CreateTimer(g_fRespawnDelay, Timer_Respawn, client);
					}
					else if(iClosest)
					{
						CPrintToChat(iClosest, "{olive}[ZR] {default}Your infection managed to spread to {blue}%N{default} prior to his/her death!", client);
						CPrintToChat(client, "{olive}[ZR] {default}The infection spread from {red}%N{default} to you before death!", iClosest);
					}
				}
				else if(iTeam == CS_TEAM_T && g_bSuicideZombie)
				{
					new iAttacker;
					if(g_iMethod == -1)
					{
						iAttacker = g_iLastAttacker[client];
						g_iLastAttacker[client] = 0;
					}
					else
					{					
						new iHighest;
						for(new i = 1; i <= MaxClients; i++)
						{
							if(g_iTotalDamage[client][i] <= iHighest)
								continue;
								
							iAttacker = i;
							iHighest = g_iTotalDamage[client][i];
						}
					}

					if(!iAttacker || !IsClientInGame(iAttacker))
					{
						new iTotal, iHumans[MaxClients + 1];
						for(new i = 1; i <= MaxClients; i++)
							if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
								iHumans[iTotal++] = i;
								
						iAttacker = iHumans[GetRandomInt(0, (iTotal - 1))];
					}
					
					if(!iAttacker || !IsClientInGame(iAttacker) || !ZR_IsClientHuman(iAttacker))
						return Plugin_Continue;

					SetEventInt(event, "attacker", GetClientUserId(iAttacker));
					new iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
					if(iWeapon >= 0 && IsValidEdict(iWeapon))
					{
						decl String:sClassname[32];
						GetEdictClassname(iWeapon, sClassname, sizeof(sClassname));
						SetEventString(event, "weapon", sClassname);
					}
					else
						SetEventString(event, "weapon", g_sWeaponZombie);
					
					SetEntProp(iAttacker, Prop_Data, "m_iFrags", (GetClientFrags(iAttacker) + 1));
					SetEventBroadcast(event, true);
				}
				
				return Plugin_Continue;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	g_hTimer_Respawn[client] = INVALID_HANDLE;

	if(IsClientInGame(client) && !IsPlayerAlive(client))
	{
		g_bRespawning[client] = true;
		if(!g_bZombies)
			CS_RespawnPlayer(client);
		else
			ZR_RespawnClient(client, ZR_Respawn_Zombie);
	}
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(!g_bZombies && motherInfect)
		g_bZombies = true;
}