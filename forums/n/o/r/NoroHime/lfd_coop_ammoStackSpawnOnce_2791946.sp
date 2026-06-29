#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Upgrade Packs with Ammo (Once Time)",
	author = "bullet28, NoroHime",
	description = "Creates ammo pile at the place where the upgrade pack was deployed",
	version = "1",
	url = "https://forums.alliedmods.net/showthread.php?p=2691806"
}

#define MODEL_AMMO "models/props_unique/spawn_apartment/coffeeammo.mdl" // another model variants: "models/props/terror/ammo_stack.mdl" "models/props/de_prodigy/ammo_can_02.mdl"

public void OnMapStart() {
	if (!IsModelPrecached(MODEL_AMMO)) {
		PrecacheModel(MODEL_AMMO);
	}
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrContains(classname, "upgrade_ammo_") != -1)
		SDKHook(entity, SDKHook_SpawnPost, OnPostUpgradeSpawn);
}

public void OnPostUpgradeSpawn(int entity) {
	if (!IsValidEntity(entity)) return;

	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "upgrade_ammo_") == -1) return;

	int ammoStack = CreateEntityByName("weapon_ammo_spawn");
	if (ammoStack <= 0) return;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	origin[0] -= 10.0;
	origin[1] -= 10.0;
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

	origin[0] += 20.0;
	origin[1] += 20.0;
	TeleportEntity(ammoStack, origin, NULL_VECTOR, NULL_VECTOR);

	SetEntityModel(ammoStack, MODEL_AMMO);
	DispatchSpawn(ammoStack);
	SDKHook(ammoStack, SDKHook_UsePost, OnUsePost);
}

void OnUsePost(int entity, int activator, int caller, UseType type, float value) {
	// if (GetRandomFloat() > 0.5)
	// 	return;
	SDKUnhook(entity, SDKHook_UsePost, OnUsePost);
	SetVariantString("OnUser1 !self:Kill::0:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}