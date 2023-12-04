#pragma semicolon 1

#include <sdkhooks>

static const char
	PL_NAME[]	= "Weapon damage modifier",
	PL_VER[]	= "1.0.0_28.08.2022";

static const int DMG_HEADSHOT = (1 << 30);

KeyValues
	kvWpn;
bool
	bLate,
	bEnable,
	bFF;
int
	iDmg[MAXPLAYERS+1],
	iHs[MAXPLAYERS+1];
float
	fMult[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Changes weapon damage depending on settings",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_weapon_dmg_mod_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_weapon_dmg_mod_enable", "1", "Enables/Disables plugin", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_weapon_dmg_mod_ff", "0", "Enables/Disables friendly fire modification", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange);
	bFF = cvar.BoolValue;

	AutoExecConfig(true, "weapon_dmg_mod");
}

public void CVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;

	if(bEnable)
	{
		bLate = true;
		OnMapStart();
	}
	else
	{
		if(kvWpn) delete kvWpn;
		for(int i = 1; i < MaxClients; ++i) if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_WeaponSwitchPost, CheckWeapon);
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnMapStart()
{
	if(kvWpn) delete kvWpn;
	kvWpn = CreateKeyValues("Weapons");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/weapon_dmg_mod.ini");
	if(!kvWpn.ImportFromFile(path) || !kvWpn.GotoFirstSubKey()) delete kvWpn;
	else
	{
		bool valid;
		int num;
		do
		{
			if((valid = kvWpn.GetNum("damage", -1) != -1 || kvWpn.GetNum("headshot", -1) != -1
			|| kvWpn.GetFloat("multiplier", 0.0) != 0.0))
				num ++;
			kvWpn.GoBack();
			if(!valid) kvWpn.DeleteThis();
		} while(kvWpn.GotoNextKey());

		if(!num) delete kvWpn;
	}

	if(!bLate) return;

	bLate = false;

	for(int i = 1; i < MaxClients; ++i) if(IsClientInGame(i))
	{
		HookPlayerEvents(i);
		CheckWeapon(i, GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon"));
	}
}

public void OnClientPutInServer(int client)
{
	if(bEnable && kvWpn) HookPlayerEvents(client);
}

stock void HookPlayerEvents(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, CheckWeapon);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(!attacker || attacker == victim || attacker > MaxClients || !IsClientInGame(attacker)
	|| !bFF && GetClientTeam(victim) == GetClientTeam(attacker))
		return Plugin_Continue;

	if(fMult[attacker] != 0.0)
		damage *= fMult[attacker];
	else if(damagetype & DMG_HEADSHOT && iHs[attacker] != -1)
		damage = iHs[attacker] + 0.0;
	else if(iDmg[attacker] != -1)
		damage = iDmg[attacker] + 0.0;
	else return Plugin_Continue;

	return Plugin_Changed;
}

public void CheckWeapon(int client, int weapon)
{
	iDmg[client] = iHs[client] = -1;
	fMult[client] = 0.0;

	static char class[32];
	if(!bEnable || !kvWpn || weapon == -1 || !GetEntityClassname(weapon, class, sizeof(class)))
		return;

	kvWpn.Rewind();
	if(!kvWpn.JumpToKey(class)) return;

	iDmg[client]	= kvWpn.GetNum("damage", -1);
	iHs[client]		= kvWpn.GetNum("headshot", -1);
	fMult[client]	= kvWpn.GetFloat("multiplier", 0.0);
}