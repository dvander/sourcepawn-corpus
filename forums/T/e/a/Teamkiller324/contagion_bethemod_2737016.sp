#pragma		semicolon	1
#pragma		newdecls	required

#include	<sdkhooks>
#include	<sdktools>
#include	<contagion>

#define		PLUGIN_VERSION	"1.7"
// The higher number the less chance the carrier can infect
#define		INFECTION_MAX_CHANCE	20

// TODO: Add lives override
enum	g_eModes
{
	MODE_LIVES=0,	// Default 4 lives on CE and other modes.
	MODE_OVERRIDE=1	// Override the amount of lives you have, so you always will live (this doesn't apply for CPC)
};

enum	g_eStatus
{
	STATE_NOT_CARRIER=0,
	STATE_CARRIER
};

enum	g_eRegene
{
	STATE_NO_REGEN=0,
	STATE_REGEN
};

enum	g_iStatus
{
	STATE_NOT_RIOT=0,
	STATE_RIOT
};

enum	g_edata
{
	g_eModes:g_nMode,
	g_eRegene:g_nIfRegen,
	g_eStatus:g_nIfSpecial_Carrier,
	g_iStatus:g_nIfSpecial_Riot
};

int	CanBeCarrier,
	CanBeRiot;
ConVar	g_hDebugMode,
		g_hCvarMode,
		g_hCvarRiotMode,
		g_hCvarNormalInfectionMode,
		g_SetRiotHealth,
		g_SetWhiteyHealth,
		g_SetWhiteyInfectionTime;
int		g_nBeTheMod[MAXPLAYERS+1][g_edata];
Handle	ResetRegenTimer[MAXPLAYERS+1];

ConVar	g_GetMeleeInfection_Easy,
		g_GetMeleeInfection_Normal,
		g_GetMeleeInfection_Hard,
		g_GetMeleeInfection_Extreme;

public Plugin myinfo =	{
	name		=	"[CE] Be The Special Survivor/Infected",
	author		=	"JonnyBoy0719, Tk /id/Teamkiller324",
	version		=	PLUGIN_VERSION,
	description	=	"Makes the first player a speical zombie and/or survivor",
	url			=	"https://forums.alliedmods.net/"
}

public void OnPluginStart()	{
	// Events
	HookEvent("player_spawn",	Event_PlayerSpawned,	EventHookMode_Pre);
	HookEvent("player_death",	Event_PlayerDeath,		EventHookMode_Pre);
	
	// Commands
	CreateConVar("sm_bethemod_version", PLUGIN_VERSION, "Current \"Be The Special Survivor/Infected\" Version",
		FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_hDebugMode						=	CreateConVar("sm_bethemod_debug",				"0",	"0 - Disable debugging | 1 - Enable Debugging");
	g_hCvarMode							=	CreateConVar("sm_bethemod_max_carrier",			"1",	"How many carriers should can we have alive at once?");
	g_hCvarRiotMode						=	CreateConVar("sm_bethemod_max_riot",			"3",	"How many riots should can we have alive at once?");
	g_hCvarNormalInfectionMode			=	CreateConVar("sm_bethemod_infection_normal",	"0",	"0 - Disable normal zombie infection | 1 - Enable normal zombie infection");
	g_SetWhiteyHealth					=	CreateConVar("sm_bethemod_carrier_health",		"350.0","Value to change the carrier health to. Minimum 250.", 
		FCVAR_NOTIFY,	true,	250.0);
	g_SetRiotHealth						=	CreateConVar("sm_bethemod_riot_health",	"250",	"Value to change the riot health to. Minimum 250.", 
		FCVAR_NOTIFY,	true,	250.0);
	g_SetWhiteyInfectionTime			=	CreateConVar("sm_bethemod_infection",	"35.0",	"Value to change the carrier infection time to. Minimum 20.", 
		FCVAR_NOTIFY,	true,	20.0);
	
	// Hooks
	g_hCvarNormalInfectionMode.AddChangeHook(OnConVarChange);
	
	// Get contagion commands
	g_GetMeleeInfection_Easy	=	FindConVar("cg_infection_attacked_chance_easy");
	g_GetMeleeInfection_Normal	=	FindConVar("cg_infection_attacked_chance_normal");
	g_GetMeleeInfection_Hard	=	FindConVar("cg_infection_attacked_chance_hard");
	g_GetMeleeInfection_Extreme	=	FindConVar("cg_infection_attacked_chance_extreme");
	
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	CheckInfectionMode();
}

void CheckInfectionMode()	{
	int	disabled = -1;
	if(g_hCvarNormalInfectionMode.BoolValue)
	{
		g_GetMeleeInfection_Easy.SetInt(disabled);
		g_GetMeleeInfection_Normal.SetInt(3);
		g_GetMeleeInfection_Hard.SetInt(8);
		g_GetMeleeInfection_Extreme.SetInt(20);
	}
	else
	{
		g_GetMeleeInfection_Easy.SetInt(disabled);
		g_GetMeleeInfection_Normal.SetInt(disabled);
		g_GetMeleeInfection_Hard.SetInt(disabled);
		g_GetMeleeInfection_Extreme.SetInt(disabled);
	}
}

void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)	{
	int	disabled = -1;
	if(strcmp(oldValue, newValue) != 0)
	{
		if (strcmp(newValue, "1") == 0)
		{
			g_GetMeleeInfection_Easy.SetInt(disabled);
			g_GetMeleeInfection_Normal.SetInt(3);
			g_GetMeleeInfection_Hard.SetInt(8);
			g_GetMeleeInfection_Extreme.SetInt(20);
		}
		else
		{
			g_GetMeleeInfection_Easy.SetInt(disabled);
			g_GetMeleeInfection_Normal.SetInt(disabled);
			g_GetMeleeInfection_Hard.SetInt(disabled);
			g_GetMeleeInfection_Extreme.SetInt(disabled);
		}
	}
}

public void OnMapStart()	{
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

Action ResetRegen(Handle timer, any client)	{
	g_nBeTheMod[client][g_nIfRegen] = STATE_REGEN;
	CreateTimer(0.5, RegenPlayer, client, TIMER_REPEAT);
	return Plugin_Handled;
}

void CheckTeams()	{
	if(g_hCvarMode.IntValue > GetSpecialCount(1))	{
		CanBeCarrier = true;
		if(g_hDebugMode.BoolValue)
			PrintToServer("Carrier: YES");
	}
	else	{
		CanBeCarrier = false;
		if(g_hDebugMode.BoolValue)
			PrintToServer("Carrier: NO");
	}
	
	if(g_hCvarRiotMode.IntValue > GetSpecialCount(2))	{
		CanBeRiot = true;
		if(g_hDebugMode.BoolValue)
			PrintToServer("Riot: YES");
	}
	else	{
		CanBeRiot = false;
		if(g_hDebugMode.BoolValue)
			PrintToServer("Riot: NO");
	}
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)	{
//	int	attacker	=	GetClientOfUserId(event.GetInt("attacker"));
	int	victim		=	GetClientOfUserId(event.GetInt("userid"));
	
//	if(!IsValidClient(attacker))	return;

	if(!IsValidClient(victim, false))
		return;
	
//	PrintToServer("[[ I AM DED ]]");
	CheckHumanSurvivors();
	
	if(g_nBeTheMod[victim][g_nIfRegen] == STATE_REGEN)
		g_nBeTheMod[victim][g_nIfRegen] = STATE_NO_REGEN;
	if(g_nBeTheMod[victim][g_nIfSpecial_Riot] == STATE_RIOT)
		g_nBeTheMod[victim][g_nIfSpecial_Riot] = STATE_NOT_RIOT;
}

void CheckHumanSurvivors()	{
	int iCount; iCount = 0;
	
	for(int i = 1; i <= MaxClients; i++ )
		if(IsClientInGame(i) && IsPlayerAlive(i) && CE_GetClientTeam(i) == CETeam_Survivor )
			iCount++;
		else
			Event_NoSurvivorsLeft();
	
	if(g_hDebugMode.BoolValue)
		PrintToServer("[[ Humans Left: %d ]]", iCount);
}

void Event_NoSurvivorsLeft()	{
	// Disable everything due the survivors are dead
	CanBeRiot		=	false;
	CanBeCarrier	=	false;
	
	for(int i = 1; i <= MaxClients; i++)	{
		if(IsValidClient(i))	{
			if(g_nBeTheMod[i][g_nIfRegen] == STATE_REGEN)
				g_nBeTheMod[i][g_nIfRegen] = STATE_NO_REGEN;
			if(g_nBeTheMod[i][g_nIfSpecial_Carrier] == STATE_CARRIER)
				g_nBeTheMod[i][g_nIfSpecial_Carrier] = STATE_NOT_CARRIER;
			if(g_nBeTheMod[i][g_nIfSpecial_Riot] == STATE_RIOT)
				g_nBeTheMod[i][g_nIfSpecial_Riot] = STATE_NOT_RIOT;
		}
	}
}

Action Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast)	{
	int	client	=	GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return;
	
	CheckTeams();
	
	// Lets make a small timer, so the model can be set 1.2 second(s) after the player has actually spawned, so we can actually override the model.
	// Note#1: Don't change this, since it might screw up the spawning for the survivors.
	float	SetTime;
	if(CE_GetClientTeam(client) == CETeam_Survivor)
		SetTime = 1.2 + float(client) / 8;
	else
		SetTime = 0.2;
	PrintToServer("[[ Client Time: %f ]]", SetTime);
	CreateTimer(SetTime, SetModel, client);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)	{
	// lets make sure they are actual clients
	if(!IsValidClient(attacker))
		return;
	if(!IsValidClient(victim))
		return;
	
	// Don't continue if the victim is also the attacker
	if(attacker == victim)
		return;
	
	if(CE_GetClientTeam(attacker) == CETeam_Zombie && g_nBeTheMod[attacker][g_nIfSpecial_Carrier] == STATE_CARRIER)
	{
		int	infection_chance	=	GetRandomInt(1, INFECTION_MAX_CHANCE);
		switch(infection_chance)
		{
			// The carrier have higher chance to infect someone
			case 1,2,5,16,20:
			{
				CE_SetInfectionTime(victim, g_SetWhiteyInfectionTime.FloatValue);
			}
			
			default:
			{
			}
		}
	}
	// If the carrier is hurt, lets reset the regen
	if(CE_GetClientTeam(victim) == CETeam_Zombie && g_nBeTheMod[victim][g_nIfSpecial_Carrier] == STATE_CARRIER)
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

public void OnClientPutInServer(int client)	{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action RegenPlayer(Handle timer, any client)	{
	// It can somehow call this w/o its being called, pretty wierd huh?
	if(CE_GetClientTeam(client) == CETeam_Survivor)
		return	Plugin_Stop;
	
	if(IsClientInGame(client) && g_nBeTheMod[client][g_nIfRegen] == STATE_REGEN && ResetRegenTimer[client] != INVALID_HANDLE)	{
		int	iHealth	=	GetClientHealth(client) + 5;
		SetEntityHealth(client,	iHealth);
		
		if(g_hDebugMode.BoolValue)	{
			PrintToServer("[[ %N new Health: %d ]]",	client,	iHealth);
			PrintToServer("[[ %N Regen Status: %d ]]",	client,	g_nBeTheMod[client][g_nIfRegen]);
		}
		
		if(g_nBeTheMod[client][g_nIfSpecial_Carrier] == STATE_CARRIER && iHealth >= g_SetWhiteyHealth.IntValue)	{
			g_nBeTheMod[client][g_nIfRegen] = STATE_NO_REGEN;
			SetEntityHealth(client,	g_SetWhiteyHealth.IntValue);
			if(g_hDebugMode.BoolValue)	{
				PrintToServer("[[ %N Health reset: %d ]]",	client,	g_SetWhiteyHealth.IntValue);
				PrintToServer("[[ %N Regen Status: %d ]]",	client,	g_nBeTheMod[client][g_nIfRegen]);
			}
			ResetRegenTimer[client] = INVALID_HANDLE;
			return	Plugin_Stop;
		}
		return	Plugin_Handled;
	}
	else
		ResetRegenTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

Action SetModel(Handle timer, any client)	{
	char	teamname[32];
	
	switch(CE_GetClientTeam(client))	{
		case	CETeam_Zombie:	teamname	=	"Zombie";
		case	CETeam_Survivor:teamname	=	"Survivor";
		case	CETeam_Spectator:teamname	=	"Spectator";
		default:	teamname	=	"";
	}
	
	if(CE_GetClientTeam(client) == CETeam_Zombie)	{
		if(CanBeCarrier)
			g_nBeTheMod[client][g_nIfSpecial_Carrier] = STATE_CARRIER;
	}
	if(CE_GetClientTeam(client) == CETeam_Survivor)	{
		if(CanBeRiot)
			g_nBeTheMod[client][g_nIfSpecial_Riot] = STATE_RIOT;
	}
	
	if(g_hDebugMode.BoolValue)	{
		if (g_nBeTheMod[client][g_nIfSpecial_Carrier] == STATE_CARRIER)
			PrintToServer("(%s) %N is a carrier",		teamname,	client);
		else
			PrintToServer("(%s) %N is not a carrier",	teamname,	client);
		
		if (g_nBeTheMod[client][g_nIfSpecial_Riot] == STATE_RIOT)
			PrintToServer("(%s) %N is a riot",		teamname,	client);
		else
			PrintToServer("(%s) %N is not a riot",	teamname,	client);
		
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
	if(CE_GetClientTeam(client) == CETeam_Zombie)	{
		if(g_nBeTheMod[client][g_nIfSpecial_Carrier] == STATE_CARRIER)	{
			SetEntityModel(client,"models/zombies/whitey/whitey.mdl");
			int	sethealth		=	g_SetWhiteyHealth.IntValue,
				newmaxhealth	=	g_SetWhiteyHealth.IntValue;
			CE_SetNewHealth(client,	sethealth,	newmaxhealth);
		}
	}
	// Survivor only
	else if(CE_GetClientTeam(client) == CETeam_Survivor)	{
		// Lets make sure what survivor they are, so we can actually make sure we set a male or a female model on them.
		int		Gender	=	CE_GetSurvivorCharacter(client);
		char	SetGender[512],
				Model_Riot[512];
		if(Gender == 4 || Gender == 5)
			SetGender	=	"_female";
		else
			SetGender	=	"";
		
		FormatEx(Model_Riot,	sizeof(Model_Riot),	"models/survivors/riot/riot%s.mdl",	SetGender);
		
		if(g_nBeTheMod[client][g_nIfSpecial_Riot] == STATE_RIOT){
			SetEntityModel(client, Model_Riot);
			int	sethealth		=	g_SetRiotHealth.IntValue,
				newmaxhealth	=	g_SetRiotHealth.IntValue;
			CE_SetNewHealth(client, sethealth, newmaxhealth);
			CE_RemoveAllFirearms(client);
			CE_GiveClientWeapon(client,	"weapon_ar15",		60);
			CE_GiveClientWeapon(client,	"weapon_revolver",	36);
			CE_GiveClientWeapon(client,	"weapon_grenade");
		}
	}
}

public void OnClientDisconnect(int client)	{
	if(!IsValidClient(client))
		return;
	CheckTeams();
}

stock bool IsValidClient(int client, bool bCheckAlive=true)	{
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(IsClientSourceTV(client) || IsClientReplay(client))
		return	false;
	if(IsFakeClient(client))
		return	false;
	if(bCheckAlive)
		return	IsPlayerAlive(client);
	return	true;
}

int GetSpecialCount(int getstate)	{
	int	iCount, i;	iCount = 0;
	
	switch(getstate)	{
		case	1:	{
			for(i = 1; i <= MaxClients; i++ )
				if(IsClientInGame(i) && IsPlayerAlive(i) && CE_GetClientTeam(i) == CETeam_Zombie && g_nBeTheMod[i][g_nIfSpecial_Carrier] == STATE_CARRIER )
					iCount++;
		}
		case	2:	{
			for(i = 1; i <= MaxClients; i++ )
				if(IsClientInGame(i) && IsPlayerAlive(i) && CE_GetClientTeam(i) == CETeam_Survivor && g_nBeTheMod[i][g_nIfSpecial_Riot] == STATE_RIOT )
					iCount++;
		}
	}
	
	return	iCount;
}

/* ********************************** */

int GetZombieCount()	{
	int	iCount, i;	iCount = 0;
	
	for(i = 1; i <= MaxClients; i++ )	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && CE_GetClientTeam(i) == CETeam_Zombie )
			iCount++;
	}
	
	return iCount;
}

int	GetSurvivorCount()	{
	int	iCount, i;	iCount = 0;
	
	for(i = 1; i <= MaxClients; i++)	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && CE_GetClientTeam(i) == CETeam_Survivor )
			iCount++;
	}
	
	return	iCount;
}

public int GetAlivePlayersCount()	{
	int iCount, i;	iCount = 0;
	
	for(i = 1; i <= MaxClients; i++ )
		if(IsClientInGame(i) && IsPlayerAlive(i) )
			iCount++;
	
	return	iCount;
}

stock void GetEntityAbsOrigin(int entity, float origin[3])	{
	float	mins[3],
			maxs[3];
	GetEntPropVector(entity,	Prop_Send,	"m_vecOrigin",	origin);
	GetEntPropVector(entity,	Prop_Send,	"m_vecMins",	mins);
	GetEntPropVector(entity,	Prop_Send,	"m_vecMaxs",	maxs);
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

stock int GetRandomEntity(char[] class, char[] name="")	{
	int	ent[100],
		ent_count,
		entity = INVALID_ENT_REFERENCE;
	char	buffer[sizeof(name)];
	while((entity = FindEntityByClassname(entity, class)) != INVALID_ENT_REFERENCE)	{
		if(strlen(name) > 0)	{
			GetEntPropString(entity,	Prop_Data,	"m_iName",	buffer,	sizeof(buffer));
			if(StrContains(name, buffer) >= 0)
				ent[ent_count++] = entity;
		}
		else
			ent[ent_count++] = entity;	
	}
	if(ent_count > 0)
		return	ent[GetRandomInt(0, ent_count - 1)];
	return -1;
}