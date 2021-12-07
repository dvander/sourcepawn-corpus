public PlVers:__version =
{
	version = 5,
	filevers = "1.5.2",
	date = "06/30/2014",
	time = "01:35:26"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new Float:MinNadeHull[3] =
{
	-1071644672, ...
};
new Float:MaxNadeHull[3] =
{
	1075838976, ...
};
new Float:SpinVel[3] =
{
	0, 0, 1128792064
};
new Float:SmokeOrigin[3] =
{
	-1041235968, 0, 0
};
new Float:SmokeAngle[3] =
{
	0, -1020002304, 0
};
new Float:g_fMinS[3] =
{
	-1044381696, ...
};
new Float:g_fMaxS[3] =
{
	1103101952, ...
};
new NadeDamage;
new NadeRadius;
new Float:NadeSpeed;
new Handle:hDamage;
new Handle:hRadius;
new Handle:hSpeed;
public Plugin:myinfo =
{
	name = "Misil",
	description = "Turns projectile weapons missiles",
	author = "Franc1sco franug",
	version = "1.0",
	url = ""
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbReadRepeatedInt");
	MarkNativeAsOptional("PbReadRepeatedFloat");
	MarkNativeAsOptional("PbReadRepeatedBool");
	MarkNativeAsOptional("PbReadRepeatedString");
	MarkNativeAsOptional("PbReadRepeatedColor");
	MarkNativeAsOptional("PbReadRepeatedAngle");
	MarkNativeAsOptional("PbReadRepeatedVector");
	MarkNativeAsOptional("PbReadRepeatedVector2D");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	VerifyCoreVersion();
	return 0;
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) == 0;
}

ScaleVector(Float:vec[3], Float:scale)
{
	new var1 = vec;
	var1[0] = var1[0] * scale;
	vec[1] *= scale;
	vec[2] *= scale;
	return 0;
}

MakeVectorFromPoints(Float:pt1[3], Float:pt2[3], Float:output[3])
{
	output[0] = pt2[0] - pt1[0];
	output[1] = pt2[1] - pt1[1];
	output[2] = pt2[2] - pt1[2];
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

GetEntSendPropOffs(ent, String:prop[], bool:actual)
{
	decl String:cls[64];
	if (!GetEntityNetClass(ent, cls, 64))
	{
		return -1;
	}
	if (actual)
	{
		return FindSendPropInfo(cls, prop, 0, 0, 0);
	}
	return FindSendPropOffs(cls, prop);
}

SetEntityMoveType(entity, MoveType:mt)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_MoveType");
		}
		gotconfig = true;
	}
	SetEntProp(entity, PropType:1, datamap, mt, 4, 0);
	return 0;
}

SetEntityRenderColor(entity, r, g, b, a)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_clrRender");
		}
		gotconfig = true;
	}
	new offset = GetEntSendPropOffs(entity, prop, false);
	if (0 >= offset)
	{
		ThrowError("SetEntityRenderColor not supported by this mod");
	}
	SetEntData(entity, offset, r, 1, true);
	SetEntData(entity, offset + 1, g, 1, true);
	SetEntData(entity, offset + 2, b, 1, true);
	SetEntData(entity, offset + 3, a, 1, true);
	return 0;
}

EmitSoundToAll(String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[MaxClients];
	new total;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			total++;
			clients[total] = i;
		}
		i++;
	}
	if (!total)
	{
		return 0;
	}
	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}

AddFileToDownloadsTable(String:filename[])
{
	static table = -1;
	if (table == -1)
	{
		table = FindStringTable("downloadables");
	}
	new bool:save = LockStringTables(false);
	AddToStringTable(table, filename, "", -1);
	LockStringTables(save);
	return 0;
}

public OnPluginStart()
{
	hSpeed = CreateConVar("missile_speed", "500.0", "Sets the speed of the missiles", 270592, true, 300.0, true, 3000.0);
	hDamage = CreateConVar("missile_damage", "1000", "Sets the maximum amount of damage the missiles can do", 270592, true, 1.0, false, 0.0);
	hRadius = CreateConVar("missile_radius", "350", "Sets the explosive radius of the missiles", 270592, true, 1.0, false, 0.0);
	NadeDamage = GetConVarInt(hDamage);
	NadeRadius = GetConVarInt(hRadius);
	NadeSpeed = GetConVarFloat(hSpeed);
	HookConVarChange(hDamage, ConVarChange);
	HookConVarChange(hRadius, ConVarChange);
	HookConVarChange(hSpeed, ConVarChange);
	return 0;
}

public ConVarChange(Handle:cvar, String:oldVal[], String:newVal[])
{
	if (hDamage == cvar)
	{
		NadeDamage = StringToInt(newVal, 10);
	}
	else
	{
		if (hRadius == cvar)
		{
			NadeRadius = StringToInt(newVal, 10);
		}
		if (hSpeed == cvar)
		{
			NadeSpeed = StringToFloat(newVal);
		}
	}
	return 0;
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/music/franug_rocket1.mp3");
	AddFileToDownloadsTable("materials/models/weapons/w_missile/missile side.vmt");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.mdl");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.phy");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.sw.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.vvd");
	PrecacheModel("models/weapons/w_missile_closed.mdl", false);
	PrecacheSound("music/franug_rocket1.mp3", false);
	PrecacheSound("weapons/hegrenade/explode5.wav", false);
	return 0;
}

public OnEntityCreated(entity, String:classname[])
{
	if (StrEqual(classname, "flashbang_projectile", false))
	{
		HookSingleEntityOutput(entity, "OnUser2", InitMissile, true);
		new String:OutputString[52] = "OnUser1 !self:FireUser2::0.0:1";
		SetVariantString(OutputString);
		AcceptEntityInput(entity, "AddOutput", -1, -1, 0);
		AcceptEntityInput(entity, "FireUser1", -1, -1, 0);
	}
	return 0;
}

public InitMissile(String:output[], caller, activator, Float:delay)
{
	new NadeOwner = GetEntPropEnt(caller, PropType:0, "m_hThrower", 0);
	if (NadeOwner == -1)
	{
		return 0;
	}
	new NadeTeam = GetEntProp(caller, PropType:0, "m_iTeamNum", 4, 0);
	SetEntProp(caller, PropType:1, "m_nNextThinkTick", any:-1, 4, 0);
	SetEntityMoveType(caller, MoveType:4);
	SetEntityModel(caller, "models/weapons/w_missile_closed.mdl");
	SetEntPropVector(caller, PropType:1, "m_vecAngVelocity", SpinVel, 0);
	SetEntPropFloat(caller, PropType:0, "m_flElasticity", 0.0, 0);
	SetEntPropVector(caller, PropType:0, "m_vecMins", MinNadeHull, 0);
	SetEntPropVector(caller, PropType:0, "m_vecMaxs", MaxNadeHull, 0);
	switch (NadeTeam)
	{
		case 2:
		{
			SetEntityRenderColor(caller, 255, 0, 0, 255);
		}
		case 3:
		{
			SetEntityRenderColor(caller, 0, 0, 255, 255);
		}
		default:
		{
		}
	}
	new SmokeIndex = CreateEntityByName("env_rockettrail", -1);
	if (SmokeIndex != -1)
	{
		SetEntPropFloat(SmokeIndex, PropType:0, "m_Opacity", 0.5, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_SpawnRate", 100.0, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_ParticleLifetime", 0.5, 0);
		new Float:SmokeRed[3] = {8.8E-44,4.6005E-41,4.6005E-41};
		new Float:SmokeBlue[3] = {4.6005E-41,4.6005E-41,8.8E-44};
		switch (NadeTeam)
		{
			case 2:
			{
				SetEntPropVector(SmokeIndex, PropType:0, "m_StartColor", SmokeRed, 0);
			}
			case 3:
			{
				SetEntPropVector(SmokeIndex, PropType:0, "m_StartColor", SmokeBlue, 0);
			}
			default:
			{
			}
		}
		SetEntPropFloat(SmokeIndex, PropType:0, "m_StartSize", 5.0, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_EndSize", 30.0, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_SpawnRadius", 0.0, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_MinSpeed", 0.0, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_MaxSpeed", 10.0, 0);
		SetEntPropFloat(SmokeIndex, PropType:0, "m_flFlareScale", 1.0, 0);
		DispatchSpawn(SmokeIndex);
		ActivateEntity(SmokeIndex);
		new String:NadeName[20];
		Format(NadeName, 20, "Nade_%i", caller);
		DispatchKeyValue(caller, "targetname", NadeName);
		SetVariantString(NadeName);
		AcceptEntityInput(SmokeIndex, "SetParent", -1, -1, 0);
		TeleportEntity(SmokeIndex, SmokeOrigin, SmokeAngle, NULL_VECTOR);
	}
	new Float:NadePos[3] = 0.0;
	GetEntPropVector(caller, PropType:0, "m_vecOrigin", NadePos, 0);
	new Float:OwnerAng[3] = 0.0;
	GetClientEyeAngles(NadeOwner, OwnerAng);
	new Float:OwnerPos[3] = 0.0;
	GetClientEyePosition(NadeOwner, OwnerPos);
	TR_TraceRayFilter(OwnerPos, OwnerAng, 33570827, RayType:1, DontHitOwnerOrNade, caller);
	new Float:InitialPos[3] = 0.0;
	TR_GetEndPosition(InitialPos, Handle:0);
	new Float:InitialVec[3] = 0.0;
	MakeVectorFromPoints(NadePos, InitialPos, InitialVec);
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, NadeSpeed);
	new Float:InitialAng[3] = 0.0;
	GetVectorAngles(InitialVec, InitialAng);
	TeleportEntity(caller, NULL_VECTOR, InitialAng, InitialVec);
	EmitSoundToAll("music/franug_rocket1.mp3", caller, 1, 90, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	HookSingleEntityOutput(caller, "OnUser2", MissileThink, false);
	new String:OutputString[52] = "OnUser1 !self:FireUser2::0.1:-1";
	SetVariantString(OutputString);
	AcceptEntityInput(caller, "AddOutput", -1, -1, 0);
	AcceptEntityInput(caller, "FireUser1", -1, -1, 0);
	SDKHook(caller, SDKHookType:25, OnStartTouchPost);
	return 0;
}

public MissileThink(String:output[], caller, activator, Float:delay)
{
	decl Float:CheckVec[3];
	GetEntPropVector(caller, PropType:0, "m_vecVelocity", CheckVec, 0);
	new var1;
	if (0.0 == CheckVec[0] && 0.0 == CheckVec[1] && 0.0 == CheckVec[2])
	{
		StopSound(caller, 1, "music/franug_rocket1.mp3");
		CreateExplosion(caller);
		return 0;
	}
	decl Float:NadePos[3];
	GetEntPropVector(caller, PropType:0, "m_vecOrigin", NadePos, 0);
	new dado = GetTraceHullEntityIndex(NadePos, caller);
	new var2;
	if (IsClientIndex(dado) && ZR_IsClientZombie(dado))
	{
		StopSound(caller, 1, "music/franug_rocket1.mp3");
		CreateExplosion(caller);
		return 0;
	}
	AcceptEntityInput(caller, "FireUser1", -1, -1, 0);
	return 0;
}

GetTraceHullEntityIndex(Float:pos[3], xindex)
{
	TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, 1174421507, THFilter, xindex);
	return TR_GetEntityIndex(Handle:0);
}

public bool:THFilter(entity, contentsMask, any:data)
{
	new var1;
	return IsClientIndex(entity) && data != entity;
}

bool:IsClientIndex(index)
{
	new var1;
	return index > 0 && index <= MaxClients;
}

public bool:DontHitOwnerOrNade(entity, contentsMask, any:data)
{
	new NadeOwner = GetEntPropEnt(data, PropType:0, "m_hThrower", 0);
	new var1;
	return data != entity && NadeOwner != entity;
}

public OnStartTouchPost(entity, other)
{
	new var1;
	if (GetEntProp(other, PropType:1, "m_nSolidType", 4, 0) && !GetEntProp(other, PropType:1, "m_usSolidFlags", 4, 0) & 4)
	{
		StopSound(entity, 1, "music/franug_rocket1.mp3");
		CreateExplosion(entity);
	}
	return 0;
}

CreateExplosion(entity)
{
	UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
	new Float:MissilePos[3] = 0.0;
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", MissilePos, 0);
	new MissileOwner = GetEntPropEnt(entity, PropType:0, "m_hThrower", 0);
	new MissileOwnerTeam = GetEntProp(entity, PropType:0, "m_iTeamNum", 4, 0);
	new ExplosionIndex = CreateEntityByName("env_explosion", -1);
	if (ExplosionIndex != -1)
	{
		DispatchKeyValue(ExplosionIndex, "classname", "flashbang_projectile");
		SetEntProp(ExplosionIndex, PropType:1, "m_spawnflags", any:6146, 4, 0);
		SetEntProp(ExplosionIndex, PropType:1, "m_iMagnitude", NadeDamage, 4, 0);
		SetEntProp(ExplosionIndex, PropType:1, "m_iRadiusOverride", NadeRadius, 4, 0);
		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		TeleportEntity(ExplosionIndex, MissilePos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, PropType:0, "m_hOwnerEntity", MissileOwner, 0);
		SetEntProp(ExplosionIndex, PropType:0, "m_iTeamNum", MissileOwnerTeam, 4, 0);
		EmitSoundToAll("weapons/hegrenade/explode5.wav", ExplosionIndex, 1, 90, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		AcceptEntityInput(ExplosionIndex, "Explode", -1, -1, 0);
		DispatchKeyValue(ExplosionIndex, "classname", "env_explosion");
		AcceptEntityInput(ExplosionIndex, "Kill", -1, -1, 0);
	}
	AcceptEntityInput(entity, "Kill", -1, -1, 0);
	return 0;
}

