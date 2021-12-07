#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <smlib>

enum ParticleAttachment_t
{
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_CUSTOMORIGIN_FOLLOW,	// Create at a custom origin, follow relative position to specified entity
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity
	PATTACH_EYES_FOLLOW,			// Create on eyes of the attached entity, and update to follow the entity

	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity

	MAX_PATTACH_TYPES,
};

public OnPluginStart()
{
	RegConsoleCmd("sm_dumpstringtables", Cmd_DumpStringtables);
	RegConsoleCmd("sm_dumpdispatcheffect", Cmd_DumpDispatchEffect);
	RegConsoleCmd("sm_bloodspray", Cmd_BloodSpray);
	RegConsoleCmd("sm_bloodimpact", Cmd_BloodImpact);
	RegConsoleCmd("sm_csblood", Cmd_CSBlood);
	RegConsoleCmd("sm_knifeslash", Cmd_KnifeSlash);
	RegConsoleCmd("sm_impact", Cmd_Impact);
	RegConsoleCmd("sm_burning", Cmd_Burning);
	RegConsoleCmd("sm_stopparticles", Cmd_StopParticles);
	RegConsoleCmd("sm_bloodspray2", Cmd_BloodSpray2);
	
	AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
	LoadTranslations("common.phrases");
}

public OnMapStart()
{
	PrecacheEffect("bloodspray");
	PrecacheEffect("bloodimpact");
	PrecacheEffect("csblood");
	PrecacheEffect("KnifeSlash");
	PrecacheEffect("Impact");
	PrecacheEffect("ParticleEffect");
	PrecacheEffect("ParticleEffectStop");
	PrecacheParticleEffect("burning_character");
}

public Action:Cmd_DumpStringtables(client, args)
{
	new iNum = GetNumStringTables();
	ReplyToCommand(client, "Listing %d stringtables:", iNum);
	decl String:sName[64];
	for(new i=0;i<iNum;i++)
	{
		GetStringTableName(i, sName, sizeof(sName));
		ReplyToCommand(client, "%d. %s (%d/%d strings)", i, sName, GetStringTableNumStrings(i), GetStringTableMaxStrings(i));
	}
	return Plugin_Handled;
}

public Action:Cmd_DumpDispatchEffect(client, args)
{
	new table = FindStringTable("EffectDispatch");
	if(table == INVALID_STRING_TABLE)
	{
		ReplyToCommand(client, "Couldn't find EffectDispatch stringtable.");
		return Plugin_Handled;
	}
	
	new iNum = GetStringTableNumStrings(table);
	decl String:sName[64];
	for(new i=0;i<iNum;i++)
	{
		ReadStringTable(table, i, sName, sizeof(sName));
		ReplyToCommand(client, "%d. %s", i, sName);
	}
	return Plugin_Handled;
}

public Action:Cmd_BloodSpray(client, args)
{
	if(args == 0 && !client)
	{
		ReplyToCommand(client, "Usage sm_bloodspray <name|steamid|#userid>");
		return Plugin_Handled;
	}
	
	decl String:sTarget[64];
	GetCmdArgString(sTarget, sizeof(sTarget));
	new iTarget = client;
	
	if(args > 0)
	{
		iTarget = FindTarget(client, sTarget, false, false);
		if(iTarget == -1)
			return Plugin_Handled;
	}
	
	new Float:fOrigin[3], Float:fAngles[3];
	GetClientEyePosition(iTarget, fOrigin);
	GetClientEyeAngles(iTarget, fAngles);
	
	TE_SetupEffect_BloodSpray(fOrigin, fAngles, 247, 10, 1);
	TE_SendToAllPVS(fOrigin);
	return Plugin_Handled;
}

public Action:Cmd_BloodSpray2(client, args)
{
	new Float:fOrigin[3] = {264.710175, 2187.193604, -32.758202};
	new Float:fAngles[3] = {5.694931, 179.667740, 0.000000};

	TE_SetupEffect_BloodSpray(fOrigin, fAngles, 247, 10, 1);
	TE_SendToAllPVS(fOrigin);
	return Plugin_Handled;
}

public Action:Cmd_BloodImpact(client, args)
{
	if(args == 0 && !client)
	{
		ReplyToCommand(client, "Usage sm_bloodimpact <name|steamid|#userid>");
		return Plugin_Handled;
	}
	
	decl String:sTarget[64];
	GetCmdArgString(sTarget, sizeof(sTarget));
	new iTarget = client;
	
	if(args > 0)
	{
		iTarget = FindTarget(client, sTarget, false, false);
		if(iTarget == -1)
			return Plugin_Handled;
	}
	
	new Float:fOrigin[3], Float:fAngles[3];
	GetClientEyePosition(iTarget, fOrigin);
	GetClientEyeAngles(iTarget, fAngles);
	
	TE_SetupEffect_BloodImpact(fOrigin, fAngles, 247, 247);
	TE_SendToAllPVS(fOrigin);
	return Plugin_Handled;
}

public Action:Cmd_CSBlood(client, args)
{
	if(args == 0 && !client)
	{
		ReplyToCommand(client, "Usage sm_csblood <name|steamid|#userid>");
		return Plugin_Handled;
	}
	
	decl String:sTarget[64];
	GetCmdArgString(sTarget, sizeof(sTarget));
	new iTarget = client;
	
	if(args > 0)
	{
		iTarget = FindTarget(client, sTarget, false, false);
		if(iTarget == -1)
			return Plugin_Handled;
	}
	
	new Float:fOrigin[3], Float:fAngles[3];
	GetClientEyePosition(iTarget, fOrigin);
	GetClientEyeAngles(iTarget, fAngles);
	
	TE_SetupEffect_CSBlood(fOrigin, fAngles, 247, iTarget);
	TE_SendToAllPVS(fOrigin);
	return Plugin_Handled;
}

public Action:Cmd_Burning(client, args)
{
	if(args == 0 && !client)
	{
		ReplyToCommand(client, "Usage sm_burning <name|steamid|#userid>");
		return Plugin_Handled;
	}
	
	decl String:sTarget[64];
	GetCmdArgString(sTarget, sizeof(sTarget));
	new iTarget = client;
	
	if(args > 0)
	{
		iTarget = FindTarget(client, sTarget, false, false);
		if(iTarget == -1)
			return Plugin_Handled;
	}
	
	TE_SetupParticleEffect("burning_character", PATTACH_WORLDORIGIN, iTarget);
	TE_SendToAll();
	return Plugin_Handled;
}

public Action:Cmd_StopParticles(client, args)
{
	if(args == 0 && !client)
	{
		ReplyToCommand(client, "Usage sm_stopparticles <name|steamid|#userid>");
		return Plugin_Handled;
	}
	
	decl String:sTarget[64];
	GetCmdArgString(sTarget, sizeof(sTarget));
	new iTarget = client;
	
	if(args > 0)
	{
		iTarget = FindTarget(client, sTarget, false, false);
		if(iTarget == -1)
			return Plugin_Handled;
	}
	
	TE_SetupStopParticleEffects(iTarget);
	TE_SendToAll();
	return Plugin_Handled;
}

public Action:Cmd_KnifeSlash(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Ingame only");
		return Plugin_Handled;
	}
	
	new Float:fOrigin[3], Float:fAngles[3], Float:fEndPoint[3];
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, fAngles);
	
	TR_TraceRayFilter(fOrigin, fAngles, MASK_ALL, RayType_Infinite, ___TE_FilterNoPlayers);
	if(TR_DidHit())
		TR_GetEndPosition(fEndPoint);
	
	TE_SetupEffect_KnifeSlash(fEndPoint, fOrigin, fAngles);
	TE_SendToAllPVS(fOrigin);
	return Plugin_Handled;
}

public Action:Cmd_Impact(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Ingame only");
		return Plugin_Handled;
	}
	
	new Float:fOrigin[3], Float:fAngles[3], Float:fEndPoint[3];
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, fAngles);
	
	TR_TraceRayFilter(fOrigin, fAngles, MASK_ALL, RayType_Infinite, ___TE_FilterNoPlayers);
	if(TR_DidHit())
	{
		TR_GetEndPosition(fEndPoint);
		TE_SetupEffect_Impact(fEndPoint, fOrigin, 0, DMG_ENERGYBEAM, TR_GetHitGroup(), TR_GetEntityIndex());
		TE_SendToAllPVS(fOrigin);
	}
	
	return Plugin_Handled;
}

public Action:TE_OnEffectDispatch(const String:te_name[], const Players[], numClients, Float:delay)
{
	new iEffectIndex = TE_ReadNum("m_iEffectName");
	new String:sEffectName[64];
	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	PrintToServer("EffectDispatch tempent to %d players! %d: %s", numClients, iEffectIndex, sEffectName);
	
	new nHitBox = TE_ReadNum("m_nHitBox");
	
	if(StrEqual(sEffectName, "ParticleEffect"))
	{
		new String:sParticleEffectName[64];
		GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
		PrintToServer("ParticleEffect %d: %s", nHitBox, sParticleEffectName);
	}
	
	new Float:vOrigin[3], Float:vStart[3], Float:vAngles[3], Float:vNormal[3];
	new bool:bHasOtherEnt = GuessSDKVersion() >= SOURCE_SDK_CSGO;
	if(!bHasOtherEnt)
	{
		vOrigin[0] = TE_ReadFloat("m_vOrigin[0]");
		vOrigin[1] = TE_ReadFloat("m_vOrigin[1]");
		vOrigin[2] = TE_ReadFloat("m_vOrigin[2]");
		vStart[0] = TE_ReadFloat("m_vStart[0]");
		vStart[1] = TE_ReadFloat("m_vStart[1]");
		vStart[2] = TE_ReadFloat("m_vStart[2]");
	}
	else
	{
		vOrigin[0] = TE_ReadFloat("m_vOrigin.x");
		vOrigin[1] = TE_ReadFloat("m_vOrigin.y");
		vOrigin[2] = TE_ReadFloat("m_vOrigin.z");
		vStart[0] = TE_ReadFloat("m_vStart.x");
		vStart[1] = TE_ReadFloat("m_vStart.y");
		vStart[2] = TE_ReadFloat("m_vStart.z");
	}
	TE_ReadVector("m_vAngles", vAngles);
	TE_ReadVector("m_vNormal", vNormal);
	new fFlags = TE_ReadNum("m_fFlags");
	new Float:flMagnitude = TE_ReadFloat("m_flMagnitude");
	new Float:flScale = TE_ReadFloat("m_flScale");
	new nAttachmentIndex = TE_ReadNum("m_nAttachmentIndex");
	new nSurfaceProp = TE_ReadNum("m_nSurfaceProp");
	new nMaterial = TE_ReadNum("m_nMaterial");
	new nDamageType = TE_ReadNum("m_nDamageType");
	new entindex = TE_ReadNum("entindex");
	new nOtherEntIndex;
	if(bHasOtherEnt)
		nOtherEntIndex = TE_ReadNum("m_nOtherEntIndex");
	new nColor = TE_ReadNum("m_nColor");
	new Float:flRadius = TE_ReadFloat("m_flRadius");
	
	
	/*new bCustomColors = TE_ReadNum("m_bCustomColors");
	new Float:vecColor1[3], Float:vecColor2[3], Float:vecOffset[3];
	TE_ReadVector("m_CustomColors.m_vecColor1", vecColor1);
	TE_ReadVector("m_CustomColors.m_vecColor2", vecColor2);
	new bControlPoint1 = TE_ReadNum("m_bControlPoint1");
	new eParticleAttachment = TE_ReadNum("m_ControlPoint1.m_eParticleAttachment");
	vecOffset[0] = TE_ReadFloat("m_ControlPoint1.m_vecOffset[0]");
	vecOffset[1] = TE_ReadFloat("m_ControlPoint1.m_vecOffset[1]");
	vecOffset[2] = TE_ReadFloat("m_ControlPoint1.m_vecOffset[2]");*/
	
	PrintToServer("vOrigin [%f,%f,%f], vStart [%f,%f,%f], vAngles [%f,%f,%f], vNormal [%f,%f,%f]", vOrigin[0], vOrigin[1], vOrigin[2], vStart[0], vStart[1], vStart[2], vAngles[0], vAngles[1], vAngles[2], vNormal[0], vNormal[1], vNormal[2]);
	PrintToServer("fFlags %d, flMagnitude %f, flScale %f, nAttachmentIndex %d, nSurfaceProp %d, nMaterial %d, nDamageType %d, nHitBox %d, entindex %d, nColor %d, flRadius %f", fFlags, flMagnitude, flScale, nAttachmentIndex, nSurfaceProp, nMaterial, nDamageType, nHitBox, entindex, nColor, flRadius);
	if(bHasOtherEnt)
		PrintToServer("nOtherEntIndex %d", nOtherEntIndex);
	/*PrintToServer("bCustomColors %d, bControlPoint1 %d", bCustomColors, bControlPoint1);
	
	if(bCustomColors)
		PrintToServer("vecColor1 [%f,%f,%f], vecColor2 [%f,%f,%f]", vecColor1[0], vecColor1[1], vecColor1[2], vecColor2[0], vecColor2[1], vecColor2[2]);
	if(bControlPoint1)
		PrintToServer("eParticleAttachment %d, vecOffset [%f,%f,%f]", eParticleAttachment, vecOffset[0], vecOffset[1], vecOffset[2]);*/
	
	return Plugin_Continue;
}

enum {
	DONT_BLEED = -1,
	
	BLOOD_COLOR_RED = 0,
	BLOOD_COLOR_YELLOW,
	BLOOD_COLOR_GREEN,
	BLOOD_COLOR_MECH,
};
#define SF_BLOOD_RANDOM		0x0001
#define SF_BLOOD_STREAM		0x0002
#define SF_BLOOD_PLAYER		0x0004
#define SF_BLOOD_DECAL		0x0008
#define SF_BLOOD_CLOUD		0x0010
#define SF_BLOOD_DROPS		0x0020
#define SF_BLOOD_GORE		0x0040

stock TE_SetupEffect_BloodSpray(const Float:pos[3], const Float:dir[3], color, amount, flags)
{
	if(color == DONT_BLEED)
		return;
	
	TE_Start("EffectDispatch");
	if(GuessSDKVersion() < SOURCE_SDK_CSGO)
		TE_WriteFloatArray("m_vOrigin[0]", pos, 3);
	else
		TE_WriteFloatArray("m_vOrigin.x", pos, 3);
	TE_WriteVector("m_vNormal", dir);
	TE_WriteFloat("m_flScale", float(amount));
	TE_WriteNum("m_fFlags", flags);
	TE_WriteNum("m_nColor", color);
	
	// DispatchEffect
	TE_WriteNum("m_iEffectName", GetEffectIndex("bloodspray"));
}

stock TE_SetupEffect_CSBlood(const Float:pos[3], const Float:dir[3], amount, entindex)
{
	TE_Start("EffectDispatch");
	if(GuessSDKVersion() < SOURCE_SDK_CSGO)
		TE_WriteFloatArray("m_vOrigin[0]", pos, 3);
	else
		TE_WriteFloatArray("m_vOrigin.x", pos, 3);
	TE_WriteVector("m_vNormal", dir);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flMagnitude", float(amount));
	TE_WriteNum("entindex", entindex);
	
	// DispatchEffect
	TE_WriteNum("m_iEffectName", GetEffectIndex("csblood"));
}

stock TE_SetupEffect_BloodImpact(const Float:origin[3], const Float:direction[3], color, amount)
{
	if(color == DONT_BLEED || amount == 0)
		return;
	
	// scale up blood effect in multiplayer for better visibility
	amount *= 5;
	
	if(amount > 255)
		amount = 255;
	
	TE_Start("EffectDispatch");
	if(GuessSDKVersion() < SOURCE_SDK_CSGO)
		TE_WriteFloatArray("m_vOrigin[0]", origin, 3);
	else
		TE_WriteFloatArray("m_vOrigin.x", origin, 3);
	TE_WriteVector("m_vNormal", direction);
	TE_WriteFloat("m_flScale", float(amount));
	TE_WriteNum("m_nColor", color);
	TE_WriteNum("m_iEffectName", GetEffectIndex("bloodimpact"));
}

stock TE_SetupEffect_KnifeSlash(const Float:origin[3], const Float:playerposition[3], const Float:playerangles[3], flags = 1, surfaceprop = 31, damagetype = 4)
{
	TE_Start("EffectDispatch");
	if(GuessSDKVersion() < SOURCE_SDK_CSGO)
	{
		TE_WriteFloatArray("m_vOrigin[0]", origin, 3);
		TE_WriteFloatArray("m_vStart[0]", playerposition, 3);
	}
	else
	{
		TE_WriteFloatArray("m_vOrigin.x", origin, 3);
		TE_WriteFloatArray("m_vStart.x", playerposition, 3);
	}
	TE_WriteVector("m_vAngles", playerangles);
	TE_WriteNum("m_fFlags", flags);
	TE_WriteNum("m_nSurfaceProp", surfaceprop);
	TE_WriteNum("m_nDamageType", damagetype);
	TE_WriteNum("m_iEffectName", GetEffectIndex("KnifeSlash"));
}

stock TE_SetupEffect_Impact(const Float:endpos[3], const Float:startpos[3], surfaceprop, damagetype, hitbox, entindex)
{
	TE_Start("EffectDispatch");
	if(GuessSDKVersion() < SOURCE_SDK_CSGO)
	{
		TE_WriteFloatArray("m_vOrigin[0]", endpos, 3);
		TE_WriteFloatArray("m_vStart[0]", startpos, 3);
	}
	else
	{
		TE_WriteFloatArray("m_vOrigin.x", endpos, 3);
		TE_WriteFloatArray("m_vStart.x", startpos, 3);
	}
	TE_WriteNum("m_nHitBox", hitbox);
	TE_WriteNum("m_nSurfaceProp", surfaceprop);
	TE_WriteNum("m_nDamageType", damagetype);
	TE_WriteNum("entindex", entindex);
	TE_WriteNum("m_iEffectName", GetEffectIndex("Impact"));
}


#define PARTICLE_DISPATCH_FROM_ENTITY		(1<<0)
#define PARTICLE_DISPATCH_RESET_PARTICLES	(1<<1)

stock TE_SetupParticleEffect(const String:sParticleName[], ParticleAttachment_t:iAttachType, entity = 0)//, const Float:fOrigin[3] = NULL_VECTOR, const Float:fAngles[3] = NULL_VECTOR, const Float:fStart[3] = NULL_VECTOR, iAttachmentPoint = -1, bool:bResetAllParticlesOnEntity = false)
{
	TE_Start("EffectDispatch");
	
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
	
	new fFlags;
	if(entity > 0)
	{
		//if(fOrigin == NULL_VECTOR)
		//{
			new Float:fEntityOrigin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fEntityOrigin);
			if(GuessSDKVersion() < SOURCE_SDK_CSGO)
				TE_WriteFloatArray("m_vOrigin[0]", fEntityOrigin, 3);
			else
				TE_WriteFloatArray("m_vOrigin.x", fEntityOrigin, 3);
		//}
		if(iAttachType != PATTACH_WORLDORIGIN)
		{
			TE_WriteNum("entindex", entity);
			fFlags |= PARTICLE_DISPATCH_FROM_ENTITY;
		}
	}
	
	/*if(fOrigin != NULL_VECTOR)
		TE_WriteFloatArray("m_vOrigin[0]", fOrigin, 3);
	if(fStart != NULL_VECTOR)
		TE_WriteFloatArray("m_vStart[0]", fStart, 3);
	if(fAngles != NULL_VECTOR)
		TE_WriteVector("m_vAngles", fAngles);*/
	
	//if(bResetAllParticlesOnEntity)
	//	fFlags |= PARTICLE_DISPATCH_RESET_PARTICLES;
	
	TE_WriteNum("m_fFlags", fFlags);
	TE_WriteNum("m_nDamageType", _:iAttachType);
	TE_WriteNum("m_nAttachmentIndex", -1);
	
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffect"));
}

stock TE_SetupStopParticleEffects(entity)
{
	TE_Start("EffectDispatch");
	
	if(entity > 0)
		TE_WriteNum("entindex", entity);
	
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
}

stock TE_SetupStopParticleEffect(entity, const String:sParticleName[])
{
	TE_Start("EffectDispatch");
	
	if(entity > 0)
		TE_WriteNum("entindex", entity);
	
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
}

// cheap imitation. should use new GetClientsInRange native in SM1.8
stock TE_SendToAllPVS(const Float:origin[3], Float:delay = 0.0)
{
	new clients[MaxClients];
	new total;
	new Float:fEyePosition[3];
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		// Always add the sourcetv client.
		if(!IsClientSourceTV(i) && !IsClientReplay(i))
		{
			GetClientEyePosition(i, fEyePosition);
			TR_TraceRayFilter(origin, fEyePosition, MASK_VISIBLE, RayType_EndPoint, ___TE_FilterNoPlayers);
			if(TR_DidHit())
				continue;
		}
		
		clients[total++] = i;
	}
	TE_Send(clients, total, delay);
}

public bool:___TE_FilterNoPlayers(entity, contentsMask)
{
	if(entity > 0 && entity <= MaxClients)
		return false;
	return true;
}

//-----------------------------------------------------------------------------
// Precaches an effect (used by DispatchEffect)
//-----------------------------------------------------------------------------
stock PrecacheEffect(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	new bool:save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

//-----------------------------------------------------------------------------
// Converts a previously precached effect into an index
//-----------------------------------------------------------------------------
stock GetEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
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

stock PrecacheParticleEffect(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	new bool:save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock GetParticleEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
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