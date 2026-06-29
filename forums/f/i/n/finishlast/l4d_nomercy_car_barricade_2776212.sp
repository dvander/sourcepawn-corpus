/****************************************************************************************************
* Plugin     : L4D - No Mercy car barricade crescendo
* Version    : 0.0.4
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself
* Website    : https://forums.alliedmods.net/showthread.php?p=2776212
* Purpose    : This plugin creates a block crescendo at the end of the nomercy subway map
* Based on code from:
* https://forums.alliedmods.net/showthread.php?t=328013 Bacardi Freight lift button
*
* Changelog:
* 0.0.4 - Fixed entity duplication on map reload / round restart.
*         All spawned entities (including decorative props) are now properly
*         killed before new ones are created, preventing ghost copies.
*         Entity cleanup also runs on round_end so mid-crescendo restarts
*         leave no orphaned entities.
****************************************************************************************************/

public Plugin myinfo =
{
	name        = "L4D - No Mercy car barricade crescendo",
	author      = "finishlast",
	description = "Block crescendo at the end of the no mercy subway map",
	version     = "0.0.4",
	url         = "https://forums.alliedmods.net/showthread.php?t=337225"
}

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

Handle g_timer = INVALID_HANDLE;

// Entity vars stored as EntRefs, initialised to INVALID_ENT_REFERENCE.
int ent_dynamic_block1  = INVALID_ENT_REFERENCE;  // moving car barricade
int ent_dynamic_block2  = INVALID_ENT_REFERENCE;  // intact door (killed at numlift==30)
int dynamic_prop_button = INVALID_ENT_REFERENCE;  // func_button
int dynamic_prop_fence  = INVALID_ENT_REFERENCE;  // left police barricade  (touch hook)
int dynamic_prop_fence2 = INVALID_ENT_REFERENCE;  // right police barricade (touch hook)
int ent_decorative_battery   = INVALID_ENT_REFERENCE;  // decorative battery prop
int ent_decorative_switchbox = INVALID_ENT_REFERENCE;  // decorative switchbox prop

int   numlift = 0;
float bigger  = 1.0;

#define PARTICLE_BOMB1 "gas_explosion_pump"

// ---------------------------------------------------------------------------
// Helper: resolve an EntRef to a usable entity index, or return -1 on failure
// ---------------------------------------------------------------------------
stock int ResolveRef(int entRef)
{
	if (entRef == INVALID_ENT_REFERENCE)
		return -1;
	int idx = EntRefToEntIndex(entRef);
	if (idx == INVALID_ENT_REFERENCE || !IsValidEntity(idx))
		return -1;
	return idx;
}

// ---------------------------------------------------------------------------
// Kill all plugin-owned entities and reset their refs to INVALID_ENT_REFERENCE.
// Safe to call at any time — skips any ref that is already invalid.
// ---------------------------------------------------------------------------
void KillAllEntities()
{
	int old;

	old = ResolveRef(ent_dynamic_block1);       if (old != -1) AcceptEntityInput(old, "Kill");
	old = ResolveRef(ent_dynamic_block2);       if (old != -1) AcceptEntityInput(old, "Kill");
	old = ResolveRef(dynamic_prop_button);      if (old != -1) AcceptEntityInput(old, "Kill");
	old = ResolveRef(dynamic_prop_fence);       if (old != -1) AcceptEntityInput(old, "Kill");
	old = ResolveRef(dynamic_prop_fence2);      if (old != -1) AcceptEntityInput(old, "Kill");
	old = ResolveRef(ent_decorative_battery);   if (old != -1) AcceptEntityInput(old, "Kill");
	old = ResolveRef(ent_decorative_switchbox); if (old != -1) AcceptEntityInput(old, "Kill");

	ent_dynamic_block1       = INVALID_ENT_REFERENCE;
	ent_dynamic_block2       = INVALID_ENT_REFERENCE;
	dynamic_prop_button      = INVALID_ENT_REFERENCE;
	dynamic_prop_fence       = INVALID_ENT_REFERENCE;
	dynamic_prop_fence2      = INVALID_ENT_REFERENCE;
	ent_decorative_battery   = INVALID_ENT_REFERENCE;
	ent_decorative_switchbox = INVALID_ENT_REFERENCE;
}

// ---------------------------------------------------------------------------
public void OnPluginStart()
{
	PrecacheModel("models/props_vehicles/racecar_damaged.mdl");
	PrecacheModel("models/props_interiors/makeshift_stove_battery.mdl");
	PrecacheModel("models/props_street/barricade_door_01_damaged.mdl");
	PrecacheModel("models/props_street/barricade_door_01.mdl");
	PrecacheModel("models/props_street/police_barricade3.mdl");
	PrecacheModel("models/props_street/police_barricade2.mdl");
	PrecacheModel("models/props_lab/freightelevatorbutton.mdl");
	PrecacheSound("animation/garage_outro.wav");
	PrecacheSound("ambient/explosions/explode_1.wav");

	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
	HookEvent("round_end",        event_round_end,        EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
	delete g_timer;
}

public void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
	delete g_timer;
	KillAllEntities();  // clean up mid-crescendo orphans if the round ends early
}

// ---------------------------------------------------------------------------
public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	numlift = 0;
	bigger  = 1.0;

	// Kill any entities left over from a previous round / map reload
	// before spawning fresh ones. This prevents ghost duplicates.
	KillAllEntities();

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if (!StrEqual(sMap, "l4d_vs_hospital02_subway", false)
	&&  !StrEqual(sMap, "l4d_hospital02_subway",    false)
	&&  !StrEqual(sMap, "c8m2_subway",              false))
		return;

	float pos[3], ang[3], fwd[3];

	// --- Button + glow prop ---
	pos[0] = 7820.0;  pos[1] = 4855.0;  pos[2] = 35.0;
	ang[0] = 0.0;     ang[1] = 0.0;     ang[2] = 90.0;

	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 100.0);
	AddVectors(fwd, pos, fwd);

	char origin[100];
	Format(origin, sizeof(origin), "%0.1f %0.1f %0.1f", fwd[0], fwd[1], fwd[2]);

	float output[3];
	MakeVectorFromPoints(fwd, pos, output);
	GetVectorAngles(output, ang);
	ang[0] = 0.0;

	char targetname[100];
	int tick = GetGameTickCount();
	Format(targetname, sizeof(targetname), "@glow_%i", tick);

	CreateGlowModel(fwd, ang, origin, targetname);
	CreateButton(fwd, ang, origin, targetname);

	// --- Damaged race car (the moving barricade) ---
	pos[0] = 7954.0;  pos[1] = 4936.0;  pos[2] = 5.0;
	ang[0] = 0.0;     ang[1] = 277.0;   ang[2] = 0.0;

	int idx = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(idx, "model",          "models/props_vehicles/racecar_damaged.mdl");
	DispatchKeyValue(idx, "disableshadows", "1");
	DispatchKeyValue(idx, "solid",          "6");
	DispatchSpawn(idx);
	TeleportEntity(idx, pos, ang, NULL_VECTOR);
	ent_dynamic_block1 = EntIndexToEntRef(idx);

	// --- Battery (decorative) ---
	pos[0] = 7923.0;  pos[1] = 4850.0;  pos[2] = 15.0;
	ang[0] = 0.0;     ang[1] = 270.0;   ang[2] = 90.0;

	idx = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(idx, "model",          "models/props_interiors/makeshift_stove_battery.mdl");
	DispatchKeyValue(idx, "disableshadows", "1");
	DispatchKeyValue(idx, "solid",          "6");
	DispatchSpawn(idx);
	TeleportEntity(idx, pos, ang, NULL_VECTOR);
	ent_decorative_battery = EntIndexToEntRef(idx);  // tracked so it can be cleaned up

	// --- Switch box / cable prop (decorative) ---
	pos[0] = 7916.0;  pos[1] = 4856.0;  pos[2] = 10.0;
	ang[0] = -90.0;   ang[1] = 90.0;    ang[2] = 0.0;

	idx = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(idx, "model",          "models/props_wasteland/prison_switchbox001a.mdl");
	DispatchKeyValue(idx, "disableshadows", "1");
	DispatchKeyValue(idx, "solid",          "6");
	DispatchSpawn(idx);
	TeleportEntity(idx, pos, ang, NULL_VECTOR);
	ent_decorative_switchbox = EntIndexToEntRef(idx);  // tracked so it can be cleaned up

	// --- Police barricade 3 (fence left) ---
	pos[0] = 8632.0;  pos[1] = 4760.0;  pos[2] = 10.0;
	ang[0] = 0.0;     ang[1] = 180.0;   ang[2] = 0.0;

	idx = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(idx, "model",          "models/props_street/police_barricade3.mdl");
	DispatchKeyValue(idx, "disableshadows", "1");
	DispatchKeyValue(idx, "solid",          "6");
	DispatchSpawn(idx);
	TeleportEntity(idx, pos, ang, NULL_VECTOR);
	dynamic_prop_fence = EntIndexToEntRef(idx);
	SDKHook(idx, SDKHook_Touch, OnTouch);

	// --- Police barricade 2 (fence right) ---
	pos[0] = 8632.0;  pos[1] = 5420.0;  pos[2] = 10.0;

	idx = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(idx, "model",          "models/props_street/police_barricade2.mdl");
	DispatchKeyValue(idx, "disableshadows", "1");
	DispatchKeyValue(idx, "solid",          "6");
	DispatchSpawn(idx);
	TeleportEntity(idx, pos, ang, NULL_VECTOR);
	dynamic_prop_fence2 = EntIndexToEntRef(idx);
	SDKHook(idx, SDKHook_Touch, OnTouch);

	// --- Door barricade (the one that explodes mid-sequence) ---
	pos[0] = 8632.0;  pos[1] = 5120.0;  pos[2] = 10.0;

	idx = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(idx, "model",          "models/props_street/barricade_door_01.mdl");
	DispatchKeyValue(idx, "disableshadows", "1");
	DispatchKeyValue(idx, "solid",          "6");
	DispatchSpawn(idx);
	TeleportEntity(idx, pos, ang, NULL_VECTOR);
	ent_dynamic_block2 = EntIndexToEntRef(idx);
	SDKHook(idx, SDKHook_Touch, OnTouch);

	// Hook the button output (dynamic_prop_button was stored as ref inside CreateButton)
	int btnIdx = ResolveRef(dynamic_prop_button);
	if (btnIdx != -1)
		HookSingleEntityOutput(btnIdx, "OnPressed", OnPressed);
}

// ---------------------------------------------------------------------------
// Create glow model (visual only, decorative — ref not needed after spawn)
// ---------------------------------------------------------------------------
void CreateGlowModel(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname)
{
	int idx = CreateEntityByName("prop_dynamic");
	if (idx == -1) return;

	DispatchKeyValue(idx, "origin",     origin);
	DispatchKeyValue(idx, "targetname", targetname);
	DispatchKeyValue(idx, "model",      "models/props_mill/freightelevatorbutton02.mdl");
	DispatchKeyValue(idx, "spawnflags", "0");
	DispatchSpawn(idx);
	TeleportEntity(idx, fwd, ang, NULL_VECTOR);
}

// ---------------------------------------------------------------------------
// Create the func_button
// ---------------------------------------------------------------------------
void CreateButton(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname)
{
	int idx = CreateEntityByName("func_button");
	if (idx == -1) return;

	DispatchKeyValue(idx, "origin",     origin);
	DispatchKeyValue(idx, "glow",       targetname);
	DispatchKeyValue(idx, "wait",       "-1");
	DispatchKeyValue(idx, "spawnflags", "1025"); // Don't move + Use Activates

	DispatchSpawn(idx);
	ActivateEntity(idx);
	TeleportEntity(idx, fwd, ang, NULL_VECTOR);

	SetEntityModel(idx, "models/props_mill/freightelevatorbutton02.mdl");

	float vMins[3] = {-30.0, -30.0,   0.0};
	float vMaxs[3] = { 30.0,  30.0, 200.0};
	SetEntPropVector(idx, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(idx, Prop_Send, "m_vecMaxs", vMaxs);

	// Suppress "Can't draw studio model ... CBaseButton not derived from C_BaseAnimating"
	int enteffects = GetEntProp(idx, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(idx, Prop_Send, "m_fEffects", enteffects);

	dynamic_prop_button = EntIndexToEntRef(idx);
}

// ---------------------------------------------------------------------------
// Button pressed callback
// ---------------------------------------------------------------------------
public void OnPressed(const char[] output, int caller, int activator, float delay)
{
	// Resolve the button ref to make sure it's still valid
	int btnIdx = ResolveRef(dynamic_prop_button);
	if (btnIdx == -1) return;

	// Lock and kill immediately to prevent any double-trigger
	AcceptEntityInput(btnIdx, "Lock");
	AcceptEntityInput(btnIdx, "Kill");
	dynamic_prop_button = INVALID_ENT_REFERENCE;

	Command_Play("animation\\garage_outro.wav");
	Command_Play("animation\\garage_outro.wav");

	char command[] = "director_force_panic_event";
	int flags = GetCommandFlags(command);  // int, not char — avoids bit truncation
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(activator, command);
	SetCommandFlags(command, flags);

	// Clean up any existing timer before starting a new one
	delete g_timer;
	g_timer = CreateTimer(0.1, gate, _, TIMER_REPEAT);
}

// ---------------------------------------------------------------------------
// Repeating timer: slides the car forward, triggers mid-point explosion,
// then finalises with fire + explosion at the end.
// ---------------------------------------------------------------------------
public Action gate(Handle timer)
{
	// Resolve the car entity; abort cleanly if it's gone
	int block1 = ResolveRef(ent_dynamic_block1);
	if (block1 == -1)
	{
		g_timer = null;
		return Plugin_Stop;
	}

	float pos[3], ang[3], dir[3];
	GetEntPropVector(block1, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(block1, Prop_Send, "m_angRotation",  ang);

	pos[0] += bigger;
	dir[0]  = 0.0;
	dir[1]  = 0.0;
	dir[2]  = 0.0;

	if (numlift <= 35)
		pos[1] += 3.0;
	else
		pos[1] += 7.0;

	// --- Mid-point: explode the door barricade ---
	if (numlift == 30)
	{
		float posbarricade[3], angbarricade[3];
		posbarricade[0] = 8632.0;  posbarricade[1] = 5120.0;  posbarricade[2] = 10.0;
		angbarricade[0] = 0.0;     angbarricade[1] = 180.0;   angbarricade[2] = 0.0;

		Command_Play("ambient\\explosions\\explode_1.wav");

		int particle = CreateEntityByName("info_particle_system");
		if (particle != -1)
		{
			DispatchKeyValue(particle, "effect_name", PARTICLE_BOMB1);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			TeleportEntity(particle, posbarricade, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("OnUser1 !self:Kill::1.0:1");
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}

		// Kill intact door, spawn damaged version (fire-and-forget, ref not needed)
		int block2 = ResolveRef(ent_dynamic_block2);
		if (block2 != -1)
			AcceptEntityInput(block2, "Kill");
		ent_dynamic_block2 = INVALID_ENT_REFERENCE;

		int damaged = CreateEntityByName("prop_dynamic");
		DispatchKeyValue(damaged, "model",          "models/props_street/barricade_door_01_damaged.mdl");
		DispatchKeyValue(damaged, "disableshadows",  "1");
		DispatchKeyValue(damaged, "solid",           "6");
		DispatchSpawn(damaged);
		TeleportEntity(damaged, posbarricade, angbarricade, NULL_VECTOR);
	}

	TeleportEntity(block1, pos, ang, dir);

	// --- End of sequence ---
	if (numlift >= 71)
	{
		numlift = 0;
		bigger  = 1.0;

		SetConVarInt(FindConVar("sb_unstick"), 1);

		pos[2] += 10.0;
		TeleportEntity(block1, pos, ang, dir);

		// Explosion particle at car position
		int particle2 = CreateEntityByName("info_particle_system");
		if (particle2 != -1)
		{
			DispatchKeyValue(particle2, "effect_name", PARTICLE_BOMB1);
			DispatchSpawn(particle2);
			ActivateEntity(particle2);
			AcceptEntityInput(particle2, "start");
			TeleportEntity(particle2, pos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("OnUser1 !self:Kill::1.0:1");
			AcceptEntityInput(particle2, "AddOutput");
			AcceptEntityInput(particle2, "FireUser1");
		}

		// Fire entity slightly above the car
		pos[2] += 50.0;
		int fire = CreateEntityByName("env_fire");
		DispatchKeyValue(fire, "firesize",    "100");
		DispatchKeyValue(fire, "health",      "1000");
		DispatchKeyValue(fire, "firetype",    "Normal");
		DispatchKeyValue(fire, "damagescale", "0.0");
		DispatchKeyValue(fire, "spawnflags",  "256");
		SetVariantString("WaterSurfaceExplosion");
		AcceptEntityInput(fire, "DispatchEffect");
		DispatchSpawn(fire);
		TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(fire, "StartFire");

		Command_Play("ambient\\explosions\\explode_1.wav");

		g_timer = null;
		return Plugin_Stop;
	}

	bigger += 1.0;
	numlift++;
	return Plugin_Continue;
}

// ---------------------------------------------------------------------------
// Play a sound to all clients
// ---------------------------------------------------------------------------
void Command_Play(const char[] arguments)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		ClientCommand(i, "playgamesound %s", arguments);
	}
}

// ---------------------------------------------------------------------------
// Touch handler: disable bot unstick when a survivor bot touches a barricade
// ---------------------------------------------------------------------------
public void OnTouch(int entity, int other)
{
	if (other < 1 || other > MaxClients)
		return;

	if (!IsClientInGame(other) || !IsFakeClient(other) || GetClientTeam(other) != 2)
		return;

	SetConVarInt(FindConVar("sb_unstick"), 0);

	// Unhook all barricade touch callbacks
	int block1 = ResolveRef(ent_dynamic_block1);
	int fence   = ResolveRef(dynamic_prop_fence);
	int fence2  = ResolveRef(dynamic_prop_fence2);

	if (block1 != -1) SDKUnhook(block1, SDKHook_Touch, OnTouch);
	if (fence   != -1) SDKUnhook(fence,  SDKHook_Touch, OnTouch);
	if (fence2  != -1) SDKUnhook(fence2, SDKHook_Touch, OnTouch);
}
