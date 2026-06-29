
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools> 
#define PLUGIN_NAME "Clone Fun"
#include <MLIB>

new Handle:cvar

#define SND "puppet/poof1.wav"
#define SND_SPAWN "puppet/spawn1.wav"
#define SND_SPAWN_PATH "sound/puppet/spawn1.wav"
#define SND_PATH "sound/puppet/poof1.wav"
#define STRLENGTH 128
#define MAX_PLAYERS 33
#define PLUGIN_VERSION "2.0"

new bot[35];
new owner[35];

public Plugin:myinfo = 
{
	name = "CloneFun",
	author = "Mentlegen",
	description = "Clones'll help you to fight! Exchange position with them! Bring them to to you, to replace you a bit! But know - they has no gravity and they can't walk and shoot!",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_addbot", AddBot);
	RegConsoleCmd("sm_delbot", DelBot);
	RegAdminCmd("sm_execbot", ExecBot, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_telebot", TeleBot);
	RegConsoleCmd("sm_bringbot", BringBot);
	RegConsoleCmd("say !clonehelp", ShowHelp);
	RegConsoleCmd("say_team !clonehelp", ShowHelp);
	RegConsoleCmd("say !bindhelp", BindHelp);
	RegConsoleCmd("say_team !bindhelp", BindHelp);
	HookEvent("player_death",Event);
	
	cvar = CreateConVar("sm_clonefun_version", PLUGIN_VERSION, "CloneFun version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	for (new i=1; i<=34; i+=1) {
		owner[i] = -1;
		bot[i] = -1;
	}
	
	CreateTimer(45.0, Show, 2, TIMER_REPEAT);
	CreateTimer(1.0, Step, 2, TIMER_REPEAT)
}

public OnMapStart() {
	PrecacheSound(SND,true);
	PrecacheSound(SND_SPAWN,true);
	AddFileToDownloadsTable(SND_PATH);
	AddFileToDownloadsTable(SND_SPAWN_PATH);
}

public Action:Step(Handle:timer, any:lol) {
	ForLoop1()
}

public Action:Event(Handle:event, const String:name[], bool:dontBroadcast) {
	new victimId = GetEventInt(event, "userid")
	new victim = GetClientOfUserId(victimId)
	for(new i=1; i<=MAX_PLAYERS; i++) {
		if (victim==bot[i]) {
			//GetClientAbsOrigin(victim,vector)
			ReAddBot(owner[i], true);
		}
	}
}

ForLoop1() {
	for (new i=1; i<=MAX_PLAYERS; i+=1) {
		if (GetClientTeam(owner[i]) != GetClientTeam(bot[i])) {
			ReAddBot(owner[i], true)
		}
		if (TF2_GetPlayerClass(owner[i]) != TF2_GetPlayerClass(bot[i])) {
			ReAddBot(owner[i], false)
		}
	}
}

public Action:AddBot(client, args) {
	if (bot[client] != -1) {
		PrintToChat(client,"You already have got one!") 
		PrintToConsole(client, "You already have one!") 
	}
	bot[client] = CreateFakeClient("Clone")
	ChangeClientTeam(bot[client], GetClientTeam(client))
	TF2_SetPlayerClass(bot[client], TFClassType:TF2_GetPlayerClass(client), true, true)
	owner[client] = client
	new Handle:spawn = CreateEvent("player_spawn",true)
	SetEventInt(spawn,"userid",bot[client])
	FireEvent(spawn, false)
	EmitSoundToAll(SND_SPAWN, bot[client])
	new Float:pos[3]
	GetClientAbsOrigin(bot[client], pos)
	ShowParticle(pos, "mini_fireworks", 1.0)
	return Plugin_Handled
}


/**
* Reconnects clone to server. Useful for changing team/class and respawning after death.
*
* Note: Clone'll automaticly join owner's team and class.
* 
* @param owner		Owners's index.
* @param playsnd  	Play spawn sound, or not.
* @noreturn
* @error				Invalid client index.
*/
ReAddBot(client, bool:playsnd) {
	EmitSoundToAll(SND, bot[client])
	KickClient(bot[client]);		
	bot[client] = -1;
	bot[client] = CreateFakeClient("Clone")
	ChangeClientTeam(bot[client], GetClientTeam(owner[client]))
	TF2_SetPlayerClass(bot[client], TFClassType:TF2_GetPlayerClass(owner[client]), false, true)
	new Float:pos[3];
	GetClientAbsOrigin(bot[client], pos)
	ShowParticle(pos, "mini_fireworks", 1.0)
	if (playsnd) {
		EmitSoundToAll(SND, bot[client])
	}
}

public Action:DelBot(client, args) {
	if (bot[client] == -1) {
		PrintToChat(client,"Noone to kick!") 
		PrintToConsole(client, "Noone to kick!") 
		return Plugin_Handled
	}
	EmitSoundToAll(SND, bot[client])
	KickClient(bot[client])
	bot[client] = -1
	owner[client]=-1
	return Plugin_Handled
}

public Action:TeleBot(client, args) {
	new Float:playervector[3]
	new Float:botvector[3]
	new Float:boteye[3]
	new Float:playereye[3]
	if (IsPlayerAlive(owner[client]) && IsPlayerAlive(bot[client])) {
		EmitSoundToAll(SND_SPAWN, bot[client])
		GetClientAbsOrigin(owner[client], playervector)
		GetClientAbsOrigin(bot[client], botvector)
		GetClientEyeAngles(owner[client], playereye)
		GetClientEyeAngles(bot[client], boteye)
		TeleportEntity(owner[client],botvector,boteye,NULL_VECTOR)
		TeleportEntity(bot[client],playervector,playereye,NULL_VECTOR)
		new Float:pos[3]
		GetClientAbsOrigin(bot[client], pos)
		ShowParticle(pos, "mini_fireworks", 1.0)
	}
	return Plugin_Handled
}

public Action:BringBot(client, args) {
	new Float:playervector[3]
	new Float:playereye[3]
	if (IsPlayerAlive(owner[client]) && IsPlayerAlive(bot[client])) {
		GetClientAbsOrigin(owner[client], playervector)
		GetClientEyeAngles(owner[client], playereye)
		TeleportEntity(bot[client],playervector, playereye, NULL_VECTOR)
		EmitSoundToAll(SND_SPAWN, bot[client])
		new Float:pos[3]
		GetClientAbsOrigin(bot[client], pos)
		ShowParticle(pos, "mini_fireworks", 1.0)
	}
	return Plugin_Handled
}

public Action:ExecBot(client, args) {
	new String:arg1[32]
	new String:arg2[32]
	new String:arg3[32]
	new count
	count = GetCmdArgs()
	for (new i = 1 ;i<=count; i++) 
	{
		if (i==1) {
			GetCmdArg(1, arg1, sizeof(arg1))
		}
		if (i==2) {
			GetCmdArg(2, arg2, sizeof(arg2))
		}
		if (i==3) {
			GetCmdArg(3, arg3, sizeof(arg3))
		}
	}
	FakeClientCommandEx(bot[client], "%s %s %s", arg1, arg2, arg3)
	return Plugin_Handled
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[STRLENGTH]
		GetEdictClassname(particle, classname, sizeof(classname))
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle)
		}
		else
		{
			LogError("DeleteParticles: not removing entity - not a particle '%s'", classname)
		}
	}
}
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system")
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
		DispatchKeyValue(particle, "effect_name", particlename)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "start")
		CreateTimer(time, DeleteParticles, particle)
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system")
	}	
}

public Action:Show(Handle:timer, any:lol) {
	ShowHelp(0, 0);
	BindHelp(0, 0)
	return Plugin_Continue
}

public Action:ShowHelp(client, args) {
	PrintToChatAll("sm_addbot - adds clone; sm_telebot - exchange position with clone; sm_delbot - delete clone; sm_bringbot - teleport clone to you. If you don't know how to bind, type in chat : !bindhelp")
	return Plugin_Handled
}

public Action:BindHelp(client, args) {
	PrintToChatAll("open console [ ` key ] and type this : bind <key> <function> , without <>. You can swith console on in keyboard options menu. Then press a desired key. For example : bind q sm_telebot . By pressing q you'll exchange position with your clone.")
	return Plugin_Handled
}

public OnClientDisconnect(client) {
	if (bot[client] != -1) {
		KickClient(bot[client]);
		owner[client] = -1
	}
}