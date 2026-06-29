#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

static const bool
	bDebug = false;

static const char
	PLUGIN_VERSION[] = "1.3.1_15.01.2023",

	WEAPON[][] =
{
	"weapon_autoshotgun_spawn",
	"weapon_rifle_spawn",
	"weapon_hunting_rifle_spawn",
	"weapon_pistol_spawn",
	"weapon_pumpshotgun_spawn",
	"weapon_smg_spawn",
	// L4D2
	"weapon_grenade_launcher_spawn",
	"weapon_pistol_magnum_spawn",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_desert_spawn",
	"weapon_rifle_m60_spawn",
	"weapon_rifle_sg552_spawn",
	"weapon_shotgun_chrome_spawn",
	"weapon_shotgun_spas_spawn",
	"weapon_smg_mp5_spawn",
	"weapon_smg_silenced_spawn",
	"weapon_sniper_awp_spawn",
	"weapon_sniper_military_spawn",
	"weapon_sniper_scout_spawn"
};

enum
{
	W_autoshotgun,
	W_rifle,
	W_hunting_rifle,
	W_pistol,
	W_pumpshotgun,
	W_smg,
	// L4D2
	W_grenade_launcher,
	W_pistol_magnum,
	W_rifle_ak47,
	W_rifle_desert,
	W_rifle_m60,
	W_rifle_sg552,
	W_shotgun_chrome,
	W_shotgun_spas,
	W_smg_mp5,
	W_smg_silenced,
	W_sniper_awp,
	W_sniper_military,
	W_sniper_scout,
	W_all,

	W_Total
};

bool
	l4d2,
	enable;
int
	max,
	limit[W_Total],
	ent_table[W_all*8][2],
	new_ent_counter;

public Plugin myinfo =
{
	name		= "[L4D1+2] Weapon Remove",
	author		= "Rain_orel, Hanzolo, Dosergen, Grey83",
	description	= "Removes weapon spawn",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=1254023"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if(!(l4d2 = ev == Engine_Left4Dead2) && ev != Engine_Left4Dead)
	{
		FormatEx(error, err_max, "Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	max = l4d2 ? W_all : W_grenade_launcher;

	if(bDebug) PrintToServer("	Array size: %i", sizeof(ent_table));

	CreateConVar("l4d_weaponremove_version", PLUGIN_VERSION, "[L4D1+2] Weapon Remover defines how many times a weapon spawns", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_enable", "1", "Enable or disable Weapon Remover plugin", _, true, _, true, 1.0)), CVarChange_Enable);
	CVarChange_Enable(cvar, NULL_STRING, NULL_STRING);

	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_all", "0", "Limits all weapons to this many pickups (0 = no limit)", _, true)), CVarChange_All);
	limit[W_all] = cvar.IntValue;

	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_autoshotgun", "1", "Limit for Autoshotguns (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Autoshotgun);
	limit[W_autoshotgun] = cvar.IntValue;
	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_rifle", "1", "Limit for M4s (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Rifle);
	limit[W_rifle] = cvar.IntValue;
	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_hunting_rifle", "1", "Limit for Sniper Rifles (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_HuntingRifle);
	limit[W_hunting_rifle] = cvar.IntValue;
	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_pistol", "1", "Limit for Pistols (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Pistol);
	limit[W_pistol] = cvar.IntValue;
	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_pumpshotgun", "1", "Limit for Pumpshotguns (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Pumpshotgun);
	limit[W_pumpshotgun] = cvar.IntValue;
	HookConVarChange((cvar = CreateConVar("l4d_weaponremove_limit_smg", "1", "Limit for SMGs (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SMG);
	limit[W_smg] = cvar.IntValue;

	if(l4d2)
	{
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_grenade_launcher", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_GrenadeLauncher);
		limit[W_grenade_launcher] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_pistol_magnum", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_PistolMagnum);
		limit[W_pistol_magnum] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_rifle_ak47", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleAK47);
		limit[W_rifle_ak47] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_rifle_desert", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleDesert);
		limit[W_rifle_desert] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_rifle_m60", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleM60);
		limit[W_rifle_m60] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_rifle_sg552", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleSG552);
		limit[W_rifle_sg552] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_shotgun_chrome", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_ShotgunChrome);
		limit[W_shotgun_chrome] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_shotgun_spas", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_ShotgunSPAS);
		limit[W_shotgun_spas] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_smg_mp5", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SMG_MP5);
		limit[W_smg_mp5] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_smg_silenced", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SMG_Silenced);
		limit[W_smg_silenced] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_sniper_awp", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SniperAWP);
		limit[W_sniper_awp] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_sniper_military", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SniperMilitary);
		limit[W_sniper_military] = cvar.IntValue;
		HookConVarChange((cvar = CreateConVar("l4d2_weaponremove_limit_sniper_scout", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SniperScout);
		limit[W_sniper_scout] = cvar.IntValue;
	}

	AutoExecConfig(true, "l4d_weaponremove");

	HookEvent("spawner_give_item", Event_Item);
	HookEvent("round_start", Event_Start);
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if(hooked == (enable = cvar.BoolValue)) return;

	if((hooked ^= true))
	{
		HookEvent("spawner_give_item", Event_Item);
		HookEvent("round_start", Event_Start);
	}
	else
	{
		UnhookEvent("spawner_give_item", Event_Item);
		UnhookEvent("round_start", Event_Start);
	}
}

public void CVarChange_All(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	limit[W_all] = cvar.IntValue;
}

public void CVarChange_Autoshotgun(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_autoshotgun);
}

public void CVarChange_Rifle(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_rifle);
}

public void CVarChange_HuntingRifle(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_hunting_rifle);
}

public void CVarChange_Pistol(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_pistol);
}

public void CVarChange_Pumpshotgun(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_pumpshotgun);
}

public void CVarChange_SMG(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_smg);
}

// L4D2
public void CVarChange_GrenadeLauncher(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_grenade_launcher);
}

public void CVarChange_PistolMagnum(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_pistol_magnum);
}

public void CVarChange_RifleAK47(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_rifle_ak47);
}

public void CVarChange_RifleDesert(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_rifle_desert);
}

public void CVarChange_RifleM60(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_rifle_m60);
}

public void CVarChange_RifleSG552(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_rifle_sg552);
}

public void CVarChange_ShotgunChrome(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_shotgun_chrome);
}

public void CVarChange_ShotgunSPAS(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_shotgun_spas);
}

public void CVarChange_SMG_MP5(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_smg_mp5);
}

public void CVarChange_SMG_Silenced(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_smg_silenced);
}

public void CVarChange_SniperAWP(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_sniper_awp);
}

public void CVarChange_SniperMilitary(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_sniper_military);
}

public void CVarChange_SniperScout(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CheckWeapons(cvar, W_sniper_scout);
}

stock void CheckWeapons(ConVar cvar, int type)
{
	if((limit[type] = cvar.IntValue) < 0 && enable) DeleteAllEntities(WEAPON[type]);
}

public void OnMapStart()
{
	int i;
	for(; i < sizeof(ent_table); i++) ent_table[i][0]= ent_table[i][1]= -1;
	new_ent_counter = i = 0;
	if(!enable) return;

	for(; i < max; i++) if(limit[i] < 0) DeleteAllEntities(WEAPON[i]);
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

public void Event_Item(Event event, const char[] name, bool dontBroadcast)
{
	static int entid, count;
	if((count = GetUseCount((entid = event.GetInt("spawner")))) == -1)
	{
		ent_table[new_ent_counter][0] = entid;
		ent_table[new_ent_counter][1] = 0;
		new_ent_counter = FindFirstEmptyCell();
	}

	if(bDebug) PrintToServer("	NewEntCounter: %i/%i", new_ent_counter, sizeof(ent_table));

	SetUseCount(entid);
	count++;

	if(limit[W_all] && limit[W_all] >= count || CheckEntity(event, entid, count))
#if SOURCEMOD_V_MAJOR < 2 && SOURCEMOD_V_MINOR < 10
		AcceptEntityInput(entid, "Kill") ResetUseCount(entid);
#else
	{
		RemoveEntity(entid);
		ResetUseCount(entid);
	}
#endif
}

stock bool CheckEntity(Event event, int ent, int count)
{
	static char item[24];
	event.GetString("item", item, sizeof(item));
	for(int i; i < max; i++) if(!strncmp(item[7], WEAPON[i][7], strlen(WEAPON[i])-13, false) && count >= limit[i])
		return true;

	return false;
}

int FindFirstEmptyCell()
{
	for(int i; i < sizeof(ent_table); i++) if(ent_table[i][0] == -1) return i;

	LogError("The table has run out of cell!");
	return -1;
}

int GetUseCount(const int entid)
{
	for(int i; i < sizeof(ent_table); i++) if(ent_table[i][0] == entid) return ent_table[i][1];

	return -1;
}

void SetUseCount(const int entid)
{
	for(int i; i < sizeof(ent_table); i++) if(ent_table[i][0] == entid)
	{
		ent_table[i][1]++;
		if(bDebug) PrintToServer("	Used table cell: %i (value: %i)", i, ent_table[i][1]);
		break;
	}
}

void ResetUseCount(const int entid)
{
	for(int i; i < sizeof(ent_table); i++) if(ent_table[i][0] == entid)
	{
		ent_table[i][0] = ent_table[i][1] = -1;
		break;
	}
}

void DeleteAllEntities(const char[] class)
{
	int ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, class)) != INVALID_ENT_REFERENCE)
#if SOURCEMOD_V_MAJOR < 2 && SOURCEMOD_V_MINOR < 10
		AcceptEntityInput(ent, "Kill");
#else
		RemoveEntity(ent);
#endif
}