#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "6.0"

#define SAVE_ID 0
#define SAVE_KILLS 1
#define SAVE_DEATHS 2
#define SAVE_MONEY 3
#define SAVE_TIME 4

#define SAVE_SIZE 5
#define MAX_SAVE 256

#define CVAR_ALLOW 0
#define CVAR_TIME 1
#define CVAR_CASH 2
#define CVAR_SPEC 3

new save_info[MAX_SAVE][SAVE_SIZE];

new Handle:g_cvars[4];
new g_iAccount;
new bool:hasmapstarted;
//new Handle:adtarray;

new spectace_money[ MAXPLAYERS + 1 ];

public Plugin:myinfo = 
{
	name = "Score saver",
	author = "Nican132",
	description = "Player will not lose their scores on reconnect",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};



public OnPluginStart()
{
	CreateConVar("sm_savescores_version", PLUGIN_VERSION, "Save scores version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvars[CVAR_ALLOW] = CreateConVar("sm_savescore_allow","1","Enable/disable saving scores");
	g_cvars[CVAR_TIME] = CreateConVar("sm_savescore_time","0","Time in seconds server will remember score, 0 for unlimited");
	g_cvars[CVAR_CASH] = CreateConVar("sm_savescore_cash","1","Save Scores will remeber money also");
	g_cvars[CVAR_SPEC] = CreateConVar("sm_savescore_spec","1","Save player money when they go to spec and back to a team");
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	//adtarray = CreateArray(SAVE_SIZE, 0);
	
	HookEvent("player_team", EventPlayerTeamChange);
	HookEvent("player_spawn", EventPlayerSpawn);
}

public OnMapStart(){
	 //ClearArray(adtarray);
	for(new i =0; i< MAX_SAVE; i++){
		save_info[i][SAVE_ID] = 0;
	}
	hasmapstarted = true;
}

public OnMapEnd(){
	hasmapstarted = false;
}

public OnClientPutInServer(client){
	if(!GetConVarInt(g_cvars[CVAR_ALLOW]))
		return;
		
	if(!hasmapstarted)
		return;
		
	spectace_money[client] = 0;
  
	new clientid = GetMysqlId(client);
	//new size =  GetArraySize(adtarray);
	
	for(new i = 0; i < MAX_SAVE; i++){
		//GetArrayArray(adtarray, i, save_inf);
			 
		if(save_info[ i ][ SAVE_ID ] == clientid){
			new cvar = GetConVarInt(g_cvars[CVAR_TIME]);			
			if(cvar == 0){
				LoadPlayerData(client, i);
			} else {
				if(RoundFloat(GetGameTime()) - save_info[i][SAVE_TIME] > cvar)
					LoadPlayerData(client, i);
			}
			break;
		}
		
		if(save_info[ i ][ SAVE_ID ] == 0)
			break;
	}
}
 
public LoadPlayerData(client, id){
	SetEntProp(client, Prop_Data, "m_iFrags", save_info[id][SAVE_KILLS], 4);
	SetEntProp(client, Prop_Data, "m_iDeaths", save_info[id][SAVE_DEATHS], 4);
	if(GetConVarInt(g_cvars[CVAR_CASH]))
		SetMoney(client,save_info[id][SAVE_MONEY]);
}


public OnClientDisconnect(index){
 	if(IsFakeClient(index))
 		return;
 		
 	if(!hasmapstarted)
 		return;
		 
	new clientid = GetMysqlId(index);
	//new size = GetArraySize(adtarray);
	new oldest, oldestId;
	
	for(new i = 0; i< MAX_SAVE; i++){
	 	//GetArrayArray(adtarray, i, save_inf);
	 	if(save_info[i][SAVE_ID] == clientid){
			SaveInfo(index, i);
			return;
		}
		
		if(save_info[i][SAVE_TIME] < oldest){
			oldest = save_info[i][SAVE_TIME];
			oldestId = i;
		}
		
		if(save_info[i][SAVE_ID] == 0)
			break;		
	}
	
	SaveInfo(index, oldestId);	
}

stock SaveInfo(index , id){
 	if(!IsClientConnected(index) || !IsClientInGame(index))
 		return;
 		
 	save_info[id][SAVE_ID] = GetMysqlId(index);
	save_info[id][SAVE_KILLS] = GetClientFrags(index);
	save_info[id][SAVE_DEATHS] = GetClientDeaths(index);
	save_info[id][SAVE_MONEY] = GetEntData(index,g_iAccount,4);
	save_info[id][SAVE_TIME] = RoundFloat(GetGameTime());	
	
/*	if(pushnew)
		PushArrayArray(adtarray, save_info);
	else
		SetArrayArray(adtarray, id, save_info); */
}

public EventPlayerTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
 	new team = GetEventInt(event, "team");
 	
	if(team == 1){
		spectace_money[client] = GetMoney(client);
		return;
	}
	//I tried to set players money when their team == 2 or 3, it does not work
	
}

public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
 	if(!GetConVarInt(g_cvars[CVAR_SPEC]))
		return;
 	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
 	
	if(spectace_money[client] > 0){
	 	//LogMessage("Setting client money to : %d", spectace_money[client]);
		SetMoney(client, spectace_money[client]);
		spectace_money[client] = 0;
	}
}

//I know this may look stupid, but it is a great way to save IDs....
public GetMysqlId(client){
	decl String:auth[32];
	if(GetClientAuthString(client, auth, sizeof(auth))){
		ReplaceString( auth, sizeof(auth), ":" , "" );
		ReplaceString( auth, sizeof(auth), "STEAM_" , "" );
		return StringToInt(auth);		
	}
	return 0;
}

stock SetMoney(client, amount, add = false){
	if(add)
		amount += GetMoney(client);
	if(amount > 16000) amount = 16000;
	if(amount < 0) amount = 0;
	
	SetEntData(client,g_iAccount,amount,4,true);
}

stock GetMoney(client){
	return GetEntData(client,g_iAccount,4);
}