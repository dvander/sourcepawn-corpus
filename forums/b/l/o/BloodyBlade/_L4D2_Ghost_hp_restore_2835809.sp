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
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <clientprefs>
#include <left4dhooks>

#define 		ZOMBIECLASS_SMOKER				1
#define 		ZOMBIECLASS_BOOMER				2
#define 		ZOMBIECLASS_HUNTER				3
#define 		ZOMBIECLASS_SPITTER				4
#define 		ZOMBIECLASS_JOCKEY				5
#define 		ZOMBIECLASS_CHARGER 			6
#define 		PLUGIN_VERSION					"0.2"
#define 		CVAR_FLAGS 						FCVAR_NOTIFY

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[VIP]_Ghost_HP_Restore",
	author = "Sneaky Green Guy (SGG)(edit. by BloodyBlade)",
	description = "Gives SI back full HP when they enter ghost mode",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1675930"
};

PluginData plugin;

enum struct PluginCvars
{
	ConVar H_RestoreEnabled[7];

	void Init()
	{
		CreateConVar("l4d2_ghost_hp_restore_version", PLUGIN_VERSION, "[L4D2] Ghost HP Restore version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.H_RestoreEnabled[0] = CreateConVar("l4d2_ghost_hp_restore_enable", "1", "Is plugin enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.H_RestoreEnabled[1] = CreateConVar("l4d2_ghost_hp_restore_smoker", "1", "Is smoker health restore enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.H_RestoreEnabled[2] = CreateConVar("l4d2_ghost_hp_restore_boomer", "1", "Is boomer health restore enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.H_RestoreEnabled[3] = CreateConVar("l4d2_ghost_hp_restore_hunter", "1", "Is huter health restore enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.H_RestoreEnabled[4] = CreateConVar("l4d2_ghost_hp_restore_spitter", "1", "Is spitter health restore enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.H_RestoreEnabled[5] = CreateConVar("l4d2_ghost_hp_restore_jockey", "1", "Is jockey health restore enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.H_RestoreEnabled[6] = CreateConVar("l4d2_ghost_hp_restore_charger", "1", "Is charger health restore enabled", CVAR_FLAGS, true, 0.0, true, 1.0);

		this.H_RestoreEnabled[0].AddChangeHook(OnConVarChange);
		this.H_RestoreEnabled[1].AddChangeHook(OnConVarChange);
		this.H_RestoreEnabled[2].AddChangeHook(OnConVarChange);
		this.H_RestoreEnabled[3].AddChangeHook(OnConVarChange);
		this.H_RestoreEnabled[4].AddChangeHook(OnConVarChange);
		this.H_RestoreEnabled[5].AddChangeHook(OnConVarChange);
		this.H_RestoreEnabled[6].AddChangeHook(OnConVarChange);
		AutoExecConfig(true, "vip_ghost_hp_restore");
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	int iSmokerHP;
	int iBoomerHP;
	int iHunterHP;
	int iSpitterHP;
	int iJockeyHP;
	int iChargerHP;
	bool b_RestoreEnabled[7];

	void Init()
	{
		this.cvars.Init();
	}

	void GetCvarValues()
	{
		this.b_RestoreEnabled[0] = this.cvars.H_RestoreEnabled[0].BoolValue;
		this.b_RestoreEnabled[1] = this.cvars.H_RestoreEnabled[1].BoolValue;
		this.b_RestoreEnabled[2] = this.cvars.H_RestoreEnabled[2].BoolValue;
		this.b_RestoreEnabled[3] = this.cvars.H_RestoreEnabled[3].BoolValue;
		this.b_RestoreEnabled[4] = this.cvars.H_RestoreEnabled[4].BoolValue;
		this.b_RestoreEnabled[5] = this.cvars.H_RestoreEnabled[5].BoolValue;
		this.b_RestoreEnabled[6] = this.cvars.H_RestoreEnabled[6].BoolValue;
		this.iSmokerHP = FindConVar("z_gas_health").IntValue;
		this.iBoomerHP = FindConVar("z_exploding_health").IntValue;
		this.iHunterHP = FindConVar("z_hunter_health").IntValue;
		this.iSpitterHP = FindConVar("z_spitter_health").IntValue;
		this.iJockeyHP = FindConVar("z_jockey_health").IntValue;
		this.iChargerHP = FindConVar("z_charger_health").IntValue;
	}
}

public void OnPluginStart()
{
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.GetCvarValues();
}

void OnConVarChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

public void L4D_OnEnterGhostState(int client)
{
	int ZClass = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(plugin.b_RestoreEnabled[0] && plugin.b_RestoreEnabled[ZClass])
	{
		switch(ZClass)
		{
			case ZOMBIECLASS_SMOKER: SetEntProp(client, Prop_Send, "m_iHealth", plugin.iSmokerHP);
			case ZOMBIECLASS_BOOMER: SetEntProp(client, Prop_Send, "m_iHealth", plugin.iBoomerHP);
			case ZOMBIECLASS_HUNTER: SetEntProp(client, Prop_Send, "m_iHealth", plugin.iHunterHP);
			case ZOMBIECLASS_SPITTER: SetEntProp(client, Prop_Send, "m_iHealth", plugin.iSpitterHP);
			case ZOMBIECLASS_JOCKEY: SetEntProp(client, Prop_Send, "m_iHealth", plugin.iJockeyHP);
			case ZOMBIECLASS_CHARGER: SetEntProp(client, Prop_Send, "m_iHealth", plugin.iChargerHP);
		}
	}
}
