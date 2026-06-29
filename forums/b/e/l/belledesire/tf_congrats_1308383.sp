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
#include <sdktools>
#define PLUGIN_VERSION "1.04"

new Handle:Cv_PluginEnabled
new clientParticle[15], firstClient, spawns[MAXPLAYERS+1]


public Plugin:myinfo = 
{

	name = "TF2 Congrats",
	author = "simoneaolson (modified by belledesire)",
	description = "First person to join the server is rewarded on spawn",
	version = PLUGIN_VERSION,
	url = "http://http://www.sourcemod.net/plugins.php?search=1&author=simoneaolson"
	
}


public OnPluginStart()
{

	LoadTranslations("congrats.phrases")
	
	CreateConVar("tf_congrats_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cv_PluginEnabled = CreateConVar("tf_congrats_enabled", "1", "Enabled/Disable Clients being rewarded (bool)", _, true, 0.0, true, 1.0)
	
	HookEventEx("player_spawn", PlayerSpawn)

}


public OnMapStart()
{
	new i = 0;
	for (; i<MAXPLAYERS+1; i++)
	{
		spawns[i] = 0;
	}
	firstClient = 0;

}


public OnClientPutInServer(client)
{
	if ((IsClientInGame(client)) && (!IsFakeClient(client)) && (firstClient == 0)) firstClient = client
}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (GetConVarBool(Cv_PluginEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		if (spawns[client] == 2)
		{
			if (firstClient != -1 && client == firstClient)
			{
				firstClient = -1
				//Attach particle effects:
				CreateTimer(1.2, TimedParticles, client)
			}
		}
		++spawns[client]
	}

}


public Action:TimedParticles(Handle:timer, any:client)
{

	PrintHintText(client, "%t", "Message")
	HoldCenterMessage(client, 3)
	
	new inc = 0
	new String:particle[30]
	new Handle:particleCfg = OpenFile("cfg/sourcemod/tf_congrats_particles.cfg", "r")
	
	while (!IsEndOfFile(particleCfg) && inc < 15)
	{
		ReadFileLine(particleCfg, particle, 30)
		//PrintToChatAll("%s", particle)
		AttachParticle(client, inc, particle, "partyhat")
		++inc
	}
	
	CloseHandle(particleCfg)

}


public Action:HoldCenterMessage(client, time)
{

	if (time > 1) PrintCenterText(client, "%t", "Message")
	else HoldCenterMessage(client, time - 1)

}


//Create Particle:
public Action:AttachParticle(const client, const particleNum, const String:effectName[], const String:attachTo[])
{
	
	clientParticle[particleNum] = CreateEntityByName("info_particle_system")
	new particle = clientParticle[particleNum]
	
	if (IsValidEdict(particle) && IsClientInGame(client))
	{
	
		decl String:tName[32], String:pName[12], Float:fPos[3]
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos)
		if (particleNum == 0) fPos[2] -= 75
		else if (particleNum == 1) fPos[2] -= 15
		TeleportEntity(particle, fPos, NULL_VECTOR, NULL_VECTOR)
		
		
		//Set Entity Keys & Spawn Entity (make sure dispatched entity name does not already exist, otherwise it will not work!!)
		Format(tName, sizeof(tName), "tf2cg_cl_%i", client)
		DispatchKeyValue(client, "targetname", tName)
		
		//Set Key Values
		Format(pName, sizeof(pName), "tf2cg_pe_%i_%i", particleNum, client)
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