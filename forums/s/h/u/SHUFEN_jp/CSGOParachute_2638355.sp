#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define Survival_ParachuteEquipped	"survival/parachute_pickup_success_01.wav"
#define Survival_ItemPickup			"~survival/money_collect_04.wav"

#define ENABLE_BUTTON_JUMP		(1<<0)		/**< Jump Key */
#define ENABLE_BUTTON_LAW		(1<<1)		/**< LookAtWeapon Key */
#define ENABLE_BUTTON_USE		(1<<2)		/**< Use Key */

int g_iToolsParachute;
Handle g_hEquipParachute;
Handle g_hRemoveParachute;

int g_iParachuteEnabled;
int g_iButtonsEnabled;

int g_iClientParachuteEntity[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

bool g_bClientPressingJump[MAXPLAYERS+1] = {false, ...};
bool g_bClientPressingLookAtWeapon[MAXPLAYERS+1] = {false, ...};
bool g_bClientPressingUse[MAXPLAYERS+1] = {false, ...};

public Plugin myinfo = {
	name = "[CS:GO] Parachute Manager",
	author = "SHUFEN from POSSESSION.tokyo",
	description = "Allows player to use CS:GO internal parachute",
	version = "2.0",
	url = "https://possession.tokyo"
};

//----------------------------------------------------------------------------------------------------
// Purpose: General
//----------------------------------------------------------------------------------------------------
public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("CSGOParachute.games");
	if (hGameConf == INVALID_HANDLE) {
		SetFailState("Couldn't load Parachute.games game config!");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "EquipParachute")) {
		delete hGameConf;
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, \"EquipParachute\" failed!");
		return;
	}
	g_hEquipParachute = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RemoveParachute")) {
		delete hGameConf;
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, \"RemoveParachute\" failed!");
		return;
	}
	g_hRemoveParachute = EndPrepSDKCall();

	delete hGameConf;

	HookEvent("player_spawn", Event_PlayerSpawnPost, EventHookMode_Post);

	ConVar cvar;
	(cvar = CreateConVar("sm_parachute_enabled", "2", "Enable/Disable this plugin [-1: Enabled Anytime, 0: Disabled, 1: Allows Command, 2: Allows Specific Buttons]", _, true, -1.0, true, 2.0)).AddChangeHook(OnConVarChanged_Enable);
	g_iParachuteEnabled = cvar.IntValue;
	(cvar = CreateConVar("sm_parachute_buttons", "1", "Enable/Disable buttons [Flags> 0: None, 1: Jump, 2: LookAtWeapon, 4: Use | e.g. 5 = Jump + Use, 7 = All]", _, true, 0.0, true, 7.0)).AddChangeHook(OnConVarChanged_Buttons);
	g_iButtonsEnabled = cvar.IntValue;
	delete cvar;

	RegConsoleCmd("sm_chute", Command_Parachute, "Equip Parachute");
	RegConsoleCmd("sm_parachute", Command_Parachute, "Equip Parachute");

	AddCommandListener(Command_LookAtWeaponPress, "+lookatweapon");
	AddCommandListener(Command_LookAtWeaponRelease, "-lookatweapon");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientConnected(i);
}

public void OnConfigsExecuted() {
	g_iToolsParachute = FindSendPropInfo("CCSPlayer", "m_bHasParachute");

	if (g_iParachuteEnabled == -1) {
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i))
					EquipParachute(i, true);
	}
}

public void OnConVarChanged_Enable(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_iParachuteEnabled = convar.IntValue;
	if (g_iParachuteEnabled == -1) {
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i))
				EquipParachute(i, true);
	}
}

public void OnConVarChanged_Buttons(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_iButtonsEnabled = convar.IntValue;
}

public void OnMapStart() {
	PrecacheModel("models/props_survival/upgrades/parachutepack.mdl");
	PrecacheModel("models/weapons/v_parachute.mdl");
	PrecacheModel("models/props_survival/parachute/chute.mdl");

	// When Start Press E
	PrecacheSound("survival/parachute_pickup_start_01.wav", true);		// ENT: Parachute, CHA:6, VOL: 1.0, LVL: 75, PIT: 100, FLAG: 0

	// When Equipped
	PrecacheSound(Survival_ParachuteEquipped, true);					// ENT: Parachute, CHA: 6, VOL: 1.0, LVL: 75, PIT: 100, FLAG: 0
	PrecacheSound(Survival_ItemPickup, true);							// ENT: Parachute, CHA: 6, VOL: 1.0, LVL: 70, PIT: 100, FLAG: 1024

	// When Deployed
	PrecacheSound("survival/dropzone_parachute_deploy.wav", true);		// ENT: Client, CHA: 6, VOL: 0.5, LVL: 80, PIT: 100, FLAG: 0
	PrecacheSound("survival/dropzone_parachute_success_02.wav", true);	// ENT: Client, CHA: 6, VOL: 0.5, LVL: 80, PIT: 100, FLAG: 0 --> VOL: 0.0, LVL: 0, PIT: 100, FLAG: 4 (Stop Sound)
}

//----------------------------------------------------------------------------------------------------
// Purpose: Clients
//----------------------------------------------------------------------------------------------------
public void OnClientConnected(int client) {
	g_iClientParachuteEntity[client] = INVALID_ENT_REFERENCE;
	g_bClientPressingJump[client] = false;
	g_bClientPressingLookAtWeapon[client] = false;
	g_bClientPressingUse[client] = false;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Entities
//----------------------------------------------------------------------------------------------------
public void OnEntityCreated(int entity, const char[] classname) {
	if (g_iParachuteEnabled != -1)
		return;

	if (StrEqual(classname, "dynamic_prop", false) || StrEqual(classname, "predicted_viewmodel", false))
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawn);
}

public void OnEntitySpawn(int entity) {
	RequestFrame(Frame_EntitySpawn_Post, entity);
}

void Frame_EntitySpawn_Post(int entity) {
	if (IsValidEntity(entity)) {
		char sModelPath[PLATFORM_MAX_PATH];//, sClassName[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
		if (StrContains(sModelPath, "chute.mdl", false) > -1) {
			//GetEntityClassname(entity, sClassName, sizeof(sClassName));
			//SetEntityTargetName(entity, "parachute_%s%i", StrEqual(sClassName, "prop_dynamic", false) ? "prop_" : "viewmodel_", entity);
			int iOwner = GetEntPropEnt(entity, Prop_Data, "m_pParent");
			if (iOwner > 0 && iOwner <= MaxClients) {
				g_iClientParachuteEntity[iOwner] = entity;
			}
		}
	}
}

public void OnEntityDestroyed(int entity) {
	if (g_iParachuteEnabled != -1)
		return;

	for (int i = 1; i < MaxClients; i++) {
		if (entity == g_iClientParachuteEntity[i])
			RequestFrame(Frame_CheckParachute, i);
	}
}

void Frame_CheckParachute(int client) {
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		EquipParachute(client);
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Events
//----------------------------------------------------------------------------------------------------
public void Event_PlayerSpawnPost(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_iParachuteEnabled == -1)
		EquipParachute(client, true);
}

//----------------------------------------------------------------------------------------------------
// Purpose: Commands
//----------------------------------------------------------------------------------------------------
public Action OnPlayerRunCmd(int client, int &buttons) {
	if (g_iParachuteEnabled == 2) {
		if (g_iButtonsEnabled & ENABLE_BUTTON_JUMP && buttons & IN_JUMP) {
			if (!g_bClientPressingJump[client] && !IsClientOnObject(client)) {
				g_bClientPressingJump[client] = true;
				EquipParachute(client);
			}
		} else if (g_bClientPressingJump[client]) {
			g_bClientPressingJump[client] = false;
			RemoveParachute(client);
		}

		if (g_iButtonsEnabled & ENABLE_BUTTON_USE && buttons & IN_USE) {
			if (!g_bClientPressingUse[client] && !IsClientOnObject(client)) {
				g_bClientPressingUse[client] = true;
				EquipParachute(client);
			}
		} else if (g_bClientPressingUse[client]) {
			g_bClientPressingUse[client] = false;
			RemoveParachute(client);
		}
	}
}

public Action Command_LookAtWeaponPress(int client, const char[] command, int argc) {
	if(g_iParachuteEnabled != 2 || !(g_iButtonsEnabled & ENABLE_BUTTON_LAW) || !IsClientInGame(client))
		return Plugin_Continue;

	if (!g_bClientPressingLookAtWeapon[client] && !IsClientOnObject(client)) {
		g_bClientPressingLookAtWeapon[client] = true;
		EquipParachute(client);
	}
	return Plugin_Continue;
}

public Action Command_LookAtWeaponRelease(int client, const char[] command, int argc) {
	if(g_iParachuteEnabled != 2 || !IsClientInGame(client))
		return Plugin_Continue;

	if (g_bClientPressingLookAtWeapon[client]) {
		g_bClientPressingLookAtWeapon[client] = false;
		RemoveParachute(client);
	}
	return Plugin_Continue;
}

public Action Command_Parachute(int client, int args) {
	if (g_iParachuteEnabled != 1 || client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	EquipParachute(client, true);
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose: SDKCalls
//----------------------------------------------------------------------------------------------------
void EquipParachute(int client, bool sounds = false) {
	if (GetEntData(client, g_iToolsParachute) < 1) {
		SDKCall(g_hEquipParachute, client);
		if (sounds) {
			EmitSoundToAll(Survival_ParachuteEquipped, client, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			EmitSoundToAll(Survival_ItemPickup, client, SNDCHAN_STATIC, SNDLEVEL_CAR, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
		}
		Event event = CreateEvent("parachute_pickup");
		if (event != null) {
			event.SetInt("userid", GetClientUserId(client));
			event.Fire();
		}
	}
}

void RemoveParachute(int client) {
	SDKCall(g_hRemoveParachute, client);
}

//----------------------------------------------------------------------------------------------------
// Purpose: Stocks
//----------------------------------------------------------------------------------------------------
stock void SetEntityTargetName(int entity, const char[] name, any ...) {
	char sFormat[64];
	VFormat(sFormat, sizeof(sFormat), name, 3);

	DispatchKeyValue(entity, "target", sFormat);
}

stock void GetEntityTargetName(int entity, char[] buffer, int maxlength) {
	GetEntPropString(entity, Prop_Data, "m_target", buffer, maxlength);
}

stock bool IsClientOnObject(int client) {
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1 ? true : false;
}