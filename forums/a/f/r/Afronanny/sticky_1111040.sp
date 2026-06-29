/* TODO:
* Knock stickies off with scout's bat
* Kamikaze confirmation
* public cvar
* Limit number of stickies that can be stuck to players
* Damage multiplier for stickies that are stuck to players
* more?
* */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//Convar flag (more to come later?)
#define FLAGS	FCVAR_PLUGIN

#define STICKY	"tf_projectile_pipe_remote"
#define PLAYER		"player"

new bool:bEnabled = true;
new bool:bKamikaze = false;

new Handle:hCvarEnabled;
new Handle:hCvarKamikaze;

public Plugin:myinfo = 
{
	name = "True Sticky Bombs",
	author = "Afronanny",
	description = "Demoman's Stickies stick to players",
	version = "1.0",
	url = "http://lmgtfy.com/"
}

public OnPluginStart()
{
	hCvarEnabled = CreateConVar("sm_sticky_enabled", "1", "Enable stickies sticking to players", FLAGS);
	hCvarKamikaze = CreateConVar("sm_sticky_kamikaze", "0", "Allow demomen to stick players of their own team", FLAGS);
	
	HookConVarChange(hCvarEnabled, ConVarChanged_Enabled);
	HookConVarChange(hCvarKamikaze, ConVarChanged_Kamikaze);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (bEnabled && strcmp(classname, STICKY) == 0)
	{
		SDKHook(entity,SDKHook_Touch, StickyTouch);
	}

}

//Entity is the one doing the touching
//Other is the entity being touched
public StickyTouch(entity, other)
{
	//Classnames of entities
	new String:otherName[64];
	new String:classname[64];
	
	GetEdictClassname(entity, classname, sizeof(classname));
	GetEdictClassname(other, otherName, sizeof(otherName));
	
	//Get the person who launched the sticky
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	
	//If the entity is a sticky, the other entity is a player,
	//the other entity is not the owner, and they are on different teams, continue, stick 'em
	if (strcmp(classname, STICKY) == 0 && strcmp(otherName, PLAYER) == 0 && other != owner)
	{
		//Block kamikaze if disabled
		if (GetClientTeam(owner) == GetClientTeam(other) && !bKamikaze)
			return;
		
		//Convert target index to a string
		new String:sStickTo[64];
		IntToString(other, sStickTo, sizeof(sStickTo));
		
		//Set the targetname of the player getting stuck
		DispatchKeyValue(other, "targetname", sStickTo);
		
		//Set the parent of the sticky to the target player
		SetVariantString(sStickTo);
		AcceptEntityInput(entity, "SetParent");
		
		//Unhook the entity, otherwise this callback gets uber spammed
		SDKUnhook(entity, SDKHook_Touch, StickyTouch);
	}
	
}

public ConVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new enabled = StringToInt(newValue);
	//if convar value equals 1, plugin enabled
	if (enabled == 1)
		bEnabled = true;
	//if convar value does not equal 1, plugin disabled
	if (enabled != 1)
		bEnabled = false;
}
public ConVarChanged_Kamikaze(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new enabled = StringToInt(newValue);
	//if convar value equals 1, kamikaze enabled
	if (enabled == 1)
		bKamikaze = true;
	//if convar value does not equal 1, kamikaze disabled
	if (enabled != 1)
		bKamikaze = false;
}

