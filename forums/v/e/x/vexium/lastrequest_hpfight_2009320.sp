
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
	AddMenuItem(Menu, "M3", "SG556 Fight");
	AddMenuItem(Menu, "M4", "AUG Fight");
	AddMenuItem(Menu, "M5", "FAMAS Fight");
	AddMenuItem(Menu, "M6", "Galil Fight");
	AddMenuItem(Menu, "M7", "M249 Fight");
	AddMenuItem(Menu, "M8", "Negev Fight");
	AddMenuItem(Menu, "M9", "Bizon Fight");
	AddMenuItem(Menu, "M10", "P90 Fight");
	AddMenuItem(Menu, "M11", "Mp9 Fight");
	AddMenuItem(Menu, "M12", "Mp7 Fight");
	AddMenuItem(Menu, "M13", "Mac10 Fight");
	AddMenuItem(Menu, "M14", "UMP45 Fight");
	AddMenuItem(Menu, "M15", "Scout Fight");
	AddMenuItem(Menu, "M16", "AWP Fight");
	AddMenuItem(Menu, "M17", "SCAR20 Fight");
	AddMenuItem(Menu, "M18", "G3SG1 Fight");
	AddMenuItem(Menu, "M19", "Glock Fight");
	AddMenuItem(Menu, "M20", "Dualies Fight");
	AddMenuItem(Menu, "M21", "Deagle Fight");
	AddMenuItem(Menu, "M22", "Tec9 Fight");
	AddMenuItem(Menu, "M23", "Fiveseven Fight");
	AddMenuItem(Menu, "M24", "P250 Fight");
	AddMenuItem(Menu, "M25", "P2000 Fight");
	AddMenuItem(Menu, "M26", "Mag7 Fight");
	AddMenuItem(Menu, "M27", "Nova Fight");
	AddMenuItem(Menu, "M28", "Sawed-Off Fight");
	AddMenuItem(Menu, "M29", "XM1014 Fight");
	AddMenuItem(Menu, "M30", "Taser Fight");
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
		if(param2 == 2) // SG556
		{
			LR_AfterMenu(2);
		}
		if(param2 == 3) // AUG
		{
			LR_AfterMenu(3);
		}
		if(param2 == 4) // FAMAS
		{
			LR_AfterMenu(4);
		}
		if(param2 == 5) // Galil
		{
			LR_AfterMenu(5);
		}
		if(param2 == 6) // M249
		{
			LR_AfterMenu(6);
		}
		if(param2 == 7) // Negev
		{
			LR_AfterMenu(7);
		}
		if(param2 == 8) // Bizon
		{
			LR_AfterMenu(8);
		}
		if(param2 == 9) // P90
		{
			LR_AfterMenu(9);
		}
		if(param2 == 10) // Mp9
		{
			LR_AfterMenu(10);
		}
		if(param2 == 11) // Mp7
		{
			LR_AfterMenu(11);
		}
		if(param2 == 12) // Mac10
		{
			LR_AfterMenu(12);
		}
		if(param2 == 13) // UMP45
		{
			LR_AfterMenu(13);
		}
		if(param2 == 14) // Scout
		{
			LR_AfterMenu(14);
		}
		if(param2 == 15) // AWP
		{
			LR_AfterMenu(15);
		}
		if(param2 == 16) // SCAR20
		{
			LR_AfterMenu(16);
		}
		if(param2 == 17) // G3SG1
		{
			LR_AfterMenu(17);
		}
		if(param2 == 18) // Glock
		{
			LR_AfterMenu(18);
		}
		if(param2 == 19) // Dualies
		{
			LR_AfterMenu(19);
		}
		if(param2 == 20) // Deagle
		{
			LR_AfterMenu(20);
		}
		if(param2 == 21) // Tec9
		{
			LR_AfterMenu(21);
		}
		if(param2 == 22) // Fiveseven
		{
			LR_AfterMenu(22);
		}
		if(param2 == 23) // P250
		{
			LR_AfterMenu(23);
		}
		if(param2 == 24) // P2000
		{
			LR_AfterMenu(24);
		}
		if(param2 == 25) // Mag7
		{
			LR_AfterMenu(25);
		}
		if(param2 == 26) // Nova
		{
			LR_AfterMenu(26);
		}
		if(param2 == 27) // Sawed-Off
		{
			LR_AfterMenu(27);
		}
		if(param2 == 28) // XM1014
		{
			LR_AfterMenu(28);
		}
		if(param2 == 29) // Taser
		{
			LR_AfterMenu(29);
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
		CPrintToChatAll("[HP Fights] {default}Get ready! Do NOT reload or you will lose infinite ammo!");
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
				CPrintToChatAll("[HP Fights] {default}Winner: %N!", g_LR_Player_Prisoner);
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
				CPrintToChatAll("[HP Fights] {default}Winner: %N!", g_LR_Player_Guard);
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
	
	SetEntityHealth(g_LR_Player_Prisoner, 750);
	SetEntityHealth(g_LR_Player_Guard, 750);
	
	switch(weapon)
	{
		case 0:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m4a1");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_m4a1");
			
			CPrintToChatAll("[HP Fights] {default}M4A1 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 1:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ak47");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ak47");
			
			CPrintToChatAll("[HP Fights] {default}AK47 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 2:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_sg556");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_sg556");
			
			CPrintToChatAll("[HP Fights] {default}SG556 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 3:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_aug");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_aug");
			
			CPrintToChatAll("[HP Fights] {default}AUG Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 4:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_famas");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_famas");
			
			CPrintToChatAll("[HP Fights] {default}FAMAS Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 5:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_galilar");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_galilar");
			
			CPrintToChatAll("[HP Fights] {default}Galil Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 6:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m249");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_m249");
			
			CPrintToChatAll("[HP Fights] {default}M249 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 7:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_negev");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_negev");
			
			CPrintToChatAll("[HP Fights] {default}Negev Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 8:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_bizon");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_bizon");
			
			CPrintToChatAll("[HP Fights] {default}Bizon Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 9:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p90");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_p90");
			
			CPrintToChatAll("[HP Fights] {default}P90 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 10:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mp9");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mp9");
			
			CPrintToChatAll("[HP Fights] {default}Mp9 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 11:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mp7");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mp7");
			
			CPrintToChatAll("[HP Fights] {default}Mp7 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 12:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mac10");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mac10");
			
			CPrintToChatAll("[HP Fights] {default}Mac10 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 13:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ump45");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ump45");
			
			CPrintToChatAll("[HP Fights] {default}UMP45 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 14:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ssg08");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ssg08");
			
			CPrintToChatAll("[HP Fights] {default}Scout Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 15:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_awp");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_awp");
			
			CPrintToChatAll("[HP Fights] {default}AWP Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 16:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_scar20");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_scar20");
			
			CPrintToChatAll("[HP Fights] {default}SCAR20 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 17:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_g3sg1");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_g3sg1");
			
			CPrintToChatAll("[HP Fights] {default}G3SG1 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 18:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_glock");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_glock");
			
			CPrintToChatAll("[HP Fights] {default}Glock Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 19:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_elite");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_elite");
			
			CPrintToChatAll("[HP Fights] {default}Dualies Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 20:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_deagle");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_deagle");
			
			CPrintToChatAll("[HP Fights] {default}Deagle Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 21:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_tec9");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_tec9");
			
			CPrintToChatAll("[HP Fights] {default}Tec9 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 22:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_fiveseven");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_fiveseven");
			
			CPrintToChatAll("[HP Fights] {default}Fiveseven Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 23:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p250");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_p250");
			
			CPrintToChatAll("[HP Fights] {default}P250 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 24:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_hkp2000");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_hkp2000");
			
			CPrintToChatAll("[HP Fights] {default}P2000 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 25:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mag7");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mag7");
			
			CPrintToChatAll("[HP Fights] {default}Mag7 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 26:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_nova");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_nova");
			
			CPrintToChatAll("[HP Fights] {default}Nova Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 27:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_sawedoff");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_sawedoff");
			
			CPrintToChatAll("[HP Fights] {default}Sawed-Off Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 28:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_xm1014");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_xm1014");
			
			CPrintToChatAll("[HP Fights] {default}XM1014 Fight has started!");
			CreateTimer(0.1, Timer_Update);
			InitializeLR(g_LR_Player_Prisoner);
		}
		case 29:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_taser");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_taser");
			
			CPrintToChatAll("[HP Fights] {default}Taser Fight has started!");
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
	
	SetEntityGravity(g_LR_Player_Prisoner, 0.8);
	SetEntityGravity(g_LR_Player_Guard, 0.8);
	
	SetEntPropFloat(g_LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 1.8);
	SetEntPropFloat(g_LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 1.8);
}