#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[HL2MP] Remove weapons",
	author = "bacardi",
	description = "Remove weapons from map and/or from player when spawn",
	version = "0.1",
	url = "www.sourcemod.net"
}

new Handle:sm_hl2mp_remove_weapons = INVALID_HANDLE;
new String:remove_weapons[200];

new Handle:sm_hl2mp_remove_weapons_player = INVALID_HANDLE;
new String:remove_weapons_player[200];


public OnPluginStart()
{
	sm_hl2mp_remove_weapons = CreateConVar("sm_hl2mp_remove_weapons", "", "List weapons remove from map", FCVAR_NONE);
	GetConVarString(sm_hl2mp_remove_weapons, remove_weapons, sizeof(remove_weapons));
	HookConVarChange(sm_hl2mp_remove_weapons, ConVarChanged);

	sm_hl2mp_remove_weapons_player = CreateConVar("sm_hl2mp_remove_weapons_player", "", "List weapons remove from player when spawn", FCVAR_NONE);
	GetConVarString(sm_hl2mp_remove_weapons_player, remove_weapons_player, sizeof(remove_weapons_player));
	HookConVarChange(sm_hl2mp_remove_weapons_player, ConVarChanged);

/**
   'weapon_357' : '' (entindex 51)
   'weapon_crossbow' : '' (entindex 247)
   'weapon_frag' : '' (entindex 409)
   'weapon_rpg' : '' (entindex 468)
   'weapon_ar2' : '' (entindex 512)
   'weapon_crowbar' : '' (entindex 55)
   'weapon_pistol' : '' (entindex 88)
   'weapon_smg1' : '' (entindex 89)
   'weapon_physcannon' : '' (entindex 92)
   'weapon_stunstick' : '' (entindex 95)
   'weapon_shotgun' : '' (entindex 98)
   'weapon_slam' : '' (entindex 101)

sm_hl2mp_remove_weapons weapon_357 weapon_crossbow weapon_frag weapon_rpg weapon_ar2 weapon_crowbar weapon_pistol weapon_smg1 weapon_physcannon weapon_stunstick weapon_shotgun weapon_slam
sm_hl2mp_remove_weapons_player weapon_crowbar weapon_pistol weapon_smg1 weapon_stunstick weapon_frag

*/
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == sm_hl2mp_remove_weapons)
	{
		GetConVarString(sm_hl2mp_remove_weapons, remove_weapons, sizeof(remove_weapons));
	}

	if(convar == sm_hl2mp_remove_weapons_player)
	{
		GetConVarString(sm_hl2mp_remove_weapons_player, remove_weapons_player, sizeof(remove_weapons_player));
	}
}


public OnMapStart()
{
	if(remove_weapons[0] != '\0')
	{
		new count, String:expl[14][18];

		count = ExplodeString(remove_weapons, " ", expl, 14, 20);
		new weapon;

		for(new i = 0; i < count; i++)
		{
			weapon = -1;
			while((weapon = FindEntityByClassname(weapon, expl[i])) != -1)
			{
				AcceptEntityInput(weapon, "Kill");
			}
		}
	}
}


public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(remove_weapons_player[0] != '\0')
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.3, TimerRemoveWeapons, client);
	}
}

public Action:TimerRemoveWeapons(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new owner = -1;
		if((owner = GetPlayerWeaponSlot(client, 0)) != 1)
		{
			owner = GetEntProp(owner, Prop_Send, "m_hOwnerEntity"); // I want know player owner ID
		}
	
		if(owner != -1)
		{
			new count, String:expl[14][18];
		
			count = ExplodeString(remove_weapons_player, " ", expl, 14, 20);
			new weapon, ent;
		
			for(new i = 0; i < count; i++)
			{
				weapon = -1;
				while((weapon = FindEntityByClassname(weapon, expl[i])) != -1)
				{
					ent = GetEntProp(weapon, Prop_Send, "m_hOwnerEntity");
					if(owner == ent)
					{
						AcceptEntityInput(weapon, "Kill");
					}
				}
			}
		}
	}
}