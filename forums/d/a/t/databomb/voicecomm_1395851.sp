/* Advanced Voice Communications Plugin
   by: databomb
   Original Compile Date: 01.17.2011
   
   Requirements:
   This plugin absolutely requires an sdktools extension from after March 8, 2011. If used without an updated sdktools then your settings are guaranteed to fail given enough time. (http://bugs.alliedmods.net/show_bug.cgi?id=4804)
   
   Description:
   This plugin is a supplement to the standard basecomm.sp written by AlliedModdders LLC. This version adds several voice options for dead talk geared towards gungame/hosties/jailbreak servers where team-play isn't key. The voice options from sm_deadtalk are: Dead all talk (dead players can talk across teams but alive players will not hear them) and mute on death.  It also allows for a configurable team to be muted at the beginning of a round for so many seconds in addition to many more options to find the right fit for your server.
   
   It also adds timed and permanent punishments to the basecomm commands (mute, gag, silence) all without needing to replace the vanilla basecomm plugin (hint: sourcebans, look at this.)  The timed punishments use the ClientPrefs database and the times can range between 1 - 65,535 minutes or be of indefinite length.  The times will only expire or countdown when a player is in the game so use more conservative numbers when handing out timed punishments.  
   
   Features:
   Allows Dead All Talk mode (sm_deadtalk -2)
   Allows timed or permanent punishments with basecomm commands (mute, gag, silence)
   Allows players to be muted on death (sm_deadtalk -1)
   Integrates with SourceMod and ensures your mutes are enforced properly
   Admin over-rides for deadtalk options (requires ADMFLAG_CHAT)
   Option to enable all talk between each round
   Option to mute spectators if they're not admins (admins can talk to everyone from spectator)
   Option to mute a team for a certain time starting from the beginning of each round
   
   Command Usage:
   sm_listmutes
   Lists all players who are administratively muted (note this doesn't include effective mute status as enforced by plugins, only those registered with sm_mute will be counted)
   
   sm_mute <target> <optional:time>
   sm_gag <target> <optional:time>
   sm_silence <target> <optional:time>
   Allows you to specify an optional time value (in minutes) the player must spend in the server before being unpunished. A time of 0 indicates a permanent punishment.
   
   sm_unmute <target> [optional:'force']
   sm_ungag <target> [optional:'force']
   sm_unsilence <target> [optional:'force']
   Allows you to specify an optional 'force' text value specifying that all timed or permanent punishments will be forcibly removed. If you don't specify this then the player will have an effective un-muted status but remain punished when they re-connect. This is so admins can target large groups such as @alive or @!me and not worry about erasing all punishment data.
   
   Settings: Values in () indicate defaults
   sm_deadtalk [-2,-1,(0),1,2]
   
   sm_deadtalk 0: normal operation (follows sv_alltalk)
   sm_deadtalk -1: Mutes players after their death
   sm_deadtalk -2: Dead all talk 
   sm_deadtalk 1: equivalent of sm_deadtalk 1 (dead players ignore teams)
   sm_deadtalk 2: equivalent of sm_deadtalk 2 (teammates can always talk)
   
   sm_voicecomm_RoundEndAlltalk [0,(1)]: If enabled, all talk is enabled between rounds.
   sm_voicecomm_Announce [0,(1)]: If enabled, sends messages to the server and clients about their current voice status.
   sm_voicecomm_TeamTalk [(0),1]: If enabled, players talk to only their teammates when alive.
   sm_voicecomm_SpectatorMute [0,(1)]: If enabled, spectators are muted unless they're an admin.
   sm_voicecomm_MutedTeam [1,(2),3]: Determines which team will start muted, defaults to 2 which is the Terrorists on CS:S.
   sm_voicecomm_StartMuted [(0),1]: If enabled, the team you specify will be muted for the time you specify at the beginning of every round.
   sm_voicecomm_MuteTime <time>  (29.0 seconds):  Controls the length (in seconds) of the mute for the team specified.
   sm_voicecomm_DeadHearAlive [0,(1)]: If enabled, the dead will still hear alive players.
   sm_voicecomm_BlockUnmuteOnReconnect [0,(1)]: If enabled, muted players who reconnect will not be unmuted until the map changes or manually unmuted by an admin.
	sm_voicecomm_AdmOvrd_FirstJoin [0,(1)]: If enabled, admins who first join will be allowed to talk.
	sm_voicecomm_AdmOvrd_Death [0,(1)]: If enabled, admins who die are allowed to talk with everyone.
	sm_voicecomm_AdmOvrd_Spectate [0, (1)]: If enabled, admins speak with everyone on round start.
   
   Sample Configurations:
   Casual Pub (Team-only while alive but dead all talk)
   sv_alltalk 0
   sm_deadtalk -2
   sm_voicecomm_teamtalk 1
   sm_voicecomm_startmuted 0
   
   Gun-Game (Cross-team and dead all talk)
   sv_alltalk 0
   sm_deadtalk -2
   sm_voicecomm_teamtalk 0
   sm_voicecomm_startmuted 0
   
   Small-Medium Jailbreak (Cross-team and dead all talk with 15 second mute for Terrorists)
   sv_alltalk 0
   sm_deadtalk -2
   sm_voicecomm_teamtalk 0
   sm_voicecomm_mutedteam 2
   sm_voicecomm_startmuted 1
   sm_voicecomm_mutetime 15.0
   
   Large Jailbreak (Cross-team and mute on death with 15 second mute for Terrorists)
   sv_alltalk 1
   sm_deadtalk -1
   sm_voicecomm_mutedteam 2
   sm_voicecomm_startmuted 1
   sm_voicecomm_mutetime 15.0
   
   Future considerations:
     - Add additional options
     
   Special Thanks:
   FLOOR_MASTER - Who wrote the original ClientPrefs PeramMute plugin
	Fyren, psychonic, & the rest of the SM Dev Team who helped me get the bug fix through
*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "2.2.1"

#define CHAT_BANNER "[\x03SM\x01] %t"

#define DEBUG 0

// structure of ClientPrefs VoiceComm cookie:
// bit 1: muted
#define BITVALUE_MUTED 1
// bit 2: gagged
#define BITVALUE_GAGGED 2
// bit 3: permanent
#define BITVALUE_PERMANENT 4
// bit 3 - 19 (unsigned double): time of punishment
#define BITVALUE_TIME 524280 

// if you need to change this then contact me first (synergy or non-standard mods will take more code to support)
#define SPECTATE_TEAM 1

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Voice Comm",
	author = "databomb",
	description = "Provides additional methods of controlling voice communication.",
	version = PLUGIN_VERSION,
	url = "vintagejailbreak.org"
};

enum VCommType
{
	CommType_Mute = 1,
	CommType_Gag,
	CommType_Silence,
	CommType_Invalid
};

// global variables
new Handle:gH_Cvar_DeadTalk = INVALID_HANDLE;
new Handle:gH_Cvar_AllTalk = INVALID_HANDLE;
new Handle:gH_Cvar_Announce = INVALID_HANDLE;
new Handle:gH_Cvar_MuteTime = INVALID_HANDLE;
new Handle:gH_Cvar_RoundEndAllTalk = INVALID_HANDLE;
new Handle:gH_Cvar_DeadHearAlive = INVALID_HANDLE;
new Handle:gH_Cvar_MuteAtStart = INVALID_HANDLE;
new Handle:gH_Cvar_TeamTalk = INVALID_HANDLE;
new Handle:gH_UnmuteTimer = INVALID_HANDLE;
new Handle:gH_Cvar_TeamToMute = INVALID_HANDLE;
new Handle:gH_Cvar_MuteSpectators = INVALID_HANDLE;
new Handle:gH_Cvar_BlockUnMuteOnRetry = INVALID_HANDLE;
new Handle:gH_Cvar_AdmOvrd_FirstJoin = INVALID_HANDLE;
new Handle:gH_Cvar_AdmOvrd_Spec = INVALID_HANDLE;
new Handle:gH_Cvar_AdmOvrd_OnDeath = INVALID_HANDLE;

new Handle:gH_Muted_Players = INVALID_HANDLE;
new Handle:gH_Cookie_VoiceCommMask = INVALID_HANDLE;
new Handle:gH_TimedPunishmentLocalArray = INVALID_HANDLE;

new bool:g_bMuted[MAXPLAYERS+1];
new bool:g_bHasJoinedOnce[MAXPLAYERS+1];
new gA_LocalTimeRemaining[MAXPLAYERS+1];
new bool:g_BetweenRounds;
new bool:g_IsMuteTimeUp;
new bool:g_bHooked;

public OnPluginStart()
{
	// load translations
	LoadTranslations("voicecomm.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_voicecomm_version", PLUGIN_VERSION, "Version of VoiceComm Plugin", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gH_Cvar_Announce = CreateConVar("sm_voicecomm_announce", "1", "Enable or disable the messages: 0 - disabled, 1 - enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);	//gH_Cvar_VoiceComm = CreateConVar("sm_voicecomm", "0", "Controls voice communications. 0-Normal, 1-Muted after death, 2-Dead talk to dead, 3-Dead ignore teams, 4-Dead talk to living teammates.", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	gH_Cvar_TeamTalk = CreateConVar("sm_voicecomm_teamtalk", "0", "Controls talking when alive if deadtalk is set to -2. 0 - Players talk to both teams when alive, 1 - Players talk to only their teammates when alive", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_MuteTime = CreateConVar("sm_voicecomm_mutetime", "29.0", "Controls the length of time terrorists are muted starting from the beginning of the round.", FCVAR_PLUGIN, true, 2.5);
	gH_Cvar_DeadHearAlive = CreateConVar("sm_voicecomm_deadhearalive", "1", "Controls hearing after death. 0 - Dead players do not hear alive players. 1 - Dead hear alive.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_MuteAtStart = CreateConVar("sm_voicecomm_startmuted", "1", "Controls whether a team starts the round muted.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_TeamToMute = CreateConVar("sm_voicecomm_mutedteam", "2", "Defines the team to mute if startmuted is enabled. In CS:S, 2=Terrorists, 3=CTs", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	gH_Cvar_RoundEndAllTalk = CreateConVar("sm_voicecomm_roundendalltalk", "1", "Controls whether all talk is turned on between the time between rounds", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_MuteSpectators = CreateConVar("sm_voicecomm_spectatormute", "1", "Controls whether spectators are automatically muted. (Admins are exempt).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_BlockUnMuteOnRetry = CreateConVar("sm_voicecomm_blockunmuteonreconnect", "1", "Controls whether players will automatically be unmuted when rejoining or if previous mutes are enforced.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_AdmOvrd_FirstJoin = CreateConVar("sm_voicecomm_admovrd_firstjoin", "1", "If enabled admins who first join will be allowed to talk.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_AdmOvrd_OnDeath = CreateConVar("sm_voicecomm_admovrd_death", "1", "If enabled admins who die are allowed to talk with everyone.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_AdmOvrd_Spec = CreateConVar("sm_voicecomm_admovrd_spectate", "1", "If enabled admins speak with everyone on round start if they are a spectator.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// register cookies - since this is a bitmask, it's too convoluted to keep public
	gH_Cookie_VoiceCommMask = RegClientCookie("VoiceComm_Status", "Bit-mask for VoiceComm status", CookieAccess_Private);

	gH_TimedPunishmentLocalArray = CreateArray();
	
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		gA_LocalTimeRemaining[idx] = 0;
	}
	
	gH_Cvar_AllTalk = FindConVar("sv_alltalk");
	SetConVarFlags(gH_Cvar_AllTalk, GetConVarFlags(gH_Cvar_AllTalk) & ~FCVAR_NOTIFY);
	
	// hook the commands from the basecomm.sp plugin
	AddCommandListener(Listen_EffectiveMute, "sm_mute");
	AddCommandListener(Listen_EffectiveMute, "sm_gag");
	AddCommandListener(Listen_EffectiveMute, "sm_silence");
	AddCommandListener(Listen_EffectiveUnMute, "sm_unmute");
	AddCommandListener(Listen_EffectiveUnMute, "sm_ungag");
	AddCommandListener(Listen_EffectiveUnMute, "sm_unsilence");
	
	// register additional commands
	
	// debug purposes
	RegAdminCmd("sm_listmutes", Command_MuteCheck, ADMFLAG_CHAT, "sm_listmutes - Lists all player names who are currently muted.");
	
	// listen for changes
	HookConVarChange(gH_Cvar_AllTalk, ConVarChange_AllTalk);
	
	// track players (cell 22: commtype, cells 0-21: steamID string)
	gH_Muted_Players = CreateArray(23);
	
	// periodic timer to handle timed punishments
	CreateTimer(60.0, CheckTimedPunishments, _, TIMER_REPEAT);
	
	AutoExecConfig(true, "voicecomm");
} // end OnPluginStart

public OnAllPluginsLoaded()
{
	gH_Cvar_DeadTalk = FindConVar("sm_deadtalk");
	if (gH_Cvar_DeadTalk != INVALID_HANDLE)
	{
		// lower the bounds for deadtalk by 2 to make room for the new options
		SetConVarBounds(gH_Cvar_DeadTalk, ConVarBound_Lower, true, -2.0);
	}
}

public OnConfigsExecuted()
{
	if (gH_Cvar_DeadTalk != INVALID_HANDLE)
	{
		// check if the value is below 0 and hook now since we missed the first change
		if ((GetConVarInt(gH_Cvar_DeadTalk) < 0) && !g_bHooked)
		{
			HookEvent("player_death", PlayerDeath, EventHookMode_Post);
			HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
			HookEvent("round_start", RoundStart, EventHookMode_Post);
			HookEvent("round_end", RoundEnd, EventHookMode_Post);
			HookEvent("player_team", Event_PlayerTeamSwitch, EventHookMode_Post);
			g_bHooked = true;
		}
		
		// listen for changes from now on
		HookConVarChange(gH_Cvar_DeadTalk, ConVarChange_DeadTalk);
	}
} 

public ConVarChange_DeadTalk(Handle:cvar, const String:oldVal[], const String:newVal[])
{
   if ((GetConVarInt(gH_Cvar_DeadTalk) < 0) && !g_bHooked)
   {
		HookEvent("player_death", PlayerDeath, EventHookMode_Post);
		HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
		HookEvent("round_start", RoundStart, EventHookMode_Post);
		HookEvent("round_end", RoundEnd, EventHookMode_Post);
		HookEvent("player_team", Event_PlayerTeamSwitch, EventHookMode_Post);
		g_bHooked = true;
   } 
   else if (g_bHooked && (GetConVarInt(gH_Cvar_DeadTalk) >= 0))
   {
		// Unhook events
		UnhookEvent("player_death", PlayerDeath, EventHookMode_Post);
		UnhookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
		UnhookEvent("round_start", RoundStart, EventHookMode_Post);
		UnhookEvent("round_end", RoundEnd, EventHookMode_Post);
		UnhookEvent("player_team", Event_PlayerTeamSwitch, EventHookMode_Post);
		g_bHooked = false;
   }
} // end ConVarChange_DeadTalk

public ConVarChange_AllTalk(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	// create timer here to avoid race condition with basecomm's ConVarChange_Alltalk
	CreateTimer(0.1, Timer_AllTalk, _, TIMER_FLAG_NO_MAPCHANGE);	
} // end ConVarChange_AllTalk

public Action:Timer_AllTalk(Handle:timer)
{
	new mode = GetConVarInt(gH_Cvar_DeadTalk);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (g_bMuted[i])
		{
			// let basecomm handle this
			continue;
		}
		else if ((mode == -1) && !IsPlayerAlive(i))
		{
			SetClientListeningFlags(i, VOICE_MUTED);
		}
		else if ((mode == -2) && !IsPlayerAlive(i))
		{
			// allow client to hear and talk to other dead players
			SetClientListeningFlags(i, VOICE_NORMAL);
			
			new DoesUserHaveAdmin = GetAdminFlag(GetUserAdmin(i), Admin_Chat);
			for (new idx = 1; idx <= MaxClients; idx++)
			{
				if ((idx != i) && IsClientInGame(idx))
				{
					new indexTeam = GetClientTeam(idx);
					if (!IsPlayerAlive(idx))
					{
						// don't run on spectators
						if ((indexTeam > 1) && !DoesUserHaveAdmin)
						{
							// make you able to speak to other dead players
							SetListenOverride(idx, i, Listen_Yes);
						}
						// make other dead players able to speak to you
						SetListenOverride(i, idx, Listen_Yes);
					}
					else if (IsPlayerAlive(idx) && !DoesUserHaveAdmin)
					{
						// make you not able to talk to alive players
						SetListenOverride(idx, i, Listen_No);
						// make alive players unable to talk to you
						if (!GetConVarBool(gH_Cvar_DeadHearAlive))
						{
							SetListenOverride(i, idx, Listen_No);
						}
					}
				}
			} // end for all players	
		}
	}	
	return Plugin_Stop;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_bMuted[client] = false;
	g_bHasJoinedOnce[client] = bool:false;
	
	return true;
}

// useful command to see who is currently muted by basecomm
// note this returns the mute status and not the effective mute status by sm_deadtalk!
public Action:Command_MuteCheck(client, args)
{
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (g_bMuted[idx])
		{
			ReplyToCommand(client, CHAT_BANNER, "List Mute Name", idx);
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_DelayedTeamVoice(Handle:timer)
{
	g_IsMuteTimeUp = true;
	new mutedTeam = GetConVarInt(gH_Cvar_TeamToMute);
	new AllTalk = GetConVarInt(gH_Cvar_AllTalk);
	new TeamTalk = GetConVarBool(gH_Cvar_TeamTalk);
	
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx))
		{
			new clientTeam = GetClientTeam(idx);
			if ((clientTeam == mutedTeam) && IsPlayerAlive(idx))
			{
				SetClientListeningFlags(idx, VOICE_NORMAL);
				
				// changed from if (DeadTalkMode == -2)
				if (!AllTalk && !TeamTalk)
				{
					// now allow spawned client to talk to everyone in game
					// only apply this to those we need to
					for (new Tidx = 1; Tidx <= MaxClients; Tidx++)
					{
						if (IsClientInGame(Tidx))
						{
							new TidxTeam = GetClientTeam(Tidx);
							if ((Tidx != idx) && (TidxTeam != clientTeam))
							{
								SetListenOverride(Tidx, idx, Listen_Yes);
							}
						} // end if in game
					} // end for all players				
				} // end if !alltalk and teamtalk
			} // end if alive and team
		} // end if in game
	} // end for all players

	if (GetConVarBool(gH_Cvar_Announce))
	{
		PrintToChatAll(CHAT_BANNER, "Mute Time Expired");
	}
	
	gH_UnmuteTimer = INVALID_HANDLE;
} // end Timer_DelayedTeamVoice

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BetweenRounds = false;
	new Announce = GetConVarBool(gH_Cvar_Announce);

	// consider turning alltalk off right now
	if (GetConVarBool(gH_Cvar_RoundEndAllTalk))
	{
		SetConVarBool(gH_Cvar_AllTalk, false);
	}	

	if (GetConVarBool(gH_Cvar_MuteAtStart))
	{
		if (Announce)
		{
			PrintToChatAll(CHAT_BANNER, "Start of Round with a Muted Team");
		}
		gH_UnmuteTimer = CreateTimer(GetConVarFloat(gH_Cvar_MuteTime), Timer_DelayedTeamVoice, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if (Announce)
		{
			PrintToChatAll(CHAT_BANNER, "Start of Round without Muted Team");
		}
	}
		
	// disallow players from spamming game from spectator team
	// and allow admins in spectate to talk to everyone
	if (GetConVarBool(gH_Cvar_MuteSpectators))
	{
		for (new AdmIdx = 1; AdmIdx <= MaxClients; AdmIdx++)
		{
			if (IsClientInGame(AdmIdx))
			{
				if ((GetClientTeam(AdmIdx) == SPECTATE_TEAM))
				{
					// check if user is an admin
					if (GetAdminFlag(GetUserAdmin(AdmIdx), Admin_Chat) && GetConVarBool(gH_Cvar_AdmOvrd_Spec))
					{
						if (Announce)
						{
							PrintToChat(AdmIdx, CHAT_BANNER, "Spectator - Admin");
						}
						// then override everyone else to hear this admin
						for (new PIdx = 1; PIdx <= MaxClients; PIdx++)
						{
							if (IsClientInGame(PIdx) && (PIdx != AdmIdx))
							{
								SetListenOverride(PIdx, AdmIdx, Listen_Yes);
							}
						}
					}
					else
					{
						if (Announce)
						{
							PrintToChat(AdmIdx, CHAT_BANNER, "Spectator - Not Admin");
						}
						for (new idx = 1; idx <= MaxClients; idx++)
						{
							if (IsClientInGame(idx) && (idx != AdmIdx))
							{
								SetListenOverride(idx, AdmIdx, Listen_No);
							} // end if
						} // end for all players
					} // end if admin
				} // end if spec team
			} // end if in game
		} // end for all players
	} // end if gH_Cvar_MuteSpectators is true
	
	return Plugin_Continue;
} // end RoundStart

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new DeadTalkMode = GetConVarInt(gH_Cvar_DeadTalk);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
	{
		return Plugin_Continue;	
	}
	
	// check if the mute time isn't up yet
	if (GetConVarBool(gH_Cvar_MuteAtStart) && (!g_IsMuteTimeUp) && (GetClientTeam(client) == GetConVarInt(gH_Cvar_TeamToMute)))
	{
		CreateTimer(0.1, Timer_DoMute, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	// enforce any previous mutes
	else if (g_bMuted[client] == true)
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		if (GetConVarInt(gH_Cvar_Announce))
		{
			PrintToChat(client, CHAT_BANNER, "Enforce Existing Mute");
		}	
	}
	else if (DeadTalkMode == -1)
	{
		// place-holder here if we need to add more actions later
	}
	else if (DeadTalkMode == -2)
	{
		if (!GetConVarBool(gH_Cvar_TeamTalk))
		{
			// allow spawned client to talk to opposing team
			for (new idx = 1; idx <= MaxClients; idx++)
			{
				if (IsClientInGame(idx))
				{
					if ((idx != client))
					{
						SetListenOverride(idx, client, Listen_Yes);
						if (IsPlayerAlive(idx))
						{
							// allow players still alive to talk to spawned player
							SetListenOverride(client, idx, Listen_Yes);
						}
					}
				}
			}
			if (GetConVarInt(gH_Cvar_Announce))
			{
				PrintToChat(client, CHAT_BANNER, "DeadAllTalk - Spawn - TeamTalk Off");
			}
		}
		else
		{
			CreateTimer(0.1, Timer_DoTeam, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
} // end PlayerSpawn

public Action:Timer_DoTeam(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		SetClientListeningFlags(client, VOICE_TEAM);
		if (GetConVarBool(gH_Cvar_Announce))
		{
			PrintToChat(client, CHAT_BANNER, "DeadAllTalk - Spawn - TeamTalk On");
		}
	}
	return Plugin_Stop;
}

public Action:Timer_DoMute(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		SetClientListeningFlags(client, VOICE_MUTED);
	}
	return Plugin_Stop;
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new DeadTalkMode = GetConVarInt(gH_Cvar_DeadTalk);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new RoundEndAllTalk = GetConVarBool(gH_Cvar_RoundEndAllTalk);
	new bool:AdminOverrideDeath = GetConVarBool(gH_Cvar_AdmOvrd_OnDeath);
	
	if (!client)
	{
		return;	
	}
	
	if (g_bMuted[client])
	{
		// let basecomm handle this
		return;
	}
	
	// don't change anything inbetween rounds
	if (!g_BetweenRounds || (g_BetweenRounds && !RoundEndAllTalk))
	{
		if (DeadTalkMode == -1)
		{
			if (!GetAdminFlag(GetUserAdmin(client), Admin_Chat) || !AdminOverrideDeath)
			{
				SetClientListeningFlags(client, VOICE_MUTED);
				if (GetConVarBool(gH_Cvar_Announce) == bool:true)
				{
					PrintToChat(client, CHAT_BANNER, "Muted On Death - Not Admin");
				}
			} // end if not admin
			else if (AdminOverrideDeath)
			{
				if (GetConVarBool(gH_Cvar_Announce) == bool:true)
				{
					PrintToChat(client, CHAT_BANNER, "Muted On Death - Admin");
				}
			} // else if admin
		}
		else if ((DeadTalkMode == -2) && !GetConVarBool(gH_Cvar_AllTalk))
		{
			// allow client to hear and talk to other dead players
			SetClientListeningFlags(client, VOICE_NORMAL);
			
			// override all alive players ability to hear who just died
			new DoesUserHaveAdmin = 0;
			if (AdminOverrideDeath)
			{
				DoesUserHaveAdmin = GetAdminFlag(GetUserAdmin(client), Admin_Chat);
			}
			//new clientTeam = GetClientTeam(client);
			for (new idx = 1; idx <= MaxClients; idx++)
			{
				if ((idx != client) && IsClientInGame(idx))
				{
					new indexTeam = GetClientTeam(idx);
					if (!IsPlayerAlive(idx))
					{
						if ((indexTeam != SPECTATE_TEAM) && !DoesUserHaveAdmin)
						{
							// make you able to speak to other dead players
							SetListenOverride(idx, client, Listen_Yes);
						}
						// make other dead players able to speak to you
						SetListenOverride(client, idx, Listen_Yes);
					}
					else if (IsPlayerAlive(idx) && !DoesUserHaveAdmin)
					{
						// make you not able to talk to alive players
						SetListenOverride(idx, client, Listen_No);
						// make alive players unable to talk to you
						if (!GetConVarBool(gH_Cvar_DeadHearAlive))
						{
							SetListenOverride(client, idx, Listen_No);
						}
					}
				}
			} // end for all players
	   		
			if (GetConVarInt(gH_Cvar_Announce))
			{
				if (DoesUserHaveAdmin)
				{
					PrintToChat(client, CHAT_BANNER, "DeadAllTalk - Death - Admin");
				}
				else
				{
					PrintToChat(client, CHAT_BANNER, "DeadAllTalk - Death - Not Admin");
				}
			}
		}
	} // end if not between rounds
	
} // end PlayerDeath

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BetweenRounds = true;
	g_IsMuteTimeUp = false;
	
	if (gH_UnmuteTimer != INVALID_HANDLE)
	{
		// kill the timer
		CloseHandle(gH_UnmuteTimer);
		gH_UnmuteTimer = INVALID_HANDLE;
		
		// unmute players
		for (new idx = 1; idx <= MaxClients; idx++)
		{
			if (IsClientInGame(idx))
			{
				// exclude those who have been administratively muted
				if (!g_bMuted[idx])
				{
					SetClientListeningFlags(idx, VOICE_NORMAL);
				}
			}
		}
	}
	
	new DeadTalkMode = GetConVarInt(gH_Cvar_DeadTalk);
	// right now mode -2 is the only one with many overrides
	if (DeadTalkMode == -2)
	{
		// clear all the hooks we did this round
		for (new RcvIdx = 1; RcvIdx <= MaxClients; RcvIdx++)
		{
			for (new SndIdx = 1; SndIdx <= MaxClients; SndIdx++)
			{
				// if both are in game
				if (IsClientInGame(RcvIdx) && IsClientInGame(SndIdx) && (SndIdx != RcvIdx))
				{
					SetListenOverride(RcvIdx, SndIdx, Listen_Default);
				}
			}
		}
	}
	
	// consider turning on alltalk 1 right now
	if (GetConVarBool(gH_Cvar_RoundEndAllTalk))
	{
		SetConVarBool(gH_Cvar_AllTalk, true);
		if (GetConVarInt(gH_Cvar_Announce))
		{
			PrintToChatAll(CHAT_BANNER, "Round End - All Talk On");
		}
	}
	else
	{
		if (GetConVarInt(gH_Cvar_Announce))
		{
			PrintToChatAll(CHAT_BANNER, "Round End - All Talk Off");
		}
	}

	return Plugin_Continue;
} // end RoundEnd

public Action:Event_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	new NewTeam = GetEventInt(event, "team");
	
	new Bool:Disconnect = Bool:GetEventBool(event, "disconnect");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Disconnect)
	{
		return Plugin_Handled;
	}

	new DeadTalkMode = GetConVarInt(gH_Cvar_DeadTalk);
	
	if (g_bHasJoinedOnce[client] == bool:false)
	{
		g_bHasJoinedOnce[client] = bool:true;
		if (DeadTalkMode)
		{	
			// if they're not an admin
			new bool:AdminOverrideJoin = GetConVarBool(gH_Cvar_AdmOvrd_FirstJoin);
			if (!GetAdminFlag(GetUserAdmin(client), Admin_Chat) || !AdminOverrideJoin)
			{	
				SetClientListeningFlags(client, VOICE_MUTED);
				
				if (GetConVarBool(gH_Cvar_Announce))
				{
					PrintToChat(client, CHAT_BANNER, "Mute On Join");
				}
			} // end if not an admin
			// else if admin
			else if (AdminOverrideJoin)
			{
				if (GetConVarBool(gH_Cvar_Announce))
				{
					PrintToChat(client, CHAT_BANNER, "Admin On Join");
				}
			}
		} // end if deadtalkmode
	} // end if has joined

	// allow opposing team to hear if teamtalk is 0
	if (!GetConVarBool(gH_Cvar_TeamTalk))
	{
		// the order of the events will be team->spawn
		// so let them hear everyone here (in case they dont spawn)
		for (new idx = 1; idx <= MaxClients; idx++)
		{
			if (IsClientInGame(idx))
			{
				new idxTeam = GetClientTeam(idx);
				// don't change spectators
				if ((idxTeam > 1) && (idxTeam != NewTeam))
				{
					SetListenOverride(client, idx, Listen_Yes);
				}
			}
		}
	}
	
	return Plugin_Handled;
} // end team switch

public Action:Listen_EffectiveMute(client, const String:command[], args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: %s <target> <optional:time>", command);
		// supercede the existing usage print with the new information
		return Plugin_Handled;
	}
	
	// check if the mute target is valid
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	                arg,
	                client,
	                target_list,
	                MAXPLAYERS,
	                0,
	                target_name,
	                sizeof(target_name),
	                tn_is_ml)) <= 0)
	{
	        // target_count problem 
	        return Plugin_Continue;
	}
	
	for (new i = 0; i < target_count; i++)
	{	
		// check type of punishment
		new VCommType:Punishment = CommType_Invalid;
		if (StrEqual(command, "sm_silence", false))
		{
			g_bMuted[target_list[i]] = true;
			Punishment = CommType_Silence;
		}
		else if (StrEqual(command, "sm_mute", false))
		{
			g_bMuted[target_list[i]] = true;
			Punishment = CommType_Mute;
		}
		else if (StrEqual(command, "sm_gag", false))
		{
			Punishment = CommType_Gag;
		}
		
		// check for additional args
		if (GetCmdArgs() > 1)
		{
			decl String:sTime[20];
			GetCmdArg(2, sTime, sizeof(sTime));
			new iTime = StringToInt(sTime);

			// truncate iTime to 16-bits
			iTime &= 0xFFFF;

			decl String:sBitMask[19];
			GetClientCookie(target_list[i], gH_Cookie_VoiceCommMask, sBitMask, sizeof(sBitMask));
			new iBitMask = StringToInt(sBitMask);

			switch (Punishment)
			{
				case CommType_Mute:
				{
					iBitMask |= BITVALUE_MUTED;
					
				}
				case CommType_Silence:
				{
					iBitMask |= BITVALUE_MUTED|BITVALUE_GAGGED;
				}
				case CommType_Gag:
				{
					iBitMask |= BITVALUE_GAGGED;
				}
			}
			#if DEBUG == 1
			LogMessage("Setting Punishment Bitmask: %d", iBitMask);
			#endif
					
			// the timed part is commented out temporarily			
			if (iTime > 0)
			{
				// timed punishment
								
				#if DEBUG == 1
				// get the current time
				new iExistingTime;
				iExistingTime &= iBitMask>>2;
				
				if (iExistingTime != 0)
				{
					LogMessage("replacing existing %d time with %d", iExistingTime, iTime);
				}
				#endif
				
				// get rid of current time 
				iBitMask &= BITVALUE_MUTED|BITVALUE_GAGGED|BITVALUE_PERMANENT;
				
				// set new time
				iBitMask |= iTime<<3;
				
				#if DEBUG == 1
				LogMessage("setting bitmask %i", iBitMask);
				#endif
				IntToString(iBitMask, sBitMask, sizeof(sBitMask));
				SetClientCookie(target_list[i], gH_Cookie_VoiceCommMask, sBitMask);

				// update local list
				new iFindIdx = FindValueInArray(gH_TimedPunishmentLocalArray, target_list[i]);
				if (iFindIdx == -1)
				{
					PushArrayCell(gH_TimedPunishmentLocalArray, target_list[i]);
				}
				
				gA_LocalTimeRemaining[target_list[i]] = iTime;
			}
			else if (iTime == 0)
			{
				// permanent punishment
				iBitMask |= BITVALUE_PERMANENT;
				
				// zero out 16-bit time, if any
				iBitMask &= BITVALUE_MUTED|BITVALUE_GAGGED|BITVALUE_PERMANENT;
				
				#if DEBUG == 1
				LogMessage("setting voicecomm bitmask %i", iBitMask);
				#endif
				// write back the information
				IntToString(iBitMask, sBitMask, sizeof(sBitMask));
				SetClientCookie(target_list[i], gH_Cookie_VoiceCommMask, sBitMask);
			}
		} // end if # args is more than 1
		
		// add to the array if not already there
		decl String:sSteamID[22];
		GetClientAuthString(target_list[i], sSteamID, sizeof(sSteamID));
		new iFindIndex = FindStringInArray(gH_Muted_Players, sSteamID);
		if (iFindIndex == -1)
		{
			new iPushedIndex = PushArrayString(gH_Muted_Players, sSteamID);
			SetArrayCell(gH_Muted_Players, iPushedIndex, Punishment, 22);
		}
	} // for all targets
		
	return Plugin_Continue;
} // end Listen_EffectiveMute

public Action:Listen_EffectiveUnMute(client, const String:command[], args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: %s <target> <optional:'force'>", command);
		return Plugin_Handled;
	}
	
	// check if the unmute target is valid
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	                arg,
	                client,
	                target_list,
	                MAXPLAYERS,
	                0,
	                target_name,
	                sizeof(target_name),
	                tn_is_ml)) <= 0)
	{
	        return Plugin_Continue;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		g_bMuted[target_list[i]] = false;
		
		// check for multiple arguments
		if (GetCmdArgs() > 1)
		{
			decl String:sOption[20];
			GetCmdArg(2, sOption, sizeof(sOption));
			
			// check if they want to force removal of stateful punishments
			if (StrEqual(sOption, "force", false))
			{
				// remove from local list if there
				new iFindIdx = FindValueInArray(gH_TimedPunishmentLocalArray, target_list[i]);
				if (iFindIdx != -1)
				{
					RemoveFromArray(gH_TimedPunishmentLocalArray, iFindIdx);
				}
				
				// clear all flags
				SetClientCookie(target_list[i], gH_Cookie_VoiceCommMask, "0");
				
				ReplyToCommand(client, CHAT_BANNER, "Removed Stateful Mute", target_list[i]);
				#if DEBUG == 1
				LogMessage("%N removed stateful mute for %N", client, target_list[i]);
				#endif
				
				// in the future if we want to support more than one type of commtype
				// we'll start from here
				/*
				decl String:sBitMask[19];
				GetClientCookie(target_list[i], gH_Cookie_VoiceCommMask, sBitMask, sizeof(sBitMask));
				new iBitMask = StringToInt(sBitMask);
				
				if (StrEqual(command, "sm_ungag", false))
				{
					iBitMask &= ~BITVALUE_GAGGED;
				}
				else if (StrEqual(command, "sm_unmute", false))
				{
					iBitMask &= ~BITVALUE_MUTED;
				}
				else if (StrEqual(command, "sm_unsilence", false))
				{
					iBitMask &= ~(BITVALUE_MUTED|BITVALUE_GAGGED);
				}
				*/
			} // end if forced
		} // end if # of args > 2
		
		// remove from array if present
		decl String:sSteamID[22];
		GetClientAuthString(target_list[i], sSteamID, sizeof(sSteamID));
		new arrayIndex = FindStringInArray(gH_Muted_Players, sSteamID);
		if (arrayIndex != -1)
		{
			RemoveFromArray(gH_Muted_Players, arrayIndex);
		}
	}

	return Plugin_Continue;
} // end Listen_EffectiveUnMute

public OnMapEnd()
{
	// clear mute information
	for (new player = 1; player <= MaxClients; player++)
	{
		g_bMuted[player] = false;
	}
	
	ClearArray(gH_Muted_Players);
}

public OnClientDisconnect(client)
{
	new iFindIdx = FindValueInArray(gH_TimedPunishmentLocalArray, client);
	if (iFindIdx != -1)
	{
		// get current cookie info
		decl String:sCookie[19];
		GetClientCookie(client, gH_Cookie_VoiceCommMask, sCookie, sizeof(sCookie));
		new iCookie = StringToInt(sCookie);
		
		// clear time field
		iCookie &= BITVALUE_MUTED|BITVALUE_GAGGED|BITVALUE_PERMANENT;
		// update time field
		if (gA_LocalTimeRemaining[client] > 0 && gA_LocalTimeRemaining[client] < 65536)
		{
			iCookie |= gA_LocalTimeRemaining[client]<<3;
		}
		#if DEBUG == 1
		else
		{
			LogMessage("time on disconnect out of bounds!");
		}
		#endif
		
		gA_LocalTimeRemaining[client] = 0;
		
		IntToString(iCookie, sCookie, sizeof(sCookie));
		SetClientCookie(client, gH_Cookie_VoiceCommMask, sCookie);
		
		// remove from local array
		RemoveFromArray(gH_TimedPunishmentLocalArray, iFindIdx);
	}
} // end disconnect

public OnClientPostAdminCheck(client)
{
	new userid = GetClientUserId(client);
	new VCommType:PunishmentType = CommType_Invalid;
	
	// check if cookies are cached
	if (AreClientCookiesCached(client))
	{
		decl String:sBitMask[18];
		GetClientCookie(client, gH_Cookie_VoiceCommMask, sBitMask, sizeof(sBitMask));
		new iBitMask = StringToInt(sBitMask);
		
		// check to see if we should do anything
		if (iBitMask != 0)
		{
			// check for a time
			new iTimeRemaining = iBitMask>>3;
			// make sure it's 16-bit
			iTimeRemaining &= 0xFFFF;
			if (iBitMask & BITVALUE_PERMANENT)
			{
				#if DEBUG == 1
				LogMessage("player %N joined with permanent punishment", client);
				#endif
			}
			else if (iTimeRemaining > 0)
			{
				#if DEBUG == 1
				LogMessage("player %N joined time remaining in punishment: %d", client, iTimeRemaining);
				#endif
				PushArrayCell(gH_TimedPunishmentLocalArray, client);
				gA_LocalTimeRemaining[client] = iTimeRemaining;
			}
			
			switch (iBitMask & BITVALUE_GAGGED|BITVALUE_MUTED)
			{
				case CommType_Silence:
				{
					#if DEBUG == 1
					LogMessage("enforcing silence on %N with bitmask %d", client, iBitMask);
					#endif
					PunishmentType = CommType_Silence;
					ServerCommand("sm_silence #%d", userid);			
				}
				case CommType_Mute:
				{
					#if DEBUG == 1
					LogMessage("enforcing mute on %N with bitmask %d", client, iBitMask);
					#endif
					PunishmentType = CommType_Mute;
					ServerCommand("sm_mute #%d", userid);			
				}
				case CommType_Gag:
				{
					#if DEBUG == 1
					LogMessage("enforcing gag on %N with bitmask %d", client, iBitMask);
					#endif
					PunishmentType = CommType_Gag;
					ServerCommand("sm_gag #%d", userid);		
				}
			}
		} // end if cookie non zero
	} // end if cookies are cached
	
	// check if we're ok to re-mute and we have not punished already
	if (GetConVarBool(gH_Cvar_BlockUnMuteOnRetry) && (PunishmentType == CommType_Invalid))
	{
		decl String:sSteamID[22];
		GetClientAuthString(client, sSteamID, sizeof(sSteamID));
		new arrayIndex = FindStringInArray(gH_Muted_Players, sSteamID);
		if (arrayIndex != -1)
		{
			// determine what mute type this was
			new VCommType:ThePunishment = GetArrayCell(gH_Muted_Players, arrayIndex, 22);
			switch (ThePunishment)
			{
				case CommType_Mute:
				{
					ServerCommand("sm_mute #%d", userid);
					#if DEBUG == 1
					LogMessage("%N was marked as evading and re-muted.", client);
					#endif
				}
				case CommType_Silence:
				{
					ServerCommand("sm_silence #%d", userid);
					#if DEBUG == 1
					LogMessage("%N was marked as evading and re-silenced.", client);
					#endif
				}
				case CommType_Gag:
				{
					ServerCommand("sm_gag #%d", userid);
					#if DEBUG == 1
					LogMessage("%N was marked as evading and re-gagged.", client);
					#endif
				}
			}			
		}
	}
} // end client post admin check

public Action:CheckTimedPunishments(Handle:timer)
{
	// check if anyone has a time
	new iTimeArraySize = GetArraySize(gH_TimedPunishmentLocalArray);
	
	for (new idx = 0; idx < iTimeArraySize; idx++)
	{
		new iClientIndex = GetArrayCell(gH_TimedPunishmentLocalArray, idx);
		if (IsClientInGame(iClientIndex))
		{
			gA_LocalTimeRemaining[iClientIndex]--;
			#if DEBUG == 1
			LogMessage("found time punishment on client %N with %i remaining", iClientIndex, gA_LocalTimeRemaining[iClientIndex]);
			#endif
			// check if we should remove the CT ban
			if (gA_LocalTimeRemaining[iClientIndex] <= 0)
			{
				// grab punishment but avoid a get cookie call
				decl String:sSteamID[22];
				GetClientAuthString(iClientIndex, sSteamID, sizeof(sSteamID));
				new iFindIndex = FindStringInArray(gH_Muted_Players, sSteamID);
				new VCommType:CommPunishment = CommType_Invalid;
				if (iFindIndex != -1)
				{
					CommPunishment = GetArrayCell(gH_Muted_Players, iFindIndex, 22);
				}
				
				// remove from list
				RemoveFromArray(gH_TimedPunishmentLocalArray, idx);
				
				SetClientCookie(iClientIndex, gH_Cookie_VoiceCommMask, "0");
				#if DEBUG == 1
				LogMessage("removed timed punishment on %N", iClientIndex);
				#endif
				
				new userid = GetClientUserId(iClientIndex);
				
				// unpunish
				switch (CommPunishment)
				{
					case CommType_Silence:
					{
						ServerCommand("sm_unsilence #%d force", userid);
					}
					case CommType_Gag:
					{
						ServerCommand("sm_ungag #%d force", userid);
					}
					case CommType_Mute:
					{
						ServerCommand("sm_unmute #%d force", userid);
					}
				}
				
			}
		}
	}
} // end punishments timer
