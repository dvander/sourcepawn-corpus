/* Copyright
 * Category: None
 * 
 * TF2Beta06 Gameplay 1.0.0 by Wolvan
 * Contact: wolvan1@gmail.com
 * 
*/

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "TF2Beta06 Gameplay"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "No Compression Blast or Building Movement!!"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2175470"

/* Create plugin instance
 * Category: Plugin Instance
 *  
 * Tell SourceMod about my Plugin
 * 
*/
public Plugin:myinfo = {
	name 			= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

/* Check Game
 * Category: Pre-Init
 *  
 * Check if the game this Plugin is running on is TF2 or TF2beta and register natives
 * 
*/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

/* Plugin starts
 * Category: Plugin Callback
 * 
 * Hook into the required TF2 Events, create the version ConVar
 * and go through every online Player to assign the current Team
 * and set the changing Class Variable to false. Also load the
 * translation file common.phrases, register the Console Commands
 * and create the Forward Calls
 * 
*/
public OnPluginStart() {
	CreateConVar("tf2beta06_version", PLUGIN_VERSION, "TF2Beta06 Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

/* Block Attack2 for Wrenches and Flamethrowers
 * Category: Keypress Callback
 * 
 * This blocks Wrenches from picking up Buildings and
 * Flamethrowers from Airblasting
 * 
*/
public Action:OnPlayerRunCmd(client, &buttons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)  {
	decl String:weapon[512];
	GetClientWeapon(client, weapon, sizeof(weapon));
	
	if(!(StrEqual(weapon, "tf_weapon_flamethrower", false) || StrEqual(weapon, "tf_weapon_wrench", false)|| StrEqual(weapon, "tf_weapon_robot_arm", false))) {
		return Plugin_Continue;
	}
	
	if (IsPlayerAlive(client)) {
		if(buttons & IN_ATTACK2) {
			buttons &= ~IN_ATTACK2;
		}
	}
	return Plugin_Continue;
}