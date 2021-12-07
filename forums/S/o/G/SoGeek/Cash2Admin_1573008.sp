#include <sourcemod>
#include <sdktools>
#include <regex>

#pragma semicolon 1

new String:link[500];
new Handle:SteamID[256];
new Handle:title_motd[256];
new Handle:Language[256];
new Handle:AdvertTimer[255];
new Handle:name[255];

new Handle:IP[256];
 
public Plugin:myinfo = {

	name = "Cash2Admin",
	author = "SoGeek - Team SkyZen",
	description = "Système d'ajout automatique d'administrateur sur votre serveur",
	version = "1.0.0.0",
	url = "http://www.team-skyzen.fr/"
	
};
 
public OnPluginStart() {

    LoadTranslations("Cash2Admin.phrases.txt");

    RegConsoleCmd( "say", CommandSay );
	RegConsoleCmd( "say_team", CommandSay );
	
	new Handle:gameIP;
    new String:IP2[64];
		 
	new Handle:gamePORT;
    new String:PORT[32];

    gameIP = FindConVar("ip");
	GetConVarString(gameIP, IP2, 32);
	
	gamePORT = FindConVar("hostport");
	GetConVarString(gamePORT, PORT, 32);
	
	Format(IP , sizeof(IP) , "%s:%s", IP2, PORT);
	
	CreateConVar("sm_cash2admin_path_url", "http://www.team-skyzen.fr/Cash2Admin/buy.php", "URL Path", FCVAR_PLUGIN, true, 0.0);
	
	ServerCommand("exec Cash2Admin/config.cfg");

}

public OnClientPutInServer(client) {

	GetClientName( client , name , sizeof( name ) - 1 );
		 
	GetClientAuthString(client , SteamID, 200);
		  
    Format(Language, sizeof(Language), "%T", "Advert", client , name);
	
	if (StrContains(Language, "acheter" , false) != -1) {
	
	     Format(Language, sizeof(Language), "fr");
	
	} if (StrContains(Language, "buy" , false) != -1) {
	
	     Format(Language, sizeof(Language), "en");
	
	} if (StrContains(Language, "Rechte" , false) != -1) {
	
		 Format(Language, sizeof(Language), "de");
	
	} if (StrContains(Language, "ваши" , false) != -1) {
	
		 Format(Language, sizeof(Language), "ru");
	
	} if (StrContains(Language, "comprare" , false) != -1) {
	
		 Format(Language, sizeof(Language), "it");
	
	}

	Format(title_motd, sizeof(title_motd), "Cash2Admin | %T", "Title", client , name);
	
	AdvertTimer[client] = CreateTimer(40.0, Advert , client, TIMER_REPEAT);

}

public OnClientDisconnect(client) {

	KillTimer(AdvertTimer[client]);
	AdvertTimer[client] = INVALID_HANDLE;
}

public Action:Advert(Handle:timer , any:client) {
	
	PrintToChat(client ,"\x03[Cash2Admin]\x01 %T", "Advert", client);

}

public Action:CommandSay( client , args ) {

	decl String:Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!buy_admin" ) || StrEqual( Said, "buy_admin" ) || StrEqual( Said, "!admin_buy" ) || StrEqual( Said, "admin_buy" ) ) {
  
         new Handle:URL;
         new String:URL_path[500];
  
  	     URL = FindConVar("sm_cash2admin_path_url");
	     GetConVarString(URL, URL_path , 500);
  
         Format(link , sizeof(link) , "http://%s?name=%s&ip=%s&id=%s&lang=%s", URL_path , name, IP, SteamID, Language);
		 
         ShowMOTDPanel(client,title_motd,link,MOTDPANEL_TYPE_URL);

	}
	
	return Plugin_Continue;
	
}