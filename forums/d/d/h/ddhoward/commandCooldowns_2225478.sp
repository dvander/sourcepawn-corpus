/*	Changes since previous version:
		Moved to fucking dynamic arrays YYYYYYEAHHHHHHHHHHHHHHHHH
	Plans for future:
		Clean up variable names, improve comments
		Add support for multiple plugins being listed in the plugins key
			Figure out what to divide plugins with; what easily typable character is illegal to use in plugin filenames across platforms?
		Create natives:
			Is a command cooling down for a given client?
			Set the time left on a client's cooldown.
		Create forward for when a command is blocked
		Create natives for adding, removing, and modifying cooldowns, once the arrays are made dynamic
*/

#pragma semicolon 1
#define PLUGIN_VERSION "14.1117"
#define UPD_LIBFUNC
#define CONVAR_PREFIX "sm_commandcooldowns"
#define DEFAULT_UPDATE_SETTING "2"
#define UPDATE_FILE "commandCooldowns.txt"
#undef REQUIRE_PLUGIN
#include <morecolors>
#include <ddhoward_updater>

new Handle:g_clCmdTime = INVALID_HANDLE; //1 index per cooldown, block size = MaxClients + 1
new Handle:g_cooldowns = INVALID_HANDLE; //each cell is the cooldown time
new Handle:g_overrides = INVALID_HANDLE;
new Handle:g_reset = INVALID_HANDLE;
new Handle:g_shared = INVALID_HANDLE;
new Handle:g_flags = INVALID_HANDLE;
new Handle:g_replies = INVALID_HANDLE; //block size = ByteCountToCells(255)
new Handle:g_pluginNames = INVALID_HANDLE; //bs = ByteCountToCells(PLATFORM_MAX_PATH+1)
new Handle:g_commandNames = INVALID_HANDLE; //EACH cooldown has its own array of strings, containing all the aliases

#define COOLDOWN_CONFIG_PATH "configs/commandCooldowns.txt"
#define DEFAULT_COOLDOWN_REPLY "You must wait {TIMELEFT} seconds!"

new Handle:hcvar_reloadPlugins;

public Plugin:myinfo = {
	name = "[Any] Command Cooldowns",
	author = "Derek D. Howard",
	description = "Allows server ops to set a cooldown for any registered command without editing the command's code.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=235539"
};

public OnPluginStart() {
	g_cooldowns = CreateArray();
	g_reset = CreateArray();
	g_shared = CreateArray();
	g_flags = CreateArray();
	g_commandNames = CreateArray();
	g_clCmdTime = CreateArray(MaxClients + 1);
	g_overrides = CreateArray(ByteCountToCells(257));
	g_replies = CreateArray(ByteCountToCells(255));
	g_pluginNames = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH + 1));
	

	hcvar_reloadPlugins = CreateConVar("sm_commandcooldowns_reloadplugins", "1", "(0/1) Enable plugin reloading by default?", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_commandcooldowns_reload", UseReloadCmd, ADMFLAG_RCON, "Reloads commandCooldowns.txt");

	ParseCooldownsKVFile(true);
}

ParseCooldownsKVFile(bool:pluginStart=false) {
	decl String:bigBuffer[257]; bigBuffer[0] = '\0';
	if (!pluginStart) {
		new numCooldowns = GetArraySize(g_cooldowns);
		for (new i = 0; i < numCooldowns; i++) {
			new Handle:namesArray = GetArrayCell(g_commandNames, i);
			new numAliases = GetArraySize(namesArray);
			for (new a = 0; a < numAliases; a++) {
				GetArrayString(namesArray, a, bigBuffer, sizeof(bigBuffer));
				RemoveCommandListener(CommandListener, bigBuffer);
			}
			CloseHandle(namesArray);
		}
		ClearArray(g_cooldowns);
		ClearArray(g_reset);
		ClearArray(g_shared);
		ClearArray(g_flags);
		ClearArray(g_commandNames);
		ClearArray(g_clCmdTime);
		ClearArray(g_overrides);
		ClearArray(g_replies);
		ClearArray(g_pluginNames);
	}

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
		do {
			//get the cooldown info from the file
			new Float:cooldown = KvGetFloat(kv, "cooldown", 0.0);

			if (cooldown > 0.0) { //cooldown needs to be more than 0.0 or else there's no point

				//get the command names
				bigBuffer[0] = '\0';
				KvGetSectionName(kv, bigBuffer, sizeof(bigBuffer));

				//remove double spaces
				ReplaceString(bigBuffer, sizeof(bigBuffer), "  ", " ");
				
				//count number of spaces
				new numSpaces, char, largestAliasSize, curAliasSize;
				while (bigBuffer[char] != '\0') {
					if (bigBuffer[char] == ' ') {
						numSpaces++;
						curAliasSize = 0;
					}
					else {
						curAliasSize++;
						if (largestAliasSize < curAliasSize)
							largestAliasSize = curAliasSize;
					}
					char++;
				}

				decl String:explodedString[numSpaces + 1][largestAliasSize + 1];
				new numberAliases = ExplodeString(bigBuffer, " ", explodedString, numSpaces+1, largestAliasSize + 1);
				//new numberAliases = ExplodeString(bigBuffer, " ", explodedString, sizeof(explodedString), sizeof(explodedString[]));

				if (numberAliases > 0) {
					//Create the array to store the command names
					new Handle:h_aliases = CreateArray(ByteCountToCells(257));
					//save that array's handle for later
					PushArrayCell(g_commandNames, h_aliases);

					//Hook the commands and add them to the array
					for (new a = 0; a < numberAliases; a++) {
						AddCommandListener(CommandListener, explodedString[a]);
						PushArrayString(h_aliases, explodedString[a]);
					}

					//store the cooldown
					PushArrayCell(g_cooldowns, cooldown);

					//parse and store the flags needed
					decl String:flags[AdminFlags_TOTAL + 1];
					KvGetString(kv, "flags", flags, sizeof(flags));
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
					PushArrayCell(g_flags, ReadFlagString(flags));

					//get the other info
					KvGetString(kv, "override", bigBuffer, sizeof(bigBuffer));
					PushArrayString(g_overrides, bigBuffer);

					KvGetString(kv, "plugin", bigBuffer, sizeof(bigBuffer));
					PushArrayString(g_pluginNames, bigBuffer);

					KvGetString(kv, "reply", bigBuffer, sizeof(bigBuffer), DEFAULT_COOLDOWN_REPLY);
					PushArrayString(g_replies, bigBuffer);

					PushArrayCell(g_reset, KvGetNum(kv, "reset", 0));

					PushArrayCell(g_shared, KvGetNum(kv, "shared", 0));

					
					new Float:worthlessArray[MaxClients +1];// = { -1.0, ... }; why does this error
					for (new i = 0; i <= MaxClients; i++) { //this whole block exists because of the error above
						worthlessArray[i] = -1.0;
					}
					PushArrayArray(g_clCmdTime, worthlessArray);
				}
			}
		} while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

public Action:CommandListener(client, const String:cmdname[], iArgs) {
	if (client == 0) { return Plugin_Continue; } //server console is immune to cooldowns

	new Handle:aliases, numaliases;
	decl String:cmdTestBuffer[257]; cmdTestBuffer[0] = '\0';
	new numCooldowns = GetArraySize(g_commandNames);
	for (new i = 0; i < numCooldowns; i++) { //loop through all cooldowns
		aliases = GetArrayCell(g_commandNames, i);
		numaliases = GetArraySize(aliases);
		for (new a = 0; a < numaliases; a++) { //loop through all that cooldown's commands
			GetArrayString(aliases, a, cmdTestBuffer, sizeof(cmdTestBuffer));
			
			if (StrEqual(cmdname, cmdTestBuffer)) { //got a match!

				new bool:shared = bool:GetArrayCell(g_shared, i);
				new Float:cooldown = Float:GetArrayCell(g_cooldowns, i);
				new Float:lastUsed = Float:GetArrayCell(g_clCmdTime, i, shared ? 0 : client);

				//calculate the time remaining until the command can be used again
				new Float:timeRemaining = (lastUsed + cooldown) - GetEngineTime();
				
				decl String:override[257]; override[0] = '\0';
				GetArrayString(g_overrides, i, override, sizeof(override));
				
				new flags = GetArrayCell(g_flags, i);

				if (timeRemaining <= 0 //if cooldown has expired, OR...
				|| lastUsed < 0.0 //the command hasn't been used at all yet
				|| !CheckCommandAccess(client, cmdname, 0) //client can't access the command anyway, OR...
				|| ((override[0] != '\0' || flags != 0) && CheckCommandAccess(client, override, flags))) { //client can bypass cooldown...

					SetArrayCell(g_clCmdTime, i, GetEngineTime(), shared ? 0 : client); //set the new command used time
					break; //stop looking at this cooldown, and go through the rest

				}
				else { //haha, stop the command

					new bool:reset = bool:GetArrayCell(g_reset, i);
					if (reset) { SetArrayCell(g_clCmdTime, i, GetEngineTime(), shared ? 0 : client); } //"reset" key was set, so restart the cooldown

					decl String:reply[55]; reply[0] = '\0';
					GetArrayString(g_replies, i, reply, sizeof(reply));
					if (reply[0] != '\0') { //a non-blank reply was set
						decl String:str_timeleft[7]; //maximum printable cooldown length is = to 11.5 days with size 7 here
						IntToString(RoundToCeil(reset ? cooldown : timeRemaining), str_timeleft, sizeof(str_timeleft));
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
	new numCooldowns = GetArraySize(g_cooldowns);
	for (new i = 0; i < numCooldowns; i++) {
		SetArrayCell(g_clCmdTime, i, 0.0, client);
	}
}

DoReloads() {
	decl String:pluginname[PLATFORM_MAX_PATH-11]; pluginname[0] = '\0';
	new numCooldowns = GetArraySize(g_cooldowns);
	for (new i = 0; i < numCooldowns; i++) {
		GetArrayString(g_pluginNames, i, pluginname, sizeof(pluginname));
		if (pluginname[0] != '\0') {
			ServerCommand("sm plugins reload %s", pluginname);
		}
	}
}

public OnConfigsExecuted() {
	if (GetConVarBool(hcvar_reloadPlugins)) {
		DoReloads();
	}
}