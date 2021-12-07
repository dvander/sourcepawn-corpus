#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "warmup manage menu for cs:go",
	author = "lowie",
	description = "Open Menu for manage warmup",
	version = "1.3"
}

new WarmUpType[MAXPLAYERS+1];

new NOCLIP = -1;
new FLASH = -1;
new INC = -1;
new TASER = -1;
new AWP = -1;
new XM = -1;
new HE = -1;
new PISTOL = -1;
new KNIFE = -1;
new DECOY = -1;

new Handle:handle_timer = INVALID_HANDLE;

new g_iPrimaryAmmoType = -1;
new g_iAccount = -1;
new g_iArmorOffset = -1;
new g_iHealth = -1;
new g_WeaponParent = -1;

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	LoadTranslations("warm.phrases");
	
	RegAdminCmd("sm_warm", smwarm, ADMFLAG_BAN, "warm up time menu");

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("weapon_reload", WeaponReload);
	HookEvent("weapon_fire_on_empty", WeaponFireEmpty);
	HookEvent("flashbang_detonate", FlashbangDetonate);
	HookEvent("molotov_detonate", MolotovDetonate);
	HookEvent("hegrenade_detonate", HegrenadeDetonate);
	HookEvent("decoy_started", Decoy_Detonate);
	HookEvent("weapon_fire", Taser_Give);
	HookConVarChange(FindConVar("mp_warmuptime"), WarmUpTime);
	HookConVarChange(FindConVar("mp_warmup_pausetimer"), WarmUpTimePause);

	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
}

public OnClientCookiesCached(target)
{
	WarmUpType[target] = 0;
}

Recover()
{
	NOCLIP = -1;
	FLASH = -1;
	INC = -1;
	TASER = -1;
	AWP = -1;
	XM = -1;
	HE = -1;
	PISTOL = -1;
	KNIFE = -1;
	DECOY = -1;
}


Money(target)
{	
	SetEntData(target, g_iAccount, 0);
}

Armor(target)
{	
	SetEntData(target, g_iArmorOffset, 0);
}

public WeaponSlot(target)
{
	new iWeapon1 = GetPlayerWeaponSlot(target, 0);
	new iWeapon2 = GetPlayerWeaponSlot(target, 1);
	new iWeapon3 = GetPlayerWeaponSlot(target, 2);
	new iWeapon4 = GetPlayerWeaponSlot(target, 3);
	if (IsValidEdict(iWeapon1))
	{
		RemovePlayerItem(target, iWeapon1);
		RemoveEdict(iWeapon1);
	}
	if (IsValidEdict(iWeapon2))
	{
		RemovePlayerItem(target, iWeapon2);
		RemoveEdict(iWeapon2);
	}
	if (IsValidEdict(iWeapon3))
	{			
		RemovePlayerItem(target, iWeapon3);
		RemoveEdict(iWeapon3);
	}
	if (IsValidEdict(iWeapon4))
	{			
		RemovePlayerItem(target, iWeapon4);
		RemoveEdict(iWeapon4);
	}
}

public WeaponSlotKnife(target)
{
	new iWeapon1 = GetPlayerWeaponSlot(target, 0);
	new iWeapon2 = GetPlayerWeaponSlot(target, 1);
	new iWeapon3 = GetPlayerWeaponSlot(target, 3);
	if (IsValidEdict(iWeapon1))
	{
		RemovePlayerItem(target, iWeapon1);
		RemoveEdict(iWeapon1);
	}
	if (IsValidEdict(iWeapon2))
	{
		RemovePlayerItem(target, iWeapon2);
		RemoveEdict(iWeapon2);
	}
	if (IsValidEdict(iWeapon3))
	{			
		RemovePlayerItem(target, iWeapon3);
		RemoveEdict(iWeapon3);
	}
}

CleanUp()
{  // By Kigen (c) 2008 - Please give me credit. :)
	new maxent = GetMaxEntities(), String:name[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, name, sizeof(name));
			if ( ( StrContains(name, "weapon_") != -1 || StrContains(name, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
			RemoveEdict(i);
		}
	}
}

ReserveAmmo(target)
{
	if (target && GetClientTeam(target) >= 2)
	{		
		new entity_index1 = GetPlayerWeaponSlot(target, 0);
		new entity_index2 = GetPlayerWeaponSlot(target, 1);
		if (IsValidEdict(entity_index1))
		{			
			new ammo_type1 = GetEntData(entity_index1, g_iPrimaryAmmoType);			
			GivePlayerAmmo(target, 200, ammo_type1, true);		
		}
		if (IsValidEdict(entity_index2))
		{						
			new ammo_type2 = GetEntData(entity_index2, g_iPrimaryAmmoType);			
			GivePlayerAmmo(target, 200, ammo_type2, true);
		}
	}
}

NoClip(target)
{
	WeaponSlot(target);
	new MoveType:movetype = GetEntityMoveType(target);
	if (movetype != MOVETYPE_NOCLIP)
	{
		CreateTimer(1.0, Timer_NoClip, target);
	}
}

public Action:Timer_NoClip(Handle:timer, any:target)
{
	SetEntityMoveType(target, MOVETYPE_NOCLIP);
}

Flash(target)
{
	SetEntData(target, g_iHealth, 1);
	WeaponSlot(target);
	GivePlayerItem(target, "weapon_flashbang");	
}

Molotov(target)
{
	WeaponSlot(target);
	GivePlayerItem(target, "weapon_incgrenade");
}

He(target)
{
	WeaponSlot(target);
	GivePlayerItem(target, "weapon_hegrenade");
}

Decoy(target)
{
	SetEntData(target, g_iHealth, 1);
	WeaponSlot(target);
	GivePlayerItem(target, "weapon_decoy");
}

Taser(target)
{
	WeaponSlot(target);
	new iItem = GivePlayerItem(target, "weapon_taser");
	EquipPlayerWeapon(target, iItem);
}

Awp(target)
{
	WeaponSlotKnife(target);
	new iItem = GivePlayerItem(target, "weapon_awp");
	EquipPlayerWeapon(target, iItem);
}

Xm(target)
{
	WeaponSlotKnife(target);
	new iItem = GivePlayerItem(target, "weapon_xm1014");
	EquipPlayerWeapon(target, iItem);
}

Pistol(target)
{
	SetEntData(target, g_iAccount, 800);
}

Knife(target)
{
	WeaponSlotKnife(target);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
	{
		return;
	}
	switch(WarmUpType[target])
	{
	case 1: if (FLASH == 1)
		{
			Money(target), Armor(target), Flash(target);
			PrintToChat(target, "[SM] %T", "You have flashbangs and 1 hp only,enjoy!", target);
		}
	case 2: if (INC == 1)
		{
			Money(target), Armor(target), Molotov(target);
			PrintToChat(target, "[SM] %T", "You have molotovs only,enjoy!", target);
		}
	case 3: if (HE == 1)
		{
			Money(target), Armor(target), He(target);
			PrintToChat(target, "[SM] %T", "You have hegrenades only,enjoy!", target);
		}
	case 4: if (TASER == 1)
		{
			Money(target), Armor(target), Taser(target);
			PrintToChat(target, "[SM] %T", "You have a taser only,enjoy!", target);
		}
	case 5: if (AWP == 1)
		{
			Money(target), Armor(target), Awp(target);
			PrintToChat(target, "[SM] %T", "You have a AWP only,enjoy!", target);
		}
	case 6: if (XM == 1)
		{
			Money(target), Armor(target), Xm(target);
			PrintToChat(target, "[SM] %T", "You have a XM1014 only,enjoy!", target);
		}
	case 7: if (PISTOL == 1)
		{
			Money(target), Armor(target), Pistol(target);
			PrintToChat(target, "[SM] %T", "You join a pistol round only,enjoy!", target);
		}
	case 8: if (KNIFE == 1)
		{
			Money(target), Armor(target), Knife(target);
			PrintToChat(target, "[SM] %T", "You have a knife only,enjoy!", target);
		}
	case 9: if (NOCLIP == 1)
		{
			Money(target), Armor(target), NoClip(target);
			PrintToChat(target, "[SM] %T", "You can scout this map,enjoy!", target);
		}
	case 10: if (DECOY == 1)
		{
			Money(target), Armor(target), Decoy(target);
			PrintToChat(target, "[SM] %T", "You have decoy and 1 hp only,enjoy!", target);

		}	
	default: {return;}
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FLASH == 1 || INC == 1 || HE == 1 || DECOY == 1 || AWP == 1 || PISTOL == 1 || XM == 1)
	CleanUp();	
}

public FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FLASH != 1)
	return;
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
	{
		return;
	}
	new iWeapon4 = GetPlayerWeaponSlot(target, 3);
	if (IsValidEdict(iWeapon4))
	{			
		RemovePlayerItem(target, iWeapon4);
		RemoveEdict(iWeapon4);
	}
	Flash(target);
}

public MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (INC != 1)
	return;
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
	{
		return;
	}
	new iWeapon4 = GetPlayerWeaponSlot(target, 3);
	if (IsValidEdict(iWeapon4))
	{			
		RemovePlayerItem(target, iWeapon4);
		RemoveEdict(iWeapon4);
	}
	GivePlayerItem(target, "weapon_incgrenade");	
}

public HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (HE != 1)
	return;
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
	{
		return;
	}
	new iWeapon4 = GetPlayerWeaponSlot(target, 3);
	if (IsValidEdict(iWeapon4))
	{			
		RemovePlayerItem(target, iWeapon4);
		RemoveEdict(iWeapon4);
	}
	GivePlayerItem(target, "weapon_hegrenade");
}

public Decoy_Detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (DECOY != 1)
	return;
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
	{
		return;
	}
	new iWeapon4 = GetPlayerWeaponSlot(target, 3);
	if (IsValidEdict(iWeapon4))
	{			
		RemovePlayerItem(target, iWeapon4);
		RemoveEdict(iWeapon4);
	}
	GivePlayerItem(target, "weapon_decoy");
}

public WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (AWP == 1 || XM == 1 || PISTOL == 1)
	{
		new target = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
		{
			return;
		}
		ReserveAmmo(target);
	}
}

public WeaponFireEmpty(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (AWP == 1 || XM == 1 || PISTOL == 1)
	{
		new target = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
		{
			return;
		}
		ReserveAmmo(target);
	}
}

public Taser_Give(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TASER != 1)
	return;
	
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
	{
		return;
	}	
	CreateTimer(1.0, Timer_Taser, target);
}

public Action:Timer_Taser(Handle:timer, any:target)
{
	new iItem = GivePlayerItem(target, "weapon_taser");
	EquipPlayerWeapon(target, iItem);
}

public Action:Timer_Start(Handle:timer, any:target)
{
	handle_timer = INVALID_HANDLE;
	Recover();
}

public WarmUpTime(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StrEqual(oldVal, newVal))
	return;	
	
	if(handle_timer != INVALID_HANDLE)
	{
		KillTimer(handle_timer);
	}
	new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
	handle_timer = CreateTimer(lefttime, Timer_Start);
	
}

public WarmUpTimePause(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(GetConVarInt(FindConVar("mp_warmup_pausetimer")) == 0)
	return;
	
	if(handle_timer != INVALID_HANDLE)
	{
		KillTimer(handle_timer);
		handle_timer = INVALID_HANDLE;
	}
}

public Action:smwarm(id, args)
{	
	new clientIndex = id;
	if(clientIndex == -1)
	{
		return Plugin_Handled;
	}
	DID(clientIndex);
	ReplyToCommand(id, "Menu of warm up time is open!");
	PrintToChat(clientIndex, "[SM] \x06 %T", "Menu of warm up time is open!", clientIndex);
	return Plugin_Handled;
}

public Action:DID(clientIndex)
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Warm up", clientIndex);
	decl String:itemtext2[256];
	Format(itemtext2, sizeof(itemtext2), "%T", "End warmup!", clientIndex);
	decl String:itemtext3[256];
	Format(itemtext3, sizeof(itemtext3), "%T", "Start warmup!", clientIndex);
	decl String:itemtext4[256];
	Format(itemtext4, sizeof(itemtext4), "%T", "Infinite Warmup!", clientIndex);
	decl String:itemtext5[256];
	Format(itemtext5, sizeof(itemtext5), "%T", "End Infinite Warmup!", clientIndex);
	decl String:itemtext6[256];
	Format(itemtext6, sizeof(itemtext6), "%T", "Warm up time contrl!", clientIndex);
	decl String:itemtext7[256];
	Format(itemtext7, sizeof(itemtext7), "%T", "Warm up types!", clientIndex);
	
	SetMenuTitle(menu, title);
	AddMenuItem(menu, "option2", itemtext2);
	AddMenuItem(menu, "option3", itemtext3);
	AddMenuItem(menu, "option4", itemtext4);
	AddMenuItem(menu, "option5", itemtext5);
	AddMenuItem(menu, "option6", itemtext6);
	AddMenuItem(menu, "option7", itemtext7);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientIndex, 15);
	
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, clientIndex, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if ( strcmp(info,"option2") == 0 )
		{
			Recover();
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
				handle_timer = INVALID_HANDLE;
			}
			ServerCommand("mp_warmup_end");
		}
		
		else if ( strcmp(info,"option3") == 0 )
		{
			Recover();
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
				handle_timer = INVALID_HANDLE;
			}
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			ServerCommand("mp_warmup_start");
		}
		
		else if ( strcmp(info,"option4") == 0 )
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "1");
		}
		
		else if ( strcmp(info,"option5") == 0 )
		{
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
				handle_timer = INVALID_HANDLE;
			}
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			ServerCommand("mp_warmup_start");
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option6") == 0 )
		{
			DID_time(clientIndex);
		}
		
		else if ( strcmp(info,"option7") == 0 ) 
		{			
			DID_type(clientIndex);
		}		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:DID_time(clientIndex)
{
	new Handle:menu_time = CreateMenu(DIDMenuHandler_time);
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Warm up time contrl", clientIndex);
	decl String:itemtext2[256];
	Format(itemtext2, sizeof(itemtext2), "%T", "Warm up time + 30 seconds!", clientIndex);
	decl String:itemtext3[256];
	Format(itemtext3, sizeof(itemtext3), "%T", "Warm up time - 30 seconds!", clientIndex);
	decl String:itemtext4[256];
	Format(itemtext4, sizeof(itemtext4), "%T", "Warm up time + 1 Minute", clientIndex);
	decl String:itemtext5[256];
	Format(itemtext5, sizeof(itemtext5), "%T", "Warm up time - 1 Minute!", clientIndex);
	decl String:itemtext6[256];
	Format(itemtext6, sizeof(itemtext6), "%T", "Warm up time + 3 Minutes!", clientIndex);
	decl String:itemtext7[256];
	Format(itemtext7, sizeof(itemtext7), "%T", "Warm up time - 3 Minutes!", clientIndex);
	
	SetMenuTitle(menu_time, title);
	AddMenuItem(menu_time, "option2", itemtext2);
	AddMenuItem(menu_time, "option3", itemtext3);
	AddMenuItem(menu_time, "option4", itemtext4);
	AddMenuItem(menu_time, "option5", itemtext5);
	AddMenuItem(menu_time, "option6", itemtext6);
	AddMenuItem(menu_time, "option7", itemtext7);
	SetMenuExitButton(menu_time, true);
	DisplayMenu(menu_time, clientIndex, 0);
	
	return Plugin_Handled;
}

public DIDMenuHandler_time(Handle:menu_time, MenuAction:action, clientIndex, itemNum) 
{
	if ( action == MenuAction_Select )
	{
		new String:info[32];
		
		GetMenuItem(menu_time, itemNum, info, sizeof(info));

		if ( strcmp(info,"option2") == 0 )
		{
			SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(FindConVar("mp_warmuptime")) + 30, true, true);
		}
		
		else if ( strcmp(info,"option3") == 0 )
		{
			if(GetConVarInt(FindConVar("mp_warmuptime")) > 30)
			SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(FindConVar("mp_warmuptime")) - 30, true, true);
		}
		
		else if ( strcmp(info,"option4") == 0 )
		{
			SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(FindConVar("mp_warmuptime")) + 60, true, true);
		}
		
		else if ( strcmp(info,"option5") == 0 )
		{
			if(GetConVarInt(FindConVar("mp_warmuptime")) > 60)
			SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(FindConVar("mp_warmuptime")) - 60, true, true);
		}
		
		else if ( strcmp(info,"option6") == 0 )
		{
			SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(FindConVar("mp_warmuptime")) + 180, true, true);
		}
		
		else if ( strcmp(info,"option7") == 0 )
		{
			if(GetConVarInt(FindConVar("mp_warmuptime")) > 180)
			SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(FindConVar("mp_warmuptime")) - 180, true, true);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu_time);
	}
}

public Action:DID_type(clientIndex)
{
	new Handle:menu_type = CreateMenu(DIDMenuHandler_type);
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Warm up types", clientIndex);
	decl String:itemtext2[256];
	Format(itemtext2, sizeof(itemtext2), "%T", "Scout!", clientIndex);
	decl String:itemtext3[256];
	Format(itemtext3, sizeof(itemtext3), "%T", "1hp and flashbang!", clientIndex);
	decl String:itemtext4[256];
	Format(itemtext4, sizeof(itemtext4), "%T", "1hp and decoy!", clientIndex);
	decl String:itemtext5[256];
	Format(itemtext5, sizeof(itemtext5), "%T", "Incendiaries!", clientIndex);
	decl String:itemtext6[256];
	Format(itemtext6, sizeof(itemtext6), "%T", "HEgrenade only!", clientIndex);
	decl String:itemtext7[256];
	Format(itemtext7, sizeof(itemtext7), "%T", "Tasers only!", clientIndex);
	decl String:itemtext8[256];
	Format(itemtext8, sizeof(itemtext8), "%T", "AWP only!", clientIndex);
	decl String:itemtext9[256];
	Format(itemtext9, sizeof(itemtext9), "%T", "XM1014 only!", clientIndex);
	decl String:itemtext10[256];
	Format(itemtext10, sizeof(itemtext10), "%T", "Pistol round!", clientIndex);
	decl String:itemtext11[256];
	Format(itemtext11, sizeof(itemtext11), "%T", "Knife round!", clientIndex);
	decl String:itemtext12[256];
	Format(itemtext12, sizeof(itemtext11), "%T", "Default!", clientIndex);
	
	SetMenuTitle(menu_type, title);
	AddMenuItem(menu_type, "option2", itemtext2);
	AddMenuItem(menu_type, "option3", itemtext3);
	AddMenuItem(menu_type, "option4", itemtext4);
	AddMenuItem(menu_type, "option5", itemtext5);
	AddMenuItem(menu_type, "option6", itemtext6);
	AddMenuItem(menu_type, "option7", itemtext7);
	AddMenuItem(menu_type, "option8", itemtext8);
	AddMenuItem(menu_type, "option9", itemtext9);
	AddMenuItem(menu_type, "option10", itemtext10);
	AddMenuItem(menu_type, "option11", itemtext11);
	AddMenuItem(menu_type, "option12", itemtext12);
	SetMenuExitButton(menu_type, true);
	DisplayMenu(menu_type, clientIndex, 15);
	
	return Plugin_Handled;
}

public DIDMenuHandler_type(Handle:menu_type, MenuAction:action, clientIndex, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu_type, itemNum, info, sizeof(info));

		if ( strcmp(info,"option2") == 0 ) 
		{									
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			Recover();
			NOCLIP = 1;
			PrintToChatAll("[SM] \x06 %T", "You can scout this map,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{																									
							WarmUpType[target] = 9;
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option3") == 0 ) 
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			Recover();
			FLASH = 1;
			PrintToChatAll("[SM] \x06 %T", "You have flashbangs and 1 hp only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 1;							
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");			
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option4") == 0 ) 
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");			
			Recover();
			DECOY = 1;
			PrintToChatAll("[SM] \x06 %T", "You have decoy and 1 hp only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 10;							
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");			
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option5") == 0 ) 
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");			
			Recover();
			INC = 1;
			PrintToChatAll("[SM] \x06 %T", "You have molotovs only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 2;						
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");		
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option6") == 0 ) 
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");			
			Recover();
			HE = 1;
			PrintToChatAll("[SM] \x06 %T", "You have hegrenades only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 3;						
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");		
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option7") == 0 ) 
		{			
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			Recover();
			TASER = 1;
			PrintToChatAll("[SM] \x06 %T", "You have a taser only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 4;							
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");			
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}

		else if ( strcmp(info,"option8") == 0 ) 
		{			
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");			
			Recover();
			AWP = 1;
			PrintToChatAll("[SM] \x06 %T", "You have a AWP only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 5;						
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");			
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option9") == 0 ) 
		{			
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");			
			Recover();
			XM = 1;
			PrintToChatAll("[SM] \x06 %T", "You have a XM1014 only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 6;						
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");			
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option10") == 0 ) 
		{			
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");			
			Recover();
			PISTOL = 1;
			PrintToChatAll("[SM] \x06 %T", "You join a pistol round only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 7;							
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");		
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option11") == 0 ) 
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			Recover();
			KNIFE = 1;
			PrintToChatAll("[SM] \x06 %T", "You have a knife only,enjoy!", clientIndex);
			for(new target = 1; target <= MaxClients; target++)
			{
				if(IsClientConnected(target))
				{
					if(IsClientInGame(target))
					{
						if(!IsClientObserver(target))
						{
							WarmUpType[target] = 8;						
						}
					}
				}
			}
			ServerCommand("mp_warmup_start");
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
			}
			new Float:lefttime = GetConVarFloat(FindConVar("mp_warmuptime"));
			handle_timer = CreateTimer(lefttime, Timer_Start);
		}
		
		else if ( strcmp(info,"option12") == 0 ) 
		{
			SetConVarString(FindConVar("mp_warmup_pausetimer"), "0");
			Recover();	
			if(handle_timer != INVALID_HANDLE)
			{
				KillTimer(handle_timer);
				handle_timer = INVALID_HANDLE;
			}
			SetConVarInt(FindConVar("mp_restartgame"), 1, true, true);		
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu_type);
	}
}