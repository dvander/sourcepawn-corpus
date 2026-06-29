#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"1.0.0"

char g_sWeapons[][] = {
//CSS Weapons Replaced
	{"weapon_galil"},
	{"weapon_ak47"},
	{"weapon_sg552"},
	{"weapon_famas"},
	{"weapon_m4a1"},
	{"weapon_aug"},
//6
	{"weapon_awp"},
	{"weapon_g3sg1"},
	{"weapon_sg550"},
	{"weapon_scout"},
//4
	{"weapon_glock"},
	{"weapon_usp"},
	{"weapon_p228"},
	{"weapon_deagle"},
	{"weapon_elite"},
	{"weapon_fiveseven"},
//6
	{"weapon_m3"},
	{"weapon_xm1014"},
//2
	{"weapon_mac10"},
	{"weapon_tmp"},
	{"weapon_mp5navy"},
	{"weapon_ump45"},
	{"weapon_p90"},
//5
	{"weapon_m249"}
//1
};

ArrayList g_GunsUsed;

ConVar g_hCV_EnablePlugin;
ConVar g_hCV_GiveArmor;
ConVar g_hCV_GiveHelmet;
ConVar g_hCV_GiveSmoke;
ConVar g_hCV_GiveHE;
ConVar g_hCV_GiveFlash;
// Deleted ConVar g_hCV_GiveDecoy;

//Plugin Information:
public Plugin myinfo = 
{
//Edited
	name = "SameGunsCS", 
	author = "Erbse+The Doggy", 
	description = "Revamped CS:S gungame basically", 
	version = PLUGIN_VERSION,
	url = "none.com"
};

public void OnPluginStart()
{
//Replace Engine_CSGO?
//	if(GetEngineVersion() != Engine_CSGO)
//	{
//		char name[32];
//		PrintToServer("This plugin can only be used on CS:GO");
//		GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
//		ServerCommand("sm plugins unload %s", name);
//	}

	g_hCV_EnablePlugin = CreateConVar("sm_same_guns_enable", "1", "Enable/Disable this plugin, 1=Enabled, 0=Disabled.");
	g_hCV_GiveArmor = CreateConVar("sm_same_guns_givearmor", "1", "Give players armor when the round starts.");
	g_hCV_GiveHelmet = CreateConVar("sm_same_guns_givehelmet", "1", "Give players helmet when the round starts.");
	g_hCV_GiveSmoke = CreateConVar("sm_same_guns_givesmoke", "1", "Give players a smoke grenade when the round starts.");
	g_hCV_GiveHE = CreateConVar("sm_same_guns_givegrenade", "1", "Give players a HE grenade when the round starts.");
	g_hCV_GiveFlash = CreateConVar("sm_same_guns_giveflash", "1", "Give players a flashbang when the round starts.");
//	g_hCV_GiveDecoy = CreateConVar("sm_same_guns_givedecoy", "1", "Give players a decoy grenade when the round starts.");	
	AutoExecConfig(true, "sm_same_guns");

	g_GunsUsed = new ArrayList(24);

	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_hCV_EnablePlugin.BoolValue)
	{
		RemoveAllWeapons();
		GiveStartingWeapons();
		GiveRandomWeapon();
//are those compatible with CSS?
		GameRules_SetProp("m_bTCantBuy", true, _, _, true);
		GameRules_SetProp("m_bCTCantBuy", true, _, _, true);
	}
}

public void RemoveAllWeapons()
{
	for(int i = 0; i < sizeof(g_sWeapons); i++)
	{
		int entity = -1;
		while((entity = FindEntityByClassname(entity, g_sWeapons[i])) != INVALID_ENT_REFERENCE)
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
		if((StrContains(map, "de_", false) != -1) && GetClientTeam(i) == CS_TEAM_CT)
			GivePlayerItem(i, "item_defuser");
	}
}

public void GiveRandomWeapon()
{
	int rand;
	do
	{
		rand = GetRandomInt(0, sizeof(g_sWeapons) - 1);
	} while(g_GunsUsed.FindString(g_sWeapons[rand]) != -1);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			GivePlayerItem(i, g_sWeapons[rand]);
	}

	g_GunsUsed.PushString(g_sWeapons[rand]);
	if(g_GunsUsed.Length > 4)
		g_GunsUsed.Erase(0);
}

//works with bots too?
stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}