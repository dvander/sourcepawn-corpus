#include <sourcemod>

#pragma semicolon 1

public Plugin myinfo = {
	name        = "WhoIS",
	author      = "JiSH",
	description = "Full Detail About a Client.",
	version     = "1.2.5",
	url         = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_whois", cmd_whois);
}

char clienthasadmin[1024];
char enteringoldname[1024];
char oldname[1024];

public void OnClientAuthorized(client)
{
	char clientnameconnected[512];
	char clientid[512];
	char tempoldname[512];
	GetClientName(client, clientnameconnected, sizeof(clientnameconnected));
	GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid));
	
	//Get Oldest Name
	KeyValues kv = new KeyValues("WhoisDB"); 

    	char sPath[PLATFORM_MAX_PATH]; 
    	BuildPath(Path_SM, sPath, sizeof(sPath), "data/whoisdb.txt"); 

    	kv.ImportFromFile(sPath); 
	kv.GoBack();
	kv.JumpToKey(clientid, true);
	kv.GetString(clientid, tempoldname, sizeof(oldname), "no");
	kv.GoBack();
	Format(oldname, sizeof(oldname), tempoldname);
	CloseHandle(kv);
	
	
	if (strlen(oldname) == 2)
	{
		// If not found Make Database and Load OldName
		new Handle:KV_Save = CreateKeyValues("WhoisDB");
    		FileToKeyValues(KV_Save, "addons/sourcemod/data/whoisdb.txt");
    		KvJumpToKey(KV_Save, clientid, true);
    		KvSetString(KV_Save, clientid, clientnameconnected);
    		KvRewind(KV_Save); 
    		KeyValuesToFile(KV_Save, "addons/sourcemod/data/whoisdb.txt"); 
    		KvGoBack(KV_Save);
    		KvJumpToKey(KV_Save, clientid, true);
    		KvGetString(KV_Save, clientid, tempoldname, sizeof(oldname));
    		CloseHandle(KV_Save); 
    		Format(oldname, sizeof(oldname), tempoldname);
	}
	
	//Get Oldest Name
	KeyValues kvjoin = new KeyValues("WhoisDB"); 
	
    	BuildPath(Path_SM, sPath, sizeof(sPath), "data/whoisdb.txt"); 

    	kvjoin.ImportFromFile(sPath); 
	kvjoin.GoBack();
	kvjoin.JumpToKey(clientid, true);
	kvjoin.GetString(clientid, tempoldname, sizeof(oldname), "no");
	kvjoin.GoBack();
	Format(enteringoldname, sizeof(enteringoldname), tempoldname);
	CloseHandle(kvjoin);
	PrintToChatAll("\x04[\x03Whois\x04] \x01Client \x03%s \x01entered the server. Old Name : \x03%s", clientnameconnected, enteringoldname);
	PrintToServer("[Whois] Client %s entered the server. Old Name: %s", clientnameconnected, enteringoldname);
    	
}

public Action cmd_whois(client, args)
{
	if (args < 1)
	{
		PrintToChat(client, "\x04[\x03Whois\x04] \x01Usage: !whois \x03<player name>" );
	}
	if (args == 1)
	{
		//Initial Action
		char TargetString[100]; 
    		GetCmdArg(1, TargetString, 100); 
     
		int[] Clients = new int[MaxClients]; 

		char TargetName[100];
		bool tn_is_ml; 
		int ValidClients = ProcessTargetString(TargetString, client, Clients, MaxClients, COMMAND_FILTER_NO_IMMUNITY, TargetName, sizeof(TargetName), tn_is_ml);
		int PlayerClient; 
    		char ClientName[100]; 
    		for (int i = 0; i < ValidClients; i++) 
    		{ 
        	PlayerClient = Clients[i];
        	GetClientName(PlayerClient, ClientName, sizeof(ClientName));
    		}
		char steamid[256];
		char ip[256];
		Format(clienthasadmin, sizeof(clienthasadmin), "No.");
		if (GetUserFlagBits(PlayerClient) != 0)
		{
			Format(clienthasadmin, sizeof(clienthasadmin), "Yes.");
		}
		
		char clientidtarget[512];
		char tempoldname[512];
		GetClientAuthId(PlayerClient, AuthId_Engine, clientidtarget, sizeof(clientidtarget));
	
	//Get Oldest Name
		KeyValues kv = new KeyValues("WhoisDB"); 

		char sPath[PLATFORM_MAX_PATH]; 
		BuildPath(Path_SM, sPath, sizeof(sPath), "data/whoisdb.txt"); 

    		kv.ImportFromFile(sPath); 
		kv.GoBack();
		kv.JumpToKey(clientidtarget, true);
		kv.GetString(clientidtarget, tempoldname, sizeof(oldname), "no");
		kv.GoBack();
		CloseHandle(kv);
		Format(oldname, sizeof(oldname), tempoldname);
	
	    	GetClientAuthId(PlayerClient, AuthId_Engine, steamid, sizeof(steamid));
	    	GetClientIP(PlayerClient, ip, sizeof(ip));
	    	PrintToChat(client, "\x04[\x03Whois\x04] \x03Player Name: %s", ClientName);
	    	PrintToChat(client, "\x03              Oldest Name: %s", oldname);
	    	PrintToChat(client, "\x03              SteamID: %s", steamid);
	    	PrintToChat(client, "\x03              IP: %s\n\x03               Adminship: %s", ip, clienthasadmin);
	}
	if (args > 1)
	{
		PrintToChat(client, "\x04[\x03Whois\x04] \x01Invalid Usage.");
	}
}
