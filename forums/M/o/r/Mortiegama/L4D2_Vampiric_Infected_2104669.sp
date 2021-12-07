#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Vampiric Infected
#define PLUGIN_VERSION "1.0"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8
#define STRING_LENGHT 56

static const String:BOOMER_WEAPON[] = "weapon_boomer_claw";
static const String:CHARGER_WEAPON[] = "weapon_charger_claw";
static const String:HUNTER_WEAPON[] = "weapon_hunter_claw";
static const String:JOCKEY_WEAPON[] = "weapon_jockey_claw";
static const String:SMOKER_WEAPON[] = "weapon_smoker_claw";
static const String:SPITTER_WEAPON[] = "weapon_spitter_claw";

new Handle:cvarVampiricCommon;
new Handle:cvarVampiricCommonAmount;
new Handle:cvarVampiricCommonCooldown;
new Handle:cvarVampiricCommonReduction;
new Handle:PluginStartTimer = INVALID_HANDLE;

new bool:isVampiricCommon;

new Float:cooldownVampiricCommon[MAXPLAYERS+1] = 0.0;

new BoomerHealth;
new ChargerHealth;
new HunterHealth;
new JockeyHealth;
new SmokerHealth;
new SpitterHealth;
new iHPRegen;
new iMaxHP;

public Plugin:myinfo = 
{
    name = "[L4D2] Vampiric Infected",
    author = "Mortiegama",
    description = "Allows for special infected to regenerate health by attacking.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2104669#post2104669"
}

public OnPluginStart()
{
	CreateConVar("l4d_vim_version", PLUGIN_VERSION, "Destructive Hunter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarVampiricCommon = CreateConVar("l4d_vim_vampiriccommon", "1", "Enables the ability for Special Infected to attack common infected to regain health. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarVampiricCommonAmount  = CreateConVar("l4d_vim_vampiriccommonamount", "5", "Amount of HP the Special Infected will receive each time it attacks a common infected. (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarVampiricCommonCooldown  = CreateConVar("l4d_vim_vampiriccommoncooldown", "0.5", "Cooldown period between vampiric hits. (Def 0.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarVampiricCommonReduction  = CreateConVar("l4d_vim_vampiriccommonreduction", "0.3", "Percent to reduce damage done to common infected while feeding. (Def 0.3)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	AutoExecConfig(true, "plugin.L4D2.VampiricInfected");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarVampiricCommon))
	{
		isVampiricCommon = true;
	}
	
	BoomerHealth = GetConVarInt(FindConVar("z_exploding_health"));		
	ChargerHealth = GetConVarInt(FindConVar("z_charger_health"));		
	HunterHealth = GetConVarInt(FindConVar("z_hunter_health"));		
	JockeyHealth = GetConVarInt(FindConVar("z_jockey_health"));		
	SmokerHealth = GetConVarInt(FindConVar("z_gas_health"));		
	SpitterHealth = GetConVarInt(FindConVar("z_spitter_health"));		
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "infected", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidClient(attacker) && GetClientTeam(attacker) == 3 && IsVampiricCommonReady(attacker))
	{
		if (isVampiricCommon && IsValidEdict(victim))
		{
			new Float:damagemod = GetConVarFloat(cvarVampiricCommonReduction);
			
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
			
			new class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
			new iHP = GetClientHealth(attacker);
			
			switch (class)  
			{	
			case ZOMBIECLASS_BOOMER:
				{
				iMaxHP = BoomerHealth;
				}

			case ZOMBIECLASS_CHARGER:
				{
				iMaxHP = ChargerHealth;
				}

			case ZOMBIECLASS_JOCKEY:
				{
				iMaxHP = JockeyHealth;
				}

			case ZOMBIECLASS_HUNTER:
				{
				iMaxHP = HunterHealth;
				}

			case ZOMBIECLASS_SMOKER:
				{
				iMaxHP = SmokerHealth;
				}

			case ZOMBIECLASS_SPITTER:
				{
				iMaxHP = SpitterHealth;
				}
			}

			iHPRegen = GetConVarInt(cvarVampiricCommonAmount);
			
			if ((iHPRegen + iHP) <= iMaxHP)
			{
				SetEntProp(attacker, Prop_Send, "m_iHealth", iHPRegen + iHP, 1);
			}
			else if ((iHP < iMaxHP) && (iMaxHP < (iHPRegen + iHP)) )
			{
				SetEntProp(attacker, Prop_Send, "m_iHealth", iMaxHP, 1);
			}
			
			cooldownVampiricCommon[attacker] = GetEngineTime();
		}
	}
	
	return Plugin_Changed;
}

public IsValidClient(client)
{
	if (client <= 0)
		return false;
		
	if (client > MaxClients)
		return false;
		
	if (!IsClientInGame(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	return true;
}

public IsVampiricCommonReady(client)
{
	return ((GetEngineTime() - cooldownVampiricCommon[client]) > GetConVarFloat(cvarVampiricCommonCooldown));
}