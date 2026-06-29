#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"

#define GRENADE_USERID 0
#define GRENADE_TEAM 1
#define GRENADE_PROJECTILE 2
#define GRENADE_PARTICLE 3
#define GRENADE_LIGHT 4
#define GRENADE_REMOVETIMER 5
#define GRENADE_DAMAGETIMER 6

new Handle:g_hSmokeGrenades;

new Handle:g_hCVDamage;
new Handle:g_hCVSeconds;
new Handle:g_hCVColorT;
new Handle:g_hCVColorCT;
new Handle:g_hCVTeam;
new Handle:g_hCVFriendlyFire;

public Plugin:myinfo = 
{
	name = "Poison Smoke",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Damages anyone who walks into a smokegrenade",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_posionsmoke_version", PLUGIN_VERSION, "Poison Smoke version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVDamage = CreateConVar("sm_poisonsmoke_damage", "5", "How much damage should we deal to the players in the smoke?", FCVAR_PLUGIN, true, 0.0);
	g_hCVSeconds = CreateConVar("sm_poisonsmoke_seconds", "1", "Deal damage every x seconds.", FCVAR_PLUGIN, true, 1.0);
	g_hCVColorT = CreateConVar("sm_poisonsmoke_color_t", "20 250 50", "What color should the smoke be for grenades thrown by terrorists? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);
	g_hCVColorCT = CreateConVar("sm_poisonsmoke_color_ct", "20 250 50", "What color should the smoke be for grenades thrown by counter-terrorists? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);
	g_hCVTeam = CreateConVar("sm_poisonsmoke_team", "0", "Which teams should be allowed to use poison smokes? 0: Both, 1: T, 2: CT", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	g_hCVFriendlyFire = FindConVar("mp_friendlyfire");
	
	g_hSmokeGrenades = CreateArray();
	
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	HookEvent("round_start", Event_OnResetSmokes);
	HookEvent("round_end", Event_OnResetSmokes);
}

public OnMapEnd()
{
	new iSize = GetArraySize(g_hSmokeGrenades);
	new Handle:hGrenade, Handle:hTimer;
	for(new i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(g_hSmokeGrenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			hTimer = GetArrayCell(hGrenade, GRENADE_REMOVETIMER);
			KillTimer(hTimer);
			hTimer = GetArrayCell(hGrenade, GRENADE_DAMAGETIMER);
			if(hTimer != INVALID_HANDLE)
				KillTimer(hTimer);
		}
		CloseHandle(hGrenade);
	}
	ClearArray(g_hSmokeGrenades);
}

// Change the killicon to a grenade. Smokes don't have an own icon, so we'll use the flashbang!
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sWeapon[64];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, "env_particlesmokegrenade"))
	{
		SetEventString(event, "weapon", "flashbang");
	}
	return Plugin_Continue;
}

public Event_OnResetSmokes(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hSmokeGrenades);
	new Handle:hGrenade, Handle:hTimer, iLight = -1;
	for(new i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(g_hSmokeGrenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			hTimer = GetArrayCell(hGrenade, GRENADE_REMOVETIMER);
			KillTimer(hTimer);
			hTimer = GetArrayCell(hGrenade, GRENADE_DAMAGETIMER);
			if(hTimer != INVALID_HANDLE)
				KillTimer(hTimer);
			// Keep the color on round end
			if(StrEqual(name, "round_start"))
			{
				iLight = GetArrayCell(hGrenade, GRENADE_LIGHT);
				if(iLight > 0 && IsValidEntity(iLight))
					AcceptEntityInput(iLight, "kill");
			}
		}
		CloseHandle(hGrenade);
	}
	ClearArray(g_hSmokeGrenades);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "smokegrenade_projectile", false))
	{
		SDKHook(entity, SDKHook_Spawn, Hook_OnSpawnProjectile);
	}
	
	if(StrEqual(classname, "env_particlesmokegrenade", false))
	{
		SDKHook(entity, SDKHook_Spawn, Hook_OnSpawnParticles);
	}
}

public Hook_OnSpawnProjectile(entity)
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1 || !IsClientInGame(client))
		return;
	
	// Maybe someone wants to restrict it to admins only?
	if(!CheckCommandAccess(client, "poison_grenade", ADMFLAG_CUSTOM1, true))
		return;
	
	new iRequiredTeam = GetConVarInt(g_hCVTeam);
	if(iRequiredTeam > 0 && iRequiredTeam != (GetClientTeam(client)-1))
		return;
	
	// Save that smoke in our array
	new Handle:hGrenade = CreateArray();
	PushArrayCell(hGrenade, GetClientUserId(client));
	PushArrayCell(hGrenade, GetClientTeam(client));
	PushArrayCell(hGrenade, entity);
	PushArrayCell(g_hSmokeGrenades, hGrenade);
}


public Hook_OnSpawnParticles(entity)
{
	new Float:fOrigin[3], Float:fOriginSmoke[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);
	
	new iSize = GetArraySize(g_hSmokeGrenades);
	new Handle:hGrenade, iGrenade;
	for(new i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(g_hSmokeGrenades, i);
		iGrenade = GetArrayCell(hGrenade, GRENADE_PROJECTILE);
		GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", fOriginSmoke);
		if(fOrigin[0] == fOriginSmoke[0] && fOrigin[1] == fOriginSmoke[1] && fOrigin[2] == fOriginSmoke[2])
		{
			PushArrayCell(hGrenade, entity);
			
			decl String:sBuffer[64];
			new iEnt = CreateEntityByName("light_dynamic");
			Format(sBuffer, sizeof(sBuffer), "smokelight_%d", entity);
			DispatchKeyValue(iEnt,"targetname", sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%f %f %f", fOriginSmoke[0], fOriginSmoke[1], fOriginSmoke[2]);
			DispatchKeyValue(iEnt, "origin", sBuffer);
			DispatchKeyValue(iEnt, "angles", "-90 0 0");
			if(GetArrayCell(hGrenade, GRENADE_TEAM) == 2)
				GetConVarString(g_hCVColorT, sBuffer, sizeof(sBuffer));
			// Fall back to CT color, even if the player switched to spectator after he threw the nade
			else
				GetConVarString(g_hCVColorCT, sBuffer, sizeof(sBuffer));
			DispatchKeyValue(iEnt, "_light", sBuffer);
			//DispatchKeyValue(iEnt, "_inner_cone","-89");
			//DispatchKeyValue(iEnt, "_cone","-89");
			DispatchKeyValue(iEnt, "pitch","-90");
			DispatchKeyValue(iEnt, "distance","256");
			DispatchKeyValue(iEnt, "spotlight_radius","96");
			DispatchKeyValue(iEnt, "brightness","3");
			DispatchKeyValue(iEnt, "style","6");
			DispatchKeyValue(iEnt, "spawnflags","1");
			DispatchSpawn(iEnt);
			AcceptEntityInput(iEnt, "DisableShadow");
			
			new Float:fFadeStartTime = GetEntPropFloat(entity, Prop_Send, "m_FadeStartTime");
			new Float:fFadeEndTime = GetEntPropFloat(entity, Prop_Send, "m_FadeEndTime");
			
			new String:sAddOutput[64];
			// Remove the light when the smoke vanished
			Format(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:kill::%f:1", fFadeEndTime);
			SetVariantString(sAddOutput);
			AcceptEntityInput(iEnt, "AddOutput");
			// Turn the light off, 1 second before the smoke it completely vanished
			Format(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:TurnOff::%f:1", fFadeStartTime+4.0);
			SetVariantString(sAddOutput);
			AcceptEntityInput(iEnt, "AddOutput");
			// Don't light any players or models, when the smoke starts to clear!
			Format(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:spawnflags:3:%f:1", fFadeStartTime);
			SetVariantString(sAddOutput);
			AcceptEntityInput(iEnt, "AddOutput");
			AcceptEntityInput(iEnt, "FireUser1");
			
			PushArrayCell(hGrenade, iEnt);
			
			new Handle:hTimer = CreateTimer(fFadeEndTime, Timer_RemoveSmoke, entity, TIMER_FLAG_NO_MAPCHANGE);
			PushArrayCell(hGrenade, hTimer);
			
			// Only start dealing damage, if we really want to. Just color it otherwise.
			new Handle:hTimer2 = INVALID_HANDLE;
			if(GetConVarFloat(g_hCVDamage) > 0.0)
				hTimer2 = CreateTimer(GetConVarFloat(g_hCVSeconds), Timer_CheckDamage, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			PushArrayCell(hGrenade, hTimer2);
			
			break;
		}
	}
}

// Remove the poison effect, 2 seconds before the smoke is completely vanished
public Action:Timer_RemoveSmoke(Handle:timer, any:entity)
{
	// Get the grenade array with this entity index
	new iSize = GetArraySize(g_hSmokeGrenades);
	new Handle:hGrenade, iGrenade = -1;
	for(new i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(g_hSmokeGrenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			iGrenade = GetArrayCell(hGrenade, GRENADE_PARTICLE);
			// This is the right grenade
			// Remove it
			if(iGrenade == entity)
			{
				// Remove the smoke in 3 seconds
				AcceptEntityInput(iGrenade, "TurnOff");
				decl String:sOutput[64];
				Format(sOutput, sizeof(sOutput), "OnUser1 !self:kill::3.0:1");
				SetVariantString(sOutput);
				AcceptEntityInput(iGrenade, "AddOutput");
				AcceptEntityInput(iGrenade, "FireUser1");
				
				new Handle:hTimer = GetArrayCell(hGrenade, GRENADE_DAMAGETIMER);
				if(hTimer != INVALID_HANDLE)
					KillTimer(hTimer);
				
				RemoveFromArray(g_hSmokeGrenades, i);
				break;
			}
		}
	}
	
	return Plugin_Stop;
}

// Do damage every seconds to players in the smoke
public Action:Timer_CheckDamage(Handle:timer, any:entityref)
{
	new entity = EntRefToEntIndex(entityref);
	if(entity == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	// Get the grenade array with this entity index
	new iSize = GetArraySize(g_hSmokeGrenades);
	new Handle:hGrenade, iGrenade = -1;
	for(new i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(g_hSmokeGrenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			iGrenade = GetArrayCell(hGrenade, GRENADE_PARTICLE);
			if(iGrenade == entity)
				break;
		}
	}
	
	if(iGrenade == -1)
		return Plugin_Continue;
	
	new userid = GetArrayCell(hGrenade, GRENADE_USERID);
	
	// Don't do anything, if the client who's thrown the grenade left.
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Continue;
	
	new Float:fSmokeOrigin[3], Float:fOrigin[3];
	GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", fSmokeOrigin);
	
	new iGrenadeTeam = GetArrayCell(hGrenade, GRENADE_TEAM);
	new bool:bFriendlyFire = GetConVarBool(g_hCVFriendlyFire);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && (bFriendlyFire || GetClientTeam(i) != iGrenadeTeam))
		{
			GetClientAbsOrigin(i, fOrigin);
			if(GetVectorDistance(fSmokeOrigin, fOrigin) <= 220)
				SDKHooks_TakeDamage(i, iGrenade, client, GetConVarFloat(g_hCVDamage), DMG_POISON, -1, NULL_VECTOR, fSmokeOrigin);
		}
	}
	
	return Plugin_Continue;
}