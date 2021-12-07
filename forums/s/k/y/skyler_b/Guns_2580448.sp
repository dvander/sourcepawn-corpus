#pragma semicolon 1

#define DEBUG
#define PREFIX "[SM] \x04"
#define PLUGIN_AUTHOR "skyler"
#define PLUGIN_VERSION "1.645"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <skyler>
char info[MAX_NAME_LENGTH];

public Plugin myinfo = 
{
	name = "Guns", 
	author = PLUGIN_AUTHOR, 
	description = "harban Gay", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=283190"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_guns", CMD_Guns, "Give players Guns");
	HookEvent("player_spawn", Event_PlayerSpawn);
}
public Action Event_PlayerSpawn(Event event, const char[] name, bool dB)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	GivePlayerItem(client, info);
}
public Action CMD_Guns(int client, args)
{
	Menu gunslist = new Menu(GunslistHander);
	gunslist.SetTitle("[SM] Choose weapon!");
	gunslist.AddItem("dgsfgsgd", "The weapon you select will be spawned to you every round!", ITEMDRAW_DISABLED);
	gunslist.AddItem("weapon_ak47", "Ak-47");
	gunslist.AddItem("weapon_aug", "Aug");
	gunslist.AddItem("weapon_bizon", "PP-Bizon");
	gunslist.AddItem("weapon_deagle", "Deagle");
	gunslist.AddItem("weapon_elite", "Dual Berettas");
	gunslist.AddItem("weapon_famas", "Famas");
	gunslist.AddItem("weapon_fiveseven", "Fiveseven");
	gunslist.AddItem("weapon_g3sg1", "G3sg1");
	gunslist.AddItem("weapon_galilar", "Galil-r");
	gunslist.AddItem("weapon_glock", "Glock-18");
	gunslist.AddItem("weapon_hkp2000", "P2000");
	gunslist.AddItem("weapon_mac10", "Mac10");
	gunslist.AddItem("weapon_mag7", "Mag7");
	gunslist.AddItem("weapon_mp7", "Mp7");
	gunslist.AddItem("weapon_mp9", "Mp9");
	gunslist.AddItem("weapon_negev", "Negev");
	gunslist.AddItem("weapon_nova", "Nova");
	gunslist.AddItem("weapon_p250", "P250");
	gunslist.AddItem("weapon_p90", "P90");
	gunslist.AddItem("weapon_sawedoff", "Sawed-off");
	gunslist.AddItem("weapon_scar20", "Scar-20");
	gunslist.AddItem("weapon_sg556", "Sg-556");
	gunslist.AddItem("weapon_ssg08", "Ssg-08");
	gunslist.AddItem("weapon_tec9", "Tec-9");
	gunslist.AddItem("weapon_ump45", "UMP-45");
	gunslist.AddItem("weapon_xm1014", "Xm-1014");
	gunslist.AddItem("weapon_m4a1","M4a1-s");
	gunslist.AddItem("weapon_m4a4","M4a4");
	gunslist.AddItem("weapon_awp","AWP");
}
public int GunslistHander(Menu gunslist, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		gunslist.GetItem(item, info, sizeof(info));
		GivePlayerItem(client, info);
	}
}
