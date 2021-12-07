#pragma semicolon 1
#pragma newdecls required

#include <sourcemod> 
#include <sdktools>

#define MAXPLACES 16

int g_iPlaces[MAXPLACES];
Handle hTime[MAXPLACES];

static const char g_sParticles[4][16] = 
{ 
    "fireworks_01", 
    "fireworks_02", 
    "fireworks_03", 
    "fireworks_04" 
}; 

static const char g_sSoundsLaunch[6][46] = 
{ 
    "ambient/atmosphere/firewerks_launch_01.wav", 
    "ambient/atmosphere/firewerks_launch_02.wav", 
    "ambient/atmosphere/firewerks_launch_03.wav", 
    "ambient/atmosphere/firewerks_launch_04.wav", 
    "ambient/atmosphere/firewerks_launch_05.wav", 
    "ambient/atmosphere/firewerks_launch_06.wav" 
}; 

static const char g_sSoundsBursts[4][46] = 
{ 
    "ambient/atmosphere/firewerks_burst_01.wav", 
    "ambient/atmosphere/firewerks_burst_02.wav", 
    "ambient/atmosphere/firewerks_burst_03.wav", 
    "ambient/atmosphere/firewerks_burst_04.wav" 
}; 

public Plugin myinfo =
{
	name = "Incap Fireworks",
	author = "BHaType",
	description = "0x90",
	version = "0x90",
	url = "0x90"
};

public void OnMapStart() 
{
	int i;
	for( i = 0; i <= 3; i++ ) PrecacheParticle(g_sParticles[i]); 
	for( i = 0; i <= 3; i++ ) PrecacheSound(g_sSoundsBursts[i], true); 
	for( i = 0; i <= 5; i++ ) PrecacheSound(g_sSoundsLaunch[i], true); 
} 

public void OnPluginStart()
{
	HookEvent("player_incapacitated", eEvent);
	HookEvent("revive_success", eEvent);
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if(strcmp(name, "player_incapacitated") == 0)
		{
			for(int i; i < MAXPLACES; i++)
			{
				if(g_iPlaces[i] == 0 || g_iPlaces[i] == INVALID_ENT_REFERENCE)
				{
					g_iPlaces[i] = GetClientUserId(client);
					hTime[i] = CreateTimer(1.3, tFireworks, i, TIMER_REPEAT);
					break;
				}
			}
		}
		else
		{
			client = GetClientOfUserId(event.GetInt("subject"));
			for(int i; i < MAXPLACES; i++)
			{
				if(GetClientOfUserId(g_iPlaces[i]) == client)
				{
					g_iPlaces[i] = INVALID_ENT_REFERENCE;
					delete hTime[i];
					break;
				}
			}
		}
	}
}

public Action tFireworks (Handle timer, int index)
{
	int client = GetClientOfUserId(g_iPlaces[index]);
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float vPos[3], vAng[3];
		
		GetClientAbsOrigin(client, vPos);
		vAng[0] = GetRandomFloat(-10.0, 10.0); 
		vAng[1] = GetRandomFloat(-10.0, 10.0); 
		vAng[2] = GetRandomFloat(-10.0, 10.0); 

		DisplayParticle(g_sParticles[GetRandomInt(0, 3)], vPos, vAng);
		
		vPos[2] += 200.0;
		
		EmitAmbientSound(g_sSoundsLaunch[GetRandomInt(0, 5)], vPos, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL); 
		
		if(GetRandomInt(0, 5) <= 3)  
			EmitAmbientSound(g_sSoundsBursts[GetRandomInt(0, 3)], vPos, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL); 
	}
	else
	{
		g_iPlaces[index] = INVALID_ENT_REFERENCE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

void DisplayParticle(const char[] sParticle, const float vPos[3], const float vAng[3])
{
	int entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		
		SetVariantString("OnUser1 !self:kill::6.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}