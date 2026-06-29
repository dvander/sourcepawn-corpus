/*
* Limit Difficulty (c) 2009 Jonah Hirsch
* 
* 
* Kicks players if difficulty is not Advanced or Expert
* 
* 
* Changelog								
* ------------	
* 1.1
*  - Fixed Advanced + Expert restrictions not working
* 1.0									
*  - Initial Release			
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

new Handle:l4d_allow_easy
new Handle:l4d_allow_normal
new Handle:l4d_allow_advanced
new Handle:l4d_allow_expert
new bool:alloweasy, bool:allownormal, bool:allowadvanced, bool:allowexpert

public Plugin:myinfo = 
{
	name = "Limit Difficulty",
	author = "Crazydog",
	description = "Kicks players if difficulty is not Advanced or Expert",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	CreateConVar("l4d_difficulty_version", PLUGIN_VERSION, "Limit Difficulty Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	l4d_allow_easy = CreateConVar("l4d_allow_easy", "1", "Allow easy games?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_allow_normal = CreateConVar("l4d_allow_normal", "1", "Allow normal games?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_allow_advanced = CreateConVar("l4d_allow_advanced", "1", "Allow advanced games?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_allow_expert = CreateConVar("l4d_allow_expert", "1", "Allow expert games?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	AutoExecConfig(true, "l4d_difficulty")
}

public OnMapStart(){
	alloweasy = GetConVarBool(l4d_allow_easy)
	allownormal = GetConVarBool(l4d_allow_normal)
	allowadvanced = GetConVarBool(l4d_allow_advanced)
	allowexpert = GetConVarBool(l4d_allow_expert)
}

public OnMapEnd(){
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen){
	new String:gamemode[64]
	new String:difficulty[64]
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode))
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty))
	if(StrEqual(gamemode, "coop")){
		if(!alloweasy){
			if(StrEqual(difficulty, "Easy")){
				KickClient(client, "Easy mode is disallowed on this server")
			}
		}
		if(!allownormal){
			if(StrEqual(difficulty, "Normal")){
				KickClient(client, "Normal mode is disallowed on this server")
			}
		}
		if(!allowadvanced){
			if(StrEqual(difficulty, "Hard")){
				KickClient(client, "Advanced mode is disallowed on this server")
			}
		}
		if(!allowexpert){
			if(StrEqual(difficulty, "Impossible")){
				KickClient(client, "Expert mode is disallowed on this server")
			}
		}
	}
	return true
}
