#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.2.0"

new bool:g_bEnabled;

new Handle:g_hCvarEnable;
new Handle:g_hCvarSpyKit;
new Handle:g_hCvarEngyTools;
new Handle:g_hCvarNonCombat;
new Handle:g_hTopMenu;

public Plugin:myinfo =
{
	name = "Melee Only",
	author = "bl4nk, linux_lover",
	description = "Enables gameplay using only melee weapons",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("meleeonly.phrases");

	CreateConVar("sm_meleeonly_version", PLUGIN_VERSION, "Melee Only Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarEnable = CreateConVar("sm_meleeonly_enable", "0", "Enable/Disable melee only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarSpyKit = CreateConVar("sm_meleeonly_spykit", "0", "Allow spies to use their disguise kit when melee only is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarEngyTools = CreateConVar("sm_meleeonly_engytools", "0", "Allow engineers to use their tools when melee only is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarNonCombat = CreateConVar("sm_meleeonly_noncombat", "0", "Allow non-combat related items (bonk, medigun, kritzkrieg, jarate)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.meleeonly");
	HookEvent("player_spawn", Event_PlayerSpawn);
	RegAdminCmd("sm_meleeonly", Command_MeleeOnly, ADMFLAG_ROOT, "sm_meleeonly - Toggles melee only");

	HookConVarChange(g_hCvarEnable, ConVarChangeHandler);
	HookConVarChange(g_hCvarSpyKit, ConVarChangeHandler);
	HookConVarChange(g_hCvarEngyTools, ConVarChangeHandler);
	HookConVarChange(g_hCvarNonCombat, ConVarChangeHandler);

	RegConsoleCmd("build", Command_Build);
	RegConsoleCmd("disguise", Command_Disguise);
	RegConsoleCmd("lastdisguise", Command_Disguise);
	
	HookEvent("post_inventory_application", Event_Resupply);
}

public Action:Event_Resupply(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled) return Plugin_Continue;
	
	new userid = GetEventInt(event, "userid");
	CreateTimer(0.1, Timer_SwitchWeapons, userid);
	
	return Plugin_Continue;
}

public Action:Command_Build(client, args)
{
	if (g_bEnabled && !GetConVarBool(g_hCvarEngyTools))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:Command_Disguise(client, args)
{
	if (g_bEnabled && !GetConVarBool(g_hCvarSpyKit))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public OnMapStart()
{
	g_bEnabled = false;
}

public OnConfigsExecuted()
{
	switch (GetConVarInt(g_hCvarEnable))
	{
		case 0:
		{
			if (g_bEnabled)
			{
				DisableMeleeOnly();
			}
		}
		case 1:
		{
			if (!g_bEnabled)
			{
				EnableMeleeOnly();
			}
		}
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu = topmenu;

	new TopMenuObject:server_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hTopMenu,
			"sm_meleeonly",
			TopMenuObject_Item,
			AdminMenu_MeleeOnly,
			server_commands,
			"sm_meleeonly",
			ADMFLAG_CUSTOM2);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "adminmenu") == 0)
	{
		g_hTopMenu = INVALID_HANDLE;
	}
}

public AdminMenu_MeleeOnly(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Melee Only Options", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayMeleeMenu(param);
	}
}

DisplayMeleeMenu(client)
{
		new Handle:menu = CreateMenu(MeleeMenuHandler);

		decl String:buff[128];
		switch (g_bEnabled)
		{
			case true:
			{
				Format(buff, sizeof(buff), "%T", "Disable Melee Only", client);
				AddMenuItem(menu, "0", buff);
			}
			case false:
			{
				Format(buff, sizeof(buff), "%T", "Enable Melee Only", client);
				AddMenuItem(menu, "0", buff);
			}
		}

		switch (GetConVarBool(g_hCvarSpyKit))
		{
			case true:
			{
				Format(buff, sizeof(buff), "%T", "Disable Spy Kits", client);
				AddMenuItem(menu, "1", buff);
			}
			case false:
			{
				Format(buff, sizeof(buff), "%T", "Enable Spy Kits", client);
				AddMenuItem(menu, "1", buff);
			}
		}

		switch (GetConVarBool(g_hCvarEngyTools))
		{
			case true:
			{
				Format(buff, sizeof(buff), "%T", "Disable Engy Tools", client);
				AddMenuItem(menu, "2", buff);
			}
			case false:
			{
				Format(buff, sizeof(buff), "%T", "Enable Engy Tools", client);
				AddMenuItem(menu, "2", buff);
			}
		}

		switch (GetConVarBool(g_hCvarNonCombat))
		{
			case true:
			{
				Format(buff, sizeof(buff), "%T", "Disable Non-Combat Weapons", client);
				AddMenuItem(menu, "3", buff);
			}
			case false:
			{
				Format(buff, sizeof(buff), "%T", "Enable Non-Combat Weapons", client);
				AddMenuItem(menu, "3", buff);
			}
		}

		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 0);
}

public MeleeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				ToggleMeleeOnly();
			}
			case 1:
			{
				SetConVarBool(g_hCvarSpyKit, GetConVarBool(g_hCvarSpyKit)==true?false:true);
			}
			case 2:
			{
				SetConVarBool(g_hCvarEngyTools, GetConVarBool(g_hCvarEngyTools)==true?false:true);
			}
			case 3:
			{
				SetConVarBool(g_hCvarNonCombat, GetConVarBool(g_hCvarNonCombat)==true?false:true);
			}
		}

		DisplayMeleeMenu(param1);
	}
}

public Action:Command_MeleeOnly(client, args)
{
	ToggleMeleeOnly();
	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);

		if (client)
		{
			CreateTimer(0.1, Timer_SwitchWeapons, userid);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_bEnabled && weapon > 0)
	{
		if (client && IsPlayerAlive(client))
		{
			new meleeWeapon = GetPlayerWeaponSlot(client, 2);
			if (meleeWeapon > -1 && weapon != meleeWeapon)
			{
				if (GetConVarBool(g_hCvarNonCombat))
				{
					decl String:weaponName[32];
					GetEdictClassname(weapon, weaponName, sizeof(weaponName));

					if (strcmp(weaponName, "tf_weapon_lunchbox_drink") == 0 || strcmp(weaponName, "tf_weapon_medigun") == 0 || strcmp(weaponName, "tf_weapon_lunchbox") == 0 || strcmp(weaponName, "tf_weapon_jar") == 0)
					{
						return;
					}
				}

				switch (TF2_GetPlayerClass(client))
				{
					case TFClass_Spy:
					{
						if (GetConVarBool(g_hCvarSpyKit))
						{
							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_pda_spy") == 0)
							{
								return;
							}
						}

						if (GetConVarBool(g_hCvarEngyTools))
						{
							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_builder") == 0)
							{
								return;
							}
						}
					}
					case TFClass_Engineer:
					{
						if (GetConVarBool(g_hCvarEngyTools))
						{
							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_pda_engineer_build") == 0 || strcmp(weaponName, "tf_weapon_pda_engineer_destroy") == 0 || strcmp(weaponName, "tf_weapon_builder") == 0)
							{
								return;
							}
						}
					}
				}

				weapon = meleeWeapon;
			}
		}
	}
}

public Action:Timer_SwitchWeapons(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client))
	{
		new weapon = GetPlayerWeaponSlot(client, 2);
		if (weapon > -1)
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
}

public ConVarChangeHandler(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hCvarEnable)
	{
		if (g_bEnabled && StringToInt(newValue) == 0)
		{
			DisableMeleeOnly();
		}
		else if (!g_bEnabled && StringToInt(newValue) == 1)
		{
			EnableMeleeOnly();
		}
	}
	else if (g_bEnabled && StringToInt(newValue) == 0)
	{
		if (convar == g_hCvarSpyKit)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetPlayerClass(i) == TFClass_Spy)
				{
					new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

					decl String:weaponName[32];
					GetEdictClassname(weapon, weaponName, sizeof(weaponName));

					if (strcmp(weaponName, "tf_weapon_pda_spy") == 0)
					{
						weapon = GetPlayerWeaponSlot(i, 2);
						SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", weapon);
					}

					TF2_RemovePlayerDisguise(i);
				}
			}
		}
		else if (convar == g_hCvarEngyTools)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					switch (TF2_GetPlayerClass(i))
					{
						case TFClass_Engineer:
						{
							new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_pda_engineer_build") == 0 || strcmp(weaponName, "tf_weapon_pda_engineer_destroy") == 0)
							{
								weapon = GetPlayerWeaponSlot(i, 2);
								SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", weapon);
							}

							new maxents = GetMaxEntities();
							for (new x = MaxClients+1; x <= maxents; x++)
							{
								if (IsValidEdict(x))
								{
									decl String:netclass[32];
									GetEntityNetClass(x, netclass, sizeof(netclass));

									if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
									{
										if (GetEntPropEnt(x, Prop_Send, "m_hBuilder") == i)
										{
											SetVariantInt(9999);
											AcceptEntityInput(x, "RemoveHealth");
										}
									}
								}
							}
						}
						case TFClass_Spy:
						{
							new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_builder") == 0)
							{
								weapon = GetPlayerWeaponSlot(i, 2);
								SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", weapon);
							}
						}
					}
				}
			}
		}
		else if (convar == g_hCvarNonCombat)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					switch (TF2_GetPlayerClass(i))
					{
						case TFClass_Scout:
						{
							new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_lunchbox_drink") == 0)
							{
								weapon = GetPlayerWeaponSlot(i, 2);
								SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", weapon);
							}
						}
						case TFClass_Medic:
						{
							new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_medigun") == 0)
							{
								weapon = GetPlayerWeaponSlot(i, 2);
								SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", weapon);
							}
						}
						case TFClass_Sniper:
						{
							new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

							decl String:weaponName[32];
							GetEdictClassname(weapon, weaponName, sizeof(weaponName));

							if (strcmp(weaponName, "tf_weapon_jar") == 0)
							{
								weapon = GetPlayerWeaponSlot(i, 2);
								SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", weapon);
							}
						}
					}
				}
			}
		}
	}
}

EnableMeleeOnly()
{
	g_bEnabled = true;
	PrintToChatAll("\x04[SM]\x01 %t", "Melee Only Enabled");

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (!GetConVarBool(g_hCvarSpyKit) && TF2_GetPlayerClass(i) == TFClass_Spy)
			{
				TF2_RemovePlayerDisguise(i);
			}

			if (!GetConVarBool(g_hCvarEngyTools) && TF2_GetPlayerClass(i) == TFClass_Engineer)
			{
				new maxents = GetMaxEntities();
				for (new x = MaxClients+1; x <= maxents; x++)
				{
					if (IsValidEdict(x))
					{
						decl String:netclass[32];
						GetEntityNetClass(x, netclass, sizeof(netclass));

						if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
						{
							if (GetEntPropEnt(x, Prop_Send, "m_hBuilder") == i)
							{
								SetVariantInt(9999);
								AcceptEntityInput(x, "RemoveHealth");
							}
						}
					}
				}
			}

			new userid = GetClientUserId(i);
			CreateTimer(0.1, Timer_SwitchWeapons, userid);
		}
	}
}

DisableMeleeOnly()
{
	g_bEnabled = false;
	PrintToChatAll("\x04[SM]\x01 %t", "Melee Only Disabled");
}

ToggleMeleeOnly()
{
	switch (g_bEnabled)
	{
		case true:
		{
			SetConVarInt(g_hCvarEnable, 0);
		}
		case false:
		{
			SetConVarInt(g_hCvarEnable, 1);
		}
	}
}