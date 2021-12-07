/*
* [L4D] Crawl Balancer (c) 2009 Jonah Hirsch
* 
* 
* Increases damage while crawling
* 
*  
* Changelog								
* ------------	
* 1.1
*  - Fixed bug where non-incapped survivors would take extra damage
*  - Because of that fix, incapped survivors with less than 100 health will take normal damage
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

new crawlers[MAXPLAYERS];
//new grabbers[MAXPLAYERS];
new Handle:sm_crawlbalance_multiplier = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Crawl Balancer",
	author = "Crazydog",
	description = "Increases damage while crawling",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	HookEvent("player_incapacitated", playerIncapped);
	HookEvent("player_hurt", increaseDamage, EventHookMode_Pre);
	HookEvent("player_death", resetCrawlers);
	HookEvent("revive_success", resetCrawlers);
	//HookEvent("player_ledge_grab", ledgeGrab);
	//HookEvent("player_ledge_release", resetCrawlers);
	sm_crawlbalance_multiplier = CreateConVar("sm_crawlbalance_multiplier", "1.3", "Multiplier for damage while crawling", FCVAR_NOTIFY, true, 1.0, true, 33.0);
	CreateConVar("sm_crawlbalance_version", PLUGIN_VERSION, "Crawl Balancer version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnMapStart(){
	new Handle:crawling = FindConVar("survivor_allow_crawling");
	SetConVarInt(crawling, 1);
}

public OnMapEnd(){}

public OnClientAuthorized(client, const String:auth[]){
	crawlers[client] = 0;
	//grabbers[client] = 0;
}

public playerIncapped(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && (!IsFakeClient(client)) && GetClientTeam(client) == 2){
		crawlers[client] = 1;
	}
}

/*public ledgeGrab(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && (!IsFakeClient(client)) && GetClientTeam(client) == 2){
		grabbers[client] = 1;
	}
}*/

public Action:increaseDamage(Handle:event, const String:name[], bool:dontBroadcast){
	decl Float:damage, Float:newDamage, String:attackedName[MAX_NAME_LENGTH], client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && (!IsFakeClient(client)) && GetClientTeam(client) == 2 && crawlers[client] == 1 /*&& grabbers[client] == 0 */&& (GetClientButtons(client) & IN_FORWARD) && GetClientHealth(client) > 100){
		GetClientName(client, attackedName, MAX_NAME_LENGTH);
		damage = GetEventFloat(event, "dmg_health");
		newDamage = damage * GetConVarFloat(sm_crawlbalance_multiplier);
		new newDamageI = RoundToCeil(newDamage);
		new damageI = RoundToFloor(damage);
		SetEntityHealth(client, GetClientHealth(client)-(newDamageI-damageI));
		return Plugin_Changed;	
	}
	return Plugin_Continue;
}

public resetCrawlers(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	crawlers[client] = 0;
	//grabbers[client] = 0;
}