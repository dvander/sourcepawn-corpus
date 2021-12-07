#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0.1"
#define MAX_JOCKEYS 8
#define TEAM_INFECTED 3

//plugin info
//#######################
public Plugin:myinfo =
{
	name = "Jockey jump",
	author = "Die Teetasse",
	description = "Adding the ability that the jockey can jump with a survivor",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122213"
};

/*
//history
//#######################

v1.0.1:
- added client checks
- added cvar for jump force
- added l4d2 check
- fixed flying survivor
- fixed press delay
- added jockey jump sound

v1.0.0:
- initial
*/

//global definitions
//#######################
new jockey_count = 0;
new jockeys[MAX_JOCKEYS];
new victims[MAX_JOCKEYS];
new bool:injump[MAX_JOCKEYS];
new bool:pressdelay[MAX_JOCKEYS];
new Handle:cvar_disabletime;
new Handle:cvar_zforce;

//plugin start
//#######################
public OnPluginStart()
{
	//L4D2 check
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Jockey jump will only work with Left 4 Dead 2!");

	//Cvars
	CreateConVar("l4d2_jockeyjump_version", PLUGIN_VERSION, "Jockey jump version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cvar_disabletime = CreateConVar("l4d2_jockeyjump_delay", "3.0", "Jockey jump - recharge time for the jockey jump", CVAR_FLAGS);
	cvar_zforce = CreateConVar("l4d2_jockeyjump_force", "330.0", "Jockey jump - jump force (z-direction)", CVAR_FLAGS, true, 251.0); //gravity is 250
	
	//Hooking Events
	HookEvent("round_start", Round_Event);
	HookEvent("jockey_ride", Ride_Event);
	HookEvent("jockey_ride_end", Ride_End_Event);
	
	AutoExecConfig(true, "l4d2_jockey_jump");
}

//map start
//events
//#######################
public Action:Round_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	//reset everything
	jockey_count = 0;
	for (new i = 0; i < MAX_JOCKEYS; i++)
	{
		injump[i] = false;
		pressdelay[i] = false;
		jockeys[i] = -1;
		victims[i] = -1;
	}
}

public Action:Ride_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	//more than MAX_JOCKEYS (8)... this one will be ignored...
	if (jockey_count > MAX_JOCKEYS-1) return Plugin_Continue;
	
	new client_jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	//everybody still there?
	if (!IsClientInGame(client_jockey)) return Plugin_Continue;
	if (!IsClientInGame(client_victim)) return Plugin_Continue;
	
	//botjockey?
	if (IsFakeClient(client_jockey)) return Plugin_Continue;
	
	//add a new jockey + victim
	jockeys[jockey_count] = client_jockey;
	victims[jockey_count] = client_victim;
	injump[jockey_count] = false;
	
	//delay jumping for a second (you can get on a survivor by jumping)
	pressdelay[jockey_count] = true;
	CreateTimer(1.0, ResetPressDelay, jockey_count);
	
	jockey_count++;
	
	return Plugin_Continue;
}

public Action:Ride_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new index = -1;
	
	//search for jockey
	for (new i = 0; i < MAX_JOCKEYS; i++)
	{
		if (jockeys[i] == client_jockey)
		{
			index = i;
			break;
		}
	}
	
	//this should not happen, except the plugin is loaded while a game is running
	if (index == -1) return Plugin_Continue;
	
	//delete the jockey
	jockeys[index] = -1;
	victims[index] = -1;
	jockey_count--;	
	
	return Plugin_Continue;
}

//events
//#######################
public Action:OnPlayerRunCmd(client, &buttons)
{
	//are there jockeys?
	if (jockey_count < 1) return;
	
	//pressing jump?
	if (!(buttons & IN_JUMP)) return;
	
	//human?
	if (IsFakeClient(client)) return;
	
	//infected?
	if (GetClientTeam(client) != TEAM_INFECTED) return;
	
	new index = -1;
			
	//searching jockey
	for (new i = 0; i < MAX_JOCKEYS; i++)
	{
		if (jockeys[i] == client)
		{
			index = i;
			break;
		}	
	}
			
	//jockey?
	if (index == -1) return;

	//delay?
	if (injump[index]) return;
	
	//pressdelay?
	if (pressdelay[index]) return;
	
	//activate press delay (half second) regardless of jumping result
	pressdelay[index] = true;
	CreateTimer(0.5, ResetPressDelay, index);
	
	//jump! (if survivor is falling return => no delay)
	if (!jump(victims[index])) return; 
	
	injump[index] = true;
	
	//setdelayreset
	new Float:delay = GetConVarFloat(cvar_disabletime);
	CreateTimer(delay, ResetJump, index);
	
	//display progress bar
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", delay);  
	
	PrintHintText(client, "Jockey jump recharge!");
}

//timer
//#######################
public Action:ResetPressDelay(Handle:timer, any:index)
{
	//reset press delay
	pressdelay[index] = false;
}

public Action:ResetJump(Handle:timer, any:index)
{
	//reset jump
	injump[index] = false;
}

//private function
//#######################
bool:jump(client)
{
	//client still there?
	if (!IsClientInGame(client)) return false;

	//get velocity
	new Float:velo[3];
	velo[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velo[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	velo[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	
	//falling or jumping?
	if (velo[2] != 0) return false;

	//add only velocity in z-direction
	new Float:vec[3];
	vec[0] = velo[0];
	vec[1] = velo[1];
	vec[2] = velo[2] + GetConVarFloat(cvar_zforce);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	
	return true;
}