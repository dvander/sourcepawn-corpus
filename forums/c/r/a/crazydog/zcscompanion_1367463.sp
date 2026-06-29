/*
* ZCS Comapnion (c) 2009 Jonah Hirsch
* 
* 
* Turns on ZCS of all zombies are admins
* Turns off ZCS if not all zombies are admins
*  
* Changelog								
* ------------	
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>

public Plugin:myinfo =
{
	name = "ZCS Companion",
	author = "Crazydog",
	description = "Toggles ZCS based on admins on infected team",
	version = "1.0",
	url = "http://www.theelders.net"
};


#include <sdktools>
#define PLUGIN_VERSION "1.0"
#define TEAM_INFECTED 3

public OnPluginStart(){
	HookEvent("player_team", event_changeTeam);
}

public Action:event_changeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	checkPlayer(client, team);
}

checkPlayer(client, team){
	if(client == 0){return;} 
	if(IsFakeClient(client)){return;}
	new String:name[256];
	new bool:nonAdminZombie = false;
	new Handle:g_hAccessLevel = FindConVar("zcs_access_level");
	new String:g_sAccessLevel[8];
	GetConVarString(g_hAccessLevel, g_sAccessLevel, sizeof(g_sAccessLevel));
	for (new i=1; i<=MaxClients; i++)
    {
		if(IsClientInGame(i) && !IsFakeClient(i)){
			GetClientName(i, name, 256);
			new currTeam;
			if(i == client){
				currTeam = team;
			}else{
				currTeam = GetClientTeam(i);
			}	
			if(currTeam == TEAM_INFECTED){
				if(GetUserFlagBits(i)&ReadFlagString(g_sAccessLevel) == 0){
					nonAdminZombie = true;
					break;
				}
			}
		}
    }
	if(nonAdminZombie){
		ServerCommand("zcs_enable 0");
	}else{
		ServerCommand("zcs_enable 1");
		ServerCommand("sm plugins reload l4d2_zcs");
	}
}