#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION	"3.2"

public Plugin myinfo =
{
	name = "[TF2] Respawn Effects",
	author = "Lucas 'aIM' Maza",
	description = "Adds a particle effect on players upon respawning.",
	version = PLUGIN_VERSION,
	url = ""
};

// ConVars
ConVar g_hRedPart;
ConVar g_hBluPart;
ConVar g_hDonorPart;
ConVar g_hSound;
ConVar g_hDonorSound;

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	
	CreateConVar("sm_respawnsfx_version", PLUGIN_VERSION, "Respawn Effects version. Don't touch this!", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hRedPart = CreateConVar("sm_rsfx_redparticle", "teleportedin_red", "Particle to use on RED players.");
	g_hBluPart = CreateConVar("sm_rsfx_bluparticle", "teleportedin_blue", "Particle to use on BLU players.");
	g_hDonorPart = CreateConVar("sm_rsfx_donorparticle", "eotl_pyro_pool_explosion", "Particle to use on donators.");
	g_hSound = CreateConVar("sm_rsfx_sound", "items/spawn_item.wav", "Path to the sound played when someone respawns.");
	g_hDonorSound = CreateConVar("sm_rsfx_donorsound", "weapons/teleporter_send.wav", "Path to the sound player when a donator respawns.");
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int user = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char hRedPart[150];
	char hBluPart[150];
	char hDonorPart[150];
	char hSound[PLATFORM_MAX_PATH];
	char hDonorSound[PLATFORM_MAX_PATH];
	
	GetConVarString(g_hRedPart, hRedPart, sizeof(hRedPart));
	GetConVarString(g_hBluPart, hBluPart, sizeof(hBluPart));
	GetConVarString(g_hDonorPart, hDonorPart, sizeof(hDonorPart));
	GetConVarString(g_hSound, hSound, sizeof(hSound));
	GetConVarString(g_hDonorSound, hDonorSound, sizeof(hDonorSound));
	
	if (!strlen(hRedPart) || !strlen(hBluPart) || !strlen(hDonorPart) || !strlen(hSound) || !strlen(hDonorSound))
	{
		return Plugin_Continue;
	}
	
	PrecacheSound(hSound);
	PrecacheSound(hDonorSound);

	if (IsPlayerAlive(user) && CheckCommandAccess(user, "respawnsfx_donator", ADMFLAG_RESERVATION))
	{
		AttachParticle (user, hDonorPart, 4.0);
		EmitSoundToClient(user, hDonorSound);
	}
	else
	{
		switch (TF2_GetClientTeam(user))
		{
			case TFTeam_Red: 
			{
				AttachParticle (user, hRedPart, 2.5);
				EmitSoundToClient(user, hSound);
			}
			case TFTeam_Blue: 
			{
				AttachParticle (user, hBluPart, 2.5);
				EmitSoundToClient(user, hSound);
			}
		}
	}
	
	return Plugin_Continue;
}

stock AttachParticle(ent, char[] particleType, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	char tName[32];

	if (IsValidEntity(particle))
    {
        float pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
	else
    {
        LogError("[Respawn SFX] Particle System failed to create (Missing Particle Name/Doesn't Exist)");
    }
}

public Action DeleteParticles(Handle timer, any particle)
{
    if (EntRefToEntIndex(particle) != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(particle, "Kill");
    }
}