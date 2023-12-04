#include <sourcemod>
#include <socket>

#define PLUGIN_VERSION "2.0"
#define MAX_SERVERS 10
#define REFRESH_TIME 60.0
#define SERVER_TIMEOUT 10.0
#define MAX_STR_LEN 160
#define MAX_INFO_LEN 200

#define A2S_INFO "\xFF\xFF\xFF\xFF\x54Source Engine Query"
#define A2S_SIZE 25

new serverCount = 0;
new advertCount = 0;
new advertInterval = 1;
new serverPort[MAX_SERVERS];

new String:serverName[MAX_SERVERS][MAX_STR_LEN];
new String:serverAddress[MAX_SERVERS][MAX_STR_LEN];
new String:serverInfo[MAX_SERVERS][MAX_INFO_LEN];

new Handle:socket[MAX_SERVERS];
new bool:socketError[MAX_SERVERS];

new Handle:cv_hoptrigger = INVALID_HANDLE
new Handle:cv_serverformat = INVALID_HANDLE
new Handle:cv_broadcasthops = INVALID_HANDLE
new Handle:cv_advert = INVALID_HANDLE
new Handle:cv_advert_interval = INVALID_HANDLE

public Plugin:myinfo =
{
  name = "Server Hop",
  author = "[GRAVE] rig0r modded by Huck",
  description = "Provides live server info with join option",
  version = PLUGIN_VERSION,
  url = "http://www.gravedigger-company.nl"
};

public OnPluginStart()
{
  LoadTranslations("serverhop.phrases");

  // convar setup
  cv_hoptrigger = CreateConVar("sm_hop_trigger", "!servers", "What players have to type in chat to activate the plugin (besides !hop)");
  cv_serverformat = CreateConVar("sm_hop_serverformat", "%name - %map (%numplayers/%maxplayers)", "Defines how the server info should be presented");
  cv_broadcasthops = CreateConVar("sm_hop_broadcasthops", "1", "Set to 1 if you want a broadcast message when a player hops to another server");
  cv_advert = CreateConVar("sm_hop_advertise", "1", "Set to 1 to enable server advertisements");
  cv_advert_interval = CreateConVar("sm_hop_advertisement_interval", "1", "Advertisement interval: advertise a server every x minute(s)");

  AutoExecConfig(true, "plugin.serverhop");
  
  new Handle:timer = CreateTimer(REFRESH_TIME, RefreshServerInfo, _, TIMER_REPEAT);

  RegConsoleCmd("say", Command_Say);
  RegConsoleCmd("say_team", Command_Say);

  new String:path[MAX_STR_LEN];
  new Handle:kv;

  BuildPath(Path_SM, path, sizeof(path), "configs/serverhop.cfg");
  kv = CreateKeyValues("Servers");

  if (!FileToKeyValues(kv, path))
    LogToGame("Error loading server list");

  new i;
  KvRewind(kv);
  KvGotoFirstSubKey(kv);
  do {
    KvGetSectionName(kv, serverName[i], MAX_STR_LEN);
    KvGetString(kv, "address", serverAddress[i], MAX_STR_LEN);
    serverPort[i] = KvGetNum(kv, "port", 27015);
    i++;
  } while (KvGotoNextKey(kv));
  serverCount = i;

  TriggerTimer(timer);
}

public Action:Command_Say(client, args)
{
  new String:text[MAX_STR_LEN];
  new startidx = 0;

  if (!GetCmdArgString(text, sizeof(text))) {
    return Plugin_Continue;
  }

  if (text[strlen(text) - 1] == '"') {
    text[strlen(text)-1] = '\0';
    startidx = 1;
  }

  new String:trigger[MAX_STR_LEN];
  GetConVarString(cv_hoptrigger, trigger, sizeof(trigger));

  if (strcmp(text[startidx], trigger, false) == 0 || strcmp(text[startidx], "!hop", false) == 0) {
    ServerMenu(client);
  }

  return Plugin_Continue;
}

public Action:ServerMenu(client)
{
  new Handle:menu = CreateMenu(MenuHandler);
  new String:serverNumStr[MAX_STR_LEN];
  new String:menuTitle[MAX_STR_LEN];
  Format(menuTitle, sizeof(menuTitle), "%T", "SelectServer", client);
  SetMenuTitle(menu, menuTitle);

  for (new i = 0; i < serverCount; i++) {
    if (strlen(serverInfo[i]) > 0) {
      IntToString(i, serverNumStr, sizeof(serverNumStr));
      AddMenuItem(menu, serverNumStr, serverInfo[i]);
    }
  } 
  DisplayMenu(menu, client, 20);
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:infobuf[MAX_STR_LEN];
		new String:address[MAX_STR_LEN];

		GetMenuItem(menu, param2, infobuf, sizeof(infobuf));
		new serverNum = StringToInt(infobuf);

		// header
		new Handle:kvheader = CreateKeyValues("header");
		new String:menuTitle[MAX_STR_LEN];
		Format(menuTitle, sizeof(menuTitle), "%T", "AboutToJoinServer", param1);
		KvSetString(kvheader, "title", menuTitle);
		KvSetNum(kvheader, "level", 1);
		KvSetString(kvheader, "time", "10");
		CreateDialog(param1, kvheader, DialogType_Msg);
		CloseHandle(kvheader);
    
		// join confirmation dialog
		new Handle:kv = CreateKeyValues("menu");
		KvSetString(kv, "time", "10");
		Format(address, MAX_STR_LEN, "%s:%i", serverAddress[serverNum], serverPort[serverNum]);
		KvSetString(kv, "title", address);
		CreateDialog(param1, kv, DialogType_AskConnect);
		CloseHandle(kv);

		// broadcast to all
		if (GetConVarBool(cv_broadcasthops)) 
		{
			new String:clientName[MAX_NAME_LENGTH];
			GetClientName(param1, clientName, sizeof(clientName));
			PrintToChatAll("\x04[\x03Serverhop\x04]\x01 %t", "HopNotification", clientName, serverInfo[serverNum]);
		}
	}
}

public Action:RefreshServerInfo(Handle:timer)
{
	for (new i = 0; i < serverCount; i++) 
	{
		serverInfo[i] = "";
		socketError[i] = false;
		socket[i] = SocketCreate(SOCKET_UDP, OnSocketError);
		SocketSetArg(socket[i], i);
		SocketConnect(socket[i], OnSocketConnected, OnSocketReceive, OnSocketDisconnected, serverAddress[i], serverPort[i]);
	}
	CreateTimer(SERVER_TIMEOUT, CleanUp);
}

public Action:CleanUp(Handle:timer)
{
  for (new i = 0; i < serverCount; i++) {
    if (strlen(serverInfo[i]) == 0 && !socketError[i]) {
      LogError("Server %s:%i is down: no timely reply received", serverAddress[i], serverPort[i]);
      CloseHandle(socket[i]);
    }
  }

  // all server info is up to date: advertise
  if (GetConVarBool(cv_advert)) {
    if (advertInterval == GetConVarFloat(cv_advert_interval)) {
      Advertise();
    }
    advertInterval++;
    if (advertInterval > GetConVarFloat(cv_advert_interval)) {
      advertInterval = 1;
    }
  }
}

public Action:Advertise()
{
  new String:trigger[MAX_STR_LEN];
  GetConVarString(cv_hoptrigger, trigger, sizeof(trigger));

  // skip servers being marked as down
  while (strlen(serverInfo[advertCount]) == 0) {
    advertCount++;
    if (advertCount >= serverCount) {
      advertCount = 0;
      break;
    }
  }

  if (strlen(serverInfo[advertCount]) > 0) {
    PrintToChatAll("\x04[\x03Serverhop\x04]\x01 %t", "Advert", serverInfo[advertCount], trigger);

    advertCount++;
    if (advertCount >= serverCount) {
      advertCount = 0;
    }
  }
}

public void OnSocketConnected(Handle sock, any i) {
	SocketSend(sock, A2S_INFO, A2S_SIZE);
}

enum struct ByteReader {
	int data[1024];
	int size;
	int offset;

	void SetData(const char[] data, int dataSize, int offset) {
		for (int i = 0; i < dataSize; ++i) {
			this.data[i] = data[i];
		}
		this.data[dataSize] = 0;
		this.size = dataSize;
		this.offset = offset;
	}

	int GetByte() {
		return this.data[this.offset++];
	}

	void GetString(char[] str = "", int size = 0) {
		int j = 0;
		for (int i = this.offset; i < this.size; ++i, ++j) {
			if (j < size) {
				str[j] = this.data[i];
			}

			if (this.data[i] == '\x0') {
				break;
			}
		}
		this.offset += j + 1;
	}
}

public void OnSocketReceive(Handle sock, char[] data, const int dataSize, any arg) {

	ByteReader byteReader;
	byteReader.SetData(data, dataSize, 4); // begin at 5th byte, index 4

	// header
	if (byteReader.GetByte() == 'A') { // challenge response received
		static char reply[A2S_SIZE + 4] = A2S_INFO;

		for (int i = A2S_SIZE, j = byteReader.offset; i < sizeof(reply); ++i, ++j) {
			reply[i] = data[j];
		}
		
		SocketSend(sock, reply, sizeof(reply));

		return;
	}

	// skip protocol
	byteReader.offset += 1;

	char hostName[64];
	byteReader.GetString(hostName, sizeof(hostName));

	char mapName[80];
	byteReader.GetString(mapName, sizeof(mapName));

	// skip game directory
	byteReader.GetString();

	// skip game description
	byteReader.GetString();

	// skip gameid
	byteReader.offset += 2;

	int players = byteReader.GetByte();

	int maxPlayers = byteReader.GetByte();

	int bots = byteReader.GetByte();

	char format[MAX_STR_LEN];
	GetConVarString(cv_serverformat, format, sizeof(format));
	ReplaceString(format, strlen(format), "%name", serverName[arg], false);
	ReplaceString(format, strlen(format), "%hostname", hostName);
	ReplaceString(format, strlen(format), "%map", mapName, false);

	char playersStr[4];
	IntToString(players, playersStr, sizeof(playersStr));
	ReplaceString(format, strlen(format), "%numplayers", playersStr, false);

	char maxPlayersStr[4];
	IntToString(maxPlayers, maxPlayersStr, sizeof(maxPlayersStr));
	ReplaceString(format, strlen(format), "%maxplayers", maxPlayersStr, false);

	char humans[4];
	IntToString(players - bots, humans, sizeof(humans));
	ReplaceString(format, strlen(format), "%humans", humans, false);

	char botsStr[4];
	IntToString(bots, botsStr, sizeof(botsStr));
	ReplaceString(format, strlen(format), "%bots", botsStr, false);

	serverInfo[arg] = format;

	CloseHandle(sock);
}

public OnSocketDisconnected(Handle:sock, any:i)
{
  CloseHandle(sock);
}

public OnSocketError(Handle:sock, const errorType, const errorNum, any:i)
{
  LogError("Server %s:%i is down: socket error %d (errno %d)", serverAddress[i], serverPort[i], errorType, errorNum);
  socketError[i] = true;
  CloseHandle(sock);
}
