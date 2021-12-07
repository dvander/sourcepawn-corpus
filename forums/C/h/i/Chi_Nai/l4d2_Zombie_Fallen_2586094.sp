#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
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

new Handle: Dropkit = INVALID_HANDLE;
new Handle: DropPills = INVALID_HANDLE;
new Handle: DropFire = INVALID_HANDLE;
new Handle: DropM60 = INVALID_HANDLE;
new Handle: DropPipe_Bomb = INVALID_HANDLE;
new Handle: DropDefibrillator = INVALID_HANDLE;
new Handle: DropAdrenaline = INVALID_HANDLE;
new Handle: DropMolotov = INVALID_HANDLE;
new Handle: DropAutoshotgun = INVALID_HANDLE;
new Handle: DropHunting_rifle = INVALID_HANDLE;
new Handle: DropPistol_magnum = INVALID_HANDLE;
new Handle: DropPumpshotgun = INVALID_HANDLE;
new Handle: DropRifle = INVALID_HANDLE;
new Handle: DropAK47 = INVALID_HANDLE;
new Handle: DropRifle_desert = INVALID_HANDLE;
new Handle: DropShotgun_chrome = INVALID_HANDLE;
new Handle: DropShotgun_spas = INVALID_HANDLE;
new Handle: DropSmg = INVALID_HANDLE;
new Handle: DropSmg_silenced = INVALID_HANDLE;
new Handle: DropSniper_military = INVALID_HANDLE;
new Handle: DropGrenade_launcher = INVALID_HANDLE;
new Handle: DropRifle_sg552 = INVALID_HANDLE;
new Handle: DropSmg_mp5 = INVALID_HANDLE;
new Handle: DropSniper_awp = INVALID_HANDLE;
new Handle: DropSniper_scout = INVALID_HANDLE;
new Handle: DropUpgradepack_explosive = INVALID_HANDLE;
new Handle: DropUpgradepack_incendiary = INVALID_HANDLE;
new Handle: DropCricket_bat = INVALID_HANDLE;
new Handle: DropCrowbar = INVALID_HANDLE;
new Handle: DropElectric_guitar = INVALID_HANDLE;
new Handle: DropFireaxe = INVALID_HANDLE;
new Handle: DropFrying_pan = INVALID_HANDLE;
new Handle: DropKatana = INVALID_HANDLE;
new Handle: DropMachete = INVALID_HANDLE;
new Handle: DropChainsaw = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "l4d2_Zombie_Fallen",
    author = "Chi_Nai",
    description = "Zombies can also drop items",
    version = PLUGIN_VERSION,
    url = "N/A"
}

public OnPluginStart()
{
	Dropkit = CreateConVar("Drop_kit", "0", "Zombie Drop First_Aid_Kit Probability(0~100)", FCVAR_PLUGIN);
	DropPills = CreateConVar("Drop_Pills", "0", "Zombie Drop Pain_Pills Probability(0~100)", FCVAR_PLUGIN);
	DropFire = CreateConVar("Drop_Fire", "0", "Zombie Drop Fire Probability(0~100)", FCVAR_PLUGIN);
	DropPipe_Bomb = CreateConVar("Drop_Pipe_Bomb", "0", "Zombie Drop Pipe_Bomb Probability(0~100)", FCVAR_PLUGIN);
	DropDefibrillator = CreateConVar("Drop_Defibrillator", "0", "Zombie Drop Defibrillator Probability(0~100)", FCVAR_PLUGIN);
	DropAdrenaline = CreateConVar("Drop_Adrenaline", "0", "Zombie Drop Adrenaline Probability(0~100)", FCVAR_PLUGIN);
	DropMolotov = CreateConVar("Drop_Molotov", "0", "Zombie Drop Molotov Probability(0~100)", FCVAR_PLUGIN);
	DropM60 = CreateConVar("Drop_M60", "0", "Zombie Drop M60 Probability(0~100)", FCVAR_PLUGIN);

	DropAutoshotgun = CreateConVar("Drop_Autoshotgun", "0", "Zombie Drop Autoshotgun Probability(0~100)", FCVAR_PLUGIN);
	DropHunting_rifle = CreateConVar("Drop_Hunting_Rifle", "0", "Zombie Drop Hunting_rifle Probability(0~100)", FCVAR_PLUGIN);
	DropPistol_magnum = CreateConVar("DropPistol_Magnum", "0", "Zombie Drop Pistol_magnum Probability(0~100)", FCVAR_PLUGIN);
	DropPumpshotgun = CreateConVar("Drop_Pumpshotgun", "0", "Zombie Drop Pumpshotgun Probability(0~100)", FCVAR_PLUGIN);
	DropRifle = CreateConVar("Drop_Rifle", "0", "Zombie Drop Rifle Probability(0~100)", FCVAR_PLUGIN);
	DropAK47 = CreateConVar("Drop_AK47", "0", "Zombie Drop AK47 Probability(0~100)", FCVAR_PLUGIN);
	DropRifle_desert = CreateConVar("Drop_Rifle_Desert", "0", "Zombie Drop Rifle_desert Probability(0~100)", FCVAR_PLUGIN);
	DropShotgun_chrome = CreateConVar("Drop_Shotgun_Chrome", "10.0", "Zombie Drop Shotgun_chrome Probability(0~100)", FCVAR_PLUGIN);
	DropShotgun_spas = CreateConVar("Drop_Shotgun_Spas", "0", "Zombie Drop Shotgun_spas Probability(0~100)", FCVAR_PLUGIN);
	DropSmg = CreateConVar("Drop_Smg", "10.0", "Zombie Drop Smg Probability(0~100)", FCVAR_PLUGIN);
	DropSmg_silenced = CreateConVar("Drop_Smg_Silenced", "0", "Zombie Drop Smg_silenced Probability(0~100)", FCVAR_PLUGIN);
	DropSniper_military = CreateConVar("Drop_Sniper_Military", "0", "Zombie Drop Sniper_military Probability(0~100)", FCVAR_PLUGIN);
	DropGrenade_launcher = CreateConVar("Drop_Grenade_Launcher", "0", "Zombie Drop Grenade_launcher Probability(0~100)", FCVAR_PLUGIN);
	DropRifle_sg552 = CreateConVar("Drop_Rifle_Sg552", "0", "Zombie Drop Rifle_sg552 Probability(0~100)", FCVAR_PLUGIN);
	DropSmg_mp5 = CreateConVar("Drop_Smg_Mp5", "0", "Zombie Drop Smg_mp5 Probability(0~100)", FCVAR_PLUGIN);
	DropSniper_awp = CreateConVar("Drop_Sniper_Awp", "0", "Zombie Drop Sniper_awp Probability(0~100)", FCVAR_PLUGIN);
	DropSniper_scout = CreateConVar("Drop_Sniper_Scout", "0", "Zombie Drop Sniper_scout Probability(0~100)", FCVAR_PLUGIN);
	DropUpgradepack_explosive = CreateConVar("Drop_Upgradepack_Explosive", "0", "Zombie Drop Upgradepack_explosive Probability(0~100)", FCVAR_PLUGIN);
	DropUpgradepack_incendiary = CreateConVar("Drop_Upgradepack_Incendiary", "0", "Zombie Drop Upgradepack_incendiary Probability(0~100)", FCVAR_PLUGIN);

	DropCricket_bat = CreateConVar("DropCricket_Bat", "1.0", "Zombie Drop Cricket_bat Probability(0~100)", FCVAR_PLUGIN);
	DropCrowbar = CreateConVar("Drop_Crowbar", "1.0", "Zombie Drop Crowbar Probability(0~100)", FCVAR_PLUGIN);
	DropElectric_guitar = CreateConVar("DropElectric_Guitar", "1.0", "Zombie Drop Electric_guitar Probability(0~100)", FCVAR_PLUGIN);
	DropFireaxe = CreateConVar("Drop_Fireaxe", "1.0", "Zombie Drop Fireaxe Probability(0~100)", FCVAR_PLUGIN);
	DropFrying_pan = CreateConVar("Drop_Frying_Pan", "1.0", "Zombie Drop Frying_pan Probability(0~100)", FCVAR_PLUGIN);
	DropKatana = CreateConVar("Drop_Katana", "1.0", "Zombie Drop Katana Probability(0~100)", FCVAR_PLUGIN);
	DropMachete = CreateConVar("Drop_Machete", "1.0", "Zombie Drop Machete Probability(0~100)", FCVAR_PLUGIN);
	DropChainsaw = CreateConVar("Drop_Chainsaw", "1.0", "Zombie Drop Chainsaw Probability(0~100)", FCVAR_PLUGIN);

	AutoExecConfig(true, "l4d2_Zombie_Fallen");
	HookEvent( "player_death", Event_PlayerDeath);
}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "entityid");
	if(entity)
	{
		decl Float:Pos[3];
        	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", Pos);
		DropItem(Pos);
	}
	return;
}
public DropItem(Float:pos[3])
{
	new KitChance = GetRandomInt(1,100);
	new PillsChance = GetRandomInt(1,100);
	new FireChance = GetRandomInt(1,100);
	new M60Chance = GetRandomInt(1,100);
	new Pipe_BombChance = GetRandomInt(1,100);
	new AdrenalineChance = GetRandomInt(1,100);
	new DefibrillatorChance = GetRandomInt(1,100);
	new MolotovChance = GetRandomInt(1,100);
	new AutoshotgunChance = GetRandomInt(1,100);
	new Hunting_rifleChance = GetRandomInt(1,100);
	new Pistol_magnumChance = GetRandomInt(1,100);
	new PumpshotgunChance = GetRandomInt(1,100);
	new RifleChance = GetRandomInt(1,100);
	new AK47Chance = GetRandomInt(1,100);
	new Rifle_desertChance = GetRandomInt(1,100);
	new Shotgun_chromeChance = GetRandomInt(1,100);
	new Shotgun_spasChance = GetRandomInt(1,100);
	new SmgChance = GetRandomInt(1,100);
	new Smg_silencedChance = GetRandomInt(1,100);
	new Sniper_militaryChance = GetRandomInt(1,100);
	new Grenade_launcherChance = GetRandomInt(1,100);
	new Rifle_sg552Chance = GetRandomInt(1,100);
	new Smg_mp5Chance = GetRandomInt(1,100);
	new Sniper_awpChance = GetRandomInt(1,100);
	new Sniper_scoutChance = GetRandomInt(1,100);
	new Upgradepack_explosiveChance = GetRandomInt(1,100);
	new Upgradepack_incendiaryChance = GetRandomInt(1,100);
	new Cricket_batChance = GetRandomInt(1,100);
	new CrowbarChance = GetRandomInt(1,100);
	new Electric_guitarChance = GetRandomInt(1,100);
	new FireaxeChance = GetRandomInt(1,100);
	new Frying_panChance = GetRandomInt(1,100);
	new KatanaChance = GetRandomInt(1,100);
	new MacheteChance = GetRandomInt(1,100);
	new ChainsawChance = GetRandomInt(1,100);

	switch(GetRandomInt(0,34))
	{
		case 0:
		{
                   	if(KitChance <= GetConVarInt(Dropkit)) 
                 	{
                        	new entity = CreateEntityByName("weapon_first_aid_kit");
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
                         	new entity = CreateEntityByName("weapon_pain_pills");
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
                         	new entity = CreateEntityByName("weapon_rifle_m60");
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
                            	new entity = CreateEntityByName("weapon_pipe_bomb");
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
                            	new entity = CreateEntityByName("weapon_adrenaline");
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
                            	new entity = CreateEntityByName("weapon_defibrillator");
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
                            	new entity = CreateEntityByName("weapon_molotov");
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
                            	new entity = CreateEntityByName("weapon_autoshotgun");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 8:
		{
        	        if(Hunting_rifleChance <= GetConVarInt(DropHunting_rifle)) 
                  	{
                            	new entity = CreateEntityByName("weapon_hunting_rifle");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 9:
		{
        	        if(Pistol_magnumChance <= GetConVarInt(DropPistol_magnum)) 
                  	{
                            	new entity = CreateEntityByName("weapon_pistol_magnum");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 10:
		{
        	        if(PumpshotgunChance <= GetConVarInt(DropPumpshotgun)) 
                  	{
                            	new entity = CreateEntityByName("weapon_pumpshotgun");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 11:
		{
        	        if(RifleChance <= GetConVarInt(DropRifle)) 
                  	{
                            	new entity = CreateEntityByName("weapon_rifle");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 12:
		{
        	        if(AK47Chance <= GetConVarInt(DropAK47)) 
                  	{
                            	new entity = CreateEntityByName("weapon_rifle_ak47");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 13:
		{
        	        if(Rifle_desertChance <= GetConVarInt(DropRifle_desert)) 
                  	{
                            	new entity = CreateEntityByName("weapon_rifle_desert");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 14:
		{
        	        if(Shotgun_chromeChance <= GetConVarInt(DropShotgun_chrome)) 
                  	{
                            	new entity = CreateEntityByName("weapon_shotgun_chrome");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 15:
		{
        	        if(Shotgun_spasChance <= GetConVarInt(DropShotgun_spas)) 
                  	{
                            	new entity = CreateEntityByName("weapon_shotgun_spas");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 16:
		{
        	        if(SmgChance <= GetConVarInt(DropSmg)) 
                  	{
                            	new entity = CreateEntityByName("weapon_smg");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 17:
		{
        	        if(Smg_silencedChance <= GetConVarInt(DropSmg_silenced)) 
                  	{
                            	new entity = CreateEntityByName("weapon_smg_silenced");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 18:
		{
        	        if(Sniper_militaryChance <= GetConVarInt(DropSniper_military)) 
                  	{
                            	new entity = CreateEntityByName("weapon_sniper_military");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 19:
		{
        	        if(Grenade_launcherChance <= GetConVarInt(DropGrenade_launcher)) 
                  	{
                            	new entity = CreateEntityByName("weapon_grenade_launcher");
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
                            	new entity = CreateEntityByName("weapon_rifle_sg552");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 21:
		{
        	        if(Smg_mp5Chance <= GetConVarInt(DropSmg_mp5)) 
                  	{
                            	new entity = CreateEntityByName("weapon_smg_mp5");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 22:
		{
        	        if(Sniper_awpChance <= GetConVarInt(DropSniper_awp)) 
                  	{
                            	new entity = CreateEntityByName("weapon_sniper_awp");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 23:
		{
        	        if(Sniper_scoutChance <= GetConVarInt(DropSniper_scout)) 
                  	{
                            	new entity = CreateEntityByName("weapon_sniper_scout");
                         	if (IsValidEntity(entity))
                            	{
                            		pos[2] += 50.0;
	                           	DispatchSpawn(entity);
	                            	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				        new Clip_Size = GetEntProp(entity, Prop_Send, "m_iClip1");
				        SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
                                	return;
                         	}
                        }

                }
		case 24:
		{
        	        if(Upgradepack_explosiveChance <= GetConVarInt(DropUpgradepack_explosive)) 
                  	{
                            	new entity = CreateEntityByName("weapon_upgradepack_explosive");
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
                            	new entity = CreateEntityByName("weapon_upgradepack_incendiary");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_melee");
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
                            	new entity = CreateEntityByName("weapon_chainsaw");
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
                         	new entity = CreateEntityByName("prop_physics");
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