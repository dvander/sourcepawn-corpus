#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo =
{
	name = "[TF2] FlameSoundFix",
	author = "Walgrim",
	description = "Fix the annoying flame sound on player hurt",
	version = "1.1",
	url = "http://steamcommunity.com/id/walgrim/"
};

/*
** If it's a tf_projectile_rocket or tf_projectile_sentryrocket.
** Hook when this projectile spawns.
*******************************************************************************/

public void OnEntityCreated(int entity, const char[] classname) {
	if (!(StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_sentryrocket"))) {
		return;
	}
	SDKHook(entity, SDKHook_Spawn, OnRocketSpawn);
}

/*
** Verify if this one is valid, set it as a BaseProjectile (if I'm not wrong).
** Just unhook it at the end to avoid bugs (or double Hook I guess).
*******************************************************************************/

public Action OnRocketSpawn(int entity) {
	if (IsValidEntity(entity)) {
		SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", entity);
		SetEntPropEnt(entity, Prop_Send, "m_hLauncher", entity);
	}
	SDKUnhook(entity, SDKHook_Spawn, OnRocketSpawn);
}
