#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_functions>
#include <sdktools_entinput>

enum
{
	Slot_Primary = 0,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};

enum
{
	Team_None = 0,
	Team_Spec,
	Team_T,
	Team_CT
};

bool bAllowAWP[] = {true, true};
int iWpnChoice[2][MAXPLAYERS+1],
	iMenuSize[2];
Menu hPrimaryMenu,
	hSecondaryMenu;

static const char	sPrimaryWeapons[][][] = {
		{"",					"Random"},
		{"weapon_awp",			"AWP"},
		{"weapon_ssg08",		"SSG 08"},
		{"weapon_ak47",			"AK-47"},
		{"weapon_m4a1",			"M4A4"},
		{"weapon_m4a1_silencer","M4A1-S"},
		{"weapon_sg556",		"Sig 553"},
		{"weapon_aug",			"Aug"},
		{"weapon_galilar",		"Galil AR"},
		{"weapon_famas",		"Famas"},
		{"weapon_mac10",		"Mac-10"},
		{"weapon_mp9",			"MP9"},
		{"weapon_mp7",			"MP7"},
		{"weapon_ump45",		"UMP-45"},
		{"weapon_bizon",		"Bizon"},
		{"weapon_p90",			"P90"}},
					sSecondaryWeapons[][][] = {
		{"",					"Random"},
		{"weapon_glock",		"Glock-18"},
		{"weapon_usp_silencer",	"USP-S"},
		{"weapon_hkp2000",		"P2000"},
		{"weapon_p250",			"P250"},
		{"weapon_deagle",		"Desert Eagle"},
		{"weapon_fiveseven",	"Five-SeveN"},
		{"weapon_elite",		"Dual Berettas"},
		{"weapon_tec9",			"Tec-9"},
		{"weapon_cz75a",		"CZ75-Auto"},
		{"weapon_revolver",		"R8 Revolver"}};

public Plugin myinfo =
{
	name		= "[CSGO] Gun Menu",
	author		= "Potatoz (rewritten by Grey83)",
	description	= "Gun Menu for gamemodes such as Retake, Deathmatch etc.",
	version		= "1.0.4",
	url			= "https://forums.alliedmods.net/showthread.php?t=294225"
};

public void OnPluginStart()
{
	iMenuSize[0]	= sizeof(sPrimaryWeapons) - 1;
	PrintToServer("\nPrimary weapons num: %i", iMenuSize[0]);
	iMenuSize[1]	= sizeof(sSecondaryWeapons) - 1;
	PrintToServer("Secondary weapons num: %i\n", iMenuSize[1]);

	hPrimaryMenu = new Menu(Handler_PrimaryMenu);
	hPrimaryMenu.SetTitle("Choose Primary weapon:");
	for(int i; i <= iMenuSize[0]; i++)	hPrimaryMenu.AddItem(sPrimaryWeapons[i][0], sPrimaryWeapons[i][1]);

	hSecondaryMenu = new Menu(Handler_SecondaryMenu);
	hSecondaryMenu.SetTitle("Choose Secondary weapon:");
	for(int i; i <= iMenuSize[1]; i++)	hSecondaryMenu.AddItem(sSecondaryWeapons[i][0], sSecondaryWeapons[i][1]);

	RegConsoleCmd("sm_guns", Menu_PrimaryWeapon);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn",Event_Spawn);

	ToggleBuyZones();
}

public void OnPluginEnd()
{
	ToggleBuyZones(true);
}

public Action Menu_PrimaryWeapon(int client, int args)
{
	if(client) hPrimaryMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Handler_PrimaryMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		iWpnChoice[0][client] = param;
		hSecondaryMenu.Display(client, MENU_TIME_FOREVER);
	}
	return 0;
}

public int Handler_SecondaryMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select) iWpnChoice[1][client] = param;
	return 0;
}

public void OnClientPutInServer(int client)
{
	iWpnChoice[0][client] = iWpnChoice[1][client] = 0;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bAllowAWP[0] = bAllowAWP[1] = true;
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(RequestFrame_Callback, event.GetInt("userid"));
}

public void RequestFrame_Callback(int client)
{
	if(!(client = GetClientOfUserId(client))) return;

	StripWeapons(client);

	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");

	static int wpn;
	if(!(wpn = iWpnChoice[0][client])) wpn = GetRandomInt(1, iMenuSize[0]);
	if(wpn == 1)
	{
		switch(GetClientTeam(client))
		{
			case Team_T:
			{
				if(bAllowAWP[0])
				{
					bAllowAWP[0] = false;
					GivePlayerItem(client, "weapon_awp");
				}
				else
				{
					GivePlayerItem(client, "weapon_ak47");
					PrintToChat(client, "AWP is limited to 1 player in each team per round.");
				}
			}
			case Team_CT:
			{
				if(bAllowAWP[1])
				{
					bAllowAWP[1] = false;
					GivePlayerItem(client, "weapon_awp");
				}
				else
				{
					GivePlayerItem(client, "weapon_m4a1");
					PrintToChat(client, "AWP is limited to 1 player in each team per round.");
				}
			}
		}
	}
	else GivePlayerItem(client, sPrimaryWeapons[wpn][0]);

	wpn = iWpnChoice[1][client];
	if(!wpn) wpn = GetRandomInt(1, iMenuSize[1]);
	GivePlayerItem(client, sSecondaryWeapons[wpn][0]);

	switch(GetRandomInt(0, 20))
	{
		case 1:		GivePlayerItem(client, "weapon_flashbang");
		case 2:		GivePlayerItem(client, "weapon_hegrenade");
		case 18:	GivePlayerItem(client, "weapon_smokegrenade");
	}
}

stock void StripWeapons(int client)
{
	RemoveWeaponBySlot(client, Slot_Primary);
	RemoveWeaponBySlot(client, Slot_Secondary);
	RemoveWeaponBySlot(client, Slot_Knife);
	while(RemoveWeaponBySlot(client)) {}
}

stock bool RemoveWeaponBySlot(int client, int slot = Slot_Grenade)
{
	int ent = GetPlayerWeaponSlot(client, slot);
	return ent > MaxClients && RemovePlayerItem(client, ent) && AcceptEntityInput(ent, "Kill");
}

stock void ToggleBuyZones(bool enable = false)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "func_buyzone")) != -1)
		AcceptEntityInput(entity, enable ? "Enable" : "Disable");
}