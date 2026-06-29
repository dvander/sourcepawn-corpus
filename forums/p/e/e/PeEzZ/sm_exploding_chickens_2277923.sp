#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin: myinfo =
{
	name = "Exploding Chickens",
	author = "PeEzZ",
	description = "Chicken exploding when die.",
	version = "1.5",
	url = "https://forums.alliedmods.net/showthread.php?t=260444"
};

new Handle: CVAR_EXPLODE_DAMAGE = INVALID_HANDLE,
	Handle: CVAR_EXPLODE_RADIUS = INVALID_HANDLE,
	Handle: CVAR_EXPLODE_SOUND = INVALID_HANDLE;

new EXPLODE_DAMAGE,
	EXPLODE_RADIUS;

new String: EXPLODE_SOUND[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	CVAR_EXPLODE_DAMAGE = CreateConVar("sm_chicken_explode_damage", "100.0", "Chicken Explode Damage. Set 0 to disable explosion.", _, true, 0.0, true, 10000.0);
	HookConVarChange(CVAR_EXPLODE_DAMAGE, OnDamageChange);
	EXPLODE_DAMAGE = GetConVarInt(CVAR_EXPLODE_DAMAGE);
	
	CVAR_EXPLODE_RADIUS = CreateConVar("sm_chicken_explode_radius", "0.0", "Chicken Explode Radius. Set 0 to auto radius.", _, true, 0.0, true, 10000.0);
	HookConVarChange(CVAR_EXPLODE_RADIUS, OnRadiusChange);
	EXPLODE_RADIUS = GetConVarInt(CVAR_EXPLODE_RADIUS);
	
	CVAR_EXPLODE_SOUND = CreateConVar("sm_chicken_explode_sound", "weapons/hegrenade/explode3.wav", "Chicken Explode Sound. Set blank for disable."); //weapons/flashbang/flashbang_explode1.wav
	HookConVarChange(CVAR_EXPLODE_SOUND, OnSoundChange);
	GetConVarString(CVAR_EXPLODE_SOUND, EXPLODE_SOUND, sizeof(EXPLODE_SOUND));
	
	HookEvent("player_death", OnPlayerDeathPre, EventHookMode_Pre);
}

public OnMapStart()
{
	if(!StrEqual(EXPLODE_SOUND, ""))
	{
		PrecacheSound(EXPLODE_SOUND, true);
	}
}

//-----EVENTS-----//
public Action: OnPlayerDeathPre(Handle: event, const String: name[], bool: dontBroadcast)
{
	new String: weaponname[32];
	GetEventString(event, "weapon", weaponname, sizeof(weaponname));
	if(StrEqual(weaponname, "chicken"))
	{
		SetEventString(event, "weapon", "hegrenade");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

//-----SDK_HOOKS-----//
public OnEntityCreated(entity)
{
	if(IsValidEntity(entity) && (EXPLODE_DAMAGE > 0))
	{
		new String: classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "chicken"))
		{
			SetEntPropFloat(entity, Prop_Data, "m_explodeDamage", float(EXPLODE_DAMAGE));
			SetEntPropFloat(entity, Prop_Data, "m_explodeRadius", float(EXPLODE_RADIUS));
			
			if(!StrEqual(EXPLODE_SOUND, ""))
			{
				HookSingleEntityOutput(entity, "OnBreak", OnBreak);
			}
		}
	}
}

//-----SINGLE_ENT_OUTPUT-----//
public OnBreak(const String: output[], caller, activator, Float: delay)
{
	if(!StrEqual(EXPLODE_SOUND, ""))
	{
		EmitSoundToAll(EXPLODE_SOUND, caller);
	}
}

//-----CVAR_CHANGE-----//
public OnDamageChange(Handle: convar, const String: oldValue[], const String: newValue[])
{
	if(!StrEqual(oldValue, newValue))
	{
		EXPLODE_DAMAGE = GetConVarInt(CVAR_EXPLODE_DAMAGE);
	}
}
public OnRadiusChange(Handle: convar, const String: oldValue[], const String: newValue[])
{
	if(!StrEqual(oldValue, newValue))
	{
		EXPLODE_RADIUS = GetConVarInt(CVAR_EXPLODE_RADIUS);
	}
}
public OnSoundChange(Handle: convar, const String: oldValue[], const String: newValue[])
{
	if(!StrEqual(oldValue, newValue))
	{
		GetConVarString(CVAR_EXPLODE_SOUND, EXPLODE_SOUND, sizeof(EXPLODE_SOUND));
		if(!StrEqual(EXPLODE_SOUND, ""))
		{
			PrecacheSound(EXPLODE_SOUND, true);
		}
	}
}