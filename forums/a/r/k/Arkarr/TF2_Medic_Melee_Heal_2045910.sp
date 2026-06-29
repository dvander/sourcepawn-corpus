#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2itemsinfo>

public Plugin:myinfo =
{
	name = "Medic Melee Heal",
	author = "Arkarr",
	description = "Meic can heal teammate by hitting them with there bonesaw.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

new maxhealth[MAXPLAYERS+1];

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	HookEvent("player_spawn", PlayerSpawn);
}

public OnPluginStart(){
	HookEvent("player_spawn", PlayerSpawn);
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	maxhealth[client] = GetClientHealth(client);
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup) {
	
	if(IsPlayerAlive(attacker) && IsClientConnected(attacker))
	{
		if(IsPlayerAlive(victim) && IsClientConnected(victim))
		{
			if(GetClientTeam(attacker) == GetClientTeam(victim))
			{
				if(TF2_GetPlayerClass(attacker) == TFClass_Medic)
				{
					
					new hClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
					new weaponindex = GetEntProp(hClientWeapon, Prop_Send, "m_iItemDefinitionIndex");
					decl String:classname[300];
					
					TF2II_GetItemClass(weaponindex, classname, sizeof(classname));
					
					if(StrEqual(classname, "tf_weapon_bonesaw", false))
					{
						SetEntityHealth(victim, maxhealth[victim]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
	