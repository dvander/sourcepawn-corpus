#include <sourcemod>
#include <sdktools>

#define WEAPON_MAG "weapon_357"

#pragma semicolon 1

new Handle:CV_GIVEWEP = INVALID_HANDLE;
 
public Plugin:myinfo =
{
	name = "Remove weapons/Mag only",
	author = "Oliveboy",
	description = "All weapons are removed on the map and you get a mag only",
	version = "Final",
	url = "nothing"
};
 
public OnPluginStart()
{
	HookEvent("player_spawn", EventSpawn);
	CV_GIVEWEP = CreateConVar("ob_magonly","1","Give magnum only and remove all weapons");
}

public OnMapStart()
{
	if(GetConVarInt(CV_GIVEWEP) == 1)
	{
		for(new i = MaxClients+1; i < GetMaxEntities(); i++)
		{	
			if(IsValidEntity(i) && IsValidEdict(i))
			{
				decl String:class[256];
				GetEdictClassname(i, class, sizeof(class));
				if((StrEqual(class, "weapon_frag")) || (StrEqual(class, "weapon_shotgun")) || (StrEqual(class, "weapon_crossbow")) || (StrEqual(class, "weapon_smg1")) || (StrEqual(class, "weapon_pistol")) || (StrEqual(class, "weapon_ar2")) || (StrEqual(class, "weapon_rpg")) || (StrEqual(class, "weapon_crowbar")) || (StrEqual(class, "weapon_stunstick")) || (StrEqual(class, "item_ammo_ar2")) || (StrEqual(class, "item_ammo_ar2_altfire")) || (StrEqual(class, "item_ammo_ar2_large")) || (StrEqual(class, "item_ammo_crate")) || (StrEqual(class, "item_ammo_crossbow")) || (StrEqual(class, "item_ammo_pistol")) || (StrEqual(class, "item_ammo_pistol_large")) || (StrEqual(class, "item_ammo_smg1")) || (StrEqual(class, "item_ammo_smg1_grenade")) || (StrEqual(class, "item_ammo_smg1_large")) || (StrEqual(class, "item_box_buckshot")) || (StrEqual(class, "item_item_crate")) || (StrEqual(class, "item_rpg_round")))
				{
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
} 

stock LoseWeapon(Client, bool:OnDeath = false)
{
	if(!IsClientInGame(Client)) return false;
	
	RemoveWeapons(Client);
	return true;	
}

public EventSpawn(Handle:event, const String:name[], bool:Broadcast)
{
	if(GetConVarInt(CV_GIVEWEP) == 1)
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsClientInGame(Client))
		{
			CreateTimer(0.5, GunTimer, Client);
		}
	}
}

public Action:GunTimer(Handle:Timer, any:Client)
{
	LoseWeapon(Client, false);
	GivePlayerItem(Client, WEAPON_MAG);	
	return Plugin_Handled;	
}

stock RemoveWeapons(Client)
{
	if(!IsClientInGame(Client)) return true;
	
	//Declare:
	decl Offset;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	new MaxGuns = 256;
	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt2(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
	return true;
}  