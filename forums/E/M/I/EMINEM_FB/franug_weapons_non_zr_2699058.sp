/*  SM Franug Weapons
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#define VERSION "3.1"


new Handle:Timers[MAXPLAYERS + 1] = INVALID_HANDLE;

new bool:newWeaponsSelected[MAXPLAYERS+1];
new bool:rememberChoice[MAXPLAYERS+1];
new bool:weaponsGivenThisRound[MAXPLAYERS + 1] = { false, ... };

// Menus
new Handle:optionsMenu1 = INVALID_HANDLE;
new Handle:optionsMenu2 = INVALID_HANDLE;
new Handle:optionsMenu3 = INVALID_HANDLE;
new Handle:optionsMenu4 = INVALID_HANDLE;

new String:primaryWeapon[MAXPLAYERS + 1][24];
new String:secondaryWeapon[MAXPLAYERS + 1][24];

new Handle:cvar_smoke;
new Handle:cvar_hegrenade;
new Handle:cvar_decoy;
new Handle:cvar_molotov;
new Handle:cvar_flash;

new b_smoke;
new b_hegrenade;
new b_decoy;
new b_molotov;
new b_flash;

// Grenade Defines
#define NADE_FLASHBANG    0
#define NADE_MOLOTOV      1
#define NADE_SMOKE        2
#define NADE_HE           3
#define NADE_DECOY        4
#define NADE_INCENDIARY   5

new const g_iaGrenadeOffsets[] = {15, 17, 16, 14, 18, 17};


enum Armas
{
	String:nombre[64],
	String:desc[64]
}

new Handle:array_primarias;
new Handle:array_secundarias;

public Plugin:myinfo =
{
	name = "SM Franug Weapons",
	author = "Franc1sco franug",
	description = "plugin",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

new Handle:weapons1 = INVALID_HANDLE;
new Handle:weapons2 = INVALID_HANDLE;
//new Handle:remember = INVALID_HANDLE;

public OnPluginStart()
{
	array_primarias = CreateArray(128);
	array_secundarias = CreateArray(128);
	ListaArmas();
	
	// Create menus
	optionsMenu1 = BuildOptionsMenu(true);
	optionsMenu2 = BuildOptionsMenu(false);
	optionsMenu3 = BuildOptionsMenuWeapons(true);
	optionsMenu4 = BuildOptionsMenuWeapons(false);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	weapons1 = RegClientCookie("Primary Weapons", "", CookieAccess_Private);
	weapons2 = RegClientCookie("Secondary Weapons", "", CookieAccess_Private);
	//remember = RegClientCookie("Remember Weapons", "", CookieAccess_Private);
	
	cvar_smoke = CreateConVar("sm_zeusweapons_smoke", "1", "Number of smoke");
	cvar_hegrenade = CreateConVar("sm_zeusweapons_hegrenade", "1", "Number of hegrenade");
	cvar_decoy = CreateConVar("sm_zeusweapons_decoy", "0", "Number of decoy");
	cvar_molotov = CreateConVar("sm_zeusweapons_molotov", "0", "Number of molotov");
	cvar_flash = CreateConVar("sm_zeusweapons_flash", "0", "Number of flashbang");
	
	b_smoke = GetConVarInt(cvar_smoke);
	b_hegrenade = GetConVarInt(cvar_hegrenade);
	b_decoy = GetConVarInt(cvar_decoy);
	b_molotov = GetConVarInt(cvar_molotov);
	b_flash = GetConVarInt(cvar_flash);
	
	HookConVarChange(cvar_smoke, OnConVarChanged);
	HookConVarChange(cvar_hegrenade, OnConVarChanged);
	HookConVarChange(cvar_decoy, OnConVarChanged);
	HookConVarChange(cvar_molotov, OnConVarChanged);
	HookConVarChange(cvar_flash, OnConVarChanged);
	
	LoadTranslations("franug_weapons.phrases");
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_smoke)
	{
		b_smoke = StringToInt(newValue);
	}
	else if (convar == cvar_hegrenade)
	{
		b_hegrenade = StringToInt(newValue);
	}
	else if (convar == cvar_decoy)
	{
		b_decoy = StringToInt(newValue);
	}
	else if (convar == cvar_molotov)
	{
		b_molotov = StringToInt(newValue);
	}
	else if (convar == cvar_flash)
	{
		b_flash = StringToInt(newValue);
	}
}

Handle:BuildOptionsMenu(bool:sameWeaponsEnabled)
{
	new sameWeaponsStyle = (sameWeaponsEnabled) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	new Handle:menu3 = CreateMenu(Menu_Options, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem );
	SetMenuTitle(menu3, "Weapon Menu:");
	SetMenuExitButton(menu3, true);
	AddMenuItem(menu3, "New", "New weapons");
	AddMenuItem(menu3, "Same 1", "Same weapons", sameWeaponsStyle);
	AddMenuItem(menu3, "Same All", "Same weapons every round", sameWeaponsStyle);
	AddMenuItem(menu3, "Random 1", "Random weapons");
	AddMenuItem(menu3, "Random All", "Random weapons every round");
	return menu3;
}

DisplayOptionsMenu(clientIndex)
{
	if (strcmp(primaryWeapon[clientIndex], "") == 0 || strcmp(secondaryWeapon[clientIndex], "") == 0)
		DisplayMenu(optionsMenu2, clientIndex, MENU_TIME_FOREVER);
	else
		DisplayMenu(optionsMenu1, clientIndex, MENU_TIME_FOREVER);
}

Handle:BuildOptionsMenuWeapons(bool:primary)
{
	new Handle:menu;
	new Items[Armas];
	if(primary)
	{
		menu = CreateMenu(Menu_Primary);
		SetMenuTitle(menu, "Primary Weapon:");
		SetMenuExitButton(menu, true);
		for(new i=0;i<GetArraySize(array_primarias);++i)
		{
			GetArrayArray(array_primarias, i, Items[0]);
			AddMenuItem(menu, Items[nombre], Items[desc]);
		}
	}
	else
	{
		menu = CreateMenu(Menu_Secondary);
		SetMenuTitle(menu, "Secundary Weapon:");
		SetMenuExitButton(menu, true);
		for(new i=0;i<GetArraySize(array_secundarias);++i)
		{
			GetArrayArray(array_secundarias, i, Items[0]);
			AddMenuItem(menu, Items[nombre], Items[desc]);
		}
	}
	
	return menu;

}


public Menu_Options(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "New"))
		{
			if (weaponsGivenThisRound[param1])
				newWeaponsSelected[param1] = true;
			DisplayMenu(optionsMenu3, param1, MENU_TIME_FOREVER);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				PrintToChat(param1, "[\x04GUNS\x01] %t.", "Same");
			}
			GiveSavedWeapons(param1);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same All"))
		{
			if (weaponsGivenThisRound[param1])
				PrintToChat(param1, "[\x04GUNS\x01] %t.", "Same_All");
			GiveSavedWeapons(param1);
			rememberChoice[param1] = true;
		}
		else if (StrEqual(info, "Random 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				PrintToChat(param1, "[\x04GUNS\x01] %t.", "Random");
			}
			primaryWeapon[param1] = "random";
			secondaryWeapon[param1] = "random";
			GiveSavedWeapons(param1);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Random All"))
		{
			if (weaponsGivenThisRound[param1])
				PrintToChat(param1, "[\x04GUNS\x01] %t.", "Random_All");
			primaryWeapon[param1] = "random";
			secondaryWeapon[param1] = "random";
			GiveSavedWeapons(param1);
			rememberChoice[param1] = true;
		}
	}
	else if	(action == MenuAction_DisplayItem)
	{
		decl String:Display[128];
		switch(param2)
		{
			case 0: FormatEx(Display, sizeof(Display), "%T", "Menu_NewWeapons", param1);
			case 1: FormatEx(Display, sizeof(Display), "%T", "Menu_SameWeapons", param1);
			case 2: FormatEx(Display, sizeof(Display), "%T", "Menu_SameWeapons_all", param1);
			case 3: FormatEx(Display, sizeof(Display), "%T", "Menu_Random", param1);
			case 4: FormatEx(Display, sizeof(Display), "%T", "Menu_Random_All", param1);
		}
		return RedrawMenuItem(Display);
	}
	return 0;
}

public Menu_Primary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		primaryWeapon[param1] = info;
		DisplayMenu(optionsMenu4, param1, MENU_TIME_FOREVER);
	}
}

public Menu_Secondary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		secondaryWeapon[param1] = info;
		GiveSavedWeapons(param1);
		if (!IsPlayerAlive(param1))
			newWeaponsSelected[param1] = true;
		if (newWeaponsSelected[param1])
			PrintToChat(param1, "[\x04GUNS\x01] %t.", "New_weapons");
	}
}

public OnMapStart()
{
	SetBuyZones("Disable");
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//CancelClientMenu(clientIndex);
	MatarTimer(clientIndex);
	Timers[clientIndex] = CreateTimer(2.0, Aparecer, clientIndex);
}

public Action:Aparecer(Handle:timer, any:clientIndex)
{
	Timers[clientIndex] = INVALID_HANDLE;
	if (GetClientTeam(clientIndex) > 1 && IsPlayerAlive(clientIndex))
	{
		// Give weapons or display menu.
		weaponsGivenThisRound[clientIndex] = false;
		if (newWeaponsSelected[clientIndex])
		{
			GiveSavedWeapons(clientIndex);
			newWeaponsSelected[clientIndex] = false;
		}
		else if (rememberChoice[clientIndex])
		{
			GiveSavedWeapons(clientIndex);
		}
		else
		{
			DisplayOptionsMenu(clientIndex);
		}
	}
}

SetBuyZones(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_buyzone"))
				AcceptEntityInput(i, status);
		}
	}
}

public Action:Event_Say(clientIndex, const String:command[], arg)
{
	static String:menuTriggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };
	
	if (clientIndex > 0 && IsClientInGame(clientIndex))
	{
		// Retrieve and clean up text.
		decl String:text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
	
		for(new i = 0; i < sizeof(menuTriggers); i++)
		{
			if (StrEqual(text, menuTriggers[i], false))
			{
				rememberChoice[clientIndex] = false;
				DisplayOptionsMenu(clientIndex);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

GiveSavedWeapons(clientIndex)
{
	decl String:weapons[128];
	new weaponindex;
	if (!weaponsGivenThisRound[clientIndex] && IsPlayerAlive(clientIndex))
	{
		//StripAllWeapons(clientIndex);
		weaponindex = GetPlayerWeaponSlot(clientIndex, CS_SLOT_PRIMARY);
		if (StrEqual(primaryWeapon[clientIndex], "random"))
		{
			if(weaponindex != -1)
			{
				RemovePlayerItem(clientIndex, weaponindex);
				AcceptEntityInput(weaponindex, "Kill");
			}
			// Select random menu item (excluding "Random" option)
			new random = GetRandomInt(0, GetArraySize(array_primarias)-1);
			new Items[Armas];
			GetArrayArray(array_primarias, random, Items[0]);
			GivePlayerItem(clientIndex, Items[nombre]);
		}
		else
		{
			if(weaponindex != -1)
			{
				GetEdictClassname(weaponindex, weapons, 128);
				if(!StrEqual(weapons, primaryWeapon[clientIndex]))
				{
					RemovePlayerItem(clientIndex, weaponindex);
					AcceptEntityInput(weaponindex, "Kill");
					
					GivePlayerItem(clientIndex, primaryWeapon[clientIndex]);
				}
			}
			else
			{
				
				GivePlayerItem(clientIndex, primaryWeapon[clientIndex]);
			}
		}
		
		// next
		
		weaponindex = GetPlayerWeaponSlot(clientIndex, CS_SLOT_SECONDARY);
		if (StrEqual(secondaryWeapon[clientIndex], "random"))
		{
			if(weaponindex != -1)
			{
				RemovePlayerItem(clientIndex, weaponindex);
				AcceptEntityInput(weaponindex, "Kill");
			}
			// Select random menu item (excluding "Random" option)
			new random = GetRandomInt(0, GetArraySize(array_secundarias)-1);
			new Items[Armas];
			GetArrayArray(array_secundarias, random, Items[0]);
			GivePlayerItem(clientIndex, Items[nombre]);
		}
		else
		{
			if(weaponindex != -1)
			{
				GetEdictClassname(weaponindex, weapons, 128);
				if(!StrEqual(weapons, secondaryWeapon[clientIndex]))
				{
					RemovePlayerItem(clientIndex, weaponindex);
					AcceptEntityInput(weaponindex, "Kill");
					
					GivePlayerItem(clientIndex, secondaryWeapon[clientIndex]);
				}
			}
			else
			{
				
				GivePlayerItem(clientIndex, secondaryWeapon[clientIndex]);
			}
		}

/* 		new iEnt;
		while ((iEnt = GetPlayerWeaponSlot(clientIndex, CS_SLOT_GRENADE)) != -1)
		{
            RemovePlayerItem(clientIndex, iEnt);
            AcceptEntityInput(iEnt, "Kill");
		} */
		
		
		RemoveNades(clientIndex);
		
		if(b_hegrenade > 0) 
		{
			GivePlayerItem(clientIndex, "weapon_hegrenade");
			SetEntProp(clientIndex, Prop_Send, "m_iAmmo", b_hegrenade, _, g_iaGrenadeOffsets[NADE_HE]);
		}
		if(b_decoy > 0)
		{
			GivePlayerItem(clientIndex, "weapon_decoy");
			SetEntProp(clientIndex, Prop_Send, "m_iAmmo", b_decoy, _, g_iaGrenadeOffsets[NADE_DECOY]);
		}
		if(b_molotov > 0)
		{
			GivePlayerItem(clientIndex, "weapon_molotov");
			SetEntProp(clientIndex, Prop_Send, "m_iAmmo", b_molotov, _, g_iaGrenadeOffsets[NADE_MOLOTOV]);
		}
		if(b_smoke > 0)
		{
			GivePlayerItem(clientIndex, "weapon_smokegrenade");
			SetEntProp(clientIndex, Prop_Send, "m_iAmmo", b_smoke, _, g_iaGrenadeOffsets[NADE_SMOKE]);
		}
		if(b_flash > 0)
		{
			GivePlayerItem(clientIndex, "weapon_flashbang");
			SetEntProp(clientIndex, Prop_Send, "m_iAmmo", b_flash, _, g_iaGrenadeOffsets[NADE_FLASHBANG]);
		}
		weaponsGivenThisRound[clientIndex] = true;
			
		if(GetPlayerWeaponSlot(clientIndex, 2) == -1) GivePlayerItem(clientIndex, "weapon_knife");
		FakeClientCommand(clientIndex,"use weapon_knife");
		PrintToChat(clientIndex, "[\x04GUNS\x01] %t.", "Change_Weapons");
		//PrintToChat(clientIndex, "Primary weapons is %s secondary weapons is %s y valor primary es %i",primaryWeapon[clientIndex], secondaryWeapon[clientIndex], strcmp(primaryWeapon[clientIndex], ""));
	}
}

/* stock StripAllWeapons(iClient)
{
    new iEnt;
    for (new i = 0; i <= 4; i++)
    {
        while ((iEnt = GetPlayerWeaponSlot(iClient, i)) != -1)
        {
            RemovePlayerItem(iClient, iEnt);
            AcceptEntityInput(iEnt, "Kill");
        }
    }
}   */

public OnClientPutInServer(client)
{
	ResetClientSettings(client);
}

public OnClientCookiesCached(client)
{
	GetClientCookie(client, weapons1, primaryWeapon[client], 24);
	GetClientCookie(client, weapons2, secondaryWeapon[client], 24);
	//rememberChoice[client] = GetCookie(client);
	rememberChoice[client] = false;
}

ResetClientSettings(clientIndex)
{
	weaponsGivenThisRound[clientIndex] = false;
	newWeaponsSelected[clientIndex] = false;
}

public OnClientDisconnect(clientIndex)
{
	MatarTimer(clientIndex);
	
	SetClientCookie(clientIndex, weapons1, primaryWeapon[clientIndex]);
	SetClientCookie(clientIndex, weapons2, secondaryWeapon[clientIndex]);
	
/* 	if(rememberChoice[clientIndex]) SetClientCookie(clientIndex, remember, "On");
	else SetClientCookie(clientIndex, remember, "Off"); */
}

MatarTimer(client)
{
	if (Timers[client] != INVALID_HANDLE)
    {
		KillTimer(Timers[client]);
		Timers[client] = INVALID_HANDLE;
	}
}


ListaArmas()
{
	ClearArray(array_primarias);
	ClearArray(array_secundarias);
	
	new Items[Armas];
	
	Format(Items[nombre], 64, "weapon_negev");
	Format(Items[desc], 64, "Negev");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_m249");
	Format(Items[desc], 64, "M249");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_bizon");
	Format(Items[desc], 64, "PP-Bizon");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_p90");
	Format(Items[desc], 64, "P90");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_scar20");
	Format(Items[desc], 64, "SCAR-20");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_g3sg1");
	Format(Items[desc], 64, "G3SG1");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_m4a1");
	Format(Items[desc], 64, "M4A1");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_m4a1_silencer");
	Format(Items[desc], 64, "M4A1-S");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_ak47");
	Format(Items[desc], 64, "AK-47");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_aug");
	Format(Items[desc], 64, "AUG");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_galilar");
	Format(Items[desc], 64, "Galil AR");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_awp");
	Format(Items[desc], 64, "AWP");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_sg556");
	Format(Items[desc], 64, "SG 553");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_ump45");
	Format(Items[desc], 64, "UMP-45");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_mp7");
	Format(Items[desc], 64, "MP7");
	PushArrayArray(array_primarias, Items[0]);

	Format(Items[nombre], 64, "weapon_famas");
	Format(Items[desc], 64, "FAMAS");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_mp9");
	Format(Items[desc], 64, "MP9");
	PushArrayArray(array_primarias, Items[0]);

	Format(Items[nombre], 64, "weapon_mac10");
	Format(Items[desc], 64, "MAC-10");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_ssg08");
	Format(Items[desc], 64, "SSG 08");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_nova");
	Format(Items[desc], 64, "Nova");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_xm1014");
	Format(Items[desc], 64, "XM1014");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_sawedoff");
	Format(Items[desc], 64, "Sawed-Off");
	PushArrayArray(array_primarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_mag7");
	Format(Items[desc], 64, "MAG-7");
	PushArrayArray(array_primarias, Items[0]);
	

	
	// Secondary weapons
	Format(Items[nombre], 64, "weapon_elite");
	Format(Items[desc], 64, "Dual Berettas");
	PushArrayArray(array_secundarias, Items[0]);

	Format(Items[nombre], 64, "weapon_deagle");
	Format(Items[desc], 64, "Desert Eagle");
	PushArrayArray(array_secundarias, Items[0]);

	Format(Items[nombre], 64, "weapon_tec9");
	Format(Items[desc], 64, "Tec-9");
	PushArrayArray(array_secundarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_fiveseven");
	Format(Items[desc], 64, "Five-SeveN");
	PushArrayArray(array_secundarias, Items[0]);

	Format(Items[nombre], 64, "weapon_cz75a");
	Format(Items[desc], 64, "CZ75-Auto");
	PushArrayArray(array_secundarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_glock");
	Format(Items[desc], 64, "Glock-18");
	PushArrayArray(array_secundarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_usp_silencer");
	Format(Items[desc], 64, "USP-S");
	PushArrayArray(array_secundarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_p250");
	Format(Items[desc], 64, "P250");
	PushArrayArray(array_secundarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_hkp2000");
	Format(Items[desc], 64, "P2000");
	PushArrayArray(array_secundarias, Items[0]);
	
	Format(Items[nombre], 64, "weapon_revolver");
	Format(Items[desc], 64, "Revolver");
	PushArrayArray(array_secundarias, Items[0]);
	
}

/* bool:GetCookie(client)
{
	decl String:buffer[10];
	GetClientCookie(client, remember, buffer, sizeof(buffer));
	
	return StrEqual(buffer, "On");
} */

stock RemoveNades(iClient)
{
    while(RemoveWeaponBySlot(iClient, 3)){}
    for(new i = 0; i < 6; i++)
        SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, g_iaGrenadeOffsets[i]);
}

stock bool:RemoveWeaponBySlot(iClient, iSlot)
{
    new iEntity = GetPlayerWeaponSlot(iClient, iSlot);
    if(IsValidEdict(iEntity)) {
        RemovePlayerItem(iClient, iEntity);
        AcceptEntityInput(iEntity, "Kill");
        return true;
    }
    return false;
}