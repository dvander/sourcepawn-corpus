/* Hidden:SourceMod - Team-Aura
 *
 * Description:
 *  Emulated Beta 6's proposed IRIS Aura by showing a tracker sprite on players when they have +aura.
 *  Hiddens can always see fellow Hiddens (OVR).
 *  Dead/Spectators can see the IRIS sprite.
 *  Depending on settings either any or only admin spectators can see the Hidden's sprite.
 *  When IRIS emit radio messages, other IRIS can see their position despite render problems.
 *
 * Convars:
 *  hsm_ta_anyone      [bool] : Can anyone see Hidden sprites when dead? 0: No, Admins only. 1: Yes. Default: No.
 *  hsm_ta_irisaura   [0/1/2] : Draw team-sprites for IRIS? 0: Never. 1: When +AURA is held. 2: Only spectators. Default: Yes.
 *  hsm_ta_radioalarm  [bool] : Enable radio-alarms? 0: No, normal sonic alarms. 1: Yes, alarms transmit over radio instead.
 *  hsm_ta_radiosprite [bool] : Draw emitter sprites for IRIS & Alarm radio signals? 0: No, 1: Yes.
 *
 * Commands:
 *  None
 *
 * Changelog:
 *  v1.1.2
 *   Re-redid the radio signal timer code so signals cycle down naturally.
 *   Added a limit on how many alarms can be active across the whole map. They all still show up on IRIS's radar though.
 *   Added a minimum range within-which other alarms cannot trigger as it overwhelm the radios or something? Should prevent alarm-spam.
 *  v1.1.1
 *   Integrated Radio-alarm plugin to allow for alarm-location sprites.
 *   Re-did most of the code to reduce server-load & potential for errors.
 *   Changes IRIS aura to work in the same way as the radio calls so it defies vis-leaf optimizations.
 *  v1.1.0
 *   Added radio-call sprite that 'defies' render-block/vis-leaf limitations.
 *  v1.0.1
 *   Fixed sprite model array overflow & broken download table / precache.
 *   Added option to draw IRIS sprites.
 *   Optimized code to reduce un-needed work.
 *  v1.0.0
 *   Initial release.
 *
 * Known Issues:
 *  v1.0.0
 *   Possibly more work than it's worth throwing at the server? sprite spam...
 *
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.Sourcemod.net
 *  Hidden:SOURCE: http://www.hidden-Source.com
 */
#define PLUGIN_VERSION		"1.1.1"

#pragma semicolon	1

#define DEV		0

#include <sdktools>

#define ANYONE	-1
#define DEAD	0
#define ALIVE	1

#define IN_AURA				(1 << 23)
#define HDN_MAXPLAYERS		10
#define HDN_TEAM_IRIS		2
#define HDN_TEAM_HIDDEN		3

#define HDN_MAXALARMS		4	// Limits the number of currently active alarms throughout the entire map.

#define HDN_RADIO_REQUESTAMMO	3
#define HDN_RADIO_ALARM			9
#define HDN_RADIO_REPORTINGIN	10
#define HDN_RADIO_MAX			10

#define Anyone		0
#define IRISAura	1
#define RadioAlarm	2
#define RadioSprite	3
#define CVARS		4

public Plugin:myinfo = {
	name		= "H:SM - Teamaura.",
	author		= "Paegus",
	description	= "Brings Beta 6 proposed team-aura w/tweaks to Beta 4.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=#"
}

static const
	String:g_szAuraModel[][][]		= {					// Aura sprite materials
		{												// TEAM 2-2 (IRIS)
			"materials/vgui/hud/iris_low.vmt",			// Low health
			"materials/vgui/hud/iris_med.vmt",			// Medium health
			"materials/vgui/hud/iris_high.vmt"			// High health
		},
		{												// TEAM 3-2 (Hidden)
			"materials/vgui/hud/hdn_low.vmt",			// Low health
			"materials/vgui/hud/hdn_med.vmt",			// Medium health
			"materials/vgui/hud/hdn_high.vmt"			// High health
		}
	},
	String:g_szRadioModel[][] 		= {					// Radio sprite materials.
		"materials/vgui/hud/assault_icon_radio.vmt",	// HDN_RADIO_AGENTDOWN
		"materials/vgui/hud/assault_icon_radio.vmt",	// HDN_RADIO_SIGHTED
		"materials/vgui/hud/assault_icon_radio.vmt",	// HDN_RADIO_AFFIRMATIVE
		"materials/vgui/hud/hdn_ammorequest.vmt",		// HDN_RADIO_REQUESTAMMO
		"materials/vgui/hud/assault_icon_radio.vmt",	// HDN_RADIO_STATUS
		"",												// HDN_RADIO_IFITBLEEDS. Doesn't use iris_radio.
		"",												// HDN_RADIO_UGLYMOTHER. Doesn't use iris_radio.
		"",												// HDN_RADIO_BRINGIT. Doesn't use iris_radio.
		"materials/vgui/hud/assault_icon_radio.vmt",	// HDN_RADIO_BACKUP.
		"materials/vgui/hud/sonic_icon.vmt",			// HDN_RADIO_NULL2. Doesn't exist. Using for HDN_RADIO_ALARM
		"materials/vgui/hud/assault_icon_radio.vmt"		// HDN_RADIO_REPORTINGIN
	},

	Float:g_flAuraSize[]			= {					// Per-team sprite size.
		0.125,											// IRIS (2-2)
		0.125											// Hidden (3-2)
	},
	Float:g_flRadioTimeouts[]		= {					// Seconds until the radio-sprite expires.
		2.0,											// HDN_RADIO_AGENTDOWN
		4.0,											// HDN_RADIO_SIGHTED
		2.0,											// HDN_RADIO_AFFIRMATIVE
		60.0,											// HDN_RADIO_REQUESTAMMO
		2.0,											// HDN_RADIO_STATUS
		0.0,											// HDN_RADIO_IFITBLEEDS. Doesn't use iris_radio.
		0.0,											// HDN_RADIO_UGLYMOTHER. Doesn't use iris_radio.
		0.0,											// HDN_RADIO_BRINGIT. Doesn't use iris_radio.
		4.0,											// HDN_RADIO_BACKUP.
		5.7,											// HDN_RADIO_NULL2. HDN_RADIO_ALARM
		4.0												// HDN_RADIO_REPORTINGIN
	},
	Float:g_flRadioBaseSize[]		= {					// Radio sprite base size.
		0.5,											// HDN_RADIO_AGENTDOWN
		0.5,											// HDN_RADIO_SIGHTED
		0.5,											// HDN_RADIO_AFFIRMATIVE
		0.5,											// HDN_RADIO_REQUESTAMMO
		0.5,											// HDN_RADIO_STATUS
		0.0,											// HDN_RADIO_IFITBLEEDS. Doesn't use iris_radio.
		0.0,											// HDN_RADIO_UGLYMOTHER. Doesn't use iris_radio.
		0.0,											// HDN_RADIO_BRINGIT. Doesn't use iris_radio.
		0.5,											// HDN_RADIO_BACKUP.
		0.5,											// HDN_RADIO_NULL2. HDN_RADIO_ALARM
		0.5												// HDN_RADIO_REPORTINGIN
	},
	Float:g_flRangeRadioMax			= 16384.0,			// Maximum distance from SOURCE to DESTINATION to render sprite.
	Float:g_flSpriteUpdate			= 0.1,				// Sprite update time.
	Float:g_flMinSpriteSize			= 0.05,				// Minimum size the sprite can be scaled to.
	Float:g_flMinAlarmRange			= 128.0,			// Range inside of which other alarms can't trigger.
	
	g_iAuraBrightness[]				= {					// Per-team sprite brightness
		255,											// IRIS (2-2)
		128												// Hidden (3-2)
	},
	g_iZOffset[]					= {					// Per-team sprite vertical offset
		9,												// IRIS (2-2)
		-12												// Hidden (3-2)
	},
	g_iLowHealth[]					= {					// Per-team Red health offsets
		37,												// IRIS (2-2)
		20												// Hidden (3-2)
	},
	g_iMedHealth[]					= {					// Per-team Orange health offsets
		74,												// IRIS (2-2)
		60												// Hidden (3-2)
	}
;

new
	Handle:cvar[CVARS]						= { INVALID_HANDLE, ... },
	
	bool:g_bRadioSprite	= true,
	bool:g_bRadioAlarm	= true,
	bool:g_bInRound		= true,
	bool:g_bAnyone		= false,
	
	#if DEV
	bool:g_bDev			= false,
	#endif
	
	g_eActiveAlarms[HDN_MAXALARMS]	= { 0, ... },		// Maximum number of active alarm sprites.
	g_iIRISAura = 1,
	g_eAuraModel[2][3],									// Sprite model indexes
	g_eRadioModel[HDN_RADIO_MAX+1],						// Radio model indexes
	g_iActiveAlarms = 0
;

public OnPluginStart () {
	/*
	#if DEV
	decl String:szHostname[MAX_NAME_LENGTH];
	new Handle:cvHostname = FindConVar ("hostname");
	GetConVarString (cvHostname, szHostname, MAX_NAME_LENGTH);
	if (StrContains (szHostname, "testcase", false) == -1) {	// Not the test server, unload the plugin.
		LogToGame ("*** Not a test server. Disabling plugin. *");
		g_bDev = true;
		return;
	}
	#endif
	*/
	
	new Handle:cvVersion = CreateConVar (
		"hsm_ta_version",
		PLUGIN_VERSION,
		"H:SM - Player tracker version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	SetConVarString (cvVersion, PLUGIN_VERSION);
	
	cvar[Anyone] = CreateConVar (
		"hsm_ta_anyone", "1", "Can anyone see Hidden sprites when dead? 0: No, Admins only. 1: Yes.",
		_, true, 0.0, true, 1.0
	);
	
	cvar[IRISAura] = CreateConVar (
		"hsm_ta_irisaura", "1", "Draw team-sprites for IRIS? 0: Never. 1: When +AURA is held. 2: Only spectators.",
		_, true, 0.0, true, 2.0
	);
	
	cvar[RadioAlarm] = CreateConVar (
		"hsm_ta_radioalarm", "1", "Enable radio-alarms? 0: No, Sonic alarms. 1: Yes, alarms transmit over radio instead.",
		_, true, 0.0, true, 1.0
	);
	
	cvar[RadioSprite] = CreateConVar (
		"hsm_ta_radiosprite", "1", "Draw emitter sprites for IRIS & Alarm radio signals? 0: No, 1: Yes.",
		_, true, 0.0, true, 1.0
	);
	
	for (new i = 0; i < CVARS; i++) {
		HookConVarChange(cvar[i], convar_Change);
	}
	
	if (GetConVarBool(cvar[RadioAlarm])) {
		AddNormalSoundHook (NormalSHook:event_SoundPlayed);	// A sound is played.
	}
	
	if (GetConVarBool(cvar[RadioSprite])) {
		HookEvent ("iris_radio", event_IRISRadio);
	}
	
	HookEvent ("game_round_start", event_RoundStart);	// Check for spawning players.
	HookEvent ("game_round_end", event_RoundEnd);		// Check for still living players.
	
	CreateTimer(g_flSpriteUpdate, tmr_DrawAuraSprites, _, TIMER_REPEAT);
}

public OnMapStart () {
	#if DEV
	if (g_bDev) return;		// DEV mode, Quit now.
	#endif
	
	decl i, j;
	
	PrecacheSound("weapons/sonic/alarm.wav", true);

	// Precache & download aura sprite materials.
	for (i = 0; i < 2; i++) {
		for (j = 0; j < 3; j++) {
			g_eAuraModel[i][j] = PrecacheModel (g_szAuraModel[i][j]);
			AddFileToDownloadsTable (g_szAuraModel[i][j]);
		}
	}
	
	// Download aura sprites textures.
	AddFileToDownloadsTable ("materials/vgui/hud/hdn_aura.vtf");
	AddFileToDownloadsTable ("materials/vgui/hud/iris_aura.vtf");
	
	// Precache & download radio sprite materials.
	for (i = 0; i <= HDN_RADIO_MAX; i++) {
		if (strlen (g_szRadioModel[i]) > 0) {
			g_eRadioModel[i] = PrecacheModel (g_szRadioModel[i]);
		}
	}
	
	g_iActiveAlarms = 0;
}

/* Monitor settings changes */
public convar_Change(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (convar == cvar[Anyone]) {
		g_bAnyone = bool:StringToInt(newVal);
	}
	
	else if (convar == cvar[IRISAura]) {
		g_iIRISAura = StringToInt(newVal);
	}
	
	else if (convar == cvar[RadioAlarm]) {
		g_bRadioAlarm = bool:StringToInt(newVal);
		if (g_bRadioAlarm) {	// Enabled
			AddNormalSoundHook (NormalSHook:event_SoundPlayed);
		} else {	// Disabled
			RemoveNormalSoundHook (NormalSHook:event_SoundPlayed);
		}
	}
	
	else if (convar == cvar[RadioSprite]) {
		g_bRadioSprite = bool:StringToInt(newVal);
		if (g_bRadioSprite) {	// Enabled
			HookEvent ("iris_radio", event_IRISRadio);
		} else {	// Disabled
			UnhookEvent ("iris_radio", event_IRISRadio);
		}
	}
	
	return;
}

/* Catch iris_radio events */
public Action:event_IRISRadio (Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_bRadioSprite) return Plugin_Continue;	// Radio sprites are disabled. Nothing to do here,
	
	decl Handle:hPack;
	new message = GetEventInt (event, "message");
	
	if (!(0 <= message <= 10)) {	// message was outside lower then 0 or higher than 10.
		message = HDN_RADIO_REPORTINGIN;	// Set generic sprite.
	}
	
	hPack = CreateDataPack();
	WritePackCell(hPack, GetClientOfUserId (GetEventInt (event, "userid")));			// Source entity.
	WritePackCell(hPack, message);														// Source's message
	WritePackCell(hPack, RoundToNearest(g_flRadioTimeouts[message]/g_flSpriteUpdate));	// Counter
	
	CreateTimer (g_flSpriteUpdate, tmr_DrawTraceSprites, hPack);
	
	#if DEV > 1
	LogToGame(
		"*** Client %d started radio trace. Msg:%d. Pings:%d.",
		GetClientOfUserId (GetEventInt (event, "userid")),
		message,
		RoundToNearest(g_flRadioTimeouts[message]/g_flSpriteUpdate)
	);
	#endif
	
	return Plugin_Continue;
}

/* Catch alarm_triggered events by entity instead of searching for the alarm by position */
public Action:event_SoundPlayed (
	clients[64],
	&numClients,
	String:sample[PLATFORM_MAX_PATH],
	&entity,
	&channel,
	&Float:volume,
	&level,
	&pitch,
	&flags
) {
	if (
		!StrEqual (sample,")weapons/sonic/alarm.wav") ||	// Wasn't an alarm.
		volume < 0.001 ||									// Too quiet to care about.
		!g_bRadioAlarm										// Radio alarms disabled.
	) {
		return Plugin_Continue;
	}
	
	SetEntProp (entity, Prop_Send, "m_CollisionGroup", 1);	// Set alarm transparent. Yeah, totally snuck that in there didn't i? :)
	
	#if DEV > 1
	LogToGame(
		"*** Alarm %d was triggered",
		entity
	);
	#endif
	
	if (!g_bInRound) {
		return Plugin_Handled;
	}
	
	if (g_bRadioSprite) {	// Render radio-alarm sprite
		if (g_iActiveAlarms >= HDN_MAXALARMS) {
			#if DEV
			LogToGame(
				"*** Too many active alarms: %d/%d",
				g_iActiveAlarms,
				HDN_MAXALARMS
			);
			#endif
			return Plugin_Handled;
		}
		
		decl String:szClass[MAX_NAME_LENGTH];
		
		for (new i = 0; i < HDN_MAXALARMS; i++) {
			if (
				g_eActiveAlarms[i] != 0 &&
				(
					!IsValidEntity(g_eActiveAlarms[i]) ||								// Not a valid entity.
					!GetEdictClassname(g_eActiveAlarms[i], szClass, MAX_NAME_LENGTH) ||	// Couldn't get class-name
					strcmp (szClass, "npc_tripmine") != 0								// Wasn't a tripmine.
				)
			) {
				#if DEV
				LogToGame (
					"*** Culling invalid alarm %d found in slot %d.",
					g_eActiveAlarms[i],
					i
				);
				#endif
				g_eActiveAlarms[i] = 0;	//
			} else if (g_eActiveAlarms[i] == entity) {	// Alarm is already drawing
				#if DEV
				LogToGame(
					"*** Alarm %d already active in slot %d.",
					entity,
					i
				);
				#endif
				return Plugin_Handled;
			} else if (GetEntityDistance (g_eActiveAlarms[i], entity) <= g_flMinAlarmRange) {	// This alarm is too close to another active alarm.
				#if DEV
				LogToGame(
					"*** Alarm %d too close to active alarm %d in slot %d: %.2f/%.2f",
					entity,
					g_eActiveAlarms[i],
					i,
					GetEntityDistance (g_eActiveAlarms[i], entity),
					g_flMinAlarmRange
				);
				#endif
				return Plugin_Handled;
			}
		}
		
		g_iActiveAlarms++;
		new bool:bLoaded = false;
		
		for (new i = 0; i < HDN_MAXALARMS; i++) {
			if (
				!bLoaded &&
				g_eActiveAlarms[i] == 0
			) {
				g_eActiveAlarms[i] = entity;
				bLoaded = true;
			}
		}
		
		new Handle:hPack = CreateDataPack();
		WritePackCell (hPack, entity);																// Source entity.
		WritePackCell (hPack, HDN_RADIO_ALARM);														// Source's message
		WritePackCell (hPack, RoundToNearest((g_flRadioTimeouts[HDN_RADIO_ALARM])/g_flSpriteUpdate));	// Counter
		
		CreateTimer (g_flSpriteUpdate, tmr_DrawTraceSprites, hPack);
		
		#if DEV
		for (new i = 0; i < HDN_MAXALARMS; i++) {
			if (g_eActiveAlarms[i] == entity) {
				LogToGame(
					"*** Alarm %d in slot %d w/%d pings. %d/%d alarms active.",
					entity,
					i,
					RoundToNearest((g_flRadioTimeouts[HDN_RADIO_ALARM])/g_flSpriteUpdate),
					g_iActiveAlarms,
					HDN_MAXALARMS
				);
			}
		}
		#endif
	}
	
	EmitSoundToTeam (	// Emit sound from alarm's origin.
		HDN_TEAM_IRIS,
		ALIVE,
		"weapons/sonic/alarm.wav",
		entity,
		channel,
		level,
		SND_NOFLAGS,
		volume,
		pitch,
		NULL_VECTOR,
		NULL_VECTOR,
		true,
		0.0
	);
	
	new Handle:hKillPack = CreateDataPack();
	WritePackCell(hKillPack, entity);
	WritePackCell(hKillPack, channel);
	WritePackFloat(hKillPack, volume);
	WritePackCell(hKillPack, level);
	WritePackCell(hKillPack, pitch);
	
	CreateTimer (g_flRadioTimeouts[HDN_RADIO_ALARM], tmr_SilenceAlarmSound, hKillPack); // Kill the sound, if any.
	
	return Plugin_Handled;
}

/* Silence the alarm sound */
public Action:tmr_SilenceAlarmSound (Handle:timer, Handle:datapack) {
	ResetPack (datapack);
	new
		alarm	= ReadPackCell(datapack),
		channel	= ReadPackCell(datapack),
		Float:volume = ReadPackFloat(datapack),
		level	= ReadPackCell(datapack),
		pitch	= ReadPackCell(datapack)
	;
	CloseHandle (datapack);
	
	#if DEV > 1
	LogToGame("*** Killing sound from alarm %d at %.1f", alarm, volume);
	#endif
	
	EmitSoundToTeam (	// Emit sound from alarm's origin.
		HDN_TEAM_IRIS,
		_,
		"weapons/sonic/alarm.wav",
		alarm,
		channel,
		level,
		SND_STOPLOOPING,
		volume,
		pitch,
		NULL_VECTOR,
		NULL_VECTOR,
		true,
		0.0
	);
	
	return Plugin_Handled;
}

/* Scans spawned players and starts their sprite timers if required. */
public Action:event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast) {
	g_bInRound = true;
	
	g_iActiveAlarms = 0;
	
	return Plugin_Continue;
}

/* Kill any active timers */
public Action:event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast) {
	g_bInRound = false;
	
	return Plugin_Continue;
}

/* Draw the spectator sprites if there are any valid spectators */
public Action:tmr_DrawAuraSprites (Handle:timer) {
	if (!g_bInRound) return Plugin_Handled;	// Round has ended, we're shouldn't be here.
	
	decl
		Float:vSpritePos[3],
		Float:vTargetPos[3],
		Float:flRangeToSource,
		Float:flRangeOfHit,
		Float:flRangeScale,
		Float:flSpriteSize,
		clTrackable[MaxClients],
		eSprite,
		iSourceTeam,
		iTargetTeam,
		iHealth,
		iRange
	;
	
	for (new source = 1; source <= MaxClients; source++) {	// Cycle through Source clients.
		if (
			IsClientInGame (source) &&		// INGAME
			IsPlayerAlive (source)			// ALIVE
		) {
			new iTargetCount = 0;
			iSourceTeam = GetClientTeam (source);
			GetClientEyePosition(source, vSpritePos);
			vSpritePos[2] += g_iZOffset[iSourceTeam-2];
			if ( 2 <= iSourceTeam <= 3) {	// Valid team.
				for (new target = 1; target <= MaxClients; target++) {	// Cycle through Target clients.
					if (
						IsClientInGame (target) &&	// Target is IN_GAME
						!IsFakeClient (target) &&	// Target is not BOT
						target != source			// Target is not source
					) {
						if (!IsPlayerAlive (target)) {	// Target is DEAD
							if (
								g_iIRISAura > 0 ||				// IRIS mode is active in some way
								(
									iSourceTeam == HDN_TEAM_HIDDEN &&	// Client is HIDDEN
									(
										g_bAnyone ||								// Anyone can see the Hidden sprite
										GetUserAdmin (target) != INVALID_ADMIN_ID	// Target is an ADMIN
									)
								) &&
								!bIsClientObserving (target, source)		// Target is not observing client through helmet-cam
							) {
								clTrackable[iTargetCount++] = target;	// Add valid Target spectator.
							}
						} else {	// Target is ALIVE
							iTargetTeam = GetClientTeam (target);
							if (
								iTargetTeam == iSourceTeam &&			// Same team.
								(
									(
										iSourceTeam == HDN_TEAM_HIDDEN &&	// Hidden team
										!IsInAura (target)					// Not in aura.
									) ||
									(
										g_iIRISAura == 1 &&					// IRIS AURA enabled.
										iSourceTeam == HDN_TEAM_IRIS &&		// IRIS team
										IsInAura (target)					// In Aura
									)
								)
							) {
								GetClientEyePosition (target, vTargetPos);						// Target position.
								flRangeToSource = GetVectorDistance (vTargetPos, vSpritePos);	// Target's distance from Source.
									
								if (flRangeToSource < g_flRangeRadioMax) {	// Target close enough Source to bother with.
									TR_TraceRayFilter (						// Trace from Target to Source.
										vTargetPos,
										vSpritePos,
										MASK_ALL,
										RayType_EndPoint,
										TraceRayDontHitSelf,
										target
									);
									
									TR_GetEndPosition (vSpritePos);	// Get the coordinates that the trace did hit.
									flRangeOfHit = GetVectorDistance (vTargetPos, vSpritePos);	// Distance from target the source hit.
									flRangeScale = flRangeOfHit / flRangeToSource;
									
									iHealth = GetClientHealth (source);		// Source's health.
									
									if (iHealth <= g_iLowHealth[iSourceTeam-2]) iRange = 0;			// Red. 20 for Hidden, 37 for IRIS
									else if (iHealth <= g_iMedHealth[iSourceTeam-2]) iRange = 1;	// Orange. 60 fof Hidden, 74 for IRIS
									else iRange = 2;												// Green
									
									eSprite = g_eAuraModel[iSourceTeam-2][iRange],
									flSpriteSize = flRangeScale * g_flAuraSize[iSourceTeam-2];
									
									if (flSpriteSize < g_flMinSpriteSize) {	// Enforce minimum sprite size.
										flSpriteSize = g_flMinSpriteSize;
									}
									
									TE_SetupGlowSprite (	// Construct the radio sprite.
										vSpritePos,
										eSprite,
										g_flSpriteUpdate - 0.05,
										flSpriteSize,
										g_iAuraBrightness[HDN_TEAM_IRIS-2]
									);
									
									TE_SendToClient (target);	// Send radio sprite to Target.
								}
							}
						}
					}
				}
				
				if (iTargetCount) {								// A valid Target was found.
					iHealth = GetClientHealth (source);		// Source's health.
					
					if (iHealth <= g_iLowHealth[iSourceTeam-2]) iRange = 0;			// Red. 20 for Hidden, 37 for IRIS
					else if (iHealth <= g_iMedHealth[iSourceTeam-2]) iRange = 1;	// Orange. 60 fof Hidden, 74 for IRIS
					else iRange = 2;												// Green
					
					TE_SetupGlowSprite (	// Construct the spectator sprite.
						vSpritePos,
						g_eAuraModel[iSourceTeam-2][iRange],
						g_flSpriteUpdate - 0.05,
						g_flAuraSize[iSourceTeam-2],
						g_iAuraBrightness[iSourceTeam-2]
					);
					
					TE_Send (clTrackable, iTargetCount);	// Sent sprite to any Targets
				}	// No valid Targets found.
			}
		}
	}
	
	return Plugin_Continue;
}

/* Process Alarm sprites */
public Action:tmr_DrawTraceSprites (Handle:timer, Handle:datapack) {
	if (!g_bInRound) {
		#if DEV
		ResetPack(datapack);
		new
			DEVsource = ReadPackCell(datapack),
			DEVmessage = ReadPackCell(datapack),
			DEVdec = ReadPackCell(datapack)
		;		
		LogToGame(
			"*** Round has ended. Killing %d:%d's %d remaining pings",
			DEVsource,
			DEVmessage,
			DEVdec
		);
		#endif
		return Plugin_Handled;		// Round has ended, We're shouldn't be here.
	}
	
	decl
		Handle:hPack,
		String:szClass[MAX_NAME_LENGTH],
		Float:vSourcePos[3],
		Float:vSpritePos[3],
		Float:vTargetPos[3],
		Float:flRangeToSource,
		Float:flSpriteSize,
		Float:flRangeOfHit,
		Float:flRangeScale,
		eSource,
		eSprite,
		iMessage,
		iDec,
		iTargetTeam,
		iHealth,
		iRange
	;
	
	new
		iSourceTeam = 0
	;
	
	ResetPack(datapack);
	eSource = ReadPackCell(datapack);
	iMessage = ReadPackCell(datapack);
	iDec = ReadPackCell(datapack);
	CloseHandle(datapack);
	
	if (iDec < 1) {		// Counter has expired, we shouldn't even be here.
		#if DEV
		LogToGame("*** Counter is %d. Should not be processing %d's message: %d.", iDec, eSource, iMessage);
		#endif
		return Plugin_Handled;
	} else if (0 < eSource <= MaxClients) {	// Source is client.
		if (
			!IsPlayerAlive(eSource) ||									// Source is DEAD.
			(
				iMessage == HDN_RADIO_REQUESTAMMO &&					// Source had asked for AMMO
				GetEntProp (eSource, Prop_Send, "m_bRequestAmmo") == 0	// AMMO request fullfulled.
			)
		) {
			#if DEV > 1
			LogToGame("*** Client %d is no longer requesting ammo:%d.", eSource, iMessage);
			#endif
			return Plugin_Handled;		// Nothing to do. we're done here.
		}
		GetClientEyePosition(eSource, vSourcePos);
		iSourceTeam = GetClientTeam(eSource);
		vSourcePos[2] += g_iZOffset[iSourceTeam-2];
	} else if (
		!IsValidEntity(eSource) ||									// Not a valid entity.
		!GetEdictClassname(eSource, szClass, MAX_NAME_LENGTH) ||	// Couldn't get class-name
		strcmp (szClass, "npc_tripmine") != 0						// Wasn't a tripmine.
	) {
		g_iActiveAlarms--;
		for (new i = 0; i < HDN_MAXALARMS; i++) {
			if (g_eActiveAlarms[i] == eSource) {
				g_eActiveAlarms[i] = 0;
			}
		}
		#if DEV
		LogToGame(
			"*** Alarm %d is invalid, \"%s\" or not a \"%s\". %d/%d active alarms remaining.",
			eSource,
			szClass,
			"npc_tripmine",
			g_iActiveAlarms,
			HDN_MAXALARMS
		);
		#endif
		return Plugin_Handled;
	} else {	// Source was a trip alarm
		GetEntityPosition (eSource, vSourcePos);
	}
	
	for (new target = 1; target <= MaxClients; target++) {	// Cycle through Target clients.
		if (
			IsClientInGame (target) &&						// Target is IN_GAME
			IsPlayerAlive (target) &&						// Target is ALIVE
			!IsFakeClient (target) &&						// Target is not BOT
			target != eSource								// Target is not Source
		) {
			iTargetTeam = GetClientTeam (target);			// Get Target's team.
			if (
				iSourceTeam == iTargetTeam ||
				(
					iMessage == HDN_RADIO_ALARM &&
					iTargetTeam == HDN_TEAM_IRIS
				)
			) {
				for (new i = 0; i < 3; i++) vSpritePos[i] = vSourcePos[i];	// Reset sprite origin.
				
				GetClientEyePosition (target, vTargetPos);						// Target position.
				flRangeToSource = GetVectorDistance (vTargetPos, vSpritePos);	// Target's distance from Source.
					
				if (flRangeToSource < g_flRangeRadioMax) {	// Target close enough Source to bother with.
					TR_TraceRayFilter (						// Trace from Target to Source.
						vTargetPos,
						vSpritePos,
						MASK_ALL,
						RayType_EndPoint,
						TraceRayDontHitSelf,
						target
					);
					
					TR_GetEndPosition (vSpritePos);	// Get the coordinates that the trace did hit.
					flRangeOfHit = GetVectorDistance (vTargetPos, vSpritePos);	// Distance from target the source hit.
					flRangeScale = flRangeOfHit / flRangeToSource;
					
					if (
						IsInAura (target) &&
						iMessage != HDN_RADIO_ALARM
					) {
						iHealth = GetClientHealth (eSource);		// Source's health.
						
						if (iHealth <= g_iLowHealth[iSourceTeam-2]) iRange = 0;			// Red. 20 for Hidden, 37 for IRIS
						else if (iHealth <= g_iMedHealth[iSourceTeam-2]) iRange = 1;	// Orange. 60 fof Hidden, 74 for IRIS
						else iRange = 2;												// Green
						
						eSprite = g_eAuraModel[iSourceTeam-2][iRange];
						flSpriteSize = flRangeScale * g_flAuraSize[iSourceTeam-2];
					} else if (iMessage == HDN_RADIO_ALARM) {
						eSprite = g_eRadioModel[HDN_RADIO_ALARM];
						flSpriteSize = flRangeScale * g_flRadioBaseSize[HDN_RADIO_ALARM];
					} else {
						eSprite = g_eRadioModel[iMessage];
						flSpriteSize = flRangeScale * g_flRadioBaseSize[iMessage];
					}
						
					if (flSpriteSize < g_flMinSpriteSize) {	// Enforce minimum sprite size.
						flSpriteSize = g_flMinSpriteSize;
					}
					
					TE_SetupGlowSprite (	// Construct the radio sprite.
						vSpritePos,
						eSprite,
						g_flSpriteUpdate - 0.05,
						flSpriteSize,
						g_iAuraBrightness[HDN_TEAM_IRIS-2]
					);
					
					TE_SendToClient (target);	// Send radio sprite to Target.
				}
			}
		}
	}
	
	if (--iDec > 0) {	// We're not done yet...
		hPack = CreateDataPack();
		WritePackCell(hPack, eSource);
		WritePackCell(hPack, iMessage);
		WritePackCell(hPack, iDec);
		for (new i = 0; i < 3; i++) WritePackFloat(hPack, vSourcePos[i]);
		
		CreateTimer (g_flSpriteUpdate, tmr_DrawTraceSprites, hPack);
	} else if (iMessage == HDN_RADIO_ALARM) {	// We are done and it was an alarm.
		g_iActiveAlarms--;
		for (new i = 0; i < HDN_MAXALARMS; i++) {
			if (g_eActiveAlarms[i] == eSource) {
				#if DEV
				LogToGame(
					"*** Alarm %d in slot %d expired. %d/%d alarms active.",
					eSource,
					i,
					g_iActiveAlarms,
					HDN_MAXALARMS
				);
				#endif
				g_eActiveAlarms[i] = 0;
			}
		}
	}
	#if DEV > 2
	else {	// We are done and it was a client.
		LogToGame(
			"*** Client %d's radio message %d has expired.",
			eSource,
			iMessage
		);
	}
	#endif
	
	return Plugin_Continue;
}

public bool:TraceRayDontHitSelf (entityhit, mask, any:client) {
	return (entityhit != client);
}

// Returns whether or not the observer is viewing through the target's POV
stock bool:bIsClientObserving (const any:observer, const any:target) {
	return (GetEntPropEnt (observer, Prop_Send, "m_hObserverTarget") == target);
}

/* Wrapper to emit sound to all members of the team.
 *
 * @param team			Team index.
 * @param alive			Life state
 * @param sample			Sound file name relative to the "sounds" folder.
 * @param entity			Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume			Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin			Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 * @noreturn
 * @error				Invalid client index.
 */
stock EmitSoundToTeam (
	team = ANYONE,
	alive = ANYONE,
	const String:sample[],
	entity = SOUND_FROM_PLAYER,
	channel = SNDCHAN_AUTO,
	level = SNDLEVEL_NORMAL,
	flags = SND_NOFLAGS,
	Float:volume = SNDVOL_NORMAL,
	pitch = SNDPITCH_NORMAL,
	const Float:origin[3] = NULL_VECTOR,
	const Float:dir[3] = NULL_VECTOR,
	bool:updatePos = true,
	Float:soundtime = 0.0
) {
	decl clients[MaxClients];
	new totalClients = 0;

	for (new i=1; i<=MaxClients; i++) {
		if (
			IsClientInGame (i) &&				// Client is connected
			 (
				team == ANYONE ||				// Specified team is ALL
				GetClientTeam (i) == team		// Client is on specified team.
			) &&
			 (
				alive == ANYONE ||				// Specified life is ANY
				IsPlayerAlive (i) == bool:alive	// Client is on specified life state.
			)
		) {
			clients[totalClients++] = i;
		}
	}
	
	if (totalClients) {
		EmitSound (
			clients,
			totalClients,
			sample,
			entity,
			channel,
			level,
			flags,
			volume,
			pitch,
			entity,
			origin,
			dir,
			updatePos,
			soundtime
		);
	}
}

/* Sets vec[] to the entity's position */
stock GetEntityPosition(const any:entity, Float:vec[3]) {
	GetEntPropVector (entity, Prop_Send, "m_vecOrigin", vec);
}

/* Returns aura state. on: true, off: false */
stock bool:IsInAura(const any:client) {
	if (GetClientTeam (client) == HDN_TEAM_IRIS) {
		if (GetClientButtons (client) & IN_AURA) {
			return true;
		} else {
			return false;
		}
	} else {
		return (GetEntProp(client, Prop_Send, "m_bAura") == 1);
	}
}

/* Returns the distance between 2 entities */
stock Float:GetEntityDistance (const any:entity1, const any:entity2, const bool:squared=false) {
	if (
		IsValidEntity(entity1) &&	// Entity1 is valid.
		IsValidEntity(entity2)		// Entity2 is valid.
	) {
		decl
			Float:vEnt1Pos[3],
			Float:vEnt2Pos[3]
		;
		
		GetEntityPosition (entity1, vEnt1Pos);
		GetEntityPosition (entity2, vEnt2Pos);
		
		return GetVectorDistance (vEnt1Pos, vEnt2Pos, squared);
	}
	
	return -1.0;
}
