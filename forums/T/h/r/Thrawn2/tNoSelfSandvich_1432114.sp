#pragma semicolon 1				// ALWAYS! Keep your code clean!
#include <sourcemod>			// obviously
#include <sdkhooks>				// SDKHOOKS v2 !!!
#include <sdktools>				// We need this only for AcceptEntityInput

#define VERSION 		"0.0.3"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new Handle:g_hCvarRefill = INVALID_HANDLE;

new bool:g_bEnabled;

new bool:g_bRefill;
new bool:g_bCanRefill[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name 		= "tNoSelfSandvich",
	author 		= "Thrawn",
	description = "Blocks Heavies from picking up their own sandvich/steak.",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tnoselfsandvich_version", VERSION, "Blocks Heavies from picking up their own sandvich/steak.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tnoselfsandvich_enable", "1", "Enable tNoSelfSandvich", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarRefill = CreateConVar("sm_tnoselfsandvich_refill", "0", "Heavies refill their meter when picking up own sandviches.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarEnabled, Cvar_Changed);
	HookConVarChange(g_hCvarRefill, Cvar_Changed);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_bRefill = GetConVarBool(g_hCvarRefill);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnEntityCreated(entity, const String:classname[]) {
	if(!g_bEnabled)return;

	// Only hook medium sized medkits (medkits, steak, sandvich...)
	// This could be extended to small medkits to block scouts from picking
	// up medkits created by their Candy Cane.
	if(StrEqual(classname, "item_healthkit_medium")) {
    	SDKHook(entity, SDKHook_SpawnPost, OnHealthKitSpawned);
    }
}

public OnHealthKitSpawned(entity) {
	// The original idea was to check for the model, but checking
	// for entities being owned by someone should be more update-safe.
	new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	// Only hook medkits being owned by someone
	// Medkits placed on the map have no owner, so they are being filtered
	if(iOwner > 0 && iOwner <= MaxClients && IsClientInGame(iOwner)) {

		// How do i explain this. Heavies run faster than they throw sandviches,
		// this means they can touch their own sandvich directly after throwing it.
		// Valve blocks this for the normal sandvich behaviour - we need to do the
		// same. So:
		// If Refill is enabled, then we need to block pickup for... experimenting... 0.6s
		if(g_bRefill) {
			g_bCanRefill[iOwner] = false;
			CreateTimer(0.6, Timer_AllowSandvichRefill, iOwner, TIMER_FLAG_NO_MAPCHANGE);
		}

		// Call OnHealthKitStartTouch if some starts to touch our owned medkits
		SDKHook(entity, SDKHook_StartTouch, OnHealthKitStartTouch);
	}
}

public Action:Timer_AllowSandvichRefill(Handle:timer, any:client) {
	// Reenable refill for this client
	g_bCanRefill[client] = true;
}

public Action:OnHealthKitStartTouch(entity, other) {
	// Only hook touch if a _client_ touches the sandvich/steak
	if (other < 1 || other >= MaxClients)
		return Plugin_Continue;

	// A player started touching our medkit, lets hook touch.
	SDKHook(entity, SDKHook_Touch, OnHealthKitTouch);
	return Plugin_Handled;
}

public Action:OnHealthKitTouch(entity, other) {
	// Block the owner from touching his own medkits
	new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	// The owner of a medium sized medkit is touching it.
	if(iOwner == other) {

		// If Refill is enabled an the owner is allowed to touch it (see above).
		if(g_bRefill && g_bCanRefill[iOwner]) {
			// We need to remove the entity ourself
			AcceptEntityInput(entity, "Kill");

			// Give the owner its sandvich 'ammo' back.
			RefillSandvich(iOwner);
		}

		// Always block 'default' pickup (for owners)
		return Plugin_Handled;
	}

	// Continue as if nothing happened
	return Plugin_Continue;
}

public RefillSandvich(client) {
	// m_iAmmo->004 contains the ammo for the heavy sandvich
	new iOffSandvich = FindDataMapOffs(client, "m_iAmmo") + 4 * 4;

	// Set it to 1 to give the heavy a sandvich.
	SetEntData(client, iOffSandvich, 1);
}