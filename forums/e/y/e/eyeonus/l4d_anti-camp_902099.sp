#include <sourcemod>
#include <sdktools> 
 
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MAX_PLAYERS 1024
#define MAX_LINE_WIDTH 64
#define PLUGIN_TAG "L4DAC"
#define PLUGIN_VERSION "1.4"

/*Changelog:
1.0 - First release
1.1 - Altered code to make the slap timer individual rather than for all survivors.
1.2 - Fixed a glitch where incapped/dead players would get slapped.
1.3 - Made warning message countdown.
1.4 - Added movement checking.
*/

public Plugin:myinfo =
{
	name = "Left 4 Dead Anti-Camping Plugin",
	author = "eyeonus",
	description = "Slaps campers and optional causes damage.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=902099"
};

new bool:active = false
new Handle:l4dac
new Handle:warn_time
new Handle:radius
new Handle:damage
new Handle:SlapTimer[4]
new Float:time_left[4], Float:old_loc[4][3]
new campers[4] = {-1,-1,-1,-1}, survivors[4] = {-1,-1,-1,-1}

public OnPluginStart() {
	HookEvent("player_left_start_area", ServerStart);
	HookEvent("round_start", Deactivate);

	RegAdminCmd("l4d_ac_check", AdminStart, ADMFLAG_GENERIC, "Activate camping check.") //make a camping check
	CreateConVar("l4d_ac_version", PLUGIN_VERSION, "l4dac version", CVAR_FLAGS) //Version
	l4dac = CreateConVar("l4d_ac", "1", "Set to 0 to turn anti-camping off", CVAR_FLAGS) //l4dac toggle
	warn_time = CreateConVar("l4d_ac_warn_time", "5.0", "Camping check warn_time", CVAR_FLAGS, true, 2.0, true, 30.0) //time between warning and slap.
	radius = CreateConVar("l4d_ac_radius", "30.0", "Maximum radius to trigger anti-camping", CVAR_FLAGS, true, 1.0, true, 100.0) //camping radius
	damage = CreateConVar("l4d_ac_slap", "0", "Damage to campers", CVAR_FLAGS, true, 0.0, true, 50.0) //slap damage
	
	AutoExecConfig(true, "l4d_anti-camp")
}

public Action:Deactivate(Handle:event, const String:name[], bool:dontBroadcast) {
	active = false
}

public Action:ServerStart(Handle:event, const String:name[], bool:dontBroadcast) { Activate(); }	

public Action:AdminStart(client, args) { 
	SetConVarBool(l4dac, true)
	Activate()
}

Activate() {
	if (!active) {
		new String:gamemode[9]
		GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
		if (GetConVarBool(l4dac) && StrContains(gamemode, "versus", false) != -1) { //Start timer if anti-camping is enabled and the game mode is versus.
			PrintToChatAll("L4D Anti-Shiva activated.")
			CreateTimer(0.5, AntiCampTimer)
			active = true
			for (new i = 0; i < 4; i++) {
				time_left[i] = GetConVarFloat(warn_time)
			}
		}
	}
}

public Action:SlapClient(Handle:timer , any:client) { CampSlap(client); }

CampSlap(client) { //Slaps the client if still camping after warn_time seconds.
	SlapTimer[client] = INVALID_HANDLE
	if (campers[client] != -1) { //AntiCamp() will set this campers[client] to -1 if the client was not camping during the last check.
		if (GetClientHealth(campers[client]) > GetConVarInt(damage)) { //Only hurt client's if it won't incap.
			SlapPlayer(campers[client], GetConVarInt(damage), true)
			PrintHintText(campers[client], "[%s] Move or you will be slapped again.", PLUGIN_TAG)
		} else { //Slap them for no damage otherwise.
			SlapPlayer(campers[client], 0, true)
			PrintHintText(campers[client], "[%s] Move or you will be slapped again.", PLUGIN_TAG)
		}
		CreateTimer(0.5, SlapClient, client)
	}
}

public Action:AntiCampTimer(Handle:timer) { AntiCamp(); }

AntiCamp() {
	new client = 0, i, compare[6][2], camper[4], bool:standing[8], Float:location[4][3], Float:distance[6], Float:z_distance[6], Float:z_location[4], Float:loc_change[4]

	compare[0] = {0, 1}
	compare[1] = {0, 2}
	compare[2] = {0, 3}
	compare[3] = {1, 2}
	compare[4] = {1, 3}
	compare[5] = {2, 3}
	if (active) {
		survivors = {-1,-1,-1,-1}
		for (i = 1; i < 9; i++) {
			if (IsValidEntity(i) && (GetClientTeam(i) == 2)) { //Find survivors.
				standing[client] = (IsPlayerAlive(i) && (GetEntProp(i, Prop_Send, "m_isIncapacitated") != 1))
				GetClientAbsOrigin(i, location[client]) //Get client's position.
				z_location[client] = location[client][2] //Need to check z-distance separately.
				location[client][2] = 0.0
				survivors[client] = i
				client++
			}
		}
		if (standing[0] && standing[1]) {
			distance[0] = GetVectorDistance(location[0], location[1])
			z_distance[0] = FloatAbs(z_location[0]-z_location[1])
		} else {
			distance[0] = 500.0
			z_distance[0] = 500.0
		}
		if (standing[0] && standing[2]) {
			distance[1] = GetVectorDistance(location[0], location[2])
			z_distance[1] = FloatAbs(z_location[0]-z_location[2])
		} else {
			distance[1] = 500.0
			z_distance[1] = 500.0
		}
		if (standing[0] && standing[3]) {
			distance[2] = GetVectorDistance(location[0], location[3])
			z_distance[2] = FloatAbs(z_location[0]-z_location[3])		
		} else {
			distance[2] = 500.0
			z_distance[2] = 500.0
		}
		if (standing[1] && standing[2]) {
			distance[3] = GetVectorDistance(location[1], location[2])			
			z_distance[3] = FloatAbs(z_location[1]-z_location[2])
		} else {
			distance[3] = 500.0
			z_distance[3] = 500.0
		}
		if (standing[1] && standing[3]) {
			distance[4] = GetVectorDistance(location[1], location[3])
			z_distance[4] = FloatAbs(z_location[1]-z_location[3])
		} else {
			distance[4] = 500.0
			z_distance[4] = 500.0
		}
		if (standing[2] && standing[3]) {
			distance[5] = GetVectorDistance(location[2], location[3])
			z_distance[5] = FloatAbs(z_location[2]-z_location[3])
		} else {
			distance[5] = 500.0
			z_distance[5] = 500.0
		}

		for (i = 0; i < 6; i++) { //Check for campers.
			if (FloatCompare(distance[i], GetConVarFloat(radius)) < 1 && FloatCompare(z_distance[i], 100.0) < 1) {
				camper[compare[i][0]]++
				camper[compare[i][1]]++
			}
		}			
		for (i = 0; i < 4; i++) { //ID any campers found.
			if (camper[i]) {
				campers[i] = survivors[i]
			} else {
				campers[i] = -1
			}
		}
		for (i = 0; i < 4; i++) {
			loc_change[i] = GetVectorDistance(location[i], old_loc[i])
			old_loc[i] = location[i]
			if (campers[i] != -1 && FloatCompare(loc_change[i], GetConVarFloat(radius)/2) < 1) { //Initial detection, issue warning and start slap timer.
				PrintHintText(campers[i], "[%s] Warning: You have %.1f seconds to move.", PLUGIN_TAG, time_left)
				time_left[i] -= 0.5
				if (SlapTimer[i] == INVALID_HANDLE) {
					SlapTimer[i] = CreateTimer(GetConVarFloat(warn_time)+1, SlapClient, i)
				}
			} else {
				if ( SlapTimer[i] != INVALID_HANDLE ) {
					KillTimer(SlapTimer[i])
					SlapTimer[i] = INVALID_HANDLE
				}
				time_left[i] = GetConVarFloat(warn_time)
			}
		}
		CreateTimer(0.5, AntiCampTimer)
	}
}