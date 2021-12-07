#include <sourcemod>
#include <sdktools>

#define MaxClients 32
#define PLUGIN_VERSION "1.0"

#define CVARS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY

#pragma semicolon 1

//plugin info
public Plugin:myinfo = 
{
	name		= "ispirto's L4D2 Server Mod",
	author		= "ispirto",
	description	= "ispirto's L4D2 Server Mod",
	version		= PLUGIN_VERSION,
	url			= "http://ispirto.us"
}

//cvar handles
new Handle:ispirtoEnabled;
new Handle:editSpawnDelay;
new Handle:editMedkits;
new Handle:editDefibs;
new Handle:editSurvivalBonus;
new Handle:editTieBonus;
new Handle:forceTankAndWitch;
new Handle:switchT2AndT3WithT1;
new Handle:SMGMaxAmmo;
new Handle:ShotgunMaxAmmo;
new Handle:HRMaxAmmo;
new Handle:newTankHealth;
new Handle:hardcoreWitch;
new Handle:removeAmmoUpgrades;
new Handle:removeChainsaws;
new Handle:removeLauncher;
new Handle:removeM60;
new Handle:removeLaser;

//other handles
new Float:Saferoom[3];
new bool:setup = false;

//plugin setup
public OnPluginStart()
{
	//require Left 4 Dead 2
	decl String:Game[64];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2.");
	}
		
	//register cvars
	ispirtoEnabled = CreateConVar("l4d2_ispirto_enabled", "1", "Enable Plugin.", FCVAR_PLUGIN);
	CreateConVar("l4d2_ispirto_Version", PLUGIN_VERSION, "Plugin Version.", FCVAR_PLUGIN);
	editSpawnDelay = CreateConVar("l4d2_infected_spawn_delay", "20", "Infected spawn delay. (secs)", FCVAR_PLUGIN);
	editSurvivalBonus = CreateConVar("l4d2_edit_survival_bonus", "100", "New value for survival bonus for each player.", FCVAR_PLUGIN);
	editTieBonus = CreateConVar("l4d2_edit_tie_bonus", "100", "New value for tie breaker bonus for team.", FCVAR_PLUGIN);
	editMedkits = CreateConVar("l4d2_edit_medkits", "2", "What to do with medkits? (0 = Keep them, 1 = Remove all of them, 2 = Replace all of them with pills, 3 = Replace the ones out of saferoom with pills).", FCVAR_PLUGIN); //not ready
	editDefibs = CreateConVar("l4d2_edit_defibs", "2", "What to do with defibs? (0 = Keep them, 1 = Remove all of them, 2 = Replace all of them with pills, 3 = Replace the ones out of saferoom with pills, 4 = Keep them but make defibbed player black and white).", FCVAR_PLUGIN); //not ready
	removeAmmoUpgrades = CreateConVar("l4d2_remove_ammo_upgrades", "1", "Remove ammo upgrades.",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeChainsaws = CreateConVar("l4d2_remove_chainsaw", "1", "Remove Chainsaws.",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeLauncher = CreateConVar("l4d2_remove_launcher", "1", "Remove grenade launchers.",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeM60 = CreateConVar("l4d2_m60", "1", "Remove M60 rifles.",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeLaser = CreateConVar("l4d2_remove_laser", "1", "Remove Laser Sights.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	forceTankAndWitch = CreateConVar("l4d2_force_tank_and_witch", "1", "Force tank and witch on every round.", FCVAR_PLUGIN);
	switchT2AndT3WithT1 = CreateConVar("l4d2_switch_T2_and_T3", "1", "Switch T2 and T3 weapons with T1", FCVAR_PLUGIN);
	SMGMaxAmmo = CreateConVar("l4d2_SMGMaxAmmo", "650", "New value for ammo for SMG weapons (works only Switch T2 and T3 weapons with T1 enabled)", FCVAR_PLUGIN);
	ShotgunMaxAmmo = CreateConVar("l4d2_ShotgunMaxAmmo", "56", "New value for ammo for shotguns (works only Switch T2 and T3 weapons with T1 enabled)", FCVAR_PLUGIN);
	HRMaxAmmo = CreateConVar("l4d2_HRMaxAmmo", "150", "New value for ammo for hunting rifles (works only Switch T2 and T3 weapons with T1 enabled)", FCVAR_PLUGIN);
	newTankHealth = CreateConVar("l42_edit_tank_health", "6000", "New value for tank health.", FCVAR_PLUGIN);
	hardcoreWitch = CreateConVar("l42_hardcore_witch", "1", "Enable hardcore witch (Witch kills you with one shot).", FCVAR_PLUGIN);
	
	//create and execute config file under cfg/sourcemod
	AutoExecConfig(true, "l4d2_ispirto");
	
	//enable plugin if cvar is enabled
	if(GetConVarInt(ispirtoEnabled) == 1)
	{
		//event hooks
		HookEvent("round_start", executePlugin); //execute hardcore methods
		HookConVarChange(ispirtoEnabled, executePlugin2); //same as round start hook
		HookEvent("defibrillator_used", Event_PlayerDefibed); //execute b&w on defib
	}
}

//HardCore hooks
public Action:executePlugin(Handle:event, const String:name[], bool:dontBroadcast)
{
	return executePluginRealism();
}

public executePlugin2(Handle:convar, const String:oldValue[], const String:newValue[])
{
	executePluginRealism();
}

//HardCore methods
Action:executePluginRealism()
{
	new String:Map[32];
	GetCurrentMap(Map, 32);
	if (StrContains(Map, "c1m1") != -1)
	{
		Saferoom[0] = 430.946594;
		Saferoom[1] = 5744.847168;
		Saferoom[2] = 2882.982178;
	}
	else if (StrContains(Map, "c1m2") != -1)
	{
		Saferoom[0] = 2397.798584;
		Saferoom[1] = 4966.103027;
		Saferoom[2] = 478.224670;
	}
	else if (StrContains(Map, "c1m3") != -1)
	{
		Saferoom[0] = 6532.310059;
		Saferoom[1] = -1473.890015;
		Saferoom[2] = 59.001575;
	}
	else if (StrContains(Map, "c1m4") != -1)
	{
		Saferoom[0] = -2201.226807;
		Saferoom[1] = -4692.452637;
		Saferoom[2] = 571.226318;
	}
	else if (StrContains(Map, "c2m1") != -1)
	{
		Saferoom[0] = 10671.254883;
		Saferoom[1] = 7857.397461;
		Saferoom[2] = -540.156860;
	}
	else if (StrContains(Map, "c2m2") != -1)
	{
		Saferoom[0] = 1724.968750;
		Saferoom[1] = 2889.561523;
		Saferoom[2] = 39.232277;
	}
	else if (StrContains(Map, "c2m3") != -1)
	{
		Saferoom[0] = 4106.663574;
		Saferoom[1] = 2159.387451;
		Saferoom[2] = -28.767725;
	}
	else if (StrContains(Map, "c2m4") != -1)
	{
		Saferoom[0] = 2925.554199;
		Saferoom[1] = 3855.020020;
		Saferoom[2] = -187.968750;
	}
	else if (StrContains(Map, "c2m5") != -1)
	{
		Saferoom[0] = -653.677185;
		Saferoom[1] = 2220.736572;
		Saferoom[2] = -220.998734;
	}
	else if (StrContains(Map, "c3m1") != -1)
	{
		Saferoom[0] = -12465.958984;
		Saferoom[1] = 10524.093750;
		Saferoom[2] = 275.434265;
	}
	else if (StrContains(Map, "c3m2") != -1)
	{
		Saferoom[0] = -8213.431641;
		Saferoom[1] = 7622.576172;
		Saferoom[2] = 44.810654;
	}
	else if (StrContains(Map, "c3m3") != -1)
	{
		Saferoom[0] = -5697.970703;
		Saferoom[1] = 1999.031250;
		Saferoom[2] = 171.226288;
	}
	else if (StrContains(Map, "c3m4") != -1)
	{
		Saferoom[0] = -5019.223145;
		Saferoom[1] = -1568.031250;
		Saferoom[2] = -64.564751;
	}
	else if (StrContains(Map, "c4m1") != -1)
	{
		Saferoom[0] = -6012.471680;
		Saferoom[1] = 7385.575684;
		Saferoom[2] = 148.909729;
	}
	else if (StrContains(Map, "c4m2") != -1)
	{
		Saferoom[0] = 3781.565186;
		Saferoom[1] = -1668.598145;
		Saferoom[2] = 262.723663;
	}
	else if (StrContains(Map, "c4m3") != -1)
	{
		Saferoom[0] = -1804.286743;
		Saferoom[1] = -13777.250977;
		Saferoom[2] = 130.031250;
	}
	else if (StrContains(Map, "c4m4") != -1)
	{
		Saferoom[0] = 4039.968750;
		Saferoom[1] = -1551.401123;
		Saferoom[2] = 262.473663;
	}
	else if (StrContains(Map, "c4m5") != -1)
	{
		Saferoom[0] = -3383.520996;
		Saferoom[1] = 7791.185059;
		Saferoom[2] = 120.031250;
	}
	else if (StrContains(Map, "c5m1") != -1)
	{
		Saferoom[0] = 735.921692;
		Saferoom[1] = 729.955750;
		Saferoom[2] = -481.968750;
	}
	else if (StrContains(Map, "c5m2") != -1)
	{
		Saferoom[0] = -4335.529785;
		Saferoom[1] = -1127.393677;
		Saferoom[2] = -343.968750;
	}
	else if (StrContains(Map, "c5m3") != -1)
	{
		Saferoom[0] = 6289.354492;
		Saferoom[1] = 8212.956055;
		Saferoom[2] = 35.232281;
	}
	else if (StrContains(Map, "c5m4") != -1)
	{
		Saferoom[0] = -3058.571045;
		Saferoom[1] = 4778.432617;
		Saferoom[2] = 103.226173;
	}
	else if (StrContains(Map, "c5m5") != -1)
	{
		Saferoom[0] = -11924.932617;
		Saferoom[1] = 5981.550293;
		Saferoom[2] = 547.226318;
	}
	
	//replace or remove items
	new EntCount = GetEntityCount();
	new String:EdictName[128];
	
	for(new i = 0; i <= EntCount; i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, EdictName, sizeof(EdictName));
			
			//edit medkits
			if(GetConVarInt(editMedkits) != 0)
			{
				if(StrContains(EdictName, "weapon_first_aid_kit", false) != -1)
				{
					new Float:Location[3];
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
					//if keep saferoom medkits
					if((GetConVarInt(editMedkits) == 3))
					{
						if(GetVectorDistance(Location, Saferoom, false) > 200)
						{
							new index = CreateEntityByName("weapon_pain_pills_spawn");
							if(index != -1)
							{
								new Float:Angle[3];
								GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
								TeleportEntity(index, Location, Angle, NULL_VECTOR);
								DispatchSpawn(index);
							}
							
							AcceptEntityInput(i, "Kill");
						}
						
					}
					//if replace them all
					else if(GetConVarInt(editMedkits) == 2)
					{
						new index = CreateEntityByName("weapon_pain_pills_spawn");
						if(index != -1)
						{
							new Float:Angle[3];
							GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
							TeleportEntity(index, Location, Angle, NULL_VECTOR);
							DispatchSpawn(index);
						}
						AcceptEntityInput(i, "Kill");
					}
					continue;
				}
			}
			
			//edit defibs
			if(GetConVarInt(editDefibs) != 0 && GetConVarInt(editDefibs) != 4)
			{
				if(StrContains(EdictName, "weapon_defibrillator", false) != -1)
				{
					new Float:Location[3];
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
					//if keep saferoom defibs
					if((GetConVarInt(editDefibs) == 3))
					{
						if(GetVectorDistance(Location, Saferoom, false) > 200)
						{
							new index = CreateEntityByName("weapon_pain_pills_spawn");
							if(index != -1)
							{
								new Float:Angle[3];
								GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
								TeleportEntity(index, Location, Angle, NULL_VECTOR);
								DispatchSpawn(index);
							}
							
							AcceptEntityInput(i, "Kill");
						}
						
					}
					//if replace them all
					else if(GetConVarInt(editDefibs) == 2)
					{
						new index = CreateEntityByName("weapon_pain_pills_spawn");
						if(index != -1)
						{
							new Float:Angle[3];
							GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
							TeleportEntity(index, Location, Angle, NULL_VECTOR);
							DispatchSpawn(index);
						}
						AcceptEntityInput(i, "Kill");
					}
					continue;
				}
			}
			
			//remove explosive and incendiary ammo
			if(GetConVarInt(removeAmmoUpgrades) == 1)
			{
				if((StrContains(EdictName, "weapon_upgradepack_explosive", false) != -1) || (StrContains(EdictName, "weapon_upgradepack_incendiary", false) != -1))
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove chainsaws
			if(GetConVarInt(removeChainsaws) == 1)
			{
				if(StrContains(EdictName, "weapon_chainsaw", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove grenade launchers
			if(GetConVarInt(removeLauncher) == 1)
			{
				if(StrContains(EdictName, "weapon_grenade", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove m60 weapon
			if(GetConVarInt(removeM60) == 1)
			{
				if(StrContains(EdictName, "weapon_rifle_m60", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove laser sights
			if(GetConVarInt(removeLaser) == 1)
			{
				if(StrContains(EdictName, "weapon_upgradepack_laser", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
		}
	}

	//setup some convars, only on first run
	if(!setup)
	{
		//edit survival bonus
		SetConVarInt(FindConVar("vs_survival_bonus"), GetConVarInt(editSurvivalBonus));
		
		//edit tie breaker bonus
		SetConVarInt(FindConVar("vs_tiebreak_bonus"), GetConVarInt(editTieBonus));
			
		//edit tank and witch chances
		if(GetConVarInt(forceTankAndWitch) == 1)
		{
			SetConVarFloat(FindConVar("versus_tank_chance_intro"), 1.0, true);
			SetConVarFloat(FindConVar("versus_tank_chance_finale"), 1.0, true);
			SetConVarFloat(FindConVar("versus_tank_chance"), 1.0, true);
			SetConVarFloat(FindConVar("versus_witch_chance_intro"), 1.0, true);
			SetConVarFloat(FindConVar("versus_witch_chance_finale"), 1.0, true);
			SetConVarFloat(FindConVar("versus_witch_chance"), 1.0, true);
			SetConVarFloat(FindConVar("versus_boss_padding_min"), 0.05, true);
			SetConVarFloat(FindConVar("versus_boss_padding_max"), 0.2, true);
		}
		
		//edit infected spawn delay
		if(GetConVarInt(editSpawnDelay) == 1)
		{
			SetConVarFloat(FindConVar("z_ghost_delay_max"), GetConVarFloat(editSpawnDelay), true);
			SetConVarFloat(FindConVar("z_ghost_delay_min"), GetConVarFloat(editSpawnDelay), true);
		}
		
		SetConVarFloat(FindConVar("z_tank_health"), GetConVarFloat(newTankHealth), true);

			
		//hook patches
		HookEvent("heal_begin", HardCore_Mode_HealthKit_Patch); //fix bugged kit spawns
		HookEvent("spawner_give_item", HardCore_Mode_Weapon_Patch); //fix bugged weapon spawns
		HookEvent("player_incapacitated_start", HardCore_Mode_Witch_Patch); //hardcore witch
		SetConVarFloat(FindConVar("director_vs_convert_pills"), 0.0);
			
		setup = true;
	}
		
	CreateTimer(1.0, HardCore_Mode_Weapons);
	
	return Plugin_Handled;
}

//switch T2 and T3 weapons with T1
public Action:HardCore_Mode_Weapons(Handle:timer)
{
	if(GetConVarInt(switchT2AndT3WithT1) == 1)
	{
		//allowed tier 1 weapons
		new String:t1_weapons[8][128] = {
		"weapon_shotgun_chrome",
		"weapon_pumpshotgun",
		"weapon_hunting_rifle",
		"weapon_smg",
		"weapon_smg",
		"weapon_smg",
		"weapon_smg_silenced",
		"weapon_smg_silenced"
		};
		
		//replace weapons
		for(new i = 0; i <= GetEntityCount(); i++)
		{
			decl String:EdictName[128];
			decl String:WeaponName[128];
			decl maxammo;
			
			if(IsValidEntity(i))
			{
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				
				if(StrContains(EdictName, "weapon_spawn", false) != -1)
				{
					//get ent vectors
					decl Float:location[3], Float:angle[3];
					
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", location);
					GetEntPropVector(i, Prop_Send, "m_angRotation", angle);
					
					//remove the weapon spawn
					RemoveEdict(i);
					
					//create a new tier 1 weapon
					new index = CreateEntityByName(t1_weapons[GetRandomInt(0, sizeof(t1_weapons) - 1)]);
					
					GetEdictClassname(i, WeaponName, sizeof(WeaponName));
					
					if(StrContains(WeaponName, "weapon_smg", false) != -1 || StrContains(WeaponName, "weapon_smg_silenced", false) != -1)
					{
						maxammo = GetConVarInt(SMGMaxAmmo);
					}		
					else if(StrContains(WeaponName, "weapon_pumpshotgun", false) != -1 || StrContains(WeaponName, "weapon_shotgun_chrome", false) != -1)
					{
						maxammo = GetConVarInt(ShotgunMaxAmmo);
					}
					else if(StrContains(WeaponName, "weapon_hunting_rifle", false) != -1)
					{
						maxammo = GetConVarInt(HRMaxAmmo);
					}
					
					TeleportEntity(index, location, angle, NULL_VECTOR);
					DispatchKeyValue(index, "count", "10");
					DispatchSpawn(index); //<- this causes crashes!!!
					ActivateEntity(index);
					
					//set ammo for the gun
					SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", maxammo);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

//patches
public Action:HardCore_Mode_HealthKit_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(editMedkits) == 2)
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid")); //get userid of the player being naughty with a health kit
		
		if(IsClientConnected(Client))
		{
			new bugged_health_kit = GetPlayerWeaponSlot(Client, 3); //get his slot 4 weapon (index starts at 0)
			
			if(IsValidEntity(bugged_health_kit))
			{
				decl String:EdictName[128];
				GetEdictClassname(bugged_health_kit, EdictName, sizeof(EdictName));
				
				if(StrContains(EdictName, "weapon_first_aid_kit", false) != -1)
				{
					//remove his kit and give him pills instead
					RemovePlayerItem(Client, bugged_health_kit);
					GivePlayerItem(Client, "weapon_pain_pills");
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:HardCore_Mode_Weapon_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(switchT2AndT3WithT1) == 1)
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(IsClientConnected(Client))
		{
			new Weapon = GetPlayerWeaponSlot(Client, 0);
			
			if(IsValidEntity(Weapon))
			{
				decl String:EdictName[128];
				GetEdictClassname(Weapon, EdictName, sizeof(EdictName));
				
				new String:t1_weapons[6][128] = {
				"weapon_shotgun_chrome",
				"weapon_pumpshotgun",
				"weapon_hunting_rifle",
				"weapon_smg",
				"weapon_smg",
				"weapon_smg_silenced"
				};
				
				new bool:is_t2 = true;
				
				for(new i = 0; i < sizeof(t1_weapons); i++)
					if(StrContains(EdictName, t1_weapons[i], false) != -1)
						is_t2 = false;
				
				if(is_t2)
					AcceptEntityInput(Weapon, "Kill");
			}
		}
	}
	
	return Plugin_Handled;
}

//hardcore Witch Mode
public Action:HardCore_Mode_Witch_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(hardcoreWitch) == 1)
	{
		decl Type;
		Type = GetEventInt(event, "type");
		
		if(Type == 4)
		{
			decl Client;
			Client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			ForcePlayerSuicide(Client);
		}
	}
}

//when a player is defibed,
public Action:Event_PlayerDefibed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(editDefibs) == 4)
	{
		new client = GetClientOfUserId(GetEventInt(event, "subject"));
		new MaxIncaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
		SetEntProp(client, Prop_Send, "m_currentReviveCount", (MaxIncaps - 0));
		if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == MaxIncaps) SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(client, Prop_Send, "m_iHealth", 1);
		SetTempHealth(client, 30);
		
		//heart beat effect
		ServerCommand("heartbeat");
		ClientCommand(client, "heartbeat");
	}
	return Plugin_Continue;
}

//Used to set temp health, written by TheDanner.
public SetTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	new Float:newOverheal = hp * 1.0; //prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}
