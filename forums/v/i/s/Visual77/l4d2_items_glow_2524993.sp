#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.1.0"

ConVar cvarGlowColor_health;
ConVar cvarGlowColor_throwables;
ConVar cvarGlowColor_weapons;
ConVar cvarGlowColor_melee;
ConVar cvarGlowColor_M60_GL;

ConVar cvarIsEnabled;
ConVar cvarGlowRange;
ConVar cvarAddGlowOnDrop;

char itemHealth[][] = 
{ 
	"weapon_pain_pills_spawn",
	"weapon_first_aid_kit_spawn", 
	"weapon_defibrillator_spawn",
	"weapon_adrenaline_spawn",
	"weapon_upgradepack_explosive_spawn",
	"weapon_upgradepack_incendiary_spawn",
	"weapon_fireworkcrate_spawn"
};

char itemThrow[][] = 
{ 
	"weapon_pipe_bomb_spawn", 
	"weapon_molotov_spawn",
	"weapon_vomitjar_spawn",
	"weapon_gascan_spawn",
	"weapon_propanetank_spawn", 
	"weapon_oxygentank_spawn"
};

char itemWeapons[][] = 
{  
	"weapon_autoshotgun_spawn", 
	"weapon_chainsaw_spawn",
	"weapon_hunting_rifle_spawn",
	"weapon_pistol_magnum_spawn",
	"weapon_pistol_spawn",
	"weapon_pumpshotgun_spawn",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_desert_spawn",
	"weapon_rifle_spawn",
	"weapon_rifle_sg552", 
	"weapon_shotgun_chrome_spawn",
	"weapon_shotgun_spas_spawn",
	"weapon_smg_silenced_spawn",
	"weapon_smg_spawn",
	"weapon_sniper_military_spawn",  
	"weapon_spawn",
	"weapon_sniper_scout",       
	"weapon_smg_mp5",
	"weapon_sniper_awp" 
};

char itemMelee[][] =
{
	"weapon_melee",
	"weapon_melee_spawn"
};

char itemM60_GL[][] = 
{ 
	"weapon_grenade_launcher_spawn",
	"weapon_rifle_m60_spawn"
};

public Plugin myinfo = 
{
	name = "L4D2 Items Glow",
	author = "V1sual",
	description = "Puts glow around items based on cvars",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	cvarIsEnabled = CreateConVar("l4d2_items_glow_enable", "1", "1 Enables plugin, 0 Disables plugin", FCVAR_NOTIFY);
	cvarGlowRange = CreateConVar("l4d2_items_glow_range", "500", "The glow is visible to the player within this range", FCVAR_NOTIFY);
	cvarAddGlowOnDrop = CreateConVar("l4d2_items_glow_on_drop", "1", "Should we add back glow on dropped items?", FCVAR_NOTIFY);
	cvarGlowColor_health = CreateConVar("l4d2_items_glow_color_health", "0 255 0", "Glow color on health items. Green by defualt");
	cvarGlowColor_throwables = CreateConVar("l4d2_items_glow_color_throw", "255 255 0", "Glow color on throwables. Yellow by defualt");
	cvarGlowColor_weapons = CreateConVar("l4d2_items_glow_color_weapons", "255 0 0", "Glow color on weapons. Red by defualt");
	cvarGlowColor_melee = CreateConVar("l4d2_items_glow_color_melee", "0 255 255", "Glow color on melee. Light blue by defualt");
	cvarGlowColor_M60_GL = CreateConVar("l4d2_items_glow_color_m60_nade", "255 0 255", "Glow color on GL and M60. Purple by defualt");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("spawner_give_item", Event_GrabbedItem); 
	HookEvent("weapon_drop", Event_WeaponDrop);

	CreateConVar("l4d2_items_glow_version", PLUGIN_VERSION, "L4D2 Items Glow Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	AutoExecConfig(true, "l4d2_items_glow");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1) return;

	SetGlowOnType(itemHealth, sizeof(itemHealth), cvarGlowColor_health);
	SetGlowOnType(itemThrow, sizeof(itemThrow), cvarGlowColor_throwables);
	SetGlowOnType(itemWeapons, sizeof(itemWeapons), cvarGlowColor_weapons);
	SetGlowOnType(itemMelee, sizeof(itemMelee), cvarGlowColor_melee);
	SetGlowOnType(itemM60_GL, sizeof(itemM60_GL), cvarGlowColor_M60_GL);
}

public Action Event_GrabbedItem(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1) return;
	
	int entity = event.GetInt("spawner");
	if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;
	
	char item[32];
	GetEdictClassname(entity, item, sizeof(item));	

	if (StrEqual(item, "weapon_pipe_bomb_spawn", false) 
	|| StrEqual(item, "weapon_molotov_spawn", false)
	|| StrEqual(item, "weapon_vomitjar_spawn", false))
	{
		DeleteGlow(entity, cvarGlowColor_throwables);	
	}
}

public Action Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1 || cvarAddGlowOnDrop.IntValue != 1) return;

	int entity = event.GetInt("propid");
	if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;

	char item[32];
	GetEdictClassname(entity, item, sizeof(item));
	int color = 0;

	if (IsItTheWeapon(item, itemHealth, sizeof(itemHealth))) color = GetColor(cvarGlowColor_health); 
	if (IsItTheWeapon(item, itemThrow, sizeof(itemThrow))) color = GetColor(cvarGlowColor_throwables);
	if (IsItTheWeapon(item, itemWeapons, sizeof(itemWeapons))) color = GetColor(cvarGlowColor_weapons);
	if (IsItTheWeapon(item, itemMelee, sizeof(itemMelee))) color = GetColor(cvarGlowColor_melee);
	if (IsItTheWeapon(item, itemM60_GL, sizeof(itemM60_GL))) color = GetColor(cvarGlowColor_M60_GL);

	if (color != 0)
	{
		SetGlowItem(entity, color);
	}
}

stock void SetGlowOnType(char [][] array, int size, ConVar cvar)
{
	int color = GetColor(cvar);
	for (int i = 0; i < size; i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, array[i])) != -1)
		{	
			SetGlowItem(entity, color);
		}
	}
}

stock void SetGlowItem(int entity, int color)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", cvarGlowRange.IntValue);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 1);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
}

stock void DeleteGlow(int entity, ConVar cvar)
{
	if (GetEntProp(entity, Prop_Send, "m_iGlowType") > 0 
	&& GetEntProp(entity, Prop_Send, "m_glowColorOverride") == GetColor(cvar))
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);

		if (GetEntProp(entity, Prop_Data, "m_itemCount") == 1) 
		{
			AcceptEntityInput(entity, "kill");
		}
	}
}

stock bool IsItTheWeapon(const char[] weapon, char[][] array, int size)
{
	for (int i = 0; i < size; i++)
	{
		if (StrContains(array[i], weapon, false) != -1) 
		{
			if (StrEqual(array[i], "weapon_rifle_m60_spawn") && StrEqual(weapon, "weapon_rifle")) return false;
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