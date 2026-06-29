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
#include <sdkhooks>
#define PLUGIN_VERSION "1.04"

new Handle:Cv_PluginEnabled, Handle:Cv_Distance, Handle:Cv_Time, Handle:Cv_OnlyAdmins, Handle:Cv_Flag
new bool:jarated[40], bool:g_bEnabled, bool:g_bOnlyAdmins, g_flag, Float:g_distance, Float:g_time

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
	
	g_bEnabled = GetConVarBool(Cv_PluginEnabled)
	g_distance = GetConVarFloat(Cv_Distance)
	g_time = GetConVarFloat(Cv_Time)
	g_bOnlyAdmins = GetConVarBool(Cv_OnlyAdmins)
	g_flag = GetConVarInt(Cv_Flag)
	
	if (GetConVarBool(Cv_PluginEnabled))
	{
		HookEventEx("player_hurt", PlayerHurt, EventHookMode_Pre)
		HookConVarChange(Cv_PluginEnabled, cvPluginEnabled)
		HookConVarChange(Cv_Distance, cvDistance)
		HookConVarChange(Cv_Time, cvTime)
		HookConVarChange(Cv_OnlyAdmins, cvOnlyAdmins)
		HookConVarChange(Cv_Flag, cvFlag)
	}
	
}


public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage)
}


public OnMapStart()
{

	for (new i = 1; i < 40; ++i)
	{
	
		jarated[i] = false
	
	}

}


public cvPluginEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{

	g_bEnabled = GetConVarBool(Cv_PluginEnabled)

}


public cvOnlyAdmins(Handle:convar, const String:oldValue[], const String:newValue[])
{

	g_bOnlyAdmins = GetConVarBool(Cv_OnlyAdmins)

}


public cvDistance(Handle:convar, const String:oldValue[], const String:newValue[])
{

	g_distance = GetConVarFloat(Cv_Distance)

}


public cvTime(Handle:convar, const String:oldValue[], const String:newValue[])
{

	g_time = GetConVarFloat(Cv_Time)

}


public cvFlag(Handle:convar, const String:oldValue[], const String:newValue[])
{

	g_flag = GetConVarInt(Cv_Flag)

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

	if (g_bEnabled)
	{
		if (StrEqual(weaponname, "tf_weapon_jar"))
		{
			CreateTimer(0.0, FindJar, client)
		}
	}
	return Plugin_Continue
	
}


public Action:FindJar(Handle:timer, const any:client)
{

	decl bool:go
	new index = -1, Handle:pack
	
	while ((index = FindEntityByClassname(index, "tf_weapon_jar")) != -1)
	{
		if (client == GetEntPropEnt(index, Prop_Send, "m_hOwner"))
		{
			//Check if only adminst can jarate teammates
			if (g_bOnlyAdmins)
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
					CreateDataTimer(0.3, JaratePlayers, pack)
					WritePackCell(pack, client)
					WritePackCell(pack, index)
				}
			}
		}
	}

}


public Action:JaratePlayers(Handle:timer, Handle:dataPack)
{

	decl Float:jarOrigin[3], Float:throwerOrigin[3], Float:clientOrigin[3], Float:distance
	ResetPack(dataPack)
	new client = ReadPackCell(dataPack), index = ReadPackCell(dataPack), team = GetClientTeam(client)
	
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
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientOrigin)
				
				distance = GetVectorDistance(jarOrigin, clientOrigin)
				if (distance <= g_distance)
				{
					jarated[i] = true
					CreateTimer(g_time, jarateFalse)
					TF2_AddCondition(i, TFCond_Jarated, g_time)
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
	
	FindFlagByChar(g_flag, aFlag)
	
	if (GetAdminFlag(admin, aFlag)) return true
	else return false
	
}


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{

	if (jarated[victim])
	{
		damage *= 0.65
		return Plugin_Changed
	}
	return Plugin_Continue

}