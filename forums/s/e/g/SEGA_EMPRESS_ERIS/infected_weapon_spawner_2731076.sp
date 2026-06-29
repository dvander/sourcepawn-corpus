#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define IGS_PREFIX "[IGS]"
#define IGS_VERSION "1.1"

TopMenu g_tmIGSMenu;

int g_SpawnedWeapons[MAXPLAYERS + 1];
int g_SpawnedMelees[MAXPLAYERS + 1];

ConVar convar_WeaponsLimit;
ConVar convar_MeleesLimit;

bool g_RoundStarted;

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Infected/Gun Spawner",
	author = "Fexii and Psyk0tik (Crasher_3637)",
	description = "Provides commands for spawning infected and guns.",
	version = IGS_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=81892"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "The plugin only supports Left 4 Dead 1 & 2.");

		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	convar_WeaponsLimit = CreateConVar("sm_igs_weapons_limit", "1", "How many weapons are allowed to players per round?", FCVAR_NOTIFY, true, 0.0);
	convar_MeleesLimit = CreateConVar("sm_igs_melees_limit", "1", "How many weapons are allowed to players per round?", FCVAR_NOTIFY, true, 0.0);
	
	RegConsoleCmd("sm_spw", cmdSpawnWeapons, "Spawn Primary Weapon");
	RegConsoleCmd("sm_ssw", cmdSpawnMelee, "Spawn Secondary Weapon");

	CreateConVar("igs_version", IGS_VERSION, "Version of the plugin.");

	TopMenu tmAdminMenu;

	if (LibraryExists("adminmenu") && ((tmAdminMenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(tmAdminMenu);
	}
	
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_RoundStarted)
		return;
	
	g_RoundStarted = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_SpawnedWeapons[i] = convar_WeaponsLimit.IntValue;
		g_SpawnedMelees[i] = convar_MeleesLimit.IntValue;
	}
	
	PrintToChatAll("Type !spw & !ssw & !csm in chat individually to select primary, secondary weapon & 1 - 8 survivor characters!");
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundStarted = false;
}


public void OnMapEnd()
{
	g_RoundStarted = false;
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == g_tmIGSMenu)
	{
		return;
	}

	g_tmIGSMenu = view_as<TopMenu>(topmenu);
	TopMenuObject igs_commands = g_tmIGSMenu.AddCategory("Primary/Secondary Weapon Spawner", iIGSAdminMenuHandler);
	if (igs_commands != INVALID_TOPMENUOBJECT)
	{
		g_tmIGSMenu.AddItem("sm_spawn_weapons", vSpawnWeaponsMenu, igs_commands, "sm_spawn_weapons", ADMFLAG_KICK);
		g_tmIGSMenu.AddItem("sm_spawn_melee", vSpawnMeleeMenu, igs_commands, "sm_spawn_melee", ADMFLAG_KICK);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_tmIGSMenu = null;
	}
}

public int iIGSAdminMenuHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption: Format(buffer, maxlength, "Primary/Secondary Weapon Spawner");
	}

	return 0;
}

public void vSpawnInfectedMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Spawn Infected");
		case TopMenuAction_SelectOption:
		{
			if (bIsL4D2Game())
			{
				vInfectedMenu2(param, 0);
			}
			else
			{
				vInfectedMenu(param, 0);
			}
		}
	}
}

public void vForcePanicMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Force Panic Event");
		case TopMenuAction_SelectOption: vForcePanicEvent(param);
	}
}

public void vSpawnWeaponsMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Spawn Primary Weapon");
		case TopMenuAction_SelectOption:
		{
			if (bIsL4D2Game())
			{
				vWeaponsMenu2(param, 0);
			}
			else
			{
				vWeaponsMenu(param, 0);
			}
		}
	}
}

public void vSpawnMeleeMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Spawn Secondary Weapon");
		case TopMenuAction_SelectOption:
		{
			if (bIsL4D2Game())
			{
				vWeaponsMenu3(param, 0);
			}
			else
			{
				vWeaponsMenu(param, 0);
			}
		}
	}
}

public Action cmdSpawnInfected(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "%s %t", IGS_PREFIX, "Command is in-game only");

		return Plugin_Handled;
	}

	switch (args)
	{
		case 1:
		{
			char sInfected[32];
			GetCmdArg(1, sInfected, sizeof(sInfected));
			vSpawnInfected(client, sInfected);
		}
		default:
		{
			if (bIsL4D2Game())
			{
				vInfectedMenu2(client, 0);
			}
			else
			{
				vInfectedMenu(client, 0);
			}
		}
	}

	return Plugin_Handled;
}

public Action cmdForcePanic(int client, int args)
{
	vForcePanicEvent(client);

	return Plugin_Handled;
}

public Action cmdSpawnWeapons(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "%s %t", IGS_PREFIX, "Command is in-game only");

		return Plugin_Handled;
	}
	
	if (g_SpawnedWeapons[client] <= 0)
	{
		ReplyToCommand(client, "%s You are not allowed to spawn more than %i primary weapon per round.", IGS_PREFIX, convar_WeaponsLimit.IntValue);
		return Plugin_Handled;
	}

	switch (args)
	{
		case 1:
		{
			char sWeapon[32];
			GetCmdArg(1, sWeapon, sizeof(sWeapon));
			vSpawnWeapons(client, sWeapon, false);
		}
		default:
		{
			if (bIsL4D2Game())
			{
				vWeaponsMenu2(client, 0);
			}
			else
			{
				vWeaponsMenu(client, 0);
			}
		}
	}

	return Plugin_Handled;
}

public Action cmdSpawnMelee(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "%s %t", IGS_PREFIX, "Command is in-game only");

		return Plugin_Handled;
	}
	
	if (g_SpawnedMelees[client] <= 0)
	{
		ReplyToCommand(client, "%s You are not allowed to spawn more than %i secondary weapon per round.", IGS_PREFIX, convar_MeleesLimit.IntValue);
		return Plugin_Handled;
	}

	switch (args)
	{
		case 1:
		{
			char sMelee[32];
			GetCmdArg(1, sMelee, sizeof(sMelee));
			vSpawnWeapons(client, sMelee, true);
		}
		default:
		{
			if (bIsL4D2Game())
			{
				vWeaponsMenu3(client, 0);
			}
			else
			{
				vWeaponsMenu(client, 0);
			}
		}
	}

	return Plugin_Handled;
}

static void vInfectedMenu(int client, int item)
{
	Menu mInfectedMenu = new Menu(iInfectedMenuHandler);

	mInfectedMenu.SetTitle("Spawn Infected:");

	mInfectedMenu.AddItem("common", "Common");
	mInfectedMenu.AddItem("smoker", "Smoker");
	mInfectedMenu.AddItem("boomer", "Boomer");
	mInfectedMenu.AddItem("hunter", "Hunter");
	mInfectedMenu.AddItem("witch", "Witch");
	mInfectedMenu.AddItem("tank", "Tank");

	mInfectedMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

static void vInfectedMenu2(int client, int item)
{
	Menu mInfectedMenu = new Menu(iInfectedMenuHandler);

	mInfectedMenu.SetTitle("Spawn Infected:");

	mInfectedMenu.AddItem("common", "Common");
	mInfectedMenu.AddItem("smoker", "Smoker");
	mInfectedMenu.AddItem("boomer", "Boomer");
	mInfectedMenu.AddItem("hunter", "Hunter");
	mInfectedMenu.AddItem("spitter", "Spitter");
	mInfectedMenu.AddItem("jockey", "Jockey");
	mInfectedMenu.AddItem("charger", "Charger");
	mInfectedMenu.AddItem("witch", "Witch");
	mInfectedMenu.AddItem("tank", "Tank");

	mInfectedMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

static void vWeaponsMenu(int client, int item)
{
	Menu mWeaponsMenu = new Menu(iWeaponsMenuHandler);

	mWeaponsMenu.SetTitle("Spawn Primary Weapon");

	mWeaponsMenu.AddItem("smg", "Uzi SMG");
	mWeaponsMenu.AddItem("pumpshotgun", "Pump Shotgun");
	mWeaponsMenu.AddItem("rifle", "M16 Assault Rifle");
	mWeaponsMenu.AddItem("hunting_rifle", "Hunting Rifle");
	mWeaponsMenu.AddItem("autoshotgun", "Auto-Shotgun");

	mWeaponsMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

static void vWeaponsMenu2(int client, int item)
{
	Menu mWeaponsMenu = new Menu(iWeaponsMenuHandler);

	mWeaponsMenu.SetTitle("Spawn Primary Weapon");

	mWeaponsMenu.AddItem("smg", "Uzi SMG");
	mWeaponsMenu.AddItem("smg_silenced", "Silenced SMG");
	mWeaponsMenu.AddItem("smg_mp5", "MP5 SMG");
	mWeaponsMenu.AddItem("pumpshotgun", "Pump Shotgun");
	mWeaponsMenu.AddItem("shotgun_chrome", "Chrome Shotgun");
	mWeaponsMenu.AddItem("rifle", "M16 Assault Rifle");
	mWeaponsMenu.AddItem("rifle_desert", "SCAR-L Desert Rifle");
	mWeaponsMenu.AddItem("rifle_ak47", "AK47 Assault Rifle");
	mWeaponsMenu.AddItem("rifle_sg552", "SG552 Assault Rifle");
	mWeaponsMenu.AddItem("rifle_m60", "M60 Machine Gun");
	mWeaponsMenu.AddItem("grenade_launcher", "Grenade Launcher");
	mWeaponsMenu.AddItem("hunting_rifle", "Hunting Rifle");
	mWeaponsMenu.AddItem("sniper_military", "Military Sniper Rifle");
	mWeaponsMenu.AddItem("sniper_scout", "Scout Sniper Rifle");
	mWeaponsMenu.AddItem("sniper_awp", "AWP Sniper Rifle");
	mWeaponsMenu.AddItem("autoshotgun", "Auto-Shotgun");
	mWeaponsMenu.AddItem("shotgun_spas", "SPAS Shotgun");

	mWeaponsMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

static void vWeaponsMenu3(int client, int item)
{
	Menu mMeleeMenu = new Menu(iMeleeMenuHandler);

	mMeleeMenu.SetTitle("Spawn Secondary Weapon");

	mMeleeMenu.AddItem("pistol", "Pistol");
	mMeleeMenu.AddItem("pistol_magnum", "Desert Eagle");
	mMeleeMenu.AddItem("baseball_bat", "Baseball Bat");
	mMeleeMenu.AddItem("cricket_bat", "Cricket Bat");
	mMeleeMenu.AddItem("crowbar", "Crowbar");
	mMeleeMenu.AddItem("electric_guitar", "Electric Guitar");
	mMeleeMenu.AddItem("fireaxe", "Fire Axe");
	mMeleeMenu.AddItem("frying_pan", "Frying Pan");
	mMeleeMenu.AddItem("golfclub", "Golf Club");
	mMeleeMenu.AddItem("katana", "Katana");
	mMeleeMenu.AddItem("knife", "CS:S Knife");
	mMeleeMenu.AddItem("machete", "Machete");
	mMeleeMenu.AddItem("pitchfork", "Pitchfork");
	mMeleeMenu.AddItem("shovel", "Shovel");
	mMeleeMenu.AddItem("tonfa", "Nightstick");
	mMeleeMenu.AddItem("chainsaw", "Chainsaw");

	mMeleeMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int iInfectedMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			vSpawnInfected(param1, sInfo);
			if (bIsL4D2Game())
			{
				vInfectedMenu2(param1, menu.Selection);
			}
			else
			{
				vInfectedMenu(param1, menu.Selection);
			}
		}
	}

	return 0;
}

public int iWeaponsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			vSpawnWeapons(param1, sInfo, false);
			if (bIsL4D2Game())
			{
				vWeaponsMenu2(param1, menu.Selection);
			}
			else
			{
				vWeaponsMenu(param1, menu.Selection);
			}
		}
	}

	return 0;
}

public int iMeleeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			vSpawnWeapons(param1, sInfo, true);
			if (bIsL4D2Game())
			{
				vWeaponsMenu3(param1, menu.Selection);
			}
			else
			{
				vWeaponsMenu(param1, menu.Selection);
			}
		}
	}

	return 0;
}

static void vSpawnInfected(int client, char[] name)
{
	vCheatCommand(client, bIsL4D2Game() ? "z_spawn_old" : "z_spawn", name);
	ShowActivity2(client, IGS_PREFIX, "Spawned a %s", name);
}

static void vForcePanicEvent(int client)
{
	int iDirector = CreateEntityByName("info_director");
	if (IsValidEntity(iDirector))
	{
		DispatchSpawn(iDirector);
		AcceptEntityInput(iDirector, "ForcePanicEvent");
		RemoveEntity(iDirector);
	}

	ShowActivity2(client, IGS_PREFIX, "Forced a panic event");
}

static void vSpawnWeapons(int client, char[] name, bool melee = false)
{
	if (melee && g_SpawnedMelees[client] <= 0)
		return;
	
	if (!melee && g_SpawnedWeapons[client] <= 0)
		return;
	
	vCheatCommand(client, "give", name);
	ShowActivity2(client, IGS_PREFIX, "Spawned a(n) %s", name);
	
	if (melee)
		g_SpawnedMelees[client]--;
	else
		g_SpawnedWeapons[client]--;
}

stock bool bIsL4D2Game()
{
	return GetEngineVersion() == Engine_Left4Dead2;
}

stock void vCheatCommand(int client, char[] command, char[] arguments = "")
{
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, iCmdFlags | FCVAR_CHEAT);
}