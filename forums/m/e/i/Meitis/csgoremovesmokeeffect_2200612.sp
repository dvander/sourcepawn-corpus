#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "CS:GO: Remove Smoke",
	author = "Peace-Maker",
	description = "Demonstrates how to remove the smokegrenade smoke in CS:GO",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de"
}

public OnPluginStart()
{
	HookEvent("smokegrenade_detonate", Event_OnSmokegrenadeDetonate, EventHookMode_Pre);
	
	AddNormalSoundHook(NormalSHook);
	
	AddTempEntHook("EffectDispatch", TE_EffectDispatch);
}

public Action:Event_OnSmokegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Remove the smokegrenade_projectile
	/*new entity = GetEventInt(event, "entityid");
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "Kill");*/
	
	// Don't tell the client where the smoke would have exploded.
	// That way it won't fade the screen to grey completely, if the player is too close to the smoke's origin.
	SetEventBroadcast(event, true);
	dontBroadcast = true;
	return Plugin_Changed;
}

public Action:NormalSHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	// Block the explosion sound.
	if(StrEqual(sample, "weapons/smokegrenade/sg_explode.wav"))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:TE_EffectDispatch(const String:te_name[], const Players[], numClients, Float:delay)
{
	new iEffectIndex = TE_ReadNum("m_iEffectName");
	new String:sEffectName[64];
	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	
	if(StrEqual(sEffectName, "ParticleEffect"))
	{
		// The particle effect index is stored in m_nHitBox when dispatching a ParticleEffect.
		new nHitBox = TE_ReadNum("m_nHitBox");
		
		new String:sParticleEffectName[64];
		GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
		// Don't show the smoke!
		if(StrEqual(sParticleEffectName, "explosion_smokegrenade", false))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock GetEffectName(index, String:sEffectName[], maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}

stock GetParticleEffectName(index, String:sEffectName[], maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}