#include <sourcemod>
#include <sdktools>

/*

////////////////////////////////////////////////////////////////////////
////////////////////// InteRank v1.0, by ZiGoM@r //////////////////////
//////////////////////////////////////////////////////////////////////

Thanks to graczu for his work (CS:S Little Rank System : http://forums.alliedmods.net/showthread.php?p=523601)



SQL TABLE :

CREATE TABLE `css_rank`(
`rank_id` int(64) NOT NULL auto_increment,
`steamId` varchar(255) NOT NULL default '',
`nick` varchar(255) NOT NULL default '',
`kills` int(12) NOT NULL default '0',
`deaths` int(12) NOT NULL default '0',
`headshots` int(12) NOT NULL default '0',
`sucsides` int(12) NOT NULL default '0',
`points` int(12) NOT NULL default '0',
`tks` int(12) NOT NULL default '0',
`lastconnec` datetime NOT NULL default '',
`time` int(12) NOT NULL default '0',
`playedround` int(12) NOT NULL default '0',
`winroundalive` int(12) NOT NULL default '0',
`winrounddead` int(12) NOT NULL default '0',
`mission` int(12) NOT NULL default '0',
`shoots` int(12) NOT NULL default '0',
`hits1` int(12) NOT NULL default '0',
`hits2` int(12) NOT NULL default '0',
`hits3` int(12) NOT NULL default '0',
`hits4` int(12) NOT NULL default '0',
`hits5` int(12) NOT NULL default '0',
`hits6` int(12) NOT NULL default '0',
`hits7` int(12) NOT NULL default '0',
`serverIp` varchar(22) NOT NULL default '',
`damage` int(12) NOT NULL default '0',
`weapon1` int(12) NOT NULL default '0',
`weapon2` int(12) NOT NULL default '0',
`weapon3` int(12) NOT NULL default '0',
`weapon4` int(12) NOT NULL default '0',
`weapon5` int(12) NOT NULL default '0',
`weapon6` int(12) NOT NULL default '0',
`weapon7` int(12) NOT NULL default '0',
`weapon8` int(12) NOT NULL default '0',
`weapon9` int(12) NOT NULL default '0',
`weapon10` int(12) NOT NULL default '0',
`weapon11` int(12) NOT NULL default '0',
`weapon12` int(12) NOT NULL default '0',
`weapon13` int(12) NOT NULL default '0',
`weapon14` int(12) NOT NULL default '0',
`weapon15` int(12) NOT NULL default '0',
`weapon16` int(12) NOT NULL default '0',
`weapon17` int(12) NOT NULL default '0',
`weapon18` int(12) NOT NULL default '0',
`weapon19` int(12) NOT NULL default '0',
`weapon20` int(12) NOT NULL default '0',
`weapon21` int(12) NOT NULL default '0',
`weapon22` int(12) NOT NULL default '0',
`weapon23` int(12) NOT NULL default '0',
`weapon24` int(12) NOT NULL default '0',
`weapon25` int(12) NOT NULL default '0',
`weapon26` int(12) NOT NULL default '0',
`weapon27` int(12) NOT NULL default '0',
`weapon28` int(12) NOT NULL default '0',
PRIMARY KEY  (`rank_id`));

CREATE TABLE `css_server`(
`serverIp` varchar(22) NOT NULL default '',
`publicPw` varchar(20) NOT NULL default '',
`hostname` varchar(255) NOT NULL default '',
`webSite` varchar(255) NOT NULL default '',
`description` varchar(255) NOT NULL default '')

*/

// MySQL Queries DEBUG MODE 0 = off
new DEBUG = 0;

// defines
#define MAX_LINE_WIDTH 60
#define PLUGIN_VERSION "1.0"

// user stats based on ID
new Kills[64];
new Deaths[64];
new HeadShots[64];
new SucSides[64];
new TKs[64];
new PlayedRound[64];
new WinRoundAlive[64];
new WinRoundDead[64];
new Shoots[64];
new Hits[7][64];
new AcomplishedMission[64];
new Damage[64];
new Weapons[28][64];
new userInit[64];
new userFlood[64];
new day[64];
new hour[64];
new min[64];
new String:steamIdSave[64][255];

new String:ServerIp[22];
new String:PublicPw[20];
new String:Hostname[255];
new String:WebSite[255];
new String:Description[255];

new String:LastConnec[64][20];
new String:Minui1[64][20];
new String:Minui2[64][20];
// mysql connection is ok
new Handle:db;

new String:buffer1[1024];

new String:FloatString1[10];
new String:FloatString2[10];
new String:FloatString3[10];

public Plugin:myinfo = 
{
	name = "CS:S InteRank",
	author = "ZiGoM@r",
	description = "CS:S Rank System based on MYSQL",
	version = PLUGIN_VERSION,
	url = "http://zizigomar.olympe-network.com/StatByZiGo/Stats.php"
};

public OnPluginStart()
{
	// chat commands
	RegConsoleCmd("say", Command_Say);

	// Events
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("bomb_exploded", EventBombExploded);
	HookEvent("bomb_defused", EventBombDefused);
	HookEvent("hostage_rescued_all", EventHostageRescued);
	HookEvent("vip_escaped", EventVipEscaped);
	HookEvent("vip_killed", EventVipKilled);
	HookEvent("weapon_fire", EventPlayerShoot);

	// Enable/Disable hp left display
	CreateConVar("ir_hp_left", "1", "1 = activation, 0 = Off",FCVAR_NOTIFY) ;

	// Security conVar (if the plugin was start more than once)
	// Edit the conVar name if you want compile
	if (FindConVar("ir_security")==INVALID_HANDLE){
		CreateConVar("ir_security", "1", "",FCVAR_PROTECTED) ;
	}
	else{
		SetConVarInt(FindConVar("ir_security"), 0)
	}

	// Nobody is initialized
	new i=0;
	while(i<64){
		userInit[i]=0;
		i++;
	}

	// Get the server ip, hostname etc...
	GetServerInfos();

	// Init the database
	DatabaseInit();

}

bool:GetServerInfos()
{
	new Handle:kv = CreateKeyValues("InteRank")
	FileToKeyValues(kv, "ServerInfo.txt")
	if (!KvJumpToKey(kv, "infos"))
	{
		return false
	}
	KvGetString(kv, "ServerIp", ServerIp, 22)
	KvGetString(kv, "PublicPw", PublicPw, 20)
	KvGetString(kv, "Hostname", Hostname, 255)
	KvGetString(kv, "WebSite", WebSite, 255)
	KvGetString(kv, "Description", Description, 255)
	CloseHandle(kv)
	return true
}


public EventBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	AcomplishedMission[client]++;
}
public EventBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	AcomplishedMission[client]++;
}
public EventHostageRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	AcomplishedMission[client]++;
}
public EventVipEscaped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	AcomplishedMission[client]++;
}
public EventVipKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	AcomplishedMission[client]++;
}

public EventPlayerShoot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	Shoots[client]++;
}


public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new timeleft;
	GetMapTimeLeft(timeleft);
	new winner = GetEventInt(event, "winner") 
	new client = 0;
	while(client<64){
		if ( userInit[client] == 1)
		{		
			if (db != INVALID_HANDLE)
			{
				// Show session at end of map
				if (timeleft<=1){
				showSession(client);
				saveUser(client);
				GetMyRank(client);
				}
				PlayedRound[client]++;
				if (GetClientTeam(client)==winner){
					if(IsPlayerAlive(client)){
					WinRoundAlive[client]++;
					}
					else{
					WinRoundDead[client]++;
					}
				}
			}
		}
		client++;
	}
	
}



public OnClientAuthorized(client, const String:auth[])
{
	InitializeClient(client);
}


public InitializeClient( client )
{
	if ( !IsFakeClient(client) )
	{
        	decl String:time_stamp[16];
        	FormatTime(time_stamp,sizeof(time_stamp),"%j");
        	day[client] = StringToInt(time_stamp);
        	FormatTime(time_stamp,sizeof(time_stamp),"%H");
        	hour[client] = StringToInt(time_stamp);
        	FormatTime(time_stamp,sizeof(time_stamp),"%M");
        	min[client] = StringToInt(time_stamp);
		Kills[client]=0;
		Deaths[client]=0;
		HeadShots[client]=0;
		SucSides[client]=0;
		TKs[client]=0;
		Shoots[client]=0;
		Hits[0][client]=0;
		Hits[1][client]=0;
		Hits[2][client]=0;
		Hits[3][client]=0;
		Hits[4][client]=0;
		Hits[5][client]=0;
		Hits[6][client]=0;
		Damage[client]=0;
		PlayedRound[client]=0;
		WinRoundAlive[client]=0;
		WinRoundDead[client]=0;
		AcomplishedMission[client]=0;
		new i=0;
		while(i<28){
			Weapons[i][client]=0;
			i++;
		}
		userFlood[client]=0;
		decl String:steamId[64];
		GetClientAuthString(client, steamId, sizeof(steamId));
		steamIdSave[client] = steamId;
		CreateTimer(1.0, initPlayerBase, client);
	}
}

public Action:initPlayerBase(Handle:timer, any:client){
	decl String:time1[20];
	decl String:time2[20];
	decl String:time3[20];
	new i=0;
	if (db != INVALID_HANDLE)
	{	
		FormatTime(time1,sizeof(time1),"%Y-%m-%d %H:%M:%S");
		FormatTime(time2,sizeof(time2),"%Y-%m-00 00:00:00");
		FormatTime(time3,sizeof(time3),"%Y-%m-31 23:59:59");
		while(i<20){
			LastConnec[client][i]=time1[i];
			Minui1[client][i]=time2[i];
			Minui2[client][i]=time3[i];
			i++;
		}
		Format(buffer1, sizeof(buffer1), "SELECT * FROM css_rank WHERE steamId = '%s' and serverIp = '%s' and lastconnec >= '%s' and lastconnec <= '%s'", steamIdSave[client], ServerIp,Minui1[client],Minui2[client]);
		if(DEBUG == 1){
			PrintToServer("DEBUG: Action:initPlayerBase (%s)", buffer1);
		}
		SQL_TQuery(db, SQLUserLoad, buffer1, client);
	}
}


////////////////////////////////////////////////////////////////
// Sorry, it's not beautyfull, but I have not the time to learne the
// sourcePawn langage correctly, like pointers etc...
// Post best code on the forum if you want. Yet sorry...
////////////////////////////////////////////////////////////////

public Round1(Float:Number){
	new String:sNumber[10];
	FloatToString(Number,sNumber,10);
	new i=0;
	while(sNumber[i]!='.' && i<10){
		FloatString1[i]=sNumber[i];
		i++;
	}
	FloatString1[i]=',';
	FloatString1[i+1]=sNumber[i+1];
	FloatString1[i+2]=sNumber[i+2];
	FloatString1[i+3]=0;
}

public Round2(Float:Number){
	new String:sNumber[10];
	FloatToString(Number,sNumber,10);
	new i=0;
	while(sNumber[i]!='.' && i<10){
		FloatString2[i]=sNumber[i];
		i++;
	}
	FloatString2[i]=',';
	FloatString2[i+1]=sNumber[i+1];
	FloatString2[i+2]=sNumber[i+2];
	FloatString2[i+3]=0;
}

public Round3(Float:Number){
	new String:sNumber[10];
	FloatToString(Number,sNumber,10);
	new i=0;
	while(sNumber[i]!='.' && i<10){
		FloatString3[i]=sNumber[i];
		i++;
	}
	FloatString3[i]=',';
	FloatString3[i+1]=sNumber[i+1];
	FloatString3[i+2]=sNumber[i+2];
	FloatString3[i+3]=0;
}


///////////////////////////////////////////////////////////////


// Return the Weapon ID
public Int:IntWeapon(String:str[32]){
	if (StrEqual(str,"galil",false)){
		return Int:0;
	}
	if (StrEqual(str,"ak47",false)){
		return Int:1;
	}
	if (StrEqual(str,"scout",false)){
		return Int:2;
	}
	if (StrEqual(str,"sg552",false)){
		return Int:3;
	}
	if (StrEqual(str,"awp",false)){
		return Int:4;
	}
	if (StrEqual(str,"g3sg1",false)){
		return Int:5;
	}
	if (StrEqual(str,"famas",false)){
		return Int:6;
	}
	if (StrEqual(str,"m4a1",false)){
		return Int:7;
	}
	if (StrEqual(str,"aug",false)){
		return Int:8;
	}
	if (StrEqual(str,"sg550",false)){
		return Int:9;
	}
	if (StrEqual(str,"glock",false)){
		return Int:10;
	}
	if (StrEqual(str,"usp",false)){
		return Int:11;
	}
	if (StrEqual(str,"p228",false)){
		return Int:12;
	}
	if (StrEqual(str,"deagle",false)){
		return Int:13;
	}
	if (StrEqual(str,"elite",false)){
		return Int:14;
	}
	if (StrEqual(str,"fiveseven",false)){
		return Int:15;
	}
	if (StrEqual(str,"m3",false)){
		return Int:16;
	}
	if (StrEqual(str,"xm1014",false)){
		return Int:17;
	}
	if (StrEqual(str,"mac10",false)){
		return Int:18;
	}
	if (StrEqual(str,"tmp",false)){
		return Int:19;
	}
	if (StrEqual(str,"mp5navy",false)){
		return Int:20;
	}
	if (StrEqual(str,"ump45",false)){
		return Int:21;
	}
	if (StrEqual(str,"p90",false)){
		return Int:22;
	}
	if (StrEqual(str,"m249",false)){
		return Int:23;
	}
	if (StrEqual(str,"flashbang",false)){
		return Int:24;
	}
	if (StrEqual(str,"hegrenade",false)){
		return Int:25;
	}
	if (StrEqual(str,"smokegrenade",false)){
		return Int:26;
	}
	if (StrEqual(str,"knife",false)){
		return Int:27;
	}
	return Int:0;
}


public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, 32)
	ReplaceString(weapon, 32, "WEAPON_", "")
	new String:attackerName[32]
	GetClientName(attacker,attackerName,32)

	new bool:headshot = GetEventBool(event, "headshot")

	new isactive = GetConVarInt(FindConVar("ir_hp_left"));
	if (isactive==1){
		if(headshot){
			HeadShots[attacker]++;	
			if (userInit[victim] == 1){
				 // HP left at enemy who kill you
				PrintToChat(victim,"\x01%s\x03 with %s (headshot),\x04 it still %i hp",attackerName,weapon,GetClientHealth(attacker))
			}
		}
		else{
			if (userInit[victim] == 1){
				PrintToChat(victim,"\x01%s\x03 with %s,\x04 it still %i hp",attackerName,weapon,GetClientHealth(attacker))
			}
		}
	}
	if ( userInit[attacker] == 1)
	{
		if (GetClientTeam(victim)==GetClientTeam(attacker)){
			TKs[attacker]++;
		}
	}
	if(victim != attacker){
		Kills[attacker]++;
		Weapons[IntWeapon(weapon)][attacker]++;
		Deaths[victim]++;

	} else {
		SucSides[victim]++;
		Deaths[victim]++;
	}


}

public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new damage = GetEventInt(event,"dmg_health")
	new hitgroup = GetEventInt(event,"hitgroup");
	new String:attackerName[32]
	GetClientName(attacker,attackerName,32)
	new String:victimName[32]
	GetClientName(victim,victimName,32)

	new i=0;
	new isactive = GetConVarInt(FindConVar("ir_hp_left"));
	if ( userInit[attacker] == 1)
	{
		if (GetClientTeam(victim)==GetClientTeam(attacker) && isactive==1){
			while (i<64){
				if (userInit[i] == 1){
					if (GetClientTeam(i)==GetClientTeam(victim)){
						// Damage given to your teammate	
						PrintToChat(i,"%s give %i damages at %s",attackerName, damage,victimName);
					}
				}
				i++;
			}	
		}
	}
	if (hitgroup>=1 && hitgroup<=7){
		Hits[hitgroup-1][attacker]++;
	}
	Damage[attacker]+=damage;
}


public OnClientDisconnect (client)
{
	if ( !IsFakeClient(client) && userInit[client] == 1)
	{		
		if (db != INVALID_HANDLE)
		{
			saveUser(client);
			userInit[client] = 0;
		}
	}
}

public saveUser(client){
	new security = GetConVarInt(FindConVar("ir_security"));
	if ( !IsFakeClient(client) && userInit[client] == 1 && security==1)
	{		
		if (db != INVALID_HANDLE)
		{
			Format(buffer1, sizeof(buffer1), "SELECT * FROM css_rank WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'", steamIdSave[client], ServerIp,Minui1[client],Minui2[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: saveUser (%s)", buffer1);
			}
			SQL_TQuery(db, SQLUserSave, buffer1, client);
		}
	}
	if (security==0){
	PrintToServer("InteRank a ete lance 2 fois...");
	}
}

// Chat commands
public Action:Command_Say(client, args){
	decl String:text[192], String:command[64];

	new startidx = 0;

	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)

	startidx += 4;

	if (strcmp(text[startidx], "!irank", false) == 0)	{
		if(userFlood[client] != 1){
			GetMyRank(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
		}
	} else	if (strcmp(text[startidx], "!itop", false) == 0)
	{		
		if(userFlood[client] != 1){
			showTOP(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
		}
	} 
	else	if (strcmp(text[startidx], "!isession", false) == 0)
	{		
		if(userFlood[client] != 1){
			showSession(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
		}
	} 
	return Plugin_Continue;
}

public Action:removeFlood(Handle:timer, any:client){
	userFlood[client]=0;
}

public GetMyRank(client){
	if (db != INVALID_HANDLE)
	{
		if(userInit[client] == 1){

			Format(buffer1, sizeof(buffer1), "SELECT * FROM css_rank WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'", steamIdSave[client],ServerIp,Minui1[client],Minui2[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: GetMyRank (%s)", buffer1);
			}
			SQL_TQuery(db, SQLGetMyRank, buffer1, client);

		} else {

			PrintToChat(client,"[RANK] Wait for system load you from database");

		}
	} else {
		PrintToChat(client, "[RANK] Rank System is now not avilable");
	}
}

public showTOP(client){

	if (db != INVALID_HANDLE)
	{
		Format(buffer1, sizeof(buffer1), "SELECT * FROM css_rank WHERE serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s' ORDER BY points DESC LIMIT 10",ServerIp,Minui1[client],Minui2[client]);
		if(DEBUG == 1){
			PrintToServer("DEBUG: showTOP (%s)", buffer1);
		}
		SQL_TQuery(db, SQLTopShow, buffer1, client);
	} else {
		PrintToChat(client, "[LRCSS] Rank System is now not avilable");
	}
}

public showSession(client){
	if (db != INVALID_HANDLE)
	{
		Format(buffer1, sizeof(buffer1), "SELECT * FROM css_rank WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'", steamIdSave[client],ServerIp,Minui1[client],Minui2[client]);
		if(DEBUG == 1){
			PrintToServer("DEBUG: showTOP (%s)", buffer1);
		}
		SQL_TQuery(db, SessionShow, buffer1, client);
	} else {
		PrintToChat(client, "[LRCSS] Rank System is now not avilable");
	}
}

public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
}


public DatabaseInit(){
		new String:error[255]

		// Connect to the database
		// Edit it if you want compile
		db = SQL_ConnectEx(SQL_GetDriver("mysql"),"Host.sql.com","User","password","database",error,511,true,0,5);

		if (db == INVALID_HANDLE)
		{
			PrintToServer("Failed to connect: %s", error)
		} else {
			PrintToServer("DEBUG: DatabaseInit (CONNECTED)");
		}
		Format(buffer1, sizeof(buffer1), "SELECT * FROM css_server WHERE serverIp = '%s'",ServerIp);
		new Handle:queryBase = SQL_Query(db, buffer1)
		if (queryBase == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error))
			PrintToServer("Failed to query: %s", error)
		} else {
			PrintToServer("DEBUG: DatabaseInit (NOT CONNECTED)");
			if(SQL_FetchRow(queryBase))
			{
				Format(buffer1, sizeof(buffer1), "UPDATE css_server SET publicPw = '%s', hostname = '%s', webSite = '%s', description = '%s' WHERE serverIp = '%s'", PublicPw,Hostname,WebSite,Description, ServerIp)
				if(DEBUG == 1){
						PrintToServer("DEBUG: SQLUserLoad (%s)", buffer1);
				}
				SQL_TQuery(db, SQLErrorCheckCallback, buffer1);
			}else{
				Format(buffer1, sizeof(buffer1), "INSERT INTO css_server VALUES('%s','%s','%s','%s','%s')", ServerIp,PublicPw,Hostname,WebSite,Description)
				if(DEBUG == 1){
					PrintToServer("DEBUG: SQLUserLoad (%s)", buffer1);
				}
				SQL_TQuery(db, SQLErrorCheckCallback, buffer1);
			}
			CloseHandle(queryBase)
		}
}


// ================================================================================

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		PrintToServer("Last Connect SQL Error: %s", error);
	}
}


public SQLUserLoad(Handle:owner, Handle:hndl, const String:error[], any:client){
	if (!IsFakeClient(client)){
		if(SQL_FetchRow(hndl))
		{
			decl String:name[MAX_LINE_WIDTH];
			GetClientName( client, name, sizeof(name) );
	
			ReplaceString(name, sizeof(name), "'", "");
			ReplaceString(name, sizeof(name), "<?", "");
			ReplaceString(name, sizeof(name), "?>", "");
			ReplaceString(name, sizeof(name), "\"", "");
			ReplaceString(name, sizeof(name), "<?PHP", "");
			ReplaceString(name, sizeof(name), "<?php", "");
	
	
			Format(buffer1, sizeof(buffer1), "UPDATE css_rank SET nick = '%s' WHERE steamId = '%s'", name, steamIdSave[client])
			if(DEBUG == 1){
				PrintToServer("DEBUG: SQLUserLoad (%s)", buffer1);
			}
			SQL_TQuery(db, SQLErrorCheckCallback, buffer1);
	
			userInit[client] = 1;
		} else {
	
			decl String:name[MAX_LINE_WIDTH];
	
			GetClientName( client, name, sizeof(name) );
	
			ReplaceString(name, sizeof(name), "'", "");
			ReplaceString(name, sizeof(name), "<?", "");
			ReplaceString(name, sizeof(name), "?>", "");
			ReplaceString(name, sizeof(name), "\"", "");
			ReplaceString(name, sizeof(name), "<?PHP", "");
			ReplaceString(name, sizeof(name), "<?php", "");
	
			Format(buffer1, sizeof(buffer1), "INSERT INTO css_rank VALUES('','%s','%s','0','0','0','0','0','0','%s','0','0','0','0','0','0','0','0','0','0','0','0','0','%s','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0')", steamIdSave[client], name,LastConnec[client],ServerIp)
			if(DEBUG == 1){
				PrintToServer("DEBUG: SQLUserLoad (%s)", buffer1);
			}
			SQL_TQuery(db, SQLErrorCheckCallback, buffer1);

			userInit[client] = 1;
		}
	}
}

public SQLUserSave(Handle:owner, Handle:hndl, const String:error[], any:client){
	new security = GetConVarInt(FindConVar("ir_security"))
	if(hndl == INVALID_HANDLE || security==0)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}

	decl QueryReadRow_KILL;
	decl QueryReadRow_DEATHS;
	decl QueryReadRow_HEADSHOTS;
	decl QueryReadRow_SUCSIDES;
	decl QueryReadRow_POINTS;
	new QueryReadRow_FPOINTS;
	decl QueryReadRow_TKS;
	decl QueryReadRow_WRA;
	decl QueryReadRow_WRD;
	decl QueryReadRow_MISSION;
	decl QueryReadRow_KNIFE;
	decl QueryReadRow_GLOCK;
	decl QueryReadRow_TIME
        decl String:time_d[16];
        decl String:time_h[16];
        decl String:time_m[16];
	new i=0;
	if(SQL_FetchRow(hndl)) 
	{
        	FormatTime(time_d,sizeof(time_d),"%j");
        	FormatTime(time_h,sizeof(time_h),"%H");
        	FormatTime(time_m,sizeof(time_m),"%M");
		QueryReadRow_KILL=SQL_FetchInt(hndl,3) + Kills[client];
		Kills[client]=0;
		QueryReadRow_DEATHS=SQL_FetchInt(hndl,4) + Deaths[client];
		Deaths[client]=0;
		QueryReadRow_HEADSHOTS=SQL_FetchInt(hndl,5) + HeadShots[client];
		HeadShots[client]=0;
		QueryReadRow_SUCSIDES=SQL_FetchInt(hndl,6) + SucSides[client];
		SucSides[client]=0;
		QueryReadRow_TKS=SQL_FetchInt(hndl,8) + TKs[client];
		TKs[client]=0;

		QueryReadRow_WRA=SQL_FetchInt(hndl,12) + WinRoundAlive[client];
		QueryReadRow_WRD=SQL_FetchInt(hndl,13) + WinRoundDead[client];
		QueryReadRow_MISSION=SQL_FetchInt(hndl,14) + AcomplishedMission[client];
		QueryReadRow_GLOCK=SQL_FetchInt(hndl,33) + Weapons[10][client];
		QueryReadRow_KNIFE=SQL_FetchInt(hndl,52) + Weapons[27][client];
		QueryReadRow_TIME=SQL_FetchInt(hndl,10) + ((StringToInt(time_d)-day[client])*24*60)+((StringToInt(time_h)-hour[client])*60)+(StringToInt(time_m)-min[client]);
        	FormatTime(time_d,sizeof(time_d),"%j");
        	day[client] = StringToInt(time_d);
        	FormatTime(time_h,sizeof(time_h),"%H");
        	hour[client] = StringToInt(time_h);
        	FormatTime(time_m,sizeof(time_m),"%M");
        	min[client] = StringToInt(time_m);
		if (QueryReadRow_DEATHS==0){
			QueryReadRow_FPOINTS=QueryReadRow_KILL*(QueryReadRow_KILL+QueryReadRow_HEADSHOTS-QueryReadRow_SUCSIDES-(QueryReadRow_TKS*2)+(QueryReadRow_MISSION*2)+(QueryReadRow_WRA*2)+QueryReadRow_WRD+(QueryReadRow_KNIFE*2)+QueryReadRow_GLOCK);
		}
		else{
			QueryReadRow_FPOINTS=(QueryReadRow_KILL/QueryReadRow_DEATHS)*(QueryReadRow_KILL+QueryReadRow_HEADSHOTS-QueryReadRow_SUCSIDES-(QueryReadRow_TKS*2)+(QueryReadRow_MISSION*2)+(QueryReadRow_WRA*2)+QueryReadRow_WRD+(QueryReadRow_KNIFE*2)+QueryReadRow_GLOCK);
		}
		QueryReadRow_POINTS=QueryReadRow_FPOINTS;

		Format(buffer1, sizeof(buffer1), "UPDATE css_rank SET kills = '%i', deaths = '%i', headshots = '%i', sucsides = '%i', points = '%i', tks = '%i', lastconnec = '%s', time = '%i' WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'", QueryReadRow_KILL, QueryReadRow_DEATHS, QueryReadRow_HEADSHOTS, QueryReadRow_SUCSIDES, QueryReadRow_POINTS, QueryReadRow_TKS, LastConnec[client],QueryReadRow_TIME,steamIdSave[client],ServerIp,Minui1[client],Minui2[client])
		
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserSave (%s)", buffer1);
		}

		SQL_TQuery(db, SQLErrorCheckCallback, buffer1);

		Format(buffer1, sizeof(buffer1), "UPDATE css_rank SET mission=mission+'%i', playedround=playedround+'%i', winroundalive=winroundalive+'%i', winrounddead=winrounddead+'%i' WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'",AcomplishedMission[client],PlayedRound[client],WinRoundAlive[client],WinRoundDead[client],steamIdSave[client],ServerIp,Minui1[client],Minui2[client])
		
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserSave (%s)", buffer1);
		}

		SQL_TQuery(db, SQLErrorCheckCallback, buffer1);
		PlayedRound[client]=0;
		WinRoundAlive[client]=0;
		WinRoundDead[client]=0;
		AcomplishedMission[client]=0;

		Format(buffer1, sizeof(buffer1), "UPDATE css_rank SET hits1=hits1+'%i', hits2=hits2+'%i', hits3=hits3+'%i', hits4=hits4+'%i', hits5=hits5+'%i', hits6=hits6+'%i', hits7=hits7+'%i', shoots=shoots+'%i', damage=damage+'%i' WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'",Hits[0][client],Hits[1][client],Hits[2][client],Hits[3][client],Hits[4][client],Hits[5][client],Hits[6][client],Shoots[client],Damage[client],steamIdSave[client],ServerIp,Minui1[client],Minui2[client])
		
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserSave (%s)", buffer1);
		}
		while(i<7){
			Hits[i][client]=0;
			i++;
		}
		Shoots[client]=0;
		SQL_TQuery(db, SQLErrorCheckCallback, buffer1);
		i=0;
		while(i<4){
			Format(buffer1, sizeof(buffer1), "UPDATE css_rank SET weapon%i = weapon%i+'%i', weapon%i = weapon%i+'%i', weapon%i = weapon%i+'%i', weapon%i = weapon%i+'%i', weapon%i = weapon%i+'%i', weapon%i = weapon%i+'%i', weapon%i = weapon%i+'%i' WHERE steamId = '%s' and serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s'",i*7+1,i*7+1,Weapons[i*7][client],i*7+2,i*7+2,Weapons[i*7+1][client],i*7+3,i*7+3,Weapons[i*7+2][client],i*7+4,i*7+4,Weapons[i*7+3][client],i*7+5,i*7+5,Weapons[i*7+4][client],i*7+6,i*7+6,Weapons[i*7+5][client],i*7+7,i*7+7,Weapons[i*7+6][client],steamIdSave[client],ServerIp,Minui1[client],Minui2[client])
			if(DEBUG == 1){
				PrintToServer("DEBUG: SQLUserSave (%s)", buffer1);
			}
			SQL_TQuery(db, SQLErrorCheckCallback, buffer1);
			i++;
		}
		i=0;
		while(i<28){
			Weapons[i][client]=0;
			i++;
		}
	}

}

public SQLGetMyRank(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
    

	decl QueryReadRow_KILL;
	decl QueryReadRow_KILL2;
	decl QueryReadRow_DEATHS;
	decl QueryReadRow_DEATHS2;
	decl QueryReadRow_HEADSHOTS;
	decl QueryReadRow_SUCSIDES;
	decl QueryReadRow_POINTS;
	new QueryReadRow_FPOINTS;
	decl QueryReadRow_TKS;
	decl QueryReadRow_WRA;
	decl QueryReadRow_WRD;
	decl QueryReadRow_PR;
	decl QueryReadRow_MISSION;
	decl QueryReadRow_KNIFE;
	decl QueryReadRow_GLOCK;
	decl QueryReadRow_TIME
        decl String:time_d[16];
        decl String:time_h[16];
        decl String:time_m[16];
	new Float:ratio;
	new Float:ratio2;
	new Float:ratio3;


	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) 
	{
        	FormatTime(time_d,sizeof(time_d),"%j");
        	FormatTime(time_h,sizeof(time_h),"%H");
        	FormatTime(time_m,sizeof(time_m),"%M");
		QueryReadRow_KILL=SQL_FetchInt(hndl,3) + Kills[client];
		QueryReadRow_DEATHS=SQL_FetchInt(hndl,4) + Deaths[client];
		QueryReadRow_HEADSHOTS=SQL_FetchInt(hndl,5) + HeadShots[client];
		QueryReadRow_SUCSIDES=SQL_FetchInt(hndl,6) + SucSides[client];
		QueryReadRow_TKS=SQL_FetchInt(hndl,8) + TKs[client];
		QueryReadRow_PR=SQL_FetchInt(hndl,11) + PlayedRound[client];
		QueryReadRow_WRA=SQL_FetchInt(hndl,12) + WinRoundAlive[client];
		QueryReadRow_WRD=SQL_FetchInt(hndl,13) + WinRoundDead[client];
		QueryReadRow_MISSION=SQL_FetchInt(hndl,14) + AcomplishedMission[client];
		QueryReadRow_GLOCK=SQL_FetchInt(hndl,33) + Weapons[10][client];
		QueryReadRow_KNIFE=SQL_FetchInt(hndl,52) + Weapons[27][client];
		QueryReadRow_TIME=SQL_FetchInt(hndl,10) + ((StringToInt(time_d)-day[client])*24*60)+((StringToInt(time_h)-hour[client])*60)+(StringToInt(time_m)-min[client]);


        	if (QueryReadRow_DEATHS==0){
			QueryReadRow_DEATHS2=1;
		}
		else{
		QueryReadRow_DEATHS2=QueryReadRow_DEATHS;
		}
        	if (QueryReadRow_KILL==0){
			QueryReadRow_KILL2=1;
		}
		else{
		QueryReadRow_KILL2=QueryReadRow_KILL;
		}
        	if (QueryReadRow_PR==0){
			QueryReadRow_PR=1;
		}
		ratio=Float:QueryReadRow_KILL/Float:QueryReadRow_DEATHS2;
		ratio2=(Float:QueryReadRow_HEADSHOTS/Float:QueryReadRow_KILL2)*100.0;
		ratio3=((Float:QueryReadRow_WRA+Float:QueryReadRow_WRD)/Float:QueryReadRow_PR)*100.0;
		QueryReadRow_FPOINTS=(QueryReadRow_KILL/QueryReadRow_DEATHS2)*(QueryReadRow_KILL+QueryReadRow_HEADSHOTS-QueryReadRow_SUCSIDES-(QueryReadRow_TKS*2)+(QueryReadRow_MISSION*2)+(QueryReadRow_WRA*2)+QueryReadRow_WRD+(QueryReadRow_KNIFE*2)+QueryReadRow_GLOCK);
		QueryReadRow_POINTS=QueryReadRow_FPOINTS;

		Format(buffer1, sizeof(buffer1), "SELECT rank_id FROM css_rank WHERE serverIp= '%s' and lastconnec >= '%s' and lastconnec <= '%s' and points >= %i", steamIdSave[client],ServerIp,Minui1[client],Minui2[client],QueryReadRow_POINTS);
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLGetMyRank (%s)", buffer1);
		}
		SQL_TQuery(db, SQLShowRank, buffer1, client);
		Round1(ratio);
		Round2(ratio2);
		Round3(ratio3);
		PrintToChat(client,"iRank :: Points: %i, Ratio: %s (%i/%i), Headshots: %s%%, Round Gagnes: %s%%, Temps: %i min",QueryReadRow_POINTS, FloatString1, QueryReadRow_KILL, QueryReadRow_DEATHS, FloatString2, FloatString3, QueryReadRow_TIME);
	} else {
		PrintToChat(client, "iRank Your rank is not avlilable!");
	}
}

public SQLShowRank(Handle:owner, Handle:hndl, const String:error[], any:client){
		if (SQL_HasResultSet(hndl))
		{
			new rows = SQL_GetRowCount(hndl);
			PrintToChat(client,"iRank :: Your rank is: %i.", rows);
		}
}


public SQLTopShow(Handle:owner, Handle:hndl, const String:error[], any:client){
		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
		new String:text[128];
		Format(text,127,"Top 10 Players");
		SetPanelTitle(Panel,text);

		decl row;
		decl String:name[64];
		decl kills;
		decl deaths;
		decl points;
		new Float:ratio;

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
				row++
				SQL_FetchString(hndl, 2, name, sizeof(name));
				kills=SQL_FetchInt(hndl,3);
				deaths=SQL_FetchInt(hndl,4);
				points=SQL_FetchInt(hndl,7);
				if (deaths==0){
					deaths=1;
				}
				ratio=Float:kills/Float:deaths;
				Round1(ratio);
				Format(text,127,"%d: %s: %i || Ratio: %s (%i/%i)", row, name, points, FloatString1, kills, deaths);
				DrawPanelText(Panel, text);

			}
		} else {
				Format(text,127,"TOP 10 is empty!");
				DrawPanelText(Panel, text);
		}

		DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

		Format(text,59,"Exit")
		DrawPanelItem(Panel, text)
		
		SendPanelToClient(Panel, client, TopMenu, 20);

		CloseHandle(Panel);

}

public SessionShow(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}

	new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	new String:text[128];
	Format(text,127,"Session:");
	SetPanelTitle(Panel,text);

	decl String:name[64];
	decl QueryReadRow_KILL;
	decl QueryReadRow_DEATHS;
	decl QueryReadRow_DEATHS2;
	decl QueryReadRow_HEADSHOTS;
	decl QueryReadRow_SUCSIDES;
	decl QueryReadRow_POINTS;
	new QueryReadRow_FPOINTS;
	decl QueryReadRow_TKS;
	decl QueryReadRow_WRA;
	decl QueryReadRow_WRD;
	decl QueryReadRow_PR;
	decl QueryReadRow_MISSION;
	decl QueryReadRow_KNIFE;
	decl QueryReadRow_GLOCK;
	decl QueryReadRow_TIME
	new Float:ratio;


	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 2, name, sizeof(name));
		QueryReadRow_KILL=SQL_FetchInt(hndl,3);
		QueryReadRow_DEATHS=SQL_FetchInt(hndl,4);
		QueryReadRow_HEADSHOTS=SQL_FetchInt(hndl,5);
		QueryReadRow_SUCSIDES=SQL_FetchInt(hndl,6);
		QueryReadRow_TKS=SQL_FetchInt(hndl,8);
		QueryReadRow_PR=SQL_FetchInt(hndl,11);
		QueryReadRow_WRA=SQL_FetchInt(hndl,12);
		QueryReadRow_WRD=SQL_FetchInt(hndl,13);
		QueryReadRow_MISSION=SQL_FetchInt(hndl,14);
		QueryReadRow_GLOCK=SQL_FetchInt(hndl,33);
		QueryReadRow_KNIFE=SQL_FetchInt(hndl,52);
		QueryReadRow_TIME=SQL_FetchInt(hndl,10);


        	if (QueryReadRow_DEATHS==0){
			QueryReadRow_DEATHS2=1;
		}
		else{
			QueryReadRow_DEATHS2=QueryReadRow_DEATHS;
		}
		ratio=Float:QueryReadRow_KILL/Float:QueryReadRow_DEATHS2;
		QueryReadRow_FPOINTS=(QueryReadRow_KILL/QueryReadRow_DEATHS2)*(QueryReadRow_KILL+QueryReadRow_HEADSHOTS-QueryReadRow_SUCSIDES-(QueryReadRow_TKS*2)+(QueryReadRow_MISSION*2)+(QueryReadRow_WRA*2)+QueryReadRow_WRD+(QueryReadRow_KNIFE*2)+QueryReadRow_GLOCK);
		QueryReadRow_POINTS=QueryReadRow_FPOINTS;

	} 
	else 
	{
		GetClientName( client, name, sizeof(name) );
		QueryReadRow_KILL=0;
		QueryReadRow_DEATHS=0;
		QueryReadRow_HEADSHOTS=0;
		QueryReadRow_SUCSIDES=0;
		QueryReadRow_TKS=0;
		QueryReadRow_PR=0;
		QueryReadRow_WRA=0;
		QueryReadRow_WRD=0;
		QueryReadRow_MISSION=0;
		QueryReadRow_GLOCK=0;
		QueryReadRow_KNIFE=0;
		QueryReadRow_TIME=0;
		QueryReadRow_DEATHS2=0;
		ratio=0.0;
		QueryReadRow_FPOINTS=0;
		QueryReadRow_POINTS=0;

			
	}

	decl New_KILL;
	decl New_DEATHS;
	decl New_DEATHS2;
	decl New_HEADSHOTS;
	decl New_SUCSIDES;
	decl New_POINTS;
	new New_FPOINTS;
	decl New_TKS;
	decl New_WRA;
	decl New_WRD;
	decl New_PR;
	decl New_MISSION;
	decl New_KNIFE;
	decl New_GLOCK;
	decl New_TIME
        decl String:time_d[16];
        decl String:time_h[16];
        decl String:time_m[16];
	new Float:New_ratio;
	new Float:New_ratio2;
	new Float:New_ratio3;


        FormatTime(time_d,sizeof(time_d),"%j");
        FormatTime(time_h,sizeof(time_h),"%H");
        FormatTime(time_m,sizeof(time_m),"%M");
	New_KILL=QueryReadRow_KILL + Kills[client];
	New_DEATHS=QueryReadRow_DEATHS + Deaths[client];
	New_HEADSHOTS=QueryReadRow_HEADSHOTS + HeadShots[client];
	New_SUCSIDES=QueryReadRow_SUCSIDES + SucSides[client];
	New_TKS=QueryReadRow_TKS + TKs[client];
	New_PR=QueryReadRow_PR + PlayedRound[client];
	New_WRA=QueryReadRow_WRA + WinRoundAlive[client];
	New_WRD=QueryReadRow_WRD + WinRoundDead[client];
	New_MISSION=QueryReadRow_MISSION + AcomplishedMission[client];
	New_GLOCK=QueryReadRow_GLOCK + Weapons[10][client];
	New_KNIFE=QueryReadRow_KNIFE + Weapons[27][client];
	New_TIME=QueryReadRow_TIME + ((StringToInt(time_d)-day[client])*24*60)+((StringToInt(time_h)-hour[client])*60)+(StringToInt(time_m)-min[client]);

	if (New_DEATHS==0){
		New_DEATHS2=1;
	}
	else{
		New_DEATHS2=New_DEATHS;
	}
	New_ratio=Float:New_KILL/Float:New_DEATHS2;
	New_FPOINTS=(New_KILL/New_DEATHS2)*(New_KILL+New_HEADSHOTS-New_SUCSIDES-(New_TKS*2)+(New_MISSION*2)+(New_WRA*2)+New_WRD+(New_KNIFE*2)+New_GLOCK);
		
	New_POINTS=New_FPOINTS;

	Format(text,127," ");DrawPanelText(Panel, text);
	Format(text,127,"%s :", name);DrawPanelText(Panel, text);
	Format(text,127," ");DrawPanelText(Panel, text);
	Format(text,127,"Points: %i : %i",New_POINTS, (New_POINTS-QueryReadRow_POINTS));DrawPanelText(Panel, text);
	Round1(New_ratio);
	Round2(New_ratio-ratio);
	Format(text,127,"Ratio: %s (%i/%i) : %s (%i/%i)",FloatString1, New_KILL, New_DEATHS, FloatString2,(New_KILL-QueryReadRow_KILL),(New_DEATHS-QueryReadRow_DEATHS));DrawPanelText(Panel, text);
	if (New_KILL==0){
		New_KILL=1;
	}
	if (QueryReadRow_KILL==0){
		QueryReadRow_KILL=1;
	}
	New_ratio2=(Float:New_HEADSHOTS/Float:New_KILL)*100.0;
	New_ratio3=New_ratio2-((Float:QueryReadRow_HEADSHOTS/Float:QueryReadRow_KILL)*100.0);
	Round1(New_ratio2);
	Round2(New_ratio3);
	Format(text,127,"Headshots: %s%% : %s%%",FloatString1, FloatString2);DrawPanelText(Panel, text);
	if (New_PR==0){
		New_PR=1;
	}
	if (QueryReadRow_PR==0){
		QueryReadRow_PR=1;
	}
	New_ratio2=((Float:New_WRA+Float:New_WRD)/Float:New_PR)*100.0;
	New_ratio3=New_ratio2-(((Float:QueryReadRow_WRA+Float:QueryReadRow_WRD)/Float:QueryReadRow_PR)*100.0);
	Round1(New_ratio2);
	Round2(New_ratio3);
	Format(text,127,"Round Gagnes: %s%% : %s%%",FloatString1, FloatString2);DrawPanelText(Panel, text);
	Format(text,127,"Temps: %i min : %i min",New_TIME,(New_TIME-QueryReadRow_TIME));DrawPanelText(Panel, text);

	DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

	Format(text,59,"Exit")
	DrawPanelItem(Panel, text)
		
	SendPanelToClient(Panel, client, TopMenu, 20);

	CloseHandle(Panel);
}