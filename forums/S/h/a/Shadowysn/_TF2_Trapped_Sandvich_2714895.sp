#define PLUGIN_NAME "[TF2] Trapped Sandvich"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Heavies can press RELOAD whilst carrying a Sandvich to throw a trapped sandvich."
#define PLUGIN_VERSION "1.0.3c"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=326857"
#define PLUGIN_NAME_SHORT "Trapped Sandvich"
#define PLUGIN_NAME_TECH "trapped_sandvich"

#define SANDVICH_MDL "models/items/plate.mdl"
#define CLASS_TRAP "item_healthkit_small"
static const char TARGETNAME_TRAP[] = "plugin_trapped_sandvich";

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

//static int oldHealth[MAXPLAYERS+1] = {0};
static int trappedSandvich[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE};
static int healonhit_Amount[MAXPLAYERS+1] = {-1};

static ConVar TrappedSandvich_Enable;
static ConVar TrappedSandvich_Damage;
//static ConVar TrappedSandvich_NotifyHurt;
static ConVar TrappedSandvich_NotifyClassChange;
static ConVar TrappedSandvich_NotifyDeath;
bool g_bEnable, g_bNotifyClassChange, g_bNotifyDeath;
int g_iDamage;

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
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_enable", PLUGIN_NAME_TECH);
	TrappedSandvich_Enable = CreateConVar(cmd_str, "1", "Allow Heavies to throw trapped sandviches by holding RELOAD while throwing a Sandvich.", FCVAR_NONE, true, 0.0, true, 1.0);
	TrappedSandvich_Enable.AddChangeHook(CC_TS_Enable);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_damage", PLUGIN_NAME_TECH);
	TrappedSandvich_Damage = CreateConVar(cmd_str, "50.0", "Damage to deal to victims of trapped sandviches.", FCVAR_NONE, true, 0.0);
	TrappedSandvich_Damage.AddChangeHook(CC_TS_Damage);
	
	//Format(cmd_str, sizeof(cmd_str), "sm_%s_notify_hurt", PLUGIN_NAME_TECH);
	//TrappedSandvich_NotifyHurt = CreateConVar(cmd_str, "1.0", "Notify players when they get hurt by a trapped sandvich?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_notify_classchange", PLUGIN_NAME_TECH);
	TrappedSandvich_NotifyClassChange = CreateConVar(cmd_str, "1.0", "Notify players that change to Heavy about how to throw trapped sandviches?", FCVAR_NONE, true, 0.0, true, 1.0);
	TrappedSandvich_NotifyClassChange.AddChangeHook(CC_TS_NotifyClassChange);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_notify_death", PLUGIN_NAME_TECH);
	TrappedSandvich_NotifyDeath = CreateConVar(cmd_str, "1.0", "Notify players when they ate a trapped sandvich which caused them to die?", FCVAR_NONE, true, 0.0, true, 1.0);
	TrappedSandvich_NotifyDeath.AddChangeHook(CC_TS_NotifyDeath);
	
	HookEvent("player_team", player_team, EventHookMode_Post);
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_healonhit", player_healonhit, EventHookMode_Pre);
	HookEvent("player_changeclass", player_changeclass, EventHookMode_Post);
	
	AutoExecConfig(true, "TF2_Trapped_Sandvich");
	SetCvars();
	LoadTranslations("trapped_sandvich.phrases");
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		RemoveTrappedSandvich(trappedSandvich[i]);
	}
}

void CC_TS_Enable(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_bEnable =			convar.BoolValue;	}
void CC_TS_Damage(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_iDamage =			convar.IntValue;	}
void CC_TS_NotifyClassChange(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bNotifyClassChange =	convar.BoolValue;	}
void CC_TS_NotifyDeath(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_bNotifyDeath =		convar.BoolValue;	}
void SetCvars()
{
	CC_TS_Enable(TrappedSandvich_Enable, "", "");
	CC_TS_Damage(TrappedSandvich_Damage, "", "");
	CC_TS_NotifyClassChange(TrappedSandvich_NotifyClassChange, "", "");
	CC_TS_NotifyDeath(TrappedSandvich_NotifyDeath, "", "");
}

void player_team(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	int sandvich = trappedSandvich[client];
	if (!RealValidEntity(sandvich)) return;
	
	SetEntPropEnt(sandvich, Prop_Send, "m_hOwnerEntity", -1);
	SetVariantString("OnUser1 !self:Kill::15.0:-1"); // Only allow for a max of 15 seconds of life time after being invalidated.
	AcceptEntityInput(sandvich, "AddOutput");
	AcceptEntityInput(sandvich, "FireUser1");
	trappedSandvich[client] = INVALID_ENT_REFERENCE;
}

void player_changeclass(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_bEnable || !g_bNotifyClassChange) return;
	
	int userid = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	TFClassType class = view_as<TFClassType>(event.GetInt("class", 0));
	if (class != TFClass_Heavy) return;
	
	CreateTimer(1.0, player_changeclass_Timer, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action player_changeclass_Timer(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	
	if (!IsValidClient(client)) return Plugin_Continue;
	
	PrintHintText(client, "%t", "Trapped Sandvich Hint");
	return Plugin_Continue;
}

void player_death(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	int inflictorID = event.GetInt("inflictor_entindex", 0);
	if (inflictorID < 0) return;
	int inflictor = EntIndexToEntRef(inflictorID);
	static char targetname[32];
	GetEntPropString(inflictor, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	//PrintToServer("targetname: %s\nstrncmp trapped_sandvich: %i", targetname, strncmp(targetname, TARGETNAME_TRAP, sizeof(TARGETNAME_TRAP)-1, false));
	if (strncmp(targetname, TARGETNAME_TRAP, sizeof(TARGETNAME_TRAP)-1) != 0) return;
	
	event.SetString("weapon", TARGETNAME_TRAP);
	event.SetString("weapon_logclassname", TARGETNAME_TRAP);
	
	if (!g_bNotifyDeath) return;
	
	CreateTimer(0.25, player_death_Timer, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action player_death_Timer(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if (!IsValidClient(client)) return Plugin_Continue;
	
	PrintHintText(client, "%t", "Died By Trapped Sandvich");
	return Plugin_Continue;
}

Action player_healonhit(Event event, const char[] name, bool dontBroadcast) 
{
	int client = event.GetInt("entindex", 0);
	if (!IsValidClient(client)) return Plugin_Continue;
	
	int amount = event.GetInt("amount", 0);
	if (amount <= 0) return Plugin_Continue;
	
	healonhit_Amount[client] = amount;
	//event.SetInt("amount", -amount-g_iDamage);
	//event.BroadcastDisabled = true;
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_bEnable && classname[0] == 'i' && strcmp(classname, "item_healthkit_medium", false) == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, RemoveOldSandvich);
	}
}

void RemoveOldSandvich(int entity)
{
	SDKUnhook(entity, SDKHook_SpawnPost, RemoveOldSandvich);
	/*static char test_info[256];
	GetEntPropString(entity, Prop_Data, "m_ModelName", test_info, sizeof(test_info));
	PrintToChatAll("%s", test_info);*/
	
	//PrintToChatAll("%i", GetEntProp(entity, Prop_Data, "m_nModelIndex"));
	
	/*float vecMins[3], vecMaxs[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);
	PrintToChatAll("m_vecMins: %f %f %f  m_vecMaxs: %f %f %f", vecMins[0], vecMins[1], vecMins[2], vecMaxs[0], vecMaxs[1], vecMaxs[2]);*/
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(client) || !IsPlayerAliveNotGhost(client)) return;
	
	RemoveTrappedSandvich(trappedSandvich[client]);
	
	if (!(GetClientButtons(client) & IN_RELOAD)) return;
	
	int slotS = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (!RealValidEntity(slotS)) return;
	//PrintToChatAll("%i", GetEntProp(slotS, Prop_Send, "m_bBroken"));
	
	int wep_index = -1;
	if (RealValidEntity(slotS) && HasEntProp(slotS, Prop_Send, "m_iItemDefinitionIndex"))
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
	
	if (!RealValidEntity(new_ent))
	{
		PrintToServer("[SM] [Trapped Sandvich] Something went wrong whilst trying to spawn a trapped sandvich!");
		return;
	}
	
	AcceptEntityInput(entity, "Kill");
}

Action PreventPickup_Timer(Handle timer, int ent_ref)
{
	int entity = EntRefToEntIndex(ent_ref);
	
	if (!RealValidEntity(entity)) return Plugin_Continue;
	
	SetEntProp(entity, Prop_Send, "m_iTeamNum", 0);
	return Plugin_Continue;
}

/*Action OnFakeSandvichPickup(int entity, int client)
{
	PrintToChatAll("Prevent!!");
	if (IsPlayerAliveNotGhost(client))
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
	if (!RealValidEntity(entity)) return;
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
	if (!g_bEnable) return;
	
	if (!IsPlayerAliveNotGhost(client)) return;
	PrintToChatAll("%i", !(buttons & IN_RELOAD));
	if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return;
	if (oldHealth[client] <= 0)
	{ oldHealth[client] = GetClientHealth(client); }
	
	if (!(buttons & IN_RELOAD)) return;
	
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!RealValidEntity(active_wep)) return;
	
	//TFClassType class = TF2_GetPlayerClass(client);
	//if (class != TFClass_Heavy) return;
	
	int wep_index = -1;
	if (RealValidEntity(active_wep) && HasEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"); }
	PrintToChatAll("%i", wep_index);
	// 42 = Sandvich.
	if (wep_index != 42) return;
	
	TF2_RemoveCondition(client, TFCond_Taunting);
	SpawnTrappedSandvich(client);
}*/

/*public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float[3] vel, float[3] angles, int& weapon)
{
	if (!g_bEnable) return;
	
	if (!IsPlayerAliveNotGhost(client)) return;
	PrintToChatAll("%i", !(buttons & IN_RELOAD));
	
	if (oldHealth[client] <= 0)
	{ oldHealth[client] = GetClientHealth(client); }
	
	if (!(buttons & IN_RELOAD) || !(buttons & IN_ATTACK2)) return;
	
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!RealValidEntity(active_wep)) return;
	
	//TFClassType class = TF2_GetPlayerClass(client);
	//if (class != TFClass_Heavy) return;
	
	int wep_index = -1;
	if (RealValidEntity(active_wep) && HasEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"); }
	PrintToChatAll("%i", wep_index);
	// 42 = Sandvich.
	if (wep_index != 42) return;
	
	SpawnTrappedSandvich(client);
}*/

/*public void OnMapStart()
{
	
}*/

int SpawnTrappedSandvich(int entity, const float velocity[3])
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (!IsValidClient(client) || !IsPlayerAliveNotGhost(client)) return -1;
	
	int pack = CreateEntityByName(CLASS_TRAP);
	DispatchKeyValue(pack, "AutoMaterialize", "0");
	DispatchKeyValue(pack, "velocity", "0.0 0.0 1.0");
	DispatchKeyValue(pack, "basevelocity", "0.0 0.0 1.0");
	
	static char temp_str[32];
	Format(temp_str, sizeof(temp_str), "%s_%i", TARGETNAME_TRAP, EntRefToEntIndex(pack));
	DispatchKeyValue(pack, "targetname", temp_str);
	
	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
	
	DispatchKeyValueVector(pack, "origin", origin);
	TeleportEntity(pack, NULL_VECTOR, NULL_VECTOR, velocity);
	
	SetEntProp(pack, Prop_Data, "m_bActivateWhenAtRest", 1);
	SetEntProp(pack, Prop_Send, "m_ubInterpolationFrame", 0);
	trappedSandvich[client] = pack;
	SetEntPropEnt(pack, Prop_Send, "m_hOwnerEntity", client);
	SetEntityGravity(pack, 1.0);
	
	DispatchKeyValue(pack, "powerup_model", SANDVICH_MDL);
	
	//HookTouch(entity);
	//CreateTimer(1.0, PreventPickup_End, entity, TIMER_FLAG_NO_MAPCHANGE);
	
	SetEntProp(pack, Prop_Send, "m_iTeamNum", 1); // This helps keep both teams from picking it up prematurely, including the thrower
	CreateTimer(0.5, PreventPickup_Timer, EntIndexToEntRef(pack), TIMER_FLAG_NO_MAPCHANGE);
	
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
	if (!RealValidEntity(sandvich)) return;
	
	static char classname[21];
	GetEntityClassname(sandvich, classname, sizeof(classname));
	if (strcmp(classname, CLASS_TRAP, false) == 0)
	{
		AcceptEntityInput(sandvich, "Kill");
	}
}

void Output_OnPlayerTouch(const char[] output, int caller, int activator, float delay)
{
	if (!IsValidClient(activator) || !IsPlayerAliveNotGhost(activator) || !RealValidEntity(caller)) return;
	
	/*float damage = g_iDamage;
	if (damage <= 0.0) return;
	
	TFClassType class = TF2_GetPlayerClass(activator);
	if (class == TFClass_Scout)
	{ damage += 35.0; } // 100.0
	else if (class == TFClass_Heavy)
	{ damage += 105.0; } // 170.0*/
	int damage_int = g_iDamage;
	float damage = damage_int+0.0;
	
	int thrower = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	int thrower_team = -1;
	int slotS = -1;
	int caller_initialteam = GetEntProp(caller, Prop_Data, "m_iInitialTeamNum"); // Time to check if thrower's team still matches caller's team
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
		if (damage > 0.0)
			SDKHooks_TakeDamage(activator, caller, thrower, damage, DMG_CLUB|DMG_PREVENT_PHYSICS_FORCE, slotS);
	}
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

bool IsPlayerAliveNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }