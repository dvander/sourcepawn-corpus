#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks>

#define CVAR_FLAGS FCVAR_NOTIFY

Handle sdkDetonateAcid = null, sdkVomitSurvivor = null, IceDamgeTimer[MAXPLAYERS + 1] = {null, ...}, AcidSpillDamgeTimer[MAXPLAYERS + 1] = {null, ...};
GameData g_hGameConf;
float brandpos[MAXPLAYERS + 1][3], IceDamgeOut = 0.0, AcidSpillDamgeOut = 0.0;
ConVar PluginOn, IceTimeout, AcidSpillTimeout, Cvar_VomitWitchHealth, Cvar_BlackWitchHealth, Cvar_IceWitchHealth, Cvar_FireWitchHealth, Cvar_GreenWitchHealth, Cvar_PurpleWitchHealth;
#if defined _l4dh_included
bool bLate = false, bL4DHooks = false;
#endif
bool IsLeft4Dead2 = false, bHooked = false, VomitWitch = false, BlackWitch = false, IceWitch = false, FireWhite = false, GreenWitch = false, PurpleWitch = false, AcidSpillEnable[MAXPLAYERS + 1] = {false, ...};
int g_BeamSprite = 0, g_HaloSprite = 0, visibility = 0, beamcol[MAXPLAYERS + 1][4], GreenWitchHealth = 0, FireWitchHealth = 0, IceWitchHealth = 0, BlackWitchHealth = 0, VomitWitchHealth = 0, PurpleWitchHealth = 0;

#define SPRITE_BEAM   "materials/sprites/laserbeam.vmt"
#define SPRITE_HALO   "materials/sun/overlay.vmt"
//#define DMG_BULLET	(1 << 1)
#define MAXPARTICLES 9

static char gStringTable[MAXPARTICLES][] =
{
	"policecar_tail_strobe_2b",
	"aircraft_destroy_fastFireTrail",
	"fire_small_01",
	"apc_wheel_smoke1",
	"boomer_leg_smoke",
	"boomer_explode_D",
	"vomit_jar_b",
	"spitter_areaofdenial_base_refract",
	"water_child_water5"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		IsLeft4Dead2 = false;
	}
	else if (engine == Engine_Left4Dead2)
	{
		IsLeft4Dead2 = true;		
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	#if defined _l4dh_included
	bLate = late
	#endif
	return APLRes_Success;
}

public void OnPluginStart()
{		
	#if !defined _l4dh_included
	g_hGameConf = new GameData("witchred");
	if(g_hGameConf == null)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}

	if(IsLeft4Dead2)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CSpitterProjectile_Detonate");
		sdkDetonateAcid = EndPrepSDKCall();
		if(sdkDetonateAcid == null)
		{
			SetFailState("Unable to find the \"CSpitterProjectile::Detonate(void)\" signature, check the file version!");
		}
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitSurvivor = EndPrepSDKCall();
	if(sdkVomitSurvivor == null)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}
	#else
	{
		if(bLateload)
		{
			bL4DHooks = LibraryExists("left4dhooks");
		}
		
		if(!bL4DHooks)
		{
			g_hGameConf = new GameData("witchred");
			if(g_hGameConf == null)
			{
				SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
			}

			if(IsLeft4Dead2)
			{
				StartPrepSDKCall(SDKCall_Entity);
				PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CSpitterProjectile_Detonate");
				sdkDetonateAcid = EndPrepSDKCall();
				if(sdkDetonateAcid == null)
				{
					SetFailState("Unable to find the \"CSpitterProjectile::Detonate(void)\" signature, check the file version!");
				}
			}

			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			sdkVomitSurvivor = EndPrepSDKCall();
			if(sdkVomitSurvivor == null)
			{
				SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
			}
		}
	}
	#endif

	PluginOn = CreateConVar("WitchRed_Enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	IceTimeout = CreateConVar("Ice_Timeout", "30", "Freezing damage duration", CVAR_FLAGS, true, 0.0, false, 0.0);
	AcidSpillTimeout = CreateConVar("AcidSpill_Timeout", "20", "Venom damage duration", CVAR_FLAGS, true, 0.0, false, 0.0);
	Cvar_GreenWitchHealth = CreateConVar("GreenWitch_hp", "2000", "Toxic witch's blood volume ", CVAR_FLAGS, true, 1.0, true, 10000.0);
	Cvar_FireWitchHealth = CreateConVar("FireWitch_hp", "3000", "Flame witch's blood ", CVAR_FLAGS, true, 1.0, true, 10000.0);
	Cvar_IceWitchHealth = CreateConVar("IceWitch_hp", "3000", "Frozen witch's blood ", CVAR_FLAGS, true, 1.0, true, 10000.0);
	Cvar_BlackWitchHealth = CreateConVar("BlackWitch_hp", "3000", "Dark witch's blood ", CVAR_FLAGS, true, 1.0, true, 10000.0);
	Cvar_VomitWitchHealth = CreateConVar("VomitWitch_hp", "3000", "Bile witch's blood volume ", CVAR_FLAGS, true, 1.0, true, 10000.0);
	Cvar_PurpleWitchHealth = CreateConVar("PurpleWitch_hp", "3000", "Blood of the poisonous witch ", CVAR_FLAGS, true, 1.0, true, 10000.0);

	AutoExecConfig(true, "witch_red", "sourcemod");

	PluginOn.AddChangeHook(OnConVarPluginOnChange);
	IceTimeout.AddChangeHook(ConVarChanged_Cvars);
	AcidSpillTimeout.AddChangeHook(ConVarChanged_Cvars);
	Cvar_GreenWitchHealth.AddChangeHook(ConVarChanged_Cvars);
	Cvar_FireWitchHealth.AddChangeHook(ConVarChanged_Cvars);
	Cvar_IceWitchHealth.AddChangeHook(ConVarChanged_Cvars);
	Cvar_BlackWitchHealth.AddChangeHook(ConVarChanged_Cvars);
	Cvar_VomitWitchHealth.AddChangeHook(ConVarChanged_Cvars);
	Cvar_PurpleWitchHealth.AddChangeHook(ConVarChanged_Cvars);
}

#if defined _vip_core_included
public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "left4dhooks") == 0)
	{
		bL4DHooks = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "left4dhooks") == 0)
	{
		bL4DHooks = false;
	}
}
#endif

public void OnMapStart()
{
	int max = MAXPARTICLES - 3;
	if( IsLeft4Dead2 ) max = MAXPARTICLES;
	
	for(int i = 0; i < max; i++)
		PrecacheParticle(gStringTable[i]);
		
	g_BeamSprite = PrecacheModel(SPRITE_BEAM);
	g_HaloSprite = PrecacheModel(SPRITE_HALO);

	PrecacheSound("ambient/ambience/rainscapes/rain/debris_05.wav");
	
	GreenWitch = false;
	FireWhite = false;
	IceWitch = false;
	BlackWitch = false;
	VomitWitch = false;
	PurpleWitch = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IceDamgeOut = IceTimeout.FloatValue;
	AcidSpillDamgeOut = AcidSpillTimeout.FloatValue;
	GreenWitchHealth = Cvar_GreenWitchHealth.IntValue;
	FireWitchHealth = Cvar_FireWitchHealth.IntValue;
	IceWitchHealth = Cvar_IceWitchHealth.IntValue;
	BlackWitchHealth = Cvar_BlackWitchHealth.IntValue;
	VomitWitchHealth = Cvar_VomitWitchHealth.IntValue;
	PurpleWitchHealth = Cvar_PurpleWitchHealth.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = PluginOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		ConVarChanged_Cvars(null, "", "");
		HookEvent("player_death", ePlayerDeath);
		HookEvent("witch_spawn", eWitchSpawn);
		HookEvent("witch_killed", eWitchKilled);
		HookEvent("witch_harasser_set", eWitchSet);
		HookEvent("round_start", eRoundStart);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_death", ePlayerDeath);
		UnhookEvent("witch_spawn", eWitchSpawn);
		UnhookEvent("witch_killed", eWitchKilled);
		UnhookEvent("witch_harasser_set", eWitchSet);
		UnhookEvent("round_start", eRoundStart);
	}
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

Action ePlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if (AcidSpillDamgeTimer[client] != null)
		{
			delete AcidSpillDamgeTimer[client];
		}
	}
	return Plugin_Continue;
}

Action eRoundStart(Event event, char[] name, bool dontBroadcast)
{
	GreenWitch = false;
	FireWhite = false;
	IceWitch = false;
	BlackWitch = false;
	VomitWitch = false;
	PurpleWitch = false;
	return Plugin_Continue;
}

void ShowParticle(float pos[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

stock void CreateParticle(int ent, char[] particleType, float time)
{
	char tName[64];
	int particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEntity(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", tName);
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, 0);
	}
}

Action DeleteParticles(Handle timer, any particle)
{
	if (IsValidEntity(particle) && IsValidEdict(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, 64);
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
	return Plugin_Stop;
}

Action eWitchKilled(Event event, char[] event_name, bool dontBroadcast)
{
	int witchid = event.GetInt("witchid");
	if (witchid != 0)
	{
		CreateTimer(1.0, TraceWitch2, witchid, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

Action TraceWitch2(Handle timer, any witch)
{
	if (witch != -1 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char sname[32];
		GetEdictClassname(witch, sname, 32);
		if (StrEqual(sname, "witch", true))
		{
			if (GreenWitch)
			{
				GreenWitch = false;
				return Plugin_Continue;
			}
			if (FireWhite)
			{
				FireWhite = false;
				return Plugin_Continue;
			}
			if (IceWitch)
			{
				IceWitch = false;
				return Plugin_Continue;
			}
			if (BlackWitch)
			{
				BlackWitch = false;
				return Plugin_Continue;
			}
			if (VomitWitch)
			{
				VomitWitch = false;
				return Plugin_Continue;
			}
			if (PurpleWitch)
			{
				PurpleWitch = false;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Stop;
}

Action eWitchSpawn(Event event, char[] s_Name, bool b_DontBroadcast)
{
	int witchid = event.GetInt("witchid");
	CreateEffects(witchid, true);
	return Plugin_Continue;
}

void CreateEffects(int witch, int Index)
{
	float fPos[3];
	GetEntPropVector(witch, Prop_Send, "m_vecOrigin", fPos);

	Index = GetRandomInt(1, 6);
	switch (Index)	
	{
		case 1:
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", GreenWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", GreenWitchHealth);
			CreateTimer(5.0, WitchGreen, witch, TIMER_REPEAT);
			GreenWitch = true;
		}
		case 2:
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", FireWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", FireWitchHealth);
			CreateTimer(0.1, WhiteFire, witch, TIMER_REPEAT);
			FireWhite = true;
		}
		case 3:
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", IceWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", IceWitchHealth);
			CreateTimer(1.0, WitchBlue, witch, TIMER_REPEAT);
			IceWitch = true;
		}
		case 4:
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", BlackWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", BlackWitchHealth);
			CreateTimer(1.0, WitchBlack, witch, TIMER_REPEAT);
			BlackWitch = true;
		}
		case 5:
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", VomitWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", VomitWitchHealth);
			CreateTimer(1.0, WitchVomit, witch, TIMER_REPEAT);
			VomitWitch = true;
		}
		case 6:
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", PurpleWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", PurpleWitchHealth);
			CreateTimer(1.0, WitchPurple, witch, TIMER_REPEAT);
			PurpleWitch = true;
		}
	}
}

Action eWitchSet(Event event, char[] name, bool dontBroadcast)
{
	int target = GetClientOfUserId(event.GetInt("userid")); 
	if (FireWhite)
	{
		CreateParticle(target, "aircraft_destroy_fastFireTrail", 10.0);
		IgniteEntity(target, 10.0);
		DealDamage(target, target, 30, DMG_BULLET,"");
	}
	if (!GreenWitch)
	{
		if (IceWitch) 
		{
			CreateTimer(1.0, Freeze, target);
		}
		if (BlackWitch)
		{
			CreateTimer(1.0, FadeoutTimer, target);
			ScreenFade(target, 0, 255, 255, 192, 5000, 1);
		}
		if (VomitWitch)
		{
			if(GetClientTeam(target) == 2)
			{
				#if !defined _l4dh_included
				SDKCall(sdkVomitSurvivor, target, target, true);
				#else
				if(bL4DHooks)
				{
					L4D_CTerrorPlayer_OnVomitedUpon(target, target);
				}
				else
				{
					SDKCall(sdkVomitSurvivor, target, target, true);
				}
				#endif
			}
		}
		if (PurpleWitch)
		{
			return Plugin_Continue;
		}
	}
	CreateTimer(AcidSpillDamgeOut, AcidSpillOutTimer, target);
	AcidSpillEnable[target] = true;
	AcidSpillDamgeTimer[target] = CreateTimer(5.0, AcidSpill, target, true);
	return Plugin_Continue;
}

Action Freeze(Handle timer, any client)
{
	SetEntityRenderMode(client, RENDER_GLOW);
	SetEntityRenderColor(client, 0, 100, 170, 180);
	SetEntityMoveType(client, MOVETYPE_VPHYSICS);
	CreateTimer(5.0, Timer_UnFreeze, client, TIMER_FLAG_NO_MAPCHANGE);
	EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenFade(client, 0, 128, 255, 192, 5000, 1);
	CreateTimer(IceDamgeOut, IceOutTimer, client, TIMER_REPEAT);
	IceDamgeTimer[client] = CreateTimer(7.0, Timer_IceWitch, client, true);
	return Plugin_Continue;
}

Action AcidSpillOutTimer(Handle timer, any client)
{
	if (AcidSpillDamgeTimer[client] != null)
	{
		AcidSpillEnable[client] = false;
		delete AcidSpillDamgeTimer[client];
	}
	return Plugin_Stop;
}

Action IceOutTimer(Handle timer, any client)
{
	if (IceDamgeTimer[client] != null)
	{
		delete IceDamgeTimer[client];
	}
	return Plugin_Continue;
}

Action AcidSpill(Handle timer, any Client)
{
	CreateAcidSpill(Client, Client);
	return Plugin_Stop;
}

Action WhiteFire(Handle timer, any witch)
{
	if (FireWhite)
	{
		CreateParticle(witch, "fire_small_01", 1.0);
	}
	return Plugin_Continue;
}

Action WitchGreen(Handle timer, any witch)
{
	if (GreenWitch)
	{
		if(IsLeft4Dead2)
		{
			CreateParticle(witch, "spitter_areaofdenial_base_refract", 5.0);
		}
	}
	return Plugin_Continue;
}

Action WitchBlue(Handle timer, any witch)
{
	if (IceWitch)
	{
	    if(IsLeft4Dead2)
		{
		    CreateParticle(witch, "apc_wheel_smoke1", 1.0);
		    CreateParticle(witch, "water_child_water5", 3.0);
		}
		else
		{
		    CreateParticle(witch, "apc_wheel_smoke1", 1.0);
		    CreateParticle(witch, "boomer_leg_smoke", 3.0);
		}
	}
	return Plugin_Continue;
}

Action WitchBlack(Handle timer, any witch)
{
	if (BlackWitch && INVALID_ENT_REFERENCE == witch)
	{
		float entpos[3], effectpos[3];
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", entpos);
		effectpos[0] = entpos[0];
		effectpos[1] = entpos[1];
		effectpos[2] = entpos[2] + 70;
		ShowParticle(effectpos, "policecar_tail_strobe_2b", 3.0);
	}
	return Plugin_Continue;
}

Action WitchVomit(Handle timer, any witch)
{
	if (VomitWitch)
	{
	    if(IsLeft4Dead2) CreateParticle(witch, "vomit_jar_b", 1.0);
		else CreateParticle(witch, "boomer_explode_D", 1.0);
	}
	return Plugin_Continue;
}

Action WitchPurple(Handle timer, any witch)
{
	return Plugin_Continue;
}

Action FadeoutTimer(Handle Timer, int killer)
{
	visibility += 8;
	if (visibility > 240) visibility = 240; 
	ScreenFade(killer, 0, 0, 0, visibility, 0, 0);
	if (visibility >= 240)
	{
		Timer = null;
	}
	return Plugin_Stop;
}

Action Timer_IceWitch(Handle timer, any client)
{
	int color[4]; 
	color[0] = GetRandomInt(1, 255); 
	color[1] = GetRandomInt(1, 255); 
	color[2] = GetRandomInt(1, 255); 
	color[3] = 255;

	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 30;
	
	TE_SetupBeamRingPoint(vec, 20.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 6.0, 0.0, color, 10, 0);
	TE_SendToAll(0.0);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			float pos[3], pos_t[3];
			float distance = 0.0;
			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, pos_t);
			distance = GetVectorDistance(pos, pos_t, false);
			if (distance <= 1200.0) //2.843
			{
				ServerCommand("sm_freeze \"%N\" \"3\"", i);
				CreateTimer(IceDamgeOut, IceOutTimer, i);
				EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
	}
	
	GetClientAbsOrigin(client, brandpos[client]);
	beamcol[client][0] = GetRandomInt(0, 255);
	beamcol[client][1] = GetRandomInt(0, 255);
	beamcol[client][2] = GetRandomInt(0, 255);
	beamcol[client][3] = 135;
	return Plugin_Stop;
}

Action Timer_UnFreeze(Handle timer, any client)
{
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	return Plugin_Stop;
}

stock void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
	{
		BfWriteShort(msg, (0x0002 | 0x0008));
	}
	else
	{
		BfWriteShort(msg, (0x0001 | 0x0010));
	}
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

stock void DealDamage(int attacker=0, int victim, int damage, int dmg_type=0, char[] weapon="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		char victimid[64];
		char dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		int PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(PointHurt,"classname",weapon);
			}
			DispatchSpawn(PointHurt);
			if(IsClientInGame(attacker))
			{
				AcceptEntityInput(PointHurt, "Hurt", attacker);
			}
			else
			{
				AcceptEntityInput(PointHurt, "Hurt", -1);
			}
			RemoveEdict(PointHurt);
		}
	}
}

stock void CreateAcidSpill(int iTarget, int iSender)
{
	float vecPos[3];
	GetClientAbsOrigin(iTarget, vecPos);
	vecPos[2]+=16.0;

	#if !defined _l4dh_included
	int iAcid = CreateEntityByName("spitter_projectile");
	if(IsValidEntity(iAcid))
	{
		DispatchSpawn(iAcid);
		SetEntPropFloat(iAcid, Prop_Send, "m_DmgRadius", 1024.0); // Radius of the acid.
		SetEntProp(iAcid, Prop_Send, "m_bIsLive", 1 ); // Without this set to 1, the acid won't make any sound.
		SetEntPropEnt(iAcid, Prop_Send, "m_hThrower", iSender); // A player who caused the acid to appear.
		TeleportEntity(iAcid, vecPos, NULL_VECTOR, NULL_VECTOR);
		SDKCall(sdkDetonateAcid, iAcid);
	}
	#else
	if(bL4DHooks)
	{
		L4D2_SpitterPrj(iTarget, vecPos, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		int iAcid = CreateEntityByName("spitter_projectile");
		if(IsValidEntity(iAcid))
		{
			DispatchSpawn(iAcid);
			SetEntPropFloat(iAcid, Prop_Send, "m_DmgRadius", 1024.0); // Radius of the acid.
			SetEntProp(iAcid, Prop_Send, "m_bIsLive", 1 ); // Without this set to 1, the acid won't make any sound.
			SetEntPropEnt(iAcid, Prop_Send, "m_hThrower", iSender); // A player who caused the acid to appear.
			TeleportEntity(iAcid, vecPos, NULL_VECTOR, NULL_VECTOR);
			SDKCall(sdkDetonateAcid, iAcid);
		}
	}
	#endif
}
