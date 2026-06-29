/**
 * vim: set ts=4 :
 * =============================================================================
 * TF2 Force Holidays
 * Force multiple holidays on at the same time
 * 
 * TF2 Force Holidays (C) 2011-2014 Ross Bemrose (Powerlord). All rights reserved.
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: 1.9.0
 */

#define VERSION "1.9.0"

#include <sourcemod>
#include <tf2>

#undef REQUIRE_PLUGIN
#include <updater>
// Seriously considering removing updater integration, moving things around to make it easier later
#define UPDATE_URL "http://www.rbemrose.com/sourcemod/tfforceholidays/updatefile.txt"

#pragma semicolon 1

new Handle:g_Cvar_Enabled		= INVALID_HANDLE;
new Handle:g_Cvar_Halloween		= INVALID_HANDLE;
new Handle:g_Cvar_FullMoon		= INVALID_HANDLE;
new Handle:g_Cvar_Birthday		= INVALID_HANDLE;
new Handle:g_Cvar_Winter		= INVALID_HANDLE;
new Handle:g_Cvar_MeetThePyro	= INVALID_HANDLE;
new Handle:g_Cvar_Valentines	= INVALID_HANDLE;
new Handle:g_Cvar_AprilFools	= INVALID_HANDLE;
new Handle:g_Cvar_Overrides     = INVALID_HANDLE;

new Handle:g_Maplist = INVALID_HANDLE;
new g_Maplist_Serial = -1;

// Valve CVars
new Handle:g_Cvar_ForceHoliday 	= INVALID_HANDLE;

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
	
	g_Cvar_Enabled     = CreateConVar("tfh_enabled", "1", "Enable TF Force Holidays", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Overrides   = CreateConVar("tfh_use_overrides", "1", "Use Overrides file for Halloween maps", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_Cvar_Halloween   = CreateConVar("tfh_halloween", "0", "Force Halloween mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_FullMoon    = CreateConVar("tfh_fullmoon", "0", "Force Full Moon mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Birthday    = CreateConVar("tfh_birthday", "0", "Force Birthday mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Winter      = CreateConVar("tfh_winter", "0", "Force Winter mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_MeetThePyro = CreateConVar("tfh_meetthepyro", "0", "Force Meet The Pyro mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Valentines  = CreateConVar("tfh_valentines", "0", "Force Valentines mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_AprilFools  = CreateConVar("tfh_aprilfools", "0", "Force April Fools mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	
	g_Cvar_ForceHoliday = FindConVar("tf_forced_holiday");
	
	g_Maplist = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

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
	decl String:mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	
	//PrecacheBoss(mapname);
}

public OnConfigsExecuted()
{
	FixForceHolidays();
}

public Cvar_HalloFullMoonChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FixForceHolidays();
}

FixForceHolidays()
{
	decl String:mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (IsHalloweenMap(mapname) || GetConVarBool(g_Cvar_Halloween))
	{
		SetConVarInt(g_Cvar_ForceHoliday, _:TFHoliday_Halloween);
	}
	else if (GetConVarBool(g_Cvar_FullMoon))
	{
		SetConVarInt(g_Cvar_ForceHoliday, _:TFHoliday_FullMoon);
	}
	else
	{
		SetConVarInt(g_Cvar_ForceHoliday, 0); // _:TFHoliday_None
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
				decl String:mapname[PLATFORM_MAX_PATH];
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
				new fullmoon = GetConVarInt(g_Cvar_FullMoon);
				
				if (fullmoon == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (fullmoon == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_HalloweenOrFullMoon:
			{
				decl String:mapname[PLATFORM_MAX_PATH];
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
				else if (halloween == 1 || fullmoon == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}

			case TFHoliday_HalloweenOrFullMoonOrValentines:
			{
				decl String:mapname[PLATFORM_MAX_PATH];
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
				else if (halloween == 1 || fullmoon == 1 || valentines == 1)
				{
					result = true;
					return Plugin_Changed;
				}
			}
			
			case TFHoliday_AprilFools:
			{
				new aprilfools = GetConVarInt(g_Cvar_AprilFools);
				if (aprilfools == -1)
				{
					result = false;
					return Plugin_Changed;
				}
				else if (aprilfools == 1)
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

// 2014-04-02: Check this again... this hasn't been tested since Valve busted boss precaching in 2012 and it needs to be tested again.
stock PrecacheBoss(const String:mapname[])
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
		PrecacheModel("models/items/ammopack_medium.mdll", true);
		PrecacheModel("models/items/ammopack_medium.mdl", true);
		
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
		
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords01.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords02.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords03.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords04.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords05.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords06.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords07.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords08.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords09.wav", true);
		PrecacheSound("vo/halloween_merasmus/sf12_magicwords10.wav", true);
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
	// Helltower appears to work properly already
	else if (StrEqual("plr_hightower_event", mapname, false))
	{
		// Skeletons
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper.mdl", true);
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_animations.mdl", true);
		PrecacheModel("models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl", true);
		PrecacheModel("models/bots/skeleton_sniper_boss/skeleton_sniper_boss_animations.mdl", true);
		
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_gib_arm_l.mdl", true);
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_gib_arm_r.mdl", true);		
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_gib_leg_l.mdl", true);		
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_gib_leg_r.mdl", true);		
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_gib_head.mdl", true);		
		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper_gib_torso.mdl", true);
		
		PrecacheSound("misc/halloween/skeleton_break.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_giant_01.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_giant_02.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_giant_03.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_01.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_02.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_03.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_04.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_05.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_06.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_medium_07.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_01.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_02.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_03.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_04.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_05.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_06.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_07.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_08.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_09.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_10.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_11.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_12.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_13.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_14.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_15.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_16.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_17.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_18.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_19.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_20.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_21.wav", true);
		PrecacheSound("misc/halloween/skeletons/skelly_small_22.wav", true);
		
		// Mann Bros Arguing
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_lost06_music.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_almost_won12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_bridge09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies13.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies14.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_enemies15.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_intro_long01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_intro_long02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_intro_short01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_intro_short02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_intro_short03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose01_music.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_lose08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing13.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing14.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing15.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing16.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing17.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_losing_push12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_midnight_again09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_misc01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_misc02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_misc03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_misc04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_misc05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_misc06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_spells07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win02_music.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_win11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_blutarch_winning09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue13.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue14.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue15.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue16.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue17.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue18.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue19.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue20.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue21.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue22.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue23.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue24.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue25.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue26.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue27.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_mannbros_argue28.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_almost_lost01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_almost_won01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_bridge08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_enemies08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_intro_long01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_intro_long02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_intro_short01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_intro_short02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_intro_short03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_intro_short04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_lose08_music.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing13.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing14.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing15.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing16.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing17.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing18.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing19.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing19_music.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing20.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing21.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_losing_push08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight_again01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight_again02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight_again03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight_again04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight_again05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_midnight_again06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_spells_long01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win02_music.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_win09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning01.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning02.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning03.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning04.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning05.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning06.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning07.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning08.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning09.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning10.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning11.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning12.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning13.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning14.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning15.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning16.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning17.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning18.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning19.wav", true);
		PrecacheSound("vo/halloween_mann_brothers/sf13_redmond_winning20.wav", true);
	}
}