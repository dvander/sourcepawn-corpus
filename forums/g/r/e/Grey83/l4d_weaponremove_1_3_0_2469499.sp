#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

static char PLUGIN_VERSION[] = "1.3.0";

bool bDebug = false;

bool l4d2;

int limit_autoshotgun,
	limit_rifle,
	limit_hunting_rifle,
	limit_pistol,
	limit_pumpshotgun,
	limit_smg,
	limit_grenade_launcher,
	limit_pistol_magnum,
	limit_rifle_ak47,
	limit_rifle_desert,
	limit_rifle_m60,
	limit_rifle_sg552,
	limit_shotgun_chrome,
	limit_shotgun_spas,
	limit_smg_mp5,
	limit_smg_silenced,
	limit_sniper_awp,
	limit_sniper_military,
	limit_sniper_scout,

	ent_table[64][2],
	new_ent_counter,
	table_size;

public Plugin myinfo =
{
	name = "[L4D1+2] Weapon Remove",
	author = "Rain_orel, Hanzolo (rewrited by Grey83)",
	description = "Removes weapon spawn",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1254023"
};

public void OnPluginStart()
{
	if(GetEngineVersion() == Engine_Left4Dead2) l4d2 = true;
	else if(GetEngineVersion() != Engine_Left4Dead) SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");

	table_size = sizeof(ent_table);
	if(bDebug) PrintToServer("	Array size: %i", table_size);

	CreateConVar("l4d_weaponremove_version", PLUGIN_VERSION, "[L4D1+2] Weapon Remover defines how many times a weapon spawns", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("l4d_weaponremove_limit_autoshotgun", "1", "Limit for Autoshotguns (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Autoshotgun);
	limit_autoshotgun = CVar.IntValue;
	HookConVarChange((CVar = CreateConVar("l4d_weaponremove_limit_rifle", "1", "Limit for M4s (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Rifle);
	limit_rifle = CVar.IntValue;
	HookConVarChange((CVar = CreateConVar("l4d_weaponremove_limit_hunting_rifle", "1", "Limit for Sniper Rifles (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_HuntingRifle);
	limit_hunting_rifle = CVar.IntValue;
	HookConVarChange((CVar = CreateConVar("l4d_weaponremove_limit_pistol", "1", "Limit for Pistols (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Pistol);
	limit_pistol = CVar.IntValue;
	HookConVarChange((CVar = CreateConVar("l4d_weaponremove_limit_pumpshotgun", "1", "Limit for Pumpshotguns (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_Pumpshotgun);
	limit_pumpshotgun = CVar.IntValue;
	HookConVarChange((CVar = CreateConVar("l4d_weaponremove_limit_smg", "1", "Limit for SMGs (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SMG);
	limit_smg = CVar.IntValue;
	if(l4d2)
	{
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_grenade_launcher", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_GrenadeLauncher);
		limit_grenade_launcher = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_pistol_magnum", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_PistolMagnum);
		limit_pistol_magnum = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_rifle_ak47", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleAK47);
		limit_rifle_ak47 = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_rifle_desert", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleDesert);
		limit_rifle_desert = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_rifle_m60", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleM60);
		limit_rifle_m60 = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_rifle_sg552", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_RifleSG552);
		limit_rifle_sg552 = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_shotgun_chrome", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_ShotgunChrome);
		limit_shotgun_chrome = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_shotgun_spas", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_ShotgunSPAS);
		limit_shotgun_spas = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_smg_mp5", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SMG_MP5);
		limit_smg_mp5 = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_smg_silenced", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SMG_Silenced);
		limit_smg_silenced = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_sniper_awp", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SniperAWP);
		limit_sniper_awp = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_sniper_military", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SniperMilitary);
		limit_sniper_military = CVar.IntValue;
		HookConVarChange((CVar = CreateConVar("l4d2_weaponremove_limit_sniper_scout", "1", "Limit for this weapon (0=infinite, -1=disable)", _, true, -1.0)), CVarChange_SniperScout);
		limit_sniper_scout = CVar.IntValue;
	}

	HookEvent("spawner_give_item", eSpawnerGiveItem, EventHookMode_Post);
	HookEvent("round_start", eRoundStart, EventHookMode_Post);

	AutoExecConfig(true, "l4d_weaponremove");
}

public void CVarChange_Autoshotgun(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_autoshotgun = CVar.IntValue) < 0)		DeleteAllEntities("weapon_autoshotgun_spawn"); }
public void CVarChange_Rifle(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_rifle = CVar.IntValue) < 0)				DeleteAllEntities("weapon_rifle_spawn"); }
public void CVarChange_HuntingRifle(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_hunting_rifle = CVar.IntValue) < 0)		DeleteAllEntities("weapon_hunting_rifle_spawn"); }
public void CVarChange_Pistol(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_pistol = CVar.IntValue) < 0)			DeleteAllEntities("weapon_pistol_spawn"); }
public void CVarChange_Pumpshotgun(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_pumpshotgun = CVar.IntValue) < 0)		DeleteAllEntities("weapon_pumpshotgun_spawn"); }
public void CVarChange_SMG(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_smg = CVar.IntValue) < 0)				DeleteAllEntities("weapon_smg_spawn"); }
// L4D2
public void CVarChange_GrenadeLauncher(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_grenade_launcher = CVar.IntValue) < 0)	DeleteAllEntities("weapon_grenade_launcher_spawn"); }
public void CVarChange_PistolMagnum(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_pistol_magnum = CVar.IntValue) < 0)		DeleteAllEntities("weapon_pistol_magnum_spawn"); }
public void CVarChange_RifleAK47(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_rifle_ak47 = CVar.IntValue) < 0)		DeleteAllEntities("weapon_rifle_ak47_spawn"); }
public void CVarChange_RifleDesert(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_rifle_desert = CVar.IntValue) < 0)		DeleteAllEntities("weapon_rifle_desert_spawn"); }
public void CVarChange_RifleM60(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_rifle_m60 = CVar.IntValue) < 0)			DeleteAllEntities("weapon_rifle_m60_spawn"); }
public void CVarChange_RifleSG552(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_rifle_sg552 = CVar.IntValue) < 0)		DeleteAllEntities("weapon_rifle_sg552_spawn"); }
public void CVarChange_ShotgunChrome(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_shotgun_chrome = CVar.IntValue) < 0)	DeleteAllEntities("weapon_shotgun_chrome_spawn"); }
public void CVarChange_ShotgunSPAS(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_shotgun_spas = CVar.IntValue) < 0)		DeleteAllEntities("weapon_shotgun_spas_spawn"); }
public void CVarChange_SMG_MP5(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_smg_mp5 = CVar.IntValue) < 0)			DeleteAllEntities("weapon_smg_mp5_spawn"); }
public void CVarChange_SMG_Silenced(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_smg_silenced = CVar.IntValue) < 0)		DeleteAllEntities("weapon_smg_silenced_spawn"); }
public void CVarChange_SniperAWP(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_sniper_awp = CVar.IntValue) < 0)		DeleteAllEntities("weapon_sniper_awp_spawn"); }
public void CVarChange_SniperMilitary(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_sniper_military = CVar.IntValue) < 0)	DeleteAllEntities("weapon_sniper_military_spawn"); }
public void CVarChange_SniperScout(ConVar CVar, const char[] oldValue, const char[] newValue)
{ if((limit_sniper_scout = CVar.IntValue) < 0)		DeleteAllEntities("weapon_sniper_scout_spawn"); }

public void OnMapStart()
{
	for(int i; i < table_size; i++)
	{
		ent_table[i][0]= ent_table[i][1]= -1;
	}
	new_ent_counter = 0;

	if(limit_autoshotgun < 0) DeleteAllEntities("weapon_autoshotgun_spawn");
	if(limit_rifle < 0) DeleteAllEntities("weapon_rifle_spawn");
	if(limit_hunting_rifle < 0) DeleteAllEntities("weapon_hunting_rifle_spawn");
	if(limit_pistol < 0) DeleteAllEntities("weapon_pistol_spawn");
	if(limit_pumpshotgun < 0) DeleteAllEntities("weapon_pumpshotgun_spawn");
	if(limit_smg < 0) DeleteAllEntities("weapon_smg_spawn");
	if(l4d2)
	{
		if(limit_grenade_launcher < 0) DeleteAllEntities("weapon_grenade_launcher_spawn");
		if(limit_pistol_magnum < 0) DeleteAllEntities("weapon_pistol_magnum_spawn");
		if(limit_rifle_ak47 < 0) DeleteAllEntities("weapon_rifle_ak47_spawn");
		if(limit_rifle_desert < 0) DeleteAllEntities("weapon_rifle_desert_spawn");
		if(limit_rifle_m60 < 0) DeleteAllEntities("weapon_rifle_m60_spawn");
		if(limit_rifle_sg552 < 0) DeleteAllEntities("weapon_rifle_sg552_spawn");
		if(limit_shotgun_chrome < 0) DeleteAllEntities("weapon_shotgun_chrome_spawn");
		if(limit_shotgun_spas < 0) DeleteAllEntities("weapon_shotgun_spas_spawn");
		if(limit_smg_mp5 < 0) DeleteAllEntities("weapon_smg_mp5_spawn");
		if(limit_smg_silenced < 0) DeleteAllEntities("weapon_smg_silenced_spawn");
		if(limit_sniper_awp < 0) DeleteAllEntities("weapon_sniper_awp_spawn");
		if(limit_sniper_military < 0) DeleteAllEntities("weapon_sniper_military_spawn");
		if(limit_sniper_scout < 0) DeleteAllEntities("weapon_sniper_scout_spawn");
	}
}

public void eRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

public void eSpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
{
	static char item[24];
	static int entid, count;
	event.GetString("item", item, 24);

	if((count = GetUseCount((entid = event.GetInt("spawner")))) == -1)
	{
		ent_table[new_ent_counter][0] = entid;
		ent_table[new_ent_counter][1] = 0;
		new_ent_counter = FindFirstEmptyCell();
	}
	if(bDebug) PrintToServer("	NewEntCounter: %i/%i", new_ent_counter, table_size);

	SetUseCount(entid);
	count++;

	if((StrContains(item, "autoshotgun", false) == 7	&& count == limit_autoshotgun) ||
	(StrContains(item, "rifle", false) == 7				&& count == limit_rifle) ||
	(StrContains(item, "hunting_rifle", false) == 7		&& count == limit_hunting_rifle) ||
	(StrContains(item, "pistol", false) == 7			&& count == limit_pistol) ||
	(StrContains(item, "pumpshotgun", false) == 7		&& count == limit_pumpshotgun) ||
	(StrContains(item, "smg", false) == 7				&& count == limit_smg) ||
	(StrContains(item, "grenade_launcher", false) == 7	&& count == limit_grenade_launcher) ||
	(StrContains(item, "pistol_magnum", false) == 7		&& count == limit_pistol_magnum) ||
	(StrContains(item, "rifle_ak47", false) == 7		&& count == limit_rifle_ak47) ||
	(StrContains(item, "rifle_desert", false) == 7		&& count == limit_rifle_desert) ||
	(StrContains(item, "rifle_m60", false) == 7			&& count == limit_rifle_m60) ||
	(StrContains(item, "rifle_sg552", false) == 7		&& count == limit_rifle_sg552) ||
	(StrContains(item, "shotgun_chrome", false) == 7	&& count == limit_shotgun_chrome) ||
	(StrContains(item, "shotgun_spas", false) == 7		&& count == limit_shotgun_spas) ||
	(StrContains(item, "smg_mp5", false) == 7			&& count == limit_smg_mp5) ||
	(StrContains(item, "smg_silenced", false) == 7		&& count == limit_smg_silenced) ||
	(StrContains(item, "sniper_awp", false) == 7		&& count == limit_sniper_awp) ||
	(StrContains(item, "sniper_military", false) == 7	&& count == limit_sniper_military) ||
	(StrContains(item, "sniper_scout", false) == 7		&& count == limit_sniper_scout))
	{
		if(AcceptEntityInput(entid, "Kill")) ResetUseCount(entid);
	}
}

int FindFirstEmptyCell()
{
	for(int i; i < table_size; i++)
	{
		if(ent_table[i][0] == -1) return i;
	}
	LogError("The table has run out of cell!");
	return -1;
}

int GetUseCount(const int entid)
{
	for(int i; i < table_size; i++)
	{
		if(ent_table[i][0] == entid) return ent_table[i][1];
	}
	return -1;
}

void SetUseCount(const int entid)
{
	for(int i; i < table_size; i++)
	{
		if(ent_table[i][0] == entid)
		{
			ent_table[i][1]++;
			if(bDebug) PrintToServer("	Used table cell: %i (value: %i)", i, ent_table[i][1]);
			break;
		}
	}
}

void ResetUseCount(const int entid)
{
	for(int i; i < table_size; i++)
	{
		if(ent_table[i][0] == entid)
		{
			ent_table[i][0] = ent_table[i][1] = -1;
			break;
		}
	}
}

void DeleteAllEntities(const char[] class)
{
	int ent = MaxClients;
	while ((ent = FindEntityByClassname(ent, class)) != INVALID_ENT_REFERENCE) 
	{
		AcceptEntityInput(ent, "Kill");
	}
}