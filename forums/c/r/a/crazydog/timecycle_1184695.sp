/*					
* Timecycle (c) 2009 Jonah Hirsch
* 
* 
* Changes mapcycles depending on date and time
* 
*  
* Changelog								
* ------------		
* 1.1
*  - Sets mapcycle on server startup
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#define PLUGIN_VERSION "1.1"

new Handle:sm_timecycle_interval = INVALID_HANDLE;
new Handle:sm_timecycle_daily = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Timecycle",
	author = "Crazydog",
	description = "Changes mapcycle based on date and time",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	CreateConVar("sm_timecycle_version", PLUGIN_VERSION, "Timecycle version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_timecycle_interval = CreateConVar("sm_timecycle_interval", "1.0", "Number of hours between mapcycle updates", FCVAR_NOTIFY, true, 1.0, true, 24.0);
	sm_timecycle_daily = CreateConVar("sm_timecycle_daily", "0.0", "Should the plugin have a different set of mapcycles for each day (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	new String:days[7][128] = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };
	new String:path[256];
	new String:daypath[256];
	path = "cfg\\sourcemod\\timecycle\\";
	CreateDirectory(path, 557);
	if(!FileExists(path)){
		new i=0;
		while(i<7){
			Format(daypath, 256, "%s%s\\", path, days[i]);
			CreateDirectory(daypath, 557);
			i++;
		}
	}
	SetMapcycle();
}

public OnMapEnd(){
	SetMapcycle();
}

public SetMapcycle(){
	new time = GetTime();
	new String:day[128];
	new String:hour[128];
	new String:path[256];
	FormatTime(day, 128, "%A", time);
	FormatTime(hour, 128, "%H", time);
	new String:message[256];
	Format(message, 256, "%s %s", day, hour);
	LogMessage(message);
	new ihour = StringToInt(hour);
	if(ihour % GetConVarInt(sm_timecycle_interval) == 0){
		if(GetConVarInt(sm_timecycle_daily) == 0){
			Format(path, 128, "cfg\\sourcemod\\timecycle\\%s.txt", hour);
		}else{
			Format(path, 128, "cfg\\sourcemod\\timecycle\\%s\\%s.txt", day, hour);
		}
		if(FileExists(path)){
			ServerCommand("mapcyclefile %s", path);
			ServerCommand("sm plugins reload nextmap");
		}
	}
}
