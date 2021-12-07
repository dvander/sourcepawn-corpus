#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define IGS_PREFIX "[IGS]"
#define IGS_VERSION "1.1"

TopMenu g_tmIGSMenu;

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
	RegAdminCmd("sm_spawn_si", cmdSpawnInfected, ADMFLAG_KICK, "Spawn an infected where you are aiming.");
	RegAdminCmd("sm_spawn_infected", cmdSpawnInfected, ADMFLAG_KICK, "Spawn an infected where you are aiming.");
	RegAdminCmd("sm_force_panic", cmdForcePanic, ADMFLAG_KICK, "Forces a director panic event.");
	RegAdminCmd("sm_force_panic_event", cmdForcePanic, ADMFLAG_KICK, "Forces a director panic event.");
	RegAdminCmd("sm_spawn_wep", cmdSpawnWeapons, ADMFLAG_KICK, "Spawn weapons.");
	RegAdminCmd("sm_spawn_weapons", cmdSpawnWeapons, ADMFLAG_KICK, "Spawn weapons.");
	RegAdminCmd("sm_spawn_melee", cmdSpawnMelee, ADMFLAG_KICK, "Spawn melee weapons.");

	CreateConVar("igs_version", IGS_VERSION, "Version of the plugin.");

	TopMenu tmAdminMenu;

	if (LibraryExists("adminmenu") && ((tmAdminMenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(tmAdminMenu);
	}
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == g_tmIGSMenu)
	{
		return;
	}

	g_tmIGSMenu = view_as<TopMenu>(topmenu);
	TopMenuObject igs_commands = g_tmIGSMenu.AddCategory("Infected-Guns Spawner", iIGSAdminMenuHandler);
	if (igs_commands != INVALID_TOPMENUOBJECT)
	{
		g_tmIGSMenu.AddItem("sm_spawn_infected", vSpawnInfectedMenu, igs_commands, "sm_spawn_infected", ADMFLAG_KICK);
		g_tmIGSMenu.AddItem("sm_force_panic_event", vForcePanicMenu, igs_commands, "sm_force_panic_event", ADMFLAG_KICK);
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
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption: Format(buffer, maxlength, "Infected-Guns Spawner");
	}
}

public void vSpawnInfectedMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Spawn Infected");
		case TopMenuAction_SelectOption: bIsL4D2Game() ? vInfectedMenu2(param, 0) : vInfectedMenu(param, 0);
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
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Spawn Weapons");
		case TopMenuAction_SelectOption: bIsL4D2Game() ? vWeaponsMenu2(param, 0) : vWeaponsMenu(param, 0);
	}
}

public void vSpawnMeleeMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "Spawn Melee Weapons");
		case TopMenuAction_SelectOption: bIsL4D2Game() ? vWeaponsMenu3(param, 0) : vWeaponsMenu(param, 0);
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
		default: bIsL4D2Game() ? vInfectedMenu2(client, 0) : vInfectedMenu(client, 0);
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

	switch (args)
	{
		case 1:
		{
			char sWeapon[32];
			GetCmdArg(1, sWeapon, sizeof(sWeapon));
			vSpawnWeapons(client, sWeapon);
		}
		default: bIsL4D2Game() ? vWeaponsMenu2(client, 0) : vWeaponsMenu(client, 0);
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

	switch (args)
	{
		case 1:
		{
			char sMelee[32];
			GetCmdArg(1, sMelee, sizeof(sMelee));
			vSpawnWeapons(client, sMelee);
		}
		default: bIsL4D2Game() ? vWeaponsMenu3(client, 0) : vWeaponsMenu(client, 0);
	}

	return Plugin_Handled;
}

void vInfectedMenu(int client, int item)
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

void vInfectedMenu2(int client, int item)
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

void vWeaponsMenu(int client, int item)
{
	Menu mWeaponsMenu = new Menu(iWeaponsMenuHandler);

	mWeaponsMenu.SetTitle("Spawn Weapons:");

	mWeaponsMenu.AddItem("pistol", "M1911 Pistol");
	mWeaponsMenu.AddItem("smg", "Uzi");
	mWeaponsMenu.AddItem("pumpshotgun", "Pump Shotgun");
	mWeaponsMenu.AddItem("rifle", "M16 Assault Rifle");
	mWeaponsMenu.AddItem("hunting_rifle", "Hunting Rifle");
	mWeaponsMenu.AddItem("autoshotgun", "Auto-Shotgun");
	mWeaponsMenu.AddItem("ammo", "Ammo");
	mWeaponsMenu.AddItem("molotov", "Molotov");
	mWeaponsMenu.AddItem("pipe_bomb", "Pipebomb");
	mWeaponsMenu.AddItem("first_aid_kit", "Medkit");
	mWeaponsMenu.AddItem("pain_pills", "Pain Pills");
	mWeaponsMenu.AddItem("gascan", "Gas Can");
	mWeaponsMenu.AddItem("propanetank", "Propane Tank");
	mWeaponsMenu.AddItem("oxygentank", "Oxygen Tank");

	mWeaponsMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

void vWeaponsMenu2(int client, int item)
{
	Menu mWeaponsMenu = new Menu(iWeaponsMenuHandler);

	mWeaponsMenu.SetTitle("Spawn Weapons:");

	mWeaponsMenu.AddItem("pistol", "P220 Pistol");
	mWeaponsMenu.AddItem("pistol_magnum", "Magnum Pistol");
	mWeaponsMenu.AddItem("smg", "Uzi");
	mWeaponsMenu.AddItem("smg_silenced", "Silenced Uzi");
	mWeaponsMenu.AddItem("smg_mp5", "MP5 Uzi");
	mWeaponsMenu.AddItem("pumpshotgun", "Pump Shotgun");
	mWeaponsMenu.AddItem("shotgun_chrome", "Chrome Shotgun");
	mWeaponsMenu.AddItem("rifle", "M16 Assault Rifle");
	mWeaponsMenu.AddItem("rifle_desert", "SCAR-L Desert Rifle");
	mWeaponsMenu.AddItem("rifle_ak47", "AK47 Assault Rifle");
	mWeaponsMenu.AddItem("rifle_sg552", "SG552 Assault Rifle");
	mWeaponsMenu.AddItem("rifle_m60", "M60 Assault Rifle");
	mWeaponsMenu.AddItem("hunting_rifle", "Hunting Rifle");
	mWeaponsMenu.AddItem("sniper_military", "Military Sniper Rifle");
	mWeaponsMenu.AddItem("sniper_scout", "Scout Sniper Rifle");
	mWeaponsMenu.AddItem("sniper_awp", "AWP Sniper Rifle");
	mWeaponsMenu.AddItem("autoshotgun", "Auto-Shotgun");
	mWeaponsMenu.AddItem("shotgun_spas", "SPAS Shotgun");
	mWeaponsMenu.AddItem("grenade_launcher", "Grenade Launcher");
	mWeaponsMenu.AddItem("ammo", "Ammo");
	mWeaponsMenu.AddItem("molotov", "Molotov");
	mWeaponsMenu.AddItem("pipe_bomb", "Pipebomb");
	mWeaponsMenu.AddItem("vomitjar", "Bile Bomb");
	mWeaponsMenu.AddItem("first_aid_kit", "Medkit");
	mWeaponsMenu.AddItem("defibrillator", "Defibrillator");
	mWeaponsMenu.AddItem("upgradepack_explosive", "Explosive Ammo Pack");
	mWeaponsMenu.AddItem("upgradepack_incendiary", "Incendiary Ammo Pack");
	mWeaponsMenu.AddItem("pain_pills", "Pain Pills");
	mWeaponsMenu.AddItem("adrenaline", "Adrenaline");
	mWeaponsMenu.AddItem("gascan", "Gas Can");
	mWeaponsMenu.AddItem("propanetank", "Propane Tank");
	mWeaponsMenu.AddItem("oxygentank", "Oxygen Tank");

	mWeaponsMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

void vWeaponsMenu3(int client, int item)
{
	Menu mMeleeMenu = new Menu(iMeleeMenuHandler);

	mMeleeMenu.SetTitle("Spawn Melee Weapons:");

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
	mMeleeMenu.AddItem("tonfa", "Nightstick");

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
			bIsL4D2Game() ? vInfectedMenu2(param1, menu.Selection) : vInfectedMenu(param1, menu.Selection);
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
			vSpawnWeapons(param1, sInfo);
			bIsL4D2Game() ? vWeaponsMenu2(param1, menu.Selection) : vWeaponsMenu(param1, menu.Selection);
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
			vSpawnWeapons(param1, sInfo);
			bIsL4D2Game() ? vWeaponsMenu3(param1, menu.Selection) : vWeaponsMenu(param1, menu.Selection);
		}
	}

	return 0;
}

void vSpawnInfected(int client, char[] name)
{
	vCheatCommand(client, bIsL4D2Game() ? "z_spawn_old" : "z_spawn", name);
	ShowActivity2(client, IGS_PREFIX, "Spawned a %s", name);
}

void vForcePanicEvent(int client)
{
	vCheatCommand(client, "director_force_panic_event");
	ShowActivity2(client, IGS_PREFIX, "Forced a panic event");
}

void vSpawnWeapons(int client, char[] name)
{
	vCheatCommand(client, "give", name);
	ShowActivity2(client, IGS_PREFIX, "Spawned a(n) %s", name);
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