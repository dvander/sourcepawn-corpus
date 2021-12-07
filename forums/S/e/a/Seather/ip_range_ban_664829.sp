#pragma semicolon 1
#include <sourcemod>

/*

example server.cfg:
sm_iprangeban_clear
sm_iprangeban_add "127.0.0.0" "127.0.0.255"
sm_iprangeban_add "192.168.0.0" "192.168.255.255"

TODO: IP v6 support

*/
public Plugin:myinfo =
{
	name = "IP Range Ban",
	author = "Seather",
	description = "Ban ranges of IP v4 addresses via cfg",
	version = "0.0.1",
	url = "http://www.sourcemod.net"
};

#define MAX_BANS 50
#define MAX_IP_LEN 20

new String:IPStartArray[MAX_BANS][MAX_IP_LEN];
new String:IPEndArray[MAX_BANS][MAX_IP_LEN];
new g_BanCount = 0;

public OnPluginStart()
{
	RegServerCmd("sm_iprangeban_add",Command_add);
	RegServerCmd("sm_iprangeban_clear",Command_clear);
}

public Action:Command_add(args) {
	if(g_BanCount == MAX_BANS) {
		LogError("Max number of IP range bans reached");
		return;
	}
	decl String:arg[MAX_IP_LEN];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:arg2[MAX_IP_LEN];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	strcopy(IPStartArray[g_BanCount], MAX_IP_LEN, arg);
	strcopy(IPEndArray[g_BanCount], MAX_IP_LEN, arg2);
		
	g_BanCount++;
}

public Action:Command_clear(args) {
	g_BanCount = 0;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	
	decl String:ip[50];
	GetClientIP(client, ip, sizeof(ip));
	
	new i;
	for(i = 0; i < g_BanCount; i++) {
		new ia = IPCompare(ip,IPStartArray[i]);
		new ib = IPCompare(ip,IPEndArray[i]);
		if((ia != -1) && (ib != 1)) {
			//PrintToServer("IP range ban triggered");
			
			//kick #2
			CreateTimer(0.1, KickThem, client);
			
			//kick #1
			//does not work?
			strcopy(rejectmsg, maxlen, "Banned");
			return false;
			
		}
	}
	
	//ok
	return true;
}

//http://forums.alliedmods.net/showthread.php?p=647017
public Action:KickThem(Handle:timer, any:client)
{
    if (IsClientConnected(client))
        KickClient(client, "Banned");
    return Plugin_Stop;
}

public IPCompare(String:str_a[],String:str_b[]) {
// return values
// 1 a > b
// 0 a == b
// -1 a < b
	
	new String:a_tokens[7][10];
	ExplodeString(str_a,".",a_tokens,7,10);
	
	new String:b_tokens[7][10];
	ExplodeString(str_b,".",b_tokens,7,10);
	
	new i;
	for(i = 0; i < 4;i++) {
		new ia = StringToInt(a_tokens[i]);
		new ib = StringToInt(b_tokens[i]);
		//PrintToServer("comp: %i %i",ia, ib);
		if(ia == ib)
			continue;
		if(ia > ib)
			return 1;
		if(ia < ib)
			return -1;
	}
	
	//equal
	return 0;
	
}
