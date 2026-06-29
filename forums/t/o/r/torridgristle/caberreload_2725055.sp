#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define STICKBOMB_CLASS "CTFStickBomb"

new Handle:v_CaberTimer = INVALID_HANDLE;
new Handle:zeTimers[MAXPLAYERS+1];

public Plugin:myinfo = {
	name            = "[TF2] Ullapool Caber Recharge",
	author          = "DarthNinja, hotgrits",
	description     = "Reset Caber after some time.",
	version         = "1.1",
	url             = ""
};

public OnPluginStart()
{
	v_CaberTimer = CreateConVar("caber_timer", "5.0", "How many seconds to wait before resetting cabers");

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_DoKillTimer);
	HookEvent("player_changeclass", Event_DoKillTimer);
	HookEvent("post_inventory_application", Event_DoKillTimer);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim == 0 || attacker != victim || !IsClientInGame(victim)
		|| GetEventInt(event, "custom") != TF_CUSTOM_STICKBOMB_EXPLOSION)
	{
		return;
	}

	zeTimers[victim] = CreateTimer(GetConVarFloat(v_CaberTimer), Timer_RefreshStickBomb, GetClientUserId(victim));
}

public Event_DoKillTimer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillStickBombTimer(client);
}

public OnClientDisconnect(client)
{
	KillStickBombTimer(client);
}

KillStickBombTimer(client)
{
	new Handle:timer = zeTimers[client];
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		zeTimers[client] = INVALID_HANDLE;
	}
}

public Action:Timer_RefreshStickBomb(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	
	RefreshStickBomb(client);
	zeTimers[client] = INVALID_HANDLE;
}

RefreshStickBomb(client, bool:doWeaponCheck=true)
{
	new stickbomb = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (stickbomb <= MaxClients || !IsValidEdict(stickbomb))
	{
		return;
	}
	
	if (doWeaponCheck)
	{
		decl String:netclass[64];
		GetEntityNetClass(stickbomb, netclass, sizeof(netclass));
		if (!!strcmp(netclass, STICKBOMB_CLASS))
		{
			return;
		}
	}

	SetEntProp(stickbomb, Prop_Send, "m_bBroken", 0);
	SetEntProp(stickbomb, Prop_Send, "m_iDetonated", 0);
}