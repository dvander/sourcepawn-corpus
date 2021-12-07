/* Zeus Round
* 
* 	DESCRIPTION
* 		A Zeus Round plugin.  Will give players back their weapons, if they were alive at the 
* 		end of the round prior to the zeus round
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Beta Release
* 
* 		0.0.1.1	*	Bug fix for when during Zeus round and a player took control of a bot and survived,
* 					the weapons the player had while playing as the bot would be recorded as that players weapons
* 				+	Added argument to admin command to determine the number of Zeus Rounds to have.
* 				+	Added more phrases to the translation file.
* 
* 		0.0.1.2	*	Optimized plugin to not hook players with SDKHooks if not on Zeus Round.  Hopefully this will
* 					fix the bug with the disappearing weapons.
* 				*	Fixed bug where zeus rounds would carry over to next round unintentionally
* 
* 		0.0.1.3	+	Added CVars for SaveMoney, StripHostages, and StripBomb
* 				+	Added Zeus weapon cleanup
* 
* 		0.0.1.4	*	Fixed {green} tag showing in hint text.
* 
* 		0.0.1.5	*	Fixed issue where if you were controlling a bot, the bot's money would be saved as yours.
* 				*	Fixed Entity -1 (-1) is invalid
* 
* 		0.0.1.6	*	Cleaned up code per asherkin's suggestions and assistance with GetEntProp for nades.
* 
* 		0.0.1.7	+	Added Zeus Modes.  1=On Demand, 2=Always ZeusRound
* 
* 		0.0.1.8	*	Fixed error: Native "ThrowError" reported: Invalid client index 0
* 				+	Added "last round = zeusround" when mp_maxrounds is the only map ending CVar
* 
* 		0.0.1.9	+	Added some optional _DEBUG stuff
* 				*	Changed the way Last Round = ZeusRound works.  Kind of emulated how SM handles timeleft
* 					and knows if it's the last round or not.
* 
* 		0.0.2.0	+	Added ZeusRound Announcement (with CVar) to announce how many rounds will be zeusrounds
* 				*	Fixed bug where players joining during a zeusround would start the next non-zeusround
* 					with 0 money.  Player will now get mp_startmoney.
* 
* 		0.0.2.1	*	Fixed bug where players joining during a zeusround would start the next non-zeusround
* 					with no weapons.  Players will now get the weapons they receive during initial spawn.
* 					*	Changed GetClientWeapons() a bit to fix the above.
* 				*	Fixed reported bug where first map would make the last 2 rounds a zeusround (hopefully)
* 					+	Added a reset for the variable of g_TotalRoundsPlayed in the max rounds changed function
* 				+	Added a few more _DEBUG spots
* 
* 		0.0.2.2	*	Recompiled with new colors.inc and SM Snapshot for 01/23/2013 CS:GO update
* 
* 		0.0.2.3	*	Fixed DEBUG messages from showing on posted plugin
* 
* 		0.0.2.4	*	Fixed code for when player is controlling a bot
* 
* 	KNOWN ISSUES
* 		If you start the Zeus Round during the warmup round, then the round after the warmup round will not be a Zeus Round
* 			-	I'll continue to work on a solution for this, for now, don't initiate a Zeus Round during the warmup round.
* 
* 	REQUESTS
* 		Requested for removal of hostages - added in version 0.0.1.3
* 
* 	TO DO
* 		Fix timers and use ClientSerial instead of ClientId
*/
#pragma semicolon 1

// ===================================================================================================================================
// Includes
// ===================================================================================================================================
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>

// ===================================================================================================================================
// Defines
// ===================================================================================================================================
#define 	PLUGIN_VERSION 		"0.0.2.4"
#define 	UPDATE_URL 			"http://dl.dropbox.com/u/3266762/zeusround.txt"

#define		MAX_WEAPON_STRING		80
#define		MAX_WEAPON_SLOTS		6

#define 	HEGrenadeOffset 		11	// (11 * 4)
#define 	FlashbangOffset 		12	// (12 * 4)
#define 	SmokegrenadeOffset		13	// (13 * 4)
#define		IncenderyGrenadesOffset	14	// (14 * 4) Also Molotovs
#define		DecoyGrenadeOffset		15	// (15 * 4)

#define _DEBUG 			0 		// Set to 1 for log debug spew
#define _DEBUG_ALL		0		// Set to 1 for in-game chat debug spew

// ===================================================================================================================================
// Client Variables
// ===================================================================================================================================
new bool:ClientHasWeapons[MAXPLAYERS+1] = {false, ...};
//new bool:IsControllingBot[MAXPLAYERS+1] = {false, ...};
new bool:GotPlayersCash[MAXPLAYERS+1] = {false, ...};

new String:PrimarySlot[MAXPLAYERS+1][MAX_WEAPON_STRING];
new String:SecondarySlot[MAXPLAYERS+1][MAX_WEAPON_STRING];

new HEGrenades[MAXPLAYERS+1];
new FlashBangs[MAXPLAYERS+1];
new SmokeGrenades[MAXPLAYERS+1];
new INCGrenades[MAXPLAYERS+1];
new DecoyGrenades[MAXPLAYERS+1];

new PlayersCash[MAXPLAYERS+1];

new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:ClientTimer2[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:ClientTimer3[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

// ===================================================================================================================================
// CVar Variables
// ===================================================================================================================================
new Handle:g_StartMoney = INVALID_HANDLE;

new bool:UseUpdater = false;
new bool:SaveWeapons = true;
new bool:SaveMoney = true;
new bool:StripHostages = true;
new bool:StripBomb = true;
new bool:CleanUpZeus = true;
new bool:ZeusLastRound = false;
new bool:ZeusCountdown = false;

new bool:UpcomingZeusRound = false;
new bool:IsZeusRound = false;
new bool:HookedPlayers = false;

new ZeusRoundLeft = 0;

new StartingCash;

new MaxEntities;

new ZeusMode = 1;

new Handle:g_MaxRounds = INVALID_HANDLE;
new Handle:g_TimeLimit = INVALID_HANDLE;
new Handle:g_FragLimit = INVALID_HANDLE;
new Handle:g_CanClinch = INVALID_HANDLE;
new Handle:g_RestartGame = INVALID_HANDLE;
//new Handle:g_WarmUpRound = INVALID_HANDLE;

new cvar_MaxRounds;
new Float:cvar_TimeLimit;
new cvar_FragLimit;
new bool:cvar_CanClinch;
new g_TotalRoundsPlayed = 0;
new bool:BugFix = false;
//new bool:WarmUpRound;

new g_bIsControllingBot = -1;

public Plugin:myinfo = 
{
	name = "Zeus Round",
	author = "TnTSCS aka ClarkKent",
	description = "CS:GO Zeus Round",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	new Handle:hRandom; // KyleS HATES Handles
	
	HookConVarChange((CreateConVar("sm_zeusround_version", PLUGIN_VERSION, 
	"Version of 'Zeus Round'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Zeus Round when updates are published?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_saveweapons", "1", 
	"Should the players get their old weapons back after the Zeus round?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnSaveWeaponsChanged);
	SaveWeapons = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_stripbomb", "1", 
	"Should the bomb be stripped during the Zeus round?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnStripBombChanged);
	StripBomb = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_striphostages", "1", 
	"Should the hostages be removed during the Zeus round?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnStripHostagesChanged);
	StripHostages = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_savemoney", "1", 
	"Should the players money be saved at the start of the Zeus round and restored after the Zeus round?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnSaveMoneyChanged);
	SaveMoney = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_cleanup", "1", 
	"Should the dropped tasers be removed from the ground during the Zeus round?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnCleanupChanged);
	CleanUpZeus = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_mode", "1", 
	"Available Zeus Modes:\n1 = On Demand, use sm_zeusround [#] to start zeus rounds\n2 = Always Zeus Round (every round is a zeus only round).", FCVAR_NONE, true, 1.0, true, 2.0)), OnModeChanged);
	ZeusMode = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_lastround", "0", 
	"Should the last round be a zeus round?  Only works if you only use mp_maxrounds to end the map.\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnLastRoundChanged);
	ZeusLastRound = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_countdown", "0", 
	"Display the number of zeus rounds remaining when multiple consecutive rounds set as zeus rounds?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnCountdownChanged);
	ZeusCountdown = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zeusround_bugfix", "0", 
	"Set this to 1 if you are seeing the last 2 rounds a zeus round - it will fix it to be only the last round", FCVAR_NONE, true, 0.0, true, 1.0)), OnBugFixChanged);
	BugFix = GetConVarBool(hRandom);
	
	AutoExecConfig(true);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("game_start", Event_GameStart);
	
	RegAdminCmd("sm_zeusround", Cmd_ZeusRound, ADMFLAG_GENERIC, "Set the next round(s) to be a Zeus Round");
	
	//AddCommandListener(Command_BotTakeControl, "bot_take_control");
	
	new String:sGameDir[32];
	
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	
	if (StrContains(sGameDir, "csgo", false) == -1)
	{
		SetFailState("Zeus Round is for CS:GO only");
	}
	
	LoadTranslations("zeusround.phrases");
	
	HookConVarChange((g_StartMoney = FindConVar("mp_startmoney")), OnStartMoneyChanged);	
	if (g_StartMoney == INVALID_HANDLE)
	{
		SetFailState("Unable to find mp_startmoney");
	}	
	StartingCash = GetConVarInt(g_StartMoney);
	
	HookConVarChange((g_FragLimit = FindConVar("mp_fraglimit")), OnFragLimitChanged);	
	if (g_FragLimit == INVALID_HANDLE)
	{
		SetFailState("Unable to find mp_fraglimit");
	}	
	cvar_FragLimit = GetConVarInt(g_FragLimit);
	
	HookConVarChange((g_TimeLimit = FindConVar("mp_timelimit")), OnTimeLimitChanged);	
	if (g_TimeLimit == INVALID_HANDLE)
	{
		SetFailState("Unable to find mp_timelimit");
	}	
	cvar_TimeLimit = GetConVarFloat(g_TimeLimit);
	
	HookConVarChange((g_MaxRounds = FindConVar("mp_maxrounds")), OnMaxRoundsChanged);	
	if (g_MaxRounds == INVALID_HANDLE)
	{
		SetFailState("Unable to find mp_maxrounds");
	}	
	cvar_MaxRounds = GetConVarInt(g_MaxRounds);
	
	HookConVarChange((g_CanClinch = FindConVar("mp_match_can_clinch")), OnCanClinchChanged);	
	if (g_CanClinch == INVALID_HANDLE)
	{
		SetFailState("Unable to find mp_match_can_clinch");
	}	
	cvar_CanClinch = GetConVarBool(g_CanClinch);
	
	HookConVarChange((g_RestartGame = FindConVar("mp_restartgame")), OnRestartGameChanged);	
	if (g_RestartGame == INVALID_HANDLE)
	{
		SetFailState("Unable to find mp_restartgame");
	}
	
	g_bIsControllingBot = FindSendPropInfo("CCSPlayer", "m_bIsControllingBot");
	
	if (g_bIsControllingBot == -1)
	{
		SetFailState("Unable to locate m_bIsControllingBot");
	}
}

public OnLibraryAdded(const String:name[])
{
	if (UseUpdater && StrEqual(name, "updater"))
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Added plugin to Updater's list of plugins");
			DebugMessage(dmsg);
		#endif

		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnConfigsExecuted()
{
	g_TotalRoundsPlayed = 0;
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "OnConfigsExecuted: g_TotalRoundsPlayed set to %i", g_TotalRoundsPlayed);
		DebugMessage(dmsg);
	#endif
}

public OnMapStart()
{
	ResetZeus();
}

public OnMapEnd()
{
	ResetZeus();
}

ResetZeus()
{
	if (ZeusMode == 2)
	{
		UpcomingZeusRound = true;
	}
	else
	{
		UpcomingZeusRound = false;
	}
	
	IsZeusRound = false;
	ZeusRoundLeft = 0;
	g_TotalRoundsPlayed = 0;
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "Running ResetZeus function, g_TotalRoundsPlayed set to %i", g_TotalRoundsPlayed);
		DebugMessage(dmsg);
	#endif
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrimarySlot[i][0] = '\0';
			SecondarySlot[i][0] = '\0';
			
			HEGrenades[i] = 0;
			FlashBangs[i] = 0;
			SmokeGrenades[i] = 0;
			INCGrenades[i] = 0;
			DecoyGrenades[i] = 0;
			
			//IsControllingBot[i] = false;
			
			PlayersCash[i] = 0;
			GotPlayersCash[i] = false;
			
			ClearTimer(ClientTimer[i]);
			ClearTimer(ClientTimer2[i]);
			ClearTimer(ClientTimer3[i]);
			
			if (HookedPlayers)
			{
				SDKUnhook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
	}
	
	HookedPlayers = false;
}

public OnClientPutInServer(client)
{
	PlayersCash[client] = StartingCash;
	GotPlayersCash[client] = true;
	
	if (HookedPlayers)
	{
		SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	}
	
	ClientTimer[client] = INVALID_HANDLE;
	ClientTimer2[client] = INVALID_HANDLE;
	ClientTimer3[client] = INVALID_HANDLE;
	
	//IsControllingBot[client] = false;
}

#if 0
public OnClientPostAdminCheck(client)
{
	// Maybe something VIP in the future
}
#endif

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		if (HookedPlayers)
		{
			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
			SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
			SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		}
		
		PrimarySlot[client][0] = '\0';
		SecondarySlot[client][0] = '\0';
		
		HEGrenades[client] = 0;
		FlashBangs[client] = 0;
		SmokeGrenades[client] = 0;
		INCGrenades[client] = 0;
		DecoyGrenades[client] = 0;
		
		//IsControllingBot[client] = false;
		
		PlayersCash[client] = 0;
		GotPlayersCash[client] = false;
		
		ClearTimer(ClientTimer[client]);
		ClearTimer(ClientTimer2[client]);
		ClearTimer(ClientTimer3[client]);
	}
}

/* Round count tracking */
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Game got restarted - reset our round count tracking */
	g_TotalRoundsPlayed = 0;	
}


public Action:Cmd_ZeusRound(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "%t", "Usage");
		
		return Plugin_Handled;
	}
	
	decl String:arg1[4];
	arg1[0] = '\0';

	GetCmdArg(1, arg1, sizeof(arg1));
	ZeusRoundLeft = StringToInt(arg1);
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "%N executed ZeusRound Command for next %i rounds", client, ZeusRoundLeft);
		DebugMessage(dmsg);
	#endif
	
	if (ZeusRoundLeft > 0)
	{
		UpcomingZeusRound = true;
		
		CPrintToChatAll("{default}[SM] %t", "Zeus On", ZeusRoundLeft);
		
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Turn Off Console");
		}
		else
		{
			CPrintToChat(client, "{default}[SM] %t", "Turn Off");
		}
	}
	else
	{
		UpcomingZeusRound = false;
		ZeusRoundLeft = 0;
		
		CPrintToChatAll("{default}[SM] %t", "Zeus Off");
	}
	
	return Plugin_Handled;
}

#if 0
public Action:Command_BotTakeControl(client, const String:command[], argc)
{
	#if _DEBUG
		new botid = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "%N took control of BOT %N", client, botid);
		DebugMessage(dmsg);
	#endif
	
	IsControllingBot[client] = true;
	
	return Plugin_Continue;
}
#endif

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "Event_RoundStart: ZeusMode [%i], UpcomingZeusRound [%i], IsZeusRound [%i], ZeusRoundsLeft [%i]", ZeusMode, UpcomingZeusRound, IsZeusRound, ZeusRoundLeft);
		DebugMessage(dmsg);
	#endif

	if (ZeusMode == 2)
	{
		if (StripHostages)
		{
			CreateTimer(1.0, Timer_RemoveHostages);
		}
		
		UpcomingZeusRound = true;
		
		CreateTimer(1.0, Timer_ZeusRound);
		
		return;
	}
	
	if (UpcomingZeusRound && IsZeusRound)
	{
		CreateTimer(1.0, Timer_ZeusRound);
		
		if (StripHostages)
		{
			CreateTimer(1.0, Timer_RemoveHostages);
		}
		
		if (ZeusRoundLeft > 1)
		{
			ZeusRoundLeft--;
			
			if (ZeusCountdown && ZeusRoundLeft > 0)
			{
				CPrintToChatAll("{default}[SM] %t", "Zeus On", ZeusRoundLeft);
			}
			
			return;
		}
		
		UpcomingZeusRound = false;
	}
}

public Action:Timer_RemoveHostages(Handle:timer)
{
	MaxEntities = GetEntityCount();
	
	/* Credit to bl4nk for this code snippit (I was trying to remove the edict when it was created, needed a timer)*/
	decl String:buffer[32];
	buffer[0] = '\0';
	
	for (new i = MaxClients + 1; i < MaxEntities; i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		GetEntityClassname(i, buffer, sizeof(buffer));
		
		if(StrEqual(buffer, "hostage_entity"))
		{
			#if _DEBUG
				new String:dmsg[MAX_MESSAGE_LENGTH];
				Format(dmsg, sizeof(dmsg), "Removed hostage_entity %i", i);
				DebugMessage(dmsg);
			#endif
			
			RemoveEdict(i);
		}
	}
}

public Action:Timer_ZeusRound(Handle:timer)
{
	PrintHintTextToAll("%t", "Zeus Round");
	
	CPrintToChatAll("{default}[SM] {green}%t", "Zeus Round");
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_TotalRoundsPlayed++;
	
	#if 0
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsControllingBot[i])
		{
			IsControllingBot[i] = false;
		}
	}
	#endif
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "Event_RoundEnd: g_TotalRoundsPlayed set to %i", g_TotalRoundsPlayed);
		DebugMessage(dmsg);
	#endif
	
	CheckZeusRoundStatus();
}

CheckZeusRoundStatus()
{
	new remaining = (cvar_MaxRounds - g_TotalRoundsPlayed);
	
	if (BugFix)
	{
		remaining++;
	}
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "CheckZeusRoundStatus: Remaining rounds set to %i", remaining);
		DebugMessage(dmsg);
	#endif
	
	if (ZeusLastRound && remaining <= 0)
	{
		UpcomingZeusRound = true;
		ZeusRoundLeft = 1;
		IsZeusRound = true;
		
		if (ZeusCountdown)
		{
			CPrintToChatAll("{default}[SM] %t", "Zeus On", ZeusRoundLeft);
		}
	}
	
	if (UpcomingZeusRound)
	{
		if (!IsZeusRound && SaveWeapons)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && IsPlayerControllingBot(i) < 1)// !IsControllingBot[i])
				{
					GetClientWeapons(i);
				}
			}
		}
		
		RemoveClientWeapons();
		
		IsZeusRound = true;
		
		if (!HookedPlayers)
		{
			HookPlayers(true);
			
			HookedPlayers = true;
		}
	}
	else
	{
		if (IsZeusRound)
		{
			IsZeusRound = false;
			
			HookPlayers(false);
			HookedPlayers = false;
		}
	}
	
	#if _DEBUG
		dmsg[0] = '\0';
		Format(dmsg, sizeof(dmsg), "EndRound: IsZeusRound [%i], Remaining [%i], MaxRounds [%i], UpcomingZeusRound [%i]", IsZeusRound, remaining, cvar_MaxRounds, UpcomingZeusRound);
		DebugMessage(dmsg);
	#endif
}

public HookPlayers(bool:mode)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (mode)
			{
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
			else
			{
				SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsZeusRound)
	{
		if (ClientHasWeapons[client])
		{
			CS_RemoveAllWeapons(client);
			
			ClientTimer3[client] = CreateTimer(0.1, Timer_GiveWeapons, client);
		}
		
		if (SaveMoney && GotPlayersCash[client])
		{
			SetPlayersCash(client, PlayersCash[client]);
			PlayersCash[client] = 0;
			
			GotPlayersCash[client] = false;
		}
		
		return;
	}
	
	if (SaveMoney && !GotPlayersCash[client])
	{
		GotPlayersCash[client] = true;
		PlayersCash[client] = GetPlayersCash(client);
	}
	
	if (!ClientHasWeapons[client] && IsPlayerControllingBot(client) < 1)// !IsControllingBot[client])
	{
		GetClientWeapons(client);
	}
	
	CS_RemoveAllWeapons(client);
	
	GivePlayerItem(client, "weapon_knife");
	
	GivePlayerItem(client, "weapon_taser");
}

public Action:Timer_GiveWeapons(Handle:timer, any:client)
{
	ClientTimer3[client] = INVALID_HANDLE;
	
	GiveClientWeapons(client);
	ClientHasWeapons[client] = false;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsZeusRound || killer < 1 || killer > MaxClients)
	{
		return;
	}
	
	#if 0
	if (IsControllingBot[killer])
	{
		IsControllingBot[killer] = false;
	}
	#endif
	
	decl String:weapon[MAX_WEAPON_STRING];
	weapon[0] = '\0';
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (StrEqual(weapon, "taser", false) || StrEqual(weapon, "knife", false))
	{
		ClientTimer[killer] = CreateTimer(0.5, Timer_GiveZeus, killer);
	}
}

public Action:Timer_GiveZeus(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	GivePlayerItem(client, "weapon_taser");
}

RemoveClientWeapons()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			CS_RemoveAllWeapons(i);
			
			GivePlayerItem(i, "weapon_knife");
		}
	}
}

CS_RemoveAllWeapons(client)
{
	new weapon_index = -1;
	
	for (new slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				if (slot == CS_SLOT_C4 && !StripBomb)
				{
					return;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

GetClientWeapons(client)
{
	new prim, sec;
	
	//for (new i = 1; i <= MaxClients; i++)
	//{
	//	if (IsClientInGame(i) && IsPlayerAlive(i) && !IsControllingBot[i])
	//	{
	PrimarySlot[client][0] = '\0';
	SecondarySlot[client][0] = '\0';
	
	ClientHasWeapons[client] = true;
	
	prim = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	if (prim > MaxClients)
	{
		GetEntityClassname(prim, PrimarySlot[client], sizeof(PrimarySlot[]));
	}
	else
	{
		Format(PrimarySlot[client], sizeof(PrimarySlot), "NONE");
	}
	
	sec = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if (sec > MaxClients)
	{
		GetEntityClassname(sec, SecondarySlot[client], sizeof(SecondarySlot[]));
	}
	else
	{
		Format(SecondarySlot[client], sizeof(SecondarySlot), "NONE");
	}
	
	HEGrenades[client] = GetClientHEGrenades(client);
	FlashBangs[client] = GetClientFlashbangs(client);
	SmokeGrenades[client] = GetClientSmokeGrenades(client);
	DecoyGrenades[client] = GetClientDecoyGrenades(client);
	INCGrenades[client] = GetClientIncendaryGrenades(client);
		//}
	//}
}

GiveClientWeapons(client)
{
	GivePlayerItem(client, "weapon_knife");
	
	if (HEGrenades[client] > 0)
	{
		for (new g = 0; g < HEGrenades[client]; g++)
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
		
		HEGrenades[client] = 0;
	}
	
	if (FlashBangs[client] > 0)
	{
		for (new fb = 0; fb < FlashBangs[client]; fb++)
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
		
		FlashBangs[client] = 0;
	}
	
	if (SmokeGrenades[client] > 0)
	{
		for (new sg = 0; sg < SmokeGrenades[client]; sg++)
		{
			GivePlayerItem(client, "weapon_smokegrenade");
		}
		
		SmokeGrenades[client] = 0;
	}
	
	if (DecoyGrenades[client] > 0)
	{
		for (new dg = 0; dg < DecoyGrenades[client]; dg++)
		{
			GivePlayerItem(client, "weapon_decoy");
		}
		
		DecoyGrenades[client] = 0;
	}
	
	if (INCGrenades[client] > 0)
	{
		for (new ig = 0; ig < INCGrenades[client]; ig++)
		{
			if (GetClientTeam(client) == CS_TEAM_CT)
			{
				GivePlayerItem(client, "weapon_incgrenade");
			}
			else
			{
				GivePlayerItem(client, "weapon_molotov");
			}
		}
		
		INCGrenades[client] = 0;
	}
	
	if (!StrEqual(SecondarySlot[client], "NONE", false))
	{
		GivePlayerItem(client, SecondarySlot[client]);
		
		SecondarySlot[client][0] = '\0';
	}
	
	if (!StrEqual(PrimarySlot[client], "NONE", false))
	{
		GivePlayerItem(client, PrimarySlot[client]);
		
		PrimarySlot[client][0] = '\0';
	}
}

public Action:OnWeaponDrop(client, weapon)
{
	if (IsZeusRound && CleanUpZeus)
	{
		if (!IsValidEntity(weapon))
		{
			return Plugin_Continue;
		}
		
		decl String:sWeapon[MAX_WEAPON_STRING];
		sWeapon[0] = '\0';
		
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		
		if (StrEqual(sWeapon, "weapon_taser", false))
		{
			RemoveEdict(weapon);
			AcceptEntityInput(weapon, "kill");
		}
	}
	
	return Plugin_Continue;
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (!IsZeusRound)
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[32];
	sWeapon[0] = '\0';
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, "weapon_taser", false) || StrEqual(sWeapon, "weapon_knife", false))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (!IsZeusRound)
	{
		return Plugin_Continue;
	}
	
	if (!IsFakeClient(client) && ClientTimer2[client] == INVALID_HANDLE)
	{
		CPrintToChat(client, "{default}[SM] %t", "CannotBuy");
		ClientTimer2[client] = CreateTimer(3.0, Timer_ResetMsg, client);
	}
	
	return Plugin_Handled;
}

public Action:Timer_ResetMsg(Handle:timer, any:client)
{
	ClientTimer2[client] = INVALID_HANDLE;
}

public Action:Timer_CheckEndRound(Handle:timer)
{
	if (ZeusLastRound)
	{
		if (cvar_FragLimit > 0 || cvar_TimeLimit > 0.0 || cvar_CanClinch)
		{
			ZeusLastRound = false;
			LogError("Cannot set last round to be ZeusRound because either mp_fraglimit or mp_timelimit or mp_match_can_clinch is being used");
		}
	}
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

/**
 * Check if a player is controlling a bot
 * @param	client	Player's ClientID
 * @return 1 if player is controlling a bot or 0 if player is not controlling a bot
 */
IsPlayerControllingBot(client)
{
	return GetEntData(client, g_bIsControllingBot, 1); 
}

#if _DEBUG
DebugMessage(const String:msg[], any:...)
{
	LogMessage("[ZeusRound DEBUG] %s", msg);
	
	#if _DEBUG_ALL
		PrintToChatAll("[ZeusRound DEBUG] %s", msg);
	#endif
}
#endif

GetClientHEGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

GetClientSmokeGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

GetClientFlashbangs(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

GetClientDecoyGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, DecoyGrenadeOffset);
}

GetClientIncendaryGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, IncenderyGrenadesOffset);
}

public GetPlayersCash(client)
{
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

public SetPlayersCash(client, amount)
{
	SetEntProp(client, Prop_Send, "m_iAccount", amount);
}

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================
public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
	
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnSaveWeaponsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SaveWeapons = GetConVarBool(cvar);
}

public OnStartMoneyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StartingCash = GetConVarInt(cvar);
}

public OnStripBombChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StripBomb = GetConVarBool(cvar);
}

public OnStripHostagesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StripHostages = GetConVarBool(cvar);
}

public OnSaveMoneyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SaveMoney = GetConVarBool(cvar);
}

public OnCleanupChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CleanUpZeus = GetConVarBool(cvar);
}

public OnModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ZeusMode = GetConVarInt(cvar);
}

public OnLastRoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ZeusLastRound = GetConVarBool(cvar);
	
	CreateTimer(2.0, Timer_CheckEndRound);
}

public OnFragLimitChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	cvar_FragLimit = GetConVarInt(cvar);
}

public OnTimeLimitChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	cvar_TimeLimit = GetConVarFloat(cvar);
}

public OnMaxRoundsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	cvar_MaxRounds = GetConVarInt(cvar);
	
	//g_TotalRoundsPlayed = 0; // Added 0.0.2.1 to fix first map from having last 2 rounds as a zeusround.
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "OnMaxRoundsChanged: g_TotalRoundsPlayed set to %i", g_TotalRoundsPlayed);
		DebugMessage(dmsg);
	#endif
}

public OnCanClinchChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	cvar_CanClinch = GetConVarBool(cvar);
}

public OnRestartGameChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	cvar_MaxRounds = GetConVarInt(g_MaxRounds);
	
	IsZeusRound = false;
	UpcomingZeusRound = false;
	ZeusRoundLeft = 0;
	
	/* Game was restarted - reset round count tracking */
	g_TotalRoundsPlayed = 1;
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "OnRestartGameChanged: g_TotalRoundsPlayed set to %i", g_TotalRoundsPlayed);
		DebugMessage(dmsg);
	#endif
}

public OnCountdownChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ZeusCountdown = GetConVarBool(cvar);
}

public OnBugFixChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BugFix = GetConVarBool(cvar);
}