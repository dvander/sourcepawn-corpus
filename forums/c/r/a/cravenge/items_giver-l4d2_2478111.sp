#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define PLUGIN_VERSION "3.9"
#define ADVERT "\x04[\x03Items Giver\x04] \x03Items Will Be Given To Survivors\x04!"

public Plugin myinfo =
{
	name = "[L4D2] Items Giver",
	author = "Jack'lul",
	description = "Gives Items To Survivors At Each Round.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1131184"
};

ConVar cvarAdvertDelay, cvarGiveInfo;
ConVar cvarDelayPrimWeapon, cvarDelaySecoWeapon, cvarDelayGranade,
	cvarDelayHealth, cvarDelaySupply, cvarDelayUpgrade, cvarDelayMelee;

ConVar cvarPrimWeapon, cvarSecoWeapon, cvarGranade,
	cvarHealth, cvarSupply, cvarUpgrade, cvarMelee;

ConVar cvarRandomPrimWeapon, cvarRandomSecoWeapon, cvarRandomGranade,
	cvarRandomHealth, cvarRandomSupply, cvarRandomUpgrade, cvarRandomMelee;

char currentmap[64];
bool itemsGiven, leftSafeSpot;

public void OnPluginStart()
{
	CreateConVar("items_giver-l4d2_version", PLUGIN_VERSION, "Items Giver Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	LoadTranslations("items_giver-l4d2.phrases");
	
	char s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (StrEqual(s_Game, "left4dead2", false))
	{
		cvarAdvertDelay = CreateConVar("items_giver-l4d2_settings_adsdelay", "7.5", "Advertisements Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarGiveInfo = CreateConVar("items_giver-l4d2_settings_giveinfo", "0", "Enable/Disable Notifications", FCVAR_NOTIFY, true, 0.0, true, 2.0);
		
		cvarDelayPrimWeapon = CreateConVar("items_giver-l4d2_delay_primweapon", "0.0", "Primary Weapons Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarDelaySecoWeapon = CreateConVar("items_giver-l4d2_delay_secweapon", "0.0", "Secondary Weapons Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarDelayGranade = CreateConVar("items_giver-l4d2_delay_grenade", "10.0", "Throwables Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarDelayHealth = CreateConVar("items_giver-l4d2_delay_health", "12.5", "Health Items Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarDelaySupply = CreateConVar("items_giver-l4d2_delay_supply", "15.0", "Supply Items Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarDelayUpgrade = CreateConVar("items_giver-l4d2_delay_upgrade", "0.0", "Upgrades Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		cvarDelayMelee = CreateConVar("items_giver-l4d2_delay_melee", "0.0", "Melee Weapons Giver Delay", FCVAR_NOTIFY, true, 0.0, true, 120.0);
		
		cvarPrimWeapon = CreateConVar("items_giver-l4d2_give_primweapon", "0", "Primary Weapons Giver Mode: 0=Off, 1=Pump Shotguns, 2=Auto Shotguns, 3=Spas Shotguns, 4=Chrome Shotguns, 5=SMGs, 6=MP5s, 7=Silenced SMGs, 8=Rifles, 9=AK47 Rifles\n10=Desert Rifles, 11=SG552s, 12=Military Snipers, 13=AWP Snipers, 14=Scout Snipers, 15=Hunting Rifles, 16=Grenade Launchers, 17=M60", FCVAR_NOTIFY, true, 0.0, true, 17.0);
		cvarSecoWeapon = CreateConVar("items_giver-l4d2_give_secweapon", "0", "Secondary Weapons Giver Mode: 0=Off, 1=Pistols, 2=Magnum Pistols", FCVAR_NOTIFY, true, 0.0, true, 13.0);
		cvarGranade = CreateConVar("items_giver-l4d2_give_grenade", "0", "Throwables Giver Mode: 0=Off, 1=Pipe Bombs, 2=Molotovs, 3=Boomer Biles", FCVAR_NOTIFY, true, 0.0, true, 3.0);
		cvarHealth = CreateConVar("items_giver-l4d2_give_health", "2", "Health Items Giver Mode: 0=Off, 1=Medkits, 2=Defibrillators", FCVAR_NOTIFY, true, 0.0, true, 4.0);
		cvarSupply = CreateConVar("items_giver-l4d2_give_supply", "0", "Supply Items Giver Mode: 0=Off, 1=Pain Pills, 2=Adrenaline", FCVAR_NOTIFY, true, 0.0, true, 2.0);
		cvarUpgrade = CreateConVar("items_giver-l4d2_give_upgrade", "0", "Upgrades Giver Mode: 0=Off, 1=Laser Sights, 2=Fire Bullets, 3=Explosive Bullets", FCVAR_NOTIFY, true, 0.0, true, 3.0);
		cvarMelee = CreateConVar("items_giver-l4d2_give_melee", "0", "Melee Weapons Giver Mode: 0=Off, 1=Oxygen Tanks, 2=Gas Cans, 3=Propane Tanks, 4=Firework Crates, 5=Cola Bottles, 6=Gnomes", FCVAR_NOTIFY, true, 0.0, true, 6.0);
		
		cvarRandomPrimWeapon = CreateConVar("items_giver-l4d2_random_primweapon", "0", "Enable/Disable Random Primary Weapons Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomSecoWeapon = CreateConVar("items_giver-l4d2_random_secweapon", "0", "Enable/Disable Random Secondary Weapons Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomGranade = CreateConVar("items_giver-l4d2_random_grenade", "1", "Enable/Disable Random Throwables Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomHealth = CreateConVar("items_giver-l4d2_random_health", "0", "Enable/Disable Random Health Items Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomSupply = CreateConVar("items_giver-l4d2_random_supply", "1", "Enable/Disable Random Supply Items Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomUpgrade = CreateConVar("items_giver-l4d2_random_upgrade", "0", "Enable/Disable Random Upgrades Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomMelee = CreateConVar("items_giver-l4d2_random_melee", "0", "Enable/Disable Random Melee Weapons Giver", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "items_giver-l4d2");
		
		HookEvent("round_start", OnRoundStart);
		HookEvent("player_left_start_area", OnPlayerLeft);
		HookEvent("player_left_checkpoint", OnPlayerLeft);
		
		RegConsoleCmd("sm_giveitems", GiveItems, "In case of some players not receiving items");
	}
	else
	{
		SetFailState("[IT] Plugin Supports L4D2 Only!");
	}
}

public Action GiveItems(int client, int args)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[\x03Items Giver\x04]\x01 Invalid Client!");
		return Plugin_Handled;
	}
	
	if (leftSafeSpot)
	{
		PrintToChat(client, "\x04[\x03Items Giver\x04]\x01 Already Left!");
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			int primary = GetPlayerWeaponSlot(i, 0);
			if (primary == -1 || !IsValidEntity(primary) || !IsValidEdict(primary))
			{
				switch (cvarPrimWeapon.IntValue)
				{
					case 0:
					{
						if (cvarRandomPrimWeapon.IntValue == 1)
						{
							switch (GetRandomInt(0, 16))
							{
								case 0: GiveItem(i, "pumpshotgun");
								case 1: GiveItem(i, "autoshotgun");
								case 2: GiveItem(i, "shotgun_spas");
								case 3: GiveItem(i, "shotgun_chrome");
								case 4: GiveItem(i, "smg");
								case 5: GiveItem(i, "smg_mp5");
								case 6: GiveItem(i, "smg_silenced");
								case 7: GiveItem(i, "rifle");
								case 8: GiveItem(i, "rifle_ak47");
								case 9: GiveItem(i, "rifle_desert");
								case 10: GiveItem(i, "rifle_sg552");
								case 11: GiveItem(i, "sniper_military");
								case 12: GiveItem(i, "sniper_awp");
								case 13: GiveItem(i, "sniper_scout");
								case 14: GiveItem(i, "hunting_rifle");
								case 15: GiveItem(i, "grenade_launcher");
								case 16: GiveItem(i, "rifle_m60");
							}
						}
					}
					case 1: GiveItem(i, "pumpshotgun");
					case 2: GiveItem(i, "autoshotgun");
					case 3: GiveItem(i, "shotgun_spas");
					case 4: GiveItem(i, "shotgun_chrome");
					case 5: GiveItem(i, "smg");
					case 6: GiveItem(i, "smg_mp5");
					case 7: GiveItem(i, "smg_silenced");
					case 8: GiveItem(i, "rifle");
					case 9: GiveItem(i, "rifle_ak47");
					case 10: GiveItem(i, "rifle_desert");
					case 11: GiveItem(i, "rifle_sg552");
					case 12: GiveItem(i, "sniper_military");
					case 13: GiveItem(i, "sniper_awp");
					case 14: GiveItem(i, "sniper_scout");
					case 15: GiveItem(i, "hunting_rifle");
					case 16: GiveItem(i, "grenade_launcher");
					case 17: GiveItem(i, "rifle_m60");
				}
				
				switch (cvarUpgrade.IntValue)
				{
					case 0:
					{
						if (cvarRandomUpgrade.IntValue == 1)
						{
							switch (GetRandomInt(0, 2))
							{
								case 0: GiveUpgrade(i, "LASER_SIGHT");
								case 1: GiveUpgrade(i, "INCENDIARY_AMMO");
								case 2: GiveUpgrade(i, "EXPLOSIVE_AMMO");
							}
						}
					}
					case 1: GiveUpgrade(i, "LASER_SIGHT");
					case 2: GiveUpgrade(i, "INCENDIARY_AMMO");
					case 3: GiveUpgrade(i, "EXPLOSIVE_AMMO");
				}
			}
			
			int secondary = GetPlayerWeaponSlot(i, 1);
			if (secondary == -1 || !IsValidEntity(secondary) || !IsValidEdict(secondary))
			{
				switch (cvarSecoWeapon.IntValue)
				{
					case 0:
					{
						if (cvarRandomSecoWeapon.IntValue == 1)
						{
							switch (GetRandomInt(0, 1))
							{
								case 0: GiveItem(i, "pistol");
								case 1: GiveItem(i, "pistol_magnum");
							}
						}
					}
					case 1: GiveItem(i, "pistol");
					case 2: GiveItem(i, "pistol_magnum");
				}
			}
			
			int throwable = GetPlayerWeaponSlot(i, 2);
			if (throwable == -1 || !IsValidEntity(throwable) || !IsValidEdict(throwable))
			{
				switch (cvarGranade.IntValue)
				{
					case 0:
					{
						if (cvarRandomGranade.IntValue == 1)
						{
							switch (GetRandomInt(0, 2))
							{
								case 0: GiveItem(i, "pipe_bomb");
								case 1: GiveItem(i, "molotov");
								case 2: GiveItem(i, "vomitjar");
							}
						}
					}
					case 1: GiveItem(i, "pipe_bomb");
					case 2: GiveItem(i, "molotov");
					case 3: GiveItem(i, "vomitjar");
				}
			}
			
			int handy = GetPlayerWeaponSlot(i, 3);
			if (handy == -1 || !IsValidEntity(handy) || !IsValidEdict(handy))
			{
				switch (cvarHealth.IntValue)
				{
					case 0:
					{
						if (cvarRandomHealth.IntValue == 1)
						{
							switch (GetRandomInt(0, 1)) 
							{
								case 0: GiveItem(i, "first_aid_kit");
								case 1: GiveItem(i, "defibrillator");
							}
						}
					}
					case 1: GiveItem(i, "first_aid_kit");
					case 2: GiveItem(i, "defibrillator");
				}
			}
			
			int useful = GetPlayerWeaponSlot(i, 4);
			if (useful == -1 || !IsValidEntity(useful) || !IsValidEdict(useful))
			{
				switch (cvarSupply.IntValue)
				{
					case 0:
					{
						if (cvarRandomSupply.IntValue == 1)
						{
							switch (GetRandomInt(0, 1)) 
							{
								case 0: GiveItem(i, "pain_pills");
								case 1: GiveItem(i, "adrenaline");
							}
						}
					}
					case 1: GiveItem(i, "pain_pills");
					case 2: GiveItem(i, "adrenaline");
				}
			}
			
			int misc = GetPlayerWeaponSlot(i, 5);
			if (misc == -1 || !IsValidEntity(misc) || !IsValidEdict(misc))
			{
				switch (cvarMelee.IntValue)
				{
					case 0:
					{
						if (cvarRandomMelee.IntValue == 1)
						{
							switch (GetRandomInt(0, 5))
							{
								case 0: GiveItem(i, "oxygentank");
								case 1: GiveItem(i, "gascan");
								case 2: GiveItem(i, "propanetank");
								case 3: GiveItem(i, "fireworkcrate");
								case 4:
								{
									if (StrEqual(currentmap, "c1m2_streets"))
									{
										GiveItem(i, "fireworkcrate");
									}
									else
									{
										GiveItem(i, "cola_bottles");
									}
								}
								case 5:
								{
									if (StrContains(currentmap, "c2", false) != -1)
									{ 
										GiveItem(i, "fireworkcrate");
									}
									else
									{
										GiveItem(i, "gnome");
									}
								}
							}
						}
					}
					case 1: GiveItem(i, "oxygentank");
					case 2: GiveItem(i, "gascan");
					case 3: GiveItem(i, "propanetank");
					case 4: GiveItem(i, "fireworkcrate");
					case 5: GiveItem(i, "cola_bottles");
					case 6: GiveItem(i, "gnome");
				}
			}
		}
	}
	
	PrintToChatAll("\x04[\x03Items Giver\x04]\x01 Items Have Been Given!");
	return Plugin_Handled;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if (!itemsGiven)
	{
		itemsGiven = true;
		
		CreateTimer(cvarAdvertDelay.FloatValue, Advert, client);
		CreateTimer(cvarDelayPrimWeapon.FloatValue, GivePrimWeaponDelay_l4d2, client);
		CreateTimer(cvarDelaySecoWeapon.FloatValue, GiveSecoWeaponDelay_l4d2, client);
		CreateTimer(cvarDelayGranade.FloatValue, GiveGranadeDelay_l4d2, client);
		CreateTimer(cvarDelayHealth.FloatValue, GiveHealthDelay_l4d2, client);
		CreateTimer(cvarDelaySupply.FloatValue, GiveSupplyDelay_l4d2, client);
		CreateTimer(cvarDelayUpgrade.FloatValue, GiveUpgradeDelay_l4d2, client);
		CreateTimer(cvarDelayMelee.FloatValue, GiveMeleeDelay_l4d2, client);
	}
}

public void OnMapStart()
{
	GetCurrentMap(currentmap, 64);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	leftSafeSpot = false;
	
	if (itemsGiven)
	{
		CreateTimer(cvarAdvertDelay.FloatValue, Advert);
		CreateTimer(cvarDelayPrimWeapon.FloatValue, GivePrimWeaponDelay_l4d2);
		CreateTimer(cvarDelaySecoWeapon.FloatValue, GiveSecoWeaponDelay_l4d2);
		CreateTimer(cvarDelayGranade.FloatValue, GiveGranadeDelay_l4d2);
		CreateTimer(cvarDelayHealth.FloatValue, GiveHealthDelay_l4d2);
		CreateTimer(cvarDelaySupply.FloatValue, GiveSupplyDelay_l4d2);
		CreateTimer(cvarDelayUpgrade.FloatValue, GiveUpgradeDelay_l4d2);
		CreateTimer(cvarDelayMelee.FloatValue, GiveMeleeDelay_l4d2);
	}
}

public Action OnPlayerLeft(Event event, const char[] name, bool dontBroadcast)
{
	if (!leftSafeSpot)
	{
		leftSafeSpot = true;
	}
}

public void OnMapEnd()
{
	itemsGiven = false;
}

public Action Advert(Handle timer)
{
	PrintToChatAll(ADVERT);
	PrintToChatAll("\x04[\x03Items Giver\x04]\x01 In Case Players Haven't Received Items, Type \x05!giveitems");
	return Plugin_Stop;
}

public Action GivePrimWeaponDelay_l4d2(Handle timer)
{
	GivePrimWeaponItem_l4d2();
	return Plugin_Stop;
}

public Action GiveSecoWeaponDelay_l4d2(Handle timer)
{
	GiveSecoWeaponItem_l4d2();
	return Plugin_Stop;
}

public Action GiveGranadeDelay_l4d2(Handle timer)
{
	GiveGranadeItem_l4d2();
	return Plugin_Stop;
}

public Action GiveHealthDelay_l4d2(Handle timer)
{
	GiveHealthItem_l4d2();
	return Plugin_Stop;
}

public Action GiveSupplyDelay_l4d2(Handle timer)
{
	GiveSupplyItem_l4d2();
	return Plugin_Stop;
}

public Action GiveUpgradeDelay_l4d2(Handle timer)
{
	GiveUpgradeItem_l4d2();
	return Plugin_Stop;
}

public Action GiveMeleeDelay_l4d2(Handle timer)
{
	GiveMeleeItem_l4d2();
	return Plugin_Stop;
}

void GivePrimWeaponItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarPrimWeapon.IntValue)
			{
				case 0:
				{
					if (cvarRandomPrimWeapon.IntValue == 1)
					{
						switch (GetRandomInt(0, 16))
						{
							case 0: GiveItem(i, "pumpshotgun");
							case 1: GiveItem(i, "autoshotgun");
							case 2: GiveItem(i, "shotgun_spas");
							case 3: GiveItem(i, "shotgun_chrome");
							case 4: GiveItem(i, "smg");
							case 5: GiveItem(i, "smg_mp5");
							case 6: GiveItem(i, "smg_silenced");
							case 7: GiveItem(i, "rifle");
							case 8: GiveItem(i, "rifle_ak47");
							case 9: GiveItem(i, "rifle_desert");
							case 10: GiveItem(i, "rifle_sg552");
							case 11: GiveItem(i, "sniper_military");
							case 12: GiveItem(i, "sniper_awp");
							case 13: GiveItem(i, "sniper_scout");
							case 14: GiveItem(i, "hunting_rifle");
							case 15: GiveItem(i, "grenade_launcher");
							case 16: GiveItem(i, "rifle_m60");
						}
					}
				}
				case 1: GiveItem(i, "pumpshotgun");
				case 2: GiveItem(i, "autoshotgun");
				case 3: GiveItem(i, "shotgun_spas");
				case 4: GiveItem(i, "shotgun_chrome");
				case 5: GiveItem(i, "smg");
				case 6: GiveItem(i, "smg_mp5");
				case 7: GiveItem(i, "smg_silenced");
				case 8: GiveItem(i, "rifle");
				case 9: GiveItem(i, "rifle_ak47");
				case 10: GiveItem(i, "rifle_desert");
				case 11: GiveItem(i, "rifle_sg552");
				case 12: GiveItem(i, "sniper_military");
				case 13: GiveItem(i, "sniper_awp");
				case 14: GiveItem(i, "sniper_scout");
				case 15: GiveItem(i, "hunting_rifle");
				case 16: GiveItem(i, "grenade_launcher");
				case 17: GiveItem(i, "rifle_m60");
			}
		}
	}
}

void GiveSecoWeaponItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarSecoWeapon.IntValue)
			{
				case 0:
				{
					if (cvarRandomSecoWeapon.IntValue == 1)
					{
						switch (GetRandomInt(0, 1))
						{
							case 0: GiveItem(i, "pistol");
							case 1: GiveItem(i, "pistol_magnum");
						}
					}
				}
				case 1: GiveItem(i, "pistol");
				case 2: GiveItem(i, "pistol_magnum");
			}
		}
	}
}

void GiveGranadeItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarGranade.IntValue)
			{
				case 0:
				{
					if (cvarRandomGranade.IntValue == 1)
					{
						switch (GetRandomInt(0, 2))
						{
							case 0: GiveItem(i, "pipe_bomb");
							case 1: GiveItem(i, "molotov");
							case 2: GiveItem(i, "vomitjar");
						}
					}
				}
				case 1: GiveItem(i, "pipe_bomb");
				case 2: GiveItem(i, "molotov");
				case 3: GiveItem(i, "vomitjar");
			}
		}
	}
}

void GiveHealthItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarHealth.IntValue)
			{
				case 0:
				{
					if (cvarRandomHealth.IntValue == 1)
					{
						switch (GetRandomInt(0, 1)) 
						{
							case 0: GiveItem(i, "first_aid_kit");
							case 1: GiveItem(i, "defibrillator");
						}
					}
				}
				case 1: GiveItem(i, "first_aid_kit");
				case 2: GiveItem(i, "defibrillator");
			}
		}
	}
}

void GiveSupplyItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarSupply.IntValue)
			{
				case 0:
				{
					if (cvarRandomSupply.IntValue == 1)
					{
						switch (GetRandomInt(0, 1)) 
						{
							case 0: GiveItem(i, "pain_pills");
							case 1: GiveItem(i, "adrenaline");
						}
					}
				}
				case 1: GiveItem(i, "pain_pills");
				case 2: GiveItem(i, "adrenaline");
			}
		}
	}
}

void GiveUpgradeItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarUpgrade.IntValue)
			{
				case 0:
				{
					if (cvarRandomUpgrade.IntValue == 1)
					{
						switch (GetRandomInt(0, 2))
						{
							case 0: GiveUpgrade(i, "LASER_SIGHT");
							case 1: GiveUpgrade(i, "INCENDIARY_AMMO");
							case 2: GiveUpgrade(i, "EXPLOSIVE_AMMO");
						}
					}
				}
				case 1: GiveUpgrade(i, "LASER_SIGHT");
				case 2: GiveUpgrade(i, "INCENDIARY_AMMO");
				case 3: GiveUpgrade(i, "EXPLOSIVE_AMMO");
			}
		}
	}
}

void GiveMeleeItem_l4d2()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			switch (cvarMelee.IntValue)
			{
				case 0:
				{
					if (cvarRandomMelee.IntValue == 1)
					{
						switch (GetRandomInt(0, 5))
						{
							case 0: GiveItem(i, "oxygentank");
							case 1: GiveItem(i, "gascan");
							case 2: GiveItem(i, "propanetank");
							case 3: GiveItem(i, "fireworkcrate");
							case 4:
							{
								if (StrEqual(currentmap, "c1m2_streets"))
								{
									GiveItem(i, "fireworkcrate");
								}
								else
								{
									GiveItem(i, "cola_bottles");
								}
							}
							case 5:
							{
								if (StrContains(currentmap, "c2", false) != -1)
								{ 
									GiveItem(i, "fireworkcrate");
								}
								else
								{
									GiveItem(i, "gnome");
								}
							}
						}
					}
				}
				case 1: GiveItem(i, "oxygentank");
				case 2: GiveItem(i, "gascan");
				case 3: GiveItem(i, "propanetank");
				case 4: GiveItem(i, "fireworkcrate");
				case 5: GiveItem(i, "cola_bottles");
				case 6: GiveItem(i, "gnome");
			}
		}
	}
}

void GiveItem(int Client, char Item[22])
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "give %s", Item);
	switch (cvarGiveInfo.IntValue)
	{
		case 1: PrintToChat(Client, "%t", Item);
		case 2: PrintHintText(Client, "%t", Item);
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

void GiveUpgrade(int Client, char Upgrade[22])
{
	int flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "upgrade_add %s", Upgrade);
	switch (cvarGiveInfo.IntValue)
	{
		case 1: PrintToChat(Client, "%t", Upgrade);
		case 2: PrintHintText(Client, "%t", Upgrade);
	}
	SetCommandFlags("upgrade_add", flags|FCVAR_CHEAT);
}

