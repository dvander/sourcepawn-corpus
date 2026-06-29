//SourcePawn

/*			Changelog
*	15/07/2018 Version 1.0 – Released.
*	28/07/2018 Version 1.1 – Added "st_mr_split" ConVar.
*	21/08/2018 Version 1.2.1 – Renamed (plugin loading priority must be above to avoid conflicts with "sm_bhop" plugin);
*							changed weapon slot selection method, by cause incorrect work at record/playback;
*							now all recorded movements are saved under "defaut.txt" name.
*	31/08/2018 Version 1.2.2 – Changed playback method to play other movements while recording;
*							changed "st_mr_stop" cmd - now you may specify player index to stop its actions.
*	10/09/2018 Version 1.2.3 – Added "st_mr_no_teleport" ConVar.
*	06/10/2018 Version 1.2.4 – Added idle flags in buttons to use idling; removed IsPlayerAlive() check in ConVarChanged callback.
*	25/01/2019 Version 1.2.5 – Fixed movement split, when player received wrong start data from another movement file;
*							some changes in syntax.
*	21/03/2019 Version 1.2.6 – Added forward OnPlayEnd to hook movement playback end event; some changes in syntax.
*	08/06/2019 Version 1.2.7 – Created hook for OnPlayEnd callback for VScript.
*	26/06/2019 Version 1.2.8 – Scripted players are now able to repeat the door opening during playback, but only partially (meaning, still doesn't work
*							properly, if player hold +use button; only single pressing might be successful).
*	09/01/2020 Version 1.2.9+ – Changed teleportation method at the beggining of playback: used KeyValue method
*							instead TeleportEntity to keep player's interpolation process; changed "st_mr_stop", "st_mr_force_file" cmds;
*							added ConVar "st_mr_stop_player" to stop certain player; fixed ForceStop(). After the movement has finished,
*							now you can see the file name in console as well. Added OnPlayLine forward to hook each movement tick.
*	25/04/2020 Version 1.3.10 – Fixed code at creating array, that caused a memory leak and plugin unloading.
*							Fixed code in OnPlayerRunCmd function when the forward calling: some script within forward could override
*							global variables until the function returned value, thus VScript callback provided incorrect parameters.
*							Fixed ST_Idle method: removed "incapacitated" condition (why it was there before for so long time??).
*							UPDATE #3: Added some TAS features for convenient interaction with movements. Now playback can match
*							the original movement, if you included additional vectors (m_vecOrigin & m_vecVelocity) through "st_mr_explay"
*							and "st_mr_exrec" convars. In other cases, plugin works in legacy mode and may read/write old files as well.
*							Also, user may rewind movement during playback, by specifying file line agrument in "st_mr_goto" command.
*	17/05/2020 Version 1.3.11 – Added FCVAR_NOTIFY flag for some convars; added simple menu for convenience.
*							Note for previous update: use careful with "st_mr_goto", by cause plugin doesn't save m_fFlags, and player's
*							flags may not match. Make sure, that you can wait for the next jump before movement split to avoid flags differences
*							and incorrect movements.
*	03/06/2020 Version 1.3.12 – Fixed missing client-side fire sounds during playback. @TODO: Add bullet effects and other sounds?
*							Removed recording of idle and takeover flags, due to incorrect initializating, especially in ExMode (st_mr_explay 1).
*	30/07/2020 Version 1.3.13 – Shotgun sounds sometimes may appear on the demo... so, they are ignored.
*							Optimized code for "st_mr_play" during file reading. Added debug mode.
*	14/10/2022 Version 1.4.13 – UPDATE #4: Added opportunity to record/split movements for multiply players at once (finally?). Added "st_mr_ffa" ConVar just in case.
*	30/10/2022 Version 1.4.14 – Returned back and fixed IDLE input recording. Extended functionality of "st_mr_goto" to execute any file at specific line.
*							Increased menu duration from 1 min. to 5 min.
*	09/12/2022 Version 1.4.15 – HOTFIX: purging the g_RecLine and g_RecFlags at the start of recording to prevent data inherition (an issue came with 1.4.14 caused
*							incorrect first line save in file at record/split within OnPlay* hooks).
*							Added IN_FREE_ANGLE bit to ignore angles input during playback, for test purposes only; added "st_mr_allow_record_idle" ConVar
*							just in case the user doesn't need the IDLE recording to the file.
*	25/07/2023 Version 1.5.16b – UPDATE #5 (BETA):
*							Added more improved Advanced Menu (requested by user @N2K). New 8 commands: "stmr2", "st_mr_allow_free_angle",
*							"st_mr_allow_host_inputs", "st_mr_tweak_delay", "st_mr_tweak_timescale", "st_mr_tracker", "st_mr_tracker_clear", st_mr_save.
*							File loading process for playback has changed, allowing initialize the movement always with EX-mode parameters,
*							even if "st_mr_explay 0" was used. Replaced variable for Call_PushCell (buttons -> mask) in order to read buttons
*							that only in movement (no clients buttons are passed). Added movement flags as a new parameter, that's necessary in GOTO mode.
*	13/08/2023 Version 1.5.17b – Fixed incorrect screen text displaying (for element: "Fields.debug2"). Fixed console text spam.
*	15/08/2023 Version 1.5.18b – Added missing RevokeHostInputs funcs. Calibrated print text in ForceStop() to display more correct time and frames value.
*							While using Record/Split option, there was an issue with exit menu – fixed. Added new option "Tracker" to menu (temporary?).
*	21/08/2023 Version 1.5.19 – Added missing RevokeHostInputs funcs. Swap of "Save" and "Tracker". Didn't work Save option for other players.
*							Added new cvar "st_mr_allow_playback_special_helpers". Optimized screen debug mode. Fixed old menu ("stmr") that was closing
*							for other players after option press; also restricted Legacy Mode option for other players. Changed duck/unduck method that
*							wouldn't work with other 3rd-party ABHs.
*							BETA: closing atm, although still functionality of GOTO mode is built on... uhm, kludges somewhere, and maybe will need
*							improvements in the future; also this feature requires more tests, so use it wisely and don't try to exploit.
*	26/09/2023 Version 1.5.20 – Tracker option, if used via menu, is now displays selected with "st_mr_force_file" movement.

*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VER "1.5.20"
#define MAXCLIENTS 32
#define BLOCKS_LEN 128
#define BLOCK_SIZE 64
#define BLOCK_COUNT 7
#define PLAYER_VEL 450.0
#define MR_DIR "plugins/disabled/movements"
#define ITEMS_COUNT 27
#define IN_IDLE			(1 << 26)
#define IN_TAKEOVER	(1 << 27)
#define IN_FREE_ANGLE	(1 << 28)

new Handle:g_ConVar_ForceFile;
new Handle:g_ConVar_Play;
new Handle:g_ConVar_Record;
new Handle:g_ConVar_Split;
new Handle:g_ConVar_NoTeleport;
new Handle:g_ConVar_Stop;
new Handle:g_ConVar_ExRecord;
new Handle:g_ConVar_ExPlay;
new Handle:g_ConVar_Debug;
new Handle:g_ConVar_FFA;
new Handle:g_ConVar_AllowIDLE;
new Handle:g_ConVar_AllowFreeAngle;
new Handle:g_ConVar_AllowHostInputs;
new Handle:g_ConVar_AllowHelpers;
new Handle:g_ConVar_TweakDelay;
new Handle:g_ConVar_TweakTimeScale;

new Handle:g_RecFile[MAXCLIENTS + 1];
new bool:g_RecClient[MAXCLIENTS + 1];
new g_RecFrames[MAXCLIENTS + 1];
new Float:g_RecTime[MAXCLIENTS + 1];
new g_RecFlags[MAXCLIENTS + 1];
new String:g_RecLine[MAXCLIENTS + 1][BLOCKS_LEN];

new bool:g_bIsApplyPlayerAction[MAXCLIENTS + 1];
new bool:g_bIsClientFired[MAXCLIENTS + 1];
new g_iTicks[MAXCLIENTS + 1];
new g_iTicksTotal[MAXCLIENTS + 1];
new Handle:g_hButtons[MAXCLIENTS + 1];
new Handle:g_hAngles[MAXCLIENTS + 1][2];
new Handle:g_hWeapons[MAXCLIENTS + 1];
new Handle:g_hOrigin[MAXCLIENTS + 1];
new Handle:g_hVelocity[MAXCLIENTS + 1];
new Handle:g_hFlags[MAXCLIENTS + 1];
new String:g_sStartData[MAXCLIENTS + 1][128];
new String:g_sFileName[MAXCLIENTS + 1][64];
new String:g_sGotoPrevFile[MAXCLIENTS + 1][64];

new Handle:g_hTakeOverBot;
new Handle:g_hGoAwayFromKeyboard;
new Handle:g_hOnPlayEnd;
new Handle:g_hOnPlayLine;

new bool:g_Menu_Active[MAXCLIENTS + 1];
new bool:g_Menu_Goto[MAXCLIENTS + 1];
new g_Menu_iGotoTicks[MAXCLIENTS + 1];
new bool:g_Menu_GotoUsage[MAXCLIENTS + 1];
new g_Menu_Goto_iWarnMsg[MAXCLIENTS + 1];
new g_Menu_eDebug[MAXCLIENTS + 1];
new bool:g_Menu_bDelay[MAXCLIENTS + 1];
new Float:g_Menu_fDelayTime[MAXCLIENTS + 1];
new bool:g_Menu_bLegacy[MAXCLIENTS + 1];

new const String:g_Items[ITEMS_COUNT][] =
{
	"NULL",
	"weapon_upgradepack_incendiary",
	"weapon_upgradepack_explosive",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_adrenaline",
	"weapon_pain_pills",
	"weapon_vomitjar",
	"weapon_pipe_bomb",
	"weapon_molotov",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_shotgun_chrome",
	"weapon_pumpshotgun",
	"weapon_shotgun_spas",
	"weapon_autoshotgun",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_rifle",
	"weapon_rifle_ak47",
	"weapon_rifle_desert",
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_rifle_m60",
	"weapon_grenade_launcher",
	"weapon_chainsaw",
	"weapon_melee"
};

new const String:g_Buttons[][] =
{
	"NULL",
	"1: IN_ATTACK",
	"2: IN_JUMP",
	"4: IN_DUCK",
	"8: IN_FORWARD",
	"16: IN_BACK",
	"32: IN_USE",
	"64: IN_CANCEL",
	"128: IN_LEFT",
	"256: IN_RIGHT",
	"512: IN_MOVELEFT",
	"1024: IN_MOVERIGHT",
	"2048: IN_ATTACK2",
	"4096: IN_RUN",
	"8192: IN_RELOAD",
	"16384: IN_ALT1",
	"32768: IN_ALT2",
	"65536: IN_SCORE",
	"131072: IN_SPEED",
	"262144: IN_WALK",
	"524288: IN_ZOOM",
	"1048576: IN_WEAPON1",
	"2097152: IN_WEAPON2",
	"4194304: IN_BULLRUSH",
	"8388608: IN_GRENADE1",
	"16777216: IN_GRENADE2",
	"33554432: IN_ATTACK3",
	"67108864: IN_IDLE",
	"134217728: IN_TAKEOVER",
	"268435456: IN_FREE_ANGLE"
};

public Plugin:myinfo =
{
	name = "Movement Reader",
	author = "noa1mbot",
	description = "Records and playbacks player's movement.",
	version = PLUGIN_VER,
	url = "http://steamcommunity.com/sharedfiles/filedetails/?id=510955402"
}

//========================================================================================================================
//MR
//========================================================================================================================

public OnPluginStart()
{
	g_ConVar_ForceFile = CreateConVar("st_mr_force_file", "default", "Force custom file name to playback.");
	g_ConVar_Record = CreateConVar("st_mr_record", "0", "Specify client index to record.");
	g_ConVar_Play = CreateConVar("st_mr_play", "0", "Specify client index to playback.");
	g_ConVar_Split = CreateConVar("st_mr_split", "0", "Specify client index to split his playback and record new one.");
	g_ConVar_NoTeleport = CreateConVar("st_mr_no_teleport", "0", "Prohibit teleportation before playback.");
	g_ConVar_Stop = CreateConVar("st_mr_stop_player", "0", "Stop any record/playback for a specific player.");
	g_ConVar_ExRecord = CreateConVar("st_mr_exrec", "1", "Allow record position and velocity vectors.", FCVAR_NOTIFY);
	g_ConVar_ExPlay = CreateConVar("st_mr_explay", "1", "Allow playback position and velocity vectors.", FCVAR_NOTIFY);
	g_ConVar_Debug = CreateConVar("st_mr_debug", "0", "Montor in console movement lines by player index.", FCVAR_NOTIFY);
	g_ConVar_FFA = CreateConVar("st_mr_ffa", "1", "Activate the free-for-all mode, which allows each player to playback their own default movement.", FCVAR_NOTIFY);
	g_ConVar_AllowIDLE = CreateConVar("st_mr_allow_record_idle", "1", "Allow IDLE bits recording.", FCVAR_NOTIFY);
	g_ConVar_AllowFreeAngle = CreateConVar("st_mr_allow_free_angle", "0", "Allow record and playback with free angle (for debugging only).", FCVAR_NOTIFY);
	g_ConVar_AllowHostInputs = CreateConVar("st_mr_allow_host_inputs", "0", "Allow sending client inputs to the host console.", FCVAR_NOTIFY);
	g_ConVar_AllowHelpers = CreateConVar("st_mr_allow_playback_special_helpers", "1", "Allow special helpers while using Play option. Such as: timer reset and removing all infected.", FCVAR_NOTIFY);
	g_ConVar_TweakDelay = CreateConVar("st_mr_tweak_delay", "1.2", "Set the delay time before record/split.", FCVAR_NOTIFY);
	g_ConVar_TweakTimeScale = CreateConVar("st_mr_tweak_timescale", "0.25", "Set the timescale value after record/split.", FCVAR_NOTIFY);
	RegConsoleCmd("st_mr_stop", Cmd_Stop, "Stop any record/playback.");
	RegConsoleCmd("st_mr_get_frame", Cmd_GetFrame, "Get current playback frame from the file for debugging.");
	RegConsoleCmd("st_mr_goto", Cmd_Goto, "Move to specific line during playback (usage: st_mr_goto 150 \"filename\"). Specify only line to manage current playback.");
	RegConsoleCmd("st_mr_tracker", Cmd_Tracker, "Draw the movement path with info to console.");
	RegConsoleCmd("st_mr_tracker_clear", Cmd_Tracker, "Clear the movement path.");
	RegConsoleCmd("st_mr_save", Cmd_Save, "Creates a copy of \"default.txt\" movement and saves it as a separate file.");
	RegConsoleCmd("stmr", Cmd_MR, "Show Movement Reader menu.");
	RegConsoleCmd("stmr2", Cmd_MR2, "Show Movement Reader advanced menu.");
	
	HookConVarChange(g_ConVar_Record, ConVarChanged);
	HookConVarChange(g_ConVar_Play, ConVarChanged);
	HookConVarChange(g_ConVar_Split, ConVarChanged);
	HookConVarChange(g_ConVar_Stop, ConVarChanged);
	HookConVarChange(g_ConVar_AllowHostInputs, ConVarChanged_RevokeHostInputs);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_PlayerBotReplace);
	CreateTimer(3.0, TimerMenuUpdate, _, TIMER_REPEAT);
	
	decl String:sFilePath[64];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/st_signs.txt");
	if (FileExists(sFilePath))
	{
		new Handle:hConfig = LoadGameConfigFile("st_signs");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot");
		g_hTakeOverBot = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "GoAwayFromKeyboard");
		g_hGoAwayFromKeyboard = EndPrepSDKCall();
		CloseHandle(hConfig);
	}
	
	g_hOnPlayEnd = CreateGlobalForward("OnPlayEnd", ET_Ignore, Param_Cell, Param_String);
	g_hOnPlayLine = CreateGlobalForward("OnPlayLine", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);
}

public ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	new client = StringToInt(newValue);
	if (IsPlayer(client))
	{
		if (g_ConVar_Record == convar)
		{
			if (!g_RecClient[client])
			{
				decl String:sFilePath[128], String:sFileName[16];
				BuildPath(Path_SM, sFilePath, sizeof(sFilePath), MR_DIR);
				if (!DirExists(sFilePath)) CreateDirectory(sFilePath, 0, true);
				Format(sFileName, sizeof(sFileName), client > 1 ? "default_%d" : "default", client);
				BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/%s.txt", MR_DIR, sFileName);
				if ((g_RecFile[client] = OpenFile(sFilePath, "w")) != INVALID_HANDLE)
				{
					g_bIsApplyPlayerAction[client] = false;
					g_RecClient[client] = true;
					g_RecLine[client][0] = 0;
					g_RecFlags[client] = 0;
					g_RecTime[client] = GetGameTime();
					g_RecFrames[client] = GetGameTickCount();
					g_sFileName[client] = sFileName;
					g_sGotoPrevFile[client][0] = 0;
					RevokeHostInputs();
					decl Float:fOrigin[3], Float:fAngles[3], Float:fVelocity[3];
					GetClientAbsOrigin(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
					WriteFileLine(g_RecFile[client], "Origin:%.03f:%.03f:%.03f", fOrigin[0], fOrigin[1], fOrigin[2]);
					WriteFileLine(g_RecFile[client], "Angles:%.03f:%.03f:%.03f", fAngles[0], fAngles[1], fAngles[2]);
					WriteFileLine(g_RecFile[client], "Velocity:%.03f:%.03f:%.03f", fVelocity[0], fVelocity[1], fVelocity[2]);
					PrintToServer("[SM] Recording %N's movement...", client);
				}
			}
		}
		else if (g_ConVar_Play == convar)
		{
			decl String:sFileName[64];
			GetConVarString(g_ConVar_ForceFile, sFileName, sizeof(sFileName));
			if (StrEqual(sFileName, "default") && GetConVarBool(g_ConVar_FFA)) Format(sFileName, sizeof(sFileName), client > 1 ? "%s_%d" : "%s", sFileName, client);
			if (!g_RecClient[client] && !IsPlayerRecFile(sFileName))
			{
				decl String:sFilePath[128];
				BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/%s.txt", MR_DIR, sFileName);
				if (FileExists(sFilePath))
				{
					new Handle:hFile = OpenFile(sFilePath, "r");
					decl String:sFileData[128]; sFileData[0] = 0;
					decl String:sValue[BLOCK_COUNT][BLOCK_SIZE], Float:fValue[3][3], String:sFileLine[BLOCKS_LEN]; //max. possible line length about 106
					for (new i; i < BLOCK_COUNT; i++) sValue[i][0] = 0;
					for (new i; i < 3; i++)
					{
						ReadFileLine(hFile, sFileLine, sizeof(sFileLine));
						Format(sFileData, sizeof(sFileData), "%s%s", sFileData, sFileLine);
						ExplodeString(sFileLine, ":", sValue, 4, 16);
						fValue[i][0] = StringToFloat(sValue[1]);
						fValue[i][1] = StringToFloat(sValue[2]);
						fValue[i][2] = StringToFloat(sValue[3]);
					}
					if (!GetConVarBool(g_ConVar_NoTeleport))
					{
						TeleportEntity(client, NULL_VECTOR, fValue[1], fValue[2]);
						DispatchKeyValueVector(client, "origin", fValue[0]);
					}
					sFileData[strlen(sFileData) - 1] = 0;
					g_sStartData[client] = sFileData;
					g_sFileName[client] = sFileName;
					g_iTicks[client] = 0;
					if (g_hButtons[client] == INVALID_HANDLE)
					{
						g_hButtons[client] = CreateArray();
						g_hAngles[client][0] = CreateArray();
						g_hAngles[client][1] = CreateArray();
						g_hWeapons[client] = CreateArray();
						g_hOrigin[client] = CreateArray(16);
						g_hVelocity[client] = CreateArray(16);
						g_hFlags[client] = CreateArray();
					}
					ClearArray(g_hButtons[client]);
					ClearArray(g_hAngles[client][0]);
					ClearArray(g_hAngles[client][1]);
					ClearArray(g_hWeapons[client]);
					ClearArray(g_hOrigin[client]);
					ClearArray(g_hVelocity[client]);
					ClearArray(g_hFlags[client]);
					while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sFileLine, sizeof(sFileLine)))
					{
						ExplodeString(sFileLine, ":", sValue, BLOCK_COUNT, BLOCK_SIZE);
						PushArrayCell(g_hButtons[client], StringToInt(sValue[0]));
						PushArrayCell(g_hAngles[client][0], StringToFloat(sValue[1]));
						PushArrayCell(g_hAngles[client][1], StringToFloat(sValue[2]));
						PushArrayCell(g_hWeapons[client], StringToInt(sValue[3]));
						PushArrayString(g_hOrigin[client], sValue[4]); sValue[4][0] = 0;
						PushArrayString(g_hVelocity[client], sValue[5]); sValue[5][0] = 0;
						PushArrayString(g_hFlags[client], sValue[6]); sValue[6][0] = 0;
					}
					CloseHandle(hFile);
					g_iTicksTotal[client] = GetArraySize(g_hButtons[client]);
					g_bIsApplyPlayerAction[client] = true;
				}
				else PrintToServer("[SM] ERROR: File \"%s\" does not exist!", sFilePath);
			}
			else PrintToServer("[SM] ERROR: Cannot play while recording!");
		}
		else if (g_ConVar_Split == convar)
		{
			if (g_bIsApplyPlayerAction[client] && !g_RecClient[client])
			{
				decl String:sFileLine[BLOCKS_LEN], String:sFileName[16];
				Format(sFileName, sizeof(sFileName), client > 1 ? "default_%d" : "default", client);
				BuildPath(Path_SM, sFileLine, sizeof(sFileLine), "%s/%s.txt", MR_DIR, sFileName);
				if ((g_RecFile[client] = OpenFile(sFileLine, "w")) != INVALID_HANDLE)
				{
					g_bIsApplyPlayerAction[client] = false;
					g_RecClient[client] = true;
					g_RecLine[client][0] = 0;
					g_RecFlags[client] = 0;
					g_RecTime[client] = GetGameTime();
					g_RecFrames[client] = GetGameTickCount();
					g_sFileName[client] = sFileName;
					g_sGotoPrevFile[client][0] = 0;
					RevokeHostInputs();
					WriteFileLine(g_RecFile[client], g_sStartData[client]);
					decl String:sFileData[BLOCK_SIZE];
					for (new i; i < g_iTicks[client]; i++)
					{
						Format(sFileLine, BLOCKS_LEN, "%d:%.03f:%.03f:%d", GetArrayCell(g_hButtons[client], i), GetArrayCell(g_hAngles[client][0], i), GetArrayCell(g_hAngles[client][1], i), GetArrayCell(g_hWeapons[client], i));
						if (GetArrayString(g_hOrigin[client], i, sFileData, BLOCK_SIZE) > 0)
						{
							Format(sFileLine, BLOCKS_LEN, "%s:%s", sFileLine, sFileData);
							if (GetArrayString(g_hVelocity[client], i, sFileData, BLOCK_SIZE) > 0)
							{
								Format(sFileLine, BLOCKS_LEN, "%s:%s", sFileLine, sFileData);
								if (GetArrayString(g_hFlags[client], i, sFileData, BLOCK_SIZE) > 0)
								{
									Format(sFileLine, BLOCKS_LEN, "%s:%s", sFileLine, sFileData);
								}
							}
							sFileLine[strlen(sFileLine) - 1] = 0;
						}
						WriteFileLine(g_RecFile[client], sFileLine);
					}
					PrintToServer("[SM] Rewriting %N's movement from %d line...", client, g_iTicks[client] + 4);
				}
			}
		}
		else if (g_ConVar_Stop == convar)
		{
			ForceStop(client);
		}
	}
	SetConVarInt(convar, 0);
}

public Action:OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (g_Menu_bDelay[client])
	{
		if ((GetGameTime() - g_Menu_fDelayTime[client] + 0.001) < GetConVarFloat(g_ConVar_TweakDelay))
		{
			ShowMenu(client);
			return Plugin_Continue;
		}
		if (client == 1) SetConVarFloat(FindConVar("host_timescale"), GetConVarFloat(g_ConVar_TweakTimeScale));
		if (g_bIsApplyPlayerAction[client]) SetConVarInt(g_ConVar_Split, client);
		else if (!g_RecClient[client])
		{
			g_Menu_iGotoTicks[client] = 0;	//use?
			g_Menu_GotoUsage[client] = false;
			SetConVarInt(g_ConVar_Record, client);
			if (GetConVarBool(g_ConVar_AllowHelpers))
			{
				decl String:sKeyValue[128];
				Format(sKeyValue, sizeof(sKeyValue), "if (\"g_ST\" in getroottable()) {SpeedrunStart(); CPSetTime(%f)}", GetGameFrameTime());
				SetVariantString(sKeyValue);
				AcceptEntityInput(client, "RunScriptCode");
			}
		}
		ResetConVar(g_ConVar_ForceFile);
		ClientCommand(client, "playgamesound buttons/bell1.wav");
		if (GetEntityMoveType(client) == MOVETYPE_NONE) SetEntityMoveType(client, MOVETYPE_WALK);
		g_Menu_Goto[client] = false;
		g_Menu_bDelay[client] = false;
		ShowMenu(client);
	}
	if (g_RecClient[client])
	{
		new item;
		if (weapon > 0)
		{
			decl String:sClass[64];
			GetEntityClassname(weapon, sClass, sizeof(sClass));
			for (new i = 1; i < ITEMS_COUNT; i++)
			{
				if (StrEqual(sClass, g_Items[i]))
				{
					item = i;
					break;
				}
			}
		}
		if (GetConVarBool(g_ConVar_ExRecord) && !g_Menu_bLegacy[client])
		{
			decl Float:fPos[3], Float:fVel[3];
			GetClientAbsOrigin(client, fPos);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
			new flags = GetEntityFlags(client), plrFlags;
			if (flags & FL_ONGROUND) plrFlags |= FL_ONGROUND;
			if (flags & FL_DUCKING) plrFlags |= FL_DUCKING;
			if (GetEntProp(client, Prop_Send, "m_duckUntilOnGround")) plrFlags |= (1 << 2);
			if (GetEntProp(client, Prop_Send, "m_bDucking")) plrFlags |= (1 << 3);
			Format(g_RecLine[client], BLOCKS_LEN, "%d:%.03f:%.03f:%d:%.03f, %.03f, %.03f:%.03f, %.03f, %.03f:%d", buttons, angles[0], angles[1], item, fPos[0], fPos[1], fPos[2], fVel[0], fVel[1], fVel[2], plrFlags);
		}
		else Format(g_RecLine[client], 64, "%d:%.03f:%.03f:%d", buttons, angles[0], angles[1], item);
	}
	else if (g_bIsApplyPlayerAction[client])
	{
		if (g_iTicksTotal[client] > g_iTicks[client])
		{
			new Float:fAngles[3], Float:fVelocity[2], mask = GetArrayCell(g_hButtons[client], g_iTicks[client]), item = GetArrayCell(g_hWeapons[client], g_iTicks[client]);
			fAngles[0] = GetArrayCell(g_hAngles[client][0], g_iTicks[client]);
			fAngles[1] = GetArrayCell(g_hAngles[client][1], g_iTicks[client]);
			
			if (g_Menu_Goto[client] || GetConVarBool(g_ConVar_ExPlay) && !g_Menu_bLegacy[client])
			{
				decl String:sFileData[BLOCK_SIZE];
				if (GetArrayString(g_hOrigin[client], g_iTicks[client], sFileData, BLOCK_SIZE) > 0)
				{
					decl String:sValue[3][16];
					if (ExplodeString(sFileData, ",", sValue, 3, 16) == 3)
					{
						decl Float:fValue[3];
						for (new i; i < 3; i++) fValue[i] = StringToFloat(sValue[i]);
						DispatchKeyValueVector(client, "origin", fValue);
						if (GetArrayString(g_hVelocity[client], g_iTicks[client], sFileData, BLOCK_SIZE) > 0 && ExplodeString(sFileData, ",", sValue, 3, 16) == 3)
						{
							for (new i; i < 3; i++) fValue[i] = StringToFloat(sValue[i]);
							TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fValue);
						}
					}
				}
			}
			if (g_Menu_Goto[client])
			{
				static bool _Keylock[MAXCLIENTS + 1];
				static float _fKeylockTime[MAXCLIENTS + 1];
				bool bRewind;
				if (buttons & (IN_MOVELEFT | IN_MOVERIGHT))
				{
					bRewind = true;
					if (!_Keylock[client])
					{
						if (buttons & IN_MOVELEFT)
						{
							g_iTicks[client] = g_iTicks[client] > 0 ? g_iTicks[client] - 1 : 0;
							buttons &= ~IN_MOVELEFT;
						}
						if (buttons & IN_MOVERIGHT)
						{
							g_iTicks[client] = g_iTicks[client] < g_iTicksTotal[client] - 1 ? g_iTicks[client] + 1: g_iTicksTotal[client] - 1;
							buttons &= ~IN_MOVERIGHT;
						}
						g_Menu_iGotoTicks[client] = g_iTicks[client];
						ShowMenu(client);
						if (!g_Menu_Active[client]) g_Menu_Active[client] = true;
					}
					else if (_fKeylockTime[client] && (GetGameTime() - _fKeylockTime[client]) > 0.25) _Keylock[client] = false;
					if (!_fKeylockTime[client])
					{
						_Keylock[client] = true;
						_fKeylockTime[client] = GetGameTime();
					}
				}
				else
				{
					if (_fKeylockTime[client])
					{
						_Keylock[client] = false;
						_fKeylockTime[client] = 0.0;
					}
					g_Menu_iGotoTicks[client] = g_iTicks[client];
				}
				decl String:sFileData[BLOCK_SIZE];
				if (GetArrayString(g_hFlags[client], g_iTicks[client], sFileData, BLOCK_SIZE) > 0)
				{
					static int _curTick[MAXCLIENTS + 1] = {-1, ...};
					static bool _warnd[MAXCLIENTS + 1];
					static bool _skipFrame[MAXCLIENTS + 1];
					bool bIssueJump, bIssueStraight, bIssueDucking;
					if (GetEntityMoveType(client) != MOVETYPE_NONE) SetEntityMoveType(client, MOVETYPE_NONE);
					new plrFlags = StringToInt(sFileData), flags = GetEntityFlags(client);
					if (!bRewind)
					{
						if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
						{
							if (plrFlags & FL_DUCKING && !(flags & FL_DUCKING)) bIssueJump = true;
							else bIssueStraight = !(plrFlags & FL_DUCKING) && flags & FL_DUCKING;
						}
						else if (plrFlags & (1 << 3)) bIssueDucking = true;
					}
					if (bIssueJump || bIssueStraight || bIssueDucking)
					{
						if (!g_Menu_Goto_iWarnMsg[client])
						{
							g_Menu_Goto_iWarnMsg[client] = GetGameTickCount();
							_curTick[client] = g_iTicks[client];
						}
						if (!bIssueDucking && !_warnd[client] && !_skipFrame[client])
						{
							//@TODO: apply another duck/unduck method?
							SetEntityMoveType(client, MOVETYPE_WALK);
							SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", 0);
							if (bIssueStraight) SetEntityFlags(client, flags & ~FL_DUCKING);
							else
							{
								buttons |= IN_JUMP;
								SetEntProp(client, Prop_Data, "m_afButtonDisabled", GetEntProp(client, Prop_Data, "m_afButtonDisabled") & ~IN_JUMP);
							}
							_skipFrame[client] = true;
						}
						else _skipFrame[client] = false;
						if (!_warnd[client] && (GetGameTickCount() - g_Menu_Goto_iWarnMsg[client]) > 5)
						{
							_warnd[client] = true;
							PrintToChat(client, "[SM] Unable to sync movement flags for this (%d) tick. Prolly that after split, a movement can be incorrect.", g_iTicks[client] + 4);
							ClientCommand(client, "playgamesound common/bugreporter_failed.wav");
						}
					}
					else if (_curTick[client] != g_iTicks[client])
					{
						_warnd[client] = false;
						g_Menu_Goto_iWarnMsg[client] = 0;
					}
					SetEntProp(client, Prop_Send, "m_duckUntilOnGround", plrFlags & (1 << 2) ? 1 : 0);
				}
				TeleportEntity(client, NULL_VECTOR, GetConVarBool(g_ConVar_AllowFreeAngle) || mask & IN_FREE_ANGLE ? NULL_VECTOR : fAngles, NULL_VECTOR);
				return Plugin_Continue;
			}
			
			if (mask & IN_FORWARD) fVelocity[0] += PLAYER_VEL;
			if (mask & IN_BACK) fVelocity[0] -= PLAYER_VEL;
			if (mask & IN_MOVERIGHT) fVelocity[1] += PLAYER_VEL;
			if (mask & IN_MOVELEFT) fVelocity[1] -= PLAYER_VEL;
			if (item > 0) FakeClientCommand(client, "use %s", g_Items[item]);
			if (mask & IN_IDLE) ST_Idle(client);
			if (mask & IN_TAKEOVER) ST_Idle(client, true);
			if (buttons & IN_ATTACK) g_bIsClientFired[client] = true;
			else g_bIsClientFired[client] = false;
			if (client == 1 && GetConVarBool(g_ConVar_AllowHostInputs) && !IsDedicatedServer() && g_iTicks[client] + 1 < g_iTicksTotal[client])
			{
				new next = GetArrayCell(g_hButtons[client], g_iTicks[client] + 1);
				if (next & IN_USE) ServerCommand("+use");
				else ServerCommand("-use");
				if (next & IN_ATTACK) ServerCommand("+attack");
				else ServerCommand("-attack");
				if (next & IN_DUCK) ServerCommand("+duck");
				else ServerCommand("-duck");
			}
			TeleportEntity(client, NULL_VECTOR, GetConVarBool(g_ConVar_AllowFreeAngle) || mask & IN_FREE_ANGLE ? NULL_VECTOR : fAngles, NULL_VECTOR);
			vel[0] = fVelocity[0];
			vel[1] = fVelocity[1];
			buttons |= mask;
			g_iTicks[client]++;
			
			decl String:sFileName[64], String:sKeyValue[128]; sFileName = g_sFileName[client];
			new ticks = g_iTicks[client] + 3;
			Call_StartForward(g_hOnPlayLine);
			Call_PushCell(client);
			Call_PushString(sFileName);
			Call_PushCell(ticks);
			Call_PushCell(mask);
			Call_Finish();
			Format(sKeyValue, sizeof(sKeyValue), "if (\"OnPlayLine\" in getroottable()) OnPlayLine(self, \"%s\", %d, %d)", sFileName, ticks, mask);
			SetVariantString(sKeyValue);
			AcceptEntityInput(client, "RunScriptCode");
		}
		else
		{
			g_bIsApplyPlayerAction[client] = false;
			decl String:sFileName[64], String:sKeyValue[128]; sFileName = g_sFileName[client];
			PrintToServer("[SM] %N's playback \"%s\" is finished.", client, sFileName);
			Call_StartForward(g_hOnPlayEnd);
			Call_PushCell(client);
			Call_PushString(sFileName);
			Call_Finish();
			Format(sKeyValue, sizeof(sKeyValue), "if (\"OnPlayEnd\" in getroottable()) OnPlayEnd(self, \"%s\")", sFileName);
			SetVariantString(sKeyValue);
			AcceptEntityInput(client, "RunScriptCode");
			if (g_Menu_Active[client]) ShowMenu(client);
			if (client == 1) RevokeHostInputs();
		}
	}
	return Plugin_Continue;
}

public OnPlayerRunCmdPost(int client)
{
	if (g_RecClient[client] && strlen(g_RecLine[client]) > 0)
	{
		if (g_RecFlags[client] && GetConVarBool(g_ConVar_AllowIDLE))
		{
			new String:sValue[BLOCK_COUNT][BLOCK_SIZE];
			new block_count = ExplodeString(g_RecLine[client], ":", sValue, BLOCK_COUNT, BLOCK_SIZE);
			Format(sValue[0], BLOCK_SIZE, "%d", g_RecFlags[client] |= StringToInt(sValue[0]));
			if (g_RecFlags[client] & IN_TAKEOVER)
			{
				decl Float:fAngles[3];
				GetClientEyeAngles(client, fAngles);
				Format(sValue[1], BLOCK_SIZE, "%.03f", fAngles[0]);
				Format(sValue[2], BLOCK_SIZE, "%.03f", fAngles[1]);
			}
			ImplodeStrings(sValue, block_count, ":", g_RecLine[client], BLOCKS_LEN);
			g_RecFlags[client] = 0;
		}
		WriteFileLine(g_RecFile[client], g_RecLine[client]);
	}
	else if (g_bIsApplyPlayerAction[client])
	{
		if (GetConVarInt(g_ConVar_Debug) == client || g_Menu_eDebug[client] == 2)
		{
			static int _curTick[MAXCLIENTS + 1] = {-1, ...};
			if (_curTick[client] != g_iTicks[client])
			{
				_curTick[client] = g_iTicks[client];
				decl Float:fVel[3], Float:fVel2D[3], String:sFileData[BLOCK_SIZE], String:sValue[3][16], String:sDebugInfo[128];
				new Float:fAngles[3], idx = g_Menu_Goto[client] ? g_iTicks[client] : g_iTicks[client] - 1, mask = GetArrayCell(g_hButtons[client], idx), item = GetArrayCell(g_hWeapons[client], idx);
				new bool:exmode = GetConVarInt(g_ConVar_ExPlay) && !g_Menu_bLegacy[client] && GetArrayString(g_hOrigin[client], idx, sFileData, BLOCK_SIZE) > 0 && ExplodeString(sFileData, ",", sValue, 3, 16) == 3;
				fAngles[0] = GetArrayCell(g_hAngles[client][0], idx);
				fAngles[1] = GetArrayCell(g_hAngles[client][1], idx);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel); fVel2D = fVel; fVel2D[2] = 0.0;
				IntToString(GetEntProp(client, Prop_Send, "m_fFlags"), sDebugInfo, sizeof(sDebugInfo));
				if (g_Menu_Goto[client] && GetArrayString(g_hFlags[client], idx, sFileData, BLOCK_SIZE) > 0) Format(sDebugInfo, sizeof(sDebugInfo), "%s:%d", sDebugInfo, StringToInt(sFileData));
				Format(sDebugInfo, sizeof(sDebugInfo), "%d >> %d:%.03f:%.03f:%d%s | VEL: %.03f | UPS: %.03f | %s | %N | %s", idx + 4, mask, fAngles[0], fAngles[1], item, exmode ? ":EXMODE" : "", GetVectorLength(fVel), GetVectorLength(fVel2D), sDebugInfo, client, g_sFileName[client]);
				if (GetConVarInt(g_ConVar_Debug) == client) PrintToServer(sDebugInfo);
				else if (g_Menu_eDebug[client] == 2) PrintToConsole(client, sDebugInfo);
			}
		}
	}
	if (g_Menu_eDebug[client] == 1)
	{
		decl String:sKeyValue[256], Float:fVel[3], Float:fVel2D[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel); fVel2D = fVel; fVel2D[2] = 0.0;
		Format(sKeyValue, sizeof(sKeyValue), "g_STLib.Vars.HUD.Fields.debug.dataval = \"UPS:       %.03f\\nVEL:        %.03f\"", GetVectorLength(fVel2D), GetVectorLength(fVel));
		SetVariantString(sKeyValue);
		AcceptEntityInput(client, "RunScriptCode");
		Format(sKeyValue, sizeof(sKeyValue), "g_STLib.Vars.HUD.Fields.debug.dataval += \"\\nLine:       ");
		if (g_bIsApplyPlayerAction[client])
		{
			decl String:sTime[16], String:sFileData[BLOCK_SIZE];
			new tick = g_Menu_Goto[client] ? g_iTicks[client] + 1: g_iTicks[client];
			GetDisplayTime(sTime, sizeof(sTime), tick);
			Format(sKeyValue, sizeof(sKeyValue), "%s%d / %d (%s)%s\"", sKeyValue, tick + 3, g_iTicksTotal[client] + 3, sTime, !GetArrayString(g_hOrigin[client], g_Menu_Goto[client] ? g_iTicks[client] : g_iTicks[client] - 1, sFileData, BLOCK_SIZE) || g_Menu_bLegacy[client] || !GetConVarInt(g_ConVar_ExPlay) ? " LEGACY" : "");
		}
		else StrCat(sKeyValue, sizeof(sKeyValue), "N/A\"");
		SetVariantString(sKeyValue);
		AcceptEntityInput(client, "RunScriptCode");
		Format(sKeyValue, sizeof(sKeyValue), "g_STLib.Vars.HUD.Fields.debug.dataval += \"\\nFlags:      %d", GetEntProp(client, Prop_Send, "m_fFlags"));
		if (g_bIsApplyPlayerAction[client] && g_Menu_Goto[client])
		{
			decl String:sFileData[8];
			if (GetArrayString(g_hFlags[client], g_iTicks[client], sFileData, BLOCK_SIZE) > 0)
			{
				Format(sKeyValue, sizeof(sKeyValue), "%s:%d", sKeyValue, StringToInt(sFileData));
			}
		}
		StrCat(sKeyValue, sizeof(sKeyValue), "\"");
		SetVariantString(sKeyValue);
		AcceptEntityInput(client, "RunScriptCode");
		int mask;
		if (g_bIsApplyPlayerAction[client]) mask = GetArrayCell(g_hButtons[client], g_Menu_Goto[client] ? g_iTicks[client] : g_iTicks[client] - 1);
		else mask = GetClientButtons(client);
		Format(sKeyValue, sizeof(sKeyValue), "g_STLib.Vars.HUD.Fields.debug2.dataval = \"\\n\\n\\n\\n\\nButtons:  %d", mask);
		if (mask)
		{
			decl String:sName[2][16];
			for (int i = 1; i <= 29; i++)
			{
				if (mask & StringToInt(g_Buttons[i]))
				{
					ExplodeString(g_Buttons[i], ":", sName, 2, 16);
					StrCat(sKeyValue, sizeof(sKeyValue), sName[1]);
				}
			}
		}
		StrCat(sKeyValue, sizeof(sKeyValue), "\"");
		SetVariantString(sKeyValue);
		AcceptEntityInput(client, "RunScriptCode");
		SetVariantString("HUDSetLayout(g_STLib.Vars.HUD)");
		AcceptEntityInput(client, "RunScriptCode");
	}
}

public Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	if (g_RecClient[client]) g_RecFlags[client] |= StrEqual(name, "player_bot_replace") ? IN_IDLE : IN_TAKEOVER;
}

public Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bIsApplyPlayerAction[client])
	{
		new entity = GetEventInt(event, "targetid");
		decl String:sName[64];
		GetEntityClassname(entity, sName, sizeof(sName));
		if (StrContains(sName, "prop_door_rotating") != -1)
		{
			if (!GetEntProp(entity, Prop_Send, "m_eDoorState")) AcceptEntityInput(entity, "PlayerOpen", client);
			else AcceptEntityInput(entity, "PlayerClose", client);
		}
	}
}

public Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bIsApplyPlayerAction[client] && !g_bIsClientFired[client] && !IsFakeClient(client) && !g_Menu_Goto[client])
	{
		decl String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "pistol"))
		{
			new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (GetEntProp(entity, Prop_Send, "m_hasDualWeapons"))
			{
				if (GetEntProp(entity, Prop_Send, "m_iClip1")%2) ClientCommand(client, "playgamesound Pistol_Silver.Fire");
				else ClientCommand(client, "playgamesound Pistol.DualFire");
			}
			else ClientCommand(client, "playgamesound Pistol.Fire");
		}
		else if (StrEqual(sWeapon, "pistol_magnum")) ClientCommand(client, "playgamesound Magnum.Fire");
		//else if (StrEqual(sWeapon, "pumpshotgun")) ClientCommand(client, "playgamesound Shotgun.Fire");
		//else if (StrEqual(sWeapon, "shotgun_chrome")) ClientCommand(client, "playgamesound Shotgun_Chrome.Fire");
		//else if (StrEqual(sWeapon, "shotgun_spas")) ClientCommand(client, "playgamesound AutoShotgun_Spas.Fire");
		//else if (StrEqual(sWeapon, "autoshotgun")) ClientCommand(client, "playgamesound AutoShotgun.Fire");
		else if (StrEqual(sWeapon, "grenade_launcher")) ClientCommand(client, "playgamesound GrenadeLauncher.Fire");
		else if (StrEqual(sWeapon, "smg")) ClientCommand(client, "playgamesound SMG.Fire");
		else if (StrEqual(sWeapon, "smg_silenced")) ClientCommand(client, "playgamesound SMG_Silenced.Fire");
		else if (StrEqual(sWeapon, "rifle")) ClientCommand(client, "playgamesound Rifle.Fire");
		else if (StrEqual(sWeapon, "rifle_ak47")) ClientCommand(client, "playgamesound AK47.Fire");
		else if (StrEqual(sWeapon, "rifle_desert")) ClientCommand(client, "playgamesound Rifle_Desert.Fire");
		else if (StrEqual(sWeapon, "rifle_m60")) ClientCommand(client, "playgamesound M60.Fire");
		else if (StrEqual(sWeapon, "hunting_rifle")) ClientCommand(client, "playgamesound HuntingRifle.Fire");
		else if (StrEqual(sWeapon, "sniper_military")) ClientCommand(client, "playgamesound Sniper_Military.Fire");
		else if (StrEqual(sWeapon, "melee")) ClientCommand(client, "playgamesound Melee.Miss");
	}
}

//========================================================================================================================
//Cmds
//========================================================================================================================

stock ForceStop(client = 0)
{
	for (int i = client ? client : 1; i <= (client ? client : MaxClients); i++)
	{
		if (g_RecClient[i])
		{
			PrintToServer("[SM] Movement \"%s\" has been created (by %N). Recording time: %.03f, game frames: %d.", g_sFileName[i], i, GetGameTime() - g_RecTime[i] + GetGameFrameTime(), GetGameTickCount() - g_RecFrames[i] + 1);
			g_RecClient[i] = false;
			CloseHandle(g_RecFile[i]);
		}
		else g_bIsApplyPlayerAction[i] = false;
		if (g_Menu_Goto[i] || g_Menu_bDelay[i])
		{
			g_Menu_Goto[i] = false;
			g_Menu_bDelay[i] = false;
			if (IsClientInGame(i) && GetEntityMoveType(i) == MOVETYPE_NONE) SetEntityMoveType(i, MOVETYPE_WALK);
		}
		if (g_Menu_Active[i]) ShowMenu(i);
	}
	RevokeHostInputs();
}

stock RevokeHostInputs(dont_check_cvar = false)
{
	if ((dont_check_cvar || GetConVarBool(g_ConVar_AllowHostInputs)) && !IsDedicatedServer())
	{
		ServerCommand("-use");
		ServerCommand("-attack");
		ServerCommand("-duck");
	}
}

public ConVarChanged_RevokeHostInputs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StringToInt(newValue))
	{
		RevokeHostInputs(true);
	}
}

public OnMapEnd()
{
	ForceStop();
}

public OnPluginEnd()
{
	if (g_Menu_eDebug[1] == 1)
	{
		SetVariantString("if (!(\"g_ST\" in getroottable())) ::g_STLib <- {Vars = {HUD = {Fields = {}}}}");
		AcceptEntityInput(0, "RunScriptCode");
		SetVariantString("if (\"debug\" in g_STLib.Vars.HUD.Fields) {g_STLib.Vars.HUD.Fields.debug.dataval = \"\"; g_STLib.Vars.HUD.Fields.debug2.dataval = \"\"}");
		AcceptEntityInput(0, "RunScriptCode");
	}
}

public Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_Menu_eDebug[1] == 1)
	{
		SetVariantString("if (!(\"g_ST\" in getroottable())) ::g_STLib <- {Vars = {HUD = {Fields = {}}}}");
		AcceptEntityInput(0, "RunScriptCode");
		SetVariantString("::g_STLib.Vars.HUD.Fields.debug <- {slot = g_MapScript.HUD_MID_BOX, dataval = \"\", flags = g_MapScript.HUD_FLAG_NOBG | g_MapScript.HUD_FLAG_ALIGN_LEFT}; HUDPlace(g_MapScript.HUD_MID_BOX, 0.43, 0.42, 0.5, 0.3);");
		AcceptEntityInput(0, "RunScriptCode");
		SetVariantString("::g_STLib.Vars.HUD.Fields.debug2 <- {slot = g_MapScript.HUD_FAR_LEFT, dataval = \"\", flags = g_MapScript.HUD_FLAG_NOBG}; HUDPlace(g_MapScript.HUD_FAR_LEFT, 0.43, 0.42, 0.5, 0.3);");
		AcceptEntityInput(0, "RunScriptCode");
		SetVariantString("if (!(\"MutationState\" in g_ModeScript)) Say(null, \"[SM] ScriptedMode must be activated to use screen messages!\", false)");
		AcceptEntityInput(0, "RunScriptCode");
	}
}

public Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ForceStop();
}

public OnClientDisconnect(int client)
{
	ForceStop(client);
}

public Action:Cmd_Stop(client, args)
{
	decl String:sArg[4];
	GetCmdArg(1, sArg, sizeof(sArg));
	ForceStop(StringToInt(sArg));
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_GetFrame(client, args)
{
	if (args > 0)
	{
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
	}
	else if (!client) client = 1;
	if (client <= 0 || client > MaxClients || !g_bIsApplyPlayerAction[client]) return Plugin_Handled;
	PrintToServer("[SM] %N's playback \"%s\" line: %d", client, g_sFileName[client], g_Menu_Goto[client] ? g_iTicks[client] + 4 : g_iTicks[client] + 3);
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_Goto(client, args)
{
	if (client == 0 && !IsClientInGame((client = 1))) return Plugin_Handled;
	if (g_Menu_bDelay[client]) return Plugin_Handled;
	decl String:sArg[8], String:sArg2[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	if (!g_bIsApplyPlayerAction[client] && !strlen(sArg2) && strlen(g_sGotoPrevFile[client])) sArg2 = g_sGotoPrevFile[client];
	if (!g_bIsApplyPlayerAction[client] || strlen(sArg2))
	{
		if (!strlen(sArg2) || StrEqual(sArg2, "default")) Format(sArg2, sizeof(sArg2), client > 1 && GetConVarBool(g_ConVar_FFA) ? "default_%d" : "default", client);
		if (!g_bIsApplyPlayerAction[client] || !StrEqual(sArg2, g_sFileName[client]))
		{
			ForceStop(client);
			SetConVarString(g_ConVar_ForceFile, sArg2);
			SetConVarInt(g_ConVar_Play, client);
		}
	}
	if (!g_iTicksTotal[client]) return Plugin_Handled;
	args = StringToInt(sArg) - 4;
	if (args < 0) args = 0;
	else if (args >= g_iTicksTotal[client]) args = g_iTicksTotal[client] - 1;
	if (g_Menu_Active[client])
	{
		if (g_bIsApplyPlayerAction[client] && !g_Menu_Goto[client])
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			if (!g_Menu_GotoUsage[client]) PrintHintText(client, "Press and hold [A] or [D] strafes to rewind or fast-forward.");
			ClientCommand(client, "playgamesound buttons/blip1.wav");
			if (client == 1) SetConVarFloat(FindConVar("host_timescale"), 1.0);
			g_Menu_Goto[client] = true;
			g_Menu_GotoUsage[client] = true;
			g_Menu_Goto_iWarnMsg[client] = 0;
		}
		g_Menu_iGotoTicks[client] = args;
		ShowMenu(client);
	}
	g_iTicks[client] = args;
	g_sGotoPrevFile[client] = g_sFileName[client];
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_Tracker(client, args)
{
	if (client == 0 && !IsClientInGame((client = 1))) return Plugin_Handled;
	static bool crosshair;
	decl String:sArg[64];
	GetCmdArg(0, sArg, sizeof(sArg));
	if (StrEqual(sArg, "st_mr_tracker_clear"))
	{
		crosshair = false;
		SetVariantString("DebugDrawClear()");
		AcceptEntityInput(client, "RunScriptCode");
		return Plugin_Handled;
	}
	GetCmdArg(1, sArg, sizeof(sArg));
	if (!strlen(sArg))
	{
		if (g_Menu_Active[client]) GetConVarString(g_ConVar_ForceFile, sArg, sizeof(sArg));
		if (g_bIsApplyPlayerAction[client]) sArg = g_sFileName[client];
	}
	if (!strlen(sArg) || StrEqual(sArg, "default")) Format(sArg, sizeof(sArg), client > 1 && GetConVarBool(g_ConVar_FFA) ? "default_%d" : "default", client);
	decl String:sFilePath[128];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/%s.txt", MR_DIR, sArg);
	if (FileExists(sFilePath))
	{
		new Handle:hFile = OpenFile(sFilePath, "r"), String:sValue[5][BLOCK_SIZE], String:sValuePrev[BLOCK_SIZE], bool:toggle, count;
		decl String:sFileLine[BLOCKS_LEN], String:sKeyValue[BLOCKS_LEN], Float:vecOrigin[3], Float:vecAng[3];
		for (count = 0; count < 3; count++)
		{
			ReadFileLine(hFile, sFileLine, sizeof(sFileLine));
			ExplodeString(sFileLine, ":", sValue, 4, 16);
			if (StrEqual(sValue[0], "Origin"))
			{
				vecOrigin[0] = StringToFloat(sValue[1]);
				vecOrigin[1] = StringToFloat(sValue[2]);
				vecOrigin[2] = StringToFloat(sValue[3]);
			}
		}
		if (!crosshair && client == 1 && !g_bIsApplyPlayerAction[client])
		{
			crosshair = true;
			GetClientEyePosition(client, vecAng);
			SubtractVectors(vecOrigin, vecAng, vecAng);
			GetVectorAngles(vecAng, vecAng);
			TeleportEntity(client, NULL_VECTOR, vecAng, NULL_VECTOR);
		}
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sFileLine, sizeof(sFileLine)))
		{
			count++;
			if (client > 1) continue;
			ExplodeString(sFileLine, ":", sValue, 5, BLOCK_SIZE);
			if (!strlen(sValue[4])) continue;
			if (!strlen(sValuePrev))
			{
				sValuePrev = sValue[4];
				continue;
			}
			Format(sKeyValue, sizeof(sKeyValue), "DebugDrawLine(Vector(%s), Vector(%s), %s, false, 1e4)", sValuePrev, sValue[4], toggle ? "255, 255, 0" : "0, 0, 255");
			SetVariantString(sKeyValue);
			AcceptEntityInput(client, "RunScriptCode");
			sValuePrev = sValue[4];
			sValue[4][0] = 0;
			toggle = !toggle;
		}
		delete hFile;
		
		decl String:sTime[16], String:sFileData[32];
		GetDisplayTime(sTime, sizeof(sTime), count - 3);
		FormatTime(sFileData, sizeof(sFileData), "%d %B, %Y @ %H:%M:%S", GetFileTime(sFilePath, FileTime_LastChange));
		PrintToConsole(client, "Movement Info");
		PrintToConsole(client, "\tName\t\t: %s", sArg);
		PrintToConsole(client, "\tDuration\t: %s (%.03f)", sTime, GetGameFrameTime()*(count - 3));
		PrintToConsole(client, "\tLines\t\t: %d", count);
		PrintToConsole(client, "\tTicks\t\t: %d", count - 3);
		PrintToConsole(client, "\tFile path\t: %s", sFilePath);
		PrintToConsole(client, "\tSize\t\t: %.03f KB", FileSize(sFilePath)/1000.0);
		PrintToConsole(client, "\tTimestamp\t: %s", sFileData);
	}
	else PrintToServer("[SM] ERROR: File \"%s\" does not exist!", sFilePath);
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_Save(client, args)
{
	if (client == 0 && !IsClientInGame((client = 1))) return Plugin_Handled;
	if (g_RecClient[client]) ForceStop(client);
	decl String:sFilePath[128];
	Format(sFilePath, sizeof(sFilePath), client > 1 && GetConVarBool(g_ConVar_FFA) ? "default_%d" : "default", client);
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/%s.txt", MR_DIR, sFilePath);
	if (FileExists(sFilePath))
	{
		decl String:sMapName[32], String:sFileName[32], String:sCopyPath[128];
		GetCurrentMap(sMapName, sizeof(sMapName));
		SplitString(sMapName, "_", sMapName, sizeof(sMapName));
		FormatTime(sFileName, sizeof(sFileName), "%H-%M-%S", GetTime());
		Format(sFileName, sizeof(sFileName), "backup_%s_%s.txt", sMapName, sFileName);
		BuildPath(Path_SM, sCopyPath, sizeof(sCopyPath), "%s/%s", MR_DIR, sFileName);
		if (!FileExists(sCopyPath))
		{
			new Handle:hFile = OpenFile(sFilePath, "rb");
			new Handle:hCopy = OpenFile(sCopyPath, "wb");
			if (hCopy != INVALID_HANDLE)
			{
				decl buffer[128];
				while (!IsEndOfFile(hFile)) WriteFile(hCopy, buffer, ReadFile(hFile, buffer, sizeof(buffer), 2), 2);
				PrintToChat(client, "[SM] Saved as: %s", sFileName);
				PrintToServer("[SM] New movement at \"%s\", saved by %N", sCopyPath, client);
				delete hCopy;
			}
			delete hFile;
		}
	}
	else PrintToChat(client, "[SM] Nothing to save!");
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_MR(client, args)
{
	if (client == 0 && !IsClientInGame((client = 1))) return Plugin_Handled;
	g_Menu_Active[client] = false;
	new Handle:hTable = CreatePanel();
	decl String:sName[32]; Format(sName, sizeof(sName), "Movement Reader v%s\n \n", PLUGIN_VER);
	SetPanelTitle(hTable, sName);
	DrawPanelItem(hTable, "Record");
	DrawPanelItem(hTable, "Playback");
	DrawPanelItem(hTable, "Split");
	DrawPanelItem(hTable, "Fwd >>");
	DrawPanelItem(hTable, "Rew <<");
	DrawPanelItem(hTable, "Stop");
	DrawPanelItem(hTable, "Legacy Mode");
	DrawPanelText(hTable, "\n \n8. Exit");
	SendPanelToClient(hTable, client, MenuHandler, 300);
	CloseHandle(hTable);
	return Plugin_Handled;
}

public MenuHandler(Menu menu, MenuAction action, int client, int value)
{
	if (action == MenuAction_Cancel) return;
	if (value == 1)
	{
		if (!g_RecClient[client])
		{
			SetConVarInt(g_ConVar_Record, client);
			ClientCommand(client, "playgamesound buttons/bell1.wav");
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 2)
	{
		ForceStop(client);
		ResetConVar(g_ConVar_ForceFile);
		SetConVarInt(g_ConVar_Play, client);
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	else if (value == 3)
	{
		if (g_bIsApplyPlayerAction[client])
		{
			SetConVarInt(g_ConVar_Split, client);
			ClientCommand(client, "playgamesound buttons/bell1.wav");
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 4)
	{
		if (g_bIsApplyPlayerAction[client]) g_iTicks[client] += g_iTicksTotal[client] > g_iTicks[client] + 150 ? 150 : 0;
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 5)
	{
		if (g_bIsApplyPlayerAction[client]) g_iTicks[client] -= g_iTicks[client] - 150 > 0 ? 150 : 0;
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 6)
	{
		ForceStop(client);
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	else if (value == 7)
	{
		if (client == 1)
		{
			if (!GetConVarBool(g_ConVar_ExRecord))
			{
				SetConVarBool(g_ConVar_ExRecord, true);
				SetConVarBool(g_ConVar_ExPlay, true);
				ClientCommand(client, "playgamesound buttons/blip1.wav");
			}
			else
			{
				SetConVarBool(g_ConVar_ExRecord, false);
				SetConVarBool(g_ConVar_ExPlay, false);
				ClientCommand(client, "playgamesound buttons/button11.wav");
			}
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	FakeClientCommand(client, "stmr");
}

//============================================================
//============================================================

stock ShowMenu(client)
{
	Handle panel = CreatePanel();
	decl String:sName[64];
	new String:eDbg[][] = {"OFF", "Screen", "Console"};
	Format(sName, sizeof(sName), "MR v%s – Advanced Menu\n \n", PLUGIN_VER);
	SetPanelTitle(panel, sName);
	if (g_bIsApplyPlayerAction[client])
	{
		Format(sName, sizeof(sName), "Replay: %s", g_sFileName[client]);
		DrawPanelText(panel, sName);
		GetDisplayTime(sName, sizeof(sName), g_iTicksTotal[client]);
		Format(sName, sizeof(sName), "Duration: %s", sName);
		DrawPanelText(panel, sName);
	}
	else if (!g_RecClient[client])
	{
		GetConVarString(g_ConVar_ForceFile, sName, sizeof(sName));
		if (StrEqual(sName, "default")) Format(sName, sizeof(sName), client > 1 && GetConVarBool(g_ConVar_FFA) ? "default_%d" : "default", client);
		decl String:sFilePath[128];
		BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/%s.txt", MR_DIR, sName);
		if (FileExists(sFilePath) && !g_Menu_bDelay[client])
		{
			new Handle:hFile = OpenFile(sFilePath, "r"), count = -3;
			decl String:sFileLine[BLOCKS_LEN];
			while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sFileLine, sizeof(sFileLine))) count++;
			delete hFile;
			Format(sName, sizeof(sName), "Replay: %s", sName);
			DrawPanelText(panel, sName);
			GetDisplayTime(sName, sizeof(sName), count);
			Format(sName, sizeof(sName), "Duration: %s", sName);
			DrawPanelText(panel, sName);
		}
		else
		{
			DrawPanelText(panel, "Replay: N/A");
			DrawPanelText(panel, "Duration: N/A");
		}
	}
	else
	{
		Format(sName, sizeof(sName), "Replay: %s", g_sFileName[client]);
		DrawPanelText(panel, sName);
		DrawPanelText(panel, "Duration: N/A");
	}
	if (g_bIsApplyPlayerAction[client] && g_Menu_Goto[client])
	{
		Format(sName, sizeof(sName), "Line: %d / %d", g_Menu_iGotoTicks[client] + 4, g_iTicksTotal[client] + 3);
		DrawPanelText(panel, sName);
	}
	DrawPanelText(panel, "\n \n");
	
	if (g_bIsApplyPlayerAction[client]) sName = "Split";
	else if (g_RecClient[client] && client == 1) sName = "TimeScale";
	else sName = "Record";
	if (g_Menu_bDelay[client]) Format(sName, sizeof(sName), "Resume in... %.03f", GetConVarFloat(g_ConVar_TweakDelay) - (GetGameTime() - g_Menu_fDelayTime[client]));
	DrawPanelItem(panel, sName);
	DrawPanelItem(panel, "Play");
	if (g_Menu_GotoUsage[client])
	{
		Format(sName, sizeof(sName), "Goto (%d)", g_Menu_iGotoTicks[client] + 4);
		DrawPanelItem(panel, sName);
	}
	else if (g_bIsApplyPlayerAction[client] && !g_Menu_GotoUsage[client]) DrawPanelItem(panel, "Freeze");
	else DrawPanelItem(panel, "Goto");
	if (g_Menu_GotoUsage[client] && !g_RecClient[client] && !g_bIsApplyPlayerAction[client] && !g_Menu_bDelay[client]) DrawPanelItem(panel, "Reset");
	else DrawPanelItem(panel, "Stop");
	if (g_Menu_bLegacy[client]) DrawPanelItem(panel, "Legacy Mode: ON");
	else DrawPanelItem(panel, "Legacy Mode: OFF");
	Format(sName, sizeof(sName), "Debug Mode: %s", eDbg[g_Menu_eDebug[client]]);
	DrawPanelItem(panel, sName);
	DrawPanelItem(panel, "Tracker");
	DrawPanelItem(panel, "Save");
	DrawPanelText(panel, "\n \n");
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, MenuHandler_AdvMenu, 45);
	delete panel;
}

public Action:TimerMenuUpdate(Handle:timer, any:data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == 1 && g_Menu_Active[i] && IsClientInGame(i))
		{
			int buttons = GetClientButtons(i);
			if (buttons & IN_USE && buttons & IN_RELOAD)
			{
				FakeClientCommand(i, "st_mr_tracker_clear");
			}
		}
		if (g_Menu_Active[i]) ShowMenu(i);
	}
	return Plugin_Continue;
}

public MenuHandler_AdvMenu(Menu menu, MenuAction action, int client, int value)
{
	if (action == MenuAction_Cancel) return;
	if (value == 1)
	{
		if (!g_RecClient[client])
		{
			g_Menu_fDelayTime[client] = GetGameTime() + GetGameFrameTime();
			g_Menu_bDelay[client] = true;
			SetEntityMoveType(client, MOVETYPE_NONE);
			// SetEntityFlags(client, GetEntityFlags(client) | FL_FROZEN);
			RevokeHostInputs();
			if (client == 1) SetConVarFloat(FindConVar("host_timescale"), 1.0);
		}
		else if (client == 1)
		{
			if (GetConVarFloat(FindConVar("host_timescale")) < 1.0) SetConVarFloat(FindConVar("host_timescale"), 1.0);
			else SetConVarFloat(FindConVar("host_timescale"), GetConVarFloat(g_ConVar_TweakTimeScale));
			ClientCommand(client, "playgamesound buttons/blip1.wav");
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 2)
	{
		if (!g_Menu_bDelay[client])
		{
			if (g_Menu_Goto[client])
			{
				g_Menu_Goto[client] = false;
				if (GetEntityMoveType(client) == MOVETYPE_NONE) SetEntityMoveType(client, MOVETYPE_WALK);
			}
			else
			{
				ForceStop(client);
				SetConVarInt(g_ConVar_Play, client);
				if (!g_Menu_bLegacy[client]) g_iTicks[client] = g_Menu_iGotoTicks[client];
			}
			if (!g_bIsApplyPlayerAction[client])
			{
				ClientCommand(client, "playgamesound buttons/button11.wav");
				ShowMenu(client);
				return;
			}
			if (client == 1) SetConVarFloat(FindConVar("host_timescale"), 1.0);
			if (GetConVarBool(g_ConVar_AllowHelpers))
			{
				SetVariantString("if (\"SpeedrunStart\" in getroottable()) SpeedrunStart()");
				AcceptEntityInput(client, "RunScriptCode");
				ServerCommand("nb_delete_all infected");	//helpful if everytime zombies are re-created by the external scripts
			}
			ClientCommand(client, "playgamesound buttons/blip1.wav");
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 3)
	{
		if (!g_Menu_bDelay[client])
		{
			if (!g_Menu_Goto[client])
			{
				if (!g_bIsApplyPlayerAction[client])
				{
					ForceStop(client);
					SetConVarInt(g_ConVar_Play, client);
					if (!g_bIsApplyPlayerAction[client] || !g_iTicksTotal[client])
					{
						ClientCommand(client, "playgamesound buttons/button11.wav");
						ShowMenu(client);
						return;
					}
				}
				SetEntityMoveType(client, MOVETYPE_NONE);
				if (!g_Menu_GotoUsage[client]) PrintHintText(client, "Press and hold [A] or [D] strafes to rewind or fast-forward.");
				ClientCommand(client, "playgamesound buttons/blip1.wav");
				if (client == 1) SetConVarFloat(FindConVar("host_timescale"), 1.0);
				g_iTicks[client] = g_Menu_GotoUsage[client] ? g_Menu_iGotoTicks[client] : g_iTicks[client];
				if (g_iTicks[client] >= g_iTicksTotal[client]) g_iTicks[client] = g_iTicksTotal[client] - 1;
				g_Menu_iGotoTicks[client] = g_iTicks[client];
				g_Menu_Goto[client] = true;
				g_Menu_GotoUsage[client] = true;
				g_Menu_Goto_iWarnMsg[client] = 0;
			}
			else
			{
				if (GetEntityMoveType(client) == MOVETYPE_NONE) SetEntityMoveType(client, MOVETYPE_WALK);
				if (client == 1) SetConVarFloat(FindConVar("host_timescale"), GetConVarFloat(g_ConVar_TweakTimeScale));
				g_Menu_Goto[client] = false;
			}
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	else if (value == 4)
	{
		if (!g_RecClient[client] && !g_bIsApplyPlayerAction[client] && !g_Menu_bDelay[client])
		{
			g_Menu_iGotoTicks[client] = 0;
			g_Menu_GotoUsage[client] = false;
		}
		if (client == 1) SetConVarFloat(FindConVar("host_timescale"), 1.0);
		ForceStop(client);
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	else if (value == 5)
	{
		g_Menu_bLegacy[client] = !g_Menu_bLegacy[client];
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	else if (value == 6)
	{
		g_Menu_eDebug[client]++;
		g_Menu_eDebug[client] = g_Menu_eDebug[client] > 2 ? 0 : g_Menu_eDebug[client];
		if (client > 1 && g_Menu_eDebug[client] == 1) g_Menu_eDebug[client] = 2;
		if (g_Menu_eDebug[client] == 1)
		{
			SetVariantString("if (!(\"g_ST\" in getroottable())) ::g_STLib <- {Vars = {HUD = {Fields = {}}}}");
			AcceptEntityInput(client, "RunScriptCode");
			SetVariantString("::g_STLib.Vars.HUD.Fields.debug <- {slot = g_MapScript.HUD_MID_BOX, dataval = \"\", flags = g_MapScript.HUD_FLAG_NOBG | g_MapScript.HUD_FLAG_ALIGN_LEFT}; HUDPlace(g_MapScript.HUD_MID_BOX, 0.43, 0.42, 0.5, 0.3);");
			AcceptEntityInput(client, "RunScriptCode");
			SetVariantString("::g_STLib.Vars.HUD.Fields.debug2 <- {slot = g_MapScript.HUD_FAR_LEFT, dataval = \"\", flags = g_MapScript.HUD_FLAG_NOBG}; HUDPlace(g_MapScript.HUD_FAR_LEFT, 0.43, 0.42, 0.5, 0.3);");
			AcceptEntityInput(client, "RunScriptCode");
			SetVariantString("if (!(\"MutationState\" in g_ModeScript)) Say(null, \"[SM] ScriptedMode must be activated to use screen messages!\", false)");
			AcceptEntityInput(client, "RunScriptCode");
		}
		else if (client == 1)
		{
			SetVariantString("if (!(\"g_ST\" in getroottable())) ::g_STLib <- {Vars = {HUD = {Fields = {}}}}");
			AcceptEntityInput(client, "RunScriptCode");
			// SetVariantString("if (\"debug\" in g_STLib.Vars.HUD.Fields) {delete g_STLib.Vars.HUD.Fields.debug; delete g_STLib.Vars.HUD.Fields.debug2}");
			SetVariantString("if (\"debug\" in g_STLib.Vars.HUD.Fields) {g_STLib.Vars.HUD.Fields.debug.dataval = \"\"; g_STLib.Vars.HUD.Fields.debug2.dataval = \"\"}");
			AcceptEntityInput(client, "RunScriptCode");
		}
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	else if (value == 7)
	{
		if (client == 1)
		{
			static int _totalTaps;
			if (!(_totalTaps%5)) PrintHintText(client, "Hold [E] + [R] buttons (use and reload) to remove all tracks.");
			_totalTaps++;
		}
		FakeClientCommand(client, "st_mr_tracker");
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	else if (value == 8)
	{
		FakeClientCommand(client, "st_mr_save");
		ClientCommand(client, "playgamesound Buttons.snd4");
	}
	else if (value == 9)
	{
		g_Menu_Active[client] = false;
		if (g_Menu_bDelay[client])
		{
			g_Menu_bDelay[client] = false;
			if (GetEntityMoveType(client) == MOVETYPE_NONE) SetEntityMoveType(client, MOVETYPE_WALK);
		}
		ClientCommand(client, "playgamesound buttons/button11.wav");
		return;
	}
	ShowMenu(client);
}

public Action:Cmd_MR2(client, args)
{
	if (client == 0 && !IsClientInGame((client = 1))) return Plugin_Handled;
	g_Menu_Active[client] = true;
	ShowMenu(client);
	return Plugin_Handled;
}

//========================================================================================================================
//Local Wraps
//========================================================================================================================

stock bool:IsPlayerRecFile(const char[] sName)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_RecClient[i] && StrEqual(sName, g_sFileName[i]))
		{
			return true;
		}
	}
	return false;
}

stock GetDisplayTime(char[] time, int size, int frames)
{
	decl String:sTime[16], String:sFrac[2][8];
	FormatTime(sTime, sizeof(sTime), "%M:%S", RoundToFloor(GetGameFrameTime()*frames));
	FloatToString(FloatFraction(GetGameFrameTime()*frames), sFrac[0], 8);
	ExplodeString(sFrac[0], ".", sFrac, 2, 4);
	Format(time, size, "%s,%s", sTime, sFrac[1]);
}

//========================================================================================================================
//Tools ScMp
//========================================================================================================================

stock bool:ST_Idle(client, bool:bType = false)
{
	if (IsPlayer(client) && !IsPlayerABot(client))
	{
		if (bType)
		{
			if (GetClientTeam(client) == 1)
			{
				SDKCall(g_hTakeOverBot, client);
				return true;
			}
		}
		else
		{
			if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsPlayerABot(i) && IsPlayerAlive(i) && client != i && GetClientTeam(i) == 2)
					{
						SDKCall(g_hGoAwayFromKeyboard, client);
						PrintToChatAll("%N is now idle.", client);
						return true;
					}
				}
			}
		}
	}
	return false;
}

//============================================================
//============================================================

stock bool:IsPlayer(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

//============================================================
//============================================================

stock bool:IsPlayerABot(client)
{
	if (GetEntityFlags(client) & FL_FAKECLIENT)
	{
		return true;
	}
	return false;
}