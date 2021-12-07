// TF2 Force Holidays
// Copyright 2011-2012 Ross Bemrose (Powerlord)
// Like All SourceMod Plugins, this code is licensed under the GPLv2

#define VERSION "1.7.0"
#define MAPLENGTH 65
#define UPDATE_URL "http://www.rbemrose.com/sourcemod/tfforceholidays/updatefile.txt"

#include <sourcemod>
#include <tf2>

#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1

new Handle:g_Cvar_Enabled		= INVALID_HANDLE;
new Handle:g_Cvar_Halloween		= INVALID_HANDLE;
new Handle:g_Cvar_Birthday		= INVALID_HANDLE;
new Handle:g_Cvar_Winter		= INVALID_HANDLE;
new Handle:g_Cvar_MeetThePyro	= INVALID_HANDLE;
new Handle:g_Cvar_MannVsMachine	= INVALID_HANDLE;

new Handle:g_Maplist = INVALID_HANDLE;
new g_Maplist_Serial = -1;

public Plugin:myinfo = 
{
	name = "TF Force Holidays",
	author = "Powerlord",
	description = "Enable multiple holidays at once",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=171012"
}

public OnPluginStart()
{
	CreateConVar("tfh_version", VERSION, "TF Force Holidays version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	
	g_Cvar_Enabled   = CreateConVar("tfh_enabled", "1", "Enable TF Force Holidays", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Halloween = CreateConVar("tfh_halloween", "0", "Force Halloween mode: -1: Always off, 0: Use game setting, 1: Halloween, 2: Full Moon", FCVAR_NOTIFY, true, -1.0, true, 2.0);
	g_Cvar_Birthday  = CreateConVar("tfh_birthday", "0", "Force Birthday mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Winter    = CreateConVar("tfh_winter", "0", "Force Winter mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_MeetThePyro = CreateConVar("tfh_meetthepyro", "0", "Force Meet The Pyro mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_MannVsMachine = CreateConVar("tfh_mannvsmachine", "0", "Force Mann Vs. Machine holiday mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	
	g_Maplist = CreateArray(ByteCountToCells(MAPLENGTH));

	// Bind the map list file to the "halloween" map list
	decl String:mapListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mapListPath, sizeof(mapListPath), "configs/halloween_maps.txt");
	SetMapListCompatBind("halloween", mapListPath);

	LoadMapList();
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

LoadMapList()
{
	if (ReadMapList(g_Maplist,
	g_Maplist_Serial,
	"halloween",
	MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT)
	!= INVALID_HANDLE)
	{
		LogMessage("Loaded/Updated Halloween map list");
	}
}

public OnMapStart()
{
	decl String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	
	// Precache sounds and models for Halloween bosses
	if (StrEqual("cp_manor_event", mapname, false))
	{
		PrecacheModel("models/bots/headless_hatman.mdl", true); 
		PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
		PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
		PrecacheSound("vo/halloween_boss/knight_alert.wav", true);
		PrecacheSound("vo/halloween_boss/knight_alert01.wav", true);
		PrecacheSound("vo/halloween_boss/knight_alert02.wav", true);
		PrecacheSound("vo/halloween_boss/knight_attack01.wav", true);
		PrecacheSound("vo/halloween_boss/knight_attack02.wav", true);
		PrecacheSound("vo/halloween_boss/knight_attack03.wav", true);
		PrecacheSound("vo/halloween_boss/knight_attack04.wav", true);
		PrecacheSound("vo/halloween_boss/knight_death01.wav", true);
		PrecacheSound("vo/halloween_boss/knight_death02.wav", true);
		PrecacheSound("vo/halloween_boss/knight_dying.wav", true);
		PrecacheSound("vo/halloween_boss/knight_laugh01.wav", true);
		PrecacheSound("vo/halloween_boss/knight_laugh02.wav", true);
		PrecacheSound("vo/halloween_boss/knight_laugh03.wav", true);
		PrecacheSound("vo/halloween_boss/knight_laugh04.wav", true);
		PrecacheSound("vo/halloween_boss/knight_pain01.wav", true);
		PrecacheSound("vo/halloween_boss/knight_pain02.wav", true);
		PrecacheSound("vo/halloween_boss/knight_pain03.wav", true);
		PrecacheSound("vo/halloween_boss/knight_spawn.wav", true);
		PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav", true);
		PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav", true);
		PrecacheSound("ui/halloween_boss_chosen_it.wav", true);
		PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);
		PrecacheSound("ui/halloween_boss_defeated.wav", true);
		PrecacheSound("ui/halloween_boss_player_becomes_it.wav", true);
		PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
		PrecacheSound("ui/halloween_boss_summoned.wav", true);
		PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
	}
	else if (StrEqual("koth_viaduct_event", mapname, false))
	{
		PrecacheModel("models/props_halloween/halloween_demoeye.mdl", true);
		PrecacheModel("models/props_halloween/eyeball_projectile.mdl", true);
		PrecacheSound("vo/halloween_eyeball/eyeball01.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball02.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball03.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball04.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball05.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball06.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball07.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball08.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball09.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball10.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball11.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_laugh01.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_laugh02.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_laugh03.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_mad01.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_mad02.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_mad03.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_teleport.wav", true);
		PrecacheSound("ui/halloween_boss_chosen_it.wav", true);
		PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);
		PrecacheSound("ui/halloween_boss_defeated.wav", true);
		PrecacheSound("ui/halloween_boss_player_becomes_it.wav", true);
		PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
		PrecacheSound(")ui/halloween_boss_summon_rumble.wav", true);
		PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
		PrecacheSound("ui/halloween_boss_summoned.wav", true);
		PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
		PrecacheSound("ui/halloween_boss_escape.wav", true);
		PrecacheSound("ui/halloween_boss_escape_sixty.wav", true);
		PrecacheSound("ui/halloween_boss_escape_ten.wav", true);
		PrecacheModel("models/props_halloween/ghost_no_hat.mdl", true);
		PrecacheSound("vo/halloween_moan1.wav", true);
		PrecacheSound("vo/halloween_moan2.wav", true);
		PrecacheSound("vo/halloween_moan3.wav", true);
		PrecacheSound("vo/halloween_moan4.wav", true);
		PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav", true);
	}
}

public Action:TF2_OnIsHolidayActive(TFHoliday:holiday, &bool:result)
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		switch(holiday)
		{
			case TFHoliday_Birthday:
			{
				new birthday = GetConVarInt(g_Cvar_Birthday);
				if (birthday == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (birthday == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_Halloween:
			{
				decl String:mapname[MAPLENGTH];
				GetCurrentMap(mapname, sizeof(mapname));
				if (IsHalloweenMap(mapname))
				{
					result = true;
					return Plugin_Changed;
				}
				
				new halloween = GetConVarInt(g_Cvar_Halloween);
				if (halloween == -1 || halloween == 2)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (halloween == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_Christmas:
			{
				new winter = GetConVarInt(g_Cvar_Winter);
				if (winter == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (winter == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_MeetThePyro:
			{
				new mtp = GetConVarInt(g_Cvar_MeetThePyro);
				if (mtp == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (mtp == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_MannVsMachine:
			{
				new mvm = GetConVarInt(g_Cvar_MannVsMachine);
				if (mvm == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (mvm == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_FullMoon:
			{
				new halloween = GetConVarInt(g_Cvar_Halloween);
				if (halloween == -1 || halloween == 1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (halloween == 2)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_HalloweenOrFullMoon:
			{
				decl String:mapname[MAPLENGTH];
				GetCurrentMap(mapname, sizeof(mapname));
				if (IsHalloweenMap(mapname))
				{
					result = true;
					return Plugin_Changed;
				}

				new halloween = GetConVarInt(g_Cvar_Halloween);
				if (halloween == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (halloween >= 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsHalloweenMap(const String:mapname[])
{
	new mapIndex = FindStringInArray(g_Maplist, mapname);
	return (mapIndex > -1);
}
