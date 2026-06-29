#include <tf2_stocks>
#include <tf2attributes>
#include <tf2idb>


#define ALIEN "\x0700ccff[HAT] "
#define GCLASS TF2_GetPlayerClass(client)
// ------------------------------------ Handles ------------------------------------ //
new Handle:g_hWearableEquip, Handle:g_hGameConfig;
new Handle:kv[16000] = {INVALID_HANDLE, ...};
new MaxItem_Look;

new GiveLook[MAXPLAYERS+1][3][10];
new RemoveLook[MAXPLAYERS+1][3];

// ------------------------------------ Misc ------------------------------------ //
new SlotCheck[MAXPLAYERS+1];
new String:PaintLook[MAXPLAYERS+1][3][10][100];

new Handle:kv2[100] = {INVALID_HANDLE, ...};
new MaxItem_Paint;

// ------------------------------------ Customizazion ------------------------------------ //
new Float:StyleLook[MAXPLAYERS+1][3];
new Float:LevelLook[MAXPLAYERS+1][3];
new Float:UnusualLook[MAXPLAYERS+1][3];
new Float:QualityLook[MAXPLAYERS+1][3];

// ------------------------------------  Handles ------------------------------------ //
new bool:RandomCheck[MAXPLAYERS+1];
new Handle:h_hat, Handle:h_misc, Handle:h_misc2, Handle:h_paint;

// ------------------------------------ Bools ------------------------------------ //
new bool:SettingPaint[MAXPLAYERS+1];
new bool:SettingReset[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Wearable Plugin",
	author = "ALIEN31ITA",
	description = "wear cosmetics, paint, set level, quality and unusual",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2731822"
};

// ------------------------------------ Start ------------------------------------ //
public OnPluginStart()
{

	g_hGameConfig = LoadGameConfigFile("give.bots.weapons");
	if (!g_hGameConfig) SetFailState("Failed to find give.bots.weapons.txt gamedata! Can't continue.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();
	
	if (!g_hWearableEquip) SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	
	RegConsoleCmd("sm_wear", LookMenu);
	RegConsoleCmd("sm_paint", PaintMenu);
	RegConsoleCmd("sm_style", StyleMenu);
	RegConsoleCmd("sm_wearlevel", LevelMenu);
	RegConsoleCmd("sm_wearunusual", UnusualMenu);
	RegConsoleCmd("sm_wearquality", QualityMenu);
	RegConsoleCmd("sm_randomwear", RandomLook);
	RegConsoleCmd("sm_wearreset", ResetCommand);
	RegConsoleCmd("sm_lall", ResetCommand2);
	RegConsoleCmd("sm_wearsetting", SettingCommand);
	//For gameplay issues

	
	HookEvent("post_inventory_application", inven);
	HookEvent("player_spawn", PlayerSpawn);
}

public OnMapStart()
{
	PrecacheModel("models/workshop/player/items/Scout/dec15_hot_heels/dec15_hot_heels.mdl", true);
}

// ------------------------------------ Clients ------------------------------------ //

public OnClientPutInServer(client)
{
	for(new i = 0; i <= 2; i++) for(new j = 0; j <= 9; j++) GiveLook[client][i][j] = 0;
	for(new i = 0; i <= 2; i++) for(new j = 0; j <= 9; j++) PaintLook[client][i][j] = "";
	for(new i = 0; i <= 2; i++) StyleLook[client][i] = 0.0;
	for(new i = 0; i <= 2; i++) LevelLook[client][i] = 0.0;
	for(new i = 0; i <= 2; i++) UnusualLook[client][i] = 0.0;
	for(new i = 0; i <= 2; i++) QualityLook[client][i] = 0.0;
	
	RemoveLook[client][0] = 0;
	RemoveLook[client][1] = 0;
	RemoveLook[client][2] = 0;
	
	SlotCheck[client] = 0;
	RandomCheck[client] = false;
	SettingPaint[client] = false;
	SettingReset[client] = false;
}


public OnMapEnd()
{
	for(new i = 0 ; i < 16000 && i < MaxItem_Look; i++) if(kv[i] != INVALID_HANDLE) CloseHandle(kv[i]);
	for(new i = 0 ; i < 100 && i < MaxItem_Paint; i++) if(kv2[i] != INVALID_HANDLE) CloseHandle(kv2[i]);
	
	if(h_hat != INVALID_HANDLE) CloseHandle(h_hat);
	if(h_misc != INVALID_HANDLE) CloseHandle(h_misc);
	if(h_misc2 != INVALID_HANDLE) CloseHandle(h_misc2);
	if(h_paint != INVALID_HANDLE) CloseHandle(h_paint);
}



public OnConfigsExecuted()
{


	decl String:strPath[192], String:szBuffer[100];
	new count = 0;
	
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/wearables/item.cfg");
	
	new Handle:DB = CreateKeyValues("items");
	FileToKeyValues(DB, strPath);

	if(KvGotoFirstSubKey(DB))
	{
		do
		{
			kv[count] = CreateArray(16000);
			
			KvGetSectionName(DB, szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);	
			
			KvGetString(DB, "name", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			count++;
		}
		while(KvGotoNextKey(DB));
	}
	CloseHandle(DB);
	MaxItem_Look = count;
	LogMessage("Look Max Item : %d", MaxItem_Look);
	
	
	decl String:strPath2[192];
	new count2 = 0;
	
	BuildPath(Path_SM, strPath2, sizeof(strPath2), "configs/wearables/paint.cfg");
	
	new Handle:DB2 = CreateKeyValues("paint");
	FileToKeyValues(DB2, strPath2);

	if(KvGotoFirstSubKey(DB2))
	{
		do
		{
			kv2[count2] = CreateArray(100);
			
			KvGetSectionName(DB2, szBuffer, sizeof(szBuffer));
			PushArrayString(kv2[count2], szBuffer);	
			
			KvGetString(DB2, "index", szBuffer, sizeof(szBuffer));
			PushArrayString(kv2[count2], szBuffer);
			count2++;
		}
		while(KvGotoNextKey(DB2));
	}
	CloseHandle(DB2);
	MaxItem_Paint = count2;
	LogMessage("Paint Max Item : %d", MaxItem_Paint);
	
	// ------------------------------------ Hats ------------------------------------ //
	
	h_hat = CreateArray(10);
	h_misc = CreateArray(10);
	h_misc2 = CreateArray(10);

	for(new i = 0 ; i < MaxItem_Look; i++)
	{
		decl String:index[10];
		if(kv[i] != INVALID_HANDLE) GetArrayString(kv[i], 0, index, sizeof(index));
		
		if(TF2IDB_GetItemSlot(StringToInt(index)) == TF2ItemSlot_Hat) PushArrayString(h_hat, index);
		if(TF2IDB_GetItemSlot(StringToInt(index)) == TF2ItemSlot_Misc) PushArrayString(h_misc, index);
		if(TF2IDB_GetItemSlot(StringToInt(index)) == TF2ItemSlot_Head) PushArrayString(h_misc2, index);
	}
	
	decl String:abc[10];
	new Handle:aaaa;
	for(new i = 0; i < GetArraySize(h_misc); i++) // 7777
	{
		decl String:index[10];
		if(h_misc != INVALID_HANDLE) GetArrayString(h_misc, i, index, sizeof(index));
		
		aaaa = TF2IDB_GetItemEquipRegions(StringToInt(index));
		for(new j = 0; j < GetArraySize(aaaa); j++)
		{
			GetArrayString(aaaa, j, abc, sizeof(abc));
			if(!StrEqual(abc, "medal")) PushArrayString(h_misc2, index);
		}
	}	
	CloseHandle(aaaa);
	
	h_paint = CreateArray(20);

	for(new i = 0 ; i < MaxItem_Paint; i++)
	{
		decl String:index[20];
		if(kv[i] != INVALID_HANDLE) GetArrayString(kv2[i], 1, index, sizeof(index));
		PushArrayString(h_paint, index);
	}
}

public Action:SettingCommand(client, args)
{
	new Handle:menu = CreateMenu(Setting_Select);
	
	new String:pp[64], String:rr[64];
	Format(pp, sizeof(pp), "Random Paint [%s]", SettingPaint[client] ? "X" : "O");
	Format(rr, sizeof(rr), "Reset Settings [%s]", SettingReset[client] ? "X" : "O");
	
	AddMenuItem(menu, "1", pp);
	AddMenuItem(menu, "1", rr);
	
	DisplayMenu(menu, client, 60);
	
	return Plugin_Handled;
}

public Setting_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			if(!SettingPaint[client])
			{
				SettingPaint[client] = true;
				PrintToChat(client, "%s\x07FFFFFFHat Random paint was applied.", ALIEN);
			}
			else
			{
				SettingPaint[client] = false;
				PrintToChat(client, "%s\x07FFFFFFHat Paint Removed", ALIEN);
			}
		}
		else if(select == 1)
		{
			if(!SettingReset[client])
			{
				SettingReset[client] = true;
				PrintToChat(client, "%s\x07FFFFFFHaT 모든 클래스를 초기화합니다.", ALIEN);
			}
			else
			{
				SettingReset[client] = false;
				PrintToChat(client, "%s\x07FFFFFFHaT 모든 클래스를 초기화하지 않습니다.", ALIEN);
			}
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action:ResetCommand(client, args)
{
	if(!SettingReset[client])
	{
		for(new i = 0; i <= 2; i++)
		{
			GiveLook[client][i][GCLASS] = 0;
			PaintLook[client][i][GCLASS] = "";
		}
	}
	else
	{
		for(new i = 0; i <= 2; i++)
		{
			for(new j = 0; j <= 9; j++)
			{
				GiveLook[client][i][j] = 0;
				PaintLook[client][i][j] = "";
			}
		}
	}
	
	RandomCheck[client] = false
	teleport(client);
	PrintToChat(client, "%s\x07FFFFFFHat", ALIEN);
	
	return Plugin_Handled;
}

public Action:ResetCommand2(client, args)
{
	for (new c = 1; c <= MaxClients; c++)
	{
		if(IsValidClient(c))
		{
			for(new i = 0; i <= 2; i++)
			{
				for(new j = 0; j <= 9; j++)
				{
					GiveLook[c][i][j] = 0;
					PaintLook[c][i][j] = "";
				}
			}
			RandomCheck[c] = false
			teleport(c);
		}
	}
	
	return Plugin_Handled;
}

public Action:RandomLook(client, args)
{
	if(!RandomCheck[client])
	{
		RandomCheck[client] = true;
		PrintToChat(client, "%s\x07FFFFFFHat Random Hat Applied", ALIEN);
	}
	else
	{
		RandomCheck[client] = false;
		PrintToChat(client, "%s\x07FFFFFFHat Random Hat Not Applied.", ALIEN);
	}
	return Plugin_Handled;
}

// ------------------------------------ The menu itself ------------------------------------ //

public Action:LookMenu(client, args)
{
	new String:SearchWord[16], SearchValue;
	decl String:name[100], String:index[10];
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	new Handle:menu = CreateMenu(Slot_Select);

	SetMenuTitle(menu, "Cosmetics\n \n /look <search>", client);
	AddMenuItem(menu, "0", "Remove");
	
	for(new i = 0 ; i < MaxItem_Look ; i++)
	{
		if(kv[i] != INVALID_HANDLE)
		{
			GetArrayString(kv[i], 0, index, sizeof(index));
			GetArrayString(kv[i], 1, name, sizeof(name));
		}
		
		if(StrContains(name, SearchWord, false) > -1)
		{
			AddMenuItem(menu, index, name);
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "%s\x03The name is either incorrect or missing.",ALIEN);
	
	DisplayMenu(menu, client, 600); //10 mins open
	
	return Plugin_Handled;
}

public Slot_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[10];
		GetMenuItem(menu, select, info, sizeof(info));
		ItemSlot(client, info);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public ItemSlot(client, String:index[])
{
	new Handle:info = CreateMenu(Look_Select);
	SetMenuTitle(info, "Equip Slot");
	
	AddMenuItem(info, index, "Slot 1"); 
	AddMenuItem(info, index, "Slot 2"); 
	AddMenuItem(info, index, "Slot 3"); 

	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
} 

public Look_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, select, info, sizeof(info));
		if(select == 0) GiveLook[client][0][GCLASS] = StringToInt(info);
		else if(select == 1) GiveLook[client][1][GCLASS] = StringToInt(info);
		else if(select == 2) GiveLook[client][2][GCLASS] = StringToInt(info);
		
		teleport(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}
// ------------------------------------ Paints ------------------------------------ //

public Action:PaintMenu(client, args)
{
	new String:SearchWord[16], SearchValue;
	decl String:name[100], String:index[64];
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	new Handle:menu = CreateMenu(PaintSlot_Select);

	SetMenuTitle(menu, "/paint <search>", client);
	AddMenuItem(menu, "", "Remove");
	
	for(new i = 0 ; i < MaxItem_Paint; i++)
	{
		if(kv2[i] != INVALID_HANDLE)
		{
			GetArrayString(kv2[i], 0, name, sizeof(name));
			GetArrayString(kv2[i], 1, index, sizeof(index));
		}
		
		if(StrContains(name, SearchWord, false) > -1)
		{
			AddMenuItem(menu, index, name);
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "%s\x03The name is either incorrect or missing.", ALIEN);
	
	DisplayMenu(menu, client, 60);
	
	return Plugin_Handled;
}

public PaintSlot_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, select, info, sizeof(info));
		PaintSlot(client, info);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public PaintSlot(client, String:index[])
{
	new Handle:info = CreateMenu(Paint_Select);
	SetMenuTitle(info, "Paint Slot");
	
	AddMenuItem(info, index, "Slot 1"); 
	AddMenuItem(info, index, "Slot 2"); 
	AddMenuItem(info, index, "Slot 3"); 

	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
} 

public Paint_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, select, info, sizeof(info));

		if(select == 0) Format(PaintLook[client][0][GCLASS], 100, "%s", info);
		else if(select == 1) Format(PaintLook[client][1][GCLASS], 100, "%s", info);
		else if(select == 2) Format(PaintLook[client][2][GCLASS], 100, "%s", info);
		
		teleport(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action:LevelMenu(client, args)
{
	if(args != 2)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearlevel <1 ~ 3> <0 ~ 127>");
		return Plugin_Handled;
	}
	
	new String:arg[2], String:arg2[3];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new slot = StringToInt(arg), Float:level = StringToFloat(arg2);
	
	if(slot < 1 || slot > 3)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearlevel <1 ~ 3> <0 ~ 127>");
		return Plugin_Handled;
	}
	
	if(level < 0.0 || level > 127.0)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearlevel <1 ~ 3> <0 ~ 127>");
		return Plugin_Handled;
	}

	LevelLook[client][slot-1] = level;
	teleport(client);
	PrintToChat(client, "%s\x04Level applied!", ALIEN);
	
	return Plugin_Handled;
}
//----------------------------------------UNUSUALS----------------------------//
public Action:UnusualMenu(client, args)
{
	if(args != 2)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearunusual <1 ~ 3> <0 ~ 3036>");
		return Plugin_Handled;
	}
	
	new String:arg[2], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new slot = StringToInt(arg), Float:unusual = StringToFloat(arg2);
	
	if(slot < 1 || slot > 3)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearunusual <1 ~ 3> <0 ~ 3036>");
		return Plugin_Handled;
	}
	
	if(unusual < 0.0 || unusual > 3036.0)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearunusual <1 ~ 3> <0 ~ 3036>");
		return Plugin_Handled;
	}
	
	int hat = CreateEntityByName("tf_wearable");

	if (!IsValidEntity(hat))
	{
		return false;
	}

	int effect
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	

	if ((effect) > 0)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2Attrib_SetByDefIndex(hat, 134, effect + 0.0);
	}

	UnusualLook[client][slot-1] = unusual;
	teleport(client);
	
	PrintToChat(client, "%s\x0EEffect applied!", ALIEN);
	
	return Plugin_Handled;
}
public Action:QualityMenu(client, args)
{
	if(args != 2)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearquality <1 ~ 3> <0 ~ 19>");
		return Plugin_Handled;
	}
	
	new String:arg[2], String:arg2[3];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new slot = StringToInt(arg), Float:quality = StringToFloat(arg2);
	
	if(slot < 1 || slot > 3)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearquality <1 ~ 3> <0 ~ 19>");
		return Plugin_Handled;
	}
	
	if(quality < 0.0 || quality > 19.0)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_wearquality <1 ~ 3> <0 ~ 19>");
		return Plugin_Handled;
	}

	QualityLook[client][slot-1] = quality;
	teleport(client);
	PrintToChat(client, "%s\x04Quality applied!", ALIEN);
	
	return Plugin_Handled;
}
public Action:StyleMenu(client, args)
{
	if(args != 2)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_style <item slot> <style index>");
		ALIEN_ReplyToCommand(client, "Usage: sm_style <1 ~ 3> <0 ~ 4>");
		return Plugin_Handled;
	}
	
	new String:arg[2], String:arg2[2];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new slot = StringToInt(arg), Float:style = StringToFloat(arg2);
	
	if(slot < 1 || slot > 3)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_style <1 ~ 3> <0 ~ 4>");
		return Plugin_Handled;
	}
	
	if(style < 0.0 || style > 4.0)
	{
		ALIEN_ReplyToCommand(client, "Usage: sm_style <1 ~ 3> <0 ~ 4>");
		return Plugin_Handled;
	}
	
	StyleLook[client][slot-1] = style;
	teleport(client);
	
	PrintToChat(client, "%s\x04Style may not be applied.", ALIEN);
	
	return Plugin_Handled;
}

// ------------------------------------ Spawn Event ------------------------------------ //

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(RandomCheck[client]) // 7777
	{
		decl String:r_hat[10], String:r_misc[10], String:r_misc2[10];
		decl String:r_paint[20], String:r_paint2[20], String:r_paint3[20];
		
		for(new i = 0; i < GetArraySize(h_hat); i++) GetArrayString(h_hat, GetRandomInt(0, i), r_hat, sizeof(r_hat));
		for(new i = 0; i < GetArraySize(h_misc); i++) GetArrayString(h_misc, GetRandomInt(0, i), r_misc, sizeof(r_misc));
		for(new i = 0; i < GetArraySize(h_misc2); i++) GetArrayString(h_misc2, GetRandomInt(0, i), r_misc2, sizeof(r_misc2));
		
		GiveLook[client][0][GCLASS] = StringToInt(r_hat);
		GiveLook[client][1][GCLASS] = StringToInt(r_misc);
		GiveLook[client][2][GCLASS] = StringToInt(r_misc2);
		
		if(SettingPaint[client])
		{
			for(new i = 0; i < GetArraySize(h_paint); i++)
			{
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint, sizeof(r_paint));
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint2, sizeof(r_paint2));
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint3, sizeof(r_paint3));
				
				Format(PaintLook[client][0][GCLASS], 100, "%s", r_paint);
				Format(PaintLook[client][1][GCLASS], 100, "%s", r_paint2);
				Format(PaintLook[client][2][GCLASS], 100, "%s", r_paint3);
			}
		}
		
		SetHudTextParams(-1.0, 0.1, 3.0, 0, 204, 255, 255, 2, 1.0, 0.05, 0.5);
		ShowHudText(client, 0, "%s", RandomLookName(r_hat));

		SetHudTextParams(-1.0, 0.15, 3.0, 249, 255, 61, 255, 2, 1.0, 0.05, 0.5);
		ShowHudText(client, 1, "%s", RandomLookName(r_misc));
		
		SetHudTextParams(-1.0, 0.2, 3.0, 255, 234, 255, 0, 2, 1.0, 0.05, 0.5);
		ShowHudText(client, 2, "%s", RandomLookName(r_misc2));

		RandomCheck[client] = false;
		teleport(client);
		RandomCheck[client] = true;
	}
}

// ------------------------------------ Inventory Event ------------------------------------ //

public Action:inven(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SlotCheck[client] = 0;
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][0]) == TF2ItemSlot_Hat)
	{
		if(GiveLook[client][0][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][0][GCLASS], PaintLook[client][0][GCLASS], StyleLook[client][0],LevelLook[client][0],UnusualLook[client][0],QualityLook[client][0]);
			PrintToChat(client, "Client: %N, Item Index: %i, Paint: %i, Style: %i, Level: %i, Unusual: %i, Quality: %i", client, GiveLook[client][0][GCLASS], PaintLook[client][0][GCLASS], StyleLook[client][0],LevelLook[client][0],UnusualLook[client][0],QualityLook[client][0]);
			RemoveHat(client, RemoveLook[client][0]);
		}
	}
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][1]) == TF2ItemSlot_Misc)
	{
		if(GiveLook[client][1][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][1][GCLASS], PaintLook[client][1][GCLASS], StyleLook[client][1],LevelLook[client][1],UnusualLook[client][1],QualityLook[client][1]);
			RemoveHat(client, RemoveLook[client][1]);
		}
	}
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][2]) == TF2ItemSlot_Head)
	{
		if(GiveLook[client][2][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][2][GCLASS], PaintLook[client][2][GCLASS], StyleLook[client][2],LevelLook[client][2],UnusualLook[client][2],QualityLook[client][2]);
			RemoveHat(client, RemoveLook[client][2]);
		}
	}
}

public Action:TF2Items_OnGiveNamedItem(client, String:szClassName[], index, &Handle:hItem)
{
	if(TF2IDB_GetItemSlot(index) == TF2ItemSlot_Hat) RemoveLook[client][0] = index;
	if(TF2IDB_GetItemSlot(index) == TF2ItemSlot_Misc)
	{
		SlotCheck[client] ++;
		if(SlotCheck[client] == 0) RemoveLook[client][0] = index;
		if(SlotCheck[client] == 1) RemoveLook[client][1] = index;
		if(SlotCheck[client] == 2) RemoveLook[client][2] = index;

	}
	if(TF2IDB_GetItemSlot(index) == TF2ItemSlot_Head)
	{
		SlotCheck[client] ++;
		if(SlotCheck[client] == 0) RemoveLook[client][0] = index;
		if(SlotCheck[client] == 1) RemoveLook[client][1] = index;
		if(SlotCheck[client] == 2) RemoveLook[client][2] = index;

	}	
	return Plugin_Continue;   
}

// ------------------------------------ Creating the hat ------------------------------------ //

stock bool:CreateHat(client, itemindex, String:att[], Float:att2, Float:att3, Float:att4, Float:att5)
{
	new hat;
	
	if(itemindex == 1067) hat = CreateEntityByName("tf_wearable_levelable_item");
	else hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat)) return Plugin_Continue;
	
	new String:entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1);     
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), 69);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);
//	DispatchSpawn(hat);
//	SDKCall(g_hWearableEquip, client, hat);
	
	if(!StrEqual(att, ""))
	{
		Paint(hat, att);
	}
	if(0.0 < att3 <= 127.0)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), RoundFloat(att3));
	}
	if(att4 != 0.0)
	{
		Unusual(hat, att4);
	}
	if(att5 != 0.0)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), RoundFloat(att5));
	}

	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);

	if(att2 > -1)
	{
		TF2Attrib_RemoveByDefIndex(hat, 542);
		TF2Attrib_SetByDefIndex(hat, 542, att2);
	}	
	return Plugin_Continue;
}

stock RemoveHat(client, index)
{
	new hat = -1;
	if(index == 1067) 
	{
		while((hat=FindEntityByClassname(hat, "tf_wearable_levelable_item"))!=INVALID_ENT_REFERENCE)
		if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)
		if(GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == index) AcceptEntityInput(hat, "Kill");
	}
	else
	{
		while((hat=FindEntityByClassname(hat, "tf_wearable"))!=INVALID_ENT_REFERENCE)
		if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)
		if(GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == index) AcceptEntityInput(hat, "Kill");
	}
}

stock AttAtt(entity, String:att[])
{
	new String:atts[32][32]; 
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	
	if (count > 1) for (new i = 0;  i < count;  i+= 2) TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
}

stock Paint(entity, String:att[])
{
	TF2Attrib_RemoveByDefIndex(entity, 1004);
	TF2Attrib_RemoveByDefIndex(entity, 142);
	TF2Attrib_RemoveByDefIndex(entity, 261);
	
	new Float:paint = StringToFloat(att);
	
	if(paint <= 5.0 && paint >= 0.0) TF2Attrib_SetByDefIndex(entity, 1004, paint);
	else
	{
		new String:aa[3][32]; 
		ExplodeString(att, " ", aa, 3, 32);
		
		if(StrEqual(aa[0], "m"))
		{
			TF2Attrib_SetByDefIndex(entity, 142, StringToFloat(aa[1]));
			TF2Attrib_SetByDefIndex(entity, 261, StringToFloat(aa[2]));
		}
		else TF2Attrib_SetByDefIndex(entity, 142, paint);
	}
}

stock Style(entity, Float:att)
{
	TF2Attrib_RemoveByDefIndex(entity, 542);
	TF2Attrib_SetByDefIndex(entity, 542, att);
}
stock Level(entity, Float:att3)
{
	entity = TF2Items_CreateItem(OVERRIDE_ITEM_LEVEL);
	TF2Items_SetLevel(entity, att3);
}
stock Unusual(entity, Float:att4)
{
	TF2Attrib_RemoveByDefIndex(entity, 134);
	TF2Attrib_SetByDefIndex(entity, 134, att4);
}
stock Quality(entity, Float:att5)
{
	TF2Items_SetQuality(entity, att5);
}

stock String:RandomLookName(String:cv[])
{
	decl String:name[100];
	new A = GetSlotCount(StringToInt(cv));
	if(kv[A] != INVALID_HANDLE) GetArrayString(kv[A], 1, name, sizeof(name));
	return name;
}

stock GetSlotCount(real)
{
	decl String:index[10];
	for(new i = 0 ; i < MaxItem_Look ; i++)
	{
		if(kv[i] != INVALID_HANDLE) GetArrayString(kv[i], 0, index, sizeof(index));
		if(StringToInt(index) == real) return i;
	}
	return -1;
}

stock teleport(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	TF2_RespawnPlayer(client);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

stock ALIEN_ReplyToCommand(client, String:say[]) ReplyToCommand(client, "%s\x07FFFFFF%s", ALIEN, say);

public bool:AliveCheck(client)
{
	if(client > 0 && client <= MaxClients)
	if(IsClientConnected(client) == true)
	if(IsClientInGame(client) == true)
	if(IsPlayerAlive(client) == true) return true;
	else return false;
	else return false;
	else return false;
	else return false;
}


stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}