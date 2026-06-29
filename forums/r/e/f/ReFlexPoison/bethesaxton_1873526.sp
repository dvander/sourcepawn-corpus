#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <tf2items>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION		"1.0"

#define SOUND_JUMP1			"saxton_hale/saxton_hale_responce_jump1.wav"
#define SOUND_JUMP2			"saxton_hale/saxton_hale_responce_jump2.wav"
#define SOUND_JUMP3			"saxton_hale/saxton_hale_132_jump_1.wav"
#define SOUND_JUMP4			"saxton_hale/saxton_hale_132_jump_2.wav"

#define SOUND_KILLSCOUT		"saxton_hale/saxton_hale_132_kill_scout.wav"
#define SOUND_KILLPYRO		"saxton_hale/saxton_hale_132_kill_w_and_m1.wav"
#define SOUND_KILLDEMO		"saxton_hale/saxton_hale_132_kill_demo.wav"
#define SOUND_KILLHEAVY		"saxton_hale/saxton_hale_132_kill_heavy.wav"
#define SOUND_KILLMEDIC		"saxton_hale/saxton_hale_responce_kill_medic.wav"
#define SOUND_KILLSNIPER1	"saxton_hale/saxton_hale_responce_kill_sniper1.wav"
#define SOUND_KILLSNIPER2	"saxton_hale/saxton_hale_responce_kill_sniper2.wav"
#define SOUND_KILLSPY1		"saxton_hale/saxton_hale_responce_kill_spy1.wav"
#define SOUND_KILLSPY2		"saxton_hale/saxton_hale_responce_kill_spy2.wav"
#define SOUND_KILLSPY3		"saxton_hale/saxton_hale_132_kill_spie.wav"
#define SOUND_KILLENGY1		"saxton_hale/saxton_hale_responce_kill_eggineer1.wav"
#define SOUND_KILLENGY2		"saxton_hale/saxton_hale_responce_kill_eggineer2.wav"
#define SOUND_KILLENGY3		"saxton_hale/saxton_hale_132_kill_engie_1.wav"
#define SOUND_KILLENGY4		"saxton_hale/saxton_hale_132_kill_engie_2.wav"
#define SOUND_KILLSENTRY	"saxton_hale/saxton_hale_132_kill_toy.wav"

#define SOUND_TAUNT1		"saxton_hale/saxton_hale_responce_rage1.wav"
#define SOUND_TAUNT2		"saxton_hale/saxton_hale_responce_rage2.wav"
#define SOUND_TAUNT3		"saxton_hale/saxton_hale_responce_rage3.wav"
#define SOUND_TAUNT4		"saxton_hale/saxton_hale_responce_rage4.wav"

#define MODEL_HALE			"models/player/saxton_hale/saxton_hale.mdl"

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
new g_iRage						[MAXPLAYERS + 1];
new TFClassType:g_iOldClass		[MAXPLAYERS + 1];
new bool:g_bSaxton				[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Be The Saxton",
	author = "ReFlexPoison",
	description = "Be Saxton Hale!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_bethesaxton_version", PLUGIN_VERSION, "Be The Saxton Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_bethesaxton_enabled", "1", "Enable Be The Saxton\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarHealth = CreateConVar("sm_bethesaxton_health", "10000", "Health Saxton Hale gets", _, true, 325.0);
	g_iHealth = GetConVarInt(g_hCvarHealth);
	HookConVarChange(g_hCvarHealth, OnConVarChange);

	g_hCvarModel = CreateConVar("sm_bethesaxton_model", "1", "Enable setting player model\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bModel = GetConVarBool(g_hCvarModel);
	HookConVarChange(g_hCvarModel, OnConVarChange);

	g_hCvarSuperJumps = CreateConVar("sm_bethesaxton_superjumps", "1", "Enable super jumps\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bSuperJumps = GetConVarBool(g_hCvarSuperJumps);
	HookConVarChange(g_hCvarSuperJumps, OnConVarChange);

	g_hCvarRaging = CreateConVar("sm_bethesaxton_raging", "2", "Rage percent regeneration\n0 = Disabled", _, true, 0.0);
	g_iRaging = GetConVarInt(g_hCvarRaging);
	HookConVarChange(g_hCvarRaging, OnConVarChange);

	g_hCvarSounds = CreateConVar("sm_bethesaxton_sounds", "1", "Enable saxton sounds\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bSounds = GetConVarBool(g_hCvarSounds);
	HookConVarChange(g_hCvarSounds, OnConVarChange);

	g_hCvarRedLimit = CreateConVar("sm_bethesaxton_redlimit", "-1", "Max red players allowed to be saxton\n-1 = Disabled", _, true, -1.0);
	g_iRedLimit = GetConVarInt(g_hCvarRedLimit);
	HookConVarChange(g_hCvarRedLimit, OnConVarChange);

	g_hCvarBluLimit = CreateConVar("sm_bethesaxton_blulimit", "-1", "Max blu players allowed to be saxton\n-1 = Disabled", _, true, -1.0);
	g_iBluLimit = GetConVarInt(g_hCvarBluLimit);
	HookConVarChange(g_hCvarBluLimit, OnConVarChange);

	g_hCvarRespawn = CreateConVar("sm_bethesaxton_respawn", "1", "Enable respawning as hale\n0 = Disabled\n1 = Enabled", _, true, -1.0);
	g_bRespawn = GetConVarBool(g_hCvarRespawn);
	HookConVarChange(g_hCvarRespawn, OnConVarChange);

	g_hCvarHintSound = FindConVar("sv_hudhint_sound");
	HookConVarChange(g_hCvarHintSound, OnConVarChange);

	AutoExecConfig(true, "plugin.bethesaxton");

	RegAdminCmd("sm_saxton", BeTheSaxtonCmd, ADMFLAG_GENERIC, "Be The Saxton");
	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("post_inventory_application", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);

	AddNormalSoundHook(SoundHook);

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("bethesaxton.phrases");

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
	g_iRage[iClient] = 0;
	g_bSaxton[iClient] = false;
	g_iOldClass[iClient] = TFClass_Unknown;
}

public OnMapStart()
{
	PrecacheSound(SOUND_JUMP1, true);
	PrecacheSound(SOUND_JUMP2, true);
	PrecacheSound(SOUND_JUMP3, true);
	PrecacheSound(SOUND_JUMP4, true);

	PrecacheSound(SOUND_KILLSCOUT, true);
	PrecacheSound(SOUND_KILLPYRO, true);
	PrecacheSound(SOUND_KILLDEMO, true);
	PrecacheSound(SOUND_KILLHEAVY, true);
	PrecacheSound(SOUND_KILLMEDIC, true);
	PrecacheSound(SOUND_KILLSNIPER1, true);
	PrecacheSound(SOUND_KILLSNIPER2, true);
	PrecacheSound(SOUND_KILLSPY1, true);
	PrecacheSound(SOUND_KILLSPY2, true);
	PrecacheSound(SOUND_KILLSPY3, true);
	PrecacheSound(SOUND_KILLENGY1, true);
	PrecacheSound(SOUND_KILLENGY2, true);
	PrecacheSound(SOUND_KILLENGY3, true);
	PrecacheSound(SOUND_KILLENGY4, true);
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
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_JUMP3);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_JUMP4);
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
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSNIPER2);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSPY1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSPY2);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLSPY3);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLENGY1);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLENGY2);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLENGY3);
	AddFileToDownloadsTable(strPath);
	Format(strPath, sizeof(strPath), "sound/%s", SOUND_KILLENGY4);
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
	AddFileToDownloadsTable("models/player/saxton_hale/saxton_hale.dx80.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/saxton_hale.dx90.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/saxton_hale.sw.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/saxton_hale.vvd");

	AddFileToDownloadsTable("materials/models/player/saxton_hale/eye.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eye.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_r.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_body.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_body.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_head.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_head.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_misc.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_misc.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_misc_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head_red.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_lens.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_lens.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_red.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_red.vtf");

	SetConVarBool(g_hCvarHintSound, false);
}

public Action:OnPlayerSpawn(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	if(!g_bSaxton[iClient] || !g_bEnabled || !g_bModel || !g_bRespawn)
	{
		CreateTimer(0.5, Timer_ResetModel, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		if(!g_bRespawn)
			g_bSaxton[iClient] = false;
	}
	else
		CreateTimer(0.5, Timer_MakeSaxton, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
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
	if(!IsValidClient(iAttacker) || !IsPlayerAlive(iAttacker) || !g_bSaxton[iAttacker])
		return Plugin_Continue;

	new iCustom = GetEventInt(hEvent, "customkill");
	if(iCustom != TF_CUSTOM_BOOTS_STOMP)
		SetEventString(hEvent, "weapon", "fists");

	if(!g_bSounds)
		return Plugin_Continue;

	if(GetRandomInt(0, 2) == 1)
	{
		new TFClassType:iClass = TF2_GetPlayerClass(iVictim);
		switch(iClass)
		{
			case TFClass_Scout: EmitSoundToAll(SOUND_KILLSCOUT, iAttacker, SNDCHAN_VOICE);
			case TFClass_Pyro: EmitSoundToAll(SOUND_KILLPYRO, iAttacker, SNDCHAN_VOICE);
			case TFClass_DemoMan: EmitSoundToAll(SOUND_KILLDEMO, iAttacker, SNDCHAN_VOICE);
			case TFClass_Heavy: EmitSoundToAll(SOUND_KILLHEAVY, iAttacker, SNDCHAN_VOICE);
			case TFClass_Medic: EmitSoundToAll(SOUND_KILLMEDIC, iAttacker, SNDCHAN_VOICE);
			case TFClass_Sniper:
			{
				switch(GetRandomInt(0, 1))
				{
					case 0: EmitSoundToAll(SOUND_KILLSNIPER1, iAttacker, SNDCHAN_VOICE);
					case 1: EmitSoundToAll(SOUND_KILLSNIPER2, iAttacker, SNDCHAN_VOICE);
				}
			}
			case TFClass_Spy:
			{
				switch(GetRandomInt(0, 2))
				{
					case 0: EmitSoundToAll(SOUND_KILLSPY1, iAttacker, SNDCHAN_VOICE);
					case 1: EmitSoundToAll(SOUND_KILLSPY2, iAttacker, SNDCHAN_VOICE);
					case 2: EmitSoundToAll(SOUND_KILLSPY3, iAttacker, SNDCHAN_VOICE);
				}
			}
			case TFClass_Engineer:
			{
				switch(GetRandomInt(0, 4))
				{
					case 0: EmitSoundToAll(SOUND_KILLENGY1, iAttacker, SNDCHAN_VOICE);
					case 1: EmitSoundToAll(SOUND_KILLENGY2, iAttacker, SNDCHAN_VOICE);
					case 2: EmitSoundToAll(SOUND_KILLENGY3, iAttacker, SNDCHAN_VOICE);
					case 3: EmitSoundToAll(SOUND_KILLENGY4, iAttacker, SNDCHAN_VOICE);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnObjectDestroyed(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iAttacker) || !IsPlayerAlive(iAttacker) || !g_bSaxton[iAttacker])
		return Plugin_Continue;

	new iCustom = GetEventInt(hEvent, "customkill");
	if(iCustom != TF_CUSTOM_BOOTS_STOMP)
		SetEventString(hEvent, "weapon", "fists");

	if(g_bSounds)
	{
		if(GetRandomInt(0, 4) == 2)
			EmitSoundToAll(SOUND_KILLSENTRY, iAttacker, SNDCHAN_VOICE);
	}
	return Plugin_Continue;
}

public Action:SoundHook(iClients[64], &iClientCount, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:fVolume, &iLevel, &iPitch, &iFlags)
{
	if(!g_bSounds || !IsValidClient(iEntity))
		return Plugin_Continue;

	if(g_bSaxton[iEntity] && StrContains(strSample, "saxton_hale", false) == -1)
		return Plugin_Stop;
	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:BeTheSaxtonCmd(iClient, iArgs)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	if(iArgs != 0 && iArgs != 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_saxton <target> <0/1>");
		return Plugin_Handled;
	}

	if(iArgs == 0)
	{
		if(g_bSaxton[iClient])
		{
			SetGlobalTransTarget(iClient);
			PrintToChat(iClient, "[SM] %t", "saxton_disabled");
			g_bSaxton[iClient] = false;
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
			PrintToChat(iClient, "[SM] %t", "saxton_enabled");
			g_iOldClass[iClient] = TF2_GetPlayerClass(iClient);
			g_bSaxton[iClient] = true;

			if(IsPlayerAlive(iClient))
				MakePlayerSaxton(iClient);
		}
	}
	else if(iArgs == 2)
	{
		if(!CheckCommandAccess(iClient, "sm_saxton_target", ADMFLAG_GENERIC))
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
			ReplyToCommand(iClient, "[SM] Usage: sm_saxton <target> <0/1>");
			return Plugin_Handled;
		}

		if(iValue == 0 && g_bSaxton[iTarget])
		{
			SetGlobalTransTarget(iTarget);
			PrintToChat(iTarget, "[SM] %t", "saxton_disabled");
			g_bSaxton[iTarget] = false;
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
		else if(iValue == 1 && !g_bSaxton[iTarget])
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
			PrintToChat(iTarget, "[SM] %t", "saxton_enabled");
			g_iOldClass[iTarget] = TF2_GetPlayerClass(iTarget);

			if(IsPlayerAlive(iTarget))
				MakePlayerSaxton(iTarget);
		}
	}
	return Plugin_Handled;
}

public Action:TauntCmd(iClient, const String:strCommand[], iArgc)
{
	if(!g_bEnabled || g_iRaging <= 0)
		return Plugin_Continue;

	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient) || !g_bSaxton[iClient] || g_iRage[iClient] < 100)
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
	g_iRage[iClient] = 0;
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
		if(!IsPlayerAlive(i) || !g_bSaxton[i])
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

			if(fAngles[0] < -45.0 && iJumpCharge[i] > 1)
			{
				decl Float:fVelocity[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", fVelocity);

				SetEntProp(i, Prop_Send, "m_bJumping", 1);

				fVelocity[2] = 750 + iJumpCharge[i] * 13.0;
				fVelocity[0] *= (1 + Sine(float(iJumpCharge[i]) * FLOAT_PI / 50));
				fVelocity[1] *= (1 + Sine(float(iJumpCharge[i]) * FLOAT_PI / 50));
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, fVelocity);

				iJumpCharge[i] = -120;

				decl Float:fPosition[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPosition);

				if(g_bSounds)
				{
					new iRandom = GetRandomInt(0, 3);
					switch(iRandom)
					{
						case 0: EmitSoundToAll(SOUND_JUMP1, i, SNDCHAN_VOICE);
						case 1: EmitSoundToAll(SOUND_JUMP2, i, SNDCHAN_VOICE);
						case 2: EmitSoundToAll(SOUND_JUMP3, i, SNDCHAN_VOICE);
						case 3: EmitSoundToAll(SOUND_JUMP4, i, SNDCHAN_VOICE);
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
		if(g_bSaxton[i])
		{
			SetGlobalTransTarget(i);
			if(g_iRage[i] + g_iRaging <= 100 - g_iRaging)
			{
				g_iRage[i] += g_iRaging;
				PrintHintText(i, "%t %", "rage_status", g_iRage[i]);
			}
			else
			{
				g_iRage[i] = 100;
				PrintHintText(i, "%t", "rage_full");
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

public Action:Timer_MakeSaxton(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Continue;

	MakePlayerSaxton(iClient);
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
		if(g_bSaxton[i] && GetClientTeam(i) == iTeam)
			iCount++;
	}
	return iCount;
}

stock MakePlayerSaxton(iClient)
{
	g_bSaxton[iClient] = true;

	TF2_SetPlayerClass(iClient, TFClass_Soldier, _, false);
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
	Format(strAttributes, sizeof(strAttributes), "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 252 ; 0.6 ; 275 ; 1 ; 26 ; %i ; 107 ; 1.7 ; 214 ; %d", g_iHealth - 200, GetRandomInt(9999, 99999));
	TF2Items_GiveWeapon(iClient, "tf_weapon_shovel", 5, 100, 4, strAttributes);

	SetEntProp(iClient, Prop_Data, "m_iHealth", g_iHealth);
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
	return iEntity;
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