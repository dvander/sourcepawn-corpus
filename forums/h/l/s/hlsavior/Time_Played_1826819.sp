#include <sourcemod>

static String:TPPath[PLATFORM_MAX_PATH];
new Handle:ClientTimer[32];
static Minutes[32];

//INFO
public Plugin:myinfo = {
	name = "HowLong",
	author = "hlsavior",
	description = "How long have you been playing?",
	url = "www.scnggames.com"
};


//ON START
public OnPluginStart()
{
	CreateDirectory("addons/sourcemod/data/stats", 0);
	BuildPath(Path_SM, TPPath, sizeof(TPPath), "data/stats/timeplayed.txt");
	RegConsoleCmd("sm_timeplayed", Command_getTime, "");
}

//IN SERVER
public OnClientPutInServer(client)
{
	AltTime(client, 1);
	ClientTimer[client] = (CreateTimer(60.0, TimerAdd, client, TIMER_REPEAT))
}

//LEAVE SERVER
public OnClientDisconnect(client)
{
	CloseHandle(ClientTimer[client]);
	AltTime(client, 0)
}

//TIMER
public Action:TimerAdd(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		Minutes[client]++;
	}
}

//COMMAND
public Action:Command_getTime(client, args)
{
    PrintToChat(client, "\x05You have played on this server for \x03%d\x05 minutes!", Minutes[client])
    return Plugin_Handled;
}  

//CHANGE
public AltTime(client, connection)
{
	new Handle:DB = CreateKeyValues("TimePlayed");
	FileToKeyValues(DB, TPPath);
	
	new String:SID[32];
	GetClientAuthString(client, SID, sizeof(SID));
	
	if(connection == 1)
	{
		//Connected
		if(KvJumpToKey(DB, SID, true))
		{
			new String:name[MAX_NAME_LENGTH], String:temp_name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			
			KvGetString(DB, "name", temp_name, sizeof(temp_name), "NULL");
			
			Minutes[client] = KvGetNum(DB, "minutes", 0);
		
			KvSetNum(DB, "minutes", Minutes[client])
		}
	}else if(connection == 0)
	{
		//Not Connected
		if(KvJumpToKey(DB, SID, true))
		{
			KvSetNum(DB, "minutes", Minutes[client]);
		}
	}
	
	KvRewind(DB);
	KeyValuesToFile(DB, TPPath);
	CloseHandle(DB);
}

