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
 * Version: 1.9.1
 */

#define VERSION "1.9.1"

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
new Handle:g_Cvar_DontForce = INVALID_HANDLE;

// Valve CVars
new Handle:g_Cvar_ForceHoliday 	= INVALID_HANDLE;

new g_OldForceValue = 0;
new g_bWeChangedForceValue = false;

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
	
	g_Cvar_Halloween   = CreateConVar("tfh_halloween", "0", "Force Halloween mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_FullMoon    = CreateConVar("tfh_fullmoon", "0", "Force Full Moon mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Birthday    = CreateConVar("tfh_birthday", "0", "Force Birthday mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Winter      = CreateConVar("tfh_winter", "0", "Force Winter mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_MeetThePyro = CreateConVar("tfh_meetthepyro", "0", "Force Meet The Pyro mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_Valentines  = CreateConVar("tfh_valentines", "0", "Force Valentines mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	g_Cvar_AprilFools  = CreateConVar("tfh_aprilfools", "0", "Force April Fools mode: -1: Always off, 0: Use game setting, 1: Always on", FCVAR_NOTIFY, true, -1.0, true, 1.0);

	g_Cvar_DontForce  = CreateConVar("tfh_dontforce", "0", "If set to 1, will not force tf_forced_holiday to change. NOTE: SETTING THIS TO 1 BREAKS ZOMBIE COSTUMES", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_Cvar_ForceHoliday = FindConVar("tf_forced_holiday");
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	HookConVarChange(g_Cvar_Halloween, Cvar_HalloFullMoonChanged);
	HookConVarChange(g_Cvar_FullMoon, Cvar_HalloFullMoonChanged);
	HookConVarChange(g_Cvar_DontForce, Cvar_HalloFullMoonChanged);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
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
	if (GetConVarBool(g_Cvar_DontForce))
	{
		if (g_bWeChangedForceValue)
		{
			SetConVarInt(g_Cvar_ForceHoliday, g_OldForceValue);
			g_bWeChangedForceValue = false;
			g_OldForceValue = 0;
		}
		return;		
	}
	
	if (!g_bWeChangedForceValue && (GetConVarBool(g_Cvar_Halloween) || GetConVarBool(g_Cvar_FullMoon)))
	{
		g_OldForceValue = GetConVarInt(g_Cvar_ForceHoliday);
		g_bWeChangedForceValue = true;
	}
	
	if (GetConVarBool(g_Cvar_Halloween))
	{
		SetConVarInt(g_Cvar_ForceHoliday, _:TFHoliday_Halloween);
	}
	else if (GetConVarBool(g_Cvar_FullMoon))
	{
		SetConVarInt(g_Cvar_ForceHoliday, _:TFHoliday_FullMoon);
	}
	else if (g_bWeChangedForceValue)
	{
		SetConVarInt(g_Cvar_ForceHoliday, g_OldForceValue);
		g_bWeChangedForceValue = false;
		g_OldForceValue = 0;		
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
