/* No Death Frags
*
*
* Description:
* A players won't get -1 kill/frag on scoreboard when he dies, the deaths aren't effected
*
*
* Installation:
* Just put the .smx into your plugins folder of sourcemod.
* Reload the map.
* Edit the auto created config 'plugin.nodeathfrags.cfg' in "<moddir>/cfg/sourcemod/".
*
*
* Configuration:
* The sm_nodeathfrags_enable is the main on off switch set it to 1 the plugin is on, set it to 0 the plugin is always off.
* If sm_nodeathfrags_deathrun is 1 then this plugin will activate only on deathrun maps. If its value is 2 then its only on deathrun maps disabled. 0 means its always on.
*
*
* Changelog:
* v1.1.4
* This version was a revamped verison modified by Minimoney1
* The plugin functions the same, but BOT support has been added and the code has been cleaned up
*
* v1.1.3
* Added check that if you got killed by an other player you won't get +1 kill/frag
*
* v1.1.1
* Corrected description of cvar sm_nodeathfrags_deathrun
* Added sm_nodeathfrags_deathrun option 2.
*
* v1.0.0
* Public release.
*
*
* Thank you Minimoney1 for the update to v1.1.4
*/


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.4"

new Handle:g_cvar_Version = INVALID_HANDLE;
new Handle:g_cvar_Enable = INVALID_HANDLE;
new Handle:g_cvar_Deathrun = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "No Death Frags",
	author = "Chanz, mINI",
	description = "A players won't get -1 kill/frag on scoreboard when he dies, the deaths aren't effected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=132354"
}

public OnPluginStart(){

	g_cvar_Version = CreateConVar("sm_nodeathfrags_version", PLUGIN_VERSION, "No Death Frags Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(g_cvar_Version,PLUGIN_VERSION);
	g_cvar_Enable = CreateConVar("sm_nodeathfrags_enable", "1","Enable or disable no death frags",FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_Deathrun = CreateConVar("sm_nodeathfrags_deathrun", "0","How to handle deathrun maps: 0 this plugin is always on, 1 this plugin is only on deathrun maps on, 2 this plugin is only on deathrun maps off",FCVAR_PLUGIN|FCVAR_DONTRECORD);

	AutoExecConfig(true,"plugin.nodeathfrags");

	if(!HookEventEx("player_death", Event_Death)){
		SetFailState("Can't hook event 'player_death'. This game/mod doesn't support it");
	}
}

public OnConfigsExecuted(){

	if(!GetConVarBool(g_cvar_Enable)){
		return;
	}

	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));

	switch(GetConVarInt(g_cvar_Deathrun)){

		case 1:{

			if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0)){

				SetConVarInt(g_cvar_Enable,true);
			}
			else {

				SetConVarBool(g_cvar_Enable,false);
			}
		}
		case 2:{

			if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0)){

				SetConVarInt(g_cvar_Enable,false);
			}
			else {

				SetConVarBool(g_cvar_Enable,true);
			}
		}
	}
}

public Event_Death(Handle:event, const String:name[], bool:broadcast) {

	if(!GetConVarBool(g_cvar_Enable)){
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (client == attacker || attacker == 0)
	{
		SetEntProp(client, Prop_Data, "m_iFrags", GetClientFrags(client)+1);
	}
}