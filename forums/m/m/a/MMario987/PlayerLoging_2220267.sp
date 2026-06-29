#include <sourcemod>	


static String:KVPath[PLATFORM_MAX_PATH];

public Plugin:myinfo = {

	name = "Player Loging",
	author = "[SD]Mario987",
	description = "Player Loging Info",
	version = "1.0",
	url = "",
}


public OnPluginStart()
{
	CreateDirectory("addons/sourcemod/data/logging", 3);
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/logging/PlayerSteamId.txt");

}

public OnClientPutInServer(client)
{
	SavePlayerInfo(client);

}

public SavePlayerInfo(client)
{
	new Handle:DB = CreateKeyValues("PlayerInfo");
	FileToKeyValues(DB, KVPath);

	new String:SID[32];
	GetClientAuthString(client, SID, sizeof(SID));

	if(KvJumpToKey(DB, SID, true))
	{
		new String:name[MAX_NAME_LENGTH], String:temp_name[MAX_NAME_LENGTH]
		GetClientName(client, name, sizeof(name));
	
		KvGetString(DB, "name", temp_name, sizeof(temp_name), "NULL");


	    new connections = KvGetNum(DB, "connections", 0);
		
		if(StrEqual(temp_name, "Null") && connections == 0)
		{
			PrintToChatAll("{green}Welcome %s to The Server!", name);
		} else {
			PrintToChatAll("%s Last Connected as %s. And has %s connections.", name, temp_name, connections);
		}

		connections++
		KvSetNum(DB, "connections", connections);
		KvSetString(DB, "name", name);

		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);


	}
}