#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#tryinclude <tf2powdrop>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

#define DEBUG 0

// From https://github.com/Scags/TF2-Powerup-API
enum eRuneTypes
{
	Rune_Invalid = -1,
	Rune_Strength,
	Rune_Haste,
	Rune_Regen,
	Rune_Resist,
	Rune_Vampire,
	Rune_Reflect,
	Rune_Precision,
	Rune_Agility,
	Rune_Knockout,
	Rune_King,
	Rune_Plague,
	Rune_Supernova,

	// ADD NEW RUNE TYPE HERE, DO NOT RE-ORDER

	Rune_LENGTH
}

#define RuneTypes eRuneTypes
#define RuneTypes_t eRuneTypes 	// Cuz

ConVar gcv_bEnable;
ConVar gcv_bEnableStrength;
ConVar gcv_bEnableHaste;
ConVar gcv_bEnableRegen;
ConVar gcv_bEnableResist;
ConVar gcv_bEnableVampire;
ConVar gcv_bEnableReflect;
ConVar gcv_bEnablePrecision;
ConVar gcv_bEnableAgility;
ConVar gcv_bEnableKnockout;
ConVar gcv_bEnableKing;
ConVar gcv_bEnablePlague;
ConVar gcv_bEnableSupernova;
ConVar gcv_flDropTime;
bool g_bShouldDrop;
float g_flDropTime;
ArrayList ga_iExclude = null;
GlobalForward g_fwOnPowerupDrop;

public Plugin myinfo =
{
	name = "[TF2] Powerup Drops",
	author = "mintoyatsu",
	description = "Killed players drop Mannpower Runes.",
	version = PLUGIN_VERSION,
	url = "https://mintosoft.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("tf2powdrop");
	return APLRes_Success;
}

public void OnPluginStart() {
	CreateConVar("sm_powdrop_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	gcv_bEnable = CreateConVar("sm_powdrop_enabled", "1", "Enable powerup drops when a player is fragged.");
	gcv_bEnable.AddChangeHook(OnConVarChange);
	g_bShouldDrop = gcv_bEnable.BoolValue;

	gcv_flDropTime = CreateConVar("sm_powdrop_drop_time", "15.0", "How long (in seconds) all dropped powerups remain in the world.\nAny powerups created by info_powerup_spawn will be removed after this time.", _, true, 0.1, true, 60.0);
	gcv_flDropTime.AddChangeHook(OnConVarChange);
	g_flDropTime = gcv_flDropTime.FloatValue;

	gcv_bEnableStrength = CreateConVar("sm_powdrop_strength_enabled", "1", "Allow STRENGTH powerups to drop.");
	gcv_bEnableStrength.AddChangeHook(OnConVarChange2);
	gcv_bEnableHaste = CreateConVar("sm_powdrop_haste_enabled", "1", "Allow HASTE powerups to drop.");
	gcv_bEnableHaste.AddChangeHook(OnConVarChange2);
	gcv_bEnableRegen = CreateConVar("sm_powdrop_regen_enabled", "0", "Allow REGENERATION powerups to drop.\nRequires tf_powerup_mode 1 for it to function properly.");
	gcv_bEnableRegen.AddChangeHook(OnConVarChange2);
	gcv_bEnableResist = CreateConVar("sm_powdrop_resist_enabled", "1", "Allow RESISTANCE powerups to drop.");
	gcv_bEnableResist.AddChangeHook(OnConVarChange2);
	gcv_bEnableVampire = CreateConVar("sm_powdrop_vampire_enabled", "1", "Allow VAMPIRE powerups to drop.");
	gcv_bEnableVampire.AddChangeHook(OnConVarChange2);
	gcv_bEnableReflect = CreateConVar("sm_powdrop_reflect_enabled", "1", "Allow REFLECT powerups to drop.");
	gcv_bEnableReflect.AddChangeHook(OnConVarChange2);
	gcv_bEnablePrecision = CreateConVar("sm_powdrop_precision_enabled", "1", "Allow PRECISION powerups to drop.");
	gcv_bEnablePrecision.AddChangeHook(OnConVarChange2);
	gcv_bEnableAgility = CreateConVar("sm_powdrop_agility_enabled", "1", "Allow AGILITY powerups to drop.");
	gcv_bEnableAgility.AddChangeHook(OnConVarChange2);
	gcv_bEnableKnockout = CreateConVar("sm_powdrop_knockout_enabled", "1", "Allow KNOCKOUT powerups to drop.");
	gcv_bEnableKnockout.AddChangeHook(OnConVarChange2);
	gcv_bEnableKing = CreateConVar("sm_powdrop_king_enabled", "0", "Allow KING powerups to drop.\nRequires tf_powerup_mode 1 for it to function properly.");
	gcv_bEnableKing.AddChangeHook(OnConVarChange2);
	gcv_bEnablePlague = CreateConVar("sm_powdrop_plague_enabled", "0", "Allow PLAGUE powerups to drop.\nThe current map should have healthkits for it to function properly.\nIt will consume nearby healthkits spawned by other plugins, so enable at your own risk.");
	gcv_bEnablePlague.AddChangeHook(OnConVarChange2);
	gcv_bEnableSupernova = CreateConVar("sm_powdrop_supernova_enabled", "0", "Allow SUPERNOVA powerups to drop.\nRequires tf_grapplinghook_enable 1 in order to use it.");
	gcv_bEnableSupernova.AddChangeHook(OnConVarChange2);

#if DEBUG
	RegAdminCmd("sm_spawnrune", CmdSpawnRune, ADMFLAG_ROOT);
#endif

	HookEvent("player_death", Event_PlayerDeath);

	ga_iExclude = new ArrayList();
	g_fwOnPowerupDrop = new GlobalForward("PowDrop_OnPowerupDrop", ET_Event, Param_Cell, Param_Cell);

	AutoExecConfig(true, "tf2powdrop");
}

public void OnConfigsExecuted() {
	ExcludePowerups();
}

public Action CmdSpawnRune(int client, int args)
{
	char arg[32]; GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client, arg);
	float pos[3]; GetClientAbsOrigin(target, pos);
	char arg2[32]; GetCmdArg(2, arg2, sizeof(arg2));

	int rune = MakeRune(view_as< RuneTypes >(StringToInt(arg2)), pos, NULL_VECTOR, NULL_VECTOR);
	ReplyToCommand(client, "Admin rune spawned: id %d | type %d", rune, TF2_GetRuneType(rune));
	return Plugin_Handled;
}

public void OnConVarChange(ConVar cvConVar, char[] sOldValue, char[] sNewValue) {
	if (cvConVar == gcv_bEnable) {
		if (!gcv_bEnable.BoolValue) {
			UnhookEvent("player_death", Event_PlayerDeath);
			g_bShouldDrop = false;
		}
		else {
			HookEvent("player_death", Event_PlayerDeath);
			g_bShouldDrop = true;
		}
	}
	if (cvConVar == gcv_flDropTime)
		g_flDropTime = gcv_flDropTime.FloatValue;
}

public void OnConVarChange2(ConVar cvConVar, char[] sOldValue, char[] sNewValue) {
	ExcludePowerups();
}

public void OnMapStart() {
	PrecacheModel("models/pickups/pickup_powerup_agility.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_haste.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_king.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_knockout.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_plague.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_precision.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_reflect.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_regen.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_resistance.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_strength.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_supernova.mdl", true);
	PrecacheModel("models/pickups/pickup_powerup_vampire.mdl", true);
}

/**
 *	Events
**/

public Action Event_PlayerDeath(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bShouldDrop)
		return;

	// Don't create a powerup for Dead Ringer Spies
	// Dead Ringer Spies automatically drop a neutral powerup if they have one
	int iFlags = GetEventInt(hEvent, "death_flags");
	if (iFlags & TF_DEATHFLAG_DEADRINGER)
		return;

	// Don't create a powerup for suicides
	// Suicidal players automatically drop a neutral powerup if they have one
	int iUserIdVictim = GetEventInt(hEvent, "userid");
	int iUserIdAttacker = GetEventInt(hEvent, "attacker");
	if (!iUserIdAttacker || (iUserIdVictim == iUserIdAttacker))
		return;

	int iClientVictim = GetClientOfUserId(iUserIdVictim);
	int iClientAttacker = GetClientOfUserId(iUserIdAttacker);
	if (!IsValidClient(iClientVictim) || !IsValidClient(iClientAttacker))
		return;

	// Only create a new powerup if neither the victim or attacker have one
	// Killed players automatically drop a team powerup if they have one
	if (TF2_GetCarryingRuneType(iClientVictim) == Rune_Invalid && TF2_GetCarryingRuneType(iClientAttacker) == Rune_Invalid) {
		Action result;
		Call_StartForward(g_fwOnPowerupDrop);
		Call_PushCell(iClientVictim);
		Call_PushCell(iClientAttacker);
		Call_Finish(result);
		if(result == Plugin_Handled || result == Plugin_Stop)
			return;

		float a_flOrigin[3];
		GetClientAbsOrigin(iClientVictim, a_flOrigin);

		float a_flVelocity[3];
		GetEntPropVector(iClientVictim, Prop_Data, "m_vecVelocity", a_flVelocity);

		// Pick a random powerup
		RuneTypes iRuneType = view_as<RuneTypes>(GetRandomIntEx(0, view_as< int >(Rune_LENGTH) - 1, ga_iExclude));
#if DEBUG
		PrintToServer("Generating rune: type %d", view_as< int >(iRuneType));
#endif
		MakeRune(iRuneType, a_flOrigin, NULL_VECTOR, a_flVelocity);
	}
}

public void OnEntityCreated(int ent, const char[] classname) 
{
	if (!strncmp(classname, "item_power", 10, false))
	{
#if DEBUG
		PrintToServer("New rune spawned: id %d", ent);
#endif
		CreateTimer(g_flDropTime, Timer_RemoveDroppedPow, ent, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 *	Timers
**/

public Action Timer_RemoveDroppedPow(Handle hTimer, int iEntity) {
	if(IsValidEntity(iEntity)) {
		char sClassname[35];
		GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
#if DEBUG
		PrintToServer("Found edict: id %d | classname %s", iEntity, sClassname);
#endif
		if (!strncmp(sClassname, "item_power", 10, false)) {
#if DEBUG
			PrintToServer("Removing edict: id %d | classname %s", iEntity, sClassname);
#endif
			RemoveEdict(iEntity);
		}
	}
}

/**
 *	Functions
**/

void ExcludePowerups() {
	ga_iExclude.Clear();
#if DEBUG
		PrintToServer("Cleared rune blacklist");
#endif
	if (!gcv_bEnableStrength.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Strength));
	if (!gcv_bEnableHaste.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Haste));
	if (!gcv_bEnableRegen.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Regen));
	if (!gcv_bEnableResist.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Resist));
	if (!gcv_bEnableVampire.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Vampire));
	if (!gcv_bEnableReflect.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Reflect));
	if (!gcv_bEnablePrecision.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Precision));
	if (!gcv_bEnableAgility.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Agility));
	if (!gcv_bEnableKnockout.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Knockout));
	if (!gcv_bEnableKing.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_King));
	if (!gcv_bEnablePlague.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Plague));
	if (!gcv_bEnableSupernova.BoolValue)
		ga_iExclude.Push(view_as< int >(Rune_Supernova));
}

/**
 *	Stocks
**/

// From https://github.com/Drixevel/sm-multitool/blob/main/scripting/include/misc-sm.inc
stock bool IsValidClient(int client) {
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client) && !GetEntProp(client, Prop_Send, "m_bIsCoaching");
}

// From https://forums.alliedmods.net/showpost.php?p=2427773&postcount=13
stock int GetRandomIntEx(int min, int max, ArrayList exclude) {
	ArrayList array = new ArrayList();
	
	for (int i = min; i <= max; i++)
	{
		if(exclude.FindValue(i) != -1)
			continue;
		array.Push(i);
	}
	
	int rand = array.Get(GetRandomInt(0, array.Length - 1));
	delete array;
	
	return rand;
}

// From https://github.com/Scags/TF2-Powerup-API
stock static TFCond g_RuneConds[view_as< int >(Rune_LENGTH)] = {	// Dammit dvander
	TFCond_RuneStrength,
	TFCond_RuneHaste,
	TFCond_RuneRegen,
	TFCond_RuneResist,
	TFCond_RuneVampire,
	TFCond_RuneWarlock,
	TFCond_RunePrecision,
	TFCond_RuneAgility,
	TFCond_RuneKnockout,
	TFCond_KingRune,
	TFCond_PlagueRune,
	TFCond_SupernovaRune

	// ADD NEW RUNE TYPE HERE, DO NOT RE-ORDER
};

// From https://github.com/Scags/TF2-Powerup-API
stock int MakeRune(RuneTypes type, float pos[3], float ang[3] = NULL_VECTOR, float vel[3] = NULL_VECTOR) {
	int ent = CreateEntityByName("item_powerup_rune");
	TeleportEntity(ent, pos, ang, vel);
	DispatchSpawn(ent);
	SetRuneType(ent, type);
	return ent;
}

stock void SetRuneType(int rune, RuneTypes type) {
	SetEntData(rune, FindDataMapInfo(rune, "m_iszModel") + 24, view_as< int >(type));
	switch (type) {
		case Rune_Strength:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_strength.mdl");
		}
		case Rune_Haste:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_haste.mdl");
		}
		case Rune_Regen:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_regen.mdl");
		}
		case Rune_Resist:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_resistance.mdl");
		}
		case Rune_Vampire:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_vampire.mdl");
		}
		case Rune_Reflect:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_reflect.mdl");
		}
		case Rune_Precision:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_precision.mdl");
		}
		case Rune_Agility:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_agility.mdl");
		}
		case Rune_Knockout:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_knockout.mdl");
		}
		case Rune_King:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_king.mdl");
		}
		case Rune_Plague:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_plague.mdl");
		}
		case Rune_Supernova:
		{
			SetEntityModel(rune, "models/pickups/pickup_powerup_supernova.mdl");
		}
	}
}

/**
 *	Get the carried rune type of a player
 *
 *	@param client 		Client index
 *
 *	@return 			RuneTypes type of carried rune, Rune_Invalid on failure
 *	@error 				Invalid client or client not in-game
**/
// This is literally CTFPlayerShared::GetCarryingRuneType
stock RuneTypes TF2_GetCarryingRuneType(int client) {
	if (!(0 < client <= MaxClients))
	{
		ThrowError("Client %d is not valid!", client);
		return Rune_Invalid;
	}

	if (!IsClientInGame(client))
	{
		ThrowError("Client %d is not in-game!", client);
		return Rune_Invalid;
	}
	
	for (int i = 0; i < view_as< int >(Rune_LENGTH); i++) {
		if (TF2_IsPlayerInCondition(client, g_RuneConds[i]))
			return view_as< RuneTypes >(i);
	}
	return Rune_Invalid;
}

/**
 *	Get the type of a rune
 *
 *	@param rune 		Rune entity
 *
 *	@return 			RuneTypes type of this rune
 *	@error 				Invalid rune entity passed, entity passed was not a rune
**/
// 1288 linux
// 1268 windows
stock RuneTypes TF2_GetRuneType(int rune) {
	if (!IsValidEntity(rune))
	{
		ThrowError("Entity %d is invalid!", rune);
		return Rune_Invalid;
	}

	char cls[32]; GetEntityClassname(rune, cls, sizeof(cls));

	if (strncmp(cls, "item_power", 10, false))
	{
		ThrowError("Entity %d (%s) is not a powerup rune!", rune, cls);
		return Rune_Invalid;
	}
	return view_as< RuneTypes >(GetEntData(rune, FindDataMapInfo(rune, "m_iszModel") + 24));
}
