#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

/*=================================
=            Constants            =
=================================*/

#define PLUGIN_NAME	 	"No Fall Damage"
#define PLUGIN_AUTHOR   "floube"
#define PLUGIN_DESC	 	"Just a short and easy plugin to block fall damage."
#define PLUGIN_VERSION  "1.00"
#define PLUGIN_URL	  	"http://www.styria-games.eu/"

/*===================================
=            Plugin Info            =
===================================*/

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

/**
 * Called when a client is entering the game.
 *
 * @param iClient		The client.
 * @noreturn
 */

public OnClientPutInServer(iClient) {
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

/**
 * Called when a client takes damage.
 *
 * @noreturn
 */

public Action:OnTakeDamage(iClient, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iWeapon, Float:fDamageForce[3], Float:fDamagePosition[3]) {
	if (iDamageType == DMG_FALL) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}