/*
*	Saferoom Door Spam Protection
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.11"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Saferoom Door Spam Protection
*	Author	:	SilverShot
*	Descrp	:	Only allows the first saferoom door to be opened once and prevents spamming the last door.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=324394
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.11 (05-Jul-2021)
	- L4D2: plugin compatibility update with "[L4D2] Saferoom Lock: Scavenge" plugin by "Eärendil" version 1.2+ only.
	- Thanks to "GL_INS" for reporting and testing.
	- Thanks to "Eärendil" for supporting the compatibility.

	- Changed method of locking doors after opening/closing. No more hackish workarounds.
	- Fixed some saferoom doors falling the wrong way when "l4d_safe_spam_physics" cvar was enabled.
	- Should now correctly detect the starting saferoom door for auto falling. Thanks to "Krevik" for reporting.

1.10 (30-Jun-2021)
	- Fixed the saferoom door not auto falling on some maps.
	- Now displays the handle falling.
	- Now swaps attachments from the old door to the new door.
	- Now supports multiple ending saferoom doors.

1.9 (26-Jun-2021)
	- Fixed cvar "l4d_safe_spam_fall_time" value "0.0" from making the door auto fall. Thanks to "Primeas" for reporting.

1.8 (21-Jun-2021)
	- Fixed not using an entity reference which could rarely throw errors otherwise.

	- Modified update from "pan0s" adding auto falling saferoom door feature.
	- Added cvar "l4d_safe_spam_fall_time" to control if the first saferoom door auto falls.
	- Added command "sm_door_last" to make a locked saferoom door fall over. Should mostly be the first saferoom door.

1.7 (15-Feb-2021)
	- Added cvar "l4d_safe_spam_physics" to allow the doors physics to persist or freeze after a specified amount of time. Requested by "yzybb".
	- Added Russian translations. Thanks to "Kleiner" for providing.

1.6 (05-Oct-2020)
	- Added cvar "l4d_safe_spam_last" to control the last saferoom door state on round start: opened, closed or map default. Thanks to "Tonblader" for requesting.

1.5 (20-Sep-2020)
	- Blocked door falling on L4D2 "Questionable Ethics" 2nd map (qe2_ep2) to prevent breaking gameplay. Thanks to "Alex101192" for reporting.
	- Fixed the door not always falling in the right direction on some maps.

1.4 (20-Sep-2020)
	- Added a sound effect for when the door breaks and falls.
	- Fixed the door not always falling on some maps.

1.3 (18-Sep-2020)
	- Changed cvar "l4d_safe_spam_open" adding option "2" to make the door fall. Thanks to "yzybb" for requesting.

1.2 (05-Jun-2020)
	- Added cvar "l4d_safe_spam_hint" to control displaying messages when saferoom doors are opened/closed.
	- Added translations support. Thanks to "Tonblader" for requesting.

1.1 (15-May-2020)
	- Initial release.

1.0 (30-Aug-2013)
	- Initial creation.

======================================================================================*/

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define SOUND_BREAK1			"physics/metal/metal_box_break1.wav"
#define SOUND_BREAK2			"physics/metal/metal_box_break2.wav"
#define MODEL_BOUNDING			"models/props/cs_militia/silo_01.mdl"
#define	MAX_DOORS				4 // Max last doors


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarHint, g_hCvarLast, g_hCvarOpen, g_hCvarPhysics, g_hCvarTimeClose, g_hCvarTimeOpen, g_hCvarType, g_hCvarFallTime;
bool g_bCvarAllow, g_bMapStarted, g_bMapBlocked, g_bLeft4Dead2, g_bGameStart, g_bOpened;
int g_iRoundStart, g_iPlayerSpawn, g_iSafeDoor, g_iLastDoor[MAX_DOORS], g_iLastFlags[MAX_DOORS], g_iCvarHint, g_iCvarLast, g_iCvarOpen, g_iCvarType, g_iLockedDoor;
float g_fLastDoor, g_fCvarPhysics, g_fCvarTimeClose, g_fCvarTimeOpen, g_fCvarFallTime;
Handle g_hTimerFall, g_hLastTimer[MAX_DOORS];

bool g_bSaferoomLocked; // Prevent forcing doors shut when another plugin is doing so. This prevents a recursive loop between the plugins causing a memory leak - This was prevalent in the old version using RequestFrame.



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Saferoom Door Spam Protection",
	author = "SilverShot",
	description = "Only allows the first saferoom door to be opened once and prevents spamming the last door.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=324394"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/safe_door_spam.phrases.txt");
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	LoadTranslations("safe_door_spam.phrases");

	g_hCvarAllow =		CreateConVar(	"l4d_safe_spam_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes =		CreateConVar(	"l4d_safe_spam_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar(	"l4d_safe_spam_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog =	CreateConVar(	"l4d_safe_spam_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	g_hCvarFallTime =	CreateConVar(	"l4d_safe_spam_fall_time",		"20.0",			"0.0=Off. How many seconds after round start until the locked saferoom door will automatically fall.", CVAR_FLAGS);
	g_hCvarHint =		CreateConVar(	"l4d_safe_spam_hint",			"1",			"0=Off. 1=Display a message showing who opened or closed the saferoom door.", CVAR_FLAGS);
	g_hCvarLast =		CreateConVar(	"l4d_safe_spam_last",			"0",			"Final door state on round start: 0=Use map default. 1=Close last door. 2=Open last door.", CVAR_FLAGS);
	g_hCvarOpen =		CreateConVar(	"l4d_safe_spam_open",			"2",			"0=Off, 1=Keep the first saferoom door open once opened, 2=Make the first saferoom door fall once opened.", CVAR_FLAGS);
	g_hCvarPhysics =	CreateConVar(	"l4d_safe_spam_physics",		"3.0",			"0.0=Always has physics. How many seconds until the fallen doors physics are disabled.", CVAR_FLAGS);
	g_hCvarTimeClose =	CreateConVar(	"l4d_safe_spam_time_close",		"1.0",			"How many seconds to block after closing the last saferoom door.", CVAR_FLAGS);
	g_hCvarTimeOpen =	CreateConVar(	"l4d_safe_spam_time_open",		"3.0",			"How many seconds to block after opening the last saferoom door.", CVAR_FLAGS);
	g_hCvarType =		CreateConVar(	"l4d_safe_spam_type",			"3",			"0=Off. When the last saferoom door is used enable the timeout on: 1=Open, 2=Close, 3=Both.", CVAR_FLAGS);

	CreateConVar(						"l4d_safe_spam_version",		PLUGIN_VERSION,	"Saferoom Door Spam Protection plugin version",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_safe_spam");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarFallTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHint.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLast.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPhysics.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarOpen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeClose.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeOpen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_door_drop", CmdDoorDrop, ADMFLAG_ROOT, "Test command to make a targeted door fall over (will likely only work correctly on Saferoom doors).");
	RegAdminCmd("sm_door_fall", CmdDoorLast, ADMFLAG_ROOT, "Test command to make the first locked saferoom door fall over (will likely only work correctly on Saferoom doors).");
}

public Action CmdDoorDrop(int client, int args)
{
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		char sClass[64];
		GetEdictClassname(entity, sClass, sizeof(sClass));
		if( strncmp(sClass, "prop_door", 9) == 0 )
		{
			// OnFrameOpen(entity);
			OnFirst("", entity, 0, 0.0);
		}
	}

	return Plugin_Handled;
}

public Action CmdDoorLast(int client, int args)
{
	if( g_iLockedDoor == -1 || EntRefToEntIndex(g_iLockedDoor) == INVALID_ENT_REFERENCE )
	{
		ReplyToCommand(client, "Locked door not found.");
		return Plugin_Handled;
	}

	OnFirst("", g_iLockedDoor, 0, 0.0);
	ReplyToCommand(client, "Locked door %d dropped", g_iLockedDoor);

	return Plugin_Handled;
}



// ====================================================================================================
//					FORWARDS FROM OTHER PLUGINS
// ====================================================================================================
public void SLS_OnDoorStatusChanged(bool locked)
{
	g_bSaferoomLocked = locked;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	int last = g_iCvarOpen;

	g_iCvarHint = g_hCvarHint.IntValue;
	g_iCvarLast = g_hCvarLast.IntValue;
	g_fCvarPhysics = g_hCvarPhysics.FloatValue;
	g_iCvarOpen = g_hCvarOpen.IntValue;
	g_fCvarTimeClose = g_hCvarTimeClose.FloatValue;
	g_fCvarTimeOpen = g_hCvarTimeOpen.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
	g_fCvarFallTime = g_hCvarFallTime.FloatValue;

	if( last != g_iCvarOpen )
	{
		if( g_iSafeDoor && EntRefToEntIndex(g_iSafeDoor) != INVALID_ENT_REFERENCE )
		{
			UnhookSingleEntityOutput(g_iSafeDoor, "OnOpen", OnFirst);
		}

		for( int i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iLastDoor[i] && EntRefToEntIndex(g_iLastDoor[i]) != INVALID_ENT_REFERENCE )
			{
				UnhookSingleEntityOutput(g_iLastDoor[i], "OnOpen", OnOpen);
				UnhookSingleEntityOutput(g_iLastDoor[i], "OnClose", OnClose);
			}
		}

		InitPlugin();
	}
}

void IsAllowed()
{
	bool bAllow = GetConVarBool(g_hCvarAllow);
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		InitPlugin();
		HookEvents(true);
	}
	else if( g_bCvarAllow == true && (bAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		HookEvents(false);
		ResetPlugin();

		delete g_hTimerFall;

		if( g_iSafeDoor && EntRefToEntIndex(g_iSafeDoor) != INVALID_ENT_REFERENCE )
		{
			UnhookSingleEntityOutput(g_iSafeDoor, "OnOpen", OnFirst);
		}

		for( int i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iLastDoor[i] && EntRefToEntIndex(g_iLastDoor[i]) != INVALID_ENT_REFERENCE )
			{
				UnhookSingleEntityOutput(g_iLastDoor[i], "OnOpen", OnOpen);
				UnhookSingleEntityOutput(g_iLastDoor[i], "OnClose", OnClose);
			}
		}
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

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

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents(bool hook)
{
	if( hook )
	{
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("player_team",		Event_PlayerTeam);
		HookEvent("door_open",			Event_DoorOpen);
		HookEvent("door_close",			Event_DoorClose);
	}
	else
	{
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("player_team",		Event_PlayerTeam);
		UnhookEvent("door_open",		Event_DoorOpen);
		UnhookEvent("door_close",		Event_DoorClose);
	}
}

public void OnMapStart()
{
	PrecacheSound(SOUND_BREAK1);
	PrecacheSound(SOUND_BREAK2);

	g_bMapStarted = true;

	if( g_bLeft4Dead2 )
	{
		char sMap[10];
		GetCurrentMap(sMap, sizeof(sMap));

		if( strcmp(sMap, "qe2_ep2") == 0 )
			g_bMapBlocked = true;
		else
			g_bMapBlocked = false;
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_bSaferoomLocked = false;
	g_bGameStart = false;
	g_bOpened = false;

	delete g_hTimerFall;

	for( int i = 0; i < MAX_DOORS; i++ )
		delete g_hLastTimer[i];
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if( g_fCvarFallTime )
	{
		int team = event.GetInt("team");
		if( team == 2 && !g_bGameStart )
		{
			g_bGameStart = true; // Game is ready to start.
			ReadyToFallLockedDoor();
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iRoundStart == 1 && g_iPlayerSpawn == 0 )
		InitPlugin();
	g_iPlayerSpawn = 1;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iRoundStart == 0 && g_iPlayerSpawn == 1 )
		InitPlugin();
	g_iRoundStart = 1;
}

public void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
	{
		DoorPrint(event, true);
		g_bOpened = true;
	}
}

public void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
		DoorPrint(event, false);
}

void DoorPrint(Event event, bool open)
{
	if( g_iCvarHint && g_fLastDoor < GetGameTime() + 0.05 )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					CPrintToChat(i, "%T", open ? "Door_Open" : "Door_Close", i, client);
				}
			}
		}
	}
}



// ====================================================================================================
//					SETUP / SOUND HOOK
// ====================================================================================================
void InitPlugin()
{
	g_bGameStart = true;
	g_bOpened = false;
	g_fLastDoor = 0.0;
	g_iSafeDoor = 0;
	g_iLockedDoor = -1;

	for( int i = 0; i < MAX_DOORS; i++ )
	{
		g_iLastDoor[i] = 0;
	}

	bool start;
	float vStart[3], vPos[3];

	// Find starting area to find nearest "prop_door_rotating_checkpoint"
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			start = true;
			GetClientAbsOrigin(i, vStart);
			break;
		}
	}

	int entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1 )
	{
		int locked = GetEntProp(entity, Prop_Send, "m_bLocked") == 1;
		if( locked )
		{
			if( g_iLockedDoor == -1 )
			{
				if( start )
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				if( !start || GetVectorDistance(vStart, vPos) < 750 )
				{
					g_iLockedDoor = EntIndexToEntRef(entity);

					if( g_iCvarOpen && g_iSafeDoor == 0 && !g_bMapBlocked )
					{
						g_iSafeDoor = EntIndexToEntRef(entity);

						if( g_iCvarOpen == 1 )
						{
							SetVariantString("OnOpen !self:Lock::0.0:-1");
							AcceptEntityInput(entity, "AddOutput");
						} else {
							HookSingleEntityOutput(entity, "OnOpen", OnFirst);
						}
					}
				}
			}
		}
		else
		{
			if( g_iCvarLast == 1 )			AcceptEntityInput(entity, "Close");
			else if( g_iCvarLast == 2 )		AcceptEntityInput(entity, "Open");

			if( g_iCvarType )
			{
				for( int i = 0; i < MAX_DOORS; i++ )
				{
					if( g_iLastDoor[i] == 0 )
					{
						HookSingleEntityOutput(entity, "OnOpen", OnOpen);
						HookSingleEntityOutput(entity, "OnClose", OnClose);

						g_iLastDoor[i] = EntIndexToEntRef(entity);
						break;
					}
				}
			}
		}
	}

	if( g_fCvarFallTime )
		ReadyToFallLockedDoor();
}



// ====================================================================================================
//					AUTO FALL
// ====================================================================================================
public void ReadyToFallLockedDoor()
{
	if( g_iLockedDoor == -1 || EntRefToEntIndex(g_iLockedDoor) == INVALID_ENT_REFERENCE ) return;

	delete g_hTimerFall;
	g_hTimerFall = CreateTimer(g_fCvarFallTime, HandleAutoFallTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action HandleAutoFallTimer(Handle timer)
{
	if( g_iLockedDoor != -1 && !g_bOpened && !g_bMapBlocked && EntRefToEntIndex(g_iLockedDoor) != INVALID_ENT_REFERENCE )
	{
		OnFirst("", g_iLockedDoor, 0, 0.0);
	}

	g_hTimerFall = null;
}



// ====================================================================================================
//					DOOR FUNCTION
// ====================================================================================================
public void OnFirst(const char[] output, int entity, int activator, float delay)
{
	// RequestFrame(OnFrameOpen, EntIndexToEntRef(entity));
// }

// public void OnFrameOpen(int entity)
// {
	// entity = EntRefToEntIndex(entity);
	// if( entity == INVALID_ENT_REFERENCE ) return;

	char sModel[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	float vPos[3], vAng[3], vDir[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
	// GetEntPropVector(entity, Prop_Data, "m_angRotationOpenForward", vDir);

	// Make old door non-solid, so physics door does not collide and stutter
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);

	// Create new physics door
	int door = CreateEntityByName("prop_physics");
	DispatchKeyValue(door, "spawnflags", "4"); // Prevent collision - make non-solid
	DispatchKeyValue(door, "model", sModel);
	DispatchSpawn(door);

	// Teleport to current door, ready to take it's attachments
	TeleportEntity(door, vPos, vAng, NULL_VECTOR);

	// Stop movement
	if( g_fCvarPhysics )
	{
		char sTemp[64];
		FormatEx(sTemp, sizeof(sTemp), "OnUser1 !self:DisableMotion::%f:1", g_fCvarPhysics);
		SetVariantString(sTemp);
		AcceptEntityInput(door, "AddOutput");
		AcceptEntityInput(door, "FireUser1");
	}

	// Handle fall animation from old door
	SetVariantString("unlock");
	AcceptEntityInput(entity, "SetAnimation");

	// Wait for handle to fall
	SetVariantString("OnUser4 !self:Kill::1.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");

	// Hide old door
	SetEntityRenderMode(entity, RENDER_TRANSALPHA);
	SetEntityRenderColor(entity, 0, 0, 0, 0);

	// Find attachments, swap to our new door
	entity = EntRefToEntIndex(entity);

	for( int att = 0; att < 2048; att++ )
	{
		if( IsValidEdict(att) )
		{
			if( HasEntProp(att, Prop_Send, "moveparent") && GetEntPropEnt(att, Prop_Send, "moveparent") == entity )
			{
				SetVariantString("!activator");
				AcceptEntityInput(att, "SetParent", door);
			}
		}
	}

	// Tilt ang away
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);

	float dist;

	if( strcmp(sModel, "models/props_doors/checkpoint_door_-01.mdl") == 0 )
		dist = -10.0;
	else
		dist = 10.0;

	// Move pos away, change ang and push
	vPos[0] += (vDir[0] * dist);
	vPos[1] += (vDir[1] * dist);
	vAng[0] = dist;
	vDir[0] = 0.0;
	vDir[1] = vAng[1] < 270.0 ? 10.0 : -10.0 * dist;
	vDir[2] = 0.0;

	TeleportEntity(door, vPos, vAng, vDir);

	EmitSoundToAll(GetRandomInt(0, 1) ? SOUND_BREAK1 : SOUND_BREAK2, door);
}

public void OnClose(const char[] output, int entity, int activator, float delay)
{
	OnUseDoor(entity, false);
}

public void OnOpen(const char[] output, int entity, int activator, float delay)
{
	OnUseDoor(entity, true);
}

void OnUseDoor(int entity, bool open)
{
	// Blocked by other plugins
	if( g_bSaferoomLocked )
		return;

	// Get door index
	int index = -1;

	for( int i = 0; i < MAX_DOORS; i++ )
	{
		if( g_iLastDoor[i] && EntRefToEntIndex(g_iLastDoor[i]) == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return;

	// Timer already blocking
	if( g_hLastTimer[index] != null )
		return;

	// Block open/close
	if( (open && g_iCvarType & 1) || (!open && g_iCvarType & 2) )
	{
		g_iLastFlags[index] = GetEntProp(g_iLastDoor[index], Prop_Send, "m_spawnflags");
		SetEntProp(g_iLastDoor[index], Prop_Send, "m_spawnflags", 36864); // Prevent +USE + Door silent
		g_hLastTimer[index] = CreateTimer(open ? g_fCvarTimeOpen : g_fCvarTimeClose, TimeReset, index);

		g_fLastDoor = GetGameTime() + (open ? g_fCvarTimeOpen : g_fCvarTimeClose);
	}
}

public Action TimeReset(Handle timer, int index)
{
	if( g_iLastDoor[index] && EntRefToEntIndex(g_iLastDoor[index]) != INVALID_ENT_REFERENCE )
		SetEntProp(g_iLastDoor[index], Prop_Send, "m_spawnflags", g_iLastFlags[index]);

	g_hLastTimer[index] = null;
}

/* OLD METHOD: Kept for demonstration purposes.
bool g_bWatch;

public void OnClose(const char[] output, int entity, int activator, float delay)
{
	OnUseDoor(false);
}

public void OnOpen(const char[] output, int entity, int activator, float delay)
{
	OnUseDoor(true);
}

void OnUseDoor(bool open)
{
	if( g_fLastDoor > GetGameTime() )
	{
		if( g_bWatch )
		{
			g_bWatch = false;
			RequestFrame(open ? DoClose : DoOpen);
		}
	}
	else
	{
		if( (open && g_iCvarType & 1) )
		{
			g_fLastDoor = GetGameTime() + g_fCvarTimeOpen;
			g_bWatch = true;
		}
		if( !open && g_iCvarType & 2 )
		{
			g_fLastDoor = GetGameTime() + g_fCvarTimeClose;
			g_bWatch = true;
		}
	}
}

public void OnFrame(bool open)
{
	RequestFrame(open ? DoClose : DoOpen);
}

public void DoClose(int na) // "int na" to support compiling on SourceMod 1.8
{
	if( g_fLastDoor > GetGameTime() )
	{
		for( int i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iLastDoor[i] && EntRefToEntIndex(g_iLastDoor[i]) != INVALID_ENT_REFERENCE )
			{
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundClose", "");
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundOpen", "");
				AcceptEntityInput(g_iLastDoor[i], "Close");
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundClose", "Doors.Checkpoint.FullClose1");
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundOpen", "Doors.Checkpoint.FullOpen1");
				g_bWatch = true;
			}
		}
	}
}

public void DoOpen(int na)
{
	if( g_fLastDoor > GetGameTime() )
	{
		for( int i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iLastDoor[i] && EntRefToEntIndex(g_iLastDoor[i]) != INVALID_ENT_REFERENCE )
			{
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundClose", "");
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundOpen", "");
				AcceptEntityInput(g_iLastDoor[i], "Open");
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundClose", "Doors.Checkpoint.FullClose1");
				SetEntPropString(g_iLastDoor[i], Prop_Data, "m_SoundOpen", "Doors.Checkpoint.FullOpen1");
				g_bWatch = true;
			}
		}
	}
}
// */



// ====================================================================================================
//					COLORS.INC REPLACEMENT
// ====================================================================================================
void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"\x03");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"\x03");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"\x04");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"\x04"); // Actually orange in L4D2, but replicating colors.inc behaviour
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"\x05");
	PrintToChat(client, buffer);
}