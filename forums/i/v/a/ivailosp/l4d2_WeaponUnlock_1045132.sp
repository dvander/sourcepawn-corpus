#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2.2"
#define SMG 2
#define RIFLE 5
#define HUNTING_RIFLE 6
#define SMG_SILENCED 7
#define RIFLE_DESERT 9
#define SNIPER_MILITARY 10
#define RIFLE_AK47 26
#define SMG_MP5 33
#define RIFLE_SG552 34
#define SNIPER_AWP 35
#define SNIPER_SCOUT 36

new g_buff_2[100]
new g_rand_counts_2 = 0
new g_ran_curr_poss_2 = 0
new g_buff_3[100]
new g_rand_counts_3 = 0
new g_ran_curr_poss_3 = 0
new g_buff_4[100]
new g_rand_counts_4 = 0
new g_ran_curr_poss_4 = 0

new i_wmodel_awp
new i_wmodel_scout
new i_wmodel_mp5
new i_wmodel_sg552

public Plugin:myinfo = 
{
	name = "[L4D2] Weapon Unlock",
	author = "Crimson_Fox",
	description = "Unlocks the hidden CSS weapons.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1041458"
}

public OnPluginStart()
{
	//Look up what game we're running,
	decl String:game[64]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
	CreateConVar("l4d2_WeaponUnlock", PLUGIN_VERSION, "Weapon Unlock version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	//Precache hidden weapon models,
	PrecacheHiddenWeaponModels()
	//and initialize them after a slight delay.
	CreateTimer(0.1, InitHiddenWeaponsDelay)
	HookEvent("round_start", Event_RoundStart)
}
public OnMapStart()
{
	g_ran_curr_poss_2 = 0
	g_ran_curr_poss_3 = 0
	g_ran_curr_poss_4 = 0
	g_rand_counts_2 = 0
	g_rand_counts_3 = 0
	g_rand_counts_4 = 0
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrecacheHiddenWeaponModels();
	g_ran_curr_poss_2 = 0
	g_ran_curr_poss_3 = 0
	g_ran_curr_poss_4 = 0
	CreateTimer(0.5, RoundWeaponCheck);
}

public Action:RoundWeaponCheck(Handle:timer)
{
	if(GetTeamClientCount(2) > 0){
		AddWeapons();
	}else{
		CreateTimer(0.5, RoundWeaponCheck);
	}
}
public AddWeapons()
{
	//Search through the entities,
	new String:EdictClassName[128]
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			//and look for dynamic weapon spawns.
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "weapon_spawn", false) != -1)
			{
				//If you find one then look up the weapon ID,
				new WeaponID = GetEntProp(i, Prop_Send, "m_weaponID")
				//and modify it as such:
				switch(WeaponID)
				{
					case RIFLE_AK47: AddWeapon(i, RIFLE_SG552, 4);
					case SNIPER_MILITARY: AddWeapon(i, SNIPER_AWP, 2);
					case RIFLE_DESERT: AddWeapon(i, RIFLE_SG552, 4);
					case SMG_SILENCED: AddWeapon(i, SMG_MP5, 3);
					case HUNTING_RIFLE: AddWeapon(i, SNIPER_SCOUT, 2);
					case RIFLE: AddWeapon(i, RIFLE_SG552, 4);
					case SMG: AddWeapon(i, SMG_MP5, 3);
				}
			}
		}
	}
}
public Action:InitHiddenWeaponsDelay(Handle:timer, any:client)
{
	//Spawn the hidden weapons,
	DispatchSpawn(CreateEntityByName("weapon_rifle_sg552"))
	DispatchSpawn(CreateEntityByName("weapon_smg_mp5"))
	DispatchSpawn(CreateEntityByName("weapon_sniper_awp"))
	DispatchSpawn(CreateEntityByName("weapon_sniper_scout"))
	//and reload the current map.
	new String:map[64]
	GetCurrentMap(map, sizeof(map))
	ForceChangeLevel(map, "Hidden weapon initialization.")
}

public PrecacheHiddenWeaponModels()
{
	i_wmodel_sg552 = PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl")
	i_wmodel_mp5 = PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl")
	i_wmodel_awp = PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl")
	i_wmodel_scout = PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl")
	PrecacheModel("models/v_models/v_rif_sg552.mdl")
	PrecacheModel("models/v_models/v_smg_mp5.mdl")
	PrecacheModel("models/v_models/v_snip_awp.mdl")
	PrecacheModel("models/v_models/v_snip_scout.mdl")
}


public RandNotRand(odds)
{
	switch(odds)
	{
	case 2:
		{
			g_ran_curr_poss_2++
			if(g_ran_curr_poss_2 > g_rand_counts_2){
				g_buff_2[g_ran_curr_poss_2-1%100] = GetRandomInt(1, odds)
				g_rand_counts_2++
			}
			return g_buff_2[g_ran_curr_poss_2-1%100]
		}
	case 3:
		{
			g_ran_curr_poss_3++
			if(g_ran_curr_poss_3 > g_rand_counts_3){
				g_buff_3[g_ran_curr_poss_3-1%100] = GetRandomInt(1, odds)
				g_rand_counts_3++
			}
			return g_buff_3[g_ran_curr_poss_3-1%100]
		}
	case 4:
		{
			g_ran_curr_poss_4++
			if(g_ran_curr_poss_4 > g_rand_counts_4){
				g_buff_4[g_ran_curr_poss_4-1%100] = GetRandomInt(1, odds)
				g_rand_counts_4++
			}
			return g_buff_2[g_ran_curr_poss_4-1%100]
		}
	}
	return 0
}

public AddWeapon(target, weaponID, odds)
{
	//Roll the dice to see if we replace this weapon.
	if (RandNotRand(odds) == 1)
	{
		//Is so, change the spawn's weaponID,
		SetEntProp(target, Prop_Send, "m_weaponID", weaponID)
		//and w_model.
		switch(weaponID)
		{
			case SNIPER_SCOUT: SetEntProp(target, Prop_Send, "m_nModelIndex", i_wmodel_scout);
			case SNIPER_AWP: SetEntProp(target, Prop_Send, "m_nModelIndex", i_wmodel_awp);
			case RIFLE_SG552: SetEntProp(target, Prop_Send, "m_nModelIndex", i_wmodel_sg552);
			case SMG_MP5: SetEntProp(target, Prop_Send, "m_nModelIndex", i_wmodel_mp5);
		}
	}
}
