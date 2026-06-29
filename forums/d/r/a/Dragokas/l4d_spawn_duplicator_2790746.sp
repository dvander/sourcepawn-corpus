#define PLUGIN_VERSION "1.2"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define ZOMBIECLASS_TANK_L4D2 8
#define ZOMBIECLASS_TANK_L4D1 5

#define CVAR_FLAGS			FCVAR_NOTIFY

enum SIClass
{
	SI_None=0,
	SI_Smoker=1,
	SI_Boomer,
	SI_Hunter,
	SI_Spitter,
	SI_Jockey,
	SI_Charger,
	SI_Witch,
	SI_Tank
};

public Plugin myinfo = 
{
	name = "[L4D] Infected duplicator",
	author = "Alex Dragokas",
	description = "Duplicates infected when they spawned",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com"
};

ConVar g_ConVarEnable, g_ConVarDifficulty;
bool g_bEnabled, g_bEasy, g_bNormal, g_bHard, g_bHardPlus, g_bExpert, g_bExpertPlus;

public void OnPluginStart()
{
	g_ConVarEnable = CreateConVar("l4d_infected_duplicator_enabled", "1", "Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	
	CreateConVar("l4d_infected_duplicator_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);

	AutoExecConfig(true, "l4d_infected_duplicator");
	
	HookConVarChange(g_ConVarEnable,		ConVarChanged);
}

public void OnAllPluginsLoaded()
{
	g_ConVarDifficulty = FindConVar("z_difficulty_ex");
	if( g_ConVarDifficulty == null )
	{
		g_ConVarDifficulty = FindConVar("z_difficulty");
	}
	g_ConVarDifficulty.AddChangeHook(ConVarChanged);
	GetCvars();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_ConVarEnable.BoolValue;
	
	static char sDif[32];
	g_bEasy = false;
	g_bNormal = false;
	g_bHard = false;
	g_bExpert = false;
	
	g_ConVarDifficulty.GetString(sDif, sizeof(sDif));
	if( strcmp(sDif, "Easy") == 0 ) {
		g_bEasy = true;
	}
	else if( strcmp(sDif, "Normal", false) == 0) {
		g_bNormal = true;
	}
	else if( strcmp(sDif, "Hard", false) == 0 ) {
		g_bHard = true;
	}
	else if( strcmp(sDif, "Hard+", false) == 0 ) {
		g_bHardPlus = true;
	}
	else if( strcmp(sDif, "Impossible", false) == 0) {
		g_bExpert = true;
	}
	else if( strcmp(sDif, "Impossible+", false) == 0) {
		g_bExpertPlus = true;
	}
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if (g_bEnabled) {
		if (!bHooked) {
			HookEvent("player_spawn", 			Event_PlayerSpawn,		EventHookMode_Pre);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("player_spawn", 			Event_PlayerSpawn,		EventHookMode_Pre);
			bHooked = false;
		}
	}
}

public void Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	static int iLastTime;
	const int RELAX_TIME = 3;
	
	if( iLastTime != 0 )
	{
		if( iLastTime + RELAX_TIME > GetTime() ) {
			return;
		}
	}
	iLastTime = GetTime();
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		//if( !IsTank(client) )
		{
			char sClass[16];
			SIClass class = view_as<SIClass>(GetEntProp(client, Prop_Send, "m_zombieClass"));
			
			if( class == SI_Boomer )
			{
				sClass = "boomer";
			}
			else if (class == SI_Hunter )
			{
				sClass = "hunter";
			}
			else if (class == SI_Smoker )
			{
				sClass = "smoker";
			}
			if( sClass[0] )
			{
				float vecStart[3], vecNew[3];
				//GetClientAbsOrigin(client, vecStart);
				
				int rusher = GetRusherIndex();
				if( rusher != 0 )
				{
					if( L4D_GetRandomPZSpawnPosition(rusher, view_as<int>(L4D1ZombieClass_Hunter), 5, vecStart) )
					{
						int numCopies = GetNumSpecialsRequired();
						
						for( int i = 0; i < numCopies; i++ )
						{
							vecNew = vecStart;
							vecNew[0] += GetRandomFloat(0.5, 1.5);
							vecNew[1] += GetRandomFloat(0.5, 1.5);
							vecNew[2] += GetRandomFloat(0.5, 15.0);
							
							SpawnInfectedAt(vecNew, sClass);
						}
						//PrintToChatAll("duplicated: %N. Num: %i", client, numCopies);
					}
				}
			}
		}
	}
}

stock int SpawnInfectedAt(float position[3], char[] sClass)
{
	int spawner = CreateEntityByName("commentary_zombie_spawner");
	if( spawner != -1 )
	{
		DispatchSpawn(spawner);
		ActivateEntity(spawner);
		DispatchKeyValue(spawner, "targetname", "drago_spawner");
		TeleportEntity(spawner, position, view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR);
		SetVariantString("OnSpawnedZombieDeath !self:Kill::5:-1");
		AcceptEntityInput(spawner, "AddOutput");
		SetVariantString(sClass);
		AcceptEntityInput(spawner, "SpawnZombie");
	}
	return spawner;
}

stock bool IsTank(int client)
{
	static int ZOMBIECLASS_TANK;
	if( ZOMBIECLASS_TANK == 0 )
	{
		ZOMBIECLASS_TANK = GetEngineVersion() == Engine_Left4Dead2 ? ZOMBIECLASS_TANK_L4D2 : ZOMBIECLASS_TANK_L4D1;
	}
	
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_TANK == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

int GetRusherIndex()
{
	int mostPlayer;
	float mostFlow, flow;

	for( int client = 1; client <= MaxClients; client++ )
	{
		if( IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client) )
		{
			// Ignore incapped
			if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) )
				continue;
			
			// Ignore reviving
			if( GetEntPropEnt(client, Prop_Send, "m_reviveOwner") > 0 || GetEntPropEnt(client, Prop_Send, "m_reviveTarget") > 0 )
				continue;
			
			// Get flow
			flow = L4D2Direct_GetFlowDistance(client);
			if( flow && flow != -9999.0 ) // Invalid flows
			{
				if( flow > mostFlow )
				{
					mostFlow = flow;
					mostPlayer = client;
				}
			}
		}
	}
	return mostPlayer;
}

int GetPlayersCount()
{
	int iPlayersCount = 0;
	
	for( int i = 1; i <= MaxClients; i++ ) {
		if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 3 )
			iPlayersCount++;
	}
	return iPlayersCount;
}



bool hasTank()
{
	for( int i = 1; i <= MaxClients; i++ )
		if( IsTank(i) )
			return true;
	return false;
}

int GetNumSpecialsRequired()
{
	if( hasTank() )
	{
		if( g_bHardPlus )
		{
			return 10;
		}
		else if( g_bExpertPlus )
		{
			return 5;
		}
		if( g_bEasy || g_bExpert )
		{
			return 1;
		}
		else if( g_bNormal )
		{
			return 2;
		}
		else if( g_bHard )
		{
			return 3;
		}
	}
	
	if( g_bHardPlus )
	{
		return 15;
	}
	else if( g_bExpertPlus )
	{
		return 10;
	}
	
	int iPlayersCount = GetPlayersCount();
	int count;
	
	count = iPlayersCount;
	
	if( g_bEasy || g_bExpert )
	{
		if( count > 3 )
			count = 3;
	}
	else if( g_bNormal )
	{
		count += 3;
	}
	else if( g_bHard )
	{
		count += 6;
	}
	
	return count;
}