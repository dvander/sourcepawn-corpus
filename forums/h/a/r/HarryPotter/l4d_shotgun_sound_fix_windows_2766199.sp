#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

static bool L4D2;

static bool bThirdPerson[MAXPLAYERS+1];

static const char SOUND_AUTOSHOTGUN[] 		= "^weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav";
static const char SOUND_SPASSHOTGUN[] 		= "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav";
static const char SOUND_PUMPSHOTGUN[] 		= "^weapons/shotgun/gunfire/shotgun_fire_1.wav";
static const char SOUND_CHROMESHOTGUN[] 	= "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav";

public Plugin myinfo =
{
    name = "[L4D/L4D2] Thirdpersonshoulder Shotgun Sound Fix",
    author = "MasterMind420, Lux",
    description = "Thirdpersonshoulder Shotgun Sound Fix",
    version = "1.1",
    url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		L4D2 = false;
	}
	else if( test == Engine_Left4Dead2 )
	{
		L4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
}

public void OnMapStart()
{
	PrefetchSound(SOUND_AUTOSHOTGUN);
	PrecacheSound(SOUND_AUTOSHOTGUN, true);

	PrefetchSound(SOUND_SPASSHOTGUN);
	PrecacheSound(SOUND_SPASSHOTGUN, true);

	PrefetchSound(SOUND_PUMPSHOTGUN);
	PrecacheSound(SOUND_PUMPSHOTGUN, true);

	PrefetchSound(SOUND_CHROMESHOTGUN);
	PrecacheSound(SOUND_CHROMESHOTGUN, true);
}

public void Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	static int client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidClient(client))
		return;

	if(!bThirdPerson[client])
		return;

	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;

	static int weapon;
	weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(weapon == -1)
		return;

	static char sWeapon[16];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

	switch(sWeapon[0])
	{
		case 'a':
		{
			if (StrEqual(sWeapon, "autoshotgun"))
				EmitSoundToClient(client, SOUND_AUTOSHOTGUN, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		}
		case 'p':
		{
			if (StrEqual(sWeapon, "pumpshotgun"))
				EmitSoundToClient(client, SOUND_PUMPSHOTGUN, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		}
		case 's':
		{
			if(!L4D2)
				return;

			if (StrEqual(sWeapon, "shotgun_spas"))
				EmitSoundToClient(client, SOUND_SPASSHOTGUN, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			else if (StrEqual(sWeapon, "shotgun_chrome"))
				EmitSoundToClient(client, SOUND_CHROMESHOTGUN, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		}
	}
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	bThirdPerson[iClient] = bIsThirdPerson;
}

static bool IsValidClient(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}