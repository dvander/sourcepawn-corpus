#pragma semicolon 1
 
// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <tf2items>
#include <float>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION	"1.5"

#define SOUND_JUMP1	"vo/halloween_boss/knight_alert02.mp3"
#define SOUND_JUMP2	"vo/halloween_boss/knight_alert01.mp3"
#define SOUND_KILLSCOUT	"vo/halloween_boss/knight_attack01.mp3"
#define SOUND_KILLSOLDIER	"vo/halloween_boss/knight_attack02.mp3"
#define SOUND_KILLPYRO	"vo/halloween_boss/knight_attack02.mp3"
#define SOUND_KILLDEMO	"vo/halloween_boss/knight_attack04.mp3"
#define SOUND_KILLHEAVY	"vo/halloween_boss/knight_attack01.mp3"
#define SOUND_KILLMEDIC	"vo/halloween_boss/knight_attack03.mp3"
#define SOUND_KILLSNIPER1	"vo/halloween_boss/knight_attack04.mp3"
#define SOUND_KILLSPY1	"vo/halloween_boss/knight_attack02.mp3"
#define SOUND_KILLENGY1	"vo/halloween_boss/knight_attack01.mp3"
#define SOUND_KILLSENTRY	"vo/halloween_boss/knight_laugh01.mp3"
#define SOUND_TAUNT1	"vo/halloween_boss/knight_alert.mp3"
#define SOUND_TAUNT2	"vo/halloween_boss/knight_alert.mp3"
#define SOUND_TAUNT3	"vo/halloween_boss/knight_alert.mp3"
#define SOUND_TAUNT4	"vo/halloween_boss/knight_alert.mp3"
 #define MODEL_HALE	"models/player/saxton_hale/hhh_jr_mk3.mdl"
 
// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;
new Handle:g_hCvarHealth;
new Handle:g_hCvarModel;
new Handle:g_hCvarSuperJumps;
new Handle:g_hCvarRaging;
new Handle:g_hCvarSounds;
new Handle:g_hCvarRedLimit;
new Handle:g_hCvarBluLimit;
new Handle:g_hCvarRespawn;
new Handle:g_hCvarHintSound;

// ====[ CVAR VARIABLES] ======================================================
new g_iHealth;
new g_iRaging;
new g_iRedLimit;
new g_iBluLimit;
new bool:g_bEnabled;
new bool:g_bModel;
new bool:g_bSuperJumps;
new bool:g_bSounds;
new bool:g_bRespawn;
 
// ====[ VARIABLES ]===========================================================
new Float:g_iRage			[MAXPLAYERS + 1];
new TFClassType:g_iOldClass	[MAXPLAYERS + 1];
new bool:g_bHHHJunior		[MAXPLAYERS + 1];
 
// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Be The Horsemann Junior",
	author = "StormishJustice",
	description = "Be the Horsemann Junior!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=264397"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_bethehhhjunior_version", PLUGIN_VERSION, "Be The Horsemann Junior Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_bethehhhjunior_enabled", "1", "Enable Be The Horsemann Junior\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarHealth = CreateConVar("sm_bethehhhjunior_health", "10000", "Health Horsemann Junior gets", _, true, 325.0);
	g_iHealth = GetConVarInt(g_hCvarHealth);
	HookConVarChange(g_hCvarHealth, OnConVarChange);

	g_hCvarModel = CreateConVar("sm_bethehhhjunior_model", "1", "Enable setting player model\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bModel = GetConVarBool(g_hCvarModel);
	HookConVarChange(g_hCvarModel, OnConVarChange);
 
	g_hCvarSuperJumps = CreateConVar("sm_bethehhhjunior_superjumps", "1", "Enable super jumps\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bSuperJumps = GetConVarBool(g_hCvarSuperJumps);
	HookConVarChange(g_hCvarSuperJumps, OnConVarChange);

	g_hCvarRaging = CreateConVar("sm_bethehhhjunior_raging", "2", "Rage percent regeneration\n0 = Disabled", _, true, 0.0);
	g_iRaging = GetConVarInt(g_hCvarRaging);
	HookConVarChange(g_hCvarRaging, OnConVarChange);

	g_hCvarSounds = CreateConVar("sm_bethehhhjunior_sounds", "1", "Enable horsemann junior sounds\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bSounds = GetConVarBool(g_hCvarSounds);
	HookConVarChange(g_hCvarSounds, OnConVarChange);

	g_hCvarRedLimit = CreateConVar("sm_bethehhhjunior_redlimit", "-1", "Max red players allowed to be horsemann junior\n-1 = Disabled", _, true, -1.0);
	g_iRedLimit = GetConVarInt(g_hCvarRedLimit);
	HookConVarChange(g_hCvarRedLimit, OnConVarChange);
 
	g_hCvarBluLimit = CreateConVar("sm_bethehhhjunior_blulimit", "-1", "Max blu players allowed to be horsemann junior\n-1 = Disabled", _, true, -1.0);
	g_iBluLimit = GetConVarInt(g_hCvarBluLimit);
	HookConVarChange(g_hCvarBluLimit, OnConVarChange);
 
	g_hCvarRespawn = CreateConVar("sm_bethehhhjunior_respawn", "1", "Enable respawning as horsemann junior\n0 = Disabled\n1 = Enabled", _, true, -1.0);
	g_bRespawn = GetConVarBool(g_hCvarRespawn);
	HookConVarChange(g_hCvarRespawn, OnConVarChange);

	g_hCvarHintSound = FindConVar("sv_hudhint_sound");
	HookConVarChange(g_hCvarHintSound, OnConVarChange);

	AutoExecConfig(true, "plugin.bethehhhjunior");

	RegAdminCmd("sm_hhhjunior", BeTheHHHJuniorCmd, ADMFLAG_GENERIC, "Be The Horsemann Junior");
	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("post_inventory_application", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);
	HookEvent("player_hurt",OnPlayerHurt);

	AddNormalSoundHook(SoundHook);
 
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("bethehhhjunior.phrases");

	CreateTimer(0.2, Timer_SuperJump, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_RageMeter, _, TIMER_REPEAT);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	if(hConvar == g_hCvarHealth)
	g_iHealth = GetConVarInt(g_hCvarHealth);
	if(hConvar == g_hCvarModel)
	g_bModel = GetConVarBool(g_hCvarModel);
	if(hConvar == g_hCvarSuperJumps)
	g_bSuperJumps = GetConVarBool(g_hCvarSuperJumps);
	if(hConvar == g_hCvarRaging)
	g_iRaging = GetConVarInt(g_hCvarRaging);
	if(hConvar == g_hCvarSounds)
	g_bSounds = GetConVarBool(g_hCvarSounds);
	if(hConvar == g_hCvarRedLimit)
	g_iRedLimit = GetConVarInt(g_hCvarRedLimit);
	if(hConvar == g_hCvarBluLimit)
	g_iBluLimit = GetConVarInt(g_hCvarBluLimit);
	if(hConvar == g_hCvarRespawn)
	g_bRespawn = GetConVarBool(g_hCvarRespawn);
	if(hConvar == g_hCvarHintSound)
	SetConVarBool(g_hCvarHintSound, false);
}

public OnClientPutInServer(iClient)
{
	g_iRage[iClient] = 0.0;
	g_bHHHJunior[iClient] = false;
	g_iOldClass[iClient] = TFClass_Unknown;
}
 
public OnMapStart()
{
	PrecacheSound(SOUND_JUMP1, true);
	PrecacheSound(SOUND_JUMP2, true);

	PrecacheSound(SOUND_KILLSCOUT, true);
	PrecacheSound(SOUND_KILLSOLDIER, true);
	PrecacheSound(SOUND_KILLPYRO, true);
	PrecacheSound(SOUND_KILLDEMO, true);
	PrecacheSound(SOUND_KILLHEAVY, true);
	PrecacheSound(SOUND_KILLMEDIC, true);
	PrecacheSound(SOUND_KILLSNIPER1, true);
	PrecacheSound(SOUND_KILLSPY1, true);
	PrecacheSound(SOUND_KILLENGY1, true);
	PrecacheSound(SOUND_KILLSENTRY, true);

	PrecacheSound(SOUND_TAUNT1, true);
	PrecacheSound(SOUND_TAUNT2, true);
	PrecacheSound(SOUND_TAUNT3, true);
	PrecacheSound(SOUND_TAUNT4, true);

	PrecacheModel(MODEL_HALE, true);

	decl String:strPath[PLATFORM_MAX_PATH];
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_JUMP1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_JUMP2);
	AddFileToDownloadsTable(strPath);

	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSCOUT);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLPYRO);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLDEMO);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLHEAVY);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLMEDIC);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSNIPER1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSPY1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLENGY1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSENTRY);
	AddFileToDownloadsTable(strPath);

	Format(strPath, sizeof(strPath), "sound/%s", SOUND_TAUNT1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_TAUNT2);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_TAUNT3);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_TAUNT4);
	AddFileToDownloadsTable(strPath);

	AddFileToDownloadsTable(MODEL_HALE);
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.dx80.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.dx90.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.sw.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.vvd");

	SetConVarBool(g_hCvarHintSound, false);
}

public Action:OnPlayerSpawn(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
	return Plugin_Continue;
 
	if(!g_bHHHJunior[iClient] || !g_bEnabled || !g_bModel || !g_bRespawn)
	{
	CreateTimer(0.5, Timer_ResetModel, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	if(!g_bRespawn)
	g_bHHHJunior[iClient] = false;
	}
	else
	CreateTimer(0.5, Timer_MakeHHHJunior, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
	return Plugin_Continue;

	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iVictim))
	return Plugin_Continue;

	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iAttacker) || !IsPlayerAlive(iAttacker) || !g_bHHHJunior[iAttacker])
	return Plugin_Continue;
 
	if(!g_bSounds)
	return Plugin_Continue;

	new TFClassType:iClass = TF2_GetPlayerClass(iVictim);
	switch(iClass)
	{
	case TFClass_Scout: EmitSoundToAll(SOUND_KILLSCOUT, iAttacker, SNDCHAN_VOICE);
	case TFClass_Soldier: EmitSoundToAll(SOUND_KILLSOLDIER, iAttacker, SNDCHAN_VOICE);
	case TFClass_Pyro: EmitSoundToAll(SOUND_KILLPYRO, iAttacker, SNDCHAN_VOICE);
	case TFClass_DemoMan: EmitSoundToAll(SOUND_KILLDEMO, iAttacker, SNDCHAN_VOICE);
	case TFClass_Heavy: EmitSoundToAll(SOUND_KILLHEAVY, iAttacker, SNDCHAN_VOICE);
	case TFClass_Medic: EmitSoundToAll(SOUND_KILLMEDIC, iAttacker, SNDCHAN_VOICE);
	case TFClass_Sniper:
	{
	EmitSoundToAll(SOUND_KILLSNIPER1, iAttacker, SNDCHAN_VOICE);
	}
	case TFClass_Spy:
	{
	EmitSoundToAll(SOUND_KILLSPY1, iAttacker, SNDCHAN_VOICE);
	}
	case TFClass_Engineer:
	{
	EmitSoundToAll(SOUND_KILLENGY1, iAttacker, SNDCHAN_VOICE);
	}
	}
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
	return Plugin_Continue;

	if(g_bHHHJunior[iClient])
	{
	if(!g_bEnabled || g_iRaging <= 0)
	return Plugin_Continue;

	new Float:rageAdd = float(GetEventInt(hEvent, "damageamount")) / 19.0;

	SetGlobalTransTarget(iClient);
	if(g_iRage[iClient] + rageAdd <= 100.0 - rageAdd)
	{
	g_iRage[iClient] += rageAdd;
	}
	else
	{
	g_iRage[iClient] = 100.0;
	}
	return Plugin_Continue;
	}

	return Plugin_Continue;
}

public Action:OnObjectDestroyed(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
	return Plugin_Continue;
 
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iAttacker) || !IsPlayerAlive(iAttacker) || !g_bHHHJunior[iAttacker])
	return Plugin_Continue;

	if(g_bSounds)
	{
	EmitSoundToAll(SOUND_KILLSENTRY, iAttacker, SNDCHAN_VOICE);
	}
	return Plugin_Continue;
}

public Action:SoundHook(iClients[64], &iClientCount, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:fVolume, &iLevel, &iPitch, &iFlags)
{
	if(!g_bSounds || !IsValidClient(iEntity))
	return Plugin_Continue;

	if(g_bHHHJunior[iEntity] && StrContains(strSample, "vo/halloween_boss", false) == -1)
	return Plugin_Stop;
	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:BeTheHHHJuniorCmd(iClient, iArgs)
{
	if(!g_bEnabled)
	return Plugin_Continue;

	if(iArgs != 0 && iArgs != 2)
	{
	ReplyToCommand(iClient, "[SM] Usage: sm_hhhjunior <target> <0/1>");
	return Plugin_Handled;
	}

	if(iArgs == 0)
	{
	if(g_bHHHJunior[iClient])
	{
	SetGlobalTransTarget(iClient);
	PrintToChat(iClient, "[SM] %t", "hhhjunior_disabled");
	g_bHHHJunior[iClient] = false;
	if(IsPlayerAlive(iClient))
	{
	decl String:strModel[PLATFORM_MAX_PATH];
	GetClientModel(iClient, strModel, sizeof(strModel));
	if(StrEqual(strModel, MODEL_HALE))
	{
	SetVariantString("");
	AcceptEntityInput(iClient, "SetCustomModel");
	}
	if(g_iOldClass[iClient] != TFClass_Unknown)
	{
	TF2_SetPlayerClass(iClient, g_iOldClass[iClient]);
	g_iOldClass[iClient] = TFClass_Unknown;
	}
	TF2_RegeneratePlayer(iClient);
	SetEntProp(iClient, Prop_Data, "m_iHealth", GetEntProp(iClient, Prop_Data, "m_iMaxHealth"));
	}
	}
	else
	{
	new iTeam = GetClientTeam(iClient);
	if(iTeam == 2 && GetTeamHaleCount(2) >= g_iRedLimit && g_iRedLimit != -1)
	{
	PrintToChat(iClient, "[SM] %t", "max_hales_red");
	return Plugin_Handled;
	}
	if(iTeam == 3 && GetTeamHaleCount(3) >= g_iBluLimit && g_iBluLimit != -1)
	{
	PrintToChat(iClient, "[SM] %t", "max_hales_blu");
	return Plugin_Handled;
	}

	SetGlobalTransTarget(iClient);
	PrintToChat(iClient, "[SM] %t", "hhhjunior_enabled");
	g_iOldClass[iClient] = TF2_GetPlayerClass(iClient);
	g_bHHHJunior[iClient] = true;

	if(IsPlayerAlive(iClient))
	MakePlayerHHHJunior(iClient);
	}
	}
	else if(iArgs == 2)
	{
	if(!CheckCommandAccess(iClient, "sm_hhhjunior_target", ADMFLAG_GENERIC))
	{
	ReplyToCommand(iClient, "[SM] %t.", "No Access");
	return Plugin_Handled;
	}

	decl String:strArg1[MAX_NAME_LENGTH];
	GetCmdArg(1, strArg1, sizeof(strArg1));

	decl String:strArg2[2];
	GetCmdArg(2, strArg2, sizeof(strArg2));

	new iTarget = FindTarget(iClient, strArg1);
	if(!IsValidClient(iTarget))
	return Plugin_Handled;

	new iValue = StringToInt(strArg2);
	if((!StrEqual(strArg2, "0") && iValue == 0) || (iValue != 0 && iValue != 1))
	{
	ReplyToCommand(iClient, "[SM] Usage: sm_hhhjunior <target> <0/1>");
	return Plugin_Handled;
	}

	if(iValue == 0 && g_bHHHJunior[iTarget])
	{
	SetGlobalTransTarget(iTarget);
	PrintToChat(iTarget, "[SM] %t", "hhhjunior_disabled");
	g_bHHHJunior[iTarget] = false;
	if(IsPlayerAlive(iTarget))
	{
	decl String:strModel[PLATFORM_MAX_PATH];
	GetClientModel(iTarget, strModel, sizeof(strModel));
	if(StrEqual(strModel, MODEL_HALE))
	{
	SetVariantString("");
	AcceptEntityInput(iTarget, "SetCustomModel");
	}
	if(g_iOldClass[iTarget] != TFClass_Unknown)
	{
	TF2_SetPlayerClass(iTarget, g_iOldClass[iTarget]);
	g_iOldClass[iTarget] = TFClass_Unknown;
	}
	TF2_RegeneratePlayer(iTarget);
	SetEntProp(iTarget, Prop_Data, "m_iHealth", GetEntProp(iTarget, Prop_Data, "m_iMaxHealth"));
	}
	}
	else if(iValue == 1 && !g_bHHHJunior[iTarget])
	{
	new iTeam = GetClientTeam(iTarget);
	if(iTeam == 2 && GetTeamHaleCount(2) >= g_iRedLimit && g_iRedLimit != -1)
	{
	PrintToChat(iClient, "[SM] %t", "max_hales_red");
	return Plugin_Handled;
	}
	if(iTeam == 3 && GetTeamHaleCount(3) >= g_iBluLimit && g_iBluLimit != -1)
	{
	PrintToChat(iClient, "[SM] %t", "max_hales_blu");
	return Plugin_Handled;
	}

	SetGlobalTransTarget(iTarget);
	PrintToChat(iTarget, "[SM] %t", "hhhjunior_enabled");
	g_iOldClass[iTarget] = TF2_GetPlayerClass(iTarget);

	if(IsPlayerAlive(iTarget))
	MakePlayerHHHJunior(iTarget);
	}
	}
	return Plugin_Handled;
}

public Action:TauntCmd(iClient, const String:strCommand[], iArgc)
{
	if(!g_bEnabled || g_iRaging <= 0)
	return Plugin_Continue;

	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient) || !g_bHHHJunior[iClient] || g_iRage[iClient] < 100.0)
	return Plugin_Continue;

	decl Float:fOrigin[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fOrigin);
	fOrigin[2] += 20.0;

	TF2_AddCondition(iClient, TFCond:42, 4.0);
	if(g_bSounds)
	{
		switch(GetRandomInt(0, 3))
		{
			case 0: EmitSoundToAll(SOUND_TAUNT1, iClient, SNDCHAN_VOICE);
			case 1: EmitSoundToAll(SOUND_TAUNT2, iClient, SNDCHAN_VOICE);
			case 2: EmitSoundToAll(SOUND_TAUNT3, iClient, SNDCHAN_VOICE);
			case 3: EmitSoundToAll(SOUND_TAUNT4, iClient, SNDCHAN_VOICE);
		}
	}
	CreateTimer(0.6, Timer_UseRage, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	g_iRage[iClient] = 0.0;
	return Plugin_Continue;
}

// ====[ TIMERS ]==============================================================
public Action:Timer_SuperJump(Handle:hTimer)
{
	if(!g_bEnabled || !g_bSuperJumps)
	return Plugin_Continue;

	static iJumpCharge[MAXPLAYERS + 1];
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(!IsPlayerAlive(i) || !g_bHHHJunior[i])
			continue;

		new iButtons = GetClientButtons(i);
		if((iButtons & IN_DUCK || iButtons & IN_ATTACK2) && iJumpCharge[i] >= 0 && !(iButtons & IN_JUMP))
		{
			if(iJumpCharge[i] + 5 < 25)
				iJumpCharge[i] += 5;
			else
				iJumpCharge[i] = 25;
			PrintCenterText(i, "%t", "jump_status", iJumpCharge[i] * 4);
		}
		else if(iJumpCharge[i] < 0)
		{
			iJumpCharge[i] += 5;
			PrintCenterText(i, "%t %i", "jump_status_2", -iJumpCharge[i] / 20);
		}
		else
		{
			decl Float:fAngles[3];
			GetClientEyeAngles(i, fAngles);
			decl Float:fOrigin[3];
			new randomPlayer = GetRandomPlayer(GetClientTeam(i));
			if(fAngles[0] < -45.0 && iJumpCharge[i] > 1 && randomPlayer != -1)
			{
				AttachParticle(i,"ghost_appearation");
				TF2_StunPlayer(i, 5.0, _, TF_STUNFLAGS_LOSERSTATE, i);
				GetEntPropVector(randomPlayer, Prop_Send, "m_vecOrigin", fOrigin);
				TeleportEntity(i, fOrigin, NULL_VECTOR, NULL_VECTOR);

				iJumpCharge[i] = -120;

				if(g_bSounds)
				{
					new iRandom = GetRandomInt(0, 1);
					switch(iRandom)
					{
						case 0: EmitSoundToAll(SOUND_JUMP1, i, SNDCHAN_VOICE);
						case 1: EmitSoundToAll(SOUND_JUMP2, i, SNDCHAN_VOICE);
					}
				}
			}
			else
			{
				iJumpCharge[i] = 0;
				PrintCenterText(i, "");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_RageMeter(Handle:hTimer)
{
	if(!g_bEnabled || g_iRaging <= 0)
	return Plugin_Continue;

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
	if(g_bHHHJunior[i])
	{
	SetGlobalTransTarget(i);
	if(g_iRage[i] >= 100.0)
	{
	PrintHintText(i, "%t", "rage_full");
	}
	else
	{
	decl String:strName[128];
	new theNumber = RoundToCeil(g_iRage[i]);
	Format(strName, sizeof(strName), "%t %", "rage_status", theNumber);
	PrintHintText(i, "%s", strName);
	}
	}
	}
	return Plugin_Continue;
}

public Action:Timer_UseRage(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
	return Plugin_Continue;

	TF2_RemoveCondition(iClient, TFCond_Taunting);


	decl Float:fOrigin1[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fOrigin1);

	decl Float:fOrigin2[3];
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
	if(GetClientTeam(i) != GetClientTeam(iClient) && IsPlayerAlive(i) && i != iClient)
	{
	GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOrigin2);
	if(!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && GetVectorDistance(fOrigin1, fOrigin2) < 800.0)
	{
	new iFlags = TF_STUNFLAGS_GHOSTSCARE;
	TF2_StunPlayer(i, 5.0, _, iFlags, iClient);
	}
	}
	}

	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "obj_sentrygun")) != -1)
	{
	if(GetEntProp(iEntity, Prop_Send, "m_iTeamNum") == GetClientTeam(iClient))
	continue;

	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin2);
	if(GetVectorDistance(fOrigin1, fOrigin2) < 800.0)
	{
	SetEntProp(iEntity, Prop_Send, "m_bDisabled", 1);
	AttachParticle(iEntity, "yikes_fx", 75.0);
	SetVariantInt(GetEntProp(iEntity, Prop_Send, "m_iHealth") / 2);
	AcceptEntityInput(iEntity, "RemoveHealth");
	CreateTimer(8.0, Timer_ReEnableSentry, EntIndexToEntRef(iEntity));
	}
	}

	while((iEntity = FindEntityByClassname(iEntity, "obj_dispenser")) != -1)
	{
	if(GetEntProp(iEntity, Prop_Send, "m_iTeamNum") == GetClientTeam(iClient))
	continue;

	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin2);
	if(GetVectorDistance(fOrigin1, fOrigin2) < 800.0)
	{
	SetVariantInt(1);
	AcceptEntityInput(iEntity, "RemoveHealth");
	}
	}

	while((iEntity = FindEntityByClassname(iEntity, "obj_teleporter")) != -1)
	{
	if(GetEntProp(iEntity, Prop_Send, "m_iTeamNum") == GetClientTeam(iClient))
	continue;

	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin2);
	if(GetVectorDistance(fOrigin1, fOrigin2) < 800.0)
	{
	SetVariantInt(1);
	AcceptEntityInput(iEntity, "RemoveHealth");
	}
	}
	return Plugin_Continue;
}

public Action:Timer_ReEnableSentry(Handle:hTimer, any:iEntityId)
{
	new iEntity = EntRefToEntIndex(iEntityId);
	if(!IsValidEntityEx(iEntity))
	return Plugin_Continue;

	decl String:strClassname[64];
	GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
	if(!StrEqual(strClassname, "obj_sentrygun"))
	return Plugin_Continue;

	SetEntProp(iEntity, Prop_Send, "m_bDisabled", 0);

	new iEntity2 = -1;
	while((iEntity2 = FindEntityByClassname(iEntity2, "info_particle_system")) != -1)
	{
	if(GetEntPropEnt(iEntity2, Prop_Send, "m_hOwnerEntity") == iEntity)
	AcceptEntityInput(iEntity2, "Kill");
	}
	return Plugin_Continue;
}

public Action:Timer_ResetModel(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
	return Plugin_Continue;

	decl String:strModel[PLATFORM_MAX_PATH];
	GetClientModel(iClient, strModel, sizeof(strModel));
	if(StrEqual(strModel, MODEL_HALE))
	{
	SetVariantString("");
	AcceptEntityInput(iClient, "SetCustomModel");
	}
	return Plugin_Continue;
}

public Action:Timer_MakeHHHJunior(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient))
	return Plugin_Continue;

	MakePlayerHHHJunior(iClient);
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
	return false;
	return true;
}

stock bool:IsValidEntityEx(iEntity)
{
	if(iEntity <= MaxClients || !IsValidEntity(iEntity))
	return false;
	return true;
}

stock GetTeamHaleCount(iTeam)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
	if(g_bHHHJunior[i] && GetClientTeam(i) == iTeam)
	iCount++;
	}
	return iCount;
}

stock MakePlayerHHHJunior(iClient)
{
	g_bHHHJunior[iClient] = true;
 
	TF2_SetPlayerClass(iClient, TFClass_DemoMan, _, false);
	TF2_RemoveAllWeapons(iClient);

	if(g_bModel)
	{
	SetVariantString(MODEL_HALE);
	AcceptEntityInput(iClient, "SetCustomModel");
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1);
	}
 
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
	{
	if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
	AcceptEntityInput(iEntity, "Kill");
	}

	decl String:strAttributes[128];
	Format(strAttributes, sizeof(strAttributes), "2 ; 3.0 ; 109 ; -10000.0 ; 252 ; 0.6 ; 402 ; 1 ; 68 ; 2 ; 26 ; 9825 ; 275 ; 1 ; 442 ; 1.21", g_iHealth - 200, GetRandomInt(9999, 99999));
	TF2Items_GiveWeapon(iClient, "tf_weapon_sword", 266, 100, 5, strAttributes);

	SetEntProp(iClient, Prop_Data, "m_iHealth", g_iHealth);
	SetEntProp(iClient, Prop_Data, "m_iMaxHealth", g_iHealth);
}

stock TF2Items_GiveWeapon(iClient, String:strName[], iIndex, iLevel = 1, iQuality = 0, String:strAtt[] = "0")
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);

	TF2Items_SetClassname(hWeapon, strName);
	TF2Items_SetItemIndex(hWeapon, iIndex);
	TF2Items_SetLevel(hWeapon, iLevel);
	TF2Items_SetQuality(hWeapon, iQuality);

	new String:strAtts[32][32];
	new iCount = ExplodeString(strAtt, " ; ", strAtts, 32, 32);
	if(iCount > 0)
	{
	TF2Items_SetNumAttributes(hWeapon, iCount / 2);
	new z;
	for(new i = 0; i < iCount; i += 2)
	{
	TF2Items_SetAttribute(hWeapon, z, StringToInt(strAtts[i]), StringToFloat(strAtts[i + 1]));
	z++;
	}
	}
	else
	TF2Items_SetNumAttributes(hWeapon, 0);

	if(hWeapon == INVALID_HANDLE)
	return -1;

	new iEntity = TF2Items_GiveNamedItem(iClient, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(iClient, iEntity);
	SetEntProp(iEntity, Prop_Send, "m_iWorldModelIndex", -1);
	SetEntProp(iEntity, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
	SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 0.001);
	return iEntity;
}
stock GetRandomPlayer(team)
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && GetClientTeam(i) != team)
				clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
stock AttachParticle(iEntity, String:strEffect[], Float:fOffset = 0.0, bool:bAttach = true)
{
	new iParticle = CreateEntityByName("info_particle_system");

	decl Float:fOrigin[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);

	fOrigin[2] += fOffset;
	TeleportEntity(iParticle, fOrigin, NULL_VECTOR, NULL_VECTOR);

	decl String:strName[128];
	Format(strName, sizeof(strName), "target%i", iEntity);

	DispatchKeyValue(iEntity, "targetname", strName);
	DispatchKeyValue(iParticle, "targetname", "tf2particle");
	DispatchKeyValue(iParticle, "parentname", strName);
	DispatchKeyValue(iParticle, "effect_name", strEffect);
	DispatchSpawn(iParticle);
	SetVariantString(strName);

	if(bAttach)
	{
	AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
	SetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity", iEntity);
	}

	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "start");
	return iParticle;
}