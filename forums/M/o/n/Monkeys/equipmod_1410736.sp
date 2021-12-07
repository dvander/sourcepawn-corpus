/*
	Feel free to edit and republish this as much as you like.
	But at least leave me some credit ;)
	Created by Jaro 'Monkeys' Vanderheijden
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#pragma semicolon 1

#define VERSION "1.0"

#define TOTAL_SLOTS 10 // Weapon, Shield, Armour, + 7 inventory
#define EQUIPMENT_OVERLAY "equipmod/equip_ui" //Overlay for equipment

static DROP_CHANCE = 5; // ~ 1 in # chance to drop
static ENCHANT_CHANCE = 10; // ~ 1 in # chance to have an enchantment
static Float:DEFENSE_RATIO = 16.5; //1 less damage per # defense
static Float:DONATION_MULTIPLIER = 0.2; //Multiplier on how much donating items returns in rarity
static Float:DOTS_DELAY = 2.0; //Delay between DoTs ticks
static DOTS_BLEEDDAMAGE = 2; //Damage from bleed
static DOTS_FIREDAMAGE = 2; //Damage from fire
static bool:SHOW_EQUIPMENTOVERLAY = true; //Use the overlay when showing equipment
static MAX_RARITY = 20; //Maximum random rarity per roll
static MAX_RARITY_ENCHANT = 20; //Maximum random rarity per roll for enchants

//Cvars
static Handle:Cvar_DropChance;
static Handle:Cvar_EnchantChance;
static Handle:Cvar_DefenseRatio;
static Handle:Cvar_DonationMultiplier;
static Handle:Cvar_DotDelay;
static Handle:Cvar_DotBleedDamage;
static Handle:Cvar_DotBurnDamage;
static Handle:Cvar_ShowEquipmentOverlay;
static Handle:Cvar_MaxRarity;
static Handle:Cvar_MaxRarityEnchant;
	
//DoTs
#define DOTS_BLEED 0
#define DOTS_FIRE 1
#define DOTS_HEAL 2

static String:SavePath[PLATFORM_MAX_PATH];
static String:ItemPath[PLATFORM_MAX_PATH];
static String:LogPath[PLATFORM_MAX_PATH];

static Handle:ItemKV = INVALID_HANDLE;

static Inventory[MAXPLAYERS+1][TOTAL_SLOTS][2];
static String:Effects[MAXPLAYERS+1][128];
static Float:SpeedBoost[MAXPLAYERS+1];
static DoTs[MAXPLAYERS+1][3][2];
static RarityBoost[MAXPLAYERS+1];

static bool:CommandDelay[MAXPLAYERS+1] = { false, ...};

public Plugin:myinfo =
{
	name = "Equipment Mod",
	author = "Jaro 'Monkeys' Vanderheijden",
	description = "Adds the Equipment to any game",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	/* Creating Cvars */
	CreateConVar("equipmod_tracker", VERSION, "Version tracker of Equipment Mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	Cvar_DropChance = CreateConVar("equipmod_dropchance", "5", "Drop Chance for Items");
	HookConVarChange(Cvar_DropChance, cbCvarChange);
	Cvar_EnchantChance = CreateConVar("equipmod_enchantchance", "10", "Enchant Chance for Items");
	HookConVarChange(Cvar_EnchantChance, cbCvarChange);
	Cvar_DefenseRatio = CreateConVar("equipmod_defenseratio", "16.5", "Defense reduction ratio");
	HookConVarChange(Cvar_DefenseRatio, cbCvarChange);
	Cvar_DonationMultiplier = CreateConVar("equipmod_donationmultiplier", "0.2", "How much of the rarity is returned when donating");
	HookConVarChange(Cvar_DonationMultiplier, cbCvarChange);
	Cvar_DotDelay = CreateConVar("equipmod_dotdelay", "2.0", "Delay between DoT ticks");
	HookConVarChange(Cvar_DotDelay, cbCvarChange);
	Cvar_DotBleedDamage = CreateConVar("equipmod_dotbleeddamage", "3", "Damage per Bleed tick");
	HookConVarChange(Cvar_DotBleedDamage, cbCvarChange);
	Cvar_DotBurnDamage = CreateConVar("equipmod_dotburndamage", "2", "Damage per Burn tick");
	HookConVarChange(Cvar_DotBurnDamage, cbCvarChange);
	Cvar_ShowEquipmentOverlay = CreateConVar("equipmod_showoverlay", "1", "Show the equipment overlay");
	HookConVarChange(Cvar_ShowEquipmentOverlay, cbCvarChange);
	Cvar_MaxRarity = CreateConVar("equipmod_maxrarity", "20", "Maximum random rarity per roll");
	HookConVarChange(Cvar_MaxRarity, cbCvarChange);
	Cvar_MaxRarityEnchant = CreateConVar("equipmod_maxrarity_enchant", "20", "Maximum random rarity per roll for enchants");
	HookConVarChange(Cvar_MaxRarityEnchant, cbCvarChange);
	
	/* Overlay cheat dissable */
	SetCommandFlags("r_screenoverlay", (GetCommandFlags("r_screenoverlay") - FCVAR_CHEAT));
	
	/* File Building */
	BuildPath(Path_SM, SavePath, sizeof(SavePath), "data/save.dat");
	if(!FileExists(SavePath)) SetFailState("Save file not found: %s", SavePath);
	
	BuildPath(Path_SM, ItemPath, sizeof(ItemPath), "data/items.txt");
	if(!FileExists(ItemPath)) SetFailState("Item file not found: %s", ItemPath);
	
	BuildPath(Path_SM, LogPath, sizeof(LogPath), "data/droplog.dat");
	if(!FileExists(LogPath)) SetFailState("Logfile not found: %s", LogPath);
	
	/*if (!FileExists("materials/particle/particledefault.vmt", true)) {
		new Handle:g_file_handle = OpenFile("materials/particle/particledefault.vmt", "a");
		if (g_file_handle != INVALID_HANDLE) {
			WriteFileString(g_file_handle, "UnlitGeneric\r\n{\r\n\"$translucent\" 1\r\n\"$basetexture\" \"Decals/blood_gunshot_decal\"\r\n\"$vertexcolor\" 1\r\n}\r\n", false);
			CloseHandle(g_file_handle);
		}
	}*/
	
	/* Events */
	HookEvent("player_spawn", EventSpawn);
	HookEvent("player_death", EventDeath);
	
	/* Commands */
	RegConsoleCmd("sm_showequip", Command_ShowEquip, "Shows your equipment");
	RegConsoleCmd("sm_closeequip", Command_CloseEquip, "Closes your equipment");
	RegConsoleCmd("sm_equip", Command_EquipItem, "Equips an item");
	RegConsoleCmd("sm_donate", Command_DonateItem, "Donates an item to a charity, increasing your luck");
	
	RegAdminCmd("sm_giveitem", Command_GiveItem, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloaditems", Command_ReloadItems, ADMFLAG_ROOT);
}

public OnMapStart()
{
	if(ItemKV != INVALID_HANDLE)
		CloseHandle(ItemKV);
	ItemKV = CreateKeyValues("Items");
	FileToKeyValues(ItemKV, ItemPath);	
	
	/* Required files for clients */
	decl String:Buff[PLATFORM_MAX_PATH];
	Format(Buff, sizeof(Buff), "materials/%s.vmt", EQUIPMENT_OVERLAY);
	AddFileToDownloadsTable(Buff);
	Format(Buff, sizeof(Buff), "materials/%s.vtf", EQUIPMENT_OVERLAY);
	AddFileToDownloadsTable(Buff);
	
	// AddFileToDownloadsTable("materials/particle/particledefault.vmt");
}

public OnClientPutInServer(Client)
{
	decl String:Auth[32], String:Buffer[TOTAL_SLOTS*8];
	GetClientAuthString(Client, Auth, sizeof(Auth));
	
	new Handle:KV = CreateKeyValues("Saves");
	FileToKeyValues(KV, SavePath);
	
	KvGetString(KV, Auth, Buffer, sizeof(Buffer), "0^0 0^0 0^0");
	decl String:ExplBuffer[TOTAL_SLOTS][8];
	new ItemCount = ExplodeString(Buffer, " ", ExplBuffer, TOTAL_SLOTS, 10);
	
	decl String:MiniExplBuffer[3][5];
	for(new X = 0; X < ItemCount; X++)
	{
		ExplodeString(ExplBuffer[X], "^", MiniExplBuffer, 3, 5);
		Inventory[Client][X][0] = StringToInt(MiniExplBuffer[0]);
		Inventory[Client][X][1] = StringToInt(MiniExplBuffer[1]);
	}
	for(new X = ItemCount; X < TOTAL_SLOTS; X++)
	{
		Inventory[Client][X][0] = 0;
		Inventory[Client][X][1] = 0;
	}
	
	CloseHandle(KV);
	
	//Remove DoTs
	for(new X = 0; X < sizeof(DoTs[]); X++)
	{
		DoTs[Client][X][0] = 0;
	}
	Effects[Client] = "";
	LoadEffects(Client);
	
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	CreateTimer(DOTS_DELAY, timerDoTs, Client, TIMER_REPEAT);
}

public OnClientDisconnect(Client)
{
	decl String:Auth[32];
	if(GetClientAuthString(Client, Auth, sizeof(Auth)))
	{
		new Handle:KV = CreateKeyValues("Saves");
		FileToKeyValues(KV, SavePath);
		decl String:sInv[TOTAL_SLOTS*8] = "";
		for(new X = 0; X < TOTAL_SLOTS; X++)
		{
			Format(sInv, sizeof(sInv), "%s%d^%d ", sInv, Inventory[Client][X][0], Inventory[Client][X][1]);
		}
		
		KvSetString(KV, Auth, sInv);
		KeyValuesToFile(KV, SavePath);
		CloseHandle(KV);
	}
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bool:HasSpeeded[MAXPLAYERS+1] = { false,...};
	if(buttons & IN_SPEED)
	{
		HasSpeeded[Client] = true;
		SetEntPropFloat(Client, Prop_Data, "m_flMaxspeed", 320.0 + SpeedBoost[Client]);
	} else
	if(HasSpeeded[Client])
	{
		SetEntPropFloat(Client, Prop_Data, "m_flMaxspeed", 190.0 + SpeedBoost[Client]);
		HasSpeeded[Client] = false;
	}
	return Plugin_Continue;
}

public EventSpawn(Handle:Event, const String:Name[], bool:dontBroadcast) 
{
	new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));
	
	//Remove DoTs
	for(new X = 0; X < sizeof(DoTs[][]); X++)
	{
		DoTs[Client][X][0] = 0;
		DoTs[Client][X][1] = 0;
	}
	
	LoadEffects(Client);
}

public EventDeath(Handle:Event, const String:EventName[], bool:dontBroadcast) 
{
	new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));
	new Attacker = GetClientOfUserId(GetEventInt( Event, "attacker" ));
	
	if(Client != Attacker && Attacker > 0 && Attacker < MaxClients && IsClientInGame(Attacker) && IsPlayerAlive(Attacker))
	{
		new Slot = GetOpenInventorySlot(Attacker);
		if(Slot != -1)
		{
			RarityBoost[Attacker] += 10;
			new nItem[2];
			nItem[0] = GetRandomItem(Attacker);
			if(nItem[0] != 0)
			{
				nItem[1] = GetRandomEnchant(Attacker, nItem[0]);
				decl String:Name[64];
				GetItemName(nItem, Name, sizeof(Name));
				CPrintToChatAll("{green}%N has found {olive}'%s'.", Attacker, Name, nItem[0], nItem[1]);
				Inventory[Attacker][Slot] = nItem;
				if(GetInventoryCount(Attacker) == TOTAL_SLOTS - 3)
					CPrintToChat(Attacker, "{default}Watch out, {green}your inventory is full! You won't be able to get any more drops!");
				RarityBoost[Attacker] = 0;
				decl String:Auth[32];
				GetClientAuthString(Attacker, Auth, sizeof(Auth));
				LogToFile(LogPath, "%N <%s> found [UID:%d-%d] and now has %d items in inventory", Attacker, Auth, nItem[0], nItem[1], GetInventoryCount(Attacker));
			}
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:Classname[64];
	GetEdictClassname(inflictor, Classname, sizeof(Classname));
	if(StrContains(Classname, "dots_") != -1)
		return Plugin_Continue;
	if(attacker > 0 && attacker <= MaxClients)
	{
		ApplyOffensiveStats(attacker, victim, damage);
	}
	ApplyDefensiveStats(victim, damage);
	return Plugin_Changed;
}

ApplyOffensiveStats(attacker, victim, &Float:damage)
{
	decl String:ExplEffects[64][8];
	new Effectcount = ExplodeString(Effects[attacker], " ", ExplEffects, 64, 8);
	for(new X = 0; X < Effectcount; X++)
	{
		switch(ExplEffects[X][0])
		{
			case 'd':
			{
				damage += (damage*StringToFloat(ExplEffects[X][1]))/100.0;
				if(damage < 0.0)
					damage = 0.0;
			}
			case 'b':
			{
				DoTs[victim][DOTS_BLEED][0] = StringToInt(ExplEffects[X][1]);
				DoTs[victim][DOTS_BLEED][1] = attacker;
			}
			case 'f':
			{
				DoTs[victim][DOTS_FIRE][0] = StringToInt(ExplEffects[X][1]);
				DoTs[victim][DOTS_FIRE][1] = attacker;
			}
		}
	}
}

ApplyDefensiveStats(victim, &Float:damage)
{
	decl String:ExplEffects[64][8];
	new Effectcount = ExplodeString(Effects[victim], " ", ExplEffects, 64, 8);
	for(new X = 0; X < Effectcount; X++)
	{
		switch(ExplEffects[X][0])
		{
			case 'r':
			{
				switch(ExplEffects[X][1])
				{
					case 'f':
					{
						DoTs[victim][DOTS_FIRE][0] = 0;
						DoTs[victim][DOTS_FIRE][1] = 0;
					}
					case 'b':
					{
						DoTs[victim][DOTS_BLEED][0] = 0;
						DoTs[victim][DOTS_BLEED][1] = 0;
					}
				}
			}
			case 'a':
			{
				damage -= (StringToFloat(ExplEffects[X][1])/DEFENSE_RATIO);
				if(damage < 0.0)
					damage = 0.0;
			}
		}
	}
}

GetRandomItem(Client)
{
	new Rarity = GetNewDropRarity(Client);
	
	KvRewind(ItemKV);
	KvJumpToKey(ItemKV, "Normal");
	new iMax = KvGetNum(ItemKV, "count", 1);
	
	new PickedRarity = 0;
	new iRand = 0;
	decl String:CurrItem[5];
	do
	{
		iRand = GetRandomInt(1, iMax*DROP_CHANCE);
		IntToString(iRand, CurrItem, sizeof(CurrItem));
		if(KvJumpToKey(ItemKV, CurrItem, false))
		{
			PickedRarity = KvGetNum(ItemKV, "Rarity", 0);
		} else
		{
			return 0;
		}
		KvGoBack(ItemKV);
	}while( Rarity < PickedRarity );
	return iRand;
}

GetRandomEnchant(Client, Item)
{
	new Rarity = GetNewEnchantRarity(Client);
	
	KvRewind(ItemKV);
	KvJumpToKey(ItemKV, "Normal");
	decl String:CurrItem[5];
	IntToString(Item, CurrItem, sizeof(CurrItem));
	if(KvJumpToKey(ItemKV, CurrItem, false))
	{
		decl String:Enchantments[64];
		KvGetString(ItemKV, "Enchants", Enchantments, sizeof(Enchantments), "");
		decl String:ExplBuffer[64][5];
		new iMax = ExplodeString(Enchantments, " ", ExplBuffer, 64, 5);
		new iRand = GetRandomInt(0, (iMax-1)*ENCHANT_CHANCE);
		KvRewind(ItemKV);
		KvJumpToKey(ItemKV, "Enchants");
		IntToString(iRand, CurrItem, sizeof(CurrItem));
		if(KvJumpToKey(ItemKV, CurrItem, false))
		{
			if(KvGetNum(ItemKV, "Rarity", 0) < Rarity)
			{
				return iRand;
			}
		}
	}
	return 0;
}

GetNewDropRarity(Client)
{
	new Rarity = GetRandomInt(0, MAX_RARITY);
	Rarity += RarityBoost[Client];
	return Rarity;
}

GetNewEnchantRarity(Client)
{
	new Rarity = GetRandomInt(0, MAX_RARITY_ENCHANT);
	Rarity += RarityBoost[Client];
	return Rarity;
}

GetInventoryCount(Client)
{
	new Count = 0;
	for(new X = 3; X < TOTAL_SLOTS; X++)
	{
		if(Inventory[Client][X][0] != 0)
			Count++;
	}
	return Count;
}

GetOpenInventorySlot(Client)
{
	for(new X = 3; X < TOTAL_SLOTS; X++)
	{
		if(Inventory[Client][X][0] == 0)
			return X;
	}
	return -1;
}

ShowEquipment(Client, Target)
{
	decl String:HudText[1500];
	new Rarity = 0;
	new clColors[4] = {255,255,255,255};
	// SetEntProp(Client, Prop_Send, "m_iHideHUD", (1<<8)|(1<<7)|(1<<4));
	if(SHOW_EQUIPMENTOVERLAY)
		ClientCommand(Client, "r_screenoverlay %s", EQUIPMENT_OVERLAY);
		
	//Weapon
	if(Inventory[Target][0][0] != 0)
	{
		strcopy(HudText, sizeof(HudText), "");
		Rarity = GetItemFullField(Inventory[Target][0], HudText, sizeof(HudText));
		GetRarityColors(Rarity, clColors);
		SetHudTextParams(0.1, 0.1, 100.0, clColors[0], clColors[1], clColors[2], clColors[3], 1, 0.0, 0.0, 0.1);
		ShowHudText(Client, 1, HudText);
	}
	
	//Shield
	if(Inventory[Target][1][0] != 0)
	{
		strcopy(HudText, sizeof(HudText), "");
		Rarity = GetItemFullField(Inventory[Target][1], HudText, sizeof(HudText));
		GetRarityColors(Rarity, clColors);
		SetHudTextParams(0.4, 0.1, 100.0, clColors[0], clColors[1], clColors[2], clColors[3], 1, 0.0, 0.0, 0.1);
		ShowHudText(Client, 2, HudText);
	}
	
	//Armour
	if(Inventory[Target][2][0] != 0)
	{
		strcopy(HudText, sizeof(HudText), "");
		Rarity = GetItemFullField(Inventory[Target][2], HudText, sizeof(HudText));
		GetRarityColors(Rarity, clColors);
		SetHudTextParams(0.7, 0.1, 100.0, clColors[0], clColors[1], clColors[2], clColors[3], 1, 0.0, 0.0, 0.1);
		ShowHudText(Client, 3, HudText);
	}
	
}

CloseEquipment(Client)
{
	// SetEntProp(Client, Prop_Send, "m_iHideHUD", 0);
	if(SHOW_EQUIPMENTOVERLAY)
		ClientCommand(Client, "r_screenoverlay 0");
	ShowHudText(Client, 1, "");
	ShowHudText(Client, 2, "");
	ShowHudText(Client, 3, "");
}

GetItemFullField(Item[2], String:Output[], len)
{
	new written = 0, rarity = 0;
	new Float:D, F, Float:S, B, H, A, bool:RF = false, bool:RB = false;
	KvRewind(ItemKV);
	decl String:Buffer[128];
	decl String:NameBuffer[64];
	decl String:ExplEffBuffer[64][8];
	
	//Normal Item name
	if(Item[0] > 0)
	{
		KvJumpToKey(ItemKV, "Normal");
		IntToString(Item[0], Buffer, sizeof(Buffer));
		KvJumpToKey(ItemKV, Buffer);
		KvGetString(ItemKV, "Name", NameBuffer, sizeof(NameBuffer), "Normal Item");
		rarity += KvGetNum(ItemKV, "Rarity", 0);
	} else
	//Unique Item name
	if(Item[0] < 0)
	{
		KvJumpToKey(ItemKV, "Unique");
		IntToString(0 - Item[0], Buffer, sizeof(Buffer));
		KvJumpToKey(ItemKV, Buffer);
		KvGetString(ItemKV, "Name", NameBuffer, sizeof(NameBuffer), "Unique Item");
		rarity += KvGetNum(ItemKV, "Rarity", 0);
	}
	
	
	//Get Base stats
	KvGetString(ItemKV, "Stats", Buffer, sizeof(Buffer), "");
	new count = ExplodeString(Buffer, " ", ExplEffBuffer, 64, 8);
	for(new X = 0; X < count; X++)
	{
		switch(ExplEffBuffer[X][0])
		{
			case 'd':
			{
				D += StringToFloat(ExplEffBuffer[X][1]);
			}
			case 'a':
			{
				A += StringToInt(ExplEffBuffer[X][1]);
			}
			case 'f':
			{
				//Fire doesn't stack
				F = (StringToInt(ExplEffBuffer[X][1]) > F) ? StringToInt(ExplEffBuffer[X][1]) : F;
			}
			case 'b':
			{
				//Bleed doesn't stack
				B = (StringToInt(ExplEffBuffer[X][1]) > B) ? StringToInt(ExplEffBuffer[X][1]) : B;
			}
			case 's':
			{
				S += StringToFloat(ExplEffBuffer[X][1]);
			}
			case 'h':
			{
				//Heal DoTs DOES stack
				H += StringToInt(ExplEffBuffer[X][1]);
			}
			case 'r':
			{
				if(ExplEffBuffer[X][1] == 'f')
					RF = true;
				if(ExplEffBuffer[X][1] == 'b')
					RB = true;
			}
		}
	}
	KvRewind(ItemKV);
	if(Item[1] > 0)
	{
		KvJumpToKey(ItemKV, "Enchants");
		IntToString(Item[0], Buffer, sizeof(Buffer));
		KvJumpToKey(ItemKV, Buffer);
		//Add enchant name
		KvGetString(ItemKV, "Name", Buffer, sizeof(Buffer), "%s");
		written += Format(Output[written], len-written, Buffer, NameBuffer);
		rarity += KvGetNum(ItemKV, "Rarity", 0);
		//Enchant Stats
		KvGetString(ItemKV, "Stats", Buffer, sizeof(Buffer), "");
		count = ExplodeString(Buffer, " ", ExplEffBuffer, 64, 8);
		for(new X = 0; X < count; X++)
		{
			switch(ExplEffBuffer[X][0])
			{
				case 'd':
				{
					D += StringToFloat(ExplEffBuffer[X][1]);
				}
				case 'a':
				{
					A += StringToInt(ExplEffBuffer[X][1]);
				}
				case 'f':
				{
					//Fire doesn't stack
					F = (StringToInt(ExplEffBuffer[X][1]) > F) ? StringToInt(ExplEffBuffer[X][1]) : F;
				}
				case 'b':
				{
					//Bleed doesn't stack
					B = (StringToInt(ExplEffBuffer[X][1]) > B) ? StringToInt(ExplEffBuffer[X][1]) : B;
				}
				case 's':
				{
					S += StringToInt(ExplEffBuffer[X][1]);
				}
				case 'h':
				{
					//Heal DoTs DOES stack
					H += StringToInt(ExplEffBuffer[X][1]);
				}
				case 'r':
				{
					if(ExplEffBuffer[X][1] == 'f')
						RF = true;
					if(ExplEffBuffer[X][1] == 'b')
						RB = true;
				}
			}
		}
		
	} else
		//Items with no enchant
		written += Format(Output[written], len-written, NameBuffer);
		
	written += Format(Output[written], len-written, "\n");
	
	//Print stats
	if(D != 0.0)
		written += Format(Output[written], len-written, "Damage: %.2f%%\n", D);
	if(A != 0)
		written += Format(Output[written], len-written, "Armour: %d\n", A);
	if(S != 0.0)
		written += Format(Output[written], len-written, "Speed: %.0f\n", S);
	if(F != 0.0)
		written += Format(Output[written], len-written, "Burning Lv.%d\n", F);
	if(B != 0)
		written += Format(Output[written], len-written, "Bleeding Lv.%d\n", B);
	if(H != 0)
		written += Format(Output[written], len-written, "Regeneration Lv.%d\n", H);
	if(RF)
		written += Format(Output[written], len-written, "Resistance to Burning\n");
	if(RB)
		written += Format(Output[written], len-written, "Resistance to Bleeding");
	
	return rarity;
}

GetItemName(Item[2], String:Output[], len)
{
	new Rarity;
	KvRewind(ItemKV);
	//Normal Item
	if(Item[0] > 0)
	{
		decl String:sItem[5];
		IntToString(Item[0], sItem, sizeof(sItem));
		KvJumpToKey(ItemKV, "Normal");
		if(KvJumpToKey(ItemKV, sItem, false))
		{
			KvGetString(ItemKV, "Name", Output, len, "Normal Item");
			Rarity += KvGetNum(ItemKV, "Rarity", 0);
			if(Item[1] > 0)
			{
				KvRewind(ItemKV);
				KvJumpToKey(ItemKV, "Enchants");
				IntToString(Item[1], sItem, sizeof(sItem));
				if(KvJumpToKey(ItemKV, sItem, false))
				{
					decl String:Buffer[64];
					KvGetString(ItemKV, "Name", Buffer, sizeof(Buffer), "%s");
					Rarity += KvGetNum(ItemKV, "Rarity", 0);
					Format(Output, len, Buffer, Output);
				}
			}
		} else
			Format(Output, len, "");
	} else
	//Unique Item
	if(Item[0] < 0)
	{
		decl String:sItem[5];
		IntToString(0 - Item[0], sItem, sizeof(sItem));
		KvJumpToKey(ItemKV, "Unique");
		if(KvJumpToKey(ItemKV, sItem, false))
		{
			KvGetString(ItemKV, "Name", Output, len, "Unique Item");
			Rarity += KvGetNum(ItemKV, "Rarity", 0);
		} else
			Format(Output, len, "");
	} else
		Format(Output, len, "");
	return Rarity;
}

GetRarityColors(Rarity, clColors[4])
{
	clColors[3] = 255;
	if( Rarity < 200)
	{
		clColors[0] = 255;
		clColors[1] = 255;
		clColors[2] = 255;
	} else
	if( Rarity < 500)
	{
		clColors[0] = 255;
		clColors[1] = 255;
		clColors[2] = 100;
	} else
	if( Rarity < 800)
	{
		clColors[0] = 255;
		clColors[1] = 100;
		clColors[2] = 100;
	} else
	if( Rarity < 1200)
	{
		clColors[0] = 0;
		clColors[1] = 255;
		clColors[2] = 255;
	} else
	if( Rarity < 1500)
	{
		clColors[0] = 0;
		clColors[1] = 0;
		clColors[2] = 255;
	} else
	if( Rarity < 2000)
	{
		clColors[0] = 26;
		clColors[1] = 96;
		clColors[2] = 26;
	} else
	{
		clColors[0] = 0;
		clColors[1] = 255;
		clColors[2] = 0;
	}
	if( Rarity == 6000)
	{
		clColors[0] = 164;
		clColors[1] = 0;
		clColors[2] = 164;
	}
}

LoadEffects(Client)
{
	//Clear Effects
	Effects[Client] = "";
	
	decl String:EffectBuffer[500] = "";
	KvRewind(ItemKV);
	decl String:sItem[5] = "0";
	
	//Loop for Weapon, Shield and Armour
	for(new X = 0; X < 3; X++)
	{
		//Normal
		if(Inventory[Client][X][0] > 0)
		{
			KvJumpToKey(ItemKV, "Normal");
			IntToString(Inventory[Client][X][0], sItem, sizeof(sItem));
			if(KvJumpToKey(ItemKV, sItem, false))
			{
				KvGetString(ItemKV, "Stats", EffectBuffer[strlen(EffectBuffer)], sizeof(EffectBuffer)-strlen(EffectBuffer), "");
				KvGoBack(ItemKV);
			}
			KvGoBack(ItemKV);
			StrCat(EffectBuffer, sizeof(EffectBuffer), " ");
			
			//With Enchantment
			if(Inventory[Client][X][1] > 0)
			{
				KvJumpToKey(ItemKV, "Enchants");
				IntToString(Inventory[Client][X][1], sItem, sizeof(sItem));
				if(KvJumpToKey(ItemKV, sItem, false))
				{
					KvGetString(ItemKV, "Stats", EffectBuffer[strlen(EffectBuffer)], sizeof(EffectBuffer)-strlen(EffectBuffer), "");
					KvGoBack(ItemKV);
				}
				KvGoBack(ItemKV);
				StrCat(EffectBuffer, sizeof(EffectBuffer), " ");
			}
		} else
		//Unique
		if(Inventory[Client][X][0] < 0)
		{
			KvJumpToKey(ItemKV, "Unique");
			IntToString(0 - Inventory[Client][X][0], sItem, sizeof(sItem));
			if(KvJumpToKey(ItemKV, sItem, false))
			{
				KvGetString(ItemKV, "Stats", EffectBuffer[strlen(EffectBuffer)], sizeof(EffectBuffer)-strlen(EffectBuffer), "");
				KvGoBack(ItemKV);
			}
			KvGoBack(ItemKV);
			StrCat(EffectBuffer, sizeof(EffectBuffer), " ");
			
			//No Enchantments for Uniques
		} 
	}
	StrCat(EffectBuffer, sizeof(EffectBuffer), " ");
	//Clean up EffectBuffer
	decl String:ExplEffBuffer[255][8];
	new Count = ExplodeString(EffectBuffer, " ", ExplEffBuffer, 255, 8);
	new Float:D, A, F, Float:S, B, H, bool:RF = false, bool:RB = false;
	for(new X = 0; X < Count; X++)
	{
		switch(ExplEffBuffer[X][0])
		{
			case 'd':
			{
				D += StringToFloat(ExplEffBuffer[X][1]);
			}
			case 'a':
			{
				A += StringToInt(ExplEffBuffer[X][1]);
			}
			case 'f':
			{
				//Fire doesn't stack
				F = (StringToInt(ExplEffBuffer[X][1]) > F) ? StringToInt(ExplEffBuffer[X][1]) : F;
			}
			case 'b':
			{
				//Bleed doesn't stack
				B = (StringToInt(ExplEffBuffer[X][1]) > B) ? StringToInt(ExplEffBuffer[X][1]) : B;
			}
			case 's':
			{
				S += StringToFloat(ExplEffBuffer[X][1]);
			}
			case 'h':
			{
				//Heal DoTs DOES stack
				H += StringToInt(ExplEffBuffer[X][1]);
			}
			case 'r':
			{
				if(ExplEffBuffer[X][1] == 'f')
					RF = true;
				if(ExplEffBuffer[X][1] == 'b')
					RB = true;
			}
		}
	}
	
	//And finally save it
	if(D != 0.0)
		Format(Effects[Client], sizeof(Effects[]), "d%.2f ", D);
	if(A != 0)
		Format(Effects[Client], sizeof(Effects[]), "%sa%d ", Effects[Client], A);
	if(F != 0.0)
		Format(Effects[Client], sizeof(Effects[]), "%sf%d ", Effects[Client], F);
	if(B != 0)
		Format(Effects[Client], sizeof(Effects[]), "%sb%d ", Effects[Client], B);
	if(H != 0)
		Format(Effects[Client], sizeof(Effects[]), "%sh%d ", Effects[Client], H);
	if(RF)
		Format(Effects[Client], sizeof(Effects[]), "%srf ", Effects[Client]);
	if(RB)
		Format(Effects[Client], sizeof(Effects[]), "%srb", Effects[Client]);
		
	//Speed is special
	if(S != 0.0)
	{
		SpeedBoost[Client] = S;
		SetEntPropFloat(Client, Prop_Data, "m_flMaxspeed", 190.0 + SpeedBoost[Client]);
	}
	
	//And add/remove the DoTs
	DoTs[Client][DOTS_HEAL][0] = H;
	DoTs[Client][DOTS_HEAL][1] = Client;
	
	
	StrCat(Effects[Client], sizeof(Effects[]), " ");
}

public Action:timerDoTs(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client))
	{
		if(IsClientInGame(Client))
		{
			if(IsPlayerAlive(Client))
			{
				//Bleed
				if(DoTs[Client][DOTS_BLEED][0] > 0)
				{
					DealDamage(Client, DOTS_BLEEDDAMAGE, DoTs[Client][DOTS_BLEED][1], (1 << 13), "dots_bleed");
					DoTs[Client][DOTS_BLEED][0]--;
					if(DoTs[Client][DOTS_BLEED][0] == 0)
						DoTs[Client][DOTS_BLEED][1] = 0;
					// BLOOOOOOOOOOOOD!
					new Float:Loc[3], Float:Dir[3];
					GetClientEyePosition(Client, Loc);
					GetClientEyeAngles(Client, Dir);
					NegateVector(Dir);
					new BloodEnt = CreateEntityByName("env_blood");
					if(IsValidEdict(BloodEnt))
					{
						DispatchKeyValue(BloodEnt, "spawnflags", "13");
						DispatchKeyValue(BloodEnt, "amount", "30.0");
						DispatchSpawn(BloodEnt);
						SetEntProp(BloodEnt, Prop_Data, "m_Color", 0);
						TeleportEntity(BloodEnt, Loc, Dir, NULL_VECTOR);
						AcceptEntityInput(BloodEnt, "EmitBlood");
						AcceptEntityInput(BloodEnt, "Kill");
					}
				}
				//Fire
				if(DoTs[Client][DOTS_FIRE][0] > 0)
				{
					DealDamage(Client, DOTS_FIREDAMAGE, DoTs[Client][DOTS_FIRE][1], (1 << 3), "dots_fire");
					DoTs[Client][DOTS_FIRE][0]--;
					if(DoTs[Client][DOTS_FIRE][0] == 0)
						DoTs[Client][DOTS_FIRE][1] = 0;
					//Fire, or something like that...
					new Float:Loc[3], Float:Dir[3];
					GetClientEyePosition(Client, Loc);
					Loc[2] -= 20.0;
					GetClientEyeAngles(Client, Dir);
					TE_SetupDust(Loc, Dir, 30.0, 2.0);
					TE_SetupMuzzleFlash(Loc, Dir, 10.0, 1);
					TE_SendToAll();
				}
				//Heal
				if(DoTs[Client][DOTS_HEAL][0] != 0)
				{
					if(DoTs[Client][DOTS_HEAL][0] < 0)
						DealDamage(Client, (0 - DoTs[Client][DOTS_HEAL][0]), DoTs[Client][DOTS_HEAL][1], (1 << 19), "dots_heal");
					else
						SetEntityHealth(Client, (GetClientHealth(Client) + DoTs[Client][DOTS_HEAL][0] > 100) ? 100 : GetClientHealth(Client) + DoTs[Client][DOTS_HEAL][0] );
				}
			}
		}
		return Plugin_Continue;
	} else
		return Plugin_Stop;
}

public Action:timerCmdDelay(Handle:Timer, any:Client)
{
	CommandDelay[Client] = false;
	return Plugin_Handled;
}

stock DealDamage(victim, damage, attacker = 0, dmg_type = 0, String:weapon[]="")
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new PointHurt = CreateEntityByName("point_hurt");
        if(PointHurt)
        {
            DispatchKeyValue(victim,"targetname","dmged_target");
            DispatchKeyValue(PointHurt,"DamageTarget","dmged_target");
            DispatchKeyValue(PointHurt,"Damage",dmg_str);
            DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(weapon,""))
            {
                DispatchKeyValue(PointHurt,"classname",weapon);
            }
            DispatchSpawn(PointHurt);
            AcceptEntityInput(PointHurt,"Hurt",(attacker>0)?attacker:-1);
            DispatchKeyValue(PointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","nondmged_target");
            RemoveEdict(PointHurt);
        }
    }
}

public Action:Command_GiveItem(Client, Args)
{
	if(Args < 2)
	{
		ReplyToCommand(Client, "<Target> <Item> [enchantment]");
		return Plugin_Handled;
	}
	decl String:Buff[64];
	GetCmdArg(1, Buff, sizeof(Buff));
	new Target = FindTarget(Client, Buff);
	GetCmdArg(2, Buff, sizeof(Buff));
	new Item[2] = { 0,0 };
	Item[0] = StringToInt(Buff);
	if(Item[0] == 0)
	{
		ReplyToCommand(Client, "Invalid Item");
		return Plugin_Handled;
	}
	if(Item[0] > 0 && Args > 2)
	{
		GetCmdArg(3, Buff, sizeof(Buff));
		Item[1] = StringToInt(Buff);
	}
	GetItemName(Item, Buff, sizeof(Buff));
	new Slot = GetOpenInventorySlot(Target);
	if( Slot == -1)
	{
		ReplyToCommand(Client, "User doesn't have enough slots");
		if(Client > 0)
		{
			if( Item[0] > 0)
				CPrintToChat(Target, "{green}%N tried giving you a {olive}'%s'", Client, Buff);
			else
				CPrintToChat(Target, "{green}%N tried giving you an unique {default}'%s'", Client, Buff);
		} else 
		{
			if( Item[0] > 0)
				CPrintToChat(Target, "{green}Rcon tried giving you a {olive}'%s'", Client, Buff);
			else
				CPrintToChat(Target, "{green}Rcon tried giving you an unique {default}'%s'", Client, Buff);
		}
		return Plugin_Handled;
	}
	Inventory[Target][Slot] = Item;
	if( Item[0] > 0)
		CPrintToChatAll("{green}%N has given %N a {olive}'%s'", Client, Target, Buff);
	else
		CPrintToChatAll("{green}%N has given %N an unique {default}'%s'", Client, Target, Buff);
	
	decl String:Auth[32];
	decl String:Auth2[32];
	if(Client > 0)
		GetClientAuthString(Client, Auth, sizeof(Auth));
	GetClientAuthString(Target, Auth2, sizeof(Auth2));
	if(Client == 0)
		LogToFile(LogPath, "Rcon gave %N <%s> a '%s' [UID:%d-%d]", Target, Auth2, Buff, Item[0], Item[1]);
	else
		LogToFile(LogPath, "%N <%s> gave %N <%s> a '%s' [UID:%d-%d]", Client, Auth, Target, Auth2, Buff, Item[0], Item[1]);
	return Plugin_Handled;
}

public Action:Command_ReloadItems(Client, Args)
{
	if(ItemKV != INVALID_HANDLE)
		CloseHandle(ItemKV);
	ItemKV = CreateKeyValues("Items");
	FileToKeyValues(ItemKV, ItemPath);
	for(new I = 1; I <= MaxClients; I++)
	{
		if(IsClientConnected(I))
		{
			LoadEffects(I);
		}
	}
	return Plugin_Handled;
}
	
	
public Action:Command_ShowEquip(Client, Args)
{
	if(CommandDelay[Client])
	{
		ReplyToCommand(Client, "No need to rush.");
		return Plugin_Handled;
	}
	new Target;
	if(Args > 0)
	{
		decl String:tString[32];
		GetCmdArgString(tString, sizeof(tString));
		Target = FindTarget(Client, tString);
	}
	if(Target <= 0)
		Target = Client;
		
	ShowEquipment(Client, Target);
	CommandDelay[Client] = true;
	CreateTimer(2.0, timerCmdDelay, Client);
	return Plugin_Handled;
}

public Action:Command_CloseEquip(Client, Args)
{	
	CloseEquipment(Client);
	return Plugin_Handled;
}

public Action:Command_EquipItem(Client, Args)
{
	if(CommandDelay[Client])
	{
		ReplyToCommand(Client, "No need to rush.");
		return Plugin_Handled;
	}
	CommandDelay[Client] = true;
	CreateTimer(2.0, timerCmdDelay, Client);
	new Handle:Menu = CreateMenu(HandleEquip);
	SetMenuTitle(Menu, "Select which item to equip");
	decl String:NameBuffer[64];
	decl String:Slot[5];
	for(new X = 3; X < TOTAL_SLOTS; X++)
	{
		if(Inventory[Client][X][0] != 0)
		{
			GetItemName(Inventory[Client][X], NameBuffer, sizeof(NameBuffer));
			IntToString(X, Slot, sizeof(Slot));
			AddMenuItem(Menu, Slot, NameBuffer);
		}
	}
	if(GetMenuItemCount(Menu) > 0)
		DisplayMenu(Menu, Client, 30);
	else
		CloseHandle(Menu);
	return Plugin_Handled;
}

public HandleEquip(Handle:menu, MenuAction:Menu_Action, Client, item)
{
	if(Menu_Action == MenuAction_Select)
	{
		decl String:Info[32];
		if(GetMenuItem(menu, item, Info, sizeof(Info)))
		{
			new Slot = StringToInt(Info);
			KvRewind(ItemKV);
			if(Inventory[Client][Slot][0] > 0)
				KvJumpToKey(ItemKV, "Normal");
			else
				KvJumpToKey(ItemKV, "Unique");
			decl String:sItem[5];
			IntToString((Inventory[Client][Slot][0] > 0)?Inventory[Client][Slot][0]:(0 - Inventory[Client][Slot][0]), sItem, sizeof(sItem));
			if(KvJumpToKey(ItemKV, sItem, false))
			{
				new TempItem[2];
				decl String:Type[32];
				KvGetString(ItemKV, "Type", Type, sizeof(Type), "Other");
				if(StrEqual(Type, "weapon", false))
				{
					TempItem = Inventory[Client][0];
					Inventory[Client][0] = Inventory[Client][Slot];
					Inventory[Client][Slot] = TempItem;
				}
				if(StrEqual(Type, "shield", false))
				{
					TempItem = Inventory[Client][1];
					Inventory[Client][1] = Inventory[Client][Slot];
					Inventory[Client][Slot] = TempItem;
				}
				if(StrEqual(Type, "armour", false))
				{
					TempItem = Inventory[Client][2];
					Inventory[Client][2] = Inventory[Client][Slot];
					Inventory[Client][Slot] = TempItem;
				}
			}
			LoadEffects(Client);
		} else
		{
			PrintToChat(Client, "Stop trying to glitch.");
			decl String:Auth[32];
			GetClientAuthString(Client, Auth, sizeof(Auth));
			LogToFile(LogPath, "%N <%s> used menu item %d while having %d items in inventory.", Client, Auth, item, GetInventoryCount(Client));
		}
	}
	else if( Menu_Action == MenuAction_End )
	{
		CloseHandle( menu );
	}
}

public Action:Command_DonateItem(Client, Args)
{
	if(CommandDelay[Client])
	{
		ReplyToCommand(Client, "No need to rush.");
		return Plugin_Handled;
	}
	CommandDelay[Client] = true;
	CreateTimer(2.0, timerCmdDelay, Client);
	new Handle:Menu = CreateMenu(HandleDonate);
	SetMenuTitle(Menu, "Select which item to donate");
	decl String:NameBuffer[64];
	decl String:Slot[5];
	for(new X = 3; X < TOTAL_SLOTS; X++)
	{
		if(Inventory[Client][X][0] != 0)
		{
			GetItemName(Inventory[Client][X], NameBuffer, sizeof(NameBuffer));
			IntToString(X, Slot, sizeof(Slot));
			AddMenuItem(Menu, Slot, NameBuffer);
		}
	}
	if(GetMenuItemCount(Menu) > 0)
		DisplayMenu(Menu, Client, 30);
	else
		CloseHandle(Menu);
	return Plugin_Handled;
}

public HandleDonate(Handle:menu, MenuAction:Menu_Action, Client, item)
{
	if(Menu_Action == MenuAction_Select)
	{
		decl String:Info[32];
		if(GetMenuItem(menu, item, Info, sizeof(Info)))
		{
			new Slot = StringToInt(Info);
			decl String:Buff[64];
			new Rarity = GetItemName(Inventory[Client][Slot], Buff, sizeof(Buff));
			RarityBoost[Client] += RoundToFloor(Rarity * DONATION_MULTIPLIER);
			if( Inventory[Client][Slot][0] > 0)
				CPrintToChatAll("{green}%N has given a {olive}'%s'{green} to charity.", Client, Buff);
			else
				CPrintToChatAll("{green}%N has given an unique {default}'%s'{green} to charity.", Client, Buff);	
			decl String:Auth[32];
			GetClientAuthString(Client, Auth, sizeof(Auth));
			LogToFile(LogPath, "%N <%s> donated [UID:%d-%d] in Slot %d.", Client, Auth, Inventory[Client][Slot][0], Inventory[Client][Slot][1], Slot);
			Inventory[Client][Slot][0] = 0;
			Inventory[Client][Slot][1] = 0;
			LoadEffects(Client);
		} else
		{
			PrintToChat(Client, "Stop trying to glitch.");
			decl String:Auth[32];
			GetClientAuthString(Client, Auth, sizeof(Auth));
			LogToFile(LogPath, "%N <%s> used menu item %d while having %d items in inventory.", Client, Auth, item, GetInventoryCount(Client));
		}
	}
	else if( Menu_Action == MenuAction_End )
	{
		CloseHandle( menu );
	}
}

public cbCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_DropChance)
	{
		PrintToChatAll("Drop Chance changed to %s", newValue);
		DROP_CHANCE = StringToInt(newValue);
	} else
	if(convar == Cvar_EnchantChance)
	{
		PrintToChatAll("Enchant Chance changed to %s", newValue);
		ENCHANT_CHANCE = StringToInt(newValue);
	} else
	if(convar == Cvar_DefenseRatio)
	{
		PrintToChatAll("Defense Ratio changed to %s", newValue);
		DEFENSE_RATIO = StringToFloat(newValue);
	} else
	if(convar == Cvar_DonationMultiplier)
	{
		PrintToChatAll("Donation Multiplier changed to %s", newValue);
		DONATION_MULTIPLIER = StringToFloat(newValue);
	} else
	if(convar == Cvar_DotDelay)
	{
		PrintToChatAll("DoT Delay changed to %s. Effect will be noticed once you rejoin.", newValue);
		DOTS_DELAY = StringToFloat(newValue);
	} else
	if(convar == Cvar_DotBleedDamage)
	{
		PrintToChatAll("Bleed Damage changed to %s", newValue);
		DOTS_BLEEDDAMAGE = StringToInt(newValue);
	} else
	if(convar == Cvar_DotBurnDamage)
	{
		PrintToChatAll("Burn Damage changed to %s", newValue);
		DOTS_FIREDAMAGE = StringToInt(newValue);
	} else	
	if(convar == Cvar_ShowEquipmentOverlay)
	{
		PrintToChatAll("Show Equipment Overlay changed to %s", newValue);
		SHOW_EQUIPMENTOVERLAY = StringToInt(newValue) != 0;
	} else
	if(convar == Cvar_MaxRarity)
	{
		PrintToChatAll("Max Random Rarity changed to %s", newValue);
		MAX_RARITY = StringToInt(newValue);
	} else	
	if(convar == Cvar_MaxRarityEnchant)
	{
		PrintToChatAll("Max Random Enchant Rarity changed to %s", newValue);
		MAX_RARITY_ENCHANT = StringToInt(newValue);
	} else	
	{
		PrintToServer("Missing cvar in cbCvarChange");
	}
}