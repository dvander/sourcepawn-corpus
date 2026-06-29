
#define DEBUG

#define PLUGIN_NAME           "Zoned AFK Manager"
#define PLUGIN_AUTHOR         "Big BOss"
#define PLUGIN_DESCRIPTION    "Detects whether or not a player is moving from an area or not doing anything and deals with them accordingly"
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <basecomm>

#pragma semicolon 1


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

ConVar g_Zonesize;ConVar g_ZoneRefresh;ConVar g_MaxWarnings;ConVar g_WarningTime;ConVar g_AfkMode;ConVar g_MaxDmgTime;
int TimeAFK[MAXPLAYERS+1];
int LastDmg[MAXPLAYERS+1];

int Warnings[MAXPLAYERS+1];
float LastPos[MAXPLAYERS+1][3];
Handle timers[MAXPLAYERS+1];

public void OnPluginStart(){
	HookEvent("player_spawn", player_spawn);  
	HookEvent("player_hurt", player_hurt);  
	g_Zonesize=CreateConVar("afk_zonesize", "200", "Sets radius size of zone");
	g_ZoneRefresh=CreateConVar("afk_zonerefresh", "100", "how far away from zone to automatically refresh it");
	g_WarningTime=CreateConVar("afk_warningtime", "15", "Maximum amount of time before a warning occurs");
	g_MaxWarnings=CreateConVar("afk_maxwarnings", "2", "Maximum amount of times a player is warned before being dealt with");
	g_AfkMode=CreateConVar("afk_mode", "1", "Set Mode for AFK Manager | 0 = move to spectator | 1 = slap | 2 = slay | 3 = kick",_,true,0.0,true,3.0);
	g_MaxDmgTime=CreateConVar("afk_dmgtime", "60", "Maximum amount of time a player can go without damaging enemy before its considered afk");
	for (int i=0;i<=MAXPLAYERS;i++){
		if (IsValidClient(i) && timers[i]==INVALID_HANDLE){
			SetTimer(i);
		}
	}
}

public void OnClientPutInServer(int client){
	SetTimer(client);
}

stock bool IsValidClient(const int client, bool replaycheck=true){
	if( client <= 0 || client > MaxClients || !IsClientInGame(client) )
	return false;
	else if( GetEntProp(client, Prop_Send, "m_bIsCoaching") )
	return false;
	else if( replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)) )
	return false;
	else if( TF2_GetPlayerClass(client)==TFClass_Unknown )
	return false;
	return true;
}


public player_hurt(Handle event, const char[] name, bool dontBroadcast){
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	TimeAFK[attacker]=0;
	LastDmg[attacker]=0;
}

public Action player_spawn(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId( event.GetInt("userid") );
	if (client>0){
		SetTimer(client);
	}  
}
public void SetTimer(int client){
	if (IsValidClient(client) && !IsFakeClient(client) ){
		CloseHandle(timers[client]);timers[client]=INVALID_HANDLE;
		GetClientAbsOrigin(client,LastPos[client]);
		LastDmg[client]=0;
		TimeAFK[client]=0;
		Warnings[client]=0;
		timers[client]=CreateTimer(1.0,Timer_PlayerThink,client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action Timer_PlayerThink(Handle timer,int client){
	if (!IsValidClient(client) || timers[client]==INVALID_HANDLE || !IsPlayerAlive(client) ){return Plugin_Stop;}
	int maxtime=g_WarningTime.IntValue;
	int maxwarning=g_MaxWarnings.IntValue;
	int AFK_Mode=g_AfkMode.IntValue;
	float MaxDmgTime=g_MaxDmgTime.FloatValue;
	float curpos[3];GetClientAbsOrigin(client,curpos);
	float zone=g_Zonesize.FloatValue;
	float zonerefresh=g_ZoneRefresh.FloatValue;
	float dist=GetVectorDistance(curpos,LastPos[client]);
	TimeAFK[client]++;
	LastDmg[client]++;
	char msg[64];
	if (LastDmg[client]>MaxDmgTime){
		TimeAFK[client]=0;
		LastDmg[client]=0;
		Warnings[client]++;
		msg="Go do some damage!";
	}
	if (dist>(zone+zonerefresh)){ /// if player moves far enough away it auto refreshes
		TimeAFK[client]=0;
		GetClientAbsOrigin(client,LastPos[client]);
		//PrintToServer("Last Position was refreshed");
	}
	if (TimeAFK[client]>=maxtime && dist>zone){ /// just incase there isn't a last position set ( 0, 0 ,0) for some reason
		TimeAFK[client]=0;
		GetClientAbsOrigin(client,LastPos[client]);
		//PrintToServer("Last Position was refreshed");
	}
	if (TimeAFK[client]>=maxtime && dist<zone){
		Warnings[client]++;
		TimeAFK[client]=0;
		msg="Stop standing around doin nothing";
	}
	if (Warnings[client]>=maxwarning){
		Warnings[client]=0;
		TimeAFK[client]=0;
		LastDmg[client]=0;
		switch (AFK_Mode){
			case 0:{
				ChangeClientTeam(client,1);
				PrintToChatAll("%N was moved to spectator due to inactivity (%s)",client,msg);
			}
			case 1:{
				SlapPlayer(client,10);SlapPlayer(client,10);SlapPlayer(client,10);
				PrintToChat(client,"[AFK Manager] HEY! Get a move on bub, %s",msg);
			}
			case 2:{
				ForcePlayerSuicide(client);
				PrintToChat(client,"[AFK Manager] You were slain due to inactivity ( %s )",msg);
			}
			case 3:{
				KickClient(client,"Kicked due to inactivity");
			}
		}
	}else{
		if (!StrEqual(msg,"\0",false)){
			//PrintToServer("%N was warned! (%i times)",client,Warnings[client]);
			PrintToChat(client,"[AFK Manager] Warning %i of %i - %s",Warnings[client],maxwarning,msg);
		}
	}
	PrintToServer("%N timer: %i | LastDMG: %i",client,TimeAFK[client],LastDmg[client]);
	return Plugin_Continue;
}

