#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools_tempents>

#define TRANSMIT_HOOK SDKHook_SetTransmit

#define STOP_SND "BaseCombatCharacter.StopWeaponSounds"

static int g_Ragdoll[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;
static int g_Weapon[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;
static int g_LastAttacker[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;
//static int g_LastVictim[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;

static float g_TimeUntilDecloak[MAXPLAYERS+1] = -1.0;

//static ArrayList g_Ragdoll_Array;
//#define RAG_ARRAY_SIZE 6

public Plugin myinfo = {
	name = "Feign sniper kills",
	author = "Seta00, Shadowysn (fake death features)",
	description = "Feign sniper kills with a configurable minimum distance",
	version = "1.5",
	url = "http://www.sourcemod.net/"
}

bool b_lateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_TF2)
	{
		b_lateLoad = true;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

ConVar cv_distance;
ConVar FeignSnipe_CloakTime;

static float f_distance;

public void OnPluginStart() {
	//g_Ragdoll_Array = CreateArray(1, 0);
	
	cv_distance = CreateConVar("sm_feignsniperkills_distance", "750", "Maximum distance between Sniper and victim for kills to register", FCVAR_NONE, true, 0.0);
	f_distance = GetConVarFloat(cv_distance);
	HookConVarChange(cv_distance, f_distance_OnConVarChange);
	
	FeignSnipe_CloakTime = CreateConVar("sm_feignsniperkills_invis", "1.5", "Total number of seconds until marked-as-hit people reappear", FCVAR_NONE, true, 0.0);
	
	if (b_lateLoad) {
		for (int i = 1; i < MaxClients; ++i) {
			if (IsValidClient(i)) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
	AutoExecConfig(true, "feign_sniper_kills");
}

public void OnPluginEnd()
{
	for (int client = 1; client <= MAXPLAYERS; client++) {
		RemoveRagdoll(client);
		RemoveWeapon(client);
	}
}

void f_distance_OnConVarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	f_distance = StringToFloat(newVal);
}

public void OnMapStart()
{
	PrecacheSound(STOP_SND, true);
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (!strcmp(classname, "player") || !strcmp(classname, "tf_bot")) {
		RequestFrame(OnEntityCreated_RequestFrame, entity);
	}
}

public void OnClientDisconnect(int client){
	RemoveRagdoll(client);
	RemoveWeapon(client);
}

void OnEntityCreated_RequestFrame(int entity)
{
	if (!IsValidClient(entity)) return;
	
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damageType, int& weapon, 
float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsValidClient(victim) || !IsValidClient(attacker)) return Plugin_Continue;
	
	char inflictingWeapon[32];
	GetClientWeapon(attacker, inflictingWeapon, sizeof(inflictingWeapon));
	
	float attackerOrigin[3], victimOrigin[3];
	GetClientAbsOrigin(attacker, attackerOrigin);
	GetClientAbsOrigin(victim, victimOrigin);
	float distance = GetVectorDistance(attackerOrigin, victimOrigin);
	
	if ((!strncmp(inflictingWeapon, "tf_weapon_sniperrifle", 21) || !strcmp(inflictingWeapon, "tf_weapon_compound_bow")) && distance > f_distance) {
		g_LastAttacker[victim] = attacker;
		//g_LastVictim[attacker] = victim;
		
		Handle newEvent = CreateEvent("player_death");
		if (newEvent != null)
		{
			SetEventInt(newEvent, "userid", GetClientUserId(victim));
			SetEventInt(newEvent, "attacker", GetClientUserId(attacker));
			SetEventString(newEvent, "weapon", "sniperrifle");
	
			float victimPos[3];
			GetClientEyePosition(victim, victimPos);
			victimPos[2] += 4.0;
	
			if (damageType & DMG_CRIT)
			{
				SetEventInt(newEvent, "customkill", TF_CUSTOM_HEADSHOT);
				SetEventBool(newEvent, "crit", true);
				TE_ParticleToClient(attacker, "crit_text", victimPos);
			}
			else if (damageType & DMG_ACID)
			{
				TE_ParticleToClient(attacker, "minicrit_text", damagePosition);
			}
			else
			{
				TE_ParticleToClient(attacker, "hit_text", damagePosition);
			}
			FireEvent(newEvent);
		}
		
		Handle newEvent2 = CreateEvent("npc_hurt");
		if (newEvent2 != null)
		{
			/*SetEventInt(newEvent2, "userid", GetClientUserId(victim));
			SetEventInt(newEvent2, "health", 0);
			SetEventInt(newEvent2, "attacker", GetClientUserId(attacker));
			SetEventInt(newEvent2, "damageamount", RoundToFloor(damage));
			//SetEventInt(newEvent2, "custom", damagecustom);*/
			SetEventInt(newEvent2, "attacker_player", GetClientUserId(attacker));
			SetEventInt(newEvent2, "entindex", EntRefToEntIndex(victim));
			SetEventInt(newEvent2, "health", 0);
			SetEventInt(newEvent2, "damageamount", RoundToFloor(damage));
			FireEvent(newEvent2);
		}
		
		if (g_TimeUntilDecloak[victim] < GetGameTime())
		{ BeginAttackerEffects(victim, attacker, weapon, damage, damageType, damageForce, damagePosition, damagecustom); }
		
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

// stolen from Thrawn's tHeadshotOnly. yarrpen-source!
void TE_ParticleToClient(int client,
			const char[] Name,
			const float origin[3]=NULL_VECTOR,
			const float start[3]=NULL_VECTOR,
			const float angles[3]=NULL_VECTOR,
			int entindex=-1,
			int attachtype=-1,
			int attachpoint=-1,
			bool resetParticles=true,
			float delay=0.0)
{
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }

    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;
    int i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    TE_SendToClient(client, delay);
}

Action HookTransmit_Timer(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	
	HookTransmit(client);
}

void BeginAttackerEffects(int client, int attacker, int weapon, const float damage, int damageType, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	TE_ParticleToClient(attacker, "blood_impact_red_01", damagePosition);
	
	SpawnRagdoll(client, weapon, damage, damageType, damageForce, damagecustom);
	SpawnWeapon(client);
	//HookTransmit(client, false);
	CreateTimer(0.02, HookTransmit_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
	g_TimeUntilDecloak[client] = GetGameTime()+GetConVarFloat(FeignSnipe_CloakTime);
	
	EmitGameSoundToClient(attacker, STOP_SND, client, SNDCHAN_VOICE);
	
	if ( (damageType & DMG_CRIT) && !(damageType & DMG_BLAST) )
	{ DoClientScream(client, 2, attacker); }
	else if ( (damageType & DMG_CLUB) && !(damageType & DMG_BLAST) )
	{ DoClientScream(client, 3, attacker); }
	else if (damageType & DMG_BLAST)
	{ DoClientScream(client, 0, attacker); }
	else
	{ DoClientScream(client, 1, attacker); }
}

void SpawnRagdoll(int client, int weapon, const float damage, int damageType, const float damageForce[3], int damagecustom)
{
	//SDKCall(hCreateRagdollEntity, client);
	
	RemoveRagdoll(client);
	
	int ragdoll = CreateEntityByName("tf_ragdoll");
	DispatchSpawn(ragdoll);
	
	float PlayerPosition[3];
	
	GetClientAbsOrigin(client, PlayerPosition);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", PlayerPosition);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", damageForce);
	TeleportEntity(ragdoll, PlayerPosition, NULL_VECTOR, NULL_VECTOR);
	
	TFClassType class = TF2_GetPlayerClass(client);
	int team = GetClientTeam(client);
	
	int disguise_class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	//int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	if (IsDisguisedAsFriendly(client))
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", disguise_class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", disguise_team);
		//SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1);
		SetEntProp(ragdoll, Prop_Send, "m_bWasDisguised", 1); // This makes the ragdoll use the disguise cosmetics instead of the real spy's cosmetics.
	}
	else
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", team);
	} // NOTE: There's a glitch with disguises where the gibs are the fake class.
	//if (!IsDisguised(client))
	SetEntPropEnt(ragdoll, Prop_Send, "m_iPlayerIndex", client);
	
	if ((TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_BurningPyro)) && 
	class != TFClass_Pyro)
	{ SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1); }
	
	Handle playergib_cvar = FindConVar("tf_playergib");
	
	int skin = GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride"); // Check for Voodoo cosmetics
	if (IsDisguisedAsFriendly(client))
	{ skin = GetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride"); }
	
	int wep_index = -1;
	if (IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"); }
	if
	(
		(
			(
				(damageType & DMG_BLAST)
				|| // or
				wep_index == 1098
			)
			&& // and
			(
				damage > 20.0
				|| // or
				(damageType & DMG_CRIT)
			)
			&& // and
			GetConVarInt(playergib_cvar) == 1
			|| // or
			GetConVarInt(playergib_cvar) >= 2
		)
	)
	{
		if (skin != 1)
		{ 
			SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1); // This allows creating multiple gib groups but screws up bodygroups
			if (wep_index == 1098)
			{
				SetEntProp(ragdoll, Prop_Send, "m_bCritOnHardHit", 1);
			}
		}
		SetEntProp(ragdoll, Prop_Send, "m_bGib", 1);
		//int gibHead = CreateEntityByName("raggib");
		//SetEntPropVector(gibHead, Prop_Send, "m_vecOrigin", PlayerPosition);
	}
	if (playergib_cvar != null) CloseHandle(playergib_cvar);
	if (damagecustom)
	{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", damagecustom); }
	
	if (IsValidEntity(weapon))
	{
		char wep_netclass_attacker[PLATFORM_MAX_PATH+1];
		GetEntityClassname(weapon, wep_netclass_attacker, sizeof(wep_netclass_attacker));
		//PrintToChatAll("%s", wep_netclass_attacker); // Debug
		
		if (wep_netclass_attacker[0] && 
		(StrContains(wep_netclass_attacker, "tf_weapon*", false) || StrContains(wep_netclass_attacker, "tf_wearable*", false)) )
		{
			//PrintToChatAll("%i", wep_index); 
			//PrintToChatAll("%i", damagecustom);
			if (wep_index == 813 || wep_index == 834) // Neon Annihilator (For some reason it's assigned 2 IDs. https://steamcommunity.com/sharedfiles/filedetails/?id=504159631)
			{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", 46); }
			else if (wep_index == 649 && damagecustom == TF_CUSTOM_BACKSTAB) // Spy-cicle
			{ SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", 1); }
			else if (wep_index == 595 || wep_index == 594 || wep_index == 593) // Manmelter (595) + The Third Degree (593) + Phlogistinator (594)
			{ SetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh", 1); }
			else if (wep_index == 225 || wep_index == 574) // Your Eternal Reward (225) + Wanga Prick (574)
			{ SetEntProp(ragdoll, Prop_Send, "m_bCloaked", 1); }
		}
	}
	
	SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 0);
	if (IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")))
	{ SetEntProp(ragdoll, Prop_Send, "m_bOnGround", 1); }
	
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
	
	SetVariantString("OnUser1 !self:Kill::15.0:-1");
	AcceptEntityInput(ragdoll, "AddOutput");
	AcceptEntityInput(ragdoll, "FireUser1");
	
	ActivateEntity(ragdoll);
	
	HookTransmit(ragdoll);
	//SetEdictFlags(ragdoll, (GetEdictFlags(ragdoll) & ~FL_EDICT_ALWAYS & FL_EDICT_FULLCHECK));
	//SetEdictFlags(ragdoll, FL_EDICT_DONTSEND);
	//RequestFrame(testcallback, ragdoll);
	
	//PushToBottom_g_Ragdoll_Array(ragdoll);
	g_Ragdoll[client] = ragdoll;
}

/*void testcallback(int entity)
{
	SetEdictFlags(entity, FL_EDICT_FULLCHECK);
}*/

void RemoveRagdoll(int client)
{
	if (IsValidEntity(g_Ragdoll[client]))
	{
		char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(g_Ragdoll[client], classname, sizeof(classname));
		if(StrEqual(classname, "tf_ragdoll", false))
		{
			AcceptEntityInput(g_Ragdoll[client], "Kill");
		}
		//SetEntProp(client, Prop_Send, "m_hRagdoll", -1);
		g_Ragdoll[client] = INVALID_ENT_REFERENCE;
	}
}

/*void Safe_RemoveRagdoll(int entity)
{
	if (IsValidEntity(entity))
	{
		char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrContains(classname, "ragdoll", false) > -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}*/

void SpawnWeapon(int client)
{
	RemoveWeapon(client);
	
	float Position[3];
	float Angles[3];
	
	GetClientAbsOrigin(client, Position);
	GetClientEyeAngles(client, Angles);
	
	// Weapon entity start v
	
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(active_wep)) return;
	
	int weapon = CreateEntityByName("tf_dropped_weapon");
	char wep_model[PLATFORM_MAX_PATH+1];
	int modelidx = GetEntProp(active_wep, Prop_Send, "m_iWorldModelIndex");
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, modelidx, wep_model, sizeof(wep_model));
	
	SetEntityModel(weapon, wep_model);
	int cl_class = GetClientTeam(client);
	SetEntProp(weapon, Prop_Data, "m_nSkin", (cl_class == 3) ? 1 : 0);
	
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"));
	SetEntProp(weapon, Prop_Send, "m_iEntityLevel", GetEntProp(active_wep, Prop_Send, "m_iEntityLevel"));
	SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", GetEntProp(active_wep, Prop_Send, "m_iItemIDHigh"));
	SetEntProp(weapon, Prop_Send, "m_iItemIDLow", GetEntProp(active_wep, Prop_Send, "m_iItemIDLow"));
	SetEntProp(weapon, Prop_Send, "m_iAccountID", GetEntProp(active_wep, Prop_Send, "m_iAccountID"));
	SetEntProp(weapon, Prop_Send, "m_iEntityQuality", GetEntProp(active_wep, Prop_Send, "m_iEntityQuality"));
	SetEntProp(weapon, Prop_Send, "m_bOnlyIterateItemViewAttributes", 
	GetEntProp(active_wep, Prop_Send, "m_bOnlyIterateItemViewAttributes"));
	SetEntProp(weapon, Prop_Send, "m_iTeamNumber", GetClientTeam(client));
	
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 0);
	
	SetHandPos(client, weapon);
	
	DispatchSpawn(weapon);
	ActivateEntity(weapon);
	
	SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	
	HookTransmit(weapon);
	
	SetVariantString("OnUser1 !self:Kill::15.0:-1");
	AcceptEntityInput(weapon, "AddOutput");
	AcceptEntityInput(weapon, "FireUser1");
	
	g_Weapon[client] = weapon;
	
	// Weapon entity end ^
}

void RemoveWeapon(int client)
{	
	if (IsValidEntity(g_Weapon[client]))
	{
		char classname[32];
		GetEdictClassname(g_Weapon[client], classname, sizeof(classname));
		if(StrEqual(classname, "tf_dropped_weapon", false))
		{
			AcceptEntityInput(g_Weapon[client], "kill");
		}
		g_Weapon[client] = INVALID_ENT_REFERENCE;
	}
}

void SetHandPos(int client, int entity)
{
	float Position[3];
	float Angles[3];
	
	GetClientAbsOrigin(client, Position);
	GetClientEyeAngles(client, Angles);
	
	TeleportEntity(entity, Position, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	SetVariantString("effect_hand_r");
	AcceptEntityInput(entity, "SetParentAttachment");
	
	AcceptEntityInput(entity, "ClearParent", -1, -1);
	
	TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
}

void DoClientScream(int client, int type = 1, int snd_target)
{
	if (!IsValidClient(client))
	{ return; }
	
	static char targetclassname_cl[128];
	int class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	
	if (!IsDisguisedAsFriendly(client))
	{ class = GetEntProp(client, Prop_Send, "m_iClass"); }
	
	switch (class)
	{
		case 1: // Scout
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Scout");
		}
		case 3: // Soldier
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Soldier");
		}
		case 7: // Pyro
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Pyro");
		}
		case 4: // Demoman
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Demoman");
		}
		case 6: // Heavy
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Heavy");
		}
		case 9: // Engineer
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Engineer");
		}
		case 5: // Medic
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Medic");
		}
		case 2: // Sniper
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Sniper");
		}
		case 8: // Spy
		{
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "Spy");
		}
	}
	
	static char dot_str[32];
	switch (type)
	{
		case 0:
		{ strcopy(dot_str, sizeof(dot_str), "ExplosionDeath"); }
		case 1:
		{ strcopy(dot_str, sizeof(dot_str), "Death"); }
		case 2:
		{ strcopy(dot_str, sizeof(dot_str), "CritDeath"); }
		case 3:
		{ strcopy(dot_str, sizeof(dot_str), "MeleeDeath"); }
	}
	
	static char scream_str[128];
	Format(scream_str, sizeof(scream_str), "%s.%s", targetclassname_cl, dot_str);
	
	/*int source_ent = client;
	int ragdoll = g_Ragdoll[client];
	if (IsValidEntity(ragdoll) && ragdoll > 0)
	{ source_ent = ragdoll; }*/
	
	//float source_orig[3]; GetEntPropVector(source_ent, Prop_Data, "m_vecOrigin", source_orig);
	float source_orig[3]; GetClientAbsOrigin(client, source_orig);
	
	int source_ent = CreateEntityByName("info_target");
	TeleportEntity(source_ent, source_orig, NULL_VECTOR, NULL_VECTOR);
	SetEdictFlags(source_ent, FL_EDICT_ALWAYS);
	DispatchSpawn(source_ent);
	ActivateEntity(source_ent);
	SetVariantString("OnUser1 !self:Kill::1.0:-1");
	AcceptEntityInput(source_ent, "AddOutput");
	AcceptEntityInput(source_ent, "FireUser1");
	
	EmitGameSoundToClient(snd_target, scream_str, source_ent, SNDCHAN_VOICE);
}

bool IsValidClient(int client, bool replaycheck = true)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
    if (replaycheck)
    {
        if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    }
    return true;
}

bool IsDisguisedAsFriendly(int client)
{
	//int class = GetEntProp(client, Prop_Send, "m_iClass");
	int team = GetClientTeam(client);
	
	int disguise_class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && disguise_index > -1 &&
	disguise_class > 0 && disguise_team == team)
	{
		return true;
	}
	return false;
}

void HookTransmit(int entity, bool boolean = true)
{
    if (!IsValidEntity(entity)) return;
    if (boolean)
    { SDKHook(entity, TRANSMIT_HOOK, Hook_SetTransmit); }
    else
    { SDKUnhook(entity, TRANSMIT_HOOK, Hook_SetTransmit); }
}

Action Hook_SetTransmit(int entity, int client)
{
	bool isValidCl = IsValidClient(client);
	bool isValidEntCl = IsValidClient(entity);
	
	if (HasEntProp(entity, Prop_Send, "m_bGoldRagdoll"))
	setEFlags(entity);
	
	if (!IsValidEntity(entity))
	{
		HookTransmit(entity, false);
		return Plugin_Continue;
	}
	if (!isValidCl)
	return Plugin_Continue;
	
	if (entity == client)
	return Plugin_Continue;
	
	float game_time = GetGameTime();
	float time_til_decloak = -1.0;
	if (isValidEntCl)
	{ time_til_decloak = g_TimeUntilDecloak[entity]; }
	
	//int victim = -1;
	int attacker = -1;
	if (IsValidEntity(entity))
	{
		attacker = GetAttacker(entity);
	}
	
	bool isAttacker = (IsValidClient(attacker) &&
	client == attacker);
	
	//PrintToChat(client, "%i", isAttacker);
	//PrintToChat(client, "%i", (time_til_decloak < game_time));
	if
	(
		(!isValidEntCl && isAttacker) ||
		(isValidEntCl && (!isAttacker || time_til_decloak < game_time))
	)
	{
		//PrintToChat(client, "bruh");
		if (isValidEntCl && time_til_decloak < game_time)
		{ HookTransmit(entity, false); }
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

void setEFlags(int edict) // Thanks to SM9(); on the Sourcemod Discord for this
{
    if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
        SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
}

int GetAttacker(int entity)
{
	if (!IsValidEntity(entity)) return -1;
	
	if (IsValidClient(entity))
	{
		return g_LastAttacker[entity];
	}
	
	char classname[PLATFORM_MAX_PATH+1];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	int temp_client = -1;
	
	if (StrEqual(classname, "tf_ragdoll", false))
	{
		if (HasEntProp(entity, Prop_Send, "m_iPlayerIndex"))
		{
			int temp_vic = GetEntPropEnt(entity, Prop_Send, "m_iPlayerIndex");
			if (temp_vic < MAXPLAYERS)
			{ temp_client = g_LastAttacker[temp_vic]; }
		}
	}
	else if (StrEqual(classname, "tf_dropped_weapon", false))
	{
		// This is only for the dropped weapons spawned from this plugin
		if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int temp_vic = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (temp_vic < MAXPLAYERS)
			{ temp_client = g_LastAttacker[temp_vic]; }
		}
	}
	
	return temp_client;
}

/*void PushToBottom_g_Ragdoll_Array(int cell)
{
	for (int i = 0; i < GetArraySize(g_Ragdoll_Array); ++i) {
		int temp_cell = GetArrayCell(g_Ragdoll_Array, i);
		
		PrintToChatAll("%i", temp_cell);
	}
	
	//if (FindValue)
	int array_size = GetArraySize(g_Ragdoll_Array);
	if (array_size > 0 && array_size >= RAG_ARRAY_SIZE)
	{
		//int temp_index = GetArraySize(g_Ragdoll_Array)-1;
		int temp_index = 0;
		
		int remove_Cell = GetArrayCell(g_Ragdoll_Array, temp_index);
		if (remove_Cell && IsValidEntity(remove_Cell))
		{
			Safe_RemoveRagdoll(remove_Cell);
			RemoveFromArray(g_Ragdoll_Array, temp_index);
		}
	}
	
	//ShiftArrayUp(g_Ragdoll_Array, 0);
	PushArrayCell(g_Ragdoll_Array, cell);
}*/