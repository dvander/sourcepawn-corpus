#include <sourcemod>
#include <sdktools>

#define sName				"\x01[\x04NWM\x01] \x03"
#define MAX_CONFIG_WEAPONS 64
#define PLUGIN_VERSION	"1.2.2"
#define PLUGIN_NAME		"[NMRiH] Weapon Menu"

new g_iWeapons;

new bool:g_bLoadedLate = false;
new bool:g_bIsAdmin[MAXPLAYERS + 1];

new String:g_sWeaponEntityNames[MAX_CONFIG_WEAPONS][32];
new String:g_sWeaponDisplayNames[MAX_CONFIG_WEAPONS][32];
new String:g_sWeaponConfigNumbers[MAX_CONFIG_WEAPONS][32];
new String:g_sWeaponEntityCategory[MAX_CONFIG_WEAPONS][32];

new Handle:g_hPluginEnabled, bool:g_bPluginEnabled,
	Handle:g_hShowOnSpawn, bool:g_bShowOnSpawn,
	Handle:g_hWeaponAdminOverride, bool:g_bAdminOverride;

public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Marcus (moded by Grey83)",
	description	= "Allows players to select their own weapons to kill zombies.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=212705"
};

//==================================================================
//							-| Plugin Forwards |-
//==================================================================

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLoadedLate = late;
}

public OnPluginStart()
{
	CreateConVar("nmrih_weaponmenu_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPluginEnabled = CreateConVar("sm_weaponmenu_enabled", "1", "Turns the plugin on or off. (1 = Enabled : 0 = Disabled)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hPluginEnabled, OnSettingsChange);
	g_hShowOnSpawn = CreateConVar("sm_weaponmenu_spawn", "1", "Displays the menu to the player who has just spawned. (1 = Enabled : 0 = Disabled)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hShowOnSpawn, OnSettingsChange);
	g_hWeaponAdminOverride = CreateConVar("sm_weaponmenu_only_admin", "0", "Weapon menu only for an Admins. (1 = Enabled : 0 = Disabled)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hWeaponAdminOverride, OnSettingsChange);

	g_bPluginEnabled = GetConVarBool(g_hPluginEnabled);
	g_bShowOnSpawn = GetConVarBool(g_hShowOnSpawn);
	g_bAdminOverride = GetConVarBool(g_hWeaponAdminOverride);

	RegAdminCmd("sm_guns", Command_WeaponMenu, 0);

	HookEvent("player_spawn", Event_PlayerSpawn);

	Config_LoadWeapons();

	if (g_bLoadedLate)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;

			g_bIsAdmin[i] = CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC);
		}
	}
	AutoExecConfig(true, "nmrih_weapon_menu");
}

public OnClientPostAdminCheck(iClient)
{
	if (1 <= iClient <= MaxClients)
		g_bIsAdmin[iClient] = CheckCommandAccess(iClient, "sm_admin", ADMFLAG_GENERIC);
}

//==================================================================
//							-| Plugin CallBacks |-
//==================================================================

public OnSettingsChange(Handle:hConvar, const String:sOldValue[], const String:sNewValue[])
{
	if (hConvar == g_hPluginEnabled) g_bPluginEnabled = bool:StringToInt(sNewValue);
		else
	if (hConvar == g_hShowOnSpawn) g_bShowOnSpawn = bool:StringToInt(sNewValue);
		else
	if (hConvar == g_hWeaponAdminOverride) g_bAdminOverride = bool:StringToInt(sNewValue);
}

//==================================================================
//							-| Plugin Events |-
//==================================================================

public Action:Event_PlayerSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bPluginEnabled && g_bShowOnSpawn)
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if ((g_bAdminOverride && g_bIsAdmin[iClient]) || !g_bAdminOverride)
			{
				Command_WeaponMenu(iClient, 0);
				return Plugin_Continue;
			}
	}
	return Plugin_Continue;
}

//==================================================================
//							-| Plugin Commands |-
//==================================================================

public Action:Command_WeaponMenu(iClient, iArgs)
{
	if (!iClient) return Plugin_Handled;

	if (!g_bPluginEnabled || (g_bAdminOverride && !g_bIsAdmin[iClient]))
	{
		PrintToChat2(iClient, "%s This feature has been disabled.", sName);
		return Plugin_Handled;
	}

	if (IsPlayerAlive(iClient))
	{

		new Handle:hMenu = CreateMenu(Weapon_Menu_1);
		SetMenuTitle(hMenu, "[NMRiH] Weapon Menu (reordered)");

		AddMenuItem(hMenu, "0", "Medical Supplies");
		AddMenuItem(hMenu, "1", "Tools");
		AddMenuItem(hMenu, "2", "Pistols");
		AddMenuItem(hMenu, "3", "SubMachineGuns");
		AddMenuItem(hMenu, "4", "Rifles");
		AddMenuItem(hMenu, "5", "Shotguns");
		AddMenuItem(hMenu, "6", "Melee");
		AddMenuItem(hMenu, "7", "Explosives");

		SetMenuPagination(hMenu, MENU_NO_PAGINATION);
		SetMenuExitButton(hMenu, true);
		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	}
	else PrintToChat2(iClient, "%s You must be alive to use this command!", sName);

	return Plugin_Handled;
}

//==================================================================
//							-| Plugin Menu-CallBacks |-
//==================================================================

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
					SetMenuTitle(hMenu, "NWM: Medic");

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

				case 1:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: Tools");

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

				case 2:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: Pistols");

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

				case 3:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: SubMachineGuns");

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

				case 4:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: Rifles");

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

				case 5:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: Shotgun");

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

				case 6:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: Melee");

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

				case 7:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "NWM: Explosive");

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
				PrintToChat2(param1, "%sYou already have \x04%s\x01.", sName, g_sWeaponDisplayNames[StringToInt(sInfo)]);
				if (1 <= param1 <= MaxClients && IsClientInGame(param1)) FakeClientCommand(param1, "sm_guns");
				return;
			}

			AcceptEntityInput(iWeapon, "use", param1, param1);
			PrintToChat2(param1, "%sYou have chosen a \x04%s\x01.", sName, g_sWeaponDisplayNames[StringToInt(sInfo)]);
			if (1 <= param1 <= MaxClients && IsClientInGame(param1)) FakeClientCommand(param1, "sm_guns");
		}
	}
}

//==================================================================
//							-| Plugin Stocks |-
//==================================================================

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
		
		PrintToServer("[NMRiH] Weapon Menu v.%s: Loaded %d weapons", PLUGIN_VERSION, g_iWeapons);
	} else
	{
		CloseHandle(hKeyValue);
		SetFailState("[NMRiH] Weapon Menu v.%s: Could not locate: %s", PLUGIN_VERSION, sPath);
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
