#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

#define GRENADE_USERID 0
#define GRENADE_TEAM 1
#define GRENADE_PROJECTILE 2
#define GRENADE_PARTICLE 3
#define GRENADE_LIGHT 4
#define GRENADE_REMOVETIMER 5
#define GRENADE_DAMAGETIMER 6

ArrayList g_hSmokeGrenades = null;
ConVar g_hCVDamage, g_hCVSeconds, g_hCVColorT, g_hCVColorCT, g_hCVTeam, g_hCVFriendlyFire;

public Plugin myinfo = 
{
	name = "Poison Smoke",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Damages anyone who walks into a smokegrenade",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public void OnPluginStart()
{
	CreateConVar("sm_posionsmoke_version", PLUGIN_VERSION, "Poison Smoke version", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hCVDamage = CreateConVar("sm_poisonsmoke_damage", "5", "How much damage should we deal to the players in the smoke?", CVAR_FLAGS, true, 0.0);
	g_hCVSeconds = CreateConVar("sm_poisonsmoke_seconds", "1", "Deal damage every x seconds.", CVAR_FLAGS, true, 1.0);
	g_hCVColorT = CreateConVar("sm_poisonsmoke_color_t", "20 250 50", "What color should the smoke be for grenades thrown by terrorists? Format: \"red green blue\" from 0 - 255.", CVAR_FLAGS);
	g_hCVColorCT = CreateConVar("sm_poisonsmoke_color_ct", "20 250 50", "What color should the smoke be for grenades thrown by counter-terrorists? Format: \"red green blue\" from 0 - 255.", CVAR_FLAGS);
	g_hCVTeam = CreateConVar("sm_poisonsmoke_team", "0", "Which teams should be allowed to use poison smokes? 0: Both, 1: T, 2: CT", CVAR_FLAGS, true, 0.0, true, 2.0);

	g_hCVFriendlyFire = FindConVar("mp_friendlyfire");
	
	g_hSmokeGrenades = new ArrayList();

	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	HookEvent("round_start", Event_OnResetSmokes);
	HookEvent("round_end", Event_OnResetSmokes);
}

public void OnMapEnd()
{
	ArrayList hGrenade;
	Handle hTimer;
	for(int i = 0; i < g_hSmokeGrenades.Length; i++)
	{
		hGrenade = g_hSmokeGrenades.Get(i);
		if(hGrenade.Length > 3)
		{
			hTimer = hGrenade.Get(GRENADE_REMOVETIMER);
			delete hTimer;
			hTimer = hGrenade.Get(GRENADE_DAMAGETIMER);
			if(hTimer != null)
				delete hTimer;
		}
		delete hGrenade;
	}
	g_hSmokeGrenades.Clear();
}

// Change the killicon to a grenade. Smokes don't have an own icon, so we'll use the flashbang!
Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char sWeapon[64];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, "env_particlesmokegrenade"))
	{
		event.SetString("weapon", "flashbang");
	}
	return Plugin_Continue;
}

void Event_OnResetSmokes(Event event, const char[] name, bool dontBroadcast)
{
	ArrayList hGrenade;
	Handle hTimer;
	int iLight = -1;
	for(int i = 0; i < g_hSmokeGrenades.Length; i++)
	{
		hGrenade = g_hSmokeGrenades.Get(i);
		if(hGrenade.Length > 3)
		{
			hTimer = hGrenade.Get(GRENADE_REMOVETIMER);
			delete hTimer;
			hTimer = hGrenade.Get(GRENADE_DAMAGETIMER);
			if(hTimer != null)
				delete hTimer;
			// Keep the color on round end
			if(StrEqual(name, "round_start"))
			{
				iLight = hGrenade.Get(GRENADE_LIGHT);
				if(iLight > 0 && IsValidEntity(iLight))
					AcceptEntityInput(iLight, "kill");
			}
		}
		delete hGrenade;
	}
	g_hSmokeGrenades.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
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

void Hook_OnSpawnProjectile(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1 || !IsClientInGame(client))
		return;

	// Maybe someone wants to restrict it to admins only?
	if(!CheckCommandAccess(client, "poison_grenade", ADMFLAG_CUSTOM1, true))
		return;
	
	int iRequiredTeam = g_hCVTeam.IntValue;
	if(iRequiredTeam > 0 && iRequiredTeam != (GetClientTeam(client)-1))
		return;
	
	// Save that smoke in our array
	ArrayList hGrenade = new ArrayList();
	hGrenade.Push(GetClientUserId(client));
	hGrenade.Push(GetClientTeam(client));
	hGrenade.Push(entity);
	g_hSmokeGrenades.Push(hGrenade);
}

void Hook_OnSpawnParticles(int entity)
{
	float fOrigin[3], fOriginSmoke[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);

	ArrayList hGrenade;
	int iGrenade;
	for(int i = 0; i < g_hSmokeGrenades.Length; i++)
	{
		hGrenade = g_hSmokeGrenades.Get(i);
		iGrenade = hGrenade.Get(GRENADE_PROJECTILE);
		GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", fOriginSmoke);
		if(fOrigin[0] == fOriginSmoke[0] && fOrigin[1] == fOriginSmoke[1] && fOrigin[2] == fOriginSmoke[2])
		{
			hGrenade.Push(entity);
			
			char sBuffer[64];
			int iEnt = CreateEntityByName("light_dynamic");
			Format(sBuffer, sizeof(sBuffer), "smokelight_%d", entity);
			DispatchKeyValue(iEnt,"targetname", sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%f %f %f", fOriginSmoke[0], fOriginSmoke[1], fOriginSmoke[2]);
			DispatchKeyValue(iEnt, "origin", sBuffer);
			DispatchKeyValue(iEnt, "angles", "-90 0 0");
			if(hGrenade.Get(GRENADE_TEAM) == 2)
				g_hCVColorT.GetString(sBuffer, sizeof(sBuffer));
			// Fall back to CT color, even if the player switched to spectator after he threw the nade
			else
				g_hCVColorCT.GetString(sBuffer, sizeof(sBuffer));
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
			
			float fFadeStartTime = GetEntPropFloat(entity, Prop_Send, "m_FadeStartTime");
			float fFadeEndTime = GetEntPropFloat(entity, Prop_Send, "m_FadeEndTime");
			
			char sAddOutput[64];
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
			
			hGrenade.Push(iEnt);
			
			Handle hTimer = CreateTimer(fFadeEndTime, Timer_RemoveSmoke, entity, TIMER_FLAG_NO_MAPCHANGE);
			hGrenade.Push(hTimer);
			
			// Only start dealing damage, if we really want to. Just color it otherwise.
			Handle hTimer2 = null;
			if(g_hCVDamage.FloatValue > 0.0)
				hTimer2 = CreateTimer(g_hCVSeconds.FloatValue, Timer_CheckDamage, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			hGrenade.Push(hTimer2);
			
			break;
		}
	}
}

// Remove the poison effect, 2 seconds before the smoke is completely vanished
Action Timer_RemoveSmoke(Handle timer, any entity)
{
	// Get the grenade array with this entity index
	ArrayList hGrenade;
	int iGrenade = -1;
	for(int i = 0; i < g_hSmokeGrenades.Length; i++)
	{
		hGrenade = g_hSmokeGrenades.Get(i);
		if(hGrenade.Length > 3)
		{
			iGrenade = hGrenade.Get(GRENADE_PARTICLE);
			// This is the right grenade
			// Remove it
			if(iGrenade == entity)
			{
				// Remove the smoke in 3 seconds
				AcceptEntityInput(iGrenade, "TurnOff");
				char sOutput[64];
				Format(sOutput, sizeof(sOutput), "OnUser1 !self:kill::3.0:1");
				SetVariantString(sOutput);
				AcceptEntityInput(iGrenade, "AddOutput");
				AcceptEntityInput(iGrenade, "FireUser1");

				Handle hTimer = hGrenade.Get(GRENADE_DAMAGETIMER);
				if(hTimer != null)
					delete hTimer;
				
				g_hSmokeGrenades.Erase(i);
				break;
			}
		}
	}

	return Plugin_Stop;
}

// Do damage every seconds to players in the smoke
Action Timer_CheckDamage(Handle timer, any entityref)
{
	int entity = EntRefToEntIndex(entityref);
	if(entity == INVALID_ENT_REFERENCE)
	{
		return Plugin_Continue;
	}

	// Get the grenade array with this entity index
	ArrayList hGrenade;
	int iGrenade = -1;
	for(int i = 0; i < g_hSmokeGrenades.Length; i++)
	{
		hGrenade = g_hSmokeGrenades.Get(i);
		if(hGrenade.Length > 3)
		{
			iGrenade = hGrenade.Get(GRENADE_PARTICLE);
			if(iGrenade == entity)
			{
				break;
			}
		}
	}

	if(iGrenade == -1)
	{
		return Plugin_Continue;
	}

	int userid = hGrenade.Get(GRENADE_USERID);

	// Don't do anything, if the client who's thrown the grenade left.
	int client = GetClientOfUserId(userid);
	if(!client)
	{
		return Plugin_Continue;
	}

	float fSmokeOrigin[3], fOrigin[3];
	GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", fSmokeOrigin);

	int iGrenadeTeam = hGrenade.Get(GRENADE_TEAM);
	bool bFriendlyFire = g_hCVFriendlyFire.BoolValue;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && (bFriendlyFire || GetClientTeam(i) != iGrenadeTeam))
		{
			GetClientAbsOrigin(i, fOrigin);
			if(GetVectorDistance(fSmokeOrigin, fOrigin) <= 220)
			{
				SDKHooks_TakeDamage(i, iGrenade, client, g_hCVDamage.FloatValue, DMG_POISON, -1, NULL_VECTOR, fSmokeOrigin);
			}
		}
	}
	
	return Plugin_Continue;
}
