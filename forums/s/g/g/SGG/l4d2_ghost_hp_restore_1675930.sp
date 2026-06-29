/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.	If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <left4downtown>

#define 		ZOMBIECLASS_SMOKER				1
#define 		ZOMBIECLASS_BOOMER				2
#define 		ZOMBIECLASS_HUNTER				3
#define 		ZOMBIECLASS_SPITTER				4
#define 		ZOMBIECLASS_JOCKEY				5
#define 		ZOMBIECLASS_CHARGER 			6
#define 		PLUGIN_VERSION					"0.2"

new Handle:H_SmokerHP = INVALID_HANDLE;
new Handle:H_BoomerHP = INVALID_HANDLE;
new Handle:H_HunterHP = INVALID_HANDLE;
new Handle:H_SpitterHP = INVALID_HANDLE;
new Handle:H_JockeyHP = INVALID_HANDLE;
new Handle:H_ChargerHP = INVALID_HANDLE;
new Handle:H_RestoreEnabled[7];

public Plugin:myinfo =
{
	name = "L4D2_Ghost_HP_Restore",
	author = "Sneaky Green Guy (SGG)",
	description = "Gives SI back full HP when they enter ghost mode",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1675930"
};
 
public OnPluginStart()
{
	decl String:sGame[16];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Plugin supports 'Left 4 Dead 2' only.");
	}
	H_RestoreEnabled[1] = CreateConVar("l4d2_ghost_hp_restore_smoker", "1", "Is smoker health restore enabled", FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	H_RestoreEnabled[2] = CreateConVar("l4d2_ghost_hp_restore_boomer", "1", "Is boomer health restore enabled", FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	H_RestoreEnabled[3] = CreateConVar("l4d2_ghost_hp_restore_hunter", "1", "Is huter health restore enabled", FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	H_RestoreEnabled[4] = CreateConVar("l4d2_ghost_hp_restore_spitter", "1", "Is spitter health restore enabled", FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	H_RestoreEnabled[5] = CreateConVar("l4d2_ghost_hp_restore_jockey", "1", "Is jockey health restore enabled", FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	H_RestoreEnabled[6] = CreateConVar("l4d2_ghost_hp_restore_charger", "1", "Is charger health restore enabled", FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	CreateConVar("l4d2_ghost_hp_restore_version", PLUGIN_VERSION, "Left 4 Dead 2 Ghost HP Restore version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_ghost_hp_restore")
	H_SmokerHP = FindConVar("z_gas_health");
	H_BoomerHP = FindConVar("z_exploding_health");
	H_HunterHP = FindConVar("z_hunter_health");
	H_SpitterHP = FindConVar("z_spitter_health");
	H_JockeyHP = FindConVar("z_jockey_health");
	H_ChargerHP = FindConVar("z_charger_health");
}

public L4D_OnEnterGhostState(client)
{
	new ZClass;
	new temp;
	ZClass = GetEntProp(client, Prop_Send, "m_zombieClass")
	temp = GetConVarInt(H_RestoreEnabled[ZClass]);
	if (temp == 1)
	{
		switch(ZClass)
		{
			case ZOMBIECLASS_SMOKER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(H_SmokerHP));
			}
			case ZOMBIECLASS_BOOMER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(H_BoomerHP));
			}
			case ZOMBIECLASS_HUNTER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(H_HunterHP));
			}
			case ZOMBIECLASS_SPITTER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(H_SpitterHP));
			}
			case ZOMBIECLASS_JOCKEY:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(H_JockeyHP));
			}
			case ZOMBIECLASS_CHARGER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(H_ChargerHP));
			}
		}
	}
}