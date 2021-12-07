#define PLUGIN_VERSION 		"1.5"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Charger Steering
*	Author	:	SilverShot
*	Descrp	:	Allows chargers to turn and strafe while charging.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=179034

========================================================================================
	Change Log:

1.5 (22-May-2012)
	- Fixed error: "SetEntPropFloat reported: Entity -1 (-1) is invalid".

1.4 (20-May-2012)
	- Added German translations - Thanks to "Dont Fear The Reaper".
	- Fixed errors reported by "Dont Fear The Reaper".

1.3 (15-May-2012)
	- Fixed cvar "l4d2_charger_steering_modes_tog" missing.
	- Small fixes.

1.2 (30-Mar-2012)
	- Fixed a bug which could allow strafing as a survivor.

1.1 (30-Mar-2012)
	- Added cvar "l4d2_charger_steering_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d2_charger_steering_modes_tog" same as above.
	- Added cvars to control hints and what humans/bots have access to.
	- Added Strafing - Thanks to "dcx2".
	- Added translations and hint messages.
	- Added Russian translations - Thanks to "disawar1".
	- Fixed being able to punch while charging.

1.0 (25-Feb-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 			1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Charger Steering] \x01"


static	Handle:g_hMPGameMode, bool:g_bIsCharging[MAXPLAYERS+1], g_iDisplayed[MAXPLAYERS+1], g_iInstructorHint[MAXPLAYERS+1],
		Handle:g_hCvarAllow, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarBots, Handle:g_hCvarHint, Handle:g_hCvarHints, Handle:g_hCvarStrafe,
		bool:g_bCvarAllow, g_iCvarAllow, g_iCvarBots, g_iCvarHint, g_iCvarHints, Float:g_fCvarStrafe;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Charger Steering",
	author = "SilverShot",
	description = "Allows chargers to turn while charging.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=179034"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("chargersteering.phrases");

	g_hMPGameMode =	FindConVar("mp_gamemode");

	g_hCvarAllow =		CreateConVar(	"l4d2_charger_steering_allow",		"3",			"0=Plugin off, 1=Allow steering with mouse, 2=Allow strafing, 3=Both.", CVAR_FLAGS );
	g_hCvarBots =		CreateConVar(	"l4d2_charger_steering_bots",		"2",			"Who can steer with the mouse. 0=Humans Only, 1=AI only, 2=Humans and AI.", CVAR_FLAGS );
	g_hCvarHint =		CreateConVar(	"l4d2_charger_steering_hint",		"2",			"Display hint when charging? 0=Off, 1=Chat text, 2=Hint box, 3=Instructor hint (Prints to Chat if clients have instructor hints off), 4=Instructor hint (Hint Box).", CVAR_FLAGS);
	g_hCvarHints =		CreateConVar(	"l4d2_charger_steering_hints",		"2",			"How many times to display hints, count is reset each map/chapter.", CVAR_FLAGS);
	g_hCvarStrafe =		CreateConVar(	"l4d2_charger_steering_strafe",		"50.0",			"0.0=Off. Other value sets the amount humans strafe to the side.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_charger_steering_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_charger_steering_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d2_charger_steering_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d2_charger_steering_version",	PLUGIN_VERSION, "Charger Steering plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_charger_steering");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarBots,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHint,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHints,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarStrafe,			ConVarChanged_Cvars);
}

public OnClientPostAdminCheck(client)
{
	g_iDisplayed[client] = 0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	g_iCvarBots = GetConVarInt(g_hCvarBots);
	g_iCvarHint = GetConVarInt(g_hCvarHint);
	g_iCvarHints = GetConVarInt(g_hCvarHints);
	g_fCvarStrafe = GetConVarFloat(g_hCvarStrafe);
}

IsAllowed()
{
	g_iCvarAllow = GetConVarInt(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && g_iCvarAllow && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("player_spawn",			Event_PlayerSpawn);
		HookEvent("player_death",			Event_PlayerDeath);
		HookEvent("charger_charge_start",	Event_ChargeStart);
		HookEvent("charger_charge_end",		Event_ChargeEnd);
	}

	else if( g_bCvarAllow == true && (g_iCvarAllow == 0 || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",			Event_PlayerSpawn);
		UnhookEvent("player_death",			Event_PlayerDeath);
		UnhookEvent("charger_charge_start",	Event_ChargeStart);
		UnhookEvent("charger_charge_end",	Event_ChargeEnd);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		new entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
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
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if( client )
	{
		g_bIsCharging[client] = false;

		if( IsFakeClient(client) == false )
		{
			g_iInstructorHint[client] = 0;
			QueryClientConVar(client, "gameinstructor_enable", QueryConVarCallback);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bIsCharging[client] = false;
}

public QueryConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	g_iInstructorHint[client] = StringToInt(cvarValue);
}

public Event_ChargeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bIsCharging[client] = false;

	if( g_iCvarAllow >= 2 )
		g_bIsCharging[client] = true;

	if( g_iCvarBots == 2 || (g_iCvarBots == 0 && IsFakeClient(client) == false) || (g_iCvarBots == 1 && IsFakeClient(client) == true) )
	{
		if( g_iCvarAllow != 2 )
		{
			SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_FROZEN);

			new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( entity != -1 )
				SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 999.9);
		}

		if( !g_iCvarHint || (g_iCvarHint < 3 && g_iDisplayed[client] >= g_iCvarHints) || IsFakeClient(client) )
			return;

		g_iDisplayed[client]++;
		new hint = g_iCvarHint;
		if( hint == 3 && g_iInstructorHint[client] == 0 )
			hint = 1;
		else if( hint == 4 && g_iInstructorHint[client] == 0 )
			hint = 2;

		switch ( hint )
		{
			case 1:		// Print To Chat
			{
				if( g_iCvarAllow == 1 && g_iCvarBots != 1 )
					PrintToChat(client, "%s%T", CHAT_TAG, "ChargerSteering_Mouse", client);
				else if( g_iCvarAllow == 2 && g_fCvarStrafe != 0.0 )
					PrintToChat(client, "%s%T", CHAT_TAG, "ChargerSteering_Strafe", client);
				else if( g_iCvarAllow == 3 && g_fCvarStrafe != 0.0 )
					PrintToChat(client, "%s%T", CHAT_TAG, "ChargerSteering_Both", client);
			}

			case 2:		// Print Hint Text
			{
				if( g_iCvarAllow == 1 && g_iCvarBots != 1 )
					PrintHintText(client, "%T", "ChargerSteering_Mouse", client);
				else if( g_iCvarAllow == 2 && g_fCvarStrafe != 0.0 )
					PrintHintText(client, "%T", "ChargerSteering_Strafe", client);
				else if( g_iCvarAllow == 3 && g_fCvarStrafe != 0.0 )
					PrintHintText(client, "%T", "ChargerSteering_Both", client);
			}

			case 3, 4:		// Instructor Hint
			{
				decl String:sBuffer[256], String:sTemp[32];

				if( g_iCvarAllow == 1 && g_iCvarBots != 1 )
					Format(sBuffer, sizeof(sBuffer), "%T", "ChargerSteering_Mouse", client);
				else if( g_iCvarAllow == 2 && g_fCvarStrafe != 0.0 )
					Format(sBuffer, sizeof(sBuffer), "%T", "ChargerSteering_Strafe", client);
				else if( g_iCvarAllow == 3 && g_fCvarStrafe != 0.0 )
					Format(sBuffer, sizeof(sBuffer), "%T", "ChargerSteering_Both", client);
				else
					return;

				new entity = CreateEntityByName("env_instructor_hint");
				FormatEx(sTemp, sizeof(sTemp), "hint%d", client);
				DispatchKeyValue(client, "targetname", sTemp);
				DispatchKeyValue(entity, "hint_target", sTemp);
				DispatchKeyValue(entity, "hint_timeout", "10");
				DispatchKeyValue(entity, "hint_range", "0.01");
				if( g_iCvarAllow == 1 )
					DispatchKeyValue(entity, "hint_icon_onscreen", "icon_mouseThree");
				else
					DispatchKeyValue(entity, "hint_icon_onscreen", "icon_run");
				DispatchKeyValue(entity, "hint_caption", sBuffer);
				DispatchKeyValue(entity, "hint_color", "255 255 255");
				DispatchSpawn(entity);
				AcceptEntityInput(entity, "ShowHint");

				SetVariantString("OnUser1 !self:Kill::10:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");
			}
		}
	}
}

public Event_ChargeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bIsCharging[client] = false;

	if( client )
	{
		if( g_iCvarAllow != 2 && (g_iCvarBots == 2 || (g_iCvarBots == 0 && IsFakeClient(client) == false) || (g_iCvarBots == 1 && IsFakeClient(client) == true)) )
		{
			new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( entity != -1 )
				SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.0);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if( g_bCvarAllow && g_fCvarStrafe && (buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && g_bIsCharging[client] && GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND )
	{
		decl Float:vVel[3], Float:vVec[3], Float:vAng[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		GetClientEyeAngles(client, vAng);

		GetAngleVectors(vAng, NULL_VECTOR, vVec, NULL_VECTOR);
		NormalizeVector(vVec, vVec);

		ScaleVector(vVec, g_fCvarStrafe);
		if (buttons & IN_MOVELEFT)
			ScaleVector(vVec, -1.0);

		AddVectors(vVel, vVec, vVel);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	}
	return Plugin_Continue;
}