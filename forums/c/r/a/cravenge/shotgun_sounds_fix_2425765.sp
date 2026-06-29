#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:SOUND_AUTOSHOTGUN[] = "weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav";
static const String:SOUND_SPASSHOTGUN[] = "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav";
static const String:SOUND_PUMPSHOTGUN[] = "weapons/shotgun/gunfire/shotgun_fire_1.wav";
static const String:SOUND_CHROMESHOTGUN[] = "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav";

static bool:confirmChangedView[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
    name = "Shotgun Sounds Fix",
    author = "DeathChaos25",
    description = "Fixes Bug Where Shotguns Don't Produce Sound In Third Person View.",
    version = "1.0",
    url = "https://forums.alliedmods.net/showthread.php?t=259986"
};

public OnPluginStart()
{
	HookEvent("weapon_fire", OnWeaponFire);
	
	CreateTimer(1.0, CheckCurrentView, _, TIMER_REPEAT);
}

public Action:CheckCurrentView(Handle:timer)
{
	for (new cIndex = 1; cIndex <= MaxClients; cIndex++)
	{
		if (IsClientInGame(cIndex) && !IsFakeClient(cIndex))
		{
			if (GetClientTeam(cIndex) == 2)
			{
				QueryClientConVar(cIndex, "c_thirdpersonshoulder", QueryClientConVarCallback);
			}
		}
	}
	
	return Plugin_Continue;
}

public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsClientInGame(client))
	{
		if (result != ConVarQuery_Okay)
		{
			confirmChangedView[client] = false;
		}
		
		if (StrEqual(cvarValue, "false") || StrEqual(cvarValue, "0"))
		{
			confirmChangedView[client] = false;
		}
		
		confirmChangedView[client] = true;
	}
}

public OnMapStart()
{
	PrefetchSound(SOUND_AUTOSHOTGUN);
	PrefetchSound(SOUND_SPASSHOTGUN);
	PrefetchSound(SOUND_CHROMESHOTGUN);
	PrefetchSound(SOUND_PUMPSHOTGUN);
	
	PrecacheSound(SOUND_AUTOSHOTGUN, true);
	PrecacheSound(SOUND_SPASSHOTGUN, true);
	PrecacheSound(SOUND_CHROMESHOTGUN, true);
	PrecacheSound(SOUND_PUMPSHOTGUN, true);
}

public Action:OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !confirmChangedView[client]) 
	{
		return Plugin_Handled;
	}
	
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(client) == 2 && i == client)
		{
			if (StrEqual(weapon, "autoshotgun"))
			{
				EmitSoundToClient(i, SOUND_AUTOSHOTGUN, client, SNDCHAN_WEAPON);
			}
			else if (StrEqual(weapon, "shotgun_spas"))
			{
				EmitSoundToClient(i, SOUND_SPASSHOTGUN, client, SNDCHAN_WEAPON);
			}
			else if (StrEqual(weapon, "pumpshotgun"))
			{
				EmitSoundToClient(i, SOUND_PUMPSHOTGUN, client, SNDCHAN_WEAPON);
			}
			else if (StrEqual(weapon, "shotgun_chrome"))
			{
				EmitSoundToClient(i, SOUND_CHROMESHOTGUN, client, SNDCHAN_WEAPON);
			}
		}
	}
	
	return Plugin_Continue;
}

