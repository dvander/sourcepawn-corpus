#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <cstrike>

static const char
	PLUGIN_VERSION[] = "1.1.0 (rewritten by Grey83)",

	g_sWeapons[][] =
{
//CSS Weapons Replaced
	"weapon_galil",
	"weapon_ak47",
	"weapon_sg552",
	"weapon_famas",
	"weapon_m4a1",
	"weapon_aug",
//6
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_sg550",
	"weapon_scout",
//4
	"weapon_glock",
	"weapon_usp",
	"weapon_p228",
	"weapon_deagle",
	"weapon_elite",
	"weapon_fiveseven",
//6
	"weapon_m3",
	"weapon_xm1014",
//2
	"weapon_mac10",
	"weapon_tmp",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_p90",
//5
	"weapon_m249"
//1
};

enum
{
	Slot_Primary = 0,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};

ArrayList
	hGuns;
bool
	bDefuse,
	bEnable,
	bArmor,
	bHelmet,
	bSmoke,
	bHE,
	bFlash;

public Plugin myinfo =
{
	name		= "SameGunsCS",
	version		= PLUGIN_VERSION,
	description	= "Revamped CS:S gungame basically",
	author		= "Erbse+The Doggy",
	url			= "none.com"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSS)
	{
		FormatEx(error, err_max, "Plugin for CS:S only!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar cvar;
	cvar = CreateConVar("sm_same_guns_enable", "1", "Enable/Disable this plugin, 1=Enabled, 0=Disabled.", _, true, _, true, 1.0);
	bEnable = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Enable);

	cvar = CreateConVar("sm_same_guns_givearmor", "1", "Give players armor when the round starts.", _, true, _, true, 1.0);
	bArmor = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Armor);

	cvar = CreateConVar("sm_same_guns_givehelmet", "1", "Give players helmet when the round starts.", _, true, _, true, 1.0);
	bHelmet = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Helmet);

	cvar = CreateConVar("sm_same_guns_givesmoke", "1", "Give players a smoke grenade when the round starts.", _, true, _, true, 1.0);
	bSmoke = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Smoke);

	cvar = CreateConVar("sm_same_guns_givegrenade", "1", "Give players a HE grenade when the round starts.", _, true, _, true, 1.0);
	bHE = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_HE);

	cvar = CreateConVar("sm_same_guns_giveflash", "1", "Give players a flashbang when the round starts.", _, true, _, true, 1.0);
	bFlash = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Flash);

	AutoExecConfig(true, "sm_same_guns");

	hGuns = new ArrayList(ByteCountToCells(16));

	HookEvent("round_freeze_end", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void CVarChange_Armor(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bArmor = cvar.BoolValue;
}

public void CVarChange_Helmet(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bHelmet = cvar.BoolValue;
}

public void CVarChange_Smoke(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bSmoke = cvar.BoolValue;
}

public void CVarChange_HE(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bHE = cvar.BoolValue;
}

public void CVarChange_Flash(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bFlash = cvar.BoolValue;
}

public void OnMapStart()
{
	bDefuse = !!GameRules_GetProp("m_bMapHasBombTarget");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable) return;

	static int armor, helmet, defuser, num;
	int i = 1;
	for(; i <= MaxClients; i++) if(IsValidClient(i))
	{
		RemoveWeaponBySlot(i, Slot_Primary);
		RemoveWeaponBySlot(i, Slot_Secondary);
		while(RemoveWeaponBySlot(i, Slot_Grenade)) {}
	}

	char cls[20];
	for(int max = GetMaxEntities(); i < max; i++)
		if(IsValidEdict(i) && GetEntityClassname(i, cls, sizeof(cls)) && !strncmp(cls, "weapon_", 7, false))
			AcceptEntityInput(i, "Kill");

	for(i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(bArmor && (armor > 0 || (armor = FindSendPropInfo("CCSPlayer", "m_ArmorValue")) > 0))
			SetEntData(i, armor, 100, 1, true);
		if(bHelmet && (helmet > 0 || (helmet = FindSendPropInfo("CCSPlayer", "m_bHasHelmet")) > 0))
			SetEntData(i, helmet, 1, 1, true);

		if(bSmoke)	GivePlayerItem(i, "weapon_smokegrenade");
		if(bHE)		GivePlayerItem(i, "weapon_hegrenade");
		if(bFlash)	GivePlayerItem(i, "weapon_flashbang");

		if(bDefuse && GetClientTeam(i) == CS_TEAM_CT
		&& (defuser > 0 || (defuser = FindSendPropInfo("CCSPlayer", "m_bHasDefuser")) > 0))
			SetEntData(i, defuser, 1, 1, true);
	}

	if(!hGuns.Length) for(i = 0; i < sizeof(g_sWeapons); i++) hGuns.PushString(g_sWeapons[i]);

	i = GetRandomInt(0, hGuns.Length-1);
	hGuns.GetString(i, cls, sizeof(cls));
	hGuns.Erase(i);

	if(++num >= 4)
	{
		num = 0;
		hGuns.Clear();
	}

	for(i = 1; i <= MaxClients; i++) if(IsValidClient(i)) GivePlayerItem(i, cls);
}

stock bool RemoveWeaponBySlot(int client, int slot)
{
	int ent = GetPlayerWeaponSlot(client, slot);
	return ent > MaxClients && RemovePlayerItem(client, ent) && AcceptEntityInput(ent, "Kill");
}

stock bool IsValidClient(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) > 1 && IsPlayerAlive(client);
}