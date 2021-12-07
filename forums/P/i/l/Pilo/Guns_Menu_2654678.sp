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

char g_szPrimary[][] =  {
	"weapon_ak47", 
	"weapon_m4a1", 
	"weapon_m4a1_silencer", 
	"weapon_sg556", 
	"weapon_aug", 
	"weapon_galilar", 
	"weapon_famas", 
	"weapon_awp", 
	"weapon_ssg08",  
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

char g_szPrimaryNames[][] =  {
	"AK47", 
	"M4A4", 
	"M4A1S", 
	"SG556", 
	"AUG", 
	"GalilAR", 
	"Famas", 
	"AWP", 
	"SGG08", 
	"M249", 
	"Negev", 
	"Nova", 
	"XM1014", 
	"SawedOff", 
	"MAG7", 
	"MAC10", 
	"MP9", 
	"MP7", 
	"UMP45", 
	"P90", 
	"Bizon",
	""
};
char g_szSecondary[][] =  {
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

char g_szSecondaryNames[][] =  {
	"Glock", 
	"P250", 
	"CZ75A", 
	"Usp-S", 
	"Five-Seven", 
	"Deagle", 
	"Revolver", 
	"Dual Berettas", 
	"Tec-9", 
	"P2000",
	""
};

#define PREFIX "[Guns Menu]"
#define MENUPREFIX "[Guns Menu]"

ConVar gcv_VipOnly;

public void OnPluginStart()
{
	RegConsoleCmd("sm_guns", Command_Guns);
	gcv_VipOnly = CreateConVar("sm_gunsmenu_vip_only", "0", "/- 0 = Allow to everyone /- 1 = Allow only to Zephyrus VIP");
}

public Action Command_Guns(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		int VIPOnly = GetConVarInt(gcv_VipOnly);
		
		if (VIPOnly == 1)
		{
			if (!Store_IsClientVIP(client))
			{
				PrintToChat(client, "%s This command is only for VIP!", PREFIX);
				return Plugin_Handled;
			}
			else
			{
				Menu gunsmenu = new Menu(menuHandler_Guns);
				char szTitle[128];
				Format(szTitle, sizeof(szTitle), "[%s] Guns Menu", MENUPREFIX);
				gunsmenu.SetTitle(szTitle);
				
				gunsmenu.AddItem("weapon_ak47", "AK-47");
				gunsmenu.AddItem("weapon_m4a1", "M4A1");
				gunsmenu.AddItem("weapon_m4a1_silencer", "M4A1-S");
				gunsmenu.AddItem("weapon_sg556", "SG 553");
				gunsmenu.AddItem("weapon_aug", "AUG");
				gunsmenu.AddItem("weapon_galilar", "Galil AR");
				gunsmenu.AddItem("weapon_famas", "FAMAS");
				gunsmenu.AddItem("weapon_awp", "AWP");
				gunsmenu.AddItem("weapon_ssg08", "SSG 08");
				gunsmenu.AddItem("weapon_g3sg1", "G3SG1");
				gunsmenu.AddItem("weapon_scar20", "SCAR-20");
				gunsmenu.AddItem("weapon_m249", "M249");
				gunsmenu.AddItem("weapon_negev", "Negev");
				gunsmenu.AddItem("weapon_nova", "Nova");
				gunsmenu.AddItem("weapon_xm1014", "XM1014");
				gunsmenu.AddItem("weapon_sawedoff", "Sawed-Off");
				gunsmenu.AddItem("weapon_mag7", "MAG-7");
				gunsmenu.AddItem("weapon_mac10", "MAC-10");
				gunsmenu.AddItem("weapon_mp9", "MP9");
				gunsmenu.AddItem("weapon_mp7", "MP7");
				gunsmenu.AddItem("weapon_ump45", "UMP-45");
				gunsmenu.AddItem("weapon_p90", "P90");
				gunsmenu.AddItem("weapon_bizon", "PP-Bizon");
				gunsmenu.AddItem("", "None");
				
				gunsmenu.Display(client, MENU_TIME_FOREVER);
			}
		}
		else
		{
			Menu gunsmenu = new Menu(menuHandler_Guns);
			char szTitle[128];
			Format(szTitle, sizeof(szTitle), "[%s] Guns Menu", MENUPREFIX);
			gunsmenu.SetTitle(szTitle);
			
			gunsmenu.AddItem("weapon_ak47", "AK-47");
			gunsmenu.AddItem("weapon_m4a1", "M4A1");
			gunsmenu.AddItem("weapon_m4a1_silencer", "M4A1-S");
			gunsmenu.AddItem("weapon_sg556", "SG 553");
			gunsmenu.AddItem("weapon_aug", "AUG");
			gunsmenu.AddItem("weapon_galilar", "Galil AR");
			gunsmenu.AddItem("weapon_famas", "FAMAS");
			gunsmenu.AddItem("weapon_awp", "AWP");
			gunsmenu.AddItem("weapon_ssg08", "SSG 08");
			gunsmenu.AddItem("weapon_g3sg1", "G3SG1");
			gunsmenu.AddItem("weapon_scar20", "SCAR-20");
			gunsmenu.AddItem("weapon_m249", "M249");
			gunsmenu.AddItem("weapon_negev", "Negev");
			gunsmenu.AddItem("weapon_nova", "Nova");
			gunsmenu.AddItem("weapon_xm1014", "XM1014");
			gunsmenu.AddItem("weapon_sawedoff", "Sawed-Off");
			gunsmenu.AddItem("weapon_mag7", "MAG-7");
			gunsmenu.AddItem("weapon_mac10", "MAC-10");
			gunsmenu.AddItem("weapon_mp9", "MP9");
			gunsmenu.AddItem("weapon_mp7", "MP7");
			gunsmenu.AddItem("weapon_ump45", "UMP-45");
			gunsmenu.AddItem("weapon_p90", "P90");
			gunsmenu.AddItem("weapon_bizon", "PP-Bizon");
			gunsmenu.AddItem("", "None");
				
			gunsmenu.Display(client, MENU_TIME_FOREVER);
		}
	}
	return Plugin_Handled;
}

public int menuHandler_Guns(Menu menu, MenuAction action, int param1, int param2)
{
	char szInfo[32];
	menu.GetItem(param2, szInfo, sizeof(szInfo));
	
	if (action == MenuAction_Select)
	{
		PrintToChat(param1, "%s You chose \x02%s", PREFIX, g_szPrimaryNames[param2]);
		GivePlayerItem(param1, g_szPrimary[param2]);
		
		char szTitle[128];
		Format(szTitle, sizeof(szTitle), "[%s] Guns Menu", MENUPREFIX);
		Menu pistolsmenu = new Menu(menuHandler_PistolsMenu);
		pistolsmenu.SetTitle(szTitle);
		
		pistolsmenu.AddItem("weapon_glock", "Glock-18");
		pistolsmenu.AddItem("weapon_p250", "P250");
		pistolsmenu.AddItem("weapon_cz75a", "CZ75-A");
		pistolsmenu.AddItem("weapon_usp_silencer", "USP-S");
		pistolsmenu.AddItem("weapon_fiveseven", "Five-SeveN");
		pistolsmenu.AddItem("weapon_deagle", "Desert Eagle");
		pistolsmenu.AddItem("weapon_revolver", "R8");
		pistolsmenu.AddItem("weapon_elite", "Dual Berettas");
		pistolsmenu.AddItem("weapon_tec9", "Tec-9");
		pistolsmenu.AddItem("weapon_hkp2000", "P2000");
		pistolsmenu.AddItem("", "None");
		
		pistolsmenu.Display(param1, MENU_TIME_FOREVER);
	}
}

public int menuHandler_PistolsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	char szInfo[32];
	menu.GetItem(param2, szInfo, sizeof(szInfo));
	
	if (action == MenuAction_Select)
	{
		PrintToChat(param1, "%s You chose \x02%s", PREFIX, g_szSecondaryNames[param2]);
		GivePlayerItem(param1, g_szSecondary[param2]);
	}
}