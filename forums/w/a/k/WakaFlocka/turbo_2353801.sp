//#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <freak_fortress_2>
#include <sdkhooks>
#include <morecolors>

#define PLUGIN_VERSION "1.22.9 Final Version v2.141"

static const String:ff2turboversiontitles[][]=
{
	"1.21.7 Beta",
	"1.22.8 Final Version",
};	
static const String:ff2turboversiondates[][]=
{
	"September 2, 2015",		//1.21.7 Beta
	"September 28, 2015",		//1.22.8 Final Version	
};

stock FindVersionData(Handle:menu, versionIndex)
{
	switch(versionIndex)
	{
		case 0:  // 1.21.7b
		{
			AddMenuItem(menu,"","Fixed An Issue With Damage Bonus Not Working",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Reserve Shooter Having Half Clip Size",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed An Issue Where Secondary Only Gets Half Clip",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Damage Bonus Only Working Some Rounds",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added Minigun Spinup Time Decrease",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added AirBlast Cost Increased",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added 20% Projectile Speed",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed An Issue Where Bosses Gets Attributes",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Primary Weapons Doing Triple Damage",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Secondary Weapons Having 10x Clip size",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed A Bug With Ammo Regen Causing Clients To Crash",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added Damage Blast Radius Increased 20%",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed A Bug Extreme Lag On Round Start",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added AirBlast Knockback Decrease",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Optimized The Plugin To Run More Efficient",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Players Speed Not Working After The 1st Round",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Fire Rate Speed Suddenly Would Stop Working",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Damage Bonus Working Only Some Rounds",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Reload Time Decrease Not Working",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Bosses Weapons Shoot 10x Faster",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added 20% Increased Jump Height So Players Can Dodge Boss Better",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Escape Plan Having Health Regen",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Escape Plan Not Displaying Health Regen After Switching Weapons",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Clip size And OffHand Ammo Having OverSized Ammo",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Arena_Round_Start 5 Second Delay On Each Round",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Clients Reloading Just to Get To The Full Clip size On Round Start",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Melee Faster Fire Rate Not Working",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Health Regen Going On Forever Causing Players To Be Op",ITEMDRAW_DISABLED);
		}
		case 1:		// 1.22.8 Final Version
		{
			AddMenuItem(menu,"","Removed 20% Projectile Speed On Direct Hit",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Reduced Melee Damage Bonus By 40%",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Back Button In Menu Simply Exiting The Entire Menu",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Added Default Movement Speed For Heavy When Firing Brass Beast",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Changed Airblast Cost Increased to 30%",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Fixed Flying Not Firing (Thanks Cuddles)",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","Gunboats Now Only Get 10 Health Regen Every 5 Seconds And 30% Rocket Jump Reduction",ITEMDRAW_DISABLED);
		}
		default:
		{
			AddMenuItem(menu,"","-- Somehow you've managed to find a glitched version page!",ITEMDRAW_DISABLED);
			AddMenuItem(menu,"","-- Congratulations.  Now go and fight!",ITEMDRAW_DISABLED);
		}
	}
}

static const maxVersion=sizeof(ff2turboversiontitles)-1;
//new curHelp[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "TF2: Turbotastic Mode",
	author = "Waka Flocka Flame",
	description = "fixedturbo",
	version = PLUGIN_VERSION,
}

public void OnPluginStart()
{
	LogMessage("TURBOTASTIC MODE INITALIZING (v%s))", PLUGIN_VERSION);
	HookEvent("player_spawn", OnSpawnPre, EventHookMode_Pre);
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_PostNoCopy);
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
	CreateTimer(5.0, Timer_Gunboats, _, TIMER_REPEAT);
	CreateTimer(120.0, Timer_Announce,_, TIMER_REPEAT);
	RegConsoleCmd("turbo", TurboPanelCommand);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new Action:action;
	
	if (GetClientTeam(victim) == FF2_GetBossTeam() && victim != attacker)
	{
		damage *= 1.75;
		action = Plugin_Changed;
	}
	
	return action;
}

public Action:Timer_Second(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		
		if (GetClientTeam(i) == FF2_GetBossTeam())						// Attributes that apply to hale
		{
			TF2Attrib_RemoveAll(i);
			TF2Attrib_SetByName(i, "self dmg push force increased", 1.0);
			TF2Attrib_SetByName(i, "damage force reduction", 0.75);
			TF2Attrib_SetByName(i, "increased jump height", 1.0);
			
			new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");	// disable or enable attributes only on weapons
			if (weapon > -1)
			{
				TF2Attrib_SetByName(weapon, "Projectile speed increased", 1.0);
				TF2Attrib_SetByName(weapon, "Blast radius increased", 1.0);
				TF2Attrib_SetByName(weapon, "self dmg push force increased", 1.0);
				TF2Attrib_SetByName(weapon, "dmg taken from blast reduced", 1.0);

				if (GetPlayerWeaponSlot(i, 2) == weapon) TF2Attrib_SetByName(weapon, "fire rate bonus", 0.65);  // Bosses Melee wep only
			}
			continue;
		}
		
		new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		if (weapon == -1) continue;
		
		//TF2Attrib_SetByName(weapon, "damage bonus", 1.75);
		
		if (!ClientHasWearable(i, 133)) Heal(i, 15);
	}
}

public Action:Timer_Gunboats(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		
		if (GetClientTeam(i) != FF2_GetBossTeam())
		{
			if (ClientHasWearable(i, 133)) Heal(i, 10);
		}
	}
}

stock Heal(client, amount)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1) return;
	new itemIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (itemIndex != 775)
	{
		new old_hp = GetClientHealth(client);
		new hp = old_hp + amount;
		if (hp > GetEntProp(client, Prop_Data, "m_iMaxHealth")) hp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		SetEntityHealth(client, hp);
		
		new Handle:event = CreateEvent("player_healonhit");
		SetEventInt(event, "entindex", client);
		SetEventInt(event, "amount", hp - old_hp);
		FireEvent(event);
	}
}

stock bool:ClientHasWearable(client, index)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		if (index != GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex")) continue;
		return true;
	}
	return false;
}

stock bool IsValidClient(client) // Checks if a client is valid
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)	// I have no idea what this is blame shadow
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(IsValidClient(client) && FF2_GetBossIndex(client)>=0)
		{
			TF2Attrib_RemoveByName(client, "max health additive bonus");
			TF2Attrib_RemoveByName(client, "ammo regen");
			TF2Attrib_RemoveByName(client, "Reload time decreased");
			TF2Attrib_RemoveByName(client, "fire rate bonus");
		}
	}
}

void SetPlayerAttributes(int client)
{
	if((FF2_GetBossIndex(client)==-1 || GetClientTeam(client)!=FF2_GetBossTeam()) && IsValidClient(client))
	{
		TF2Attrib_RemoveAll(client);
		TF2Attrib_SetByName(client, "Reload time decreased", 0.4);
		TF2Attrib_SetByName(client, "max health additive bonus", 50.0);
		TF2Attrib_SetByName(client, "fire rate bonus", 0.5);
		TF2Attrib_SetByName(client, "ammo regen", 100.0);
		TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
		TF2Attrib_SetByName(client, "rocket jump damage reduction", 0.7);
		TF2Attrib_SetByName(client, "self dmg push force increased", 1.1);
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "airblast pushback scale", 0.9);
		TF2Attrib_SetByName(client, "increased jump height",	1.2);
		TF2Attrib_SetByName(client, "minigun spinup time decreased", 0.7);
		TF2Attrib_SetByName(client, "airblast cost increased", 1.8);
		
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_DemoMan: TF2Attrib_SetByName(client, "max pipebombs increased", 2.0);
			case TFClass_Engineer: 	TF2Attrib_SetByName(client, "metal regen", 200.0);
		}
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_DemoMan:	TF2Attrib_SetByName(client, "self dmg push force increased", 1.0);
			case TFClass_Soldier:	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 1.0);
		}
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: TF2Attrib_SetByName(client, "move speed bonus", 1.25);
			case TFClass_Heavy: TF2Attrib_SetByName(client, "move speed bonus", 1.80);
			case TFClass_Soldier: TF2Attrib_SetByName(client, "move speed bonus", 1.80); 
			case TFClass_DemoMan: TF2Attrib_SetByName(client, "move speed bonus", 1.70);
			default: TF2Attrib_SetByName(client, "move speed bonus", 1.65);
		}
	
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		new index=-1;
		if(slot && IsValidEdict(slot))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Primary));
			index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(index)
			{
				case 405, 608, 1101:
				{
					// NOOP
				}
				case 730:
				{
					DelaySetByName(weapon, "maxammo primary increased", 1.4);			//	total ammo
					//TF2Attrib_SetByName(weapon, "damage bonus", 1.75);
					DelaySetByName(weapon, "clip size bonus", 1.66);						// ammo before reloading
				}
				case 1104:
				{
					DelaySetByName(weapon, "clip size bonus", 2.5);
				}
				case 312:
				{
					TF2Attrib_SetByName(weapon, "minigun spinup time decreased", 0.7);
					TF2Attrib_SetByName(weapon, "aiming movespeed decreased",	1.0);
				}
				case 127:			// Default speed for direct hit to balance game out
				{
					TF2Attrib_SetByName(weapon, "Projectile speed increased", 1.0);
				}
				default:
				{
					DelaySetByName(weapon, "maxammo primary increased", 2.0);
					//TF2Attrib_SetByName(weapon, "damage bonus", 1.75);
					DelaySetByName(weapon, "clip size bonus", 2.0);
					TF2Attrib_SetByName(weapon, "Projectile speed increased", 1.5);
					TF2Attrib_SetByName(weapon, "Blast radius increased", 1.2);
				}
			}
		}
		slot=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(slot && IsValidEdict(slot))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary));
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(index)
			{
				case 42, 46, 57, 58, 129, 131, 140, 159, 163, 222, 231, 266, 311, 354, 406, 433, 444, 642, 735, 736, 810, 831, 863, 933, 1001, 1002, 1080, 1083, 1086, 1099, 1101, 1102, 1105, 1121, 1144, 1145:
				{
					// disabled weapons
				}
				case 29, 211, 35, 411, 663, 796, 805, 885, 894, 903, 912, 961, 970, 998:
				{
					// Mediguns
					TF2Attrib_SetByName(weapon, "generate rage on heal", 50.0);
				}
				case 20, 130, 265, 661, 797, 806, 886, 895, 904, 913, 962, 971:
				{
					DelaySetByName(weapon, "Projectile speed increased", 2.5);
					DelaySetByName(weapon, "maxammo primary increased", 2.0);
					DelaySetByName(weapon, "clip size bonus", 2.0);
					TF2Attrib_SetByName(weapon, "Blast radius increased", 1.2);
				}
				default:
				{
					DelaySetByName(weapon, "maxammo secondary increased", 2.0); //index != 415 ? 2.0 : 4.0);
					//TF2Attrib_SetByName(weapon, "damage bonus", 1.75);
					DelaySetByName(weapon, "clip size bonus", index != 415 ? 2.0 : 2.67);
					TF2Attrib_SetByName(weapon, "Projectile speed increased", 1.5);
					TF2Attrib_SetByName(weapon, "Blast radius increased", 1.2);
				}	
			}
		}
		slot=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(slot && IsValidEdict(slot))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch (TF2_GetPlayerClass(client))
				{
					case TFClass_Scout: TF2Attrib_SetByName(client, "damage bonus", 1.25);
				}
			switch(index)				
			{
				case 239, 1084:
				{
					TF2Attrib_SetByName(weapon, "damage bonus", 1.40);
				}
				default:
				{
					TF2Attrib_SetByName(weapon, "damage bonus", 1.10);			// damage bonus for melee weapons only
				}
			}	
		}
	}
}

public Action OnSpawnPre(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	TF2_RemoveAllWeapons(client);
	CreateTimer(0.0, Timer_Resupply, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Resupply(Handle timer, any uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	TF2_RegeneratePlayer(client);
}

public void OnPlayerInventory(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && !IsFakeClient(client))
		SetPlayerAttributes(client);
}

stock DelaySetByName(const weapon, const String:attribute[], const Float:value)
{
	if (StrContains(attribute, "clip size") == 0)
	{
		new String:classname[64];
		GetEdictClassname(weapon, classname, sizeof(classname));
		if (StrContains(classname, "tf_weapon_flamethrower", false) == 0 ||			// means covers all types of that weapon
		StrContains(classname, "tf_weapon_minigun", false) == 0 ||
		StrContains(classname, "tf_weapon_sniperrifle", false) == 0 ||
		StrContains(classname, "tf_weapon_flaregun", false) == 0 ||
		StrContains(classname, "tf_weapon_cleaver",	false) ==0)
			return;
	}
	
	new Handle:data;
	CreateDataTimer(0.3, Timer_SetByName, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, EntIndexToEntRef(weapon));
	WritePackString(data, attribute);
	WritePackFloat(data, value);
	ResetPack(data);
	
	if (StrContains(attribute, "clip size ") == 0)
		SetClip_Weapon(weapon, RoundFloat(GetClip_Weapon(weapon) * value));
	else if (StrContains(attribute, "maxammo ") == 0)
		SetAmmo_Weapon(weapon, RoundFloat(GetAmmo_Weapon(weapon) * value));
}

public Action Timer_SetByName(Handle timer, Handle data)
{
	new ref = ReadPackCell(data);
	new weapon = EntRefToEntIndex(ref);
	if (weapon <= MaxClients) return;
	new String:attribute[96];
	ReadPackString(data, attribute, sizeof(attribute));
	new Float:value = ReadPackFloat(data);
	
	TF2Attrib_SetByName(weapon, attribute, value);
}

stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(owner, iAmmoTable+iOffset, newAmmo, 4, true);
}

stock GetAmmo_Weapon(weapon)
{
	if (weapon == -1) return 0;
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return 0;
	new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	return GetEntData(owner, iAmmoTable+iOffset, 4);
}

stock SetClip_Weapon(weapon, newClip)
{
	new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, iAmmoTable, newClip, 4, true);
}

stock GetClip_Weapon(weapon)
{
	new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	return GetEntData(weapon, iAmmoTable, 4);
}

public Action:Timer_Announce(Handle:timer)
{																							
	static announcecount=-1;
	announcecount++;
	{
		switch(announcecount)
		{
			case 1:
			{
				CPrintToChatAll("{darkorange}[Turbo]\x070792AD Type !turbo or /turbo to open menu{default}"); 
			}
			case 2:
			{
				CPrintToChatAll("{darkorange}[Turbo]{default} Version %s", PLUGIN_VERSION);
			}
			case 3:
			{
				announcecount=0;
				CPrintToChatAll("{darkorange}Turbo 5x Plugin By (Waka Flocka Flame){default}");
			}
			default:
			{
				CPrintToChatAll("{darkorange}[Turbo]\x070792AD Type !turbo or /turbo to open menu{default}");
			}
		}
	}
	return Plugin_Continue;
}

public Action:TurboPanelCommand(client, arg)
{
	DisplayTurboPanel(client);
	return Plugin_Handled;
}

stock DisplayTurboPanel(client)
{
	new Handle:panel=CreatePanel();
	SetPanelTitle(panel, "Turbo Menu:");
	DrawPanelItem(panel, "Player Attributes");
	DrawPanelItem(panel, "Change Log");
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, MenuHandler_TurboPanel, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public MenuHandler_AttributesMenu(Handle:menu, MenuAction:action, client, number)
{
	if (action == MenuAction_End)
	{
		if(client == MenuEnd_ExitBack)
		{
			CloseHandle(menu);
			DisplayTurboPanel(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(number == MenuCancel_ExitBack)
		{
			CloseHandle(menu);
			DisplayTurboPanel(client);
		}
	}
	else
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_TurboPanel(Handle:menu, MenuAction:action, client, number)
{
	if (action == MenuAction_End || action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		switch(number)
		{
			case 1:
			{
				new Handle:amenu = CreateMenu(MenuHandler_AttributesMenu);
				SetMenuTitle(amenu, "Attributes");
				AddMenuItem(amenu,"","Faster Reload Time By 60%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Rocket Jump Damage Reduction by 30%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Movement Speed Increased By 60%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Fire Rate Bonus By 50%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Increased Jump Height By 20%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Self Push Force Increased By 10%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Max Health Bonus By 50%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Damage Taken From Blast Reduced By 30%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","100 Ammo Regen Every 5 Seconds", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Self DmgPush Force Increased By 10%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Minigun Spinup Time Decreased By 30%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","AirBlast Push Weaker By 10%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","AirBlast Cost Increased By 30%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Increased Jump Height By 20%", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Maxpipe Bombs Increased By 2", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","All Players Move 65% Faster (Not Bosses)", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Heavies And Soldiers Move 80% Faster)", ITEMDRAW_DISABLED);
				AddMenuItem(amenu,"","Gunboats Only Get 30% Rocket Jump Damage Reduction)", ITEMDRAW_DISABLED);
				SetMenuExitBackButton(amenu, true);
				DisplayMenu(amenu, client, MENU_TIME_FOREVER);
				//AddMenuItem(amenu,"","Number) Stuff", ITEMDRAW_DISABLED);
			}
			case 2:		// Version Menu Number
			{
				new Handle:vmenu = CreateMenu(MenuHandler_VersionMenu);
				SetMenuTitle(vmenu, "Versions");
				for(int val=0;val<=maxVersion;val++)
				{
					new String:value[10];
					IntToString(val,value, sizeof(value));
					AddMenuItem(vmenu,value,ff2turboversiontitles[val], ITEMDRAW_DEFAULT);
				}
				SetMenuExitBackButton(vmenu, true);
				DisplayMenu(vmenu, client, MENU_TIME_FOREVER);
			}
			case 3:
			{
				CloseHandle(menu);
			}
			default:
			{
				return;
			}
		}
	}	
}

public MenuHandler_VersionInfoMenu(Handle:menu, MenuAction:action, client, number)
{
	if (action == MenuAction_End)
	{
		if(client == MenuEnd_ExitBack)
		{
			CloseHandle(menu);
			DisplayTurboPanel(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(number == MenuCancel_ExitBack)
		{
			CloseHandle(menu);
			DisplayTurboPanel(client);
		}
	}
	else
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_VersionMenu(Handle:menu, MenuAction:action, client, number)		// Version Menu Number
{
	if (action == MenuAction_End)
	{
		if(client == MenuEnd_ExitBack)
		{
			CloseHandle(menu);
			DisplayTurboPanel(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(number == MenuCancel_ExitBack)
		{
			CloseHandle(menu);
			DisplayTurboPanel(client);
		}
	}
	else if (action == MenuAction_Select)
	{
		new Handle:vmenu = CreateMenu(MenuHandler_VersionInfoMenu);
		SetMenuTitle(vmenu, ff2turboversiondates[number]);
		FindVersionData(vmenu, number);
		SetMenuExitBackButton(vmenu, true);
		DisplayMenu(vmenu, client, MENU_TIME_FOREVER);
	}
}
