/*

Description:

Gives the players the ability to add friends to to their steam friend list without having to ask/look for the players friends name. This allows any @targets tu be used like @all (too add all players playing in the server to your friends list ), or admins can also use the second parameter to specifc for who to add the friends.

Commands:

sm_addfriend target [<target>] - When a player executes it, it allows him to add any friends specified in the first parameter target (nickname, userids, @targets)
When an admin executes it he can also use the second parameter, that specifies for which players to add the friend(s) into the steam friends list for.

sm_ts - Alias of above


Changelog

Date: 23.08.2008
Version: 0.6

    * Initial release

*/








// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.6"



/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "",
	author = "Berni",
	description = "Plugin by Berni",
	version = PLUGIN_VERSION,
	url = "http://manni.ice-gfx.com/forum"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:addfriend_version;



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	
	// ConVars
	addfriend_version = CreateConVar("addfriend_version", PLUGIN_VERSION, "Add Friend plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(addfriend_version, PLUGIN_VERSION);

	
	RegConsoleCmd("sm_addfriend", Command_AddFriend, "Allows players to add other players to their friends list");
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_AddFriend(client, args) {
	
	new bool:isAdmin = false;
	
	new AdminId:aid = GetUserAdmin(client);
		
	if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Custom4)) {
		isAdmin = true;
	}
	
	if (args == 0 || (!isAdmin && args > 1) || (isAdmin && args > 2)) {
		decl String:command[32];
		GetCmdArg(0, command, sizeof(command));

		if (isAdmin) {
			PrintToChat(client, "\x04[SM] Usage: %s <players> (<target>)", command);
		}
		else {
			PrintToChat(client, "\x04[SM] Usage: %s <players>", command);
		}

		return Plugin_Handled;
	}
	
	decl target_list[MAXPLAYERS];
	new target_count;
	decl String:target_name[MAX_TARGET_LENGTH];
	decl bool:tn_is_ml;
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	if (args == 2) {
		decl String:target2[MAX_TARGET_LENGTH];
		GetCmdArg(1, target2, sizeof(target2));


		target_count = ProcessTargetString(
				target2,
				client,
				target_list,
				sizeof(target_list),
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml
		);
		
		if (target_count <= 0) {
			ReplyToCommand(client, "\x04[SM] Error: no valid targets found");
			return Plugin_Handled;
		}
	}
	else {
		target_count = 1;
		target_list[0] = client;
	}

	decl target_list_friends[MAXPLAYERS];
	new target_count_friends;

	target_count_friends = ProcessTargetString(
			target,
			client,
			target_list_friends,
			sizeof(target_list_friends),
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count_friends <= 0) {
		ReplyToCommand(client, "\x04[SM] Error: no valid friends found");
		return Plugin_Handled;
	}
	
	decl String:FriendID[32];
	decl String:AuthID[32];
	decl String:URL[256];
	
	for (new i=0; i<target_count; ++i) {
		for (new x=0; x<target_count_friends; ++x) {
			// Don't add yourself
			if (target_list[i] == target_list_friends[x]) {
				continue;
			}
			
			GetClientAuthString(target_list_friends[x], AuthID, sizeof(AuthID));
			AuthIDToFriendID(AuthID, FriendID, sizeof(FriendID));
			Format(URL, sizeof(URL), "steam://friends/add/%s", FriendID);
			
			ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
			ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
			
			ReplyToCommand(target_list[i], "\x04[SM] Player %N has been added to your steam friends list !", target_list_friends[x]);
		}
	}

	
	return Plugin_Handled;
}



/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

AuthIDToFriendID(String:AuthID[], String:FriendID[], size) {
	
	ReplaceString(AuthID, strlen(AuthID), "STEAM_", "");

	if (StrEqual(AuthID, "ID_LAN")) {
		FriendID[0] = '\0';
		
		return;
	}

	decl String:toks[3][16];

	ExplodeString(AuthID, ":", toks, sizeof(toks), sizeof(toks[]));

	//new unknown = StringToInt(toks[0]);
	new iServer = StringToInt(toks[1]);
	new iAuthID = StringToInt(toks[2]);

	new iFriendID = (iAuthID*2) + 60265728 + iServer;

	Format(FriendID, size, "765611979%d", iFriendID);
}
