#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.1.6"

ConVar cvarIsEnabled;
ConVar cvarGlowRange;
ConVar cvarGlowOn_health;
ConVar cvarGlowOn_throwables;
ConVar cvarGlowOn_weapons;
ConVar cvarGlowOn_melee;
ConVar cvarGlowOn_M60_GL;
ConVar cvarGlowOnCrate_UP;
ConVar cvarGlowOn_drop;

ConVar cvarGlowColor_health;
ConVar cvarGlowColor_throwables;
ConVar cvarGlowColor_weapons;
ConVar cvarGlowColor_melee;
ConVar cvarGlowColor_M60_GL;
ConVar cvarGlowColor_Crate_UP;
ConVar survivorLimit;

int ROUNDSTART; 

Handle roundBegin = null;

char itemHealth[][] = 
{ 
	"weapon_pain_pills",
	"weapon_pain_pills_spawn",
	"weapon_first_aid_kit",
	"weapon_first_aid_kit_spawn",
 	"weapon_defibrillator",
	"weapon_defibrillator_spawn",
	"weapon_adrenaline",
	"weapon_adrenaline_spawn",
};

char itemThrow[][] = 
{ 
	"weapon_pipe_bomb", 
	"weapon_pipe_bomb_spawn", 
	"weapon_molotov",
	"weapon_molotov_spawn",
	"weapon_vomitjar",
	"weapon_vomitjar_spawn",
	"weapon_gascan",
	"weapon_gascan_spawn",
	"weapon_propanetank", 
	"weapon_propanetank_spawn", 
	"weapon_oxygentank_spawn",
	"weapon_oxygentank",
	"weapon_gnome",
	"weapon_cola"
};

char itemWeapons[][] = 
{  
	"weapon_autoshotgun",
	"weapon_autoshotgun_spawn", 
	"weapon_hunting_rifle",
	"weapon_hunting_rifle_spawn",
	"weapon_pistol_magnum",
	"weapon_pistol_magnum_spawn",
	"weapon_pistol",
	"weapon_pistol_spawn",
	"weapon_pumpshotgun",
	"weapon_pumpshotgun_spawn",
	"weapon_rifle_ak47",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_desert",
	"weapon_rifle_desert_spawn",
	"weapon_rifle",
	"weapon_rifle_spawn",
	"weapon_rifle_sg552", 
	"weapon_shotgun_chrome",
	"weapon_shotgun_chrome_spawn",
	"weapon_shotgun_spas",
	"weapon_shotgun_spas_spawn",
	"weapon_smg_silenced",
	"weapon_smg_silenced_spawn",
	"weapon_smg",
	"weapon_smg_spawn",
	"weapon_smg_mp5",
	"weapon_sniper_military",  
	"weapon_sniper_military_spawn",  
	"weapon_sniper_scout",  
	"weapon_sniper_awp", 
	"weapon_spawn" 
};

char itemMelee[][] =
{
	"weapon_melee",
	"weapon_melee_spawn",
	"weapon_chainsaw",
	"weapon_chainsaw_spawn"
};

char itemM60_GL[][] = 
{ 
	"weapon_grenade_launcher",
	"weapon_grenade_launcher_spawn",
	"weapon_rifle_m60",
	"weapon_rifle_m60_spawn"
};

char itemCrate_UP[][] =
{	
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_explosive_spawn",
	"weapon_upgradepack_incendiary",
	"weapon_upgradepack_incendiary_spawn",
	"weapon_fireworkcrate",
	"weapon_fireworkcrate_spawn"
};

char physicsThrow[][] =
{
	"models/props_equipment/oxygentank01.mdl",
	"models/props_junk/propanecanister001a.mdl",
	"models/props_junk/gascan001a.mdl", 
	"models/props_junk/gnome.mdl",
	"models/w_models/weapons/w_cola.mdl"
};

public Plugin myinfo = 
{
	name = "L4D2 Items Glow",
	author = "V1sual",
	description = "Puts glow around items based on cvars",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	cvarIsEnabled = CreateConVar("l4d2_items_glow_enable", "1", "1 Enables plugin, 0 Disables plugin", FCVAR_NOTIFY);
	cvarGlowRange = CreateConVar("l4d2_items_glow_range", "500", "The glow is visible to the player within this range", FCVAR_NOTIFY);
	cvarGlowOn_health = CreateConVar("l4d2_items_glow_health", "1", "Should we add glow to health items? 1 = Yes. 0 = No");
	cvarGlowOn_throwables = CreateConVar("l4d2_items_glow_throw", "1", "Should we add glow to throwable items? 1 = Yes. 0 = No (Inlcuding cola & gnome)");
	cvarGlowOn_weapons = CreateConVar("l4d2_items_glow_weapons", "1", "Should we add glow to weapons? 1 = Yes. 0 = No");
	cvarGlowOn_melee = CreateConVar("l4d2_items_glow_melee", "1", "Should we add glow to melee weapons? 1 = Yes. 0 = No");
	cvarGlowOn_M60_GL = CreateConVar("l4d2_items_glow_m60_gl", "1", "Should we add glow to M60 and GL? 1 = Yes. 0 = No");
	cvarGlowOnCrate_UP = CreateConVar("l4d2_items_glow_crate_up", "1", "Should we add glow to upgradepacks and firework crate? 1 = Yes. 0 = No");
	cvarGlowOn_drop = CreateConVar("l4d2_items_glow_on_drop", "1", "Should we add back glow on dropped items?", FCVAR_NOTIFY);

	cvarGlowColor_health = CreateConVar("l4d2_items_glow_color_health", "0 255 0", "Glow color on health items. Green by defualt", FCVAR_NOTIFY);
	cvarGlowColor_throwables = CreateConVar("l4d2_items_glow_color_throw", "255 255 0", "Glow color on throwables. Yellow by defualt", FCVAR_NOTIFY);
	cvarGlowColor_weapons = CreateConVar("l4d2_items_glow_color_weapons", "255 0 0", "Glow color on weapons. Red by defualt", FCVAR_NOTIFY);
	cvarGlowColor_melee = CreateConVar("l4d2_items_glow_color_melee", "0 255 255", "Glow color on melee. Light blue by defualt", FCVAR_NOTIFY);
	cvarGlowColor_M60_GL = CreateConVar("l4d2_items_glow_color_m60_nade", "255 0 255", "Glow color on GL and M60. Purple by defualt", FCVAR_NOTIFY);
	cvarGlowColor_Crate_UP = CreateConVar("l4d2_items_glow_color_crate_up", "0 255 0", "Glow color on fire work crate and upgrade packs. Green by defualt", FCVAR_NOTIFY);

	survivorLimit = FindConVar("survivor_limit");

	HookEvent("round_start_pre_entity", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("spawner_give_item", Event_GrabbedItem); 
	HookEvent("weapon_drop", Event_WeaponDrop);

	CreateConVar("l4d2_items_glow_version", PLUGIN_VERSION, "L4D2 Items Glow Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	AutoExecConfig(true, "l4d2_items_glow");
}

public void OnMapStart()
{ 
	roundBegin = null;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1) return;
	ROUNDSTART = 1; 
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1) return;

	if (ROUNDSTART == 1 && roundBegin == null) 
	{
		ROUNDSTART = 0;
		roundBegin = CreateTimer(1.0, hasEveryoneSpawned, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action hasEveryoneSpawned(Handle timer)
{
	if (cvarIsEnabled.IntValue != 1)
	{ 		
		roundBegin = null;
		return Plugin_Stop;
	}

	if (GetTotalSurvivors() >= survivorLimit.IntValue)
	{
		roundBegin = null;

		SetGlowOnType(itemHealth, sizeof(itemHealth), cvarGlowColor_health);
		SetGlowOnType(itemThrow, sizeof(itemThrow), cvarGlowColor_throwables);
		SetGlowOnType(itemWeapons, sizeof(itemWeapons), cvarGlowColor_weapons);
		SetGlowOnType(itemMelee, sizeof(itemMelee), cvarGlowColor_melee);
		SetGlowOnType(itemM60_GL, sizeof(itemM60_GL), cvarGlowColor_M60_GL);
		SetGlowOnType(itemCrate_UP, sizeof(itemCrate_UP), cvarGlowColor_Crate_UP);
		SetGlowOnProp(physicsThrow, sizeof(physicsThrow), "prop_physics", cvarGlowColor_throwables);
		
		return Plugin_Stop;
	} 
	return Plugin_Continue;
}

public Action Event_GrabbedItem(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1) return;
	if (cvarGlowOn_throwables.IntValue != 1) return;
	
	int entity = event.GetInt("spawner");
	if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;
	
	char item[32];
	GetEdictClassname(entity, item, sizeof(item));	

	if (StrContains(item, "_spawn", false) != -1)
	{
		DeleteGlow(entity);	
	}
}

public Action Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1 || cvarGlowOn_drop.IntValue != 1) return;

	int entity = event.GetInt("propid");
	if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;

	char item[32];
	GetEdictClassname(entity, item, sizeof(item));
	int color = 0;

	if (cvarGlowOn_health.IntValue == 1 && IsItTheWeapon(item, itemHealth, sizeof(itemHealth))) color = GetColor(cvarGlowColor_health); 
	if (cvarGlowOn_throwables.IntValue == 1 && IsItTheWeapon(item, itemThrow, sizeof(itemThrow))) color = GetColor(cvarGlowColor_throwables);
	if (cvarGlowOn_weapons.IntValue == 1 && IsItTheWeapon(item, itemWeapons, sizeof(itemWeapons))) color = GetColor(cvarGlowColor_weapons);
	if (cvarGlowOn_melee.IntValue == 1 && IsItTheWeapon(item, itemMelee, sizeof(itemMelee))) color = GetColor(cvarGlowColor_melee);
	if (cvarGlowOn_M60_GL.IntValue == 1 && IsItTheWeapon(item, itemM60_GL, sizeof(itemM60_GL))) color = GetColor(cvarGlowColor_M60_GL);
	if (cvarGlowOnCrate_UP.IntValue == 1 && IsItTheWeapon(item, itemCrate_UP, sizeof(itemCrate_UP))) color = GetColor(cvarGlowColor_Crate_UP);
	
	if (color != 0)
	{
		if (IsGasCanFinale() && StrContains(item, "gascan", false) != -1)
		{
			SetGlowItem(entity, color, 3); 
			return;
		}
		SetGlowItem(entity, color, 1);
	}
}

stock void SetGlowOnType(char [][] array, int size, ConVar cvar)
{
	if (cvar == cvarGlowColor_health && cvarGlowOn_health.IntValue != 1) return;
	if (cvar == cvarGlowColor_throwables && cvarGlowOn_throwables.IntValue != 1) return;
	if (cvar == cvarGlowColor_weapons && cvarGlowOn_weapons.IntValue != 1) return;
	if (cvar == cvarGlowColor_melee && cvarGlowOn_melee.IntValue != 1) return;
	if (cvar == cvarGlowColor_M60_GL && cvarGlowOn_M60_GL.IntValue != 1) return;
	if (cvar == cvarGlowColor_Crate_UP && cvarGlowOnCrate_UP.IntValue != 1) return;

	int color = GetColor(cvar);
	for (int i = 0; i < size; i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, array[i])) != -1)
		{	
			if (IsGasCanFinale() && StrContains(array[i], "gascan", false) != -1)
			{
				SetGlowItem(entity, color, 3); 
				continue;
			}

			SetGlowItem(entity, color, 1);
		}
	}
}

stock void SetGlowOnProp(char [][] array, int size, const char[] propType, ConVar cvar)
{
	if (cvar == cvarGlowColor_throwables && cvarGlowOn_throwables.IntValue != 1) return;

	int color = GetColor(cvar);
	char sModelName[256];
	int entity = -1;

	while ((entity = FindEntityByClassname(entity, propType)) != -1)
	{	
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		for (int i = 0; i < size; i++)
		{
			if (StrContains(sModelName, array[i], false) != -1)
			{
				if (IsGasCanFinale() && StrContains(sModelName, "gascan", false) != -1)
				{	
					SetGlowItem(entity, color, 3); 
					continue;
				}

				SetGlowItem(entity, color, 1);
			}
		}
	}
}

stock void SetGlowItem(int entity, int color, int glowtype)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", (glowtype == 3) ? 0 : cvarGlowRange.IntValue);
	SetEntProp(entity, Prop_Send, "m_iGlowType", glowtype);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
}

stock void DeleteGlow(int entity)
{
	if (GetEntProp(entity, Prop_Send, "m_iGlowType") > 0 
	&& GetEntProp(entity, Prop_Data, "m_itemCount") <= 1) 
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);

		AcceptEntityInput(entity, "kill"); 
	}
}

stock bool IsItTheWeapon(const char[] weapon, char[][] array, int size)
{
	for (int i = 0; i < size; i++)
	{
		if (StrEqual(array[i], weapon, false))
		{
			return true;
		}
	}
	return false;
}

/* Code from Silvers [L4D2] Charger Power - Objects Glow */
stock int GetColor(ConVar cvar) 
{
	char sTemp[12];
	cvar.GetString(sTemp, sizeof(sTemp));

	if (strcmp(sTemp, "") == 0)
	{
		return 0;
	}

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if (color != 3)
	{
		return 0;
	}

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

stock bool IsGasCanFinale()
{
	// gas cans should glow constant on these maps as they always were.

	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	if (StrEqual(map, "c1m4_atrium", false) || StrEqual(map, "c6m3_port", false) || StrEqual(map, "c7m3_port", false))
	{
		return true;
	}
	return false;
}

stock int GetTotalSurvivors()
{
	int survivors = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			survivors++;
		}
	}
	return survivors;
}
