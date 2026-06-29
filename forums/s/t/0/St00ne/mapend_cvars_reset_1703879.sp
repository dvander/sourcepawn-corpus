/**
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
 */

#include <sourcemod>

#define PLUGIN_VERSION "2.1"

public Plugin:myinfo =
{
	name = "Map end cvars reset",
	author = "St00ne",
	description = "Resets any cvar like sv_gravity, phys_pushscale and phys_timescale before map changes.",
	version = PLUGIN_VERSION,
	url = "http://www.esc90.fr"
}

public OnPluginStart()
{
	CreateConVar("sm_mapend_cvars_reset_version", PLUGIN_VERSION, "Version of Map end cvars reset plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
}

public OnMapEnd()
{
	if (FileExists("cfg/sourcemod/mapend_cvars_reset.cfg"))
	{
		ServerCommand("exec sourcemod/mapend_cvars_reset.cfg");
	}
	
	else
		LogError("Unable to load mapend_cvars_reset.cfg. File may not be present in cfg/sourcemod folder.");
}
