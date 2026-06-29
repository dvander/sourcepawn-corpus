#include <sourcemod>
#include <socket>
#include <sdktools>
#include <morecolors>

#define CHAR_PERCENT "%"
#define CHAR_NULL "\0"
#define CHAT_SYMBOL '@'
#define PLUGIN_VERSION "1.1.5"



public Plugin:myinfo = {
	name = "SteamRep Checker",
	author = "jameless",
	description = "Check to see if connecting player is a reported scammer",
	version = PLUGIN_VERSION,
	url = "http://steamrep.com/"
};

new Handle:g_scammerchoice=INVALID_HANDLE;
new Handle:g_banlength=INVALID_HANDLE;
new Handle:g_baniplength=INVALID_HANDLE;
new Handle:g_kick_renamed_scammers;
new String:logFile[1024];
new bool:g_IsScammer[MAXPLAYERS+1];
new Handle:g_exclude=INVALID_HANDLE;
new Handle:g_checkIP;

public OnPluginStart() {
	AutoExecConfig(true,"steamrep");
	LoadTranslations("common.phrases");
	g_scammerchoice=CreateConVar("sr_scammer","0","How to handle the scammer. 0-Rename with [SCAMMER] tag, 1-Kick, 2-Ban for X minutes (configured by sr_bantime), 3-Same as 2 but also ban ip for Y minutes (configured by sr_baniptime)");
	g_banlength=CreateConVar("sr_bantime","10","If sr_scammer is set to 2 or 3, this is where you set how long to ban the user for, in minutes");
	g_baniplength=CreateConVar("sr_baniptime","10","If sr_scammer is set to 3, this is where you set how long to ban the ip for, in minutes");
	g_kick_renamed_scammers=CreateConVar("sr_kick_renamed_scammers","1","Kick a scammer when the server is full. Set to 0 to disable");
	g_exclude=CreateConVar("sr_exclude","","Which tags you DO NOT trust for reported scammers. Input the tags here for any community whose bans you DO NOT TRUST.");
	g_checkIP=CreateConVar("sr_checkip","1","Include IP address of connecting players in query. Set to 0 to disable");
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/steamrep.log");
	RegConsoleCmd("sm_sr", Command_SR,"Check the SteamRep page of another player");
	RegConsoleCmd("sm_rep", Command_SR,"Check the SteamRep page of another player");
	CreateConVar("sr_checker_version", PLUGIN_VERSION, "SteamRep Checker Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

// kick a scammer if we are full
public KickAScammer() {
    if(GetConVarInt(g_scammerchoice) != 0 || GetConVarInt(g_kick_renamed_scammers) == 0)
        return;
    
    new maxplayers = GetConVarInt(FindConVar("sv_visiblemaxplayers"));
    if(maxplayers == -1)
        maxplayers = MaxClients;
    
    if(GetClientCount(false) >= maxplayers) {
        for(new i=1;i<=MaxClients;i++) {
            if(IsClientConnected(i) && !IsFakeClient(i) && g_IsScammer[i]) {
                KickClient(i, "You were kicked to free a slot because you are a reported scammer.");
                break;
            }
        }
    }
}

public OnClientConnected(client) { 
	g_IsScammer[client]=false; 
}

public OnClientPostAdminCheck(client) {
	g_IsScammer[client]=false;
	KickAScammer();
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket, GetClientUserId(client));
	SocketSetOption(socket, SocketSendTimeout, 5160);
	SocketSetOption(socket, SocketReceiveTimeout, 5160);
	// connect the socket
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamrep.com", 80);
}

public OnConfigsExecuted() {
	if (GetConVarInt(g_scammerchoice)==0){
		HookEvent("player_changename", OnClientChangeName);
		RegConsoleCmd("say", Command_Say);
		RegConsoleCmd("say_team", Command_SayTeam);
	}
}


public OnSocketConnected(Handle:socket, any:userid) {
	// socket is connected, send the http request
	new client = GetClientOfUserId(userid);

	if(client == 0) {
		CloseHandle(socket);
		return;
	}
	if(IsClientConnected(client) && !CheckCommandAccess(client, "SkipSR", ADMFLAG_ROOT, true) && !IsFakeClient(client)) {
		decl String:steamid[32];
		decl String:requestStr[450];
		decl String:excludetags[128];
		decl String:ip[17]="";

		if(GetConVarInt(g_checkIP) == 1){GetClientIP(client,ip,sizeof(ip));}
		GetClientAuthString(client,steamid,sizeof(steamid));
		GetConVarString(g_exclude,excludetags,sizeof(excludetags));
		Format(requestStr, sizeof(requestStr), "GET /%s%s%s%s%s%s%s%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", "id2rep.php?steamID32=",steamid,"&ignore=",excludetags,"&IP=",ip,"&version=",PLUGIN_VERSION,"steamrep.com");
		SocketSend(socket, requestStr);
	}else{
		CloseHandle(socket);
	}
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:userid) {
	// receive chunk
	new client = GetClientOfUserId(userid);
	if(client == 0) {
        CloseHandle(socket);
        return;
    }
	HandleString(receiveData,client);
}

public OnSocketDisconnected(Handle:socket, any:client) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:client) {
	// a socket error occured
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public HandleScammer(client,String:scamid32[]) {
	// Kick or ban the scammer
	new time=GetConVarInt(g_banlength);
	new iptime=GetConVarInt(g_baniplength);
	new choice=GetConVarInt(g_scammerchoice);
	new String:reason[64]="Player is a reported scammer";
	new String:ipreason[64]="A scammer has connected from this IP. steamid: ";
	decl String:steamid[42];
	GetClientAuthString(client,steamid,sizeof(steamid));
	decl String:ip[17];
	GetClientIP(client,ip,sizeof(ip));
	
	if(StrEqual(steamid,scamid32,false)){
		switch(choice)
		{
			case 0: {
			
				LabelScammer(client);
				g_IsScammer[client]=true;
				LogToFile(logFile,"%s was renamed as [SCAMMER]",steamid);
				KickAScammer();
				CreateTimer(5.0,checkname,GetClientUserId(client));
			}
			case 1: {
				
				KickClient(client,"You are a reported Scammer");
				LogToFile(logFile,"%s was kicked.",steamid);
			}	
			case 2: {
				
				ServerCommand("sm_ban #%d %d \"%s\"",GetClientUserId(client),time,reason);
				LogToFile(logFile,"%s was banned.",steamid);
			}
			case 3: {
				
				ServerCommand("sm_ban #%d %d \"%s\"",GetClientUserId(client),time,reason);
				ServerCommand("sm_banip #%d %d \"%s%s\"",GetClientUserId(client),iptime,ipreason,steamid);
				LogToFile(logFile,"%s was banned. IP: %s",steamid,ip);
			}
		
		}
	}else{
		LogToFile(logFile,"Streams were crossed for %s",scamid32);
	}
}

public HandleString(String:receiveData[],client) {
	//Parse String
	decl String:reps[3][35];
	new String:scammer[8]="SCAMMER";
	ExplodeString(receiveData,"&",reps,sizeof(reps),sizeof(reps[]));
	if((StrContains(reps[1],scammer,false))>0){HandleScammer(client,reps[2]);}
	if(!StrEqual(reps[1]," ")){LogToFile(logFile,"Rep:%s Steamid:%s",reps[1],reps[2]);}
}

public Action:OnClientChangeName(Handle:event, const String:name[], bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:newname[MAX_NAME_LENGTH];
	GetEventString(event, "newname", newname, sizeof(newname));
	if (g_IsScammer[client]){
		if (!StartsWithScammer(newname)) { KickClient(client,"Do not try to rename yourself to remove the SCAMMER label"); }
	}	
}

public LabelScammer (client) {
	
	decl String:name[32];
	new String:tag[42]="[SCAMMER] ";
	GetClientName(client,name,sizeof(name));
	if(!StartsWithScammer(name)){
		StrCat(tag,42,name);
		SetClientInfo(client, "name", tag);
		CPrintToChatEx(client,client, "{yellow}You were renamed for being a reported scammer. Renaming yourself will get you kicked.");
	}
}

public Action:Command_Say(client, args)
{
	
	if (client == 0 || !g_IsScammer[client])
	{
		return Plugin_Continue;
	}
	
	decl	String:sMessage[1024];
	GetCmdArgString(sMessage, sizeof(sMessage));
	return ProcessMessage(client, false, sMessage, sizeof(sMessage));
}

public Action:Command_SayTeam(client, args)
{
	
	if (client == 0 || !g_IsScammer[client])
	{
		return Plugin_Continue;
	}
	
	decl	String:sMessage[1024];
	GetCmdArgString(sMessage, sizeof(sMessage));
	return ProcessMessage(client, true, sMessage, sizeof(sMessage));
}

stock Action:ProcessMessage(client, bool:teamchat, String:message[], maxlength)
{
	
	decl String:sChatMsg[1280];
	StripQuotes(message);
	TrimString(message);
	ReplaceString(message, maxlength, CHAR_PERCENT, CHAR_NULL);
	if (IsStringBlank(message))	{
		return Plugin_Stop;
	}
	if (message[0] == CHAT_SYMBOL) {
		return Plugin_Continue;
	}
	FormatMessage(client, GetClientTeam(client), IsPlayerAlive(client), teamchat, message, sChatMsg, sizeof(sChatMsg));
	new iCurrentTeam = GetClientTeam(client);
	if (teamchat)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == iCurrentTeam)
			{
				CPrintToChatEx(i,i, "%s", sChatMsg);
			}
		}
	}
	else
	{
		CPrintToChatAllEx(client,"%s", sChatMsg);
	}
	return Plugin_Stop;
}

stock FormatMessage(client, team, bool:alive, bool:teamchat, const String:message[], String:chatmsg[], maxlength)
{
	decl String:sDead[10], String:sTeam[15], String:sClientName[64];	
	GetClientName(client, sClientName, sizeof(sClientName));
	
	if (teamchat) {
		if (team != 1) {
			Format(sTeam, sizeof(sTeam), "(TEAM) ");
		}
		else {
			Format(sTeam, sizeof(sTeam), "(Spectator) ");
		}
	}
	else {
		if (team != 1) {
			Format(sTeam, sizeof(sTeam), "");
		}
		else {
			Format(sTeam, sizeof(sTeam), "*SPEC* ");
		}
	}
	if (team != 1) {
		if (alive) {
			Format(sDead, sizeof(sDead), "");
		}
	}
	else {
		Format(sDead, sizeof(sDead), "");
	}
	
	new String:sNameColor[15]="{teamcolor}";
	new String:sTextColor[15]="{default}";
	new String:sTagText[24]="[SCAMMER] ";
	new String:sTagColor[15]="{red}";
	
	Format(chatmsg, maxlength, "{default}%s%s%s%s%s%s {default}:  %s%s", sDead, sTeam, sTagColor, sTagText, sNameColor, sClientName, sTextColor, message);
}

stock bool:IsStringBlank(const String:input[]) {
	new len = strlen(input);
	for (new i=0; i<len; i++) {
		if (!IsCharSpace(input[i])) {
			return false;
		}
	}
	return true;
}

public Action:Command_SR(client,args) {
	if(client==0) {
	ReplyToCommand(client,"This only works when you are in the game");
	return Plugin_Handled;
	}
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	new target = FindTarget(client, arg1, true, false);
	if(target == -1) { target = GetClientAimTarget(client);}
	if(target == -1 || target == -2) {
	PrintToChat(client,"[SteamRep] Invalid Target Specified");
	return Plugin_Handled;
	}
	decl String:steamid[42];
	GetClientAuthString(target,steamid,sizeof(steamid));
	new String:url[128]="http://steamrep.com/index.php?id=";
	StrCat(url,128,steamid);
	ShowMOTDPanelBIG( client, "SteamRep", url, MOTDPANEL_TYPE_URL );
	return Plugin_Handled;
}

public bool:StartsWithScammer(String:str[]) {
	new String:scammer[] = "[SCAMMER]";
	if(strlen(scammer) > strlen(str)) {return false;}
	for(new i=0;i<(sizeof(scammer)-1);i++) {
		if(str[i] != scammer[i]) {return false;}
	}
	return true;
}

public Action:checkname(Handle:timer, any:data) {
	
	new client = GetClientOfUserId(data);
	if (client==0) { return; }
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client,name,sizeof(name));
	if (g_IsScammer[client]){
		if (!StartsWithScammer(name)) { KickClient(client,"Do not try to rename yourself to remove the SCAMMER label"); }
	}	
}

stock ShowMOTDPanelBIG(client, const String:title[], const String:msg[], type=MOTDPANEL_TYPE_INDEX)
{
	decl String:num[3];
	new Handle:Kv = CreateKeyValues("data");
	IntToString(type, num, sizeof(num));

	KvSetString(Kv, "title", title);
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", msg);
	KvSetNum(Kv, "customsvr", 1);
	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);
}