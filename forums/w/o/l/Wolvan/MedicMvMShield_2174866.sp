/* Copyright
 * Category: None
 * 
 * Medic MvM Shield 1.2.3 by Wolvan
 * Contact: wolvan1@gmail.com
 * Plugin based on abrandnewday's Medic's Anti-Projectile Shield & Pelipoika's modified Version
*/

/* Includes
 * Category: Preprocessor
 *  
 * Includes the necessary SourceMod modules
 * 
*/
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <permissionssm>

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "Medic's MvM Shield"
#define PLUGIN_VERSION "1.2.3"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Activate the Medic's Shield in PvP easily! Highly customizable using CVars and/or the Admin Menu"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=245063"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.MedicMvMShield.cfg"
#define PERMISSIONNODE_BASE "MedicMvMShield"

/* Variable creation
 * Category: Storage
 *  
 * Set variables to store some shit while Plugin runs
 * 
*/
new g_entCurrentShield[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
new bool:announced[MAXPLAYERS+1] = { false, ... };
new bool:g_onTimeRecharge[MAXPLAYERS+1] = { false, ... };
new bool:g_bPlayerPressedReload[MAXPLAYERS+1] = { false, ... };
new bool:permissionssm = false;
new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:announceTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:delayTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:tmpTopMenuHandle = INVALID_HANDLE;
new TopMenuObject:obj_mscommands;

/* ConVar Handle creation
 * Category: Storage
 * 
 * Create the Variables to store the ConVar Handles in.
 * 
*/
new Handle:g_adminOnly = INVALID_HANDLE;
new Handle:g_rechargeMode = INVALID_HANDLE;
new Handle:g_rechargeDelay = INVALID_HANDLE;
new Handle:g_requiredCharge = INVALID_HANDLE;
new Handle:g_disableRecharge = INVALID_HANDLE;
new Handle:g_pluginEnabled = INVALID_HANDLE;
new Handle:g_rechargeOnDeath = INVALID_HANDLE;
new Handle:g_team = INVALID_HANDLE;
new Handle:g_useOverrideStrings = INVALID_HANDLE;

/* Forward Handle creation
 * Category: Storage
 * 
 * Create the Handles for the Forward Calls
 * 
*/
new Handle:forward_shieldSpawn = INVALID_HANDLE;
new Handle:forward_shieldReady = INVALID_HANDLE;

/* Create plugin instance
 * Category: Plugin Instance
 *  
 * Tell SourceMod about my Plugin
 * 
*/
public Plugin:myinfo = {
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
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
	
	RegPluginLibrary("medicshield");
	
	return APLRes_Success;
}

/* Plugin starts
 * Category: Plugin Callback
 * 
 * Hook into the required TF2 Events, create the version ConVar
 * and the Config ConVars. Register Console Command and Hook into
 * Adminmenu if possible.
 * 
*/
public OnPluginStart() {
	g_rechargeDelay = CreateConVar("medicshield_recharge_delay", "60", "Set the time it takes to recharge the shield", FCVAR_NOTIFY, true, 0.0);
	g_adminOnly = CreateConVar("medicshield_admin_only", "0", "Enable or disable access for normal users", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_rechargeMode = CreateConVar("medicshield_recharge_mode", "1", "Change Recharge Mode (0 - Use Time Delay, 1 - Use Medigun Charge Level", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_requiredCharge = CreateConVar("medicshield_required_charge", "0.75", "Change how much Medigun charge is required to deploy the shield (float)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_disableRecharge = CreateConVar("medicshield_disable_recharge", "0", "Disable recharge time/required Übercharge to activate shield", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_rechargeOnDeath = CreateConVar("medicshield_recharge_on_death", "1", "If the recharge is time based, the shield will be available after dying", FCVAR_NOTIFY, true, 0.0, true, 1.0); 
	g_pluginEnabled = CreateConVar("medicshield_enable_plugin", "1", "Enable or disable the Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_team = CreateConVar("medicshield_team", "0", "Allow only one team to use the shield. 0 - Both teams, 1 - RED, 2 - BLU", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_useOverrideStrings = CreateConVar("medicshield_use_override_strings", "0", "Use Override Strings for Permissions", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	
	HookEvent("player_death", Event_OnPlayerDeath);
	
	RegConsoleCmd("medicshield_shield", Command_Shield, "Turns on the Medic's shield effect from MvM. Usage: medicshield_shield");
	RegConsoleCmd("medicshield_shield2", Command_Shield2, "Turns on the Medic's advanced shield effect from MvM. Usage: medicshield_shield2");
	RegConsoleCmd("medicshield_info", PrintPluginInfo, "Show information about the Plugin");
	
	forward_shieldSpawn = CreateGlobalForward("OnMedicShieldSpawn", ET_Event, Param_Cell);
	forward_shieldReady = CreateGlobalForward("OnMedicShieldReady", ET_Event, Param_Cell);
	
	if (FindConVar("medicshield_version") == INVALID_HANDLE) { AutoExecConfig(true); }
	
	CreateConVar("medicshield_version", PLUGIN_VERSION, "Medic's MvM Shield Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
	permissionssm = LibraryExists("permissionssm");
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			announced[i] = false;
			announceTimer[i] = CreateTimer(1.0, AnnounceReadyShield, GetClientUserId(i), TIMER_REPEAT);
			SDKHook(i, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
		}
	}
}

/* Plugin ends
 * Category: Plugin Callback
 *  
 * When the Plugin gets unloaded, remove every Shield
 * from the world
 * 
*/
public OnPluginEnd() {
	for (new i = 1; i <= MaxClients; i++) {
		if (announceTimer[i] != INVALID_HANDLE) {
			KillTimer(announceTimer[i]);
			announceTimer[i] = INVALID_HANDLE;
		}
		if (delayTimer[i] != INVALID_HANDLE) {
			KillTimer(delayTimer[i]);
			delayTimer[i] = INVALID_HANDLE;
		}
		deleteShield(i);
	}
}

public OnMapStart() {
	PrecacheSound("weapons/medi_shield_deploy.wav");
}

/* Client connected
 * Category: Plugin Callback
 *  
 * A new client has connected. Prepare initial values and register
 * an announce timer
 * 
*/
public OnClientPutInServer(client) {
	announced[client] = false;
	announceTimer[client] = CreateTimer(1.0, AnnounceReadyShield, GetClientUserId(client), TIMER_REPEAT);
	SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
}

/* Client disconnected
 * Category: Plugin Callback
 *  
 * Unregister the AnnounceTimer and remove the Shield if it exists
 * 
*/
public OnClientDisconnect(client) {
	if (announceTimer[client] != INVALID_HANDLE) {
		KillTimer(announceTimer[client]);
		announceTimer[client] = INVALID_HANDLE;
	}
	if (delayTimer[client] != INVALID_HANDLE) {
		KillTimer(delayTimer[client]);
		delayTimer[client] = INVALID_HANDLE;
	}
	deleteShield(client);
}

/* Library removed
 * Category: Plugin Callback
 *  
 * This waits for libraries being removed. Currently only
 * used to unhook the Admin Menu
 * 
*/
public OnLibraryRemoved(const String:name[]) {
	if (StrEqual(name, "adminmenu")) {
		hAdminMenu = INVALID_HANDLE;
	} else if (StrEqual(name, "permissionssm")) {
		permissionssm = false;
	}
}

/* Library added
 * Category: Plugin Callback
 *  
 * If a new Library gets added, check if it's a PermissionsSM and enabled
 * the PermissionsSM Functions
 * 
*/
public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "permissionssm")) {
		permissionssm = true;
	}
}

/* AdminMenu ready for hook
 * Category: Plugin Callback
 *  
 * The AdminMenu is now ready for us to hook into
 * and create our own category and fill it.
 * 
*/
public OnAdminMenuReady(Handle:topmenu) {
	if(obj_mscommands == INVALID_TOPMENUOBJECT) {
		OnAdminMenuCreated(topmenu);
	}
	if (topmenu == hAdminMenu) {
		return;
	}
	hAdminMenu = topmenu;
	AttachAdminMenu();
}

/* Creation of Admin Menu
 * Category: Plugin Callback
 * 
 * The AdminMenu is being created, time to add our own sub-menu
 * 
*/
public OnAdminMenuCreated(Handle:topmenu) {
	if (topmenu == hAdminMenu && obj_mscommands != INVALID_TOPMENUOBJECT) {
		return;
	}
	obj_mscommands = AddToTopMenu(topmenu, "Medic MvM Shield", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
}

/* Client Keypress
 * Category: Keypress Callback
 * 
 * Checks if Attack3 has been pressed and runs the
 * Shield Spawn Function
 * 
*/
public Action:OnPlayerRunCmd(client, &buttons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)  {
	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic) {
		if(buttons & IN_ATTACK3) {
			g_bPlayerPressedReload[client] = true;
		} else if (!(buttons & IN_ATTACK3) && g_bPlayerPressedReload[client]) {
			g_bPlayerPressedReload[client] = false;
			if(TF2_GetUberLevel(client) >= 1.0) {
				Command_Shield2(client, -1);
			} else {
				Command_Shield(client, -1);
			}
		}
	}
	return Plugin_Continue;
}

/* Player Death
 * Category: Event Callback
 *  
 * Kill a shield if it's active and remove the
 * cooldown timer
 * 
*/
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0) {
		return Plugin_Continue;
    }
	deleteShield(client);
	if (GetConVarBool(g_rechargeOnDeath)) {
		g_onTimeRecharge[client] = false;
		if (delayTimer[client] != INVALID_HANDLE) {
			KillTimer(delayTimer[client]);
			delayTimer[client] = INVALID_HANDLE;
		}
	}
	return Plugin_Continue;
}

/* Shield Level 1
 * Category: Console Command
 * 
 * Spawns the Level 1 Shield if conditions are met
 * 
*/
public Action:Command_Shield(client, args) {
	if(!GetConVarBool(g_pluginEnabled)) {
		return Plugin_Handled;
	}
	if(GetConVarBool(g_adminOnly)) {
		if(!hasAdminPermission(client)) {
			PrintToChat(client, "[SM] You are not allowed to deploy a shield, Admin-Only Mode enabled");
			return Plugin_Handled;
		}
	}
	
	new Action:result = Plugin_Continue;
	Call_StartForward(forward_shieldSpawn);
	Call_PushCell(client);
	Call_Finish(result);
	
	if (result == Plugin_Handled || result == Plugin_Stop) {
		return Plugin_Handled;
	}
	
	if(permissionssm) {
		if(!PsmHasPermission(client, "%s.shield.lvl1", PERMISSIONNODE_BASE)) {
			PrintToChat(client, "[SM] No Permission to deploy shield Level 1");
			return Plugin_Handled;
		}
	} else if (GetConVarBool(g_useOverrideStrings)) {
		if (!CheckCommandAccess(client, "medicshield_shield", ADMFLAG_GENERIC)) {
			PrintToChat(client, "[SM] No Permission to deploy shield Level 1");
			return Plugin_Handled;
		}
	}
	if((GetConVarInt(g_team) == 1 && GetClientTeam(client) != _:TFTeam_Red) || (GetConVarInt(g_team) == 2 && GetClientTeam(client) != _:TFTeam_Blue)) {
		if (permissionssm) {
			if (!PsmHasPermission(client, "%s.teamOnlyOverride", PERMISSIONNODE_BASE)) {
				PrintToChat(client, "[SM] Your team isn't allowed to spawn shields");
				return Plugin_Handled;
			}
		} else if (GetConVarBool(g_useOverrideStrings)) {
			if (!CheckCommandAccess(client, "medicshield_teamonlyoverride", ADMFLAG_GENERIC, true)) {
				PrintToChat(client, "[SM] Your team isn't allowed to spawn shields");
				return Plugin_Handled;
			}
		} else {
			PrintToChat(client, "[SM] Your team isn't allowed to spawn shields");
			return Plugin_Handled;	
		}
	}
	if (!CheckReadyShield(client)) {
		if (GetConVarBool(g_rechargeMode)) {
			PrintToChat(client, "[SM] Your shield is recharging and will be ready once you aquire %i%% ubercharge.", RoundFloat(GetConVarFloat(g_requiredCharge) * 100));
		} else {
			PrintToChat(client, "[SM] Your shield is recharging.");
		}
		return Plugin_Handled;
	}
	decl String:WeaponName[32];
	GetClientWeapon(client, WeaponName, sizeof(WeaponName));
	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic && StrEqual(WeaponName, "tf_weapon_medigun")) {
		new shield = CreateEntityByName("entity_medigun_shield");
		if(shield != -1) {
			g_entCurrentShield[client] = EntIndexToEntRef(shield);
			SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
			SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
			SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));  
			if (GetClientTeam(client) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
			else if (GetClientTeam(client) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
			SetEntProp(client, Prop_Send, "m_bRageDraining", 1);
			DispatchSpawn(shield);
			EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);
			SetEntityModel(shield, "models/props_mvm/mvm_player_shield2.mdl");
			if (GetConVarBool(g_rechargeMode)) { TF2_SetUberLevel(client, TF2_GetUberLevel(client) - GetConVarFloat(g_requiredCharge)); }
			else { Delay(client); }
			announced[client] = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

/* Shield Level 2
 * Category: Console Command
 * 
 * Spawns the Level 2 Shield if conditions are met
 * 
*/
public Action:Command_Shield2(client, args) {
	if(!GetConVarBool(g_pluginEnabled)) {
		return Plugin_Handled;
	}
	if(GetConVarBool(g_adminOnly)) {
		if(!hasAdminPermission(client)) {
			PrintToChat(client, "[SM] You are not allowed to deploy a shield, Admin-Only Mode enabled");
			return Plugin_Handled;
		}
	}
	
	new Action:result = Plugin_Continue;
	Call_StartForward(forward_shieldSpawn);
	Call_PushCell(client);
	Call_Finish(result);
	
	if (result == Plugin_Handled || result == Plugin_Stop) {
		return Plugin_Handled;
	}
	
	if(permissionssm) {
		if(!PsmHasPermission(client, "%s.shield.lvl2", PERMISSIONNODE_BASE)) {
			PrintToChat(client, "[SM] No Permission to deploy shield Level 2");
			return Plugin_Handled;
		}
	} else if (GetConVarBool(g_useOverrideStrings)) {
		if (!CheckCommandAccess(client, "medicshield_shield2", ADMFLAG_GENERIC)) {
			PrintToChat(client, "[SM] No Permission to deploy shield Level 2");
			return Plugin_Handled;
		}
	}
	if((GetConVarInt(g_team) == 1 && GetClientTeam(client) != _:TFTeam_Red) || (GetConVarInt(g_team) == 2 && GetClientTeam(client) != _:TFTeam_Blue)) {
		if (permissionssm) {
			if (!PsmHasPermission(client, "%s.teamOnlyOverride", PERMISSIONNODE_BASE)) {
				PrintToChat(client, "[SM] Your team isn't allowed to spawn shields");
				return Plugin_Handled;
			} 
		} else if (GetConVarBool(g_useOverrideStrings)) {
			if (!CheckCommandAccess(client, "medicshield_teamonlyoverride", ADMFLAG_GENERIC, true)) {
				PrintToChat(client, "[SM] Your team isn't allowed to spawn shields");
				return Plugin_Handled;
			}
		} else {
			PrintToChat(client, "[SM] Your team isn't allowed to spawn shields");
			return Plugin_Handled;	
		}
	}
	if (!CheckReadyShield(client)) {
		if (GetConVarBool(g_rechargeMode)) {
			PrintToChat(client, "[SM] Your shield is recharging and will be ready once you aquire %i%% ubercharge.", RoundFloat(GetConVarFloat(g_requiredCharge) * 100));
		} else {
			PrintToChat(client, "[SM] Your shield is recharging.");
		}
		return Plugin_Handled;
	}
	if (IsValidClient(client)) {
		decl String:WeaponName[32];
		GetClientWeapon(client, WeaponName, sizeof(WeaponName));
		if (IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic && StrEqual(WeaponName, "tf_weapon_medigun")) {
			new shield = CreateEntityByName("entity_medigun_shield");
			if(shield != -1) {
				g_entCurrentShield[client] = EntIndexToEntRef(shield);
				SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
				SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
				SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));  
				if (GetClientTeam(client) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
				else if (GetClientTeam(client) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
				SetEntProp(client, Prop_Send, "m_bRageDraining", 1);
				DispatchSpawn(shield);
				EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);
				SetEntityModel(shield, "models/props_mvm/mvm_player_shield2.mdl");
				if (GetConVarBool(g_rechargeMode)) { TF2_SetUberLevel(client, 0.0); }
				else { Delay(client); }
				announced[client] = false;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
} 

/* Show Plugin Info
 * Category: Console Command
 * 
 * Shows the current Plugin Info and Configuration to the User
 * 
*/
public Action:PrintPluginInfo(client, args) {
	if(args == -5) {
		PrintToChat(client, "%s v%s by %s\nWebsite: %s\n%s\nConfiguration:", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_URL, PLUGIN_DESCRIPTION);
		if(GetConVarBool(g_pluginEnabled)) {
			PrintToChat(client, "Plugin is enabled");
		} else {
			PrintToChat(client, "Plugin is disabled");
		}
		if(GetConVarBool(g_disableRecharge)) {
			PrintToChat(client, "Recharge: DISABLED");
		} else {
			PrintToChat(client, "Recharge: ENABLED");
		}
		if(GetConVarBool(g_rechargeMode)) {
			PrintToChat(client, "Mode: Übercharge based recharge");
		} else {
			PrintToChat(client, "Mode: Time based recharge");
		}
		if(GetConVarInt(g_team) == 0) {
			PrintToChat(client, "Allowed Team: Both");
		} else if (GetConVarInt(g_team) == 1) {
			PrintToChat(client, "Allowed Team: RED");
		} else if (GetConVarInt(g_team) == 2) {
			PrintToChat(client, "Allowed Team: BLU");
		}
		if(GetConVarBool(g_adminOnly)) {
			PrintToChat(client, "Admins only: YES");
		} else {
			PrintToChat(client, "Admins only: NO");
		}
		PrintToChat(client, "Recharge Delay: %i seconds", GetConVarInt(g_rechargeDelay));
		PrintToChat(client, "Required Übercharge: %i%", RoundFloat(GetConVarFloat(g_requiredCharge) * 100));
	} else {
		PrintToConsole(client, "%s v%s by %s\nWebsite: %s\n%s\nConfiguration:", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_URL, PLUGIN_DESCRIPTION);
		if(GetConVarBool(g_pluginEnabled)) {
			PrintToConsole(client, "Plugin is enabled");
		} else {
			PrintToConsole(client, "Plugin is disabled");
		}
		if(GetConVarBool(g_disableRecharge)) {
			PrintToConsole(client, "Recharge: DISABLED");
		} else {
			PrintToConsole(client, "Recharge: ENABLED");
		}
		if(GetConVarBool(g_rechargeMode)) {
			PrintToConsole(client, "Mode: Übercharge based recharge");
		} else {
			PrintToConsole(client, "Mode: Time based recharge");
		}
		if(GetConVarInt(g_team) == 0) {
			PrintToConsole(client, "Allowed Team: Both");
		} else if (GetConVarInt(g_team) == 1) {
			PrintToConsole(client, "Allowed Team: RED");
		} else if (GetConVarInt(g_team) == 2) {
			PrintToConsole(client, "Allowed Team: BLU");
		}
		if(GetConVarBool(g_adminOnly)) {
			PrintToConsole(client, "Admins only: YES");
		} else {
			PrintToConsole(client, "Admins only: NO");
		}
		PrintToConsole(client, "Recharge Delay: %i seconds", GetConVarInt(g_rechargeDelay));
		PrintToConsole(client, "Required Übercharge: %i%", RoundFloat(GetConVarFloat(g_requiredCharge) * 100));
	}
	return Plugin_Handled;
}

/* WeaponSwitch
 * Category: SDKHook Action
 * 
 * Checks if the medic switches away from his Medigun
 * 
*/
public Action:Hook_WeaponSwitch(client, weapon) {
	if(TF2_GetPlayerClass(client) != TFClass_Medic) {
		return Plugin_Continue;
	}
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if(!StrEqual(sWeapon, "tf_weapon_medigun")) {
		deleteShield(client);
	}
	return Plugin_Continue;
}

/* Delay Timer Callback
 * Category: Timer Callback
 * 
 * End the Shield Cooldown Time
 * 
*/
public Action:Timer_Delay(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}
	g_onTimeRecharge[client] = false;
	if (delayTimer[client] != INVALID_HANDLE) {
		KillTimer(delayTimer[client]);
		delayTimer[client] = INVALID_HANDLE;
	}
}

/* Announce Shield Ready
 * Category: Timer Callback
 * 
 * Tell the player that his shield can be activated again
 * 
*/
public Action:AnnounceReadyShield(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client == 0) {
		return Plugin_Continue;
	}
	if (!GetConVarBool(g_pluginEnabled)) {
		return Plugin_Continue;
	}
	new Action:result = Plugin_Continue;
	Call_StartForward(forward_shieldReady);
	Call_PushCell(client);
	Call_Finish(result);
	
	if (result == Plugin_Handled || result == Plugin_Stop) {
		return Plugin_Continue;
	}
	if(GetConVarBool(g_adminOnly)) {
		if(hasAdminPermission(client)) {
			if (CheckReadyShield(client) && !announced[client]) {
				announced[client] = true;
				PrintCenterText(client, "Your Medic Shield is ready");
			}
		}
	} else {
		if (CheckReadyShield(client) && !announced[client]) {
			announced[client] = true;
			PrintCenterText(client, "Your Medic Shield is ready");
		}
	}
	return Plugin_Continue;
}

/* Validate client
 * Category: Self-defined function
 * 
 * Check if the client is a valid player
 * 
*/
stock bool:IsValidClient(client, bool:replay = true) {
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}

/* Begin Recharge
 * Category: Self-defined function
 * 
 * Set Recharge delay time so you can't spawn another shield for x seconds
 * 
*/
public Delay(client) {
	g_onTimeRecharge[client] = true;
	delayTimer[client] = CreateTimer(GetConVarFloat(g_rechargeDelay) + 10.0, Timer_Delay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

/* Ready State Check
 * Category: Self-defined function
 * 
 * Check if the conditions are met to activate the shield again
 * 
*/
public bool:CheckReadyShield(client) {
	if (GetConVarBool(g_disableRecharge)) {
		return true;
	}
	if (IsValidEntity(g_entCurrentShield[client])) {
		return false;
	}
	if (GetConVarBool(g_rechargeMode)) {
		if (TF2_GetUberLevel(client) < GetConVarFloat(g_requiredCharge)) {
			return false;
		}
	} else {
		if (g_onTimeRecharge[client]) {
			return false;
		}
	}
	return true;
}

/* Get Uberlevel
 * Category: Self-defined function
 * 
 * Get the Player's current Uberlevel
 * 
*/
stock Float:TF2_GetUberLevel(client) {
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0) {
		decl String:class[64];
		GetEdictClassname(index, class, sizeof(class));
		if(strncmp(class, "tf_weapon_medigun", 17) == 0) {
			return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel");
		} else {
			return 0.0;
		}
    } else {
        return 0.0;
	}
}

/* Set Uberlevel
 * Category: Self-defined function
 * 
 * Set the Player's current Uberlevel
 * 
*/
stock TF2_SetUberLevel(client, Float:uberlevel) {
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0) {
		decl String:class[64];
		GetEdictClassname(index, class, sizeof(class));
		if(strncmp(class, "tf_weapon_medigun", 17) == 0) {
			SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
		}
	}
}

/* Kill Shields
 * Category: Self-defined function
 * 
 * Delete an existing shield and the delay timer
 * 
*/
public bool:deleteShield(client) {
	if (IsValidEntity(g_entCurrentShield[client])) {
		AcceptEntityInput(g_entCurrentShield[client], "Kill");
		g_entCurrentShield[client] = INVALID_ENT_REFERENCE;
	}
}

/* Check Admin Permission
 * Category: Self-defined function
 * 
 * Checks if the client has Admin Permissions
 * 
*/
public bool:hasAdminPermission(client) {
	if(permissionssm) { return PsmHasPermission(client, "%s.admin", PERMISSIONNODE_BASE); }
	return CheckCommandAccess(client, "medicshield_admin", ADMFLAG_GENERIC, true);
}

/* Category Display Text
 * Category: Self-defined function
 * 
 * This function returns the correct text for the admin menu
 * to show in both the main menu and the MedicShield Submenu
 * 
*/
public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "%s:", PLUGIN_NAME);
	} else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, PLUGIN_NAME);
	}
}

/* Fill Sub-Menu
 * Category: Self-defined function
 * 
 * Fills the MedicShield Sub-Menu with the respective entries 
 * 
*/
public AttachAdminMenu() {
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 
	if (player_commands == INVALID_TOPMENUOBJECT) {
		return;
	}
 
	AddToTopMenu(hAdminMenu, "medicshield_disable_recharged", TopMenuObject_Item, AdminMenu_DisableRecharge, obj_mscommands, "medicshield_disable_recharged",	ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_recharge_mode", TopMenuObject_Item, AdminMenu_RechargeMode, obj_mscommands, "medicshield_recharge_mode",	ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_admin_only", TopMenuObject_Item, AdminMenu_AdminOnly, obj_mscommands, "medicshield_admin_only",	ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_recharge_delay", TopMenuObject_Item, AdminMenu_TimeDelay, obj_mscommands, "medicshield_recharge_delay",	ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_required_charge", TopMenuObject_Item, AdminMenu_RequiredCharge, obj_mscommands, "medicshield_required_charge",	ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_shield", TopMenuObject_Item, AdminMenu_DeployShield, obj_mscommands, "medicshield_shield",	ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_info", TopMenuObject_Item, AdminMenu_PrintInfo, obj_mscommands, "medicshield_info", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_recharge_on_death", TopMenuObject_Item, AdminMenu_DeathRecharge, obj_mscommands, "medicshield_recharge_on_death", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_enable_plugin", TopMenuObject_Item, AdminMenu_PluginEnabled, obj_mscommands, "medicshield_enable_plugin", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "medicshield_team", TopMenuObject_Item, AdminMenu_DropForOneTeam, obj_mscommands, "medicshield_team", ADMFLAG_SLAY);
}

/* Show Info Admin-Menu
 * Category: AdminMenu Item
 * 
 * Show Plugin Info to User
 * 
*/
public AdminMenu_PrintInfo(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Get Plugin&Config Info");
	} else if (action == TopMenuAction_SelectOption) {
		PrintPluginInfo(param, -5);
	}
}

/* Change Recharge Mode Admin-Menu
 * Category: AdminMenu Item
 * 
 * Set the Cooldown Mode of the Plugin
 * 
*/
public AdminMenu_RechargeMode(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Change Recharge Mode");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_RechargeMode(param,topmenu);
	}
}
DisplayMenu_RechargeMode(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_RechargeMode);
	SetMenuTitle(menu, "Recharge Mode");
	AddMenuItem(menu, "0", "Time based recharge");
	AddMenuItem(menu, "1", "Übercharge based reload");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_RechargeMode(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_rechargeMode, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Enable Plugin Admin-Menu
 * Category: AdminMenu Item
 * 
 * Enable or disable Plugin
 * 
*/
public AdminMenu_PluginEnabled(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Enable or disable Plugin");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_PluginEnabled(param,topmenu);
	}
}
DisplayMenu_PluginEnabled(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_PluginEnabled);
	SetMenuTitle(menu, "Enable Plugin");
	AddMenuItem(menu, "1", "ENABLE");
	AddMenuItem(menu, "0", "DISABLE");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_PluginEnabled(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_pluginEnabled, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Disable Recharge Admin-Menu
 * Category: AdminMenu Item
 * 
 * Disable or Enable Cooldown
 * 
*/
public AdminMenu_DisableRecharge(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Shield must recharge");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DisableRecharge(param,topmenu);
	}
}
DisplayMenu_DisableRecharge(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_DisableRecharge);
	SetMenuTitle(menu, "Disable Recharge");
	AddMenuItem(menu, "0", "Recharge enabled");
	AddMenuItem(menu, "1", "Recharge disabled");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DisableRecharge(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_disableRecharge, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Admin-Only Admin-Menu
 * Category: AdminMenu Item
 * 
 * Enable or disable Admin-Only Mode
 * 
*/
public AdminMenu_AdminOnly(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength){
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Admin-Only usage");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_AdminOnly(param,topmenu);
	}
}
DisplayMenu_AdminOnly(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_AdminOnly);
	SetMenuTitle(menu, "Who can use the shield?");
	AddMenuItem(menu, "0", "Everyone");
	AddMenuItem(menu, "1", "Only Admins");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_AdminOnly(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_adminOnly, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Recharge on Death Admin-Menu
 * Category: AdminMenu Item
 * 
 * Change Time-based cooldown behaviour on death
 * 
*/
public AdminMenu_DeathRecharge(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength){
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Recharge on Death");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DeathRecharge(param,topmenu);
	}
}
DisplayMenu_DeathRecharge(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_DeathRecharge);
	SetMenuTitle(menu, "Recharge shield on death (time-delay = 0)");
	AddMenuItem(menu, "0", "Off");
	AddMenuItem(menu, "1", "On");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DeathRecharge(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_rechargeOnDeath, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Cooldown Time Admin-Menu
 * Category: AdminMenu Item
 * 
 * Set cooldown time
 * 
*/
public AdminMenu_TimeDelay(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Time to recharge");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_TimeDelay(param,topmenu);
	}
}
DisplayMenu_TimeDelay(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_TimeDelay);
	SetMenuTitle(menu, "Recharge Delay in Seconds");
	AddMenuItem(menu, "0", "0");
	AddMenuItem(menu, "1", "1");
	AddMenuItem(menu, "2", "2");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10");
	AddMenuItem(menu, "20", "20");
	AddMenuItem(menu, "30", "30");
	AddMenuItem(menu, "40", "40");
	AddMenuItem(menu, "50", "50");
	AddMenuItem(menu, "60", "60");
	AddMenuItem(menu, "90", "90");
	AddMenuItem(menu, "120", "120");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_TimeDelay(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_rechargeDelay, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Required Charge Admin-Menu
 * Category: AdminMenu Item
 * 
 * How much charge do you need to deploy the shield
 * 
*/
public AdminMenu_RequiredCharge(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Required Charge to deploy shield");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_RequiredCharge(param,topmenu);
	}
}
DisplayMenu_RequiredCharge(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_RequiredCharge);
	SetMenuTitle(menu, "Required Charge");
	AddMenuItem(menu, "0.0", "  0%");
	AddMenuItem(menu, "0.10", " 10%");
	AddMenuItem(menu, "0.20", " 20%");
	AddMenuItem(menu, "0.25", " 25%");
	AddMenuItem(menu, "0.30", " 30%");
	AddMenuItem(menu, "0.40", " 40%");
	AddMenuItem(menu, "0.50", " 50%");
	AddMenuItem(menu, "0.60", " 60%");
	AddMenuItem(menu, "0.70", " 70%");
	AddMenuItem(menu, "0.75", " 75%");
	AddMenuItem(menu, "0.80", " 80%");
	AddMenuItem(menu, "0.90", " 90%");
	AddMenuItem(menu, "1.00", "100%");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_RequiredCharge(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarFloat(g_requiredCharge, StringToFloat(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Deploy Admin-Menu
 * Category: AdminMenu Item
 * 
 * Use Menu to deploy shield
 * 
*/
public AdminMenu_DeployShield(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Deploy Shield");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DeployShield(param,topmenu);
	}
}
DisplayMenu_DeployShield(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_DeployShield);
	SetMenuTitle(menu, "Select Shield to deploy");
	AddMenuItem(menu, "1", "Shield Level 1");
	AddMenuItem(menu, "2", "Shield Level 2");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DeployShield(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new CompareInt = StringToInt(info);
		if(CompareInt == 1) {
			Command_Shield(param1, param2);
		} else {
			Command_Shield2(param1, param2);
		}
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Drop for one team only
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the MedicMvMShield Sub-Menu
 * 
*/
public AdminMenu_DropForOneTeam(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Drop for one team only");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DropForOneTeam(param,topmenu);
	}
}
DisplayMenu_DropForOneTeam(client, Handle:topmenu) {
	tmpTopMenuHandle = topmenu;
	new Handle:menu = CreateMenu(MenuHandler_DropForOneTeam);
	SetMenuTitle(menu, "Drop for which team?");
	AddMenuItem(menu, "0", "Both");
	AddMenuItem(menu, "1", "RED");
	AddMenuItem(menu, "2", "BLU");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DropForOneTeam(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_team, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}