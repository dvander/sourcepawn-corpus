#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hSpawnDelay = INVALID_HANDLE;
new Handle:g_hDropDelay = INVALID_HANDLE;
new Handle:g_hDropDeath = INVALID_HANDLE;
new Handle:g_hDissolve = INVALID_HANDLE;

new Handle:g_hWeapons = INVALID_HANDLE;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bEnding, bool:g_bDropDeath, bool:g_bDissolve;
new Float:g_fSpawnDelay, Float:g_fDropDelay;
new String:g_sDissolve[4];

public Plugin:myinfo = 
{
	name = "CSS Anti Weapon Spam",
	author = "Twisted|Panda",
	description = "Automatically deletes spawned weapon entities after x seconds to prevent spam/lag.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_anti_weapon_spam_version", PLUGIN_VERSION, "CSS Anti Weapon Spam: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_anti_weapon_spam_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hSpawnDelay = CreateConVar("css_anti_weapon_spam_delay", "30.0", "The number of seconds after a weapon is created that it is checked for ownership and deleted if necessary. (0.0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpawnDelay, OnSettingsChange);
	g_hDropDelay = CreateConVar("css_anti_weapon_spam_drop", "10.0", "The number of seconds after a weapon is dropped that it is checked for ownership and deleted if necessary. (0.0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hDropDelay, OnSettingsChange);
	g_hDropDeath = CreateConVar("css_anti_weapon_spam_death", "0", "If enabled, the weapons dropped after a player's death will be deleted after css_anti_weapon_spam_drop delay.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDropDeath, OnSettingsChange);
	g_hDissolve = CreateConVar("css_anti_weapon_spam_dissolve", "3", "The desired dissolve effect to apply to removing weapons. (-1 = Disabled, 0 = Energy, 1 = Light, 2 = Heavy, 3 = Core)", FCVAR_NONE, true, -1.0, true, 3.0);
	HookConVarChange(g_hDissolve, OnSettingsChange);
	
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fSpawnDelay = GetConVarFloat(g_hSpawnDelay);
	g_fDropDelay = GetConVarFloat(g_hDropDelay);
	g_bDropDeath = GetConVarBool(g_hDropDeath);
	GetConVarString(g_hDissolve, g_sDissolve, 4);
	g_bDissolve = GetConVarInt(g_hDissolve) >= 0 ? true : false;
	
	new _iTemp;
	g_hWeapons = CreateTrie();
	SetTrieValue(g_hWeapons, "weapon_hegrenade", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_smokegrenade", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_flashbang", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_knife", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_glock", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_usp", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_p228", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_deagle", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_elite", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_fiveseven", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_m3", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_xm1014", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_galil", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_ak47", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_scout", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_sg552", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_awp", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_g3sg1", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_famas", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_m4a1", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_aug", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_sg550", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_mac10", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_tmp", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_mp5navy", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_ump45", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_p90", _iTemp++);
	SetTrieValue(g_hWeapons, "weapon_m249", _iTemp++);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSpawnDelay)
		g_fSpawnDelay = StringToFloat(newvalue);
	else if(cvar == g_hDropDelay)
		g_fDropDelay = StringToFloat(newvalue);
	else if(cvar == g_hDropDeath)
		g_bDropDeath = StringToInt(newvalue) ? true : false;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_bEnabled && entity >= 0 && !g_bEnding)
	{
		decl _iValid;
		if(GetTrieValue(g_hWeapons, classname, _iValid))
			CreateTimer(g_fSpawnDelay, Timer_DeleteWeapon, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{	
		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					SDKHook(i, SDKHook_WeaponDrop, Hook_OnWeaponDrop);
				}	
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_WeaponDrop, Hook_OnWeaponDrop);
		}
	}
}

public Action:Hook_OnWeaponDrop(client, weapon)
{
	if(g_bEnabled && weapon > 0 && !g_bEnding)
	{
		decl _iValid, String:_sClassname[32];
		GetEntityClassname(weapon, _sClassname, sizeof(_sClassname));
		if(GetTrieValue(g_hWeapons, _sClassname, _iValid))
		{
			if(IsClientInGame(client))
			{
				if(!g_bDropDeath && GetClientHealth(client) <= 0)
					return Plugin_Continue;

				CreateTimer(g_fDropDelay, Timer_DeleteWeapon, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;
	}

	return Plugin_Continue;
}

public Action:Timer_DeleteWeapon(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1)
		{
			if(g_bDissolve)
			{
				new _iDissolve = CreateEntityByName("env_entity_dissolver");
				if(_iDissolve > 0)
				{
					decl String:_sName[64];
					GetEntPropString(entity, Prop_Data, "m_iName", _sName, 64);
					if(StrEqual(_sName, ""))
					{
						Format(_sName, sizeof(_sName), "Weapon_%d", entity);
						DispatchKeyValue(entity, "targetname", _sName);
					}
					DispatchKeyValue(_iDissolve, "dissolvetype", g_sDissolve);
					DispatchKeyValue(_iDissolve, "target", _sName);
					AcceptEntityInput(_iDissolve, "Dissolve");
					CreateTimer(1.0, Timer_KillEntity, ref);
					CreateTimer(0.1, Timer_KillEntity, EntIndexToEntRef(_iDissolve));
					return Plugin_Continue;
				}
			}

			AcceptEntityInput(entity, "Kill");
		}
	}

	return Plugin_Continue;
}

public Action:Timer_KillEntity(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1)
			AcceptEntityInput(entity, "Kill");

	return Plugin_Continue;
}