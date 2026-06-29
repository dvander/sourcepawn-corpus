#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
    name = "[L4D/L4D2] Thirdpersonshoulder Shotgun Sound Fix",
    author = "MasterMind420, Lux",
    description = "Thirdpersonshoulder Shotgun Sound Fix",
    version = "1.1",
    url = ""
}

ConVar hPluginOn;
static bool L4D2 = false, bThirdPerson[MAXPLAYERS + 1] = {false, ...}, bHooked = false;

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

/* Plugin Functions */
public void OnPluginStart()
{
	CreateConVar("l4d_TPSSF_version", PLUGIN_VERSION, "Version of the [L4D/L4D2] Thirdpersonshoulder Shotgun Sound Fix plugin.", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("l4d_TPSSF_plugin_on", "1", "Plugin On/Off.", CVAR_FLAGS);
	hPluginOn.AddChangeHook(OnConVarChanged_Allow);
	AutoExecConfig(true, "l4d_TPSSF");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarChanged_Allow(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	}
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	client = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidClient(client) && bThirdPerson[client] && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		static int weapon;
		weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(weapon != -1)
		{
			static char sWeapon[16];
			event.GetString("weapon", sWeapon, sizeof(sWeapon));

			switch(sWeapon[0])
			{
				case 'a':
				{
					if (StrEqual(sWeapon, "autoshotgun"))
					{
						if(L4D2 && GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
						{
						    EmitGameSoundToClient(client, "AutoShotgun.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
						}
						else
						{
						    EmitGameSoundToClient(client, "AutoShotgun.Fire", SOUND_FROM_PLAYER, SND_NOFLAGS);
						}
					}
				}
				case 'p':
				{
					if (StrEqual(sWeapon, "pumpshotgun"))
					{
						if(L4D2 && GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
						{
						    EmitGameSoundToClient(client, "Shotgun.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
						}
						else
						{
						    EmitGameSoundToClient(client, "Shotgun.Fire", SOUND_FROM_PLAYER, SND_NOFLAGS);
						}
					}
				}
				case 's':
				{
					if(L4D2)
					{
						if (StrEqual(sWeapon, "shotgun_spas"))
						{
							if(GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
							{
							    EmitGameSoundToClient(client, "AutoShotgun_Spas.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
							}
							else
							{
							    EmitGameSoundToClient(client, "AutoShotgun_Spas.Fire", SOUND_FROM_PLAYER, SND_NOFLAGS);
							}
						}
						else if (StrEqual(sWeapon, "shotgun_chrome"))
						{
							if(GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
							{
							    EmitGameSoundToClient(client, "Shotgun_Chrome.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
							}
							else
							{
							    EmitGameSoundToClient(client, "Shotgun_Chrome.Fire", SOUND_FROM_PLAYER, SND_NOFLAGS);
							}
						}
					}
				}
			}
		}
	}
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	bThirdPerson[iClient] = bIsThirdPerson;
}

static bool IsValidClient(int iClient)
{
	return iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient);
}
