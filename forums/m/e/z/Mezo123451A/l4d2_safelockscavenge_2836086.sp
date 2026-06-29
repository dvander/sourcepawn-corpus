/**
 * ======================================================================================== *
 *                             [L4D2] Saferoom Lock: Scavenge                               *
 * ---------------------------------------------------------------------------------------- *
 *  Author      :   Eärendil                                                                *
 *  Descrp      :   Players must complete a small scavenge event to unlock the saferoom     *
 *  Version     :   1.2.2                                                                   *
 *  Link        :   https://forums.alliedmods.net/showthread.php?t=333086                   *
 * ======================================================================================== *
 *                                                                                          *
 *  CopyRight (C) 2022 Eduardo "Eärendil" Chueca                                            *
 * ---------------------------------------------------------------------------------------- *
 *  This program is free software; you can redistribute it and/or modify it under the       *
 *  terms of the GNU General Public License, version 3.0, as published by the Free          *
 *  Software Foundation.                                                                    *
 *                                                                                          *
 *  This program is distributed in the hope that it will be useful, but WITHOUT ANY         *
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A         *
 *  PARTICULAR PURPOSE. See the GNU General Public License for more details.                *
 *                                                                                          *
 *  You should have received a copy of the GNU General Public License along with            *
 *  this program. If not, see <http://www.gnu.org/licenses/>.                               *
 * ======================================================================================== *
 */
 
#pragma		semicolon 1
#pragma		newdecls required
#include	<sourcemod>
#include	<sdktools>

#define CFG_FILE		"data/l4d2_safelockscavenge.cfg"

#define MDL_GEN1		"models/props_vehicles/radio_generator.mdl"
#define MDL_GEN2		"models/props_vehicles/floodlight_generator_nolight_static.mdl"
#define MDL_GEN3		"models/props_vehicles/floodlight_generator_pose01_static.mdl"
#define MDL_GEN4		"models/props_vehicles/floodlight_generator_pose02_static.mdl"
#define MDL_GASCAN		"models/props_junk/gascan001a.mdl"

#define SND_START1		"ui/critical_event_1.wav"
#define SND_START2		"ui/pickup_secret01.wav"
#define SND_COMPLETE1	"ui/pickup_misc42.wav"
#define SND_COMPLETE2	"ui/beep22.wav"

#define TN_GEN			"plugin_scav_model_generator"
#define TN_NOZZLE		"plugin_scav_model_nozzle"
#define TN_USETARGET	"plugin_scav_usetarget"
#define TN_GASCAN		"plugin_scav_gascan"
#define TN_EDITGEN		"plugin_scav_propbuild_generator"
#define TN_EDITCAN		"plugin_scav_propbuild_gascan"

#define CHAT_TAG		"\x04[\x05SLS\x04]\x01"
#define CAN_LIMIT		32

#define CL_DEF			"\x01"
#define CL_ORANGE		"\x04"
#define CL_LIGHTGREEN	"\x03"
#define CL_GREEN		"\x05"

#define PLUGIN_VERSION	"1.2.2"


bool g_bAllow, g_bPluginOn, g_bAllowGamemode, g_bRoundStart, g_bPlayerSpawn, g_bSpawned, g_bEditMode, g_bInTime, g_bLoaded;

int g_iGascanAm, g_iArGenColor[3], g_iArnozzleGlow[3], g_iCurrEnt, g_iDoor, g_iScavStatus, g_iPourAmount, g_iEdNozzle[3],
	g_iScavDisp, g_iNozzleRef, g_iUseTargetRef, g_iNozzlePos, g_iGenModel, g_iCommonLimit, g_iCanEditorCount, g_iPanicVar, g_iPanicCount;

char g_sGasCanAm[8], g_sGascanSkin[8], g_sMapName[32];

float g_vUseTarget[3];

ConVar g_hAllow, g_hGascanAm, g_hGenColor, g_hnozzleGlow, g_hGascanSkin, g_hPanic;

Menu g_hMenuPre, g_hMenu, g_hMenuPos, g_hMenuAng, g_hMenuModel, g_hMenuNozzle;

Handle g_hBotTimer[MAXPLAYERS+1];	// Handle for timer to stop bot commands

GlobalForward g_hForwardScavenge;	// Global forward for plugin API

public Plugin myinfo =
{
	name = "[L4D2] Saferoom Lock: Scavenge",
	author = "Eärendil",
	description = "Players must complete a scavenge event to unlock the saferoom",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333086",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
		return APLRes_Success;
		
	strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

//==========================================================================================
//								Sourcemod & Client Forwards
//==========================================================================================
public void OnPluginStart()
{
	CreateConVar("l4d2_safelockscavenge_version", PLUGIN_VERSION, "Scavenge to unlock saferoom version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAllow =			CreateConVar("l4d2_sls_enable",				"1",			"0 = Plugin Off. 1 = Plugin On", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGascanAm =		CreateConVar("l4d2_sls_gascan_amount",		"8",			"Amount of gascans needed to unlock the saferoom.", FCVAR_NOTIFY, true, 1.0, true, 32.0);
	g_hGenColor =		CreateConVar("l4d2_sls_generatorcolor",		"234,171,102",	"RGB color of the generator, separate values by commas, no spaces.\nUse -1 on a value to make it random.", FCVAR_NOTIFY);
	g_hnozzleGlow =		CreateConVar("l4d2_sls_nozzleglowcolor", 	"255,31,26",	"RGB glowing color of the generator nozzle, separate values by commas, no spaces.\nUse -1 on a value to make it random.", FCVAR_NOTIFY);
	g_hGascanSkin =		CreateConVar("l4d2_sls_gascanskin",			"0",			"Sets the skin of the gascan. 0 = Random skin.\n1 = Orange skin. 2 = Green sking. 3 = Diesel skin.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hPanic =			CreateConVar("l4d2_sls_panicamount",		"0",			"Amount of panic events to create while scavenge is active and not completed. -1 = infinite", FCVAR_NOTIFY, true, -1.0);
	
	RegAdminCmd("sm_sls_generator",	AdmSpawnGen,		ADMFLAG_ROOT, "Sets generator position");
	RegAdminCmd("sm_sls_genmodel",	AdmGenModel,		ADMFLAG_ROOT, "Changes generator model");
	RegAdminCmd("sm_sls_nozzlepos",	AdmNozzlePos,		ADMFLAG_ROOT, "Changes the position of the nozzle (-1 = left, 0 = center, 1 = right)");
	RegAdminCmd("sm_sls_gascan",	AdmSpawnCan,		ADMFLAG_ROOT, "Sets gascan spawn position");
	RegAdminCmd("sm_sls_editor",	AdmToggleEditor,	ADMFLAG_ROOT, "Toggles editor mode: 0 = editor off, 1 = editor on");
	RegAdminCmd("sm_sls_save",		AdmSaveSpawns,		ADMFLAG_ROOT, "Save map config into file");
	RegAdminCmd("sm_sls_mark",		AdmMarkEnt,			ADMFLAG_ROOT, "Mark entity for manipulation (unmarks previous entity)");
	RegAdminCmd("sm_sls_unmark",	AdmUnmarkEnt,		ADMFLAG_ROOT, "Unmark entity");
	RegAdminCmd("sm_sls_delete",	AdmDeleteEnt,		ADMFLAG_ROOT, "Delete marked entity");
	RegAdminCmd("sm_sls_move",		AdmMovEnt,			ADMFLAG_ROOT, "Move current marked entity");
	RegAdminCmd("sm_sls_rotate",	AdmRotEnt,			ADMFLAG_ROOT, "Rotate current marked entity");
	RegAdminCmd("sm_sls_wipe",		AdmWipeEnts,		ADMFLAG_ROOT, "Wipe scavenge entities in the map");
	RegAdminCmd("sm_sls_load",		AdmLoadEnts,		ADMFLAG_ROOT, "Load map config");
	RegAdminCmd("sm_sls_menu",		AdmMenu,			ADMFLAG_ROOT, "Open menu to edit scavenge item positions");
	
	g_hAllow.AddChangeHook(CVarChange_Enable);
	g_hGascanAm.AddChangeHook(CVarChange_CVars);
	g_hPanic.AddChangeHook(CVarChange_CVars);
	g_hGenColor.AddChangeHook(CVarChange_Colors);
	g_hnozzleGlow.AddChangeHook(CVarChange_Colors);
	g_hGascanSkin.AddChangeHook(CVarChange_CVars);
	
	AutoExecConfig(true, "l4d2_safelockscavenge");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/safelockscavenge.phrases.txt");
	if (!FileExists(sPath))
		SetFailState("%s Missing translation file!", CHAT_TAG);
	
	LoadTranslations("safelockscavenge.phrases");
	
	g_hForwardScavenge = CreateGlobalForward("SLS_OnDoorStatusChanged", ET_Event, Param_Cell);
}

public void OnConfigsExecuted()
{
	SwitchPlugin();
	GetCVars();
	GetColors();
}

public void OnMapStart()
{
	GetCurrentMap(g_sMapName, sizeof(g_sMapName));
	PrecacheModel("models/props_vehicles/floodlight_generator_nolight_static.mdl", true);
	PrecacheModel("models/props_vehicles/floodlight_generator_pose01_static.mdl", true);
	PrecacheModel("models/props_vehicles/floodlight_generator_pose02_static.mdl", true);
	PrecacheModel("models/props_vehicles/radio_generator.mdl", true);
	PrecacheModel("models/props_vehicles/radio_generator_fillup.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	
	PrecacheSound(SND_COMPLETE1, false);
	PrecacheSound(SND_COMPLETE2, false);
	PrecacheSound(SND_START1, false);
	PrecacheSound(SND_START2, false);
}

public void OnClientConnected(int client)
{
	if (g_bEditMode && IsFakeClient(client))
		KickClient(client);
		
	if (!g_bLoaded)	// First round of server run is never recorded with "player_spawn" or "round_start"
	{
		g_bLoaded = true;
		CreateTimer(10.0, FirstExecution_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnMapEnd()
{
	g_bPlayerSpawn = false;
	g_bRoundStart = false;
	g_iDoor = 0;
	g_iScavStatus = 0;
	g_iPourAmount = 0;
	g_bSpawned = false;
	g_iPanicCount = 0;
	DeleteBotTimers();
}

//==========================================================================================
//										ConVars
//==========================================================================================
void CVarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	SwitchPlugin();
}

void CVarChange_CVars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}
void CVarChange_Colors(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetColors();
}

void SwitchPlugin()
{
	g_bAllow = g_hAllow.BoolValue;
	GetGamemode();
	if (g_bPluginOn == false && g_bAllow == true && g_bAllowGamemode == true)
	{
		g_bPluginOn = true;
		HookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
		HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_PostNoCopy);
		HookEvent("round_end", Event_Round_End, EventHookMode_PostNoCopy);
	}
	if (g_bPluginOn == true && (g_bAllow == false || g_bAllowGamemode == false))
	{
		g_bPluginOn = false;
		UnhookEvent("round_start", Event_Round_Start);
		UnhookEvent("player_spawn", Event_Player_Spawn);
		UnhookEvent("round_end", Event_Round_End);
		if (g_bEditMode)
			DisableEditorMode();
			
		DeleteBotTimers();
	}
}

void GetGamemode()
{
	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_bAllowGamemode = true;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_bAllowGamemode = false;
	else if( strcmp(output, "OnVersus") == 0 )
		g_bAllowGamemode = true;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_bAllowGamemode = false;
}

void GetCVars()
{
	g_iGascanAm = g_hGascanAm.IntValue;
	IntToString(g_iGascanAm, g_sGasCanAm, sizeof(g_sGasCanAm));	// We need to parse the amount as a string
	if (g_hGascanSkin.IntValue >= 1)
		g_hGascanSkin.GetString(g_sGascanSkin, sizeof(g_sGascanSkin));
		
	g_iPanicVar = g_hPanic.IntValue;
}

void GetColors()
{
	char sBuffer[16], sArBuffer[3][8];
	g_hGenColor.GetString(sBuffer, sizeof(sBuffer));
	if (ExplodeString(sBuffer, ",", sArBuffer, 3, sizeof(sArBuffer[]), true) == 3)
	{
		for (int i = 0; i <= 2; i++)
			g_iArGenColor[i] = StringToInt(sArBuffer[i]);
	}
	else
	{
		PrintToServer("Error, couldn`t get generator color ConVar, using default values.");
		g_iArGenColor[0] = 234;
		g_iArGenColor[1] = 171;
		g_iArGenColor[2] = 102;
	}
	g_hnozzleGlow.GetString(sBuffer, sizeof(sBuffer));
	if (ExplodeString(sBuffer, ",", sArBuffer, 3, sizeof(sArBuffer[]), true) == 3)
	{
		for (int i = 0; i <= 2; i++)
			g_iArnozzleGlow[i] = StringToInt(sArBuffer[i]);
	}
	else
	{
		PrintToServer("Error, couldn't get nozzle glow color ConVar, using default values.");
		g_iArnozzleGlow[0] = 255;
		g_iArnozzleGlow[1] = 31;
		g_iArnozzleGlow[2] = 26;
	}
}

//==========================================================================================
//									Events
//==========================================================================================
void Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bPlayerSpawn && !g_bRoundStart)
		CreateTimer(1.0, MainSpawn_Timer, _, TIMER_FLAG_NO_MAPCHANGE);

	g_bRoundStart = true;
}

void Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPlayerSpawn && g_bRoundStart)
		CreateTimer(1.0, MainSpawn_Timer, _, TIMER_FLAG_NO_MAPCHANGE);

	g_bPlayerSpawn = true;
}

void Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	// This will prevent the plugin to crash scavenge finales in dead center, the passing and the last stand
	if( StrEqual(g_sMapName, "c1m4_atrium", false) || StrEqual(g_sMapName, "c6m3_port", false) || StrEqual(g_sMapName, "c14m2_lighthouse", false) )
		return;

	g_bPlayerSpawn = false;
	g_bRoundStart = false;
	g_iDoor = 0;
	g_iPourAmount = 0;
	if (IsValidEntity(g_iScavDisp))
		AcceptEntityInput(g_iScavDisp, "TurnOff");

	// Kill scavenge item spawns or they remain for the next round. Yeah, more bugs!
	int i = -1;
	while( (i = FindEntityByClassname(i, "weapon_scavenge_item_spawn")) != -1 )
	{
		char sName[32];
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if( StrEqual(sName, TN_GASCAN) )
			AcceptEntityInput(i, "Kill");
	}
			
	g_iScavStatus = 0;
	g_iPanicCount = 0;
	g_bSpawned = false;
	DeleteBotTimers();
}

//========================================================================================
//									Admin Commands
//==========================================================================================
Action AdmToggleEditor(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (args != 1)
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CmdEdUsage", CL_LIGHTGREEN, CL_GREEN, CL_DEF);

	char sArgs[8];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	if (StrEqual(sArgs, "1", false) && !g_bEditMode)
	{
		if (g_iDoor != 0)
		{
			SetEntProp(g_iDoor, Prop_Send, "m_glowColorOverride", GetColorInt(0, 0, 255));
			AcceptEntityInput(g_iDoor, "StartGlowing");
		}
		else
		{
			ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_EdFailNoDoor");
			return Plugin_Handled;
		}
		EnableEditorMode();
		if (LoadAllEditorEnts()) ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_LoadSuccess");
		else ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_LoadFail");	
	}
	if (StrEqual(sArgs, "0", false) && g_bEditMode)
		DisableEditorMode();

	return Plugin_Handled;
}

Action AdmSaveSpawns(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	
	if (SaveSpawns()) ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_SaveSuccess");
	else ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_SaveFail");
	
	return Plugin_Handled;
}

Action AdmSpawnGen(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	
	int i = -1;
	int gen = 0;
	while ((i = FindEntityByClassname(i, "prop_dynamic")) != -1)
	{
		char sName[32], sModel[64];
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		if (StrEqual(sName, TN_EDITGEN, false))
			gen = EntIndexToEntRef(i);
	}
	float vPos[3];
	if(GetHitPoint(client, vPos))
	{
		if (gen != 0) TeleportEntity(gen, vPos, NULL_VECTOR, NULL_VECTOR);	// We will preserve generator model, angles and nozzle pos
		else
		{
			if (g_iGenModel == 0) g_iGenModel = 1;
			switch(g_iGenModel)
			{
				case 1: SpawnEdGenerator(vPos, NULL_VECTOR, MDL_GEN1);
				case 2: SpawnEdGenerator(vPos, NULL_VECTOR, MDL_GEN2);
				case 3: SpawnEdGenerator(vPos, NULL_VECTOR, MDL_GEN3);
				case 4: SpawnEdGenerator(vPos, NULL_VECTOR, MDL_GEN4);
			}
		}
	}
	else
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_SpawnFail");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

Action AdmGenModel(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CmdModelUsage", CL_LIGHTGREEN, CL_GREEN, CL_DEF);
		return Plugin_Handled;
	}
	
	char sArgs[8];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	int value = StringToInt(sArgs);
	if (value < 1 || value > 4)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CmdModelUsage", CL_LIGHTGREEN, CL_GREEN, CL_DEF);
		return Plugin_Handled;
	}
	
	SetGeneratorModel(value);
	if (g_iNozzlePos == 0 && value != 1)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_NoCenterNozzle");
		SetNozzlePos(1);
	}
	else ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_GenModelSuccess");

	return Plugin_Handled;
}

Action AdmNozzlePos(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComNozUsage", CL_LIGHTGREEN, CL_GREEN, CL_DEF);
		return Plugin_Handled;
	}

	char sArgs[8];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	int value = StringToInt(sArgs);
	if (value < -1 || value > 1)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComNozUsage", CL_LIGHTGREEN, CL_GREEN, CL_DEF);
		return Plugin_Handled;
	}

	int result = SetNozzlePos(value);
	switch(result)
	{
		case -1: ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_NozLeft", CL_GREEN, CL_DEF);
		case 0: ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_NozCent", CL_GREEN, CL_DEF);
		case 1: ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_NozRight", CL_GREEN, CL_DEF);
		case 2: ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_NozNotCen");
	}
	return Plugin_Handled;
}

int SetNozzlePos(int value)
{
	// Make current active nozzle invisible
	if (g_iGenModel != 1 && value == 0)
		return 2;
		
	if (IsValidEntity(g_iEdNozzle[g_iNozzlePos+1]))
	{
			AcceptEntityInput(g_iEdNozzle[g_iNozzlePos+1], "StopGlowing");
			SetVariantString("0");
			AcceptEntityInput(g_iEdNozzle[g_iNozzlePos+1], "Alpha");
	}
	
	if (value > 0)
	{
		if (IsValidEntity(g_iEdNozzle[2]))
		{
			AcceptEntityInput(g_iEdNozzle[2], "StartGlowing");
			SetVariantString("255");
			AcceptEntityInput(g_iEdNozzle[2], "Alpha");	
		}
		g_iNozzlePos = 1;
		return 1;
	}
	if (value < 0)
	{
		if (IsValidEntity(g_iEdNozzle[0]))
		{
			AcceptEntityInput(g_iEdNozzle[0], "StartGlowing");
			SetVariantString("255");
			AcceptEntityInput(g_iEdNozzle[0], "Alpha");
		}
		g_iNozzlePos = -1;
		return -1;
	}
	
	if (IsValidEntity(g_iEdNozzle[1]))
	{	
		AcceptEntityInput(g_iEdNozzle[1], "StartGlowing");
		SetVariantString("255");
		AcceptEntityInput(g_iEdNozzle[1], "Alpha");	
	}

	g_iNozzlePos = 0;
	return 0;
}

Action AdmSpawnCan(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (g_iCanEditorCount >= 32)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CanLimit");
		return Plugin_Handled;
	}

	float vPos[3];
	if(GetHitPoint(client, vPos))
	{
		SpawnEdGascan(vPos, NULL_VECTOR, true);
		g_iGenModel = 1;
		g_iCanEditorCount++;
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CanSpawn", CL_ORANGE, CL_LIGHTGREEN, g_iCanEditorCount, CL_ORANGE);
	}
	else ReplyToCommand(client, "%t", "SLS_SpawnFail");

	return Plugin_Handled;
}

Action AdmMarkEnt(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}

	if (args == 1)
	{
		char sArgs[16];
		GetCmdArg(1, sArgs, sizeof(sArgs));
		if (StrEqual(sArgs, "closest", true))
		{
			if (MarkClosestEnt(client))
				ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_MarkSuccess");
				
			else
				ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_MarkFail");
			
			return Plugin_Handled;
		}
	}
	if (SelectEntity(client))
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_MarkSuccess");

	else
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_MarkFail");

	return Plugin_Handled;
}

Action AdmUnmarkEnt(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (g_iCurrEnt != 0)
	{
		SetEntProp(g_iCurrEnt, Prop_Send, "m_glowColorOverride", GetColorInt(255, 255, 255));
		g_iCurrEnt = 0;
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_UnmarkSuccess");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

Action AdmDeleteEnt(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (DeleteFakeEnt())
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_DeleteSuccess");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_DeleteFail");
	return Plugin_Handled;
}

Action AdmMovEnt(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, CL_LIGHTGREEN, CL_GREEN, CL_DEF);
		return Plugin_Handled;
	}
	
	char sAxis[8], sAmount[16];
	int iAxis;
	
	GetCmdArg(1, sAxis, sizeof(sAxis));
	GetCmdArg(2, sAmount, sizeof(sAmount));
	
	if (StrEqual(sAxis, "x", false)) iAxis = 0;
	else if (StrEqual(sAxis, "y", false)) iAxis = 1;
	else iAxis = 2;
	float fAmount = StringToFloat(sAmount);
	
	if (g_iCurrEnt != 0)
	{
		MoveEntity(iAxis, fAmount, false);
		return Plugin_Handled;
	}
	ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_MoveFail");
	return Plugin_Handled;
}

Action AdmRotEnt(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CmdRotUsage", CL_LIGHTGREEN, CL_GREEN, CL_DEF);
		return Plugin_Handled;
	}
	
	char sAxis[8], sAmount[16];
	int iAxis;
	
	GetCmdArg(1, sAxis, sizeof(sAxis));
	GetCmdArg(2, sAmount, sizeof(sAmount));
	
	if (StrEqual(sAxis, "x", false)) iAxis = 0;
	else if (StrEqual(sAxis, "z", false)) iAxis = 1;
	else iAxis = 2;
	float fAmount = StringToFloat(sAmount);
	
	if (g_iCurrEnt != 0)
	{
		MoveEntity(iAxis, fAmount, true);
		return Plugin_Handled;
	}
	ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_CmdRotFail");
	return Plugin_Handled;
}

Action AdmWipeEnts(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	WipeFakeEnts();
	ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_Wiped");
	return Plugin_Handled;
}

Action AdmLoadEnts(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	if (!g_bEditMode)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComEdOnly");
		return Plugin_Handled;
	}
	WipeFakeEnts();
	LoadAllEditorEnts();
	ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_LoadSuccess");
	return Plugin_Handled;
}

Action AdmMenu(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s %t", CHAT_TAG, "SLS_ComGameOnly");
		return Plugin_Handled;
	}
	GenerateMenus(client);
	if (!g_bEditMode) g_hMenuPre.Display(client, MENU_TIME_FOREVER);
	else g_hMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

//==========================================================================================
//										Menus
//==========================================================================================
// I know that menus will be only shown in the language of the user who first uses sm_sls_menu command
// But this should be used by only 1 person per server, usually the server owner. 
void GenerateMenus(int client)
{
	char sBuffer[64];
	if (g_hMenuPre == null)
	{
		g_hMenuPre = new Menu(MenuPreEditHandler);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Title", client);
		g_hMenuPre.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_EnableEd", client);
		g_hMenuPre.AddItem("", sBuffer);
	}
	if (g_hMenu == null)
	{
		g_hMenu = new Menu(MenuEditorHandler);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Title", client);
		g_hMenu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_SpawnGen", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_SpawnCan", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Mark", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Unmark", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_MarkClose", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Delete", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Move", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Rotate", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_GenModel", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_NozzlePos", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Wipe", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Save", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Load", client);
		g_hMenu.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_DisableEd", client);
		g_hMenu.AddItem("", sBuffer);
	}
	if (g_hMenuPos == null)
	{
		g_hMenuPos = new Menu(MenuPositionHandler);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Move", client);
		g_hMenuPos.SetTitle(sBuffer);
		g_hMenuPos.AddItem("", "X + 2");
		g_hMenuPos.AddItem("", "X - 2");
		g_hMenuPos.AddItem("", "Y + 2");
		g_hMenuPos.AddItem("", "Y - 2");
		g_hMenuPos.AddItem("", "Z + 2");
		g_hMenuPos.AddItem("", "Z - 2");
		g_hMenuPos.ExitBackButton = true;
	}
	if (g_hMenuAng == null)
	{
		g_hMenuAng = new Menu(MenuAnglesHandler);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Rotate", client);
		g_hMenuAng.SetTitle(sBuffer);
		g_hMenuAng.AddItem("", "X + 5");
		g_hMenuAng.AddItem("", "X - 5");
		g_hMenuAng.AddItem("", "Z + 5");
		g_hMenuAng.AddItem("", "Z - 5");
		g_hMenuAng.AddItem("", "Y + 5");
		g_hMenuAng.AddItem("", "Y - 5");
		g_hMenuAng.ExitBackButton = true;
	}
	if (g_hMenuModel == null)
	{
		g_hMenuModel = new Menu(MenuModelHandler);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_GenModel", client);
		g_hMenuModel.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T %s", "SLSM_Model", client, "1");
		g_hMenuModel.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T %s", "SLSM_Model", client, "2");
		g_hMenuModel.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T %s", "SLSM_Model", client, "3");
		g_hMenuModel.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T %s", "SLSM_Model", client, "4");
		g_hMenuModel.AddItem("", sBuffer);
		g_hMenuModel.ExitBackButton = true;
	}
	if (g_hMenuNozzle == null)
	{
		g_hMenuNozzle = new Menu(MenuNozzleHandler);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_NozzlePos", client);
		g_hMenuNozzle.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Left", client);
		g_hMenuNozzle.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Center", client);
		g_hMenuNozzle.AddItem("", sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%T", "SLSM_Right", client);
		g_hMenuNozzle.AddItem("", sBuffer);
		g_hMenuNozzle.ExitBackButton = true;
	}
}

int MenuPreEditHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		if (g_iDoor != 0)
		{
			SetEntProp(g_iDoor, Prop_Send, "m_glowColorOverride", GetColorInt(0, 0, 255));
			AcceptEntityInput(g_iDoor, "StartGlowing");
		}
		else
		{
			PrintToChat(client, "%s %t", CHAT_TAG, "SLS_EdFailNoDoor");
			return 0;
		}	
		EnableEditorMode();
		if (LoadAllEditorEnts()) PrintToChat(client, "%s %t", CHAT_TAG, "SLS_LoadSuccess");
		else PrintToChat(client, "%s %t", CHAT_TAG, "SLS_LoadFail");
		g_hMenu.Display(client, MENU_TIME_FOREVER);
	}
	return 0;
}

int MenuEditorHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		switch (index)
		{
			case 0:
			{
				AdmSpawnGen(client, 0);
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 1:
			{
				AdmSpawnCan(client, 0);
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 2:
			{
				AdmMarkEnt(client, 0);
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 3:
			{
				AdmUnmarkEnt(client, 0);
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 4:
			{
				if (MarkClosestEnt(client)) PrintToChat(client, "%s %t", CHAT_TAG, "SLS_MarkSuccess");
				else PrintToChat(client, "%s %t", "SlS_MarkFail");
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 5:
			{
				if (DeleteFakeEnt()) PrintToChat(client, "%s %t", CHAT_TAG, "SLS_DeleteSuccess");
				else PrintToChat(client, "%s %t", CHAT_TAG, "SLS_DeleteFail");
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 6: g_hMenuPos.Display(client, MENU_TIME_FOREVER);
			case 7: g_hMenuAng.Display(client, MENU_TIME_FOREVER);
			case 8: g_hMenuModel.Display(client, MENU_TIME_FOREVER);
			case 9: g_hMenuNozzle.Display(client, MENU_TIME_FOREVER);
			case 10:
			{
				WipeFakeEnts();
				PrintToChat(client, "%s %t", CHAT_TAG, "SLS_Wiped");
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 11:
			{
				if (SaveSpawns()) PrintToChat(client, "%s %t", CHAT_TAG, "SLS_SaveSuccess");
				else PrintToChat(client, "%s %t", CHAT_TAG, "SLS_SaveFail");
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 12:
			{
				WipeFakeEnts();
				LoadAllEditorEnts();			
				g_hMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 13: DisableEditorMode();
		}
	}
	return 0;
}

int MenuAnglesHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		if (g_iCurrEnt != 0)
		{
			switch(index)
			{
				case 0: MoveEntity(0, 5.0, true);
				case 1: MoveEntity(0, -5.0, true);
				case 2: MoveEntity(1, 5.0, true);
				case 3: MoveEntity(1, -5.0, true);
				case 4: MoveEntity(2, 5.0, true);
				case 5: MoveEntity(2, -5.0, true);
			}
		}
		else PrintToChat(client, "%s %t", CHAT_TAG, "SLS_CmdRotFail");
		g_hMenuAng.Display(client, MENU_TIME_FOREVER);
	}
	if (action == MenuAction_Cancel && index ==  MenuCancel_ExitBack)
		g_hMenu.Display(client, MENU_TIME_FOREVER);
		
	return 0;
}

int MenuPositionHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		if (g_iCurrEnt != 0)
		{
			switch(index)
			{
				case 0: MoveEntity(0, 2.0, false);
				case 1: MoveEntity(0, -2.0, false);
				case 2: MoveEntity(1, 2.0, false);
				case 3: MoveEntity(1, -2.0, false);
				case 4: MoveEntity(2, 2.0, false);
				case 5: MoveEntity(2, -2.0, false);
			}
		}
		else PrintToChat(client, "%s %t", CHAT_TAG, "SLS_MoveFail");
		g_hMenuPos.Display(client, MENU_TIME_FOREVER);
	}
	if (action == MenuAction_Cancel && index ==  MenuCancel_ExitBack)
		g_hMenu.Display(client, MENU_TIME_FOREVER);
		
	return 0;
}

int MenuModelHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		int value = index + 1;
		SetGeneratorModel(value);
		if (g_iNozzlePos == 0 && value != 1)
		{
			PrintToChat(client, "%s %t", CHAT_TAG, "SLS_NoCenterNozzle");
			SetNozzlePos(1);
		}
		else PrintToChat(client, "%s %t", CHAT_TAG, "SLS_GenModelSuccess");
		
		g_hMenuModel.Display(client, MENU_TIME_FOREVER);
	}
	if (action == MenuAction_Cancel && index ==  MenuCancel_ExitBack)
		g_hMenu.Display(client, MENU_TIME_FOREVER);
		
	return 0;
}

int MenuNozzleHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		int result = SetNozzlePos(index - 1);
		switch(result)
		{
			case -1: PrintToChat(client, "%s %t", CHAT_TAG, "SLS_NozLeft", CL_LIGHTGREEN, CL_DEF);
			case 0: PrintToChat(client, "%s %t", CHAT_TAG, "SLS_NozCent", CL_LIGHTGREEN, CL_DEF);
			case 1: PrintToChat(client, "%s %t", CHAT_TAG, "SLS_NozRight", CL_LIGHTGREEN, CL_DEF);
			case 2: PrintToChat(client, "%s %t", CHAT_TAG, "SLS_NozNotCen");
		}
		g_hMenuNozzle.Display(client, MENU_TIME_FOREVER);
	}
	if (action == MenuAction_Cancel && index ==  MenuCancel_ExitBack)
		g_hMenu.Display(client, MENU_TIME_FOREVER);
		
	return 0;
}

//==========================================================================================
//									Editor functions
//==========================================================================================
bool GetHitPoint(int client, float vPos[3])
{
	float vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_ALL, RayType_Infinite, _TraceFilter);

	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(vPos, hTrace);
		
		delete hTrace;
		return true;
	}
	delete hTrace;
	return false;
}

int TR_HitEntity(int client)
{
	float vPos[3], vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_ALL, RayType_Infinite, _TraceFilter);

	if (TR_DidHit(hTrace))
	{
		int entity = TR_GetEntityIndex(hTrace);
		delete hTrace;
		return entity;
	}
	delete hTrace;
	return 0;
}

bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

// Spawn the generator in editor mode
void SpawnEdGenerator(const float position[3], const float angles[3], const char modelName[64])
{
	int gen = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(gen, "targetname", TN_EDITGEN);
	DispatchKeyValue(gen, "model", modelName);
	DispatchKeyValue(gen, "solid", "6");
	DispatchKeyValue(gen, "glowcolor", "255 255 255");
	DispatchKeyValue(gen, "glowstate", "3");

	DispatchSpawn(gen);
	SpawnEdNozzles();
	FindSaferoomDoor(position);
	TeleportEntity(gen, position, angles, NULL_VECTOR);
}

// Spawn gascans in editor mode
void SpawnEdGascan(float position[3], const float angles[3], bool firstSpawn = false)
{
	if (firstSpawn)
		position[2] += 11.0;

	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "targetname", TN_EDITCAN);
	DispatchKeyValue(entity, "model", MDL_GASCAN);
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "glowcolor", "255 255 255");
	DispatchKeyValue(entity, "glowstate", "3");
	TeleportEntity(entity, position, angles, NULL_VECTOR);
	DispatchSpawn(entity);
}

// Create generator nozzles to preview its position in editor mode
void SpawnEdNozzles()
{
	for (int i = 0; i < 3; i++)
	{
		int nozzle = CreateEntityByName("prop_dynamic");
		DispatchKeyValue(nozzle, "targetname", "plugin_scav_propbuild_nozleft");
		DispatchKeyValue(nozzle, "model", "models/props_vehicles/radio_generator_fillup.mdl");
		DispatchKeyValue(nozzle, "glowcolor", "0 255 255");
		DispatchKeyValue(nozzle, "glowstate", "0");
		DispatchKeyValue(nozzle, "rendermode", "1"); // Rendermode: Color
		DispatchKeyValue(nozzle, "renderamt", "0"); // Opacity: 255 = opaque, 0 = invisible
		
		switch (i)
		{
			case 0:
			{
				float npos[3] = {54.0, -36.0, 41.0}, nang[3] = {0.0, 270.0, 37.0};
				TeleportEntity(nozzle, npos, nang, NULL_VECTOR);
			}
			case 2:
			{
				float npos[3] = {-54.0, -46.0, 41.0}, nang[3] = {0.0, 90.0, 37.0};
				TeleportEntity(nozzle, npos, nang, NULL_VECTOR);
			}
		}
		DispatchSpawn(nozzle);
		g_iEdNozzle[i] = EntIndexToEntRef(nozzle);
		SetVariantString(TN_EDITGEN);
		AcceptEntityInput(nozzle, "SetParent");
	}
	switch(g_iNozzlePos)
	{
		case -1:{
			SetVariantString("255");
			AcceptEntityInput(g_iEdNozzle[0], "Alpha");
			AcceptEntityInput(g_iEdNozzle[0], "StartGlowing");}
		case 0:{
			SetVariantString("255");
			AcceptEntityInput(g_iEdNozzle[1], "Alpha");
			AcceptEntityInput(g_iEdNozzle[1], "StartGlowing");}
		case 1:{
			SetVariantString("255");
			AcceptEntityInput(g_iEdNozzle[2], "Alpha");
			AcceptEntityInput(g_iEdNozzle[2], "StartGlowing");}
	}
}

void SetGeneratorModel(int value)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "prop_dynamic")) != -1)
	{
		char sName[32];
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if (StrEqual(sName, TN_EDITGEN, false))
		{
			switch(value)
			{
				case 1: SetEntityModel(i, MDL_GEN1);
				case 2: SetEntityModel(i, MDL_GEN2);
				case 3: SetEntityModel(i, MDL_GEN3);
				case 4: SetEntityModel(i, MDL_GEN4);
			}
		}
	}
	g_iGenModel = value;
	return;
}

void DeleteScavEnts()
{
	int i = -1;
	char sName[32];
	while ((i = FindEntityByClassname(i, "prop_dynamic")) != -1)
	{
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if( StrEqual(sName, TN_GEN) || StrEqual(sName, TN_NOZZLE) )
			AcceptEntityInput(i, "Kill");
	}
}

void WipeFakeEnts()
{
	g_iCurrEnt = 0;
	g_iCanEditorCount = 0;
	int i = -1;
	while( (i = FindEntityByClassname(i, "prop_dynamic")) != -1 )	//For some reason prop_dynamic_override is detected as prop_dynamic
	{
		char sName[32];
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if( StrEqual(sName, TN_EDITGEN) || StrEqual(sName, TN_EDITCAN) )
			AcceptEntityInput(i, "Kill");
	}
}

bool DeleteFakeEnt()
{
	if (g_iCurrEnt == 0)
		return false;
	char sName[32];
	GetEntPropString(g_iCurrEnt, Prop_Data, "m_iName", sName, sizeof(sName));
	if( StrEqual(sName, TN_EDITCAN) )
		g_iCanEditorCount--;

	AcceptEntityInput(g_iCurrEnt, "Kill");
	g_iCurrEnt = 0;
	return true;
}

bool SelectEntity(int client)
{
	float vPos[3], vAng[3];
	int entity;
	
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);
	entity = TR_HitEntity(client);

	if( !IsValidEntity(entity) || entity == 0 )
		return false;

	char sName[32];
	GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
	if( StrEqual(sName, TN_EDITGEN) || StrEqual(sName, TN_EDITCAN) )
	{
		if( IsValidEntity(g_iCurrEnt) && g_iCurrEnt != 0 )
			SetEntProp(g_iCurrEnt, Prop_Send, "m_glowColorOverride", GetColorInt(255, 255, 255));

		g_iCurrEnt = EntIndexToEntRef(entity);
		SetEntProp(g_iCurrEnt, Prop_Send, "m_glowColorOverride", GetColorInt(0, 255, 0));
		return true;
	}
	return false;
}

// Finds the closest scavenge entity and marks it
bool MarkClosestEnt(int client)
{
	float fMin = -1.0, vPos[3], vClient[3];
	int iEnt = -1, i = -1;
	char sName[32];
	GetClientEyePosition(client, vClient);
	while( (i = FindEntityByClassname(i, "prop_dynamic")) != -1 )
	{
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if( !StrEqual(sName, TN_EDITCAN) && !StrEqual(sName, TN_EDITGEN) )
			continue;
			
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);
		float distance = GetVectorDistance(vPos, vClient, true);
		if( fMin < 0.0 || distance < fMin )
		{
			fMin = distance;
			iEnt = i;
		}
	}
	if( iEnt != -1 )
	{
		if( g_iCurrEnt != -1 )
			SetEntProp(g_iCurrEnt, Prop_Send, "m_glowColorOverride", GetColorInt(255, 255, 255));
			
		g_iCurrEnt = EntIndexToEntRef(iEnt);
		SetEntProp(g_iCurrEnt, Prop_Send, "m_glowColorOverride", GetColorInt(0, 255, 0));
		return true;
	}
	return false;
}

void MoveEntity(int axis, float amount, const bool rotate)
{
	float vPos[3], vAng[3];
	GetEntPropVector(g_iCurrEnt, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(g_iCurrEnt, Prop_Data, "m_angRotation", vAng);
	
	if (!rotate) vPos[axis] += amount;
	else vAng[axis] += amount;

	TeleportEntity(g_iCurrEnt, vPos, vAng, NULL_VECTOR);
}

void EnableEditorMode()
{
	g_bEditMode = true;
	ConVar hCVar = FindConVar("z_common_limit");
	g_iCommonLimit = hCVar.IntValue;
	hCVar.SetInt(0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i))
			KickClient(i);
	}
	DeleteScavEnts();
	if (IsValidEntity(g_iDoor))
	{
		UnhookSingleEntityOutput(g_iDoor, "OnOpen", OnOpen);
		CallForward(false);
		g_iDoor = 0;
	}
}

void DisableEditorMode()
{
	g_bEditMode = false;
	int players = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			players++;
			if(IsPlayerAlive(i))
				ForcePlayerSuicide(i);
		}
	}
	for (int i = players; i < 4; i++)	// Fill survivors with bots until 4 players are ingame
	{
		int newbot = CreateFakeClient("Bot");
		ChangeClientTeam(newbot, 2);
		KickClient(newbot);
	}
	ConVar hCVar = FindConVar("z_common_limit");
	hCVar.SetInt(g_iCommonLimit);
	delete g_hMenuPre;
	delete g_hMenu;
	delete g_hMenuPos;
	delete g_hMenuAng;
	delete g_hMenuModel;
	delete g_hMenuNozzle;
}

//==========================================================================================
//								Editor Save & Load system
//==========================================================================================
bool LoadAllEditorEnts()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CFG_FILE);
	if (!FileExists(sPath))
	{
		PrintToServer("%s Configuration file \"%s\" not found, can't load spawns.", CHAT_TAG, CFG_FILE);
		return false;
	}
	KeyValues hKV = new KeyValues("settings");
	if (!hKV.ImportFromFile(sPath))
	{
		PrintToServer("%s Error: can't load %s file.", CHAT_TAG, CFG_FILE);
		delete hKV;
		return false;
	}
	if (!hKV.JumpToKey(g_sMapName, true))
	{
		PrintToServer("%s Error: Couldn`t find current map config in the file.", CHAT_TAG);
		delete hKV;
		return false;
	}
	
	//Looking for generator in config file
	if (hKV.JumpToKey("generator"))
	{
		float vPos[3], vAng[3];
		g_iGenModel = hKV.GetNum("model");
		g_iNozzlePos = hKV.GetNum("nozzlepos");
		hKV.GetVector("origin", vPos);
		hKV.GetVector("angles", vAng);
		
		if (g_iGenModel < 2) SpawnEdGenerator(vPos, vAng, MDL_GEN1);
		else if (g_iGenModel < 3) SpawnEdGenerator(vPos, vAng, MDL_GEN2);
		else if (g_iGenModel < 4) SpawnEdGenerator(vPos, vAng, MDL_GEN3);
		else SpawnEdGenerator(vPos, vAng, MDL_GEN4);
		
		hKV.GoBack();
		if (g_iDoor != 0)
		{
			SetEntProp(g_iDoor, Prop_Send, "m_glowColorOverride", GetColorInt(0, 0, 255));
			AcceptEntityInput(g_iDoor, "StartGlowing");
		}
	}

	// Looking for gascans in config file
	g_iCanEditorCount = hKV.GetNum("gascancount");
	if (g_iCanEditorCount == 0)
	{
		delete hKV;
		return false;
	}
	for (int i = 0; i < g_iCanEditorCount; i++)
	{
		char sKey[16], sBuffer[8];
		float vPos[3], vAng[3];
		IntToString(i, sBuffer, sizeof(sBuffer));
		Format(sKey, sizeof(sKey), "gascan#%s", sBuffer);
		hKV.JumpToKey("gascan_origins");
		hKV.GetVector(sKey, vPos);
		hKV.GoBack();
		hKV.JumpToKey("gascan_angles");
		hKV.GetVector(sKey, vAng);
		SpawnEdGascan(vPos, vAng);
		hKV.GoBack();
	}
	delete hKV;
	return true;
}

bool SaveSpawns()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CFG_FILE);
	if (!FileExists(sPath))
	{
		File hFile = OpenFile(sPath, "w");
		hFile.WriteLine("");
		delete hFile;
	}
	KeyValues hKV = new KeyValues("settings");
	if (!hKV.ImportFromFile(sPath))
	{
		PrintToServer("%s Error: can't load %s file.", CHAT_TAG, CFG_FILE);
		delete hKV;
		return false;
	}
	
	// Delte last saved config for map if existed
	if (hKV.JumpToKey(g_sMapName, true))
	{
		hKV.DeleteThis();
		hKV.Rewind();
		hKV.JumpToKey(g_sMapName, true);
	}
	else
	{
		delete hKV;
		return false;
	}
	
	// Save generator position
	int i = -1;
	while ((i = FindEntityByClassname(i, "prop_dynamic")) != -1)	//For some reason prop_dynamic_override is detected as prop_dynamic
	{
		char sName[32];
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if (StrEqual(sName, TN_EDITGEN, false))
		{
			float vPos[3], vAng[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(i, Prop_Data, "m_angRotation", vAng);
			hKV.JumpToKey("generator", true);
			hKV.SetNum("model", g_iGenModel);
			hKV.SetNum("nozzlepos", g_iNozzlePos);
			hKV.SetVector("origin", vPos);
			hKV.SetVector("angles", vAng);
			hKV.GoBack();
			break;
		}
	}
	
	// Save gascan positions
	int count = 0;
	i = -1;
	while ((i = FindEntityByClassname(i, "prop_dynamic")) != -1)
	{
		char sName[32];
		GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
		if (StrEqual(sName, TN_EDITCAN, false))
		{
			char sKey[16], sBuffer[8];
			float vPos[3], vAng[3];
			
			IntToString(count, sBuffer, sizeof(sBuffer));
			Format(sKey, sizeof(sKey), "gascan#%s", sBuffer);
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(i, Prop_Data, "m_angAbsRotation", vAng);
			
			hKV.JumpToKey("gascan_origins", true);
			hKV.SetVector(sKey, vPos);
			hKV.GoBack();
			hKV.JumpToKey("gascan_angles", true);
			hKV.SetVector(sKey, vAng);
			hKV.GoBack();

			count++;
		}
	}
	hKV.SetNum("gascancount", count);
	hKV.Rewind();
	hKV.ExportToFile(sPath);
	delete hKV;
	return true;
}

//==========================================================================================
//								Scavenge system
//==========================================================================================
bool InitializeRound()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CFG_FILE);
	if (!FileExists(sPath))
	{
		PrintToServer("Configuration file \"%s\" not found.", CFG_FILE);
		return false;
	}
	KeyValues hKV = new KeyValues("settings");
	if (!hKV.ImportFromFile(sPath))
	{
		PrintToServer("%s Error: can't load \"%s\" file.", CHAT_TAG, CFG_FILE);
		delete hKV;
		return false;
	}
	if (!hKV.JumpToKey(g_sMapName))
	{
		PrintToServer("%s Error: Couldn`t get current map.", CHAT_TAG);
		delete hKV;
		return false;
	}
	if (hKV.GetNum("gascancount") == 0)
	{
		delete hKV;
		return false;	
	}
	if (!hKV.JumpToKey("generator"))
	{
		delete hKV;
		return false;
	}
	
	float vPos[3], vAng [3];
	hKV.GetVector("origin", vPos);
	hKV.GetVector("angles", vAng);
	CreateMainEntities(vPos, vAng, hKV.GetNum("model"), hKV.GetNum("nozzlepos"));
	FindSaferoomDoor(vPos);	
	delete hKV;
	
	// Hook Door outputs
	if (g_iDoor != 0)
	{
		AcceptEntityInput(g_iDoor, "Close");
		// I tried to block the door with "Lock" input but that didn`t work. So I will use Silver`s method from Safe Door Spam Protection https://forums.alliedmods.net/showthread.php?p=2700212
		HookSingleEntityOutput(g_iDoor, "OnOpen", OnOpen);
		CallForward(true);
	}
	return true;
}

void OnOpen(const char[] output, int caller, int activator, float delay)
{
	if (!g_bPluginOn)
		return;
		
	if (g_iScavStatus >= 0 && !g_bInTime)
	{
		RequestFrame(CloseDoor);
		CommandBotsAway();
		g_bInTime = true;
	}
	if (g_iScavStatus == 0)
	{
		if (InitializeScavenge())
		{
			if (GetRandomInt(0,1) == 0) EmitSoundToAll(SND_START1);
			else EmitSoundToAll(SND_START2);
			PrintToChatAll("%s %t", CHAT_TAG, "SLS_AnounceScavStart");
			if (g_iPanicVar != 0)
				ForcePanicEvent();
		}
	}
}

void CloseDoor(int na)
{
	SetEntPropString(g_iDoor, Prop_Data, "m_SoundClose", "");
	SetEntPropString(g_iDoor, Prop_Data, "m_SoundOpen", "");
	AcceptEntityInput(g_iDoor, "Close");
	SetEntPropString(g_iDoor, Prop_Data, "m_SoundClose", "Doors.Checkpoint.FullClose1");
	SetEntPropString(g_iDoor, Prop_Data, "m_SoundOpen", "Doors.Checkpoint.FullOpen1");
	g_bInTime = false;
}

bool InitializeScavenge()
{
	if (g_iScavStatus != 0)
		return false;
	// Load gascans
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CFG_FILE);
	if( !FileExists(sPath) )
		return false;
		
	KeyValues hKV = new KeyValues("settings");
	if( !hKV.ImportFromFile(sPath) )
	{
		delete hKV;
		return false;
	}
	if( !hKV.JumpToKey(g_sMapName) )
	{
		delete hKV;
		return false;
	}
	int iGascanCount = 0;
	iGascanCount = hKV.GetNum("gascancount");
	if( iGascanCount == 0 )
	{
		delete hKV;
		return false;	
	}
	// Create a dynamic array to randomize gascan spawns
	ArrayList hArray = CreateArray(1, 0);
	for( int i = 0; i < iGascanCount; i++ )
	{
		hArray.Push(i);
	}
	if( iGascanCount > g_iGascanAm )
		iGascanCount = g_iGascanAm;	// Allow to spawn only the gascans set by convar

	hArray.Sort(Sort_Random, Sort_Integer);

	// Spawn gascans randomly	
	for( int i = 0; i < iGascanCount; i++ )
	{
		char sKey[16], sBuffer[8];
		float vPos[3], vAng[3];
		int value = hArray.Get(i);
		IntToString(value, sBuffer, sizeof(sBuffer));
		Format(sKey, sizeof(sKey), "gascan#%s", sBuffer);
		
		hKV.JumpToKey("gascan_origins");
		hKV.GetVector(sKey, vPos);
		hKV.GoBack();
		hKV.JumpToKey("gascan_angles");
		hKV.GetVector(sKey, vAng);
		SpawnGascan(vPos, vAng);
		hKV.GoBack();
	}
	delete hKV;
	
	// Make checkpoint door and generator nozzle glow
	SetEntProp(g_iDoor, Prop_Send, "m_glowColorOverride", GetColorInt(255, 0, 0));
	AcceptEntityInput(g_iDoor, "StartGlowing");
	AcceptEntityInput(g_iNozzleRef, "StartGlowing");

	char sGascanCount[8];
	IntToString(iGascanCount, sGascanCount, sizeof(sGascanCount));
	// Spawn and enable the progress display
	int display = CreateEntityByName("game_scavenge_progress_display");
	DispatchKeyValue(display, "Max", sGascanCount);
	DispatchSpawn(display);
	AcceptEntityInput(display, "TurnOn");
	g_iScavDisp = EntIndexToEntRef(display);
	
	// Send back the point_prop_use_target back to its position
	TeleportEntity(g_iUseTargetRef, g_vUseTarget, NULL_VECTOR, NULL_VECTOR);
	g_iScavStatus = 1;
	return true;
}

void SpawnGascan(float vPos[3], float vAng[3])
{
	if (g_hGascanSkin.IntValue == 0)
		IntToString(GetRandomInt(1,3), g_sGascanSkin, sizeof(g_sGascanSkin));

	int gascan = CreateEntityByName("weapon_scavenge_item_spawn");
	DispatchKeyValue(gascan, "targetname", TN_GASCAN);
	DispatchKeyValue(gascan, "glowstate", "3");
	DispatchKeyValue(gascan, "solid", "6");
	DispatchKeyValue(gascan, "spawnflags", "1");
	DispatchKeyValue(gascan, "weaponskin", g_sGascanSkin);
	TeleportEntity(gascan, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(gascan);
	AcceptEntityInput(gascan, "SpawnItem");
}

void CreateMainEntities(const float vPos[3], const float vAng[3], int model, int nozzlePos)
{
	// Get generator color and nozzle glow color
	char sGenColor[16], sNozzleGlow[16];
	RGBToString(g_iArGenColor , sGenColor, sizeof(sGenColor));
	RGBToString(g_iArnozzleGlow, sNozzleGlow, sizeof(sNozzleGlow));

	// Spawn generator
	int generator = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(generator, "targetname", TN_GEN);
	switch (model)
	{
		case 1: DispatchKeyValue(generator, "model", MDL_GEN1);
		case 2: DispatchKeyValue(generator, "model", MDL_GEN2);
		case 3: DispatchKeyValue(generator, "model", MDL_GEN3);
		case 4: DispatchKeyValue(generator, "model", MDL_GEN4);
	}
	DispatchKeyValue(generator, "rendercolor", sGenColor);
	DispatchKeyValue(generator, "solid", "6");
	DispatchSpawn(generator);
	
	// Generator nozzle
	int nozzle = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(nozzle, "targetname", TN_NOZZLE);
	DispatchKeyValue(nozzle, "model", "models/props_vehicles/radio_generator_fillup.mdl");
	DispatchKeyValue(nozzle, "glowcolor", sNozzleGlow);
	DispatchKeyValue(nozzle, "glowrange", "1800");
	DispatchKeyValue(nozzle, "glowstate", "0");	// Nozzle will glow later
	DispatchKeyValue(nozzle, "solid", "6");

	// point_prop_use_target
	int propUseTarget = CreateEntityByName("point_prop_use_target");
	DispatchKeyValue(propUseTarget, "targetname", TN_USETARGET);
	DispatchKeyValue(propUseTarget, "nozzle", TN_NOZZLE);

	if (nozzlePos < 0)
	{
		float npos[3] = {54.0, -36.0, 41.0}, nang[3] = {0.0, 270.0, 37.0}, tpos[3] = {-24.0, -40.0, 52.0};
		TeleportEntity(nozzle, npos, nang, NULL_VECTOR);
		TeleportEntity(propUseTarget, tpos, NULL_VECTOR, NULL_VECTOR);
	}
	else if (nozzlePos > 0)
	{
		float npos[3] = {-54.0, -46.0, 41.0}, nang[3] = {0.0, 90.0, 37.0}, tpos[3] = {24.0, -40.0, 52.0};
		TeleportEntity(nozzle, npos, nang, NULL_VECTOR);
		TeleportEntity(propUseTarget, tpos, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		float tpos[3] = {4.0, -60.0, 56.0};
		TeleportEntity(propUseTarget, tpos, NULL_VECTOR, NULL_VECTOR);	
	}
	
	DispatchSpawn(nozzle);
	DispatchSpawn(propUseTarget);
	HookSingleEntityOutput(propUseTarget, "OnUseFinished", OnUseFinished);	// Hook usetarget filling outputs
	g_iNozzleRef = EntIndexToEntRef(nozzle);
	g_iUseTargetRef = EntIndexToEntRef(propUseTarget);

	SetVariantString(TN_GEN);
	AcceptEntityInput(g_iNozzleRef, "SetParent");
	SetVariantString(TN_GEN);
	AcceptEntityInput(g_iUseTargetRef, "SetParent");
	
	TeleportEntity(generator, vPos, vAng, NULL_VECTOR);
	RequestFrame(MoveUsetarget);	// Move the use target away to prevent players use it before scavenge starts
}

void OnUseFinished(const char[] output, int caller, int activator, float delay)
{
	g_iPourAmount++;
	if (g_iPourAmount == g_iGascanAm)
	{
		SetEntProp(g_iDoor, Prop_Send, "m_glowColorOverride", GetColorInt(0, 255, 0));
		g_iScavStatus = -1;
		if (GetRandomInt(0,1) == 0)	EmitSoundToAll(SND_COMPLETE1);
		else EmitSoundToAll(SND_COMPLETE2);
		PrintToChatAll("%s %t", CHAT_TAG, "SLS_AnounceScavEnd");
		UnhookSingleEntityOutput(g_iDoor, "OnOpen", OnOpen);
		CallForward(false);
	}	
}

void MoveUsetarget(int na)
{
	AcceptEntityInput(g_iUseTargetRef, "ClearParent");	// Clear parent before requesting origin or we will get its local origin from parent hierarchy
	GetEntPropVector(g_iUseTargetRef, Prop_Send, "m_vecOrigin", g_vUseTarget);
	float vPos[3] = {32768.0, 32768.0, 32768.0};	// Send entity to a corner (in the Hammer editor this vector is a corner of the cube where we can make the map)
	TeleportEntity(g_iUseTargetRef, vPos, NULL_VECTOR, NULL_VECTOR);
}

//==========================================================================================
//								Other functions and Timers
//==========================================================================================
// Find the closest saferoom door to a vector position
void FindSaferoomDoor(const float position[3])
{
	int i = -1;
	float vPos[3], fDist = -1.0;
	g_iDoor = 0;
	while ((i = FindEntityByClassname(i, "prop_door_rotating_checkpoint")) != -1)
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);
		float tempdist = GetVectorDistance(vPos, position, true);
		if (fDist < 0.0 || fDist > tempdist)
		{
			fDist = tempdist;
			g_iDoor = EntIndexToEntRef(i);
		}
	}
}

// Convert 3 values of 8-bit into a 32-bit
int GetColorInt(int red, int green, int blue)
{
	return red + (green << 8) + (blue << 16);
}

// Converts an array [R, G, B] into a string as "R G B"
void RGBToString(int RGB[3], char[] string, int stringSize)
{
	string[0] = '\0';
	for (int i = 0; i < 3; i++)
	{
		char sBuffer[8];
		if (RGB[i] < 0)
			IntToString(GetRandomInt(0, 255), sBuffer, sizeof(sBuffer));
			
		else if (RGB[i] < 256)
			IntToString(RGB[i], sBuffer, sizeof(sBuffer));
			
		else
			IntToString(255, sBuffer, sizeof(sBuffer));
				
		if (i == 0) Format(string, stringSize, "%s%s", string, sBuffer);
		else Format(string, stringSize, "%s %s", string, sBuffer);
	}
}

void DeleteBotTimers()
{
	for (int i = 1; i <= MaxClients; i++)
		delete g_hBotTimer[i];
}

void CommandBotsAway()
{
	char sBuffer[128];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsBotNearDoor(i)) continue;
		// Send bot to the generator to prevent spamming door (yeah bots are dumb)
		Format (sBuffer, sizeof(sBuffer), "CommandABot( { cmd = 1, bot = GetPlayerFromUserID(%i) pos = Vector(%f,%f,%f) } )", GetClientUserId(i), g_vUseTarget[0], g_vUseTarget[1], g_vUseTarget[2]);
		SetVariantString(sBuffer);
		AcceptEntityInput(i, "RunScriptCode");
		delete g_hBotTimer[i];
		g_hBotTimer[i] = CreateTimer(5.0, BotCommand_Timer, i);	// Cancel de command after 5 seconds, this should allow bot to stay away from saferoom door and dont spam it
	}
}

bool IsBotNearDoor(int client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client))
		return false;
		
	if (!IsPlayerAlive(client) || !IsFakeClient(client) || GetClientTeam(client) != 2)
		return false;

	float vPos[3], vPos2[3];
	GetEntPropVector(g_iDoor, Prop_Send, "m_vecOrigin", vPos);
	GetClientAbsOrigin(client, vPos2);
	if (GetVectorDistance(vPos, vPos2, true) > 16384.0)
		return false;
	
	return true;
}

void ForcePanicEvent()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			int iComFlags = GetCommandFlags("director_force_panic_event");
			SetCommandFlags("director_force_panic_event", iComFlags & ~FCVAR_CHEAT);
			FakeClientCommand(i, "director_force_panic_event");
			SetCommandFlags("director_force_panic_event", iComFlags);
			break;
		}
	}
	g_iPanicCount++;
	if (g_iPanicCount < g_iPanicVar || g_iPanicVar < 0)
		CreateTimer(80.0, PanicLoop_Timer, TIMER_FLAG_NO_MAPCHANGE);
}

Action PanicLoop_Timer(Handle timer)
{
	if (g_iScavStatus != 1)
		return Plugin_Stop;

	ForcePanicEvent();
	return Plugin_Stop;
}

Action MainSpawn_Timer(Handle timer)
{
	if( !g_bPluginOn )
		return Plugin_Stop;
		
	if( g_bSpawned )
		return Plugin_Stop;
		
	if( !InitializeRound() )
	{
		PrintToServer("Plugin can't spawn scavenge entities, plugin will not work.");
		return Plugin_Stop;
	}
	g_bSpawned = true;
	return Plugin_Stop;
}

Action FirstExecution_Timer(Handle timer)
{
	if( !g_bPluginOn )
		return Plugin_Stop;
		
	if( g_bSpawned )
		return Plugin_Stop;

	if( !InitializeRound() )
	{
		PrintToServer("Plugin can't spawn scavenge entities, plugin will not work.");
		return Plugin_Stop;
	}
	g_bSpawned = true;
	return Plugin_Stop;	
}

// Stop previous bot command and allow AI to take control over the bot
Action BotCommand_Timer(Handle timer, int bot)
{
    g_hBotTimer[bot] = null;
    
    // Check if the bot is still connected before using it
    if (!IsClientConnected(bot) || !IsClientInGame(bot))
        return Plugin_Stop;
        
    char sBuffer[96];
    Format(sBuffer, sizeof(sBuffer), "CommandABot( { cmd = 3, bot = GetPlayerFromUserID(%i) } )", GetClientUserId(bot));
    SetVariantString(sBuffer);
    AcceptEntityInput(bot, "RunScriptCode");    
    return Plugin_Stop;
}

void CallForward(bool locked)
{
	Call_StartForward(g_hForwardScavenge);
	Call_PushCell(locked);
	Call_Finish();	
}

/*============================================================================================
									Changelog
----------------------------------------------------------------------------------------------
* 1.2.2 (08-Oct-2022)
	- Fixed problems with custom maps/addons that created more scavenge events, deleting their entities.
* 1.2.1 (20-Jul-2021)
	- Fixed bug on Dead Center, The Passing and The Last Stand finales, where map scavenges 
		crashed after round restart.
* 1.2 (05-Jul-2021)
	- Saferoom door outputs are unhooked when scavenge ends.
	- Fixed compatibility with Silvers plugin [L4D & L4D2] Saferoom Door Spam Protection 1.11+
	- Thanks to GL_INS for reporting and testing.
    - Thanks to Silvers for support and showing and helping with compatibility.
* 1.1.1 (24-Jun-2021)
	- Fixed an error in spanish translation causing some editor menu options to be 
		displayed in spanish.
* 1.1	(20-Jun-2021)
	- Fixed error with reading cfg file, thanks to VladimirTk for pointing the bug.
	- Saferoom door now is detected by its distance to the generator (prevents bugs).
	- Plugin can force panic events when scavenge starts (new ConVar).
	- Deleted unused functions.
* 1.0	(18-Jun-2021)
	- Initial release.
==============================================================================================*/