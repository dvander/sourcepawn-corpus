/*
* 0.7
*  - Added CVARs.
* 0.6
*  - Added drop on hunter pounce.
*  - Fixed crash bugs, thanks Frus!
* 0.5
*  - Survivors will now drop currently equipped item on drag/incap.
* 0.4
*  - Added funtionality for survivor incap.
* 0.3
*  - Added check so that weapon is not dropped if tongue is released before survivor is paralyzed.
* 0.2
*  - Disabled weapon dropping for bots since the AI doesn't know to pick them back up.
* 0.1
*  - Beta release.
*/

#include <sourcemod>
#include <sdktools>

new Handle:DropTimers[MAXPLAYERS+1];new Handle:g_DropSlot;
new Handle:sm_dad_drag;
new Handle:sm_dad_pounce;
new Handle:sm_dad_incap;
new Handle:sm_dad_incap_grenade;
new Handle:sm_dad_pistols;
new Handle:sm_dad_bots;

public Plugin:myinfo =
{
	name = "[L4D] Drag and Drop",
	author = "Crimson_Fox",
	description = "Survivors drop equipped item on smoker drag or incap.",
	version = "0.7",
	url = "http://forums.alliedmods.net/showthread.php?p=950571"
}

public OnPluginStart()
{
	HookEvent("tongue_grab", EventTongueGrab, EventHookMode_Post);
	HookEvent("tongue_release", EventTongueRelease, EventHookMode_Post);
	HookEvent("lunge_pounce", EventPlayerPounced, EventHookMode_Post);
	HookEvent("player_incapacitated", EventPlayerIncap, EventHookMode_Post);
	g_DropSlot = CreateGlobalForward("DropSlot", ET_Ignore, Param_Cell, Param_Cell);
	sm_dad_drag = CreateConVar("sm_dad_drag", "1", "Survivors drop equipped item on smoker drag.",FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_dad_pounce = CreateConVar("sm_dad_pounce", "0", "Survivors drop equipped item on hunter pounce.",FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_dad_incap = CreateConVar("sm_dad_incap", "1", "Survivors drop equipped item when they become incapacitated.",FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_dad_incap_grenade = CreateConVar("sm_dad_incap_grenade", "1", "Survivors drop their grenade when they become incapacitated.",FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_dad_pistols = CreateConVar("sm_dad_pistols", "0", "Will survivors drop second pistol?",FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_dad_bots = CreateConVar("sm_dad_bots", "0", "Will bots drop equipped item?",FCVAR_PLUGIN|FCVAR_SPONLY);
}

public EventTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_dad_drag))
	{
		new client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropTimers[client] = CreateTimer(1.0, DropItemDelay, client);
	}
}

public EventTongueRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (DropTimers[client] != INVALID_HANDLE)
	{
		KillTimer(DropTimers[client])
		DropTimers[client] = INVALID_HANDLE
	}
}

public EventPlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_dad_pounce))
	{
		new client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public EventPlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_dad_incap))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		DropItem(client);
		if (GetConVarInt(sm_dad_incap_grenade)) DropGrenade(client);
	}
}

public Action:DropItemDelay(Handle:timer, any:client)
{
	if (!IsClientInGame(client)) return;
	DropItem(client);
	DropTimers[client] = INVALID_HANDLE
}

public DropItem(client)
{
	if ((IsFakeClient(client)) && (!GetConVarInt(sm_dad_bots))) return;
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	if ((StrEqual(weapon, "weapon_pistol")) && (!GetConVarInt(sm_dad_pistols))) return;
	FakeClientCommand(client, "sm_drop");
}

public DropGrenade(client)
{
	Call_StartForward(g_DropSlot);
	Call_PushCell(client);
	Call_PushCell(2);
	Call_Finish();
}
