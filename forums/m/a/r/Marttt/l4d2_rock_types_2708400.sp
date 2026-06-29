#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CONFIG "data/smoke_rock_settings.cfg"
#define MAXSETTINGS 16

#define MAXROCKS 32
#define MAXTYPES 10

#define GetHitted 	"ambient/energy/zap1.wav"

#define CVAR_FLAGS FCVAR_NOTIFY

enum RockType
{
	Fire = 0,
	Electrical,
	Infected,
	Gravity,
	Nuke,
	Spitter,
	Tesla,
	Boomer,
	Smoke,
	Methamphetamine,
	INVALID_TYPE
}

static const int g_iChances[] =
{
	100, 		// Fire
	100,		// Electrical
	100,		// Infected
	100,		// Gravity
	100,		// Nuke
	100,		// Spitter
	100,		// Tesla
	100,		// Boomer
	100,		// Smoke
	100,		// Methamphetamine
	0		// Normal Rock
};

static const char g_szExplode[][] =
{
	"weapons/hegrenade/explode3.wav",
	"weapons/hegrenade/explode4.wav",
	"weapons/hegrenade/explode5.wav"
};

char g_szRockSettings[MAXSETTINGS][8][16];
float g_flAliveTime[MAXSETTINGS], g_flOrigin[MAXSETTINGS], g_flRadius, g_flInterval;
int g_iMolotovCount, g_iInfected, g_iSpittersProjectiles, g_iSettingsCount, g_iMethamphetamineCount;
int g_iRocks[MAXROCKS], g_iHookCommonState;
bool g_bHook[MAXROCKS], g_bReAllow[MAXPLAYERS + 1], g_bFinale;
Handle sdkMolotovCreate, sdkDeafen, sdkCreateSpitterProjectile, sdkVomited;
ConVar  cMolotovs, cElectricalDamage, cElectricalInterval, cElectricalRadius, cInfectedCount, cIntervalSpawn, cGravityRadius, cGravityStreght, cSpitterRockCount, cSpitterRockInterval,
		cTeslaInterval, cTeslaDamage, cTeslaRadius, cBileRockRadius, cAllowFinale, cMethamphetamineRadius, cMethamphetamineInterval, cMethamphetamineCount;

ConVar g_hCvar_MPGameMode, g_hCvar_GameModesOn, g_hCvar_GameModesOff, g_hCvar_GameModesToggle;

static bool   g_bMapStarted;
static int    g_iCvar_GameModesToggle;
static int    g_iCurrentMode;
static char   g_sCvar_MPGameMode[16];
static char   g_sCvar_GameModesOn[256];
static char   g_sCvar_GameModesOff[256];

public Plugin myinfo =
{
	name = "[L4D2] Rock Types",
	author = "BHaType",
	description = "Creates a different rock types.",
	version = "0.0.7",
	url = "N/A"
}

bool SetupRock(int entity, RockType iType)
{
	if (iType == INVALID_TYPE)
		return false;

	bool bSaved;
	int index;

	for (int i; i < MAXROCKS ; i++)
	{
		if (EntRefToEntIndex(g_iRocks[i]) == 0 || !IsValidEntity(EntRefToEntIndex(g_iRocks[i])))
		{
			index = i;
			g_iRocks[i] = EntIndexToEntRef(entity);
			bSaved = true;
			break;
		}
	}

	if (!bSaved)
		return false;

	switch(iType)
	{
		case Fire:
		{
			IgniteEntity(entity, 30.0);
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 0, 0, 255);
			g_bHook[index] = true;
		}
		case Electrical:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 0, 255, 200);

			int iLightGlow = CreateEntityByName("env_lightglow");

			DispatchKeyValue(iLightGlow, "GlowProxySize", "4.0");
			DispatchKeyValue(iLightGlow, "HDRColorScale", "4.7");
			DispatchKeyValue(iLightGlow, "HorizontalGlowSize", "90");
			DispatchKeyValue(iLightGlow, "MaxDist", "1600");
			DispatchKeyValue(iLightGlow, "MinDist", "500");
			DispatchKeyValue(iLightGlow, "OuterMaxDist", "-2000");
			DispatchKeyValue(iLightGlow, "rendercolor", "20 179 239");
			DispatchKeyValue(iLightGlow, "VerticalGlowSize", "90");

			SetVariantString("!activator");
			AcceptEntityInput(iLightGlow, "SetParent", entity);

			DispatchSpawn(iLightGlow);

			float vOrigin[3];
			vOrigin[2] += 20.0;
			TeleportEntity(iLightGlow, vOrigin, NULL_VECTOR, NULL_VECTOR);

			g_bHook[index] = true;
		}
		case Infected:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 255, 0, 100);
			MakeEnvSteam(entity, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), "0 250 154", "10", "20", "50");
			g_bHook[index] = true;
		}
		case Gravity:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 1, 1, 1, 255);

			int iPush = CreateEntityByName("point_push");

			char szConvars[16];
			cGravityRadius.GetString(szConvars, sizeof szConvars);

			DispatchKeyValue(iPush, "enabled", "0");
			DispatchKeyValue(iPush, "spawnflags", "24");
			DispatchKeyValue(iPush, "radius", szConvars);

			cGravityStreght.GetString(szConvars, sizeof szConvars);
			DispatchKeyValue(iPush, "magnitude", szConvars);

			SetVariantString("!activator");
			AcceptEntityInput(iPush, "SetParent", entity);

			DispatchSpawn(iPush);

			float vOrigin[3];
			TeleportEntity(iPush, vOrigin, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(iPush, "Enable");

			SetEntityGravity(entity, 0.7);
		}
		case Nuke:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 205, 205, 13, 255);

			IgniteEntity(entity, 30.0);
			g_bHook[index] = true;
		}
		case Spitter:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 155, 13, 180);

			g_bHook[index] = true;
		}
		case Tesla:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 25, 25, 255, 60);

			CreateTimer(cTeslaInterval.FloatValue, tThinkRock, EntIndexToEntRef(entity), TIMER_REPEAT);
		}
		case Boomer:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 255, 0, 255);

			SetEntProp(entity, Prop_Send, "m_nGlowRange", 5000);
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (256 * 255 + (65536 * 0)));

			float vAngles[3];

			for (int i; i <= 2; i++)
			{
				vAngles[i] = GetRandomFloat(-180.0, 180.0);
				CreateAttachParticle(vAngles, "boomer_vomit", entity, vAngles);
			}

			g_bHook[index] = true;
		}
		case Smoke:
		{
			float vOrigin[3];
			CreateSmoke (vOrigin, entity, "140", "20", "50", "150", "255 255 255", "255", "666", "666");
			g_bHook[index] = true;
		}
		case Methamphetamine:
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			CreateTimer(0.01, tTimer, EntIndexToEntRef(entity), TIMER_REPEAT);
			g_bHook[index] = true;
		}
	}

	SetEntProp(entity, Prop_Data, "m_iHammerID", view_as<int>(iType));
	return true;
}

public Action tTimer (Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) <= MaxClients || !IsValidEntity(entity))
		return Plugin_Stop;

	SetEntityRenderColor(entity, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
	return Plugin_Continue;
}

public Action tThinkRock (Handle timer, any entity)
{
	static float flTime;
	if ((entity = EntRefToEntIndex(entity)) <= MaxClients || !IsValidEntity(entity))
	{
		flTime = 0.0;
		return Plugin_Stop;
	}

	float vOrigin[3], vPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

	if (vOrigin[0] == 0.0 && vOrigin[1] == 0.0 && vOrigin[2] == 0.0)
		return Plugin_Continue;

	if (GetTickedTime() - flTime > 0.1)
	{
		CreateAttachParticle(vOrigin, "electrical_arc_01_parent", entity);
		flTime = GetTickedTime();
	}

	int client = GetNearestClient(vOrigin, vPos, cTeslaRadius.FloatValue);

	if (client <= 0)
		return Plugin_Continue;

	CreateEffect(vOrigin, vPos);
	ForceDamageEntity(client, cTeslaDamage.IntValue, client);

	return Plugin_Continue;
}

public void OnEntityDestroyed (int entity)
{
	if (IsValidEntity(entity))
	{
		RockType iType;
		bool bFounded;
		int index;

		for (int i; i < MAXROCKS; i++)
		{
			if (EntRefToEntIndex(g_iRocks[i]) == entity && g_bHook[i])
			{
				iType = view_as<RockType>(GetEntProp(entity, Prop_Data, "m_iHammerID"));
				index = i;
				bFounded = true;
				break;
			}
		}

		if (!bFounded)
			return;

		switch (iType)
		{
			case Fire:
			{
				float vOrigin[3], vAngles[3], velocity[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				for (int i; i < g_iMolotovCount; i++)
				{
					velocity[0] = GetRandomFloat(-300.0, 300.0);
					velocity[1] = GetRandomFloat(-300.0, 300.0);
					velocity[2] = GetRandomFloat(-250.0, 250.0);

					SDKCall(sdkMolotovCreate, vOrigin, vOrigin, velocity, vAngles, GetAnyClient(), 0.0);
				}
			}
			case Electrical:
			{
				float vOrigin[3], vPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				int iLight = MakeLightDynamic(vOrigin, vOrigin, "20 179 239", 500);
				int client = GetNearestClient(vOrigin, vPos, 300.0);

				if (client)
				{
					DataPack dPack;

					CreateDataTimer(cElectricalInterval.FloatValue, vElectricalReaction, dPack, TIMER_DATA_HNDL_CLOSE);

					for (int i; i <= 2; i++)
						dPack.WriteFloat(vOrigin[i]);
					dPack.WriteCell(EntIndexToEntRef(iLight));
					dPack.Reset();
				}
				else
				{
					if (!IsValidEntity(iLight) || iLight <= MaxClients)
						return;

					SetVariantString("OnUser1 !self:Kill::1.0:-1");
					AcceptEntityInput(iLight, "AddOutput");
					AcceptEntityInput(iLight, "FireUser1");
				}
			}
			case Infected:
			{
				float vOrigin[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);
				int iSteam = MakeEnvSteam(0, vOrigin, view_as<float>({0.0, 90.0, 0.0}), "0 250 154", "5", "250", "5");
				CreateTimer(cIntervalSpawn.FloatValue, tSpawn, EntIndexToEntRef(iSteam), TIMER_REPEAT);
			}
			case Nuke:
			{
				float vOrigin[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				for (int i = 1; i <= MaxClients; i++)
					if (IsClientInGame(i))
						vForceFly(entity, i);

				CreateAttachParticle(vOrigin, "explosion_huge_b");
				CreateAttachParticle(vOrigin, "explosion_huge");
				CreateAttachParticle(vOrigin, "burning_wood_02c");

				EmitSoundToAll(g_szExplode[GetRandomInt(0, sizeof g_szExplode - 1)], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);

				int iExplosion = CreateEntityByName("env_explosion");

				DispatchKeyValueFloat(iExplosion, "DamageForce", 900.0);

				SetEntProp(iExplosion, Prop_Data, "m_iMagnitude", 0, 4);
				SetEntProp(iExplosion, Prop_Data, "m_iRadiusOverride", 2100, 4);
				DispatchSpawn(iExplosion);

				TeleportEntity(iExplosion, vOrigin, NULL_VECTOR, NULL_VECTOR);

				AcceptEntityInput(iExplosion, "Explode");
				AcceptEntityInput(iExplosion, "Kill");
			}
			case Spitter:
			{
				float vOrigin[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				DataPack dPack;

				CreateDataTimer(cSpitterRockInterval.FloatValue, vInitialVelocitySpitterProjectile, dPack, TIMER_REPEAT + TIMER_DATA_HNDL_CLOSE);

				dPack.WriteFloat(vOrigin[0]);
				dPack.WriteFloat(vOrigin[1]);
				dPack.WriteFloat(vOrigin[2]);
			}
			case Boomer:
			{
				float vOrigin[3], vPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				CreateAttachParticle(vOrigin, "boomer_explode");

				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i) || GetClientTeam(i) != 2)
						continue;

					GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);

					if (GetVectorDistance(vPos, vOrigin) <= cBileRockRadius.FloatValue && IsVisibleTo(vOrigin, vPos))
					{
						SDKCall(sdkVomited, i, i, true);
					}
				}
			}
			case Smoke:
			{
				float vOrigin[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				vOrigin[2] += 150.0;

				int iSmoke;
				int iSmokeSettings = GetRandomInt(0, g_iSettingsCount - 1);

				if (g_szRockSettings[iSmokeSettings][0][0] != '\0')
				{
					vOrigin[2] += g_flOrigin[iSmokeSettings];
					iSmoke = CreateSmoke (vOrigin, _, g_szRockSettings[iSmokeSettings][0], g_szRockSettings[iSmokeSettings][1], g_szRockSettings[iSmokeSettings][2], g_szRockSettings[iSmokeSettings][3], g_szRockSettings[iSmokeSettings][7], g_szRockSettings[iSmokeSettings][4], g_szRockSettings[iSmokeSettings][5], g_szRockSettings[iSmokeSettings][6]);
				}
				else
				{
					iSmoke = CreateSmoke (vOrigin, _, "40", "125", "700", "400", "195 0 50", "255", "0", "600");
				}

				if (iSmoke != -1)
				{
					char szTemp[36];
					Format(szTemp, sizeof szTemp, "OnUser1 !self:Kill::%f:-1", g_szRockSettings[iSmokeSettings][0][0] != '\0' ? g_flAliveTime[iSmokeSettings] : 30.0);
					SetVariantString(szTemp);
					AcceptEntityInput(iSmoke, "AddOutput");
					AcceptEntityInput(iSmoke, "FireUser1");
				}
			}
			case Methamphetamine:
			{
				float vOrigin[3], vPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

				CreateAttachParticle(vOrigin, "embers_small_01");

				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i))
					{
						GetClientEyePosition(i, vPos);

						if (GetVectorDistance(vPos, vOrigin) <= g_flRadius)
							CreateTimer(g_flInterval, tMethamphetamine, GetClientUserId(i), TIMER_REPEAT);
					}
				}
			}
		}
		g_bHook[index] = false;
		g_iRocks[index] = 0;
	}
}

public Action tMethamphetamine (Handle timer, int client)
{
	static int iCount;

	if ((client = GetClientOfUserId(client)) <= 0 || !IsClientInGame(client))
	{
		iCount = 0;
		return Plugin_Stop;
	}

	if (iCount >= g_iMethamphetamineCount)
	{
		float vAngles[3];
		GetClientEyeAngles(client, vAngles);

		vAngles[2] = 0.0;

		TeleportEntity(client, NULL_VECTOR, vAngles, NULL_VECTOR);
		iCount = 0;
		return Plugin_Stop;
	}

	Fade(client, 100, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255),  GetRandomInt(0, 255));

	float vAngles[3];

	GetClientEyeAngles(client, vAngles);

	vAngles[2] += GetRandomFloat(-80.0, 80.0);
	vAngles[0] += GetRandomFloat(-25.0, 25.0);
	vAngles[1] += GetRandomFloat(-25.0, 25.0);

	TeleportEntity(client, NULL_VECTOR, vAngles, NULL_VECTOR);
	iCount++;

	return Plugin_Continue;
}

public Action tSpawn (Handle timer, any iSteam)
{
	static int iSpawn;

	if ((iSteam = EntRefToEntIndex(iSteam)) <= MaxClients || !IsValidEntity(iSteam))
	{
		iSpawn = 0;
		return Plugin_Stop;
	}

	float vOrigin[3];
	GetEntPropVector(iSteam, Prop_Send, "m_vecOrigin", vOrigin);

	SpawnCommon(vOrigin);
	iSpawn++;

	if (iSpawn > g_iInfected)
		AcceptEntityInput(iSteam, "kill");

	return Plugin_Continue;
}

public Action vElectricalReaction (Handle timer, DataPack dPack)
{
	float vOrigin[3], vPos[3];

	for (int i; i <= 2; i++)
		vOrigin[i] = dPack.ReadFloat();

	int iLight = EntRefToEntIndex(dPack.ReadCell());

	SetVariantString("OnUser1 !self:Kill::1.0:-1");
	AcceptEntityInput(iLight, "AddOutput");
	AcceptEntityInput(iLight, "FireUser1");

	int client = GetNearestClient(vOrigin, vPos, cElectricalRadius.FloatValue);

	if (!client)
	{
		for (int i = 1; i <= MaxClients; i++)
			g_bReAllow[i] = false;

		return Plugin_Stop;
	}

	g_bReAllow[client] = true;
	ForceDamageEntity(client, cElectricalDamage.IntValue, client);
	CreateEffect(vPos, vOrigin);

	int iLighting = MakeLightDynamic(vOrigin, vOrigin, "20 179 239", cElectricalRadius.IntValue);

	dPack = new DataPack();

	CreateDataTimer(cElectricalInterval.FloatValue, vElectricalReaction, dPack, TIMER_DATA_HNDL_CLOSE);

	for (int i; i <= 2; i++)
		dPack.WriteFloat(vPos[i]);
	dPack.WriteCell(EntIndexToEntRef(iLighting));
	dPack.Reset();

	return Plugin_Continue;
}

public Action vInitialVelocitySpitterProjectile (Handle timer, DataPack dPack)
{
	static int iCreate;

	if (iCreate > g_iSpittersProjectiles)
	{
		//delete dPack;
		iCreate = 0;
		return Plugin_Stop;
	}

	dPack.Reset();

	float vOrigin[3], vAngles[3];

	for (int i; i <= 2; i++)
		vOrigin[i] = dPack.ReadFloat();

	int iSpitterProjectile = SDKCall(sdkCreateSpitterProjectile, vOrigin, vAngles, vAngles, vAngles,  GetAnyClient());

	if (!IsValidEntity(iSpitterProjectile))
		return Plugin_Continue;

	iCreate++;

	float velocity[3];
	velocity[0] = GetRandomFloat(-250.0, 600.0);
	velocity[1] = GetRandomFloat(-250.0, 600.0);
	velocity[2] = GetRandomFloat(-100.0, 350.0);

	TeleportEntity(iSpitterProjectile, NULL_VECTOR, NULL_VECTOR, velocity);
	return Plugin_Continue;
}

public void OnEntityCreated (int entity, const char[] clsname)
{
	if (!IsValidEntity(entity) || (!g_bFinale && cAllowFinale.IntValue))
		return;

	if (strcmp(clsname, "tank_rock") == 0)
		SDKHook(EntIndexToEntRef(entity), SDKHook_Spawn, eSpawn);
	else if (strcmp(clsname, "infected") == 0 && g_iHookCommonState == 1)
		g_iHookCommonState = EntIndexToEntRef(entity);
}

public void eSpawn (int entity)
{
	if (!IsAllowedGameMode())
		return;

	if ((entity = EntRefToEntIndex(entity)) > MaxClients && IsValidEntity(entity))
	{
		bool bBool;
		int iInt = GetRandomInt(0, MAXTYPES);
		RockType rType = INVALID_TYPE;

		for (int i = iInt; i <= MAXTYPES; i++)
		{
			if (GetRandomInt(1, 100) <= g_iChances[i])
			{
				rType = view_as<RockType>(i);
				bBool = true;
				break;
			}
		}

		if (!bBool)
		{
			for (int i = iInt; i > 0; i--)
			{
				if (GetRandomInt(1, 100) <= g_iChances[i])
				{
					rType = view_as<RockType>(i);
					break;
				}
			}
		}


		SetupRock(entity, rType);
	}
}

public void OnPluginStart()
{
	g_hCvar_MPGameMode = FindConVar("mp_gamemode");
	g_hCvar_MPGameMode.AddChangeHook(OnConVarChange);

	Handle hGameConf = LoadGameConfigFile("l4d2_rock_gamedata");

	if (hGameConf == null)
		SetFailState("No gamedata, unloading...");

	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CMolotovProjectile::Create"))
		SetFailState("Unable to set signature from conf \"CMolotov::EmitGrenade\"");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	//PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkMolotovCreate = EndPrepSDKCall();
	if (sdkMolotovCreate == null)
		SetFailState("Failed to create SDKCall: CMolotov::EmitGrenade");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTerrorPlayer::Deafen"))
		SetFailState("Unable to set signature from conf \"CTerrorPlayer::Deafen\"");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkDeafen = EndPrepSDKCall();
	if (sdkDeafen == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::Deafen");

	StartPrepSDKCall(SDKCall_Static);
	if (PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSpitterProjectile::Create") == false)
		SetFailState("Unable to set signature from conf \"CSpitterProjectile::Create\"");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkCreateSpitterProjectile = EndPrepSDKCall();
	if (sdkCreateSpitterProjectile == null)
		SetFailState("Failed to create SDKCall: CSpitterProjectile::Create");

	StartPrepSDKCall(SDKCall_Player);
	if (PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTerrorPlayer::OnVomitedUpon") == false)
		SetFailState("Unable to set signature from conf \"CTerrorPlayer::OnVomitedUpon\"");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomited = EndPrepSDKCall();
	if (sdkVomited == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::OnVomitedUpon");

	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "%s", CONFIG);

	if (!FileExists(szPath))
	{
		File hFile = OpenFile(szPath, "w");
		hFile.WriteLine("");
		delete hFile;
	}

	LoadSettings(szPath);

	cMolotovs = CreateConVar("sm_molotovs_count_fire_rock", "15", "Number of molotovs from fire rock");

	cElectricalDamage = CreateConVar("sm_damage_electrical_rock", "15", "Damage of electrical rock");
	cElectricalInterval = CreateConVar("sm_interval_electrical_rock", "0.09", "Interval of electrical rock");
	cElectricalRadius = CreateConVar("sm_radius_electrical_rock", "300", "Radius of electrical rock");

	cGravityRadius = CreateConVar("sm_radius_gravity_rock", "700", "Radius of gravity rock");
	cGravityStreght = CreateConVar("sm_streght_gravity_rock", "-600", "Streght of gravity rock");

	cInfectedCount = CreateConVar("sm_infected_rock_count", "15", "Number of commmons by infected rock");
	cIntervalSpawn = CreateConVar("sm_infected_rock_interval", "0.1", "Interval of commmon spawn by infected rock");

	cSpitterRockCount = CreateConVar("sm_spitter_rock_count", "5", "Count of spitter projectiles from spitter rock");
	cSpitterRockInterval = CreateConVar("sm_spitter_rock_interval", "0.1", "Interval of spitter projectile spawn by spitter rock");

	cTeslaInterval  = CreateConVar("sm_tesla_rock_interval", "0.1", "Interval of tesla hit by tesla rock");
	cTeslaDamage = CreateConVar("sm_tesla_rock_damage", "1", "Damage of tesla rock");
	cTeslaRadius = CreateConVar("sm_tesla_rock_radius", "300.0", "Radius of tesla rock");

	cBileRockRadius = CreateConVar("sm_boomer_rock_radius", "150.0", "Radius of boomer rock");

	cAllowFinale = CreateConVar("sm_allow_rocks_only_finale", "0", "Allow plugin works only in finale escape", FCVAR_NONE);

	cMethamphetamineRadius = CreateConVar("sm_methamphetamine_radius", "300.0", "Methamphetamine radius", FCVAR_NONE);
	cMethamphetamineInterval = CreateConVar("sm_methamphetamine_interval", "0.1", "Methamphetamine interval", FCVAR_NONE);
	cMethamphetamineCount = CreateConVar("sm_methamphetamine", "200", "How many times fade client", FCVAR_NONE);

	g_hCvar_GameModesOn =     CreateConVar("l4d2_rock_types_gamemodes_on",     "",  "Turn on the plugin in these game modes, separate by commas (no spaces). Empty = all.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
	g_hCvar_GameModesOff =    CreateConVar("l4d2_rock_types_gamemodes_off",    "",  "Turn off the plugin in these game modes, separate by commas (no spaces). Empty = none.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
	g_hCvar_GameModesToggle = CreateConVar("l4d2_rock_types_gamemodes_toggle", "0", "Turn on the plugin in these game modes.\nKnown values: 0 = all, 1 = coop, 2 = survival, 4 = versus, 8 = scavenge.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for \"coop\" (1) and \"survival\" (2).", CVAR_FLAGS);

	g_iMolotovCount = cMolotovs.IntValue;
	g_iSpittersProjectiles = cSpitterRockCount.IntValue;
	g_iInfected = cInfectedCount.IntValue;
	g_iMethamphetamineCount = cMethamphetamineCount.IntValue;
	g_flRadius = cMethamphetamineRadius.FloatValue;
	g_flInterval = cMethamphetamineInterval.FloatValue;

	cMolotovs.AddChangeHook(OnConVarChange);
	cSpitterRockCount.AddChangeHook(OnConVarChange);
	cInfectedCount.AddChangeHook(OnConVarChange);
	cMethamphetamineRadius.AddChangeHook(OnConVarChange);
	cMethamphetamineInterval.AddChangeHook(OnConVarChange);
	cMethamphetamineCount.AddChangeHook(OnConVarChange);

	g_hCvar_GameModesOn.AddChangeHook(OnConVarChange);
	g_hCvar_GameModesOff.AddChangeHook(OnConVarChange);
	g_hCvar_GameModesToggle.AddChangeHook(OnConVarChange);

	HookEvent("finale_radio_start", eStart, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", eStop, EventHookMode_PostNoCopy);
	HookEvent("round_end", eStop, EventHookMode_PostNoCopy);

	AutoExecConfig(true, "l4d2_rock_types");

	GetCvars();
}

public void eStart (Event event, const char[] name, bool dontbroadcast)
{
	g_bFinale = true;
}

public void eStop (Event event, const char[] name, bool dontbroadcast)
{
	g_bFinale = false;
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void OnConfigsExecuted()
{
    GetCvars();
}

void GetCvars()
{
	g_iMolotovCount = cMolotovs.IntValue;
	g_iSpittersProjectiles = cSpitterRockCount.IntValue;
	g_iInfected = cInfectedCount.IntValue;
	g_flRadius = cMethamphetamineRadius.FloatValue;
	g_flInterval = cMethamphetamineInterval.FloatValue;
	g_iMethamphetamineCount = cMethamphetamineCount.IntValue;

	g_hCvar_MPGameMode.GetString(g_sCvar_MPGameMode, sizeof(g_sCvar_MPGameMode));
	TrimString(g_sCvar_MPGameMode);
	g_hCvar_GameModesOn.GetString(g_sCvar_GameModesOn, sizeof(g_sCvar_GameModesOn));
	ReplaceString(g_sCvar_GameModesOn, sizeof(g_sCvar_GameModesOn), " ", "", false);
	g_hCvar_GameModesOff.GetString(g_sCvar_GameModesOff, sizeof(g_sCvar_GameModesOff));
	ReplaceString(g_sCvar_GameModesOff, sizeof(g_sCvar_GameModesOff), " ", "", false);
	g_iCvar_GameModesToggle = g_hCvar_GameModesToggle.IntValue;
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheSound(GetHitted, true);
	for (int i; i < sizeof g_szExplode; i++)
		PrecacheSound(g_szExplode[i], true);

	PrecacheParticle("st_elmos_fire");
	PrecacheParticle("explosion_huge_j");
	PrecacheParticle("explosion_huge_b");
	PrecacheParticle("explosion_huge");
	PrecacheParticle("burning_wood_02c");
	PrecacheParticle("electrical_arc_01_parent");
	PrecacheParticle("boomer_vomit");
	PrecacheParticle("boomer_explode");
	PrecacheParticle("embers_small_01");
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public bool TraceRayFilter (int entity, int mask)
{
	return (entity > 0 || !IsValidEntity(entity));
}

int MakeLightDynamic (const float vOrigin[3], const float vAngles[3], const char[] sColor, int iDist)
{
	int entity = CreateEntityByName("light_dynamic");
	char sTemp[16];
	Format(sTemp, sizeof(sTemp), "6");
	DispatchKeyValue(entity, "style", sTemp);
	Format(sTemp, sizeof(sTemp), "%s 255", sColor);
	DispatchKeyValue(entity, "_light", sTemp);
	DispatchKeyValue(entity, "brightness", "3");
	DispatchKeyValueFloat(entity, "spotlight_radius", 30.0);
	DispatchKeyValueFloat(entity, "distance", float(iDist));
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	return entity;
}

stock bool IsVisibleTo(float position[3], float targetposition[3])
{
	float vAngles[3], vLookAt[3];
	position[2] += 50.0;

	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	Handle trace = TR_TraceRayFilterEx(position, vAngles, MASK_ALL, RayType_Infinite, TraceRayFilter);

	bool isVisible = false;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint

		if (GetVectorDistance(position, vStart) + 25.0 >= GetVectorDistance(position, targetposition))
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
	}
	else
		isVisible = false;

	position[2] -= 50.0;
	delete trace;
	return isVisible;
}

int GetNearestClient (float vOrigin[3], float vClientOrigin[3], float flRadius)
{
	float vPos[3], flDistance = 66666.666, fDist;
	int client;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !g_bReAllow[i])
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);

			fDist = GetVectorDistance(vOrigin, vPos);

			if (fDist < flDistance && fDist <= flRadius)
			{
				for (int l; l <= 2; l++)
					vClientOrigin[l] = vPos[l];

				flDistance = fDist;
				client = i;
			}
		}
	}

	return client;
}

void CreateEffect (float vPos[3], float vPosEntity[3])
{
	char szTarget[16];
	int info_target = CreateEntityByName("info_particle_target");
	DispatchSpawn(info_target);
	TeleportEntity(info_target, vPosEntity, NULL_VECTOR, NULL_VECTOR);

	Format(szTarget, sizeof(szTarget), "target%d", info_target);
	DispatchKeyValue(info_target, "targetname", szTarget);

	int info_particle = CreateEntityByName("info_particle_system");

	DispatchKeyValue(info_particle, "effect_name", "st_elmos_fire");
	DispatchKeyValue(info_particle, "cpoint1", szTarget);
	DispatchKeyValue(info_particle, "parentname", szTarget);
	DispatchSpawn(info_particle);
	ActivateEntity(info_particle);

	TeleportEntity(info_particle, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(info_particle, "start");

	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(info_particle, "AddOutput");
	AcceptEntityInput(info_particle, "FireUser1");

	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(info_target, "AddOutput");
	AcceptEntityInput(info_target, "FireUser1");

	EmitSoundToAll(GetHitted, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vPosEntity, NULL_VECTOR, true, 0.0);
}

int MakeEnvSteam (int target, const float vPos[3], const float vAng[3], const char[] sColor, const char[] startsize, const char[] endsize, const char[] lenght)
{
	int entity = CreateEntityByName("env_steam");
	if (entity == -1)
	{
		LogError("Failed to create 'env_steam'");
		return -1;
	}

	char sTemp[32];
	Format(sTemp, sizeof sTemp, "silv_steam_%d", target);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(entity, "SpawnFlags", "1");
	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "SpreadSpeed", "10");
	DispatchKeyValue(entity, "Speed", "20");
	DispatchKeyValue(entity, "StartSize", startsize);
	DispatchKeyValue(entity, "EndSize", endsize);
	DispatchKeyValue(entity, "Rate", "50");
	DispatchKeyValue(entity, "JetLength", lenght);
	DispatchKeyValue(entity, "renderamt", "150");
	DispatchKeyValue(entity, "InitialState", "1");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	if (target)
	{
		float vOrigin[3];
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
		TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	return entity;
}

void ForceDamageEntity(int causer, int damage, int victim)
{
	float victim_origin[3];
	char rupture[32], damage_victim[32];
	IntToString(damage, rupture, sizeof(rupture));
	Format(damage_victim, sizeof(damage_victim), "hurtme%d", victim);
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victim_origin);
	int entity = CreateEntityByName("point_hurt");
	DispatchKeyValue(victim, "targetname", damage_victim);
	DispatchKeyValue(entity, "DamageTarget", damage_victim);
	DispatchKeyValue(entity, "Damage", rupture);
	DispatchSpawn(entity);
	TeleportEntity(entity, victim_origin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Hurt", (causer > 0 && causer <= MaxClients) ? causer : -1);
	DispatchKeyValue(entity, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	AcceptEntityInput(entity, "Kill");
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if (FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

void CreateAttachParticle(float vOrigin[3], const char[] name, int iEntity = -1, float vAngles[3] = {0.0, 0.0, 0.0})
{
	int entity = CreateEntityByName("info_particle_system");

	if (entity == -1)
	{
		LogError("Inalid entity %i", entity);
		return;
	}

	DispatchKeyValue(entity, "effect_name", name);

	if (iEntity != -1)
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", iEntity);
	}

	DispatchSpawn(entity);
	ActivateEntity(entity);

	if (iEntity == -1)
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	else
		TeleportEntity(entity, view_as<float>({0.0, 0.0, 0.0}), vAngles, NULL_VECTOR);

	AcceptEntityInput(entity, "start");

	SetVariantString("OnUser1 !self:Kill::9.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

void SpawnCommon(float vOrigin[3])
{
	g_iHookCommonState = 1;

	int client;

	if ((client = GetAnyClient()) <= 0)
		return;

	int iFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn_old infected auto");
	SetCommandFlags("z_spawn_old", iFlags);
	int iEntity = EntRefToEntIndex(g_iHookCommonState);

	if (!IsValidEntity(iEntity) || iEntity <= MaxClients)
		return;

	TeleportEntity(iEntity, vOrigin, NULL_VECTOR, NULL_VECTOR);
}

void vForceFly (int client, int target)
{
	float vPos[3], vOrigin[3], flPower, vAng[3], vResult[3];

	GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(target, Prop_Data,"m_vecOrigin", vOrigin);

	flPower = 1200 - GetVectorDistance(vPos, vOrigin);

	if (flPower < 1 || !IsVisibleTo(vPos, vOrigin))
		return;

	MakeVectorFromPoints(vPos, vOrigin, vAng);
	GetVectorAngles(vAng, vResult);

	vResult[0] = Cosine(DegToRad(vResult[1])) * flPower * GetRandomFloat(0.8, 1.2);
	vResult[1] = Sine(DegToRad(vResult[1])) * flPower * GetRandomFloat(0.8, 1.2);
	vResult[2] = (flPower + flPower) * GetRandomFloat(0.3, 0.5);

	ForceDamageEntity(target, iGetProcentDamage(flPower), target);

	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vResult);
	if (GetVectorDistance(vPos, vOrigin) <= 200.0)
		SDKCall(sdkDeafen, target, 1.0, 0.0, 0.01);
}

int iGetProcentDamage(float flDistance)
{
	return RoundToCeil(100 * flDistance / 1500);
}

int CreateSmoke (float vOrigin[3], int iEntity = -1, const char[] szSpeed, const char[] szStart, const char[] szEnd, const char[] szLenght, const char[] szColor, const char[] szArmt, const char[] szTwist, const char[] szRate)
{
	int entity = CreateEntityByName("env_smokestack");

	if (entity == -1)
		return -1;

	DispatchKeyValue(entity, "BaseSpread", "25");
	DispatchKeyValue(entity, "SpreadSpeed", "1000");
	DispatchKeyValue(entity, "Speed", szSpeed);
	DispatchKeyValue(entity, "StartSize", szStart);
	DispatchKeyValue(entity, "EndSize", szEnd);
	DispatchKeyValue(entity, "Rate", szRate);
	DispatchKeyValue(entity, "JetLength", szLenght);
	DispatchKeyValue(entity, "SmokeMaterial", "particle/SmokeStack.vmt");
	DispatchKeyValue(entity, "twist", szTwist);
	DispatchKeyValue(entity, "rendercolor", szColor);
	DispatchKeyValue(entity, "renderamt", szArmt);
	DispatchKeyValue(entity, "roll", "100");
	DispatchKeyValue(entity, "InitialState", "1");
	DispatchKeyValue(entity, "angles", "180 0 0");
	DispatchKeyValue(entity, "WindSpeed", "200");
	DispatchKeyValue(entity, "WindAngle", "0");

	if (iEntity != -1)
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", iEntity);
		TeleportEntity(entity, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		DispatchKeyValueVector(entity, "origin", vOrigin);
		TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	return entity;
}

void LoadSettings (const char[] szPath)
{
	g_iSettingsCount = 0;

	KeyValues hKeyValues = new KeyValues("Settings");

	if (!hKeyValues.ImportFromFile(szPath))
	{
		delete hKeyValues;
		return;
	}

	char szTemp[4];

	for (int i; i < MAXSETTINGS; i++)
	{
		IntToString(i, szTemp, sizeof szTemp);

		if (!hKeyValues.JumpToKey(szTemp))
			break;

		hKeyValues.GetString("Speed", 		g_szRockSettings[i][0], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("Start Size",	g_szRockSettings[i][1], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("End Size", 		g_szRockSettings[i][2], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("Lenght", 		g_szRockSettings[i][3], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("Armt", 			g_szRockSettings[i][4], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("Twist", 		g_szRockSettings[i][5], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("Rate", 			g_szRockSettings[i][6], sizeof g_szRockSettings[][]);
		hKeyValues.GetString("Color", 		g_szRockSettings[i][7], sizeof g_szRockSettings[][]);

		g_flOrigin[i] = hKeyValues.GetFloat("Origin");
		g_flAliveTime[i] = hKeyValues.GetFloat("Alive Time");

		hKeyValues.GoBack();

		g_iSettingsCount++;
	}

	delete hKeyValues;
}

void Fade(int client, int iTime, int R, int G, int B, int A, int iMode = 0x0010)
{
	Handle FadeM = StartMessageOne("Fade", client);

	BfWriteShort(FadeM, 255);
	BfWriteShort(FadeM, iTime);
	BfWriteShort(FadeM, iMode);
	BfWriteByte(FadeM, R);
	BfWriteByte(FadeM, G);
	BfWriteByte(FadeM, B);
	BfWriteByte(FadeM, A);

	EndMessage();
}

int GetAnyClient ()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			return i;

	return 0;
}

//Silvers method for IsAllowedGameMode
bool IsAllowedGameMode()
{
	if (g_hCvar_MPGameMode == null)
		return false;

	if (g_iCvar_GameModesToggle)
	{
		if (g_bMapStarted == false)
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if (IsValidEntity(entity))
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGameMode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGameMode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGameMode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGameMode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if (IsValidEntity(entity)) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if (!g_iCurrentMode)
			return false;

		if (!(g_iCvar_GameModesToggle & g_iCurrentMode))
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvar_MPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvar_GameModesOn.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
			return false;
	}

	g_hCvar_GameModesOff.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
			return false;
	}

	return true;
}

public void OnGameMode(const char[] output, int caller, int activator, float delay)
{
	if (StrEqual(output, "OnCoop"))
	    g_iCurrentMode = 1;
	else if (StrEqual(output, "OnSurvival"))
	    g_iCurrentMode = 2;
	else if (StrEqual(output, "OnVersus"))
	    g_iCurrentMode = 4;
	else if (StrEqual(output, "OnScavenge"))
	    g_iCurrentMode = 8;
	else
	    g_iCurrentMode = 0;
}