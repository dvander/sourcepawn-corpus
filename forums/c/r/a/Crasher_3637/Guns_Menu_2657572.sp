#define PLUGIN_NAME "Guns Menu by Pilo#8253"
#define PLUGIN_LERIAS "Discord : Pilo#8253"
#define PLUGIN_AUTHOR "Pilo"
#define PLUGIN_VERSION "1.0"
#define AUTHOR_URL "https://forums.alliedmods.net/member.php?u=290157"

#include <sourcemod>
#include <sdktools>
#include <store>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION,
	url = AUTHOR_URL
};

char g_szPrimary[][] = {
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_m4a1_silencer",
	"weapon_sg556",
	"weapon_aug",
	"weapon_galilar",
	"weapon_famas",
	"weapon_awp",
	"weapon_ssg08",
	"weapon_g3sg1",
	"weapon_scar20",
	"weapon_m249",
	"weapon_negev",
	"weapon_nova",
	"weapon_xm1014",
	"weapon_sawedoff",
	"weapon_mag7",
	"weapon_mac10",
	"weapon_mp9",
	"weapon_mp7",
	"weapon_ump45",
	"weapon_p90",
	"weapon_bizon",
	""
};
char g_szPrimaryNames[][] = {
	"AK-47",
	"M4A1",
	"M4A1-S",
	"SG-556",
	"AUG",
	"Galil-AR",
	"FAMAS",
	"AWP",
	"SGG-08",
	"G3SG1",
	"SCAR-20",
	"M249",
	"Negev",
	"Nova",
	"XM1014",
	"Sawed-Off",
	"MAG-7",
	"MAC-10",
	"MP9",
	"MP7",
	"UMP-45",
	"P90",
	"Bizon",
	"None"
};
char g_szSecondary[][] = {
	"weapon_glock",
	"weapon_p250",
	"weapon_cz75a",
	"weapon_usp_silencer",
	"weapon_fiveseven",
	"weapon_deagle",
	"weapon_revolver",
	"weapon_elite",
	"weapon_tec9",
	"weapon_hkp2000",
	""
};
char g_szSecondaryNames[][] = {
	"Glock-18",
	"P250",
	"CZ75-A",
	"USP-S",
	"Five-Seven",
	"Deagle",
	"Revolver",
	"Dual Berettas",
	"Tec-9",
	"P2000",
	"None"
};

#define PREFIX "[Guns Menu]"

ConVar gcv_VipOnly;

public void OnPluginStart()
{
	RegConsoleCmd("sm_guns", Command_Guns);
	gcv_VipOnly = CreateConVar("sm_gunsmenu_vip_only", "0", "0 = Allow to everyone | 1 = Allow only to Zephyrus VIP");
}

public Action Command_Guns(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (gcv_VipOnly.BoolValue && !Store_IsClientVIP(client))
		{
			PrintToChat(client, "%s This command is only for VIP!", PREFIX);

			return Plugin_Handled;
		}
		else
		{
			Menu gunsmenu = new Menu(menuHandler_Guns);
			char szTitle[128];
			Format(szTitle, sizeof(szTitle), "%s Guns Menu", PREFIX);
			gunsmenu.SetTitle(szTitle);

			for (int i = 0; i < 24; i++)
			{
				gunsmenu.AddItem(g_szPrimary[i], g_szPrimaryNames[i]);
			}

			gunsmenu.Display(client, MENU_TIME_FOREVER);
		}
	}

	return Plugin_Handled;
}

public int menuHandler_Guns(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char szInfo[32];
			menu.GetItem(param2, szInfo, sizeof(szInfo));

			PrintToChat(param1, "%s You chose \x02%s", PREFIX, g_szPrimaryNames[param2]);
			GivePlayerItem(param1, g_szPrimary[param2]);

			char szTitle[128];
			Format(szTitle, sizeof(szTitle), "%s Guns Menu", PREFIX);
			Menu pistolsmenu = new Menu(menuHandler_PistolsMenu);
			pistolsmenu.SetTitle(szTitle);

			for (int i = 0; i < 11; i++)
			{
				pistolsmenu.AddItem(g_szSecondary[i], g_szSecondaryNames[i]);
			}

			pistolsmenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
}

public int menuHandler_PistolsMenu(Menu menu, MenuAction action, int param1, int param2)
{	
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char szInfo[32];
			menu.GetItem(param2, szInfo, sizeof(szInfo));

			PrintToChat(param1, "%s You chose \x02%s", PREFIX, g_szSecondaryNames[param2]);
			GivePlayerItem(param1, g_szSecondary[param2]);
		}
	}
}