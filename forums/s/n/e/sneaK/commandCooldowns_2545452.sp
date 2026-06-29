/*	Changes since previous version:
		Added support for command aliases sharing a cooldown (up to 8 commands per cooldown)
		Reduced maximum number of cooldowns from 255 to 64
		Removed "%i" support from replies
		Replies now replace "{COMMAND_NAME}" and "{TIMELEFT}" with the appropriate information
		Removed pointless RemoveCommandListener calls in OnPluginEnd
		Added "shared" keyvalue key
		Switched to using BuildPath() rather than hard-coding in addons/sourcemod/
		Updated version of ddhoward_updater used
		other minor internal code improvements
	Plans for future:
		Move all large arrays that are only changed on txt load to dynamic arrays!!!
			finally, an excuse to learn how to do adt arrays
		Add support for multiple plugins being listed in the plugins key
			Figure out what to divide plugins with; what easily typable character is illegal to use in plugin filenames across platforms?
		Create natives:
			Is a command cooling down for a given client?
			Set the time left on a client's cooldown.
		Create forward for when a command is blocked
		Create natives for adding, removing, and modifying cooldowns, once the arrays are made dynamic
*/

#pragma semicolon 1
#define PLUGIN_VERSION "14.0926"
#define UPD_LIBFUNC
#define CONVAR_PREFIX "sm_commandcooldowns"
#define DEFAULT_UPDATE_SETTING "2"
#define UPDATE_FILE "commandCooldowns.txt"
#undef REQUIRE_PLUGIN
#include <morecolors>
#include <ddhoward_updater>

#define MAX_COOLDOWNS 64 //this can be increased if necessary i guess
#define MAX_CMD_LENGTH 64 //256 is the actual largest size that is not completely pointless here, but even 64 is beyond anything realistic.
#define MAX_CMD_ALIASES 8 //this can be increased if necessary
new Float:g_clCmdTime[MAX_COOLDOWNS][MAXPLAYERS+1];
new Float:g_cooldowns[MAX_COOLDOWNS];
new String:g_commandNames[MAX_COOLDOWNS][MAX_CMD_ALIASES][MAX_CMD_LENGTH + 1];
new String:g_numAliases[MAX_COOLDOWNS];
new String:g_overrides[MAX_COOLDOWNS][MAX_CMD_LENGTH + 1];
new String:g_pluginNames[MAX_COOLDOWNS][PLATFORM_MAX_PATH - 28]; // 26 == strlen("**/addons/sourcemod/plugins/")
new String:g_replies[MAX_COOLDOWNS][255];
new bool:g_reset[MAX_COOLDOWNS];
new bool:g_shared[MAX_COOLDOWNS];
new g_flags[MAX_COOLDOWNS];
new g_numCooldowns;

#define COOLDOWN_CONFIG_PATH "configs/commandCooldowns.txt"
#define DEFAULT_COOLDOWN_REPLY "You must wait {TIMELEFT} seconds!"
//remove these in a future update
#define PRINT_FLAGS_ERROR_1 new bool:printError;
#define PRINT_FLAGS_ERROR_2 if (flags[0] == '\0') { KvGetString(kv, "defaultFlag", flags, sizeof(flags)); if (flags[0] != '\0') { printError = true; } }
#define PRINT_FLAGS_ERROR_3 if (printError) { LogError("\"defaultFlag\" in commandCooldowns.txt has been replaced with \"flags\". Please update your commandCooldowns config file appropriately."); }

new Handle:hcvar_reloadPlugins;

public Plugin:myinfo = {
	name = "[Any] Command Cooldowns",
	author = "Derek D. Howard",
	description = "Allows server ops to set a cooldown for any registered command without editing the command's code.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=235539"
};

public OnPluginStart() {
	hcvar_reloadPlugins = CreateConVar("sm_commandcooldowns_reloadplugins", "1", "(0/1) Enable plugin reloading by default?", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_commandcooldowns_reload", UseReloadCmd, ADMFLAG_RCON, "Reloads commandCooldowns.txt");

	ParseCooldownsKVFile();
}

ParseCooldownsKVFile() {
	for (new i = 0; i < g_numCooldowns; i++) {
		for (new a = 0; a < g_numAliases[i]; a++) {
			RemoveCommandListener(CommandListener, g_commandNames[i][a]);
		}
		for (new client = 1; client <= MaxClients; client++) {
			g_clCmdTime[i][client] = 0.0;
		}
	}
	g_numCooldowns = 0;
	new Handle:kv = CreateKeyValues("CommandCooldowns");

	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), COOLDOWN_CONFIG_PATH);
	if (!FileToKeyValues(kv, path)) {
		LogError("commandCooldowns.txt not found!!");
	}
	else if (!KvGotoFirstSubKey(kv)) {
		LogError("commandCooldowns.txt appears to be empty!!");
	}
	else {
		PRINT_FLAGS_ERROR_1
		do {

			//get the command names
			decl String:allCommands[MAX_CMD_ALIASES * (MAX_CMD_LENGTH + 1)];
			KvGetSectionName(kv, allCommands, sizeof(allCommands));
			g_numAliases[g_numCooldowns] = ExplodeString(allCommands, " ", g_commandNames[g_numCooldowns], sizeof(g_commandNames[]), sizeof(g_commandNames[][]));

			//get the cooldown
			g_cooldowns[g_numCooldowns] = KvGetFloat(kv, "cooldown", 0.0);

			if (g_numAliases[g_numCooldowns] > 0 && g_cooldowns[g_numCooldowns] > 0.0) { //need a cooldown and at least 1 command

				//Hook the commands
				for (new a = 0; a < g_numAliases[g_numCooldowns]; a++) {
					AddCommandListener(CommandListener, g_commandNames[g_numCooldowns][a]);
				}

				//parse and store the flags needed
				decl String:flags[AdminFlags_TOTAL + 1];
				KvGetString(kv, "flags", flags, sizeof(flags));
				PRINT_FLAGS_ERROR_2
				new AdminFlag:useless;
				for (new i = 0; i < strlen(flags); i++) {
					flags[i] = CharToLower(flags[i]); //upper case flags don't work with ReadFlagString()
					if (!FindFlagByChar(flags[i], useless)) { //get rid of characters that aren't valid flags
						decl String:temp[1];
						temp[0] = flags[i];
						ReplaceStringEx(flags, sizeof(flags), temp, "", 1, 0);
						i--;
					}
				}
				g_flags[g_numCooldowns] = ReadFlagString(flags);

				//get the other info
				KvGetString(kv, "override", g_overrides[g_numCooldowns], sizeof(g_overrides[]));
				KvGetString(kv, "plugin", g_pluginNames[g_numCooldowns], sizeof(g_pluginNames[]));
				KvGetString(kv, "reply", g_replies[g_numCooldowns], sizeof(g_replies[]), DEFAULT_COOLDOWN_REPLY);
				g_reset[g_numCooldowns] = bool:KvGetNum(kv, "reset", 0);
				g_shared[g_numCooldowns] = bool:KvGetNum(kv, "shared", 0);

				g_numCooldowns++;
			}
		} while (KvGotoNextKey(kv) && g_numCooldowns < MAX_COOLDOWNS);
		PRINT_FLAGS_ERROR_3
	}
	CloseHandle(kv);
}

public Action:CommandListener(client, const String:cmdname[], iArgs) {
	if (client == 0) { return Plugin_Continue; } //server console is immune to cooldowns

	for (new i = 0; i < g_numCooldowns; i++) { //loop through all cooldowns
		for (new a = 0; a < g_numAliases[i]; a++) { //loop through all that cooldown's commands
			if (StrEqual(cmdname, g_commandNames[i][a])) { //got a match!

				//calculate the time remaining until the command can be used again
				new Float:timeRemaining = (g_clCmdTime[i][g_shared[i] ? 0 : client] + g_cooldowns[i]) - GetEngineTime();

				if (timeRemaining <= 0 //if cooldown has expired, OR...
				|| !CheckCommandAccess(client, cmdname, 0) //client can't access the command anyway, OR...
				|| ((g_overrides[i][0] != '\0' || g_flags[i] != 0) && CheckCommandAccess(client, g_overrides[i], g_flags[i]))) { //client can bypass cooldown...

					g_clCmdTime[i][g_shared[i] ? 0 : client] = GetEngineTime(); //set the new command used time, and...
					return Plugin_Continue; //let the command go through

				}

				else { //haha, stop the command

					if (g_reset[i]) { g_clCmdTime[i][g_shared[i] ? 0 : client] = GetEngineTime(); } //"reset" key was set, so restart the cooldown

					if (g_replies[i][0] != '\0') { //a non-blank reply was set
						decl String:reply[255];
						reply = g_replies[i];
						decl String:str_timeleft[7]; //maximum printable cooldown length is = to 11.5 days with size 7 here
						IntToString(RoundToCeil(g_reset[i] ? g_cooldowns[i] : timeRemaining), str_timeleft, sizeof(str_timeleft));
						ReplaceString(reply, sizeof(reply), "{COMMAND_NAME}", cmdname);
						ReplaceString(reply, sizeof(reply), "{TIMELEFT}", str_timeleft);
						CReplyToCommand(client, reply);
					}

					//note to self: put forward here in future update

					return Plugin_Stop;
				}
			}
		}
	}
	return Plugin_Continue; //no idea how we'd even get here, but the compiler isn't happy unless this is here
}

public Action:UseReloadCmd(client, args) {
	ParseCooldownsKVFile();
	new bool:reloaded;
	if (GetCmdArgs() > 0) {
		decl String:arg1[2]; GetCmdArg(1, arg1, sizeof(arg1));	new intarg = StringToInt(arg1);
		if (intarg == 1 || (intarg != 0 && GetConVarBool(hcvar_reloadPlugins))) {
			reloaded = true;
		}
	}
	else if (GetConVarBool(hcvar_reloadPlugins)) {
		reloaded = true;
	}
	if (reloaded) {
		DoReloads();
	}
	ReplyToCommand(client, "Cooldowns have been reloaded.%s", reloaded ? " Any applicable plugins have also been reloaded." : "");
	return Plugin_Handled;
}

public OnClientDisconnect(client) {
	for (new i = 0; i < g_numCooldowns; i++) {
		g_clCmdTime[i][client] = 0.0;
	}
}

DoReloads() {
	for (new i = 0; i < g_numCooldowns; i++) {
		if (g_pluginNames[i][0] != '\0') {
			ServerCommand("sm plugins reload %s", g_pluginNames[i]);
		}
	}
}

public OnConfigsExecuted() {
	if (GetConVarBool(hcvar_reloadPlugins)) {
		DoReloads();
	}
}