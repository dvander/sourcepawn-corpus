// Ver 1.1
// - Updated to new syntax
// - Added proper damage flags to the damage of the taunt, DMG_CLUB and DMG_BLAST, so they will now 
// gib and/or make a critical death scream.
// - Added cabertauntkill.cfg to cfg/sourcemod/
// - Fixed taunt kill from occuring with the wrong weapon and/or the wrong (paid) taunt.
// TF2's Halloween Thriller taunt can still trigger it, but the default timer is long enough that it 
// does not trigger on the short Thriller.
// - Synced the taunt kill as the swing was a bit off from the taunt kill triggering part.
// - Set caberDmg to an array per asherkin's suggestion.

#define PLUGIN_NAME "[TF2] Caber Taunt Kill"
#define PLUGIN_AUTHOR "MasterOfTheXP, Shadowysn"
#define PLUGIN_DESC "I'm gointa liquify ya. (Allows the Demoman's Caber to taunt kill.)"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?s=eeacb4270ea3c477c550561c86dc53ad&t=190171"
#define PLUGIN_NAME_SHORT "Caber TauntKill"
#define PLUGIN_NAME_TECH "cabertaunt"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define AUTOEXEC_CFG "cabertauntkill"

ConVar TauntDist, DamageExplode, DamageBroken, RadiusDist, RadiusDmg, RadiusSelfDmg, HitDelay;
float g_fTauntDist, g_fRadiusDist, g_fHitDelay;
int g_iDamageExplode, g_iDamageBroken, g_iRadiusDmg, g_iRadiusSelfDmg;

ConVar mp_friendlyfire;
bool g_bIsFFEnabled = false;

Handle g_hTimerTaunts[MAXPLAYERS+1] = {null};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

#define CABERDMG_NONE		0
#define CABERDMG_MELEE	1
#define CABERDMG_EXPLODE	2
int caberDmg[MAXPLAYERS+1] = {CABERDMG_NONE};

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_dist", PLUGIN_NAME_TECH);
	TauntDist = CreateConVar(cmd_str, "150.0", "Maximum range on the Ullapool Caber taunt kill.", FCVAR_NONE, true, 0.0);
	TauntDist.AddChangeHook(CC_CTK_Dist);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_explode", PLUGIN_NAME_TECH);
	DamageExplode = CreateConVar(cmd_str, "600", "Damage to deal on taunt kill with an un-exploded Caber.", FCVAR_NONE, true, 0.0);
	DamageExplode.AddChangeHook(CC_CTK_DmgExplode);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_broken", PLUGIN_NAME_TECH);
	DamageBroken = CreateConVar(cmd_str, "500", "Damage to deal on taunt kill with a broken Caber.", FCVAR_NONE, true, 0.0);
	DamageBroken.AddChangeHook(CC_CTK_DmgBroken);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_radiusdist", PLUGIN_NAME_TECH);
	RadiusDist = CreateConVar(cmd_str, "150.0", "To be caught within the explosion of the Caber taunt kill, you must be this close to the attacking Demoman.", FCVAR_NONE, true, 0.0);
	RadiusDist.AddChangeHook(CC_CTK_RadiusDist);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_radiusdmg", PLUGIN_NAME_TECH);
	RadiusDmg = CreateConVar(cmd_str, "200", "Damage to deal when caught within the explosion of the Caber taunt kill.", FCVAR_NONE, true, 0.0);
	RadiusDmg.AddChangeHook(CC_CTK_RadiusDmg);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_radiusselfdmg", PLUGIN_NAME_TECH);
	RadiusSelfDmg = CreateConVar(cmd_str, "50", "Damage to deal to the Demoman when the Caber explodes, due to the taunt kill.", FCVAR_NONE, true, 0.0);
	RadiusSelfDmg.AddChangeHook(CC_CTK_RadiusSelfDmg);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_hitdelay", PLUGIN_NAME_TECH);
	HitDelay = CreateConVar(cmd_str, "3.7", "How long it takes for the actual attack after the Caber's taunt is started.", FCVAR_NONE, true, 0.0);
	HitDelay.AddChangeHook(CC_CTK_HitDelay);
	
	//AddCommandListener(Command_taunt, "taunt");
	//AddCommandListener(Command_taunt, "+taunt");
	
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	if (mp_friendlyfire != null)
	{
		mp_friendlyfire.AddChangeHook(CC_mp_friendlyfire);
		CC_mp_friendlyfire(mp_friendlyfire, "", "");
	}
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

void CC_mp_friendlyfire(ConVar convar, const char[] oldValue, const char[] newValue)
{ g_bIsFFEnabled = convar.BoolValue; }

void CC_CTK_Dist(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fTauntDist =		convar.FloatValue;	}
void CC_CTK_DmgExplode(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iDamageExplode =	convar.IntValue;		}
void CC_CTK_DmgBroken(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iDamageBroken =	convar.IntValue;		}
void CC_CTK_RadiusDist(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fRadiusDist =		convar.FloatValue;	}
void CC_CTK_RadiusDmg(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iRadiusDmg =		convar.IntValue;		}
void CC_CTK_RadiusSelfDmg(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_iRadiusSelfDmg =	convar.IntValue;		}
void CC_CTK_HitDelay(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fHitDelay =		convar.FloatValue;	}
void SetCvarValues()
{
	CC_CTK_Dist(TauntDist, "", "");
	CC_CTK_DmgExplode(DamageExplode, "", "");
	CC_CTK_DmgBroken(DamageBroken, "", "");
	CC_CTK_RadiusDist(RadiusDist, "", "");
	CC_CTK_RadiusDmg(RadiusDmg, "", "");
	CC_CTK_RadiusSelfDmg(RadiusSelfDmg, "", "");
	CC_CTK_HitDelay(HitDelay, "", "");
}

public void OnMapStart()
{
	PrecacheScriptSound("Weapon_Bottle.HitFlesh");
	/*for (int i = 1; i >= 3; i++)
	{
		static char snd[32];
		Format(snd, sizeof(snd), "weapons/bottle_hit_flesh%i.wav", i);
		PrecacheSound(snd);
	}*/
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hTimerTaunts[i] != null)
		{
			KillTimer(g_hTimerTaunts[i]);
			g_hTimerTaunts[i] = null;
		}
	}
}

/*Action Command_taunt(int client, const char[] command, int args)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || 
	TF2_GetPlayerClass(client) != TFClass_DemoMan || TF2_IsPlayerInCondition(client, TFCond_Taunting))
		return Plugin_Continue;
	
	int wepEnt, meleeWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2)) != -1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	
	if (meleeWeapon == 307) CreateTimer(g_fHitDelay, CaberTauntKill, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}*/

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (TF2_GetPlayerClass(client) != TFClass_DemoMan || condition != TFCond_Taunting) return;
	
	int wepEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int meleeWeapon = 0;
	if (wepEnt != -1 && HasEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex"))
		meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	
	int tauntIdx = 0;
	if (HasEntProp(client, Prop_Send, "m_iTauntItemDefIndex"))
		tauntIdx = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
	
	if (meleeWeapon == 307 && tauntIdx == -1)
	{
		g_hTimerTaunts[client] = CreateTimer(g_fHitDelay, CaberTauntKill, GetClientUserId(client));
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (TF2_GetPlayerClass(client) != TFClass_DemoMan || condition != TFCond_Taunting) return;
	
	if (g_hTimerTaunts[client] != null)
	{ KillTimer(g_hTimerTaunts[client]); g_hTimerTaunts[client] = null; }
}

Action CaberTauntKill(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	g_hTimerTaunts[client] = null;
	if (!IsValidClient(client) || !IsPlayerAlive(client) || 
	TF2_GetPlayerClass(client) != TFClass_DemoMan || !TF2_IsPlayerInCondition(client, TFCond_Taunting))
		return Plugin_Continue;
	
	//PrintToServer("tauntDef: %i", GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex"));
	
	int wepEnt, meleeWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2)) != -1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (meleeWeapon != 307) return Plugin_Continue;
	
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos); GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	// Most of this traceray stuff is from the Khopesh Climber code found in Give Weapon
	if (!TR_DidHit(null)) return Plugin_Continue;

	int target = TR_GetEntityIndex(null);
	if (target <= 0 || target > MaxClients) return Plugin_Continue;
	
	float fNormal[3];
	TR_GetPlaneNormal(null, fNormal);
	GetVectorAngles(fNormal, fNormal);

	if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return Plugin_Continue;
	if (fNormal[0] <= -30.0) return Plugin_Continue;

	float pos[3];
	TR_GetEndPosition(pos);
	float distance = GetVectorDistance(vecClientEyePos, pos);

	if (distance >= g_fTauntDist) return Plugin_Continue;
	if (!IsPlayerAlive(target) || (GetClientTeam(target) == GetClientTeam(client) && 
	!g_bIsFFEnabled)) return Plugin_Continue;
	
	EmitGameSoundToAll("Weapon_Bottle.HitFlesh", client);
	
	/*static char snd[32];
	Format(snd, sizeof(snd), "weapons/bottle_hit_flesh%i.wav", GetRandomInt(1,3));
	EmitSoundToAll(snd, client);*/
	
	if (view_as<bool>(GetEntProp(wepEnt, Prop_Send, "m_iDetonated")))
	{
		caberDmg[client] = CABERDMG_MELEE;
		DoDamage(client, target, g_iDamageBroken, 128); // DMG_CLUB
	}
	else
	{
		caberDmg[client] = CABERDMG_EXPLODE;
		SetEntProp(wepEnt, Prop_Send, "m_bBroken", 1);
		SetEntProp(wepEnt, Prop_Send, "m_iDetonated", 1);
		// Moved them here so in case the Demo dies the weapon is still used up
		DoDamage(client, target, g_iDamageExplode, 192); // DMG_BLAST 64 + DMG_CLUB 128
		DoDamage(client, client, g_iRadiusSelfDmg, 192);
		
		int explosion = CreateEntityByName("env_explosion");
		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		if (explosion != -1)
		{
			DispatchSpawn(explosion);
			TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode", -1, -1, 0);
			RemoveEdict(explosion);
		}
		
		for (int z = 1; z <= MaxClients; z++)
		{
			if (!IsValidClient(z, true, true) || !IsPlayerAlive(z) || (GetClientTeam(z) == GetClientTeam(client) && 
			!g_bIsFFEnabled)) continue;
			
			float zPos[3];
			GetClientAbsOrigin(z, zPos);
			float Dist = GetVectorDistance(clientPos, zPos);
			if (Dist > g_fRadiusDist) continue;
			
			DoDamage(client, z, g_iRadiusDmg, 64); // DMG_BLAST
		}
	}
	return Plugin_Continue;
}

stock void DoDamage(int client, int target, int amount, int type = 0)
{
	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt == -1) return;
	
	float pos[3]; GetClientAbsOrigin(client, pos);
	DispatchKeyValue(pointHurt, "DamageTarget", "cabertaunt_hitme");
	DispatchKeyValueVector(pointHurt, "origin", pos);
	
	static char dmg[12];
	Format(dmg, sizeof(dmg), "%i", amount);
	DispatchKeyValue(pointHurt, "Damage", dmg);
	Format(dmg, sizeof(dmg), "%i", type);
	DispatchKeyValue(pointHurt, "DamageType", dmg); // DMG_BLAST (1 << 6) 64 + DMG_CLUB (1 << 7) 128

	DispatchSpawn(pointHurt);
	static char oldTargetName[64];
	GetEntPropString(target, Prop_Data, "m_iName", oldTargetName, sizeof(oldTargetName));
	DispatchKeyValue(target, "targetname", "cabertaunt_hitme");
	AcceptEntityInput(pointHurt, "Hurt", client, client);
	DispatchKeyValue(target, "targetname", oldTargetName);
	RemoveEdict(pointHurt);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker == 0 || caberDmg[attacker] == CABERDMG_NONE) return;
	
	switch (caberDmg[attacker])
	{
		case CABERDMG_MELEE:
		{
			event.SetString("weapon", "ullapool_caber");
			event.SetString("weapon_logclassname", "taunt_caber");
			caberDmg[attacker] = CABERDMG_NONE;
		}
		case CABERDMG_EXPLODE:
		{
			event.SetString("weapon", "ullapool_caber_explosion");
			event.SetString("weapon_logclassname", "taunt_caber");
			caberDmg[attacker] = CABERDMG_NONE;
		}
	}
}

stock bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		if (HasEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2, CSGO?
			if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsCoaching"))) return false;
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

/*stock int GetTauntEventIndex(int client)
{
	int offs = FindSendPropInfo("CTFPlayer", "m_iSpawnCounter");
	if (offs <= 0) return 0;	//neutral value typically found on clients
	
	return GetEntData(client, offs-24);
}*/

bool TraceRayDontHitSelf(int entity, int mask, int data)
{
	return (entity != data);
}