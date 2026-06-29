#pragma semicolon 1
#include <sourcemod>

// we need a couple of important functions from these built-in extensions
#include <sdkhooks>
#include <sdktools>

/**
 * we need this to hook the projectile "touch" event
 * you may recall the other day that I mentioned `SDKHook`'s `Touch` event should be fine
 * 
 * that was a lie
 */
#include <dhooks>

// enforces new syntax (1.7 onward)
#pragma newdecls required

// declares a variable that is available across all functions
Handle g_DHookProjectileTouch;

public void OnPluginStart() {
	// declares a game configuration file (from `gamedata/`)
	// this is used for certain values that may change across game or game updates instead of
	// hardcoding the values in the plugin
	Handle hGameConf = LoadGameConfigFile("tf2.projectile_heal_on_teammate_contact");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.projectile_heal_on_teammate_contact).");
	}
	
	// prepares a hook on a virtual function CTFBaseProjectile::ProjectileTouch()
	int offs = GameConfGetOffset(hGameConf, "CTFBaseProjectile::ProjectileTouch()");
	g_DHookProjectileTouch = DHookCreate(offs, HookType_Entity, ReturnType_Void,
			ThisPointer_CBaseEntity, OnProjectileTouch);
	DHookAddParam(g_DHookProjectileTouch, HookParamType_CBaseEntity);
	
	delete hGameConf;
}

/**
 * Called when an entity has been created.
 */
public void OnEntityCreated(int entity, const char[] className) {
	// you'll need to identify any other entity names if you want to add 
	if (StrEqual(className, "tf_projectile_syringe")) {
		// hooks the entity with the information given in OnPluginStart()
		// https://bitbucket.org/Peace_Maker/dhooks2/src/e7363b9d67935f70d1269b449e9fc6d5d6b43bd8/sourcemod/scripting/include/dhooks.inc?at=dynhooks
		DHookEntity(g_DHookProjectileTouch, false, entity);
	}
}

/**
 * Called when the syringe hits another entity.
 */
public MRESReturn OnProjectileTouch(int entity, Handle hParams) {
	// retrieves the entity from the parameter list
	int other = DHookGetParam(hParams, 1);
	
	// use default behavior when the entity hit isn't a player
	if (other < 1 || other > MaxClients) {
		return MRES_Ignored;
	}
	
	// use default behavior when the entity hit is on a different team
	int teamNum = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	if (teamNum != GetClientTeam(other)) {
		return MRES_Ignored;
	}
	
	/**
	 * TODO you may want to check for the item's definition index to differentiate between
	 * syringes from the stock syringe gun, blutsauger, and overdose
	 */
	
	// to keep things simple, placeholder amount to heal, do some fancy math or something
	int nHealAmount = 5;
	
	// do the heal, remove the syringe, and prevent the default behavior
	TF2_HealPlayer(other, nHealAmount, true, true);
	RemoveEntity(entity);
	return MRES_Supercede;
}

/**
 * Premade function that heals a player.
 * https://github.com/nosoop/stocksoup/blob/b39a83fbc9880a5312f73912dac57ef89a1e64e9/tf/player.inc#L11-L47
 */
stock bool TF2_HealPlayer(int client, int nHealAmount, bool overheal = false,
		bool notify = false) {
	if (!IsPlayerAlive(client)) {
		return false;
	}
	
	int nHealth = GetClientHealth(client);
	int nMaxHealth = TF2_GetPlayerMaxHealth(client);
	
	// cap heals to max health
	if (!overheal && nHealAmount > nMaxHealth - nHealth) {
		nHealAmount = nMaxHealth - nHealth;
	}
	
	if (nHealAmount > 0) {
		SetEntityHealth(client, nHealth + nHealAmount);
		
		// player health HUD notification
		if (notify) {
			Event event = CreateEvent("player_healonhit");
			if (event) {
				event.SetInt("amount", nHealAmount);
				event.SetInt("entindex", client);
				
				event.FireToClient(client);
				delete event;
			}
		}
		return true;
	}
	return false;
}

/**
 * Returns the current maximum amount of health that a player can have.
 */
stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
