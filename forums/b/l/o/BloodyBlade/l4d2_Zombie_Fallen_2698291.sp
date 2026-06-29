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

ConVar Dropkit;
ConVar DropPills;
ConVar DropFire;
ConVar DropM60;
ConVar DropPipe_Bomb;
ConVar DropDefibrillator;
ConVar DropAdrenaline;
ConVar DropMolotov;
ConVar DropAutoshotgun;
ConVar DropHunting_rifle;
ConVar DropPistol_magnum;
ConVar DropPumpshotgun;
ConVar DropRifle;
ConVar DropAK47;
ConVar DropRifle_desert;
ConVar DropShotgun_chrome;
ConVar DropShotgun_spas;
ConVar DropSmg;
ConVar DropSmg_silenced;
ConVar DropSniper_military;
ConVar DropGrenade_launcher;
ConVar DropRifle_sg552;
ConVar DropSmg_mp5;
ConVar DropSniper_awp;
ConVar DropSniper_scout;
ConVar DropUpgradepack_explosive;
ConVar DropUpgradepack_incendiary;
ConVar DropCricket_bat;
ConVar DropCrowbar;
ConVar DropElectric_guitar;
ConVar DropFireaxe;
ConVar DropFrying_pan;
ConVar DropKatana;
ConVar DropMachete;
ConVar DropChainsaw;

public Plugin myinfo =
{
    name = "l4d2_Zombie_Fallen",
    author = "Chi_Nai",
    description = "Zombies can also drop items",
    version = PLUGIN_VERSION,
    url = "N/A"
}

public void OnPluginStart()
{
	Dropkit = CreateConVar("Drop_kit", "3", "Zombie Drop First_Aid_Kit Probability(0~100)", CVAR_FLAGS);
	DropPills = CreateConVar("Drop_Pills", "3", "Zombie Drop Pain_Pills Probability(0~100)", CVAR_FLAGS);
	DropFire = CreateConVar("Drop_Fire", "3", "Zombie Drop Fire Probability(0~100)", CVAR_FLAGS);
	DropPipe_Bomb = CreateConVar("Drop_Pipe_Bomb", "3", "Zombie Drop Pipe_Bomb Probability(0~100)", CVAR_FLAGS);
	DropDefibrillator = CreateConVar("Drop_Defibrillator", "3", "Zombie Drop Defibrillator Probability(0~100)", CVAR_FLAGS);
	DropAdrenaline = CreateConVar("Drop_Adrenaline", "3", "Zombie Drop Adrenaline Probability(0~100)", CVAR_FLAGS);
	DropMolotov = CreateConVar("Drop_Molotov", "3", "Zombie Drop Molotov Probability(0~100)", CVAR_FLAGS);
	DropM60 = CreateConVar("Drop_M60", "2", "Zombie Drop M60 Probability(0~100)", CVAR_FLAGS);

	DropAutoshotgun = CreateConVar("Drop_Autoshotgun", "3", "Zombie Drop Autoshotgun Probability(0~100)", CVAR_FLAGS);
	DropHunting_rifle = CreateConVar("Drop_Hunting_Rifle", "3", "Zombie Drop Hunting_rifle Probability(0~100)", CVAR_FLAGS);
	DropPistol_magnum = CreateConVar("DropPistol_Magnum", "3", "Zombie Drop Pistol_magnum Probability(0~100)", CVAR_FLAGS);
	DropPumpshotgun = CreateConVar("Drop_Pumpshotgun", "0", "Zombie Drop Pumpshotgun Probability(0~100)", CVAR_FLAGS);
	DropRifle = CreateConVar("Drop_Rifle", "3", "Zombie Drop Rifle Probability(0~100)", CVAR_FLAGS);
	DropAK47 = CreateConVar("Drop_AK47", "2", "Zombie Drop AK47 Probability(0~100)", CVAR_FLAGS);
	DropRifle_desert = CreateConVar("Drop_Rifle_Desert", "0", "Zombie Drop Rifle_desert Probability(0~100)", CVAR_FLAGS);
	DropShotgun_chrome = CreateConVar("Drop_Shotgun_Chrome", "0", "Zombie Drop Shotgun_chrome Probability(0~100)", CVAR_FLAGS);
	DropShotgun_spas = CreateConVar("Drop_Shotgun_Spas", "2", "Zombie Drop Shotgun_spas Probability(0~100)", CVAR_FLAGS);
	DropSmg = CreateConVar("Drop_Smg", "0", "Zombie Drop Smg Probability(0~100)", CVAR_FLAGS);
	DropSmg_silenced = CreateConVar("Drop_Smg_Silenced", "0", "Zombie Drop Smg_silenced Probability(0~100)", CVAR_FLAGS);
	DropSniper_military = CreateConVar("Drop_Sniper_Military", "3", "Zombie Drop Sniper_military Probability(0~100)", CVAR_FLAGS);
	DropGrenade_launcher = CreateConVar("Drop_Grenade_Launcher", "2", "Zombie Drop Grenade_launcher Probability(0~100)", CVAR_FLAGS);
	DropRifle_sg552 = CreateConVar("Drop_Rifle_Sg552", "2", "Zombie Drop Rifle_sg552 Probability(0~100)", CVAR_FLAGS);
	DropSmg_mp5 = CreateConVar("Drop_Smg_Mp5", "2", "Zombie Drop Smg_mp5 Probability(0~100)", CVAR_FLAGS);
	DropSniper_awp = CreateConVar("Drop_Sniper_Awp", "2", "Zombie Drop Sniper_awp Probability(0~100)", CVAR_FLAGS);
	DropSniper_scout = CreateConVar("Drop_Sniper_Scout", "2", "Zombie Drop Sniper_scout Probability(0~100)", CVAR_FLAGS);
	DropUpgradepack_explosive = CreateConVar("Drop_Upgradepack_Explosive", "3", "Zombie Drop Upgradepack_explosive Probability(0~100)", CVAR_FLAGS);
	DropUpgradepack_incendiary = CreateConVar("Drop_Upgradepack_Incendiary", "3", "Zombie Drop Upgradepack_incendiary Probability(0~100)", CVAR_FLAGS);

	DropCricket_bat = CreateConVar("DropCricket_Bat", "2", "Zombie Drop Cricket_bat Probability(0~100)", CVAR_FLAGS);
	DropCrowbar = CreateConVar("Drop_Crowbar", "2", "Zombie Drop Crowbar Probability(0~100)", CVAR_FLAGS);
	DropElectric_guitar = CreateConVar("DropElectric_Guitar", "2", "Zombie Drop Electric_guitar Probability(0~100)", CVAR_FLAGS);
	DropFireaxe = CreateConVar("Drop_Fireaxe", "2", "Zombie Drop Fireaxe Probability(0~100)", CVAR_FLAGS);
	DropFrying_pan = CreateConVar("Drop_Frying_Pan", "2", "Zombie Drop Frying_pan Probability(0~100)", CVAR_FLAGS);
	DropKatana = CreateConVar("Drop_Katana", "2", "Zombie Drop Katana Probability(0~100)", CVAR_FLAGS);
	DropMachete = CreateConVar("Drop_Machete", "2", "Zombie Drop Machete Probability(0~100)", CVAR_FLAGS);
	DropChainsaw = CreateConVar("Drop_Chainsaw", "2", "Zombie Drop Chainsaw Probability(0~100)", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_Zombie_Fallen");
	HookEvent( "player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int entity = GetEventInt(event, "entityid");
	if(entity)
	{
		float Pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", Pos);
		DropItem(Pos);
	}
	return;
}

public void DropItem(float pos[3])
{
	int KitChance = GetRandomInt(1, 100);
	int PillsChance = GetRandomInt(1, 100);
	int FireChance = GetRandomInt(1, 100);
	int M60Chance = GetRandomInt(1, 100);
	int Pipe_BombChance = GetRandomInt(1, 100);
	int AdrenalineChance = GetRandomInt(1, 100);
	int DefibrillatorChance = GetRandomInt(1, 100);
	int MolotovChance = GetRandomInt(1, 100);
	int AutoshotgunChance = GetRandomInt(1, 100);
	int Hunting_rifleChance = GetRandomInt(1, 100);
	int Pistol_magnumChance = GetRandomInt(1, 100);
	int PumpshotgunChance = GetRandomInt(1, 100);
	int RifleChance = GetRandomInt(1, 100);
	int AK47Chance = GetRandomInt(1, 100);
	int Rifle_desertChance = GetRandomInt(1, 100);
	int Shotgun_chromeChance = GetRandomInt(1, 100);
	int Shotgun_spasChance = GetRandomInt(1, 100);
	int SmgChance = GetRandomInt(1, 100);
	int Smg_silencedChance = GetRandomInt(1, 100);
	int Sniper_militaryChance = GetRandomInt(1, 100);
	int Grenade_launcherChance = GetRandomInt(1, 100);
	int Rifle_sg552Chance = GetRandomInt(1, 100);
	int Smg_mp5Chance = GetRandomInt(1, 100);
	int Sniper_awpChance = GetRandomInt(1, 100);
	int Sniper_scoutChance = GetRandomInt(1, 100);
	int Upgradepack_explosiveChance = GetRandomInt(1, 100);
	int Upgradepack_incendiaryChance = GetRandomInt(1, 100);
	int Cricket_batChance = GetRandomInt(1, 100);
	int CrowbarChance = GetRandomInt(1, 100);
	int Electric_guitarChance = GetRandomInt(1, 100);
	int FireaxeChance = GetRandomInt(1, 100);
	int Frying_panChance = GetRandomInt(1, 100);
	int KatanaChance = GetRandomInt(1, 100);
	int MacheteChance = GetRandomInt(1, 100);
	int ChainsawChance = GetRandomInt(1, 100);

	switch(GetRandomInt(0, 34))
	{
		case 0:
		{
			if(KitChance <= GetConVarInt(Dropkit)) 
            {
                int entity = CreateEntityByName("weapon_first_aid_kit");
                if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
                }
            }
        }
		case 1:
		{
			if(PillsChance <= GetConVarInt(DropPills)) 
			{
				int entity = CreateEntityByName("weapon_pain_pills");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
				}
			}
        }
		case 2:
		{
        	if(M60Chance <= GetConVarInt(DropM60)) 
            {
                int entity = CreateEntityByName("weapon_rifle_m60");
                if (IsValidEntity(entity))
                {
                   	pos[2] += 50.0;
	                DispatchSpawn(entity);
	                TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	                return;
                }
            }
        }
		case 3:
		{
        	if(Pipe_BombChance <= GetConVarInt(DropPipe_Bomb)) 
            {
                int entity = CreateEntityByName("weapon_pipe_bomb");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
                }
            }
        }
		case 4:
		{
			if(AdrenalineChance <= GetConVarInt(DropAdrenaline)) 
			{
				int entity = CreateEntityByName("weapon_adrenaline");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
				}
			}
		}
		case 5:
		{
			if(DefibrillatorChance <= GetConVarInt(DropDefibrillator)) 
			{
				int entity = CreateEntityByName("weapon_defibrillator");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
				}
			}
		}
		case 6:
		{
			if(MolotovChance <= GetConVarInt(DropMolotov)) 
			{
				int entity = CreateEntityByName("weapon_molotov");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
				}
			}
		}
		case 7:
		{
			if(AutoshotgunChance <= GetConVarInt(DropAutoshotgun)) 
			{
				int entity = CreateEntityByName("weapon_autoshotgun");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 8:
		{
			if(Hunting_rifleChance <= GetConVarInt(DropHunting_rifle)) 
			{
				int entity = CreateEntityByName("weapon_hunting_rifle");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 9:
		{
			if(Pistol_magnumChance <= GetConVarInt(DropPistol_magnum)) 
			{
				int entity = CreateEntityByName("weapon_pistol_magnum");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 10:
		{
			if(PumpshotgunChance <= GetConVarInt(DropPumpshotgun)) 
			{
				int entity = CreateEntityByName("weapon_pumpshotgun");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 11:
		{
			if(RifleChance <= GetConVarInt(DropRifle)) 
			{
				int entity = CreateEntityByName("weapon_rifle");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 12:
		{
			if(AK47Chance <= GetConVarInt(DropAK47)) 
			{
				int entity = CreateEntityByName("weapon_rifle_ak47");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 13:
		{
			if(Rifle_desertChance <= GetConVarInt(DropRifle_desert)) 
			{
				int entity = CreateEntityByName("weapon_rifle_desert");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 14:
		{
			if(Shotgun_chromeChance <= GetConVarInt(DropShotgun_chrome)) 
			{
				int entity = CreateEntityByName("weapon_shotgun_chrome");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 15:
		{
			if(Shotgun_spasChance <= GetConVarInt(DropShotgun_spas)) 
			{
				int entity = CreateEntityByName("weapon_shotgun_spas");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 16:
		{
			if(SmgChance <= GetConVarInt(DropSmg)) 
			{
				int entity = CreateEntityByName("weapon_smg");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 17:
		{
			if(Smg_silencedChance <= GetConVarInt(DropSmg_silenced)) 
			{
				int entity = CreateEntityByName("weapon_smg_silenced");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 18:
		{
			if(Sniper_militaryChance <= GetConVarInt(DropSniper_military)) 
			{
				int entity = CreateEntityByName("weapon_sniper_military");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
					SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
					return;
				}
			}
		}
		case 19:
		{
			if(Grenade_launcherChance <= GetConVarInt(DropGrenade_launcher)) 
			{
				int entity = CreateEntityByName("weapon_grenade_launcher");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
                }
            }
        }
		case 20:
		{
        	if(Rifle_sg552Chance <= GetConVarInt(DropRifle_sg552)) 
			{
                int entity = CreateEntityByName("weapon_rifle_sg552");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
                    SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                    return;
				}
            }
        }
		case 21:
		{
        	if(Smg_mp5Chance <= GetConVarInt(DropSmg_mp5)) 
            {
                int entity = CreateEntityByName("weapon_smg_mp5");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
                    SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                    return;
				}
			}
        }
		case 22:
		{
        	if(Sniper_awpChance <= GetConVarInt(DropSniper_awp)) 
            {
                int entity = CreateEntityByName("weapon_sniper_awp");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
                    SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                    return;
                }
            }
        }
		case 23:
		{
        	if(Sniper_scoutChance <= GetConVarInt(DropSniper_scout)) 
			{
                int entity = CreateEntityByName("weapon_sniper_scout");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    int Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
                    SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                    return;
             	}
            }
        }
		case 24:
		{
        	if(Upgradepack_explosiveChance <= GetConVarInt(DropUpgradepack_explosive)) 
            {
            	int entity = CreateEntityByName("weapon_upgradepack_explosive");
                if (IsValidEntity(entity))
				{
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
				}
            }
        }
		case 25:
		{
			if(Upgradepack_incendiaryChance <= GetConVarInt(DropUpgradepack_incendiary)) 
            {
                int entity = CreateEntityByName("weapon_upgradepack_incendiary");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
                }
            }
        }
		case 26:
		{
        	if(Cricket_batChance <= GetConVarInt(DropCricket_bat)) 
            {
                int entity = CreateEntityByName("weapon_melee");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchKeyValue(entity,"melee_script_name","cricket_bat");
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
				}
            }
        }
		case 27:
		{
        	if(CrowbarChance <= GetConVarInt(DropCrowbar)) 
            {
                int entity = CreateEntityByName("weapon_melee");
                if (IsValidEntity(entity))
				{
                    pos[2] += 50.0;
                    DispatchKeyValue(entity,"melee_script_name","crowbar");
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
				}
            }
        }
		case 28:
		{
        	if(Electric_guitarChance <= GetConVarInt(DropElectric_guitar)) 
            {
                int entity = CreateEntityByName("weapon_melee");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchKeyValue(entity,"melee_script_name","electric_guitar");
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
                }
            }
        }
		case 29:
		{
			if(FireaxeChance <= GetConVarInt(DropFireaxe)) 
			{
				int entity = CreateEntityByName("weapon_melee");
				if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchKeyValue(entity,"melee_script_name","fireaxe");
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
				}
			}
        }
		case 30:
		{
        	if(Frying_panChance <= GetConVarInt(DropFrying_pan)) 
			{
                int entity = CreateEntityByName("weapon_melee");
                if (IsValidEntity(entity))
                {
                    pos[2] += 50.0;
                    DispatchKeyValue(entity,"melee_script_name","frying_pan");
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
				}
            }
        }
		case 31:
		{
        	if(KatanaChance <= GetConVarInt(DropKatana)) 
			{
                int entity = CreateEntityByName("weapon_melee");
                if (IsValidEntity(entity))
				{
                    pos[2] += 50.0;
                    DispatchKeyValue(entity,"melee_script_name","katana");
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
				}
            }
        }
		case 32:
		{
        	if(MacheteChance <= GetConVarInt(DropMachete)) 
            {
                int entity = CreateEntityByName("weapon_melee");
                if (IsValidEntity(entity))
				{
                    pos[2] += 50.0;
                    DispatchKeyValue(entity,"melee_script_name","machete");
                    DispatchSpawn(entity);
                    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
                    return;
				}
            }
        }
		case 33:
		{
        	if(ChainsawChance <= GetConVarInt(DropChainsaw)) 
            {
                int entity = CreateEntityByName("weapon_chainsaw");
                if (IsValidEntity(entity))
				{
					pos[2] += 50.0;
					DispatchSpawn(entity);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					return;
                }
            }
        }
		case 34:
		{
            if(FireChance <= GetConVarInt(DropFire)) 
            {
                int entity = CreateEntityByName("prop_physics");
                if (IsValidEntity(entity))
                {
					pos[2] += 10.0;
					DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");

					DispatchSpawn(entity);
					SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					AcceptEntityInput(entity, "break");
					return;
                }
            }
        }
    }
}
