#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <loghelper>

#define VERSION 		"0.2.0"
#define DEFAULTFLAG		0

#define SOUND_GRAB	"misc/rubberglove_stretch.wav"
#define SOUND_CUT	"misc/rubberglove_snap.wav"

new Handle:g_hCvarEnable = INVALID_HANDLE;
new bool:g_bEnabled;

new Handle:g_hCvarMinCharge = INVALID_HANDLE;
new g_iMinCharge;

new bool:g_bGrab[MAXPLAYERS+1] = {false, ...};
new bool:g_bLong[MAXPLAYERS+1] = {false, ...};
new bool:g_bAccessAllowed[MAXPLAYERS+1] = {true, ...};


public Plugin:myinfo = {
	name = "tMedicRubber",
	author = "Thrawn",
	description = "Medics can jump with their patients.",
	version = VERSION,
};


public OnPluginStart() {
	CreateConVar("sm_tmedicrubber_version", VERSION, "[TF2] tMedicRubber", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnable = CreateConVar("sm_tmedicrubber_enabled", "1", "Enables the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarMinCharge = CreateConVar("sm_tmedicrubber_mincharge", "25", "Required charge amount", FCVAR_PLUGIN, true, 0.0, true, 100.0);

	HookConVarChange(g_hCvarEnable, Cvar_Changed);
	HookConVarChange(g_hCvarMinCharge, Cvar_Changed);

	/* Account for late loading */
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			g_bAccessAllowed[i] = CheckCommandAccess(i, "sm_tmedicrubber", DEFAULTFLAG);
			SDKHook(i, SDKHook_PreThink, OnPreThink);
		}
	}

	AutoExecConfig(true, "plugin.tMedicRubber");
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);
	g_iMinCharge = GetConVarInt(g_hCvarMinCharge);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnMapStart() {
	GetTeams();
	PrecacheSound(SOUND_GRAB, true );
	PrecacheSound(SOUND_CUT, true );
}

public OnClientPostAdminCheck(client) {
	g_bAccessAllowed[client] = CheckCommandAccess(client, "sm_tmedicrubber", DEFAULTFLAG);
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public OnPreThink(client) {
	if(!g_bEnabled)
		return;

	if(!g_bAccessAllowed[client]) {
		return;
	}

	if(TF2_GetPlayerClass(client) != TFClass_Medic)
		return;

	if(!(GetEntityFlags(client) & FL_ONGROUND)) {
		new iPatient = TF2_GetHealingTarget(client);

		if(iPatient != -1 && IsClientInGame(iPatient) && !(GetEntityFlags(iPatient) & FL_ONGROUND)) {	//We need a airborne patient
			if (GetClientButtons(client) & IN_JUMP) {		//Our jump key needs to be pressed
				if(g_bGrab[client]) {
					new Float:targetPos[3];
					new Float:clientPos[3];
					GetClientAbsOrigin(iPatient, targetPos);
					GetClientAbsOrigin(client, clientPos);

					new Float:diffPos[3];
					targetPos[2] += 120.0;							//add to Z, we dont want to get pulled in the ground
					SubtractVectors(targetPos, clientPos, diffPos);	//get the directional vector to the target
					ScaleVector(diffPos, 0.05);						//scale it to 5%

					new Float:clientVelocity[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", clientVelocity);
					AddVectors(clientVelocity, diffPos, clientVelocity);		//add it to the current velocity
					SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", clientVelocity);

					if( GetVectorDistance( clientPos, targetPos, false ) / 50.00 > 4.5 ) {
						if(!g_bLong[client]) {
							g_bLong[client] = true;
							StopSound(TF2_GetCurrentWeapon(client), 0, SOUND_GRAB);
							EmitSoundToAll(SOUND_GRAB, TF2_GetCurrentWeapon(client), _, _, _, 0.8);
						}
					} else {
						g_bLong[client] = false;
					}
				} else {
					if(TF2_GetPlayerUberLevel(client) > g_iMinCharge) {		//To start a grab, we need more than x charge
						g_bGrab[client] = true;
						StopSound(TF2_GetCurrentWeapon(client), 0, SOUND_GRAB);
						EmitSoundToAll(SOUND_GRAB, TF2_GetCurrentWeapon(client), _, _, _, 0.8);
						LogPlayerEvent(client, "triggered", "medic_rubberjump");
					}
				}
			} else	{
				g_bGrab[client]		= false;
				g_bLong[client]		= false;
			}
		} else {
			if( g_bGrab[client] ) {
				g_bGrab[client]		= false;
				g_bLong[client]		= false;
				StopSound(TF2_GetCurrentWeapon(client), 0, SOUND_GRAB);
				EmitSoundToAll(SOUND_CUT, TF2_GetCurrentWeapon(client), _, _, SND_CHANGEPITCH, 1.00, 100);
			}
		}
	}
}

stock TF2_GetHealingTarget(client) {
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if(StrEqual(classname, "CWeaponMedigun"))	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(GetEntProp(index, Prop_Send, "m_bHealing") == 1) {
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength) {
	if(client > 0) {
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_GetCurrentWeapon(client) {
	if(client > 0) {
		new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		return weaponIndex;
	}

	return -1;
}

stock TF2_GetWeaponClass(index, String:name[], maxlength) {
	if (index > 0)
		GetEntityNetClass(index, name, maxlength);
}

stock TF2_GetPlayerUberLevel(client) {
	new index = GetPlayerWeaponSlot(client, 1);

	if (index > 0) {
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));

		if(StrEqual(classname, "CWeaponMedigun")) {
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
		}
	}

	return 0;
}