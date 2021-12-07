/*
 *
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
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
 */

#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.02"

new bool:jarated[40]

new Handle:Cv_PluginEnabled, Handle:Cv_Distance, Handle:Cv_Time, Handle:Cv_OnlyAdmins, Handle:Cv_Flag
public Plugin:myinfo = 
{

	name = "Jarate Teammates",
	author = "simoneaolson",
	description = "Jarate teammates for fun!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
}


public OnPluginStart()
{
	
	AutoExecConfig(true, "tf_jar_teammates")
	
	CreateConVar("tf_jar_teammates_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cv_PluginEnabled = CreateConVar("tf_jar_teammates_enabled", "1", "Enabled/Disable the plugin (bool)", _, true, 0.0, true, 1.0)
	Cv_Distance = CreateConVar("tf_jar_teammates_distance", "750.0", "Max distance a player can be from jarate to be covered in piss (float)", _, true, 300.0, true, 1000.0)
	Cv_Time = CreateConVar("tf_jar_teammates_time", "7.0", "Time in seconds to cover player in piss (float)", _, true, 3.0, true, 12.0)
	Cv_OnlyAdmins = CreateConVar("tf_jar_teammates_admins", "0", "Only admins can jarate teammates (bool)", _, true, 0.0, true, 1.0)
	Cv_Flag = CreateConVar("tf_jar_teammates_flag", "0", "ASCII code of admin flag to use ex: 'c' = 99 (int)", _, false, _, false, _)
	
	if (GetConVarBool(Cv_PluginEnabled))
	{
		HookEventEx("player_hurt", PlayerHurt, EventHookMode_Pre)
	}
	
}


public OnMapStart()
{

	for (new i = 1; i < 40; ++i)
	{
	
		jarated[i] = false
	
	}

}


public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (jarated[client])
	{
		SetEventBool(event, "minicrit", false)
		return Plugin_Changed
	}
	return Plugin_Continue

}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{

	if (GetConVarBool(Cv_PluginEnabled))
	{
		if (StrEqual(weaponname, "tf_weapon_jar"))
		{
			PrintToChatAll("STAGE 1")
			CreateTimer(0.0, FindJar, client)
		}
	}
	return Plugin_Continue
	
}


public Action:FindJar(Handle:timer, const any:client)
{

	decl Float:distance, Float:jarOrigin[3], Float:throwerOrigin[3], Float:clientOrigin[3], bool:go
	new team = GetClientTeam(client)
	
	new index = -1
	PrintToChatAll("STAGE 2")
	while ((index = FindEntityByClassname(index, "tf_weapon_jar")) != -1)
	{
		if (client == GetEntPropEnt(index, Prop_Send, "m_hOwner"))
		{
			PrintToChatAll("STAGE 3")
			//Check if only adminst can jarate teammates
			if (GetConVarBool(Cv_OnlyAdmins))
			{
				if (CheckClientFlags(client)) go = true
				else go = false
			}
			else go = true
			
			if (go)
			{
				if (GetEntProp(index, Prop_Send, "m_iState") == 2)
				{
					CreateTimer(0.1, FindJar, client)
				}
				else
				{
					PrintToChatAll("STAGE 4")
					GetEntPropVector(index, Prop_Send, "m_vecMaxs", jarOrigin)
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", throwerOrigin)
					
					//Convert to absolute origin
					jarOrigin[0] += throwerOrigin[0]
					jarOrigin[1] += throwerOrigin[1]
					jarOrigin[2] += throwerOrigin[2]
					
					for (new i = 1; i < MaxClients; ++i)
					{
						if (IsClientInGame(i))
						{	
							if (GetClientTeam(i) == team && client != i)
							{
								PrintToChatAll("STAGE 5")
								GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientOrigin)
								
								distance = GetVectorDistance(jarOrigin, clientOrigin)
								
								if (distance <= GetConVarFloat(Cv_Distance))
								{
									PrintToChatAll("STAGE 6")
									jarated[i] = true
									CreateTimer(GetConVarFloat(Cv_Time), jarateFalse)
									TF2_AddCondition(i, TFCond_Jarated, GetConVarFloat(Cv_Time))
								}
							}
						}
					}
				}
			}
		}
	}

}


public Action:jarateFalse(Handle:timer, any:client)
{

	jarated[client] = false

}


public bool:CheckClientFlags(client)
{
	
	decl AdminFlag:aFlag
	new AdminId:admin = GetUserAdmin(client)
	
	FindFlagByChar(GetConVarInt(Cv_Flag), aFlag)
	
	if (GetAdminFlag(admin, aFlag)) return true
	else return false
	
}