
#include <sourcemod>
#include <sdktools>
#include <menus>
#include <hosties>
#include <lastrequest>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

new g_LREntryNum;
new g_This_LR_Type;
new g_LR_Player_Prisoner;
new g_LR_Player_Guard;

new String:g_sLR_Name[64];

// menu handler
new Handle:Menu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Last Request: Hp Fight",
	author = "EGood",
	description = "hp and speed fights",
	version = PLUGIN_VERSION,
	url = "http://www.GameX.co.il"
};

public OnPluginStart()
{
	// Load translations
	LoadTranslations("hpfight.phrases");
	
	// Name of the LR
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "HP Fight", LANG_SERVER);	
	
	// menu
	
	Menu = CreateMenu(MenuHandler);
	SetMenuTitle(Menu, "HP Fights");
	AddMenuItem(Menu, "M1", "M4A1 Fight");
	AddMenuItem(Menu, "M2", "AK47 Fight");
	AddMenuItem(Menu, "M3", "MP5 Fight");
	AddMenuItem(Menu, "M4", "Galil Fight");
	AddMenuItem(Menu, "M5", "P90 Fight");
	AddMenuItem(Menu, "M5", "Machine Gun Fight");
	SetMenuExitButton(Menu, true);
}

public OnConfigsExecuted()
{
	static bool:bAddedLRHPFight = false;
	if (!bAddedLRHPFight)
	{
		g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, g_sLR_Name);
		bAddedLRHPFight = true;
	}   
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 0) // M4A1
		{
			LR_AfterMenu(0);
		}
		if(param2 == 1) // Ak47
		{
			LR_AfterMenu(4);
		}
		if(param2 == 2) // MP5
		{
			LR_AfterMenu(5);
		}
		if(param2 == 3) // Galil
		{
			LR_AfterMenu(3);
		}
		if(param2 == 4) // P90
		{
			LR_AfterMenu(4);
		}
		if(param2 == 5) // M249
		{
			LR_AfterMenu(5);
		}
	}
}

// The plugin should remove any LRs it loads when it's unloaded
public OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, "HP Fight");
}

public LR_Start(Handle:LR_Array, iIndexInArray)
{
	g_This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (g_This_LR_Type == g_LREntryNum)
	{
		g_LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		g_LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
		
		new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);   
		switch (LR_Pack_Value)
		{
			case -1:
			{
				PrintToServer("no info included");
			}
		}
		DisplayMenu(Menu, g_LR_Player_Prisoner, 0);
	}
}


public LR_Stop(Type, Prisoner, Guard)
{
	if (Type == g_LREntryNum)
	{
		if (IsClientInGame(Prisoner))
		{
			if (IsPlayerAlive(Prisoner))
			{
				SetEntityGravity(Prisoner, 1.0);
				SetEntityHealth(Prisoner, 100);
				StripAllWeapons(Prisoner);
				GivePlayerItem(Prisoner, "weapon_knife");
				PrintToChatAll(CHAT_BANNER, "HF Win", Prisoner);
			}
		}
		if (IsClientInGame(Guard))
		{
			if (IsPlayerAlive(Guard))
			{
				SetEntityGravity(Guard, 1.0);
				SetEntityHealth(Guard, 100);
				StripAllWeapons(Guard);
				GivePlayerItem(Guard, "weapon_knife");
				PrintToChatAll(CHAT_BANNER, "HF Win", Guard);
			}
		}
	}
}

public LR_AfterMenu(weapon)
{
	StripAllWeapons(g_LR_Player_Prisoner);
	StripAllWeapons(g_LR_Player_Guard);
	
	SetEntData(g_LR_Player_Prisoner, FindSendPropOffs("CBasePlayer", "m_iHealth"), 1000);
	SetEntData(g_LR_Player_Guard, FindSendPropOffs("CBasePlayer", "m_iHealth"), 1000);
	
	new wep1;
	new wep2;
	
	switch(weapon)
	{
		case 0:
		{
			wep1 = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m4a1");
			wep2 = GivePlayerItem(g_LR_Player_Guard, "weapon_m4a1");
			
			PrintToChatAll(CHAT_BANNER, "LR M4A1 Start", g_LR_Player_Prisoner, g_LR_Player_Guard);
		}
		case 1:
		{
			wep1 = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ak47");
			wep2 = GivePlayerItem(g_LR_Player_Guard, "weapon_ak47");
			
			PrintToChatAll(CHAT_BANNER, "LR AK47 Start", g_LR_Player_Prisoner, g_LR_Player_Guard);
		}
		case 2:
		{
			wep1 = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mp5navy");
			wep2 = GivePlayerItem(g_LR_Player_Guard, "weapon_mp5navy");
			
			PrintToChatAll(CHAT_BANNER, "LR MP5 Start", g_LR_Player_Prisoner, g_LR_Player_Guard);
		}
		case 3:
		{
			wep1 = GivePlayerItem(g_LR_Player_Prisoner, "weapon_galil");
			wep2 = GivePlayerItem(g_LR_Player_Guard, "weapon_galil");
			
			PrintToChatAll(CHAT_BANNER, "LR Galil Start", g_LR_Player_Prisoner, g_LR_Player_Guard);
		}
		case 4:
		{
			wep1 = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p90");
			wep2 = GivePlayerItem(g_LR_Player_Guard, "weapon_p90");
			
			PrintToChatAll(CHAT_BANNER, "LR P90 Start", g_LR_Player_Prisoner, g_LR_Player_Guard);
		}
		case 5:
		{
			wep1 = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m249");
			wep2 = GivePlayerItem(g_LR_Player_Guard, "weapon_m249");
			
			PrintToChatAll(CHAT_BANNER, "LR MGUN Start", g_LR_Player_Prisoner, g_LR_Player_Guard);
		}
	}
	
	SetEntData(wep1, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
	SetEntData(wep2, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
	
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	SetEntData(g_LR_Player_Prisoner, ammoOffset+(1*4), 0);
	SetEntData(g_LR_Player_Guard, ammoOffset+(1*4), 0);
	
	SetEntityGravity(g_LR_Player_Prisoner, 1.0);
	SetEntityGravity(g_LR_Player_Guard, 1.0);
	
	SetEntPropFloat( g_LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 3.0 );
	SetEntPropFloat( g_LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 3.0 );
	
	InitializeLR(g_LR_Player_Prisoner);
}