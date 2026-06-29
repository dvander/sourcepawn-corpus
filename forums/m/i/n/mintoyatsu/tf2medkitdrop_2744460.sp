#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#tryinclude <tf2medkitdrop>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

#define DEBUG 0

ConVar gcv_bEnable;
ConVar gcv_iSize;
ConVar gcv_bRandom;
ConVar gcv_bGravity;
ConVar gcv_flTimeout;
ConVar gcv_bSandvich;
ConVar gcv_bBirthday;
ConVar gcv_bHalloween;
ConVar gcv_bUnconditional;
ConVar gcv_bOverheal;
ConVar gcv_tf_max_health_boost;
GlobalForward g_fwOnMedkitDrop;

public Plugin myinfo =
{
	name = "[TF2] Medkit Drops",
	author = "mintoyatsu",
	description = "Killed players drop medkits.",
	version = PLUGIN_VERSION,
	url = "https://mintosoft.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("tf2medkitdrop");
	return APLRes_Success;
}

public void OnPluginStart() {
	gcv_bEnable = CreateConVar("sm_medkitdrop_enabled", "1", "Enable medkit drops on player death.");
	HookConVarChange(gcv_bEnable, OnConVarChange);
	gcv_iSize = CreateConVar("sm_medkitdrop_size", "2", "The size of medkit to drop.\n1 - Small (20.5% health)\n2 - Medium (50% health)\n3 - Large (100% health)", _, true, 1.0, true, 3.0);
	gcv_bRandom = CreateConVar("sm_medkitdrop_random", "1", "Randomize the dropped medkit size.\nOverrides sm_medkitdrop_size.");
	gcv_bGravity = CreateConVar("sm_medkitdrop_physics", "1", "Allow medkits to be affected by gravity, similar to the Candy Cane.\nWhen disabled, medkits will float in the air where the player died.");
	gcv_flTimeout = CreateConVar("sm_medkitdrop_time", "15.0", "How long (in seconds) dropped medkits remain in the world.", 0, true, 0.0, true, 60.0);
	gcv_bSandvich = CreateConVar("sm_medkitdrop_sandvich", "0", "Use the sandvich plate model for medkits.");
	gcv_bBirthday = CreateConVar("sm_medkitdrop_birthday", "0", "Use the birthday cake model for medkits.");
	gcv_bHalloween = CreateConVar("sm_medkitdrop_halloween", "0", "Use the halloween candy model for medkits.");
	gcv_bUnconditional = CreateConVar("sm_medkitdrop_unconditional", "0", "Always drop medkits on death, including suicides and environmental deaths.");
	gcv_bOverheal = CreateConVar("sm_medkitdrop_overheal", "0", "Large medkits overheal the player when picked up.");
	gcv_tf_max_health_boost = FindConVar("tf_max_health_boost");

	HookEvent("player_death", Event_PlayerDeath);

	g_fwOnMedkitDrop = new GlobalForward("MedkitDrop_OnMedkitDrop", ET_Event, Param_Cell);

	AutoExecConfig(true, "tf2medkitdrop");
}

public void OnConVarChange(Handle hCvar, char[] oldValue, char[] newValue) {
	if(hCvar == gcv_bEnable) {
		if(!gcv_bEnable.BoolValue) {
			UnhookEvent("player_death", Event_PlayerDeath);
		}
		else {
			HookEvent("player_death", Event_PlayerDeath);
		}
	}
}

public void OnMapStart() {
	PrecacheModel("models/items/medkit_large.mdl", true);
	PrecacheModel("models/items/medkit_medium.mdl", true);
	PrecacheModel("models/items/medkit_small.mdl", true);
	PrecacheModel("models/items/plate.mdl", true);
	PrecacheModel("models/items/medkit_small_bday.mdl", true);
	PrecacheModel("models/items/medkit_medium_bday.mdl", true);
	PrecacheModel("models/items/medkit_large_bday.mdl", true);
	PrecacheModel("models/props_halloween/halloween_medkit_small.mdl", true);
	PrecacheModel("models/props_halloween/halloween_medkit_medium.mdl", true);
	PrecacheModel("models/props_halloween/halloween_medkit_large.mdl", true);
}

/**
 *	Events
**/

public Action Event_PlayerDeath(Handle hEvent, char[] sName, bool dontBroadcast) {
	int iFlags = GetEventInt(hEvent, "death_flags");
	int iUserIdVictim = GetEventInt(hEvent, "userid");
	int iUserIdAttacker = GetEventInt(hEvent, "attacker");
	int iClientVictim = GetClientOfUserId(iUserIdVictim);
	int iClientAttacker = GetClientOfUserId(iUserIdAttacker);
	
	// Don't create a medkit for Dead Ringer Spies
	if (iFlags & TF_DEATHFLAG_DEADRINGER)
		return;

	if (!gcv_bUnconditional.BoolValue) {
		// Don't create a medkit for suicides
		if (!iUserIdAttacker || (iUserIdVictim == iUserIdAttacker))
			return;
		if (!IsValidClient(iClientAttacker))
			return;
	}

	if (!IsValidClient(iClientVictim))
		return;

	Action result;
	Call_StartForward(g_fwOnMedkitDrop);
	Call_PushCell(iClientVictim);
	Call_Finish(result);
	if(result == Plugin_Handled || result == Plugin_Stop)
		return;

	float a_flPos[3];
	GetClientAbsOrigin(iClientVictim, a_flPos);
	a_flPos[2] += 10.0;

	float a_flVelocity[3];
	a_flVelocity[0] = float(GetRandomInt(0, 100)), a_flVelocity[1] = float(GetRandomInt(0, 100)), a_flVelocity[2] = 300.0;

	int iEntityMedkit;
	int iSize = gcv_bRandom.BoolValue ? GetRandomInt(1, 3) : GetConVarInt(gcv_iSize);

	switch (iSize) {
		case 1:
		{
			iEntityMedkit = CreateEntityByName("item_healthkit_small");
		}
		case 2:
		{
			iEntityMedkit = CreateEntityByName("item_healthkit_medium");
		}
		case 3:
		{
			iEntityMedkit = CreateEntityByName("item_healthkit_full");
		}
		default:
		{
			iEntityMedkit = CreateEntityByName("item_healthkit_full");
		}
	}

	if (IsValidEntity(iEntityMedkit)) {
		if(gcv_bSandvich.BoolValue) {
			DispatchKeyValue(iEntityMedkit, "powerup_model", "models/items/plate.mdl");	// Set the correct model
		}
		if(gcv_bBirthday.BoolValue) {
			switch (iSize)
			{
				case 1:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/items/medkit_small_bday.mdl");	// Set the correct model
				}
				case 2:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/items/medkit_medium_bday.mdl");	// Set the correct model
				}
				case 3:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/items/medkit_large_bday.mdl");	// Set the correct model
				}
				default:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/items/medkit_large_bday.mdl");	// Set the correct model
				}
			}
		}
		if(gcv_bHalloween.BoolValue) {
			switch (iSize)
			{
				case 1:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/props_halloween/halloween_medkit_small.mdl");	// Set the correct model
				}
				case 2:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/props_halloween/halloween_medkit_medium.mdl");	// Set the correct model
				}
				case 3:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/props_halloween/halloween_medkit_large.mdl");	// Set the correct model
				}
				default:
				{
					DispatchKeyValue(iEntityMedkit, "powerup_model", "models/props_halloween/halloween_medkit_large.mdl");	// Set the correct model
				}
			}
		}

		DispatchKeyValue(iEntityMedkit, "AutoMaterialize", "0");
		DispatchKeyValue(iEntityMedkit, "velocity", "0.0 0.0 1.0");
		DispatchKeyValue(iEntityMedkit, "basevelocity", "0.0 0.0 1.0");
		TeleportEntity(iEntityMedkit, a_flPos, NULL_VECTOR, a_flVelocity);
		SetEntProp(iEntityMedkit, Prop_Data, "m_bActivateWhenAtRest", 1);
		SetEntProp(iEntityMedkit, Prop_Send, "m_ubInterpolationFrame", 0);
		if (IsValidClient(iClientAttacker))
			SetEntPropEnt(iEntityMedkit, Prop_Send, "m_hOwnerEntity", iClientAttacker);

		DispatchSpawn(iEntityMedkit);
		ActivateEntity(iEntityMedkit);

		DispatchKeyValue(iEntityMedkit, "nextthink", "0.1"); // The fix to the laggy physics.

		SetVariantString("OnPlayerTouch !self:Kill::0:-1");
		AcceptEntityInput(iEntityMedkit, "AddOutput");

		float flTimeout = GetConVarFloat(gcv_flTimeout);
		CreateTimer(flTimeout, Timer_RemoveDroppedMedkit, iEntityMedkit, TIMER_FLAG_NO_MAPCHANGE);

		if(gcv_bOverheal.BoolValue && iSize == 3)
			HookSingleEntityOutput(iEntityMedkit, "OnPlayerTouch", PlayerPickedUp, true);

		if(gcv_bGravity.BoolValue)
			RequestFrame(SpawnPack_FrameCallback, iEntityMedkit); // Have to change movetype in a frame callback
	}
}

public void PlayerPickedUp(char[] output, int caller, int activator, float delay) {
	if (IsValidClient(activator) && IsPlayerAlive(activator)) {
		int iPlayerHealth = GetClientHealth(activator);
		int iPlayerMaxHealth = GetEntData(activator, FindDataMapInfo(activator, "m_iMaxHealth"), 4);
		iPlayerHealth = RoundToZero(iPlayerMaxHealth * GetConVarFloat(gcv_tf_max_health_boost));
		SetEntProp(activator, Prop_Send, "m_iHealth", iPlayerHealth);
	}
}

/**
 *	Timers
**/

public Action Timer_RemoveDroppedMedkit(Handle hTimer, int iEntity) {
	if(IsValidEntity(iEntity)) {
		char sClassname[35];
		GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
#if DEBUG
		LogMessage("Found edict: id %d | classname %s", iEntity, sClassname);
#endif
		if (!strncmp(sClassname, "item_healt", 10, false)) {
#if DEBUG
			LogMessage("Removing edict: id %d | classname %s", iEntity, sClassname);
#endif
			RemoveEdict(iEntity);
		}
	}
}

/**
 *	Functions
**/

// From https://forums.alliedmods.net/showthread.php?t=326148
void SpawnPack_FrameCallback(int pack) {
	if (!IsValidEntity(pack) || pack < 1) return;

	SetEntityMoveType(pack, MOVETYPE_FLYGRAVITY);
	SetEntProp(pack, Prop_Send, "movecollide", 1); // These two...
	SetEntProp(pack, Prop_Data, "m_MoveCollide", 1); // ...allow the pack to bounce.
}

/**
 *	Stocks
**/

// From https://github.com/Drixevel/sm-multitool/blob/main/scripting/include/misc-sm.inc
stock bool IsValidClient(int client) {
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client) && !GetEntProp(client, Prop_Send, "m_bIsCoaching");
}
