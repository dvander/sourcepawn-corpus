#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "[L4D2] Realism Penetration Fix"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar difficulty, gamemode, cvarEnable, cvarNerfMagnum,
	cvarBuffSniper, cvarSniperLimit, cvarMagnumLimit;

int g_iEnabled, g_iNerfMagnum, g_iBuffSniper, g_iMagnumPenetrationLimit,
	g_iSniperPenetrationLimit, g_iCurrentPenetrationCount[MAXPLAYERS+1];

float g_fDifficultyMultiplier;
bool g_bRealism;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "dcx2, cravenge",
	description = "Fixes Realism Weapons Penetrations By Buffing Snipers And Nerfing Magnum.",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

public void OnPluginStart()
{
	char game[32];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("[FIX] Plugin Supports L4D2 Only!");
	}
	
	cvarEnable = CreateConVar("rpf-l4d2_enable", "1", "Enable/Disable Plugin", CVAR_FLAGS);
	cvarNerfMagnum = CreateConVar("rpf-l4d2_nerfmagnum", "1", "Magnum Penetration Bonus: 0=Full, 1=Half, 2=None Without Distance Damage Penalty, 3=None With Distance Damage Penalty", CVAR_FLAGS);
	cvarBuffSniper = CreateConVar("rpf-l4d2_buffsniper", "1", "Sniper Penetration Bonus: 0=Full, 1=Half, 2=None Without Distance Damage Penalty, 3=None With Distance Damage Penalty", CVAR_FLAGS);
	cvarMagnumLimit = CreateConVar("rpf-l4d2_magnumlimit", "0", "Number Of Enemies One Magnum Bullet Kills", CVAR_FLAGS);
	cvarSniperLimit = CreateConVar("rpf-l4d2_sniperlimit", "0", "Number Of Enemies One Sniper Bullet Kills", CVAR_FLAGS);
	CreateConVar("rpf-l4d2_version", PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "rpf-l4d2");
	
	HookConVarChange(cvarEnable, OnPluginCVarsModified);
	HookConVarChange(cvarNerfMagnum, OnPluginCVarsModified);
	HookConVarChange(cvarBuffSniper, OnPluginCVarsModified);
	HookConVarChange(cvarMagnumLimit, OnPluginCVarsModified);
	HookConVarChange(cvarSniperLimit, OnPluginCVarsModified);
	
	g_iEnabled = cvarEnable.IntValue;
	g_iNerfMagnum = cvarNerfMagnum.IntValue;
	g_iBuffSniper = cvarBuffSniper.IntValue;
	g_iMagnumPenetrationLimit = cvarMagnumLimit.IntValue;
	g_iSniperPenetrationLimit = cvarSniperLimit.IntValue;
	
	HookEvent("weapon_reload", OnWeaponReload);
	
	difficulty = FindConVar("z_difficulty");
	HookConVarChange(difficulty, OnDifficultyChanged);
	
	char difficultyString[32];
	difficulty.GetString(difficultyString, sizeof(difficultyString));
	g_fDifficultyMultiplier = GetDifficultyMultiplier(difficultyString);
	
	gamemode = FindConVar("mp_gamemode");
	
	char gamemodeString[32];
	gamemode.GetString(gamemodeString, sizeof(gamemodeString));
	g_bRealism = StrContains(gamemodeString, "realism", false) != -1;
}

public void OnDifficultyChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_fDifficultyMultiplier = GetDifficultyMultiplier(newValue);
}

float GetDifficultyMultiplier(const char[] Difficulty)
{
	float ret;
	if (StrEqual(Difficulty, "impossible", false))
	{
		ret = FindConVar("z_non_head_damage_factor_expert").FloatValue;
	}
	else if (StrEqual(Difficulty, "hard", false))
	{
		ret = (g_bRealism) ? FindConVar("z_non_head_damage_factor_expert").FloatValue : FindConVar("z_non_head_damage_factor_hard").FloatValue;
	}
	else if (StrEqual(Difficulty, "normal", false))
	{
		ret = (!g_bRealism) ? FindConVar("z_non_head_damage_factor_normal").FloatValue : FindConVar("z_non_head_damage_factor_hard").FloatValue;
	}
	else if (StrEqual(Difficulty, "easy", false))
	{
		ret = (g_bRealism) ? FindConVar("z_non_head_damage_factor_normal").FloatValue : FindConVar("z_non_head_damage_factor_easy").FloatValue;
	}
	ret *= FindConVar("z_non_head_damage_factor_multiplier").FloatValue;
	return ret;
}

public void OnPluginCVarsModified(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iEnabled = StringToInt(newVal);
	g_iNerfMagnum = StringToInt(newVal);
	g_iBuffSniper = StringToInt(newVal);
	g_iMagnumPenetrationLimit = StringToInt(newVal);
	g_iSniperPenetrationLimit = StringToInt(newVal);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= 0 || entity > 2048)
	{
		return;
	}
	
	if (StrEqual(classname, "infected"))
	{
		SDKHook(entity, SDKHook_SpawnPost, RPF_SpawnPost);
	}
}

public void RPF_SpawnPost(int entity)
{
	SDKHook(entity, SDKHook_TraceAttack, RPFTraceAttack);
	SDKHook(entity, SDKHook_OnTakeDamage, RPFOnTakeDamage);
}

float lastTraceAttackDamage;
public Action RPFTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	lastTraceAttackDamage = damage;
	return Plugin_Continue;
}

public Action RPFOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	bool changed, bModeEnabled = (g_iEnabled == 2) || (g_iEnabled == 1 && g_bRealism);
	
	if (bModeEnabled && IsSurvivor(attacker) && IsPlayerAlive(attacker))
	{
		g_iCurrentPenetrationCount[attacker] += 1;
		
		char weaponName[32];
		if (weapon > 0 && IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		}
		
		if (!(damagetype & 0x40000000))
		{
			if (StrEqual(weaponName, "weapon_pistol_magnum"))
			{
				switch (g_iNerfMagnum)
				{
					case 0:
					{
						if (g_iCurrentPenetrationCount[attacker] < g_iMagnumPenetrationLimit)
						{
							return Plugin_Handled;
						}
					}
					case 1:
					{
						damage /= 2.0;
						changed = true;
					}
					case 2:
					{
						damage = g_fDifficultyMultiplier * 78.0;
						changed = true;
					}
					case 3:
					{
						damage = g_fDifficultyMultiplier * lastTraceAttackDamage;
						changed = true;
					}
				}
			}
			else if (((!g_bRealism && g_iBuffSniper < 2) || (g_bRealism && g_iBuffSniper > 0)) && (StrEqual(weaponName, "weapon_hunting_rifle") || StrEqual(weaponName, "weapon_sniper_military")))
			{
				float maxHealth = float(GetEntProp(victim, Prop_Data, "m_iMaxHealth"));
				if (isFallenSurvivor(victim))
				{
					maxHealth /= 2.0;
				}
				
				float newDamage = damage;
				
				if (g_bRealism)
				{
					switch (g_iBuffSniper)
					{
						case 0:
						{
							if (g_iCurrentPenetrationCount[attacker] < g_iSniperPenetrationLimit)
							{
								return Plugin_Handled;
							}
						}
						case 1: newDamage = maxHealth / 2.0;
						case 2,3: newDamage = maxHealth;
					}
					
					if (newDamage > damage)
					{
						damage = newDamage;
					}
					changed = true;
				}
				else
				{
					switch (g_iBuffSniper)
					{
						case 0:
						{
							if (g_iCurrentPenetrationCount[attacker] < g_iSniperPenetrationLimit)
							{
								return Plugin_Handled;
							}
						}
						case 1: damage *= g_fDifficultyMultiplier;
						case 2,3: newDamage = maxHealth / 2.0;
					}
					
					if (newDamage < damage)
					{
						damage = newDamage;
					}
					changed = true;
				}
			}
		}
	}
	
	if (changed)
	{
		return Plugin_Changed;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action OnWeaponReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_iCurrentPenetrationCount[client] = 0;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool isFallenSurvivor(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEdict(entity))
	{
		return false;
	}
	
	char model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "fallen") != -1;
}


