#include <sourcemod>
#include <sdktools>
#include <socket>
#include <scp>
#include <multicolors>
#include <clientprefs>

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION 	"1.00"
#define PLUGIN_TAG		"{blue}[Cross Server Chat]{default}"
#define PLAYER_GAGED 	1
#define PLAYER_UNGAGED 	0
#define DISCONNECTSTR	"DISCONNECTMEPLSTHX"
#define SENDERNAME		"[SENDER NAME]"
#define SERVERTAG		"[SERVER TAG]"
#define SENDERMSG		"[MESSAGE]"

Handle serverSocket;
Handle globalClientSocket;
Handle COOKIE_ClientGaged;
Handle ARRAY_Connections;
Handle CVAR_MessageKey;
Handle CVAR_ConnectionPort;
Handle CVAR_ReconnectTime;
Handle CVAR_MasterServerIP;
Handle CVAR_MasterChatServer;
Handle CVAR_ServerTag;
Handle CVAR_SendMessageTag;
Handle CVAR_AdminFlag;
Handle CVAR_MsgFormat;

int gagState[MAXPLAYERS+1];

bool isMasterServer;
bool processing[MAXPLAYERS+1];
bool connected;

public Plugin myinfo = 
{
    name = "[ANY] Cross Server Chat",
    author = PLUGIN_AUTHOR,
    description = "Send message on all connected server !",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_cscgag", CMD_GagFromCrossServer, ADMFLAG_CHAT, "Ban/Unban a player from using the cross server chat functionality.");
	RegConsoleCmd("sm_msg", CMD_SendMessage, "Send a message to all server.");

	CVAR_MasterChatServer = CreateConVar("sm_csc_is_master_server", "0", "Is this server the master chat server ? 1 = yes | 0 = no", _, true, 0.0, true, 1.0);
	CVAR_MasterServerIP = CreateConVar("sm_csc_master_chat_server_ip", "123.467.89.10", "IP of the master chat server");
	CVAR_ConnectionPort = CreateConVar("sm_csc_connection_port", "2001", "On wich port should the plugin read & send the messages ?", _, true, 1025.0);
	CVAR_MessageKey = CreateConVar("sm_csc_message_key", "[PASSWORD]", "Wich key should the plugin use to send messages, KEEP PRIVATE !!!");
	CVAR_ReconnectTime = CreateConVar("sm_csc_reconnect_time", "45.00", "After how much time a connection should try to reconnect disconnected sockets ?", _, true, 5.0);
	CVAR_ServerTag = CreateConVar("sm_csc_server_tag", "[REMOTE MSG]", "Tag before messages coming from outside of the actual server");
	CVAR_SendMessageTag = CreateConVar("sm_csc_mark_to_send", "+", "Tag before chat messages to send to all other servers");
	CVAR_AdminFlag = CreateConVar("sm_csc_admin_flag", "NONE", "Putting a flag as value will restrict the usage to all players who hvae this flag, putting NONE don't restrict the acces.");
	CVAR_MsgFormat = CreateConVar("sm_csc_message_format", "{red}[SERVER TAG] {purple}->{default} {pink}[SENDER NAME]{default} {purple}said{default} [MESSAGE]", "Format of the message. Use the tag [SERVER TAG] to represent the value of 'CVAR_ServerTag', [SENDER NAME] for the player name who send the message, and [MESSAGE] to represent the message of teh player.");
	
	COOKIE_ClientGaged = RegClientCookie("sm_csc_client_gaged", "Store the gag state of the player.", CookieAccess_Private);
	
	ARRAY_Connections = CreateArray();
	
	for(new i = MaxClients; i > 0; --i)
	{
		if(!AreClientCookiesCached(i))
			continue;
		
		OnClientCookiesCached(i);
	}
	
	AutoExecConfig(true, "CrossServerChat");
}

//When the plugin is unloaded / reloaded
public void OnPluginEnd()
{
	//If the client is connected (and is not the master chat server (MCS)) send the qui messsage to MCS
	if(connected && !isMasterServer)
	{
		DisconnectFromMasterServer();
	}
	else if(isMasterServer)
	{
		CloseHandle(serverSocket);
		serverSocket = INVALID_HANDLE;
	}
}

public void OnConfigsExecuted()
{
	isMasterServer = GetConVarBool(CVAR_MasterChatServer);
	
	if(isMasterServer)
		CreateServer();	//This server is actually the MCS
	else
		ConnecToMasterServer(); //This server is a client server and want to connect to the MCS
}

//Load data from cookies
public OnClientCookiesCached(int client)
{
	//Get value of cookie and store it inside gagState[]
	char cookieValue[10];
	GetClientCookie(client, COOKIE_ClientGaged, cookieValue, sizeof(cookieValue));
	gagState[client] = StringToInt(cookieValue);
}

public Action CMD_SendMessage(client, args)
{
	char allArgs[90];
	GetCmdArgString(allArgs, sizeof(allArgs));

	char finalMessage[999];
	char key[20];
	char serverTag[60];
	char playerName[40];
	
	bool execute = false;
	char strFlag[100];
	GetConVarString(CVAR_AdminFlag, strFlag, sizeof(strFlag));
	
	if(!StrEqual(strFlag, "NONE"))
	{
		int flag = ReadFlagString(strFlag);
	
		if(CheckCommandAccess(client, "CAN_SEND_NETWORK_MESSAGES", flag, true))
			execute = true;
	}
	else
	{
		execute = true;
	}
		
	if(execute)
	{
		if(gagState[client] == PLAYER_GAGED)
		{
			Handle pack;
			char text[200];
			CreateDataTimer(0.5, PrintMessageOnChatMessage, pack);
			WritePackCell(pack, client);
			Format(text, sizeof(text), "%s You have been banned from using this command.", PLUGIN_TAG);
			WritePackString(pack, text);
		}
		else
		{
			GetConVarString(CVAR_ServerTag, serverTag, sizeof(serverTag));
			GetConVarString(CVAR_MessageKey, key, sizeof(key));
			GetConVarString(CVAR_MsgFormat, finalMessage, sizeof(finalMessage));
			Format(playerName, sizeof(playerName), "%N", client); //Little hack for chat colors user
			
			ReplaceString(finalMessage, sizeof(finalMessage), SENDERNAME, playerName);
			ReplaceString(finalMessage, sizeof(finalMessage), SERVERTAG, serverTag);
			ReplaceString(finalMessage, sizeof(finalMessage), SENDERMSG, allArgs);
			Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
			
			if(isMasterServer)
				SendToAllClients(finalMessage, sizeof(finalMessage), INVALID_HANDLE);
			else
				SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
		}
	}
	else
	{
		Handle pack;
		char text[200];
		CreateDataTimer(0.5, PrintMessageOnChatMessage, pack);
		WritePackCell(pack, client);
		Format(text, sizeof(text), "%s You don't have the right to do that.", PLUGIN_TAG);
		WritePackString(pack, text);	
	}
	
	return Plugin_Handled;
}

//I don't think commenting this block is needed.
public Action CMD_GagFromCrossServer(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(args != 1)
	{
		CPrintToChat(client, "%s Usage : sm_cscgag [TARGET]", PLUGIN_TAG);
		return Plugin_Handled;
	}
		
	char arg1[20];
	char tmp[10];
	char cookieValue[10];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetClientCookie(client, COOKIE_ClientGaged, cookieValue, sizeof(cookieValue));
	gagState[client] = StringToInt(cookieValue);
	
	int target = FindTarget(client, arg1, true);
	
	if(gagState[target] == PLAYER_GAGED)
	{
		CPrintToChat(client, "%s %N is now {green}ungaged{default} !", PLUGIN_TAG, target);	
		gagState[target] = PLAYER_UNGAGED;
	}
	else if(gagState[target] == PLAYER_UNGAGED)
	{
		CPrintToChat(client, "%s %N is now {fullred}gaged{default} !", PLUGIN_TAG, target);	
		gagState[target] = PLAYER_GAGED;
	}
	
	IntToString(gagState[client], tmp, sizeof(tmp));
	SetClientCookie(client, COOKIE_ClientGaged, tmp);
		
	return Plugin_Continue;		
}

public Action OnChatMessage(&author, Handle recipients, char[] name, char[] message)
{
	//If the author of the message if already sending anthoer message, skip
	//This boolean is made to avoid to send 423141 the same message.
	if(!processing[author])
	{
		processing[author] = true;		
		char finalMessage[999];
		char key[20];
		char serverTag[60];
		char sendChar[2];
		char playerName[40];
		
		//Get the character to define if the message is a net message (default '+')
		GetConVarString(CVAR_SendMessageTag, sendChar, sizeof(sendChar));	
		if(FindCharInString(message, sendChar[0]) == 0) //'+' as been found, continue :
		{
			bool execute = false;
			char strFlag[100];
			GetConVarString(CVAR_AdminFlag, strFlag, sizeof(strFlag)); //Get the admin flag from the cvar
			
			if(!StrEqual(strFlag, "NONE")) //If the admin flag is NONE, then, skip this small block and continue :
			{
				int flag = ReadFlagString(strFlag); //Create flag from string
			
				if(CheckCommandAccess(author, "CAN_SEND_NETWORK_MESSAGES", flag, true)) //Check acces level of the player
					execute = true;
			}
			else if(gagState[author] == PLAYER_GAGED) //If the player is gaged, block him.
			{
				Handle pack;
				char text[200];
				CreateDataTimer(0.5, PrintMessageOnChatMessage, pack);
				WritePackCell(pack, author);
				Format(text, sizeof(text), "%s You have been banned from using this command.", PLUGIN_TAG);
				WritePackString(pack, text);
				execute = false; //Can always execute the next part of code 
			}
			else
			{
				execute = true;
			}
				
			if(execute) //if the author is allowed to continue
			{
				//<-------------------------------------------------------------------
				GetConVarString(CVAR_ServerTag, serverTag, sizeof(serverTag));
				GetConVarString(CVAR_MessageKey, key, sizeof(key));
				GetConVarString(CVAR_MsgFormat, finalMessage, sizeof(finalMessage));
				Format(playerName, sizeof(playerName), "%N", author); //Little hack for chat colors user
				
				ReplaceString(finalMessage, sizeof(finalMessage), SENDERNAME, playerName);
				ReplaceString(finalMessage, sizeof(finalMessage), SERVERTAG, serverTag);
				ReplaceString(finalMessage, sizeof(finalMessage), SENDERMSG, message);
				Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
				//------------------------------------------------------------------->
				
				//This block above is just to build message, could make a function but too lazy.
			
			
				if(isMasterServer) //If the this server is the MCS, then send the message to all clients
					SendToAllClients(finalMessage, sizeof(finalMessage), INVALID_HANDLE);
				else // If the this server is NOT the MCS, send it to the MCS and he will send to all other clients
					SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
			}
			else //Player don't have acces to the command, send a delayed message (because we are on OnChatMessage hook)
			{
				Handle pack;
				char text[200];
				CreateDataTimer(0.5, PrintMessageOnChatMessage, pack);
				WritePackCell(pack, author);
				Format(text, sizeof(text), "%s You don't have the right to do that.", PLUGIN_TAG);
				WritePackString(pack, text);	
			}
		}
		
		processing[author] = false; //Processing is done, ready for next hook
	}
}
   
//In case a client get disconnected, reconnect him every X seconds
public Action TimerReconnect(Handle tmr, any arg)
{
	PrintToServer("Trying to reconnect to the master server...");
	ConnecToMasterServer();
}

//Allow you to print messages when OnChatMessage hook delayed by a timer
public Action PrintMessageOnChatMessage(Handle timer, Handle pack)
{
	char text[128];
	int client;
 
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack, text, sizeof(text));
	//Restoring pack has finished, go abive and print message.
 
	CPrintToChat(client, "%s", text);
}

//stocks

//Nah.
stock bool IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

//Socket callback

//When someone sucessfully connected to the server :
public OnSocketIncoming(Handle socket, Handle newSocket, char[] remoteIP, remotePort, any arg)
{
	if(isMasterServer) //This is the job of the MCS, he have to handle clients :
	{
		PrintToServer("Another server connected to the chat server ! (%s:%d)", remoteIP, remotePort);
		SocketSetReceiveCallback(newSocket, OnChildSocketReceive);			//Bla bla bla, you got it.	
		SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnected);	//Bla bla bla, you got it.
		SocketSetErrorCallback(newSocket, OnChildSocketError);				//Bla bla bla, you got it.
		PushArrayCell(ARRAY_Connections, newSocket); //Save the handle to the connection into a array to send futur messages
	}
}

//When the CLIENT (and not the MCS) connected to the MCS :
public OnClientSocketConnected(Handle socket, any arg)
{
	char ip[65];
	char port[6];
	GetConVarString(CVAR_MasterServerIP, ip, sizeof(ip));
	GetConVarString(CVAR_ConnectionPort, port, sizeof(port));
	
	PrintToServer("Sucessfully connected to master chat server ! (%s:%s)", ip, port);
	
	//Nothing much to say...
	
	connected = true; //Important boolean : Store the state of the connection for this server.
}

//When the server crash, we can't do something but wait for a admin to reload the plugin.
public OnServerSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("socket error %d (errno %d)", errorType, errorNum);
	int index = FindValueInArray(ARRAY_Connections, socket); //Look in the array of connection to see if the clients his inside
	if(index != -1) //Of the client is inside :
		RemoveFromArray(ARRAY_Connections, index); //Remove the client from connection, since he is disconnected
	CloseHandle(socket);
}

//When the client crash
public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	connected = false; //Client NOT connected anymore, this is very important.
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CreateTimer(GetConVarFloat(CVAR_ReconnectTime), TimerReconnect); //Ask for the plugin to reconnect to the MCS in X seconds
	CloseHandle(socket);
}

//When a client sent a message to the MCS OR the MCS sent a message to the client, and the MCS have to handle it :
public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	char key[20];
	GetConVarString(CVAR_MessageKey, key, sizeof(key)); 
	if(StrContains(receiveData, key) != -1) //The message contain the security key ?
	{
		ReplaceString(receiveData, dataSize, key, ""); //Remove the key from the message
		if(StrContains(receiveData, DISCONNECTSTR) != -1) //Is the message a quit message ?
		{
			ReplaceString(receiveData, dataSize, DISCONNECTSTR, ""); //Remove the quit string from the message
			int index = FindValueInArray(ARRAY_Connections, socket); //Look in the array of connection to see if the clients his inside
			if(index != -1) //Of the client is inside :
			{
				PrintToServer("Lost connection to %s. Removing from clients.", receiveData);
				RemoveFromArray(ARRAY_Connections, index); //Remove the client from connection, since he is disconnected
			}
		}
		else //The message is a simple message, print it.
		{
			PrintToServer(receiveData);
			CPrintToChatAll(receiveData);
		}
	}
	
	//If the message is coming from a client, then the server has to send it to ALL other clients :
	if(isMasterServer)
		SendToAllClients(receiveData, dataSize, socket);
}

//Called when the MCS disconnect, force the client to reconnect :
public OnChildSocketDisconnected(Handle socket, any hFile)
{
	if(!isMasterServer)
	{
		PrintToServer("Lost connection to master chat server, reconnecting...");
		connected = false; //Very important.
		CreateTimer(GetConVarFloat(CVAR_ReconnectTime), TimerReconnect); //Reconnecting timer
	}
	CloseHandle(socket);
}

//When a client crash :
public OnChildSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("child socket error %d (errno %d)", errorType, errorNum);
	int index = FindValueInArray(ARRAY_Connections, socket); //Look in the array of connection to see if the clients his inside
	if(index != -1) //Of the client is inside :
		RemoveFromArray(ARRAY_Connections, index); //Remove the client from connection, since he is disconnected
	CloseHandle(socket);
}

//stocks

//Stock to send a message to all clients :
stock void SendToAllClients(char[] finalMessage, int msgSize, Handle sender)
{
	//Loop through all clients :
	for(int i = 0; i < GetArraySize(ARRAY_Connections); i++)
	{
		//Get client :
		Handle clientSocket = GetArrayCell(ARRAY_Connections, i);
		if(clientSocket != INVALID_HANDLE && clientSocket != sender && SocketIsConnected(clientSocket))
		{
			SocketSend(clientSocket, finalMessage, msgSize);
		}
	}
}

//Create the server
stock void CreateServer()
{
	if(serverSocket == INVALID_HANDLE)
	{
		serverSocket = SocketCreate(SOCKET_TCP, OnServerSocketError);
		SocketBind(serverSocket, "0.0.0.0", GetConVarInt(CVAR_ConnectionPort)); //Listen everything
		SocketListen(serverSocket, OnSocketIncoming);	
		PrintToServer("Server created succesfullly ! Waiting for clients...");
	}
}

stock void DisconnectFromMasterServer()
{
	//Build the disconnecting message
	char finalMessage[400];
	char serverName[45];
	char key[45];
	GetConVarString(CVAR_MessageKey, key, sizeof(key));
	GetConVarString(FindConVar("hostname"), serverName, sizeof(serverName));
	Format(finalMessage, sizeof(finalMessage), "%s%s%s", key, DISCONNECTSTR, serverName);
	//Send the disconnecting message
	SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	CloseHandle(globalClientSocket);
	globalClientSocket = INVALID_HANDLE;	
}

//Connect to the MCS
stock void ConnecToMasterServer()
{
	if(isMasterServer)
		return;
		
	connected = false;
	globalClientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	char chatServerIP[60];
	int port = GetConVarInt(CVAR_ConnectionPort);
	GetConVarString(CVAR_MasterServerIP, chatServerIP, sizeof(chatServerIP));
	PrintToServer("Attempt to connect to %s:%i ...", chatServerIP, port);
	SocketConnect(globalClientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, chatServerIP, port);	
}