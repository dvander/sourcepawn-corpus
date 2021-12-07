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
*							Update #3: Added some TAS features for convenient interaction with movements. Now playback can match
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
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VER "1.3.13"
#define MAXCLIENTS 32
#define BLOCKS_LEN 128
#define BLOCK_SIZE 64
#define BLOCK_COUNT 6
#define PLAYER_VEL 450.0
#define MR_DIR "plugins/disabled/movements"
#define ITEMS_COUNT 27
#define IN_IDLE			(1 << 26)
#define IN_TAKEOVER	(1 << 27)

new Handle:g_ConVar_ForceFile;
new Handle:g_ConVar_Play;
new Handle:g_ConVar_Record;
new Handle:g_ConVar_Split;
new Handle:g_ConVar_NoTeleport;
new Handle:g_ConVar_Stop;
new Handle:g_ConVar_ExRecord;
new Handle:g_ConVar_ExPlay;
new Handle:g_ConVar_Debug;

new Handle:g_RecFile;
new g_RecClient;
new g_RecFrames;
new Float:g_RecTime;

new bool:g_bIsApplyPlayerAction[MAXCLIENTS + 1];
new bool:g_bIsClientFired[MAXCLIENTS + 1];
new g_iTicks[MAXCLIENTS + 1];
new g_iTicksTotal[MAXCLIENTS + 1];
new Handle:g_hButtons[MAXCLIENTS + 1];
new Handle:g_hAngles[MAXCLIENTS + 1][2];
new Handle:g_hWeapons[MAXCLIENTS + 1];
new Handle:g_hOrigin[MAXCLIENTS + 1];
new Handle:g_hVelocity[MAXCLIENTS + 1];
new String:g_sStartData[MAXCLIENTS + 1][128];
new String:g_sFileName[MAXCLIENTS + 1][64];

new Handle:g_hTakeOverBot;
new Handle:g_hGoAwayFromKeyboard;

new Handle:g_hOnPlayEnd;
new Handle:g_hOnPlayLine;

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
	g_ConVar_Debug = CreateConVar("st_mr_debug", "0", "Enable debug mode.", FCVAR_NOTIFY);
	RegConsoleCmd("st_mr_stop", Cmd_Stop, "Stop any record/playback.");
	RegConsoleCmd("st_mr_get_frame", Cmd_GetFrame, "Get current playback frame from the file for debugging.");
	RegConsoleCmd("st_mr_goto", Cmd_Goto, "Move to the specified file line during playback (w/o args – first line).");
	RegConsoleCmd("stmr", Cmd_MR, "Show Movement Reader menu.");
	
	HookConVarChange(g_ConVar_Record, ConVarChanged);
	HookConVarChange(g_ConVar_Play, ConVarChanged);
	HookConVarChange(g_ConVar_Split, ConVarChanged);
	HookConVarChange(g_ConVar_Stop, ConVarChanged);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("weapon_fire", Event_WeaponFire);
	
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
			if (g_RecClient == 0)
			{
				decl String:sFilePath[128];
				BuildPath(Path_SM, sFilePath, sizeof(sFilePath), MR_DIR);
				if (!DirExists(sFilePath)) CreateDirectory(sFilePath, 0, true);
				BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/default.txt", MR_DIR);
				if ((g_RecFile = OpenFile(sFilePath, "w")) != INVALID_HANDLE)
				{
					g_bIsApplyPlayerAction[client] = false;
					g_RecClient = client;
					g_RecTime = GetGameTime();
					g_RecFrames = GetGameTickCount();
					decl Float:fOrigin[3], Float:fAngles[3], Float:fVelocity[3];
					GetClientAbsOrigin(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
					WriteFileLine(g_RecFile, "Origin:%.03f:%.03f:%.03f", fOrigin[0], fOrigin[1], fOrigin[2]);
					WriteFileLine(g_RecFile, "Angles:%.03f:%.03f:%.03f", fAngles[0], fAngles[1], fAngles[2]);
					WriteFileLine(g_RecFile, "Velocity:%.03f:%.03f:%.03f", fVelocity[0], fVelocity[1], fVelocity[2]);
					PrintToServer("[SM] Recording %N's movement...", client);
				}
			}
		}
		else if (g_ConVar_Play == convar)
		{
			decl String:sFileName[64];
			GetConVarString(g_ConVar_ForceFile, sFileName, sizeof(sFileName));
			if (g_RecClient == 0 || (!StrEqual(sFileName, "default") && g_RecClient != client))
			{
				decl String:sFilePath[128];
				BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "%s/%s.txt", MR_DIR, sFileName);
				if (FileExists(sFilePath))
				{
					new Handle:hFile = OpenFile(sFilePath, "r"), block_count = GetConVarBool(g_ConVar_ExPlay) ? BLOCK_COUNT : 4;
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
					}
					ClearArray(g_hButtons[client]);
					ClearArray(g_hAngles[client][0]);
					ClearArray(g_hAngles[client][1]);
					ClearArray(g_hWeapons[client]);
					ClearArray(g_hOrigin[client]);
					ClearArray(g_hVelocity[client]);
					while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sFileLine, sizeof(sFileLine)))
					{
						ExplodeString(sFileLine, ":", sValue, block_count, BLOCK_SIZE);
						PushArrayCell(g_hButtons[client], StringToInt(sValue[0]));
						PushArrayCell(g_hAngles[client][0], StringToFloat(sValue[1]));
						PushArrayCell(g_hAngles[client][1], StringToFloat(sValue[2]));
						PushArrayCell(g_hWeapons[client], StringToInt(sValue[3]));
						PushArrayString(g_hOrigin[client], sValue[4]); sValue[4][0] = 0;
						PushArrayString(g_hVelocity[client], sValue[5]); sValue[5][0] = 0;
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
			if (g_bIsApplyPlayerAction[client] && g_RecClient == 0)
			{
				decl String:sFileLine[BLOCKS_LEN];
				BuildPath(Path_SM, sFileLine, sizeof(sFileLine), "%s/default.txt", MR_DIR);
				if ((g_RecFile = OpenFile(sFileLine, "w")) != INVALID_HANDLE)
				{
					g_bIsApplyPlayerAction[client] = false;
					g_RecClient = client;
					g_RecTime = GetGameTime();
					g_RecFrames = GetGameTickCount();
					WriteFileLine(g_RecFile, g_sStartData[client]);
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
							}
							sFileLine[strlen(sFileLine) - 1] = 0;
						}
						WriteFileLine(g_RecFile, sFileLine);
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
	if (g_RecClient == client)
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
		if (GetConVarBool(g_ConVar_ExRecord))
		{
			decl Float:fPos[3], Float:fVel[3];
			GetClientAbsOrigin(client, fPos);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
			WriteFileLine(g_RecFile, "%d:%.03f:%.03f:%d:%.03f, %.03f, %.03f:%.03f, %.03f, %.03f", buttons, angles[0], angles[1], item, fPos[0], fPos[1], fPos[2], fVel[0], fVel[1], fVel[2]);
		}
		else WriteFileLine(g_RecFile, "%d:%.03f:%.03f:%d", buttons, angles[0], angles[1], item);
	}
	else if (g_bIsApplyPlayerAction[client])
	{
		if (g_iTicksTotal[client] > g_iTicks[client])
		{
			new bool:exmode, Float:fAngles[3], Float:fVelocity[2], mask = GetArrayCell(g_hButtons[client], g_iTicks[client]), item = GetArrayCell(g_hWeapons[client], g_iTicks[client]);
			fAngles[0] = GetArrayCell(g_hAngles[client][0], g_iTicks[client]);
			fAngles[1] = GetArrayCell(g_hAngles[client][1], g_iTicks[client]);
			
			if (GetConVarBool(g_ConVar_ExPlay))
			{
				decl String:sFileData[BLOCK_SIZE];
				if (GetArrayString(g_hOrigin[client], g_iTicks[client], sFileData, BLOCK_SIZE) > 0)
				{
					decl String:sValue[3][16];
					if (ExplodeString(sFileData, ",", sValue, 3, 16) == 3)
					{
						decl Float:fValue[3]; exmode = true;
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
			
			if (mask & IN_FORWARD) fVelocity[0] += PLAYER_VEL;
			if (mask & IN_BACK) fVelocity[0] -= PLAYER_VEL;
			if (mask & IN_MOVERIGHT) fVelocity[1] += PLAYER_VEL;
			if (mask & IN_MOVELEFT) fVelocity[1] -= PLAYER_VEL;
			if (item > 0) FakeClientCommand(client, "use %s", g_Items[item]);
			if (mask & IN_IDLE) ST_Idle(client);
			if (mask & IN_TAKEOVER) ST_Idle(client, true);
			if (buttons & IN_ATTACK) g_bIsClientFired[client] = true;
			else g_bIsClientFired[client] = false;
			TeleportEntity(client, NULL_VECTOR, fAngles, NULL_VECTOR);
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
			Call_PushCell(buttons);
			Call_Finish();
			Format(sKeyValue, sizeof(sKeyValue), "if (\"OnPlayLine\" in getroottable()) OnPlayLine(self, \"%s\", %d, %d)", sFileName, ticks, buttons);
			SetVariantString(sKeyValue);
			AcceptEntityInput(client, "RunScriptCode");
			
			if (GetConVarInt(g_ConVar_Debug) == client)
			{
				decl Float:fPos[3], Float:fVel[3];
				GetClientAbsOrigin(client, fPos);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
				PrintToServer("%d >> %d:%.03f:%.03f:%d%s | %.03f | %d | %.03f, %.03f, %.03f:%.03f, %.03f, %.03f | %N | %s", ticks, buttons, fAngles[0], fAngles[1], item, exmode ? ":EXMODE" : "", GetVectorLength(fVel), GetEntProp(client, Prop_Send, "m_fFlags"), fPos[0], fPos[1], fPos[2], fVel[0], fVel[1], fVel[2], client, sFileName);
			}
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
		}
	}
	return Plugin_Continue;
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
	if (g_bIsApplyPlayerAction[client] && !g_bIsClientFired[client] && !IsFakeClient(client))
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

//============================================================
//============================================================

stock ForceStop(client = 0)
{
	bool bRecStop;
	if (client > 0 && client <= MaxClients)
	{
		if (g_RecClient == client) bRecStop = true;
		else g_bIsApplyPlayerAction[client] = false;
	}
	else
	{
		if (g_RecClient > 0) bRecStop = true;
		for (int i = 1; i <= MaxClients; i++) g_bIsApplyPlayerAction[i] = false;
	}
	if (!bRecStop) return;
	g_RecClient = 0;
	CloseHandle(g_RecFile);
	PrintToServer("[SM] File has been created. Recording time: %.03f, game frames: %d.", GetGameTime() - g_RecTime, GetGameTickCount() - g_RecFrames);
}

public OnMapEnd()
{
	ForceStop();
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

public Action:Cmd_GetFrame(client, args)
{
	if (args > 0)
	{
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
	}
	else if (client == 0) client = 1;
	if (client <= 0 || client > MaxClients || !g_bIsApplyPlayerAction[client]) return Plugin_Handled;
	PrintToServer("[SM] %N's playback \"%s\" line: %d", client, g_sFileName[client], g_iTicks[client] + 3);
	return Plugin_Handled;
}

public Action:Cmd_Goto(client, args)
{
	if (client == 0) client = 1;
	if (g_bIsApplyPlayerAction[client])
	{
		decl String:sArg[8];
		GetCmdArg(1, sArg, sizeof(sArg));
		if ((args = StringToInt(sArg)) < 4) args = 4;
		g_iTicks[client] = args - 4;
	}
	return Plugin_Handled;
}

public Action:Cmd_MR(client, args)
{
	if (client == 0 && !IsClientInGame((client = 1))) return Plugin_Handled;
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
	SendPanelToClient(hTable, client, MenuHandler, 60);
	CloseHandle(hTable);
	return Plugin_Handled;
}

public MenuHandler(Menu menu, MenuAction action, int client, int value)
{
	if (action == MenuAction_Cancel) return;
	if (value == 1)
	{
		if (g_RecClient == 0)
		{
			SetConVarInt(g_ConVar_Record, client);
			ClientCommand(client, "playgamesound buttons/bell1.wav");
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	if (value == 2)
	{
		ForceStop(client);
		ResetConVar(g_ConVar_ForceFile);
		SetConVarInt(g_ConVar_Play, client);
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	if (value == 3)
	{
		if (g_bIsApplyPlayerAction[client])
		{
			SetConVarInt(g_ConVar_Split, client);
			ClientCommand(client, "playgamesound buttons/bell1.wav");
		}
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	if (value == 4)
	{
		if (g_bIsApplyPlayerAction[client]) g_iTicks[client] += g_iTicksTotal[client] > g_iTicks[client] + 150 ? 150 : 0;
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	if (value == 5)
	{
		if (g_bIsApplyPlayerAction[client]) g_iTicks[client] -= g_iTicks[client] - 150 > 0 ? 150 : 0;
		else ClientCommand(client, "playgamesound buttons/button11.wav");
	}
	if (value == 6)
	{
		ForceStop(client);
		ClientCommand(client, "playgamesound buttons/blip1.wav");
	}
	if (value == 7)
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
	ClientCommand(client, "stmr");
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