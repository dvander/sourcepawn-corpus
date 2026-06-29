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
#define PLUGIN_VERSION "1.03"

new Handle:Cv_PluginEnabled, Handle:Cv_Threshold, Handle:Cv_NumHumiliations
new Float:BluSpawnCoords[3], Float:RedSpawnCoords[3]
new bool:humiliate[40], arrayTeam[40]
new humiliations[40], clientParticle[40][3], spawnsClient[40], humiliateTeams[4], spawnsRed, spawnsBlu

public Plugin:myinfo = 
{

	name = "Team Fortress 2 Teamswitch Humiliation",
	author = "simoneaolson",
	description = "Humiliates players switching to the other team when their team is losing, then sends them back to their original team",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
}


public OnPluginStart()
{

	AutoExecConfig(true, "tf_teamswitch_hum")
	
	CreateConVar("tf_teamswitch_hum_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cv_PluginEnabled = CreateConVar("tf_teamswitch_hum_enabled", "1", "Enabled/Disable the plugin (bool)", _, true, 0.0, true, 1.0)
	Cv_Threshold = CreateConVar("tf_teamswitch_hum_threshold", "0.80", "Threshold that determines if the client's team is losing (float)", _, true, 0.6, true, 0.99)
	Cv_NumHumiliations = CreateConVar("tf_teamswitch_hum_num_humiliations", "10", "Number of times to humiliate the client at the opposite spawn (int)", _, true, 1.0, true, 15.0)
	
	if (GetConVarBool(Cv_PluginEnabled))
	{
		HookEventEx("player_spawn", PlayerSpawn)
		HookEventEx("player_death", PlayerDeath, EventHookMode_Post)
		RegAdminCmd("jointeam", PlayerJoinTeam, 0)
	}

}


public OnMapStart()
{

	for (new i = 0; i < MaxClients; ++i)
	{
		humiliate[i] = false
		humiliations[i] = 0
		spawnsClient[i] = 0
	}
	
	humiliateTeams[2] = 0
	humiliateTeams[3] = 0
	spawnsRed = 0
	spawnsBlu = 0

}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new team = GetClientTeam(client)
	
	arrayTeam[client] = team
	++spawnsClient[client]
	
	if (team == 2 && spawnsRed == 0)
	{
		//Get coordinates of player
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", RedSpawnCoords)
		++spawnsRed
	}
	else if (team == 3 && spawnsBlu == 0)
	{
		//Get coordinates of player
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", BluSpawnCoords)
		++spawnsBlu
	}
	
	if (humiliate[client])
	{
		HumiliationTeleport(client, team)
		PrintCenterText(client, "You Cannot Stack The Teams! Humiliation Awaits!")
		CreateTimer(0.0, tauntClient, client)
	}

}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new team = GetClientTeam(client)
	
	if (humiliate[client])
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
		
		if (attacker != client)
		{
			//Reward attacker for killing humiliated client
			AttachParticle(attacker, 0, "achieved", "partyhat")
			AttachParticle(attacker, 1, "bday_1balloon", "partyhat")
			AttachParticle(attacker, 2, "bday_confetti", "partyhat")
			
			++humiliations[client]
			
			if (humiliations[client] == GetConVarInt(Cv_NumHumiliations))
			{
				humiliate[client] = false
				SetEntityMoveType(client, MOVETYPE_WALK)
				humiliateTeams[team] -= 1
				ServerCommand("tf_birthday 0")
			}
		}
		
		CreateTimer(0.1, RespawnPlayer, client)
		
	}
	else
	{
		if (team == 2)
		{
			if (humiliateTeams[3] > 0) TF2_RespawnPlayer(client)
		}
		else if (team == 3)
		{
			if (humiliateTeams[2] > 0) TF2_RespawnPlayer(client)
		}
	}

}


public Action:PlayerJoinTeam(client, args)
{

	if (GetConVarBool(Cv_PluginEnabled))
	{
		if (humiliate[client])
		{
			ChangeClientTeam(client, GetClientTeam(client))
			return Plugin_Handled
		}
		else
		{
			if (spawnsClient[client] >= 2)
			{
				new team = GetClientTeam(client)
				if (ShouldHumiliate(client, team))
				{
					ChangeClientTeam(client, GetClientTeam(client))
					++humiliateTeams[team]					
					Humiliate(client, team)
					return Plugin_Handled
				}
			}
		}
	}
	return Plugin_Continue

}


public bool:ShouldHumiliate(const client, const team)
{

	if (team == 2)
	{
		if (CalcTeamScore(2) / CalcTeamScore(3) <= GetConVarFloat(Cv_Threshold)) return true
		else return false
	}
	else if (team == 3)
	{
		if (CalcTeamScore(3) / CalcTeamScore(2) <= GetConVarFloat(Cv_Threshold)) return true
		else return false
	}
	else return false

}


public CalcTeamScore(const team)
{

	new score = 0, players = 0
	
	for (new i = 1; i < MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == team)
			{
				score += GetScore(i)
				++players
			}
		}
	}
	
	if (players > 0) return score
	else return 1

}


public GetScore(const client)
{

	return TF2_GetPlayerResourceData(client, TFResource_TotalScore)	

}


public Action:Humiliate(const client, const clientTeam)
{

	if (IsClientInGame(client))
	{
		decl team, String:name[64]
		
		ServerCommand("tf_birthday 1")
		humiliate[client] = true
		
		SetEntityMoveType(client, MOVETYPE_NONE)
		
		//Teleport douchebag trying to stack the teams
		HumiliationTeleport(client, clientTeam)
		
		//Spawn all dead players on opposite team
		for (new i = 1; i < MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				if (!IsPlayerAlive(i))
				{
					team = GetClientTeam(i)
					
					if (clientTeam == 2 && team == 3)
					{
						TF2_RespawnPlayer(i)
					}
					else if (clientTeam == 3 && team == 2)
					{
						TF2_RespawnPlayer(i)
					}
				}
			}
		}
		
		GetClientName(client, name, 64)
		PrintToChatAll("\x05%s \x04tried to stack the teams!", name)
		PrintCenterText(client, "You Cannot Stack The Teams! Humiliation Awaits!")
		CreateTimer(0.0, tauntClient, client)
	}

}


public Action:HumiliationTeleport(const client, const team)
{

	if (team == 2) TeleportEntity(client, BluSpawnCoords, NULL_VECTOR, NULL_VECTOR)
	else if (team == 3) TeleportEntity(client, RedSpawnCoords, NULL_VECTOR, NULL_VECTOR)

}


//Create Particle:
public Action:AttachParticle(const client, const particleNum, const String:effectName[], const String:attachTo[])
{
	
	clientParticle[client][particleNum] = CreateEntityByName("info_particle_system")
	new particle = clientParticle[client][particleNum]
	
	if (IsValidEdict(particle) && IsClientInGame(client))
	{
	
		decl String:tName[32], String:pName[12], Float:fPos[3]
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos)
		if (particleNum == 0) fPos[2] -= 75
		else if (particleNum == 1) fPos[2] -= 15
		TeleportEntity(particle, fPos, NULL_VECTOR, NULL_VECTOR)
		
		
		//Set Entity Keys & Spawn Entity (make sure dispatched entity name does not already exist, otherwise it will not work!!)
		Format(tName, sizeof(tName), "tf2hum_cl_%i", client)
		DispatchKeyValue(client, "targetname", tName)
		
		//Set Key Values
		Format(pName, sizeof(pName), "tf2hum_pe_%i_%i", particleNum, client)
		DispatchKeyValue(particle, "targetname", pName)
		DispatchKeyValue(particle, "parentname", tName)
		DispatchKeyValue(particle, "effect_name", effectName)
		DispatchSpawn(particle)
		
		//Set Entity Inputs
		SetVariantString("!activator")
		AcceptEntityInput(particle, "SetParent", client, particle, 0)
		SetVariantString(attachTo)
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "Start")
		
	}
	else
	{
		LogError("Failed to create info_particle_system!")
	}
	
}


public Action:tauntClient(Handle:timer, any:client)
{

	if (IsClientInGame(client) && IsPlayerAlive(client) && humiliate[client])
	{
		FakeClientCommand(client, "taunt")
		CreateTimer(2.3, tauntClient, client)
	}

}


public Action:RespawnPlayer(Handle:timer, any:client)
{

	TF2_RespawnPlayer(client)

}

public OnClientDisconnect(client)
{

	humiliate[client] = false
	humiliations[client] = 0
	spawnsClient[client] = 0
	humiliateTeams[arrayTeam[client]] = 0

}