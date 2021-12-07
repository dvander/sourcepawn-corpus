#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name        = "Group Tags",
	author      = "Dr. McKay",
	description = "Sets a tag on a player if they're in a certain admin group",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

public OnClientPostAdminCheck(client)
{
	new AdminId:admin = GetUserAdmin(client); // Pull the client's Admin ID
	if(admin != INVALID_ADMIN_ID) // If the client is an admin
	{
		decl String:fPath[256];
		BuildPath(Path_SM, fPath, sizeof(fPath), "configs/grouptags.txt"); // Build a path to the config file
		new Handle:kv = CreateKeyValues("Group Tags"); // Create our keyfiles
		FileToKeyValues(kv, fPath); // Pull our config file into our keyfiles
		decl String:steamid[30];
		GetClientAuthString(client, steamid, sizeof(steamid)); // Grab the client's Steam ID
		decl String:group[50];
		GetAdminGroup(admin, 0, group, sizeof(group)); // Get the client's group name
		KvJumpToKey(kv, group); // Jump to the group name in the keyfiles
		new String:prefix[50];
		new String:suffix[50];
		KvGetString(kv, "prefix", prefix, sizeof(prefix), ""); // Pull the prefix, if present
		KvGetString(kv, "suffix", suffix, sizeof(suffix), ""); // Pull the suffix, if present
		if(KvJumpToKey(kv, "prefix") || KvJumpToKey(kv, "suffix")) // If there's either a prefix or a suffix
		{
			KvRewind(kv); // Go back to the root of our keyfiles
			KvJumpToKey(kv, "Whitelist"); // Go to the whitelist
			if(KvGetNum(kv, steamid, 0) == 1) // If the client is whitelisted
				return; // Ignore 'em
			decl String:newName[MAX_NAME_LENGTH];
			FormatEx(newName, sizeof(newName), "%s%N%s", prefix, client, suffix); // Make up our new name
			SetClientInfo(client, "name", newName); // Name 'em
		}
		CloseHandle(kv); // Done with our keyfiles
		return; // Done
	}
	return; // Isn't an admin, let's return
}