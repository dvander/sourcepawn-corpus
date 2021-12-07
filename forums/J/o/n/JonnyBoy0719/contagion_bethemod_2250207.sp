#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <contagion>

#define PLUGIN_VERSION "1.6"
// The higher number the less chance the carrier can infect
#define INFECTION_MAX_CHANCE	20

// TODO: Add lives override
enum g_eModes
{
	MODE_LIVES=0,	// Default 4 lives on CE and other modes.
	MODE_OVERRIDE=1	// Override the amount of lives you have, so you always will live (this doesn't apply for CPC)
};

enum g_eStatus
{
	STATE_NOT_CARRIER=0,
	STATE_CARRIER
};

enum g_eRegene
{
	STATE_NO_REGEN=0,
	STATE_REGEN
};

enum g_iStatus
{
	STATE_NOT_RIOT=0,
	STATE_RIOT
};

enum g_edata
{
	g_eModes:g_nMode,
	g_eRegene:g_nIfRegen,
	g_eStatus:g_nIfSpecial_Carrier,
	g_iStatus:g_nIfSpecial_Riot
};

new CanBeCarrier;
new CanBeRiot;
new Handle:g_hDebugMode;
new Handle:g_hCvarMode;
new Handle:g_hCvarRiotMode;
new Handle:g_hCvarNormalInfectionMode;
new Handle:g_SetRiotHealth;
new Handle:g_SetWhiteyHealth;
new Handle:g_SetWhiteyInfectionTime;
new g_nBeTheMod[MAXPLAYERS+1][g_edata];
new Handle:ResetRegenTimer[MAXPLAYERS+1];

new Handle:g_GetMeleeInfection_Easy;
new Handle:g_GetMeleeInfection_Normal;
new Handle:g_GetMeleeInfection_Hard;
new Handle:g_GetMeleeInfection_Extreme;

public Plugin:myinfo =
{
	name = "[Contagion] Be The Special Survivor/Infected",
	author = "JonnyBoy0719",
	version = PLUGIN_VERSION,
	description = "Makes the first player a speical zombie and/or survivor",
	url = "https://forums.alliedmods.net/"
}

public OnPluginStart()
{
	// Events
	HookEvent("player_spawn",EVENT_PlayerSpawned);
	HookEvent("player_death",EVENT_PlayerDeath);
	
	// Commands
	CreateConVar("sm_bethemod_version", PLUGIN_VERSION, "Current \"Be The Special Survivor/Infected\" Version",
		FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_hDebugMode						= CreateConVar("sm_bethemod_debug", "0", "0 - Disable debugging | 1 - Enable Debugging");
	g_hCvarMode							= CreateConVar("sm_bethemod_max_carrier", "1", "How many carriers should can we have alive at once?");
	g_hCvarRiotMode						= CreateConVar("sm_bethemod_max_riot", "3", "How many riots should can we have alive at once?");
	g_hCvarNormalInfectionMode			= CreateConVar("sm_bethemod_infection_normal", "0", "0 - Disable normal zombie infection | 1 - Enable normal zombie infection");
	g_SetWhiteyHealth					= CreateConVar("sm_bethemod_carrier_health", "350.0", "Value to change the carrier health to. Minimum 250.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 250.0);
	g_SetRiotHealth						= CreateConVar("sm_bethemod_riot_health", "250", "Value to change the riot health to. Minimum 250.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 250.0);
	g_SetWhiteyInfectionTime			= CreateConVar("sm_bethemod_infection", "35.0", "Value to change the carrier infection time to. Minimum 20.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 20.0);
	
	// Hooks
	HookConVarChange(g_hCvarNormalInfectionMode, OnConVarChange);
	
	// Get Contagion commands
	g_GetMeleeInfection_Easy = FindConVar("cg_infection_attacked_chance_easy");
	g_GetMeleeInfection_Normal = FindConVar("cg_infection_attacked_chance_normal");
	g_GetMeleeInfection_Hard = FindConVar("cg_infection_attacked_chance_hard");
	g_GetMeleeInfection_Extreme = FindConVar("cg_infection_attacked_chance_extreme");
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	CheckInfectionMode();
}

public CheckInfectionMode()
{
	new disabled = -1;
	if (GetConVarInt(g_hCvarNormalInfectionMode) == 1)
	{
		SetConVarInt(g_GetMeleeInfection_Easy, disabled);
		SetConVarInt(g_GetMeleeInfection_Normal, 3);
		SetConVarInt(g_GetMeleeInfection_Hard, 8);
		SetConVarInt(g_GetMeleeInfection_Extreme, 20);
	}
	else
	{
		SetConVarInt(g_GetMeleeInfection_Easy, disabled);
		SetConVarInt(g_GetMeleeInfection_Normal, disabled);
		SetConVarInt(g_GetMeleeInfection_Hard, disabled);
		SetConVarInt(g_GetMeleeInfection_Extreme, disabled);
	}
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new disabled = -1;
	if (strcmp(oldValue, newValue) != 0)
	{
		if (strcmp(newValue, "1") == 0)
		{
			SetConVarInt(g_GetMeleeInfection_Easy, disabled);
			SetConVarInt(g_GetMeleeInfection_Normal, 3);
			SetConVarInt(g_GetMeleeInfection_Hard, 8);
			SetConVarInt(g_GetMeleeInfection_Extreme, 20);
		}
		else
		{
			SetConVarInt(g_GetMeleeInfection_Easy, disabled);
			SetConVarInt(g_GetMeleeInfection_Normal, disabled);
			SetConVarInt(g_GetMeleeInfection_Hard, disabled);
			SetConVarInt(g_GetMeleeInfection_Extreme, disabled);
		}
	}
}

public OnMapStart()
{
	// Download the models
	AddFileToDownloadsTable("models/zombies/whitey/whitey.mdl");
	AddFileToDownloadsTable("models/zombies/whitey/whitey.dx90.vtx");
	AddFileToDownloadsTable("models/zombies/whitey/whitey.vvd");
	//=====================//
	AddFileToDownloadsTable("models/survivors/riot/riot.mdl");
	AddFileToDownloadsTable("models/survivors/riot/riot.dx90.vtx");
	AddFileToDownloadsTable("models/survivors/riot/riot.vvd");
	AddFileToDownloadsTable("models/survivors/riot/riot_female.mdl");
	AddFileToDownloadsTable("models/survivors/riot/riot_female.dx90.vtx");
	AddFileToDownloadsTable("models/survivors/riot/riot_female.vvd");
	
	// Download the textures
	AddFileToDownloadsTable("materials/models/survivors/riot/riot_diff.vmt");
	AddFileToDownloadsTable("materials/models/survivors/riot/riot_diff.vtf");
	AddFileToDownloadsTable("materials/models/survivors/riot/riot_norm.vtf");
	AddFileToDownloadsTable("materials/models/survivors/riot/riot_glass.vmt");
	AddFileToDownloadsTable("materials/models/survivors/riot/riot_glass_diff.vtf");
	AddFileToDownloadsTable("materials/models/survivors/riot/riot_glass_norm.vtf");
	//=====================//
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_body_DIF.vmt");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_body_DIF.vtf");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_body_NM.vtf");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_eye.vmt");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_eye.vtf");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_head_DIF.vmt");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_head_DIF.vtf");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_head_NM.vtf");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_teeth.vmt");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zombie1_teeth.vtf");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zp_sv1_pants.vmt");
	AddFileToDownloadsTable("materials/models/zombies/Zombie0/zp_sv1_pants.vtf");
	
	// Precache everything
	PrecacheModel("models/zombies/whitey/whitey.mdl");
	PrecacheModel("models/survivors/riot/riot.mdl");
	PrecacheModel("models/survivors/riot/riot_female.mdl");
}

public Action:ResetRegen(Handle:timer, any:client)
{
	g_nBeTheMod[client][g_nIfRegen] = STATE_REGEN;
	CreateTimer(0.5, RegenPlayer, client, TIMER_REPEAT);
	return Plugin_Handled;
}

public CheckTeams()
{
	if (GetConVarInt(g_hCvarMode) > GetSpecialCount(1))
	{
		CanBeCarrier = true;
		if (GetConVarInt(g_hDebugMode) >= 1)
			PrintToServer("Carrier: YES");
	}
	else
	{
		CanBeCarrier = false;
		if (GetConVarInt(g_hDebugMode) >= 1)
			PrintToServer("Carrier: NO");
	}
	
	if (GetConVarInt(g_hCvarRiotMode) > GetSpecialCount(2))
	{
		CanBeRiot = true;
		if (GetConVarInt(g_hDebugMode) >= 1)
			PrintToServer("Riot: YES");
	}
	else
	{
		CanBeRiot = false;
		if (GetConVarInt(g_hDebugMode) >= 1)
			PrintToServer("Riot: NO");
	}
}

public Action:EVENT_PlayerDeath(Handle:hEvent,const String:name[],bool:dontBroadcast)
{
//	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
//	if (!IsValidClient(attacker)) return;
	if (!IsValidClient(victim, false)) return;
	
//	PrintToServer("[[ I AM DED ]]");
	CheckHumanSurvivors();
	
	if (g_nBeTheMod[victim][g_nIfRegen] == STATE_REGEN)
		g_nBeTheMod[victim][g_nIfRegen] = STATE_NO_REGEN;
	if (g_nBeTheMod[victim][g_nIfSpecial_Riot] == STATE_RIOT)
		g_nBeTheMod[victim][g_nIfSpecial_Riot] = STATE_NOT_RIOT;
}

public CheckHumanSurvivors()
{
	decl iCount, i; iCount = 0;
	
	for( i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:CTEAM_Survivor )
			iCount++;
		else
			EVENT_NoSurvivorsLeft();
	
	if (GetConVarInt(g_hDebugMode) >= 1)
		PrintToServer("[[ Humans Left: %d ]]", iCount);
}

public EVENT_NoSurvivorsLeft()
{
	// Disable everything due the survivors are dead
	CanBeRiot = false;
	CanBeCarrier = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (g_nBeTheMod[i][g_nIfRegen] == STATE_REGEN)
				g_nBeTheMod[i][g_nIfRegen] = STATE_NO_REGEN;
			if (g_nBeTheMod[i][g_nIfSpecial_Carrier] == STATE_CARRIER)
				g_nBeTheMod[i][g_nIfSpecial_Carrier] = STATE_NOT_CARRIER;
			if (g_nBeTheMod[i][g_nIfSpecial_Riot] == STATE_RIOT)
				g_nBeTheMod[i][g_nIfSpecial_Riot] = STATE_NOT_RIOT;
		}
	}
}

public Action:EVENT_PlayerSpawned(Handle:hEvent,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(client)) return;
	
	CheckTeams();
	
	// Lets make a small timer, so the model can be set 1.2 second(s) after the player has actually spawned, so we can actually override the model.
	// Note#1: Don't change this, since it might screw up the spawning for the survivors.
	new Float:SetTime;
	if (GetClientTeam(client) == _:CTEAM_Survivor)
		SetTime = 1.2 + float(client) / 8;
	else
		SetTime = 0.2;
	PrintToServer("[[ Client Time: %f ]]", SetTime);
	CreateTimer(SetTime, SetModel, client);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	// lets make sure they are actual clients
	if (!IsValidClient(attacker)) return;
	if (!IsValidClient(victim)) return;
	
	// Don't continue if the victim is also the attacker
	if (attacker == victim) return;
	
	if (GetClientTeam(attacker) == _:CTEAM_Zombie && g_nBeTheMod[attacker][g_nIfSpecial_Carrier] == STATE_CARRIER)
	{
		new infection_chance = GetRandomInt(1, INFECTION_MAX_CHANCE);
		switch(infection_chance)
		{
			// The carrier have higher chance to infect someone
			case 1,2,5,16,20:
			{
				CONTAGION_SetInfectionTime(victim, GetConVarFloat(g_SetWhiteyInfectionTime));
			}
			
			default:
			{
			}
		}
	}
	// If the carrier is hurt, lets reset the regen
	if (GetClientTeam(victim) == _:CTEAM_Zombie && g_nBeTheMod[victim][g_nIfSpecial_Carrier] == STATE_CARRIER)
	{
		if (g_nBeTheMod[victim][g_nIfRegen] == STATE_REGEN)
			g_nBeTheMod[victim][g_nIfRegen] = STATE_NO_REGEN;
		if(ResetRegenTimer[victim] != INVALID_HANDLE)
		{
			ResetRegenTimer[victim] = INVALID_HANDLE;
		}
		ResetRegenTimer[victim] = CreateTimer(30.0, ResetRegen, victim);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:RegenPlayer(Handle:timer, any:client)
{
	// It can somehow call this w/o its being called, pretty wierd huh?
	if (GetClientTeam(client) == _:CTEAM_Survivor)
		return Plugin_Stop;
	
	if (IsClientInGame(client) && g_nBeTheMod[client][g_nIfRegen] == STATE_REGEN && ResetRegenTimer[client] != INVALID_HANDLE)
	{
		new iHealth = GetClientHealth(client) + 5;
		SetEntityHealth(client, iHealth);
		
		if (GetConVarInt(g_hDebugMode) >= 1)
		{
			PrintToServer("[[ %N new Health: %d ]]", client, iHealth);
			PrintToServer("[[ %N Regen Status: %d ]]", client, g_nBeTheMod[client][g_nIfRegen]);
		}
		
		if(g_nBeTheMod[client][g_nIfSpecial_Carrier] == STATE_CARRIER && iHealth >= GetConVarInt(g_SetWhiteyHealth))
		{
			g_nBeTheMod[client][g_nIfRegen] = STATE_NO_REGEN;
			SetEntityHealth(client, GetConVarInt(g_SetWhiteyHealth));
			if (GetConVarInt(g_hDebugMode) >= 1)
			{
				PrintToServer("[[ %N Health reset: %d ]]", client, GetConVarInt(g_SetWhiteyHealth));
				PrintToServer("[[ %N Regen Status: %d ]]", client, g_nBeTheMod[client][g_nIfRegen]);
			}
			ResetRegenTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		return Plugin_Handled;
	}
	else
		ResetRegenTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:SetModel(Handle:timer, any:client)
{
	new String:teamname[32];
	
	if (GetClientTeam(client) == _:CTEAM_Zombie)
		teamname = "Zombie";
	else if (GetClientTeam(client) == _:CTEAM_Survivor)
		teamname = "Survivor";
	else
		teamname = "Spectator";
	
	if (GetClientTeam(client) == _:CTEAM_Zombie)
	{
		if (CanBeCarrier)
			g_nBeTheMod[client][g_nIfSpecial_Carrier] = STATE_CARRIER;
	}
	if (GetClientTeam(client) == _:CTEAM_Survivor)
	{
		if (CanBeRiot)
			g_nBeTheMod[client][g_nIfSpecial_Riot] = STATE_RIOT;
	}
	
	if (GetConVarInt(g_hDebugMode) >= 1)
	{
		if (g_nBeTheMod[client][g_nIfSpecial_Carrier] == STATE_CARRIER)
			PrintToServer("(%s) %N is a carrier", teamname, client);
		else
			PrintToServer("(%s) %N is not a carrier", teamname, client);
		
		if (g_nBeTheMod[client][g_nIfSpecial_Riot] == STATE_RIOT)
			PrintToServer("(%s) %N is a riot", teamname, client);
		else
			PrintToServer("(%s) %N is not a riot", teamname, client);
		
		// Lets get the information of how many zombies there is, and what the amount is
		PrintToServer("[[ =========================== ]]");
		PrintToServer("[[ There is %d amount of zombies (players) ]]", GetZombieCount());
		PrintToServer("[[ There is %d amount of carriers ]]", GetSpecialCount(1));
		PrintToServer("[[ %d is the max carrier count ]]", GetConVarInt(g_hCvarMode));
		PrintToServer("[[ =========================== ]]");
		PrintToServer("[[ There is %d amount of survivors (players) ]]", GetSurvivorCount());
		PrintToServer("[[ There is %d amount of riots ]]", GetSpecialCount(2));
		PrintToServer("[[ %d is the max riot count ]]", GetConVarInt(g_hCvarRiotMode));
		PrintToServer("[[ =========================== ]]");
	}
	
	// Zombies only
	if (GetClientTeam(client) == _:CTEAM_Zombie)
	{
		if (g_nBeTheMod[client][g_nIfSpecial_Carrier] == STATE_CARRIER)
		{
			SetEntityModel(client,"models/zombies/whitey/whitey.mdl");
			new sethealth = GetConVarInt(g_SetWhiteyHealth);
			new newmaxhealth = GetConVarInt(g_SetWhiteyHealth);
			CONTAGION_SetNewHealth(client, sethealth, newmaxhealth);
		}
	}
	// Survivor only
	else if (GetClientTeam(client) == _:CTEAM_Survivor)
	{
		// Lets make sure what survivor they are, so we can actually make sure we set a male or a female model on them.
		new Gender = CONTAGION_GetSurvivorCharacter(client);
		decl String:SetGender[512];
		decl String:Model_Riot[512];
		if (Gender == 4 || Gender == 5)
			SetGender = "_female";
		else
			SetGender = "";
		
		Format(Model_Riot, sizeof(Model_Riot), "models/survivors/riot/riot%s.mdl", SetGender);
		
		if (g_nBeTheMod[client][g_nIfSpecial_Riot] == STATE_RIOT)
		{
			SetEntityModel(client, Model_Riot);
			new sethealth = GetConVarInt(g_SetRiotHealth);
			new newmaxhealth = GetConVarInt(g_SetRiotHealth);
			CONTAGION_SetNewHealth(client, sethealth, newmaxhealth);
			CONTAGION_RemoveAllFirearms(client);
			CONTAGION_GiveClientWeapon(client, "weapon_ar15", 60);
			CONTAGION_GiveClientWeapon(client, "weapon_revolver", 36);
			CONTAGION_GiveClientWeapon(client, "weapon_grenade");
		}
	}
}

public OnClientDisconnect(client)
{
	if (!IsValidClient(client)) return;
	CheckTeams();
}

stock bool:IsValidClient(client, bool:bCheckAlive=true)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	if(IsFakeClient(client)) return false;
	if(bCheckAlive) return IsPlayerAlive(client);
	return true;
}

GetSpecialCount(getstate)
{
	decl iCount, i; iCount = 0;
	
	if (getstate == 1)
	{
		for( i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:CTEAM_Zombie && g_nBeTheMod[i][g_nIfSpecial_Carrier] == STATE_CARRIER )
				iCount++;
	}
	else if (getstate == 2)
	{
		for( i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:CTEAM_Survivor && g_nBeTheMod[i][g_nIfSpecial_Riot] == STATE_RIOT )
				iCount++;
	}
	
	return iCount;
}

/* ********************************** */

GetZombieCount()
{
	decl iCount, i; iCount = 0;
	
	for( i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:CTEAM_Zombie )
			iCount++;
	
	return iCount;
}

GetSurvivorCount()
{
	decl iCount, i; iCount = 0;
	
	for( i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:CTEAM_Survivor )
			iCount++;
	
	return iCount;
}

public GetAlivePlayersCount()
{
	decl iCount, i; iCount = 0;
	
	for( i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && IsPlayerAlive(i) )
			iCount++;
	
	return iCount;
}

stock GetEntityAbsOrigin(entity, Float:origin[3])
{
	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

stock GetRandomEntity(String:class[64], String:name[64] = "")
{
	new ent[100];
	new ent_count;
	new entity = INVALID_ENT_REFERENCE;
	decl String:buffer[sizeof(name)];
	while ((entity = FindEntityByClassname(entity, class)) != INVALID_ENT_REFERENCE)
	{
		if (strlen(name) > 0)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrContains(name, buffer) >= 0)
			{
				ent[ent_count++] = entity;
			}
		}
		else
		{
			ent[ent_count++] = entity;	
		}
	}
	if (ent_count > 0)
	{
		return ent[GetRandomInt(0, ent_count - 1)];
	}
	return -1;
}