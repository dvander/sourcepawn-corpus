#include <sourcemod>
#include <sdktools>

#define sNotice "\x01[\x07FF0000Notice\x01]"
#define sError "\x01[\x07FF0000Error\x01]"
#define MAX_CONFIG_WEAPONS 64
#define Plugin_Version "1.1.0"

new g_iWeapons;
new g_iToolLimit;
new g_iRifleLimit;
new g_iMeleeLimit;
new g_iPistolLimit;
new g_iShotgunLimit;
new g_iMedicalLimit;
new g_iExplosiveLimit;
new g_iSubMachineGunLimit;

new g_iToolCount[MAXPLAYERS + 1];
new g_iMeleeCount[MAXPLAYERS + 1];
new g_iRifleCount[MAXPLAYERS + 1];
new g_iPistolCount[MAXPLAYERS + 1];
new g_iShotgunCount[MAXPLAYERS + 1];
new g_iMedicalCount[MAXPLAYERS + 1];
new g_iExplosiveCount[MAXPLAYERS + 1];
new g_iSubMachineGunCount[MAXPLAYERS + 1];

new bool:g_bAdminOverride;
new bool:g_bPluginEnabled;
new bool:g_bLoadedLate = false;
new bool:g_bIsAdmin[MAXPLAYERS + 1];

new String:g_sWeaponEntityNames[MAX_CONFIG_WEAPONS][32];
new String:g_sWeaponDisplayNames[MAX_CONFIG_WEAPONS][32];
new String:g_sWeaponConfigNumbers[MAX_CONFIG_WEAPONS][32];
new String:g_sWeaponEntityCategory[MAX_CONFIG_WEAPONS][32];

new Handle:g_hToolLimit = INVALID_HANDLE;
new Handle:g_hMeleeLimit = INVALID_HANDLE;
new Handle:g_hRifleLimit = INVALID_HANDLE;
new Handle:g_hPistolLimit = INVALID_HANDLE;
new Handle:g_hMedicalLimit = INVALID_HANDLE;
new Handle:g_hShotgunLimit = INVALID_HANDLE;
new Handle:g_hPluginEnabled = INVALID_HANDLE;
new Handle:g_hExplosiveLimit = INVALID_HANDLE;
new Handle:g_hSubMachineGunLimit = INVALID_HANDLE;
new Handle:g_hWeaponAdminOverride = INVALID_HANDLE;

public Plugin:myinfo = { name = "[NMRiH] Weapon Menu", author = "Marcus", description = "Allows players to select their own weapons to kill zombies.", version = Plugin_Version, url = "http://www.sourcemod.com"};

//==========================================================================================
//							-| Plugin Forwards |-
//==========================================================================================

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLoadedLate = late;
}

public OnPluginStart()
{
	CreateConVar("sv_nmrih_weaponmenu_version", Plugin_Version, "This is the version of the Weapon Menu the server is running.", FCVAR_NOTIFY|FCVAR_SPONLY);
	g_hPluginEnabled = CreateConVar("sv_nmrih_weaponmenu_enabled", "1", "Turns the plugin on or off. (1 = Enabled : 0 = Disabled)", FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hPluginEnabled, OnSettingsChange);

	g_hRifleLimit = CreateConVar("sv_weaponmenu_rifle_limit", "1", "Sets the maximum amount of times a rifle can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hRifleLimit, OnSettingsChange);
	g_hSubMachineGunLimit = CreateConVar("sv_weaponmenu_smg_limit", "1", "Sets the maximum amount of times a smg can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hSubMachineGunLimit, OnSettingsChange);
	g_hShotgunLimit = CreateConVar("sv_weaponmenu_shotgun_limit", "1", "Sets the maximum amount of times a shotgun can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hShotgunLimit, OnSettingsChange);
	g_hPistolLimit = CreateConVar("sv_weaponmenu_pistol_limit", "1", "Sets the maximum amount of times a pistol can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hPistolLimit, OnSettingsChange);
	g_hToolLimit = CreateConVar("sv_weaponmenu_tool_limit", "1", "Sets the maximum amount of times a tool can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hToolLimit, OnSettingsChange);
	g_hMeleeLimit = CreateConVar("sv_weaponmenu_melee_limit", "1", "Sets the maximum amount of times a melee weapon can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hMeleeLimit, OnSettingsChange);
	g_hMedicalLimit = CreateConVar("sv_weaponmenu_medical_limit", "10", "Sets the maximum amount of times medical supplies can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hMedicalLimit, OnSettingsChange);
	g_hExplosiveLimit = CreateConVar("sv_weaponmenu_explosive_limit", "1", "Sets the maximum amount of times explosives can be selected.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hExplosiveLimit, OnSettingsChange);
	g_hWeaponAdminOverride = CreateConVar("sv_weaponmenu_admin_override", "1", "Discards all weapon limitations for an Admin.", FCVAR_SPONLY, true, 0.0);
	HookConVarChange(g_hWeaponAdminOverride, OnSettingsChange);

	g_bPluginEnabled = GetConVarBool(g_hPluginEnabled);

	g_iRifleLimit = GetConVarInt(g_hRifleLimit);
	g_iSubMachineGunLimit = GetConVarInt(g_hSubMachineGunLimit);
	g_iShotgunLimit = GetConVarInt(g_hShotgunLimit);
	g_iPistolLimit = GetConVarInt(g_hPistolLimit);
	g_iToolLimit = GetConVarInt(g_hToolLimit);
	g_iMeleeLimit = GetConVarInt(g_hMeleeLimit);
	g_iMedicalLimit = GetConVarInt(g_hMedicalLimit);
	g_iExplosiveLimit = GetConVarInt(g_hExplosiveLimit);

	g_bAdminOverride = GetConVarBool(g_hWeaponAdminOverride);

	RegAdminCmd("sm_guns", Command_WeaponMenu, 0);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	Config_LoadWeapons();

	if (g_bLoadedLate)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;

			g_iRifleCount[i] = 0;
			g_iSubMachineGunCount[i] = 0;
			g_iShotgunCount[i] = 0;
			g_iPistolCount[i] = 0;
			g_iToolCount[i] = 0;
			g_iMeleeCount[i] = 0;

			g_bIsAdmin[i] = CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC);
		}
	}
}

public OnClientPostAdminCheck(iClient)
{
	if (1 <= iClient <= MaxClients)
	{
		g_iRifleCount[iClient] = 0;
		g_iSubMachineGunCount[iClient] = 0;
		g_iShotgunCount[iClient] = 0;
		g_iPistolCount[iClient] = 0;
		g_iToolCount[iClient] = 0;
		g_iMeleeCount[iClient] = 0;
		g_iMedicalCount[iClient] = 0;
		g_iExplosiveCount[iClient] = 0;

		g_bIsAdmin[iClient] = CheckCommandAccess(iClient, "sm_admin", ADMFLAG_GENERIC);
	}
}

//==========================================================================================
//							-| Plugin CallBacks |-
//==========================================================================================

public OnSettingsChange(Handle:hConvar, const String:sOldValue[], const String:sNewValue[])
{
	if (hConvar == g_hPluginEnabled) g_bPluginEnabled = bool:StringToInt(sNewValue);
		else
	if (hConvar == g_hRifleLimit) g_iRifleLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hSubMachineGunLimit) g_iSubMachineGunLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hShotgunLimit) g_iShotgunLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hPistolLimit) g_iPistolLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hToolLimit) g_iToolLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hMeleeLimit) g_iMeleeLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hMedicalLimit) g_iMedicalLimit = StringToInt(sNewValue);
		else
	if (hConvar == g_hExplosiveLimit) g_iExplosiveLimit = StringToInt(sNewValue);
}

//==========================================================================================
//							-| Plugin Events |-
//==========================================================================================

public Event_PlayerSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (1 <= iClient <= MaxClients)
	{
		g_iRifleCount[iClient] = 0;
		g_iSubMachineGunCount[iClient] = 0;
		g_iShotgunCount[iClient] = 0;
		g_iPistolCount[iClient] = 0;
		g_iToolCount[iClient] = 0;
		g_iMeleeCount[iClient] = 0;
		g_iMedicalCount[iClient] = 0;
		g_iExplosiveCount[iClient] = 0;
	}
}

//==========================================================================================
//							-| Plugin Commands |-
//==========================================================================================

public Action:Command_WeaponMenu(iClient, iArgs)
{
	if (IsPlayerAlive(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		if (!g_bPluginEnabled)
		{
			PrintToChat2(iClient, "%s This feature has been disabled.", sError);

			return Plugin_Handled;
		}

		new Handle:hMenu = CreateMenu(Weapon_Menu_1);
		SetMenuTitle(hMenu, "[NMRiH] Weapon Menu");

		AddMenuItem(hMenu, "0", "Rifles", ((g_iRifleLimit > 0) && (g_iRifleCount[iClient] < g_iRifleLimit)) && (ItemQuantity("rifle") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "1", "SubMachineGuns", ((g_iSubMachineGunLimit > 0) && (g_iSubMachineGunCount[iClient] < g_iSubMachineGunLimit)) && (ItemQuantity("smg") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "2", "Shotguns", ((g_iShotgunLimit > 0) && (g_iShotgunCount[iClient] < g_iShotgunLimit)) && (ItemQuantity("shotgun") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "3", "Pistols", ((g_iPistolLimit > 0) && (g_iPistolCount[iClient] < g_iPistolLimit)) && (ItemQuantity("pistol") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "4", "Tools", ((g_iToolLimit > 0) && (g_iToolCount[iClient] < g_iToolLimit)) && (ItemQuantity("tool") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "5", "Melee", ((g_iMeleeLimit > 0) && (g_iMeleeCount[iClient] < g_iMeleeLimit)) && (ItemQuantity("melee") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "6", "Medical Supplies", ((g_iMedicalLimit > 0) && (g_iMedicalCount[iClient] < g_iMedicalLimit)) && (ItemQuantity("medic") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		AddMenuItem(hMenu, "7", "Explosives", ((g_iExplosiveLimit > 0) && (g_iExplosiveCount[iClient] < g_iExplosiveLimit)) && (ItemQuantity("explo") > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	} else
	PrintToChat2(iClient, "%s You must be alive to use this command!", sError);
	
	return Plugin_Handled;
}

//==========================================================================================
//							-| Plugin Menu-CallBacks |-
//==========================================================================================

public Weapon_Menu_1(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End: { CloseHandle(hHandle); }

		case MenuAction_Select:
		{
			new String:sInfo[32], Handle:hMenu;
			GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));

			switch (StringToInt(sInfo))
			{
				case 0:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Rifles");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "rifle", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 1:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: SubMachineGuns");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "smg", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 2:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Shotgun");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "shotgun", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 3:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Pistols");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "pistol", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 4:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Tools");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "tool", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 5:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Melee");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "melee", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 6:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Medic");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "medic", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}

				case 7:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "Weapon Menu: Explosive");

					for (new i; i < g_iWeapons; i++)
					{
						if (StrContains(g_sWeaponEntityCategory[i], "explo", false) == -1) continue;

						decl String:sBuffer[36];
						Format(sBuffer, sizeof(sBuffer), "%s", g_sWeaponDisplayNames[i]);
						AddMenuItem(hMenu, g_sWeaponConfigNumbers[i], sBuffer);
					}

					SetMenuExitBackButton(hMenu, true);
					DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

public Weapon_Menu(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End: { CloseHandle(hHandle); }

		case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
			
			new iWeapon = GivePlayerItem(param1, g_sWeaponEntityNames[StringToInt(sInfo)]);

			if (iWeapon == -1)
			{
				PrintToChat2(param1, "%s Something went wrong.", sError);
				LogError("Invalid Entity Name Found: [#] %d [entity_name] %s", g_sWeaponConfigNumbers[StringToInt(sInfo)], g_sWeaponEntityNames[StringToInt(sInfo)]);

				return;
			}

			if (g_bAdminOverride && !g_bIsAdmin[param1]) g_iRifleCount[param1] += 1;

			AcceptEntityInput(iWeapon, "use", param1, param1);
			PrintToChat2(param1, "%s You have chosen a \x04%s\x01.", sNotice, g_sWeaponDisplayNames[StringToInt(sInfo)]);
		}
	}

	if (1 <= param1 <= MaxClients) FakeClientCommand(param1, "sm_guns");
}

//==========================================================================================
//							-| Plugin Stocks |-
//==========================================================================================

stock ItemQuantity(const String:sName[])
{
	decl iCount;
	for (new i; i < g_iWeapons; i++)
	{
		if (StrContains(g_sWeaponEntityCategory[i], sName) == -1) continue;

		iCount++
	}

	return iCount;
}

Config_LoadWeapons() // Originally, this was from TwistedPanda's BuildWars : It helped alot!!
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/weapon_menu.ini");

	new Handle:hKeyValue = CreateKeyValues("Weapons");
	if (FileToKeyValues(hKeyValue, sPath))
	{
		KvGotoFirstSubKey(hKeyValue);
		do
		{
			KvGetSectionName(hKeyValue, g_sWeaponConfigNumbers[g_iWeapons], sizeof(g_sWeaponConfigNumbers[]));

			KvGetString(hKeyValue, "display_name", g_sWeaponDisplayNames[g_iWeapons], sizeof(g_sWeaponDisplayNames[]));
			KvGetString(hKeyValue, "entity_name", g_sWeaponEntityNames[g_iWeapons], sizeof(g_sWeaponEntityNames[]));
			KvGetString(hKeyValue, "entity_category", g_sWeaponEntityCategory[g_iWeapons], sizeof(g_sWeaponEntityCategory[]));

			g_iWeapons++;
		}
		while (KvGotoNextKey(hKeyValue));
		CloseHandle(hKeyValue);
		
		PrintToServer("[NMRiH] Weapon Menu: Loaded %d weapons", g_iWeapons);
	} else
	{
		CloseHandle(hKeyValue);
		SetFailState("[NMRiH] Weapon Menu: Could not locate: %s", sPath);
	}
}

public PrintToChat2(client, const String:format[], any:...)
{
	decl String:buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	new Handle:bf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}
