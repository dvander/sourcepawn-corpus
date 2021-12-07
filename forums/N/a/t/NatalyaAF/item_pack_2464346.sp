// An Item Database for CS:GO
// Script by Natalya

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <roleplay_classes>
#include <emitsoundany>

#define PLUGIN_VERSION	"0.86 GO"
#define MAXITEMS		500
#define MAXCATEGORIES	100



new Handle:g_Cvar_Database = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_Slots = INVALID_HANDLE;
new Handle:g_Cvar_Interval = INVALID_HANDLE;
new Handle:g_Cvar_HInterval = INVALID_HANDLE;
new Handle:g_ItemTimer = INVALID_HANDLE;
new Handle:g_NotifyTimer = INVALID_HANDLE;
new Handle:db_items = INVALID_HANDLE;
new Handle:g_PackMenu = INVALID_HANDLE;
new Handle:g_InvMenu = INVALID_HANDLE;
new Handle:g_BuyMenu = INVALID_HANDLE;
new Handle:g_InfoMenu = INVALID_HANDLE;
new Handle:itembuykv;
new Handle:itemcatkv;
new Handle:h_drunk_a = INVALID_HANDLE;
new Handle:h_drunk_b = INVALID_HANDLE;

new g_flProgressBarStartTime;
new g_iProgressBarDuration;

// Database Creation
new item_quantity = 0;
new String:item_name[MAXITEMS][64];
new String:item_type[MAXITEMS][64];
new item_enabled[MAXITEMS];				// Lets you disable the item but not mess up a player's inventory.  Defaults to 1.
new item_price[MAXITEMS];
new item_flags[MAXITEMS];
new Float:item_dmgscale[MAXITEMS];
new item_minhealthdmg[MAXITEMS];
new item_slots[MAXITEMS];
new String:item_model[MAXITEMS][256];
new item_use_mode[MAXITEMS];			// If you press Use on it what happens?  0 = goes to inventory   1 = used on the spot
new item_buy_mode[MAXITEMS];			// 0 = Anyone   1 = Team   2 = Class
new item_team[MAXITEMS];				// Team index which can buy this item.
new item_class[MAXITEMS];				// Class index which can buy this item.
new item_vip[MAXITEMS];
new item_amount[MAXITEMS]; 				// This means like, if it's a health pack for example, how much health it would give you.
new item_duration[MAXITEMS]; 			// How long its effect lasts.  (Alcohol or Drugs for example...)
new item_buy_quantity[MAXITEMS]; 		// Defaults to 1, but if more means you buy in bulk.
new String:item_entity[MAXITEMS][64];	// weapon_awp, prop_physics...
new item_cat[MAXITEMS];
new item_vendable[MAXITEMS];
new item_food_used = 0;
new item_vend_used = 0;
new Float:item_angles[MAXITEMS][3];
new Float:item_position[MAXITEMS][3];

// Category Creation
new cat_quantity = 0;
new cat_enabled[MAXCATEGORIES];
new String:cat_name[MAXCATEGORIES][64];
new started = 0;


// Player Loading to Database
public bool:InQuery;
public bool:IsDisconnect[33];
public bool:Loaded[33];


// Individual Player Arrays
public bool:holstering[MAXPLAYERS+1];
public bool:AtVend[MAXPLAYERS+1];
new Float:player_pos[MAXPLAYERS+1][3];
new String:authid[MAXPLAYERS+1][35];
new Item[MAXPLAYERS+1][MAXITEMS];
new slots[MAXPLAYERS+1];
new selected_item[MAXPLAYERS+1];
new hunger[MAXPLAYERS+1];
new Drunk[MAXPLAYERS+1];
new DrunkTime[MAXPLAYERS+1];
new unlocking_ent[MAXPLAYERS+1];
new wearing_hat_type[MAXPLAYERS+1];
new wearing_hat_number[MAXPLAYERS+1];

// Command Offsets
new offsPunchAngle;

public Plugin:myinfo =
{
	name = "Item Pack",
	author = "Natalya[AF]",
	description = "Natalya's item pack plugin.",
	version = PLUGIN_VERSION,
	url = "http://www.lady-natalya.info/"
}

public OnPluginStart()
{
	// Load Translations
	LoadTranslations("plugin.item_pack");

	RegConsoleCmd("sm_item", Command_Item, "Open the Item Menu");
	RegConsoleCmd("sm_inventaire", Command_Item, "Ouvrir l'inventorie.");
	RegConsoleCmd("sm_holster_p", Command_HolsterP, "Holster Your Primary Weapon");
	RegConsoleCmd("sm_ranger_p", Command_HolsterP, "Ranger l'arme primaire.");
	RegConsoleCmd("sm_holster_s", Command_HolsterS, "Holster Your Secondary Weapon");
	RegConsoleCmd("sm_ranger_s", Command_HolsterS, "Ranger l'arme secondaire.");
	RegConsoleCmd("sm_remove_hat", Command_Hat, "Put away your hat.");
	RegConsoleCmd("sm_ranger_chapeau", Command_Hat, "Ranger le chapeau.");
	RegAdminCmd("item_db_save", Command_DBSave, ADMFLAG_CUSTOM3, "Force Server DB Save");
	
	CreateConVar("item_pack_version", PLUGIN_VERSION, "Version of Natalya's item pack plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Enable = CreateConVar("item_pack_enabled", "1", "Enables or Disables item pack", FCVAR_PLUGIN);
	g_Cvar_Slots = CreateConVar("item_maxslots", "50", "Sets the maximum slot number.", FCVAR_PLUGIN);
	g_Cvar_Interval = CreateConVar("item_save_interval", "3600.0", "Interval between Item DB saves in seconds.  Set higher if server doesn't crash frequently.", FCVAR_PLUGIN);
	g_Cvar_HInterval = CreateConVar("item_hunger_interval", "30.0", "Interval between hunger increase in seconds.  Set higher for slower hunger.", FCVAR_PLUGIN);
	g_Cvar_Database = CreateConVar("item_db_mode", "0", "DB Location 1 = remote or 2 = local -- 0 = failure", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);


	HookEvent("round_start", RoundStartEvent, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	
	offsPunchAngle = FindSendPropInfo("CBasePlayer", "m_vecPunchAngle");
	
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{ 
			GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
			Loaded[client] = false;
			holstering[client] = false;
			AtVend[client] = false;
			DeleteHat(client, true);
	
			CreateTimer(1.0, CreateSQLAccount, client);
		}
	}
	
	PrecacheSound("buttons/blip2.wav", false);
	
	// Load Items -- This builds arrays for all the items and every piece of info they need.
	LoadItems();
	// Load Categories
	LoadCategories();

	// Lockpick Timer
	g_flProgressBarStartTime = FindSendPropOffs("CCSPlayer", "m_flProgressBarStartTime");
	if(g_flProgressBarStartTime == -1)
		SetFailState("Couldnt find the m_flProgressBarStartTime offset!");
	g_iProgressBarDuration = FindSendPropOffs("CCSPlayer", "m_iProgressBarDuration");
	if(g_iProgressBarDuration == -1)
		SetFailState("Couldnt find the m_iProgressBarDuration offset!");
}
public OnConfigsExecuted()
{
	PrecacheSoundAny("buttons/blip2.wav", true);
	PrecacheSoundAny("doors/latchunlocked1.wav", true);
	AddFileToDownloadsTable("buttons/blip2.wav");
	AddFileToDownloadsTable("doors/latchunlocked1.wav");

	AddFileToDownloadsTable("models/natalya/weapons/armour.mdl");
	AddFileToDownloadsTable("models/natalya/weapons/armour.vvd");
	AddFileToDownloadsTable("models/natalya/weapons/armour.phy");
	AddFileToDownloadsTable("models/natalya/weapons/armour.sw.vtx");
	AddFileToDownloadsTable("models/natalya/weapons/armour.dx80.vtx");
	AddFileToDownloadsTable("models/natalya/weapons/armour.dx90.vtx");
	AddFileToDownloadsTable("materials/models/natalya/weapons/armour.vtf");
	AddFileToDownloadsTable("materials/models/natalya/weapons/armour.vmt");
	AddFileToDownloadsTable("models/natalya/weapons/crowbar.mdl");
	AddFileToDownloadsTable("models/natalya/weapons/crowbar.vvd");
	AddFileToDownloadsTable("models/natalya/weapons/crowbar.phy");
	AddFileToDownloadsTable("models/natalya/weapons/crowbar.sw.vtx");
	AddFileToDownloadsTable("models/natalya/weapons/crowbar.dx80.vtx");
	AddFileToDownloadsTable("models/natalya/weapons/crowbar.dx90.vtx");
	AddFileToDownloadsTable("materials/models/natalya/weapons/crowbar_cyl.vtf");
	AddFileToDownloadsTable("materials/models/natalya/weapons/crowbar_cyl.vmt");
	AddFileToDownloadsTable("materials/models/natalya/weapons/crowbar_normal.vtf");
	AddFileToDownloadsTable("materials/models/natalya/weapons/head_normal.vtf");
	AddFileToDownloadsTable("materials/models/natalya/weapons/head.vtf");
	AddFileToDownloadsTable("materials/models/natalya/weapons/head.vmt");
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[],  err_max)
{
/*	CreateNative("GetClientHat", NativeGetClientHat);
	CreateNative("GetClientHatEntity", NativeGetClientHatEntity);
	CreateNative("SetHatEntityToParent", NativeSetHatEntityToParent); */
	RegPluginLibrary("item_pack");
	return APLRes_Success;
}
// native functions
public NativeGetClientHat(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return wearing_hat_type[client];
}
public NativeGetClientHatEntity(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return wearing_hat_number[client];
}
public NativeSetHatEntityToParent(Handle:plugin, numParams)
{
	new bool:success;
	success = false;
	
	new hat = GetNativeCell(1);
	new parententity = GetNativeCell(2);
	new type = GetNativeCell(3);
	
	new Float:origin[3];
	new Float:angle[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	
	HatMath(parententity, type, origin, angle, fForward, fRight, fUp);
	
	AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
	SetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity", parententity);
	
	// Teleport the hat.

	TeleportEntity(hat, origin, angle, NULL_VECTOR);
	
	if (parententity > MaxClients)
	{
		new String:car_ent_name[128];
		GetTargetName(parententity, car_ent_name, sizeof(car_ent_name));		
		SetVariantString(car_ent_name);
	}
	else SetVariantString("!activator");
		
	AcceptEntityInput(hat, "SetParent", parententity, hat, 0);
	
	if (parententity > MaxClients)
	{
		SetVariantString("n_head");
	}
	else SetVariantString("forward");
	
	AcceptEntityInput(hat, "SetParentAttachmentMaintainOffset", hat, hat, 0);	
	
	success = true;
	return success;
}



// #############
// PLUGIN EVENTS
// #############



public OnMapStart()
{
	HookEvent("player_spawn", PlayerSpawnEvent);
	if (GetConVarInt(g_Cvar_Enable))
	{
		g_PackMenu = BuildPackMenu();
		g_BuyMenu = BuildBuyMenu();
		g_InfoMenu = BuildInfoMenu();
		new Float:interval_time = GetConVarFloat(g_Cvar_Interval);
		g_ItemTimer = CreateTimer(interval_time, Item_Time, INVALID_HANDLE, TIMER_REPEAT);
		new Float:hunger_time = GetConVarFloat(g_Cvar_HInterval);
		g_ItemTimer = CreateTimer(hunger_time, Hunger_Time, INVALID_HANDLE, TIMER_REPEAT);
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{ 
				holstering[client] = false;
			}
		}
	}
	if (item_vend_used == 1)
	{
		// Hook Vending Machine Stuff Here
		HookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
		HookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
	}
	PrecacheSound("buttons/blip2.wav", false);
	PrecacheSound("doors/latchunlocked1.wav", false);
	
	// This handles the database mode.
	if (started == 0)
	{
		new db_mode = GetConVarInt(g_Cvar_Database);
		if (db_mode == 0)
		{
			CreateTimer(1.0, FUCKING_DB_MODE_NOT_0);
		}
		else InitializeItemDB();
	}
}
public Action:FUCKING_DB_MODE_NOT_0(Handle:Timer, any:client)
{
	new db_mode = GetConVarInt(g_Cvar_Database);
	if (db_mode == 0)
	{
		PrintToChatAll("\x03[Item] item_db_mode is 0 -- set it to 1 or 2");
		CreateTimer(1.0, FUCKING_DB_MODE_NOT_0);
	}
	else InitializeItemDB();
}
public OnMapEnd()
{
	if (item_vend_used == 1)
	{
		UnhookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
		UnhookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
	}
	if (g_PackMenu != INVALID_HANDLE)
	{
		CloseHandle(g_PackMenu);
		g_PackMenu = INVALID_HANDLE;
	}
	if (g_InvMenu != INVALID_HANDLE)
	{
		CloseHandle(g_InvMenu);
		g_InvMenu = INVALID_HANDLE;
	}
	if (g_BuyMenu != INVALID_HANDLE)
	{
		CloseHandle(g_BuyMenu);
		g_BuyMenu = INVALID_HANDLE;
	}
	if (g_InfoMenu != INVALID_HANDLE)
	{
		CloseHandle(g_InfoMenu);
		g_InfoMenu = INVALID_HANDLE;
	}
	if (g_ItemTimer != INVALID_HANDLE)
	{
		CloseHandle(g_ItemTimer);
		g_ItemTimer = INVALID_HANDLE;
	}
	if (g_NotifyTimer != INVALID_HANDLE)
	{
		CloseHandle(g_NotifyTimer);
		g_NotifyTimer = INVALID_HANDLE;
	}
	if (h_drunk_a != INVALID_HANDLE)
	{
		CloseHandle(h_drunk_a);
		h_drunk_a = INVALID_HANDLE;
	}
	if (h_drunk_b != INVALID_HANDLE)
	{
		CloseHandle(h_drunk_b);
		h_drunk_b = INVALID_HANDLE;
	}
	UnhookEvent("player_spawn", PlayerSpawnEvent);
}
public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{ 
			holstering[client] = false;
		}
	}
}
public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		Drunk[client] = 0;
		DrunkTime[client] = 0;
		AtVend[client] = false;
	}
}
public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{	
			GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
			PrintToServer("[ITEM] Plugin Ending -- updating client in SQL Database.", authid[client]);
			LogMessage("[ITEM] Plugin Ending -- updating client in SQL Database.", authid[client]);
			DBSave(client);
		}
	}
}
public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if (0 < activator <= MaxClients)
	{
		if(caller == -1)
			return;
		if(!IsPlayerAlive(activator))
			return;
		if(!IsClientInGame(activator))
			return;
		if(item_vend_used == 1)
		{
			new String:classname[64];
			new String:targetname[64];
		
			GetEdictClassname(caller,classname,sizeof(classname));
			if(StrEqual(classname,"trigger_multiple"))
			{
				GetTargetName(caller,targetname,sizeof(targetname));
				if(StrEqual(targetname,"vend"))
				{
					AtVend[activator] = true;
					new Handle:vend = CreateMenu(Menu_Vend);
					
					decl String:title_str[64];
					Format(title_str, sizeof(title_str), "%T", "Vend_Menu", activator);
					SetMenuTitle(vend, title_str);
					
					new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
					new money = GetEntData(activator, MoneyOffset);
					
					decl String:buffer[64];
					decl String:X_str[8];
					new price = 0;
					for(new X = 0;X < MAXITEMS;X++)
					{
						if (item_vendable[X] == 1)
						{
							price = (item_price[X] / item_buy_quantity[X]);
							Format(buffer, sizeof(buffer), "%s $%i", item_name[X], price);
							Format(X_str, sizeof(X_str), "%i", X);
							if (slots[activator] >= item_slots[X])
							{
								if (money >= price)
								{
									AddMenuItem(vend, X_str, buffer);
								}
								else
								{
									AddMenuItem(vend, X_str, buffer, ITEMDRAW_DISABLED);
								}
							}
							else
							{
								AddMenuItem(vend, X_str, buffer, ITEMDRAW_DISABLED);
							}
						}
					}				
					DisplayMenu(vend, activator, MENU_TIME_FOREVER);
				}
			}
		}
	}
	return;
}
public Menu_Vend(Handle:vend, MenuAction:action, param1, param2)
{
	// User has walked up to a Vending Machine
	if (action == MenuAction_Select)
	{
		if(item_vend_used == 1)
		{
			if (AtVend[param1] == false)
			{
				PrintToChat(param1, "\x03[Item] %T", "Go_To_Vend", param1);
				return;			
			}
		}
		if(!IsPlayerAlive(param1))
		return;
		if(!IsClientInGame(param1))
		return;
		
		new String:info[32];
		GetMenuItem(vend, param2, info, sizeof(info));
		new X = StringToInt(info, 10);

		if (X > -1)
		{
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			new money = GetEntData(param1, MoneyOffset, 4);
			new price = (item_price[X] / item_buy_quantity[X]);
			if (money >= price)
			{
				if (slots[param1] >= item_slots[X])
				{
					SetEntData(param1, MoneyOffset, money - price, 4, true);
					SetClientMoney(param1, money - price);
					slots[param1] -= item_slots[X];
					PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[X]);
					Item[param1][X] += 1;
				}
				else
				{
					PrintToChat(param1, "\x04[Item] %T", "Need_Slots", param1, item_slots[X]);
					return;
				}
			}
			else
			{
				PrintToChat(param1, "\x04[Item] %T", "Expensive", param1, price);
				return;
			}
		}
	}
	return;
}
public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if (0 < activator <= MaxClients)
	{
		if(caller == -1)
			return;
		if(!IsClientInGame(activator))
			return;
		if(!IsPlayerAlive(activator))
			return;

		new String:classname[64];
		new String:targetname[64];
			
		GetEdictClassname(caller,classname,sizeof(classname));
		if(StrEqual(classname,"trigger_multiple"))
		{
			GetTargetName(caller,targetname,sizeof(targetname));
			if(StrEqual(targetname,"vend"))
			{
				if(item_vend_used == 1)
				{
					AtVend[activator] = false;
				}
			}
		}
	}
	return;
}
stock GetTargetName(entity, String:buf[], len)
{
	// Thanks to Joe Maley for this.
	GetEntPropString(entity, Prop_Data, "m_iName", buf, len);
}


//	######################
//	Load Items and Item DB
//	######################




public LoadItems()
{
	itembuykv = CreateKeyValues("Commands");
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/items.ini");
	FileToKeyValues(itembuykv, file);

	KvRewind(itembuykv);

	if (!KvGotoFirstSubKey(itembuykv))
	{
		PrintToServer("[item_pack.smx] There are no items listed in items.ini, or there is an error with the file.");
		SetFailState("[item_pack.smx] There are no items listed in items.ini, or there is an error with the file.");
	}
	
	new i = 0;
	do
	{
		KvGetSectionName(itembuykv, item_name[i], sizeof(item_name[]));
		KvGetString(itembuykv, "type", item_type[i], sizeof(item_type[]), "INVALID");
		if (StrEqual(item_type[i], "food", false))
		{
			item_food_used = 1;
		}
		if (StrEqual(item_type[i], "hat", false))
		{	
			new Float:temp[3];
			
			KvGetVector(itembuykv, "position", temp);
			item_position[i] = temp;
			KvGetVector(itembuykv, "angles", temp);
			item_angles[i] = temp;		
		}
		item_enabled[i] = KvGetNum(itembuykv, "enabled", 1);
		item_price[i] = KvGetNum(itembuykv, "price", 2000);
		if (item_price[i] < 0)
		{
			item_enabled[i] = 0;
			PrintToServer("[RP] Item %s (#%i) Disabled -- price less than 0.", item_name[i], 1);
		}
		item_slots[i] = KvGetNum(itembuykv, "slots", 1);
		if (item_slots[i] < 1)
		{
			item_enabled[i] = 0;
			PrintToServer("[RP] Item %s (#%i) Disabled -- slots less than 1.", item_name[i], 1);
		}
		KvGetString(itembuykv, "model", item_model[i], sizeof(item_model[]), "INVALID");
		item_use_mode[i] = KvGetNum(itembuykv, "use_mode", 0);
		item_buy_mode[i] = KvGetNum(itembuykv, "buy_mode", 0);
		if (item_buy_mode[i] == 0)
		{
			item_team[i] = -1;
			item_class[i] = -1;
		}
		if (item_buy_mode[i] == 1)
		{
			item_team[i] = KvGetNum(itembuykv, "team", -1);
			if (item_team[i] < 0)
			{
				item_buy_mode[i] = 0;
			}
			item_class[i] = -1;
		}
		if (item_buy_mode[i] == 2)
		{
			item_class[i] = KvGetNum(itembuykv, "class", -1);
			if (item_class[i] < 0)
			{
				item_buy_mode[i] = 0;
			}
			item_team[i] = -1;
		}			
		item_vip[i] = KvGetNum(itembuykv, "vip", 0);
		item_flags[i] = KvGetNum(itembuykv, "flags", -1);
		if (item_flags[i] > -1)
		{
			PrintToServer("Item #%i has Spawn Flags: %i", i, item_flags[i]);
		}
		item_dmgscale[i] = KvGetFloat(itembuykv, "physdamagescale", 1.0);
		if (item_dmgscale[i] < 1)
		{
			PrintToServer("Item #%i has physdamagescale: %f", i, item_dmgscale[i]);
		}
		item_minhealthdmg[i] = KvGetNum(itembuykv, "minhealthdmg", 0);
		if (item_minhealthdmg[i] > 0)
		{
			PrintToServer("Item #%i has minhealthdmg: %i", i, item_minhealthdmg[i]);
		}
		item_amount[i] = KvGetNum(itembuykv, "amount", 0);
		item_duration[i] = KvGetNum(itembuykv, "duration", 0);
		item_buy_quantity[i] = KvGetNum(itembuykv, "buy_quantity", 1);
		item_vendable[i] = KvGetNum(itembuykv, "vend", 0);
		if (item_vendable[i] == 1)
		{
			item_vend_used = 1;
		}
		if (item_buy_quantity[i] < 1)
		{
			item_enabled[i] = 0;
			PrintToServer("[RP] Item %s (#%i) Disabled -- buy_quantity less than 1.", item_name[i], 1);
		}
		KvGetString(itembuykv, "entity", item_entity[i], sizeof(item_entity[]), "INVALID");
		item_cat[i] = KvGetNum(itembuykv, "category", 0);
		
		i += 1;

	} while (KvGotoNextKey(itembuykv) && (i < MAXITEMS));
	
	item_quantity = i;

	KvRewind(itembuykv);
	
	PrintToServer("[RP Items] Items Loaded");
	PrintToServer("[RP Items] %i Items were detected.", item_quantity);
	if (item_food_used == 0)
	{
		PrintToServer("[RP Items] No Food Detected");
	}
	else if (item_food_used == 1)
	{
		PrintToServer("[RP Items] Food Detected -- Enabling Hunger Mode");
	}
	if (item_vend_used == 0)
	{
		PrintToServer("[RP Items] No Vending Machine Items Detected");
	}
	else if (item_vend_used == 1)
	{
		PrintToServer("[RP Items] Vending Machine Items Detected -- Enabling Vending Machine Menu");
	}
	
	// Now make a super item quantity array!!
}
public LoadCategories()
{
	itemcatkv = CreateKeyValues("Categories");
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/item_categories.ini");
	FileToKeyValues(itemcatkv, file);
	
	if (!KvGotoFirstSubKey(itemcatkv))
	{
		PrintToServer("[item_pack.smx] There are no categories listed in item_categories.ini, or there is an error with the file.");
		SetFailState("[item_pack.smx] There are no categories listed in item_categories.ini, or there is an error with the file.");
	}

	new i = 0;
	do
	{
		KvGetString(itemcatkv, "name", cat_name[i], sizeof(cat_name[]), "INVALID");
		cat_enabled[i] = KvGetNum(itemcatkv, "enabled", 1);
		cat_quantity += 1;
		i += 1;
	} while ((KvGotoNextKey(itemcatkv)) && (cat_quantity < MAXCATEGORIES));
	
	KvRewind(itemcatkv);
	
	PrintToServer("[RP] Item Categories Loaded");
	PrintToServer("[RP] %i Categories were detected.", cat_quantity);
}
public InitializeItemDB()
{
	// Same as createdbitems
	new String:error[255];
	new db_mode = GetConVarInt(g_Cvar_Database);
	
	if (db_mode == 1)
	{
		// MySQL
		
		db_items = SQL_Connect("ln-roleplay", true, error, sizeof(error));
		if(db_items == INVALID_HANDLE)
		{
			SetFailState("[item_pack.smx] %s", error);
		}
		
		// Stuff
		new len = 0;
		decl String:query[20000];
		
		// Format the DB Item Table
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Items`");
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0, ");
		for(new i= 1; i < MAXITEMS; i++)	//its running till MAXITEMS-1 !! , this array will go between 0-499 if MAXITEMS = 500
		{
			len += Format(query[len], sizeof(query)-len, "`%i` int(25) NOT NULL DEFAULT 0, ", i);
		}
		len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`));");
		
		
		// Lock and Load!!
		SQL_LockDatabase(db_items);
		SQL_FastQuery(db_items, query);
		SQL_UnlockDatabase(db_items);
		started = 1;		
	}
	else if (db_mode == 2)
	{
		// SQLite
		
		//db_items = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "rp_items", error, sizeof(error), true, 0);
		db_items = SQLite_UseDatabase("rp_items", error, sizeof(error));
		if(db_items == INVALID_HANDLE)
		{
			SetFailState("[item_pack.smx] %s", error);
		}
		
		// Stuff
		new len = 0;
		decl String:query[20000];
		
		// Format the DB Item Table
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Items`");
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0, ");
		for(new i= 1; i < MAXITEMS; i++)	//its running till MAXITEMS-1 !! , this array will go between 0-499 if MAXITEMS = 500
		{
			len += Format(query[len], sizeof(query)-len, "`%i` int(25) NOT NULL DEFAULT 0, ", i);
		}
		len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`));");
		
		
		// Lock and Load!!
		SQL_LockDatabase(db_items);
		SQL_FastQuery(db_items, query);
		SQL_UnlockDatabase(db_items);
		started = 1;
	}
	else
	{
		Format(error, sizeof(error), "[Item] item_db_mode is %i when it needs to be 1 or 2.", db_mode);
		SetFailState("[item_pack.smx] %s", error);
	}
}


//	###################
//	Generate Item Menus
//	###################



Handle:BuildPackMenu()
{
	new Handle:items = CreateMenu(Menu_Items);
	AddMenuItem(items, "g_InvMenu", "Inventory");
	AddMenuItem(items, "g_BuyMenu", "Buy Menu");
	AddMenuItem(items, "g_InfoMenu", "Help?");

	SetMenuTitle(items, "Item Menu:");
	return items;
}
public Menu_Items(Handle:items, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(items, param2, info, sizeof(info));
		if (StrEqual(info,"g_InvMenu"))
		{	
			new Handle:inv_cats = CreateMenu(Menu_Inv_Categories);
			decl String:title_str[64];
			if (slots[param1] == 0)
			{		
				Format(title_str, sizeof(title_str), "%T", "Inv_Full", param1);
			}
			else
			{
				Format(title_str, sizeof(title_str), "%T", "Inventory", param1);
			}
			SetMenuTitle(inv_cats, title_str);

			new max_slots = GetConVarInt(g_Cvar_Slots);
			if (slots[param1] >= max_slots)
			{
				new String:itemless_str[64];
				Format(itemless_str, sizeof(itemless_str), "%T", "Itemless", param1);
				AddMenuItem(inv_cats, "9001", itemless_str, ITEMDRAW_DISABLED);
				DisplayMenu(inv_cats, param1, MENU_TIME_FOREVER);
				return;
			}			
			else
			{
				
				new cat_owned[cat_quantity];
				new cat = 0;
				for (new index = 0; index < item_quantity; index++)
				{
					if (Item[param1][index] > 0)
					{
						cat = item_cat[index];
						cat_owned[cat] = 1;
					}
				}		
				
				decl String:cat_str[4];
				for (new i = 0; i < cat_quantity; i++)
				{
					Format(cat_str, sizeof(cat_str), "%i", i);
					if (cat_enabled[i] == 1)
					{
						if (cat_owned[i] == 1)
						{
							AddMenuItem(inv_cats, cat_str, cat_name[i]);
						}
						else AddMenuItem(inv_cats, cat_str, cat_name[i], ITEMDRAW_DISABLED);
					}
				}		
				DisplayMenu(inv_cats, param1, MENU_TIME_FOREVER);
				selected_item[param1] = -1;
				return;
			}		
		}
		if (StrEqual(info,"g_BuyMenu"))
		{
			DisplayMenu(g_BuyMenu, param1, 20);
		}
		if (StrEqual(info,"g_InfoMenu"))
		{
			DisplayMenu(g_InfoMenu, param1, 20);\
		}
	}
}
public Menu_Inv_Categories(Handle:inv_cats, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(inv_cats, param2, info, sizeof(info));
		new cat = StringToInt(info);
		
		/* Create the menu Handle */
		new Handle:inv = CreateMenu(Menu_Inventory);

		decl String:buffer[64];
		decl String:X_str[8];
		for(new X = 0;X < MAXITEMS;X++)
		{
			if (Item[param1][X] > 0)
			{
				if (item_cat[X] == cat)
				{
					Format(X_str, sizeof(X_str), "%i", X);
					Format(buffer, sizeof(buffer), "%s (%i)", item_name[X], Item[param1][X]);
					AddMenuItem(inv, X_str, buffer);
				}
			}
		}
		SetMenuTitle(inv, cat_name[cat]);
			
		DisplayMenu(inv, param1, MENU_TIME_FOREVER);
	}
}			
public Menu_Inventory(Handle:inv, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!IsClientHandcuffed(param1))
		{
			new String:info[32];
			GetMenuItem(inv, param2, info, sizeof(info));
			new index = StringToInt(info);

			// They chose an item.  Give them the options to use it, discard it, drop 1, or drop all.
			/* Create the menu Handle */
			new Handle:use = CreateMenu(Menu_Use);
			new String:use_str[32], String:trash_str[32], String:drop_str[32], String:drop_all_str[32], String:title_str[32];
			if (StrEqual(item_type[index], "food", false))
			{
				Format(use_str, sizeof(use_str), "%T", "Menu_Eat", param1, item_name[index]);
			}
			else if ((StrEqual(item_type[index], "alcohol", false)) || (StrEqual(item_type[index], "drink", false)))
			{
				Format(use_str, sizeof(use_str), "%T", "Menu_Drink", param1, item_name[index]);
			}
			else if (StrEqual(item_type[index], "hat", false))
			{
				if (wearing_hat_type[param1] == index)
				{
					Format(use_str, sizeof(use_str), "%T", "Menu_Take_Off", param1, item_name[index]);
				}
				else
				{
					Format(use_str, sizeof(use_str), "%T", "Menu_Wear", param1, item_name[index]);
				}
			}
			else
			{
				Format(use_str, sizeof(use_str), "%T", "Menu_Use", param1, item_name[index]);
			}
			Format(trash_str, sizeof(trash_str), "%T", "Menu_Trash", param1, item_name[index]);
			Format(drop_str, sizeof(drop_str), "%T", "Menu_Drop1", param1, item_name[index]);
			Format(drop_all_str, sizeof(drop_all_str), "%T", "Menu_DropA", param1, item_name[index]);
			Format(title_str, sizeof(title_str), "%s:", item_name[index]);
				
			AddMenuItem(use, "0", use_str);
			AddMenuItem(use, "1", trash_str);
			AddMenuItem(use, "2", drop_str);
			AddMenuItem(use, "3", drop_all_str);
			SetMenuTitle(use, title_str);
				
			selected_item[param1] = index;
			DisplayMenu(use, param1, MENU_TIME_FOREVER);
		}
		else PrintToChat(param1, "\x03[Item] %T", "Handcuffed", param1);
	}
}
public Menu_Use(Handle:use, MenuAction:action, param1, param2)
{
	// user has selected to do something with an item, holy bullshit!!
	if (action == MenuAction_Select)
	{
		if (!IsPlayerAlive(param1))
		{
			PrintToChat(param1, "\x03[Item] %T", "Youre_Dead", param1);
			selected_item[param1] = -1;
			return;
		}
		if (IsClientHandcuffed(param1))
		{
			PrintToChat(param1, "\x03[Item] %T", "Handcuffed", param1);
			selected_item[param1] = -1;
			return;
		}
		new index = selected_item[param1];
		if (index <= -1)
		{		
			return;
		}
		if (index > -1)
		{
			if (param2 == 0)
			{
				// param2 0 means Use the item
				if (StrEqual(item_type[index], "pistol", false))
				{
					new plyr_gun = GetPlayerWeaponSlot(param1, 1);
					// We now know the player's guns.  Let's figure out if we give it to them or not.

					if (plyr_gun != -1)
					{
						PrintToChat(param1, "\x03[Item] %T", "No_Equip_S", param1);
						return;
					}
					if (plyr_gun == -1)
					{
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;

						GivePlayerItem(param1, item_entity[index], 0);

						new String:name[128];
						GetClientName(param1, name, sizeof(name));		
						new String:message[128];
						Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
						PrintToChatNear(param1, message);
						selected_item[param1] = -1;

						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}
				}
				if (StrEqual(item_type[index], "shotgun", false))
				{
					new plyr_gun = GetPlayerWeaponSlot(param1, 0);
					// We now know the player's guns.  Let's figure out if we give it to them or not.

					if (plyr_gun != -1)
					{
						PrintToChat(param1, "\x03[Item] %T", "No_Equip_P", param1);
						return;
					}
					if (plyr_gun == -1)
					{
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;

						GivePlayerItem(param1, item_entity[index], 0);

						new String:name[128];
						GetClientName(param1, name, sizeof(name));		
						new String:message[128];
						Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
						PrintToChatNear(param1, message);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}
				}
				if (StrEqual(item_type[index], "smg", false))
				{
					new plyr_gun = GetPlayerWeaponSlot(param1, 0);
					// We now know the player's guns.  Let's figure out if we give it to them or not.

					if (plyr_gun != -1)
					{
						PrintToChat(param1, "\x03[Item] %T", "No_Equip_P", param1);
						return;
					}
					if (plyr_gun == -1)
					{
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;

						GivePlayerItem(param1, item_entity[index], 0);

						new String:name[128];
						GetClientName(param1, name, sizeof(name));		
						new String:message[128];
						Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
						PrintToChatNear(param1, message);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}
				}
				if (StrEqual(item_type[index], "rifle", false))
				{
					new plyr_gun = GetPlayerWeaponSlot(param1, 0);
					// We now know the player's guns.  Let's figure out if we give it to them or not.

					if (plyr_gun != -1)
					{
						PrintToChat(param1, "\x03[Item] %T", "No_Equip_P", param1);
						return;
					}
					if (plyr_gun == -1)
					{
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;

						GivePlayerItem(param1, item_entity[index], 0);

						new String:name[128];
						GetClientName(param1, name, sizeof(name));		
						new String:message[128];
						Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
						PrintToChatNear(param1, message);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}
				}
				if (StrEqual(item_type[index], "sniper", false))
				{
					new plyr_gun = GetPlayerWeaponSlot(param1, 0);
					// We now know the player's guns.  Let's figure out if we give it to them or not.

					if (plyr_gun != -1)
					{
						PrintToChat(param1, "\x03[Item] %T", "No_Equip_P", param1);
						return;
					}
					if (plyr_gun == -1)
					{
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;

						GivePlayerItem(param1, item_entity[index], 0);

						new String:name[128];
						GetClientName(param1, name, sizeof(name));		
						new String:message[128];
						Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
						PrintToChatNear(param1, message);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}
				}
				if (StrEqual(item_type[index], "machine_gun", false))
				{
					new plyr_gun = GetPlayerWeaponSlot(param1, 0);
					// We now know the player's guns.  Let's figure out if we give it to them or not.

					if (plyr_gun != -1)
					{
						PrintToChat(param1, "\x03[Item] %T", "No_Equip_P", param1);
						return;
					}
					if (plyr_gun == -1)
					{
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;

						GivePlayerItem(param1, item_entity[index], 0);

						new String:name[128];
						GetClientName(param1, name, sizeof(name));		
						new String:message[128];
						Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
						PrintToChatNear(param1, message);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}
				}
				if (StrEqual(item_type[index], "grenade", false))
				{
					slots[param1] += item_slots[index];
					Item[param1][index] -= 1;

					GivePlayerItem(param1, item_entity[index], 0);

					new String:name[128];
					GetClientName(param1, name, sizeof(name));		
					new String:message[128];
					Format(message, 128, "*** %s pulled a %s out of their backpack ***", name, item_name[index]);
					PrintToChatNear(param1, message);
					selected_item[param1] = -1;
					if (!IsClientHandcuffed(param1))
					{
						DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
					}
					return;
				}
				if (StrEqual(item_type[index], "lockpick", false))
				{
					//Declare:
					decl Ent;
					decl String:ClassName[255];
					//Initialize:
					Ent = GetClientAimTarget(param1, false);

					//Valid:
					if(Ent != -1)
					{
						//Class Name:
						GetEdictClassname(Ent, ClassName, 255);

						//Valid:
						if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating") || StrEqual(ClassName, "prop_vehicle_driveable"))
						{
							new Float:origin[3];
							new Float:ent_origin[3];
							new Float:distance;

							GetClientAbsOrigin(param1, origin);	
							GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", ent_origin);
							distance = GetVectorDistance(origin, ent_origin, false);
							if ((distance <= 80.00) && (GetEntProp(Ent, Prop_Data, "m_bLocked")))
							{
								// Lose 1 lockpick, gain 1 slot.
								slots[param1] += item_slots[index];
								Item[param1][index] -= 1;
								
								if (item_duration[index] > 0)
								{
									new Float:dur_float = float(item_duration[index]);
									unlocking_ent[param1] = Ent;
									// Show Progress Bar
									SetEntDataFloat(param1, g_flProgressBarStartTime, GetGameTime(), true);
									SetEntData(param1, g_iProgressBarDuration, dur_float, 4, true);
									SetEntPropFloat(param1, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
									SetEntProp(param1, Prop_Send, "m_iProgressBarDuration", dur_float);								
									CreateTimer(dur_float, Lock_Time, param1);
									SetEntityRenderColor(param1, 255, 255, 100, 255);
									Blops_ShowBarTime(param1, item_duration[index]);
								}
								else
								{
									AcceptEntityInput(Ent, "Unlock", param1);					
									SetLockedState(Ent, 0);
								}
								new String:type[32];
								if (StrEqual(ClassName, "prop_vehicle_driveable"))
								{
									Format(type, sizeof(type), "vehicle");
								} else Format(type, sizeof(type), "door");
								PrintToChat(param1, "\x03[Item] Unlocking...  Stay near the %s.", type);
							}
						}
						else PrintToChat(param1, "\x03[Item] %T", "Only_Doors_Cars", param1);
					}
					else PrintToChat(param1, "\x03[Item] %T", "Only_Doors_Cars", param1);
				}
				if (StrEqual(item_type[index], "health", false))
				{
					new plyr_hp = GetClientHealth(param1);
					
					new combined_hp = (plyr_hp + item_amount[index]);

					if (plyr_hp >= 100)
					{
						PrintToChat(param1, "\x03[Item] %T", "Full_Health_Already", param1);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}	
						return;
					}
					if (combined_hp >= 100)
					{
						Item[param1][index] -= 1;
						slots[param1] += item_slots[index];
						SetEntityHealth(param1, 100);
						PrintToChat(param1, "\x03[Item] %T", "Full_Health", param1);
						PrintToChat(param1, "\x03[Item] %T", "Items_Left", param1, Item[param1][index], item_name[index]);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}	
						return;
					}
					if (combined_hp <= 99)
					{
						Item[param1][index] -= 1;
						slots[param1] += item_slots[index];
						plyr_hp += item_amount[index];
						SetEntityHealth(param1, plyr_hp);
						PrintToChat(param1, "\x03[Item] %T", "Num_HP", param1, item_amount[index]);
						PrintToChat(param1, "\x03[Item] %T", "Items_Left", param1, Item[param1][index], item_name[index]);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}	
						return;
					}	
				}
				if ((StrEqual(item_type[index], "armour", false)) || (StrEqual(item_type[index], "armor", false)))
				{
					new p_armour = GetClientArmor(param1);
					if (p_armour > 99)
					{
						PrintToChat(param1, "\x03[Item] %T", "Full_Armour_Already", param1);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;	
					}

					slots[param1] += item_slots[index];
					Item[param1][index] -= 1;

					GivePlayerItem(param1, "item_assaultsuit");

					// Why is it like this?  I have no idea.  Thx go to exvel for this.
					new g_iArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
					SetEntData(param1, g_iArmorOffset, 100);

					PrintToChat(param1, "\x03[Item] %T", "Full_Armour", param1);
					selected_item[param1] = -1;
					if (!IsClientHandcuffed(param1))
					{
						DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
					}	
					return;
				}
				if ((StrEqual(item_type[index], "food", false)) || (StrEqual(item_type[index], "drink", false)))
				{
					// Check if they can use the item.
					if (hunger[param1] < 1)
					{
						PrintToChat(param1, "\x03[Item] %T", "Not_Hungry", param1);
						selected_item[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
						return;
					}

					// Slots
					slots[param1] += item_slots[index];
					Item[param1][index] -= 1;

					// Item Effect on Player
					hunger[param1] -= item_amount[index];
					if (hunger[param1] < 0)
					{
						hunger[param1] = 0;
					}

					// Notification and Reset Selection
					if (StrEqual(item_type[index], "food", false))
					{
						PrintToChat(param1, "\x03[Item] %T", "You_Ate", param1, item_name[index], hunger[param1]);
					}
					else if (StrEqual(item_type[index], "drink", false))
					{
						PrintToChat(param1, "\x03[Item] %T", "You_Drank", param1, item_name[index], hunger[param1]);
					}
					selected_item[param1] = -1;
					if (!IsClientHandcuffed(param1))
					{
						DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
					}
					return;
				}
				if (StrEqual(item_type[index], "alcohol", false))
				{
					// Let everyone know that you're getting wasted
					
					new String:ClientName[32];
					GetClientName(param1, ClientName, 32);
								
					new Float:distance;
					decl Float:PosVec[3], Float:PosVec2[3];							
					GetClientEyePosition(param1, PosVec);
								
					for (new i = 1; i <= MaxClients; i += 1)
					{
						if (IsClientInGame(i))
						{
							GetClientEyePosition(i, PosVec2);
							distance = GetVectorDistance(PosVec, PosVec2);

							if (512.0 >= distance)
							{
								PrintToChat(i, "*** %s drank a %s ***", ClientName, item_name[index]);
								PrintToChat(i, "*** %s is getting drunk as fuck ***", ClientName);
							}
						}
					}					

					// Slots
					slots[param1] += item_slots[index];
					Item[param1][index] -= 1;

					// Item Effect on Player
					if (Drunk[param1] == 0)
					{
						Drunk[param1] = 1;
						h_drunk_a = CreateTimer(0.5, A_Time, param1);
					}
					new drunktime2 = (item_duration[index] * 2);
					DrunkTime[param1] += drunktime2;

					// Reset Selection
					selected_item[param1] = -1;
					if (!IsClientHandcuffed(param1))
					{
						DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
					}
					return;
				}
				if (StrEqual(item_type[index], "hat", false))
				{
					new current_hat = wearing_hat_type[param1];
					if (current_hat == index)
					{
						// They are wearing this hat already.  Take it off.
						DeleteHat(param1, false);
						
						wearing_hat_type[param1] = -1;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
					}
					else if ((current_hat != index) && (current_hat != -1))
					{
						new car = GetEntPropEnt(param1, Prop_Send, "m_hVehicle");	
						if(IsValidEntity(car))
						{
							return;
						}
						// They are wearing a different hat already.  Take that off then put on this one.
						DeleteHat(param1, false);
						WearHat(param1, index);
						
						wearing_hat_type[param1] = index;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
					}
					else
					{
						new car = GetEntPropEnt(param1, Prop_Send, "m_hVehicle");	
						if(IsValidEntity(car))
						{
							return;
						}
						// They aren't wearing a hat yet.  Put this one on.
						WearHat(param1, index);
						
						wearing_hat_type[param1] = index;
						if (!IsClientHandcuffed(param1))
						{
							DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
						}
					}
				}
			}
			if (param2 == 1)
			{
				// param2 1 = trash one
				new Handle:verifymenu = CreateMenu(Menu_Verify);
				new String:str_sure[48], String:str_yes[16], String:str_no[16];
				Format(str_sure, sizeof(str_sure), "%T", "R_U_Sure", param1);
				Format(str_yes, sizeof(str_yes), "%T", "Yes", param1);
				Format(str_no, sizeof(str_no), "%T", "No", param1);
				AddMenuItem(verifymenu, "0", str_no);
				AddMenuItem(verifymenu, "1", str_yes);
				SetMenuTitle(verifymenu, str_sure);
				DisplayMenu(verifymenu, param1, MENU_TIME_FOREVER);
				return;
			}
			if (param2 == 2)
			{
				// param2 2 = drop one
				
				new Float:EyeAng[3];
				GetClientEyeAngles(param1, EyeAng);
				new Float:ForwardVec[3];
				GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(ForwardVec, 100.0);
				ForwardVec[2] = 0.0;
				new Float:EyePos[3];
				GetClientEyePosition(param1, EyePos);
				new Float:AbsAngle[3];
				GetClientAbsAngles(param1, AbsAngle);
		
				new Float:SpawnAngles[3];
				SpawnAngles[1] = EyeAng[1];
				new Float:SpawnOrigin[3];
				AddVectors(EyePos, ForwardVec, SpawnOrigin);
				
				new ent = CreateEntityByName(item_entity[index]);
				if(IsValidEntity(ent))
				{
					if (!IsModelPrecached(item_model[index]))
					{
						PrecacheModel(item_model[index]);
					}
					ActivateEntity(ent);
					
					// Set Spawn Flags
					if (item_flags[index] > -1)
					{
						new String:flag_str[16];
						Format(flag_str, sizeof(flag_str), "%i", item_flags[index]);
						DispatchKeyValue(ent, "spawnflags", flag_str);
					}
					
					// Set Physics Damage Scale
					DispatchKeyValueFloat(ent, "physdamagescale", item_dmgscale[index]);

					
					SetEntityModel(ent, item_model[index]);
					DispatchKeyValueFloat (ent, "MaxPitch", 360.00);
					DispatchKeyValueFloat (ent, "MinPitch", -360.00);
					DispatchKeyValueFloat (ent, "MaxYaw", 90.00);
					DispatchSpawn(ent);
					TeleportEntity(ent, SpawnOrigin, SpawnAngles, NULL_VECTOR);
						
					PrintToChat(param1, "\x03[Item] %T", "Dropped", param1, item_name[index]);
					PrintToServer("[Item] %s dropped by %n.", item_name[index], param1);
						
					slots[param1] += item_slots[index];
					Item[param1][index] -= 1;
						
					selected_item[param1] = -1;
					if (!IsClientHandcuffed(param1))
					{
						DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
					}
					return;
				}
			}
			if (param2 == 3)
			{
				// param2 3 = drop all
				
				new Float:EyeAng[3];
				GetClientEyeAngles(param1, EyeAng);
				new Float:ForwardVec[3];
				GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(ForwardVec, 100.0);
				ForwardVec[2] = 0.0;
				new Float:EyePos[3];
				GetClientEyePosition(param1, EyePos);
				new Float:AbsAngle[3];
				GetClientAbsAngles(param1, AbsAngle);
		
				new Float:SpawnAngles[3];
				SpawnAngles[1] = EyeAng[1];
				new Float:SpawnOrigin[3];
				AddVectors(EyePos, ForwardVec, SpawnOrigin);
				
				do
				{
					new ent = CreateEntityByName(item_entity[index]);
					if(IsValidEntity(ent))
					{
						if (!IsModelPrecached(item_model[index]))
						{
							PrecacheModel(item_model[index]);
						}
						ActivateEntity(ent);
						
						// Set Spawn Flags
						if (item_flags[index] > -1)
						{
							new String:flag_str[16];
							Format(flag_str, sizeof(flag_str), "%i", item_flags[index]);
							DispatchKeyValue(ent, "spawnflags", flag_str);
						}
					
						// Minimum Health Damage
						if (item_minhealthdmg[index] > -1)
						{
							new String:hp_str[16];
							Format(hp_str, sizeof(hp_str), "%i", item_minhealthdmg[index]);
							DispatchKeyValue(ent, "minhealthdmg", hp_str);
						}
					
						// Set Physics Damage Scale
						DispatchKeyValueFloat(ent, "physdamagescale", item_dmgscale[index]);
						
						SetEntityModel(ent, item_model[index]);
						DispatchKeyValueFloat (ent, "MaxPitch", 360.00);
						DispatchKeyValueFloat (ent, "MinPitch", -360.00);
						DispatchKeyValueFloat (ent, "MaxYaw", 90.00);
						DispatchSpawn(ent);
						TeleportEntity(ent, SpawnOrigin, SpawnAngles, NULL_VECTOR);
						
						PrintToServer("[Item] %s dropped by %n.", item_name[index], param1);
						
						slots[param1] += item_slots[index];
						Item[param1][index] -= 1;
					}
				} while (Item[param1][index] >> 0);
				selected_item[param1] = -1;
				PrintToChat(param1, "\x03[Item] %T", "Dropped_All", param1, item_name[index]);
				if (!IsClientHandcuffed(param1))
				{
					DisplayMenu(g_PackMenu, param1, MENU_TIME_FOREVER);
				}
				return;
			}
		}
	}
}
public Action:Lock_Time(Handle:Timer, any:client)
{
	if ((!IsClientInGame(client)) || (!IsPlayerAlive(client)) || (IsClientHandcuffed(client)))
	{
		return;
	}
	SetEntityRenderColor(client, 255, 255, 255, 255);
	if (IsValidEntity(unlocking_ent[client]))
	{
		new Ent = unlocking_ent[client];
		unlocking_ent[client] = 0;
		
		new Float:origin[3];
		new Float:ent_origin[3];
		new Float:distance;

		GetClientAbsOrigin(client, origin);	
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", ent_origin);
		distance = GetVectorDistance(origin, ent_origin, false);
		
		if (distance <= 96.0)
		{
			AcceptEntityInput(Ent, "Unlock", client);					
			SetLockedState(Ent, 0);
			
			EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			
			decl String:ClassName[255];
			GetEdictClassname(Ent, ClassName, 255);
							
			if(StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				PrintToChat(client, "\x03[Item] %T", "Unlocked_Car", client);
				
			} else PrintToChat(client, "\x03[Item] %T", "Unlocked_Door", client);

			DisplayMenu(g_PackMenu, client, MENU_TIME_FOREVER);					
			return;
		}
		else PrintToChat(client, "\x03[Item] You moved away...  Lockpicking Failed.");
	}
}
public Action:A_Time(Handle:timer, any:client)
{
	if(DrunkTime[client] > 0)
	{
        if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{		
			new Float:vecPunch[3];
			vecPunch[0] = GetRandomFloat(-50.0, 50.0);
			vecPunch[1] = GetRandomFloat(-50.0, 50.0);
			vecPunch[2] = GetRandomFloat(-50.0, 50.0);
        
			if (offsPunchAngle != -1)
			{
				SetEntDataVector(client, offsPunchAngle, vecPunch);
			}

			DrunkTime[client] -= 1;
			SetEntityRenderColor(client, 255, 255, 100, 255);
			h_drunk_b = CreateTimer(0.50, B_Time, client);				
		}
		else DrunkTime[client] -= 1;
	}
	else if(DrunkTime[client] <= 0)
	{
        if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			DrunkTime[client] = 0;
			Drunk[client] = 0;
			SetEntityRenderColor(client, 255, 255, 255, 255);

			new String:ClientName[32];
			GetClientName(client, ClientName, 32);

			new Float:distance;
			decl Float:PosVec[3], Float:PosVec2[3];							
			GetClientEyePosition(client, PosVec);		
		
			for (new i = 1; i <= MaxClients; i += 1)
			{
				if (IsClientInGame(i))
				{
					GetClientEyePosition(i, PosVec2);
					distance = GetVectorDistance(PosVec, PosVec2);
					if (512.0 >= distance)
					{
						PrintToChat(i, "*** %s is sobering up ***", ClientName);
					}
				}
			}
		}
		else DrunkTime[client] -= 1;
	}
}
public Action:B_Time(Handle:timer, any:client)
{
	if(DrunkTime[client] > 0)
	{
        if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			
			new Float:vecPunch[3];
			vecPunch[0] = GetRandomFloat(-50.0, 50.0);
			vecPunch[1] = GetRandomFloat(-50.0, 50.0);
			vecPunch[2] = GetRandomFloat(-50.0, 50.0);
        
			if (offsPunchAngle != -1)
			{
				SetEntDataVector(client, offsPunchAngle, vecPunch);
			}

			DrunkTime[client] -= 1;
			SetEntityRenderColor(client, 255, 255, 100, 255);
			h_drunk_a = CreateTimer(0.50, A_Time, client);				
		}
		else DrunkTime[client] -= 1;
	}
	else if(DrunkTime[client] <= 0)
	{
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			DrunkTime[client] = 0;
			Drunk[client] = 0;
			SetEntityRenderColor(client, 255, 255, 255, 255);
		
			new String:ClientName[32];
			GetClientName(client, ClientName, 32);

			new Float:distance;
			decl Float:PosVec[3], Float:PosVec2[3];							
			GetClientEyePosition(client, PosVec);		
		
			for (new i = 1; i <= MaxClients; i += 1)
			{
				if (IsClientInGame(i))
				{
					GetClientEyePosition(i, PosVec2);
					distance = GetVectorDistance(PosVec, PosVec2);
					if (512.0 >= distance)
					{
						PrintToChat(i, "*** %s is sobering up ***", ClientName);
					}
				}
			}
		}
	}
}
public Menu_Verify(Handle:verifymenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(verifymenu, param2, info, sizeof(info));
		if (param2 == 1)
		{
			new index = selected_item[param1];
			Item[param1][index] -= 1;
			slots[param1] += item_slots[index];
			selected_item[param1] = -1;
			PrintToChat(param1, "\x04[Item] %T", "Deleted", param1, item_name[index]);
			return;
		}
	}
}
Handle:BuildBuyMenu()
{
	new Handle:categories = CreateMenu(Menu_Categories);
	SetMenuTitle(categories, "Item Menu:");	

	decl String:cat_str[4];
	for (new i = 0; i < cat_quantity; i++)
	{
		Format(cat_str, sizeof(cat_str), "%i", i);
		if (cat_enabled[i] == 1)
		{
			AddMenuItem(categories, cat_str, cat_name[i]);
		}
		else AddMenuItem(categories, cat_str, cat_name[i], ITEMDRAW_DISABLED);
	}
	
	SetMenuTitle(categories, "Choose a Category");
	return categories;
}
public Menu_Categories(Handle:categories, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		/* Create the menu Handle */
		new Handle:menu = CreateMenu(Menu_Buy);

		decl String:i_str[4], String:name_str[64];
		new AdminId:admin = GetUserAdmin(param1);

		for (new i = 0; i < item_quantity; i++)
		{
			if (item_cat[i] == param2)
			{
				if (item_enabled[i] == 1)
				{
					Format(i_str, sizeof(i_str), "%i", i);
					Format(name_str, sizeof(name_str), "(%i) %s -- $%i", item_buy_quantity[i], item_name[i], item_price[i]);
					if (item_vip[i] == 1)
					{
						if (admin != INVALID_ADMIN_ID)
						{
							if (item_buy_mode[i] == 0)
							{
								AddMenuItem(menu, i_str, name_str);
							}
							else if (item_buy_mode[i] == 1)
							{
								new team = GetClientRPTeam(param1);
								if (team == item_team[i])
								{
									AddMenuItem(menu, i_str, name_str);
								}
								else AddMenuItem(menu, i_str, name_str, ITEMDRAW_DISABLED);
							}
							else if (item_buy_mode[i] == 2)
							{
								new class = GetClientClass(param1);
								if (class == item_class[i])
								{
									AddMenuItem(menu, i_str, name_str);
								}
								else AddMenuItem(menu, i_str, name_str, ITEMDRAW_DISABLED);
							}
						}
						else AddMenuItem(menu, i_str, name_str, ITEMDRAW_DISABLED);					
					}
					else
					{
						if (item_buy_mode[i] == 0)
						{
							AddMenuItem(menu, i_str, name_str);
						}
						else if (item_buy_mode[i] == 1)
						{
							new team = GetClientRPTeam(param1);
							if (team == item_team[i])
							{
								AddMenuItem(menu, i_str, name_str);
							}
							else AddMenuItem(menu, i_str, name_str, ITEMDRAW_DISABLED);
						}
						else if (item_buy_mode[i] == 2)
						{
							new class = GetClientClass(param1);
							if (class == item_class[i])
							{
								AddMenuItem(menu, i_str, name_str);
							}
							else AddMenuItem(menu, i_str, name_str, ITEMDRAW_DISABLED);
						}
					}
				}
			}
		}
		SetMenuTitle(menu, cat_name[param2]);
		DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		return;
	}	
}
public Menu_Buy(Handle:menu, MenuAction:action, param1, param2)
{
	// user has selected to buy something

	if (action == MenuAction_Select)
	{
		new String:info[30];

		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));

		if (!found)
			return;
			
		new index = StringToInt(info, 10);

		// user selected an item

		new cost2 = (item_price[index] - 1);

		// Why is it like this?  I have no idea.
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		new money = GetEntData(param1, MoneyOffset);
		new bank = GetClientBank(param1);
		
		if(money > cost2)
		{
			new slotsx = (item_slots[index] * item_buy_quantity[index]);

			if (slots[param1] >= slotsx)
			{
				if (item_vip[index] != 1)
				{
					if (item_buy_mode[index] == 0)
					{
						SetEntData(param1, MoneyOffset, money - item_price[index], 4, true);
						SetClientMoney(param1, money - item_price[index]);
						slots[param1] -= slotsx;
						PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[index]);
						Item[param1][index] += item_buy_quantity[index];
					}
					else if (item_buy_mode[index] == 1)
					{
						new team = GetClientRPTeam(param1);
						if (team == item_team[index])
						{
							SetEntData(param1, MoneyOffset, money - item_price[index], 4, true);
							SetClientMoney(param1, money - item_price[index]);
							slots[param1] -= slotsx;
							PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[index]);
							Item[param1][index] += item_buy_quantity[index];
						}
						else
						{
							PrintToChat(param1, "\x03[Item] %T", "Wrong_Team", param1);
						}
					}
					else if (item_buy_mode[index] == 2)
					{
						new class = GetClientClass(param1);
						if (class == item_class[index])
						{
							SetEntData(param1, MoneyOffset, money - item_price[index], 4, true);
							SetClientMoney(param1, money - item_price[index]);
							slots[param1] -= slotsx;
							PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[index]);
							Item[param1][index] += item_buy_quantity[index];
						}
						else
						{
							PrintToChat(param1, "\x03[Item] %T", "Wrong_Class", param1);
						}
					}
				}
				else if (item_vip[index] == 1)
				{
					new AdminId:admin = GetUserAdmin(param1);
					if (admin != INVALID_ADMIN_ID)
					{
						if (item_buy_mode[index] == 0)
						{
							SetEntData(param1, MoneyOffset, money - item_price[index], 4, true);
							SetClientMoney(param1, money - item_price[index]);
							slots[param1] -= slotsx;
							PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[index]);
							Item[param1][index] += item_buy_quantity[index];
						}
						else if (item_buy_mode[index] == 1)
						{
							new team = GetClientRPTeam(param1);
							if (team == item_team[index])
							{
								SetEntData(param1, MoneyOffset, money - item_price[index], 4, true);
								SetClientMoney(param1, money - item_price[index]);
								slots[param1] -= slotsx;
								PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[index]);
								Item[param1][index] += item_buy_quantity[index];
							}
							else
							{
								PrintToChat(param1, "\x03[Item] %T", "Wrong_Team", param1);
							}
						}
						else if (item_buy_mode[index] == 2)
						{
							new class = GetClientClass(param1);
							if (class == item_class[index])
							{
								SetEntData(param1, MoneyOffset, money - item_price[index], 4, true);
								SetClientMoney(param1, money - item_price[index]);
								slots[param1] -= slotsx;
								PrintToChat(param1, "\x03[Item] %T", "Bought_C", param1, item_name[index]);
								Item[param1][index] += item_buy_quantity[index];
							}
							else
							{
								PrintToChat(param1, "\x03[Item] %T", "Wrong_Class", param1);
							}
						}	
					}
					else PrintToChat(param1, "\x03[Item] %T", "Not_Admin", param1);
				}
			}
			else PrintToChat(param1, "\x03[Item] %T", "Need_Slots", param1, slotsx);
		}
		else if(bank > cost2)
		{
			new slotsx = (item_slots[index] * item_buy_quantity[index]);
			if (slots[param1] >= slotsx)
			{
				if (item_vip[index] != 1)
				{
					if (item_buy_mode[index] == 0)
					{
						bank -= item_price[index];
						SetClientBank(param1, bank);
						PrintToChat(param1, "\x03[Item] %T", "Bought_B", param1, item_name[index]);
						Item[param1][index] += item_buy_quantity[index];
					}
					else if (item_buy_mode[index] == 1)
					{
						new team = GetClientRPTeam(param1);
						if (team == item_team[index])
						{
							bank -= item_price[index];
							SetClientBank(param1, bank);							
							slots[param1] -= slotsx;
							PrintToChat(param1, "\x03[Item] %T", "Bought_B", param1, item_name[index]);
							Item[param1][index] += item_buy_quantity[index];
						}
						else
						{
							PrintToChat(param1, "\x03[Item] %T", "Wrong_Team", param1);
						}
					}
					else if (item_buy_mode[index] == 2)
					{
						new class = GetClientClass(param1);
						if (class == item_class[index])
						{
							bank -= item_price[index];
							SetClientBank(param1, bank);							
							slots[param1] -= slotsx;
							PrintToChat(param1, "\x03[Item] %T", "Bought_B", param1, item_name[index]);
							Item[param1][index] += item_buy_quantity[index];
						}
						else
						{
							PrintToChat(param1, "\x03[Item] %T", "Wrong_Class", param1);
						}
					}
				}
				else if (item_vip[index] == 1)
				{
					new AdminId:admin = GetUserAdmin(param1);
					if (admin != INVALID_ADMIN_ID)
					{
						if (item_buy_mode[index] == 0)
						{
							bank -= item_price[index];
							SetClientBank(param1, bank);							
							slots[param1] -= slotsx;
							PrintToChat(param1, "\x03[Item] %T", "Bought_B", param1, item_name[index]);
							Item[param1][index] += item_buy_quantity[index];
						}
						else if (item_buy_mode[index] == 1)
						{
							new team = GetClientRPTeam(param1);
							if (team == item_team[index])
							{
								bank -= item_price[index];
								SetClientBank(param1, bank);
								slots[param1] -= slotsx;
								PrintToChat(param1, "\x03[Item] %T", "Bought_B", param1, item_name[index]);
								Item[param1][index] += item_buy_quantity[index];
							}
							else
							{
								PrintToChat(param1, "\x03[Item] %T", "Wrong_Team", param1);
							}
						}
						else if (item_buy_mode[index] == 2)
						{
							new class = GetClientClass(param1);
							if (class == item_class[index])
							{
								bank -= item_price[index];
								SetClientBank(param1, bank);								
								slots[param1] -= slotsx;
								PrintToChat(param1, "\x03[Item] %T", "Bought_B", param1, item_name[index]);
								Item[param1][index] += item_buy_quantity[index];
							}
							else
							{
								PrintToChat(param1, "\x03[Item] %T", "Wrong_Class", param1);
							}
						}	
					}
					else PrintToChat(param1, "\x03[Item] %T", "Not_Admin", param1);
				}
			}
			else PrintToChat(param1, "\x03[Item] %T", "Need_Slots", param1, slotsx);					
		}
		else PrintToChat(param1, "\x03[Item] %T", "Expensive", param1, item_price[index]);
	}
	return;
}
Handle:BuildInfoMenu()
{
	new Handle:info = CreateMenu(Menu_Info);
	AddMenuItem(info, "1", "  Type !item to open the item menu.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Select Inventory to see your inventory.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Select Buy Items to buy new stuff.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Type !holster_p to holster your Primary Weapon", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Type !holster_s to holster your Secondary Weapon", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  www.lady-natalya.info", ITEMDRAW_DISABLED);
	SetMenuTitle(info, "<==>  Plugin by Lady Natalya  <==>");
	return info;
}
public Menu_Info(Handle:info, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		return;
	}
}



//	################################
//	Load Players and Refresh Players
//	################################



public OnClientDisconnect(client)
{
	DeleteHat(client, false);
	wearing_hat_type[client] = -1;
	IsDisconnect[client] = true;
	DBSave(client);    
}
public bool:OnClientConnect(client, String:Reject[], Len)
{
	//Disable:
	Loaded[client] = false;
	return true; 
}
public OnClientPutInServer(client)
{
	//Default Values:
	holstering[client] = false;
	hunger[client] = 20;
	AtVend[client] = false;
	wearing_hat_type[client] = -1;
	
	if(!Loaded[client])
	{
		CreateTimer(1.0, CreateSQLAccount, client);
	}
}
public Action:CreateSQLAccount(Handle:Timer, any:client)
{   
	if (!IsClientConnected(client))
	{
		CreateTimer(1.0, CreateSQLAccount, client);
	}
	else
	{	
		new String:SteamId[64];
		GetClientAuthId(client, AuthId_Engine, SteamId, 64);
	
	
		if(StrEqual(SteamId, "") || InQuery)
		{
			CreateTimer(1.0, CreateSQLAccount, client);
		}
		else
		{	
			//PrintToChatAll("Connection Successful");
		
			// InQuery stops it from loading more than one player at a time.
			InQuery = true;
			InitializeClientonDB(client); 	
		}
	}
}
public InitializeClientonDB(client)
{
	
	if(IsFakeClient(client)) return true;
	
	new String:SteamId[255];
	new String:query[255];
	
	new conuserid;
	conuserid = GetClientUserId(client);
	
	GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
	Format(query, sizeof(query), "SELECT LASTONTIME FROM Items WHERE STEAMID = '%s';", SteamId);
	SQL_TQuery(db_items, T_CheckConnectingItems, query, conuserid);
	return true;
}
public T_CheckConnectingItems(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return true;
	}
	
	new String:SteamId[255];
	GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	}
	else 
	{
		new String:buffer[255];
		if (!SQL_GetRowCount(hndl))
		{
			// insert user
			GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
			Format(buffer, sizeof(buffer), "INSERT INTO Items (`STEAMID`,`LASTONTIME`) VALUES ('%s',%i);", SteamId, GetTime());
			SQL_FastQuery(db_items, buffer);
			
			for(new X = 0;X < 500;X++)
			{
				Item[client][X] = 0;			
			}
			slots[client] = GetConVarInt(g_Cvar_Slots);
		}
		else
		{
			Format(buffer, sizeof(buffer), "SELECT * FROM `Items` WHERE STEAMID = '%s';", SteamId);
			SQL_TQuery(db_items, DBItemLoad_Callback, buffer, data);
		}
		FinallyLoaded(client);
	}
	return true;
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}
public FinallyLoaded(client)
{
	if(!IsClientConnected(client))return true;
	InQuery = false;		
	Loaded[client] = true;
	IsDisconnect[client] = false;
	
	return true;
}

// New Client Loading Done.  Now for Client Data Updating

public Action:DBSave_Restart(Handle:Timer, any:client){
	DBSave(client);
	return Plugin_Handled;
}
public DBSave(client)
{
	if(!IsClientConnected(client))return true;
	if(InQuery)
	{
		CreateTimer(1.0, DBSave_Restart, client);
		return true;
	}
	
	if(Loaded[client]){
		InQuery = true;
		new userid = GetClientUserId(client);
		
		//Declare:
		new String:SteamId[32], String:query[512];
		new UnixTime = GetTime();
		
		//Initialize:
		GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
		
		Format(query, sizeof(query), "UPDATE Items SET LASTONTIME = %d WHERE STEAMID = '%s';",UnixTime, SteamId);
		SQL_TQuery(db_items, T_SaveCallback, query, userid);		
		
		new maxitem = (item_quantity + 4);
		if (maxitem > 500)
		{
			maxitem = 500;
		}
		
		for(new X = 1;X <= maxitem;X += 10)
		{
			Format(query, sizeof(query), "UPDATE Items SET `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d, `%d` = %d WHERE STEAMID = '%s';", X, Item[client][X], X+1, Item[client][X+1], X+2, Item[client][X+2], X+3, Item[client][X+3], X+4, Item[client][X+4], X+5, Item[client][X+5], X+6, Item[client][X+6], X+7, Item[client][X+7], X+8, Item[client][X+8], X+9, Item[client][X+9], SteamId);
			SQL_TQuery(db_items, T_SaveCallback, query, userid);
		}
			
		if(IsDisconnect[client])
		{
			Loaded[client] = false;
			IsDisconnect[client] = false;
		}
		InQuery = false;
	}
	return true;
}
public T_SaveCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	/* Make sure the client didn't disconnect while the thread was running */
	if (GetClientOfUserId(data) == 0)
	{
		return;
	}
	return;
}
// Now we go to loading existing clients.

public DBItemLoad_Callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{  
	new client = GetClientOfUserId(data);
	slots[client] = GetConVarInt(g_Cvar_Slots);
	
	//Make sure the client didn't disconnect while the thread was running
	
	if(client == 0)
	{
		return true;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	}
	else
	{
		if(!SQL_GetRowCount(hndl))
		{
			LogError("Database error! SteamID not found!");
		}
		else
		{
			while (SQL_FetchRow(hndl))
			{
				for(new X = 0; X <= MAXITEMS - 2; X++)
				{
					Item[client][X+1] = SQL_FetchInt(hndl,(X+2));
					if (Item[client][X+1] > 0)
					{
						slots[client] -= (Item[client][X+1] * item_slots[X+1]);
					}
					else if (Item[client][X+1] < 0)
					{
						Item[client][X+1] = 0;
					}
				}  
			}
		} 
	}
	return true;
}



// ###############
// Player Commands
// ###############



public Action:Command_Item(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			if (!IsClientHandcuffed(client))
			{
				new AdminId:admin = GetUserAdmin(client);
				if (admin != INVALID_ADMIN_ID)
				{
					DisplayMenu(g_PackMenu, client, MENU_TIME_FOREVER);
					PrintToChat(client, "\x03[Item] %T", "Have_Slots", client, slots[client]);
				}
				else
				{
					DisplayMenu(g_PackMenu, client, MENU_TIME_FOREVER);
					PrintToChat(client, "\x03[Item] %T", "Have_Slots", client, slots[client]);
				}
			}
			else PrintToChat(client, "\x03[Item] %T", "Handcuffed", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x03[Item] %T", "Youre_Dead", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x03[Item] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Command_HolsterP(client, args)
{
	if (holstering[client] == false)
	{
		if (IsPlayerAlive(client))
		{
			new plyr_gun = GetPlayerWeaponSlot(client, 0);
			// We now know the player's guns.  Let's figure out if we give it to them or not.
			if (plyr_gun == -1)
			{
				PrintToChat(client, "\x03[Item] %T", "No_Holster_P", client);
				return Plugin_Handled;
			}
			if (IsValidEdict(plyr_gun))
			{
				new String:player_name[64];
				new String:gun_class[20];
				GetEdictClassname(plyr_gun, gun_class, 20);
				
				new index = -1;
				for (new X = 0; X < 500; X++)
				{
					if (StrEqual(gun_class, item_entity[X], false))
					{
						index = X;
						break;
					}
				}
				
				GetClientName(client, player_name, 64);
				if (slots[client] >= item_slots[index])
				{
					new String:message[256];
					Format(message, 256, "*** %s started to rummage through their backpack ***", player_name);
					PrintToChatNear(client, message);
					GetClientAbsOrigin(client, player_pos[client]);											
					CreateTimer(4.0, Holster_P_Time, client, 0);
					holstering[client] = true;
				}
				else PrintToChat(client, "\x03[Item] %T", "Need_Slots_Weapon", client, item_slots[index]);
			}
		}
		else PrintToChat(client, "\x03[Item] %T", "Youre_Dead", client);
	}
	else PrintToChat(client, "\x03[Item] %T", "Holstering", client);
	return Plugin_Handled;
}
public Action:Holster_P_Time(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	new Float:new_origin[3];	
	GetClientAbsOrigin(client, new_origin);	
	
	new Float:distance = GetVectorDistance(player_pos[client], new_origin, false);
	
	new String:player_name[64];
	GetClientName(client, player_name, 64);

	if (64.0 >= distance)
	{
		if (IsPlayerAlive(client))
		{
			new plyr_gun = GetPlayerWeaponSlot(client, 0);
			// We now know the player's guns.  Let's figure out if we give it to them or not.
			if (plyr_gun == -1)
			{
				PrintToChat(client, "\x03[Item] %T", "No_Holster_P", client);
				holstering[client] = false;
				return Plugin_Handled;
			}
			if (plyr_gun != -1)
			{
				new String:gun_class[20];
				GetEdictClassname(plyr_gun, gun_class, 20);
				new index = -1;
				for (new X = 0; X < 500; X++)
				{
					if (StrEqual(gun_class, item_entity[X], false))
					{
						index = X;
						break;
					}
				}
				if (slots[client] >= item_slots[index])
				{
					new String:message[256];
					Format(message, 256, "*** %s put the %s into their backpack ***", player_name, gun_class);
					PrintToChatNear(client, message);

					PrintToChat(client, "\x03[Item] %T", "Holstered_P", client, gun_class);
					RemovePlayerItem(client, plyr_gun);
					RemoveEdict(plyr_gun);
					
					Item[client][index] += 1;
					slots[client] -= item_slots[index];

					new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
					if (IsValidEntity(plyr_gun2))
					{
						EquipPlayerWeapon(client, plyr_gun2);
					}
					
					holstering[client] = false;
					return Plugin_Handled;					
				}
				else PrintToChat(client, "\x03[Item] %T", "Need_Slots_Weapon", client, item_slots[index]);
				holstering[client] = false;
			}
			holstering[client] = false;
		}
		else PrintToChat(client, "\x03[Item] %T", "Youre_Dead", client);
		holstering[client] = false;
	}
	new String:fail_message[256];
	Format(fail_message, 256, "*** %s gave up and put their backpack back on ***", player_name);
	PrintToChatNear(client, fail_message);
	holstering[client] = false;
	return Plugin_Handled;
}			
public Action:Command_HolsterS(client, args)
{
	if (holstering[client] == false)
	{
		if (IsPlayerAlive(client))
		{
			new plyr_gun = GetPlayerWeaponSlot(client, 1);
			// We now know the player's guns.  Let's figure out if we give it to them or not.
			if (plyr_gun == -1)
			{
				PrintToChat(client, "\x03[Item] %T", "No_Holster_S", client);
				return Plugin_Handled;
			}
			if (plyr_gun != -1)
			{
				new String:player_name[64];
				new String:gun_class[20];
				GetEdictClassname(plyr_gun, gun_class, 20);
				
				new index = -1;
				for (new X = 0; X < 500; X++)
				{
					if (StrEqual(gun_class, item_entity[X], false))
					{
						index = X;
						break;
					}
				}
				
				GetClientName(client, player_name, 64);
				if (slots[client] >= item_slots[index])
				{
					new String:message[256];
					Format(message, 256, "*** %s started to rummage through their backpack ***", player_name);
					PrintToChatNear(client, message);
					GetClientAbsOrigin(client, player_pos[client]);											
					CreateTimer(4.0, Holster_S_Time, client, 0);
					holstering[client] = true;
				}
				else PrintToChat(client, "\x03[Item] %T", "Need_Slots_Weapon", client, item_slots[index]);
			}
		}
		else PrintToChat(client, "\x03[Item] %T", "Youre_Dead", client);
	}
	else PrintToChat(client, "\x03[Item] %T", "Holstering", client);
	return Plugin_Handled;
}
public Action:Holster_S_Time(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	new Float:new_origin[3];	
	GetClientAbsOrigin(client, new_origin);	
	
	new Float:distance = GetVectorDistance(player_pos[client], new_origin, false);
	
	new String:player_name[64];
	GetClientName(client, player_name, 64);

	if (64.0 >= distance)
	{
		if (IsPlayerAlive(client))
		{
			new plyr_gun = GetPlayerWeaponSlot(client, 1);
			// We now know the player's guns.  Let's figure out if we give it to them or not.
			if (plyr_gun == -1)
			{
				PrintToChat(client, "\x03[Item] %T", "No_Holster_S", client);
				holstering[client] = false;
				return Plugin_Handled;
			}
			if (plyr_gun != -1)
			{
				new String:gun_class[20];
				GetEdictClassname(plyr_gun, gun_class, 20);
				new index = -1;
				for (new X = 0; X < 500; X++)
				{
					if (StrEqual(gun_class, item_entity[X], false))
					{
						index = X;
						break;
					}
				}
				if (slots[client] >= item_slots[index])
				{
					new String:message[256];
					Format(message, 256, "*** %s put the %s into their backpack ***", player_name, gun_class);
					PrintToChatNear(client, message);

					PrintToChat(client, "\x03[Item] %T", "Holstered_S", client, gun_class);
					RemovePlayerItem(client, plyr_gun);
					RemoveEdict(plyr_gun);
					
					Item[client][index] += 1;
					slots[client] -= item_slots[index];

					new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
					if (IsValidEntity(plyr_gun2))
					{
						EquipPlayerWeapon(client, plyr_gun2);
					}					
					
					holstering[client] = false;
					return Plugin_Handled;					
				}
				else PrintToChat(client, "\x03[Item] %T", "Need_Slots_Weapon", client, item_slots[index]);
				holstering[client] = false;
			}
			holstering[client] = false;
		}
		else PrintToChat(client, "\x03[Item] %T", "Youre_Dead", client);
		holstering[client] = false;
	}
	new String:fail_message[256];
	Format(fail_message, 256, "*** %s gave up and put their backpack back on ***", player_name);
	PrintToChatNear(client, fail_message);
	holstering[client] = false;
	return Plugin_Handled;
}
public Action:Command_DBSave(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		for (new player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				DBSave(player);
			}
		}
	}
	if (client == 0)
	{
		PrintToServer("[Item] Server Forced DB Save");
	}
	else
	{
		PrintToChat(client, "[Item] %N Forced DB Save", client);
	}
	return Plugin_Handled;
}



// ##################
// Other Player Stuff
// ##################



public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_USE)
	{
		if (IsPlayerAlive(client))
		{
			//Declare:
			decl Ent;
			decl String:ClassName[255];

			//Initialize:
			Ent = GetClientAimTarget(client, false);

			//Valid:
			if (IsValidEdict(Ent))
			{
				//Class Name:
				GetEdictClassname(Ent, ClassName, 255);

				//Valid:
				if((StrEqual(ClassName, "prop_physics")) || (StrEqual(ClassName, "prop_physics_multiplayer")))
				{
					new Float:origin[3];
					new Float:item_origin[3];
					new Float:distance;

					GetClientAbsOrigin(client, origin);	
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", item_origin);
					distance = GetVectorDistance(origin, item_origin, false);
					if (distance > 64.00)
					{
						return Plugin_Continue;
					}
				
					new String:model[256];
					new String:name[128];
					GetClientName(client, name, sizeof(name));
					GetEntPropString(Ent, Prop_Data, "m_ModelName", model, sizeof(model));
					PrintToServer("[Item] Command_Pickup called on a %s with model %s by %s.", ClassName, model, name);


					new index = -1;
					for (new X = 0; X < 500; X++)
					{
						if (StrEqual(model, item_model[X], false))
						{
							index = X;
							break;
						}
					}
					if (index > -1)
					{
						if (slots[client] >= item_slots[index])
						{
							AcceptEntityInput(Ent, "kill", 0, 0, 0);
							RemoveEdict(Ent);

							slots[client] -= item_slots[index];
							Item[client][index] += 1;
							EmitSoundToClient(client, "buttons/blip2.wav");

							PrintToChat(client, "\x03[Item] %T", "Grabbed", client, item_name[index], slots[client]);
							return Plugin_Handled;
						}
						else PrintToChat(client, "\x03[Item] %T", "Need_Slots", client, item_slots[index]);
					}
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}



// ####################
// SUPPORTING FUNCTIONS
// ####################



public Action:Item_Time(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{	
			GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
			PrintToServer("[ITEM] Auto Save -- updating client in SQL Database.", authid[client]);
			LogMessage("[ITEM] Auto Save -- updating client in SQL Database.", authid[client]);
			DBSave(client);
		}
	}
}
public Action:Hunger_Time(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			if (item_food_used == 1)
			{
				if (IsPlayerAlive(client))
				{
					if (hunger[client] < 100)
					{
						hunger[client] += 1;
					}
					PrintHintText(client, "%T", "Hunger", client, hunger[client]);
					if (hunger[client] > 89)
					{
						PrintHintText(client, "%T", "Hungry", client);
					}
					if (hunger[client] == 100)
					{
						CreateTimer(1.0, Hungry_Time, client);
					}
				}
			}
		}
	}
}
public Action:Hungry_Time(Handle:Timer, any:client)
{
    if (IsClientInGame(client))
    {
		if (IsPlayerAlive(client))
		{
			if (hunger[client] == 100)
			{
				new plyr_hp = GetClientHealth(client);
				plyr_hp -= 1;
				if (plyr_hp <= 0)
				{
					FakeClientCommand(client, "kill");
					hunger[client] = 50;
					new String:Name[64];
					GetClientName(client, Name, sizeof(Name));
					PrintToChatAll("\x03[Item] %T", "Starvation", LANG_SERVER, Name);					
				}
				else
				{
					SetEntityHealth(client, plyr_hp);
					CreateTimer(1.0, Hungry_Time, client);
				}
			}
		}
	}
}
public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}



// ######
// STOCKS
// ######



stock PrintToChatNear(client, String:message[])
{
	new Float:origin[3];
	new Float:i_origin[3];
	new Float:distance;

	GetClientAbsOrigin(client, origin);	
	
	for (new i = 1; i <= MaxClients; i++)
	{
    	if (IsClientInGame(i))
    	{
			if (IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, i_origin);
				distance = GetVectorDistance(origin, i_origin, false);
				if (256.0 >= distance)
				{
					PrintToChat(i, message);
				}
			}
		}
	}
	return;
}
stock Blops_ShowBarTime(client, dur)
{
	if (!IsValidEntity(client) || !IsClientInGame(client)) return;
	Blops_RemoveBarTime(INVALID_HANDLE, client);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", dur);
	CreateTimer(float(dur), Blops_RemoveBarTime, client);
}

public Action:Blops_RemoveBarTime(Handle: timer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client)) return;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
}

stock HatMath(client, type, Float:origin[3], Float:angle[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
	// Hat Location Math -- Thanks to Zephyrus
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
	
	GetClientAbsAngles(client, angle);
	
	angle[0] += item_angles[type][0];
	angle[1] += item_angles[type][1];
	angle[2] += item_angles[type][2];
	
	new Float:fOffset[3];
	fOffset[0] = item_position[type][0];
	fOffset[1] = item_position[type][1];
	fOffset[2] = item_position[type][2];

	GetAngleVectors(angle, fForward, fRight, fUp);
	
	origin[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	origin[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	origin[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
}

DeleteHat(client, lollerbool)
{
	new hat = wearing_hat_number[client];
	if(IsValidEntity(hat) && hat > MaxClients)
	{
		AcceptEntityInput(hat, "Kill");
		RemoveEdict(hat);
	}	
	if (!lollerbool)
	{
		new index = wearing_hat_type[client];
		if (index > 0)
		{
			slots[client] -= item_slots[index];
			Item[client][index] += 1;
		}
	}
	wearing_hat_type[client] = -1;
	wearing_hat_number[client] = -1;
}

WearHat(client, type)
{
	new Float:origin[3];
	new Float:angle[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	
	HatMath(client, type, origin, angle, fForward, fRight, fUp);
	
	// Spawn the hat.
	new hat = CreateEntityByName("prop_dynamic_override");
	
	if (!IsModelPrecached(item_model[type]))
	{
		PrecacheModel(item_model[type]);
	}
	
	SetEntityModel(hat, item_model[type]);
	DispatchKeyValue(hat, "spawnflags", "4");
	SetEntProp(hat, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(hat);	
	AcceptEntityInput(hat, "TurnOn", hat, hat, 0);
	
	TeleportEntity(hat, origin, angle, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(hat, "SetParent", client, hat, 0);
	
	SetVariantString("forward");
	AcceptEntityInput(hat, "SetParentAttachmentMaintainOffset", hat, hat, 0);	
	
	slots[client] += item_slots[type];
	Item[client][type] -= 1;			
	wearing_hat_type[client] = type;
	wearing_hat_number[client] = hat;
}
public Action:Command_Hat(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			DeleteHat(client, false);
		}
		else PrintToChat(client, "\x03[Item] %T", "Youre_Dead", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x03[Item] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	DeleteHat(client, false);
	return Plugin_Continue;
}