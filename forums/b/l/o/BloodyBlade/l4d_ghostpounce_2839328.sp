#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* CHANGELOG
 * Added cvar l4d_ghostpounce_vector_mult_x, l4d_ghostpounce_vector_mult_z and l4d_ghostpounce_vector_y to controle the jump
 */

/*
 * This plugin is a slight modification of original Left 4 dead Ghost Leap by AtomicStryker
 */
#define PLUGIN_VERSION "1.0.5"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar p_e, p_b, p_x, p_z, p_y, p_MFS;
bool val_B = false, val_E = false, val_MFS = false;
int val_x = 0, val_z = 0;
float val_y	= 0.0;

public Plugin myinfo = 
{
	name = "Infected Ghost Pounce",
	author = " AtomicStryker",
	description = "Allows infected make high jump while ghost",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=99519"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_ghostpounce_version", PLUGIN_VERSION, "Infected Ghost Pounce plugin version ", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	p_e = CreateConVar("l4d_ghostpounce_enable", "1", "Enables this plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
	p_b = CreateConVar("l4d_ghostpounce_button", "0", "Button to pounce(0 = RELOAD, 1 = ATTACK2)", CVAR_FLAGS);
	p_x = CreateConVar("l4d_ghostpounce_vector_mult_x", "3", "Multiplication speed when pounce on x", CVAR_FLAGS);
	p_z = CreateConVar("l4d_ghostpounce_vector_mult_z", "3", "Multiplication speed when pounce on z", CVAR_FLAGS); 
	p_y = CreateConVar("l4d_ghostpounce_vector_y", "900.0", "set how high is pounce", CVAR_FLAGS);
	p_MFS = CreateConVar("l4d_ghostpounce_flightspawnallowed", "1", "Allow or Disallow Infected to Spawn during Ghost Pounce", CVAR_FLAGS);

	AutoExecConfig(true, "l4d_ghostpounce");

	p_e.AddChangeHook(OnConVarsChanged);
	p_b.AddChangeHook(OnConVarsChanged);
	p_x.AddChangeHook(OnConVarsChanged);
	p_z.AddChangeHook(OnConVarsChanged);
	p_y.AddChangeHook(OnConVarsChanged);
	p_MFS.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	OnConVarsChanged(null, "", "");
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	val_E = p_e.BoolValue;
	val_B = p_b.BoolValue;
	val_x = p_x.IntValue;
	val_y = p_y.FloatValue;
	val_z = p_z.IntValue;
	val_MFS = p_MFS.BoolValue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(val_E && bIsValidGhostInf(client))
    {
        if((!val_B && (buttons & IN_RELOAD)) || (val_B && (buttons & IN_ATTACK2)))
        {
            float vec[3];
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
            if (vec[2] != 0)
            {
                PrintCenterText(client, "You must be on even ground to ghost pounce");
                return Plugin_Continue;
            }

            if (vec[0] == 0 && vec[1] == 0)
            {
                PrintCenterText(client, "You must be on the move to ghost pounce");
                return Plugin_Continue;
            }

            vec[0] *= val_x;
            vec[1] *= val_z;
            vec[2] = val_y;
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
        }

        if ((buttons & IN_ATTACK) && NoGhostSpawnState4(client) && val_MFS)
        {
            PrintToChat(client, "\x04This server disallows spawning during Ghost Pounce");
            SetEntProp(client, Prop_Send, "m_ghostSpawnState", 128, 4);
        }
    }
    return Plugin_Continue;
}

stock bool IsPlayerSpawnGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

stock bool NoGhostSpawnState4(int client)
{
    return !view_as<int>(GetEntProp(client, Prop_Send, "m_ghostSpawnState", 4));
}

stock bool bIsValidGhostInf(int client)
{
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerSpawnGhost(client);
}
