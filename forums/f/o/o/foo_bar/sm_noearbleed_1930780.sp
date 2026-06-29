/*
 * sm_noearbleed: Turn off "tinnitus" ringing sound on explosions
 * Thrown together by [foo] bar <foobarhl@gmail.com> | http://steamcommunity.com/id/foo-bar/
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <sourcemod>
#include <sdkhooks>

#define VERSION "1.0"

public Plugin:myinfo = {
	name = "sm_noearbleed",
	author = "[foo] bar",
	description = "Turn off ear ringing on explosion",
	version = VERSION,
	url = "https://github.com/foobarhl/sourcemod/"
};

public OnPluginStart()
{
	CreateConVar("sm_noearbleed_version",VERSION,"Version of this plugin", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public OnClientPutInServer(client)	// from superlogs-hl2mp.sp
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnAllPluginsLoaded()	// from superlogs-hl2mp.sp
{
	if (GetExtensionFileStatus("sdkhooks.ext") != 1)
	{
		SetFailState("SDK Hooks v1.3 or higher is required for sm_noearbleed");
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
                Float:damageForce[3], Float:damagePosition[3], damagecustom)
{	
	if(damagetype & DMG_BLAST )
	{	
		damagetype = DMG_GENERIC;
	}	
	return(Plugin_Changed);
}
