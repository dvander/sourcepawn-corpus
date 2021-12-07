#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME "[TF2] Trapped Sandvich"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Heavies can press RELOAD whilst eating a Sandvich to throw a trapped sandvich."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Trapped Sandvich"
#define PLUGIN_NAME_TECH "trapped_sandvich"

#define SANDVICH_MDL "models/items/plate.mdl"
#define CLASS_TRAP "item_healthkit_small"
#define TARGETNAME_TRAP "plugin_trapped_sandvich"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

//static int oldHealth[MAXPLAYERS+1] = 0;
static int trappedSandvich[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;
static int healonhit_Amount[MAXPLAYERS+1] = -1;

ConVar TrappedSandvich_Enable;
ConVar TrappedSandvich_Damage;
//ConVar TrappedSandvich_NotifyHurt;
ConVar TrappedSandvich_NotifyClassChange;
ConVar TrappedSandvich_NotifyDeath;

ConVar version_cvar;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	char temp_str[128];
	char desc_str[256];
	
	Format(temp_str, sizeof(temp_str), "sm_%s_enable", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "Allow Heavies to throw trapped sandviches by holding RELOAD while throwing a Sandvich.");
	TrappedSandvich_Enable = CreateConVar(temp_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_damage", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "Additional damage to add to victims of trapped sandviches.");
	TrappedSandvich_Damage = CreateConVar(temp_str, "0.0", desc_str, FCVAR_NONE, true, 0.0);
	
	//Format(temp_str, sizeof(temp_str), "sm_%s_notify_hurt", PLUGIN_NAME_TECH);
	//strcopy(desc_str, sizeof(desc_str), "Notify players when they get hurt by a trapped sandvich?");
	//TrappedSandvich_NotifyHurt = CreateConVar(temp_str, "1.0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_notify_classchange", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "Notify players that change to Heavy about how to throw trapped sandviches?");
	TrappedSandvich_NotifyClassChange = CreateConVar(temp_str, "1.0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_notify_death", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "Notify players when they ate a trapped sandvich which caused them to die?");
	TrappedSandvich_NotifyDeath = CreateConVar(temp_str, "1.0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(desc_str, sizeof(desc_str), "%s version", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar("sm_trapped_sandvich_version", PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	HookEvent("player_team", player_team, EventHookMode_Post);
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_healonhit", player_healonhit, EventHookMode_Pre);
	HookEvent("player_changeclass", player_changeclass, EventHookMode_Post);
	
	AutoExecConfig(true, "TF2_Trapped_Sandvich");
	LoadTranslations("trapped_sandvich.phrases");
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		RemoveTrappedSandvich(trappedSandvich[i]);
	}
}

void player_team(Handle event, const char[] name, bool dontBroadcast) 
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	int sandvich = trappedSandvich[client];
	if (!IsValidEntity(sandvich) || sandvich <= 0) return;
	
	SetEntPropEnt(sandvich, Prop_Send, "m_hOwnerEntity", -1);
	SetVariantString("OnUser1 !self:Kill::15.0:-1"); // Only allow for a max of 15 seconds of life time after being invalidated.
	AcceptEntityInput(sandvich, "AddOutput");
	AcceptEntityInput(sandvich, "FireUser1");
	trappedSandvich[client] = INVALID_ENT_REFERENCE;
}

void player_changeclass(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(TrappedSandvich_Enable) || !GetConVarBool(TrappedSandvich_NotifyClassChange)) return;
	
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	TFClassType class = view_as<TFClassType>(GetEventInt(event, "class"));
	if (class != TFClass_Heavy) return;
	
	CreateTimer(1.0, player_changeclass_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action player_changeclass_Timer(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	
	PrintHintText(client, "%t", "Trapped Sandvich Hint");
}

void player_death(Handle event, const char[] name, bool dontBroadcast) 
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	int inflictorID = GetEventInt(event, "inflictor_entindex");
	int inflictor = EntIndexToEntRef(inflictorID);
	char targetname[PLATFORM_MAX_PATH+1];
	GetEntPropString(inflictor, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	if (StrContains(targetname, TARGETNAME_TRAP, false) < 0) return;
	
	SetEventString(event, "weapon", TARGETNAME_TRAP);
	SetEventString(event, "weapon_logclassname", TARGETNAME_TRAP);
	
	if (!GetConVarBool(TrappedSandvich_NotifyDeath)) return;
	
	CreateTimer(0.25, player_death_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action player_death_Timer(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	
	PrintHintText(client, "%t", "Died By Trapped Sandvich");
}

void player_healonhit(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetEventInt(event, "entindex");
	if (!IsValidClient(client)) return;
	
	int amount = GetEventInt(event, "amount");
	if (amount <= 0) return;
	
	healonhit_Amount[client] = amount;
	//SetEventInt(event, "amount", -amount-GetConVarInt(TrappedSandvich_Damage));
	SetEventBroadcast(event, true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarBool(TrappedSandvich_Enable) && StrEqual(classname, "item_healthkit_medium"))
	{
		SDKHook(entity, SDKHook_SpawnPost, RemoveOldSandvich);
	}
}

void RemoveOldSandvich(int entity)
{
	SDKUnhook(entity, SDKHook_SpawnPost, RemoveOldSandvich);
	/*char test_info[256];
	GetEntPropString(entity, Prop_Data, "m_ModelName", test_info, sizeof(test_info));
	PrintToChatAll("%s", test_info);*/
	
	//PrintToChatAll("%i", GetEntProp(entity, Prop_Data, "m_nModelIndex"));
	
	/*float vecMins[3], vecMaxs[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);
	PrintToChatAll("m_vecMins: %f %f %f  m_vecMaxs: %f %f %f", vecMins[0], vecMins[1], vecMins[2], vecMaxs[0], vecMaxs[1], vecMaxs[2]);*/
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsPlayerAliveOrNotGhost(client)) return;
	
	RemoveTrappedSandvich(trappedSandvich[client]);
	
	if (!(GetClientButtons(client) & IN_RELOAD)) return;
	
	int slotS = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (!IsValidEntity(slotS)) return;
	//PrintToChatAll("%i", GetEntProp(slotS, Prop_Send, "m_bBroken"));
	
	int wep_index = -1;
	if (IsValidEntity(slotS) && HasEntProp(slotS, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(slotS, Prop_Send, "m_iItemDefinitionIndex"); }
	
	// 42 = Sandvich.
	if (wep_index != 42) return;
	
	float angForward[3];
	GetClientEyeAngles(client, angForward);
	angForward[0] -= 10.0;
	
	float vecForward[3], vecRight[3], vecUp[3];
	GetAngleVectors( angForward, vecForward, vecRight, vecUp );
	float divideVel = 500.0;
	float vecVelocity[3];
	vecVelocity[0] = vecForward[0] * divideVel; vecVelocity[1] = vecForward[1] * divideVel; vecVelocity[2] = vecForward[2] * divideVel;
	
	int new_ent = SpawnTrappedSandvich(entity, vecVelocity);
	
	if (!IsValidEntity(new_ent) || new_ent <= 0)
	{
		PrintToServer("[SM] [Trapped Sandvich] Something went wrong whilst trying to spawn a trapped sandvich!");
		return;
	}
	
	AcceptEntityInput(entity, "Kill");
}

Action PreventPickup_Timer(Handle timer, int entity)
{
	if (!IsValidEntity(entity))
	{ return; }
	
	SetEntProp(entity, Prop_Send, "m_iTeamNum", 0);
}

/*Action OnFakeSandvichPickup(int entity, int client)
{
	PrintToChatAll("Prevent!!");
	if (IsPlayerAliveOrNotGhost(client))
	{ return Plugin_Handled; }
	return Plugin_Continue;
}

Action PreventPickup_End(Handle timer, int entity)
{
	HookTouch(entity, false);
}

void HookTouch(int entity, bool boolean = true)
{
	PrintToChatAll("HookTouch");
	if (!IsValidEntity(entity)) return;
	if (boolean)
	{
		SDKHook(entity, SDKHook_Touch, OnFakeSandvichPickup);
		SDKHook(entity, SDKHook_StartTouch, OnFakeSandvichPickup);
	}
	else
	{
		SDKUnhook(entity, SDKHook_Touch, OnFakeSandvichPickup);
		SDKUnhook(entity, SDKHook_StartTouch, OnFakeSandvichPickup);
	}
}*/

/*public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float[3] vel, float[3] angles, int& weapon)
{
	if (!GetConVarBool(TrappedSandvich_Enable)) return;
	
	if (!IsPlayerAliveOrNotGhost(client)) return;
	PrintToChatAll("%i", !(buttons & IN_RELOAD));
	if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return;
	if (oldHealth[client] <= 0)
	{ oldHealth[client] = GetClientHealth(client); }
	
	if (!(buttons & IN_RELOAD)) return;
	
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(active_wep)) return;
	
	//TFClassType class = TF2_GetPlayerClass(client);
	//if (class != TFClass_Heavy) return;
	
	int wep_index = -1;
	if (IsValidEntity(active_wep) && HasEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"); }
	PrintToChatAll("%i", wep_index);
	// 42 = Sandvich.
	if (wep_index != 42) return;
	
	TF2_RemoveCondition(client, TFCond_Taunting);
	SpawnTrappedSandvich(client);
}*/

/*public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float[3] vel, float[3] angles, int& weapon)
{
	if (!GetConVarBool(TrappedSandvich_Enable)) return;
	
	if (!IsPlayerAliveOrNotGhost(client)) return;
	PrintToChatAll("%i", !(buttons & IN_RELOAD));
	
	if (oldHealth[client] <= 0)
	{ oldHealth[client] = GetClientHealth(client); }
	
	if (!(buttons & IN_RELOAD) || !(buttons & IN_ATTACK2)) return;
	
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(active_wep)) return;
	
	//TFClassType class = TF2_GetPlayerClass(client);
	//if (class != TFClass_Heavy) return;
	
	int wep_index = -1;
	if (IsValidEntity(active_wep) && HasEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"); }
	PrintToChatAll("%i", wep_index);
	// 42 = Sandvich.
	if (wep_index != 42) return;
	
	SpawnTrappedSandvich(client);
}*/

/*public void OnMapStart()
{
	
}*/

int SpawnTrappedSandvich(int entity, const float Velocity[3])
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (!IsPlayerAliveOrNotGhost(client)) return -1;
	
	int pack = CreateEntityByName(CLASS_TRAP);
	DispatchKeyValue(pack, "AutoMaterialize", "0");
	DispatchKeyValue(pack, "velocity", "0.0 0.0 0.1");
	DispatchKeyValue(pack, "basevelocity", "0.0 0.0 0.1");
	
	char temp_str[128];
	Format(temp_str, sizeof(temp_str), "%s_%i", TARGETNAME_TRAP, EntRefToEntIndex(pack));
	DispatchKeyValue(pack, "targetname", temp_str);
	
	float ent_pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", ent_pos);
	
	TeleportEntity(pack, ent_pos, NULL_VECTOR, Velocity);
	
	SetEntProp(pack, Prop_Data, "m_bActivateWhenAtRest", 1);
	SetEntProp(pack, Prop_Send, "m_ubInterpolationFrame", 0);
	trappedSandvich[client] = pack;
	SetEntPropEnt(pack, Prop_Send, "m_hOwnerEntity", client);
	SetEntityGravity(pack, 1.0);
	
	DispatchKeyValue(pack, "powerup_model", SANDVICH_MDL);
	
	//HookTouch(entity);
	//CreateTimer(1.0, PreventPickup_End, entity, TIMER_FLAG_NO_MAPCHANGE);
	
	SetEntProp(pack, Prop_Send, "m_iTeamNum", 1); // This helps keep both teams from picking it up prematurely, including the thrower
	CreateTimer(0.5, PreventPickup_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	DispatchSpawn(pack);
	ActivateEntity(pack);
	
	SetEntProp(pack, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client)); // Store initial team for later, when it gets picked up
	
	SetEntityMoveType(pack, MOVETYPE_FLYGRAVITY);
	SetEntProp(pack, Prop_Send, "movecollide", 1); // These two...
	SetEntProp(pack, Prop_Data, "m_MoveCollide", 1); // ...allow the pack to bounce.
	
	// This forces sandvich model on all holiday modes. Thanks to https://forums.alliedmods.net/showthread.php?p=2416912
	if (HasEntProp(pack, Prop_Send, "m_nModelIndexOverrides"))
	{
		int mdl_override_index = GetEntProp(pack, Prop_Send, "m_nModelIndexOverrides", _, 0);
		SetEntProp(pack, Prop_Send, "m_nModelIndexOverrides", mdl_override_index, _, 1);
		SetEntProp(pack, Prop_Send, "m_nModelIndexOverrides", mdl_override_index, _, 2);
		SetEntProp(pack, Prop_Send, "m_nModelIndexOverrides", mdl_override_index, _, 3);
	}
	
	float vecMins[3], vecMaxs[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);
	//PrintToChatAll("m_vecMins: %f %f %f  m_vecMaxs: %f %f %f", vecMins[0], vecMins[1], vecMins[2], vecMaxs[0], vecMaxs[1], vecMaxs[2]);
	
	SetEntPropVector(pack, Prop_Send, "m_vecMins", vecMins);
	SetEntPropVector(pack, Prop_Send, "m_vecMaxs", vecMaxs);
	
	DispatchKeyValue(pack, "nextthink", "0.5"); // The fix to the laggy physics.
	
	SetVariantString("OnPlayerTouch !self:Kill::1.0:-1");
	AcceptEntityInput(pack, "AddOutput");
	
	HookSingleEntityOutput(pack, "OnPlayerTouch", Output_OnPlayerTouch, true);
	
	SetVariantString("OnUser1 !self:Kill::30.0:-1");
	AcceptEntityInput(pack, "AddOutput");
	AcceptEntityInput(pack, "FireUser1");
	
	//RequestFrame(SpawnPack_FrameCallback, pack); // Have to change movetype in a frame callback
	return pack;
}

void RemoveTrappedSandvich(int sandvich)
{
	if (!IsValidEntity(sandvich) || sandvich <= INVALID_ENT_REFERENCE) return;
	
	char classname[PLATFORM_MAX_PATH+1];
	GetEntityClassname(sandvich, classname, sizeof(classname));
	if (StrEqual(classname, CLASS_TRAP, false))
	{
		AcceptEntityInput(sandvich, "Kill");
	}
}

void Output_OnPlayerTouch(const char[] output, int caller, int activator, float delay)
{
	if (!IsPlayerAliveOrNotGhost(activator) || !IsValidEntity(caller)) return;
	
	/*float damage = GetConVarFloat(TrappedSandvich_Damage);
	if (damage <= 0.0) return;
	
	TFClassType class = TF2_GetPlayerClass(activator);
	if (class == TFClass_Scout)
	{ damage += 35.0; } // 100.0
	else if (class == TFClass_Heavy)
	{ damage += 105.0; } // 170.0*/
	int damage_int = healonhit_Amount[activator]+GetConVarInt(TrappedSandvich_Damage);
	float damage = damage_int+0.0;
	
	if (damage <= 0.0) return;
	
	int thrower = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	int thrower_team = -1;
	int caller_initialteam = GetEntProp(caller, Prop_Data, "m_iInitialTeamNum"); // Time to check if thrower's team still matches caller's team
	int slotS = -1;
	if (IsValidClient(thrower) && GetClientTeam(thrower) == caller_initialteam) // If it does, then set them as the damage dealer.
	{
		thrower_team = GetClientTeam(thrower);
		slotS = GetPlayerWeaponSlot(thrower, TFWeaponSlot_Secondary);
	}
	else // Otherwise they're invalid or on a different team now; if so, set the sandvich as the damage dealer.
	{
		thrower_team = caller_initialteam;
		thrower = caller;
	}
	
	if (GetClientTeam(activator) != thrower_team)
	{
		EmitGameSoundToAll("Flesh.BulletImpact", activator);
		SetEntityHealth(activator, GetClientHealth(activator)-healonhit_Amount[activator]);
		SDKHooks_TakeDamage(activator, caller, thrower, damage, DMG_CLUB|DMG_PREVENT_PHYSICS_FORCE, slotS);
	}
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

bool IsPlayerAliveOrNotGhost(int client)
{
	if (!IsValidClient(client))
	{ return false; }
	if (!IsPlayerAlive(client) || TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{ return false; }
	return true;
}