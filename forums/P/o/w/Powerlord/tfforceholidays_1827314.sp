// TF2 Force Holidays
// Copyright 2011-2012 Ross Bemrose (Powerlord)
// Like All SourceMod Plugins, this code is licensed under the GPLv2

#define VERSION "1.8.0"
#define MAPLENGTH 65
#define UPDATE_URL "http://www.rbemrose.com/sourcemod/tfforceholidays/updatefile.txt"

#include <sourcemod>
#include <tf2>

#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1

new Handle:g_Cvar_Enabled		= INVALID_HANDLE;
new Handle:g_Cvar_Halloween		= INVALID_HANDLE;
new Handle:g_Cvar_FullMoon		= INVALID_HANDLE;
new Handle:g_Cvar_Birthday		= INVALID_HANDLE;
new Handle:g_Cvar_Winter		= INVALID_HANDLE;
new Handle:g_Cvar_MeetThePyro	= INVALID_HANDLE;
new Handle:g_Cvar_Valentines	= INVALID_HANDLE;

new Handle:g_Cvar_Overrides     = INVALID_HANDLE;

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
	
	g_Cvar_Enabled     = CreateConVar("tfh_enabled", "1", "Enable TF Force Holidays", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Overrides   = CreateConVar("tfh_use_overrides", "1", "Use Overrides file for Halloween maps", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_Cvar_Halloween   = CreateConVar("tfh_halloween", "0", "Force Halloween mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 2.0);
	g_Cvar_FullMoon    = CreateConVar("tfh_fullmoon", "0", "Force Full Moon mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Birthday    = CreateConVar("tfh_birthday", "0", "Force Birthday mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Winter      = CreateConVar("tfh_winter", "0", "Force Winter mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_MeetThePyro = CreateConVar("tfh_meetthepyro", "0", "Force Meet The Pyro mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Valentines  = CreateConVar("tfh_valentines", "0", "Force Valentines mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	
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
	decl String:mapname[MAPLENGTH];
	GetCurrentMap(mapname, sizeof(mapname));
	
	PrecacheBoss(mapname);
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
			
			case TFHoliday_ValentinesDay:
			{
				new valentines = GetConVarInt(g_Cvar_Valentines);
				if (valentines == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (valentines == 1)
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
			
			case TFHoliday_FullMoon:
			{
				new halloween = GetConVarInt(g_Cvar_Halloween);
				new fullmoon = GetConVarInt(g_Cvar_FullMoon);
				
				if (fullmoon == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (fullmoon == 1 || halloween == 2)
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
				new fullmoon = GetConVarInt(g_Cvar_FullMoon);

				if (halloween == -1 && fullmoon == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (halloween >= 1 || fullmoon == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}

			case TFHoliday_HalloweenOrFullMoonOrValentines:
			{
				decl String:mapname[MAPLENGTH];
				GetCurrentMap(mapname, sizeof(mapname));
				if (IsHalloweenMap(mapname))
				{
					result = true;
					return Plugin_Changed;
				}

				new halloween = GetConVarInt(g_Cvar_Halloween);
				new fullmoon = GetConVarInt(g_Cvar_FullMoon);
				new valentines = GetConVarInt(g_Cvar_Valentines);

				if (halloween == -1 && fullmoon == -1 && valentines == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (halloween >= 1 || fullmoon == 1 || valentines == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

bool:IsHalloweenMap(const String:mapname[])
{
	if (!GetConVarBool(g_Cvar_Overrides))
	{
		return false;
	}
	
	new mapIndex = FindStringInArray(g_Maplist, mapname);
	return (mapIndex > -1);
}

PrecacheBoss(const String:mapname[])
{
		// Precache sounds and models
	if (StrEqual("cp_manor_event", mapname, false))
	{
		// Horsemann stuff  taken from Geit's Horseless Headless Horsemann plugin
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
		// Monoculus stuff taken from DarthNinja's Monoculus Spawner plugin
		// and then had koth_viaduct_event specific stuff added by Powerlord
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
	else if (StrEqual("koth_lakeside_event", mapname, false))
	{
		// Merasmus stuff taken from Chaosxk's Merasmus Spawner plugin
		// with the koth_lakeside_event specific stuff uncommented
		PrecacheModel("models/bots/merasmus/merasmus.mdl", true);
		PrecacheModel("models/props_halloween/bombonomicon.mdl", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears15.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears16.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_appears17.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_attacks01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_attacks11.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb17.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb19.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb23.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb24.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb25.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb26.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb28.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb29.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb30.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb31.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb32.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb33.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb34.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb35.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb36.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb37.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb38.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb39.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb40.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb41.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb42.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb44.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb45.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb46.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb47.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb48.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb49.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb50.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb51.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb52.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb53.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb54.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up15.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up17.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up18.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up19.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up20.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up21.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up24.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up25.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up27.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up28.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up29.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up30.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up31.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up32.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up33.wav", true);

		PrecacheSound("vo/halloween_merasmus/sf12_bcon_island02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_island03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_island04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat03.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_bombinomicon15.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_combat_idle01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_combat_idle02.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_defeated01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_defeated12.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_found01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_found09.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_grenades03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_grenades04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_grenades05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_grenades06.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit15.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit16.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit17.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit18.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit19.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit20.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit21.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit23.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit24.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit25.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit26.wav", true);

		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal15.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal16.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal17.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_heal19.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles14.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles15.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles16.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles18.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles20.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles21.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles22.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles23.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles24.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles25.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles26.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles27.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles28.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles29.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles30.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles31.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles33.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles27.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles41.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles42.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles44.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles46.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles47.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles48.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_hide_idles49.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_leaving01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_leaving16.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_pain01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_pain02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_pain03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_pain04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_pain05.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack08.wav", true);

		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_staff_magic13.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bighead07.wav", true);
		
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bloody01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bloody02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bloody03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bloody04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_bloody05.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_crits02.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_dance02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_dance03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_dance04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_dance05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_dance06.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_fire01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_fire02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_fire03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_fire04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_fire05.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_ghosts01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_ghosts02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_ghosts03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_ghosts05.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_gravity01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_gravity02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_gravity03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_gravity04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_gravity05.wav", true);

		PrecacheSound("vo/halloween_merasmus/sf12_wheel_happy04.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_invincible11.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jarate01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jarate02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jarate03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jarate04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jarate05.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jump01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_jump02.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_nonspecific04.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_scared08.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_speed01.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin10.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin11.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin12.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin13.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin15.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin18.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin19.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin21.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin22.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin23.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin24.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin25.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_spin26.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_tinyhead01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_tinyhead02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_tinyhead03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_tinyhead04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_tinyhead05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_tinyhead06.wav", true);
		
		PrecacheSound("vo/halloween_merasmus/sf12_wheel_ubercharge01.wav", true);
		
		PrecacheModel("models/props_halloween/ghost_no_hat.mdl", true);
		PrecacheSound("vo/halloween_moan1.wav", true);
		PrecacheSound("vo/halloween_moan2.wav", true);
		PrecacheSound("vo/halloween_moan3.wav", true);
		PrecacheSound("vo/halloween_moan4.wav", true);
	}
}