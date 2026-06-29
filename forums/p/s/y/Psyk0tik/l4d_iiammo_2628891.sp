#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.5.7"

public Plugin myinfo =
{
	name = "[L4D] Individual Infinite Ammo",
	author = "Machine and modified by Psyk0tik (Crasher_3637)",
	description = "Gives Infinite Ammo to players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123100"
}

int InfiniteAmmo[MAXPLAYERS+1];
Handle IAmmo = INVALID_HANDLE;
Handle AllowMeds = INVALID_HANDLE;
Handle AllowPills = INVALID_HANDLE;
Handle AdminOverride = INVALID_HANDLE;
Handle hAdminMenu = INVALID_HANDLE;

public void OnPluginStart()
{
	RegAdminCmd("sm_iammo", Command_IAmmo, ADMFLAG_BAN, "sm_iammo <#userid|name> <0|1> - Toggles Infinite Ammo on player(s)");
	CreateConVar("l4d_iammo_version", PLUGIN_VERSION, "l4d Infinite Ammo Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	IAmmo = CreateConVar("l4d_iammo_enable", "1", "<0|1|2> Enable Infinite Ammo? 0=Off 1=On 2=Everyone", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowMeds = CreateConVar("l4d_iammo_meds", "1", "<0|1|2> Allow Infinite Medkits? 0=Off 1=On 2=only", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowPills = CreateConVar("l4d_iammo_pills", "1", "<0|1|2> Allow Infinite Pills? 0=Off 1=On 2=only", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AdminOverride = CreateConVar("l4d_admin_override", "1", "<0|1> Admins with infinite ammo always have all settings enabled? 0=Off 1=On", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d_iiammo");
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookConVarChange(IAmmo, IAmmoChanged);
	HookConVarChange(AllowMeds, AllowMedsChanged);
	HookConVarChange(AllowPills, AllowPillsChanged);
	HookConVarChange(AdminOverride, AdminOverrideChanged);
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	LoadTranslations("common.phrases");	
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}

	hAdminMenu = topmenu;
	TopMenuObject menu_category = AddToTopMenu(hAdminMenu, "l4d_ia_topmenu", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT);
	if (menu_category != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "l4d_ia_enable_player_menu", TopMenuObject_Item, AdminMenu_IAEnablePlayer, menu_category, "l4d_ia_enable_player_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "l4d_ia_disable_player_menu", TopMenuObject_Item, AdminMenu_IADisablePlayer, menu_category, "l4d_ia_disable_player_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "l4d_ia_config_menu", TopMenuObject_Item, AdminMenu_IAConfigMenu, menu_category, "l4d_ia_config_menu", ADMFLAG_SLAY);
	}
}

public int Handle_Category(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "Infinite Ammo Menu");
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "Infinite Ammo Menu");
	}
}

public int AdminMenu_IAEnablePlayer(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
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

public void DisplayEnablePlayerMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_EnablePlayer);
	SetMenuTitle(menu, "Enable Infinite Ammo Menu");
	SetMenuExitBackButton(menu, true);
	char name[32];
	char info[32];
	if (InfiniteAmmo[client] == 0)
	{
		Format(name, sizeof(name), "Enable me");
		Format(info, sizeof(info), "%i", client);
		AddMenuItem(menu, info, name);
	}

	Format(name, sizeof(name), "Enable all players");
	Format(info, sizeof(info), "477");
	AddMenuItem(menu, info, name);
	for (int i=1; i<=MaxClients; i++)
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

public int MenuHandler_EnablePlayer(Handle menu, MenuAction action, int client, int param)
{
	char name[32];
	char info[32];
	GetMenuItem(menu, param, info, sizeof(info), _, name, sizeof(name));
	int target = StringToInt(info);
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
				int count = 0;
				for (int i=1; i<=MaxClients; i++)
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

public int AdminMenu_IADisablePlayer(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
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

public void DisplayDisablePlayerMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_DisablePlayer);
	SetMenuTitle(menu, "Disable Infinite Ammo Menu");
	SetMenuExitBackButton(menu, true);
	char name[32];
	char info[32];
	if (InfiniteAmmo[client] == 1)
	{
		Format(name, sizeof(name), "Disable me");
		Format(info, sizeof(info), "%i", client);
		AddMenuItem(menu, info, name);
	}

	Format(name, sizeof(name), "Disable all players");
	Format(info, sizeof(info), "477");
	AddMenuItem(menu, info, name);
	for (int i=1; i<=MaxClients; i++)
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

public int MenuHandler_DisablePlayer(Handle menu, MenuAction action, int client, int param)
{
	char name[32];
	char info[32];
	GetMenuItem(menu, param, info, sizeof(info), _, name, sizeof(name));
	int target = StringToInt(info);
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
				int count = 0;
				for (int i=1; i<=MaxClients; i++)
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

public int AdminMenu_IAConfigMenu(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
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

public void DisplayIAConfigMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_IAConfigMenu);
	SetMenuTitle(menu, "Infinite Ammo Config Menu");
	SetMenuExitBackButton(menu, true);
	char name[64];
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

public int MenuHandler_IAConfigMenu(Handle menu, MenuAction action, int client, int param)
{
	char name[64];
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

public void IAmmoChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == IAmmo)
	{
		int oldval = StringToInt(oldValue);
		int newval = StringToInt(newValue);
		if (newval == oldval) return;
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(IAmmo, oldval);
		}

		else
		{
			for (int i=1; i<=MaxClients; i++)
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

public void AllowMedsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == AllowMeds)
	{
		int oldval = StringToInt(oldValue);
		int newval = StringToInt(newValue);
		if (newval == oldval) 
			return;
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowMeds, oldval);
		}

		else if (newval == 2)
		{
			SetConVarInt(AllowPills, 0);
		}
	}
}

public void AllowPillsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == AllowPills)
	{
		int oldval = StringToInt(oldValue);
		int newval = StringToInt(newValue);
		if (newval == oldval) 
			return;
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowPills, oldval);
		}

		else if (newval == 2)
		{
			SetConVarInt(AllowMeds, 0);
		}
	}
}

public void AdminOverrideChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == AdminOverride)
	{
		int oldval = StringToInt(oldValue);
		int newval = StringToInt(newValue);
		if (newval == oldval) 
			return;
		if (newval < 0 || newval > 1)
			SetConVarInt(AdminOverride, oldval);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (GetConVarInt(IAmmo) == 2)
	{
		InfiniteAmmo[client] = 1;
	}
}

public Action Command_IAmmo(int client, int args)
{
	int EnableVar = GetConVarInt(IAmmo);
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
		ReplyToCommand(client, "[SM] Usage: l4d_iammo <#userid|name> <0|1>");
	}

	else if (args == 2)
	{
		char target[32];
		char arg2[32];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		int args2 = StringToInt(arg2);
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
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

		for (int i=0; i<target_count; i++)
		{
			char clientname[64];
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
				ReplyToCommand(client, "[SM] Usage: l4d_iammo <#userid|name> <0|1>");
			}		
		}
	}

	else if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: l4d_iammo <#userid|name> <0|1>");
	}

	return Plugin_Handled;
}

public Action Event_PlayerDisconnect(Handle event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (InfiniteAmmo[client] == 1)
	{
		InfiniteAmmo[client] = 0;
	}
}

public bool CheckForOnlyOn()
{
	if (GetConVarInt(AllowMeds) == 2)
		return true;
	else if (GetConVarInt(AllowPills) == 2)
		return true;
	else
		return false;
}

public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	char weapon[64];
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				int slot = -1;
				int clipsize;
				if (StrEqual(weapon, "pumpshotgun"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 16;
					}
				}

				else if (StrEqual(weapon, "autoshotgun"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 20;
					}
				}

				else if (StrEqual(weapon, "hunting_rifle"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 30;
					}
				}

				else if (StrEqual(weapon, "smg") || StrEqual(weapon, "rifle"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 100;
					}
				}

				else if (StrEqual(weapon, "pistol"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 1;
						if (GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_isDualWielding") > 0)
							clipsize = 60;
						else
							clipsize = 30;
					}
				}

				if (slot == 0 || slot == 1)
				{
					int weaponent = GetPlayerWeaponSlot(client, slot);
					if (weaponent > 0 && IsValidEntity(weaponent))
					{
						SetEntProp(weaponent, Prop_Send, "m_iClip1", clipsize+1);
					}
				}
			}
		}
	}
}

public Action Event_HealSuccess(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
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

public Action TimerMedkit(Handle timer, any client)
{
	CheatCommand(client, "give", "first_aid_kit");
}

public Action Event_PillsUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
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

public Action TimerPills(Handle timer, any client)
{
	CheatCommand(client, "give", "pain_pills");
}

public bool IsAdminOverride(int client)
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

stock void CheatCommand(int client, const char[] command, const char[] arguments)
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments );
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}