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

#define PLUGIN_NAME		"Infected Ghost Pounce"
#define PLUGIN_DESC		"Allows infected make high jump while ghost"
#define PLUGIN_VERSION		"1.0.5"
#define PLUGIN_FILENAME		"l4d2_ghostpounce"

Handle p_x 				= INVALID_HANDLE;
Handle p_z 				= INVALID_HANDLE;
Handle p_y 				= INVALID_HANDLE;
int val_x		= 0;
float val_y	= 0.0;
int val_z		= 0;

public Plugin myinfo = 
{
  name = PLUGIN_NAME,
  author = " AtomicStryker",
  description = PLUGIN_DESC,
  version = PLUGIN_VERSION,
  url = "http://forums.alliedmods.net/showthread.php?t=99519"
};


public void OnPluginStart()
{
  /* Load ConVar */
  CreateConVar("l4d_ghostpounce_version", PLUGIN_VERSION, " Ghost Leap Plugin Version ", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  p_x = CreateConVar("l4d_ghostpounce_vector_mult_x", "3", "Multiplication speed when pounce on x", FCVAR_NOTIFY); 
  p_z = CreateConVar("l4d_ghostpounce_vector_mult_z", "3", "Multiplication speed when pounce on z", FCVAR_NOTIFY); 
  p_y = CreateConVar("l4d_ghostpounce_vector_y", "900.0", "set how high is pounce", FCVAR_NOTIFY); 
	
  val_x = GetConVarInt(p_x);
  val_y = GetConVarFloat(p_y);
  val_z = GetConVarInt(p_z);
  AutoExecConfig(true, "l4d_ghostpounce");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{

  /* When player press RELOAD button, make a pounce if infected and as ghost */
  if (buttons & IN_RELOAD)
    {
      if (GetClientTeam(client)!=3) return Plugin_Continue;
      if (!IsPlayerSpawnGhost(client)) return Plugin_Continue;
		
      DoPounce(client);
    }

  return Plugin_Continue;
}

void DoPounce(any client)
{
  float vec[3];
  GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	
  if (vec[2] != 0)
    {
      return;
    }
  if (vec[0] == 0 && vec[1] == 0)
    {
      return;
    }
 /*yep look strange, but that more clear when puttin cvar. Z velocity make go fast forward, so higher */
  vec[0] *= val_x;
  vec[1] *= val_z;
  vec[2] = val_y;
	
  TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
}

stock bool IsPlayerSpawnGhost(client)
{
  if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
  else return false;
}
