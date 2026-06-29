#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

ConVar cvarIsEnabled;
ConVar cvarGlowColor;
ConVar cvarGlowRange;

char GlowItems[][] = 
{ 
	"weapon_first_aid_kit_spawn", 
	"weapon_pain_pills_spawn",
	"weapon_defibrillator_spawn",
	"weapon_adrenaline_spawn",
	"weapon_molotov_spawn",
	"weapon_pipe_bomb_spawn", 
	"weapon_vomitjar_spawn",
	"weapon_gascan_spawn",
	"weapon_propanetank_spawn", 
	"weapon_oxygentank_spawn",
	"weapon_melee_spawn",
	"weapon_upgradepack_explosive_spawn",
	"weapon_upgradepack_incendiary_spawn",
	"weapon_fireworkcrate_spawn",
};

public Plugin myinfo = 
{
	name = "L4D2 Items Glow",
	author = "V1sual",
	description = "Puts glow around items. Green glow by defualt",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	cvarIsEnabled = CreateConVar("l4d2_items_glow_enable",  "1", "1 Enables plugin, 0 Disables plugin", FCVAR_NOTIFY);
	cvarGlowColor = CreateConVar("l4d2_items_glow_color", "0 255 0", "RGB Glow Colour. Green by defualt", FCVAR_NOTIFY);
	cvarGlowRange = CreateConVar("l4d2_items_glow_range",  "250", "The glow is visible to the player within this range", FCVAR_NOTIFY);
	
	CreateConVar("l4d2_items_glow_version", PLUGIN_VERSION, "L4D2 Items Glow Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("round_start", Event_RoundStart);

	AutoExecConfig(true, "l4d2_glow_items");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarIsEnabled.IntValue != 1) return;

	for (int i = 0; i < sizeof(GlowItems); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, GlowItems[i])) != -1)
		{	
			SetGlowItem(entity);   
		}
	}
}

stock void SetGlowItem(int entity)
{
	int color = GetColor(cvarGlowColor);

	SetEntProp(entity, Prop_Send, "m_nGlowRange", cvarGlowRange.IntValue);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
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