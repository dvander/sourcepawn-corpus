#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <socket>
#undef REQUIRE_PLUGIN
#include <zephyrus_store>

#define PLUGIN_NAME 		"[ANY] Steambot credits"
#define PLUGIN_AUTHOR 		"Arkarr"
#define PLUGIN_VERSION 		"1.00"
#define PLUGIN_DESCRIPTION 	"Give credits when user trade with bot."
#define PLUGIN_TAG			"{purple}[Steambot Credits]{default}"

Handle clientSocket;
Handle CVAR_SteambotServerIP;
Handle CVAR_SteambotServerPort;
Handle CVAR_SteambotTCPPassword;
Handle TRIE_TF2Values;
Handle TimerReconnect;

char steambotIP[100];
char steambotPort[10];
char steambotPassword[25];

public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	CVAR_SteambotServerIP = CreateConVar("sm_steambot_server_ip", "XXX.XXX.XXX.XXX", "The ip of the server where the steambot is hosted.");
	CVAR_SteambotServerPort = CreateConVar("sm_steambot_server_port", "11000", "The port of the server where the steambot is hosted, WATCH OUT ! In version 1.0 of the bot, the port is hardcoded and is 11000 !!");
	CVAR_SteambotTCPPassword = CreateConVar("sm_steambot_tcp_password", "Pa$Sw0Rd", "The password to allow TCP data to be read / send (TCPPassword in settings.json)");

	AutoExecConfig(true, "SteamBot_StoreCredits");
}

public void OnConfigsExecuted()
{
	GetConVarString(CVAR_SteambotServerIP, steambotIP, sizeof(steambotIP));
	GetConVarString(CVAR_SteambotServerPort, steambotPort, sizeof(steambotPort));
	GetConVarString(CVAR_SteambotTCPPassword, steambotPassword, sizeof(steambotPassword));
	
	TRIE_TF2Values = ReadConfigFile();
	
	AttemptSteamBotConnection();
}

public void ProcessMessage(char[] receiveData, int dataSize)
{
	//Password removed, priting the message :
	if (StrContains(receiveData, "TRADEOFFER_ENDED") != -1)
	{
		ReplaceString(receiveData, dataSize, "TRADEOFFER_ENDED|", "");
		
		//steamid,itemtoget, itemtogive
		char SteamIDIGetIGiveValue[4][600];
		ExplodeString(receiveData, "|", SteamIDIGetIGiveValue, sizeof SteamIDIGetIGiveValue, sizeof SteamIDIGetIGiveValue[]);
		
		//Item to receive
		char defIndex[900][6];
		ExplodeString(SteamIDIGetIGiveValue[1], ",", defIndex, sizeof defIndex, sizeof defIndex[]);
		int i = 0;
		int credits = 0;
		while (!StrEqual(defIndex[i], ""))
		{
			int value;
			if(GetTrieValue(TRIE_TF2Values, defIndex[i], value))
				credits += value;
			i++;
		}
		
		credits += 1000 * StringToInt(SteamIDIGetIGiveValue[3]);
		
		char auth[40];
		char steamID[40];
		int client = -1;
		Format(steamID, sizeof(steamID), SteamIDIGetIGiveValue[0]);
		
		for (int z = 0; z < MaxClients; z++)
		{
			if (IsValidClient(z))
			{
				GetClientAuthId(z, AuthId_Steam2, auth, sizeof(auth));
				if (StrEqual(auth, steamID))
				{
					client = z;
					break;
				}
			}
		}
		
		
		if (client != -1)
		{
			Store_SetClientCredits(client, Store_GetClientCredits(client) + credits);
			CPrintToChat(client, "%s +%i credits added to your balance, have fun !", PLUGIN_TAG, credits);
		}
		else
		{
			PrintToServer("NO CLIENTS FOUND, TRADE ACCEPTED BUT CLIENT DIDN'T GET POINTS ! Need to fix that somedays... [Arkarr]");
		}
	}
}

//Steam bot related stuff (template)
public void AttemptSteamBotConnection()
{
	clientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	PrintToServer("Attempt to connect to %s:%i ...", steambotIP, StringToInt(steambotPort));
	SocketConnect(clientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, steambotIP, StringToInt(steambotPort));
}

public OnClientSocketConnected(Handle socket, any arg)
{
	/*
	>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	We NEED to send the data 'REQUEST_CONNECTION' ONCE and AT THE FIRST CONNECTION so the steambot register us in his client list.
   	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	*/
	PrintToServer(">>> CONNECTED !");
	char data[200];
	char map[100];
	GetHostName(map, sizeof(map));
	Format(data, sizeof(data), "%sREQUEST_CONNECTION%s", steambotPassword, map);
	SocketSend(clientSocket, data, sizeof(data));
	
	//Destroying the reconnect timer on failure :
	if (TimerReconnect != INVALID_HANDLE)
	{
		KillTimer(TimerReconnect);
		TimerReconnect = INVALID_HANDLE;
	}
}

public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	if(StrContains(receiveData, steambotPassword) != -1)
	{
		ReplaceString(receiveData, dataSize, steambotPassword, "");
		
		ProcessMessage(receiveData, dataSize);
	}
}

public OnChildSocketDisconnected(Handle socket, any hFile)
{
	PrintToServer(">>> DISCONNECTED !");
	CloseHandle(socket);
	
	TimerReconnect = CreateTimer(10.0, TMR_TryReconnection, _, TIMER_REPEAT);
}

public Action TMR_TryReconnection(Handle timer, any none)
{
	AttemptSteamBotConnection();
}

stock void GetHostName(char[] str, size)
{
	Handle hHostName;
	
	if (hHostName == INVALID_HANDLE)
		if ((hHostName = FindConVar("hostname")) == INVALID_HANDLE)
		return;
	
	GetConVarString(hHostName, str, size);
}

stock Handle ReadConfigFile()
{
	Handle TmpTrie = CreateTrie();
	char path[PLATFORM_MAX_PATH]
	char line[30];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/Steambot_CustomPrices.txt");
	if(FileExists(path))
	{
		Handle configFile = OpenFile(path, "r");
		while(!IsEndOfFile(configFile) && ReadFileLine (configFile, line, sizeof(line)))
		{
			char itemIndexValue[2][10];
			ExplodeString(line, ":", itemIndexValue, sizeof itemIndexValue, sizeof itemIndexValue[]);
			SetTrieValue(TmpTrie, itemIndexValue[0], StringToInt(itemIndexValue[1]));
		}
		CloseHandle(configFile);
	}
	
	return TmpTrie;
}

stock bool IsValidClient(iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
} 