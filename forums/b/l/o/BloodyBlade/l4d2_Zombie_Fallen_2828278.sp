#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.1" 

#define MELEE_FIREAXE "fireaxe"
#define MELEE_FRYING_PAN "frying_pan"
#define MELEE_MACHETE "machete"
#define MELEE_BASEBALL_BAT "baseball_bat"
#define MELEE_CROWBAR "crowbar"
#define MELEE_CRICKET_BAT "cricket_bat"
#define MELEE_TONFA "tonfa"
#define MELEE_KATANA "katana"
#define MELEE_GUITAR "electric_guitar"
#define MELEE_KNIFE "knife"

enum
{
    DropItemsOn,
    Dropkit, 
    DropPills, 
    DropFire, 
    DropM60, 
    DropPipe_Bomb, 
    DropDefibrillator, 
    DropAdrenaline, 
    DropMolotov, 
    DropAutoshotgun, 
    DropHunting_rifle, 
    DropPistol_magnum, 
    DropPumpshotgun, 
    DropRifle, 
    DropAK47, 
    DropRifle_desert, 
    DropShotgun_chrome, 
    DropShotgun_spas, 
    DropSmg, 
    DropSmg_silenced, 
    DropSniper_military, 
    DropGrenade_launcher, 
    DropRifle_sg552, 
    DropSmg_mp5,
    DropSniper_awp, 
    DropSniper_scout,
    DropUpgradepack_explosive, 
    DropUpgradepack_incendiary, 
    DropCricket_bat, 
    DropCrowbar, 
    DropElectric_guitar, 
    DropFireaxe, 
    DropFrying_pan, 
    DropKatana, DropMachete, 
    DropChainsaw,
    DropChances
};

ConVar DropChance[DropChances];
int iDropChance[DropChances] = 0;
bool bHooked = false;

public Plugin myinfo =
{
    name = "Zombie Fallen",
    author = "Chi_Nai(Rewritten by BloodyBlade)",
    description = "Zombies can also drop items",
    version = PLUGIN_VERSION,
    url = "N/A"
}

public void OnPluginStart()
{
	CreateConVar("zombie_fallen_version", PLUGIN_VERSION, "Zombie Fallen plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	DropChance[DropItemsOn] = CreateConVar("drop_item_plugin_on", "1", "Plugin On/Off", CVAR_FLAGS);
	DropChance[Dropkit] = CreateConVar("Drop_kit", "3", "Zombie Drop First_Aid_Kit Probability(0~100)", CVAR_FLAGS);
	DropChance[DropPills] = CreateConVar("Drop_Pills", "3", "Zombie Drop Pain_Pills Probability(0~100)", CVAR_FLAGS);
	DropChance[DropFire] = CreateConVar("Drop_Fire", "3", "Zombie Drop Fire Probability(0~100)", CVAR_FLAGS);
	DropChance[DropPipe_Bomb] = CreateConVar("Drop_Pipe_Bomb", "3", "Zombie Drop Pipe_Bomb Probability(0~100)", CVAR_FLAGS);
	DropChance[DropDefibrillator] = CreateConVar("Drop_Defibrillator", "3", "Zombie Drop Defibrillator Probability(0~100)", CVAR_FLAGS);
	DropChance[DropAdrenaline] = CreateConVar("Drop_Adrenaline", "3", "Zombie Drop Adrenaline Probability(0~100)", CVAR_FLAGS);
	DropChance[DropMolotov] = CreateConVar("Drop_Molotov", "3", "Zombie Drop Molotov Probability(0~100)", CVAR_FLAGS);
	DropChance[DropM60] = CreateConVar("Drop_M60", "2", "Zombie Drop M60 Probability(0~100)", CVAR_FLAGS);

	DropChance[DropAutoshotgun] = CreateConVar("Drop_Autoshotgun", "3", "Zombie Drop Autoshotgun Probability(0~100)", CVAR_FLAGS);
	DropChance[DropHunting_rifle] = CreateConVar("Drop_Hunting_Rifle", "3", "Zombie Drop Hunting_rifle Probability(0~100)", CVAR_FLAGS);
	DropChance[DropPistol_magnum] = CreateConVar("DropPistol_Magnum", "3", "Zombie Drop Pistol_magnum Probability(0~100)", CVAR_FLAGS);
	DropChance[DropPumpshotgun] = CreateConVar("Drop_Pumpshotgun", "0", "Zombie Drop Pumpshotgun Probability(0~100)", CVAR_FLAGS);
	DropChance[DropRifle] = CreateConVar("Drop_Rifle", "3", "Zombie Drop Rifle Probability(0~100)", CVAR_FLAGS);
	DropChance[DropAK47] = CreateConVar("Drop_AK47", "2", "Zombie Drop AK47 Probability(0~100)", CVAR_FLAGS);
	DropChance[DropRifle_desert] = CreateConVar("Drop_Rifle_Desert", "0", "Zombie Drop Rifle_desert Probability(0~100)", CVAR_FLAGS);
	DropChance[DropShotgun_chrome] = CreateConVar("Drop_Shotgun_Chrome", "0", "Zombie Drop Shotgun_chrome Probability(0~100)", CVAR_FLAGS);
	DropChance[DropShotgun_spas] = CreateConVar("Drop_Shotgun_Spas", "2", "Zombie Drop Shotgun_spas Probability(0~100)", CVAR_FLAGS);
	DropChance[DropSmg] = CreateConVar("Drop_Smg", "0", "Zombie Drop Smg Probability(0~100)", CVAR_FLAGS);
	DropChance[DropSmg_silenced] = CreateConVar("Drop_Smg_Silenced", "0", "Zombie Drop Smg_silenced Probability(0~100)", CVAR_FLAGS);
	DropChance[DropSniper_military] = CreateConVar("Drop_Sniper_Military", "3", "Zombie Drop Sniper_military Probability(0~100)", CVAR_FLAGS);
	DropChance[DropGrenade_launcher] = CreateConVar("Drop_Grenade_Launcher", "2", "Zombie Drop Grenade_launcher Probability(0~100)", CVAR_FLAGS);
	DropChance[DropRifle_sg552] = CreateConVar("Drop_Rifle_Sg552", "2", "Zombie Drop Rifle_sg552 Probability(0~100)", CVAR_FLAGS);
	DropChance[DropSmg_mp5] = CreateConVar("Drop_Smg_Mp5", "2", "Zombie Drop Smg_mp5 Probability(0~100)", CVAR_FLAGS);
	DropChance[DropSniper_awp] = CreateConVar("Drop_Sniper_Awp", "2", "Zombie Drop Sniper_awp Probability(0~100)", CVAR_FLAGS);
	DropChance[DropSniper_scout] = CreateConVar("Drop_Sniper_Scout", "2", "Zombie Drop Sniper_scout Probability(0~100)", CVAR_FLAGS);
	DropChance[DropUpgradepack_explosive] = CreateConVar("Drop_Upgradepack_Explosive", "3", "Zombie Drop Upgradepack_explosive Probability(0~100)", CVAR_FLAGS);
	DropChance[DropUpgradepack_incendiary] = CreateConVar("Drop_Upgradepack_Incendiary", "3", "Zombie Drop Upgradepack_incendiary Probability(0~100)", CVAR_FLAGS);

	DropChance[DropCricket_bat] = CreateConVar("DropCricket_Bat", "2", "Zombie Drop Cricket_bat Probability(0~100)", CVAR_FLAGS);
	DropChance[DropCrowbar] = CreateConVar("Drop_Crowbar", "2", "Zombie Drop Crowbar Probability(0~100)", CVAR_FLAGS);
	DropChance[DropElectric_guitar] = CreateConVar("DropElectric_Guitar", "2", "Zombie Drop Electric_guitar Probability(0~100)", CVAR_FLAGS);
	DropChance[DropFireaxe] = CreateConVar("Drop_Fireaxe", "2", "Zombie Drop Fireaxe Probability(0~100)", CVAR_FLAGS);
	DropChance[DropFrying_pan] = CreateConVar("Drop_Frying_Pan", "2", "Zombie Drop Frying_pan Probability(0~100)", CVAR_FLAGS);
	DropChance[DropKatana] = CreateConVar("Drop_Katana", "2", "Zombie Drop Katana Probability(0~100)", CVAR_FLAGS);
	DropChance[DropMachete] = CreateConVar("Drop_Machete", "2", "Zombie Drop Machete Probability(0~100)", CVAR_FLAGS);
	DropChance[DropChainsaw] = CreateConVar("Drop_Chainsaw", "2", "Zombie Drop Chainsaw Probability(0~100)", CVAR_FLAGS);

	DropChance[DropItemsOn].AddChangeHook(OnConVarPluginOnChange);
	for (int i = 1; i < DropChances; i++)
	{
		DropChance[i].AddChangeHook(OnConVarChanceChange);
	}

	AutoExecConfig(true, "l4d2_Zombie_Fallen");
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (StringToInt(newVal) != StringToInt(oldVal))
	{
	    IsAllowed();
	}
}

void OnConVarChanceChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (StringToInt(newVal) != StringToInt(oldVal))
	{
		for (int i = 0; i < DropChances; i++)
		{
			if (DropChance[i] == cvar)
			{
				iDropChance[i] = cvar.IntValue;
			}
		}
	}
}

void IsAllowed()
{
    bool bPluginOn = DropChance[DropItemsOn].BoolValue;
    if(bPluginOn && !bHooked)
    {
        bHooked = true;
        GetCvars();
        HookEvent("player_death", Event_PlayerDeath);
    }
    else if(!bPluginOn && bHooked)
    {
        bHooked = false;
        UnhookEvent("player_death", Event_PlayerDeath);
    }
}

void GetCvars()
{
	for (int i = 0; i < DropChances; i++)
	{
		iDropChance[i] = DropChance[i].IntValue;
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("entityid");
	if(entity)
	{
    	float pos[3];
    	pos[0] = event.GetFloat("victim_x");
    	pos[1] = event.GetFloat("victim_y");
    	pos[2] = event.GetFloat("victim_z");

        int Chance = GetRandomInt(1, 100);
        char Weapon[64];
        switch(GetRandomInt(0, 34))
        {
        	case 0:
        	{
        		if(Chance <= iDropChance[Dropkit])
                {
                    Weapon = "weapon_first_aid_kit";
                    SpawnWeaponAndAmmo(Weapon, pos, false);
                }
            }
        	case 1:
        	{
        		if(Chance <= iDropChance[DropPills])
        		{
        			Weapon = "weapon_pain_pills";
        			SpawnWeaponAndAmmo(Weapon, pos, false);
        		}
            }
        	case 2:
        	{
            	if(Chance <= iDropChance[DropM60])
                {
                    Weapon = "weapon_rifle_m60";
                    SpawnWeaponAndAmmo(Weapon, pos, false);
                }
            }
        	case 3:
        	{
            	if(Chance <= iDropChance[DropPipe_Bomb])
                {
                    Weapon = "weapon_pipe_bomb";
                    SpawnWeaponAndAmmo(Weapon, pos, false);
                }
            }
        	case 4:
        	{
        		if(Chance <= iDropChance[DropAdrenaline])
        		{
        			Weapon = "weapon_adrenaline";
        			SpawnWeaponAndAmmo(Weapon, pos, false);
        		}
        	}
        	case 5:
        	{
        		if(Chance <= iDropChance[DropDefibrillator])
        		{
        			Weapon = "weapon_defibrillator";
        			SpawnWeaponAndAmmo(Weapon, pos, false);
        		}
        	}
        	case 6:
        	{
        		if(Chance <= iDropChance[DropMolotov])
        		{
        			Weapon = "weapon_molotov";
        			SpawnWeaponAndAmmo(Weapon, pos, false);
        		}
        	}
        	case 7:
        	{
        		if(Chance <= iDropChance[DropAutoshotgun])
        		{
        			Weapon = "weapon_autoshotgun";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 8:
        	{
        		if(Chance <= iDropChance[DropHunting_rifle]) 
        		{
        			Weapon = "weapon_hunting_rifle";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 9:
        	{
        		if(Chance <= iDropChance[DropPistol_magnum])
        		{
        			Weapon = "weapon_pistol_magnum";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 10:
        	{
        		if(Chance <= iDropChance[DropPumpshotgun])
        		{
        			Weapon = "weapon_pumpshotgun";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 11:
        	{
        		if(Chance <= iDropChance[DropRifle])
        		{
        			Weapon = "weapon_rifle";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 12:
        	{
        		if(Chance <= iDropChance[DropAK47])
        		{
        			Weapon = "weapon_rifle_ak47";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 13:
        	{
        		if(Chance <= iDropChance[DropRifle_desert]) 
        		{
        			Weapon = "weapon_rifle_desert";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 14:
        	{
        		if(Chance <= iDropChance[DropShotgun_chrome])
        		{
        			Weapon = "weapon_shotgun_chrome";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 15:
        	{
        		if(Chance <= iDropChance[DropShotgun_spas])
        		{
        			Weapon = "weapon_shotgun_spas";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 16:
        	{
        		if(Chance <= iDropChance[DropSmg])
        		{
        			Weapon = "weapon_smg";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 17:
        	{
        		if(Chance <= iDropChance[DropSmg_silenced])
        		{
        			Weapon = "weapon_smg_silenced";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 18:
        	{
        		if(Chance <= iDropChance[DropSniper_military])
        		{
        			Weapon = "weapon_sniper_military";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
        	}
        	case 19:
        	{
        		if(Chance <= iDropChance[DropGrenade_launcher])
        		{
        			Weapon = "weapon_grenade_launcher";
        			SpawnWeaponAndAmmo(Weapon, pos, true);
                }
            }
        	case 20:
        	{
            	if(Chance <= iDropChance[DropRifle_sg552])
        		{
                    Weapon = "weapon_rifle_sg552";
                    SpawnWeaponAndAmmo(Weapon, pos, true);
                }
            }
        	case 21:
        	{
            	if(Chance <= iDropChance[DropSmg_mp5])
                {
                    Weapon = "weapon_smg_mp5";
                    SpawnWeaponAndAmmo(Weapon, pos, true);
        		}
            }
        	case 22:
        	{
            	if(Chance <= iDropChance[DropSniper_awp])
                {
                    Weapon = "weapon_sniper_awp";
                    SpawnWeaponAndAmmo(Weapon, pos, true);
                }
            }
        	case 23:
        	{
            	if(Chance <= iDropChance[DropSniper_scout])
        		{
                    Weapon = "weapon_sniper_scout";
                    SpawnWeaponAndAmmo(Weapon, pos, true);
                }
            }
        	case 24:
        	{
            	if(Chance <= iDropChance[DropUpgradepack_explosive]) 
                {
                	Weapon = "weapon_upgradepack_explosive";
                	SpawnWeaponAndAmmo(Weapon, pos, false);
                }
            }
        	case 25:
        	{
        		if(Chance <= iDropChance[DropUpgradepack_incendiary])
                {
                    Weapon = "weapon_upgradepack_incendiary";
                    SpawnWeaponAndAmmo(Weapon, pos, false);
                }
            }
        	case 26:
        	{
            	if(Chance <= iDropChance[DropCricket_bat])
                {
                    SpawnMelee(pos, "cricket_bat");
                }
            }
        	case 27:
        	{
            	if(Chance <= iDropChance[DropCrowbar])
                {
                    SpawnMelee(pos, "crowbar");
                }
            }
        	case 28:
        	{
            	if(Chance <= iDropChance[DropElectric_guitar]) 
                {
                    SpawnMelee(pos, "electric_guitar");
                }
            }
        	case 29:
        	{
        		if(Chance <= iDropChance[DropFireaxe])
        		{
        			SpawnMelee(pos, "fireaxe");
        		}
            }
        	case 30:
        	{
            	if(Chance <= iDropChance[DropFrying_pan])
        		{
                    SpawnMelee(pos, "frying_pan");
                }
            }
        	case 31:
        	{
            	if(Chance <= iDropChance[DropKatana])
        		{
                    SpawnMelee(pos, "katana");
                }
            }
        	case 32:
        	{
            	if(Chance <= iDropChance[DropMachete])
                {
                    SpawnMelee(pos, "machete");
                }
            }
        	case 33:
        	{
            	if(Chance <= iDropChance[DropChainsaw])
                {
                    Weapon = "weapon_chainsaw";
                    SpawnWeaponAndAmmo(Weapon, pos, false);
                }
            }
        	case 34:
        	{
                if(Chance <= iDropChance[DropFire])
                {
                    entity = CreateEntityByName("prop_physics");
                    if (IsValidEntity(entity))
                    {
        				Weapon = "models/props_junk/gascan001a.mdl";
        				SpawnProp(Weapon, pos);
                    }
                }
            }
        }
    }
}

void SpawnWeaponAndAmmo(char cWeapon[64], float fPos[3], bool bNeedWeapon)
{
    int Wentity = CreateEntityByName(cWeapon);
    if (IsValidEntity(Wentity))
    {
        fPos[2] += 50.0;
        DispatchSpawn(Wentity);
        TeleportEntity(Wentity, fPos, NULL_VECTOR, NULL_VECTOR);
        if(bNeedWeapon)
        {
        	int Clip_Size = GetEntProp(Wentity, Prop_Send, "m_iClip1");
        	SetEntProp(Wentity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
    	}
    }
}

void SpawnMelee(float fPos[3], char model[64])
{
    int Mentity = CreateEntityByName("weapon_melee");
    if (IsValidEntity(Mentity))
	{
    	fPos[2] += 50.0;
    	DispatchKeyValue(Mentity, "melee_script_name", model);
    	DispatchSpawn(Mentity);
    	TeleportEntity(Mentity, fPos, NULL_VECTOR, NULL_VECTOR);
	}
}

void SpawnProp(char model[64], float fPos[3])
{
    int iEnt = CreateEntityByName("prop_physics");
    if (IsValidEntity(iEnt))
    {
    	fPos[2] += 10.0;
    	DispatchKeyValue(iEnt, "model", model);
    	DispatchSpawn(iEnt);
    	SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_CollisionGroup"), 1, 1, true);
    	TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);
    	AcceptEntityInput(iEnt, "break");
    }
}
