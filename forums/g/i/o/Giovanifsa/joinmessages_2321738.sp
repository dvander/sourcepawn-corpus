#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#tryinclude <updater>

new Handle:msgnamehandle;
new Handle:msgon;
static String:KVPath[PLATFORM_MAX_PATH];

#define PLUGIN_VERSION "1.1.1"
#define UPDATE_URL "https://giovanifsa.jhost.org/images/sampledata/plugins/joinmessages/update.txt"

public Plugin:myinfo = {
	name = "[ANY] Simple client join messages",
	author = "Nescau",
	description = "Prints a message when a specific client joins",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

public OnPluginStart()
{
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/messages.txt");
	msgon = CreateConVar("sm_msgon ", "1", "Enables or disables the plugin [ANY] Simple client join messages");
	msgnamehandle = CreateConVar("sm_msgnames", "0", "Defines if the plugin will show the client name before the message.");
	
	#if defined _updater_included
		if (LibraryExists("updater"))
		{
			Updater_AddPlugin(UPDATE_URL);
		}
	#endif
}

public OnLibraryAdded(const String:name[])
{
	#if defined _updater_included
		if (StrEqual(name, "updater"))
		{
			Updater_AddPlugin(UPDATE_URL);
		}
	#endif
}

#if defined _updater_included

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}

#endif

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(msgon))
	{
		PrintClientMessage(client);
	}	
}

public PrintClientMessage(client)
{
	new String:clientIP[128];
	new String:clientID[128];
	new String:clientName[MAX_NAME_LENGTH];
	GetClientIP(client, clientIP, 128);
	GetClientAuthId(client, AuthId_Steam3, clientID, 128);
	GetClientName(client, clientName, sizeof(clientName));
	
	new bool:authIDfound;
	new bool:IPfound;
	
	new Handle:DB = CreateKeyValues("Messages");
	FileToKeyValues(DB, KVPath);
	new String:messageString[256];
	new String:messageArea[10];
	
	if(KvJumpToKey(DB, clientID, false))
	{	
		KvGetString(DB, "message", messageString, 256, "EMPTY");
		KvGetString(DB, "area", messageArea, 10, "EMPTY");
		if (!StrEqual(messageString, "EMPTY") || !StrEqual(messageArea, "EMPTY"))
		{
			authIDfound = true;
		}
	}
	
	if (KvJumpToKey(DB, clientIP, false))
	{
		if (!authIDfound)
		{
			KvGetString(DB, "message", messageString, 256, "EMPTY");
			KvGetString(DB, "area", messageArea, 10, "EMPTY");
			
			if (!StrEqual(messageString, "EMPTY") || !StrEqual(messageArea, "EMPTY"))
			{
				IPfound = true;
			}
		}
		
	}

	KvRewind(DB);
	KeyValuesToFile(DB, KVPath);
	CloseHandle(DB);
	
	if (authIDfound || IPfound)
	{
		PrintMessage(client, messageString, messageArea);
	}
}

public PrintMessage(client, const String:message[], const String:area[])
{
	new messagearea;
	new String:clientID[128];
	new String:clientIP[128];
	new String:clientName[MAX_NAME_LENGTH];
	
	GetClientAuthId(client, AuthId_Steam3, clientID, 128);
	GetClientIP(client, clientIP, 128);
	GetClientName(client, clientName, sizeof(clientName));
	
	if (StrEqual(area, "chat", false))
	{
		messagearea = 1;
	}
	else if (StrEqual(area, "center", false))
	{
		messagearea = 2;
	}
	else if (StrEqual(area, "hint", false))
	{
		messagearea = 3;
	}
	else {
		PrintToServer("[ANY] Simple client join messages: Player %s with SteamID %s and IP %s have a incorrect message area.",clientName, clientID, clientIP);
	}
	
	new bool:format = GetConVarBool(msgnamehandle);
	new String:messageTemp[256];
	if (format)
	{
		Format(messageTemp, 256, "%s : %s",clientName, message);
	} else {
		strcopy(messageTemp, 256, message);
	}
	
	if (messagearea == 1)
	{
		CPrintToChatAll(message);
	}
	else if (messagearea == 2)
	{
		PrintCenterTextAll(message);
	}
	else if (messagearea == 3)
	{
		PrintHintTextToAll(message);
	}
}