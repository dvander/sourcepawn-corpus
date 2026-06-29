#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle sm_redman_kills = INVALID_HANDLE;

char redMan[64];
bool started = false;
int startDeaths = 0;
StringMap playerInfo;

//#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	
	sm_redman_kills = CreateConVar("sm_redman_kills","4","Red man deaths before switching.");	
	HookEvent("player_death", Event_PlayerDeath);
	playerInfo = CreateTrie();
	
}
public void OnPluginEnd(){
	ClearTrie(playerInfo);
}
public void OnMapEnd(){
	ClearTrie(playerInfo);
}
public void OnMapStart(){
	resetTurnCounter();
}
void resetTurnCounter(){
	ClearTrie(playerInfo);
	playerInfo = CreateTrie();
	
	char authString[64];
	for (int i = 1; i < MaxClients+1;i++){
		if(IsClientConnected(i) && !(IsFakeClient(i))){
			if(GetClientAuthId(i,AuthId_SteamID64, authString, 64)){			
				SetTrieValue(playerInfo, authString, 0);
			}
		}
	}
}
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
	int victimId = event.GetInt("userid");
	int victim = GetClientOfUserId(victimId);
	char auth[64];
	GetClientAuthId(victim, AuthId_SteamID64, auth, 64);

	if(StrEqual(redMan,auth)){
		int deaths = GetClientDeaths(victim);
		
		if((deaths - startDeaths) >= GetConVarInt(sm_redman_kills)-1){
			PrintToChatAll("Kill The Red Man!");
			char turns[64];
			int t;
			GetTrieValue(playerInfo, auth, t);
			IntToString(t, turns, 64);
			//PrintToChatAll(turns);
			chooseRedMan();
		}
	}
}
public OnClientAuthorized(int client, const char[] auth){
	int turns = 0;
	//SDKHook(client, SDKHook_WeaponCanUse, WeaponCanSwitchTo);
	//SDKHook(client, SDKHook_OnTakeDamage, TakeDamage);
	char authID[64];
	if(IsClientConnected(client) && !(IsFakeClient(client))){
		GetClientAuthId(client, AuthId_SteamID64, authID, 64);
		if(!GetTrieValue(playerInfo,authID,turns)){
			SetTrieValue(playerInfo,authID, 0);
			
		}
	}
}
public void OnClientPutInServer(int client)
{
	//PrintToChatAll("hooked client damage");
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

} 
public OnClientDisconnect(int client){
	//SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanSwitchTo);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	char auth[64];
	GetClientAuthId(client, AuthId_SteamID64, auth, 64);
	if(StrEqual(auth,redMan)){
		char empty[64];
		redMan = empty;
	}
	
}

 public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype){
 	if (!started)return Plugin_Continue;
	//PrintToChatAll("hooking take damage");
	char authStringVictim[64];
	char authStringAttacker[64];
	
	bool success = GetClientAuthId(victim,AuthId_SteamID64, authStringVictim, 64);
	success = GetClientAuthId(attacker,AuthId_SteamID64, authStringAttacker, 64) && success;
	if (!success){
		//PrintToChatAll("at least one client is invalid");
		//PrintToChatAll(authStringVictim);
		//PrintToChatAll(authStringAttacker);
		return Plugin_Continue;
	}
	
	if(!(StrEqual(authStringAttacker,redMan)) && !(StrEqual(authStringVictim,redMan)) && !(StrEqual(authStringVictim,authStringAttacker))){
		//PrintToChatAll("both clients are not redMan");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (!started) return Plugin_Continue;
	char sWeapon[32];
	char auth[64];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	GetClientAuthId(client, AuthId_SteamID64, auth, 64);
	if(!(StrEqual(redMan,auth))){
		if(StrEqual(sWeapon,"weapon_physcannon")){
				if(buttons & IN_ATTACK2){
					buttons = buttons - IN_ATTACK2;
				}
		}
		int a1 = buttons & IN_ATTACK;
		int a2 = buttons & IN_ATTACK2;
		bool acceptWeapon = StrEqual(sWeapon,"weapon_stunstick");
		acceptWeapon = StrEqual(sWeapon,"weapon_crowbar") || acceptWeapon;
		acceptWeapon = StrEqual(sWeapon,"weapon_physcannon") || acceptWeapon;
		if(!acceptWeapon){
			if(a1){
				buttons = buttons - IN_ATTACK;
			}
			if(a2){
				buttons = buttons - IN_ATTACK2;
			}
		}
	}
	
	
	return Plugin_Continue;
}
public void setRedMan(int client){
	for (int i = 1; i < MaxClients+1;i++){
		if(IsClientConnected(i) && !(IsFakeClient(i))){
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
	SetEntityRenderColor(client, 255, 0, 0, 255);
	char auth[64];
	GetClientAuthId(client, AuthId_SteamID64, auth, 64);
	redMan = auth;
	int turns;
	if(!GetTrieValue(playerInfo,auth,turns)){
		SetTrieValue(playerInfo,auth, 1);
	}
	else{
		turns = turns + 1;
		SetTrieValue(playerInfo, auth, turns);
	}
	PrintToChat(client, "YOU ARE THE RED MAN");
	startDeaths = GetClientDeaths(client);
}
public void chooseRedMan(){
	int minTurns = 100;
	int minClient = 0;
	int turns =0;
	for (int client = 1; client < MaxClients+1; client++){
		char auth[64];
		if(IsClientConnected(client) && !(IsFakeClient(client))){
		if(GetClientAuthId(client, AuthId_SteamID64, auth, 64)){
			if(!GetTrieValue(playerInfo, auth, turns)){
				setRedMan(client);
				return;
			}
			else{
				if(minTurns > turns){
					minTurns = turns;
					minClient = client;
				}
			
			}
		}
	}
	}
	//char minClientString[64];
	//IntToString(minClient, minClientString, 64);
	//PrintToChatAll(minClientString);
	setRedMan(minClient);

}
public Action OnClientSayCommand(int client, const char[] command, const char[] arg){
	//PrintToChatAll(command);
	//PrintToChatAll(arg);
	char clientInd[64];
	IntToString(client, clientInd, 64);
	//PrintToChatAll(clientInd);
	char auth[64];
	GetClientAuthId(client, AuthId_SteamID64, auth, 64);
	
	//PrintToChatAll(auth);
	if(StrEqual(arg,"!redman")){
		started = true;
		resetTurnCounter();
		chooseRedMan();
	}
	if(StrEqual(arg,"!noredman")){
		started = false;
		char empty[64];
		redMan = empty;
		for (int i = 1; i < MaxClients+1;i++){
			if(IsClientConnected(i) && !(IsFakeClient(i))){
				SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
	}
}