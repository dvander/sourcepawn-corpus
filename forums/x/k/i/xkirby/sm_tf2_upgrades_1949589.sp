// Includes
#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#include <tf2>
#include <tf2_stocks>

// Version Define
#define SM_UU_VERSION		"1.4"

// Other Constants
#define MAX_ATTRIBS			600

// Plugin Info
public Plugin:myinfo =
{
	name = "[TF2]Universal Upgrades",
	author = "X Kirby",
	description = "My attempt at making an Upgrade Station system.",
	version = SM_UU_VERSION,
	url = "http://www.sourcemod.net/",
}

// Handles
new Handle:uu_Version;
new Handle:uu_hStartMoney;
new Handle:uu_hKillMoney;
new Handle:uu_hKillStreak;
new Handle:uu_hKillBonus;
new Handle:uu_hCostIncrease;
new Handle:uu_hPluginInUse;
new Handle:uu_hAssistMoney;
new Handle:uu_hDeathMoney;
new Handle:uu_hPoorBonus;
new Handle:uu_hPoorCheck;
new Handle:kv = INVALID_HANDLE;

// Arrays
new Currency[MAXPLAYERS+1] = 0;
new SpentCurrency[MAXPLAYERS+1] = 0;
new Kills[MAXPLAYERS+1] = 0;
new Weapon[MAXPLAYERS+1] = -1;
new String:Attrib[MAXPLAYERS+1][512];
new String:ClassAttribs[MAX_ATTRIBS][1024];
new String:WeaponAttribs[MAX_ATTRIBS][1024];
new Handle:SteamIDs = INVALID_HANDLE;

// Other Variables
new PlayerInMenu = 0;
new String:path[255];

// On Plugin Start
public OnPluginStart()
{
	// Translation File
	LoadTranslations("common.phrases");
	LoadTranslations("sm_tf2_upgrades.phrases");

	// CVars
	uu_Version = CreateConVar("universalupgrades_version", SM_UU_VERSION, "The Plugin Version. Don't change.", FCVAR_NOTIFY);
	uu_hStartMoney = CreateConVar("sm_uu_currencystart", "500", "Sets the starting currency used for upgrades. Default: 500");
	uu_hKillMoney = CreateConVar("sm_uu_currencyonkill", "25", "Sets the currency you obtain on kill. Default: 25");
	uu_hKillStreak = CreateConVar("sm_uu_killstreakstart", "2", "Sets the required kill streak to start adding extra money. Default: 2");
	uu_hKillBonus = CreateConVar("sm_uu_killstreakbonus", "0.05", "Sets the extra percentage you gain for money. Default: 0.05");
	uu_hCostIncrease = CreateConVar("sm_uu_costincrease", "0.0", "Sets the percentage prices increase every purchase. Default: 0.0");
	uu_hPluginInUse = CreateConVar("sm_uu_enabled", "1.0", "Enables or disables the plugin. Default: 1.0")
	uu_hAssistMoney = CreateConVar("sm_uu_currencyonassist", "0.5", "Sets the percentage of money you gain on kill assist. Default: 0.5");
	uu_hDeathMoney = CreateConVar("sm_uu_currencyondeath", "0.25", "Sets the percentage of money you gain on death. Default: 0.25");
	uu_hPoorBonus = CreateConVar("sm_uu_poorkillbonus", "0.1", "Sets the percentage of extra money you gain from killing richer people. Default: 0.1");
	uu_hPoorCheck = CreateConVar("sm_uu_poorcheck", "0.75", "The percentile difference between you and the target you killed before you can gain extra money. Default: 0.75");
	
	// Admin Command
	RegAdminCmd("sm_uu_givecurrency", ACommand_GiveCurrency, ADMFLAG_ROOT);
	
	// Player Commands
	RegConsoleCmd("sm_upgrade", Command_UUShop);
	RegConsoleCmd("sm_buy", Command_UUShop);
	RegConsoleCmd("sm_checkcurrency", Command_CheckCurrency);
	RegConsoleCmd("sm_money", Command_CheckCurrency);
	RegConsoleCmd("sm_reset", Command_ResetPlayer);
	
	// Hooked Events
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("teamplay_restart_round", Event_RoundRestart);
	HookEvent("teamplay_round_start", Event_RoundStart);
	
	// Hooked CVars
	HookConVarChange(uu_hPluginInUse, OnPluginToggle);
	
	// Arrays
	SteamIDs = CreateArray(MAXPLAYERS+1, 64);
	
	// Currency Set
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		Currency[i] = 0;
		SpentCurrency[i] = 0;
	}
	
	// Automatically set up a Config File.
	AutoExecConfig(true, "universalupgrades", "sourcemod");
	SetConVarString(uu_Version, SM_UU_VERSION);
	
	// Sets the path variable to the upgrades file
	BuildPath(Path_SM, path, sizeof(path), "configs/uu_upgrades.txt");
}

// On Plugin End
public OnPluginEnd()
{
	ResetAllPlayers();
	CloseHandle(SteamIDs);

	// Reset Currency
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidEdict(i))
		{
			Currency[i] = 0;
			SpentCurrency[i] = 0;
		}
	}
	
	// Remove KeyValues Handle
	if(kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
		kv = INVALID_HANDLE;
	}
}

// On Map Start
public OnMapStart()
{
	if(kv == INVALID_HANDLE)
	{
		kv = CreateKeyValues("Upgrades");
		WriteAttribs();
	}

	// Reset Currency
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidEdict(i))
		{
			Currency[i] = 0;
			SpentCurrency[i] = 0;
		}
	}
}

// On Map End
public OnMapEnd()
{
	// Reset Currency
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidEdict(i))
		{
			Currency[i] = 0;
			SpentCurrency[i] = 0;
		}
	}
	
	// Remove KeyValues Handle
	if(kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
		kv = INVALID_HANDLE;
	}
}

// Client Connected Successfully
public OnClientConnected(client)
{
	new i=0, Money=0;
	for(i=1; i<=MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i))
			{
				if(Money > Currency[i] + SpentCurrency[i] && Money > GetConVarInt(uu_hStartMoney))
				{
					Money = Currency[i] + SpentCurrency[i];
				}
				else if(Money < 1)
				{
					Money = Currency[i] + SpentCurrency[i];
				}
			}
		}
	}
	Currency[client] = GetConVarInt(uu_hStartMoney);
	SpentCurrency[client] = 0;
	
	if(Money >= Currency[client])
	{
		Currency[client] = Money;
	}
	
}

public Action:ACommand_GiveCurrency(client, args)
{
	// Set up Args
	new String:arg1[64], String:arg2[24];
	new amount = 0;
	if(args < 2)
	{
		PrintToConsole(client, "Usage: sm_uu_givecurrency <username> <amount>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	amount = StringToInt(arg2);
	
	// Find Target
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	// Give Money to targets
	for(new i=0; i < target_count; i++)
	{
		new String:N[128];
		GetClientName(target_list[i], N, sizeof(N));
		Currency[target_list[i]] += amount;
		
		PrintToConsole(client, "Gave $%d to %s.", amount, N);
		PrintToChat(target_list[i], "You were given $%d!", amount);
	}
	return Plugin_Handled;
}

// User Upgrade Shop Command
public Action:Command_UUShop(client, args)
{
	if(GetConVarBool(uu_hPluginInUse))
	{
		if(IsPlayerAlive(client))
		{
			new Handle:panel = CreatePanel();
			new String:UText[255];
			Format(UText, sizeof(UText), "%T", "UpgradeWeaponSelect", client);
			SetPanelTitle(panel, UText);
			DrawPanelItem(panel, "Primary");
			DrawPanelItem(panel, "Secondary");
			DrawPanelItem(panel, "Melee");
			DrawPanelItem(panel, "Device 1");
			DrawPanelItem(panel, "Device 2");
			DrawPanelItem(panel, "Player");
			SendPanelToClient(panel, client, PanelHandler2, MENU_TIME_FOREVER);
			CloseHandle(panel);
		}
	}
	return Plugin_Handled;
}

// Check Money
public Action:Command_CheckCurrency(client, args)
{
	if(GetConVarBool(uu_hPluginInUse))
	{
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "[UU] %t", "PriceCheck", Currency[client], Currency[client] + SpentCurrency[client]);
		}
	}
	return Plugin_Handled;
}

// Reset Player's Stats
public Action:Command_ResetPlayer(client, args)
{
	if(GetConVarBool(uu_hPluginInUse))
	{
		if(IsPlayerAlive(client))
		{
			ResetPlayer(client);
			Kills[client] = 0;
			Currency[client] += SpentCurrency[client];
			SpentCurrency[client] = 0;
			PrintToChat(client, "[UU] %t", "Upgrade_Reset");
		}
	}
	return Plugin_Handled;
}

// Upgrade Menu Handle
Handle:BuildUpgradeMenu()
{
	// Open the Upgrades File
	new Handle:menu = INVALID_HANDLE;
	
	menu = CreateMenu(Menu_UpgradeShop);
	new p1 = PlayerInMenu;
	new bool:IsWeapon = false
	
	PlayerInMenu = 0;
	
	new TFClassType:Cl, String:W[255];
	Cl = TF2_GetPlayerClass(p1);
	if(Weapon[p1] > -1)
	{
		GetEntityClassname(Weapon[p1], W, sizeof(W));
		IsWeapon = true;
	}
	else
	{
		W = "<Empty>";
		IsWeapon = false;
	}
	
	// Split Attribute Strings
	for(new i = 0; i < MAX_ATTRIBS; i++)
	{
		new bool:MATCH = false;
		new String:BuffersC[6][128], String:BuffersW[6][128], String:SubSections[4][128];
		new String:SubSectionValues[12][128];
		ExplodeString(ClassAttribs[i], "|", BuffersC, 6, 128, false);
		ExplodeString(WeaponAttribs[i], "|", BuffersW, 6, 128, false);
		for(new j = 0; j < 6; j++)
		{
			// Class Attribute Subsection Finding
			if(IsWeapon == false)
			{
				ExplodeString(BuffersC[j], ",", SubSections, 4, 128, false);
				if(TF2_GetClass(SubSections[0]) == Cl || StrEqual(SubSections[0], "all"))
				{
					MATCH = true;
					strcopy(SubSectionValues[j], 128, SubSections[3]);
				}
			}
			
			// Weapon Attribute Subsection Finding
			else
			{
				ExplodeString(BuffersW[j], ",", SubSections, 4, 128, false);
				if(StrEqual(W, SubSections[0]))
				{
					MATCH = true;
					strcopy(SubSectionValues[j+6], 128, SubSections[3]);
				}
			}
		}
		
		new String:NAME[128];
		if(MATCH == false)
		{
			continue;
		}
		if(IsWeapon == false)
		{
			strcopy(NAME, sizeof(NAME), AddMenuAttrib(p1, SubSections[1], StringToInt(SubSectionValues[1]), StringToFloat(SubSectionValues[2]), StringToFloat(SubSectionValues[4]), SubSectionValues[0], StringToInt(SubSectionValues[5])));
			if(!StrEqual(NAME, "<Empty>") && !StrEqual(NAME, ""))
			{
				AddMenuItem(menu, ClassAttribs[i], NAME);
			}
		}
		else
		{
			strcopy(NAME, sizeof(NAME), AddMenuAttrib(p1, SubSections[1], StringToInt(SubSectionValues[7]), StringToFloat(SubSectionValues[8]), StringToFloat(SubSectionValues[10]), SubSectionValues[6], StringToInt(SubSectionValues[11])));
			if(!StrEqual(NAME, "<Empty>") && !StrEqual(NAME, ""))
			{
				AddMenuItem(menu, WeaponAttribs[i], NAME);
			}
		}
	}
	
	new String:UMName[255];
	Format(UMName, sizeof(UMName), "%T", "MenuTitle", p1, Currency[p1], Currency[p1] + SpentCurrency[p1]);
	SetMenuTitle(menu, UMName);
	return menu;
}

// Upgrade Panel Handler
public PanelHandler1(Handle:menu, MenuAction:action, p1, p2)
{
	if(action == MenuAction_Select)
	{
		if(p2 == 1)
		{
			new playernum = CheckSteamID(p1);
			UpgradeAttribs(p1, playernum, Attrib[p1]);
			Attrib[p1] = "";
		}
		PlayerInMenu = p1;
		new Handle:Menu = BuildUpgradeMenu();
		if(Menu != INVALID_HANDLE)
		{
			DisplayMenu(Menu, p1, MENU_TIME_FOREVER);
		}
	}
}

// Weapon Selection Panel Handler
public PanelHandler2(Handle:menu, MenuAction:action, p1, p2)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(p1))
		{
			p2 -= 1;
			PlayerInMenu = p1;
			if(p2 >= 5)
			{
				Weapon[p1] = -1;
				new Handle:Menu = INVALID_HANDLE;
				Menu = BuildUpgradeMenu();
				if(Menu != INVALID_HANDLE)
				{
					DisplayMenu(Menu, p1, MENU_TIME_FOREVER);
				}
			}
			else
			{
				if(GetPlayerWeaponSlot(p1, p2) >= 0)
				{
					Weapon[p1] = GetPlayerWeaponSlot(p1, p2);
					new Handle:Menu = INVALID_HANDLE;
					Menu = BuildUpgradeMenu();
					if(Menu != INVALID_HANDLE)
					{
						DisplayMenu(Menu, p1, MENU_TIME_FOREVER);
					}
				}
			}
		}
	}
}

// Upgrade Menu Handle Handler
public Menu_UpgradeShop(Handle:menu, MenuAction:action, p1, p2)
{
	if(action == MenuAction_Select)
	{
		new String:AT[512], TFClassType:Cl, String:W[255];
		Cl = TF2_GetPlayerClass(p1);
		if(Weapon[p1] > -1)
		{
			GetEntityClassname(Weapon[p1], W, sizeof(W));
		}
		else
		{
			W = "<Empty>"
		}
		GetMenuItem(menu, p2, AT, sizeof(AT));
		
		new String:BuffersC[6][128], String:BuffersW[6][128], String:SubSections[4][128], TFClassType:SCl;
		new String:SubSectionValues[6][128], String:info[128];
		ExplodeString(AT, "|", BuffersC, 6, 128, false);
		ExplodeString(AT, "|", BuffersW, 6, 128, false);
		for(new j = 0; j < 6; j++)
		{
			// Class Attribute Subsection Finding
			ExplodeString(BuffersC[j], ",", SubSections, 4, 128, false);
			SCl = TF2_GetClass(SubSections[0]);
			if(Cl == SCl || StrEqual(SubSections[0], "all"))
			{
				info = SubSections[1];
				strcopy(SubSectionValues[j], 128, SubSections[3]);
			}
			
			// Weapon Attribute Subsection Finding
			ExplodeString(BuffersW[j], ",", SubSections, 4, 128, false);
			if(StrEqual(W, SubSections[0]))
			{
				info = SubSections[1];
				strcopy(SubSectionValues[j], 128, SubSections[3]);
			}
		}
		
		new Cost, Float:UpVal, useWeapon, Float:startpoint, Float:CostIncrease;
		CostIncrease = GetConVarFloat(uu_hCostIncrease);
		Cost = StringToInt(SubSectionValues[1]);
		UpVal = StringToFloat(SubSectionValues[2]);
		startpoint = StringToFloat(SubSectionValues[4]);
		useWeapon = StringToInt(SubSectionValues[5]);

		new wep = Weapon[p1];
		if(!IsValidEntity(wep) || useWeapon == 0)
		{
			wep = p1;
		}

		// Creates the new Attribute
		new Address:A = TF2Attrib_GetByName(wep, info);
		if(Address:A < Address_MinimumValid)
		{
			TF2Attrib_SetByName(wep, info, startpoint);
			A = TF2Attrib_GetByName(wep, info);
			if(TF2Attrib_GetInitialValue(A) == 0.0)
			{
				TF2Attrib_SetInitialValue(A, startpoint);
			}
		}

		// Checks the attribute difference
		if(CostIncrease != 0.0)
		{
			new Float:AttribAmount = TF2Attrib_GetValue(A);
			new Float:i = 0.0, Count = 0;
			if(UpVal > 0)
			{
				for(i = startpoint; i < FloatAbs(AttribAmount);i += FloatAbs(UpVal))
				{
					Count += 1;
				}
			}
			else if(UpVal < 0)
			{
				for(i = startpoint; i > FloatAbs(AttribAmount);i -= FloatAbs(UpVal))
				{
					Count += 1;
				}
			}
			Cost = RoundToCeil(float(Cost) * (1.0 + (CostIncrease * float(Count))));
		}
		
		strcopy(Attrib[p1], 512, AT);
		
		new Handle:panel = CreatePanel();
		new String:UText[255];
		Format(UText, sizeof(UText), "%T", "UpgradeCheck", p1, Cost, Currency[p1]);
		SetPanelTitle(panel, UText);
		DrawPanelItem(panel, "Yes");
		DrawPanelItem(panel, "No");
		SendPanelToClient(panel, p1, PanelHandler1, MENU_TIME_FOREVER);
		CloseHandle(panel);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// Player Death Event
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(uu_hPluginInUse))
	{
		new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
		new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
		new assistId = GetClientOfUserId(GetEventInt(event, "assister"));
		new addmoney = GetConVarInt(uu_hKillMoney);
		new newmoney = 0;
		Kills[victimId] = 0;
		
		if(IsValidEntity(attackerId) && IsValidEntity(victimId))
		{
			if(victimId != attackerId)
			{
				Kills[attackerId] += 1
				
				if(IsValidEntity(assistId) && assistId > 0)
				{
					newmoney = RoundToFloor(float(addmoney) * GetConVarFloat(uu_hAssistMoney));
					if(IsValidEntity(victimId) && victimId > 0)
					{
						if(Currency[victimId] + SpentCurrency[victimId] > 0)
						{
							if(float(Currency[assistId] + SpentCurrency[assistId]) / float(Currency[victimId] + SpentCurrency[victimId]) <= GetConVarFloat(uu_hPoorCheck) &&
							float((Currency[victimId] + SpentCurrency[victimId]) - (Currency[assistId] + SpentCurrency[assistId])) > 0.0)
							{
								newmoney += RoundToFloor(float((Currency[victimId] + SpentCurrency[victimId]) - (Currency[assistId] + SpentCurrency[assistId])) * GetConVarFloat(uu_hPoorBonus) * GetConVarFloat(uu_hAssistMoney));
							}
						}
					}
					if(newmoney > 0)
					{
						Currency[assistId] += newmoney;
						PrintToChat(assistId, "[UU] %t", "MoneyGain_OnAssist", newmoney, attackerId);
					}
				}
				
				if(Kills[attackerId] >= GetConVarInt(uu_hKillStreak))
				{
					new Float:Bonus = 1.0 + (GetConVarFloat(uu_hKillBonus) * (Kills[attackerId] - GetConVarFloat(uu_hKillStreak)));
					addmoney = RoundToFloor(float(addmoney) * Bonus);
				}
				
				if(IsValidEntity(victimId) && victimId > 0)
				{
					if(Currency[victimId] + SpentCurrency[victimId] > 0)
					{
						if(float(Currency[attackerId] + SpentCurrency[attackerId]) / float(Currency[victimId] + SpentCurrency[victimId]) <= GetConVarFloat(uu_hPoorCheck) &&
						float((Currency[victimId] + SpentCurrency[victimId]) - (Currency[attackerId] + SpentCurrency[attackerId])) > 0.0)
						{
							addmoney += RoundToFloor(float((Currency[victimId] + SpentCurrency[victimId]) - (Currency[attackerId] + SpentCurrency[attackerId])) * GetConVarFloat(uu_hPoorBonus));
						}
					}
				}
				
				if(addmoney > 0)
				{
					Currency[attackerId] += addmoney;
					PrintToChat(attackerId, "[UU] %t", "MoneyGain_OnKill", addmoney);
				}
				
				if(IsValidEntity(victimId) && victimId > 0)
				{
					newmoney = RoundToFloor(float(GetConVarInt(uu_hKillMoney)) * GetConVarFloat(uu_hDeathMoney));
					if(newmoney > 0)
					{
						Currency[victimId] += newmoney;
						PrintToChat(victimId, "[UU] %t", "MoneyGain_OnDeath", newmoney);
					}
				}
			}
		}
	}
}

// Player Spawn Event
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:ID[64];
	GetClientAuthString(client, ID, sizeof(ID));
	SetArrayString(SteamIDs, client, ID);
}

// Player Change Class Event
public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Kills[client] = 0;
	ResetPlayer(client);
	Currency[client] += SpentCurrency[client];
	SpentCurrency[client] = 0;
	if(GetConVarBool(uu_hPluginInUse))
	{
		PrintToChat(client, "[UU] %t", "Intro_1");
		PrintToChat(client, "[UU] %t", "Intro_2");
		PrintToChat(client, "[UU] %t", "Intro_3");
	}
}

// Player Loadout Swap Event
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Kills[client] = 0;
}

// Round Start Event
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllPlayers();
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidEntity(i))
		{
			Kills[i] = 0;
			Currency[i] = GetConVarInt(uu_hStartMoney);
			SpentCurrency[i] = 0;
		}
	}
}

// Round Restart Event
public Event_RoundRestart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllPlayers();
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidEntity(i))
		{
			Kills[i] = 0;
			Currency[i] = GetConVarInt(uu_hStartMoney);
			SpentCurrency[i] = 0;
		}
	}
}

// When the plugin is enabled and disabled
public OnPluginToggle(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new String:cname[255], String:aname[255];
	GetConVarName(convar, cname, sizeof(cname));
	GetConVarName(uu_hPluginInUse, aname, sizeof(aname));
	if(StrEqual(cname, aname))
	{
		if(StringToInt(newValue, 10) == 0)
		{
			ResetAllPlayers();
			for(new i=1; i<=MaxClients; i++)
			{
				if(IsValidEdict(i))
				{
					Kills[i] = 0;
					Currency[i] = GetConVarInt(uu_hStartMoney);
					SpentCurrency[i] = 0;
				}
			}
			
			if(kv != INVALID_HANDLE)
			{
				CloseHandle(kv);
				kv = INVALID_HANDLE;
				for(new j=0; j < MAX_ATTRIBS; j++)
				{
					ClassAttribs[j] = "";
					WeaponAttribs[j] = "";
				}
			}
		}
		
		if(StringToInt(newValue, 10) == 1)
		{
			if(kv != INVALID_HANDLE)
			{
				CloseHandle(kv);
				kv = INVALID_HANDLE;
			}
			
			kv = CreateKeyValues("Upgrades");
			WriteAttribs();
		}
	}
}

// Reset a single player's Attributes
ResetPlayer(client)
{
	if(IsClientInGame(client))
	{
		TF2Attrib_RemoveAll(client);
		TF2_RemoveAllWeapons(client);
		TF2_RespawnPlayer(client);
		Kills[client] = 0;
	}
}

// Reset EVERYONE'S Attributes
ResetAllPlayers()
{
	// Reset Stats
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			TF2Attrib_RemoveAll(i);
			TF2_RemoveAllWeapons(i);
			TF2_RespawnPlayer(i);
		}
	}
}

// Upgrade Command
UpgradeAttribs(client, MoneyHolder, String:AttribID[512])
{
	if(IsPlayerAlive(client))
	{
		new TFClassType:Cl, String:W[255];
		Cl = TF2_GetPlayerClass(client);
		if(Weapon[client] > -1)
		{
			GetEntityClassname(Weapon[client], W, sizeof(W));
		}
		else
		{
			W = "<Empty>"
		}
		
		new String:BuffersC[6][128], String:BuffersW[6][128], String:SubSections[4][128], TFClassType:SCl;
		new String:SubSectionValues[6][128], String:info[128];
		new String:ClassCheck[128];
		ExplodeString(AttribID, "|", BuffersC, 6, 128, false);
		ExplodeString(AttribID, "|", BuffersW, 6, 128, false);
		for(new j = 0; j < 6; j++)
		{
			// Class Attribute Subsection Finding
			ExplodeString(BuffersC[j], ",", SubSections, 4, 128, false);
			SCl = TF2_GetClass(SubSections[0]);
			strcopy(ClassCheck, 128, SubSections[0]);
			if(Cl == SCl || StrEqual(ClassCheck, "all"))
			{
				info = SubSections[1];
				strcopy(SubSectionValues[j], 128, SubSections[3]);
			}
			
			// Weapon Attribute Subsection Finding
			ExplodeString(BuffersW[j], ",", SubSections, 4, 128, false);
			if(StrEqual(W, SubSections[0]))
			{
				info = SubSections[1];
				strcopy(SubSectionValues[j], 128, SubSections[3]);
			}
		}
		
		new Cost, Float:UpVal, Float:MaxUpgrade, useWeapon, Float:startpoint, Float:CostIncrease;
		CostIncrease = GetConVarFloat(uu_hCostIncrease);
		Cost = StringToInt(SubSectionValues[1]);
		UpVal = StringToFloat(SubSectionValues[2]);
		MaxUpgrade = StringToFloat(SubSectionValues[3]);
		startpoint = StringToFloat(SubSectionValues[4]);
		useWeapon = StringToInt(SubSectionValues[5]);
		
		new wep = Weapon[client];
		if(!IsValidEntity(wep) || useWeapon == 0)
		{
			wep = client;
		}
		
		// Creates the new Attribute
		new Address:A = TF2Attrib_GetByName(wep, info);
		if(Address:A < Address_MinimumValid)
		{
			TF2Attrib_SetByName(wep, info, startpoint);
			A = TF2Attrib_GetByName(wep, info);
			if(Address:A < Address_MinimumValid)
			{
				return -1;
			}
			if(TF2Attrib_GetInitialValue(A) == 0.0)
			{
				TF2Attrib_SetInitialValue(A, startpoint);
			}
		}
		
		// Checks the attribute difference
		if(CostIncrease != 0.0)
		{
			new Float:AttribAmount = TF2Attrib_GetValue(A);
			new Float:i = 0.0, Float:NewCost, Count = 0;
			if(UpVal > 0)
			{
				for(i = startpoint; i < FloatAbs(AttribAmount);i += FloatAbs(UpVal))
				{
					Count += 1;
				}
			}
			else if(UpVal < 0)
			{
				for(i = startpoint; i > FloatAbs(AttribAmount);i -= FloatAbs(UpVal))
				{
					Count += 1;
				}
			}
			NewCost = float(Cost) * (1.0 + (CostIncrease * float(Count)));
			Cost = RoundToCeil(NewCost);
		}
		
		if(Currency[MoneyHolder] >= Cost && UpVal != 0.0)
		{
			new Float:flval = 0.0;
			flval = TF2Attrib_GetValue(A);
			if((flval < MaxUpgrade && UpVal > 0.0) || (flval > MaxUpgrade && UpVal < 0.0))
			{
				flval += UpVal;
				TF2Attrib_SetByName(wep, info, flval);
				SpentCurrency[MoneyHolder] += Cost;
				Currency[MoneyHolder] -= Cost;
				PrintToChat(client, "[UU] %t", "Upgrade_Success", flval);
			}
			else
			{
				PrintToChat(client, "[UU] %t", "Upgrade_Max");
			}
		}
		else
		{
			PrintToChat(client, "[UU] %t", "Upgrade_Poor");
		}
	}
	else
	{
		PrintToChat(client, "[UU] %t", "Upgrade_Dead");
	}
	
	return 1;
}

// Writes the Upgrades file to String Arrays.
WriteAttribs()
{
	if(FileToKeyValues(kv, path))
	{
		new Cost, CA, WA, Float:UpVal, Float:startpoint, Float:MaxUpgrade, useWeapon;
		new String:CName[64], String:UName[128], String:DName[128];
		
		// Start at Array Index 0.
		CA = 0;
		WA = 0;
		
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetSectionName(kv, CName, sizeof(CName));
			
			if(TF2_GetClass(CName) == TFClass_Unknown && !StrEqual(CName, "all") && StrContains(CName, "tf_weapon", false) == -1 && StrContains(CName, "saxxy", false) == -1)
			{
				continue;
			}
			else
			{
				KvGotoFirstSubKey(kv);
				do
				{
					KvGetSectionName(kv, UName, sizeof(UName));
					KvGetString(kv, "menuname", DName, sizeof(DName), "Upgrade");
					Cost = KvGetNum(kv, "cost", 0);
					UpVal = KvGetFloat(kv, "upgrade", 0.0);
					MaxUpgrade = KvGetFloat(kv, "max", 0.0);
					useWeapon = KvGetNum(kv, "onweapon", 0);
					startpoint = KvGetFloat(kv, "start", 0.0);
					
					new String:SectionName[6][128], String:Final[1024];
					Format(SectionName[0], 128, "%s,%s,%s,%s", CName, UName, "menuname", DName);
					Format(SectionName[1], 128, "%s,%s,%s,%d", CName, UName, "cost", Cost);
					Format(SectionName[2], 128, "%s,%s,%s,%f", CName, UName, "upgrade", UpVal);
					Format(SectionName[3], 128, "%s,%s,%s,%f", CName, UName, "max", MaxUpgrade);
					Format(SectionName[4], 128, "%s,%s,%s,%f", CName, UName, "start", startpoint);
					Format(SectionName[5], 128, "%s,%s,%s,%d", CName, UName, "onweapon", useWeapon);
					
					ImplodeStrings(SectionName, 6, "|", Final, sizeof(Final));
					if(TF2_GetClass(CName) != TFClass_Unknown || StrEqual(CName, "all"))
					{
						strcopy(ClassAttribs[CA], 1024, Final);
						CA++;
					}
					
					if(StrContains(CName, "tf_weapon", false) >= 0 || StrContains(CName, "saxxy", false) >= 0)
					{
						strcopy(WeaponAttribs[WA], 1024, Final);
						WA++;
					}
					
				} while (KvGotoNextKey(kv));
				
				KvGoBack(kv);
			}
			
		} while (KvGotoNextKey(kv));
	}
}

// Adds a Menu Section to the Main Upgrade Menu!
String:AddMenuAttrib(entID, String:UName[128], Cost, Float:UpVal, Float:startpoint, String:DName[128], useWeapon)
{
	new E = entID;
	if(useWeapon == 1)
	{
		E = Weapon[entID];
	}
	else
	{
		E = entID;
	}

	new Float:CostIncrease;
	CostIncrease = GetConVarFloat(uu_hCostIncrease);

	// Creates the new Attribute
	new Address:A = TF2Attrib_GetByName(E, UName);
	if(Address:A < Address_MinimumValid)
	{
		TF2Attrib_SetByName(E, UName, startpoint);
		A = TF2Attrib_GetByName(E, UName);
		if(Address:A < Address_MinimumValid)
		{
			new String:ERROR[128] = "<Empty>";
			return ERROR;
		}
		if(TF2Attrib_GetInitialValue(A) == 0.0)
		{
			TF2Attrib_SetInitialValue(A, startpoint);
		}
	}

	// Checks the attribute difference
	if(CostIncrease != 0.0)
	{
		new Float:AttribAmount = TF2Attrib_GetValue(A);
		new Float:i = 0.0, Count = 0;
		if(UpVal > 0)
		{
			for(i = startpoint; i < FloatAbs(AttribAmount);i += FloatAbs(UpVal))
			{
				Count += 1;
			}
		}
		else if(UpVal < 0)
		{
			for(i = startpoint; i > FloatAbs(AttribAmount);i -= FloatAbs(UpVal))
			{
				Count += 1;
			}
		}
		Cost = RoundToCeil(float(Cost) * (1.0 + (CostIncrease * float(Count))));
	}

	if(TF2Attrib_GetValue(A) == startpoint)
	{
		TF2Attrib_RemoveByName(E, UName);
	}

	new String:C[255], String:Br[255];
	IntToString(Cost, C, sizeof(C));
	if(useWeapon == 0)
	{
		Format(Br, sizeof(Br), "%T ", "Upgrade_Player", entID);
	}
	else
	{
		Format(Br, sizeof(Br), "%T ", "Upgrade_Weapon", entID);
	}
	
	Format(DName, sizeof(DName), "%s ($%s) %s", Br, C, DName);
	
	return DName;
}

// Checks a client's Steam ID
CheckSteamID(client)
{
	new String:AuthID[64], String:OrigID[64];
	new playernum = 0;
	GetClientAuthString(client, AuthID, sizeof(AuthID));
	for(new i=1; i<=MaxClients; i++)
	{
		GetArrayString(SteamIDs, i, OrigID, sizeof(OrigID));
		if(StrEqual(AuthID, OrigID))
		{
			playernum = i;
			break;
		}
	}
	
	return playernum;
}