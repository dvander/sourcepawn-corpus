#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_PLUGIN
#include <tf2items>
#include <tf2items_giveweapon>

#define PLUGIN_VERSION "1.2.0"

#define HATS_ENABLED

#define DEFINED_MAX_CLASSES				10
#define DEFINED_MAX_ITEMS_PER_CLASS		10
#define DEFINED_ITEMS_STRING_L			6
#define DEFINED_MAX_MEMORY_STRING_L		( DEFINED_MAX_ITEMS_PER_CLASS * DEFINED_ITEMS_STRING_L + DEFINED_MAX_ITEMS_PER_CLASS )
#define DEFINED_MAX_PAINTS_STRING_L		20

enum
{
	TF2ItemSlot_Primary = 0,
	TF2ItemSlot_Secondary,
	TF2ItemSlot_Melee,
	TF2ItemSlot_PDA1,
	TF2ItemSlot_PDA2,
#if defined HATS_ENABLED
	TF2ItemSlot_Hat,
	TF2ItemSlot_Misc,
	TF2ItemSlot_Action,
#endif
	TF2ItemSlot_Maximum
};

enum 
{
	TF2ItemQuality_Normal = 0,
	TF2ItemQuality_Unknown1,
	TF2ItemQuality_Genuine = 1,
	TF2ItemQuality_Unknown2,
	TF2ItemQuality_Vintage,
	TF2ItemQuality_Unknown3,
	TF2ItemQuality_Unusual,
	TF2ItemQuality_Unique,
	TF2ItemQuality_Community,
	TF2ItemQuality_Developer,
	TF2ItemQuality_Selfmade,
	TF2ItemQuality_Customized,
	TF2ItemQuality_Strange,
	TF2ItemQuality_Maximum
};

new Handle:g_cvVersion = INVALID_HANDLE;
new Handle:g_cvEnable = INVALID_HANDLE;
new Handle:g_cvFile = INVALID_HANDLE;
new Handle:g_cvMemory = INVALID_HANDLE;
new Handle:g_cvKeep = INVALID_HANDLE;
new Handle:g_cvSWeps = INVALID_HANDLE;
new Handle:g_cvSMWeps = INVALID_HANDLE;
new Handle:g_cvSDMelee = INVALID_HANDLE;
new Handle:g_cvMedieval = INVALID_HANDLE;
new Handle:g_cvRandomizer = INVALID_HANDLE;
#if defined HATS_ENABLED
new Handle:g_cvHats = INVALID_HANDLE;
new Handle:g_cvUHats = INVALID_HANDLE;
new Handle:g_cvHolidays = INVALID_HANDLE;
new Handle:g_hSDKTFEquipWearable = INVALID_HANDLE;
#endif
new bool:g_bSuddenDeath = false;
new bool:g_bMedieval = false;
new bool:g_bRandomizer = false;
#if defined HATS_ENABLED
new bool:g_bHolydays = false;
new TFHoliday:g_nHoliday = TFHoliday:0;
#endif
new iWeapons[DEFINED_MAX_CLASSES][TF2ItemSlot_Maximum][DEFINED_MAX_ITEMS_PER_CLASS];
new iWepCount[DEFINED_MAX_CLASSES][TF2ItemSlot_Maximum];
new String:sMemoryItems[MAXPLAYERS+1][DEFINED_MAX_MEMORY_STRING_L]; // OH SHI-
new TFClassType:sMemoryClass[MAXPLAYERS+1];
#if defined HATS_ENABLED
new String:sMemoryPaint[MAXPLAYERS+1][DEFINED_MAX_PAINTS_STRING_L];
new iPaintColorsS[] = { 1, 7511618, 4345659, 5322826, 14204632, 8208497, 13595446, 10843461, 12955537, 6901050, 8154199, 15185211, 8289918, 15132390, 1315860, 12073019 };
new iPaintColorsT[][2] = { {12073019,5801378}, {4732984,3686984}, {4732984,3686984}, {11049612,8626083}, {3874595,1581885}, {6637376,2636109}, {8400928,2452877}, {12807213,12091445} };
new iUnusualEffects[] = { 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 29, 30, 31, 32, 33, 34, 35, 36 };
#endif


public Plugin:myinfo = {
	name = "[TF2Items] Bot Weapon Randomizer",
	author = "Leonardo",
	description = "Give random weapon to bots",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
};

public OnPluginStart()
{
	g_cvVersion = CreateConVar("tf2items_botweprand_version", PLUGIN_VERSION, "TF2 Bot Weapon Randomizer", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	
	decl String:sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "tf", false) && !StrEqual(sGameDir, "tf_beta", false))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	g_cvEnable = CreateConVar("tf2items_botweprand_enable", "1", _, FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvMemory = CreateConVar("tf2items_botweprand_memory", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvKeep = CreateConVar("tf2items_botweprand_keep_weapon", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvSWeps = CreateConVar("tf2items_botweprand_stock_weapons", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvSMWeps = CreateConVar("tf2items_botweprand_stock_melee", "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvSDMelee = FindConVar("mp_stalemate_meleeonly");
#if defined HATS_ENABLED
	g_cvHats = CreateConVar("tf2items_botweprand_hats", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvUHats = CreateConVar("tf2items_botweprand_unusual_hats", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvHolidays = CreateConVar("tf2items_botweprand_holidays", "1", _, FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_cvHolidays, OnConVarChanged_Holydays);
#endif
	g_cvFile = CreateConVar("tf2items_botweprand_file", "tf2items.botweapons.txt", _, FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_cvFile, OnConVarChanged_File);
	
	HookEvent("post_inventory_application", OnPlayerUpdate, EventHookMode_Post);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("player_changeclass", OnPlayerChangeClass, EventHookMode_Post);
	HookEvent("teamplay_suddendeath_begin", OnSuddenDeathStart, EventHookMode_Pre);
	HookEvent("teamplay_suddendeath_end", OnSuddenDeathEnd, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnSuddenDeathEnd, EventHookMode_Pre);
	
	RegConsoleCmd("tf2items_botweprand_reload", Command_Reload, "Reload config file");
	
	g_bSuddenDeath = false;
	TF2_IsMedievalMode();
	
#if defined HATS_ENABLED
	new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDKTFEquipWearable = EndPrepSDKCall();
		
		CloseHandle(hGameConf);
	}
#endif
}

public OnAllPluginsLoaded()
{
	g_cvRandomizer = FindConVar("tf2items_rnd_enabled");
	if(g_cvRandomizer == INVALID_HANDLE)
		g_bRandomizer = false;
	else
	{
		HookConVarChange(g_cvRandomizer, OnConVarChanged_Randomizer);
		g_bRandomizer = ( GetConVarInt(g_cvRandomizer)!=0 ? true : false );
	}
}

public OnMapStart()
{
	if(GuessSDKVersion()==SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	
	ClearMemory();
	
	g_bSuddenDeath = false;
	TF2_IsMedievalMode();
	
	ReloadConfigs();
}

public OnConfigsExecuted()
{
	if(g_cvRandomizer == INVALID_HANDLE)
		g_bRandomizer = false;
	else
	{
		HookConVarChange(g_cvRandomizer, OnConVarChanged_Randomizer);
		g_bRandomizer = ( GetConVarInt(g_cvRandomizer)!=0 ? true : false );
	}
	
	TF2_IsMedievalMode();
}

#if defined HATS_ENABLED
public Action:TF2_OnIsHolidayActive(TFHoliday:holiday, &bool:result)
{
	if(result) g_nHoliday = holiday;
	return Plugin_Continue;
}
#endif

public Action:OnPlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient>0 && iClient<=MaxClients && IsClientInGame(iClient) && IsFakeClient(iClient))
	{
		new TFClassType:iClass = TF2_GetPlayerClass(iClient);
		if( !GetConVarBool(g_cvKeep) && (GetEventInt(hEvent, "attacker")>0 || GetEventInt(hEvent, "assister")>0) )
		{
			if(strlen(sMemoryItems[iClient])>1)
			{
#if defined HATS_ENABLED
				decl String:sBuffer[DEFINED_MAX_ITEMS_PER_CLASS][DEFINED_ITEMS_STRING_L];
				ExplodeString(sMemoryItems[iClient], ",", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
				Format(sMemoryItems[iClient], DEFINED_MAX_MEMORY_STRING_L, "%i,%i,%i,%i,-1,%s,%s", GetRandomItem(iClass, TF2ItemSlot_Primary), GetRandomItem(iClass, TF2ItemSlot_Secondary), GetRandomItem(iClass, TF2ItemSlot_Melee), GetRandomItem(iClass, TF2ItemSlot_PDA1), sBuffer[TF2ItemSlot_Hat], sBuffer[TF2ItemSlot_Misc]);
#else
				Format(sMemoryItems[iClient], DEFINED_MAX_MEMORY_STRING_L, "%i,%i,%i,%i,-1,-1,-1", GetRandomItem(iClass, TF2ItemSlot_Primary), GetRandomItem(iClass, TF2ItemSlot_Secondary), GetRandomItem(iClass, TF2ItemSlot_Melee), GetRandomItem(iClass, TF2ItemSlot_PDA1));
#endif
			}
			else
				sMemoryItems[iClient] = "";
		}
	}
}

public Action:OnPlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient>0 && iClient<=MaxClients && IsClientInGame(iClient) && IsFakeClient(iClient))
		CheckForSDWeapons( iClient );
}

public Action:OnPlayerChangeClass(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient>0 && iClient<=MaxClients && IsClientInGame(iClient) && IsFakeClient(iClient))
		ClearMemory(iClient);
}

public Action:OnPlayerUpdate(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || !IsFakeClient(iClient))
		return Plugin_Continue;
	
	CheckForSDWeapons( iClient );
	
	if( sMemoryClass[iClient] != TF2_GetPlayerClass(iClient) ) ClearMemory(iClient);
	sMemoryClass[iClient] = TF2_GetPlayerClass(iClient);
	
	if(!GetConVarBool(g_cvEnable) || g_bRandomizer)
		return Plugin_Continue;
	
	CreateTimer(0.05, Timer_LittleDelay, iClient);
	
	return Plugin_Continue;
}

public Action:OnSuddenDeathStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	ClearMemory();
	g_bSuddenDeath = true;
	return Plugin_Continue;
}

public Action:OnSuddenDeathEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	g_bSuddenDeath = false;
	return Plugin_Continue;
}

public Action:Timer_LittleDelay(Handle:hTimer, any:iClient)
{
	new String:sBuffer[DEFINED_MAX_ITEMS_PER_CLASS][DEFINED_ITEMS_STRING_L];
	static iAmmoTable = -1; if (iAmmoTable == -1) iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	
	if(!GetConVarBool(g_cvEnable) || g_bRandomizer)
		return Plugin_Handled;
	
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || !IsFakeClient(iClient))
		return Plugin_Handled;
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient), iDefIndex[TF2ItemSlot_Maximum] = { -1, ... };
	
	if( sMemoryClass[iClient] != iClass ) ClearMemory(iClient);
	sMemoryClass[iClient] = iClass;
	
	if(strlen(sMemoryItems[iClient])>1 && GetConVarBool(g_cvMemory))
	{
		ExplodeString(sMemoryItems[iClient], ",", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
		for(new iSlot=0; iSlot<TF2ItemSlot_Maximum; iSlot++)
		{
#if defined HATS_ENABLED
			if((iSlot==TF2ItemSlot_Hat || iSlot==TF2ItemSlot_Misc) && !GetConVarBool(g_cvHats))
				continue;
#endif
			if(strlen(sBuffer[iSlot])>0 && StringToInt(sBuffer[iSlot])>=0)
				iDefIndex[iSlot] = StringToInt(sBuffer[iSlot]);
			else
				iDefIndex[iSlot] = -1;
		}
	}
	else
		for(new iSlot=0; iSlot<TF2ItemSlot_Maximum; iSlot++)
			iDefIndex[iSlot] = GetRandomItem(iClass, iSlot);
	
	
	if(!g_bSuddenDeath)
	{
		if(iDefIndex[TF2ItemSlot_Primary] != -1)
			if(!g_bMedieval || g_bMedieval && IsMedievalWeapon(iDefIndex[TF2ItemSlot_Primary]))
				TF2Items_GiveWeapon(iClient, iDefIndex[TF2ItemSlot_Primary]);
		
		if(iDefIndex[TF2ItemSlot_Secondary] != -1)
			if(!g_bMedieval || g_bMedieval && IsMedievalWeapon(iDefIndex[TF2ItemSlot_Secondary]))
				TF2Items_GiveWeapon(iClient, iDefIndex[TF2ItemSlot_Secondary]);
	}
	
	if(iDefIndex[TF2ItemSlot_Melee] != -1)
		TF2Items_GiveWeapon(iClient, iDefIndex[TF2ItemSlot_Melee]);
	
	if(iDefIndex[TF2ItemSlot_PDA1] != -1)
		TF2Items_GiveWeapon(iClient, iDefIndex[TF2ItemSlot_PDA1]);
	
#if defined HATS_ENABLED
	if(GetConVarBool(g_cvHats) && g_hSDKTFEquipWearable != INVALID_HANDLE)
	{
		if(iDefIndex[TF2ItemSlot_Hat] != -1)
			EquipNewItem(iClient, iDefIndex[TF2ItemSlot_Hat], TF2ItemSlot_Hat);
		
		if(iDefIndex[TF2ItemSlot_Misc] != -1)
			EquipNewItem(iClient, iDefIndex[TF2ItemSlot_Misc], TF2ItemSlot_Misc);
	}
#endif
	
	
#if defined HATS_ENABLED
	Format(sMemoryItems[iClient], DEFINED_MAX_MEMORY_STRING_L, "%i,%i,%i,%i,-1,%i,%i", iDefIndex[TF2ItemSlot_Primary], iDefIndex[TF2ItemSlot_Secondary], iDefIndex[TF2ItemSlot_Melee], iDefIndex[TF2ItemSlot_PDA1], iDefIndex[TF2ItemSlot_Hat], iDefIndex[TF2ItemSlot_Misc]);
#else
	Format(sMemoryItems[iClient], DEFINED_MAX_MEMORY_STRING_L, "%i,%i,%i,%i,-1,-1,-1", iDefIndex[TF2ItemSlot_Primary], iDefIndex[TF2ItemSlot_Secondary], iDefIndex[TF2ItemSlot_Melee], iDefIndex[TF2ItemSlot_PDA1]);
#endif
	//PrintToServer("- %N - %s -", iClient, sMemoryItems[iClient]);
	
	
	if(iClass==TFClass_Engineer)
	{
		new iWeapon = GetPlayerWeaponSlot(iClient, TF2ItemSlot_Secondary);
		if(IsValidEntity(iWeapon))
		{
			GetEdictClassname(iWeapon, sBuffer[0], DEFINED_ITEMS_STRING_L-1);
			if(strcmp(sBuffer[0],"tf_weapon_pistol",false)==0)
				SetEntData(iClient, iAmmoTable + 8, 200, _, true);
		}
	}
	
	// civilian bug fix
	new iActiveWeapon = -1;
	for(new iSlot=0; iSlot<TF2ItemSlot_Maximum; iSlot++)
		if((iActiveWeapon = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
			if(IsValidEntity(iActiveWeapon))
			{
				EquipPlayerWeapon(iClient, iActiveWeapon);
				break;
			}
	
	return Plugin_Handled;
}

public Action:Command_Reload(iClient, iArgs)
{
	ClearMemory();
	ReloadConfigs();
	if (iClient>=0) ReplyToCommand(iClient, "[TF2Items] Custom Weapons list for Bot Weapon Randomizer reloaded");
	return Plugin_Handled;
}

public OnConVarChanged_Medieval(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	if(bool:StringToInt(sNewValue))
		g_bMedieval = true;
	else
	{
		g_bMedieval = false;
		TF2_IsMedievalMode();
	}
	if(bool:StringToInt(sNewValue)!=bool:StringToInt(sOldValue))
		ClearMemory();
}

public OnConVarChanged_Randomizer(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	g_bRandomizer = ( StringToInt(sNewValue)!=0 ? true : false );

public OnConVarChanged_File(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	Command_Reload(-1, 0);

#if defined HATS_ENABLED
public OnConVarChanged_Holydays(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	g_bHolydays = ( StringToInt(sNewValue)!=0 ? true : false );

EquipNewItem(iClient, iDefIndex, iSlot)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || !IsFakeClient(iClient) || iDefIndex<=0)
		return;
	
	new Handle:hItem = INVALID_HANDLE, iItem = -1, iRand[3] = { -1, -1, -1 }, String:sMemory[4][8], bool:bCustomized = false;
	
	hItem = TF2Items_CreateItem(OVERRIDE_ALL);
	TF2Items_SetClassname(hItem, "tf_wearable");
	TF2Items_SetItemIndex(hItem, iDefIndex);
	TF2Items_SetLevel(hItem, GetItemLevelByID(iDefIndex));
	
	if(iSlot == TF2ItemSlot_Hat)
	{
		if(GetConVarBool(g_cvMemory))
		{
			ExplodeString(sMemoryPaint[iClient], ",", sMemory, sizeof(sMemory), sizeof(sMemory[]));
			if(bool:StringToInt(sMemory[0]))
			{
				iRand[0] = StringToInt(sMemory[1]);
				iRand[1] = StringToInt(sMemory[2]);
				iRand[2] = StringToInt(sMemory[3]);
			}
		}
		
		if(IsCustomizableItem(iDefIndex))
		{
			if(GetConVarBool(g_cvUHats) && (iDefIndex!=116 && iDefIndex!=279) && (GetRandomInt(0,100)<=0 || iRand[0]!=-1))
			{
				if(iRand[0]==-1) iRand[0] = GetRandomInt(1,sizeof(iUnusualEffects)-1);
				TF2Items_SetQuality(hItem, TF2ItemQuality_Unusual);
				TF2Items_SetNumAttributes(hItem, 1);
				TF2Items_SetAttribute(hItem, 0, 134, float(iUnusualEffects[iRand[0]]));
				bCustomized = true;
			}
			if(GetRandomInt(0,100)<=10 || iRand[1]!=-1)
			{
				if(!bCustomized) TF2Items_SetQuality(hItem, TF2ItemQuality_Unique);
				if(bool:GetRandomInt(0,1) && iRand[1]==-1 || iRand[1]==0)
				{
					iRand[1] = 0;
					if(iRand[2]==-1) iRand[2] = GetRandomInt(0,15);
					if(!bCustomized) TF2Items_SetNumAttributes(hItem, 1);
					TF2Items_SetAttribute(hItem, ( bCustomized ? 1 : 0 ), 142, float(iPaintColorsS[iRand[2]]));
				}
				else
				{
					iRand[1] = 1;
					if(iRand[2]==-1) iRand[2] = GetRandomInt(0,7);
					if(!bCustomized) TF2Items_SetNumAttributes(hItem, 2);
					TF2Items_SetAttribute(hItem, ( bCustomized ? 1 : 0 ), 142, float(iPaintColorsT[iRand[2]][0]));
					TF2Items_SetAttribute(hItem, ( bCustomized ? 2 : 1 ), 261, float(iPaintColorsT[iRand[2]][1]));
				}
				bCustomized = true;
			}
		}

		if(!bCustomized)
		{
			TF2Items_SetQuality(hItem, TF2ItemQuality_Unique);
			switch(iDefIndex)
			{
				case 125:
				{
					TF2Items_SetNumAttributes(hItem, 1);
					TF2Items_SetAttribute(hItem, 0, 134, 5.0);
				}
				case 540:
				{
					TF2Items_SetNumAttributes(hItem, 2);
					TF2Items_SetAttribute(hItem, 0, 330, 1.0);
					TF2Items_SetAttribute(hItem, 0, 331, 1.0);
				}
				default:
					TF2Items_SetNumAttributes(hItem, 0);
			}
			sMemoryPaint[iClient] = "0,-1,-1,-1";
		}
		else
		{
			Format(sMemoryPaint[iClient], DEFINED_MAX_PAINTS_STRING_L-1, "1,%i,%i,%i", iRand[0], iRand[1], iRand[1]);
		}
	}
	else if(iSlot == TF2ItemSlot_Misc)
	{
		TF2Items_SetQuality(hItem, TF2ItemQuality_Unique);
		if(iDefIndex==164)
		{
			TF2Items_SetNumAttributes(hItem, 1);
			TF2Items_SetAttribute(hItem, 0, 143, 1223596800.0);
		}
		else if(iDefIndex==165)
		{
			TF2Items_SetNumAttributes(hItem, 1);
			TF2Items_SetAttribute(hItem, 0, 143, 1199923200.0);
		}
		else if(iDefIndex==166)
		{
			TF2Items_SetNumAttributes(hItem, 1);
			TF2Items_SetAttribute(hItem, 0, 143, 1191974400.0);
		}
		else if(iDefIndex==167)
		{
			TF2Items_SetNumAttributes(hItem, 1);
			TF2Items_SetAttribute(hItem, 0, 143, 1189987200.0);
		}
		else
			TF2Items_SetNumAttributes(hItem, 0);
	}

	iItem = TF2Items_GiveNamedItem(iClient, hItem);
	CloseHandle(hItem);

	if(IsValidEntity(iItem))
		SDKCall(g_hSDKTFEquipWearable, iClient, iItem);
}
#endif

GetRandomItem(&TFClassType:iClass, iSlot)
{
	new rand = GetRandomInt(0, iWepCount[_:iClass-1][iSlot]);
#if defined HATS_ENABLED
	if(iSlot==TF2ItemSlot_Hat)
	{
		if(g_bHolydays && g_nHoliday==TFHoliday_HalloweenOrFullMoon)
		{
			rand = GetRandomInt(0, 15);
			switch(rand)
			{
				case 1: return 115;
				case 2: return 116;
				case 3:
					switch(_:iClass)
					{
						case 1: return 268;
						case 2: return 269;
						case 3: return 270;
						case 4: return 271;
						case 5: return 272;
						case 6: return 273;
						case 7: return 276;
						case 8: return 274;
						case 9: return 275;
						default: return -1;
					}
				case 4: return 277;
				case 5: return 279;
				case 6: return 287;
				case 7: return 289;
				case 8:
					switch(_:iClass)
					{
						case 3: return 575;
						case 7: return ( GetRandomInt(0, 1)!=0 ? 570 : 571 );
						default: return -1;
					}
				case 9: return 576;
				case 10: return 578;
				case 11: return 579;
				case 12: return 580;
				case 13: return 581;
				case 14: return 582;
				case 15: return 584;
				default: return -1;
			}
		}
		else if(g_bHolydays && g_nHoliday==TFHoliday_Birthday)
		{
			rand = GetRandomInt(0, 1);
			switch(rand)
			{
				case 1: return 537;
				default: return -1;
			}
		}
		else
		{
			if( GetRandomInt(0,100)>=25 )
			{
				while(
					iWeapons[_:iClass-1][iSlot][rand]==135 // Towering Pillar of Hats
				||	iWeapons[_:iClass-1][iSlot][rand]==137 // Noble Amassment of Hats
				||	iWeapons[_:iClass-1][iSlot][rand]==139 // Modest Pile of Hat
				)
					rand = GetRandomInt(0, iWepCount[_:iClass-1][iSlot]);
			}
		}
	}
#endif
	if(!(_:iClass>0 && _:iClass<=DEFINED_MAX_CLASSES)) return -1;
	if(!(iSlot!=TF2ItemSlot_Primary || iSlot==TF2ItemSlot_Primary && iClass!=TFClass_Spy)) return -1;
	if(!(iClass!=TFClass_Engineer || iClass==TFClass_Engineer && ( iSlot!=TF2ItemSlot_Melee || iSlot==TF2ItemSlot_Melee && (g_bMedieval || g_bSuddenDeath)))) return -1;
	return iWeapons[_:iClass-1][iSlot][rand];
}

CheckForSDWeapons( iClient )
{
	if(iClient>0 && iClient<=MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient))
		if(GetConVarBool(g_cvEnable) && (g_bSuddenDeath && GetConVarBool(g_cvSDMelee) || GetConVarBool(g_cvSMWeps)))
		{
			TF2_RemoveWeaponSlot(iClient, TF2ItemSlot_Primary);
			TF2_RemoveWeaponSlot(iClient, TF2ItemSlot_Secondary);
			if( TF2_GetPlayerClass(iClient) == TFClass_Engineer )
				TF2_RemoveWeaponSlot(iClient, 5); // removing tf_weapon_builder
		}
}

IsMedievalWeapon(_:iDefItemID)
{
	if(
		iDefItemID == 42 // sandwich
		|| iDefItemID == 46 // bonk
		|| iDefItemID == 56 // huntsman
		|| iDefItemID == 57 // razorback
		|| iDefItemID == 131 // chargin targe
		|| iDefItemID == 133 // gunboats
		|| iDefItemID == 159 // dalokohs bar
		|| iDefItemID == 163 // crit-a-cola
		|| iDefItemID == 222 // mad milk
		|| iDefItemID == 231 // darwin's danger shield
		|| iDefItemID == 305 // crusaders crossbow
		|| iDefItemID == 311 // buffalo steak sandvich
		|| iDefItemID == 405 // ali babas wee booties
		|| iDefItemID == 406 // splendid screen
		|| iDefItemID == 433 // fishcake
		|| iDefItemID == 444 // mantreads
		|| iDefItemID == 608 // bootlegger
	)
		return true;
	return false;
}

#if defined HATS_ENABLED
IsCustomizableItem(_:iDefItemID)
{
	if(
		iDefItemID == 47 || iDefItemID == 49 || iDefItemID == 50 || iDefItemID == 51 || iDefItemID == 52 || iDefItemID == 53 || iDefItemID == 54 || iDefItemID == 55
		|| iDefItemID == 94 || iDefItemID == 95 || iDefItemID == 96 || iDefItemID == 97 || iDefItemID == 99 || iDefItemID == 100 || iDefItemID == 101 || iDefItemID == 102
		|| iDefItemID == 103 || iDefItemID == 105 || iDefItemID == 106 || iDefItemID == 107 || iDefItemID == 108 || iDefItemID == 110 || iDefItemID == 116 || iDefItemID == 120
		|| iDefItemID == 126 || iDefItemID == 144 || iDefItemID == 145 || iDefItemID == 146 || iDefItemID == 147 || iDefItemID == 150 || iDefItemID == 151 || iDefItemID == 152
		|| iDefItemID == 158 || iDefItemID == 162 || iDefItemID == 174 || iDefItemID == 175 || iDefItemID == 178 || iDefItemID == 179 || iDefItemID == 180 || iDefItemID == 181
		|| iDefItemID == 182 || iDefItemID == 183 || iDefItemID == 184 || iDefItemID == 185 || iDefItemID == 189 || iDefItemID == 216 || iDefItemID == 246 || iDefItemID == 247
		|| iDefItemID == 248 || iDefItemID == 249 || iDefItemID == 251 || iDefItemID == 252 || iDefItemID == 253 || iDefItemID == 254 || iDefItemID == 255 || iDefItemID == 259
		|| iDefItemID == 260 || iDefItemID == 261 || iDefItemID == 263 || iDefItemID == 279 || iDefItemID == 287 || iDefItemID == 289 || iDefItemID == 291 || iDefItemID == 292
		|| iDefItemID == 295 || iDefItemID == 315 || iDefItemID == 316 || iDefItemID == 319 || iDefItemID == 321 || iDefItemID == 322 || iDefItemID == 323 || iDefItemID == 324
		|| iDefItemID == 330 || iDefItemID == 334 || iDefItemID == 335 || iDefItemID == 339 || iDefItemID == 340 || iDefItemID == 342 || iDefItemID == 344 || iDefItemID == 346
		|| iDefItemID == 347 || iDefItemID == 360 || iDefItemID == 377 || iDefItemID == 380 || iDefItemID == 381 || iDefItemID == 382 || iDefItemID == 384 || iDefItemID == 389
		|| iDefItemID == 390 || iDefItemID == 391 || iDefItemID == 393 || iDefItemID == 395 || iDefItemID == 397 || iDefItemID == 399 || iDefItemID == 420 || iDefItemID == 427
		|| iDefItemID == 436 || iDefItemID == 437 || iDefItemID == 441 || iDefItemID == 446 || iDefItemID == 453 || iDefItemID == 454 || iDefItemID == 459 || iDefItemID == 462
		|| iDefItemID == 465 || iDefItemID == 470 || iDefItemID == 480 || iDefItemID == 483 || iDefItemID == 484 || iDefItemID == 490 || iDefItemID == 491 || iDefItemID == 492
		|| iDefItemID == 514 || iDefItemID == 518 || iDefItemID == 533 || iDefItemID == 534 || iDefItemID == 535 || iDefItemID == 539 || iDefItemID == 600 || iDefItemID == 601
		|| iDefItemID == 602 || iDefItemID == 603 || iDefItemID == 604 || iDefItemID == 605 || iDefItemID == 606 || iDefItemID == 607 || iDefItemID == 611 || iDefItemID == 612
		|| iDefItemID == 613 || iDefItemID == 614 || iDefItemID == 615 || iDefItemID == 616 || iDefItemID == 617 || iDefItemID == 620 || iDefItemID == 621 || iDefItemID == 622
		|| iDefItemID == 626 || iDefItemID == 627 || iDefItemID == 628 || iDefItemID == 629 || iDefItemID == 630 || iDefItemID == 631 || iDefItemID == 633 || iDefItemID == 639
		|| iDefItemID == 641 || iDefItemID == 644 || iDefItemID == 645 || iDefItemID == 647 || iDefItemID == 651 || iDefItemID == 652 || iDefItemID == 653 || iDefItemID == 666
		|| iDefItemID == 671 || iDefItemID == 675 || iDefItemID == 702 || iDefItemID == 703 || iDefItemID == 719 || iDefItemID == 720 || iDefItemID == 722 || iDefItemID == 734
		|| iDefItemID == 753 || iDefItemID == 754
	)
		return true;
	return false;
}
#endif

#if defined HATS_ENABLED
GetItemLevelByID(_:iDefItemID)
{
	new iLevel = GetRandomInt(1,100);
	switch(iDefItemID)
	{
		case 125,262,335,336,360,434,435: { iLevel = 1; }
		case 164,343: { iLevel = 5; }
		case 115,116,126,165,240,261,268,269,270,271,272,273,274,275,276,277,263,279,346,347,486,408,409,410,470,473,490,491,492,514,515,516,517,518,519,520,537: { iLevel = 10; }
		case 422: { iLevel = 13; }
		case 166,333,392,443,483,484: { iLevel = 15; }
		case 170,189,295,299,296,345,420,432,454,1899: { iLevel = 20; }
		case 334: { iLevel = 28; }
		case 332: { iLevel = 30; }
		case 278,287,289,290,291: { iLevel = 31; }
		case 292,471: { iLevel = 50; }
	}
	return iLevel;
}
#endif

ReloadConfigs()
{
	// clearing memory
	ClearMemory();
	
	// loading items
	new Handle:hBotItems = CreateKeyValues("schema"), String:sFilePath[128], String:sBuffer[32];
	
	GetConVarString(g_cvFile, sFilePath, sizeof(sFilePath));
	Format(sFilePath, sizeof(sFilePath), "configs/%s", sFilePath);
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), sFilePath);
	if(!FileExists(sFilePath))
	{
		new Handle:hDataFile = OpenFile(sFilePath, "a");
		WriteFileLine(hDataFile, "\"schema\"");
		WriteFileLine(hDataFile, "{");
		WriteFileLine(hDataFile, "\t\"settings\"");
		WriteFileLine(hDataFile, "\t{");
		GetConVarDefault(g_cvMemory, sBuffer, sizeof(sBuffer));
		WriteFileLine(hDataFile, "\t\t\"enable_itemsets_memory\"\t\"%s\"", sBuffer);
		GetConVarDefault(g_cvKeep, sBuffer, sizeof(sBuffer));
		WriteFileLine(hDataFile, "\t\t\"keep_weapon_after_death\"\t\"%s\"", sBuffer);
		GetConVarDefault(g_cvSWeps, sBuffer, sizeof(sBuffer));
		WriteFileLine(hDataFile, "\t\t\"allow_normal_weapons\"\t\t\"%s\"", sBuffer);
		GetConVarDefault(g_cvSMWeps, sBuffer, sizeof(sBuffer));
		WriteFileLine(hDataFile, "\t\t\"use_normal_melee_only\"\t\t\"%s\"", sBuffer);
#if defined HATS_ENABLED
		GetConVarDefault(g_cvHats, sBuffer, sizeof(sBuffer));
		WriteFileLine(hDataFile, "\t\t\"allow_hats_and_misc\"\t\t\"%s\"", sBuffer);
		GetConVarDefault(g_cvUHats, sBuffer, sizeof(sBuffer));
		WriteFileLine(hDataFile, "\t\t\"allow_unusual_hats\"\t\t\"%s\"", sBuffer);
#endif
		WriteFileLine(hDataFile, "\t}");
		WriteFileLine(hDataFile, "\t\"items\"");
		WriteFileLine(hDataFile, "\t{");
		WriteFileLine(hDataFile, "\t\t\"scout\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"sniper\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"soldier\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"demoman\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"medic\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"hwguy\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"pyro\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"spy\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"pda\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t\t\"engineer\"");
		WriteFileLine(hDataFile, "\t\t{");
		WriteFileLine(hDataFile, "\t\t\t\"primary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"secondary\"\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"melee\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"hat\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t\t\"misc\"\t\t\t\"\"");
		WriteFileLine(hDataFile, "\t\t}");
		WriteFileLine(hDataFile, "\t}");
		WriteFileLine(hDataFile, "}");
		CloseHandle(hDataFile);
		LogError("[TF2Items] Creating new config file: %s", sFilePath);
	}
	else
		FileToKeyValues(hBotItems, sFilePath);
	
	KvRewind(hBotItems);
	
	KvJumpToKey(hBotItems, "settings", false);
	GetConVarDefault(g_cvMemory, sBuffer, sizeof(sBuffer));
	SetConVarBool(g_cvMemory, KvGetNum(hBotItems, "enable_itemsets_memory", StringToInt(sBuffer))!=0, _, false);
	GetConVarDefault(g_cvKeep, sBuffer, sizeof(sBuffer));
	SetConVarBool(g_cvKeep, KvGetNum(hBotItems, "keep_weapon_after_death", StringToInt(sBuffer))!=0, _, false);
	GetConVarDefault(g_cvSWeps, sBuffer, sizeof(sBuffer));
	SetConVarBool(g_cvSWeps, KvGetNum(hBotItems, "allow_normal_weapons", StringToInt(sBuffer))!=0, _, false);
	GetConVarDefault(g_cvSMWeps, sBuffer, sizeof(sBuffer));
	SetConVarBool(g_cvSMWeps, KvGetNum(hBotItems, "use_normal_melee_only", StringToInt(sBuffer))!=0, _, false);
#if defined HATS_ENABLED
	GetConVarDefault(g_cvHats, sBuffer, sizeof(sBuffer));
	SetConVarBool(g_cvHats, KvGetNum(hBotItems, "allow_hats_and_misc", StringToInt(sBuffer))!=0, _, false);
	GetConVarDefault(g_cvUHats, sBuffer, sizeof(sBuffer));
	SetConVarBool(g_cvUHats, KvGetNum(hBotItems, "allow_unusual_hats", StringToInt(sBuffer))!=0, _, false);
#endif
	
	ParseKVDataRow("scout", 1, hBotItems);
	ParseKVDataRow("sniper", 2, hBotItems);
	ParseKVDataRow("soldier", 3, hBotItems);
	ParseKVDataRow("demoman", 4, hBotItems);
	ParseKVDataRow("medic", 5, hBotItems);
	ParseKVDataRow("hwguy", 6, hBotItems);
	ParseKVDataRow("pyro", 7, hBotItems);
	ParseKVDataRow("spy", 8, hBotItems);
	ParseKVDataRow("engineer", 9, hBotItems);
	
	CloseHandle(hBotItems);
}

ClearMemory( iClient = 0 )
{
	if( iClient > 0 && iClient <= MaxClients )
	{
		sMemoryItems[iClient] = "";
#if defined HATS_ENABLED
		sMemoryPaint[iClient] = "";
#endif
		sMemoryClass[iClient] = TFClass_Unknown;
	}
	else
		for(new i=0; i<=MAXPLAYERS; i++)
		{
			sMemoryItems[i] = "";
#if defined HATS_ENABLED
			sMemoryPaint[i] = "";
#endif
			sMemoryClass[i] = TFClass_Unknown;
		}
}

stock TF2_IsMedievalMode()
{
	if(g_cvMedieval==INVALID_HANDLE)
	{
		g_cvMedieval = FindConVar("tf_medieval");
		if(g_cvMedieval==INVALID_HANDLE)
			SetFailState("Can't find tf_medieval ConVar");
		else
			HookConVarChange(g_cvMedieval, OnConVarChanged_Medieval);
	}
	
	if(GetConVarBool(g_cvMedieval))
	{
		g_bMedieval = true;
		return;
	}
	
	new iEntity = -1;
	while((iEntity = FindEntityByClassname2(iEntity, "tf_logic_medieval")) != -1)
	{
		g_bMedieval = true;
		return;
	}
	
	new String:sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	if(strcmp(sMapName, "cp_degrootkeep", false) == 0)
	{
		g_bMedieval = true;
		return;
	}
	
	g_bMedieval = false;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
		startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

stock ParseKVDataRow(String:sClass[], iClass, &Handle:hBotItems)
{
	iClass--;
	new String:sBuffer[(DEFINED_MAX_ITEMS_PER_CLASS-1)*5];
	KvRewind(hBotItems);
	if(KvJumpToKey(hBotItems, "items", false) && KvJumpToKey(hBotItems, sClass, false))
	{
		KvGetString(hBotItems, "primary", sBuffer, sizeof(sBuffer), "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Primary, sBuffer);
		KvGetString(hBotItems, "secondary", sBuffer, sizeof(sBuffer), "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Secondary, sBuffer);
		KvGetString(hBotItems, "melee", sBuffer, sizeof(sBuffer), "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Melee, sBuffer);
		KvGetString(hBotItems, "pda", sBuffer, sizeof(sBuffer), "");
		ParseKVDataRow2(iClass, TF2ItemSlot_PDA1, sBuffer);
#if defined HATS_ENABLED
		KvGetString(hBotItems, "hat", sBuffer, sizeof(sBuffer), "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Hat, sBuffer);
		KvGetString(hBotItems, "misc", sBuffer, sizeof(sBuffer), "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Misc, sBuffer);
#endif
		KvGoBack(hBotItems);
	}
	else
	{
		ParseKVDataRow2(iClass, TF2ItemSlot_Primary, "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Secondary, "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Melee, "");
		ParseKVDataRow2(iClass, TF2ItemSlot_PDA1, "");
#if defined HATS_ENABLED
		ParseKVDataRow2(iClass, TF2ItemSlot_Hat, "");
		ParseKVDataRow2(iClass, TF2ItemSlot_Misc, "");
#endif
	}
}

stock ParseKVDataRow2(iClass, iSlot, String:sItems[])
{
	new bool:bStockWeapons = true;
	if((iSlot==TF2ItemSlot_Primary || iSlot==TF2ItemSlot_Secondary || TF2ItemSlot_Melee)) bStockWeapons = GetConVarBool(g_cvSWeps);
	
	iWepCount[iClass][iSlot] = 0;
	for(new i=0; i<DEFINED_MAX_ITEMS_PER_CLASS; i++)
		iWeapons[iClass][iSlot][i] = -1;
	
	if(strlen(sItems)>0)
	{
		new String:sMultiBuffer[DEFINED_MAX_ITEMS_PER_CLASS-1][DEFINED_MAX_ITEMS_PER_CLASS], iDefIndex;
		iWepCount[iClass][iSlot] = ExplodeString(sItems, ",", sMultiBuffer, sizeof(sMultiBuffer), sizeof(sMultiBuffer[]));
		if(iWepCount[iClass][iSlot]>0)
		{
			for(new iItem=0; iItem<iWepCount[iClass][iSlot]; iItem++)
			{
				if(strlen(sMultiBuffer[iItem])>0)
					iDefIndex = StringToInt(sMultiBuffer[iItem]);
				else
					iDefIndex = -1;
				iWeapons[iClass][iSlot][iItem+(bStockWeapons?1:0)] = iDefIndex;
			}
			if(!bStockWeapons) iWepCount[iClass][iSlot]=iWepCount[iClass][iSlot]-1;
		}
	}
}