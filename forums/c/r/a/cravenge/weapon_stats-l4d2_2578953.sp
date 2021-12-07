/*
 * [L4D2] Weapon Stats plugin. A SourceMod plugin for Left 4 Dead 2.
 *	===========================================================================
 *	Copyright (C) 2018-2019 John Mark "cravenge" Moreno.  All rights reserved.
 *	===========================================================================
 *	
 *	The source code in this file is originally made by me, courtesy of
 *	DeathChaos25 for the code of manipulating bots into picking and
 *	avoiding specific items in the game.
 *	
 *	I strictly prohibit the unauthorized tweaking/modification, and/or
 *	redistribution of this plugin under the same and/or different names
 *	but there are exceptions.
 *
 *	If you have any suggestions on improving the plugin's functionality,
 *	please do not hesitate to send a private message to my AlliedModders
 *	profile. For feedbacks/improvements, you can either post them in the
 *	thread or notify me through PM.
 *
 *	------------------------------- Changelog ---------------------------------
 *  Version 1.2 (February 17, 2018)
 *	X Unreleased.
 *
 *  Version 1.1 (February 12, 2018)
 *  X Unreleased.
 *
 *	Version 1.01 (February 19, 2018)
 *	X Game check fix.
 *  
 *	Version 1.0 (February 19, 2018)
 *	X Initial release.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.01"

ConVar wsWarnings;
bool bKeyValues, bTranslations, bWarnings;
char sDataFilePath[PLATFORM_MAX_PATH], sTranslationsFilePath[PLATFORM_MAX_PATH];

KeyValues kvWeaponStats;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (!StrEqual(sGameName, "left4dead2", false))
	{
		strcopy(error, err_max, "[WS] Plugin Supports L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] Weapon Stats",
	author = "cravenge",
	description = "Displays Weapons' Attributes For Players To Know.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	char sExtensionPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sExtensionPath, sizeof(sExtensionPath), "extensions/left4downtown.ext.2.l4d2.dll");
	if (!FileExists(sExtensionPath))
	{
		SetFailState("[WS] Problem Found! Error Code: WSP-EC-00");
	}
	
	BuildPath(Path_SM, sDataFilePath, sizeof(sDataFilePath), "data/weapons_stats-l4d2.txt");
	if (FileExists(sDataFilePath))
	{
		bKeyValues = true;
	}
	else
	{
		PrintToServer("[WS] Problem Found! Error Code: WSP-EC-01A");
		bKeyValues = false;
	}
	
	BuildPath(Path_SM, sTranslationsFilePath, sizeof(sTranslationsFilePath), "translations/weapons_stats.phrases.txt");
	if (!FileExists(sTranslationsFilePath))
	{
		PrintToServer("[WS] Problem Found! Error Code: WSP-EC-01B");
		bTranslations = false;
	}
	else
	{
		bTranslations = true;
	}
	
	CreateConVar("weapon_stats-l4d2_version", PLUGIN_VERSION, "Weapon Stats Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	wsWarnings = CreateConVar("ws-l4d2_warnings", "1", "Enable/Disable Plugin Warnings", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	bWarnings = wsWarnings.BoolValue;
	wsWarnings.AddChangeHook(OnWSCVarChanged);
	
	if (FileExists("./cfg/sourcemod/weapon_stats-l4d2.cfg"))
	{
		if (bWarnings)
		{
			PrintToServer("[WS] Problem Found! Error Code: WSP-EC-02");
		}
	}
	else
	{
		AutoExecConfig(true, "weapon_stats-l4d2");
	}
	
	RegConsoleCmd("sm_weapon_stats", OnAllWSCmd, "Lists All Weapons' Attributes");
	RegConsoleCmd("sm_wstats", OnAllWSCmd, "Lists All Weapons' Attributes");
	RegConsoleCmd("sm_weapons", OnAllWSCmd, "Lists All Weapons' Attributes");
}

public void OnWSCVarChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	bWarnings = wsWarnings.BoolValue;
}

public Action OnAllWSCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		if (bWarnings)
		{
			PrintToServer("[WS] Problem Found! Error Code: WSP-EC-03");
			PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-03");
		}
		return Plugin_Handled;
	}
	
	CreateWSMenu(client);
	return Plugin_Handled;
}

public void OnPluginEnd()
{
	wsWarnings.RemoveChangeHook(OnWSCVarChanged);
	delete wsWarnings;
}

public int pOWStatHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1 && IsValidClient(param1))
		{
			Menu mOtherWeapons = new Menu(mOtherWeaponsHandler, (bTranslations) ? MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem : MENU_ACTIONS_DEFAULT);
			mOtherWeapons.SetTitle("Other Weapons:");
			
			mOtherWeapons.AddItem("", "Gasoline Cans");
			mOtherWeapons.AddItem("", "Propane Tanks");
			mOtherWeapons.AddItem("", "Oxygen Tanks");
			mOtherWeapons.AddItem("", "Firework Crates");
			
			mOtherWeapons.ExitButton = true;
			mOtherWeapons.ExitBackButton = true;
			mOtherWeapons.Display(param1, MENU_TIME_FOREVER);
		}
	}
}

void CreateWSMenu(int client)
{
	Menu mAllWeapons = new Menu(mAllWeaponsHandler, (bTranslations) ? MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem : MENU_ACTIONS_DEFAULT);
	mAllWeapons.SetTitle("Weapon Stats:");
	
	mAllWeapons.AddItem("", "Primary Weapons");
	mAllWeapons.AddItem("", "Secondary Weapons");
	mAllWeapons.AddItem("", "Grenades");
	mAllWeapons.AddItem("", "Packs");
	mAllWeapons.AddItem("", "Painkillers");
	mAllWeapons.AddItem("", "Other Weapons");
	
	mAllWeapons.ExitButton = false;
	mAllWeapons.Display(client, MENU_TIME_FOREVER);
}

public int mAllWeaponsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					Menu mPrimaryWeapons = new Menu(mPrimaryWeaponsHandler, (!bTranslations) ? MENU_ACTIONS_DEFAULT : MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
					mPrimaryWeapons.SetTitle("Primary Weapons:");
					
					mPrimaryWeapons.AddItem("", "SMG");
					mPrimaryWeapons.AddItem("", "Silenced SMG");
					mPrimaryWeapons.AddItem("", "MP5 SMG");
					mPrimaryWeapons.AddItem("", "Pump Shotgun");
					mPrimaryWeapons.AddItem("", "Chrome Shotgun");
					mPrimaryWeapons.AddItem("", "Assault Rifle");
					mPrimaryWeapons.AddItem("", "Desert Rifle");
					mPrimaryWeapons.AddItem("", "AK47 Rifle");
					mPrimaryWeapons.AddItem("", "SG552 Rifle");
					mPrimaryWeapons.AddItem("", "Auto Shotgun");
					mPrimaryWeapons.AddItem("", "Spas Shotgun");
					mPrimaryWeapons.AddItem("", "Hunting Rifle");
					mPrimaryWeapons.AddItem("", "Military Sniper");
					mPrimaryWeapons.AddItem("", "Scout Sniper");
					mPrimaryWeapons.AddItem("", "AWP Sniper");
					mPrimaryWeapons.AddItem("", "M60 Rifle");
					mPrimaryWeapons.AddItem("", "Grenade Launcher");
					
					mPrimaryWeapons.ExitButton = true;
					mPrimaryWeapons.ExitBackButton = true;
					mPrimaryWeapons.Display(param1, MENU_TIME_FOREVER);
				}
				case 1:
				{
					Menu mSecondaryWeapons = new Menu(mSecondaryWeaponsHandler, (!bTranslations) ? MENU_ACTIONS_DEFAULT : MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
					mSecondaryWeapons.SetTitle("Secondary Weapons:");
					
					mSecondaryWeapons.AddItem("", "Pistol");
					mSecondaryWeapons.AddItem("", "Magnum Pistol");
					mSecondaryWeapons.AddItem("", "Baseball Bat");
					mSecondaryWeapons.AddItem("", "Cricket Bat");
					mSecondaryWeapons.AddItem("", "Crowbar");
					mSecondaryWeapons.AddItem("", "Electric Guitar");
					mSecondaryWeapons.AddItem("", "Fire Axe");
					mSecondaryWeapons.AddItem("", "Frying Pan");
					mSecondaryWeapons.AddItem("", "Golf Club");
					mSecondaryWeapons.AddItem("", "Katana");
					mSecondaryWeapons.AddItem("", "Knife");
					mSecondaryWeapons.AddItem("", "Machete");
					mSecondaryWeapons.AddItem("", "Riot Shield");
					mSecondaryWeapons.AddItem("", "Police Baton");
					
					mSecondaryWeapons.ExitButton = true;
					mSecondaryWeapons.ExitBackButton = true;
					mSecondaryWeapons.Display(param1, MENU_TIME_FOREVER);
				}
				case 2:
				{
					Menu mGrenades = new Menu(mGrenadesHandler, (!bTranslations) ? MENU_ACTIONS_DEFAULT : MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
					mGrenades.SetTitle("Grenades:");
					
					mGrenades.AddItem("", "Molotov");
					mGrenades.AddItem("", "Pipe Bomb");
					mGrenades.AddItem("", "Vomit Jar");
					
					mGrenades.ExitButton = true;
					mGrenades.ExitBackButton = true;
					mGrenades.Display(param1, MENU_TIME_FOREVER);
				}
				case 3:
				{
					Menu mPacks = new Menu(mPacksHandler, (!bTranslations) ? MENU_ACTIONS_DEFAULT : MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
					mPacks.SetTitle("Packs:");
					
					mPacks.AddItem("", "First Aid Kit");
					mPacks.AddItem("", "Defibrillator");
					mPacks.AddItem("", "Incendiary Ammo Pack");
					mPacks.AddItem("", "Explosive Ammo Pack");
					
					mPacks.ExitButton = true;
					mPacks.ExitBackButton = true;
					mPacks.Display(param1, MENU_TIME_FOREVER);
				}
				case 4:
				{
					Menu mPainkillers = new Menu(mPainkillersHandler, (!bTranslations) ? MENU_ACTIONS_DEFAULT : MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
					mPainkillers.SetTitle("Painkillers:");
					
					mPainkillers.AddItem("", "Pain Pills");
					mPainkillers.AddItem("", "Adrenaline");
					
					mPainkillers.ExitButton = true;
					mPainkillers.ExitBackButton = true;
					mPainkillers.Display(param1, MENU_TIME_FOREVER);
				}
				case 5:
				{
					Menu mOtherWeapons = new Menu(mOtherWeaponsHandler, (!bTranslations) ? MENU_ACTIONS_DEFAULT : MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
					mOtherWeapons.SetTitle("Other Weapons:");
					
					mOtherWeapons.AddItem("", "Gasoline Cans");
					mOtherWeapons.AddItem("", "Propane Tanks");
					mOtherWeapons.AddItem("", "Oxygen Tanks");
					mOtherWeapons.AddItem("", "Firework Crates");
					
					mOtherWeapons.ExitButton = true;
					mOtherWeapons.ExitBackButton = true;
					mOtherWeapons.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Display: TranslateText(menu, param2, "WS_Title", param1, 0);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_Primary_Weapons", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Secondary_Weapons", param1, 1);
				case 2: return TranslateText(menu, 0, "WS_Grenades", param1, 1);
				case 3: return TranslateText(menu, 0, "WS_Packs", param1, 1);
				case 4: return TranslateText(menu, 0, "WS_Painkillers", param1, 1);
				case 5: return TranslateText(menu, 0, "WS_Other_Weapons", param1, 1);
			}
		}
	}
	
	return 0;
}

public int mPrimaryWeaponsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: CreateWSMenu(param1);
		case MenuAction_Display: TranslateText(menu, param2, "WS_Primary_Weapons", param1, 0, true);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_SMG", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Silenced_SMG", param1, 1);
				case 2: return TranslateText(menu, 0, "WS_MP5_SMG", param1, 1);
				case 3: return TranslateText(menu, 0, "WS_Pump_Shotgun", param1, 1);
				case 4: return TranslateText(menu, 0, "WS_Chrome_Shotgun", param1, 1);
				case 5: return TranslateText(menu, 0, "WS_Assault_Rifle", param1, 1);
				case 6: return TranslateText(menu, 0, "WS_Desert_Rifle", param1, 1);
				case 7: return TranslateText(menu, 0, "WS_AK47_Rifle", param1, 1);
				case 8: return TranslateText(menu, 0, "WS_SG552_Rifle", param1, 1);
				case 9: return TranslateText(menu, 0, "WS_Auto_Shotgun", param1, 1);
				case 10: return TranslateText(menu, 0, "WS_Spas_Shotgun", param1, 1);
				case 11: return TranslateText(menu, 0, "WS_Hunting_Rifle", param1, 1);
				case 12: return TranslateText(menu, 0, "WS_Military_Sniper", param1, 1);
				case 13: return TranslateText(menu, 0, "WS_Scout_Sniper", param1, 1);
				case 14: return TranslateText(menu, 0, "WS_AWP_Sniper", param1, 1);
				case 15: return TranslateText(menu, 0, "WS_M60_Rifle", param1, 1);
				case 16: return TranslateText(menu, 0, "WS_Grenade_Launcher", param1, 1);
			}
		}
	}
	
	return 0;
}

public int mSecondaryWeaponsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: CreateWSMenu(param1);
		case MenuAction_Display: TranslateText(menu, param2, "WS_Secondary_Weapons", param1, 0, true);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_Pistol", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Magnum_Pistol", param1, 1);
				case 2: return TranslateText(menu, 0, "WS_Baseball_Bat", param1, 1);
				case 3: return TranslateText(menu, 0, "WS_Cricket_Bat", param1, 1);
				case 4: return TranslateText(menu, 0, "WS_Crowbar", param1, 1);
				case 5: return TranslateText(menu, 0, "WS_Electric_Guitar", param1, 1);
				case 6: return TranslateText(menu, 0, "WS_Fire_Axe", param1, 1);
				case 7: return TranslateText(menu, 0, "WS_Frying_Pan", param1, 1);
				case 8: return TranslateText(menu, 0, "WS_Golf_Club", param1, 1);
				case 9: return TranslateText(menu, 0, "WS_Katana", param1, 1);
				case 10: return TranslateText(menu, 0, "WS_Knife", param1, 1);
				case 11: return TranslateText(menu, 0, "WS_Machete", param1, 1);
				case 12: return TranslateText(menu, 0, "WS_Riot_Shield", param1, 1);
				case 13: return TranslateText(menu, 0, "WS_Police_Baton", param1, 1);
			}
		}
	}
	
	return 0;
}

public int mGrenadesHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: CreateWSMenu(param1);
		case MenuAction_Display: TranslateText(menu, param2, "WS_Grenades", param1, 0, true);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_Molotov", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Pipe_Bomb", param1, 1);
				case 2: return TranslateText(menu, 0, "WS_Vomit_Jar", param1, 1);
			}
		}
	}
	
	return 0;
}

public int mPacksHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: CreateWSMenu(param1);
		case MenuAction_Display: TranslateText(menu, param2, "WS_Packs", param1, 0, true);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_First_Aid_Kit", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Defibrillator", param1, 1);
				case 2: return TranslateText(menu, 0, "WS_Incendiary_Ammo_Pack", param1, 1);
				case 3: return TranslateText(menu, 0, "WS_Explosive_Ammo_Pack", param1, 1);
			}
		}
	}
	
	return 0;
}

public int mPainkillersHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: CreateWSMenu(param1);
		case MenuAction_Display: TranslateText(menu, param2, "WS_Painkillers", param1, 0, true);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_Pain_Pills", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Adrenaline", param1, 1);
			}
		}
	}
	
	return 0;
}

public int mOtherWeaponsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select: ShowOWStats(param1, param2);
		case MenuAction_Cancel: CreateWSMenu(param1);
		case MenuAction_Display: TranslateText(menu, param2, "WS_Other_Weapons", param1, 0, true);
		case MenuAction_DisplayItem:
		{
			switch (param2)
			{
				case 0: return TranslateText(menu, 0, "WS_Gasoline_Cans", param1, 1);
				case 1: return TranslateText(menu, 0, "WS_Propane_Tanks", param1, 1);
				case 2: return TranslateText(menu, 0, "WS_Oxygen_Tanks", param1, 1);
				case 3: return TranslateText(menu, 0, "WS_Firework_Crates", param1, 1);
			}
		}
	}
	
	return 0;
}

int TranslateText(Menu mHandle, int iParam, char[] sText, int client, int iType, bool bIsTitle = false, char[] sExtraText = "")
{
	if (mHandle == null || sText[0] == '\0' || !IsValidClient(client))
	{
		if (bWarnings)
		{
			PrintToServer("[WS] Problem Found! Error Code: WSP-EC-04");
			PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-04");
		}
		return 0;
	}
	
	char sMenuText[128];
	Format(sMenuText, sizeof(sMenuText), "%T", sText, client);
	if (bIsTitle)
	{
		StrCat(sMenuText, sizeof(sMenuText), ":");
	}
	
	if (sExtraText[0] != '\0')
	{
		StrCat(sMenuText, sizeof(sMenuText), sExtraText);
	}
	
	switch (iType)
	{
		case 0:
		{
			Panel pHandle = view_as<Panel>(iParam);
			pHandle.SetTitle(sMenuText);
		}
		case 1: return RedrawMenuItem(sMenuText);
	}
	
	return 0;
}

void ShowOWStats(int client, int iOWKind)
{
	if (!IsValidClient(client))
	{
		if (bWarnings)
		{
			PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05");
			PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05");
		}
		return;
	}
	
	char sPanelText[4][128], sKVText[128];
	if (bKeyValues)
	{
		if (kvWeaponStats == null)
		{
			kvWeaponStats = new KeyValues("weapons_stats");
			kvWeaponStats.ImportFromFile(sDataFilePath);
		}
		else
		{
			kvWeaponStats.Rewind();
		}
	}
	
	Panel pOWStat = new Panel();
	
	switch (iOWKind)
	{
		case 0:
		{
			if (bTranslations)
			{
				Format(sPanelText[0], 128, "%T", "WS_Title", client);
				Format(sPanelText[1], 128, "%T", "WS_Gasoline_Cans", client);
				
				StrCat(sPanelText[0], 128, " (");
				StrCat(sPanelText[0], 128, sPanelText[1]);
				StrCat(sPanelText[0], 128, ")");
				
				pOWStat.SetTitle(sPanelText[0]);
			}
			else
			{
				pOWStat.SetTitle("Weapon Stats: (Gasoline Cans)");
			}
			pOWStat.DrawText(" \n");
			
			if (bKeyValues)
			{
				if (!kvWeaponStats.JumpToKey("gasoline_cans"))
				{
					if (bWarnings)
					{
						PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05A-1");
						PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05A-1");
					}
					
					pOWStat.DrawText("Function: Burns and damages everything near it.");
					pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
					pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
				}
				else
				{
					if (bTranslations)
					{
						kvWeaponStats.GetString("function", sKVText, sizeof(sKVText), "Burns and damages everything near it.");
						
						Format(sPanelText[0], 128, "%T", "WS_Function", client);
						StrCat(sPanelText[0], 128, " ");
						
						if (!StrEqual(sKVText, "WS_GC_Function"))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05A-2");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05A-2");
							}
							
							StrCat(sPanelText[0], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[0], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[0]);
						
						kvWeaponStats.GetString("special", sKVText, sizeof(sKVText), "Survivors can carry this weapon. Useful for scavenging too.");
						
						Format(sPanelText[1], 128, "%T", "WS_Special", client);
						StrCat(sPanelText[1], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Special", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05A-3");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05A-3");
							}
							
							StrCat(sPanelText[1], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[1], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[1]);
						
						kvWeaponStats.GetString("problem", sKVText, sizeof(sKVText), "Bullets and projectiles destroy them.");
						
						Format(sPanelText[2], 128, "%T", "WS_Problem", client);
						StrCat(sPanelText[2], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Problem", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05A-4");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05A-4");
							}
							
							StrCat(sPanelText[2], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[2], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[2]);
					}
					else
					{
						pOWStat.DrawText("Function: Burns and damages everything near it.");
						pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
						pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
					}
				}
			}
			else
			{
				pOWStat.DrawText("Function: Burns and damages everything near it.");
				pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
				pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
			}
		}
		case 1:
		{
			if (bTranslations)
			{
				Format(sPanelText[0], 128, "%T", "WS_Title", client);
				Format(sPanelText[1], 128, "%T", "WS_Propane_Tanks", client);
				
				StrCat(sPanelText[0], 128, " (");
				StrCat(sPanelText[0], 128, sPanelText[1]);
				StrCat(sPanelText[0], 128, ")");
				
				pOWStat.SetTitle(sPanelText[0]);
			}
			else
			{
				pOWStat.SetTitle("Weapon Stats: (Propane Tanks)");
			}
			pOWStat.DrawText(" \n");
			
			if (bKeyValues)
			{
				if (!kvWeaponStats.JumpToKey("propane_tanks"))
				{
					if (bWarnings)
					{
						PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05B-1");
						PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05B-1");
					}
					
					pOWStat.DrawText("Function: Explodes. Hurts everything nearby.");
					pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
					pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
				}
				else
				{
					if (bTranslations)
					{
						kvWeaponStats.GetString("function", sKVText, sizeof(sKVText), "Explodes. Hurts everything nearby.");
						
						Format(sPanelText[0], 128, "%T", "WS_Function", client);
						StrCat(sPanelText[0], 128, " ");
						
						if (!StrEqual(sKVText, "WS_PT_OT_Function"))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05B-2");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05B-2");
							}
							
							StrCat(sPanelText[0], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[0], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[0]);
						
						kvWeaponStats.GetString("special", sKVText, sizeof(sKVText), "Survivors can carry this weapon. Useful for scavenging too.");
						
						Format(sPanelText[1], 128, "%T", "WS_Special", client);
						StrCat(sPanelText[1], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Special", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05B-3");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05B-3");
							}
							
							StrCat(sPanelText[1], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[1], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[1]);
						
						kvWeaponStats.GetString("problem", sKVText, sizeof(sKVText), "Bullets and projectiles destroy them.");
						
						Format(sPanelText[2], 128, "%T", "WS_Problem", client);
						StrCat(sPanelText[2], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Problem", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05B-4");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05B-4");
							}
							
							StrCat(sPanelText[2], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[2], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[2]);
					}
					else
					{
						pOWStat.DrawText("Function: Explodes. Hurts everything nearby.");
						pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
						pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
					}
				}
			}
			else
			{
				pOWStat.DrawText("Function: Explodes. Hurts everything nearby.");
				pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
				pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
			}
		}
		case 2:
		{
			if (bTranslations)
			{
				Format(sPanelText[0], 128, "%T", "WS_Title", client);
				Format(sPanelText[1], 128, "%T", "WS_Oxygen_Tanks", client);
				
				StrCat(sPanelText[0], 128, " (");
				StrCat(sPanelText[0], 128, sPanelText[1]);
				StrCat(sPanelText[0], 128, ")");
				
				pOWStat.SetTitle(sPanelText[0]);
			}
			else
			{
				pOWStat.SetTitle("Weapon Stats: (Oxygen Tanks)");
			}
			pOWStat.DrawText(" \n");
			
			if (bKeyValues)
			{
				if (!kvWeaponStats.JumpToKey("oxygen_tanks"))
				{
					if (bWarnings)
					{
						PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05C-1");
						PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05C-1");
					}
					
					pOWStat.DrawText("Function: Explodes. Hurts everything nearby.");
					pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
					pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
				}
				else
				{
					if (bTranslations)
					{
						kvWeaponStats.GetString("function", sKVText, sizeof(sKVText), "Explodes. Hurts everything nearby.");
						
						Format(sPanelText[0], 128, "%T", "WS_Function", client);
						StrCat(sPanelText[0], 128, " ");
						
						if (!StrEqual(sKVText, "WS_PT_OT_Function"))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05C-2");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05C-2");
							}
							
							StrCat(sPanelText[0], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[0], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[0]);
						
						kvWeaponStats.GetString("special", sKVText, sizeof(sKVText), "Survivors can carry this weapon. Useful for scavenging too.");
						
						Format(sPanelText[1], 128, "%T", "WS_Special", client);
						StrCat(sPanelText[1], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Special", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05C-3");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05C-3");
							}
							
							StrCat(sPanelText[1], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[1], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[1]);
						
						kvWeaponStats.GetString("problem", sKVText, sizeof(sKVText), "Bullets and projectiles destroy them.");
						
						Format(sPanelText[2], 128, "%T", "WS_Problem", client);
						StrCat(sPanelText[2], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Problem", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05C-4");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05C-4");
							}
							
							StrCat(sPanelText[2], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[2], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[2]);
					}
					else
					{
						pOWStat.DrawText("Function: Explodes. Hurts everything nearby.");
						pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
						pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
					}
				}
			}
			else
			{
				pOWStat.DrawText("Function: Explodes. Hurts everything nearby.");
				pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
				pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
			}
		}
		case 3:
		{
			if (bTranslations)
			{
				Format(sPanelText[0], 128, "%T", "WS_Title", client);
				Format(sPanelText[1], 128, "%T", "WS_Firework_Crates", client);
				
				StrCat(sPanelText[0], 128, " (");
				StrCat(sPanelText[0], 128, sPanelText[1]);
				StrCat(sPanelText[0], 128, ")");
				
				pOWStat.SetTitle(sPanelText[0]);
			}
			else
			{
				pOWStat.SetTitle("Weapon Stats: (Firework Crates)");
			}
			pOWStat.DrawText(" \n");
			
			if (bKeyValues)
			{
				if (!kvWeaponStats.JumpToKey("oxygen_tanks"))
				{
					if (bWarnings)
					{
						PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05D-1");
						PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05D-1");
					}
					
					pOWStat.DrawText("Function: Burns everything near it while producing sparks.");
					pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
					pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
				}
				else
				{
					if (bTranslations)
					{
						kvWeaponStats.GetString("function", sKVText, sizeof(sKVText), "Burns everything near it while producing sparks.");
						
						Format(sPanelText[0], 128, "%T", "WS_Function", client);
						StrCat(sPanelText[0], 128, " ");
						
						if (!StrEqual(sKVText, "WS_PT_OT_Function"))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05D-2");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05D-2");
							}
							
							StrCat(sPanelText[0], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[0], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[0]);
						
						kvWeaponStats.GetString("special", sKVText, sizeof(sKVText), "Survivors can carry this weapon. Useful for scavenging too.");
						
						Format(sPanelText[1], 128, "%T", "WS_Special", client);
						StrCat(sPanelText[1], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Special", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05D-3");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05D-3");
							}
							
							StrCat(sPanelText[1], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[1], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[1]);
						
						kvWeaponStats.GetString("problem", sKVText, sizeof(sKVText), "Bullets and projectiles destroy them.");
						
						Format(sPanelText[2], 128, "%T", "WS_Problem", client);
						StrCat(sPanelText[2], 128, " ");
						
						if (!StrEqual(sKVText, "WS_OW_Problem", false))
						{
							if (bWarnings)
							{
								PrintToServer("[WS] Problem Found! Error Code: WSP-EC-05D-4");
								PrintToChatAll("\x01[\x05WS\x01] Problem Found! Error Code: \x03WSP-EC-05D-4");
							}
							
							StrCat(sPanelText[2], 128, sKVText);
						}
						else
						{
							Format(sPanelText[3], 128, "%T", sKVText, client);
							StrCat(sPanelText[2], 128, sPanelText[3]);
						}
						pOWStat.DrawText(sPanelText[2]);
					}
					else
					{
						pOWStat.DrawText("Function: Burns everything near it while producing sparks.");
						pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
						pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
					}
				}
			}
			else
			{
				pOWStat.DrawText("Function: Burns everything near it while producing sparks.");
				pOWStat.DrawText("Special: Survivors can carry this weapon. Useful for scavenging too.");
				pOWStat.DrawText("Problem: Bullets and projectiles destroy them.");
			}
		}
	}
	
	pOWStat.DrawText(" \n");
	pOWStat.DrawItem("Back");
	
	pOWStat.Send(client, pOWStatHandler, 30);
	delete pOWStat;
	
	delete kvWeaponStats;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

