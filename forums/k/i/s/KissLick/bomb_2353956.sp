#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colorvariables>

#define PLUGIN_AUTHOR    "tuty, Raska"
#define PLUGIN_VERSION    "1.2"

#pragma semicolon 1

new Handle:gBombEvents = INVALID_HANDLE;
new Handle:gBombPlanted = INVALID_HANDLE;
new Handle:gBombDefused = INVALID_HANDLE;
new Handle:gBombPlanting = INVALID_HANDLE;
new Handle:gBombExploded = INVALID_HANDLE;
new Handle:gBombAbort = INVALID_HANDLE;
new Handle:gBombPickUp = INVALID_HANDLE;
new Handle:gBombDropped = INVALID_HANDLE;
new Handle:gBombDefusing = INVALID_HANDLE;
new Handle:gBombAbortDef = INVALID_HANDLE;
new Handle:gPrintType = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Bomb Events",
	author = PLUGIN_AUTHOR,
	description = "Bomb events. Show when a player planted ... defused the bomb.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	gBombEvents = CreateConVar("be_enabled", "1");
	CreateConVar("bombevents_version", PLUGIN_VERSION, "Bomb Events", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	if (GetConVarInt(gBombEvents) != 0) {
		HookEvent("bomb_beginplant", Event_BeginPlant);
		HookEvent("bomb_abortplant", Event_BombAbort);
		HookEvent("bomb_planted", Event_BombPlanted);
		HookEvent("bomb_defused", Event_BombDefused);
		HookEvent("bomb_exploded", Event_BombExploded);
		HookEvent("bomb_dropped", Event_BombDropped);
		HookEvent("bomb_pickup", Event_BombPickup);
		HookEvent("bomb_begindefuse", Event_BombBeginDefuse);
		HookEvent("bomb_abortdefuse", Event_BombAbortDefuse);

		gBombPlanted = CreateConVar("be_planted", "0");
		gBombDefused = CreateConVar("be_defused", "0");
		gBombPlanting = CreateConVar("be_planting", "0");
		gBombExploded = CreateConVar("be_exploded", "0");
		gBombAbort = CreateConVar("be_abort", "1");
		gBombPickUp = CreateConVar("be_pickup", "1");
		gBombDropped = CreateConVar("be_dropped", "1");
		gBombDefusing = CreateConVar("be_defusing", "0");
		gBombAbortDef = CreateConVar("be_abortdefuse", "1");
		gPrintType = CreateConVar("be_printtype", "2"); // 1 hint, 2 chat, 3 center
	}
}

public Action:Event_BeginPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombPlanting) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{highlight}Warning{default}! {player}%N{default} is planting the BOMB!!", id);
		}
	}
}

public Action:Event_BombAbort(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombAbort) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{player}%N{default} a oprit amorsarea bombei!", id);
		}
	}
}

public Action:Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombPlanted) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{player}%N{default} has planted the BOMB!", id);
			EmitSoundToAll("misc/c4powa.wav");
		}
	}
}

public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombDefused) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{player}%N{default} defused the BOMB!", id);
			EmitSoundToAll("misc/laugh.wav");
		}
	}
}

public Action:Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombExploded) == 1) {
		PrintMessage("{highlight}BOMB successfully exploded");
		EmitSoundToAll("misc/witch.wav");
	}
}

public Action:Event_BombDropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombDropped) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{player}%N{default} a scapat bomba!", id);
		}
	}
}

public Action:Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombPickUp) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{player}%N{default} a ridicat bomba.", id);
		}
	}
}

public Action:Event_BombBeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombDefusing) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{highlight}OMG! {player}%N{default} is defusing the BOMB!!!!", id);
		}
	}
}

public Action:Event_BombAbortDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombAbortDef) == 1) {
		new id = GetClientOfUserId(GetEventInt(event, "userid"));

		if (id != 0) {
			PrintMessage("{player}%N{default} a oprit dezamorsarea bombei!", id);
		}
	}
}

PrintMessage(const String:format[], any:...)
{
	new String:msg[512];
	VFormat(msg, sizeof(msg), format, 2);

	switch(GetConVarInt(gPrintType))
	{
		case 1:    {CRemoveColors(msg, sizeof(msg)); PrintHintTextToAll(msg);}
		// case 2:    CPrintToChatAll(msg);
		case 2:    CPrintToChatTeam(CS_TEAM_T, msg);
		case 3:    {CRemoveColors(msg, sizeof(msg)); PrintCenterTextAll(msg);}
	}
}