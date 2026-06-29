#include <sourcemod>
#include <sdktools>

#define sNotice "\x01[\x0700FF00给予\x01]"
#define sError "\x01[\x07FF0000错误\x01]"
#define MAX_CONFIG_WEAPONS 64
#define Plugin_Version "1.2.1"

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
	name	= "给予道具",
	author	= "Marcus", //base Marcus_Brown001 newcode Grey83 translate PLTAT
	description	= "给予存活玩家道具.",
	version	= Plugin_Version,
	url		= "https://forums.alliedmods.net/showpost.php?p=2287388&postcount=95"
};

//==========================================================================================
//							-| Plugin Forwards |-
//==========================================================================================

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLoadedLate = late;
}

public OnPluginStart()
{
	CreateConVar("nmrih_weaponmenu_version", Plugin_Version, "插件版本.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPluginEnabled = CreateConVar("sm_weaponmenu_enabled", "1", "插件状态. (1 = 开 : 0 = 关)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hPluginEnabled, OnSettingsChange);
	g_hShowOnSpawn = CreateConVar("sm_weaponmenu_spawn", "1", "自动显示. (1 = 显示 : 0 = 手动命令)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hShowOnSpawn, OnSettingsChange);
	g_hWeaponAdminOverride = CreateConVar("sm_weaponmenu_only_admin", "0", "仅管理. (1 = 管理 : 0 = 所有人)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
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

//==========================================================================================
//							-| Plugin CallBacks |-
//==========================================================================================

public OnSettingsChange(Handle:hConvar, const String:sOldValue[], const String:sNewValue[])
{
	if (hConvar == g_hPluginEnabled) g_bPluginEnabled = bool:StringToInt(sNewValue);
		else
	if (hConvar == g_hShowOnSpawn) g_bShowOnSpawn = bool:StringToInt(sNewValue);
		else
	if (hConvar == g_hWeaponAdminOverride) g_bAdminOverride = bool:StringToInt(sNewValue);
}

//==========================================================================================
//							-| Plugin Events |-
//==========================================================================================

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

//==========================================================================================
//							-| Plugin Commands |-
//==========================================================================================

public Action:Command_WeaponMenu(iClient, iArgs)
{
	if (IsPlayerAlive(iClient))
	{
		if (!g_bPluginEnabled || (g_bAdminOverride && !g_bIsAdmin[iClient]))
		{
			PrintToChat2(iClient, "%s 禁用.", sError);

			return Plugin_Handled;
		}

		new Handle:hMenu = CreateMenu(Weapon_Menu_1);
		SetMenuTitle(hMenu, "给予道具");

		AddMenuItem(hMenu, "0", "手枪");
		AddMenuItem(hMenu, "1", "步枪");
		AddMenuItem(hMenu, "2", "霰弹枪");
		AddMenuItem(hMenu, "3", "冲锋枪");
		AddMenuItem(hMenu, "4", "近战");
		AddMenuItem(hMenu, "5", "工具");
		AddMenuItem(hMenu, "6", "药物");
		AddMenuItem(hMenu, "7", "爆炸物");

		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	} else
	PrintToChat2(iClient, "%s 仅存活!", sError);
	
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
					SetMenuTitle(hMenu, "手枪 菜单");

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

				case 1:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "步枪 菜单");

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

				case 2:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "霰弹枪 菜单");

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
					SetMenuTitle(hMenu, "冲锋枪 菜单");

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
					SetMenuTitle(hMenu, "近战 菜单");

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

				case 5:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "工具 菜单");

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

				case 6:
				{
					hMenu = CreateMenu(Weapon_Menu);
					SetMenuTitle(hMenu, "药物 菜单");

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
					SetMenuTitle(hMenu, "爆炸物 菜单");

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
				PrintToChat2(param1, "%s 已发到后台.", sError);
				LogError("源码号 %d 实体 %s", g_sWeaponConfigNumbers[StringToInt(sInfo)], g_sWeaponEntityNames[StringToInt(sInfo)]);

				return;
			}

			AcceptEntityInput(iWeapon, "use", param1, param1);
			PrintToChat2(param1, "%s 道具 \x04%s\x01.", sNotice, g_sWeaponDisplayNames[StringToInt(sInfo)]);
		}
	}

	if (1 <= param1 <= MaxClients) FakeClientCommand(param1, "sm_guns");
}

//==========================================================================================
//							-| Plugin Stocks |-
//==========================================================================================

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
		
		PrintToServer("给予道具 版本 %s: 加载 %d 物品", Plugin_Version, g_iWeapons);
	} else
	{
		CloseHandle(hKeyValue);
		SetFailState("给予道具 版本 %s: 无法加载: %s", Plugin_Version, sPath);
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
