#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name        = "Rename by steamID",
	author      = "Arkarr",
	description = "Replace players name with another specific name based on steamID.",
	version     = "1.0",
	url         = "sourcemod.net"
};

new Handle:trie = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_changename", PlayerChangeName, EventHookMode_Post);
	
	trie = CreateTrie();
	LoadConfig();
}

public OnClientPostAdminCheck(client)
{	
	if (IsFakeClient(client))
		return;
		
	RenamePlayer(client);
	return;
}

public Action:Timer_Rename(Handle:timer, any:client)
{
	RenamePlayer(client);
	return Plugin_Stop;
}


public PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(0.5, Timer_Rename, client, TIMER_FLAG_NO_MAPCHANGE);
}

stock LoadConfig()
{
	new Handle:kv = CreateKeyValues("Rename by steamid config file");
	FileToKeyValues(kv, "addons/sourcemod/configs/steamid_renamer.cfg");

	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}

	decl String:steamid[255];
	decl String:new_name[255];

	do
	{
		KvGetString(kv, "steamid", steamid, sizeof(steamid));
		KvGetString(kv, "new_name", new_name, sizeof(new_name));
		if(!SetTrieString(trie, steamid, new_name, false))
		{
			PrintToServer("****************************");
			PrintToServer("ERROR IN RenameBySteamID_KV_version.smx !");
			PrintToServer(">>> A steamid have already a new name <<<");
			PrintToServer("****************************");
		}
	}while(KvGotoNextKey(kv));

	CloseHandle(kv);  
}

stock RenamePlayer(client)
{
	decl String:new_name[MAX_NAME_LENGTH], String:steam_id[64];
	GetClientAuthString(client, steam_id, sizeof(steam_id));
	if(GetTrieString(trie, steam_id, new_name, sizeof(new_name)))
		SetClientInfo(client, "name", new_name);
}