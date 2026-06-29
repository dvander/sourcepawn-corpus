#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_NAME "[TF2] Shotgun Disguise Fix"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Fixes missing shotguns on default disguises."
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Shotgun Disguise Fix"
#define PLUGIN_NAME_TECH "disguise_shotgun_fix"

#define SHOTGUN_CLASS_BROKEN "tf_weapon_shotgun"
#define SHOTGUN_CLASS_SOLDIER "tf_weapon_shotgun_soldier"
#define SHOTGUN_CLASS_PYRO "tf_weapon_shotgun_pyro"
#define SHOTGUN_CLASS_HEAVY "tf_weapon_shotgun_hwg"
#define SHOTGUN_CLASS_ENGINEER "tf_weapon_shotgun_primary"
#define PISTOl_CLASS_SCOUT "tf_weapon_pistol_scout"
#define PISTOl_CLASS_ENGINEER "tf_weapon_pistol"

#define SHOTGUN_ID_ENGINEER 9
#define SHOTGUN_ID_SOLDIER 10
#define SHOTGUN_ID_HEAVY 11
#define SHOTGUN_ID_PYRO 12
#define PISTOL_ID 22

#define SHOTGUN_MDL "models/weapons/c_models/c_shotgun/c_shotgun.mdl"

#define SCOUT_PISTOL_FIX false
// scout's disguise pistol is actually engineer's pistol but there's literally no difference, as said by shounic
// i only made a fix because of dead ringer spies disguised as friendly scouts dropping the pistol but
// turns out engineer and scout pistol can be picked up by both scout and engineer so uh...
#define DEBUG false

#define THINK_HOOK SDKHook_PostThink

//static TFClassType oldDisguiseClass[MAXPLAYERS+1];

bool b_lateLoad = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_TF2)
	{
		b_lateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

public void OnMapStart()
{
	PrecacheModel(SHOTGUN_MDL);
}

public void OnPluginStart()
{
	static char temp_str[32];
	static char desc_str[64];
	
	Format(temp_str, sizeof(temp_str), "sm_%s_version", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Version of the %s plugin.", PLUGIN_NAME_SHORT);
	ConVar version_cvar = CreateConVar(temp_str, PLUGIN_VERSION, desc_str, FCVAR_NONE|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	if (b_lateLoad)
	{
		for (int client = 1; client <= MAXPLAYERS; client++)
		{
			if (!IsValidClient(client) || !IsPlayerAliveOrNotGhost(client) || !TF2_IsPlayerInCondition(client, TFCond_Disguised)) continue;
			
			HookThink(client);
		}
	}
	
	#if DEBUG
	RegAdminCmd("sm_shotgundisfix_devping", Ping_CMD, ADMFLAG_CHEATS, "Ping for Shotgun Disguise Fix");
	RegAdminCmd("sm_shotgundisfix_removegun", RemoveDisguiseWep_CMD, ADMFLAG_CHEATS, "Test for Shotgun Disguise Fix");
	#endif
}

public void OnPluginEnd()
{
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		if (!IsValidClient(client) || !IsPlayerAliveOrNotGhost(client) || !TF2_IsPlayerInCondition(client, TFCond_Disguised)) continue;
		
		HookThink(client, false);
	}
}

#if DEBUG
Action RemoveDisguiseWep_CMD(int not_used, int args)
{
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		if (!IsValidClient(client) || !IsPlayerAliveOrNotGhost(client)) continue;
		
		int active_wep = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if (!RealValidEntity(active_wep)) continue;
		
		AcceptEntityInput(active_wep, "Kill");
	}
	return Plugin_Handled;
}

Action Ping_CMD(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	
	bool isDisguiseWep = true;
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if (!RealValidEntity(active_wep))
	{ active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); isDisguiseWep = false; }
	if (!RealValidEntity(active_wep)) return Plugin_Handled;
	
	if (!isDisguiseWep) PrintToServer("No disguise wep! Using active wep.");
	
	PrintToServer("m_iItemDefinitionIndex: %i", GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"));
	PrintToServer("m_iEntityLevel: %i", GetEntProp(active_wep, Prop_Send, "m_iEntityLevel"));
	PrintToServer("m_iItemIDHigh: %i", GetEntProp(active_wep, Prop_Send, "m_iItemIDHigh"));
	PrintToServer("m_iItemIDLow: %i", GetEntProp(active_wep, Prop_Send, "m_iItemIDLow"));
	PrintToServer("m_iAccountID: %i", GetEntProp(active_wep, Prop_Send, "m_iAccountID"));
	PrintToServer("m_iEntityQuality: %i", GetEntProp(active_wep, Prop_Send, "m_iEntityQuality"));
	PrintToServer("m_bOnlyIterateItemViewAttributes: %i", GetEntProp(active_wep, Prop_Send, "m_bOnlyIterateItemViewAttributes"));
	PrintToServer("m_iTeamNumber: %i", GetEntProp(active_wep, Prop_Send, "m_iTeamNumber"));
	PrintToServer("m_iTeamNum: %i", GetEntProp(active_wep, Prop_Send, "m_iTeamNum"));
	PrintToServer("m_iState: %i", GetEntProp(active_wep, Prop_Send, "m_iState"));
	PrintToServer("m_CollisionGroup: %i", GetEntProp(active_wep, Prop_Send, "m_CollisionGroup"));
	PrintToServer("m_bInitialized: %i", GetEntProp(active_wep, Prop_Send, "m_bInitialized"));
	PrintToServer("moveparent: %i", GetEntPropEnt(active_wep, Prop_Send, "moveparent"));
	PrintToServer("m_hMoveParent: %i", GetEntPropEnt(active_wep, Prop_Data, "m_hMoveParent"));
	PrintToServer("movetype: %i", GetEntProp(active_wep, Prop_Send, "movetype"));
	PrintToServer("movecollide: %i", GetEntProp(active_wep, Prop_Send, "movecollide"));
	PrintToServer("m_hOwner: %i", GetEntPropEnt(active_wep, Prop_Send, "m_hOwner"));
	PrintToServer("m_hOwnerEntity: %i", GetEntPropEnt(active_wep, Prop_Send, "m_hOwnerEntity"));
	PrintToServer("m_fEffects: %i", GetEntProp(active_wep, Prop_Send, "m_fEffects"));
	
	return Plugin_Handled;
}
#endif
// v This scout pistol fix provides a baseline for people to replace disguise weapons with anything else.
#if SCOUT_PISTOL_FIX
public void OnEntityCreated(int entity, const char[] classname) // OnEntityCreated does not work, because tf_weapon_shotgun isn't created in the first place
{
	#if DEBUG
	PrintToServer("Entity created! %i %s", entity, classname);
	#endif
	if (!RealValidEntity(entity) || classname[0] != 't') return;
	
	if (strcmp(classname, PISTOl_CLASS_ENGINEER, false) != 0) return;
	
	//SDKHook(entity, SDKHook_SpawnPost, OnPistolSpawn); // SDKHook is too early, m_bDisguiseWeapon isn't set on this
	RequestFrame(OnPistolSpawn, entity);
}
void OnPistolSpawn(int weapon)
{
	if (!RealValidEntity(weapon)) return;
	//SDKUnhook(weapon, SDKHook_SpawnPost, OnPistolSpawn);
	
	bool isDisguiseWep = view_as<bool>(GetEntProp(weapon, Prop_Send, "m_bDisguiseWeapon"));
	if (!isDisguiseWep) return;
	
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(client)) return;
	
	static char model[64];
	GetEntPropString(weapon, Prop_Data, "m_ModelName", model, sizeof(model));
	
	SetEntProp(client, Prop_Send, "m_hDisguiseWeapon", -1);
	AcceptEntityInput(weapon, "Kill");
	
	int new_wep = CreateEntityByName(PISTOl_CLASS_SCOUT);
	SetEntityModel(new_wep, model);
	AttachDisguiseWeapon(client, new_wep, PISTOL_ID);
}
#endif

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!IsValidClient(client) || condition != TFCond_Disguised) return;
	
	#if DEBUG
	PrintToServer("%N is disguised", client);
	PrintToServer("%N's disguise is: %i", client, GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	#endif
	
	//oldDisguiseClass[client] = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	
	HookThink(client);
}

void HookThink(int entity, bool boolean = true)
{
    if (boolean)
    { SDKHook(entity, THINK_HOOK, Hook_ClientThink); }
    else
    { SDKUnhook(entity, THINK_HOOK, Hook_ClientThink); }
}

void Hook_ClientThink(int client)
{
	if (!IsPlayerAliveOrNotGhost(client) || !TF2_IsPlayerInCondition(client, TFCond_Disguised)) 
	{
		HookThink(client, false);
		return;
	}
	
	bool missingWepAffect = false;
	TFClassType class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	switch (class)
	{
		case TFClass_Soldier, TFClass_Heavy, TFClass_Pyro, TFClass_Engineer: missingWepAffect = true;
	}
	
	int disguise_wep = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if (missingWepAffect && !RealValidEntity(disguise_wep))
	{
		int wep_id = -1;
		int weapon = -1;
		switch (class)
		{
			case TFClass_Soldier:	{ weapon = CreateEntityByName(SHOTGUN_CLASS_SOLDIER);	wep_id = SHOTGUN_ID_SOLDIER; }
			case TFClass_Heavy:		{ weapon = CreateEntityByName(SHOTGUN_CLASS_HEAVY);	wep_id = SHOTGUN_ID_HEAVY; }
			case TFClass_Pyro:		{ weapon = CreateEntityByName(SHOTGUN_CLASS_PYRO);		wep_id = SHOTGUN_ID_PYRO; }
			case TFClass_Engineer:	{ weapon = CreateEntityByName(SHOTGUN_CLASS_ENGINEER);	wep_id = SHOTGUN_ID_ENGINEER; }
		}
		if (wep_id < 0 || !RealValidEntity(weapon))
		{
			HookThink(client, false);
			return;
		}
		
		SetEntityModel(weapon, SHOTGUN_MDL);
		AttachDisguiseWeapon(client, weapon, wep_id);
		
		#if DEBUG 
		PrintToServer("%N doesn't have a valid disguise wep! Creating shotgun...", client); 
		#endif
		return;
	}
}

void AttachDisguiseWeapon(int client, int weapon, int wep_id = 0)
{
	int cl_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	//int real_cl_team = GetClientTeam(client);
	SetEntProp(weapon, Prop_Data, "m_nSkin", (cl_team == 3) ? 1 : 0);
	
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", wep_id);
	SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 1);
	SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 0);
	
	//SetEntProp(weapon, Prop_Send, "m_iTeamNum", cl_team);
	SetEntProp(weapon, Prop_Send, "m_iTeamNumber", cl_team);
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntProp(weapon, Prop_Send, "m_bDisguiseWeapon", 1);
	
	SetEntPropEnt(weapon, Prop_Send, "m_hOwner", client);
	SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(weapon, Prop_Send, "m_CollisionGroup", 11);
	
	float origin[3], angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientAbsAngles(client, angles);
	
	DispatchKeyValueVector(weapon, "origin", origin);
	DispatchKeyValueVector(weapon, "angles", angles);
	
	SetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon", weapon);
	
	DispatchSpawn(weapon);
	ActivateEntity(weapon);
	
	SetVariantString("!activator");
	AcceptEntityInput(weapon, "SetParent", client);
	
	SetEntProp(weapon, Prop_Send, "m_iState", 2);
	SetEntProp(weapon, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
}

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool IsPlayerAliveOrNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }