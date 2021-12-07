/*					
* 'Mapchooser Extended' companion (c) 2009 Jonah Hirsch
* 
* 
* Schedules mapchooser votes based on winlimit or maxrounds
* 
*  
* Changelog								
* ------------		
* 2.0									
*  - Initial Public Release			
* 
* 		
*/

#include <sourcemod>
#define PLUGIN_VERSION "2.0"

new Handle:winlimit = INVALID_HANDLE;
new Handle:maxrounds = INVALID_HANDLE;
//new Handle:timelimit = INVALID_HANDLE;
new Handle:sm_mcec_bonustime = INVALID_HANDLE;
new Handle:sm_mcec_votetime = INVALID_HANDLE;
new Handle:sm_mcec_warntime = INVALID_HANDLE;
new Handle:sm_mcec_runoffwarntime = INVALID_HANDLE;
new Handle:sm_mcec_bonusroundrunoff = INVALID_HANDLE;
new bool:set;

public Plugin:myinfo = 
{
	name = "'Mapchooser extended' companion",
	author = "Crazydog",
	description = "Schedules mapchooser votes based on winlimit or maxrounds",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	winlimit = FindConVar("mp_winlimit");
	maxrounds = FindConVar("mp_maxrounds");
	//timelimit = FindConVar("mp_timelimit");	
	HookEvent("teamplay_round_active", Event_RoundStart);
	CreateConVar("sm_mcec_version", PLUGIN_VERSION, "Mapchooser extended companion version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_mcec_bonustime = CreateConVar("sm_mcec_bonustime", "15", "Bonus round time when maxrounds or winlimit is > 1", FCVAR_NOTIFY, true, 0.0, true, 30.0);
	sm_mcec_votetime = CreateConVar("sm_mcec_votetime", "30", "Vote time when maxrounds or winlimit is > 1", FCVAR_NOTIFY, true, 5.0);
	sm_mcec_warntime = CreateConVar("sm_mcec_warntime", "5", "Vote warning time when maxrounds or winlimit is > 1",  FCVAR_NOTIFY, true, 0.0, true, 60.0);
	sm_mcec_runoffwarntime = CreateConVar("sm_mcec_runoffwarntime", "5", "Runoff warning time when maxrounds or winlimit is > 1", FCVAR_NOTIFY,true, 0.0, true, 30.0);
	sm_mcec_bonusroundrunoff = CreateConVar("sm_mcec_bonusroundrunoff", "0", "Enable runoff voting during bonus round votes?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public OnMapStart(){
	new String:currentMap[128];
	GetCurrentMap(currentMap, 128);
	set = false;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	if(!set){
		new bonustime = GetConVarInt(sm_mcec_bonustime);
		new votetime = GetConVarInt(sm_mcec_votetime);
		new warntime = GetConVarInt(sm_mcec_warntime);
		new runoffwarntime = GetConVarInt(sm_mcec_runoffwarntime);
		new bonusroundrunoff = GetConVarInt(sm_mcec_bonusroundrunoff);
		new winamt = GetConVarInt(winlimit);
		new roundamt = GetConVarInt(maxrounds);
		if((roundamt > 1 || winamt > 1)){
			ServerCommand("sm_mapvote_startround 1");
			ServerCommand("mp_bonusroundtime %i", bonustime);
			ServerCommand("sm_mapvote_runoffvotewarningtime %i", runoffwarntime);
			ServerCommand("sm_mapvote_voteduration %i", votetime);
			ServerCommand("sm_mapvote_warningtime %i", warntime);
		}else{
			if(bonusroundrunoff == 0){
				ServerCommand("sm_mapvote_startround 0");
				ServerCommand("mp_bonusroundtime 30");
				ServerCommand("sm_mapvote_runoffvotewarningtime 0");
				ServerCommand("sm_mapvote_voteduration 28");
				ServerCommand("sm_mapvote_warningtime 0");
				ServerCommand("sm_mapvote_runoff 0");
			}else{
				ServerCommand("sm_mapvote_startround 0");
				ServerCommand("mp_bonusroundtime 30");
				ServerCommand("sm_mapvote_runoffvotewarningtime 0");
				ServerCommand("sm_mapvote_voteduration 12");
				ServerCommand("sm_mapvote_warningtime 0");
				ServerCommand("sm_mapvote_runoff 1");
			}
		}
		
	
		//This automatically sets the interval for the automatic 'timeleft' message.
		//It divides the timelimit by 5, and uses that as the interval.
		//Uncoment if you want to use it.
		//Also uncomment the timelimit lines above (one in onpluginstart, one above that)
		/*new timeamt = GetConVarInt(timelimit);
		if(timeamt != 0){
			new interval = (timeamt / 5) * 60;
			ServerCommand("sm_timeleft_interval %i", interval);
		}*/
		set = true;
	}
}

public OnMapEnd(){
	set = false;
}
