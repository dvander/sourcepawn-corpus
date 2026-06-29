#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

new bool:revolver;

public Plugin:myinfo =
{
	name = "SM Revolver Round",
	author = "Franc1sco Steam: franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

new Handle:timers[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("round_prestart", Restart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	RegAdminCmd("sm_revolver", Rondas, ADMFLAG_GENERIC);
	
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
}

public Action:Restart(Handle:event, const String:name[], bool:dontBroadcast)
{
	revolver = false;
	SetBuyZones("Enable");
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(revolver)
	{
		new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		decl String:classname[64];
		
		if(index == 64 || (GetEdictClassname(weapon, classname, 64) && (StrContains(classname, "weapon_knife") != -1 || StrContains(classname, "weapon_bayonet") != -1))) return Plugin_Continue;
		else return Plugin_Handled;
		
	}
	return Plugin_Continue;
}

public Action:Rondas(client, args)
{
	SetBuyZones("Disable");
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			CS_RespawnPlayer(i);
		}
		
	revolver = true;
	return Plugin_Handled;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(revolver) DoRound(client);
}

public Action:CS_OnCSWeaponDrop(client, weaponindex)
{
	if(revolver) return Plugin_Handled;
	
	return Plugin_Continue;
}

SetBuyZones(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_buyzone"))
				AcceptEntityInput(i, status);
		}
	}
}

DoRound(client)
{
	if(timers[client] != INVALID_HANDLE) KillTimer(timers[client]);
	
	timers[client] = CreateTimer(3.0, Darm, client, TIMER_REPEAT);
	
	StripAllWeapons(client);
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_revolver");
}

stock StripAllWeapons(iClient)
{
    new iEnt;
    for (new i = 0; i <= 4; i++)
    {
		while ((iEnt = GetPlayerWeaponSlot(iClient, i)) != -1)
		{
            RemovePlayerItem(iClient, iEnt);
            AcceptEntityInput(iEnt, "Kill");
		}
    }
}  

public OnClientPostAdminCheck(client)
{
	timers[client] = CreateTimer(3.0, Darm, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	if(timers[client] != INVALID_HANDLE)
	{
		KillTimer(timers[client]);
		timers[client] = INVALID_HANDLE;
	}
}

public Action:Darm(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(weapon > 0 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 64)
		{
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 8);
		}
	}
}
