#include <sourcemod>
#include <sdktools>
#include <socket>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"

Handle clientSocket;
Handle CVAR_SteambotServerIP;
Handle CVAR_SteambotServerPort;
Handle CVAR_SteambotTCPPassword;
Handle CVAR_GroupID;
Handle TimerReconnect;
Handle ARRAY_Config;

char steambotIP[100];
char steambotPort[10];
char steambotPassword[25];
char steamID[40];
char AnouncementT[200];
char AnouncementB[200];
char groupID[100];

bool connected;

public Plugin myinfo = 
{
    name = "[ANY] Steambot - OnJoinAnouncement",
    author = PLUGIN_AUTHOR,
    description = "Write a anouncement into the steam group to warn about a specific player connection !",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
    CVAR_SteambotServerIP = CreateConVar("sm_steambot_server_ip", "XXX.XXX.XXX.XXX", "The ip of the server where the steambot is hosted.");
    CVAR_SteambotServerPort = CreateConVar("sm_steambot_server_port", "11000", "The port of the server where the steambot is hosted, WATCH OUT ! In version 1.0 of the bot, the port is hardcoded and is 11000 !!");
    CVAR_SteambotTCPPassword = CreateConVar("sm_steambot_tcp_password", "Pa$Sw0Rd", "The password to allow TCP data to be read / send (TCPPassword in settings.json)");
    CVAR_GroupID = CreateConVar("sm_steam_group_id", "XXXXXXXXXXXX", "The steam group id, can't be found in the xml fail (see OP in alliedmodders plugin's page)");
    
    AutoExecConfig(true, "Steambot_OnJoinAnouncement");
    
    GetConVarString(CVAR_SteambotServerIP, steambotIP, sizeof(steambotIP));
    GetConVarString(CVAR_SteambotServerPort, steambotPort, sizeof(steambotPort));
    GetConVarString(CVAR_SteambotTCPPassword, steambotPassword, sizeof(steambotPassword));
    GetConVarString(CVAR_GroupID, groupID, sizeof(groupID));
    
    AttemptSteamBotConnection();
    
    ReadConfig();
}
   
public void OnClientPostAdminCheck(int client)
{
	if(!connected)
	{
		PrintToServer("[Steambot - OnJoinAnouncement] Plugin not connected to the steambot, can't do anouncement.");
		return;
	}
		
	char clientSteamID[50];
	GetClientAuthId(client, AuthId_Steam2, clientSteamID, sizeof(clientSteamID));
	
	for(int i = 0; i < GetArraySize(ARRAY_Config); i++)
	{
		Handle tmpHashMap = GetArrayCell(ARRAY_Config, i);
		
		if(tmpHashMap != INVALID_HANDLE)
		{
			GetTrieString(tmpHashMap, "steamID", steamID, sizeof(steamID));
			PrintToServer("test : %s == %s", steamID, clientSteamID);
			if(StrEqual(clientSteamID, steamID))
			{
				GetTrieString(tmpHashMap, "AnouncementT", AnouncementT, sizeof(AnouncementT));
				GetTrieString(tmpHashMap, "AnouncementB", AnouncementB, sizeof(AnouncementB));
				
				char data[600];
				Format(data, sizeof(data), "%sSTEAMGROUP_POST_ANOUNCEMENT%s/%s/%s", steambotPassword, groupID, AnouncementT, AnouncementB);
				PrintToServer(data);
				SocketSend(clientSocket, data, sizeof(data));
				break;
			}
		}
	}
}   

public void ReadConfig()
{
	ARRAY_Config = CreateArray();
	
	char path[100];
	Handle kv = CreateKeyValues("Steambot_OnJoinAnouncement");
	Handle tmpTrie;
	BuildPath(Path_SM, path, sizeof(path), "/configs/Steambot_OnJoinAnouncement.cfg");
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv))
	    return;
	
	do
	{
	    KvGetString(kv, "steamID", steamID, sizeof(steamID));
	    KvGetString(kv, "Anouncement Title", AnouncementT, sizeof(AnouncementT));
	    KvGetString(kv, "Anouncement Body", AnouncementB, sizeof(AnouncementB));
	    
	    tmpTrie = CreateTrie();
	    SetTrieString(tmpTrie, "steamID", steamID);
	    SetTrieString(tmpTrie, "AnouncementT", AnouncementT);
	    SetTrieString(tmpTrie, "AnouncementB", AnouncementB);
	    
	    PushArrayCell(ARRAY_Config, tmpTrie);
	    
	}while(KvGotoNextKey(kv));
	
	CloseHandle(kv);  
}

//Steambot related stuff (connection)
public void AttemptSteamBotConnection()
{
    connected = false;
    clientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
    PrintToServer("Attempt to connect to %s:%i ...", steambotIP, StringToInt(steambotPort));
    SocketConnect(clientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, steambotIP, StringToInt(steambotPort));
}

public OnClientSocketConnected(Handle socket, any arg)
{
    PrintToServer(">>> Steambot - OnJoinAnouncement is CONNECTED to the steambot !");    
    connected = true;
    //Destroying the reconnect timer on failure :
    if(TimerReconnect != INVALID_HANDLE)
    {
        KillTimer(TimerReconnect);
        TimerReconnect = INVALID_HANDLE;
    }
}

public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
    connected = false; //Client NOT connected anymore, this is very important.
    LogError("socket error %d (errno %d)", errorType, errorNum);
    CloseHandle(socket);
}

public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
    //Nothing to do.
}

public OnChildSocketDisconnected(Handle socket, any hFile)
{
    //Connection to steam bot lost !
    PrintToServer(">>> Steambot - OnJoinAnouncement is DISCONNECTED to the steambot ! !");
    connected = false;
    CloseHandle(socket);
    
    TimerReconnect = CreateTimer(10.0, TMR_TryReconnection, _, TIMER_REPEAT);
}

public Action TMR_TryReconnection(Handle timer, any none)
{
    AttemptSteamBotConnection();
}  