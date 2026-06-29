
#include <sourcemod>
#include <sdktools>
#include <menus>
#include <hosties>
#include <morecolors>
#include <lastrequest>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

new g_LREntryNum;
new g_This_LR_Type;
new g_LR_Player_Prisoner;
new g_LR_Player_Guard;

new TWep;
new CTWep;

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
	LoadTranslations("lastrequest_hpfight.phrases");
	
	// Name of the LR
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "HP Fight", LANG_SERVER);	
	
	// menu
	
	Menu = CreateMenu(MenuHandler);
	SetMenuTitle(Menu, "HP Fight");
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
		g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, g_sLR_Name, false);
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
			LR_AfterMenu(1);
		}
		if(param2 == 2) // MP5
		{
			LR_AfterMenu(2);
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

public OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, g_sLR_Name);
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
		DisplayMenu(Menu, g_LR_Player_Prisoner, MENU_TIME_FOREVER);
		CPrintToChatAll("{lightgreen}[HP Fights] {default}Get ready to fight!");
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
				CPrintToChatAll("{green}[HP Fights] {default}Winner: {lightgreen}%N!", g_LR_Player_Prisoner);
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
				CPrintToChatAll("{green}[HP Fights] {default}Winner: {lightgreen}%N!", g_LR_Player_Guard);
			}
		}
		SetEntPropFloat(g_LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntPropFloat(g_LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

public LR_AfterMenu(weapon)
{
	StripAllWeapons(g_LR_Player_Prisoner);
	StripAllWeapons(g_LR_Player_Guard);
	
	SetEntityHealth(g_LR_Player_Prisoner, 1000);
	SetEntityHealth(g_LR_Player_Guard, 1000);
	
	switch(weapon)
	{
		case 0:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m4a1");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_m4a1");
			
			CPrintToChatAll("{lightgreen}[HP Fights] {default}M4A1 Fight had started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 1:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ak47");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ak47");
			
			CPrintToChatAll("{lightgreen}[HP Fights] {default}AK47 Fight had started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 2:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mp5navy");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mp5navy");
			
			CPrintToChatAll("{lightgreen}[HP Fights] {default}M5 Fight had started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 3:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_galil");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_galil");
			
			CPrintToChatAll("{lightgreen}[HP Fights] {default}Galil Fight had started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 4:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p90");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_p90");
			
			CPrintToChatAll("{lightgreen}[HP Fights] {default}P90 Fight had started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 5:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m249");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_m249");
			
			CPrintToChatAll("{lightgreen}[HP Fights] {default}Machine Gun Fight had started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
	}
}

public Action:Timer_Update(Handle:timer)
{
	SetEntData(TWep, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
	SetEntData(CTWep, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
	
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	SetEntData(g_LR_Player_Prisoner, ammoOffset+(1*4), 0);
	SetEntData(g_LR_Player_Guard, ammoOffset+(1*4), 0);
	
	SetEntityGravity(g_LR_Player_Prisoner, 1.0);
	SetEntityGravity(g_LR_Player_Guard, 1.0);
	
	SetEntPropFloat(g_LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 2.5);
	SetEntPropFloat(g_LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 2.5);
}