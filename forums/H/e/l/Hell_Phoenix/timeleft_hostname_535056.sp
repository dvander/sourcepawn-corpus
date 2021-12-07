/*
Timeleft Hostname
Hell Phoenix
http://www.charliemaurice.com/plugins

Description:
  This is a port of Cheap_Suit's amxx plugin to sourcemod.  It grabs the timeleft for the map, and 
  puts it into the hostname so people can see how much time is left on the current map.  Note that 
  because of how the source engine works, this doesnt work until someone joins the server.

Thanks To:
	Cheap Suit - for the original plugin
	Ferret for pointing out some things to fix =D
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Added missing mapend timer kill
	1.2
		* Fixed errors in the console
	1.3
		* Fixed frequency cvar not doing anything if set
		

Cvars:
	sm_timeleft_hostname_frequency 2.0  - How often in seconds to update the hostname with timeleft
		****You MUST set this in a config such as sourcemod.cfg or server.cfg...it cannot be changed 
				"on the fly"

*/


#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

new Handle:cvarTLHNfrequency;
new Handle:TLHNhandle;
new Handle:Hostname;
new String:oldHN[256];
new bool:getHN = false;

public Plugin:myinfo = 
{
	name = "Timeleft Hostname",
	author = "Hell Phoenix",
	description = "Timeleft Hostname",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	CreateConVar("sm_timeleft_hostname_version", PLUGIN_VERSION, "Timeleft Hostname Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarTLHNfrequency = CreateConVar("sm_timeleft_hostname_frequency","2.0","How often in seconds to update the hostname with timeleft",FCVAR_PLUGIN);
	Hostname = FindConVar("hostname");
}

public OnMapStart(){
	CreateTimer(5.0, Timeleft_Start);
}

public Action:Timeleft_Start(Handle:timer){
	TLHNhandle = CreateTimer(GetConVarFloat(cvarTLHNfrequency), Update_Hostname, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:Update_Hostname(Handle:timer){
	if(getHN == false){
		GetConVarString(Hostname, oldHN, sizeof(oldHN));
		getHN = true;
	}
	new timeleft;
	GetMapTimeLeft(timeleft);
	if (timeleft <= 0)
		return Plugin_Handled;
	decl String:NewHN[256];
	Format(NewHN, 256, "%s (Timeleft %d:%02d)", oldHN, (timeleft / 60), (timeleft % 60));
	SetConVarString(Hostname, NewHN);
	return Plugin_Continue;
}

public OnMapEnd(){
  CloseHandle(TLHNhandle);
  SetConVarString(Hostname, oldHN);
}

public OnPluginEnd(){
  CloseHandle(TLHNhandle);
  SetConVarString(Hostname, oldHN);
}