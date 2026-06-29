#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION			"1.6"
#define SOLIDFLAGS				((1 << 1) | (1 << 2))
#define MODEL_GHOST				"models/props_halloween/ghost.mdl"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;
new Handle:g_hCvarTelyMode;
new Handle:g_hCvarFlyMode;
new Handle:g_hCookieGhost;
new Handle:g_hCookieThirdPerson;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;
new g_iTelyMode;
new g_iDeathState				[MAXPLAYERS + 1];
new bool:g_bFlyMode;
new bool:g_bArena;
new bool:g_bRoundStarted;
new bool:g_bInformed			[MAXPLAYERS + 1];
new bool:g_bGhost				[MAXPLAYERS + 1];
new bool:g_bThirdPerson			[MAXPLAYERS + 1];
new Float:g_fLocVec				[MAXPLAYERS + 1][3];
new Float:g_fLocAng				[MAXPLAYERS + 1][3];
new Float:g_fLocVel				[MAXPLAYERS + 1][3];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Ghost Mode",
	author = "ReFlexPoison",
	description = "Fly around as a ghost after death",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_ghostymode_version", PLUGIN_VERSION, "Ghost Mode Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_ghostmode_enabled", "1", "Enable Ghost Mode\n0 = Disabled\n1 = Enabled\n2 = Enabled (Arena Only)", _, true, 0.0, true, 2.0);
	g_iEnabled = GetConVarInt(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, CVarChange);

	g_hCvarTelyMode = CreateConVar("sm_ghostmode_telymode", "1", "Enable Tely-Mode (Main-Fire)\n0 = Disabled\n1 = Random target\n2 = Random team target", _, true, 0.0, true, 2.0);
	g_iTelyMode = GetConVarInt(g_hCvarTelyMode);
	HookConVarChange(g_hCvarTelyMode, CVarChange);

	g_hCvarFlyMode = CreateConVar("sm_ghostmode_flymode", "1", "Enable Fly-Mode (Alt-Fire)\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bFlyMode = GetConVarBool(g_hCvarFlyMode);
	HookConVarChange(g_hCvarFlyMode, CVarChange);

	AutoExecConfig(true, "plugin.ghostmode");

	RegAdminCmd("sm_ghost", GhostModeCmd, 0, "Ghost Mode");

	AddCommandListener(TauntCmd, "+use_action_slot_item_server");
	AddCommandListener(TauntCmd, "use_action_slot_item_server");
	AddCommandListener(TauntCmd, "+taunt");
	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(JoinclassCmd, "joinclass");
	AddCommandListener(JoinclassCmd, "join_class");

	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_round_start", OnRoundActive);
	HookEvent("teamplay_round_active", OnRoundActive);
	HookEvent("arena_round_start", OnRoundActive);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_changeclass", OnPlayerChangeClass);

	g_hCookieGhost = RegClientCookie("ghostmode_set", "Is ghostmode on?", CookieAccess_Private);
	g_hCookieThirdPerson = RegClientCookie("ghostmode_thirdperson", "Is thirdperson on?", CookieAccess_Private);

	AddNormalSoundHook(SoundHook);

	LoadTranslations("core.phrases");
	LoadTranslations("ghostmode.phrases");

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		SDKHook(i, SDKHook_SetTransmit, SetTransmit);
		SDKHook(i, SDKHook_WeaponCanSwitchTo, OnWeaponSwitch);
	}
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_iEnabled = GetConVarInt(g_hCvarEnabled);
	if(hConvar == g_hCvarTelyMode)
		g_iTelyMode = GetConVarInt(g_hCvarTelyMode);
	if(hConvar == g_hCvarFlyMode)
		g_bFlyMode = GetConVarBool(g_hCvarFlyMode);
}

// ====[ COMMANDS ]============================================================
public Action:GhostModeCmd(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	GhostModeMenu(iClient);
	return Plugin_Handled;
}

public Action:JoinclassCmd(iClient, const String:strCommand[], iArgs)
{
	if(iArgs < 1 || g_iDeathState[iClient] != 2)
		return Plugin_Continue;

	decl String:strCmd[32];
	GetCmdArg(1, strCmd, sizeof(strCmd));
	if(strncmp(strCmd, "heavy", 5, false) == 0)
		strcopy(strCmd, sizeof(strCmd), "heavy");

	new TFClassType:iClass = TF2_GetClass(strCmd);
	if(iClass != TFClass_Unknown)
		SetEntProp(iClient, Prop_Send, "m_iDesiredPlayerClass", iClass);
	return Plugin_Handled;
}

public Action:TauntCmd(iClient, const String:strCommand[], iArgs)
{
	if(g_iDeathState[iClient] == 2)
		return Plugin_Handled;
	return Plugin_Continue;
}

// ====[ MENUS ]===============================================================
public GhostModeMenu(iClient)
{
	if(!IsValidClient(iClient) || IsVoteInProgress())
		return;

	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Ghostmode Preferences");
	DrawPanelText(hPanel, " ");

	SetGlobalTransTarget(iClient);
	decl String:strInfo[128];
	if(g_bGhost[iClient])
	{
		Format(strInfo, sizeof(strInfo), "%t", "ghoston");
		DrawPanelText(hPanel, strInfo);
		Format(strInfo, sizeof(strInfo), "%t", "ghostdisable");
		DrawPanelItem(hPanel, strInfo);
	}
	else
	{
		Format(strInfo, sizeof(strInfo), "%t", "ghostoff");
		DrawPanelText(hPanel, strInfo);
		Format(strInfo, sizeof(strInfo), "%t", "ghostenable");
		DrawPanelItem(hPanel, strInfo);
	}
	DrawPanelText(hPanel, " ");
	if(g_bThirdPerson[iClient])
	{
		Format(strInfo, sizeof(strInfo), "%t", "thirdpersonon");
		DrawPanelText(hPanel, strInfo);
		Format(strInfo, sizeof(strInfo), "%t", "thirdpersondisable");
		DrawPanelItem(hPanel, strInfo);
	}
	else
	{
		Format(strInfo, sizeof(strInfo), "%t", "thirdpersonoff");
		DrawPanelText(hPanel, strInfo);
		Format(strInfo, sizeof(strInfo), "%t", "thirdpersonenable");
		DrawPanelItem(hPanel, strInfo);
	}
	DrawPanelText(hPanel, " ");
	Format(strInfo, sizeof(strInfo), "%t", "Exit");
	DrawPanelItem(hPanel, strInfo);

	SendPanelToClient(hPanel, iClient, GhostModeMenuHandle, 30);
	CloseHandle(hPanel);
}

public GhostModeMenuHandle(Handle:hPanel, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_Select)
	{
		if(iParam2 == 1)
		{
			if(g_bGhost[iParam1])
			{
				SetClientCookie(iParam1, g_hCookieGhost, "0");
				g_bGhost[iParam1] = false;
			}
			else
			{
				SetClientCookie(iParam1, g_hCookieGhost, "1");
				g_bGhost[iParam1] = true;
			}
			GhostModeMenu(iParam1);
		}
		if(iParam2 == 2)
		{
			if(g_bThirdPerson[iParam1])
			{
				g_bThirdPerson[iParam1] = false;
				SetClientCookie(iParam1, g_hCookieThirdPerson, "0");
				if(g_iDeathState[iParam1] == 2)
				{
					SetVariantInt(0);
					AcceptEntityInput(iParam1, "SetForcedTauntCam");
				}
			}
			else
			{
				g_bThirdPerson[iParam1] = true;
				SetClientCookie(iParam1, g_hCookieThirdPerson, "1");
				if(g_iDeathState[iParam1] == 2)
				{
					SetVariantInt(2);
					AcceptEntityInput(iParam1, "SetForcedTauntCam");
				}
			}
			GhostModeMenu(iParam1);
		}
	}
}

// ====[ EVENTS ]==============================================================
public OnMapStart()
{
	PrecacheModel(MODEL_GHOST, true);
	g_bArena = false;
	if(FindEntityByClassname(-1, "tf_logic_arena") != -1)
		g_bArena = true;
}

public OnClientConnected(iClient)
{
	g_bGhost[iClient] = true;
	g_bThirdPerson[iClient] = true;
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_SetTransmit, SetTransmit);
	SDKHook(iClient, SDKHook_WeaponCanSwitchTo, OnWeaponSwitch);
}

public OnClientCookiesCached(iClient)
{
	decl String:strCookie[16];
	GetClientCookie(iClient, g_hCookieGhost, strCookie, sizeof(strCookie));
	if(StrEqual(strCookie, "0"))
		g_bGhost[iClient] = false;
	GetClientCookie(iClient, g_hCookieThirdPerson, strCookie, sizeof(strCookie));
	if(StrEqual(strCookie, "0"))
		g_bThirdPerson[iClient] = false;
}

public Action:OnRoundActive(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	g_bRoundStarted = true;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(IsPlayerAlive(i) && GetClientTeam(i) > 1)
			g_iDeathState[i] = 0;
	}
}

public Action:OnRoundEnd(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	g_bRoundStarted = false;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(IsPlayerAlive(i) && GetClientTeam(i) > 1)
		{
			if(g_iDeathState[i] == 2)
				SetEntityMoveType(i, MOVETYPE_WALK);
			g_iDeathState[i] = 0;
		}
	}
}

public Action:OnPlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	new RoundState:iRoundState = GameRules_GetRoundState();
	if((iRoundState != RoundState_RoundRunning && iRoundState != RoundState_Stalemate) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) <= 1 || g_iDeathState[iClient] != 1 || !CheckCommandAccess(iClient, "sm_ghost", 0, true) || !g_bGhost[iClient])
	{
		if(IsPlayerAlive(iClient))
		{
			if(GetEntProp(iClient, Prop_Send, "m_CollisionGroup") == 1)
				SetEntProp(iClient, Prop_Send, "m_CollisionGroup", 5);
			SetEntProp(iClient, Prop_Send, "m_usSolidFlags", (GetEntProp(iClient, Prop_Send, "m_usSolidFlags") & ~SOLIDFLAGS));
		}
		g_iDeathState[iClient] = 0;

		decl String:strModel[128];
		GetClientModel(iClient, strModel, sizeof(strModel));
		if(StrEqual(strModel, MODEL_GHOST))
		{
			SetVariantString("");
			AcceptEntityInput(iClient, "SetCustomModel");
		}
		SetVariantInt(0);
		AcceptEntityInput(iClient, "SetForcedTauntCam");
		CreateTimer(0.2, Timer_StopParticles, iClient, TIMER_FLAG_NO_MAPCHANGE);

		for(new i = 0; i <= 5 ; i++)
		{
			new iWeapon = GetPlayerWeaponSlot(iClient, i);
			if(IsValidEntityEx(iWeapon))
			{
				SetEntityRenderMode(iWeapon, RENDER_NORMAL);
				SetEntityRenderColor(iWeapon, _, _, _, 255);
			}
		}

		new iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
		{
			if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				SetEntityRenderMode(iEntity, RENDER_NORMAL);
		}
		iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
		{
			if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				SetEntityRenderMode(iEntity, RENDER_NORMAL);
		}
		iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_robot_arm")) != -1)
		{
			if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				SetEntityRenderMode(iEntity, RENDER_NORMAL);
		}
		iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) != -1)
		{
			if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				SetEntityRenderMode(iEntity, RENDER_NORMAL);
		}
		return Plugin_Continue;
	}

	for(new i = 0; i <= 5 ; i++)
	{
		new iWeapon = GetPlayerWeaponSlot(iClient, i);
		if(IsValidEntityEx(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSALPHA);
			SetEntityRenderColor(iWeapon, _, _, _, 0);
			if(iWeapon == GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee))
				SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		}
	}

	TeleportEntity(iClient, g_fLocVec[iClient], g_fLocAng[iClient], g_fLocVel[iClient]);
	SetEntProp(iClient, Prop_Send, "m_CollisionGroup", 1);
	SetEntProp(iClient, Prop_Send, "m_bGlowEnabled", 0);
	SetEntProp(iClient, Prop_Send, "m_usSolidFlags", (GetEntProp(iClient, Prop_Send, "m_usSolidFlags") | SOLIDFLAGS));
	SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 0);
	SetVariantInt(1);
	AcceptEntityInput(iClient, "SetCustomModelRotates");
	SetEntProp(iClient, Prop_Send, "m_iHideHUD", GetEntProp(iClient, Prop_Send, "m_iHideHUD") | (1 << 3));
	g_iDeathState[iClient] = 2;

	CreateTimer(0.5, Timer_ThirdPerson, iClient, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_SetModel, iClient, TIMER_FLAG_NO_MAPCHANGE);

	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
	{
		if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
		{
			SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
			SetEntityRenderColor(iEntity, 255, 255, 255, 0);
		}
	}
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
	{
		if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
		{
			SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
			SetEntityRenderColor(iEntity, 255, 255, 255, 0);
		}
	}
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_robot_arm")) != -1)
	{
		if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
		{
			SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
			SetEntityRenderColor(iEntity, 255, 255, 255, 0);
		}
	}
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) != -1)
	{
		if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
		{
			SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
			SetEntityRenderColor(iEntity, 255, 255, 255, 0);
		}
	}
	return Plugin_Handled;
}

public Action:OnPlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	if(!CheckForEnable())
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || IsFakeClient(iClient) || !CheckCommandAccess(iClient, "sm_ghost", 0, true) || !g_bGhost[iClient])
		return Plugin_Continue;

	new RoundState:iRoundState = GameRules_GetRoundState();
	if(iRoundState != RoundState_RoundRunning && iRoundState != RoundState_Stalemate)
		return Plugin_Continue;

	if(TF2_GetPlayerDesiredClass(iClient) == TFClass_Unknown)
		return Plugin_Continue;

	new iFlags = GetEventInt(hEvent, "death_flags");
	if(iFlags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;

	g_iDeathState[iClient] = 1;
	GetClientAbsOrigin(iClient, g_fLocVec[iClient]);
	GetClientAbsAngles(iClient, g_fLocAng[iClient]);
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", g_fLocVel[iClient]);
	CreateTimer(0.1, Timer_Respawn, iClient);

	if(!g_bInformed[iClient])
	{
		PrintToChat(iClient, "%t", "ghostinfo");
		g_bInformed[iClient] = true;
	}

	return Plugin_Continue;
}

public Action:OnPlayerChangeClass(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Continue;

	g_iDeathState[iClient] = 0;
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	static iLastButtons[MAXPLAYERS + 1];
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	new iLastButton = iLastButtons[iClient];
	iLastButtons[iClient] = iButtons;
	if(GetClientTeam(iClient) == 1 && GetEntityMoveType(iClient) != MOVETYPE_OBSERVER)
		TF2_RespawnPlayer(iClient);

	if(IsPlayerAlive(iClient) || g_iDeathState[iClient] != 2)
		return Plugin_Continue;

	if(iButtons & IN_ATTACK)
	{
		if(!(iLastButton & IN_ATTACK) && g_iTelyMode > 0)
			TeleportToPlayer(iClient);
		iButtons &= ~IN_ATTACK;
	}
	new MoveType:iMoveType = GetEntityMoveType(iClient);
	if(iButtons & IN_ATTACK2)
	{
		if(g_bFlyMode)
		{
			if(iMoveType != MOVETYPE_FLY)
				SetEntityMoveType(iClient, MOVETYPE_FLY);
		}
		iButtons &= ~IN_ATTACK2;
	}
	else
		SetEntityMoveType(iClient, MOVETYPE_WALK);
	return Plugin_Changed;
}

public Action:SetTransmit(iEntity, iClient)
{
	if(g_iDeathState[iEntity] > 0 && g_iDeathState[iClient] == 0 && GetClientTeam(iClient) > 1 && g_bRoundStarted)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:OnWeaponSwitch(iClient, iWeapon)
{
	if(g_iDeathState[iClient] > 0 && GetClientTeam(iClient) > 1 && g_bRoundStarted && iWeapon != GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:SoundHook(iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags)
{
	if(IsValidClient(iEntity) && g_iDeathState[iEntity] == 2)
	{
		if(StrContains(strSample, "footsteps", false) != -1 || StrContains(strSample, "weapons", false) != -1)
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Respawn(Handle:hTimer, any:iClient)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	new RoundState:iRoundState = GameRules_GetRoundState();
	if(iRoundState != RoundState_RoundRunning && iRoundState != RoundState_Stalemate)
	{
		g_iDeathState[iClient] = 0;
		return Plugin_Continue;
	}
	if(TF2_GetPlayerDesiredClass(iClient) != TFClass_Unknown)
		TF2_RespawnPlayer(iClient);
	return Plugin_Continue;
}

public Action:Timer_ThirdPerson(Handle:hTimer, any:iClient)
{
	if(!IsValidClient(iClient) || IsPlayerAlive(iClient))
		return Plugin_Continue;

	if(g_bThirdPerson[iClient])
	{
		SetVariantInt(2);
		AcceptEntityInput(iClient, "SetForcedTauntCam");
	}
	return Plugin_Continue;
}

public Action:Timer_StopParticles(Handle:hTimer, any:iClient)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(iClient, "DispatchEffect");
	return Plugin_Continue;
}

public Action:Timer_SetModel(Handle:hTimer, any:iClient)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	SetVariantString(MODEL_GHOST);
	AcceptEntityInput(iClient, "SetCustomModel");
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
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

stock bool:CheckForEnable()
{
	if(g_iEnabled == 1)
		return true;
	else if(g_iEnabled == 2 && g_bArena)
		return true;
	return false;
}

stock TFClassType:TF2_GetPlayerDesiredClass(iClient)
{
	return TFClassType:GetEntProp(iClient, Prop_Send, "m_iDesiredPlayerClass");
}

stock TeleportToPlayer(iClient)
{
	new iTarget;
	new iCount;
	new iPlayers[MAXPLAYERS + 1];
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(IsPlayerAlive(i) && i != iClient)
		{
			if(g_iTelyMode == 2 && GetClientTeam(i) != GetClientTeam(iClient))
				continue;

			if(GetEntProp(i, Prop_Send, "m_bDucked") || GetEntProp(i, Prop_Send, "m_bDucking"))
				continue;

			iPlayers[iCount] = i;
			iCount++;
		}
	}

	if(iCount <= 0)
		return;

	iTarget = iPlayers[GetRandomInt(0, iCount - 1)];
	if(!IsValidClient(iTarget))
		return;

	decl Float:fPosition[3], Float:fAngle[3];
	GetClientAbsOrigin(iTarget, fPosition);
	GetClientAbsAngles(iTarget, fAngle);
	TeleportEntity(iClient, fPosition, fAngle, NULL_VECTOR);
}