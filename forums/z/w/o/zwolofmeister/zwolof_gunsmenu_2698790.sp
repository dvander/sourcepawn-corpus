#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

//would rather use an enum, bbut nah m8
#define Rifle 		0
#define Grenade 	1
#define Pistol 		2

int g_iChoice[MAXPLAYERS+1][3];
int g_iMenuType[MAXPLAYERS+1] = Pistol;

#define PREFIX		" \x01\x0B\x01[\x04Guns\x01]"

// Freely edit this array to add/remove pistols
char PISTOLS[][][] = {
	{"weapon_hkp2000",			"P2000"},
	{"weapon_usp_silencer",		"USP-S"},
	{"weapon_glock",			"Glock-18"},
	{"weapon_cz75a",			"CZ-75 Auto"},
	{"weapon_tec9",				"Tec-9"},
	{"weapon_deagle",			"Desert Eagle"}
};

// Freely edit this array to add/remove guns
char GUNS[][][] = {
	{"weapon_famas",			"Famas"},
	{"weapon_m4a1",				"M4A4"},
	{"weapon_ak47",				"AK-47"},
	{"weapon_m4a1_silencer",	"M4A1-S"},
	{"weapon_aug",				"AUG"},
	{"weapon_ssg08",			"SSG08"},
	{"weapon_awp",				"AWP"}
};

// Freely edit this array to add/remove nades
char GRENADES[][][] = {
	{"weapon_hegrenade",		"Grenade"},
	{"weapon_flashbang",		"Flashbang"},
	{"weapon_smokegrenade",		"Smokegrenade"}
};

public Plugin myinfo = 
{
	name = "[SM] Custom Rifle and Pistol Menu",
	author = "zwolof",
	description = "Custom Guns Menu",
	version = "1.0.0",
	url = "/id/zwolof"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	
	RegConsoleCmd("sm_guns", Command_Guns);
}

public Action Command_Guns(int client, int iArgs)
{
	if(iArgs > 0)
	{
		ReplyToCommand(client, "[SM] Usage /guns");
		return Plugin_Handled;
	}
	CreateGunsMenu(client, 0);
	
	return Plugin_Handled;
}

public void Event_RoundStart(Event hEvent, const char[] szName, bool dontBroadcast)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			GiveWeapon(i, g_iChoice[i][Pistol], Pistol);
			GiveWeapon(i, g_iChoice[i][Rifle], Rifle);
			GiveWeapon(i, g_iChoice[i][Grenade], Grenade);
		}
	}
} 

public Action CreateGunsMenu(int client, int iArgs)
{
	int iType = g_iMenuType[client];
	
	Menu hMenu = new Menu(GunsMenuCallback);
	char Title[200];
	Format(Title, sizeof(Title), "Choose your %s:\n", iType == Pistol ? "Secondary weapon" : iType==Rifle ? "Primary weapon" : "Extra Grenade");
	hMenu.SetTitle(Title);
	
	//could optimize this but I cba
	if(iType == Pistol)
	{
		for(int i = 0; i < sizeof(PISTOLS); i++)
		hMenu.AddItem("xx", PISTOLS[i][1]);
	}
	else if(iType == Rifle)
	{
		for(int i = 0; i < sizeof(GUNS); i++)
		hMenu.AddItem("xx", GUNS[i][1]);
	}
	else
	{
		for(int i = 0; i < sizeof(GRENADES); i++)
		hMenu.AddItem("xx", GRENADES[i][1]);
	}
	
	hMenu.ExitButton 		= true;
	hMenu.Display(client, 	MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int GunsMenuCallback(Menu hMenu, MenuAction mAction, int client, int iOption)
{
	int iType = g_iMenuType[client];
	
	switch(mAction)
	{
		case MenuAction_Select:
		{
			g_iChoice[client][iType] = iOption;
			
			GiveWeapon(client, iOption, iType == Pistol ? Pistol : iType==Rifle ? Rifle : Grenade);
			g_iMenuType[client] = (g_iMenuType[client] == Grenade) ? Rifle : g_iMenuType[client] == Rifle ? Pistol : Grenade;

			if(g_iMenuType[client] != Rifle)
				CreateGunsMenu(client, 0);
		}
		case MenuAction_End:
		delete hMenu;
	}
}

void GiveWeapon(int client, int iWeapon, int iType)
{
	char sColor[12];
	if(IsValidClient(client))
	{
		int iSlot = GetPlayerWeaponSlot(client, iType==Pistol ? CS_SLOT_SECONDARY : iType==Rifle ? CS_SLOT_PRIMARY : CS_SLOT_GRENADE);
		if(iSlot != -1 || iSlot != CS_SLOT_GRENADE) 
		if (IsValidEntity(iSlot))
		AcceptEntityInput(iSlot, "kill");
		
		FormatEx(sColor, sizeof(sColor), "%s", iType==Pistol ? "\x0B" : iType==Rifle ? "\x0F" : "\x08");
		GivePlayerItem(client, iType==Pistol ? PISTOLS[iWeapon][0] : iType==Rifle ? GUNS[iWeapon][0] : GRENADES[iWeapon][0]);
		PrintToChat(client, "%s \x0AYou have been given a %s%s", PREFIX, sColor, iType == Pistol ? PISTOLS[iWeapon][1] : iType == Rifle ? GUNS[iWeapon][1] : GRENADES[iWeapon][1]);
	}
}

bool IsValidClient(int client)
{
	return view_as<bool>((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
}