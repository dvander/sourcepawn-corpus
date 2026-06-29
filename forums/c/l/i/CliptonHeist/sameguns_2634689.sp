#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"1.1.1"

ArrayList g_Weapons;
ArrayList g_GunsUsed;

ConVar g_hCV_EnablePlugin;
ConVar g_hCV_GiveArmor;
ConVar g_hCV_GiveHelmet;
ConVar g_hCV_GiveSmoke;
ConVar g_hCV_GiveHE;
ConVar g_hCV_GiveFlash;
ConVar g_hCV_GiveDecoy;

//Plugin Information:
public Plugin myinfo = 
{
	name = "Same Guns", 
	author = "The Doggy", 
	description = "Revamped CS:GO gungame basically", 
	version = PLUGIN_VERSION,
	url = "coldcommunity.com"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		char name[32];
		PrintToServer("This plugin can only be used on CS:GO");
		GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
		ServerCommand("sm plugins unload %s", name);
	}

	g_hCV_EnablePlugin = CreateConVar("sm_same_guns_enable", "1", "Enable/Disable this plugin, 1=Enabled, 0=Disabled.");
	g_hCV_GiveArmor = CreateConVar("sm_same_guns_givearmor", "1", "Give players armor when the round starts.");
	g_hCV_GiveHelmet = CreateConVar("sm_same_guns_givehelmet", "1", "Give players helmet when the round starts.");
	g_hCV_GiveSmoke = CreateConVar("sm_same_guns_givesmoke", "1", "Give players a smoke grenade when the round starts.");
	g_hCV_GiveHE = CreateConVar("sm_same_guns_givegrenade", "1", "Give players a HE grenade when the round starts.");
	g_hCV_GiveFlash = CreateConVar("sm_same_guns_giveflash", "1", "Give players a flashbang when the round starts.");
	g_hCV_GiveDecoy = CreateConVar("sm_same_guns_givedecoy", "1", "Give players a decoy grenade when the round starts.");
	AutoExecConfig(true, "sm_same_guns");

	g_Weapons = new ArrayList(32);
	g_GunsUsed = new ArrayList(32);

	g_Weapons.PushString("weapon_ak47");
	g_Weapons.PushString("weapon_aug");
	g_Weapons.PushString("weapon_awp");
	g_Weapons.PushString("weapon_bizon");
	g_Weapons.PushString("weapon_cz75a");
	g_Weapons.PushString("weapon_deagle");
	g_Weapons.PushString("weapon_famas");
	g_Weapons.PushString("weapon_fiveseven");
	g_Weapons.PushString("weapon_g3sg1");
	g_Weapons.PushString("weapon_galilar");
	g_Weapons.PushString("weapon_glock");
	g_Weapons.PushString("weapon_hkp2000");
	g_Weapons.PushString("weapon_m249");
	g_Weapons.PushString("weapon_m4a1");
	g_Weapons.PushString("weapon_m4a1_silencer");
	g_Weapons.PushString("weapon_mac10");
	g_Weapons.PushString("weapon_mag7");
	g_Weapons.PushString("weapon_mp7");
	g_Weapons.PushString("weapon_mp9");
	g_Weapons.PushString("weapon_negev");
	g_Weapons.PushString("weapon_nova");
	g_Weapons.PushString("weapon_p250");
	g_Weapons.PushString("weapon_p90");
	g_Weapons.PushString("weapon_sawedoff");
	g_Weapons.PushString("weapon_scar20");
	g_Weapons.PushString("weapon_sg556");
	g_Weapons.PushString("weapon_ssg08");
	g_Weapons.PushString("weapon_taser");
	g_Weapons.PushString("weapon_tec9");
	g_Weapons.PushString("weapon_ump45");
	g_Weapons.PushString("weapon_usp_silencer");
	g_Weapons.PushString("weapon_xm1014");
	g_Weapons.PushString("weapon_revolver");

	RegAdminCmd("sm_toggleweapon", Command_ToggleWeapon, ADMFLAG_BAN, "[SM] Toggles whether a weapon can be given during round start.");
	RegAdminCmd("sm_listweapons", Command_ListWeapon, ADMFLAG_BAN, "[SM] Shows all weapons currently allowed to be given during round start.");
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_hCV_EnablePlugin.BoolValue)
	{
		RemoveAllWeapons();
		GiveStartingWeapons();
		GiveRandomWeapon();

		GameRules_SetProp("m_bTCantBuy", true, _, _, true);
		GameRules_SetProp("m_bCTCantBuy", true, _, _, true);
	}
}

public Action Command_ToggleWeapon(int Client, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Handled;

	if(iArgs != 1)
	{
		PrintToChat(Client, "[SM] Invalid Syntax. Usage: sm_toggleweapon <weapon_name>");
		return Plugin_Handled;
	}

	char weapon[32];
	GetCmdArg(1, weapon, sizeof(weapon));

	if(StrContains(weapon, "weapon_", true) == -1)
		Format(weapon, sizeof(weapon), "weapon_%s", weapon);

	if(g_Weapons.FindString(weapon) == -1 && CS_IsValidWeaponID(CS_AliasToWeaponID(weapon)))
	{
		g_Weapons.PushString(weapon);
		ReplaceString(weapon, sizeof(weapon), "weapon_", "", true);
		PrintToChat(Client, "[SM] %s has been added to the weapons list!", weapon);
	}
	else if(g_Weapons.FindString(weapon) != -1)
	{
		g_Weapons.Erase(g_Weapons.FindString(weapon));
		ReplaceString(weapon, sizeof(weapon), "weapon_", "", true);
		PrintToChat(Client, "[SM] %s has been removed from the weapons list!", weapon);
	}
	else
		PrintToChat(Client, "[SM] Invalid Weapon: %s", weapon);

	return Plugin_Handled;
}

public Action Command_ListWeapon(int Client, int iArgs)
{
	if(!IsValidClient) return Plugin_Handled;

	Menu hWeaponMenu = new Menu(WeaponMenu);
	for(int i = 0; i < g_Weapons.Length; i++)
	{
		char weapon[32];
		g_Weapons.GetString(i, weapon, sizeof(weapon));
		hWeaponMenu.AddItem(weapon, weapon, ITEMDRAW_DISABLED);
	}
	hWeaponMenu.Display(Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int WeaponMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		delete menu;

	return 0;
}

public void RemoveAllWeapons()
{
	for(int i = 0; i < g_Weapons.Length; i++)
	{
		int entity = -1;
		char weapon[32];
		g_Weapons.GetString(i, weapon, sizeof(weapon));

		while((entity = FindEntityByClassname(entity, weapon)) != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public void GiveStartingWeapons()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;

		if(g_hCV_GiveArmor.BoolValue)
			SetEntProp(i, Prop_Send, "m_ArmorValue", 100, 1);
		if(g_hCV_GiveHelmet.BoolValue)
			GivePlayerItem(i, "item_assaultsuit");
		if(g_hCV_GiveSmoke.BoolValue)
			GivePlayerItem(i, "weapon_smokegrenade");
		if(g_hCV_GiveHE.BoolValue)
			GivePlayerItem(i, "weapon_hegrenade");
		if(g_hCV_GiveFlash.BoolValue)
			GivePlayerItem(i, "weapon_flashbang");
		if(g_hCV_GiveDecoy.BoolValue)
			GivePlayerItem(i, "weapon_decoy");
		if((StrContains(map, "de_", false) != -1) && GetClientTeam(i) == CS_TEAM_CT)
			GivePlayerItem(i, "item_defuser");
	}
}

public void GiveRandomWeapon()
{
	int rand;
	char weapon[32];
	do
	{
		rand = GetRandomInt(0, g_Weapons.Length - 1);
		g_Weapons.GetString(rand, weapon, sizeof(weapon));
	} while(g_GunsUsed.FindString(weapon) != -1);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			GivePlayerItem(i, weapon);
	}

	g_GunsUsed.PushString(weapon);
	if(g_GunsUsed.Length > 4)
		g_GunsUsed.Erase(0);
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}