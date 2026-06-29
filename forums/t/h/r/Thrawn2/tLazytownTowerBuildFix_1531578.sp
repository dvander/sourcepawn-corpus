#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new String:g_sPushModel[64] = "models/props_2fort/frog.mdl";

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name = "tLazytownTowerBuildFix",
	author = "Thrawn",
	description = "Creates no-build zones on the lazytown towers",
	version = PLUGIN_VERSION,
	url = "http://aaa.wallbash.com"
}

public OnPluginStart() {
	// Create ConVars
	CreateConVar("sm_tlazytowntowerbuildfix_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	HookEvent("teamplay_round_start", Hook_Start, EventHookMode_Post);
}

public OnMapStart() {
	PrecacheModel(g_sPushModel);
}

public Action:Hook_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	new String:sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));

	if(StrEqual(sMapName, "cp_lazytown_efix")) {
		LogMessage("Placing no-build-zones on both towers");

		CreateNoBuildZoneRed();
		CreateNoBuildZoneBlue();
	}
}

stock CreateNoBuildZoneRed() {
	new entindex = CreateEntityByName("func_nobuild");

	DispatchSpawn(entindex);
	ActivateEntity(entindex);

	AcceptEntityInput(entindex, "SetActive");
	SetEntityModel(entindex, g_sPushModel);

	new Float:maxbounds[3] = {180.0,260.0,100.0};
	new Float:minbounds[3] = {-180.00,-200.00,-120.00};
	new Float:position[3] = {-894.82,1340.44,588.03};

	TeleportEntity(entindex, position, NULL_VECTOR, NULL_VECTOR);

	SetEntProp(entindex, Prop_Send, "m_nSolidType", 2);

	SetEntPropVector(entindex, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(entindex, Prop_Send, "m_vecMaxs", maxbounds);

	new enteffects = GetEntProp(entindex, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(entindex, Prop_Send, "m_fEffects", enteffects);

	TeleportEntity(entindex, position, NULL_VECTOR, NULL_VECTOR);
}

stock CreateNoBuildZoneBlue() {
	new entindex = CreateEntityByName("func_nobuild");

	DispatchSpawn(entindex);
	ActivateEntity(entindex);

	AcceptEntityInput(entindex, "SetActive");
	SetEntityModel(entindex, g_sPushModel);

	new Float:maxbounds[3] = {190.00,180.00,100.00};
	new Float:minbounds[3] = {-190.00,-270.00,-160.00};
	new Float:position[3] = {-901.26,2509.27,628.03};

	TeleportEntity(entindex, position, NULL_VECTOR, NULL_VECTOR);

	SetEntProp(entindex, Prop_Send, "m_nSolidType", 2);

	SetEntPropVector(entindex, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(entindex, Prop_Send, "m_vecMaxs", maxbounds);

	new enteffects = GetEntProp(entindex, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(entindex, Prop_Send, "m_fEffects", enteffects);

	TeleportEntity(entindex, position, NULL_VECTOR, NULL_VECTOR);
}