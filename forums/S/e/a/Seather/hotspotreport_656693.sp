#pragma semicolon 1
#include <sourcemod>
#include <downloader>
/*
feature/todo/ideas

User info ---
steamid
ip (no?)
name(trimmed)

server info ---
ip(source web server detects)
ip(multi ip box)
port
plugin version
mod

event info---
type

detect---
connect spam
name change spam
say spam
say spam by multiple clients
door way blocking, clump of players
spray checksum?
vote kick/ban spam in wide window
mic spam http://forums.alliedmods.net/showthread.php?p=633905
blank name?

ignore---
passworded server
admins
*/

#define MAXURLLEN 2048
new String:BaseURL[MAXURLLEN] = "http://www.joe.to/moo/hotspotreport.php";
new String:nullString[10];

new Handle:g_Cvar_ip = INVALID_HANDLE;
new Handle:g_Cvar_port = INVALID_HANDLE;

new VoteKickBanCount[MAXPLAYERS + 1];
new NameChangeCount[MAXPLAYERS + 1];
new SayCount[MAXPLAYERS + 1];

new SendCount = 0; //prevent central server from getting spammed in certain cases.

#define PLUGIN_VERSION "1"
public Plugin:myinfo =
{
	name = "Hot spot report",
	author = "Seather",
	description = "Auto detects interesting chaos and reports to a central server",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};


public OnPluginStart()
{
	ResetCountAll();
	
	g_Cvar_ip = FindConVar("ip"); //see sourcebans for "hostip", not "ip"
	g_Cvar_port = FindConVar("hostport");

	CreateTimer(30.0, RepeatProcess, _, TIMER_REPEAT);
	CreateTimer(300.0, RepeatProcess2, _, TIMER_REPEAT);
	
	//from: http://forums.alliedmods.net/showthread.php?p=499584
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say); //Insurgency
	RegConsoleCmd("say_team", Command_Say);
	
	//from: http://forums.alliedmods.net/showthread.php?p=498974
	HookEvent("player_changename", checkName);
	
	//RegConsoleCmd("test", Command_Test);
	
	//http://www.joe.to/moo/hotspotreport.php?sv_ip=localhost&eventid=test&sv_port=27015&p_version=1&sv_mod=cstrike&cl_steamid=STEAM_0:1:74989&cl_ip=192.168.1.47&cl_name=Posts&sv_map=de_dust
}

//public Action:Command_Test(client,args){
//	Report1(client,"test");
//	return Plugin_Handled;
//}

public Action:RepeatProcess(Handle:timer)
{
	//Count + Report
	new i;
	new size = sizeof(SayCount);
	new VoteKickBanCount2 = 0;
	for(i = 1;i < size;i++) {
		if(NameChangeCount[i] > 10)
			Report1(i,"namespam");
		if(SayCount[i] > 20)
			Report1(i,"sayspam");
		VoteKickBanCount2 = VoteKickBanCount2 + VoteKickBanCount[i];
	}
	if(VoteKickBanCount2 > 3)
		Report1(-1,"votekbspam");

	//Clear Count
	ResetCountAll();
	
	return Plugin_Continue;
}

public Action:RepeatProcess2(Handle:timer)
{
	SendCount = 0;
	return Plugin_Continue;
}
public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	ResetCount(client);
	return true;
}
public OnClientAuthorized(client, const String:auth[]) {
	
}
public OnClientDisconnect(client) {
	decl String:auth[50];
	GetClientAuthString(client, auth, sizeof(auth));


	ResetCount(client);
}

ResetCount(client) {
	VoteKickBanCount[client] = 0;
	NameChangeCount[client] = 0;
	SayCount[client] = 0;
}

ResetCountAll() {
	new i;
	new size = sizeof(SayCount);
	for(i = 0;i < size;i++) {
		ResetCount(i);
	}
}

Report1(client, const String:eventid[]) {

	if(client == -1) {
		Report2("null","null","null",eventid);
		return;
	}

	decl String:auth[50];
	GetClientAuthString(client, auth, sizeof(auth));
	
	decl String:ip[50];
	GetClientIP(client, ip, sizeof(ip));
	
	decl String:name[50];
	GetClientName(client, name, sizeof(name));
	Report2(auth,ip,name,eventid);
	
	
}
Report2(const String:cl_steamid[], const String:cl_ip[], const String:pre_cl_name[], const String:eventid[]) {

	if(SendCount >= 3)
		return;
	SendCount++;
	
	//cl_name, + clean it
	decl String:pre_cl_name2[50];
	Format(pre_cl_name2, sizeof(pre_cl_name2), "%s", pre_cl_name);
	new i;
	for(i = 0;i < strlen(pre_cl_name2);i++) {
		if(!IsCharNumeric(pre_cl_name2[i]) && !IsCharAlpha(pre_cl_name2[i]))
			pre_cl_name2[i] = ' ';
	}
	ReplaceString(pre_cl_name2, sizeof(pre_cl_name2), " ", "");
	decl String:cl_name[20];
	Format(cl_name, sizeof(cl_name), "%s", pre_cl_name2);
	
	//sv_ip
	decl String:sv_ip[64];
	if (g_Cvar_ip != INVALID_HANDLE) {
		GetConVarString(g_Cvar_ip, sv_ip, sizeof(sv_ip));
	} else {
		Format(sv_ip, sizeof(sv_ip), "?");
	}

	/*
	decl String:sv_ip[64];
	if (g_Cvar_ip != INVALID_HANDLE) {
		GetConVarString(g_Cvar_ip, sv_ip, sizeof(sv_ip));
		//from: sourcebans
		decl pieces[4];
		new longip = GetConVarInt(g_Cvar_ip);
		pieces[0] = (longip >> 24) & 0x000000FF;
		pieces[1] = (longip >> 16) & 0x000000FF;
		pieces[2] = (longip >> 8) & 0x000000FF;
		pieces[3] = longip & 0x000000FF;
		FormatEx(sv_ip, sizeof(sv_ip), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	} else {
		Format(sv_ip, sizeof(sv_ip), "?");
	}*/
	
	//sv_port
	decl String:sv_port[10];
	if (g_Cvar_port != INVALID_HANDLE) {
		GetConVarString(g_Cvar_port, sv_port, sizeof(sv_port));
	} else {
		Format(sv_port, sizeof(sv_port), "?");
	}
	//sv_mod
	decl String:sv_mod[32];
	GetGameFolderName(sv_mod, sizeof(sv_mod));
	
	//sv_map
	decl String:sv_map[64];
	GetCurrentMap(sv_map, sizeof(sv_map));
	
	//mix url + data
	decl String:tempurl[MAXURLLEN];
	Format(tempurl, sizeof(tempurl), "%s?sv_ip=%s&sv_port=%s&p_version=%s&sv_mod=%s&cl_steamid=%s&cl_ip=%s&cl_name=%s&eventid=%s&sv_map=%s", 
		BaseURL,sv_ip,sv_port,PLUGIN_VERSION,sv_mod,cl_steamid,cl_ip,cl_name,eventid,sv_map);

	//send data
	FireURL(tempurl);
	//PrintToServer("url %s",tempurl);

}

FireURL(const String:url[]) {
	new Handle:tempHandle;
	tempHandle = CreateDownloader();
	
	//URL
	decl String:tempurl[MAXURLLEN];
	Format(tempurl, sizeof(tempurl), "%s", url);
	SetURL(tempHandle, tempurl);

	SetCallback(tempHandle, update_Complete);
	SetProgressCallback(tempHandle, update_Progress);

	SetArg(tempHandle, tempHandle);
	
	SetOutputString(tempHandle, nullString, 5);

	Download(tempHandle);
}
public update_Progress(const recvSize, const totalSize, Handle:arg)
{
}
public update_Complete(const sucess, const status, Handle:arg)
{
	CloseHandle(arg);
}

//votekick/voteban
//from: http://forums.alliedmods.net/showthread.php?p=527208
public Action:OnLogAction(Handle:source, 
						   Identity:ident,
						   client,
						   target,
						   const String:message[])
{	
	if (StrContains(message, "votekick", false) == -1 
		&& StrContains(message, "voteban", false) == -1){
		return Plugin_Continue;
	}

	VoteKickBanCount[client]++;
	
	return Plugin_Continue;
}
public Action:Command_Say(client,args){
	SayCount[client]++;
	return Plugin_Continue;
}

public Action:checkName(Handle:event, const String:name[], bool:dontBroadcast){
	new playerId = GetEventInt(event, "userid");
	new player = GetClientOfUserId(playerId);
	
	NameChangeCount[player]++;
	
	return Plugin_Continue;
}