#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Ghost Mode"
#define PLUGIN_VERSION "2.2a"
#define DEFAULT_HUD 0
#define DEFAULT_COLLISION 5
#define DEFAULT_SOLID 16
#define GHOST_HUD 8
#define GHOST_COLLISION 1
#define GHOST_SOLID 22

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled, g_iCvarEnabled;
new Handle:g_hCvarTeleporting, g_iCvarTeleporting;
new Handle:g_hCvarFlying, bool:g_bCvarFlying;
new Handle:g_hCvarModel, String:g_strCvarModel[255];
new Handle:g_hCvarWearables, bool:g_bCvarWearables;
new Handle:g_hCookieGhost;
new Handle:g_hCookieThirdPerson;

// ====[ VARIABLES ]===========================================================
new bool:g_bArena;
new bool:g_bRoundStarted;
new bool:g_bIsGhost[MAXPLAYERS + 1];
new bool:g_bBecomingGhost[MAXPLAYERS + 1];
new bool:g_bInformed[MAXPLAYERS + 1];
new bool:g_bGhost[MAXPLAYERS + 1];
new bool:g_bThirdPerson[MAXPLAYERS + 1];
new Float:g_flOrigin[MAXPLAYERS + 1][3];
new Float:g_flAngles[MAXPLAYERS + 1][3];
new Float:g_flVelocity[MAXPLAYERS + 1][3];

// ====[ PLUGIN ]==============================================================
public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:strError[], iErrorSize)
{
	CreateNative("GhostMode_IsPlayerGhost", Native_IsPlayerGhost);
	RegPluginLibrary("ghostmode");
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "Ghost Mode",
	author = "ReFlexPoison",
	description = "Fly around as a ghost after death",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

// ====[ NATIVES ]=============================================================
public Native_IsPlayerGhost(Handle:hPlugin, iParams)
{
	new iClient = GetNativeCell(1);
	if(IsValidClient(iClient) && g_bIsGhost[iClient])
	return true;
	return false;
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_ghostymode_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_ghostmode_enabled", "1", "Enable Ghost Mode\n0 = Disabled\n1 = Enabled\n2 = Enabled (Arena Only)", _, true, 0.0, true, 2.0);
	g_iCvarEnabled = GetConVarInt(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarTeleporting = CreateConVar("sm_ghostmode_teleporting", "2", "Enable teleporting\n0 = Disabled\n1 = Random target\n2 = Random team target", _, true, 0.0, true, 2.0);
	g_iCvarTeleporting = GetConVarInt(g_hCvarTeleporting);
	HookConVarChange(g_hCvarTeleporting, OnConVarChange);

	g_hCvarFlying = CreateConVar("sm_ghostmode_flying", "1", "Enable flying\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarFlying = GetConVarBool(g_hCvarFlying);
	HookConVarChange(g_hCvarFlying, OnConVarChange);

	g_hCvarModel = CreateConVar("sm_ghostmode_model", "models/props_halloween/ghost.mdl", "Model to use for ghosts");
	GetConVarString(g_hCvarModel, g_strCvarModel, sizeof(g_strCvarModel));
	HookConVarChange(g_hCvarModel, OnConVarChange);

	g_hCvarWearables = CreateConVar("sm_ghostmode_wearables", "0", "Enable wearables on ghosts\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarWearables = GetConVarBool(g_hCvarWearables);
	HookConVarChange(g_hCvarWearables, OnConVarChange);

	AutoExecConfig(true, "plugin.ghostmode");

	RegConsoleCmd("sm_ghost", Command_Ghost, "Ghost Mode");

	AddCommandListener(Command_Taunt, "+use_action_slot_item_server");
	AddCommandListener(Command_Taunt, "use_action_slot_item_server");
	AddCommandListener(Command_Taunt, "+taunt");
	AddCommandListener(Command_Taunt, "taunt");
	AddCommandListener(Command_Jointeam, "spectate");
	AddCommandListener(Command_Jointeam, "jointeam");
	AddCommandListener(Command_Joinclass, "joinclass");
	AddCommandListener(Command_Joinclass, "join_class");

	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_ArenaStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changeclass", Event_PlayerChangeClass);

	g_hCookieGhost = RegClientCookie("ghostmode_set", "Is ghostmode on?", CookieAccess_Private);
	g_hCookieThirdPerson = RegClientCookie("thirdperson", "Is thirdperson on?", CookieAccess_Private);

	AddNormalSoundHook(SoundHook);

	LoadTranslations("core.phrases");
	LoadTranslations("ghostmode.phrases");

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		OnClientPutInServer(i);
		if(AreClientCookiesCached(i))
		OnClientCookiesCached(i);
	}
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
	g_iCvarEnabled = GetConVarInt(g_hCvarEnabled);
	else if(hConvar == g_hCvarTeleporting)
	g_iCvarTeleporting = GetConVarInt(g_hCvarTeleporting);
	else if(hConvar == g_hCvarFlying)
	g_bCvarFlying = GetConVarBool(g_hCvarFlying);
	else if(hConvar == g_hCvarModel)
	{
		GetConVarString(g_hCvarModel, g_strCvarModel, sizeof(g_strCvarModel));

		if(FileExists(g_strCvarModel, true))
		{
			PrecacheModel(g_strCvarModel, true);
			return;
		}

		LogError("Model (%s) does not exist!", g_strCvarModel);
		strcopy(g_strCvarModel, sizeof(g_strCvarModel), "models/props_halloween/ghost.mdl");
		SetConVarString(g_hCvarModel, g_strCvarModel);
	}
	else if(hConvar == g_hCvarWearables)
	g_bCvarWearables = GetConVarBool(g_hCvarWearables);
}

public OnConfigsExecuted()
{
	g_bRoundStarted = false;

	g_bArena = false;
	if(FindEntityByClassname(-1, "tf_logic_arena") != -1)
	g_bArena = true;

	PrecacheModel("models/props_halloween/ghost.mdl", true);
	if(FileExists(g_strCvarModel, true))
	{
		PrecacheModel(g_strCvarModel, true);
		return;
	}

	LogError("Model (%s) does not exist!", g_strCvarModel);
	strcopy(g_strCvarModel, sizeof(g_strCvarModel), "models/props_halloween/ghost.mdl");
	SetConVarString(g_hCvarModel, g_strCvarModel);
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_SetTransmit, SetTransmit);
	SDKHook(iClient, SDKHook_PreThink, PreThink);
}

public OnClientCookiesCached(iClient)
{
	/*
	decl String:strCookies[3];
	GetClientCookie(iClient, g_hCookieGhost, strCookieGhost, sizeof(strCookieGhost));
	if(StrEqual(strCookieGhost, "0"))
	(StrEqual(strCookies, "0") ? (g_bGhost[iClient] = false) : (g_bGhost[iClient] = true);
	GetClientCookie(iClient, g_hCookieThirdPerson, strCookies, sizeof(strCookies));
	(StrEqual(strCookies, "0") ? (g_bThirdPerson[iClient] = false) : (g_bThirdPerson[iClient] = true);
	*/
	new String:sValue[10];
	GetClientCookie(iClient, g_hCookieThirdPerson, sValue, sizeof(sValue));
	(sValue[0]=='\0') ? (g_bThirdPerson[iClient]=true) : (g_bThirdPerson[iClient]=bool:StringToInt(sValue));
	GetClientCookie(iClient, g_hCookieGhost, sValue, sizeof(sValue));
	(sValue[0]=='\0') ? (g_bGhost[iClient]=true) : (g_bGhost[iClient]=bool:StringToInt(sValue));
}

public OnClientDisconnect(iClient) //Better save cookies on disconnect and reset arrays
{
	SaveCookieValues(iClient);
	g_bIsGhost[iClient] = false;
	g_bBecomingGhost[iClient] = false;
	g_bGhost[iClient] = true;
	g_bThirdPerson[iClient] = true;
}


public Action:Event_RoundStart(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	if(g_bArena)
	{
		g_bRoundStarted = false;
		return;
	}

	g_bRoundStarted = true;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsPlayerAlive(i))
		{
			g_bIsGhost[i] = false;
			g_bBecomingGhost[i] = false;
		}
	}
}

public Action:Event_ArenaStart(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	g_bRoundStarted = true;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsPlayerAlive(i))
		{
			g_bIsGhost[i] = false;
			g_bBecomingGhost[i] = false;
		}
	}
}

public Action:Event_RoundEnd(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	g_bRoundStarted = false;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsPlayerAlive(i))
		{
			g_bIsGhost[i] = false;
			g_bBecomingGhost[i] = false;
		}

		// Re apply colors on round end... :/
		if(g_bIsGhost[i])
		{
			SetEntityRenderMode(i, RENDER_TRANSALPHA);
			SetEntityRenderColor(i, 255, 255, 255, 75);
		}
	}
}

public Action:Event_PlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new iUserId = GetEventInt(hEvent, "userid");
	new iClient = GetClientOfUserId(iUserId);
	if(!IsValidClient(iClient))
	return;

	if(g_bRoundStarted && g_bGhost[iClient] && g_bBecomingGhost[iClient] &&  GetClientTeam(iClient) > 1 && IsPlayerAlive(iClient) && CheckCommandAccess(iClient, "sm_ghost", 0, true))
	{
		g_bIsGhost[iClient] = true;
		g_bBecomingGhost[iClient] = false;

		SetEntProp(iClient, Prop_Send, "m_iHideHUD", GHOST_HUD);
		SetEntProp(iClient, Prop_Send, "m_CollisionGroup", GHOST_COLLISION);
		SetEntProp(iClient, Prop_Send, "m_usSolidFlags", GHOST_SOLID);
		SetEntProp(iClient, Prop_Send, "m_bGlowEnabled", 0);
		SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
		SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 0);

		SetVariantInt(1);
		AcceptEntityInput(iClient, "SetCustomModelRotates");

		SetVariantString(g_strCvarModel);
		AcceptEntityInput(iClient, "SetCustomModel");

		SetEntityGravity(iClient, 0.5);
		SetEntityRenderMode(iClient, RENDER_TRANSALPHA);
		SetEntityRenderColor(iClient, 255, 255, 255, 75);

		TeleportEntity(iClient, g_flOrigin[iClient], g_flAngles[iClient], g_flVelocity[iClient]);

		CreateTimer(0.1, Timer_ReApplyModel, iUserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.2, Timer_ThirdPerson, iUserId, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_RemoveParticles, iUserId, TIMER_FLAG_NO_MAPCHANGE);

		for(new i = 0; i <= 5 ; i++)
		{
			new iWeapon = GetPlayerWeaponSlot(iClient, i);
			if(iWeapon != -1)
			{
				if(i != TFWeaponSlot_Melee)
				TF2_RemoveWeaponSlot(iClient, i);
				else
				{
					SetEntityRenderMode(iWeapon, RENDER_TRANSALPHA);
					SetEntityRenderColor(iWeapon, _, _, _, 0);
					SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", GetGameTime() + 7200.0);
					SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack", GetGameTime() + 7200.0);
				}
			}
		}

		new iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) != -1)
		{
			if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
			AcceptEntityInput(iEntity, "kill");
		}

		if(!g_bCvarWearables)
		{
			iEntity = -1;
			while((iEntity = FindEntityByClassname(iEntity, "tf_wear*")) != -1)
			{
				if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				AcceptEntityInput(iEntity, "kill");
			}
		}

		if(!g_bInformed[iClient])
		{
			PrintToChat(iClient, "%t", "ghostinfo");
			g_bInformed[iClient] = true;
		}
	}
	else
	{
		g_bIsGhost[iClient] = false;
		g_bBecomingGhost[iClient] = false;

		if(IsPlayerAlive(iClient))
		{
			SetEntProp(iClient, Prop_Send, "m_iHideHUD", DEFAULT_HUD);
			SetEntProp(iClient, Prop_Send, "m_CollisionGroup", DEFAULT_COLLISION);
			SetEntProp(iClient, Prop_Send, "m_usSolidFlags", DEFAULT_SOLID);
		}

		decl String:strModel[PLATFORM_MAX_PATH];
		GetClientModel(iClient, strModel, sizeof(strModel));
		if(StrEqual(strModel, g_strCvarModel) || StrEqual(strModel, "models/props_halloween/ghost.mdl"))
		{
			SetVariantString("");
			AcceptEntityInput(iClient, "SetCustomModel");
		}
		
		CreateTimer(1.0, Timer_RemoveParticles, iUserId, TIMER_FLAG_NO_MAPCHANGE);

		SetEntityGravity(iClient, 1.0);
		SetEntityRenderMode(iClient, RENDER_NORMAL);

		new iWeapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if(iWeapon != -1)
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSALPHA);
			SetEntityRenderColor(iWeapon, _, _, _, 255);
			SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
			SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack", GetGameTime() + 1.0);
		}
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	if(!g_bRoundStarted)
	return;

	if(g_iCvarEnabled == 2 && !g_bArena)
	return;

	new iFlags = GetEventInt(hEvent, "death_flags");
	if(iFlags & TF_DEATHFLAG_DEADRINGER)
	return;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsFakeClient(iClient) || !CheckCommandAccess(iClient, "sm_ghost", 0, true) || TF2_GetPlayerDesiredClass(iClient) == TFClass_Unknown)
	return;

	if(g_bGhost[iClient])
	{
		g_bBecomingGhost[iClient] = true;

		GetClientAbsOrigin(iClient, g_flOrigin[iClient]);
		GetClientAbsAngles(iClient, g_flAngles[iClient]);
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", g_flVelocity[iClient]);

		CreateTimer(0.1, Timer_Respawn, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Event_PlayerChangeClass(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsPlayerAlive(iClient))
	return;

	g_bIsGhost[iClient] = false;
	g_bBecomingGhost[iClient] = false;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:flVelocity[3], Float:fAngles[3], &iWeapon)
{
	if(!IsValidClient(iClient))
	return;

	if(GetClientTeam(iClient) == 1 && GetEntityMoveType(iClient) != MOVETYPE_OBSERVER)
	TF2_RespawnPlayer(iClient);

	if(!g_bIsGhost[iClient] || IsPlayerAlive(iClient))
	return;

	if(g_iCvarTeleporting > 0 && iButtons & IN_ATTACK)
	{
		static iLastTeleport[MAXPLAYERS + 1];
		new iTime = GetTime();
		if(iTime - iLastTeleport[iClient] >= 4)
		{
			TeleportToRandomPlayer(iClient);
			iLastTeleport[iClient] = iTime;
		}
	}

	if(g_bCvarFlying && iButtons & IN_ATTACK2 || (iButtons & IN_JUMP && !(GetEntityFlags(iClient) & FL_ONGROUND)))
	{
		if(GetEntityMoveType(iClient) != MOVETYPE_FLY)
		SetEntityMoveType(iClient, MOVETYPE_FLY);
	}
	else if(GetEntityMoveType(iClient) != MOVETYPE_WALK)
	SetEntityMoveType(iClient, MOVETYPE_WALK);
}

public Action:SetTransmit(iEntity, iClient)
{
	if(!g_bRoundStarted)
	return Plugin_Continue;

	if(g_bIsGhost[iEntity] && IsPlayerAlive(iClient))
	{
		if(GetClientTeam(iClient) > 1)
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:PreThink(iEntity, iClient)
{
	if(!g_bIsGhost[iEntity])
	return;

	SetEntPropFloat(iEntity, Prop_Send, "m_flMaxspeed", 300.0);
	if(GetEntityMoveType(iEntity) == MOVETYPE_FLY && GetClientTeam(iEntity) > 1)
	{
		decl Float:flVelocity[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecVelocity", flVelocity);

		flVelocity[0] *= 0.98;
		flVelocity[1] *= 0.98;
		flVelocity[2] *= 0.98;

		TeleportEntity(iEntity, NULL_VECTOR, NULL_VECTOR, flVelocity);
	}
}

public Action:SoundHook(iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags)
{
	if(IsValidClient(iEntity) && g_bIsGhost[iEntity])
	{
		if(StrContains(strSample, "footsteps", false) != -1 || StrContains(strSample, "weapons", false) != -1 || StrContains(strSample, "pain", false) != -1)
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:Command_Ghost(iClient, iArgs)
{
	if(!IsValidClient(iClient))
	return Plugin_Continue;

	Menu_Ghost(iClient);
	return Plugin_Handled;
}

public Action:Command_Joinclass(iClient, const String:strCmd[], iArgs)
{
	if(!g_bIsGhost[iClient])
	return Plugin_Continue;

	decl String:strCommand[32];
	GetCmdArg(1, strCommand, sizeof(strCommand));

	new TFClassType:iClass = TF2_GetClass(strCommand);
	if(iClass != TFClass_Unknown)
	SetEntProp(iClient, Prop_Send, "m_iDesiredPlayerClass", iClass);

	return Plugin_Stop;
}

public Action:Command_Jointeam(iClient, const String:strCmd[], iArgs)
{
	if(g_bIsGhost[iClient])
	return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Command_Taunt(iClient, const String:strCmd[], iArgs)
{
	if(g_bIsGhost[iClient])
	return Plugin_Handled;
	return Plugin_Continue;
}

// ====[ MENUS ]===============================================================
public Menu_Ghost(iClient)
{
	if(IsVoteInProgress())
	return;

	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Ghostmode Preferences");
	DrawPanelText(hPanel, " ");

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

	SendPanelToClient(hPanel, iClient, MenuHandler_Ghost, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
}

public MenuHandler_Ghost(Handle:hPanel, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction != MenuAction_Select)
	return;

	if(iParam2 == 1)
	{
		if(g_bGhost[iParam1])
		{
			g_bGhost[iParam1] = false;
		}
		else
		{
			g_bGhost[iParam1] = true;
		}
		Menu_Ghost(iParam1);
	}

	if(iParam2 == 2)
	{
		if(g_bThirdPerson[iParam1])
		{
			g_bThirdPerson[iParam1] = false;

			if(g_bIsGhost[iParam1])
			{
				SetVariantInt(0);
				AcceptEntityInput(iParam1, "SetForcedTauntCam");
			}
		}
		else
		{
			g_bThirdPerson[iParam1] = true;

			if(g_bIsGhost[iParam1])
			{
				SetVariantInt(2);
				AcceptEntityInput(iParam1, "SetForcedTauntCam");
			}
		}
		Menu_Ghost(iParam1);
	}
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Respawn(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
	return;

	if(!g_bRoundStarted)
	{
		g_bIsGhost[iClient] = false;
		g_bBecomingGhost[iClient] = false;
		return;
	}

	if(TF2_GetPlayerDesiredClass(iClient) != TFClass_Unknown)
	TF2_RespawnPlayer(iClient);
}

public Action:Timer_ReApplyModel(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient) || !g_bIsGhost[iClient])
	return Plugin_Stop;

	decl String:strModel[PLATFORM_MAX_PATH];
	GetClientModel(iClient, strModel, sizeof(strModel));

	if(StrEqual(strModel, g_strCvarModel))
	return Plugin_Stop;

	SetVariantString(g_strCvarModel);
	AcceptEntityInput(iClient, "SetCustomModel");

	return Plugin_Continue;
}

public Action:Timer_ThirdPerson(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
	return;

	if(g_bIsGhost[iClient] && g_bThirdPerson[iClient])
	{
		SetVariantInt(2);
		AcceptEntityInput(iClient, "SetForcedTauntCam");
	}
}

public Action:Timer_RemoveParticles(Handle:hTimer, any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
	return;

	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(iClient, "DispatchEffect");
}

SaveCookieValues(client)
{
	new String:value[10];
	IntToString(g_bGhost[client], value, sizeof(value));
	SetClientCookie(client, g_hCookieGhost, value);
	IntToString(g_bThirdPerson[client], value, sizeof(value));
	SetClientCookie(client, g_hCookieThirdPerson, value);
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	return false;
	return true;
}

stock TFClassType:TF2_GetPlayerDesiredClass(iClient)
{
	return TFClassType:GetEntProp(iClient, Prop_Send, "m_iDesiredPlayerClass");
}

stock TeleportToRandomPlayer(iClient)
{
	new iCount;
	new iPlayers[MAXPLAYERS + 1];

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsPlayerAlive(i) && i != iClient)
		{
			if(g_iCvarTeleporting == 2 && GetClientTeam(iClient) != GetClientTeam(i))
			continue;

			if(GetEntProp(i, Prop_Send, "m_bDucked") || GetEntProp(i, Prop_Send, "m_bDucking"))
			continue;

			iPlayers[iCount++] = i;
		}
	}

	if(iCount <= 0)
	return;

	new iTarget = iPlayers[GetRandomInt(0, iCount - 1)];
	if(IsValidClient(iTarget))
	{
		decl Float:flPosition[3];
		GetClientAbsOrigin(iTarget, flPosition);

		decl Float:flAngle[3];
		GetClientAbsAngles(iTarget, flAngle);

		TeleportEntity(iClient, flPosition, flAngle, NULL_VECTOR);
	}
}