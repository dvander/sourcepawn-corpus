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
new bool:bPickup = false;

new Handle:hCvarEnabled;
new Handle:hCvarKamikaze;
new Handle:hCvarPickup;

new Handle:hTrie;


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
	hCvarPickup = CreateConVar("sm_sticky_pickup", "0", "Pickup stickies from the ground or walls", FLAGS);
	
	HookConVarChange(hCvarEnabled, ConVarChanged_Enabled);
	HookConVarChange(hCvarKamikaze, ConVarChanged_Kamikaze);
	HookConVarChange(hCvarPickup, ConVarChanged_Pickup);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	hTrie = CreateTrie();
}

public OnEntityCreated(entity, const String:classname[])
{
	if (bEnabled && strcmp(classname, STICKY) == 0)
	{
		SDKHook(entity,SDKHook_Touch, StickyTouch);
	}
	
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:sStickTo[64];
	Format(sStickTo, sizeof(sStickTo), "player%i", client);
	//Set the targetname of the player getting stuck
	DispatchKeyValue(client, "targetname", sStickTo);
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new maxents = GetMaxEntities();
	new value;
	new String:val[6];
	for (new i = 0; i < maxents; i++)
	{
		IntToString(i, val, sizeof(val));
		if (GetTrieValue(hTrie, val, value) && value == client)
		{
			SetVariantString("");
			AcceptEntityInput(i, "SetParent");
			RemoveFromTrie(hTrie, val);
		}
	}
	return Plugin_Continue;
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
	//the other entity is not the owner, stick 'em
	if (strcmp(classname, STICKY) == 0 && strcmp(otherName, PLAYER) == 0 && other != owner)
	{
		//Block kamikaze if disabled
		if (GetClientTeam(owner) == GetClientTeam(other) && !bKamikaze)
			return;
		
		//Convert target index to a string
		new String:sStickTo[64];
		Format(sStickTo, sizeof(sStickTo), "player%i", other);
		//Set the targetname of the player getting stuck
		
		//Set the parent of the sticky to the target player
		SetVariantString(sStickTo);
		AcceptEntityInput(entity, "SetParent");
		decl String:ent[16];
		IntToString(entity, ent, sizeof(ent));
		
		SetTrieValue(hTrie, ent, other);
		
		if (bPickup)
			SDKUnhook(entity, SDKHook_Touch, StickyTouch);
		return;
	}
	//Unhook the entity, otherwise this callback gets uber spammed
	SDKUnhook(entity, SDKHook_Touch, StickyTouch);
	
}

public Action:SetTransmit(entity, client)
{
	if (GetEntProp(entity, Prop_Send, "moveparent") == client)
	{
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
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

public ConVarChanged_Pickup(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new enabled = StringToInt(newValue);
	if (enabled == 1)
		bPickup= true;
	if (enabled != 1)
		bPickup = false;
}


