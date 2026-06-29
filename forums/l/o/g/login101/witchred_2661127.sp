public PlVers:__version =
{
	version = 5,
	filevers = "1.4.0",
	date = "01/05/2012",
	time = "18:12:43"
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
new bool:CEventIsHooked;
new bool:CSkipList[66];
new String:CTag[6][] =
{
	"",
	"",
	"",
	"",
	"",
	""
};
new String:CTagCode[6][16];
new bool:CTagReqSayText2[6];
new bool:CProfile_Colors[6] =
{
	1, 1, 0, 0, 0, 0
};
new CProfile_TeamIndex[6] =
{
	-1, ...
};
new bool:CProfile_SayText2;
public Extension:__ext_sdkhooks =
{
	name = "sdkhooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new Handle:sdkAdrenaline;
new Handle:sdkVomitSurvivor;
new Handle:sdkDetonateAcid;
new Handle:sdkCallPushPlayer;
new Handle:g_hGameConf;
new Handle:IceDamgeTimer[66];
new Handle:AcidSpillDamgeTimer[66];
new beamcol[66][4];
new Float:brandpos[66][3];
new Float:addpos[66];
new visibility;
new killer;
new g_BeamSprite;
new g_HaloSprite;
new bool:GreenWitch;
new bool:FireWhite;
new bool:IceWitch;
new bool:BlackWitch;
new bool:PurpleWitch;
new bool:VomitWitch;
new Handle:IceTimeout;
new Handle:AcidSpillTimeout;
new bool:AcidSpillEnable[66];
new Handle:Cvar_GreenWitchHealth;
new Handle:Cvar_FireWitchHealth;
new Handle:Cvar_IceWitchHealth;
new Handle:Cvar_BlackWitchHealth;
new Handle:Cvar_PurpleWitchHealth;
new Handle:Cvar_VomitWitchHealth;
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

Float:operator+(Float:,_:)(Float:oper1, oper2)
{
	return oper1 + float(oper2);
}

bool:operator<=(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) <= 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

PrintToChatAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
		}
		i++;
	}
	return 0;
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

SetEntityRenderMode(entity, RenderMode:mode)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nRenderMode", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_nRenderMode");
		}
		gotconfig = true;
	}
	SetEntProp(entity, PropType:0, prop, mode, 1, 0);
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

TE_SendToAll(Float:delay)
{
	new total;
	new clients[MaxClients];
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
	return TE_Send(clients, total, delay);
}

TE_SetupBeamRingPoint(Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, Color[4], Speed, Flags)
{
	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", center);
	TE_WriteFloat("m_flStartRadius", Start_Radius);
	TE_WriteFloat("m_flEndRadius", End_Radius);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", StartFrame);
	TE_WriteNum("m_nFrameRate", FrameRate);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", Width);
	TE_WriteFloat("m_fAmplitude", Amplitude);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
	TE_WriteNum("m_nSpeed", Speed);
	TE_WriteNum("m_nFlags", Flags);
	TE_WriteNum("m_nFadeLength", 0);
	return 0;
}

CSetupProfile()
{
	decl String:szGameName[32];
	GetGameFolderName(szGameName, 30);
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[2] = 1;
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_Colors[5] = 1;
		CProfile_TeamIndex[2] = 0;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = true;
	}
	else
	{
		if (StrEqual(szGameName, "tf", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 2;
			CProfile_TeamIndex[4] = 3;
			CProfile_SayText2 = true;
		}
		new var1;
		if (StrEqual(szGameName, "left4dead", false) || StrEqual(szGameName, "left4dead2", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 3;
			CProfile_TeamIndex[4] = 2;
			CProfile_SayText2 = true;
		}
		if (StrEqual(szGameName, "hl2mp", false))
		{
			if (GetConVarBool(FindConVar("mp_teamplay")))
			{
				CProfile_Colors[3] = 1;
				CProfile_Colors[4] = 1;
				CProfile_TeamIndex[3] = 3;
				CProfile_TeamIndex[4] = 2;
				CProfile_SayText2 = true;
			}
			else
			{
				CProfile_SayText2 = false;
			}
		}
		if (StrEqual(szGameName, "dod", false))
		{
			CProfile_Colors[5] = 1;
			CProfile_SayText2 = false;
		}
		if (GetUserMessageId("SayText2") == -1)
		{
			CProfile_SayText2 = false;
		}
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = true;
	}
	return 0;
}

public Action:CEvent_MapStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CSetupProfile();
	new i = 1;
	while (i <= MaxClients)
	{
		CEventIsHooked[i] = false;
		i++;
	}
	return Action:0;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_show", Command_Show, "", 0);
	IceTimeout = CreateConVar("Ice_Timeout", "30", "冰凍傷害持續時間", 262144, true, 0.0, false, 0.0);
	AcidSpillTimeout = CreateConVar("AcidSpill_Timeout", "20", "毒液傷害持續時間", 262144, true, 0.0, false, 0.0);
	Cvar_GreenWitchHealth = CreateConVar("GreenWitch_hp", "2000", "毒素女巫的血量 ", 262144, true, 1.0, true, 10000.0);
	Cvar_FireWitchHealth = CreateConVar("FireWitch_hp", "3000", "火焰女巫的血量 ", 262144, true, 1.0, true, 10000.0);
	Cvar_IceWitchHealth = CreateConVar("IceWitch_hp", "3000", "冰凍女巫的血量 ", 262144, true, 1.0, true, 10000.0);
	Cvar_BlackWitchHealth = CreateConVar("BlackWitch_hp", "3000", "黑暗女巫的血量 ", 262144, true, 1.0, true, 10000.0);
	Cvar_PurpleWitchHealth = CreateConVar("PurpleWitch_hp", "3000", "毒氣女巫的血量 ", 262144, true, 1.0, true, 10000.0);
	Cvar_VomitWitchHealth = CreateConVar("VomitWitch_hp", "3000", "膽汁女巫的血量 ", 262144, true, 1.0, true, 10000.0);
	AutoExecConfig(true, "witch-ju-on", "sourcemod");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode:1);
	HookEvent("witch_spawn", witch_spawn, EventHookMode:1);
	HookEvent("witch_killed", Event_Witch_Kill, EventHookMode:1);
	HookEvent("witch_harasser_set", WitchTargetBufferSet, EventHookMode:1);
	HookEvent("round_start", Event_RoundStart, EventHookMode:1);
	g_hGameConf = LoadGameConfigFile("witchred");
	if (!g_hGameConf)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}
	StartPrepSDKCall(SDKCallType:2);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKFuncConfSource:1, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType:2, SDKPassMethod:3, 0, 0);
	PrepSDKCall_AddParameter(SDKType:4, SDKPassMethod:1, 0, 0);
	PrepSDKCall_AddParameter(SDKType:1, SDKPassMethod:0, 0, 0);
	PrepSDKCall_AddParameter(SDKType:5, SDKPassMethod:1, 0, 0);
	sdkCallPushPlayer = EndPrepSDKCall();
	if (!sdkCallPushPlayer)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_Fling\" signature, check the file version!");
	}
	StartPrepSDKCall(SDKCallType:1);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKFuncConfSource:1, "CSpitterProjectile_Detonate");
	sdkDetonateAcid = EndPrepSDKCall();
	if (!sdkDetonateAcid)
	{
		SetFailState("Unable to find the \"CSpitterProjectile::Detonate(void)\" signature, check the file version!");
	}
	StartPrepSDKCall(SDKCallType:2);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKFuncConfSource:1, "CTerrorPlayer_OnAdrenalineUsed");
	PrepSDKCall_AddParameter(SDKType:5, SDKPassMethod:1, 0, 0);
	sdkAdrenaline = EndPrepSDKCall();
	if (!sdkAdrenaline)
	{
		SetFailState("Unable to find the \"CTerrorPlayer::OnAdrenalineUsed(float)\" signature, check the file version!");
	}
	StartPrepSDKCall(SDKCallType:2);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKFuncConfSource:1, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType:1, SDKPassMethod:0, 0, 0);
	PrepSDKCall_AddParameter(SDKType:4, SDKPassMethod:1, 0, 0);
	sdkVomitSurvivor = EndPrepSDKCall();
	if (!sdkVomitSurvivor)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}
	return 0;
}

public OnMapStart()
{
	PrecacheParticle("spitter_areaofdenial_base_refract");
	PrecacheParticle("policecar_tail_strobe_2b");
	PrecacheParticle("water_child_water5");
	PrecacheParticle("aircraft_destroy_fastFireTrail");
	PrecacheParticle("fire_small_01");
	PrecacheParticle("vomit_jar_b");
	PrecacheParticle("apc_wheel_smoke1");
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", false);
	g_HaloSprite = PrecacheModel("materials/sun/overlay.vmt", false);
	GreenWitch = false;
	FireWhite = false;
	IceWitch = false;
	BlackWitch = false;
	PurpleWitch = false;
	VomitWitch = false;
	return 0;
}

public Action:Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == 2)
	{
		if (AcidSpillDamgeTimer[client])
		{
			KillTimer(AcidSpillDamgeTimer[client], false);
			AcidSpillDamgeTimer[client] = 0;
		}
	}
	return Action:0;
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	GreenWitch = false;
	FireWhite = false;
	IceWitch = false;
	BlackWitch = false;
	PurpleWitch = false;
	VomitWitch = false;
	return Action:0;
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(time, DeleteParticles, particle, 0);
	}
	return 0;
}

public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(0.01, DeleteParticle, particle, 0);
	}
	return 0;
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[128];
		GetEdictClassname(particle, classname, 128);
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
		else
		{
			LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
		}
	}
	return Action:0;
}

public AttachParticle(ent, String:particleType[], Float:time)
{
	decl String:tName[64];
	new particle = CreateEntityByName("info_particle_system", -1);
	new var1;
	if (IsValidEdict(particle) && IsValidEdict(ent))
	{
		new Float:pos[3] = 0.0;
		GetEntPropVector(ent, PropType:0, "m_vecOrigin", pos, 0);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, PropType:1, "m_iName", tName, 64, 0);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(time, DeleteParticles, particle, 0);
	}
	return 0;
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	new var1;
	if (IsValidEntity(particle) || IsValidEdict(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, 64);
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop", -1, -1, 0);
			AcceptEntityInput(particle, "kill", -1, -1, 0);
			RemoveEdict(particle);
		}
	}
	return Action:0;
}

RGB_TO_INT(red, green, blue)
{
	return green * 256 + blue * 65536 + red;
}

public Action:Event_Witch_Kill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new witchid = GetEventInt(event, "witchid");
	if (0 < witchid)
	{
		CreateTimer(1.0, TraceWitch2, witchid, 2);
	}
	return Action:0;
}

public Action:TraceWitch2(Handle:timer, any:witch)
{
	new var1;
	if (witch != any:-1 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		decl Stirng:sname[32];
		GetEdictClassname(witch, sname, 32);
		if (StrEqual(sname, "witch", true))
		{
			if (GreenWitch)
			{
				GreenWitch = false;
				return Action:0;
			}
			if (FireWhite)
			{
				FireWhite = false;
				return Action:0;
			}
			if (IceWitch)
			{
				IceWitch = false;
				return Action:0;
			}
			if (BlackWitch)
			{
				BlackWitch = false;
				return Action:0;
			}
			if (PurpleWitch)
			{
				PurpleWitch = false;
				return Action:0;
			}
			if (VomitWitch)
			{
				VomitWitch = false;
				return Action:0;
			}
		}
	}
	return Action:0;
}

public Action:witch_spawn(Handle:h_Event, String:s_Name[], bool:b_DontBroadcast)
{
	new witchid = GetEventInt(h_Event, "witchid");
	if (0 < witchid)
	{
		CreateTimer(1.0, TraceWitchl, witchid, 2);
	}
	return Action:0;
}

public Action:TraceWitchl(Handle:timer, any:witch)
{
	new var1;
	if (witch != any:-1 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		decl Stirng:sname[32];
		GetEdictClassname(witch, sname, 32);
		if (StrEqual(sname, "witch", true))
		{
			switch (GetRandomInt(0, 5))
			{
				case 0:
				{
					new GreenWitchHealth = GetConVarInt(Cvar_GreenWitchHealth);
					SetEntProp(witch, PropType:1, "m_iMaxHealth", GreenWitchHealth, 4, 0);
					SetEntProp(witch, PropType:1, "m_iHealth", GreenWitchHealth, 4, 0);
					SetEntProp(witch, PropType:0, "m_iGlowType", any:3, 4, 0);
					SetEntProp(witch, PropType:0, "m_bFlashing", any:1, 4, 0);
					SetEntProp(witch, PropType:0, "m_glowColorOverride", any:119911, 4, 0);
					CreateTimer(5.0, WitchGreen, witch, 1);
					GreenWitch = true;
					SetClientInfo(witch, "name", "毒素女巫");
				}
				case 1:
				{
					new glowcolor = RGB_TO_INT(255, 0, 0);
					new FireWitchHealth = GetConVarInt(Cvar_FireWitchHealth);
					SetEntProp(witch, PropType:1, "m_iMaxHealth", FireWitchHealth, 4, 0);
					SetEntProp(witch, PropType:1, "m_iHealth", FireWitchHealth, 4, 0);
					SetEntProp(witch, PropType:0, "m_iGlowType", any:3, 4, 0);
					SetEntProp(witch, PropType:0, "m_bFlashing", any:1, 4, 0);
					SetEntProp(witch, PropType:0, "m_glowColorOverride", glowcolor, 4, 0);
					CreateTimer(0.1, WhiteFire, witch, 1);
					FireWhite = true;
					SetClientInfo(witch, "name", "火焰女巫");
				}
				case 2:
				{
					new glowcolor = RGB_TO_INT(0, 0, 255);
					new IceWitchHealth = GetConVarInt(Cvar_IceWitchHealth);
					SetEntProp(witch, PropType:1, "m_iMaxHealth", IceWitchHealth, 4, 0);
					SetEntProp(witch, PropType:1, "m_iHealth", IceWitchHealth, 4, 0);
					SetEntProp(witch, PropType:0, "m_iGlowType", any:3, 4, 0);
					SetEntProp(witch, PropType:0, "m_bFlashing", any:1, 4, 0);
					SetEntProp(witch, PropType:0, "m_glowColorOverride", glowcolor, 4, 0);
					CreateTimer(1.0, WitchBlue, witch, 1);
					IceWitch = true;
					SetClientInfo(witch, "name", "冰凍女巫");
				}
				case 3:
				{
					new glowcolor = RGB_TO_INT(0, 0, 0);
					new BlackWitchHealth = GetConVarInt(Cvar_BlackWitchHealth);
					SetEntProp(witch, PropType:1, "m_iMaxHealth", BlackWitchHealth, 4, 0);
					SetEntProp(witch, PropType:1, "m_iHealth", BlackWitchHealth, 4, 0);
					SetEntProp(witch, PropType:0, "m_iGlowType", any:3, 4, 0);
					SetEntProp(witch, PropType:0, "m_bFlashing", any:1, 4, 0);
					SetEntProp(witch, PropType:0, "m_glowColorOverride", glowcolor, 4, 0);
					CreateTimer(1.0, WitchBlack, witch, 1);
					BlackWitch = true;
					SetClientInfo(witch, "name", "黑暗女巫");
				}
				case 4:
				{
					new glowcolor = RGB_TO_INT(218, 112, 214);
					new VomitWitchHealth = GetConVarInt(Cvar_VomitWitchHealth);
					SetEntProp(witch, PropType:1, "m_iMaxHealth", VomitWitchHealth, 4, 0);
					SetEntProp(witch, PropType:1, "m_iHealth", VomitWitchHealth, 4, 0);
					SetEntProp(witch, PropType:0, "m_iGlowType", any:3, 4, 0);
					SetEntProp(witch, PropType:0, "m_bFlashing", any:1, 4, 0);
					SetEntProp(witch, PropType:0, "m_glowColorOverride", glowcolor, 4, 0);
					CreateTimer(1.0, WitchVomit, witch, 1);
					VomitWitch = true;
					SetClientInfo(witch, "name", "膽汁女巫");
				}
				case 6:
				{
					new glowcolor = RGB_TO_INT(255, 0, 255);
					new PurpleWitchHealth = GetConVarInt(Cvar_PurpleWitchHealth);
					SetEntProp(witch, PropType:1, "m_iMaxHealth", PurpleWitchHealth, 4, 0);
					SetEntProp(witch, PropType:1, "m_iHealth", PurpleWitchHealth, 4, 0);
					SetEntProp(witch, PropType:0, "m_iGlowType", any:3, 4, 0);
					SetEntProp(witch, PropType:0, "m_bFlashing", any:1, 4, 0);
					SetEntProp(witch, PropType:0, "m_glowColorOverride", glowcolor, 4, 0);
					CreateTimer(1.0, WitchPurple, witch, 1);
					PurpleWitch = true;
					SetClientInfo(witch, "name", "毒煙女巫");
				}
				default:
				{
				}
			}
		}
	}
	return Action:4;
}

public WitchTargetBufferSet(Handle:event, String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (FireWhite)
	{
		AttachParticle(target, "aircraft_destroy_fastFireTrail", 10.0);
		IgniteEntity(target, 10.0, false, 0.0, false);
		DealDamage(target, target, 30, 2, "");
		return 0;
	}
	if (!GreenWitch)
	{
		if (IceWitch)
		{
			CreateTimer(1.0, Freeze, target, 0);
			return 0;
		}
		if (BlackWitch)
		{
			CreateTimer(1.0, FadeoutTimer, target, 0);
			ScreenFade(target, 0, 255, 255, 192, 5000, 1);
			return 0;
		}
		if (PurpleWitch)
		{
			return 0;
		}
		if (VomitWitch)
		{
			VomitPlayer(target, target);
			return 0;
		}
		return 0;
	}
	new Float:AcidSpillDamgeOut = GetConVarFloat(AcidSpillTimeout);
	CreateTimer(AcidSpillDamgeOut, AcidSpillOutTimer, target, 0);
	AcidSpillEnable[target] = 1;
	AcidSpillDamgeTimer[target] = CreateTimer(5.0, AcidSpill, target, 1);
	return 0;
}

public Action:Freeze(Handle:timer, any:client)
{
	SetEntityRenderMode(client, RenderMode:3);
	SetEntityRenderColor(client, 0, 100, 170, 180);
	SetEntityMoveType(client, MoveType:6);
	CreateTimer(5.0, Timer_UnFreeze, client, 2);
	EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenFade(client, 0, 128, 255, 192, 5000, 1);
	new Float:IceDamgeOut = GetConVarFloat(IceTimeout);
	CreateTimer(IceDamgeOut, IceOutTimer, client, 0);
	IceDamgeTimer[client] = CreateTimer(7.0, Timer_IceWitch, client, 1);
	return Action:0;
}

public Action:AcidSpillOutTimer(Handle:timer, any:client)
{
	if (AcidSpillDamgeTimer[client])
	{
		AcidSpillEnable[client] = 0;
		KillTimer(AcidSpillDamgeTimer[client], false);
		AcidSpillDamgeTimer[client] = 0;
	}
	return Action:0;
}

public Action:IceOutTimer(Handle:timer, any:client)
{
	if (IceDamgeTimer[client])
	{
		KillTimer(IceDamgeTimer[client], false);
		IceDamgeTimer[client] = 0;
	}
	return Action:0;
}

public Action:AcidSpill(Handle:timer, any:Client)
{
	CreateAcidSpill(Client, Client);
	return Action:0;
}

public Action:WhiteFire(Handle:timer, any:witch)
{
	if (FireWhite)
	{
		AttachParticle(witch, "fire_small_01", 1.0);
	}
	return Action:0;
}

public Action:WitchGreen(Handle:timer, any:witch)
{
	if (GreenWitch)
	{
		AttachParticle(witch, "spitter_areaofdenial_base_refract", 5.0);
	}
	return Action:0;
}

public Action:WitchBlue(Handle:timer, any:witch)
{
	if (IceWitch)
	{
		AttachParticle(witch, "apc_wheel_smoke1", 1.0);
		AttachParticle(witch, "water_child_water5", 3.0);
	}
	return Action:0;
}

public Action:WitchBlack(Handle:timer, any:witch)
{
	if (BlackWitch)
	{
		new Float:entpos[3] = 0.0;
		new Float:effectpos[3] = 0.0;
		GetEntPropVector(witch, PropType:0, "m_vecOrigin", entpos, 0);
		effectpos[0] = entpos[0];
		effectpos[1] = entpos[1];
		effectpos[2] = entpos[2] + 70;
		ShowParticle(effectpos, "policecar_tail_strobe_2b", 3.0);
	}
	return Action:0;
}

public Action:WitchPurple(Handle:timer, any:witch)
{
	return Action:0;
}

public Action:WitchVomit(Handle:timer, any:witch)
{
	if (VomitWitch)
	{
		AttachParticle(witch, "vomit_jar_b", 1.0);
	}
	return Action:0;
}

public Action:FadeoutTimer(Handle:Timer)
{
	visibility = visibility + 8;
	if (visibility > 240)
	{
		visibility = 240;
	}
	ScreenFade(killer, 0, 0, 0, visibility, 0, 0);
	if (visibility >= 240)
	{
		FakeRealism(true);
		KillTimer(Timer, false);
	}
	return Action:0;
}

public Action:Timer_IceWitch(Handle:timer, any:client)
{
	new Float:vec[3] = 0.0;
	new Color[4];
	Color[3] = 255;
	GetClientAbsOrigin(client, vec);
	Color[0] = GetRandomInt(0, 255);
	Color[1] = GetRandomInt(0, 255);
	Color[2] = GetRandomInt(0, 255);
	vec[2] += 30;
	TE_SetupBeamRingPoint(vec, 20.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 6.0, 0.0, Color, 10, 0);
	TE_SendToAll(0.0);
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			new Float:pos[3] = 0.0;
			new Float:pos_t[3] = 0.0;
			new Float:distance = 0.0;
			new Float:IceDamgeOut = GetConVarFloat(IceTimeout);
			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, pos_t);
			distance = GetVectorDistance(pos, pos_t, false);
			if (distance <= 2.8E-43)
			{
				ServerCommand("sm_freeze \"%N\" \"3\"", i);
				CreateTimer(IceDamgeOut, IceOutTimer, i, 0);
				EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
		i++;
	}
	addpos[client] = 0;
	GetClientAbsOrigin(client, brandpos[client]);
	beamcol[client][0] = GetRandomInt(0, 255);
	beamcol[client][1] = GetRandomInt(0, 255);
	beamcol[client][2] = GetRandomInt(0, 255);
	beamcol[client][3] = 135;
	return Action:3;
}

public Action:Timer_UnFreeze(Handle:timer, any:client)
{
	if (any:0 < client)
	{
		new var1;
		if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RenderMode:3);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MoveType:2);
		}
	}
	return Action:0;
}

public FakeRealism(bool:mode)
{
	if (mode == true)
	{
		SetConVarInt(FindConVar("sv_disable_glow_faritems"), 1, true, true);
		SetConVarInt(FindConVar("sv_disable_glow_survivors"), 1, true, true);
	}
	else
	{
		SetConVarInt(FindConVar("sv_disable_glow_faritems"), 0, true, true);
		SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0, true, true);
	}
	return 0;
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target, 0);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type)
	{
		BfWriteShort(msg, 17);
	}
	else
	{
		BfWriteShort(msg, 10);
	}
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
	return 0;
}

DealDamage(attacker, victim, damage, dmg_type, String:weapon[])
{
	new var1;
	if (IsValidEdict(victim) && damage > 0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		new PointHurt = CreateEntityByName("point_hurt", -1);
		if (PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim, "targetname", victimid);
			DispatchKeyValue(PointHurt, "DamageTarget", victimid);
			DispatchKeyValueFloat(PointHurt, "Damage", float(damage));
			DispatchKeyValue(PointHurt, "DamageType", dmg_type_str);
			if (!StrEqual(weapon, "", true))
			{
				DispatchKeyValue(PointHurt, "classname", weapon);
			}
			DispatchSpawn(PointHurt);
			if (IsClientInGame(attacker))
			{
				AcceptEntityInput(PointHurt, "Hurt", attacker, -1, 0);
			}
			else
			{
				AcceptEntityInput(PointHurt, "Hurt", -1, -1, 0);
			}
			RemoveEdict(PointHurt);
		}
	}
	return 0;
}

VomitPlayer(target, sender)
{
	if (target)
	{
		if (target == -1)
		{
			return 0;
		}
		if (GetClientTeam(target) == 2)
		{
			SDKCall(sdkVomitSurvivor, target, sender, 1);
		}
		return 0;
	}
	return 0;
}

CreateAcidSpill(iTarget, iSender)
{
	decl Float:vecPos[3];
	GetClientAbsOrigin(iTarget, vecPos);
	vecPos[2] += 16.0;
	new iAcid = CreateEntityByName("spitter_projectile", -1);
	if (IsValidEntity(iAcid))
	{
		DispatchSpawn(iAcid);
		SetEntPropFloat(iAcid, PropType:0, "m_DmgRadius", 1024.0, 0);
		SetEntProp(iAcid, PropType:0, "m_bIsLive", any:1, 4, 0);
		SetEntPropEnt(iAcid, PropType:0, "m_hThrower", iSender, 0);
		TeleportEntity(iAcid, vecPos, NULL_VECTOR, NULL_VECTOR);
		SDKCall(sdkDetonateAcid, iAcid);
	}
	return 0;
}

public Action:Command_Show(client, args)
{
	PrintToChatAll("\x03==========================\x09\x09\x09\x09\x03");
	PrintToChatAll("\x04|插件名稱:女巫咒怨\x09\x09\x09\x09\x09\x09\x04");
	PrintToChatAll("\x04|插件作者:奇奈cheryl\x09\x09\x09\x04");
	PrintToChatAll("\x03==========================\x09\x09\x09\x09\x03");
	return Action:0;
}

