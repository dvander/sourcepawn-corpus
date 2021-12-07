/*  
*    Copyright (C) 2019  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.2"

#define INT_(%1) view_as<int>(%1)

#define ENTITY_SAFE_LIMIT 1900

#define ZOMBIECLASS_BOOMER	2
#define GIBMODELS 5
#define MAX_FLESH_PARTS 12 //changeme for more flesh parts bewarned setting too high will make some gibs despawn instantly depends on client settings from testing 15 total seems to be consisten regardless of settings

enum BoomerGib
{
	BoomerGib_Head = 0,
	BoomerGib_Arm,
	BoomerGib_Flesh1,
	BoomerGib_Flesh2,
	BoomerGib_Flesh3
}

char g_sBoomerGibModel[GIBMODELS][] =
{
	"models/infected/limbs/exploded_boomer_head.mdl",
	"models/infected/limbs/exploded_boomer_rarm.mdl",// only right arm exists O.o
	"models/infected/limbs/exploded_boomer_steak1.mdl",
	"models/infected/limbs/exploded_boomer_steak2.mdl",
	"models/infected/limbs/exploded_boomer_steak3.mdl"
};


float g_flTickInterval;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion CurrentEngine = GetEngineVersion();
	if(CurrentEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2]boomer_gibs_restore",
	author = "Lux",
	description = "Replicates the clientside cheat z_boomer_gibs",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/L4D_boomer_gibs_restore"
};

public void OnPluginStart()
{
	CreateConVar("boomer_gibs_restore_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_death", ePlayerDeath);
}

public void OnMapStart()
{
	g_flTickInterval = GetTickInterval();
	
	for(int i; i < sizeof(g_sBoomerGibModel); i++)
		PrecacheModel(g_sBoomerGibModel[i], true);
}

public void ePlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(iVictim < 1 || !IsClientInGame(iVictim) || GetClientTeam(iVictim) != 3)
		return;
	
	if(GetEntProp(iVictim, Prop_Send, "m_zombieClass") != ZOMBIECLASS_BOOMER)
		return;
	
	static float vecPos[3];
	static float vecAng[3];
	
	GetEntityMidOrigin(iVictim, vecPos);
	GetClientAbsAngles(iVictim, vecAng);
	
	SpawnBoomerGibs(vecPos, vecAng);
	
	TE_SetupExplodeForce(vecPos, 75.0, 20.0);
	TE_SendToAll(g_flTickInterval);
}

void SpawnBoomerGibs(float vecPos[3], float vecAng[3])
{
	static float vecPosCopy[3];
	static float vecAngCopy[3];
	
	vecPosCopy = vecPos;
	vecPosCopy[2] += 30.0;
	if(CreateBoomerGib(vecPosCopy, vecAng, BoomerGib_Head))//head
		return;
	
	vecAngCopy = vecAng;
	vecPosCopy = vecPos;
	vecAngCopy[1] += 45.0;
	
	GetDirection(vecPosCopy, vecAngCopy, 30.0);
	if(CreateBoomerGib(vecPosCopy, vecAng, BoomerGib_Arm))//arm
		return;
	
	vecAngCopy = vecAng;
	vecPosCopy = vecPos;
	vecAngCopy[1] += -45.0;
	
	GetDirection(vecPosCopy, vecAngCopy, 30.0);
	if(CreateBoomerGib(vecPosCopy, vecAng, BoomerGib_Arm))//flesh parts
		return;
	
	int iFleshyParts = GetRandomInt(MAX_FLESH_PARTS / 2, MAX_FLESH_PARTS);// add random amount
	for(int i = 1; i <= iFleshyParts; i++)
	{
		vecPosCopy[0] = vecPos[0] + GetRandomFloat(-20.0, 20.0);
		vecPosCopy[1] = vecPos[1] + GetRandomFloat(-20.0, 20.0);
		vecPosCopy[2] = vecPos[2] + GetRandomFloat(-20.0, 20.0);
		
		if(CreateBoomerGib(vecPosCopy, vecAng, view_as<BoomerGib>(GetRandomInt(INT_(BoomerGib_Flesh1), INT_(BoomerGib_Flesh3)))))
			return;
	}
}

bool CreateBoomerGib(float vecPos[3], float vecAng[3], BoomerGib GibType)
{
	int iGib = CreateEntityByName("prop_dynamic_override");
	if(iGib == -1)
		return false;
	
	bool bAtEntityLimit = (iGib >= ENTITY_SAFE_LIMIT);
	
	DispatchKeyValue(iGib, "model", g_sBoomerGibModel[GibType]);
	DispatchKeyValue(iGib, "solid", "0");
	
	TeleportEntity(iGib, vecPos, vecAng, NULL_VECTOR);
	DispatchSpawn(iGib);
	
	
	static char sBuf[64];
	Format(sBuf, sizeof(sBuf), "OnUser1 !self:BecomeRagdoll::%f:-1", g_flTickInterval);
	SetVariantString(sBuf);
	AcceptEntityInput(iGib, "AddOutput");
	AcceptEntityInput(iGib, "FireUser1");
	
	return bAtEntityLimit;
}

void GetEntityMidOrigin(int iEntity, float fOrigin[3])
{
	float fMins[3];
	float fMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMaxs);
	
	fOrigin[0] += (fMins[0] + fMaxs[0]) * 0.5;
	fOrigin[1] += (fMins[1] + fMaxs[1]) * 0.5;
	fOrigin[2] += (fMins[2] + fMaxs[2]) * 0.5;
}

void GetDirection(float vecPos[3], float vecAng[3], float flDistance=0.0)
{
	float vecDirection[3];
	GetAngleVectors(vecAng, vecDirection, NULL_VECTOR, NULL_VECTOR);

	vecPos[0] = vecPos[0] + vecDirection[0] * flDistance;
	vecPos[1] = vecPos[1] + vecDirection[1] * flDistance;
	vecPos[2] = vecPos[2] + vecDirection[2] * flDistance;
}

stock void TE_SetupExplodeForce(float vecPos[3], float flRadius, float flForce)
{
	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ExplosionForce");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ExplosionForce indexes");
		
	}
	
	TE_Start("EffectDispatch");
	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteFloat("m_vOrigin.x", vecPos[0]);
	TE_WriteFloat("m_vOrigin.y", vecPos[1]);
	TE_WriteFloat("m_vOrigin.z", vecPos[2]);
	TE_WriteFloat("m_flRadius", flRadius);
	TE_WriteFloat("m_flMagnitude", flForce);
}

//Credit smlib https://github.com/bcserv/smlib
/*
 * Rewrite of FindStringIndex, because in my tests
 * FindStringIndex failed to work correctly.
 * Searches for the index of a given string in a string table. 
 * 
 * @param tableidx		A string table index.
 * @param str			String to find.
 * @return				String index if found, INVALID_STRING_INDEX otherwise.
 */
stock int __FindStringIndex2(int tableidx, const char[] str)
{
	char buf[1024];

	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		
		if (StrEqual(buf, str)) {
			return i;
		}
	}
	
	return INVALID_STRING_INDEX;
}