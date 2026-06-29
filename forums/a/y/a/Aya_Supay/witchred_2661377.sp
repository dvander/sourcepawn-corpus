
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle sdkDetonateAcid = INVALID_HANDLE;
Handle sdkAdrenaline = INVALID_HANDLE;
Handle sdkVomitSurvivor = INVALID_HANDLE;
Handle sdkCallPushPlayer = INVALID_HANDLE;
Handle g_hGameConf = INVALID_HANDLE;

Handle IceDamgeTimer[66];
Handle AcidSpillDamgeTimer[66];
int beamcol[66][4];
float brandpos[66][3];
float addpos[66];
int visibility;
int killer;
int g_BeamSprite;
int g_HaloSprite;
bool GreenWitch;
bool FireWhite;
bool IceWitch;
bool BlackWitch;
bool PurpleWitch;
bool VomitWitch;
Handle IceTimeout;
Handle AcidSpillTimeout;
bool AcidSpillEnable[66];
Handle Cvar_GreenWitchHealth;
Handle Cvar_FireWitchHealth;
Handle Cvar_IceWitchHealth;
Handle Cvar_BlackWitchHealth;
Handle Cvar_PurpleWitchHealth;
Handle Cvar_VomitWitchHealth;

public void OnPluginStart()
{	
	IceTimeout = CreateConVar("Ice_Timeout", "30", "Freezing damage duration", 262144, true, 0.0, false, 0.0);
	AcidSpillTimeout = CreateConVar("AcidSpill_Timeout", "20", "Venom damage duration", 262144, true, 0.0, false, 0.0);
	Cvar_GreenWitchHealth = CreateConVar("GreenWitch_hp", "2000", "Toxic witch's blood volume ", 262144, true, 1.0, true, 10000.0);
	Cvar_FireWitchHealth = CreateConVar("FireWitch_hp", "3000", "Flame witch's blood ", 262144, true, 1.0, true, 10000.0);
	Cvar_IceWitchHealth = CreateConVar("IceWitch_hp", "3000", "Frozen witch's blood ", 262144, true, 1.0, true, 10000.0);
	Cvar_BlackWitchHealth = CreateConVar("BlackWitch_hp", "3000", "Dark witch's blood ", 262144, true, 1.0, true, 10000.0);
	Cvar_PurpleWitchHealth = CreateConVar("PurpleWitch_hp", "3000", "Blood of the poisonous witch ", 262144, true, 1.0, true, 10000.0);
	Cvar_VomitWitchHealth = CreateConVar("VomitWitch_hp", "3000", "Bile witch's blood volume ", 262144, true, 1.0, true, 10000.0);
	
	AutoExecConfig(true, "witch-ju-on", "sourcemod");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_spawn", witch_spawn);
	HookEvent("witch_killed", Event_Witch_Kill);
	HookEvent("witch_harasser_set", WitchTargetBufferSet);
	HookEvent("round_start", Event_RoundStart);
	
	g_hGameConf = LoadGameConfigFile("witchred");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if (sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CSpitterProjectile_Detonate");
	sdkDetonateAcid = EndPrepSDKCall();
	if(sdkDetonateAcid == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CSpitterProjectile::Detonate(void)\" signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnAdrenalineUsed");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkAdrenaline = EndPrepSDKCall();
	if(sdkAdrenaline == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer::OnAdrenalineUsed(float)\" signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitSurvivor = EndPrepSDKCall();
	if(sdkVomitSurvivor == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}
}

public void OnMapStart()
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
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0 && client <= MaxClients && GetClientTeam(client) == 2)
	{
		if (AcidSpillDamgeTimer[client])
		{
			KillTimer(AcidSpillDamgeTimer[client], false);
			AcidSpillDamgeTimer[client] = false;
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	GreenWitch = false;
	FireWhite = false;
	IceWitch = false;
	BlackWitch = false;
	PurpleWitch = false;
	VomitWitch = false;
	return Plugin_Continue;
}

public void ShowParticle(float pos[3], char[] particlename, float time)
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

public void PrecacheParticle(char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(0.01, DeleteParticle, particle, 0);
	}
}

public Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classname[128];
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
	return Plugin_Continue;
}
public void AttachParticle(int ent, char[] particleType, float time)
{
	char tName[64];
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle) && IsValidEdict(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
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
}

public Action DeleteParticles(Handle timer, any particle)
{
	if (IsValidEntity(particle) || IsValidEdict(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, 64);
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop", -1, -1, 0);
			AcceptEntityInput(particle, "kill", -1, -1, 0);
			RemoveEdict(particle);
		}
	}
	return Plugin_Continue;
}

stock int RGB_TO_INT(int red, int green, int blue) 
{
	return (blue * 65536) + (green * 256) + red;
}

public Action Event_Witch_Kill(Handle event, char[] event_name, bool dontBroadcast)
{
	int witchid = GetEventInt(event, "witchid");
	if (witchid != 0)
	{
		CreateTimer(1.0, TraceWitch2, witchid, 2);
	}
	return Plugin_Continue;
}

public Action TraceWitch2(Handle timer, any witch)
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
			if (PurpleWitch)
			{
				PurpleWitch = false;
				return Plugin_Continue;
			}
			if (VomitWitch)
			{
				VomitWitch = false;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public Action witch_spawn(Handle h_Event, char[] s_Name, bool b_DontBroadcast)
{
	int witchid = GetEventInt(h_Event, "witchid");
	if (witchid != 0)
	{
		CreateTimer(1.0, TraceWitchl, witchid, 2);
	}
	return Plugin_Continue;
}

public Action TraceWitchl(Handle timer, any witch)
{
	if (witch != -1 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char sname[32];
		GetEdictClassname(witch, sname, 32);
		if (StrEqual(sname, "witch", true))
		{
			switch (GetRandomInt(0, 5))
			{
				case 0:
				{
					int GreenWitchHealth = GetConVarInt(Cvar_GreenWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iMaxHealth", GreenWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iHealth", GreenWitchHealth);
					SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
					SetEntProp(witch, Prop_Send, "m_bFlashing", 1);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", 119911);
					CreateTimer(5.0, WitchGreen, witch, 1);
					GreenWitch = true;
					SetClientInfo(witch, "name", "toxin witch");
				}
				case 1:
				{
					int glowcolor = RGB_TO_INT(255, 0, 0);
					int FireWitchHealth = GetConVarInt(Cvar_FireWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iMaxHealth", FireWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iHealth", FireWitchHealth);
					SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
					SetEntProp(witch, Prop_Send, "m_bFlashing", 1);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", glowcolor);
					CreateTimer(0.1, WhiteFire, witch, 1);
					FireWhite = true;
					SetClientInfo(witch, "name", "flame witch");
				}
				case 2:
				{
					int glowcolor = RGB_TO_INT(0, 0, 255);
					int IceWitchHealth = GetConVarInt(Cvar_IceWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iMaxHealth", IceWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iHealth", IceWitchHealth);
					SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
					SetEntProp(witch, Prop_Send, "m_bFlashing", 1);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", glowcolor);
					CreateTimer(1.0, WitchBlue, witch, 1);
					IceWitch = true;
					SetClientInfo(witch, "name", "frozen witch");
				}
				case 3:
				{
					int glowcolor = RGB_TO_INT(0, 0, 0);
					int BlackWitchHealth = GetConVarInt(Cvar_BlackWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iMaxHealth", BlackWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iHealth", BlackWitchHealth);
					SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
					SetEntProp(witch, Prop_Send, "m_bFlashing", 1);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", glowcolor);
					CreateTimer(1.0, WitchBlack, witch, 1);
					BlackWitch = true;
					SetClientInfo(witch, "name", "dark witch");
				}
				case 4:
				{
					int glowcolor = RGB_TO_INT(218, 112, 214);
					int VomitWitchHealth = GetConVarInt(Cvar_VomitWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iMaxHealth", VomitWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iHealth", VomitWitchHealth);
					SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
					SetEntProp(witch, Prop_Send, "m_bFlashing", 1);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", glowcolor);
					CreateTimer(1.0, WitchVomit, witch, 1);
					VomitWitch = true;
					SetClientInfo(witch, "name", "bile witch");
				}
				case 5:
				{
					int glowcolor = RGB_TO_INT(255, 0, 255);
					int PurpleWitchHealth = GetConVarInt(Cvar_PurpleWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iMaxHealth", PurpleWitchHealth);
					SetEntProp(witch, Prop_Data, "m_iHealth", PurpleWitchHealth);
					SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
					SetEntProp(witch, Prop_Send, "m_bFlashing", 1);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", glowcolor);
					CreateTimer(1.0, WitchPurple, witch, 1);
					PurpleWitch = true;
					SetClientInfo(witch, "name", "toxic smoke witch");
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action WitchTargetBufferSet(Handle event, char[] name, bool dontBroadcast)
{
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (FireWhite)
	{
		AttachParticle(target, "aircraft_destroy_fastFireTrail", 10.0);
		IgniteEntity(target, 10.0, false, 0.0, false);
		DealDamage(target, target, 30, 2, "");
	}
	if (!GreenWitch)
	{
		if (IceWitch)
		{
			CreateTimer(1.0, Freeze, target, 0);
		}
		if (BlackWitch)
		{
			CreateTimer(1.0, FadeoutTimer, target, 0);
			ScreenFade(target, 0, 255, 255, 192, 5000, 1);
		}
		if (PurpleWitch)
		{
			return;
		}
		if (VomitWitch)
		{
			VomitPlayer(target, target);
		}
	}
	float AcidSpillDamgeOut = GetConVarFloat(AcidSpillTimeout);
	CreateTimer(AcidSpillDamgeOut, AcidSpillOutTimer, target, 0);
	AcidSpillEnable[target] = true;
	AcidSpillDamgeTimer[target] = CreateTimer(5.0, AcidSpill, target, 1);
}

public Action Freeze(Handle timer, any client)
{
	SetEntityRenderMode(client, RENDER_GLOW);
	SetEntityRenderColor(client, 0, 100, 170, 180);
	SetEntityMoveType(client, MOVETYPE_VPHYSICS);
	CreateTimer(5.0, Timer_UnFreeze, client, 2);
	EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenFade(client, 0, 128, 255, 192, 5000, 1);
	float IceDamgeOut = GetConVarFloat(IceTimeout);
	CreateTimer(IceDamgeOut, IceOutTimer, client, 0);
	IceDamgeTimer[client] = CreateTimer(7.0, Timer_IceWitch, client, 1);
	return Plugin_Continue;
}

public Action AcidSpillOutTimer(Handle timer, any client)
{
	if (AcidSpillDamgeTimer[client])
	{
		AcidSpillEnable[client] = false;
		KillTimer(AcidSpillDamgeTimer[client], false);
		AcidSpillDamgeTimer[client] = false;
	}
	return Plugin_Continue;
}

public Action IceOutTimer(Handle timer, any client)
{
	if (IceDamgeTimer[client])
	{
		KillTimer(IceDamgeTimer[client], false);
		IceDamgeTimer[client] = false;
	}
	return Plugin_Continue;
}

public Action AcidSpill(Handle timer, any Client)
{
	CreateAcidSpill(Client, Client);
	return Plugin_Continue;
}

public Action WhiteFire(Handle timer, any witch)
{
	if (FireWhite)
	{
		AttachParticle(witch, "fire_small_01", 1.0);
	}
	return Plugin_Continue;
}

public Action WitchGreen(Handle timer, any witch)
{
	if (GreenWitch)
	{
		AttachParticle(witch, "spitter_areaofdenial_base_refract", 5.0);
	}
	return Plugin_Continue;
}

public Action WitchBlue(Handle timer, any witch)
{
	if (IceWitch)
	{
		AttachParticle(witch, "apc_wheel_smoke1", 1.0);
		AttachParticle(witch, "water_child_water5", 3.0);
	}
	return Plugin_Continue;
}

public Action WitchBlack(Handle timer, any witch)
{
	if (BlackWitch)
	{
		float entpos[3], effectpos[3];
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", entpos, 0);
		effectpos[0] = entpos[0];
		effectpos[1] = entpos[1];
		effectpos[2] = entpos[2] + 70;
		ShowParticle(effectpos, "policecar_tail_strobe_2b", 3.0);
	}
	return Plugin_Continue;
}

public Action WitchPurple(Handle timer, any witch)
{
	return Plugin_Continue;
}

public Action WitchVomit(Handle timer, any witch)
{
	if (VomitWitch)
	{
		AttachParticle(witch, "vomit_jar_b", 1.0);
	}
	return Plugin_Continue;
}

public Action FadeoutTimer(Handle Timer)
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
	return Plugin_Continue;
}

public Action Timer_IceWitch(Handle timer, any client)
{
	float vec[3];
	int Color[4];
	Color[3] = 255;
	GetClientAbsOrigin(client, vec);
	Color[0] = GetRandomInt(0, 255);
	Color[1] = GetRandomInt(0, 255);
	Color[2] = GetRandomInt(0, 255);
	vec[2] += 30;
	
	TE_SetupBeamRingPoint(vec, 20.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 6.0, 0.0, Color, 10, 0);
	TE_SendToAll(0.0);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			float pos[3], pos_t[3];
			float distance = 0.0;
			float IceDamgeOut = GetConVarFloat(IceTimeout);
			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, pos_t);
			distance = GetVectorDistance(pos, pos_t, false);
			if (distance <= 2.843)
			{
				ServerCommand("sm_freeze \"%N\" \"3\"", i);
				CreateTimer(IceDamgeOut, IceOutTimer, i, 0);
				EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
	}
	addpos[client] = 0;
	GetClientAbsOrigin(client, brandpos[client]);
	beamcol[client][0] = GetRandomInt(0, 255);
	beamcol[client][1] = GetRandomInt(0, 255);
	beamcol[client][2] = GetRandomInt(0, 255);
	beamcol[client][3] = 135;
	return Plugin_Handled;
}

public Action Timer_UnFreeze(Handle timer, any client)
{
	if (0 < client)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RENDER_GLOW);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	return Plugin_Continue;
}

public void FakeRealism(bool mode)
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
}

public void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

stock void DealDamage(int victim, int damage, int attacker=0, int dmg_type=0, char weapon[]="")
{
	if(victim > 0 && GetEntProp(victim, Prop_Data, "m_iHealth") > 0 && attacker > 0 && damage > 0)
	{
		char dmg_str[16];
		IntToString(damage, dmg_str, 16);
		char dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		int pointHurt = CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt, "Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType", dmg_type_str);
			if(!StrEqual(weapon, ""))
			{
				DispatchKeyValue(pointHurt, "classname", weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt",(attacker > 0) ? attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

/*
stock void DealDamage(int attacker, int victim, int damage, int dmg_type, char[] weapon)
{
	if (IsValidEdict(victim) && damage > 0)
	{
		char victimid[64];
		char dmg_str[16];
		IntToString(damage, dmg_str, 16);
		char dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		int PointHurt = CreateEntityByName("point_hurt");
		if (PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim, "targetname", victimid);
			DispatchKeyValue(PointHurt, "DamageTarget", victimid);
			DispatchKeyValue(PointHurt, "Damage",dmg_str);
			//DispatchKeyValueFloat(PointHurt, "Damage", float(damage));
			DispatchKeyValue(PointHurt, "DamageType", dmg_type_str);
			if (!StrEqual(weapon, "", true))
			{
				DispatchKeyValue(PointHurt, "classname", weapon);
			}
			DispatchSpawn(PointHurt);
			if (IsClientInGame(attacker)) AcceptEntityInput(PointHurt, "Hurt", attacker, -1, 0);
			else AcceptEntityInput(PointHurt, "Hurt", -1, -1, 0);
			RemoveEdict(PointHurt);
		}
	}
}
*/

int VomitPlayer(int target, int sender)
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

void CreateAcidSpill(int iTarget, int iSender)
{
	float vecPos[3];
	GetClientAbsOrigin(iTarget, vecPos);
	vecPos[2] += 16.0;
	int iAcid = CreateEntityByName("spitter_projectile");
	if (IsValidEntity(iAcid))
	{
		DispatchSpawn(iAcid);
		SetEntPropFloat(iAcid, Prop_Send, "m_DmgRadius", 1024.0);
		SetEntProp(iAcid, Prop_Send, "m_bIsLive", 1);
		SetEntPropEnt(iAcid, Prop_Send, "m_hThrower", iSender, 0);
		TeleportEntity(iAcid, vecPos, NULL_VECTOR, NULL_VECTOR);
		SDKCall(sdkDetonateAcid, iAcid);
	}
}

