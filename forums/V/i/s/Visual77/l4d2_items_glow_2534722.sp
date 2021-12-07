#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.2.5"

ConVar cvarIsEnabled;
ConVar cvarGlowRange;
ConVar cvarGlowOn_health;
ConVar cvarGlowOn_throwables;
ConVar cvarGlowOn_weapons;
ConVar cvarGlowOn_melee;
ConVar cvarGlowOn_M60_GL;
ConVar cvarGlowOnCrate_UP;
ConVar cvarGlowOn_footlocker;
ConVar cvarGlowOn_medcabinet;
ConVar cvarGlowOn_drop;

ConVar cvarGlowColor_health;
ConVar cvarGlowColor_throwables;
ConVar cvarGlowColor_weapons;
ConVar cvarGlowColor_melee;
ConVar cvarGlowColor_M60_GL;
ConVar cvarGlowColor_Crate_UP;
ConVar cvarGlowColor_footlocker;
ConVar cvarGlowColor_medcabinet;
ConVar survivorLimit;
ConVar gameMode;

int ROUNDSTART; 

Handle roundBegin = null;
Handle scavengeTimer = null;

bool scavengeMap;
bool delayScavenge;

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
	"weapon_cola_bottles" 
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
	"models/w_models/weapons/w_cola.mdl"
};

char footLocker[][] = { "models/props_waterfront/footlocker01.mdl" };
char medcabinet[][] = { "models/props_interiors/medicalcabinet02.mdl" };

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
	cvarGlowOn_throwables = CreateConVar("l4d2_items_glow_throw", "1", "Should we add glow to throwable items? 1 = Yes. 0 = No (Inlcuding cola)");
	cvarGlowOn_weapons = CreateConVar("l4d2_items_glow_weapons", "1", "Should we add glow to weapons? 1 = Yes. 0 = No");
	cvarGlowOn_melee = CreateConVar("l4d2_items_glow_melee", "1", "Should we add glow to melee weapons? 1 = Yes. 0 = No");
	cvarGlowOn_M60_GL = CreateConVar("l4d2_items_glow_m60_gl", "1", "Should we add glow to M60 and GL? 1 = Yes. 0 = No");
	cvarGlowOnCrate_UP = CreateConVar("l4d2_items_glow_crate_up", "1", "Should we add glow to upgradepacks and firework crate? 1 = Yes. 0 = No");
	cvarGlowOn_footlocker = CreateConVar("l4d2_items_glow_footlocker", "1", "Should we add glow to footlockers? 1 = Yes. 0 = No");
	cvarGlowOn_medcabinet = CreateConVar("l4d2_items_glow_medcabinet", "1", "Should we add glow to medical cabinets? 1 = Yes. 0 = No");
	cvarGlowOn_drop = CreateConVar("l4d2_items_glow_on_drop", "1", "Should we add back glow on dropped items?", FCVAR_NOTIFY);

	cvarGlowColor_health = CreateConVar("l4d2_items_glow_color_health", "0 255 0", "Glow color on health items. Green by defualt", FCVAR_NOTIFY);
	cvarGlowColor_throwables = CreateConVar("l4d2_items_glow_color_throw", "255 255 0", "Glow color on throwables. Yellow by defualt", FCVAR_NOTIFY);
	cvarGlowColor_weapons = CreateConVar("l4d2_items_glow_color_weapons", "255 0 0", "Glow color on weapons. Red by defualt", FCVAR_NOTIFY);
	cvarGlowColor_melee = CreateConVar("l4d2_items_glow_color_melee", "0 255 255", "Glow color on melee. Light blue by defualt", FCVAR_NOTIFY);
	cvarGlowColor_M60_GL = CreateConVar("l4d2_items_glow_color_m60_nade", "255 0 255", "Glow color on GL and M60. Purple by defualt", FCVAR_NOTIFY);
	cvarGlowColor_Crate_UP = CreateConVar("l4d2_items_glow_color_crate_up", "0 255 0", "Glow color on fire work crate and upgrade packs. Green by defualt", FCVAR_NOTIFY);
	cvarGlowColor_footlocker = CreateConVar("l4d2_items_glow_color_footlock", "0 255 0", "Glow color on footlockers. Green by defualt", FCVAR_NOTIFY);
	cvarGlowColor_medcabinet = CreateConVar("l4d2_items_glow_color_medcab", "0 255 0", "Glow color on medical cabinets. Green by defualt", FCVAR_NOTIFY);

	survivorLimit = FindConVar("survivor_limit");
	gameMode = FindConVar("mp_gamemode"); 

	HookEvent("round_start_pre_entity", Event_RoundStart);
	HookEvent("player_first_spawn", Event_PlayerSpawn);
	HookEvent("spawner_give_item", Event_GrabbedItem); 
	HookEvent("weapon_drop", Event_WeaponDrop);
	HookEvent("player_use", Event_PlayerUse);

	CreateConVar("l4d2_items_glow_version", PLUGIN_VERSION, "L4D2 Items Glow Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);

	AutoExecConfig(true, "l4d2_items_glow");
}

public void OnMapStart()
{ 
	scavengeMap = IsGasCanFinale() ? true : false;
	delayScavenge = false;

	char gamemode[32];
	gameMode.GetString(gamemode, sizeof(gamemode));

	if (StrContains(gamemode, "scavenge", false) != -1)
	{
		scavengeMap = true;
		delayScavenge = true;      //player_spawn fires 1 sec after map change to scavenge. this is too early for entity glow on cans?
	}

	roundBegin = null;
	scavengeTimer = null;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarIsEnabled.BoolValue) return;
	ROUNDSTART = 1; 
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarIsEnabled.BoolValue) return;

	if (ROUNDSTART == 1 && roundBegin == null) 
	{
		ROUNDSTART = 0;
		roundBegin = CreateTimer(1.0, hasEveryoneSpawned, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action hasEveryoneSpawned(Handle timer)
{
	if (!cvarIsEnabled.BoolValue) 
	{ 		
		roundBegin = null;
		return Plugin_Stop;
	}

	if (delayScavenge)
	{
		if (scavengeTimer == null)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) >= 2)
				{
					// Even here glow on gascans will fail. WTF valve.
					scavengeTimer = CreateTimer(10.0, delayScavengeStart, TIMER_FLAG_NO_MAPCHANGE); // Scavenge round start animation seems to take 10 seconds more or less
					break;
				}
			}
		}

		return Plugin_Continue;
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

		SetGlowOnProp(physicsThrow, sizeof(physicsThrow), "prop_physics", cvarGlowColor_throwables, 1);
		SetGlowOnProp(footLocker, sizeof(footLocker), "prop_dynamic", cvarGlowColor_footlocker, 3);
		SetGlowOnProp(medcabinet, sizeof(medcabinet), "prop_health_cabinet", cvarGlowColor_medcabinet, 2);

		return Plugin_Stop;
	} 
	return Plugin_Continue;
}

public Action delayScavengeStart(Handle timer)
{
	scavengeTimer = null;
	delayScavenge = false;
}

public Action Event_GrabbedItem(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarIsEnabled.BoolValue) return;
	
	int entity = event.GetInt("spawner");

	//if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;
	//char item[32];
	//GetEdictClassname(entity, item, sizeof(item));	

	if (GetEntProp(entity, Prop_Send, "m_iGlowType") > 0 && GetEntProp(entity, Prop_Data, "m_itemCount") <= 1) 
	{
		SetGlowItem(entity, 0, 0, 0);
		AcceptEntityInput(entity, "kill"); 
	}
}

public Action Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarIsEnabled.BoolValue || !cvarGlowOn_drop.BoolValue) return;

	int entity = event.GetInt("propid");
	//if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;

	char item[32];
	GetEdictClassname(entity, item, sizeof(item));
	int color = 0;

	if (cvarGlowOn_health.BoolValue && IsItTheWeapon(item, itemHealth, sizeof(itemHealth))) color = GetColor(cvarGlowColor_health); 
	if (cvarGlowOn_throwables.BoolValue && IsItTheWeapon(item, itemThrow, sizeof(itemThrow))) color = GetColor(cvarGlowColor_throwables);
	if (cvarGlowOn_weapons.BoolValue && IsItTheWeapon(item, itemWeapons, sizeof(itemWeapons))) color = GetColor(cvarGlowColor_weapons);
	if (cvarGlowOn_melee.BoolValue && IsItTheWeapon(item, itemMelee, sizeof(itemMelee))) color = GetColor(cvarGlowColor_melee);
	if (cvarGlowOn_M60_GL.BoolValue && IsItTheWeapon(item, itemM60_GL, sizeof(itemM60_GL))) color = GetColor(cvarGlowColor_M60_GL);
	if (cvarGlowOnCrate_UP.BoolValue && IsItTheWeapon(item, itemCrate_UP, sizeof(itemCrate_UP))) color = GetColor(cvarGlowColor_Crate_UP);

	if (color != 0)
	{
		if (scavengeMap && StrContains(item, "gascan", false) != -1)
		{
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", color); 
			return;
		}
		
		SetGlowItem(entity, color, 1, cvarGlowRange.IntValue);
	}
}

public Action Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarIsEnabled.BoolValue) return;

	int entity = event.GetInt("targetid");
	if (entity <= 0 || entity >= 2048 || !IsValidEntity(entity)) return;

	char buffer[32], netclass[32];

	GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
	GetEntityNetClass(entity, netclass, sizeof(netclass));

	if (cvarGlowOn_medcabinet.BoolValue && StrEqual(netclass, "CPropHealthCabinet", false))
	{
		SetGlowItem(entity, 0, 0, 0);

		if (cvarGlowOn_health.BoolValue) 
		{
			float cabPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", cabPos);

			DataPack data;
			CreateDataTimer(0.5, hCabinetOpend, data, TIMER_FLAG_NO_MAPCHANGE); 

			data.WriteFloat(cabPos[0]);
			data.WriteFloat(cabPos[1]);
			data.WriteFloat(cabPos[2]);
		}
	}

	if (cvarGlowOn_footlocker.BoolValue && StrContains(buffer, "button_locker", false) != -1)
	{
		float lockerPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", lockerPos);

		DataPack data;
		CreateDataTimer(0.5, footLockerOpend, data, TIMER_FLAG_NO_MAPCHANGE); 

		data.WriteFloat(lockerPos[0]);
		data.WriteFloat(lockerPos[1]);
		data.WriteFloat(lockerPos[2]);
	}
}

public Action hCabinetOpend(Handle timer, DataPack data)
{
	float cabPos[3], itemPos[3];

	data.Reset();
	cabPos[0] = data.ReadFloat();
	cabPos[1] = data.ReadFloat();
	cabPos[2] = data.ReadFloat();

	for (int i = 0; i < sizeof(itemHealth); i++)
	{
		int entity = -1;

		while ((entity = FindEntityByClassname(entity, itemHealth[i])) != -1)
		{	
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", itemPos);

			if (GetVectorDistance(cabPos, itemPos) < 150.0)
			{
				SetGlowItem(entity, GetColor(cvarGlowColor_health), 3, cvarGlowRange.IntValue);
			}
		}
	}
}

public Action footLockerOpend(Handle timer, DataPack data)
{
	char items[32], model[32]; float lockerPos[3], itemPos[3]; int ent = -1;

	data.Reset();
	lockerPos[0] = data.ReadFloat();
	lockerPos[1] = data.ReadFloat();
	lockerPos[2] = data.ReadFloat();

	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", itemPos);
		GetEntPropString(ent, Prop_Data, "m_iName", items, sizeof(items));

		if (GetVectorDistance(lockerPos, itemPos) < 150.0)
		{
			for (int i = 0; i < sizeof(footLocker); i++)
			{
				if (StrEqual(model, footLocker[i], false))
				{
					SetGlowItem(ent, 0, 0, 0); 
				}
			}

			if (cvarGlowOn_throwables.BoolValue)
			{
				if (StrContains(items, "molotov", false) != -1 
				|| StrContains(items, "pipebomb", false) != -1
				|| StrContains(items, "vomitjar", false) != -1)
				{
					SetGlowItem(ent, GetColor(cvarGlowColor_throwables), 3, cvarGlowRange.IntValue);
				}
			}

			if (cvarGlowOn_health.BoolValue) 
			{
				if (StrContains(items, "adrenaline", false) != -1 
				|| StrContains(items, "pills", false) != -1
				|| StrContains(items, "first_aid", false) != -1
				|| StrContains(items, "defibrillator", false) != -1)
				{
					SetGlowItem(ent, GetColor(cvarGlowColor_health), 3, cvarGlowRange.IntValue);
				}
			}
		}
	}
}

stock void SetGlowOnType(char [][] array, int size, ConVar cvar)
{
	if (cvar == cvarGlowColor_health && !cvarGlowOn_health.BoolValue) return;
	if (cvar == cvarGlowColor_throwables && !cvarGlowOn_throwables.BoolValue) return;
	if (cvar == cvarGlowColor_weapons && !cvarGlowOn_weapons.BoolValue) return;
	if (cvar == cvarGlowColor_melee && !cvarGlowOn_melee.BoolValue) return;
	if (cvar == cvarGlowColor_M60_GL && !cvarGlowOn_M60_GL.BoolValue) return;
	if (cvar == cvarGlowColor_Crate_UP && !cvarGlowOnCrate_UP.BoolValue) return;

	for (int i = 0; i < size; i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, array[i])) != -1)
		{	
			if (scavengeMap && StrContains(array[i], "gascan", false) != -1) 
			{
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor(cvar));
				continue;
			}
			
			SetGlowItem(entity, GetColor(cvar), 1, cvarGlowRange.IntValue);
		}
	}
}

stock void SetGlowOnProp(char [][] array, int size, const char[] propType, ConVar cvar, int glowtype)
{
	if (cvar == cvarGlowColor_throwables && !cvarGlowOn_throwables.BoolValue) return;
	if (cvar == cvarGlowColor_footlocker && !cvarGlowOn_footlocker.BoolValue) return;
	if (cvar == cvarGlowColor_medcabinet && !cvarGlowOn_medcabinet.BoolValue) return;

	char sModelName[256];
	int entity = -1;

	while ((entity = FindEntityByClassname(entity, propType)) != -1)
	{	
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		for (int i = 0; i < size; i++)
		{
			if (StrContains(sModelName, array[i], false) != -1)
			{
				if (scavengeMap && StrContains(sModelName, "gascan", false) != -1)
				{
					SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor(cvar));
					continue;
				}
				
				SetGlowItem(entity, GetColor(cvar), glowtype, cvarGlowRange.IntValue);
			}
		}
	}
}

stock void SetGlowItem(int entity, int color, int glowtype, int range)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
	SetEntProp(entity, Prop_Send, "m_iGlowType", glowtype);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
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
	
	if (StrEqual(map, "c1m4_atrium", false) || StrEqual(map, "c6m3_port", false))
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
