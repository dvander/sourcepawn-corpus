#include <sdktools>
#include <sdkhooks>
#include <sourcemod>
#include <cstrike>

ConVar g_WeaponsCleanup;
ConVar g_WeaponsStayTime;
ConVar g_WeaponsStayTime2;
ConVar g_WeaponsStart;
ConVar g_WeaponsPrim;
ConVar g_WeaponsSec;
ConVar g_WeaponsMel;

char WeaponPrimary[64];
char WeaponSecondary[64];
char WeaponMelee[64];

Handle WeaponTimers[123123];
int i_WeaponTimer[123123];

public Plugin myinfo = 
{
	name = "CTF: Weapons",
	author = "extwc",
	description = "Weapons on spawn, Weapons cleanup",
	version = "1.0",
	url = "https://discord.com/invite/yMZC878uSj"
};

public void OnPluginStart()
{
	g_WeaponsCleanup = CreateConVar("ctf_weapons_cleanup", "1");
	g_WeaponsStayTime = CreateConVar("ctf_weapons_staytime", "5");
	g_WeaponsStayTime2 = CreateConVar("ctf_weapons_staytime_worldspawn", "3");
	g_WeaponsStart = CreateConVar("ctf_weapons_start", "1");
	g_WeaponsPrim = CreateConVar("ctf_weapons_start_primary", "weapon_ak47");
	g_WeaponsSec = CreateConVar("ctf_weapons_start_secondary", "weapon_deagle");
	g_WeaponsMel = CreateConVar("ctf_weapons_start_melee", "weapon_knife");
}

public void OnClientPutInServer(int client)
{
	Weapons_OnClientJoin(client);
}

Weapons_OnClientJoin(client)
{
	HookEvent("player_spawn", 	CTF_PlayerSpawn);
	
	SDKHook(client, SDKHook_WeaponDrop, Weapons_Drophook );  
	SDKHook(client, SDKHook_WeaponEquip, Weapons_Equiphook );
}

public Action CTF_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client))
	{
		Weapons_OnPlayerSpawn(client);
	}
}

public Action Weapons_Cleanup(Handle tmr)
{
	if(GetConVarInt(g_WeaponsCleanup) > 0)
	{
		new maxent = GetMaxEntities(), String:weapon[64];
		for (new i=GetMaxClients();i<maxent;i++)
		{
			if ( IsValidEdict(i) && IsValidEntity(i) )
			{
				GetEdictClassname(i, weapon, sizeof(weapon));
				new Owner = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity"); 
				
				if((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ))
				{
					if(Owner == -1)
					{
						if(WeaponTimers[i] == null)
						{
							// Time to kill weapons spawned by map
							i_WeaponTimer[i] = GetConVarInt(g_WeaponsStayTime2);
							WeaponTimers[i] = CreateTimer(1.0, Weapon_TimerToKill, i, TIMER_REPEAT);	
						}
					}
				}
			}
		}	
	}
}

public Weapons_OnPlayerSpawn(client)
{
	if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
	{
		if(IsPlayerAlive(client))
		{	
			if(GetConVarInt(g_WeaponsStart) > 0)
			{
				GetConVarString(g_WeaponsPrim, WeaponPrimary, sizeof(WeaponPrimary));
				GetConVarString(g_WeaponsSec, WeaponSecondary, sizeof(WeaponSecondary));
				GetConVarString(g_WeaponsMel, WeaponMelee, sizeof(WeaponMelee));
				
				int slot1 = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
				int slot2 = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
				int slot3 = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				
				if(slot1 > 0) 
				{
					RemovePlayerItem(client, slot1);
					RemoveEdict(slot1);
					GivePlayerItem(client, WeaponPrimary);
				}
				else
					GivePlayerItem(client, WeaponPrimary);
				
				
				if(slot2 > 0) 
				{
					RemovePlayerItem(client, slot2);
					RemoveEdict(slot2);
					GivePlayerItem(client, WeaponSecondary);
				}
				else
					GivePlayerItem(client, WeaponSecondary);
					
				if(slot3 > 0) 
				{
					RemovePlayerItem(client, slot3);
					RemoveEdict(slot3);
					GivePlayerItem(client, WeaponMelee);
				}
				else 
					GivePlayerItem(client, WeaponMelee);
			}
		}
	}
}

public Action:Weapons_Equiphook(client,weapon)
{
	if(GetConVarInt(g_WeaponsCleanup) > 0)
	{
		if(IsValidEntity(weapon))
		{
			KillWeaponTmr(weapon);
		}
	}
}

public Action:Weapons_Drophook(client,weapon)
{
	if(GetConVarInt(g_WeaponsCleanup) > 0)
	{
		if(IsValidEntity(weapon))
		{
			char classname[64]; 
			GetEdictClassname(weapon, classname, sizeof(classname));

			if(StrEqual(classname, "weapon_knife"))
				return;

			if(WeaponTimers[weapon] == null)
			{
				i_WeaponTimer[weapon] = GetConVarInt(g_WeaponsStayTime);
				WeaponTimers[weapon] = CreateTimer(1.0, Weapon_TimerToKill, weapon, TIMER_REPEAT);
			}
		}
	}
} 

public Action Weapon_TimerToKill(Handle tmr,weapon)
{
	if(i_WeaponTimer[weapon] <= 0)
	{
		Weapon_Kill(weapon);
	}
	else
		i_WeaponTimer[weapon]--;
	
}

public Action Weapon_Kill(weapon)
{
	if(IsValidEntity(weapon))
	{
		new Owner = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
		
		if(Owner == -1)
		{
			KillWeaponTmr(weapon);
			AcceptEntityInput(weapon, "Kill");
			RemoveEdict(weapon);
		}
	}
	else
		KillWeaponTmr(weapon);
}

void KillWeaponTmr(weapon)
{
	if (WeaponTimers[weapon] != null)
	{
		KillTimer(WeaponTimers[weapon]);
		WeaponTimers[weapon] = null;
	}
}

