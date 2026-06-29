#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define MaxClients 32
#define PLUGIN_VERSION "1.5.6"

public Plugin:myinfo =
{
	name = "L4D2 Infinite Ammo",
	author = "Machine",
	description = "Gives Infinite Ammo to players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123100"
};

new InfiniteAmmo[MaxClients+1];
new Throwing[MaxClients+1];
new Handle:IAmmo = INVALID_HANDLE;
new Handle:AllowGL = INVALID_HANDLE;
new Handle:AllowM60 = INVALID_HANDLE;
new Handle:AllowChainsaw = INVALID_HANDLE;
new Handle:AllowThrowables = INVALID_HANDLE;
new Handle:AllowUpgradeAmmo = INVALID_HANDLE;
new Handle:AllowMeds = INVALID_HANDLE;
new Handle:AllowDefibs = INVALID_HANDLE;
new Handle:AllowPills = INVALID_HANDLE;
new Handle:AllowShots = INVALID_HANDLE;
new Handle:AdminOverride = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("l4d2_iammo", Command_IAmmo, ADMFLAG_BAN, "sm_iammo <#userid|name> <0|1> - Toggles Infinite Ammo on player(s)");

	CreateConVar("l4d2_iammo_version", PLUGIN_VERSION, "L4D2 Infinite Ammo Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	IAmmo = CreateConVar("l4d2_iammo_enable", "1", "<0|1|2> Enable Infinite Ammo? 0=Off 1=On 2=Everyone", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowGL = CreateConVar("l4d2_iammo_gl", "1", "<0|1|2> Allow Infinite Ammo on Grenade Launcher? 0=Off 1=On 2=Only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowM60 = CreateConVar("l4d2_iammo_m60", "1", "<0|1|2> Allow Infinite Ammo on the M60? 0=Off 1=On 2=Only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowChainsaw = CreateConVar("l4d2_iammo_chainsaw", "1", "<0|1|2> Allow Infinite Ammo on the Chainsaw? 0=Off 1=On 2=Only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowThrowables = CreateConVar("l4d2_iammo_throwables", "1", "<0|1|2> Allow Infinite Ammo on Throwables? 0=Off 1=On 2=Only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowUpgradeAmmo = CreateConVar("l4d2_iammo_upgradeammo", "1", "<0|1> Allow Infinite Explosive and Incendiary Ammo? 0=Off 1=On", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AllowMeds = CreateConVar("l4d2_iammo_meds", "1", "<0|1|2> Allow Infinite Medkits? 0=Off 1=On 2=only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowDefibs = CreateConVar("l4d2_iammo_defibs", "1", "<0|1|2> Allow Infinite Defibs? 0=Off 1=On 2=only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowPills = CreateConVar("l4d2_iammo_pills", "1", "<0|1|2> Allow Infinite Pills? 0=Off 1=On 2=only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowShots = CreateConVar("l4d2_iammo_shots", "1", "<0|1|2> Allow Infinite Shots? 0=Off 1=On 2=only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);

	AdminOverride = CreateConVar("l4d2_admin_override", "1", "<0|1> Admins with infinite ammo always have all settings enabled? 0=Off 1=On", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_drop", Event_WeaponDrop);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookConVarChange(IAmmo, IAmmoChanged);
	HookConVarChange(AllowGL, AllowGLChanged);
	HookConVarChange(AllowM60, AllowM60Changed);
	HookConVarChange(AllowChainsaw, AllowChainsawChanged);
	HookConVarChange(AllowThrowables, AllowThrowablesChanged);
	HookConVarChange(AllowUpgradeAmmo, AllowUpgradeAmmoChanged);
	HookConVarChange(AllowMeds, AllowMedsChanged);
	HookConVarChange(AllowDefibs, AllowDefibsChanged);
	HookConVarChange(AllowPills, AllowPillsChanged);
	HookConVarChange(AllowShots, AllowShotsChanged);
	HookConVarChange(AdminOverride, AdminOverrideChanged);

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	LoadTranslations("common.phrases");	
}
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}

	hAdminMenu = topmenu;

	new TopMenuObject:menu_category = AddToTopMenu(hAdminMenu, "l4d2_ia_topmenu", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT);

	if (menu_category != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "l4d2_ia_enable_player_menu", TopMenuObject_Item, AdminMenu_IAEnablePlayer, menu_category, "l4d2_ia_enable_player_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "l4d2_ia_disable_player_menu", TopMenuObject_Item, AdminMenu_IADisablePlayer, menu_category, "l4d2_ia_disable_player_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "l4d2_ia_config_menu", TopMenuObject_Item, AdminMenu_IAConfigMenu, menu_category, "l4d2_ia_config_menu", ADMFLAG_SLAY);
	}
}
public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "Infinite Ammo Menu");
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "Infinite Ammo Menu");
	}
}
public AdminMenu_IAEnablePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Enable Infinite Ammo");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayEnablePlayerMenu(param);
	}
}
public DisplayEnablePlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EnablePlayer);
	SetMenuTitle(menu, "Enable Infinite Ammo Menu");

	SetMenuExitBackButton(menu, true);

	decl String:name[32];
	decl String:info[32];

	if (InfiniteAmmo[client] == 0)
	{
		Format(name, sizeof(name), "Enable me");
		Format(info, sizeof(info), "%i", client);
		AddMenuItem(menu, info, name);
	}
	Format(name, sizeof(name), "Enable all players");
	Format(info, sizeof(info), "477");
	AddMenuItem(menu, info, name);
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 0 && i != client)
		{
			Format(name, sizeof(name), "%N", i);
			Format(info, sizeof(info), "%i", i);
			AddMenuItem(menu, info, name);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_EnablePlayer(Handle:menu, MenuAction:action, client, param)
{
	decl String:name[32];
	decl String:info[32];

	GetMenuItem(menu, param, info, sizeof(info), _, name, sizeof(name));
	new target = StringToInt(info);

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (target > 0)
		{
			if (target == client)
			{
				InfiniteAmmo[client] = 1;
				PrintToChat(client,"\x01[SM] Infinite Ammo \x03Enabled");	
			}
			else if (target == 477)
			{
				new count = 0;
				for (new i=1; i<=MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 0 && i != client)
					{
						InfiniteAmmo[i] = 1;
						PrintToChat(client,"[SM] Infinite Ammo Enabled on %N", i);
						PrintToChat(i, "\x01[SM] You have been given \x03Infinite Ammo");
						count++;
					}
				}
				if (count == 0)
				{
					PrintToChat(client,"[SM] No players found or all players have infinite ammo");
				}
			}
			else if (target > 0)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == 2 && !IsFakeClient(target) && InfiniteAmmo[target] == 0)
				{
					InfiniteAmmo[target] = 1;
					PrintToChat(client,"[SM] Infinite Ammo Enabled on %N", target);
					PrintToChat(target, "\x01[SM] You have been given \x03Infinite Ammo");
				}
			}
			DisplayEnablePlayerMenu(client);
		}
	}
}
public AdminMenu_IADisablePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Disable Infinite Ammo");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayDisablePlayerMenu(param);
	}
}
public DisplayDisablePlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DisablePlayer);
	SetMenuTitle(menu, "Disable Infinite Ammo Menu");

	SetMenuExitBackButton(menu, true);

	decl String:name[32];
	decl String:info[32];

	if (InfiniteAmmo[client] == 1)
	{
		Format(name, sizeof(name), "Disable me");
		Format(info, sizeof(info), "%i", client);
		AddMenuItem(menu, info, name);
	}
	Format(name, sizeof(name), "Disable all players");
	Format(info, sizeof(info), "477");
	AddMenuItem(menu, info, name);
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 1 && i != client)
		{
			Format(name, sizeof(name), "%N", i);
			Format(info, sizeof(info), "%i", i);
			AddMenuItem(menu, info, name);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_DisablePlayer(Handle:menu, MenuAction:action, client, param)
{
	decl String:name[32];
	decl String:info[32];

	GetMenuItem(menu, param, info, sizeof(info), _, name, sizeof(name));
	new target = StringToInt(info);

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (target > 0)
		{
			if (target == client)
			{
				InfiniteAmmo[client] = 0;
				PrintToChat(client,"\x01[SM] Infinite Ammo \x05Disabled");	
			}
			else if (target == 477)
			{
				new count = 0;
				for (new i=1; i<=MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 1 && i != client)
					{
						InfiniteAmmo[i] = 0;
						PrintToChat(client,"[SM] Infinite Ammo Disabled on %N", i);
						PrintToChat(i,"\x01[SM] You have lost \x05Infinite Ammo");
						count++;
					}
				}
				if (count == 0)
				{
					PrintToChat(client,"[SM] No players found or all players don't have infinite ammo");
				}
			}
			else if (target > 0)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == 2 && !IsFakeClient(target) && InfiniteAmmo[target] == 1)
				{
					InfiniteAmmo[target] = 0;
					PrintToChat(client,"[SM] Infinite Ammo Disabled on %N", target);
					PrintToChat(target,"\x01[SM] You have lost \x05Infinite Ammo");
				}
			}
			DisplayDisablePlayerMenu(client);
		}
	}
}
public AdminMenu_IAConfigMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Infinite Ammo Config");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayIAConfigMenu(param);
	}
}
public DisplayIAConfigMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_IAConfigMenu);
	SetMenuTitle(menu, "Infinite Ammo Config Menu");

	SetMenuExitBackButton(menu, true);

	decl String:name[64];

	if (GetConVarInt(IAmmo) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Ammo");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Ammo");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowGL) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Grenade Launcher");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Grenade Launcher");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowM60) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite M60");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite M60");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowChainsaw) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Chainsaw");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Chainsaw");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowThrowables) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Throwables");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Throwables");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowMeds) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Medkits");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Medkits");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowDefibs) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Defibrillators");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Defibrillators");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowPills) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Pills");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Pills");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowShots) == 0)
	{
		Format(name, sizeof(name), "Enable Infinite Adrenaline");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Infinite Adrenaline");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AdminOverride) == 0)
	{
		Format(name, sizeof(name), "Enable Admin Override");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "Disable Admin Override");
		AddMenuItem(menu, name, name);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_IAConfigMenu(Handle:menu, MenuAction:action, client, param)
{
	decl String:name[64];

	GetMenuItem(menu, param, name, sizeof(name), _, name, sizeof(name));

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (StrContains(name, "Enable Infinite Ammo", false) != -1)
		{
			SetConVarInt(IAmmo, 1);
			PrintToChat(client,"[SM] Infinite Ammo Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Ammo", false) != -1)
		{
			SetConVarInt(IAmmo, 0);
			PrintToChat(client,"[SM] Infinite Ammo Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Grenade Launcher", false) != -1)
		{
			SetConVarInt(AllowGL, 1);
			PrintToChat(client,"[SM] Infinite Grenade Launcher Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Grenade Launcher", false) != -1)
		{
			SetConVarInt(AllowGL, 0);
			PrintToChat(client,"[SM] Infinite Grenade Launcher Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite M60", false) != -1)
		{
			SetConVarInt(AllowM60, 1);
			PrintToChat(client,"[SM] Infinite M60 Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite M60", false) != -1)
		{
			SetConVarInt(AllowM60, 0);
			PrintToChat(client,"[SM] Infinite M60 Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Chainsaw", false) != -1)
		{
			SetConVarInt(AllowChainsaw, 1);
			PrintToChat(client,"[SM] Infinite Chainsaw Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Chainsaw", false) != -1)
		{
			SetConVarInt(AllowChainsaw, 0);
			PrintToChat(client,"[SM] Infinite Chainsaw Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Throwables", false) != -1)
		{
			SetConVarInt(AllowThrowables, 1);
			PrintToChat(client,"[SM] Infinite Throwables Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Throwables", false) != -1)
		{
			SetConVarInt(AllowThrowables, 0);
			PrintToChat(client,"[SM] Infinite Throwables Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Medkits", false) != -1)
		{
			SetConVarInt(AllowMeds, 1);
			PrintToChat(client,"[SM] Infinite Medkits Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Medkits", false) != -1)
		{
			SetConVarInt(AllowMeds, 0);
			PrintToChat(client,"[SM] Infinite Medkits Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Defibrillators", false) != -1)
		{
			SetConVarInt(AllowDefibs, 1);
			PrintToChat(client,"[SM] Infinite Defibrillators Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Defibrillators", false) != -1)
		{
			SetConVarInt(AllowDefibs, 0);
			PrintToChat(client,"[SM] Infinite Defibrillators Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Pills", false) != -1)
		{
			SetConVarInt(AllowPills, 1);
			PrintToChat(client,"[SM] Infinite Pills Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Pills", false) != -1)
		{
			SetConVarInt(AllowPills, 0);
			PrintToChat(client,"[SM] Infinite Pills Cvar Disabled");
		}
		else if (StrContains(name, "Enable Infinite Adrenaline", false) != -1)
		{
			SetConVarInt(AllowShots, 1);
			PrintToChat(client,"[SM] Infinite Adrenaline Cvar Enabled");
		}
		else if (StrContains(name, "Disable Infinite Adrenaline", false) != -1)
		{
			SetConVarInt(AllowShots, 0);
			PrintToChat(client,"[SM] Infinite Adrenaline Cvar Disabled");
		}
		else if (StrContains(name, "Enable Admin Override", false) != -1)
		{
			SetConVarInt(AdminOverride, 1);
			PrintToChat(client,"[SM] Admin Override Cvar Enabled");
		}
		else if (StrContains(name, "Disable Admin Override", false) != -1)
		{
			SetConVarInt(AdminOverride, 0);
			PrintToChat(client,"[SM] Admin Override Cvar Disabled");
		}
		DisplayIAConfigMenu(client);
	}
}
public IAmmoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == IAmmo)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(IAmmo, oldval);
		}
		else
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					if (oldval == 2)
					{
						InfiniteAmmo[i] = 0;
						PrintToChat(i, "\x01[SM] You have lost \x05Infinite Ammo");
					}
					else if (newval == 2) 
					{
						InfiniteAmmo[i] = 1;
						PrintToChat(i, "\x01[SM] You have been given \x03Infinite Ammo");
					}
				}
			}
		}
	}
}
public AllowGLChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowGL)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowGL, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowM60Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowM60)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowM60, oldval);
		}		
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowChainsawChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowChainsaw)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowChainsaw, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowThrowablesChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowThrowables)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowThrowables, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowUpgradeAmmoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowUpgradeAmmo)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 1)
			SetConVarInt(AllowUpgradeAmmo, oldval);
	}
}
public AllowMedsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowMeds)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowMeds, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowDefibsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowDefibs)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowDefibs, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowPillsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowPills)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowPills, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowShotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowShots)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowShots, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
		}
	}
}
public AdminOverrideChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AdminOverride)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 1)
			SetConVarInt(AdminOverride, oldval);
	}
}
public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(IAmmo) == 2)
	{
		InfiniteAmmo[client] = 1;
	}
}
public Action:Command_IAmmo(client, args)
{
	new EnableVar = GetConVarInt(IAmmo);
	if (EnableVar == 0)
	{
		ReplyToCommand(client, "[SM] Infinite Ammo is currently disabled");
		return Plugin_Handled;
	}	
	if (args < 1)
	{
		if (client > 0)
		{
			if (InfiniteAmmo[client] == 0)
			{
				InfiniteAmmo[client] = 1;
				PrintToChat(client,"\x01[SM] Infinite Ammo \x03Enabled");
			}
			else
			{
				InfiniteAmmo[client] = 0;
				PrintToChat(client,"\x01[SM] Infinite Ammo \x05Disabled");
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] Must be in game to toggle Infinite Ammo on yourself");	
		}
	}		
	else if (args == 1)
	{
		ReplyToCommand(client, "[SM] Usage: l4d2_iammo <#userid|name> <0|1>");
	}
	else if (args == 2)
	{
		new String:target[32], String:arg2[32];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		new args2 = StringToInt(arg2);
			
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (new i=0; i<target_count; i++)
		{
			new String:clientname[64];
			GetClientName(target_list[i], clientname, sizeof(clientname));
			if (args2 == 0)
			{
				ReplyToCommand(client,"[SM] Infinite Ammo Disabled on %s",clientname);	
				InfiniteAmmo[target_list[i]] = 0;
				PrintToChat(target_list[i],"\x01[SM] You have lost \x05Infinite Ammo");
			}
			else if (args2 == 1)
			{
				ReplyToCommand(client,"[SM] Infinite Ammo Enabled on %s",clientname);	
				InfiniteAmmo[target_list[i]] = 1;
				PrintToChat(target_list[i],"\x01[SM] You have been given \x03Infinite Ammo");
			}			
			else
			{
				ReplyToCommand(client, "[SM] Usage: l4d2_iammo <#userid|name> <0|1>");
			}		
		}
	}
	else if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: l4d2_iammo <#userid|name> <0|1>");
	}

	return Plugin_Handled;
}
public Action:Event_PlayerDisconnect(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (InfiniteAmmo[client] == 1)
	{
		InfiniteAmmo[client] = 0;
	}
}
public Action:Event_WeaponDrop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "item", weapon, sizeof(weapon));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowThrowables) > 0 || IsAdminOverride(client))
				{
					if (Throwing[client] == 1)
					{
						if (StrEqual(weapon, "pipe_bomb"))
						{
							CheatCommand(client, "give", "pipe_bomb");
						}
						else if (StrEqual(weapon, "vomitjar"))
						{
							CheatCommand(client, "give", "vomitjar");
						}
						else if (StrEqual(weapon, "molotov"))
						{
							CheatCommand(client, "give", "molotov");
						}
						Throwing[client] = 0;
					}
				}
			}
		}
	}
}

public CheckForOnlyOn()
{
	if (GetConVarInt(AllowGL) == 2)
		return true;
	else if (GetConVarInt(AllowM60) == 2)
		return true;
	else if (GetConVarInt(AllowChainsaw) == 2)
		return true;
	else if (GetConVarInt(AllowThrowables) == 2)
		return true;
	else if (GetConVarInt(AllowMeds) == 2)
		return true;
	else if (GetConVarInt(AllowDefibs) == 2)
		return true;
	else if (GetConVarInt(AllowPills) == 2)
		return true;
	else if (GetConVarInt(AllowShots) == 2)
		return true;
	else
		return false;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				new slot = -1;
				new clipsize;
				Throwing[client] = 0;
				if (StrEqual(weapon, "pipe_bomb") || StrEqual(weapon, "vomitjar") || StrEqual(weapon, "molotov"))
				{
					if (GetConVarInt(AllowThrowables) > 0 || IsAdminOverride(client))
						Throwing[client] = 1;
				}
				else if (StrEqual(weapon, "grenade_launcher"))
				{
					if (GetConVarInt(AllowGL) > 0 || IsAdminOverride(client))
					{
						slot = 0;
						clipsize = 1;
					}
				}
				else if (StrEqual(weapon, "pumpshotgun") || StrEqual(weapon, "shotgun_chrome"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 8;
					}
				}
				else if (StrEqual(weapon, "autoshotgun") || StrEqual(weapon, "shotgun_spas"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 10;
					}
				}
				else if (StrEqual(weapon, "hunting_rifle") || StrEqual(weapon, "sniper_scout"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 15;
					}
				}
				else if (StrEqual(weapon, "sniper_awp"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 20;
					}
				}
				else if (StrEqual(weapon, "sniper_military"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 30;
					}
				}
				else if (StrEqual(weapon, "rifle_ak47"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 40;
					}
				}
				else if (StrEqual(weapon, "smg") || StrEqual(weapon, "smg_silenced") || StrEqual(weapon, "smg_mp5") || StrEqual(weapon, "rifle") || StrEqual(weapon, "rifle_sg552"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 50;
					}
				}
				else if (StrEqual(weapon, "rifle_desert"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 60;
					}
				}
				else if (StrEqual(weapon, "rifle_m60"))
				{
					if (GetConVarInt(AllowM60) > 0 || IsAdminOverride(client))
					{
						slot = 0;
						clipsize = 150;
					}
				}
				else if (StrEqual(weapon, "pistol"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 1;
						if (GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_isDualWielding") > 0)
							clipsize = 30;
						else
							clipsize = 15;
					}
				}
				else if (StrEqual(weapon, "pistol_magnum"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 1;
						clipsize = 8;
					}
				}
				else if (StrEqual(weapon, "chainsaw"))
				{
					if (GetConVarInt(AllowChainsaw) > 0 || IsAdminOverride(client))
					{
						slot = 1;
						clipsize = 30;
					}
				}
				if (slot == 0 || slot == 1)
				{
					new weaponent = GetPlayerWeaponSlot(client, slot);
					if (weaponent > 0 && IsValidEntity(weaponent))
					{
						SetEntProp(weaponent, Prop_Send, "m_iClip1", clipsize);
						if (slot == 0 && (GetConVarInt(AllowUpgradeAmmo) > 0 || IsAdminOverride(client)))
						{
							new upgradedammo = GetEntProp(weaponent, Prop_Send, "m_upgradeBitVec");
							if (upgradedammo == 1 || upgradedammo == 2 || upgradedammo == 5 || upgradedammo == 6)
								SetEntProp(weaponent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", clipsize);
						}
					}
				}
			}
		}
	}
}
public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowMeds) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerMedkit, client);
				}
			}
		}
	}
}
public Action:TimerMedkit(Handle:timer, any:client)
{
	CheatCommand(client, "give", "first_aid_kit");
}
public Action:Event_DefibrillatorUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowDefibs) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerDefib, client);
				}
			}
		}
	}
}
public Action:TimerDefib(Handle:timer, any:client)
{
	CheatCommand(client, "give", "defibrillator");
}
public Action:Event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowPills) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerPills, client);
				}
			}
		}
	}
}
public Action:TimerPills(Handle:timer, any:client)
{
	CheatCommand(client, "give", "pain_pills");
}
public Action:Event_AdrenalineUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowShots) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerShot, client);
				}
			}
		}
	}
}
public Action:TimerShot(Handle:timer, any:client)
{
	CheatCommand(client, "give", "adrenaline");
}
public IsAdminOverride(client)
{
	if (GetConVarInt(AdminOverride) > 0)
	{
		if (GetUserFlagBits(client) > 0)
		{
			return true;
		}
	}
	return false;	
}
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments );
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}