/* Copyright
 * Category: None
 * 
 * PermissionsSM 1.0.1 by Wolvan
 * Contact: wolvan1@gmail.com
 * 
*/

/* Includes
 * Category: Preprocessor
 *  
 * Includes the necessary SourceMod modules
 * 
*/
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "PermissionsSM"
#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Node-based Permission-Management"
#define PLUGIN_URL "NULL"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.PermissionsSM.cfg"
#define PLUGIN_DATA_STORAGE "PermissionsSM"
#define PERMISSIONNODE_BASE "PermissionsSM"

/* Permission Return Values
 * Category: Preprocessor
 * 
 * Define Values that find permission functions can return
 * 
*/
#define CloneHandleError -4
#define NoSubGroup -3
#define PermissionNotFound -2
#define TargetNotFound -1
#define NotHasPermission 0
#define HasPermission 1

/* Variable creation
 * Category: Storage
 *  
 * Create required Storage Variables for the Plugin
 * 
*/
new Handle:ConfigKV = INVALID_HANDLE;
new Handle:UsersKV = INVALID_HANDLE;
new Handle:GroupsKV = INVALID_HANDLE;
new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:tmpTopMenuHandle = INVALID_HANDLE;
new TopMenuObject:obj_psmcommands;

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
 * Register natives and library
 * 
*/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	
	RegPluginLibrary("permissionssm");
	
	CreateNative("PsmHasPermission", Native_hasPermission);
	CreateNative("PsmCanTarget", Native_canTarget);
	
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
	// load translations
	LoadTranslations("common.phrases");
	
	// load Data Storage
	ConfigKV = CreateKeyValues("Config");
	UsersKV = CreateKeyValues("Users");
	GroupsKV = CreateKeyValues("Groups");
	decl String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Config.txt", PLUGIN_DATA_STORAGE);
	FileToKeyValues(ConfigKV, filename);
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Users.txt", PLUGIN_DATA_STORAGE);
	FileToKeyValues(UsersKV, filename);
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Groups.txt", PLUGIN_DATA_STORAGE);
	FileToKeyValues(GroupsKV, filename);
	
	// register console commands
	RegConsoleCmd("permissionssm", Command_PermissionsSM, "Permissions SM Base Command.");
	RegConsoleCmd("sm_permissionssm", Command_PermissionsSM, "Permissions SM Base Command.");
	RegConsoleCmd("psm", Command_PermissionsSM, "Alias for permissionssm.");
	RegConsoleCmd("sm_psm", Command_PermissionsSM, "Alias for permissionssm.");
	
	// load Config File
	if (FindConVar("permissionssm_version") == INVALID_HANDLE) { AutoExecConfig(true); }
	
	CreateConVar("permissionssm_version", PLUGIN_VERSION, "PermissionsSM Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// check if AdminMenu is already there
	/*new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}*/
}

/* Plugin ends
 * Category: Plugin Callback
 *  
 * Close KeyValues Handles
 * 
*/
public OnPluginEnd() {
	if(ConfigKV != INVALID_HANDLE) {
		CloseHandle(ConfigKV);
		ConfigKV = INVALID_HANDLE;
	}
	if(UsersKV != INVALID_HANDLE) {
		CloseHandle(UsersKV);
		UsersKV = INVALID_HANDLE;
	}
	if(GroupsKV != INVALID_HANDLE) {
		CloseHandle(GroupsKV);
		GroupsKV = INVALID_HANDLE;
	}
}

/* PermissionsSM Command
 * Category: Console Command
 * 
 * Use every command PermissionSM has to offer
 * 
*/
public Action:Command_PermissionsSM(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "[PSM] Missing arguments, use <psm help> for commands");
		return Plugin_Handled;
	}
	decl String:arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));
	if(!hasPermission(client, "%s.admin", PERMISSIONNODE_BASE)) {
		if (!hasPermission(client, "%s.%s", PERMISSIONNODE_BASE, arg1)) {
			ReplyToCommand(client, "[PSM] You don't have access to this command!");
			return Plugin_Handled;
		}
	}
	if (StrEqual(arg1, "", false)) {
		ReplyToCommand(client, "[PSM] Missing arguments, use <psm help> for commands");
		return Plugin_Handled;
	} else if (StrEqual(arg1, "help", false)) {
		ReplyToCommand(client, "[PSM] PSM Arguments:\npsm help	-	Show help\npsm user	-	Modify User\npsm group	-	Modify Group\npsm reload	-	Reload Config, Users and Groups\npsm test <User> <Permission>	-	Check if User has Permission Node directly or via Groups");
		return Plugin_Handled;
	} else if (StrEqual(arg1, "user", false)) {
		if (args < 2) {
			ReplyToCommand(client, "[PSM] Missing arguments, use <psm user help> for commands");
			return Plugin_Handled;
		}
		decl String:arg2[512];
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StrEqual(arg2, "help", false)) {
			ReplyToCommand(client, "[PSM] PSM User Arguments:");
			ReplyToCommand(client, "[PSM] user addgroup <User> <Groupname> [-negate/-n] - Adds User to the specified Group");
			ReplyToCommand(client, "[PSM] user delgroup <User> <Groupname>	- Remove User from the specified Group");
			ReplyToCommand(client, "[PSM] user addperm <User> <Permission> [-negate/-n] - Give User specified Permission Node");
			ReplyToCommand(client, "[PSM] user delperm <User> <Permission>	- Remove Permission Node from User");
			ReplyToCommand(client, "[PSM] user prefix <User> [Prefix]	- Set User Prefix or remove it");
			ReplyToCommand(client, "[PSM] user suffix <User> [suffix]	- Set User Suffix or remove it");
			ReplyToCommand(client, "[PSM] user immunity <User> <Immunity>	- Set User Immunity Value");
		} else if (StrEqual(arg2, "addgroup", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user addgroup <User> <Group>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			decl String:arg5[512];
			GetCmdArg(5, arg5, sizeof(arg5));
			
			new bool:negated = false;
			if(StrEqual(arg5, "-n", false) || StrEqual(arg5, "-negated", false)) {
				negated = true;
			}
			
			if (!GroupExists(arg4)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					AddUserGroup(target_list[i], arg4, negated);
				}
			}
			ReplyToCommand(client, "[PSM] Added %i Player(s) to Group %s", target_count, arg4);
		} else if (StrEqual(arg2, "delgroup", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user delgroup <User> <Group>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			
			if (!GroupExists(arg4)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					DelUserGroup(target_list[i], arg4);
				}
			}
			ReplyToCommand(client, "[PSM] Removed %i Player(s) from Group %s", target_count, arg4);
		} else if (StrEqual(arg2, "addperm", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user addperm <User> <Permission>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			decl String:arg5[512];
			GetCmdArg(5, arg5, sizeof(arg5));
			
			new bool:negated = false;
			if(StrEqual(arg5, "-n", false) || StrEqual(arg5, "-negated", false)) {
				negated = true;
			}
			
			if (StrEqual(arg4, "", false)) {
				ReplyToCommand(client, "[PSM] No Permission specified");
				return Plugin_Handled;
			}
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					AddUserPerm(target_list[i], arg4, negated);
				}
			}
			ReplyToCommand(client, "[PSM] Added Permission %s to %i Player(s)", arg4, target_count);
		} else if (StrEqual(arg2, "delperm", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user delperm <User> <Permission>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			
			if (StrEqual(arg4, "", false)) {
				ReplyToCommand(client, "[PSM] Permission not specified");
				return Plugin_Handled;
			}
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					DelUserPerm(target_list[i], arg4);
				}
			}
			ReplyToCommand(client, "[PSM] Removed Permission %s from %i Player(s)", arg4, target_count);
		} else if (StrEqual(arg2, "prefix", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user prefix <User> [Prefix]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					SetUserPrefix(target_list[i], arg4);
				}
			}
			ReplyToCommand(client, "[PSM] Set Prefix to %s for %i Player(s)", arg4, target_count);
		} else if (StrEqual(arg2, "suffix", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user prefix <User> [Prefix]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					SetUserSuffix(target_list[i], arg4);
				}
			}
			ReplyToCommand(client, "[PSM] Set Suffix to %s for %i Player(s)", arg4, target_count);
		} else if (StrEqual(arg2, "immunity", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing arguments, use <psm user prefix <User> [Prefix]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			decl String:arg4[512];
			GetCmdArg(4, arg4, sizeof(arg4));
			
			new immunity = 1;
			if (!StrEqual(arg4, "", false)) {
				immunity = StringToInt(arg4);
			}
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString( arg3, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, target_count);
				if (client != 0) {
					PrintToChat(client, "[PSM] No targets found. Check console for more Information");
				}
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++) {
				if(canTarget(client, target_list[i])) {
					SetUserImmunity(target_list[i], immunity);
				}
			}
			ReplyToCommand(client, "[PSM] Set Immunity to %i for %i Player(s)", immunity, target_count);
		} else {
			ReplyToCommand(client, "[PSM] Unknown argument, use <psm user help> for commands");
			return Plugin_Handled;
		}
		return Plugin_Handled;
	} else if (StrEqual(arg1, "group", false)) {
		if (args < 2) {
			ReplyToCommand(client, "[PSM] Missing arguments, use <psm group help> for commands");
			return Plugin_Handled;
		}
		decl String:arg2[512];
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StrEqual(arg2, "help", false)) {
			ReplyToCommand(client, "[PSM] PSM Group Arguments:");
			ReplyToCommand(client, "[PSM] group add <Group> <Parent> - Adds new Group");
			ReplyToCommand(client, "[PSM] group del <Group> <Parent> - Removes Group");
			ReplyToCommand(client, "[PSM] group addinherit <Group> <Parent> [-negate/-n] - Adds inheritance to the specified Group");
			ReplyToCommand(client, "[PSM] group delinherit <Group> <Parent> - Remove inheritance from the specified Group");
			ReplyToCommand(client, "[PSM] group addperm <Group> <Permission> [-negate/-n] - Give Group specified Permission Node");
			ReplyToCommand(client, "[PSM] group delperm <Group> <Permission> - Remove Permission Node from Group");
			ReplyToCommand(client, "[PSM] group prefix <Group> [Prefix] - Set Group Prefix or remove it");
			ReplyToCommand(client, "[PSM] group suffix <Group> [suffix] - Set Group Suffix or remove it");
			ReplyToCommand(client, "[PSM] group immunity <Group> <Immunity> - Set Group Immunity Value");
			ReplyToCommand(client, "[PSM] group default <Group> - Set Group as default group");
			ReplyToCommand(client, "[PSM] group list - List all Groups");
		} else if (StrEqual(arg2, "list", false)) {
			ListGroups(client);
		} else if (StrEqual(arg2, "add", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group add <Groupname>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			if(GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group already exists");
				return Plugin_Handled;
			}
			CreateGroup(arg3);
			ReplyToCommand(client, "[PSM] Group created");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "del", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group del <Groupname>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			DeleteGroup(arg3);
			ReplyToCommand(client, "[PSM] Group deleted");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "addinherit", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group addinherit <Group> <Parent> [-negated/-n]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			decl String:arg5[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			GetCmdArg(5, arg5, sizeof(arg5));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			if(!GroupExists(arg4)) {
				ReplyToCommand(client, "[PSM] Parent Group doesn't exist");
				return Plugin_Handled;
			}
			if(StrEqual(arg3, arg4, false)) {
				ReplyToCommand(client, "[PSM] Can't inherit itself");
				return Plugin_Handled;
			}
			new bool:negated = false;
			if(StrEqual(arg5, "-n", false) || StrEqual(arg5, "-negated", false)) {
				negated = true;
			}
			AddInherit(arg3, arg4, negated);
			if (negated) {
				ReplyToCommand(client, "[PSM] Added Group %s as negated parent of Group %s");
				return Plugin_Handled;
			}
			ReplyToCommand(client, "[PSM] Added Group %s as parent of Group %s");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "delinherit", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group delinherit <Group> <Parent>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			if(!GroupExists(arg4)) {
				ReplyToCommand(client, "[PSM] Parent Group doesn't exist");
				return Plugin_Handled;
			}
			DelInherit(arg3, arg4);
			ReplyToCommand(client, "[PSM] Deleted Group %s as parent from Group %s");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "addperm", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group addperm <Group> <Permission> [-negated/-n]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			decl String:arg5[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			GetCmdArg(5, arg5, sizeof(arg5));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			if(StrEqual(arg4, "", false)) {
				ReplyToCommand(client, "[PSM] No Permission specified");
				return Plugin_Handled;
			}
			new bool:negated = false;
			if(StrEqual(arg5, "-n", false) || StrEqual(arg5, "-negated", false)) {
				negated = true;
			}
			AddGroupPerm(arg3, arg4, negated);
			if (negated) {
				ReplyToCommand(client, "[PSM] Added Permission %s as negated Permission to Group %s");
				return Plugin_Handled;
			}
			ReplyToCommand(client, "[PSM] Added Permission %s to Group %s");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "delperm", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group delperm <Group> <Permission>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			if(StrEqual(arg4, "", false)) {
				ReplyToCommand(client, "[PSM] Permission not specified");
				return Plugin_Handled;
			}
			DelGroupPerm(arg3, arg4);
			ReplyToCommand(client, "[PSM] Removed Permission %s from Group %s");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "prefix", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group prefix <Group> [Prefix]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			SetGroupPrefix(arg3, arg4);
			if (StrEqual(arg4, "", false)) {
				ReplyToCommand(client, "[PSM] Removed Prefix for Group %s");
			} else {
				ReplyToCommand(client, "[PSM] Set Prefix to %s for Group %s");
			}
			return Plugin_Handled;
		} else if (StrEqual(arg2, "suffix", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group suffix <Group> [Suffix]>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			SetGroupSuffix(arg3, arg4);
			if (StrEqual(arg4, "", false)) {
				ReplyToCommand(client, "[PSM] Removed Suffix for Group %s");
			} else {
				ReplyToCommand(client, "[PSM] Set Suffix to %s for Group %s");
			}
			return Plugin_Handled;
		} else if (StrEqual(arg2, "immunity", false)) {
			if (args < 4) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group immunity <Group> <Immunity>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			decl String:arg4[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			GetCmdArg(4, arg4, sizeof(arg4));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			new immunity = StringToInt(arg4);
			SetGroupImmunity(arg3, immunity);
			ReplyToCommand(client, "[PSM] Set immunity of Group %s to %i");
			return Plugin_Handled;
		} else if (StrEqual(arg2, "default", false)) {
			if (args < 3) {
				ReplyToCommand(client, "[PSM] Missing argument, use <psm group default <Group>>");
				return Plugin_Handled;
			}
			decl String:arg3[512];
			GetCmdArg(3, arg3, sizeof(arg3));
			if(!GroupExists(arg3)) {
				ReplyToCommand(client, "[PSM] Group doesn't exist");
				return Plugin_Handled;
			}
			SetDefaultGroup(arg3);
			ReplyToCommand(client, "[PSM] Set default Group to %s");
			return Plugin_Handled;
		} else {
			ReplyToCommand(client, "[PSM] Unknown argument, use <psm group helpParentor commands");
			return Plugin_Handled;
		}
	} else if (StrEqual(arg1, "reload", false)) {
		reloadConfigs(client);
		return Plugin_Handled;
	} else if (StrEqual(arg1, "test", false)) {
		if (args < 3) {
			ReplyToCommand(client, "[PSM] Missing arguments, use <psm test <User> <Permission>>");
			return Plugin_Handled;
		}
		
		decl String:arg2[512];
		GetCmdArg(2, arg2, sizeof(arg2));
		decl String:arg3[512];
		GetCmdArg(3, arg3, sizeof(arg3));
		
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString( arg2, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			if (client != 0) {
				PrintToChat(client, "[PSM] No targets found. Check console for more Information");
			}
			return Plugin_Handled;
		}
		decl String:nbuffer[512];
		for (new i = 0; i < target_count; i++) {
			GetClientName(target_list[i], nbuffer, sizeof(nbuffer));
			if(hasPermission(target_list[i], arg3)) {
				ReplyToCommand(client, "[PSM] User %s HAS Permission %s!", nbuffer, arg3);
			} else{
				ReplyToCommand(client, "[PSM] User %s DOES NOT HAVE Permission %s!", nbuffer, arg3);
			}
		}
		return Plugin_Handled;
	} else {
		ReplyToCommand(client, "[PSM] Unknown argument, use <psm help> for commands");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

/* Immunity check
 * Category: Self-defined Function
 *
 * TODO: Add Group Immunity check if client immunity check failed
 *
 * Compares 2 immunities
 * 
*/
public bool:canTarget(client, target) {
	if (target == 0) { return false; }
	if (client == 0) { return true; }
	if (client == target) { return true; }
	return (getClientImmunity(client) > getClientImmunity(target));
}

/* Client Immunity
 * Category: Self-defined Function
 * 
 * Get client immunity
 * 
*/
getClientImmunity(client, defaultImmunity = 0) {
	KvRewind(UsersKV);
	new Handle:tmpHandle = CloneHandle(UsersKV);
	if (tmpHandle == INVALID_HANDLE) { LogError("An Error occured while cloning the UserKV Handle."); return 0; }
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	if (!KvJumpToKey(tmpHandle, AuthString)) {
		CloseHandle(tmpHandle);
		return defaultImmunity;
	}
	if (KvJumpToKey(tmpHandle, "Options")) {
		decl String:ImmunityString[512];
		KvGetString(tmpHandle, "immunity", ImmunityString, sizeof(ImmunityString));
		if (StrEqual(ImmunityString, "", false)) {
			CloseHandle(tmpHandle);
			return defaultImmunity;
		}
		CloseHandle(tmpHandle);
		return StringToInt(ImmunityString);
	} else {
		CloseHandle(tmpHandle);
		return defaultImmunity;
	}
}

/* Check Permission String
 * Category: Self-defined Function
 *  
 * Checks if User has required Permission Node
 * 
*/
public bool:hasPermission(client, String:PString[], any:...) {
	decl String:PermissionString[8192];
	VFormat(PermissionString, sizeof(PermissionString), PString, 3);
	KvRewind(UsersKV);
	new Handle:tmpHandle = CloneHandle(UsersKV);
	if (tmpHandle == INVALID_HANDLE) { LogError("An Error occured while cloning the UserKV Handle."); return false; }
	if (client == 0) { return true; }
	new clientPermissions = hasClientPermission(client, PermissionString);
	if (clientPermissions == HasPermission) {
		CloseHandle(tmpHandle);
		return true;
	} else if (clientPermissions == NotHasPermission || clientPermissions == TargetNotFound) {
		CloseHandle(tmpHandle);
		return false;
	}
	KvRewind(tmpHandle);
	decl String:steamid[512];
	GetClientAuthString(client, steamid, sizeof(steamid));
	if (!KvJumpToKey(tmpHandle, steamid)) {
		decl String:dflt[512];
		new dfltPerm;
		if(!GetDefaultGroup(dflt, sizeof(dflt))) {
			CloseHandle(tmpHandle);
			return false;
		}
		dfltPerm = hasGroupPermission(dflt, PermissionString);
		CloseHandle(tmpHandle);
		if (dfltPerm == HasPermission) {
			return true;
		}
		return false;
	}
	if (KvJumpToKey(tmpHandle, "Groups")) {
		if (!KvGotoFirstSubKey(tmpHandle, false)) {
			decl String:dflt[512];
			new dfltPerm;
			if(!GetDefaultGroup(dflt, sizeof(dflt))) {
				CloseHandle(tmpHandle);
				return false;
			}
			dfltPerm = hasGroupPermission(dflt, PermissionString);
			CloseHandle(tmpHandle);
			if (dfltPerm == HasPermission) {
				return true;
			}
			return false;
		}
		decl String:buffer[255];
		new String:Negated[] = "false"; 
		new PermissionState;
		do {
			KvGetSectionName(tmpHandle, buffer, sizeof(buffer));
			PermissionState = hasGroupPermission(buffer, PermissionString);
			KvGetString(tmpHandle, NULL_STRING, Negated, sizeof(Negated));
			if (PermissionState == HasPermission) {
				CloseHandle(tmpHandle);
				if (!StringToBool(Negated)) { return false; }
				return true;
			} else if (PermissionState == NotHasPermission) {
				CloseHandle(tmpHandle);
				if (!StringToBool(Negated)) { return false; }
				return false;
			}
		} while (KvGotoNextKey(tmpHandle, false));
	} else {
		decl String:dflt[512];
		new dfltPerm;
		if(!GetDefaultGroup(dflt, sizeof(dflt))) {
			CloseHandle(tmpHandle);
			return false;
		}
		dfltPerm = hasGroupPermission(dflt, PermissionString);
		CloseHandle(tmpHandle);
		if (dfltPerm == HasPermission) {
			return true;
		}
		return false;
	}
	CloseHandle(tmpHandle);
	return false;
}

/* Check Client Permission String
 * Category: Self-defined Function
 *  
 * Checks if Client has required Permission Node
 * 
*/
hasClientPermission(client, String:PermissionString[]) {
	KvRewind(UsersKV);
	new Handle:tmpHandle = CloneHandle(UsersKV);
	if (tmpHandle == INVALID_HANDLE) { LogError("An Error occured while cloning the UserKV Handle."); return CloneHandleError; }
	decl String:steamid[512];
	GetClientAuthString(client, steamid, sizeof(steamid));
	if (!KvJumpToKey(tmpHandle, steamid)) {
		CloseHandle(tmpHandle);
		return TargetNotFound;
	}
	if (KvJumpToKey(tmpHandle, "Permissions")) {
		decl String:PermissionNode[] = "false";
		KvGetString(tmpHandle, PermissionString, PermissionNode, sizeof(PermissionNode));
		CloseHandle(tmpHandle);
		if (StrEqual(PermissionNode, "", false)) {
			return PermissionNotFound;
		}
		if (StringToBool(PermissionNode)) {
			return HasPermission;
		} else {
			return NotHasPermission;
		}
	} else {
		CloseHandle(tmpHandle);
		return PermissionNotFound;
	}
}

/* Check Group Permission String
 * Category: Self-defined Function
 * 
 * Checks if Group has required Permission Node
 * 
*/
hasGroupPermission(String:Group[], String:PermissionString[]) {
	KvRewind(GroupsKV);
	new Handle:tmpHandle = CloneHandle(GroupsKV);
	if (tmpHandle == INVALID_HANDLE) { LogError("An Error occured while cloning the GroupsKV Handle."); return CloneHandleError; }
	if (!KvJumpToKey(tmpHandle, Group)) {
		CloseHandle(tmpHandle);
		return TargetNotFound;
	}
	if (KvJumpToKey(tmpHandle, "Permissions")) {
		decl String:PermissionNode[] = "false";
		KvGetString(tmpHandle, PermissionString, PermissionNode, sizeof(PermissionNode));
		KvGoBack(tmpHandle);
		if (!StrEqual(PermissionNode, "", false)) {
			CloseHandle(tmpHandle);
			if (StringToBool(PermissionNode)) {
				return HasPermission;
			} else {
				return NotHasPermission;
			}
		}
		if (KvJumpToKey(tmpHandle, "Inheritance")) {
			if (!KvGotoFirstSubKey(tmpHandle, false)) {
				CloseHandle(tmpHandle);
				return NoSubGroup;
			}
			decl String:buffer[255];
			new String:Negated[] = "false";
			new PermissionState;
			do {
				KvGetSectionName(tmpHandle, buffer, sizeof(buffer));
				PermissionState = hasGroupPermission(buffer, PermissionString);
				KvGetString(tmpHandle, NULL_STRING, Negated, sizeof(Negated));
				if (PermissionState == HasPermission) {
					CloseHandle(tmpHandle);
					if (!StringToBool(Negated)) { return NotHasPermission; }
					return HasPermission;
				} else if (PermissionState == NotHasPermission) {
					CloseHandle(tmpHandle);
					if (!StringToBool(Negated)) { return HasPermission; }
					return NotHasPermission;
				}
			} while (KvGotoNextKey(tmpHandle, false));
		} else {
			CloseHandle(tmpHandle);
			return TargetNotFound;
		}
	}
	CloseHandle(tmpHandle);
	return PermissionNotFound;
}

/* Reload Configs
 * Category: Self-defined Function
 * 
 * Reloads the Groups, Users and Config File
 * 
*/
reloadConfigs(client = 0) {
	if(ConfigKV != INVALID_HANDLE) {
		CloseHandle(ConfigKV);
		ConfigKV = INVALID_HANDLE;
	}
	if(UsersKV != INVALID_HANDLE) {
		CloseHandle(UsersKV);
		UsersKV = INVALID_HANDLE;
	}
	if(GroupsKV != INVALID_HANDLE) {
		CloseHandle(GroupsKV);
		GroupsKV = INVALID_HANDLE;
	}
	ConfigKV = CreateKeyValues("Config");
	UsersKV = CreateKeyValues("Users");
	GroupsKV = CreateKeyValues("Groups");
	decl String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Config.txt", PLUGIN_DATA_STORAGE);
	FileToKeyValues(ConfigKV, filename);
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Users.txt", PLUGIN_DATA_STORAGE);
	FileToKeyValues(UsersKV, filename);
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Groups.txt", PLUGIN_DATA_STORAGE);
	FileToKeyValues(GroupsKV, filename);
	
	PrintToServer("[PSM] Configs reloaded");
	if (client > 0) {
		PrintToChat(client, "[PSM] Configs reloaded");
	}
}

/* String To Bool Conversion
 * Category: Self-defined function
 * 
 * Converts the Strings "true" and "false" to actual boolean values
 * 
*/
bool:StringToBool(String:BoolString[]) {
	if (StrEqual(BoolString, "true", false)) { return true; } else { return false; }
}

/* Group Exists
 * Category: Self-defined function
 * 
 * Check if Group exists
 * 
*/
bool:GroupExists(String:Groupname[]) {
	KvRewind(GroupsKV);
	new Handle:tmpHandle = CloneHandle(GroupsKV);
	if (tmpHandle == INVALID_HANDLE) { LogError("An Error occured while cloning the GroupsKV Handle."); return false; }
	if (KvJumpToKey(tmpHandle, Groupname)) {
		CloseHandle(tmpHandle);
		return true;
	} else {
		CloseHandle(tmpHandle);
		return false;
	}
}

/* Create Group
 * Category: Self-defined function
 * 
 * Create a Group
 * 
*/
bool:CreateGroup(String:Groupname[]) {
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname, true);
	KvJumpToKey(GroupsKV, "Options", true);
	KvSetString(GroupsKV, "default", "false");
	KvSetString(GroupsKV, "prefix", "");
	KvSetString(GroupsKV, "suffix", "");
	KvSetString(GroupsKV, "immunity", "1");
	KvGoBack(GroupsKV);
	KvJumpToKey(GroupsKV, "Permissions", true);
	KvGoBack(GroupsKV);
	KvJumpToKey(GroupsKV, "Inheritance", true);
	KvGoBack(GroupsKV);
	return SaveGroups();
}

/* Delete Group
 * Category: Self-defined function
 * 
 * Delete a Group
 * 
*/
bool:DeleteGroup(String:Groupname[]) {
	KvRewind(GroupsKV);
	KvGotoFirstSubKey(GroupsKV)
	do {
		if (KvJumpToKey(GroupsKV, "Inheritance")) {
			if (KvGotoFirstSubKey(GroupsKV, false)) {
				decl String:buffer[255];
				do {
					KvGetSectionName(GroupsKV, buffer, sizeof(buffer));
					if(StrEqual(buffer, Groupname, false)) {
						KvDeleteThis(GroupsKV);
					}
				} while (KvGotoNextKey(GroupsKV, false));
			}
			KvGoBack(GroupsKV);
		}
	} while (KvGotoNextKey(GroupsKV));
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname, true);
	KvDeleteThis(GroupsKV);
	KvRewind(GroupsKV);
	return SaveGroups();
}

/* Set User Prefix
 * Category: Self-defined function
 * 
 * Set a prefix for the User
 * 
*/
bool:SetUserPrefix(client, String:Prefix[]) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Options", true);
	KvSetString(UsersKV, "prefix", Prefix);
	PrintToChat(client, "[PSM] An Admin has set your Prefix to %s", Prefix);
	return SaveUsers();
}

/* Set User Suffix
 * Category: Self-defined function
 * 
 * Set a suffix for the User
 * 
*/
bool:SetUserSuffix(client, String:Suffix[]) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Options", true);
	KvSetString(UsersKV, "suffix", Suffix);
	PrintToChat(client, "[PSM] An Admin has set your Suffix to %s", Suffix);
	return SaveUsers();
}

/* Set User Immunity
 * Category: Self-defined function
 * 
 * Set a immunity for the User
 * 
*/
bool:SetUserImmunity(client, immunity) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Options", true);
	KvSetNum(UsersKV, "immunity", immunity);
	PrintToChat(client, "[PSM] An Admin has set your Immunity to %i", immunity);
	return SaveUsers();
}

/* Add User Group
 * Category: Self-defined function
 * 
 * Add a Group to an User
 * 
*/
bool:AddUserGroup(client, String:Groupname[], negated = false) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvGotoFirstSubKey(UsersKV);
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Groups", true);
	if (!negated) { KvSetString(UsersKV, Groupname, "true"); } else {KvSetString(UsersKV, Groupname, "false"); }
	PrintToChat(client, "[PSM] An Admin added you to the Group %s", Groupname);
	return SaveUsers();
}

/* Remove User Group
 * Category: Self-defined function
 * 
 * Remove a Group from an User
 * 
*/
bool:DelUserGroup(client, String:Groupname[]) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvGotoFirstSubKey(UsersKV)
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Groups", true);
	KvDeleteKey(UsersKV, Groupname);
	PrintToChat(client, "[PSM] An Admin removed you from the Group %s", Groupname);
	return SaveUsers();
}

/* Add User Permission
 * Category: Self-defined function
 * 
 * Add a Permission or Negation Permission to a Group
 * 
*/
bool:AddUserPerm(client, String:Permission[], negated = false) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvGotoFirstSubKey(UsersKV);
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Permissions", true);
	if (!negated) { KvSetString(UsersKV, Permission, "true"); } else {KvSetString(UsersKV, Permission, "false"); }
	PrintToChat(client, "[PSM] An Admin gave you the Permission %s", Permission);
	return SaveUsers();
}

/* Remove User Permission
 * Category: Self-defined function
 * 
 * Remove Permission or Negation Permission from a Group
 * 
*/
bool:DelUserPerm(client, String:Permission[]) {
	decl String:AuthString[512];
	GetClientAuthString(client, AuthString, sizeof(AuthString));
	KvRewind(UsersKV);
	KvGotoFirstSubKey(UsersKV)
	KvRewind(UsersKV);
	KvJumpToKey(UsersKV, AuthString, true);
	KvJumpToKey(UsersKV, "Permissions", true);
	KvDeleteKey(UsersKV, Permission);
	PrintToChat(client, "[PSM] An Admin removed the Permission %s from you", Permission);
	return SaveUsers();
}

/* Set Group Prefix
 * Category: Self-defined function
 * 
 * Set a prefix for the Group
 * 
*/
bool:SetGroupPrefix(String:Groupname[], String:Prefix[]) {
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Options", true);
	KvSetString(GroupsKV, "prefix", Prefix);
	return SaveGroups();
}

/* Set Group Suffix
 * Category: Self-defined function
 * 
 * Set a suffix for the Group
 * 
*/
bool:SetGroupSuffix(String:Groupname[], String:Prefix[]) {
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Options", true);
	KvSetString(GroupsKV, "suffix", Prefix);
	return SaveGroups();
}

/* Set Group Immunity
 * Category: Self-defined function
 * 
 * Set a immunity for the Group
 * 
*/
bool:SetGroupImmunity(String:Groupname[], immunity) {
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Options", true);
	KvSetNum(GroupsKV, "immunity", immunity);
	return SaveGroups();
}

/* Set Default Group
 * Category: Self-defined function
 * 
 * Set a Group to default
 * 
*/
bool:SetDefaultGroup(String:Groupname[]) {
	KvRewind(GroupsKV);
	KvGotoFirstSubKey(GroupsKV)
	do {
		KvJumpToKey(GroupsKV, "Options", true);
		KvSetString(GroupsKV, "default", "false");
		KvGoBack(GroupsKV);
	} while (KvGotoNextKey(GroupsKV));
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Options", true);
	KvSetString(GroupsKV, "default", "true");
	return SaveGroups();
}

/* Get Default Group
 * Category: Self-defined function
 * 
 * Returns the default Group
 * 
*/
bool:GetDefaultGroup(String:Groupname[], maxlength, String:defaultValue[] = "") {
	KvRewind(GroupsKV);
	new Handle:tmpHandle = CloneHandle(GroupsKV);
	strcopy(Groupname, maxlength, defaultValue);
	if (tmpHandle == INVALID_HANDLE) { LogError("An Error occured while cloning the GroupsKV Handle."); return false; }
	if (!KvGotoFirstSubKey(tmpHandle, false)) {
		CloseHandle(tmpHandle);
		strcopy(Groupname, maxlength, defaultValue);
		return false;
	}
	decl String:buffer[255];
	new String:dflt[] = "false";
	do {
		KvGetSectionName(tmpHandle, buffer, sizeof(buffer));
		KvJumpToKey(tmpHandle, "Options", true);
		KvGetString(tmpHandle, "default", dflt, sizeof(dflt), "false");
		if (StringToBool(dflt)) {
			CloseHandle(tmpHandle);
			strcopy(Groupname, maxlength, buffer);
			return true;
		}
		KvGoBack(tmpHandle);
	} while (KvGotoNextKey(tmpHandle, false));
	CloseHandle(tmpHandle);
	strcopy(Groupname, maxlength, defaultValue);
	return false;
}

/* Add Group Inheritance
 * Category: Self-defined function
 * 
 * Add a Group as Parent or Negation Parent to another Group
 * 
*/
bool:AddInherit(String:Groupname[], String:Parent[], negated = false) {
	KvRewind(GroupsKV);
	KvGotoFirstSubKey(GroupsKV);
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Inheritance", true);
	if (!negated) { KvSetString(GroupsKV, Parent, "true"); } else {KvSetString(GroupsKV, Parent, "false"); }
	return SaveGroups();
}

/* Remove Group Inheritance
 * Category: Self-defined function
 * 
 * Remove a Group as Parent or Negation Parent to another Group
 * 
*/
bool:DelInherit(String:Groupname[], String:Parent[]) {
	KvRewind(GroupsKV);
	KvGotoFirstSubKey(GroupsKV)
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Inheritance", true);
	KvDeleteKey(GroupsKV, Parent);
	return SaveGroups();
}

/* Add Group Permission
 * Category: Self-defined function
 * 
 * Add a Permission or Negation Permission to a Group
 * 
*/
bool:AddGroupPerm(String:Groupname[], String:Permission[], negated = false) {
	KvRewind(GroupsKV);
	KvGotoFirstSubKey(GroupsKV);
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Permissions", true);
	if (!negated) { KvSetString(GroupsKV, Permission, "true"); } else {KvSetString(GroupsKV, Permission, "false"); }
	return SaveGroups();
}

/* Remove Group Permission
 * Category: Self-defined function
 * 
 * Remove Permission or Negation Permission from a Group
 * 
*/
bool:DelGroupPerm(String:Groupname[], String:Permission[]) {
	KvRewind(GroupsKV);
	KvGotoFirstSubKey(GroupsKV)
	KvRewind(GroupsKV);
	KvJumpToKey(GroupsKV, Groupname);
	KvJumpToKey(GroupsKV, "Permissions", true);
	KvDeleteKey(GroupsKV, Permission);
	return SaveGroups();
}

/* Save Groups
 * Category: Self-defined function
 * 
 * Saves the entire GroupKeyValue Handle to the file
 * 
*/
bool:SaveGroups() {
	decl String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Groups.txt", PLUGIN_DATA_STORAGE);
	KvRewind(GroupsKV);
	return KeyValuesToFile(GroupsKV, filename);
}

/* Save Users
 * Category: Self-defined function
 * 
 * Saves the entire UsersKeyValue Handle to the file
 * 
*/
bool:SaveUsers() {
	decl String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s/Users.txt", PLUGIN_DATA_STORAGE);
	KvRewind(UsersKV);
	return KeyValuesToFile(UsersKV, filename);
}

/* List Groups
 * Category: Self-defined function
 * 
 * List all groups to a client
 * 
*/
bool:ListGroups(client) {
	decl String:buffer[512];
	if (!KvGotoFirstSubKey(GroupsKV)) {
		if (client == 0) {
			PrintToConsole(client, "[SM] No groups exist");
		} else {
			PrintToChat(client, "[SM] No groups exist");
		}
		return false;
	}
	if (client == 0) {
		PrintToConsole(client, "[SM] Groups:");
	} else {
		PrintToChat(client, "[SM] Groups:");
	}
	do {
		KvGetSectionName(GroupsKV, buffer, sizeof(buffer));
		if (!StrEqual(buffer, "Inheritance", false) || !StrEqual(buffer, "Permissions", false) || !StrEqual(buffer, "Options", false)) {
			if (client == 0) {
				PrintToConsole(client, "[SM] %s", buffer);
			} else {
				PrintToChat(client, "[SM] %s", buffer);
			}
		}
	} while (KvGotoNextKey(GroupsKV, false));
	return true;
}

/* hasPermission Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public Native_hasPermission(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	decl String:PermissionNode[1024], written;
	FormatNativeString(0, 2, 3, sizeof(PermissionNode), written, PermissionNode);
	if (client < 0 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return _:hasPermission(client, PermissionNode);
}

/* canTarget Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public Native_canTarget(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new target = GetNativeCell(2);
	if (client == 0) { return _:canTarget(client, target); }
	if ((client < 1 || client > MaxClients) ||(target < 1 || target > MaxClients)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client) || !IsClientConnected(target)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return _:canTarget(client, target);
}