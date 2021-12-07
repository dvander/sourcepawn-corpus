/*

	Spawn Weapon
	Version 1.0
	By Hartmann
	
	Information about this plugin can be found at:
	http://hartmannq.github.io/SpawnWeapon/

	Copyright © 2015, Hartmann

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define TeamCT    3

new Handle:szWeaponArray[2];
new Handle:iBuyZones;
new bool:iBuyZonesDisable;

enum {
	TT = 0, 
	CT
}
public Plugin:myinfo = {
	name = "Spawn Weapon",
	author = "Hartmann",
	description = "http://hartmannq.github.io/SpawnWeapon/",
	version = PLUGIN_VERSION,
	url = "http://hartmannq.blogspot.com/"
}
public void OnPluginStart()
{
	CreateConVar("Spawn_Weapon", PLUGIN_VERSION, "Console Display Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	iBuyZones = CreateConVar("buyzone_disable", "1", "Buyzone Remove/Disable 1 - Disable/Remove 0 - Enable/Not Remove .");
	HookConVarChange(iBuyZones, Event_CvarChange); 
	HookEvent("player_spawn", Event_Spawn);
}
public OnMapStart()
{
	decl String:szMap[64], String:szFilePath[PLATFORM_MAX_PATH];
	
	GetCurrentMap( szMap, sizeof(szMap));
	BuildPath(Path_SM, szFilePath, PLATFORM_MAX_PATH, "%s.spawn_weapon.ini",szMap );
	
	if(!FileExists(szFilePath)){  
		BuildPath(Path_SM, szFilePath, PLATFORM_MAX_PATH, "spawn_weapon.ini");
	}
	
	CreateWeaponArray(szFilePath);
	
	if (iBuyZonesDisable)
     	{
         	SetBuyZones("Disable");
     	}
     	else
     	{
        	SetBuyZones("Enable");
     	}
	
}
public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iBuyZonesDisable = GetConVarBool(iBuyZones);
}
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new usr = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (usr != 0 && IsClientInGame(usr) && IsPlayerAlive(usr))
	{
		new szTeam = GetClientTeam(usr) == TeamCT ? CT : TT;
		StripUserWeapons(usr);
		GiveWeapons(usr, szTeam);
	}
	
	return bool:Plugin_Handled;
}
public CreateWeaponArray(const String:szFile[]) {
	decl String:szFileLine[512], Handle:iFile, iTeam;
	new String:szBuffer[2][32], String:szWeaponName[32];

	szWeaponArray[0] = CreateArray(32);
	szWeaponArray[1] = CreateArray(32);
	
	iFile = OpenFile(szFile, "r");
	if (iFile != INVALID_HANDLE) {
		
		while (!IsEndOfFile(iFile) && ReadFileLine(iFile, szFileLine, sizeof(szFileLine))) {
			
			TrimString(szFileLine);
			if (!(szFileLine[0] == ';') && szFileLine[0]){

				ExplodeString(szFileLine, " ", szBuffer, sizeof(szBuffer), sizeof(szBuffer[]));

				if (StrEqual(szBuffer[0], "CT", false))
					iTeam = CT;
				else if (StrEqual(szBuffer[0], "TT", false))
					iTeam = TT;

				FormatEx(szWeaponName, sizeof(szWeaponName), "weapon_%s", szBuffer[1]);			

				PushArrayString(szWeaponArray[iTeam], szWeaponName);
			}
			
		}
		CloseHandle(iFile);
		}else {
		LogMessage("*** Unable to open /* %s */ for reading.", szFile);
	}	
}
stock GiveWeapons( usr, szTeam )
{
	new String:iBuffer[32];
	if (IsClientInGame(usr) && IsPlayerAlive(usr))
	{
		for(new i=0; i < GetArraySize(szWeaponArray[szTeam]); i++ )
		{
			GetArrayString(szWeaponArray[szTeam], i, iBuffer, sizeof(iBuffer));
			GivePlayerItem(usr, iBuffer); 
		}
	}
}
stock StripUserWeapons(usr)
{
	if (IsClientInGame(usr) && IsPlayerAlive(usr))
	{
		FakeClientCommand(usr, "use weapon_knife");
		for (new i = 0; i < 4; i++)
		{
			if (i == 2) continue; // Keep knife.
			new entityIndex;
			while ((entityIndex = GetPlayerWeaponSlot(usr, i)) != -1)
			{
				RemovePlayerItem(usr, entityIndex);
				AcceptEntityInput(entityIndex, "Kill");
			}
		}
	}
}
stock SetBuyZones(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];

	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_buyzone"))
				AcceptEntityInput(i, status);
		}
	}
}
