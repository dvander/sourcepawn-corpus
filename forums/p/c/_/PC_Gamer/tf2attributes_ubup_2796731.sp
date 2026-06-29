#include <sourcemod>
#include <tf2items>
#include <tf2itemsinfo>
#include <tf2attributes>
#include <sdktools>

#define UU_VERSION "0.9.4g"
#define PLUGIN_VERSION "0.9.4g"

#define RED 0
#define BLUE 1

#define NB_B_WEAPONS 37

#define NB_SLOTS_UED 5

#define MAX_ATTRIBUTES 3000

#define MAX_ATTRIBUTES_ITEM 42

#define _NUMBER_DEFINELISTS 90

#define _NUMBER_DEFINELISTS_CAT 8

#define WCNAMELISTSIZE 90

#define _NB_SP_TWEAKS 90
#define MAXLEVEL_D 400

new Handle:up_menus[MAXPLAYERS + 1]

new Handle:menuBuy
new Handle:BuyNWmenu

new BuyNWmenu_enabled;

static Handle:db;
new Handle:cvar_uu_version
new Handle:cvar_StartMoney
new StartMoney
new Handle:cvar_TimerMoneyGive_BlueTeam
new TimerMoneyGive_BlueTeam
new Handle:cvar_TimerMoneyGive_RedTeam
new TimerMoneyGive_RedTeam
new Handle:cvar_MoneyBonusKill
new MoneyBonusKill
//new Handle:cvar_MoneyForTeamRatioRed
new Handle:cvar_AutoMoneyForTeamRatio
new Float:MoneyForTeamRatio[2]
new Float:MoneyTotalFlow[2]
new Handle:Timers_[3]
new clientLevels[MAXPLAYERS + 1]
new String:clientBaseName[MAXPLAYERS + 1][255]
new moneyLevels[MAXLEVEL_D + 1]
new given_upgrd_list_nb[_NUMBER_DEFINELISTS]
new given_upgrd_list[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][64]
new String:given_upgrd_classnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][64]
new given_upgrd_classnames_tweak_idx[_NUMBER_DEFINELISTS]
new given_upgrd_classnames_tweak_nb[_NUMBER_DEFINELISTS]
new String:wcnamelist[WCNAMELISTSIZE][64]
new wcname_l_idx[WCNAMELISTSIZE]
new current_w_list_id[MAXPLAYERS + 1]
new current_w_c_list_id[MAXPLAYERS + 1]
new _:current_class[MAXPLAYERS + 1]
new String:current_slot_name[5][32]
new current_slot_used[MAXPLAYERS + 1]
new currentupgrades_idx[MAXPLAYERS + 1][5][MAX_ATTRIBUTES_ITEM]
new Float:currentupgrades_val[MAXPLAYERS + 1][5][MAX_ATTRIBUTES_ITEM]
//new currentupgrades_special_ratio[MAXPLAYERS + 1][5][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number[MAXPLAYERS + 1][5]
new currentitem_level[MAXPLAYERS + 1][5]
new currentitem_idx[MAXPLAYERS + 1][5]
new currentitem_ent_idx[MAXPLAYERS + 1][5] 
new currentitem_catidx[MAXPLAYERS + 1][5]
new String:currentitem_classname[MAXPLAYERS + 1][5][64]
new upgrades_ref_to_idx[MAXPLAYERS + 1][5][MAX_ATTRIBUTES]
new currentupgrades_idx_mvm_chkp[MAXPLAYERS + 1][5][MAX_ATTRIBUTES_ITEM]
new Float:currentupgrades_val_mvm_chkp[MAXPLAYERS + 1][5][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number_mvm_chkp[MAXPLAYERS + 1][5]
new _u_id;
new client_spent_money[MAXPLAYERS + 1][5]
new client_new_weapon_ent_id[MAXPLAYERS + 1]
new client_spent_money_mvm_chkp[MAXPLAYERS + 1][5]
new client_last_up_slot[MAXPLAYERS + 1]
new client_last_up_idx[MAXPLAYERS + 1]
new client_iCash[MAXPLAYERS + 1];
new client_respawn_handled[MAXPLAYERS + 1]
new client_respawn_checkpoint[MAXPLAYERS + 1]
new client_no_showhelp[MAXPLAYERS + 1]
new client_no_d_team_upgrade[MAXPLAYERS + 1]
new client_no_d_menubuy_respawn[MAXPLAYERS + 1]
new Handle:_upg_names
new Handle:_weaponlist_names
new Handle:_spetweaks_names
new String:upgradesNames[MAX_ATTRIBUTES][64]
new String:upgradesWorkNames[MAX_ATTRIBUTES][96]
new upgrades_to_a_id[MAX_ATTRIBUTES]
new upgrades_costs[MAX_ATTRIBUTES]
new Float:upgrades_ratio[MAX_ATTRIBUTES]
new Float:upgrades_i_val[MAX_ATTRIBUTES]
new Float:upgrades_m_val[MAX_ATTRIBUTES]
new Float:upgrades_costs_inc_ratio[MAX_ATTRIBUTES]
new String:upgrades_tweaks[_NB_SP_TWEAKS][64]
new upgrades_tweaks_nb_att[_NB_SP_TWEAKS]
new upgrades_tweaks_att_idx[_NB_SP_TWEAKS][10]
new Float:upgrades_tweaks_att_ratio[_NB_SP_TWEAKS][10]
new newweaponidx[128];
new String:newweaponcn[64][64];
new String:newweaponmenudesc[64][64];
new gamemode
#define MVM_GAMEMODE 0
#define CP_GAMEMODE 1

public Plugin myinfo = 
{
	name = "Uber Upgrades",
	author = "Mr L, modified by PC Gamer",
	description = "Players can upgrade their abilities",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public Action:Timer_WaitForTF2II(Handle:timer)
{
	new i = 0
	if (TF2II_IsValidAttribID(1))
	{
		for (i = 1; i < 3000; i++)
		{
			if (TF2II_IsValidAttribID(i))
			{
				TF2II_GetAttributeNameByID( i, upgradesWorkNames[i], 96 );
				//	PrintToServer("%s\n", upgradesWorkNames[i]);
			}
			else
			{
				//	PrintToServer("unvalid attrib %d\n", i);
			}
		}
		for (i = 0; i < MAX_ATTRIBUTES; i++)
		{
			upgrades_ratio[i] = 0.0
			upgrades_i_val[i] = 0.0
			upgrades_costs[i] = 0
			upgrades_costs_inc_ratio[i] = 0.25
			upgrades_m_val[i] = 0.0
		}
		for (i = 1; i < _NUMBER_DEFINELISTS; i++)
		{
			given_upgrd_classnames_tweak_idx[i] = -1
			given_upgrd_list_nb[i] = 0
		}
		_load_cfg_files()
		KillTimer(timer)
	}
	
}

public UberShopDefineUpgradeTabs()
{
	new i = 0
	while (i < MAXPLAYERS + 1)
	{
		client_respawn_handled[i] = 0
		client_respawn_checkpoint[i] = 0
		clientLevels[i] = 0
		up_menus[i] = INVALID_HANDLE
		new j = 0
		while (j < NB_SLOTS_UED)
		{
			currentupgrades_number[i][j] = 0
			currentitem_level[i][j] = 0
			currentitem_idx[i][j] = 9999
			client_spent_money[i][j] = 0
			new k = 0
			while (k < MAX_ATTRIBUTES)
			{
				upgrades_ref_to_idx[i][j][k] = 9999
				k++
			}
			j++
		}	
		i++
		
	}
	
	current_slot_name[0] = "Primary Weapon"
	current_slot_name[1] = "Secondary Weapon"
	current_slot_name[2] = "Melee Weapon"
	current_slot_name[3] = "Special Weapon"
	current_slot_name[4] = "Body"
	upgradesNames[0] = ""
	CreateTimer(3.5, Timer_WaitForTF2II, _, TIMER_REPEAT);
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (!IsFakeClient(client) && IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if (itemLevel == 242)
		{
			new slot = 3
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)

			GiveNewUpgradedWeapon_(client, slot)
		}

		if (itemDefinitionIndex == 327) //Claidheamh Mor
		{
			new slot = 2
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_sword")	
			GiveNewUpgradedWeapon_(client, slot)
		}
		if (itemDefinitionIndex == 172)  //Scottsmans Skullcutter
		{
			new slot = 2
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_sword")	
			GiveNewUpgradedWeapon_(client, slot)
		}
		if (itemDefinitionIndex == 404) //Persian Persuader
		{
			new slot = 2
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_sword")	
			GiveNewUpgradedWeapon_(client, slot)
		}
		if (itemDefinitionIndex == 208) // Renamed Strange Flame Thrower
		{
			new slot = 0
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_flamethrower")	
			GiveNewUpgradedWeapon_(client, slot)
		}
		if (itemDefinitionIndex == 215) //Degreaser
		{
			new slot = 0
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_flamethrower")	
			GiveNewUpgradedWeapon_(client, slot)
		}
		if (itemDefinitionIndex == 594) //Phlog
		{
			new slot = 0
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_flamethrower")	
			GiveNewUpgradedWeapon_(client, slot)
		}		
		if (itemDefinitionIndex == 199 && !(current_class[client] == _:TFClass_Engineer)) //Renamed Strange Shotgun
		{
			new slot = 1
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun")	
			GiveNewUpgradedWeapon_(client, slot)
		}

		if (itemDefinitionIndex == 1153 && !(current_class[client] == _:TFClass_Engineer)) //Panic Attack
		{
			new slot = 1
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun")	
			GiveNewUpgradedWeapon_(client, slot)
		}
		if (itemDefinitionIndex == 1153 && (current_class[client] == _:TFClass_Engineer)) //Panic Attack
		{
			new slot = 0
			current_class[client] = _:TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_primary")	
			GiveNewUpgradedWeapon_(client, slot)
		}		
		else
		{
			new slot = _:TF2II_GetItemSlot(itemDefinitionIndex)	
			
			if (current_class[client] == _:TFClass_Spy)
			{
				if (!strcmp(classname, "tf_weapon_pda_spy"))
				{
					slot = 1
					current_class[client] = _:TF2_GetPlayerClass(client)
					currentitem_ent_idx[client][slot] = entityIndex
					if (!currentupgrades_number[client][slot])
					{
						currentitem_idx[client][slot] = 9999
					}
					DefineAttributesTab(client, itemDefinitionIndex, slot)
					GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
					currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_sapper")	
					GiveNewUpgradedWeapon_(client, slot)
				}
				if (slot == 2)
				{
					currentitem_classname[client][slot] = "tf_weapon_knife"					
					currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_knife")
				}
				if (itemDefinitionIndex == 735 || itemDefinitionIndex == 736 || StrEqual(classname, "tf_weapon_sapper"))
				{
					slot = 1;
				}
				
				if (StrEqual(classname, "tf_weapon_revolver"))
				{
					slot = 0;
				}
			}
			if (slot < 3 && slot > -1)
			{
				GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
				currentitem_ent_idx[client][slot] = entityIndex
				current_class[client] = _:TF2_GetPlayerClass(client)
				//currentitem_idx[client][slot] = itemDefinitionIndex
				DefineAttributesTab(client, itemDefinitionIndex, slot)
				if (current_class[client] == _:TFClass_DemoMan)
				{
					
					if (!strcmp(classname, "tf_wearable"))
					{
						if (itemDefinitionIndex == 405
								|| itemDefinitionIndex == 608) //Ali Babas Wee Booties or Bootlegger
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_wear_alishoes")
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Soldier)
				{
					if (!strcmp(classname, "tf_wearable"))
					{
						if (itemDefinitionIndex == 133) //Gunboats
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_w_gbt")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Sniper)
				{
					if (!strcmp(classname, "tf_wearable"))
					{
						if (itemDefinitionIndex == 231) //Darwins Danger Shield
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_w_darws")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Scout)
				{
					if (!strcmp(classname, "tf_weapon_scattergun"))
					{
						if (itemDefinitionIndex == 13
								|| itemDefinitionIndex == 200
								|| itemDefinitionIndex == 669
								|| itemDefinitionIndex == 799
								|| itemDefinitionIndex == 808
								|| itemDefinitionIndex == 880
								|| itemDefinitionIndex == 888
								|| itemDefinitionIndex == 897
								|| itemDefinitionIndex == 906
								|| itemDefinitionIndex == 915
								|| itemDefinitionIndex == 964
								|| itemDefinitionIndex == 973)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun_")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun")
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Engineer)
				{
					if (!strcmp(classname, "tf_weapon_shotgun_primary"))
					{
						if (itemDefinitionIndex == 527) //Widowmaker
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_widowmaker")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					if (!strcmp(classname, "saxxy"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_wrench")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				else if (current_class[client] == _:TFClass_Heavy)
				{
					if (!strcmp(classname, "tf_weapon_minigun"))
					{
						if (itemDefinitionIndex == 811 || itemDefinitionIndex == 832) //Huo Long Heatmaker
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_heater")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
					
				}
				else if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
				{
					if (!strcmp(classname, "tf_weapon_parachute"))
					{
						slot = 0;
					}
				}
				else
				{
					currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
				}				
				GiveNewUpgradedWeapon_(client, slot)
			}
			
		}
		//PrintToChatAll("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
	}
}

public void Event_PlayerChangeClass(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2Attrib_RemoveAll(client);
	if (IsValidClient(client))
	{
		ResetClientUpgrades(client);
		TF2Attrib_RemoveAll(client);
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_RemoveAll(Weapon);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
		}
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
		}
		int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
		if(IsValidEntity(Weapon4))
		{
			TF2Attrib_RemoveAll(Weapon4);
		}
		//ForcePlayerSuicide(client);
		
		ResetClientUpgrades(client);		
		current_class[client] = _:TF2_GetPlayerClass(client)
		ResetClientUpgrades(client);
		FakeClientCommand(client, "menuselect 0");		
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
	}	
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//	new team = GetClientOfUserId(GetEventInt(event, "team"));
	
	if (!client_respawn_handled[client])
	{
		client_respawn_handled[client] = 1
		//PrintToChat(client, "TEAM #%d", team)

		if (client_respawn_checkpoint[client])
		{
			//PrintToChatAll("cash readjust")
			CreateTimer(0.3, mvm_CheckPointAdjustCash, GetClientUserId(client));
		}
		else
		{
			CreateTimer(0.4, WeaponReGiveUpgrades, GetClientUserId(client));
		}
	}
}

public Action:Timer_GetConVars(Handle:timer)//Reload con_vars into vars
{
	new entityP = FindEntityByClassname(-1, "func_upgradestation");
	if (entityP > -1)
	{
		AcceptEntityInput(entityP, "Kill");
	}	
	
	//CostIncrease_ratio_default  = GetConVarFloat(cvar_CostIncrease_ratio_default)
	MoneyBonusKill = GetConVarInt(cvar_MoneyBonusKill)
	//MoneyForTeamRatio[RED]  = GetConVarFloat(cvar_MoneyForTeamRatioRed)
	//MoneyForTeamRatio[BLUE]  = GetConVarFloat(cvar_MoneyForTeamRatioBlue)
	TimerMoneyGive_BlueTeam = GetConVarInt(cvar_TimerMoneyGive_BlueTeam)
	TimerMoneyGive_RedTeam = GetConVarInt(cvar_TimerMoneyGive_RedTeam)
	StartMoney = GetConVarInt(cvar_StartMoney)
}

public Action:Timer_GiveSomeMoney(Handle:timer)//GIVE MONEY EVRY 20s
{
	new iCashtmp;
	
	MoneyTotalFlow[RED] = 0.00
	MoneyTotalFlow[BLUE] = 0.00
	for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id) && (GetClientTeam(client_id) > 1))
		{
			iCashtmp = GetEntProp(client_id, Prop_Send, "m_nCurrency", iCashtmp);
			iCashtmp += client_spent_money[client_id][0]
			+client_spent_money[client_id][1]
			+client_spent_money[client_id][2]
			+client_spent_money[client_id][3];
			if (GetClientTeam(client_id) == 3)
			{
				MoneyTotalFlow[BLUE] += iCashtmp
			}
			else
			{
				MoneyTotalFlow[RED] += iCashtmp
			}
			
		}
	}

	if (MoneyTotalFlow[RED])
	{
		MoneyForTeamRatio[RED] = MoneyTotalFlow[BLUE] / MoneyTotalFlow[RED]
	}
	if (MoneyTotalFlow[BLUE])
	{
		MoneyForTeamRatio[BLUE] = MoneyTotalFlow[RED] / MoneyTotalFlow[BLUE]
	}
	if (MoneyForTeamRatio[RED] > 3.0)
	{
		MoneyForTeamRatio[RED] = 3.0
	}
	if (MoneyForTeamRatio[BLUE] > 3.0)
	{
		MoneyForTeamRatio[BLUE] = 3.0
	}
	MoneyForTeamRatio[BLUE] *= MoneyForTeamRatio[BLUE]
	MoneyForTeamRatio[RED] *= MoneyForTeamRatio[RED]
	for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id))
		{
			iCashtmp = GetEntProp(client_id, Prop_Send, "m_nCurrency", iCashtmp);
			if (GetClientTeam(client_id) == 3)//BLUE TEAM
			{
				if (GetConVarInt(cvar_AutoMoneyForTeamRatio))
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
					iCashtmp + RoundToFloor(TimerMoneyGive_BlueTeam * MoneyForTeamRatio[BLUE]));
				}
				else
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
					iCashtmp + TimerMoneyGive_BlueTeam);
				}
			}
			else if (GetClientTeam(client_id) == 2)//RED TEAM
			{
				if (GetConVarInt(cvar_AutoMoneyForTeamRatio))
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
					iCashtmp + RoundToFloor(TimerMoneyGive_RedTeam * MoneyForTeamRatio[RED]));
				}
				else
				{
					SetEntProp(client_id, Prop_Send, "m_nCurrency",
					iCashtmp + TimerMoneyGive_RedTeam);
				}
			}
		}
	}
	TimerMoneyGive_BlueTeam = 100
	TimerMoneyGive_RedTeam = 100

}

public Action:Timer_Resetupgrades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IsValidClient(client, false))
	{
		SetEntProp(client, Prop_Send, "m_nCurrency", StartMoney);
	}
	if (IsValidClient(client))
	{
		for (new slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			client_spent_money[client][slot] = 0
			client_spent_money_mvm_chkp[client][slot] = 0
		}
		ResetClientUpgrades(client)
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
	}
}

public Action:ClChangeClassTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		client_respawn_checkpoint[client] = 0
		if (!client_no_d_menubuy_respawn[client])
		{
			Menu_BuyUpgrade(client, 0);
		}
		
	}
}

public Action:WeaponReGiveUpgrades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		client_respawn_handled[client] = 1
		for (new slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			if (client_spent_money[client][slot] > 0)
			{
				if (slot == 3 && client_new_weapon_ent_id[client])
				{
					GiveNewWeapon(client, 3)
				}
				GiveNewUpgradedWeapon_(client, slot)
			}
		}
		if (!client_no_d_menubuy_respawn[client])
		{
			Menu_BuyUpgrade(client, 0);
		}
	}
	client_respawn_handled[client] = 0
}

public OnClientDisconnect(client)
{
	ResetClientUpgrades(client)
}

public OnClientPutInServer(client)
{
	new iCashtmp;
	new maxCashtmp = 0;

	
	decl String:clname[255]
	GetClientName(client, clname, sizeof(clname))
	clientBaseName[client] = clname
	clientLevels[client] = 0
	client_no_d_team_upgrade[client] = 1
	client_no_showhelp[client] = 1
	ResetClientUpgrades(client)
	current_class[client] = _:TF2_GetPlayerClass(client)
	if (!client_respawn_handled[client])
	{
		CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
	}
	if (gamemode != MVM_GAMEMODE)
	{
		iCashtmp = 0
		maxCashtmp = 0
		for (new client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
		{
			if ((client_id != client) && IsValidClient(client_id) && IsPlayerAlive(client_id))
			{
				iCashtmp = client_spent_money[client_id][0]
				+client_spent_money[client_id][1]
				+client_spent_money[client_id][2]
				+client_spent_money[client_id][3];
				if (iCashtmp > maxCashtmp)
				{
					maxCashtmp = iCashtmp
				}
			}
		}
		SetEntProp(client, Prop_Send, "m_nCurrency", maxCashtmp/2);		
		if (maxCashtmp < 1500)
		{
			maxCashtmp = 1500
			SetEntProp(client, Prop_Send, "m_nCurrency", maxCashtmp);			
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) 
{
	if ((buttons & IN_SCORE) && (buttons & IN_RELOAD))
	{
		Menu_BuyUpgrade(client, 0);
	}
	return Plugin_Continue;		
}

public Action Resspawnn(Handle timer, any client)
{
	float playerpos[3];
	float nulVec[3];
	nulVec[0] = 0.0;
	nulVec[1] = 0.0;
	nulVec[2] = 0.0;

	TeleportEntity(client, playerpos, nulVec, nulVec);

	CloseHandle(timer);
	
	return Plugin_Handled;	
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attack = GetClientOfUserId(GetEventInt(event, "attacker"));
	int assist = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if (gamemode != MVM_GAMEMODE)
	{
		FakeClientCommand(client, "menuselect 0");
		int iCash_forteam;
		if (IsValidClient(attack, false) && IsValidClient(client, false) && attack != client)
		{
			int iCash_a = GetEntProp(attack, Prop_Send, "m_nCurrency");
			iCash_forteam = client_iCash[client] + client_spent_money[client][0]
			+client_spent_money[client][1]
			+client_spent_money[client][2]
			+client_spent_money[client][3];
			iCash_forteam = 0
			iCash_a = iCash_a + MoneyBonusKill + iCash_forteam
			client_iCash[attack] = iCash_a
			SetEntProp(attack, Prop_Send, "m_nCurrency", iCash_a)
			if (IsValidClient(assist))
			{
				int iCash_ass = GetEntProp(assist, Prop_Send, "m_nCurrency");
				//							iCash_ass += ((MoneyBonusKill + iCash_forteam) / 2)
				iCash_ass += (MoneyBonusKill)
				client_iCash[assist] = iCash_ass
				SetEntProp(assist, Prop_Send, "m_nCurrency", iCash_ass)
			}
		}
	}

	return Plugin_Continue
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	MoneyForTeamRatio[RED] = 1.0
	MoneyForTeamRatio[BLUE] = 1.0
}

public void Event_teamplay_round_win(Handle event, const char[] name, bool dontBroadcast)
{
	int slot, i
	int team = GetEventInt(event, "team");
	if (gamemode == MVM_GAMEMODE && team == 3)
	{
		for (int client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
		{
			if (IsValidClient(client_id))
			{
				
				client_respawn_checkpoint[client_id] = 1
				client_spent_money[client_id] = client_spent_money_mvm_chkp[client_id]
				for (slot = 0; slot < 5; slot++)
				{
					for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
					{
						upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = 9999
					}			
					currentupgrades_idx[client_id][slot] = currentupgrades_idx_mvm_chkp[client_id][slot]
					currentupgrades_val[client_id][slot] = currentupgrades_val_mvm_chkp[client_id][slot]
					currentupgrades_number[client_id][slot] = currentupgrades_number_mvm_chkp[client_id][slot]
					for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
					{
						upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = i
					}
				}
			}
		}
	}
}

public void Event_mvm_begin_wave(Handle event, const char[] name, bool dontBroadcast)
{
	gamemode = MVM_GAMEMODE
}

public void Event_mvm_wave_complete(Handle event, const char[] name, bool dontBroadcast)
{
	int client_id, slot
	
	for (client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
	{
		if (IsValidClient(client_id))
		{
			
			client_spent_money_mvm_chkp[client_id] = client_spent_money[client_id]
			for (slot = 0; slot < 5; slot++)
			{
				currentupgrades_number_mvm_chkp[client_id][slot] = currentupgrades_number[client_id][slot]
				currentupgrades_idx_mvm_chkp[client_id][slot] = currentupgrades_idx[client_id][slot]
				currentupgrades_val_mvm_chkp[client_id][slot] = currentupgrades_val[client_id][slot]
			}
		}
	}
}

public Action mvm_CheckPointAdjustCash(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && client_respawn_checkpoint[client])
	{
		int iCash = GetEntProp(client, Prop_Send, "m_nCurrency");
		SetEntProp(client, Prop_Send, "m_nCurrency", iCash -
		(client_spent_money_mvm_chkp[client][0] 
		+ client_spent_money_mvm_chkp[client][1] 
		+ client_spent_money_mvm_chkp[client][2] 
		+ client_spent_money_mvm_chkp[client][3]) );
		client_respawn_checkpoint[client] = 0
		CreateTimer(0.1, WeaponReGiveUpgrades, GetClientUserId(client));
	}
	return Plugin_Handled;
}


public void Event_PlayerChangeTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		ResetClientUpgrades(client)
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
	}
}

public Action jointeam_callback(int client, const char[] command, int argc) //protection from spectators
{
	char arg[3];
	arg[0] = '\0';
	PrintToServer("jointeam callback #%d", client);
	GetCmdArg(1, arg, sizeof(arg));
	if(StrEqual(arg, "") || StringToInt(arg) == 0)
	{
		ResetClientUpgrades(client)
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
		if (gamemode != MVM_GAMEMODE)
		{
			int iCashtmp;
			int maxCashtmp = 0;
			for (int client_id = 1; client_id < MAXPLAYERS + 1; client_id++)
			{
				if ((client_id != client) && IsValidClient(client_id) && IsPlayerAlive(client_id))
				{
					iCashtmp = GetEntProp(client, Prop_Send, "m_nCurrency", iCashtmp);
					iCashtmp = client_spent_money[client_id][0]
					+client_spent_money[client_id][1]
					+client_spent_money[client_id][2]
					+client_spent_money[client_id][3];
					if (iCashtmp > maxCashtmp)
					{
						maxCashtmp = iCashtmp
					}
				}
			}
			iCashtmp = GetEntProp(client, Prop_Send, "m_nCurrency");
			SetEntProp(client, Prop_Send, "m_nCurrency", (maxCashtmp * 3)/4);
			
			PrintToServer("give to client #%d startmoney", (maxCashtmp * 3)/4);
			if (maxCashtmp < StartMoney)
			{
				maxCashtmp = StartMoney
				SetEntProp(client, Prop_Send, "m_nCurrency", maxCashtmp);
				PrintToServer("gave to client #%d more money", maxCashtmp);			
			}			
		}
	}
	return Plugin_Handled;	
} 

public Action Disp_Help(int client, int args)
{
	PrintToChat(client, "!uuhelp : display help");
	PrintToChat(client, "!nohelp : stop displaying the repetitive help message");
	PrintToChat(client, "!buy : display buy menu");
	PrintToChat(client, "<showscore> + <reload>: display buy menu (by default ");
	PrintToChat(client, "To get your money back, change loadout or class.");
	PrintToChat(client, "In game, use MOUSESCROLL to switch to your original weapons and use NUMERICS for your additional one(s).");

	return Plugin_Handled;	
}

public Action Toggl_DispTeamUpgrades(int client, int args)
{
	char arg1[32];
	int arg;
	
	client_no_d_team_upgrade[client] = 0
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 0)
		{
			client_no_d_team_upgrade[client] = 1
		}
	}
	return Plugin_Handled;	
}

public Action Toggl_DispMenuRespawn(int client, int args)
{
	char arg1[32];
	int arg;
	
	client_no_d_menubuy_respawn[client] = 0
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 0)
		{
			client_no_d_menubuy_respawn[client] = 1
		}
	}
	return Plugin_Handled;	
}

public Action StopDisp_chatHelp(int client, int args)
{
	client_no_showhelp[client] = 1
		
	return Plugin_Handled;	
}

public Action ShowSpentMoney(int admid, int args)
{
	for(int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (IsValidClient(i))
		{
			char cstr[255]
			GetClientName(i, cstr, 255)
			PrintToChat(admid, "**%s**\n**", cstr)
			for (int s = 0; s < 5; s++)
			{
				PrintToChat(admid, "%s : %d$ of upgrades", current_slot_name[s], client_spent_money[i][s])
			}
		}
	}
	return Plugin_Handled;		
}

public Action ShowTeamMoneyRatio(int admid, int args)
{
	for(int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (IsValidClient(i))
		{
			char cstr[255]
			GetClientName(i, cstr, 255)
			PrintToChat(admid, "**%s**\n**", cstr)
			for (int s = 0; s < 5; s++)
			{
				PrintToChat(admid, "%s : %d$ of upgrades", current_slot_name[s], client_spent_money[i][s])
			}
		}
	}
	return Plugin_Handled;		
}

public Action ReloadCfgFiles(int client, int args)
{
	_load_cfg_files()
	
	for (int cl = 0; cl < MAXPLAYERS + 1; cl++)
	{
		if (IsValidClient(cl))
		{
			ResetClientUpgrades(cl)
			current_class[cl] = _:TF2_GetPlayerClass(client)
			//PrintToChat(cl, "client changeclass");
			if (!client_respawn_handled[cl])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(cl));
			}
		}	
	}
	return Plugin_Handled;		
}


//admin cmd: enable/disable menu "buy an additional weapon"
public Action EnableBuyNewWeapon(int client, int args)
{
	char arg1[32];
	int arg;
	
	BuyNWmenu_enabled = 0
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 1)
		{
			BuyNWmenu_enabled = 1
		}
	}
	return Plugin_Handled;		
}

public Action Menu_QuickBuyUpgrade2(int mclient, int args)
{
	if (IsPlayerAlive(mclient))
	{
		PrintToChat(mclient, "QBuy is disabled due to player exploits");
	}
	return Plugin_Handled;		
}

public Action Menu_QuickBuyUpgrade(int mclient, int args)
{
	if (IsPlayerAlive(mclient))
	{
		char arg1[32];
		int arg1_;
		char arg2[32];
		int arg2_;
		char arg3[32];
		int arg3_ = 0;
		char arg4[32];
		int arg4_ = 0;
		bool flag = false
		
		if (GetCmdArg(1, arg1, sizeof(arg1)))
		{
			arg1_ = StringToInt(arg1);//SLOT USED
			if (arg1_ > -1 && arg1_ < 5 && GetCmdArg(2, arg2, sizeof(arg2)))
			{
				int w_id = currentitem_catidx[mclient][arg1_]
				arg2_ = StringToInt(arg2);
				if (GetCmdArg(3, arg3, sizeof(arg3)))
				{
					arg3_ = StringToInt(arg3);
					arg4_ = 1
					if (GetCmdArg(4, arg4, sizeof(arg4)))
					{
						arg4_ = StringToInt(arg4);
						if (arg4_ >= 100)
						{
							arg4_ = 100
						}
						if (arg4_ < 1)
						{
							arg4_ = 1
						}
					}
					if (arg2_ > -1 && arg2_ < given_upgrd_list_nb[w_id]
							&& given_upgrd_list[w_id][arg2_][arg3_])
					{
						int iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency");
						int upgrade_choice = given_upgrd_list[w_id][arg2_][arg3_]
						int inum = upgrades_ref_to_idx[mclient][arg1_][upgrade_choice]
						if (inum == 9999)
						{
							inum = currentupgrades_number[mclient][arg1_]
							currentupgrades_number[mclient][arg1_]++
							upgrades_ref_to_idx[mclient][arg1_][upgrade_choice] = inum;
							currentupgrades_idx[mclient][arg1_][inum] = upgrade_choice 
							currentupgrades_val[mclient][arg1_][inum] = upgrades_i_val[upgrade_choice];
						}
						int idx_currentupgrades_val = RoundToFloor((currentupgrades_val[mclient][arg1_][inum] - upgrades_i_val[upgrade_choice])
						/ upgrades_ratio[upgrade_choice])
						float upgrades_val = currentupgrades_val[mclient][arg1_][inum]
						int up_cost = upgrades_costs[upgrade_choice]
						up_cost /= 2
						if (arg1_ == 1)
						{
							up_cost = RoundToFloor((up_cost * 1.0) * 0.75)
						}
						if (inum != 9999 && upgrades_ratio[upgrade_choice])
						{
							int t_up_cost = 0
							for (int idx = 0; idx < arg4_; idx++)
							{
								t_up_cost += up_cost + RoundToFloor(up_cost * (
								idx_currentupgrades_val
								* upgrades_costs_inc_ratio[upgrade_choice]))
								idx_currentupgrades_val++		
								upgrades_val += upgrades_ratio[upgrade_choice]
							}
							
							if (t_up_cost < 0.0)
							{
								t_up_cost *= -1;
								if (t_up_cost < (upgrades_costs[upgrade_choice] / 2))
								{
									t_up_cost = upgrades_costs[upgrade_choice] / 2
								}
							}
							if (iCash < t_up_cost)
							{
								char buffer[64]
								Format(buffer, sizeof(buffer), "%T", "Not enough money!!", mclient);
								PrintToChat(mclient, buffer);
							}
							else
							{
								if ((upgrades_ratio[upgrade_choice] > 0.0 && upgrades_val >= upgrades_m_val[upgrade_choice])
										|| (upgrades_ratio[upgrade_choice] < 0.0 && upgrades_val <= upgrades_m_val[upgrade_choice]))
								{
									PrintToChat(mclient, "Maximum upgrade value reached for this category.");
								}
								else
								{
									flag = true
									client_iCash[mclient] = iCash - t_up_cost
									SetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
									currentupgrades_val[mclient][arg1_][inum] = upgrades_val
									client_spent_money[mclient][arg1_] += t_up_cost
									int totalmoney = 0
									
									for (int s = 0; s < 5; s++)
									{
										totalmoney += client_spent_money[mclient][s]
									}
									int ctr_m = clientLevels[mclient]
									
									while (ctr_m < MAXLEVEL_D && totalmoney > moneyLevels[ctr_m])
									{
										ctr_m++
									}
									if (ctr_m != clientLevels[mclient])
									{
										clientLevels[mclient] = ctr_m
										char clname[255]
										char strsn[12]
										if (ctr_m == MAXLEVEL_D)
										{
											strsn = "[_over9000]"
										}
										else
										{
											Format(strsn, sizeof(strsn), "[Lvl %d]", ctr_m + 1)
										}
										Format(clname, sizeof(clname), "%s%s", strsn, clientBaseName[mclient])
										SetClientInfo(mclient, "name", clname);
									}
									GiveNewUpgradedWeapon_(mclient, arg1_)
									PrintToChat(mclient, "yep");
								}
							}
						}
					}
				}
			}
		}
		if (!flag)
		{
			PrintToChat(mclient, "Usage: /qbuy [slot 0] [upgrade menu cat 0-n] [upgrade menu entry 0-n] [nb of buy]");
			PrintToChat(mclient, "slot : 0 primary 1 secondary 2 melee 3 special 4 body");
			PrintToChat(mclient, "for example /qbuy 4 0 1 10 will make you buy health regen 10 times");
		}
	}
	if (!IsPlayerAlive(mclient))
	{
		PrintToChat(mclient, "You must be alive to qbuy!");
	}
	return Plugin_Handled;		
}

GetWeaponsCatKVSize(Handle:kv)
{
	new siz = 0
	do
	{
		if (!KvGotoFirstSubKey(kv, false))
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				siz++
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return siz
}

BrowseWeaponsCatKV(Handle:kv)
{
	new u_id = 0
	new t_idx = 0
	SetTrieValue(_weaponlist_names, "body_scout" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_sniper" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_soldier" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_demoman" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_medic" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_heavy" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_pyro" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_spy" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_engie" , t_idx++, false);
	decl String:Buf[64];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseWeaponsCatKV(kv);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				wcnamelist[u_id] = Buf
				KvGetString(kv, "", Buf, 64);
				if (SetTrieValue(_weaponlist_names, Buf, t_idx, false))
				{
					t_idx++
				}
				GetTrieValue(_weaponlist_names, Buf, wcname_l_idx[u_id])
				//PrintToServer("weapon list %d: %s - %s(%d)", u_id,wcnamelist[u_id], Buf, wcname_l_idx[u_id])
				u_id++;
				//PrintToServer("%s linked : %s->%d",  wcnamelist[u_id], Buf,wcname_l_idx[u_id])
				//PrintToServer("value:%s", Buf)
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}

BrowseAttributesKV(Handle:kv)
{
	decl String:Buf[64];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			//PrintToServer("\nAttribute #%d", _u_id)
			BrowseAttributesKV(kv);
			KvGoBack(kv);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				if (!strcmp(Buf,"ref"))
				{
					KvGetString(kv, "", Buf, 64);
					upgradesNames[_u_id] = Buf
					SetTrieValue(_upg_names, Buf, _u_id, true);
					//	PrintToServer("ref:%s --uid:%d", Buf, _u_id)
				}
				if (!strcmp(Buf,"name"))
				{
					KvGetString(kv, "", Buf, 64);
					if (strcmp(Buf,""))
					{
						//PrintToServer("Name:%s-", Buf)
						//new _:att_id = TF2II_GetAttributeIDByName(Buf)
						for (new i_ = 1; i_ < MAX_ATTRIBUTES; i_++)
						{
							if (!strcmp(upgradesWorkNames[i_], Buf))
							{
								upgrades_to_a_id[_u_id] = i_
								//	PrintToServer("up_ref/id[%d]:%s/%d", _u_id, Buf, upgrades_to_a_id[_u_id])
								break;
							}
						}
					}
				}
				if (!strcmp(Buf,"cost"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs[_u_id] = StringToInt(Buf)
					//PrintToServer("cost:%d", upgrades_costs[_u_id])
				}
				if (!strcmp(Buf,"increase_ratio"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs_inc_ratio[_u_id] = StringToFloat(Buf)
					//PrintToServer("increase rate:%f", upgrades_costs_inc_ratio[_u_id])
				}
				if (!strcmp(Buf,"value"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_ratio[_u_id] = StringToFloat(Buf)
					//PrintToServer("val:%f", upgrades_ratio[_u_id])
				}
				if (!strcmp(Buf,"init"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_i_val[_u_id] = StringToFloat(Buf)
					//PrintToServer("init:%f", upgrades_i_val[_u_id])
				}
				if (!strcmp(Buf,"max"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_m_val[_u_id] = StringToFloat(Buf)
					//PrintToServer("max:%f", upgrades_m_val[_u_id])
					_u_id++
				}

			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return (_u_id)
}

BrowseAttListKV(Handle:kv, &w_id = -1, &w_sub_id = -1, w_sub_att_idx = -1, level = 0)
{
	decl String:Buf[64];
	do
	{
		KvGetSectionName(kv, Buf, sizeof(Buf));
		if (level == 1)
		{
			if (!GetTrieValue(_weaponlist_names, Buf, w_id))
			{
				PrintToServer("[uu_lists] Malformated uu_lists | uu_weapon.txt file?: %s was not found", Buf)
			}
			w_sub_id = -1;
			given_upgrd_classnames_tweak_nb[w_id] = 0
		}
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf))
			if (!strcmp(Buf, "special_tweaks_listid"))
			{

				KvGetString(kv, "", Buf, 64);
				//PrintToServer("  ->Sublist/#%s -- #%d", Buf, w_id)
				given_upgrd_classnames_tweak_idx[w_id] = StringToInt(Buf)
			}
			else
			{
				w_sub_id++
				//	PrintToServer("section #%s", Buf)
				given_upgrd_classnames[w_id][w_sub_id] = Buf
				given_upgrd_list_nb[w_id]++
				w_sub_att_idx = 0
			}
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			BrowseAttListKV(kv, w_id, w_sub_id, w_sub_att_idx, level + 1);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				new attr_id
				KvGetSectionName(kv, Buf, sizeof(Buf));
				//	PrintToServer("section:%s", Buf)
				if (strcmp(Buf, "special_tweaks_listid"))
				{
					KvGetString(kv, "", Buf, 64);
					if (w_sub_id == given_upgrd_classnames_tweak_idx[w_id])
					{
						given_upgrd_classnames_tweak_nb[w_id]++
						if (!GetTrieValue(_spetweaks_names, Buf, attr_id))
						{
							PrintToServer("[uu_lists] Malformated uu_lists | uu_specialtweaks.txt file?: %s was not found", Buf)
						}
					}
					else
					{
						if (!GetTrieValue(_upg_names, Buf, attr_id))
						{
							PrintToServer("[uu_lists] Malformated uu_lists | uu_attributes.txt file?: %s was not found", Buf)
						}
					}
					//		PrintToServer("             **list%d sublist%d %d :%s(%d)", w_sub_att_idx, w_id, w_sub_id, Buf, attr_id)
					given_upgrd_list[w_id][w_sub_id][w_sub_att_idx] = attr_id
					w_sub_att_idx++
				}
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}

BrowseSpeTweaksKV(Handle:kv, &u_id = -1, att_id = -1, level = 0)
{
	decl String:Buf[64];
	new attr_ref
	do
	{
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			u_id++
			SetTrieValue(_spetweaks_names, Buf, u_id)
			upgrades_tweaks[u_id] = Buf
			upgrades_tweaks_nb_att[u_id] = 0
			att_id = 0
		}
		if (level == 3)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if (!GetTrieValue(_upg_names, Buf, attr_ref))
			{
				PrintToServer("[spetw_lists] Malformated uu_specialtweaks | uu_attribute.txt file?: %s was not found", Buf)
			}
			//	PrintToServer("Adding Special tweak [%s] attribute %s(%d)", upgrades_tweaks[u_id], Buf, attr_ref)
			upgrades_tweaks_att_idx[u_id][att_id] = attr_ref
			KvGetString(kv, "", Buf, 64);
			upgrades_tweaks_att_ratio[u_id][att_id] = StringToFloat(Buf)
			//	PrintToServer("               ratio => %f)", upgrades_tweaks_att_ratio[u_id][att_id])
			upgrades_tweaks_nb_att[u_id]++
			att_id++
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseSpeTweaksKV(kv, u_id, att_id, level + 1);
			KvGoBack(kv);
		}
	}
	while (KvGotoNextKey(kv, false));
	return (u_id)
}

public _load_cfg_files()
{
	_upg_names = CreateTrie();
	_weaponlist_names = CreateTrie();
	_spetweaks_names = CreateTrie();

	new Handle:kv = CreateKeyValues("uu_weapons");
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_weapons.txt");
	if (!KvGotoFirstSubKey(kv))
	{
		return false;
	}
	new siz = GetWeaponsCatKVSize(kv)
	PrintToServer("[UberUpgrades] %d weapons loaded", siz)
	KvRewind(kv);
	BrowseWeaponsCatKV(kv)
	CloseHandle(kv);

	kv = CreateKeyValues("attribs");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_attributes.txt");
	_u_id = 0
	PrintToServer("browsin uu attribs (kvh:%d)", kv)
	BrowseAttributesKV(kv)
	PrintToServer("[UberUpgrades] %d attributes loaded", _u_id)
	CloseHandle(kv);

	new static_uid = -1
	kv = CreateKeyValues("special_tweaks");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_specialtweaks.txt");
	BrowseSpeTweaksKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d special tweaks loaded", static_uid)
	CloseHandle(kv);

	static_uid = -1
	kv = CreateKeyValues("lists");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_lists.txt");
	BrowseAttListKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d lists loaded", static_uid)
	CloseHandle(kv);

	newweaponidx[0] = 13;
	newweaponcn[0] = "tf_weapon_scattergun";
	newweaponmenudesc[0] = "Scattergun";

	newweaponidx[1] = 45;
	newweaponcn[1] = "tf_weapon_scattergun";
	newweaponmenudesc[1] = "Force-A-Nature";

	newweaponidx[2] = 220;
	newweaponcn[2] = "tf_weapon_handgun_scout_primary";
	newweaponmenudesc[2] = "The Shortstop";

	newweaponidx[3] = 772;
	newweaponcn[3] = "tf_weapon_pep_brawler_blaster";
	newweaponmenudesc[3] = "Baby Face's Blaster";

	newweaponidx[4] = 18;
	newweaponcn[4] = "tf_weapon_rocketlauncher";
	newweaponmenudesc[4] = "Rocket Launcher";

	newweaponidx[5] = 127;
	newweaponcn[5] = "tf_weapon_rocketlauncher_directhit";
	newweaponmenudesc[5] = "The Direct Hit";

	newweaponidx[6] = 228;
	newweaponcn[6] = "tf_weapon_rocketlauncher";
	newweaponmenudesc[6] = "The Black Box";

	newweaponidx[7] = 414;
	newweaponcn[7] = "tf_weapon_rocketlauncher";
	newweaponmenudesc[7] = "The Libery Launcher";

	newweaponidx[8] = 441;
	newweaponcn[8] = "tf_weapon_particle_cannon";
	newweaponmenudesc[8] = "The Cow Mangler 5000";

	newweaponidx[9] = 730;
	newweaponcn[9] = "tf_weapon_rocketlauncher";
	newweaponmenudesc[9] = "The Begger's Bazooka";

	newweaponidx[10] = 21;
	newweaponcn[10] = "tf_weapon_flamethrower";
	newweaponmenudesc[10] = "Flamethrower";

	newweaponidx[11] = 40;
	newweaponcn[11] = "tf_weapon_flamethrower";
	newweaponmenudesc[11] = "The Backburner";

	newweaponidx[12] = 215;
	newweaponcn[12] = "tf_weapon_flamethrower";
	newweaponmenudesc[12] = "The Degreaser";

	newweaponidx[13] = 594;
	newweaponcn[13] = "tf_weapon_flamethrower";
	newweaponmenudesc[13] = "The Phlogistinator";

	newweaponidx[14] = 19;
	newweaponcn[14] = "tf_weapon_grenadelauncher";
	newweaponmenudesc[14] = "Grenade Launcher";

	newweaponidx[15] = 308;
	newweaponcn[15] = "tf_weapon_grenadelauncher";
	newweaponmenudesc[15] = "The Loch-n-Load";

	newweaponidx[16] = 996;
	newweaponcn[16] = "tf_weapon_cannon";
	newweaponmenudesc[16] = "The Loose Cannon";

	newweaponidx[17] = 15;
	newweaponcn[17] = "tf_weapon_minigun";
	newweaponmenudesc[17] = "Minigun";

	newweaponidx[18] = 298;
	newweaponcn[18] = "tf_weapon_minigun";
	newweaponmenudesc[18] = "Iron Curtain";

	newweaponidx[19] = 312;
	newweaponcn[19] = "tf_weapon_minigun";
	newweaponmenudesc[19] = "The Brass Beast";

	//	newweaponidx[20] = 9;
	//	newweaponcn[20] = "tf_weapon_shotgun";
	//	newweaponmenudesc[20] = "Engineer's Shotgun";

	newweaponidx[20] = 588;
	newweaponcn[20] = "tf_weapon_drg_pomson";
	newweaponmenudesc[20] = "The Pomson 6000";

	newweaponidx[21] = 997;
	newweaponcn[21] = "tf_weapon_shotgun_building_rescue";
	newweaponmenudesc[21] = "The Rescue Ranger";

	newweaponidx[22] = 17;
	newweaponcn[22] = "tf_weapon_syringegun_medic";
	newweaponmenudesc[22] = "Syringe Gun";

	newweaponidx[23] = 36;
	newweaponcn[23] = "tf_weapon_syringegun_medic";
	newweaponmenudesc[23] = "The Blutsauger";

	newweaponidx[24] = 305;
	newweaponcn[24] = "tf_weapon_crossbow";
	newweaponmenudesc[24] = "Crusader's Crossbow";

	newweaponidx[25] = 14;
	newweaponcn[25] = "tf_weapon_sniperrifle";
	newweaponmenudesc[25] = "Sniper Rifle";

	newweaponidx[26] = 56;
	newweaponcn[26] = "tf_weapon_compound_bow";
	newweaponmenudesc[26] = "The Huntsman";

	newweaponidx[27] = 230;
	newweaponcn[27] = "tf_weapon_sniperrifle";
	newweaponmenudesc[27] = "The Sydney Sleeper";

	newweaponidx[28] = 24;
	newweaponcn[28] = "tf_weapon_revolver";
	newweaponmenudesc[28] = "Revolver";

	newweaponidx[29] = 4;
	newweaponcn[29] = "tf_weapon_knife";
	newweaponmenudesc[29] = "Knife";

	newweaponidx[30] = 30;
	newweaponcn[30] = "tf_weapon_invis";
	newweaponmenudesc[30] = "Watch";

	newweaponidx[31] = 29;
	newweaponcn[31] = "tf_weapon_medigun";
	newweaponmenudesc[31] = "Medigun";

	newweaponidx[32] = 357;
	newweaponcn[32] = "tf_weapon_katana";
	newweaponmenudesc[32] = "The Half-Zatoichi";

	newweaponidx[33] = 20;
	newweaponcn[33] = "tf_weapon_pipebomblauncher";
	newweaponmenudesc[33] = "Pipebomb launcher";

	newweaponidx[34] = 58;
	newweaponcn[34] = "tf_weapon_jar";
	newweaponmenudesc[34] = "Jarate";

	//	newweaponidx[36] = 25;
	//	newweaponcn[36] = "tf_weapon_pda_engineer_build";
	//	newweaponmenudesc[36] = "engie pda";



	CreateBuyNewWeaponMenu()
	return true
}stock bool:IsValidClient(client, bool:nobots = true)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false; 
	}
	return IsClientInGame(client); 
}

//Initialize New Weapon menu
public CreateBuyNewWeaponMenu()
{
	BuyNWmenu = CreateMenu(MenuHandler_BuyNewWeapon);
	
	SetMenuTitle(BuyNWmenu, "***Choose additional weapon for 200$:");
	
	for (new i=0; i < NB_B_WEAPONS; i++)
	{
		AddMenuItem(BuyNWmenu, "tweak", newweaponmenudesc[i]);
	}
	SetMenuExitButton(BuyNWmenu, true);
}

//Initialize menus , CVARs, con cmds and timers handlers on plugin load
public UberShopinitMenusHandlers()
{
	LoadTranslations("tf2items_uu.phrases.txt");
	gamemode = -1
	BuyNWmenu_enabled = true
	
	cvar_uu_version = CreateConVar("uberupgrades_version", UU_VERSION, "The Plugin Version. Don't change.", FCVAR_NOTIFY);
	cvar_MoneyBonusKill = 				CreateConVar("sm_uu_moneybonuskill", "100", "Sets the money bonus a client gets for killing: default 100");
	cvar_AutoMoneyForTeamRatio = 			CreateConVar("sm_uu_automoneyforteam_ratio", "1", "If set to 1, the plugin will manage money balancing");
	cvar_StartMoney = 					CreateConVar("sm_uu_startmoney", "1500", "Sets the starting money: default 1500");
	cvar_TimerMoneyGive_BlueTeam = 		CreateConVar("sm_uu_timermoneygive_blueteam", "100", "Sets the money blue team get every timermoney event: default 100");
	cvar_TimerMoneyGive_RedTeam =  		CreateConVar("sm_uu_timermoneygive_redteam", "100", "Sets the money blue team get every timermoney event: default 80");
	MoneyBonusKill = GetConVarInt(cvar_MoneyBonusKill)
	MoneyForTeamRatio[RED]  = 1.0
	MoneyForTeamRatio[BLUE]  = 1.0
	TimerMoneyGive_BlueTeam = GetConVarInt(cvar_TimerMoneyGive_BlueTeam)
	TimerMoneyGive_RedTeam = GetConVarInt(cvar_TimerMoneyGive_RedTeam)
	StartMoney = GetConVarInt(cvar_StartMoney)
	if (cvar_uu_version) //Compile warning fast bypass
	{
	}	
	
	RegAdminCmd("sm_wipeall", Command_wipeall, ADMFLAG_SLAY, "Remove all Uber Upgrades from Target");
	RegConsoleCmd("sm_refund", Command_Refund)

	RegConsoleCmd("uuhelp", Disp_Help)
	RegAdminCmd("us_enable_buy_new_weapon", EnableBuyNewWeapon, ADMFLAG_GENERIC)
	RegAdminCmd("sm_uuspentmoney", ShowSpentMoney, ADMFLAG_GENERIC)
	RegAdminCmd("reload_cfg", ReloadCfgFiles, ADMFLAG_GENERIC)
	RegAdminCmd("resetuu", ReloadCfgFiles, ADMFLAG_GENERIC)	
	RegConsoleCmd("uu", Disp_Help)
	RegConsoleCmd("nohelp", StopDisp_chatHelp)
	RegConsoleCmd("uudteamup", Toggl_DispTeamUpgrades)
	RegConsoleCmd("uu_no", Toggl_DispTeamUpgrades)
	RegConsoleCmd("uuaide", Disp_Help)
	RegConsoleCmd("aide", Disp_Help)
	RegConsoleCmd("buy", Menu_BuyUpgrade)
	RegConsoleCmd("qbuy", Menu_QuickBuyUpgrade2)
	RegConsoleCmd("upgrade", Menu_BuyUpgrade)
	RegConsoleCmd("BUY", Menu_BuyUpgrade)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("teamplay_round_start", Event_RoundStart)
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre)
	HookEvent("player_changeclass", Event_PlayerChangeClass)
	HookEvent("player_class", Event_PlayerChangeClass)
	HookEvent("player_team", Event_PlayerChangeTeam)
	AddCommandListener(jointeam_callback, "jointeam");
	//HookEvent("item_pickup", Event_PlayerreSpawn)
	//HookEvent("mm_lobby_member_join", OnClientPutInServer)
	HookEvent("mvm_begin_wave", Event_mvm_begin_wave)
	HookEvent("mvm_wave_complete", Event_mvm_wave_complete)
	HookEvent("teamplay_round_win", Event_teamplay_round_win)
	
	Timers_[0] = CreateTimer(20.0, Timer_GetConVars, _, TIMER_REPEAT);
	Timers_[1] = CreateTimer(20.0, Timer_GiveSomeMoney, _, TIMER_REPEAT);
	Timers_[2] = CreateTimer(1.0, Timer_PrintMoneyHud, _, TIMER_REPEAT);
	
	moneyLevels[0] = 125;
	for (new level = 1; level < MAXLEVEL_D; level++)
	{
		moneyLevels[level] = (125 + ((level + 1) * 50)) + moneyLevels[level - 1];
	}
}

//Initialize menus , CVARs, con cmds and timers handlers on plugin load
public UberShopUnhooks()
{

	UnhookEvent("post_inventory_application", Event_PlayerreSpawn)
	UnhookEvent("player_spawn", Event_PlayerreSpawn)
	UnhookEvent("teamplay_round_start", Event_RoundStart)
	
	UnhookEvent("player_death", Event_PlayerDeath)
	UnhookEvent("player_changeclass", Event_PlayerChangeClass)
	UnhookEvent("player_class", Event_PlayerChangeClass)
	UnhookEvent("player_team", Event_PlayerChangeTeam)
	
	UnhookEvent("mvm_begin_wave", Event_mvm_begin_wave)
	
	UnhookEvent("mvm_wave_complete", Event_mvm_wave_complete)
	UnhookEvent("teamplay_round_win", Event_teamplay_round_win)
	
	KillTimer(Timers_[0]);
	KillTimer(Timers_[1]);
	KillTimer(Timers_[2]);
}

public GetUpgrade_CatList(String:WCName[])
{
	new i, wis, w_id
	
	wis = 0// wcname_idx_start[cl_class]
	//PrintToChatAll("Class: %d; WCname:%s", cl_class, WCName);
	for (i = wis, w_id = -1; i < WCNAMELISTSIZE; i++)
	{
		if (!strcmp(wcnamelist[i], WCName, false))
		{
			w_id = wcname_l_idx[i]
			//PrintToChatAll("wid found; %d", w_id)
			return w_id
		}
	}
	if (w_id < -1)
	{
		PrintToServer("UberUpgrade error: #%s# was not a valid weapon classname..", WCName)
	}
	return w_id
}

public void OnPluginStart()
{
	UberShopinitMenusHandlers()

	UberShopDefineUpgradeTabs()
	
	for (new client = 0; client < MAXPLAYERS + 1; client++)
	{
		if (IsValidClient(client))
		{
			client_no_d_team_upgrade[client] = 1
			client_no_showhelp[client] = 0
			ResetClientUpgrades(client)
			current_class[client] = _:TF2_GetPlayerClass(client)
			//PrintToChat(client, "client changeclass");
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
			}
		}	
	}
}

public OnMapEnd()
{
	UberShopUnhooks()
}

public Action:Timer_PrintMoneyHud(Handle:timer)
{
	for (new i = 1; i < MAXPLAYERS + 1; i++)
	{
		if (IsValidClient(i))
		{
			decl String:Buffer[12]
			Format(Buffer, sizeof(Buffer), "%d$", client_iCash[i]); 
			SetHudTextParams(0.9, 0.8, 1.0, 255,0,0,255);
			ShowHudText(i, -1, Buffer);
		}
	}
}

/*player_spawn
Scout, Soldier, Pyro, DemoMan, Heavy, Medic, Sniper: 
[code]0 - Primary 1 - Secondary 2 - Melee[/code] 
Engineer: 
[code]0 - Primary 1 - Secondary 2 - Melee 3 - Construction PDA 4 - Destruction PDA 5 - Building[/code] 
Spy: 
[code]0 - Secondary 1 - Sapper 2 - Melee 3 - Disguise Kit 4 - Invisibility Watch[/code]
*/

public bool:GiveNewWeapon(client, slot)
{
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	new Flags = 0;
	
	new itemDefinitionIndex = currentitem_idx[client][slot]
	TF2Items_SetItemIndex(newItem, itemDefinitionIndex);
	currentitem_level[client][slot] = 242
	
	TF2Items_SetLevel(newItem, 242);
	
	Flags |= PRESERVE_ATTRIBUTES;
	
	TF2Items_SetFlags(newItem, Flags);
	
	TF2Items_SetClassname(newItem, currentitem_classname[client][slot]);
	
	slot = 6
	new weaponIndextorem_ = GetPlayerWeaponSlot(client, slot);
	new weaponIndextorem = weaponIndextorem_;
	
	
	new entity = TF2Items_GiveNamedItem(client, newItem);
	if (IsValidEntity(entity))
	{
		while ((weaponIndextorem = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			RemovePlayerItem(client, weaponIndextorem);
			RemoveEdict(weaponIndextorem);
		}
		client_new_weapon_ent_id[client] = entity
		EquipPlayerWeapon(client, entity);
		return true;
	}
	else
	{
		return false
	}
}

public GiveNewUpgrade(client, slot, uid, a)
{
	//new itemDefinitionIndex = currentitem_idx[client][slot]
	
	//	PrintToChatAll("--Give new upgrade", slot);
	new iEnt;
	if (slot == 4 && IsValidEntity(client))
	{
		iEnt = client
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot]
	}
	else
	{
		slot = 3
		iEnt = client_new_weapon_ent_id[client]
	}
	if (IsValidEntity(iEnt) && strcmp(upgradesWorkNames[upgrades_to_a_id[uid]], ""))
	{
		//PrintToChatAll("trytoremov slot %d", slot);
		TF2Attrib_SetByName(iEnt, upgradesWorkNames[upgrades_to_a_id[uid]],
		currentupgrades_val[client][slot][a]);
		
		//TF2Attrib_ClearCache(iEnt)
	}
}

public GiveNewUpgradedWeapon_(client, slot)
{
	//new itemDefinitionIndex = currentitem_idx[client][slot]
	
	new a, iNumAttributes;
	new iEnt;
	iNumAttributes = currentupgrades_number[client][slot]
	if (slot == 4 && IsValidEntity(client))
	{
		iEnt = client
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot]
	}
	else
	{
		slot = 3
		iEnt = client_new_weapon_ent_id[client]
	}
	if (IsValidEntity(iEnt))
	{
		//PrintToChatAll("trytoremov slot %d", slot);
		Address pEntAttributeList = GetTheEntityAttributeList(iEnt);
		
		if (pEntAttributeList && iNumAttributes > 0 )
		{
			for( a = 0; a < 42 && a < iNumAttributes ; a++ )
			{
				new uuid = upgrades_to_a_id[
				currentupgrades_idx[client][slot][a]]
				if (strcmp(upgradesWorkNames[uuid], ""))
				{
					TF2Attrib_SetByName(iEnt, upgradesWorkNames[uuid],
					currentupgrades_val[client][slot][a]);
				}
			}
		}
		TF2Attrib_ClearCache(iEnt)
	}
}

public	is_client_got_req(mclient, upgrade_choice, slot, inum)
{
	int iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency");
	int up_cost = upgrades_costs[upgrade_choice]
	int max_ups = currentupgrades_number[mclient][slot]
	up_cost /= 2
	client_iCash[mclient] = iCash;
	if (slot == 1)
	{
		up_cost = RoundToFloor((up_cost * 1.0) * 0.75)
	}
	if (inum != 9999 && upgrades_ratio[upgrade_choice])
	{
		up_cost += RoundToFloor(up_cost * (
		(currentupgrades_val[mclient][slot][inum] - upgrades_i_val[upgrade_choice])
		/ upgrades_ratio[upgrade_choice]) 
		* upgrades_costs_inc_ratio[upgrade_choice])
		if (up_cost < 0.0)
		{
			up_cost *= -1;
			if (up_cost < (upgrades_costs[upgrade_choice] / 2))
			{
				up_cost = upgrades_costs[upgrade_choice] / 2
			}
		}
	}
	if (iCash < up_cost)
	{
		char buffer[64]
		Format(buffer, sizeof(buffer), "%T", "Not enough money!!", mclient);
		PrintToChat(mclient, buffer);
		return 0
	}
	else
	{
		if (inum != 9999)
		{	
			if (currentupgrades_val[mclient][slot][inum] == upgrades_m_val[upgrade_choice])
			{
				PrintToChat(mclient, "You already have reached the maximum upgrade for this category.");
				return 0
			}
		}
		else
		{
			if (max_ups >= MAX_ATTRIBUTES_ITEM)
			{
				PrintToChat(mclient, "You have reached the maximum number of upgrade category for this item.");
				return 0
			}
		}
		
		client_iCash[mclient] = iCash - up_cost
		SetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
		client_spent_money[mclient][slot] += up_cost
		int totalmoney = 0
		for (int s = 0; s < 5; s++)
		{
			totalmoney += client_spent_money[mclient][s]
		}
		int ctr_m = clientLevels[mclient]
		
		while (ctr_m < MAXLEVEL_D && totalmoney > moneyLevels[ctr_m])
		{
			ctr_m++
		}
		if (ctr_m != clientLevels[mclient])
		{
			clientLevels[mclient] = ctr_m
			char clname[255]
			char strsn[12]
			if (ctr_m == MAXLEVEL_D)
			{
				strsn = "[_over9000]"
			}
			else
			{
				Format(strsn, sizeof(strsn), "[Lvl %d]", ctr_m + 1)
			}
			Format(clname, sizeof(clname), "%s%s", strsn, clientBaseName[mclient])
			SetClientInfo(mclient, "name", clname);
		}
		return 1
	}
}

public	check_apply_maxvalue(mclient, slot, inum, upgrade_choice)
{
	if ((upgrades_ratio[upgrade_choice] > 0.0
				&& currentupgrades_val[mclient][slot][inum] > upgrades_m_val[upgrade_choice])
			|| (upgrades_ratio[upgrade_choice] < 0.0 
				&& currentupgrades_val[mclient][slot][inum] < upgrades_m_val[upgrade_choice]))
	{
		currentupgrades_val[mclient][slot][inum] = upgrades_m_val[upgrade_choice]
	}
}

public UpgradeItem(mclient, upgrade_choice, inum, Float:ratio)
{
	new slot = current_slot_used[mclient]
	//PrintToChat(mclient, "Entering #upprimary");
	
	
	if (inum == 9999)
	{
		inum = currentupgrades_number[mclient][slot]
		upgrades_ref_to_idx[mclient][slot][upgrade_choice] = inum;
		currentupgrades_idx[mclient][slot][inum] = upgrade_choice 
		currentupgrades_val[mclient][slot][inum] = upgrades_i_val[upgrade_choice];
		currentupgrades_number[mclient][slot] = currentupgrades_number[mclient][slot] + 1
		currentupgrades_val[mclient][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
	}
	else
	{
		currentupgrades_val[mclient][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
		check_apply_maxvalue(mclient, slot, inum, upgrade_choice)
	}
	client_last_up_idx[mclient] = upgrade_choice
	client_last_up_slot[mclient] = slot
}

public ResetClientUpgrade_slot(client, slot)
{
	int i
	int iNumAttributes = currentupgrades_number[client][slot]
	
	if (client_spent_money[client][slot])
	{
		int iCash = GetEntProp(client, Prop_Send, "m_nCurrency");
		SetEntProp(client, Prop_Send, "m_nCurrency", iCash + client_spent_money[client][slot]);
	}
	currentitem_level[client][slot] = 0
	client_spent_money[client][slot] = 0
	client_spent_money_mvm_chkp[client][slot] = 0
	currentupgrades_number[client][slot] = 0

	for (i = 0; i < iNumAttributes; i++)
	{
		upgrades_ref_to_idx[client][slot][currentupgrades_idx[client][slot][i]] = 9999
	}

	if (slot != 4 && currentitem_idx[client][slot])
	{
		currentitem_idx[client][slot] = 9999
		GiveNewUpgradedWeapon_(client, slot)
	}

	if (slot == 3 && client_new_weapon_ent_id[client])
	{
		currentitem_idx[client][3] = 9999
		currentitem_ent_idx[client][3] = -1
		GiveNewUpgradedWeapon_(client, slot)
		client_new_weapon_ent_id[client] = 0;
	}
	if (slot == 4)
	{
		GiveNewUpgradedWeapon_(client, slot)
	}
	int totalmoney = 0
	for (int s = 0; s < 5; s++)
	{
		totalmoney += client_spent_money[client][s]
	}
	int ctr_m = clientLevels[client]
	
	while (ctr_m && totalmoney < moneyLevels[ctr_m])
	{
		ctr_m--
	}
	if (ctr_m != clientLevels[client])
	{
		clientLevels[client] = ctr_m
		char strsn[12]
		char clname[255]
		if (ctr_m == MAXLEVEL_D)
		{
			strsn = "[_over9000]"
		}
		else
		{
			Format(strsn, sizeof(strsn), "[Lvl %d]", ctr_m + 1)
		}
		Format(clname, sizeof(clname), "%s%s", strsn, clientBaseName[client])
		SetClientInfo(client, "name", clname);
	}
}

public ResetClientUpgrades(client)
{
	int slot
	
	client_respawn_handled[client] = 0
	for (slot = 0; slot < NB_SLOTS_UED; slot++)
	{
		ResetClientUpgrade_slot(client, slot)
		//PrintToChatAll("reset all upgrade slot %d", slot)
	}
	Address pEntAttributeList = GetTheEntityAttributeList(client);
	if (pEntAttributeList)
	{
		TF2Attrib_RemoveAll(client);
	}
}


public DefineAttributesTab(client, itemidx, slot)
{	
	if (currentitem_idx[client][slot] == 9999)
	{
		new a, a2, i, a_i
		
		currentitem_idx[client][slot] = itemidx
		new inumAttr = TF2II_GetItemNumAttributes( itemidx );
		for( a = 0, a2 = 0; a < inumAttr && a < 42; a++ )
		{
			decl String:Buf[64]
			a_i = TF2II_GetItemAttributeID( itemidx, a);
			TF2II_GetAttribName( a_i, Buf, 64);

			if (GetTrieValue(_upg_names, Buf, i))
			{
				currentupgrades_idx[client][slot][a2] = i
				
				upgrades_ref_to_idx[client][slot][i] = a2;
				currentupgrades_val[client][slot][a2] = TF2II_GetItemAttributeValue( itemidx, a );
				a2++
			}
		}
		currentupgrades_number[client][slot] = a2
	}
	else
	{
		if (itemidx > 0 && itemidx != currentitem_idx[client][slot])
		{
			ResetClientUpgrade_slot(client, slot)
			new a, a2, i, a_i
			
			currentitem_idx[client][slot] = itemidx
			new inumAttr = TF2II_GetItemNumAttributes( itemidx );
			for( a = 0, a2 = 0; a < inumAttr && a < 42; a++ )
			{
				decl String:Buf[64]
				a_i = TF2II_GetItemAttributeID( itemidx, a);
				TF2II_GetAttribName( a_i, Buf, 64);

				if (GetTrieValue(_upg_names, Buf, i))
				{
					currentupgrades_idx[client][slot][a2] = i
					
					upgrades_ref_to_idx[client][slot][i] = a2;
					currentupgrades_val[client][slot][a2] = TF2II_GetItemAttributeValue( itemidx, a );
					//PrintToChat(client, "init-attribute-%d [%d ; %f]", itemidx, i, currentupgrades_val[client][slot][a]);
					a2++
				}
			}
			currentupgrades_number[client][slot] = a2
		}
	}
}


public	Menu_TweakUpgrades(mclient)
{
	new Handle:menu = CreateMenu(MenuHandler_AttributesTweak);
	new s
	
	SetMenuTitle(menu, "Display Upgrades/Remove downgrades");
	for (s = 0; s < 5; s++)
	{
		decl String:fstr[100]
		
		Format(fstr, sizeof(fstr), "%d$ of upgrades) Modify/Remove my %s attributes", client_spent_money[mclient][s], current_slot_name[s])
		AddMenuItem(menu, "tweak", fstr);
	}
	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		DisplayMenu(menu, mclient, 20);
	}
}

public	Menu_TweakUpgrades_slot(mclient, arg)
{
	if (arg > -1 && arg < 5
			&& IsValidClient(mclient) 
			&& IsPlayerAlive(mclient))
	{
		new Handle:menu = CreateMenu(MenuHandler_AttributesTweak_action);
		new i, s
		
		s = arg;
		current_slot_used[mclient] = s;
		SetMenuTitle(menu, "%d$ ***%s - Choose attribute:", client_iCash[mclient], current_slot_name[s]);
		decl String:buf[64]
		decl String:fstr[255]
		for (i = 0; i < currentupgrades_number[mclient][s]; i++)
		{
			new u = currentupgrades_idx[mclient][s][i]
			Format(buf, sizeof(buf), "%T", upgradesNames[u], mclient)
			if (upgrades_costs[u] < -0.0001)
			{
				Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f\n%d", buf, currentupgrades_val[mclient][s][i], 
				RoundToFloor(upgrades_costs[u] * ((upgrades_i_val[u] - currentupgrades_val[mclient][s][i]) / upgrades_ratio[u]) * 3))
			}
			else
			{
				Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f", buf, currentupgrades_val[mclient][s][i])
			}
			AddMenuItem(menu, "yep", fstr);
		}
		if (IsValidClient(mclient) && IsPlayerAlive(mclient))
		{
			DisplayMenu(menu, mclient, 20);
		}
	}
}

public remove_attribute(client, inum)
{
	new slot = current_slot_used[client];

	currentupgrades_val[client][slot][inum] = upgrades_i_val[currentupgrades_idx[client][slot][inum]];
	
	GiveNewUpgradedWeapon_(client, slot)
}



//menubuy 3- choose the upgrade
public Action:Menu_SpecialUpgradeChoice(client, cat_choice, String:TitleStr[100], selectidx)
{
	int i, j

	Handle menu = CreateMenu(MenuHandler_SpecialUpgradeChoice);
	SetMenuPagination(menu, 2);
	if (cat_choice != -1)
	{
		char desc_str[512]
		int w_id = current_w_list_id[client]
		int tmp_up_idx
		int tmp_spe_up_idx
		int tmp_ref_idx
		float tmp_val
		float tmp_ratio
		int slot
		char plus_sign[2]
		char buft[64]
		
		current_w_c_list_id[client] = cat_choice
		slot = current_slot_used[client]
		for (i = 0; i < given_upgrd_classnames_tweak_nb[w_id]; i++)
		{
			tmp_spe_up_idx = given_upgrd_list[w_id][cat_choice][i]
			Format(buft, sizeof(buft), "%T",  upgrades_tweaks[tmp_spe_up_idx], client)
			//PrintToChat(client, "--->special ID", tmp_spe_up_idx);	
			desc_str = buft;
			for (j = 0; j < upgrades_tweaks_nb_att[tmp_spe_up_idx]; j++)
			{
				tmp_up_idx = upgrades_tweaks_att_idx[tmp_spe_up_idx][j]
				tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx]
				if (tmp_ref_idx != 9999)
				{	
					tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
				}
				else
				{
					tmp_val = 0.0
				}
				tmp_ratio = upgrades_ratio[tmp_up_idx]
				if (tmp_ratio > 0.0)
				{
					plus_sign = "+"
				}
				else
				{
					tmp_ratio *= -1.0
					plus_sign = "-"
				}
				char buf[64]
				Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client)
				if (tmp_ratio < 0.99)
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j]
					Format(desc_str, sizeof(desc_str), "%s\n%\t-%s\n\t\t\t%s%i%%\t(%i%%)",
					desc_str, buf,
					plus_sign, RoundToFloor(tmp_ratio * 100), RoundToFloor(tmp_val * 100))
				}
				else
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j]
					Format(desc_str, sizeof(desc_str), "%s\n\t-%s\n\t\t\t%s%3i\t(%i)",
					desc_str, buf,
					plus_sign, RoundToFloor(tmp_ratio), RoundToFloor(tmp_val))
				}
			}
			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, selectidx, 30);
}



public MenuHandler_SpecialUpgradeChoice(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[mclient] = 0
		new String:fstr[100]
		new got_req = 1
		new slot = current_slot_used[mclient]
		new w_id = current_w_list_id[mclient]
		new cat_id = current_w_c_list_id[mclient]
		new spTweak = given_upgrd_list[w_id][cat_id][param2]
		for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
		{
			new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
			new inum = upgrades_ref_to_idx[mclient][slot][upgrade_choice]
			if (inum != 9999)
			{
				if (currentupgrades_val[mclient][slot][inum] == upgrades_m_val[upgrade_choice])
				{
					PrintToChat(mclient, "You already have reached the maximum upgrade for this tweak.");
					got_req = 0
				}
			}
			else
			{
				if (currentupgrades_number[mclient][slot] + upgrades_tweaks_nb_att[spTweak] >= MAX_ATTRIBUTES_ITEM)
				{
					PrintToChat(mclient, "Not enough upgrade category slots for this tweak.");
					got_req = 0
				}
			}
			
			
		}
		if (got_req)
		{
			decl String:clname[255]
			GetClientName(mclient, clname, sizeof(clname))
			for (new i = 1; i < MAXPLAYERS + 1; i++)
			{
				if (IsValidClient(i) && !client_no_d_team_upgrade[i])
				{
					PrintToChat(i,"%s : [%s tweak] - %s!", 
					clname, upgrades_tweaks[spTweak], current_slot_name[slot]);
				}
			}
			for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
			{
				new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
				UpgradeItem(mclient, upgrade_choice, upgrades_ref_to_idx[mclient][slot][upgrade_choice], 
				upgrades_tweaks_att_ratio[spTweak][i])
			}
			GiveNewUpgradedWeapon_(mclient, slot)
			new String:buf[32]
			Format(buf, sizeof(buf), "%T", current_slot_name[slot], mclient);
			Format(fstr, sizeof(fstr), "%d$ [%s] - %s", client_iCash[mclient], buf, 
			given_upgrd_classnames[w_id][cat_id])
			Menu_SpecialUpgradeChoice(mclient, cat_id, fstr, GetMenuSelectionPosition())
		}
		//PrintToChat(mclient, "#MENU UPC FSTR=%s", fstr);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public MenuHandler_AttributesTweak_action(Handle:menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		int s = current_slot_used[client]
		if (s >= 0 && s < 4 && param2 < MAX_ATTRIBUTES_ITEM)
		{
			if (param2 >= 0)
			{
				int u = currentupgrades_idx[client][s][param2]
				if (u != 9999)
				{
					if (upgrades_costs[u] < -0.0001)
					{
						int iCash = GetEntProp(client, Prop_Send, "m_nCurrency");
						int nb_time_upgraded = RoundToFloor((upgrades_i_val[u] - currentupgrades_val[client][s][param2]) / upgrades_ratio[u])
						int up_cost = upgrades_costs[u] * nb_time_upgraded * 3
						if (iCash >= up_cost)
						{
							
							remove_attribute(client, param2)
							SetEntProp(client, Prop_Send, "m_nCurrency", iCash - up_cost);
							client_iCash[client] = iCash;
							client_spent_money[client][s] += up_cost
							char buffer[80];
							Format(buffer, sizeof(buffer), "%T", "Attribute removed", client, current_slot_name[s], upgradesNames[u]);
							PrintToChat(client,"%s", buffer);
						}
						else
						{
							char buffer[64]
							Format(buffer, sizeof(buffer), "%T", "Not enough money!!", client);
							PrintToChat(client, buffer);
						}
					}
					else
					{
						PrintToChat(client,"Nope.")
					}
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


//menubuy 1-chose the item attribute to tweak
public MenuHandler_AttributesTweak(Handle:menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		Menu_TweakUpgrades_slot(client, param2)
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//cl command to display current item attributes tables
public	DisplayCurrentUps(mclient)
{
	new i, s
	PrintToChat(mclient, "***Current attributes:");
	for (s = 0; s < 4; s++)
	{
		PrintToChat(mclient, "[%s]:", current_slot_name[s]);
		for (i = 0; i < currentupgrades_number[mclient][s]; i++)
		{
			PrintToChat(mclient, "%s: %10.2f", upgradesNames[currentupgrades_idx[mclient][s][i]], currentupgrades_val[mclient][s][i]);
		}
	}
}


public	Menu_BuyNewWeapon(mclient)
{

	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		DisplayMenu(BuyNWmenu, mclient, 20);
	}
}


//menubuy 2- choose the category of upgrades
public Action:Menu_ChooseCategory(client, String:TitleStr[64])
{
	//	PrintToChat(client, "Entering menu_chscat");
	new i
	new w_id
	
	new Handle:menu = CreateMenu(MenuHandler_Choosecat);
	new slot = current_slot_used[client];
	if (slot != 4)
	{
		w_id = currentitem_catidx[client][slot];
	}
	else
	{
		w_id = current_class[client] - 1;
	}
	if (w_id >= 0)
	{
		current_w_list_id[client] = w_id
		new String:buf[64]
		for (i = 0; i < given_upgrd_list_nb[w_id]; i++)
		{
			Format(buf, sizeof(buf), "%T", given_upgrd_classnames[w_id][i], client)
			AddMenuItem(menu, "upgrade", buf);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(menu, client, 20);
	}
}

public isValidVIP(client)
{
	new flags = GetUserFlagBits (client) 
	return (flags & ADMFLAG_CUSTOM1 )
}

//menubuy 3- choose the upgrade
public Action:Menu_UpgradeChoice(client, cat_choice, String:TitleStr[100])
{
	int i

	Handle menu = CreateMenu(MenuHandler_UpgradeChoice);
	if (cat_choice != -1)
	{
		int w_id = current_w_list_id[client]

		char desc_str[255]
		int tmp_up_idx
		int tmp_ref_idx
		int up_cost
		float tmp_val
		float tmp_ratio
		int slot
		char plus_sign[2]
		current_w_c_list_id[client] = cat_choice
		slot = current_slot_used[client]
		for (i = 0; (tmp_up_idx = given_upgrd_list[w_id][cat_choice][i]); i++)
		{
			up_cost = upgrades_costs[tmp_up_idx] / 2
			if (slot == 1)
			{
				up_cost = RoundToFloor((up_cost * 1.0) * 0.75)
			}
			tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx]
			if (tmp_ref_idx != 9999)
			{	
				tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
			}
			else
			{
				tmp_val = 0.0
			}
			tmp_ratio = upgrades_ratio[tmp_up_idx]
			if (tmp_val && tmp_ratio)
			{
				up_cost += RoundToFloor(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx])
				if (up_cost < 0.0)
				{
					up_cost *= -1;
					if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
					{
						up_cost = upgrades_costs[tmp_up_idx] / 2
					}
				}
			}
			if (tmp_ratio > 0.0)
			{
				plus_sign = "+"
			}
			else
			{
				tmp_ratio *= -1.0
				plus_sign = "-"
			}
			new String:buf[64]
			Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client)
			if (tmp_ratio < 0.99)
			{
				Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%i%%\t(%i%%)",
				up_cost, buf,
				plus_sign, RoundToFloor(tmp_ratio * 100), ((RoundToFloor(tmp_val * 100) / 5) * 5))
			}
			else
			{
				Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%3i\t(%i)",
				up_cost, buf,
				plus_sign, RoundToFloor(tmp_ratio), RoundToFloor(tmp_val))
			}
			
			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
}


//menubuy 1-chose the item category of upgrade
public Action:Menu_BuyUpgrade(client, args)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		new String:buffer[64];
		menuBuy = CreateMenu(MenuHandler_BuyUpgrade);
		SetMenuTitle(menuBuy, "****UberUpgrades");
		Format(buffer, sizeof(buffer), "%T", "Body upgrade", client);
		AddMenuItem(menuBuy, "upgrade_player", buffer);
		
		Format(buffer, sizeof(buffer), "%T", "Upgrade my primary weapon", client);
		AddMenuItem(menuBuy, "upgrade_primary", buffer);
		
		Format(buffer, sizeof(buffer), "%T", "Upgrade my secondary weapon", client);
		AddMenuItem(menuBuy, "upgrade_secondary", buffer);
		
		Format(buffer, sizeof(buffer), "%T", "Upgrade my melee weapon", client);
		AddMenuItem(menuBuy, "upgrade_melee", buffer);
		
		AddMenuItem(menuBuy, "upgrade_dispcurrups", "Display Upgrades/Remove downgrades");
		if (!BuyNWmenu_enabled)
		{
			Format(buffer, sizeof(buffer), "%T", "Buy a neeew weapon!!", client);
			AddMenuItem(menuBuy, "upgrade_buyoneweap", buffer);
			if (currentitem_level[client][3] == 242)
			{
				Format(buffer, sizeof(buffer), "%T", "Upgrade my neeew weapon!!", client);
				AddMenuItem(menuBuy, "upgrade_buyoneweap", buffer);
			}
		}
		SetMenuExitButton(menuBuy, true);
		DisplayMenu(menuBuy, client, 20);
	}
}


//menubuy 3-Handler
public MenuHandler_BuyNewWeapon(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		int iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency");
		if (iCash > 200)
		{
			if (currentitem_idx[mclient][3])
			{
				PrintToChat(mclient, "You already have that weapon")
			}
			ResetClientUpgrade_slot(mclient, 3)
			currentitem_idx[mclient][3] = newweaponidx[param2];
			currentitem_classname[mclient][3] = newweaponcn[param2];
			SetEntProp(mclient, Prop_Send, "m_nCurrency", iCash - 200);
			client_spent_money[mclient][3] = 200;
			//PrintToChat(mclient, "You will have it next spawn.")
			GiveNewWeapon(mclient, 3)
		}
		else
		{
			char buffer[64]
			Format(buffer, sizeof(buffer), "%T", "Not enough money!!", mclient);
			PrintToChat(mclient, buffer);
		}
	}
}


public MenuHandler_AccessDenied(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToChat(mclient, "This feature is donators/VIPs only")
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//menubuy 3-Handler
public MenuHandler_UpgradeChoice(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[mclient] = 0
		int slot = current_slot_used[mclient]
		int w_id = current_w_list_id[mclient]
		int cat_id = current_w_c_list_id[mclient]
		int upgrade_choice = given_upgrd_list[w_id][cat_id][param2]
		int inum = upgrades_ref_to_idx[mclient][slot][upgrade_choice]

		if (is_client_got_req(mclient, upgrade_choice, slot, inum))
		{
			UpgradeItem(mclient, upgrade_choice, inum, 1.0)
			GiveNewUpgradedWeapon_(mclient, slot)
		}
		char fstr2[100]
		char fstr[40]
		char fstr3[20]
		if (slot != 4)
		{
			Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[w_id][cat_id], 
			mclient)
			Format(fstr3, sizeof(fstr3), "%t", current_slot_name[slot], mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
			fstr)
		}
		else
		{
			Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[current_class[mclient] - 1][cat_id], 
			mclient)
			Format(fstr3, sizeof(fstr3), "%t", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
			fstr)
		}
		SetMenuTitle(menu, fstr2);
		char desc_str[255]
		int tmp_up_idx
		int tmp_ref_idx
		int up_cost
		float tmp_val
		float tmp_ratio
		char plus_sign[2]
		
		tmp_up_idx = given_upgrd_list[w_id][cat_id][param2]
		up_cost = upgrades_costs[tmp_up_idx] / 2
		if (slot == 1)
		{
			up_cost = RoundToFloor((up_cost * 1.0) * 0.75)
		}
		tmp_ref_idx = upgrades_ref_to_idx[mclient][slot][tmp_up_idx]
		if (tmp_ref_idx != 9999)
		{	
			tmp_val = currentupgrades_val[mclient][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
		}
		else
		{
			tmp_val = 0.0
		}
		tmp_ratio = upgrades_ratio[tmp_up_idx]
		if (tmp_val && tmp_ratio)
		{
			up_cost += RoundToFloor(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx])
			if (up_cost < 0.0)
			{
				up_cost *= -1;
				if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
				{
					up_cost = upgrades_costs[tmp_up_idx] / 2
				}
			}
		}
		if (tmp_ratio > 0.0)
		{
			plus_sign = "+"
		}
		else
		{
			tmp_ratio *= -1.0
			plus_sign = "-"
		}
		char buf[64]
		Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], mclient)
		if (tmp_ratio < 0.99)
		{
			Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%i%%\t(%i%%)",
			up_cost, buf,
			plus_sign, RoundToFloor(tmp_ratio * 100), ((RoundToFloor(tmp_val * 100) / 5) * 5))
		}
		else
		{
			Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%3i\t(%i)",
			up_cost, buf,
			plus_sign, RoundToFloor(tmp_ratio), RoundToFloor(tmp_val))
		}
		
		
		InsertMenuItem(menu, param2, "upgrade", desc_str);
		RemoveMenuItem(menu, param2 + 1);
		DisplayMenuAtItem(menu, mclient, GetMenuSelectionPosition(), 20)
		
	}
}


//menubuy 2- Handler
public MenuHandler_BodyUpgrades(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		
		Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[current_class[mclient] - 1][param2], 
		mclient)
		Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient)
		Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
		fstr)

		Menu_UpgradeChoice(mclient, param2, fstr2)
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SpeMenubuy(Handle:menu, MenuAction:action, mclient, param2)
{
	CloseHandle(menu);
}

public MenuHandler_Choosecat(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		new slot = current_slot_used[mclient]
		new cat_id = currentitem_catidx[mclient][slot]
		if (slot == 4)
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[current_class[mclient] - 1][param2], 
			mclient)
			Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3,
			fstr)
			Menu_UpgradeChoice(mclient, param2, fstr2)
		}
		else
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], mclient)
			Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [%s] - %s", client_iCash[mclient], fstr3, 
			fstr)
			if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
			{
				Menu_SpecialUpgradeChoice(mclient, param2, fstr2,0)
			}
			else
			{
				Menu_UpgradeChoice(mclient, param2, fstr2)
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public MenuHandler_BuyUpgrade(Handle:menu, MenuAction:action, mclient, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			decl String:fstr[30]
			decl String:fstr2[64]
			current_slot_used[mclient] = 4;
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr, sizeof(fstr), "%T", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%d$ [ - %s - ]", client_iCash[mclient], fstr)
			Menu_ChooseCategory(mclient, fstr2)
		}
		else if (param2 == 4)
		{
			Menu_TweakUpgrades(mclient);
		}
		else if (param2 == 5)
		{
			Menu_BuyNewWeapon(mclient);
		}
		else if (param2 == 6)
		{
			decl String:fstr[30]
			decl String:fstr2[64]
			current_slot_used[mclient] = 3
			
			Format(fstr, sizeof(fstr), "%T", "Body upgrade", mclient)
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr2, sizeof(fstr2), "%d$ [ - Upgrade %s - ]", client_iCash[mclient]
			,fstr)
			Menu_ChooseCategory(mclient, fstr2)
		}
		else
		{
			decl String:fstr[30]
			decl String:fstr2[64]
			param2 -= 1
			current_slot_used[mclient] = param2
			Format(fstr, sizeof(fstr), "%T", current_slot_name[param2], mclient)
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr2, sizeof(fstr2), "%d$ [ - Upgrade %s - ]", client_iCash[mclient]
			,fstr)
			Menu_ChooseCategory(mclient, fstr2)
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public ConnectDB()
{
	new String:error_[255]
	db = SQL_DefConnect(error_, sizeof(error_))

	if (db == INVALID_HANDLE)
	{
		PrintToServer("Could not connect: %s", error_)
	} else {
		CloseHandle(db)
	}
	
	new Handle:query = SQL_Query(db, "SELECT lastname FROM hlstats_Players ORDER BY skill DESC LIMIT 10")
	if (query == INVALID_HANDLE)
	{
		SQL_GetError(db, error_, sizeof(error_))
		PrintToServer("Failed to query (error: %s)", error_)
	} else {
		
		
		CloseHandle(query)
	}
}

public Action:Command_wipeall(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		ResetClientUpgrades(target_list[i]);
		TF2Attrib_RemoveAll(target_list[i]);
		int Weapon = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_RemoveAll(Weapon);
		}
		int Weapon2 = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
		}
		int Weapon3 = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
		}
		int Weapon4 = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_PDA);
		if(IsValidEntity(Weapon4))
		{
			TF2Attrib_RemoveAll(Weapon4);
		}
		SetEntProp(target_list[i], Prop_Send, "m_iHealth", 125, 1);			
		TF2_RegeneratePlayer(target_list[i]);		
		LogAction(client, target_list[i], "\"%L\" removed all upgrades on \"%L\"", client, target_list[i]);
	}
	return Plugin_Handled;
}

public Action:Command_Refund(client, args)
{
	ResetClientUpgrades(client);
	TF2Attrib_RemoveAll(client);
	int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon))
	{
		TF2Attrib_RemoveAll(Weapon);
	}
	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon2))
	{
		TF2Attrib_RemoveAll(Weapon2);
	}
	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon3))
	{
		TF2Attrib_RemoveAll(Weapon3);
	}
	int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
	if(IsValidEntity(Weapon4))
	{
		TF2Attrib_RemoveAll(Weapon4);
	}
	ForcePlayerSuicide(client);			
	LogAction(client, client, "\"%L\" removed all upgrades on \"%L\"", client, client);

	return Plugin_Handled;
}

/**
 * Returns the m_AttributeList offset.  This does not correspond to the CUtlVector instance
 * (which is offset by 0x04).
 */
static Address GetTheEntityAttributeList(int entity) {
	int offsAttributeList = GetEntSendPropOffs(entity, "m_AttributeList", true);
	if (offsAttributeList > 0) {
		return GetEntityAddress(entity) + view_as<Address>(offsAttributeList);
	}
	return Address_Null;
}