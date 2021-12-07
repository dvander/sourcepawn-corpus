/*

Reverse Friendly-Fire (l4d_reverse_ff) by Mystik Spiral

This Left4Dead2 SourceMod plugin reverses friendly-fire... the attacker takes all of the damage and the victim takes none.
This forces players to be more precise with their shots... or they will spend a lot of time on the ground.

Although this plugin discourages griefers/team killers since they can only damage themselves and no one else, the first objective is to force players to improve their shooting tatics and aim. The second objective is to encourage new/inexperienced players to only join games with a difficulty that match their skillset, rather than trying to play at a difficulty above their ability and constantly incapping their teammates.

This plugin reverses damage from the grenade launcher, but does not otherwise reverse explosion damage. This plugin does not reverse molotov/gascan damage and I do not intend to add it, though I may make a separate plugin to handle molotov/gascan damage.

    Option to specify extra damage if attacker is using explosive/incendiary ammo. [reverseff_multiplier (default: 1.125 {12.5%})]
    Option to not reverse friendly-fire when attacker is an admin. [reverseff_immunity (default: true)]
    Option to reverse friendly-fire when victim is a bot. [reverseff_bot (default: false)]
    Option to specify maximum damage allowed per chapter before ban. [reverseff_maxdamage (default: 180)]
    Option to specify ban duration in minutes. [reverseff_banduration (default: 10)]
    Option to reverse friendly-fire when victim is incapacitated. [reverseff_incapped (default: false)]

Want to contribute code enhancements?
Create a pull request using this GitHub repository: https://github.com/Mystik-Spiral/l4d_reverse_ff

*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.6.test3"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar cvar_reverseff_enabled;
ConVar cvar_reverseff_immunity;
ConVar cvar_reverseff_multiplier;
ConVar cvar_reverseff_bot;
ConVar cvar_reverseff_maxdamage;
ConVar cvar_reverseff_banduration;
ConVar cvar_reverseff_incapped;

bool g_bCvarRffPluginEnabled;
bool g_bCvarAdminImmunity;
float g_fCvarDamageMultiplier;
bool g_bCvarReverseIfBot;
float g_fAccumDamage[MAXPLAYERS+1];
float g_fMaxAlwdDamage;
int g_iBanDuration;
bool g_bCvarReverseIfIncapped;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Reverse Friendly-Fire",
	author = "Mystic Spiral",
	description = "Team attacker takes friendly-fire damage, victim takes no damage.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2727641#post2727641"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if ( test == Engine_Left4Dead2 || test == Engine_Left4Dead )
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	CreateConVar("reverseff_version", PLUGIN_VERSION, "Reverse Friendly-Fire", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_reverseff_enabled = CreateConVar("reverseff_enabled", "1", "Enable this plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_reverseff_immunity = CreateConVar("reverseff_immunity", "1", "Admin immune to reversing FF", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_reverseff_multiplier = CreateConVar("reverseff_multiplier", "1.125", "Special ammo damage multiplier", CVAR_FLAGS, true, 1.0, true, 2.0);
	cvar_reverseff_bot = CreateConVar("reverseff_bot", "0", "Reverse FF if victim is bot", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_reverseff_maxdamage = CreateConVar("reverseff_maxdamage", "180", "Maximum damage allowed before kicking", CVAR_FLAGS, true, 0.0, true, 999.0);
	cvar_reverseff_banduration = CreateConVar("reverseff_banduration", "10", "Ban duration in minutes (0=permanent)", CVAR_FLAGS, true, 0.0, false);
	cvar_reverseff_incapped = CreateConVar("reverseff_incapped", "0", "Reverse FF if victim is incapped", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d_reverse_ff");
	
	GetCvars();
	
	cvar_reverseff_enabled.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_immunity.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_multiplier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_bot.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_maxdamage.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_banduration.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_incapped.AddChangeHook(action_ConVarChanged);
}

public int action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarRffPluginEnabled = cvar_reverseff_enabled.BoolValue;
	g_bCvarAdminImmunity = cvar_reverseff_immunity.BoolValue;
	g_fCvarDamageMultiplier = cvar_reverseff_multiplier.FloatValue;
	g_bCvarReverseIfBot = cvar_reverseff_bot.BoolValue;
	g_fMaxAlwdDamage = cvar_reverseff_maxdamage.FloatValue;
	g_iBanDuration = cvar_reverseff_banduration.IntValue;
	g_bCvarReverseIfIncapped = cvar_reverseff_incapped.BoolValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_fAccumDamage[client] = 0.0;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!g_bCvarRffPluginEnabled)
	{
		return Plugin_Continue;
	}
	//debug damage
	//PrintToServer("Vic: %i, Atk: %i, Inf: %i, Dam: %f, DamTyp: %i, Wpn: %i", victim, attacker, inflictor, damage, damagetype, weapon);
	//attacker and victim checks
	if (IsValidClientAndInGameAndSurvivor(attacker) && IsValidClientAndInGameAndSurvivor(victim) && victim != attacker)
	{
		char sInflictorClass[64];
		if (inflictor > MaxClients)
		{
			GetEdictClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
		}
		//is weapon grenade launcher
		bool bWeaponGL = IsWeaponGrenadeLauncher(sInflictorClass);
		//is weapon minigun
		bool bWeaponMG = IsWeaponMinigun(sInflictorClass);
		//debug weapon
		//PrintToServer("GL: %b, MG: %b, InfCls: %s, weapon: %i", bWeaponGL, bWeaponMG, sInflictorClass, weapon);
		//if weapon caused damage
		if (weapon > 0 || bWeaponGL || bWeaponMG)
		{
			//do not reverse friendly-fire for these three situations
			if (!((IsClientAdmin(attacker) && g_bCvarAdminImmunity == true) || (IsFakeClient(victim) && g_bCvarReverseIfBot == false) || (IsClientIncapped(victim) && g_bCvarReverseIfIncapped == false)))
			{
				//special ammo checks
				if (IsSpecialAmmo(weapon, attacker, inflictor, damagetype, bWeaponGL))
				{
					//damage * "reverseff_multiplier"
					damage *= g_fCvarDamageMultiplier;
				}
				//accumulate damage total for attacker
				g_fAccumDamage[attacker] += damage;
				//debug acculated damage
				PrintToServer("Atk: %N, Dmg: %f, AcmDmg: %f, MaxDmg: %f", attacker, damage, g_fAccumDamage[attacker], g_fMaxAlwdDamage);
				//does accumulated damage exceed "reverseff_maxdamage"
				if (g_fAccumDamage[attacker] > g_fMaxAlwdDamage)
				{
					//ban attacker for "reverseff_banduration"
					BanClient(attacker, g_iBanDuration, BANFLAG_AUTO, "ExcessiveFF", "Excessive Friendly-Fire", _, attacker);
					//reset accumulated damage
					g_fAccumDamage[attacker] = 0.0;
					//do not inflict damage since player was banned
					return Plugin_Handled;
				}
				//inflict damage to attacker
				SDKHooks_TakeDamage(attacker, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);
			}
			//no damage for victim
			return Plugin_Handled;
		}
	}
	//all other damage behaves normal
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}

stock bool IsWeaponGrenadeLauncher(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "grenade_launcher_projectile"));
}

stock bool IsWeaponMinigun(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "prop_minigun") || StrEqual(sInflictorClass, "prop_minigun_l4d1") || StrEqual(sInflictorClass, "prop_mounted_machine_gun"));
}

stock bool IsSpecialAmmo(int weapon, int attacker, int inflictor, int damagetype, bool bWeaponGL)
{
	//damage from gun with special ammo
	if ((weapon > 0 && attacker == inflictor) && (damagetype & DMG_BURN || damagetype & DMG_BLAST))
	{
		return true;
	}
	//damage from grenade launcher with incendiary ammo
	if ((bWeaponGL) && (damagetype & DMG_BURN))
	{
		return true;
	}
	//damage from melee weapon or weapon with regular ammo
	return false;
}

stock bool IsClientAdmin(int client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}

stock bool IsValidClientAndInGameAndSurvivor(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsClientIncapped(int client)
{
	//convert integer to boolean for return value
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}