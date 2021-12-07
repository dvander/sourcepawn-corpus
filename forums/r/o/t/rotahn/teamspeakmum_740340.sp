/*

Description:

Adds a !ts or a !vent command that allows players to join the teamspeak/ventrilo server or admins to force players into the teamspeak server

Requirements:

    * Game that supports opening URLs in the game browser.

Commands:

sm_teamspeak [<target>] -

    * When a player executes it, it just opens the players teamspeak, connects him to the server and joins the specified channel in the config.

    * When an admin executes it he can also specify a target which player to join the teamspeak.

example: !ts @all would force all players to connect to the teamspeak server

sm_ts - Alias of above

sm_ventrilo [<target>] -

    * When a player executes it, it just opens the players ventrilo, connects him to the server and joins the specified channel in the config.

    * When an admin executes it he can also specify a target which player to join the ventrilo.

example: !ts @all would force all players to connect to the teamspeak server

sm_vent - Alias of above

ConVars:

ts_printjoins - Enable/disable teamspeak join messages <1/0>
Default: 1

Config

configs/teamspeak.cfg
configs/ventrilo.cfg

Todo

    * Add support for any voice server


Changelog

Date: 26.08.2008
Version: 1.2

    * Added ventrilo support (Thanks to the_reverend)

Date: 26.08.2008
Version: 1.1

    * Removed debug message on join
    * Added display ts joins in green text in the serverchat
    * Added Convar for setting join messages on/off

Date: 24.08.2008
Version: 1.0.2

    * Fixed not working disallowed-characters replacement

Date: 24.08.2008
Version: 1.0.1

    * Fixed hardcoded server address

Date: 23.08.2008
Version: 1.0

    * Initial release

*/





// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2"


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Teamspeak join command",
	author = "Berni",
	description = "Allows players to join the teamspeak server",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=674090"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:ts_version;
new Handle:ts_printjoins;

// Teamspeak
new String:teamspeak_address[256];
new String:teamspeak_password[64];
new String:teamspeak_channel[128];
new String:teamspeak_disallowed[128];

// Ventrilo
new String:ventrilo_address[256];
new String:ventrilo_servername[128];
new String:ventrilo_password[64];
new String:ventrilo_channel[128];

// Mumble
new String:mumble_address[256];
new String:mumble_password[64];
new String:mumble_channel[128];


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	
	// ConVars
	ts_version = CreateConVar("ts_version", PLUGIN_VERSION, "Teamspeak & ventrilo join plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(ts_version, PLUGIN_VERSION);
	
	ts_printjoins = CreateConVar("ts_printjoins", "1", "Enable/disable teamspeak join messages <1/0>", FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("sm_ts", Command_Teamspeak, "Allows users to join the teamspeak server");
	RegConsoleCmd("sm_teamspeak", Command_Teamspeak, "Allows users to join the teamspeak server");
	RegConsoleCmd("sm_vent", Command_Ventrilo, "Allows users to join the ventrilo server");
	RegConsoleCmd("sm_ventrilo", Command_Ventrilo, "Allows users to join the ventrilo server");
	RegConsoleCmd("sm_mumb", Command_Mumble, "Allows users to join the mumble server");
	RegConsoleCmd("sm_mumble", Command_Mumble, "Allows users to join the mumble server");
}

public OnConfigsExecuted() {
	ReadConfig_Teamspeak();
	ReadConfig_Ventrilo();
	ReadConfig_Mumble();
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_Teamspeak(client, args) {
	decl target_list[MAXPLAYERS];
	new target_count;

	if (args == 0) {
		target_count = 1;
		target_list[0] = client;
	}
	else {
	
		new AdminId:aid = GetUserAdmin(client);
		
		if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Custom4)) {
			decl String:target[MAX_TARGET_LENGTH];
			GetCmdArg(1, target, sizeof(target));

			decl String:target_name[MAX_TARGET_LENGTH];
			decl bool:tn_is_ml;

			target_count = ProcessTargetString(
					target,
					client,
					target_list,
					sizeof(target_list),
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml
			);
			
			ReplyToCommand(client, "\x04[SM] Command executed on target %s...", target);
		}
		else {
			ReplyToCommand(client, "\x04[SM] Access denied");
			return Plugin_Handled;
		}
	}
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] Error: no valid targets found");
		return Plugin_Handled;
	}
	
	decl String:URL[256];
	decl String:nickName[64];

	for (new i=0; i<target_count; ++i) {
		GenerateValidTeamspeakNickName(target_list[i], nickName, sizeof(nickName));
		
		Format(URL, sizeof(URL), "teamspeak://%s/nickname=%s?password=%s?channel=%s", teamspeak_address, nickName, teamspeak_password, teamspeak_channel);
		
		ReplyToCommand(target_list[i], "\x04[SM] Trying to join Teamspeak server...");
		ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
		
		if (GetConVarBool(ts_printjoins)) {
			PrintToChatAll("\x04[SM] Player %N is joining the teamspeak server !", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Ventrilo(client, args) {
	decl target_list[MAXPLAYERS];
	new target_count;

	if (args == 0) {
		target_count = 1;
		target_list[0] = client;
	}
	else {
	
		new AdminId:aid = GetUserAdmin(client);
		
		if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Custom4)) {
			decl String:target[MAX_TARGET_LENGTH];
			GetCmdArg(1, target, sizeof(target));

			decl String:target_name[MAX_TARGET_LENGTH];
			decl bool:tn_is_ml;

			target_count = ProcessTargetString(
					target,
					client,
					target_list,
					sizeof(target_list),
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml
			);
			
			ReplyToCommand(client, "\x04[SM] Command executed on target %s...", target);
		}
		else {
			ReplyToCommand(client, "\x04[SM] Access denied");
			return Plugin_Handled;
		}
	}
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] Error: no valid targets found");
		return Plugin_Handled;
	}
	
	decl String:URL[256];
	decl String:nickName[64];

	for (new i=0; i<target_count; ++i) {
		GenerateValidTeamspeakNickName(target_list[i], nickName, sizeof(nickName));
		
		Format(URL, sizeof(URL), "ventrilo://%s/servername=%s&serverpassword=%s&channelname=%s", ventrilo_address, ventrilo_servername, ventrilo_password, ventrilo_channel);
		
		ReplyToCommand(target_list[i], "\x04[SM] Trying to join Ventrilo server...");
		ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
		
		if (GetConVarBool(ts_printjoins)) {
			PrintToChatAll("\x04[SM] Player %N is joining the ventrilo server !", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Mumble(client, args) {
	decl target_list[MAXPLAYERS];
	new target_count;

	if (args == 0) {
		target_count = 1;
		target_list[0] = client;
	}
	else {
	
		new AdminId:aid = GetUserAdmin(client);
		
		if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Custom4)) {
			decl String:target[MAX_TARGET_LENGTH];
			GetCmdArg(1, target, sizeof(target));

			decl String:target_name[MAX_TARGET_LENGTH];
			decl bool:tn_is_ml;

			target_count = ProcessTargetString(
					target,
					client,
					target_list,
					sizeof(target_list),
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml
			);
			
			ReplyToCommand(client, "\x04[SM] Command executed on target %s...", target);
		}
		else {
			ReplyToCommand(client, "\x04[SM] Access denied");
			return Plugin_Handled;
		}
	}
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] Error: no valid targets found");
		return Plugin_Handled;
	}
	
	decl String:URL[256];
	decl String:nickName[64];

	for (new i=0; i<target_count; ++i) {
		GenerateValidTeamspeakNickName(target_list[i], nickName, sizeof(nickName));
		
		Format(URL, sizeof(URL), "mumble://%s:%s@%s/%s", nickName, mumble_password, mumble_address, mumble_channel);
		
		ReplyToCommand(target_list[i], "\x04[SM] Trying to join Mumble server...");
		ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
		
		if (GetConVarBool(ts_printjoins)) {
			PrintToChatAll("\x04[SM] Player %N is joining the Mumble server !", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

GenerateValidTeamspeakNickName(client, String:buffer[], size) {
	if (size == 0) {
		return;
	}

	decl String:clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	
	new n=0;
	new buf_pos = 0;
	while (clientName[n] != '\0') {
		new x = 0;
		new invalid = false;
		while (teamspeak_disallowed[x] != '\0') {
			if (clientName[n] == teamspeak_disallowed[x]) {
				invalid = true;
				break;
			}
			
			++x;
		}
		
		if (!invalid) {
			buffer[buf_pos] = clientName[n];
			buf_pos++;
			
			if (buf_pos == size) {
				break;
			}
		}
		
		++n;
	}
	
	buffer[buf_pos] = '\0';
}

ReadConfig_Teamspeak() {
	decl String:path[PLATFORM_MAX_PATH];

	new Handle:kv = CreateKeyValues("Teamspeakserver");
	
	BuildPath(Path_SM, path, sizeof(path), "configs/voiceserver/teamspeak.cfg");
	FileToKeyValues(kv, path);

	KvGetString(kv, "address", teamspeak_address, sizeof(teamspeak_address));
	KvGetString(kv, "password", teamspeak_password, sizeof(teamspeak_password));
	KvGetString(kv, "channel", teamspeak_channel, sizeof(teamspeak_channel));
	KvGetString(kv, "DisAllowedClientNameChars", teamspeak_disallowed, sizeof(teamspeak_disallowed));
	
	CloseHandle(kv);

	return true;

}

ReadConfig_Ventrilo() {
	decl String:path[PLATFORM_MAX_PATH];

	new Handle:kv = CreateKeyValues("Ventriloserver");
	
	BuildPath(Path_SM, path, sizeof(path), "configs/voiceserver/ventrilo.cfg");
	FileToKeyValues(kv, path);

	KvGetString(kv, "address", ventrilo_address, sizeof(ventrilo_address));
	KvGetString(kv, "password", ventrilo_password, sizeof(ventrilo_password));
	KvGetString(kv, "servername", ventrilo_servername, sizeof(ventrilo_servername));
	KvGetString(kv, "channel", ventrilo_channel, sizeof(ventrilo_channel));
	
	CloseHandle(kv);

	return true;

}

ReadConfig_Mumble() {
	decl String:path[PLATFORM_MAX_PATH];

	new Handle:kv = CreateKeyValues("Mumbleserver");
	
	BuildPath(Path_SM, path, sizeof(path), "configs/voiceserver/mumble.cfg");
	FileToKeyValues(kv, path);

	KvGetString(kv, "address", mumble_address, sizeof(mumble_address));
	KvGetString(kv, "password", mumble_password, sizeof(mumble_password));
	KvGetString(kv, "channel", mumble_channel, sizeof(mumble_channel));
	KvGetString(kv, "DisAllowedClientNameChars", teamspeak_disallowed, sizeof(teamspeak_disallowed));
	
	CloseHandle(kv);

	return true;

}