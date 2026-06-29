/*
 * Hidden:SourceMod - Radio+
 *
 * Description:
 *  Enabled additional radio commands from clients.
 *
 * Cvars:
 *  hsm_radioplus_access [level] Admin access level required to run custom radio commands.
 *
 * Commands:
 *  radio [#|GROUP SOUNDFILE PHRASE]: Allow the use of additional or custom radio message. # can be 9 for 'Negative' and 11 for 'Secure Location'. 0~7 are the 8 default radio messages. 8 is used by the Request backup plugin. GROUP is either team or all, SOUNDFILE is any valid audio file present in the server file system that does NOT contain a space in the name (remember to set custom ones to download) and PHRASE can be any chat message.
 *
 * Changelog:
 *  v1.0.0
 *   Initial release
 *
 * Known Issues:
 *  v1.0.0
 *   The text parsing hasn't been enabled so %L is not yet replaced by your location, etc...
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */

#define PLUGIN_VERSION		"1.0.0"

#define MAX_CHAT_LENGTH		1024

#define HDN_TEAM_IRIS		2
#define HDN_TEAM_HIDDEN		3

#define DEAD_ONLY			-1
#define ANYONE				0
#define ALIVE_ONLY			1
#define TEAM_ALL			-1

#include <sdktools>

public Plugin:myinfo = {
	name		= "H:SM - Radio+",
	author		= "Paegus",
	description	= "Enabled additional radio commands from clients.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=699598"
}

new	AdminFlag:g_afAdminLevel	= Admin_Kick,
	Handle:cvarAccess			= INVALID_HANDLE,
	String:gszClientLocation[MAXPLAYERS][MAX_NAME_LENGTH]

public OnPluginStart() {
	CreateConVar(
		"hsm_radioplus_version",
		PLUGIN_VERSION,
		"H:SM - Radio+ version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	
	cvarAccess = CreateConVar(
		"hsm_radioplus_access",
		"c",
		"Admin level to allow playing customized radio strings in the form of \"radio Group SoundFile Phrase\"\n   Group must be either team or all.\n   SoundFile can be any valid audio file.\n     %R+x~y results in a random number between x and y. If + is included then the number is automatically padded\n   Phrase can be a number of words to say as a phrase.\n     %L is your Location.\n          %H is your Health.\n     %A is your remaining ammunition."
	)
	
	HookEventEx("player_location", event_PlayerLocation)
	HookEventEx("iris_radio", event_Radio)
	
	RegConsoleCmd("radio", cmd_Radio)
	
	HookConVarChange(cvarAccess, convar_Change)
}

public OnMapStart() {
	for (new i = 1; i < MaxClients; i++ ) {
		gszClientLocation[i][0] = '\0'	// Clear location arrays
	}
}

// Configure access level
public convar_Change(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (convar == cvarAccess) {
		switch (CharToLower(newVal[0])) {
			case 'a': {	//"reservation"	"a"			//Reserved slots
				g_afAdminLevel = Admin_Reservation;
			}
			case 'b': {	//"generic"		"b"			//Generic admin, required for admins
				g_afAdminLevel = Admin_Generic;
			}
			case 'c': {	//"kick"		"c"			//Kick other players
				g_afAdminLevel = Admin_Kick;
			}
			case 'd': {	//"ban"			"d"			//Banning other players
				g_afAdminLevel = Admin_Ban;
			}
			case 'e': {	//"unban"		"e"			//Removing bans
				g_afAdminLevel = Admin_Unban;
			}
			case 'f': {	//"slay"		"f"			//Slaying other players
				g_afAdminLevel = Admin_Slay;
			}
			case 'g': {	//"changemap"	"g"			//Changing the map
				g_afAdminLevel = Admin_Changemap;
			}
			case 'h': {	//"cvars"		"h"			//Changing cvars
				g_afAdminLevel = Admin_Convars;
			}
			case 'i': {	//"config"		"i"			//Changing configs
				g_afAdminLevel = Admin_Config;
			}
			case 'j': {	//"chat"		"j"			//Special chat privileges
				g_afAdminLevel = Admin_Chat;
			}
			case 'k': {	//"vote"		"k"			//Voting
				g_afAdminLevel = Admin_Vote;
			}
			case 'l': {	//"password"	"l"			//Password the server
				g_afAdminLevel = Admin_Password;
			}
			case 'm': {	//"rcon"		"m"			//Remote console
				g_afAdminLevel = Admin_RCON;
			}
			case 'n': {	//"cheats"		"n"			//Change sv_cheats and related commands
				g_afAdminLevel = Admin_Cheats;
			}
			case 'o': {	//"custom1"		"o"
				g_afAdminLevel = Admin_Custom1;
			}
			case 'p': {	//"custom2"		"p"
				g_afAdminLevel = Admin_Custom2;
			}
			case 'q': {	//"custom3"		"q"
				g_afAdminLevel = Admin_Custom3;
			}
			case 'r': {	//"custom4"		"r"
				g_afAdminLevel = Admin_Custom4;
			}
			case 's': {	//"custom5"		"s"
				g_afAdminLevel = Admin_Custom5;
			}
			case 't': {	//"custom6"		"t"
				g_afAdminLevel = Admin_Custom6;
			}
			case 'z': {	//"root"		"z"			// Access to all.
				g_afAdminLevel = Admin_Root;
			}
			default: {	//no level specified. everyone can use it
				g_afAdminLevel = INVALID_ADMIN_ID;
			}
		}
	}
}

// Is the client allowed to spectate the hidden through?
stock bool:ClientPermitted (const any:client) {
	if (g_afAdminLevel == INVALID_ADMIN_ID) {	// No access levels required. Everyone can spectate hidden.
		return true;
	} else {	// Access level specified.
		new AdminId:aiClient = GetUserAdmin (client);
		return (
			aiClient != INVALID_ADMIN_ID &&							// Client is an admin of some kind.
			//GetAdminFlags (aiClient, Access_Real) & ADMFLAG_KICK	// Client has needed access
			GetAdminFlag (aiClient, g_afAdminLevel)					// Client has needed access
		);
	}
}

// Store current locations.
public Action:event_PlayerLocation(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	GetEventString(event, "location", gszClientLocation[client], MAX_NAME_LENGTH)
}

// Intercept normal radio commands.
public Action:event_Radio(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid")) // Get the person who called the radio.
	
	decl String:szMessage[128]
	decl String:szClientName[MAX_NAME_LENGTH]
	
	GetClientName(client, szClientName, MAX_NAME_LENGTH)
	GetEventString(event, "message", szMessage, 128)
	//LogToGame("[Radio+] %02i:%s radio \"%s\"", client, szClientName, szMessage)
	
	decl String:szSound[PLATFORM_MAX_PATH]
	decl String:szChat[MAX_CHAT_LENGTH]
	szChat[0] = '\0'	// Null the string.
	
	new
		bValidMessage	= false,
		bTeamOnly		= false
	
	if (IsHidden(client)) {
		// Process hidden radio
	} else if (IsIRIS(client)) {
		// Process IRIS radio
		switch (GetEventInt(event, "message")) {
			case 9: {
				Format(
					szSound,
					PLATFORM_MAX_PATH,
					"player/IRIS/IRIS-negative%02i.wav",
					GetRandomInt(1,4)
				)
				
				Format(
					szChat,
					MAX_CHAT_LENGTH,
					"Negative!"
				)
				
				bTeamOnly		= true
				bValidMessage	= true
			}
			case 11: {
				Format(
					szSound,
					PLATFORM_MAX_PATH,
					"player/IRIS/IRIS-securearea%02i.wav",
					GetRandomInt(1,4)
				)
				
				Format(
					szChat,
					MAX_CHAT_LENGTH,
					"Secure %s!",
					gszClientLocation[client]
				)
				
				bTeamOnly		= true
				bValidMessage	= true
			}
		}
	}
	

	if (!bValidMessage) {	// Radio message wasn't valid so we're done here.
		return Plugin_Continue;
	}
	
	new Float:vEyePos[3];
	GetClientEyePosition(client, vEyePos); // Get attacker's facial position.
	
	new Float:vEyeDir[3];
	GetClientEyeAngles(client, vEyeDir); // Get attacker's facial direction.
	
	PrecacheSound(szSound, true); // Precache the sound now. Can't be arsed to list them all.
	
	if (strlen(szChat)) {
		if (bTeamOnly) {
			FakeClientCommand(client, "say_team %s", szChat)
		} else {
			FakeClientCommand(client, "say %s", szChat)
		}
	}	// No chat string defined.
	
	if (bTeamOnly) {
		EmitSoundToTeam(
			HDN_TEAM_HIDDEN,
			ANYONE,
			szSound,
			client,
			SNDCHAN_AUTO,
			SNDLEVEL_MINIBIKE,
			SND_NOFLAGS,
			SNDVOL_NORMAL,
			SNDPITCH_NORMAL,
			client,
			vEyePos,
			vEyeDir,
			true,
			0.0
		) // Emit sound hiddens as positional.
		EmitSoundToTeam(
			HDN_TEAM_IRIS,
			ANYONE,
			szSound
		) // Emit sound IRIS as local
	} else {
		EmitSoundToTeam(
			TEAM_ALL,
			ANYONE,
			szSound,
			client,
			SNDCHAN_AUTO,
			SNDLEVEL_MINIBIKE,
			SND_NOFLAGS,
			SNDVOL_NORMAL,
			SNDPITCH_NORMAL,
			client,
			vEyePos,
			vEyeDir,
			true,
			0.0
		) // Emit sound to Victim from Attacker.
	}
	return Plugin_Continue;
}

public Action:cmd_Radio (client, argc) {
	if (!ClientPermitted(client)) return Plugin_Continue	// Not permitted!
	
	decl String:szMessage[MAX_CHAT_LENGTH]
	decl String:szGroup[MAX_NAME_LENGTH]
	decl String:szSoundAndPhrase[MAX_CHAT_LENGTH]
	decl String:szSoundFile[PLATFORM_MAX_PATH]
	decl String:szPhrase[MAX_CHAT_LENGTH]
	
	//LogToGame("[Radio+] Message: [%s]", szMessage)
	
	szGroup[0]			= '\0'
	szSoundAndPhrase[0]	= '\0'
	szSoundFile[0]		= '\0'
	szPhrase[0]			= '\0'
	
	decl String:szClientName[MAX_NAME_LENGTH]
	GetCmdArgString(szMessage, MAX_CHAT_LENGTH);
	
	GetClientName(client, szClientName, MAX_NAME_LENGTH)
	//LogToGame("[Radio+] %02i:%s radio [%s]", client, szClientName, szMessage)
	
	new bool:bTeamOnly = false
	
	new breakpos = StrContains(szMessage, " ", false)
	
	if (breakpos == -1) {
		return Plugin_Continue
	}
	
	strcopy(szGroup, breakpos+1, szMessage)
	szGroup[breakpos+2] = '\0'
	//LogToGame("[Radio+] Group:   [%s]", szGroup)
	
	if (StrContains(szGroup, "team", false) == 0) {
		bTeamOnly = true
	}
	
	new maxmessage = strlen(szMessage)
	
	for (new i = 0; i < (maxmessage - breakpos); i++) {	// Cycle though string
		szSoundAndPhrase[i] = szMessage[i+breakpos+1]
	}
	szSoundAndPhrase[maxmessage - breakpos] = '\0'
	
	//LogToGame("[Radio+] S&P:     [%s]", szSoundAndPhrase)
	
	breakpos = StrContains(szSoundAndPhrase, " ", false)
	
	if (breakpos > -1) {
		// There's a say-phrase.
		
		strcopy(szSoundFile, breakpos+1, szSoundAndPhrase)
		szSoundFile[breakpos+2] = '\0'
		
		new String:szSoundFilePath[PLATFORM_MAX_PATH] = "sound/"
		StrCat(szSoundFilePath,PLATFORM_MAX_PATH,szSoundFile)
		
		//LogToGame("[Radio+] Sound:   [%s]", szSoundFilePath)
		
		if (!FileExists(szSoundFilePath, true)) {
			ReplyToCommand(client, "[Radio+] No such file \"%s\" found in filesystem. Aborting!", szSoundFilePath)
			return Plugin_Handled
		}
		
		new Float:vEyePos[3];
		GetClientEyePosition(client, vEyePos); // Get attacker's facial position.
		
		new Float:vEyeDir[3];
		GetClientEyeAngles(client, vEyeDir); // Get attacker's facial direction.
		
		PrecacheSound(szSoundFile, true)
		
		if (bTeamOnly) {
			EmitSoundToTeam(
				HDN_TEAM_HIDDEN,
				ANYONE,
				szSoundFile,
				client,
				SNDCHAN_AUTO,
				SNDLEVEL_MINIBIKE,
				SND_NOFLAGS,
				SNDVOL_NORMAL,
				SNDPITCH_NORMAL,
				client,
				vEyePos,
				vEyeDir,
				true,
				0.0
			) // Emit sound hiddens as positional.
			EmitSoundToTeam(
				HDN_TEAM_IRIS,
				ANYONE,
				szSoundFile
			) // Emit sound IRIS as local
		} else {
			EmitSoundToTeam(
				TEAM_ALL,
				ANYONE,
				szSoundFile,
				client,
				SNDCHAN_AUTO,
				SNDLEVEL_MINIBIKE,
				SND_NOFLAGS,
				SNDVOL_NORMAL,
				SNDPITCH_NORMAL,
				client,
				vEyePos,
				vEyeDir,
				true,
				0.0
			) // Emit sound to Victim from Attacker.
		}
		
		maxmessage = strlen(szSoundAndPhrase)
		
		for (new i = 0; i < (maxmessage - breakpos); i++) {	// Cycle though string
			szPhrase[i] = szSoundAndPhrase[i+breakpos+1]
			if (szSoundAndPhrase[i+breakpos+1] == '\0') break
		}
		
		//LogToGame("[Radio+] Phrase:  [%s]", szPhrase)
		
		if (strlen(szPhrase)) {
			if (bTeamOnly) {
				FakeClientCommand(client, "say_team %s", szPhrase)
			} else {
				FakeClientCommand(client, "say %s", szPhrase)
			}
		}
	}
	
	return Plugin_Handled
}



// Return true if valid player.
stock bool:IsPlayer(const any:client) {
	return(
		client &&
		IsClientInGame(client) &&
		IsPlayerAlive(client)
	)
}

// Returns true if client is IRIS player.
stock bool:IsIRIS(const any:client) {
	return (
		IsPlayer(client) &&
		GetClientTeam(client) == HDN_TEAM_IRIS
	)
}

// Returns true if client is Hidden player.
stock bool:IsHidden(const any:client) {
	return (
		IsPlayer(client) &&
		GetClientTeam(client) == HDN_TEAM_HIDDEN
	)
}

/**
 * Wrapper to emit sound to all members of the team.
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
stock EmitSoundToTeam(
	team					= TEAM_ALL,
	alive					= ANYONE,
	const String:sample[],
	entity					= SOUND_FROM_PLAYER,
	channel					= SNDCHAN_AUTO,
	level					= SNDLEVEL_NORMAL,
	flags					= SND_NOFLAGS,
	Float:volume			= SNDVOL_NORMAL,
	pitch					= SNDPITCH_NORMAL,
	speakerentity			= -1,
	const Float:origin[3]	= NULL_VECTOR,
	const Float:dir[3]		= NULL_VECTOR,
	bool:updatePos			= true,
	Float:soundtime			= 0.0
)
{
	new total = 0
	decl clients[MAXPLAYERS]
	
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (
				team == TEAM_ALL ||
				GetClientTeam(i) == team
			) {
				if (
					alive == ANYONE ||
					(
						alive == ALIVE_ONLY &&
						IsPlayerAlive(i)
					) ||
					(
						alive == DEAD_ONLY &&
						!IsPlayerAlive(i)
					)
				) {
					clients[total++] = i;
				}
			}
		}
	}

	if (!total) {
		return;
	}

	EmitSound(
		clients,
		total,
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

