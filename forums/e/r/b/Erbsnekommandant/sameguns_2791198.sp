#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"1.0.0"

char g_sWeapons[][] = {
	{"weapon_ak47"},
	{"weapon_aug"},
	{"weapon_awp"},
	{"weapon_bizon"},
	{"weapon_cz75a"},
	{"weapon_deagle"},
	{"weapon_elite"},
	{"weapon_famas"},
	{"weapon_fiveseven"},
	{"weapon_g3sg1"},
	{"weapon_galilar"},
	{"weapon_glock"},
	{"weapon_hkp2000"},
	{"weapon_m249"},
	{"weapon_m4a1"},
	{"weapon_m4a1_silencer"},
	{"weapon_mac10"},
	{"weapon_mag7"},
	{"weapon_mp7"},
	{"weapon_mp9"},
	{"weapon_negev"},
	{"weapon_nova"},
	{"weapon_p250"},
	{"weapon_p90"},
	{"weapon_sawedoff"},
	{"weapon_scar20"},
	{"weapon_sg556"},
	{"weapon_ssg08"},
	{"weapon_taser"},
	{"weapon_tec9"},
	{"weapon_ump45"},
	{"weapon_usp_silencer"},
	{"weapon_xm1014"},
	{"weapon_revolver"}
};

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

	g_GunsUsed = new ArrayList(32);

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
		if(g_hCV_GiveDecoy.BoolValue)
			GivePlayerItem(i, "weapon_decoy");
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

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}