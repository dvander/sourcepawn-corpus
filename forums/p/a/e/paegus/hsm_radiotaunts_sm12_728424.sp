/*
 * Hidden:SourceMod - Radio Proximity Taunts
 *
 * Description:
 *  Plays radiotaunts#.mp3 over the IRIS's radio if a corpse_ragdoll is close enough when a hidden taunts.
 *
 * Console Variables:
 *  hsm_rpt_chat [0/1] : Successfully radioed taunts appear in global chat? 0: No, 1:Yes. Default: 1
 *  hsm_rpt_auto [0~1] : Chance for Hidden to automatically taunt when he kills. 0: Never. 1: Always. Default: 0
 *  hsm_rpt_last [0~1] : Alternate chance for Hidden to automatically taunt on the 2nd to last possible kill. 0: No alternate. 1: Always. Default: 0.333333
 *
 * Commands:
 *
 * Change-log:
 *  v1.0.2
 *   Set last-kill auto-taunt to be only "You're Next" (or "I'm coming for you" if you've altered the server's sound file. Manual taunts remain.
 *   Fixed error on World damage.
 *  v1.0.1
 *   Added chances to automatically taunt on each kill and 2nd to last possible kill.
 *   Removed dependency on hidden & toteam includes.
 *  v1.0.0
 *   Initial release.
 *
 * Known Issues:
 *
 * To-Do:
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net
 *  Hidden:Source: http://www.hidden-source.com
 */

#define PLUGIN_VERSION	"1.0.2"

#pragma semicolon 1

#define EITHER		-1
#define DEAD		0
#define LIVING		1
#define TEAM_ANY	-1
#define TEAM_ALL	-1
#define TEAM_NONE	0
#define TEAM_SPEC	1

#define HDN_TEAM_IRIS	2
#define HDN_TEAM_HIDDEN	3
#define HDN_MAXPLAYERS	10

#include <sdktools>

public Plugin:myinfo = {
	name		= "H:SM - Radio Proximity Taunts",
	author		= "Paegus",
	description	= "Plays radiotaunts#.mp3 over the IRIS's radio if a corpse_ragdoll is close enough when a hidden taunts.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=728424"
}

static const String:g_szClass[] = "corpse_ragdoll";	// corpse_ragdoll... pretty self-explanatory i would have thought.
static const Float:g_flMaxRange = 256.0;			// Farthest a Hidden can be from a corpse_ragdoll to trigger the radio broadcast.
static const Float:g_flDeathTimer = 0.1;			// Delay to check player's death in case of health alterations from other plugins.
new Handle:g_cvChat = INVALID_HANDLE;				// Does the radioed message appear in global chat?
new Handle:g_cvAuto = INVALID_HANDLE;				// 1 in this chance to auto-taunt on kill.
new Handle:g_cvLast = INVALID_HANDLE;				// 1 in this chance to auto-taunt on 2nd to last kill.
new g_iAttTrack[HDN_MAXPLAYERS+1] = { -1, ...};		// Tracks who attacked an IRIS. Since you can only pass 1 non-arrayed parameter to a timer :(

public OnPluginStart() {
	CreateConVar(
		"hsm_rpt_version",
		PLUGIN_VERSION,
		"H:SM - Radio Taunt version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	
	g_cvChat = CreateConVar(
		"hsm_rpt_chat",
		"1",
		"Successfully radioed taunts appear in global chat? 0: No, 1:Yes.",
		_,
		true, 0.0,
		true, 1.0
	);
	
	g_cvAuto = CreateConVar(
		"hsm_rpt_auto",
		"0",
		"Chance for Hidden to automatically taunt when he kills. 0: Never. 1: Always.",
		_,
		true, 0.0,
		true, 1.0
	);
	
	g_cvLast = CreateConVar(
		"hsm_rpt_last",
		"0.333333",
		"Alternate chance for Hidden to automatically taunt on the 2nd to last possible kill. 0: No alternate. 1: Always.",
		_,
		true, 0.0,
		true, 1.0
	);
	
	AddNormalSoundHook(NormalSHook:hook_Sound); // A sound is played.
	
	if ((GetConVarFloat(g_cvAuto) + GetConVarFloat(g_cvLast)) > 0) {
		HookEvent("player_hurt", event_Hurt);	// Auto taunting is active.
	}
	
	HookConVarChange(g_cvAuto, convar_Change);
	HookConVarChange(g_cvLast, convar_Change);
}

/**
 * If either Auto or Last-Chances are enabled or disabled while the other is disabled, enable or disable the player_hurt hook to match.
 */
public convar_Change(
	Handle:convar,
	const String:oldVal[],
	const String:newVal[]
) {
	if (
		(convar == g_cvAuto && GetConVarFloat(g_cvLast) == 0) ||
		(convar == g_cvLast && GetConVarFloat(g_cvAuto) == 0)
	) {
		if (StringToFloat(newVal) > 0) {
			HookEvent("player_hurt", event_Hurt);
		} else {
			UnhookEvent("player_hurt", event_Hurt);
		}
	}
}

/**
 * Check for the 617-radiotaunts#.mp3 from a hidden and if there's a corpse_ragdoll close enough, send broadcast through IRIS radio
 */
public Action:hook_Sound(
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
	if (StrContains(sample,"player/hidden/voice/617-radiotaunts") == -1) return Plugin_Continue;	// Isn't a Hidden's radiotaunt so we're not interested
	if (!IsClientInGame(entity)) return Plugin_Continue;	// Didn't come from a client
	if (GetClientTeam(entity) != HDN_TEAM_HIDDEN) return Plugin_Continue; 	// Didn't come from the hidden... what the?
	
	decl Float:vSourcePos[3];
	GetClientEyePosition(
		entity,
		vSourcePos
	);	// the hidden's position
	
	new Float:flClosest = g_flMaxRange + 0.1;
	new eTarget = FindEntityByClassname(0, g_szClass);
	
	// Scroll through all available targets and find the closest.
	while (eTarget != -1) {
		decl Float:vTargetPos[3];
		GetEntPropVector(
			eTarget,
			Prop_Send,
			"m_vecOrigin",
			vTargetPos
		);	// target entity's position.
		
		new Float:flRange = GetVectorDistance(vSourcePos, vTargetPos);
		
		if (flRange <= flClosest) flClosest = flRange; // update Closest range
		
		eTarget = FindEntityByClassname(eTarget, g_szClass);
	}
	
	if (flClosest <= g_flMaxRange) { // We found a valid target within range. 
		new Float:flVolume = 1.0 - (flClosest / g_flMaxRange);	// Scale the sound volume by the distance.
		decl String:szNewSample[48];
	
		new iOffset = StrContains(sample, ".mp3", false);
		Format(
			szNewSample,
			sizeof(szNewSample),
			"player/iris/IRIS-617radiotaunts0%c.mp3",
			sample[iOffset-1]
		); // Build the IRIS radio version
		
		if (GetConVarBool(g_cvChat)) {
			switch (sample[iOffset-1]) {
				case 49, 50: { 		// You're Next 
					ClientCommand(entity, "say You're Next!");
				}
				case 51, 55, 56: {	// Fresh Meat
					ClientCommand(entity, "say Fresh Meat!");
				}
				case 52, 53, 54: {	// I'm coming for you
					ClientCommand(entity, "say I'm coming for you!");
				}
			}
		}
		
		PrecacheSound(szNewSample, true);
		
		EmitSoundToTeam(
			HDN_TEAM_IRIS,
			LIVING,
			szNewSample,
			_,
			_,
			_,
			SND_CHANGEVOL,
			flVolume
		); // Emit sound to living IRIS
	}
	
	return Plugin_Continue;
}

/**
 * If an IRIS was attacked by a HIDDEN and the chances are successful, check the IRIS is actually dead and taunt.
 */
public Action:event_Hurt(
	Handle:event,
	const String:name[],
	bool:dontBroadcast
) {
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iAttTrack[iVictim] = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (g_iAttTrack[iVictim] == 0) {
		return Plugin_Continue;
	}
	
	if (
		GetClientTeam(g_iAttTrack[iVictim]) != HDN_TEAM_HIDDEN ||
		GetClientTeam(iVictim) != HDN_TEAM_IRIS ||
		GetClientHealth(iVictim) > 0
	) {
		return Plugin_Continue;
	}
	
	new bAutoTaunt = false;
	new iCount = GetLifeState(HDN_TEAM_IRIS, LIVING);
	new Float:flAutoChance = GetConVarFloat(g_cvAuto);
	new Float:flLastChance = GetConVarFloat(g_cvLast);
	
	if (flAutoChance > 0) {
		if (iCount > 0 && GetRandomInt(1,RoundToNearest(1.0 / flAutoChance)) == 1) {
			bAutoTaunt = true;
		}
	} else if (flLastChance > 0) {
		if (iCount < 2 && GetRandomInt(1,RoundToNearest(1.0 / flLastChance)) == 1) {
			bAutoTaunt = true;
		}
	}
	
	if (bAutoTaunt) {
		CreateTimer(g_flDeathTimer, tmr_StayedDead, iVictim);
	}
	
	return Plugin_Continue;
}

/**
 * Check if the player is still dead.
 */
public Action:tmr_StayedDead(
	Handle:timer,
	any:iVictim
) {
	new count = GetLifeState(HDN_TEAM_IRIS, LIVING);
	if (IsClientInGame(g_iAttTrack[iVictim])) {
		if (IsPlayerAlive(g_iAttTrack[iVictim])) {
			if (count < 2) {
				ClientCommand(g_iAttTrack[iVictim], "radio %d", 7);	// Only 1 player left so "You're next".
			} else if (count > 1) {
				ClientCommand(g_iAttTrack[iVictim], "radio %d", GetRandomInt(6,7)); // More than 1 player left so either.
			}
		}
	}
}

/**
 * Wrapper to emit sound to all members of the team.
 *
 * @param team			Team index.
 * @param alive			Life state
 * @param sample		Sound file name relative to the "sounds" folder.
 * @param entity		Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume		Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin		Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 *
 * @noreturn
 * @error				Invalid client index.
 */
stock EmitSoundToTeam(
	client_team = TEAM_ALL,
	client_state = EITHER,
	const String:sample[],
	entity = SOUND_FROM_PLAYER,
	channel = SNDCHAN_AUTO,
	level = SNDLEVEL_NORMAL,
	flags = SND_NOFLAGS,
	Float:volume = SNDVOL_NORMAL,
	pitch = SNDPITCH_NORMAL,
	speakerentity = -1,
	const Float:origin[3] = NULL_VECTOR,
	const Float:dir[3] = NULL_VECTOR,
	bool:updatePos = true,
	Float:soundtime = 0.0
) {
	decl clients[MaxClients];
	new numClients = 0;

	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (client_team == TEAM_ALL || GetClientTeam(i) == client_team) {
				if (
					(client_state == EITHER) ||
					(client_state == LIVING && IsPlayerAlive(i)) ||
					(client_state == DEAD && !IsPlayerAlive(i))
				) {
					clients[numClients++] = i;
				}
			}
		}
	}

	if (!numClients) return;

	EmitSound(
		clients,
		numClients,
		sample,
		entity,
		channel,
		level,
		flags,
		volume,
		pitch,
		speakerentity,
		origin,
		dir,
		updatePos,
		soundtime
	);
}

/**
 * Numerical GetClientTeam() & IsPlayerAlive()
 *
 * @param client_team	Target team index.
 * @param client_state	Target life state
 *
 * @return				Number of clients matching team and state
 */
stock GetLifeState(
	client_team = TEAM_ALL,
	client_state = EITHER
) {
	decl bool:client_alive;
	new count = 0;
	for (new i = 1; i <= MaxClients; i++ ) {
		if (IsClientInGame(i)) {
			if (
				(client_team == TEAM_ALL) ||
				(GetClientTeam(i) == client_team)
			) {
				client_alive = GetClientHealth(i) > 0;
				if (
					(client_state == EITHER) ||
					(client_state == DEAD && client_alive) ||
					(client_state == LIVING && client_alive)
				) {
					count++;
				}
			}
		}
	}
	
	return count;
}
