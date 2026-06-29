//Includes.
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <adminmenu>
#pragma semicolon 2 //Who doesn't like semicolons? :)

//Definitions
#define ALERTSOUND "music/terror/iamsocold.wav"
#define BEEPSOUND "player/heartbeatloop.wav"
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2 "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3 "explosion_huge_b"
#define FIRE_SOUND "ambient/fire/interior_fire01_stereo.wav"
#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define BOOMSOUND "ambient/explosions/explode_1.wav"

#define GETVERSION "1.1.3"
#define DEBUG 0

//VARIABLES
new bool:g_bAct = false;
static g_iChoosedClient = 0;
static g_iChoosedUserId = 0;

new g_iSurvivors = 0;
new g_iSurvivorPlayers = 0;
new bool:g_bIsTracked[MAXPLAYERS+1] = false;
new bool:g_bSomeoneTracked = false;
new bool:g_bWarning[MAXPLAYERS+1] = false;
new g_iWarningCount[MAXPLAYERS+1] = 0;
new bool:g_bInRadius[MAXPLAYERS+1] = true;
new g_bCarried = false;
new g_bHit = false;
new g_bRiden = false;
new g_bBeenSet = false;
new g_bTanked = false;
new g_iGameMode;

//HANDLES
new Handle:g_cvarEnable = INVALID_HANDLE;
new Handle:g_cvarColor = INVALID_HANDLE;
new Handle:g_cvarHealth = INVALID_HANDLE;
new Handle:g_cvarPenalty = INVALID_HANDLE;
new Handle:g_cvarRadius = INVALID_HANDLE;
new Handle:g_cvarPower = INVALID_HANDLE;
new Handle:g_cvarFireTrace = INVALID_HANDLE;
new Handle:g_cvarEndGame = INVALID_HANDLE;
new Handle:g_cvarHealthPenalty = INVALID_HANDLE;
new Handle:g_cvarAdvert = INVALID_HANDLE;
new Handle:g_cvarAdvertSurvivor = INVALID_HANDLE;
new Handle:g_cvarAdvertInfected = INVALID_HANDLE;
new Handle:g_cvarHurt = INVALID_HANDLE;
new Handle:g_cvarHurtLuck = INVALID_HANDLE;
new Handle:g_cvarHurtDiv = INVALID_HANDLE;
new Handle:g_cvarVomit = INVALID_HANDLE;
new Handle:g_cvarAdmin = INVALID_HANDLE;
new Handle:g_cvarAttach = INVALID_HANDLE;
new Handle:g_cvarAttachRadius = INVALID_HANDLE;
new Handle:g_cvarAttachWarnings = INVALID_HANDLE;
new Handle:g_cvarAttachPenalty = INVALID_HANDLE;
new Handle:g_cvarAttachHealth = INVALID_HANDLE;
new Handle:g_cvarAttachInterval = INVALID_HANDLE;
new Handle:g_cvarAttachInfected = INVALID_HANDLE;
new Handle:g_cvarAttachAnnounce = INVALID_HANDLE;
//new Handle:g_cvarReference = INVALID_HANDLE;
new Handle:g_cvarAttachHealthInterval = INVALID_HANDLE;
new Handle:g_cvarAttachIncap = INVALID_HANDLE;
new Handle:g_cvarFriendly = INVALID_HANDLE;
new Handle:g_cvarFriendlyPunish = INVALID_HANDLE;
new Handle:g_cvarFriendlyChoosed = INVALID_HANDLE;
new Handle:g_cvarSuicide = INVALID_HANDLE;
new Handle:g_cvarChooseTime = INVALID_HANDLE;
//new Handle:g_cvarVote = INVALID_HANDLE;

new Handle:g_hGameConf = INVALID_HANDLE;
new Handle:sdkCallPushPlayer = INVALID_HANDLE;
new Handle:sdkCallVomitPlayer = INVALID_HANDLE;

new Handle:g_hSurvivorMaxIncapCount = INVALID_HANDLE;
new Handle:g_hChooseTimer = INVALID_HANDLE;
new Handle:g_hCarryTimeOut = INVALID_HANDLE;
new Handle:g_hHitTimeOut = INVALID_HANDLE;
new Handle:g_hTankedTimeOut = INVALID_HANDLE;
new Handle:g_hTopMenu = INVALID_HANDLE;
new Handle:g_hGameMode = INVALID_HANDLE;
new Handle:g_hEndGame = INVALID_HANDLE;

//Plugin Info
public Plugin:myinfo = 
{
	name = "[L4D2] The Chosen one",
	author = "honorcode23",
	description = "On versus, the plugin will select a random survivor, and the others must protect him. If the chosen survivor dies, the game ends",
	version = GETVERSION,
	url = "<-No url available yet->"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("The chosen one plugin supports left 4 dead 2 only!");
	}
	
	//Configuration ConVars
	CreateConVar("l4d2_chosen_one_version", GETVERSION, "Version of [L4D2] The chosen One plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarEnable = CreateConVar("l4d2_chosen_one_enable", "1", "Enable the plugin?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarColor = CreateConVar("l4d2_chosen_one_color", "6", "Color of the chosen survivor? (1:RED | 2:BLUE | 3:GREEN| 4:BLACK | 5:INVISIBLE | 6:NORMAL)", FCVAR_PLUGIN);
	g_cvarHealth = CreateConVar("l4d2_chosen_one_health", "150", "Health of the chosen survivor?", FCVAR_PLUGIN);
	g_cvarPenalty = CreateConVar("l4d2_chosen_one_penalty", "1", "What should happen with the team if the survivor dies? (0: EXPLOSION IN RADIUS| 1: END GAME| 2:HEALTH PENALTY |3:INCAP IN RADIUS)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_cvarRadius = CreateConVar("l4d2_chosen_one_radius", "450", "Radius value for explosion or incap", FCVAR_PLUGIN);
	g_cvarPower = CreateConVar("l4d2_chosen_one_power", "1500", "Power of the explosion, if activated", FCVAR_PLUGIN);
	g_cvarFireTrace = CreateConVar("l4d2_chosen_one_fire_trace", "15.0", "How long should the fire trace of the explosion last", FCVAR_PLUGIN, true, 0.0);
	g_cvarEndGame = CreateConVar("l4d2_chosen_one_end_time", "0", "Time  in seconds to wait before ending game", FCVAR_PLUGIN, true, 0.0);
	g_cvarHealthPenalty = CreateConVar("l4d2_chosen_one_penalty_health", "75", "Health penalty for the survivors?", FCVAR_PLUGIN);
	g_cvarAdvert = CreateConVar("l4d2_chosen_one_advert", "1", "How should the plugin announce itself? (0: DONT ANNOUNCE |1:CHAT| 2:HINT TEXT | 3:CENTER HINT TEXT)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_cvarAdvertSurvivor = CreateConVar("l4d2_chosen_one_advert_survivor", "4", "How should the plugin announce the chosen one to Survivors? (0: DONT ANNOUNCE |1:CHAT| 2:HINT TEXT | 3:CENTER HINT TEXT | 4:INSTRUCTOR HINT)", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	g_cvarAdvertInfected = CreateConVar("l4d2_chosen_one_advert_infected", "4", "How should the plugin announce the chosen one to Infected? (0: DONT ANNOUNCE |1:CHAT| 2:HINT TEXT | 3:CENTER HINT TEXT | 4:INSTRUCTOR HINT)", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	g_cvarVomit = CreateConVar("l4d2_chosen_one_vomit_all", "1", "Should the entire survivor team get vomited (Shorter time) if the chosen one does?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarHurt = CreateConVar("l4d2_chosen_one_hurt_all", "1", "Should the entire survivor team get damage if the chosen one does?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarHurtLuck = CreateConVar("l4d2_chosen_one_hurt_all_chance", "5", "Chance of hurting the entire team if the chosen one gets hurt (1: 100% | 2: 50% and so on)", FCVAR_PLUGIN, true, 1.0);
	g_cvarHurtDiv = CreateConVar("l4d2_chosen_one_hurt_all_damage", "50", "Percentage of the chosen one damage received by the rest of the team?", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	g_cvarAdmin = CreateConVar("l4d2_chosen_one_admin_select", "1", "Allow the admins to select or change the chosen one by a command or trough the admin menu?", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	g_cvarAttach = CreateConVar("l4d2_chosen_one_attach", "1", "Attach players to the chosen one? If the get too far, they get a penalty",  FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarAttachRadius = CreateConVar("l4d2_chosen_one_attach_radius", "3000", "Maximum distance allowed between a player and the chosen one", FCVAR_PLUGIN);
	g_cvarAttachWarnings = CreateConVar("l4d2_chosen_one_attach_warnings", "5", "Number of warnings before appling the penalty", FCVAR_PLUGIN, true, 0.0);
	g_cvarAttachAnnounce = CreateConVar("l4d2_chosen_one_attach_announce", "4", "How should the plugin warn the player? (0: DONT WARN |1:CHAT| 2:HINT TEXT | 3:CENTER HINT TEXT | INSTRUCTOR HINT)", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	g_cvarAttachPenalty = CreateConVar("l4d2_chosen_one_attach_penalty", "1", "Penalty if the player ignores the warnings and still too far (0: INCAP | 1: APPLY DAMAGE | 2: FREEZE | 3: KILL | 4:SPAWN INFECTED IN FRONT)", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	g_cvarAttachHealth = CreateConVar("l4d2_chosen_one_attach_damage", "5", "Damage done to the player that is too far from the chosen one?", FCVAR_PLUGIN, true, 0.0);
	g_cvarAttachInterval = CreateConVar("l4d2_chosen_one_attach_interval", "5", "Interval between each warning?", FCVAR_PLUGIN, true, 0.0);
	g_cvarAttachHealthInterval = CreateConVar("l4d2_chosen_one_attach_damage_interval", "5", "If the damage penalty is choosed (when out of the radius), interval between hits", FCVAR_PLUGIN, true, 0.0);
	g_cvarAttachInfected = CreateConVar("l4d2_chosen_one_attach_infected", "hunter", "Infected to spawn in front of the player, specifiy separated by comas, but only 1 per class(smoker, smoker: is incorrect)", FCVAR_PLUGIN);
	g_cvarAttachIncap = CreateConVar("l4d2_chosen_one_attach_incap", "0", "Run the warnings timer if the player is incapacitated?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarFriendly = CreateConVar("l4d2_chosen_one_friendly_fire", "1", "What should the plugin do if the chosen one gets friendly fired? (0: NOTHING | 1:HEAL HIM | 2:HEAL AND PUNISH AGRESSOR", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_cvarFriendlyPunish = CreateConVar("l4d2_chosen_one_friendly_fire_punish", "100", "Percentage of the damage returned to the agressor?", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	g_cvarFriendlyChoosed = CreateConVar("l4d2_chosen_one_friendly_fire_disable", "1", "The chosen one will not deal any friendly fire to survivors", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	g_cvarSuicide = CreateConVar("l4d2_chosen_one_suicide", "1", "If set to 1, the plugin will check if the chosen one commits suicide, and will re-choose a player without appling penalty", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarChooseTime = CreateConVar("l4d2_chosen_one_select_time", "50", "Time to wait before selecting a survivor", FCVAR_PLUGIN);
	//g_cvarReference = CreateConVar("l4d2_chosen_one_create_reference", "2", "Create a reference entity to calculate distances and check rushers? (0: DONT | 1:START | 2:END | 3:BOTH)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	//g_cvarVote = CreateConVar("l4d2_chosen_one_allow_vote", "1", "Allow players to vote for the chosen one?", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	
	//Player Commans
	//RegConsoleCmd("sm_votechosen", CmdVoteChosen, "Vote for The Chosen One player");
	
	//Admin Commands
	RegAdminCmd("sm_boomboom", CmdBoom, ADMFLAG_SLAY, "Creates an explosion right under your feet");
	RegAdminCmd("sm_selectchosen", CmdSelectChosen, ADMFLAG_SLAY, "Will change the chosen player");
	RegAdminCmd("sm_spawnpack", CmdSpawnPack, ADMFLAG_SLAY, "Will spawn a pack right in front a player, based on the server convars");
	
	//Create Config File
	AutoExecConfig(true, "l4d2_chosen_one");
	
	//EVENTS
	HookEvent("round_start_post_nav", OnRoundStart); //ROUND START
	HookEvent("round_end", OnRoundEnd); //ROUND END
	HookEvent("player_bot_replace", OnBotReplacePlayer, EventHookMode_Pre); //A bot takes over an existing player
	HookEvent("bot_player_replace", OnPlayerReplaceBot, EventHookMode_Pre); //A player takes over an existing bot
	HookEvent("player_death", OnPlayerDeath); //
	HookEvent("player_incapacitated", OnIncap); //Incapacitated
	HookEvent("revive_success", OnRevived); //Revived
	HookEvent("player_now_it", OnVomit); //VOMIT
	HookEvent("player_hurt", OnHurt); //HURT
	HookEvent("mission_lost", OnMissionLost);
	
	HookEvent("charger_impact", OnChargerImpact);
	HookEvent("charger_carry_start", OnCarried);
	HookEvent("jockey_ride", OnRideStart);
	HookEvent("jockey_ride_end", OnRideEnd);
	
	//GET GAME VARS
	g_hSurvivorMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_hGameMode = FindConVar("mp_gamemode");
	
	//SDKCALL
	g_hGameConf = LoadGameConfigFile("l4d2chosenone");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the signatures file. Please, check that it is installed correctly.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitPlayer = EndPrepSDKCall();
	
	if(sdkCallVomitPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_OnHitByVomitJar' signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}
	
	if (LibraryExists("adminmenu") && ((g_hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(g_hTopMenu);
	}
}

public Action:CmdBoom(client, args)
{
	CreateExplosion(client, 0);
}

public Action:CmdSelectChosen(client, args)
{
	if(args > 1 || args > 1)
	{
		PrintToChat(client, "[SM] Usage: sm_selectchosen <name>");
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	new target = GetTarget(arg);
	ChangePlayer(target, client);
	return Plugin_Handled;
}

public Action:CmdSpawnPack(client, args)
{
	if(args > 1 || args > 1)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnpack <name>");
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	new target = GetTarget(arg);
	SpawnPack(target);
	return Plugin_Handled;
}
//*********VOTE***********
/*
public Action:CmdVoteChosen(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_Vote);
	decl String:name[256], decl String:user[32];
	SetMenuTitle(menu, "Who should be The Chosen One?");
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
		{
			GetClientName(i, name, sizeof(name))
			IntToString(GetClientUserId(i), user, sizeof(user));
			AddMenuItem(menu, user, name);
		}
	}
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
}

public MenuHandler_Vote(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	if(action == MenuAction_Select)
	{
		decl String:name[256], String:user[32];
*/
//*****************************
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = INVALID_HANDLE;
	}
}

//Bot replaces a player
public Action:OnBotReplacePlayer(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new botuserid = GetEventInt(event, "bot");
	new bot = GetClientOfUserId(botuserid);
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if(client > 0 && g_bIsTracked[client])
	{
		g_bIsTracked[client] = false;
		g_bIsTracked[bot] = true;
		g_iChoosedClient = bot;
		g_iChoosedUserId = botuserid;
		#if DEBUG
		PrintToChatAll("The chosen one has been replaced (Prev: %i id: No id | New: %i id: %i)", client, bot, botuserid);
		#endif
	}
	
	if(client == 0 && !g_bSomeoneTracked)
	{
		g_bIsTracked[bot] = true;
		g_iChoosedClient = bot;
		g_iChoosedUserId = botuserid;
		#if DEBUG
		PrintToChatAll("The chosen one disconnected, took the next replace as valid (New: %i id: %i)", client, GetClientUserId(client), bot, botuserid);
		#endif
	}
	
	#if DEBUG
	decl String:sName[256];
	GetClientName(client, sName, sizeof(sName));
	PrintToChatAll("\x04[Event] \x01A bot(id:%i)(index: %i) just replaced %s", botuserid, bot, sName);
	#endif
}

public Action:OnPlayerReplaceBot(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new botuserid = GetEventInt(event, "bot");
	new bot = GetClientOfUserId(botuserid);
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	if(g_bIsTracked[bot])
	{
		g_bIsTracked[client] = true;
		g_bIsTracked[bot] = false;
		g_iChoosedClient = client;
		g_iChoosedUserId = GetClientUserId(client);
	}
	#if DEBUG
	decl String:sName[256];
	GetClientName(client, sName, sizeof(sName));
	PrintToChatAll("\x04[Event] \x01%s replaced a bot(id:%i)(index: %i)", sName, botuserid, bot);
	#endif
}

public OnRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_cvarEnable))
	{
		#if DEBUG
		PrintToChatAll("Plugin Disabled");
		#endif
		return;
	}
	g_bAct = true;
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 Round Started!");
	#endif
	if(g_hChooseTimer != INVALID_HANDLE)
	{
		KillTimer(g_hChooseTimer);
		g_hChooseTimer = INVALID_HANDLE;
	}
	g_hChooseTimer = CreateTimer(GetConVarFloat(g_cvarChooseTime), timerChoose);
	#if DEBUG
	PrintToChatAll("Creating the choose timer");
	#endif
	if(GetConVarBool(g_cvarAttach))
	{
		CreateTimer(5.0, timerCheckDistance, _, TIMER_REPEAT);
	}
}

public Action:timerCheckDistance(Handle:timer)
{
	if(!g_bAct)
	{
		return Plugin_Stop;
	}
	if(g_iChoosedClient != 0)
	{
		new Float:flMaxDistance = GetConVarFloat(g_cvarAttachRadius);
		#if DEBUG
		new userid = GetClientUserId(g_iChoosedClient);
		PrintToConsole(g_iChoosedClient, "Getting position from this client[Index :%i | User Id: %i]", g_iChoosedClient, userid);
		#endif
		
		//Declare the client's position and the target position as floats.
		decl Float:pos[3];
		
		//Get the client's position and store it on the declared variable.
		GetClientAbsOrigin(g_iChoosedClient, pos);
		#if DEBUG
		PrintToConsole(g_iChoosedClient, "Position for (%i) is: %f, %f, %f", userid, pos[0], pos[1], pos[2]);
		#endif
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				decl Float:distance;
				distance = CheckDistance(i, pos);
				if(FloatCompare(distance, flMaxDistance) != 1)
				{
					g_bInRadius[i] = true;
				}
				if(FloatCompare(distance, flMaxDistance) == 1)
				{
					g_bInRadius[i] = false;
					if(IsFakeClient(i))
					{
						#if DEBUG
						decl Float:bpos[3], String:sName[256];
						GetClientAbsOrigin(i, bpos);
						GetClientName(i, sName, sizeof(sName));
						PrintToConsole(g_iChoosedClient, "Target %i was too far! However, a fake client has been detected!", i);
						PrintToConsole(g_iChoosedClient, "The position of the target was: %f, %f, %f", bpos[0], bpos[1], bpos[2]);
						PrintToConsole(g_iChoosedClient, "Distance between you and the target is: %f / %f", distance, flMaxDistance);
						PrintToChatAll("%s (index: %i | id: %i) is too far! Warnings: %i", sName, i, GetClientUserId(i), g_iWarningCount[i]);
						#endif
					}
					else
					{
						if(GetEntProp(i, Prop_Send, "m_isIncapacitated") == 0 && !g_bWarning[i])
						{
							#if DEBUG
							PrintToConsole(g_iChoosedClient, "Target %i was too far! Start to warn the player!", i);
							#endif
							CreateTimer(GetConVarFloat(g_cvarAttachInterval), timerWarn, i, TIMER_REPEAT);
							g_bWarning[i] = true;
						}
						if(GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1 && GetConVarBool(g_cvarAttachIncap) && !g_bWarning[i])
						{
							#if DEBUG
							PrintToConsole(g_iChoosedClient, "Target %i was too far! Start to warn the player!");
							#endif
							CreateTimer(GetConVarFloat(g_cvarAttachInterval), timerWarn, i, TIMER_REPEAT);
							g_bWarning[i] = true;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:timerWarn(Handle:timer, any:client)
{
	if(!g_bAct)
	{
		return Plugin_Stop;
	}
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		if(g_iWarningCount[client] >= GetConVarInt(g_cvarAttachWarnings))
		{
			g_iWarningCount[client] = 0;
			switch(GetConVarInt(g_cvarAttachPenalty))
			{
				case 0:
				{
					if(GetEntProp(client, Prop_Send, "m_isIncapacitated") != 1)
					{
						IncapSurvivor(client, client);
					}
				}
				case 1:
				{
					HurtPlayer(client, GetConVarInt(g_cvarAttachHealth), GetConVarFloat(g_cvarAttachHealthInterval));
					YouAreHurt(client);
				}
				case 2:
				{
					YouAreFreezed(client);
					FreezePlayer(client);
				}
				case 3:
				{
					ForcePlayerSuicide(client);
				}
				case 4:
				{
					SpawnPack(client);
				}
			}
			g_iWarningCount[client] = 0;
			g_bWarning[client] = false;
			return Plugin_Stop;
		}
		if(g_iWarningCount[client] < GetConVarInt(g_cvarAttachWarnings))
		{
			switch(GetConVarInt(g_cvarAttachAnnounce))
			{
				case 1:
				{
					PrintToChat(client, "\x04 You are too far from the chosen one, get near him now!");
				}
				case 2:
				{
					PrintHintText(client, "You are too far from the chosen one, get near him now!");
				}
				case 3:
				{
					PrintCenterText(client, "You are too far from the chosen one, get near him now!");
				}
				case 4:
				{
					decl String:sMessage[256], String:sUser[256];
					Format(sMessage, sizeof(sMessage), "You are too far from the chosen one, get near him now!");
					IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
					new instructor  = CreateEntityByName("env_instructor_hint");
					DispatchKeyValue(client, "targetname", sUser);
					DispatchKeyValue(instructor, "hint_target", sUser);
					DispatchKeyValue(instructor, "hint_color", "255 255 255");
					DispatchKeyValue(instructor, "hint_caption", sMessage);
					DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_alert");
					DispatchKeyValue(instructor, "hint_timeout", "10");
					
					ClientCommand(client, "gameinstructor_enable 1");
					DispatchSpawn(instructor);
					AcceptEntityInput(instructor, "ShowHint", client);
					
					CreateTimer(10.0, timerEndHint, instructor);
				}
			}
			g_iWarningCount[client]++;
			return Plugin_Continue;
		}
	}
	else
	{
		g_iWarningCount[client] = 0;
		g_bWarning[client] = false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:timerChoose(Handle:timer)
{
	g_hChooseTimer = INVALID_HANDLE;
	#if DEBUG
	PrintToChatAll("Timer is over, proceeding");
	#endif
	//First, we check for the survivors count
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
		{
			g_iSurvivors++;
			if(!IsFakeClient(i))
			{
				g_iSurvivorPlayers++;
			}
		}
	}
	#if DEBUG
	PrintToChatAll("Found %i total survivors, and %i was/were human players", g_iSurvivors, g_iSurvivorPlayers);
	#endif
	SelectSurvivor();
	if(g_iChoosedClient == 0)
	{
		SelectSurvivor();
		if(g_iChoosedClient == 0)
		{
			SelectSurvivor();
		}
	}
	if(g_iChoosedClient > 0)
	{
		g_iChoosedUserId = GetClientUserId(g_iChoosedClient);
	}
	else
	{
		#if debug
		PrintToChatAll("No survivors choosed!");
		#endif
	}
	SetUpchosenSurvivor();
	for(new i=1;i<=MaxClients;i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && !IsFakeClient(i))
		{
			Announce(i);
		}
	}

	#if DEBUG
	decl String:sName[256];
	GetClientName(g_iChoosedClient, sName, sizeof(sName));
	PrintToChatAll("Choosed %s (%i | id:%i)", sName, g_iChoosedClient, g_iChoosedUserId);
	#endif
}

public OnMapStart()
{
	decl String:gamemode[32];
	GetConVarString(g_hGameMode, gamemode, sizeof(gamemode));
	if(StrEqual(gamemode, "coop") || StrEqual(gamemode, "realism") || StrEqual(gamemode, "mutation9") || StrEqual(gamemode, "versuscoop"))
	{
		g_iGameMode = 0;
	}
	
	if(StrEqual(gamemode, "versus") || StrEqual(gamemode, "versussurvival"))
	{
		g_iGameMode = 1;
	}
	
	if(StrEqual(gamemode, "scavenge"))
	{
		g_iGameMode = 2;
	}
	
	if(StrEqual(gamemode, "survival"))
	{
		g_iGameMode = 3;
	}
	PrecacheSound(ALERTSOUND);
	PrecacheSound(BEEPSOUND);
	PrecacheSound(BOOMSOUND);
	PrecacheSound(FIRE_SOUND);
	PrecacheSound(EXPLOSION_SOUND);
	
	PrecacheModel("sprites/muzzleflash4.vmt");
	
	PrefetchSound(ALERTSOUND);
	PrefetchSound(BEEPSOUND);
	PrefetchSound(BOOMSOUND);
	PrefetchSound(FIRE_SOUND);
	PrefetchSound(EXPLOSION_SOUND);
}

public OnClientPutInServer(client)
{
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(20.0, timerAnnounce, client);
		#if DEBUG
		PrintToConsole(client, "Running advert timer for you");
		#endif
	}
}

public OnClientDisconnect(client)
{
	#if DEBUG
	PrintToChatAll("Client %i is disconnecting!", client);
	#endif
	if(client == g_iChoosedClient)
	{
		g_bIsTracked[client] = false;
		g_bSomeoneTracked = false;
	}
}

public Action:timerAnnounce(Handle:timer, any:client)
{
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		#if DEBUG
		PrintToConsole(client, "You passed the filters");
		#endif
		switch(GetConVarInt(g_cvarAdvert))
		{
			case 1:
			{
				#if DEBUG
				PrintToConsole(client, "Advert type is: Chat");
				#endif
				if(GetClientTeam(client) == 3 || GetClientTeam(client) == 1)
				{
					PrintToChat(client, "\x04[SM]\x03 This server is under 'The chosen One' mode. Kill the chosen one to win!");
				}
				else
				{
					PrintToChat(client, "\x04[SM]\x03 This server is under 'The chosen One' mode. Protect the chosen one or face the consequences!");
				}
			}
			case 2:
			{
				#if DEBUG
				PrintToConsole(client, "Advert type is: Hint Text");
				#endif
				if(GetClientTeam(client) == 3 || GetClientTeam(client) == 1)
				{
					PrintHintText(client, "[SM] This server is under 'The chosen One' mode. Kill the chosen one to win!");
				}
				else
				{
					PrintHintText(client, "[SM] This server is under 'The chosen One' mode. Protect the chosen one or face the consequences!");
				}
			}
			case 3:
			{
				#if DEBUG
				PrintToConsole(client, "Advert type is: Center Hint Text");
				#endif
				if(GetClientTeam(client) == 3 || GetClientTeam(client) == 1)
				{
					PrintCenterText(client, "[SM] This server is under 'The chosen One' mode. Kill the chosen one to win!");
				}
				else
				{
					PrintCenterText(client, "[SM] This server is under 'The chosen One' mode. Protect the chosen one or face the consequences!");
				}
			}
		}
	}
}

public OnIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsTracked[client])
	{
		EmitAlert();
		for(new i=1;i<=MaxClients;i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
			{
				Alert(i);
			}
		}
	}
}

public OnRevived(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if(g_bIsTracked[client])
	{
		new revivecount = GetEntProp(g_iChoosedClient, Prop_Send, "m_currentReviveCount");
		if(revivecount == (GetConVarInt(g_hSurvivorMaxIncapCount)-1))
		{
			EmitBeep();
			CreateTimer(1.0, timerBeep, _, TIMER_REPEAT);
		}
	}
}

public OnPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new entityid = GetEventInt(event, "attackerentid");
	new damagetype = GetEventInt(event, "type");
	decl String:sHammer[256];
	GetEdictClassname(entityid, sHammer, sizeof(sHammer));
	if(g_bIsTracked[client] && GetConVarBool(g_cvarSuicide))
	{
		#if DEBUG
		PrintToChatAll("Chosen one death, checking state!");
		PrintToChatAll("Carried: %b, Jockey: %b, Hit: %b", g_bCarried, g_bRiden, g_bHit);
		#endif
		if(!g_bHit && !g_bRiden && !g_bCarried && !g_bTanked && (client == attacker || damagetype == 32 || StrEqual(sHammer, "trigger_hurt_ghost")))
		{
			#if DEBUG
			PrintToChatAll("The chosen one commited suicide, proceed to select a new survivor...");
			#endif
			g_bIsTracked[client] = false;
			g_bWarning[client] = false;
			g_iWarningCount[client] = 0;
			g_bInRadius[client] = true;
			g_bSomeoneTracked = false;
			g_iChoosedClient = 0;
			g_iChoosedUserId = 0;
			g_iSurvivors = 0;
			g_iSurvivorPlayers = 0;
			if(g_hChooseTimer != INVALID_HANDLE)
			{
				KillTimer(g_hChooseTimer);
				g_hChooseTimer = INVALID_HANDLE;
			}
			g_bCarried = false;
			g_bHit = false;
			g_bRiden = false;
			g_bTanked = false;
			g_hChooseTimer = CreateTimer(1.0, timerChoose);
		}
	}
	
	if(g_bIsTracked[client])
	{
		g_bCarried = false;
		g_bHit = false;
		g_bRiden = false;
		g_bTanked = false;
		#if DEBUG
		PrintToChatAll("The chosen one is death, proceeding with penaly!");
		#endif
		if(GetConVarInt(g_cvarPenalty) == 0)
		{
			CreateExplosion(client, 0);
			#if DEBUG
			PrintToChatAll("Created explosion!");
			#endif
		}
		if(GetConVarInt(g_cvarPenalty) == 1)
		{
			EndGame();
			#if DEBUG
			PrintToChatAll("Ended game!");
			#endif
		}
		if(GetConVarInt(g_cvarPenalty) == 2)
		{
			DamageTeam(2, GetConVarInt(g_cvarHealthPenalty), 0);
			#if DEBUG
			PrintToChatAll("Damaged the entire team!");
			#endif
		}
		if(GetConVarInt(g_cvarPenalty) == 3)
		{
			CreateExplosion(client, 1);
			#if DEBUG
			PrintToChatAll("Incapacitated survivors within radius!");
			#endif
		}
	}
}

public OnHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	if(g_bIsTracked[client] && attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 3)
	{
		decl String:weapon[256]; 
		new entity = GetEntDataEnt2(attacker, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
		GetEntityNetClass(entity, weapon, sizeof(weapon));
		if(StrEqual(weapon, "CTankClaw"))
		{
			g_bTanked = true;
			if(g_hTankedTimeOut != INVALID_HANDLE)
			{
				KillTimer(g_hTankedTimeOut);
				g_hTankedTimeOut = INVALID_HANDLE;
			}
			g_hTankedTimeOut = CreateTimer(5.5, timerTankedTimeOut);
		}
	}
	
	if(g_bIsTracked[client] && attacker != client && GetConVarInt(g_cvarFriendly) > 0)
	{
		if(attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2)
		{
			switch(GetConVarInt(g_cvarFriendly))
			{
				case 1:
				{
					new health = GetClientHealth(client);
					new total = health+damage;
					SetEntityHealth(client, total);
				}
				case 2:
				{
					new health = GetClientHealth(client);
					new total = health+damage;
					SetEntityHealth(client, total);
					new revenge = RoundToNearest((total*GetConVarFloat(g_cvarFriendlyPunish)) / 100);
					SetEntityHealth(attacker, revenge);
				}
			}
		}
	}
	
	if(g_bIsTracked[attacker] && client > 0 && attacker != client && IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && GetConVarBool(g_cvarFriendlyChoosed))
	{
		new health = GetClientHealth(client);
		new total = health+damage;
		SetEntityHealth(client, total);
	}
	
	if(g_bIsTracked[client] && GetConVarBool(g_cvarHurt) && attacker != client )
	{
		switch(GetRandomInt(1, GetConVarInt(g_cvarHurtLuck)))
		{
			case 1:
			{
				if(attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && GetConVarInt(g_cvarFriendly) > 0)
				{
					return;
				}
				new newdamage = RoundToFloor((damage*GetConVarFloat(g_cvarHurtDiv)) / 100.0);
				DamageTeam(2, newdamage, g_iChoosedClient);
			}
		}
	}
}

public OnVomit(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(g_bIsTracked[client] && GetConVarBool(g_cvarVomit))
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
			{
				SDKCall(sdkCallVomitPlayer, i, attacker, true);
			}
		}
	}
}

public OnChargerImpact(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if(g_bIsTracked[victim])
	{
		g_bHit = true;
		if(g_hHitTimeOut != INVALID_HANDLE)
		{
			KillTimer(g_hHitTimeOut);
			g_hHitTimeOut = INVALID_HANDLE;
		}
		g_hHitTimeOut = CreateTimer(4.5, timerHitTimeOut);
	}
}

public OnCarried(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if(g_bIsTracked[victim])
	{
		g_bCarried = true;
		if(g_hCarryTimeOut != INVALID_HANDLE)
		{
			KillTimer(g_hCarryTimeOut);
			g_hCarryTimeOut = INVALID_HANDLE;
		}
		g_hCarryTimeOut = CreateTimer(10.0, timerCarryTimeOut);
		#if DEBUG
		PrintToChatAll("Chosen one being carried! [%b]", g_bCarried);
		#endif
	}
}

public OnRideStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if(g_bIsTracked[victim])
	{
		g_bRiden = true;
	}
}

public OnRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if(g_bIsTracked[victim])
	{
		g_bRiden = false;
	}
}

public OnMapEnd()
{
	if(g_hEndGame != INVALID_HANDLE)
	{
		KillTimer(g_hEndGame);
		g_hEndGame = INVALID_HANDLE;
	}
	if(g_hChooseTimer != INVALID_HANDLE)
	{
		KillTimer(g_hChooseTimer);
		g_hChooseTimer = INVALID_HANDLE;
	}
	g_bBeenSet = false;
	g_iSurvivors = 0;
	g_iChoosedClient = 0;
	g_iChoosedUserId = 0;
	g_iSurvivorPlayers = 0;
	g_bSomeoneTracked = false;
	g_bAct = false;
	g_bCarried = false;
	g_bHit = false;
	g_bRiden = false;
	g_bTanked = false;
	for(new i=1; i<=MaxClients; i++)
	{
		g_bIsTracked[i] = false;
		g_bWarning[i] = false;
		g_iWarningCount[i] = 0;
		g_bInRadius[i] = true;
	}
}

public OnMissionLost(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_iGameMode != 0)
	{
		return;
	}
	g_bBeenSet = false;
	g_bAct = false;
	if(g_hEndGame != INVALID_HANDLE)
	{
		KillTimer(g_hEndGame);
		g_hEndGame = INVALID_HANDLE;
	}
	if(g_hChooseTimer != INVALID_HANDLE)
	{
		KillTimer(g_hChooseTimer);
		g_hChooseTimer = INVALID_HANDLE;
	}
	g_iSurvivors = 0;
	g_iChoosedClient = 0;
	g_iChoosedUserId = 0;
	g_iSurvivorPlayers = 0;
	g_bSomeoneTracked = false;
	g_bCarried = false;
	g_bHit = false;
	g_bRiden = false;
	g_bTanked = false;
	for(new i=1; i<=MaxClients; i++)
	{
		g_bIsTracked[i] = false;
		g_bWarning[i] = false;
		g_iWarningCount[i] = 0;
		g_bInRadius[i] = true;
	}
}

public OnRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	g_bBeenSet = false;
	g_bAct = false;
	if(g_hEndGame != INVALID_HANDLE)
	{
		KillTimer(g_hEndGame);
		g_hEndGame = INVALID_HANDLE;
	}
	if(g_hChooseTimer != INVALID_HANDLE)
	{
		KillTimer(g_hChooseTimer);
		g_hChooseTimer = INVALID_HANDLE;
	}
	g_iSurvivors = 0;
	g_iChoosedClient = 0;
	g_iChoosedUserId = 0;
	g_iSurvivorPlayers = 0;
	g_bSomeoneTracked = false;
	g_bCarried = false;
	g_bHit = false;
	g_bRiden = false;
	g_bTanked = false;
	for(new i=1; i<=MaxClients; i++)
	{
		g_bIsTracked[i] = false;
		g_bWarning[i] = false;
		g_iWarningCount[i] = 0;
		g_bInRadius[i] = true;
	}
}

SelectSurvivor()
{
	if(g_bSomeoneTracked)
	{
		return;
	}
	
	if(g_iSurvivorPlayers == 0)
	{
		new botcount = 0;
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
			{
				botcount++;
				if(botcount >= 2)
				{
					g_iChoosedClient = i;
					g_bIsTracked[i] = true;
					g_bSomeoneTracked = true;
					botcount = 0;
					return;
				}
			}
		}
	}
	
	if(g_iSurvivorPlayers > 0)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
			{
				if(!IsFakeClient(i))
				{
					if(g_iSurvivorPlayers <= 2)
					{
						g_iChoosedClient = i;
						g_bIsTracked[i] = true;
						g_bSomeoneTracked = true;
						return;
					}
					else
					{
						switch(GetRandomInt(1, 2))
						{
							case 1:
							{
								g_iChoosedClient = i;
								g_bIsTracked[i] = true;
								g_bSomeoneTracked = true;
								return;
							}
						}
					}
				}
			}
		}
	}
}

SetUpchosenSurvivor()
{
	if(g_bBeenSet)
	{
		return;
	}
	if(g_iChoosedClient == 0 || !g_bSomeoneTracked || !IsValidEntity(g_iChoosedClient))
	{
		return;
	}
	KeepColor();
	SetEntityHealth(g_iChoosedClient, GetConVarInt(g_cvarHealth));
	g_bBeenSet = true;
}

KeepColor()
{
	if(GetConVarInt(g_cvarColor) == 1) //RED
	{
		SetEntityRenderColor(g_iChoosedClient, 189, 9, 13, 235);
	}
	if(GetConVarInt(g_cvarColor) == 2) //BLUE
	{
		SetEntityRenderColor(g_iChoosedClient, 34, 22, 173, 235);
	}
	if(GetConVarInt(g_cvarColor) == 3) //GREEN
	{
		SetEntityRenderColor(g_iChoosedClient, 34, 120, 24, 235);
	}
	if(GetConVarInt(g_cvarColor) == 4) //BLACK
	{
		SetEntityRenderColor(g_iChoosedClient, 0, 0, 0, 235);
	}
	if(GetConVarInt(g_cvarColor) == 5) //INVISIBLE
	{
		SetEntityRenderColor(g_iChoosedClient, 255, 255, 255, 0);
	}
	if(GetConVarInt(g_cvarColor) == 6) //NORMAL
	{
		SetEntityRenderColor(g_iChoosedClient, 255, 255, 255, 255);
	}
	CreateTimer(45.0, timerCheckColor, _, TIMER_REPEAT);
}

public Action:timerCheckColor(Handle:timer)
{
	if(!g_bAct)
	{
		return Plugin_Stop;
	}
	if(g_iChoosedClient > 0 && IsValidEntity(g_iChoosedClient) && IsClientInGame(g_iChoosedClient) && IsPlayerAlive(g_iChoosedClient))
	{
		if(GetConVarInt(g_cvarColor) == 1) //RED
		{
			SetEntityRenderColor(g_iChoosedClient, 189, 9, 13, 235);
		}
		if(GetConVarInt(g_cvarColor) == 2) //BLUE
		{
			SetEntityRenderColor(g_iChoosedClient, 34, 22, 173, 235);
		}
		if(GetConVarInt(g_cvarColor) == 3) //GREEN
		{
			SetEntityRenderColor(g_iChoosedClient, 34, 120, 24, 235);
		}
		if(GetConVarInt(g_cvarColor) == 4) //BLACK
		{
			SetEntityRenderColor(g_iChoosedClient, 0, 0, 0, 235);
		}
		if(GetConVarInt(g_cvarColor) == 5) //INVISIBLE
		{
			SetEntityRenderColor(g_iChoosedClient, 255, 255, 255, 0);
		}
		if(GetConVarInt(g_cvarColor) == 6) //NORMAL
		{
			SetEntityRenderColor(g_iChoosedClient, 255, 255, 255, 255);
		}
	}
	return Plugin_Continue;
}

CreateExplosion(client, kind)
{
	new Float:flMaxDistance = GetConVarFloat(g_cvarRadius);
	new Float:power = GetConVarFloat(g_cvarPower);
	new tcount = 0;
	#if DEBUG
	new userid = GetClientUserId(client);
	PrintToConsole(client, "Getting position from this client[Index :%i | User Id: %i]", client, userid);
	#endif
	
	//Declare the client's position and the target position as floats.
	decl Float:pos[3], Float:tpos[3], Float:distance[3];
	
	//Get the client's position and store it on the declared variable.
	GetClientAbsOrigin(client, pos);
	#if DEBUG
	PrintToConsole(client, "Position for (%i) is: %f, %f, %f", userid, pos[0], pos[1], pos[2]);
	#endif
	if(kind == 0)
	{
		decl String:sRadius[256];
		decl String:sPower[256];
		IntToString(GetConVarInt(g_cvarRadius), sRadius, sizeof(sRadius));
		IntToString(GetConVarInt(g_cvarPower), sPower, sizeof(sPower));
		new exParticle = CreateEntityByName("info_particle_system");
		new exParticle2 = CreateEntityByName("info_particle_system");
		new exParticle3 = CreateEntityByName("info_particle_system");
		new exTrace = CreateEntityByName("info_particle_system");
		new exEntity = CreateEntityByName("env_explosion");
		new exPhys = CreateEntityByName("env_physexplosion");
		new exHurt = CreateEntityByName("point_hurt");
		/*new exPush = CreateEntityByName("point_push");*/
		
		//Set up the particle explosion
		DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
		DispatchSpawn(exParticle);
		ActivateEntity(exParticle);
		TeleportEntity(exParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
		DispatchSpawn(exParticle2);
		ActivateEntity(exParticle2);
		TeleportEntity(exParticle2, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
		DispatchSpawn(exParticle3);
		ActivateEntity(exParticle3);
		TeleportEntity(exParticle3, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
		DispatchSpawn(exTrace);
		ActivateEntity(exTrace);
		TeleportEntity(exTrace, pos, NULL_VECTOR, NULL_VECTOR);
		
		
		//Set up explosion entity
		DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
		DispatchKeyValue(exEntity, "iMagnitude", sPower);
		DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
		DispatchKeyValue(exEntity, "spawnflags", "828");
		DispatchSpawn(exEntity);
		TeleportEntity(exEntity, pos, NULL_VECTOR, NULL_VECTOR);
		
		//Set up physics movement explosion
		DispatchKeyValue(exPhys, "radius", sRadius);
		DispatchKeyValue(exPhys, "magnitude", sPower);
		DispatchSpawn(exPhys);
		TeleportEntity(exPhys, pos, NULL_VECTOR, NULL_VECTOR);
		
		//Set up hurt point
		DispatchKeyValue(exHurt, "DamageRadius", sRadius);
		DispatchKeyValue(exHurt, "DamageDelay", "0.1");
		DispatchKeyValue(exHurt, "Damage", "1");
		DispatchKeyValue(exHurt, "DamageType", "8");
		DispatchSpawn(exHurt);
		TeleportEntity(exHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		EmitSoundToAll(EXPLOSION_SOUND, exParticle);
		
		//BOOM!
		AcceptEntityInput(exParticle, "Start");
		AcceptEntityInput(exParticle2, "Start");
		AcceptEntityInput(exParticle3, "Start");
		AcceptEntityInput(exTrace, "Start");
		AcceptEntityInput(exEntity, "Explode");
		AcceptEntityInput(exPhys, "Explode");
		AcceptEntityInput(exHurt, "TurnOn");
		
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, exTrace);
		WritePackCell(pack, exHurt);
		CreateTimer(GetConVarFloat(g_cvarFireTrace), timerStopFire, pack);
	}
	
	//Find any possible colliding clients.
	for(new i=1; i<=MaxClients; i++)
	{
		if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		if(GetClientTeam(i) != 2)
		{
			continue;
		}
		tcount++;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
		distance[0] = (pos[0] - tpos[0]);
		distance[1] = (pos[1] - tpos[1]);
		distance[2] = (pos[2] - tpos[2]);
		
		new Float:realdistance = SquareRoot(FloatMul(distance[0],distance[0])+FloatMul(distance[1],distance[1]));
		if(realdistance <= flMaxDistance)
		{
			#if DEBUG
			PrintToConsole(client, "Got a matching target[id: %i | pos: %f, %f, %f", GetClientUserId(i), tpos[0], tpos[1], tpos[2]);
			PrintToConsole(client, "Distance is: %f, %f, %f", distance[0], distance[1], distance[2]);
			#endif
			decl Float:addVel[3], Float:final[3], Float:tvec[3], Float:ratio[3];
			
			ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio x/hypo
			ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio y/hypo
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", tvec);
			
			addVel[0] = FloatMul(ratio[0]*-1, power);
			addVel[1] = FloatMul(ratio[1]*-1, power);
			addVel[2] = power;
			
			final[0] = FloatAdd(addVel[0], tvec[0]);
			final[1] = FloatAdd(addVel[1], tvec[1]);
			final[2] = power;
			#if DEBUG
			PrintToConsole(client, "Original target velocity: %f, %f, %f", tvec[0], tvec[1], tvec[2]);
			PrintToConsole(client, "Added target velocity: %f, %f, %f", addVel[0], addVel[1], addVel[2]);
			PrintToConsole(client, "Final target velocity: %f, %f, %f", final[0], final[1], final[2]);
			#endif
			if(kind == 0)
			{
				FlingPlayer(i, addVel, client);
			}
			
			if(kind == 1)
			{
				IncapSurvivor(i, i);
			}
			#if DEBUG
			PrintToConsole(client, "Target %i got teleported!", GetClientUserId(i));
			#endif
		}
	}
}

public Action:timerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

DamageTeam(team, damage, exception)
{
	new health = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == team)
		{
			if(exception != 0 && exception == i)
			{
				continue;
			}
			health = GetClientHealth(i);
			new total = health-damage;
			if(total <= 0)
			{
				IncapSurvivor(i, i);
			}
			SetEntityHealth(i, total);
		}
	}
}

EndGame()
{
	if(g_hEndGame != INVALID_HANDLE)
	{
		KillTimer(g_hEndGame);
		g_hEndGame = INVALID_HANDLE;
	}
	g_hEndGame = CreateTimer(GetConVarFloat(g_cvarEndGame), timerEndGame);
}

public Action:timerEndGame(Handle:timer)
{
	g_hEndGame = INVALID_HANDLE;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
		{
			ForcePlayerSuicide(i);
		}
	}
}

IncapSurvivor(client, attacker)
{
	if(IsValidEntity(client))
	{
		decl String:sUser[256];
		IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
		new iDmgEntity = CreateEntityByName("point_hurt");
		SetEntityHealth(client, 1);
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
		DispatchKeyValue(iDmgEntity, "Damage", "1");
		DispatchKeyValue(iDmgEntity, "DamageType", "0");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", attacker);
		RemoveEdict(iDmgEntity);
	}
}

stock FlingPlayer(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	SDKCall(sdkCallPushPlayer, target, vector, 96, attacker, stunTime);
}

Announce(client)
{
	decl String:sUser[32], String:sMessage[256], sName[256];
	GetClientName(g_iChoosedClient, sName, sizeof(sName));
	if(GetClientTeam(client) == 2)
	{
		switch(GetConVarInt(g_cvarAdvertSurvivor))
		{
			case 1:
			{
				PrintToChat(client, "\x04 %s is the chosen one, protect him at all cost!", sName);
			}
			case 2:
			{
				PrintHintText(client, "%s is the chosen one, protect him at all cost!", sName);
			}
			case 3:
			{
				PrintCenterText(client, "%s is the chosen one, protect him at all cost!", sName);
			}
			case 4:
			{
				Format(sMessage, sizeof(sMessage), "%s is the chosen one, protect him at all cost!", sName);
				IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
				new instructor  = CreateEntityByName("env_instructor_hint");
				DispatchKeyValue(client, "targetname", sName);
				DispatchKeyValue(instructor, "hint_target", sName);
				DispatchKeyValue(instructor, "hint_color", "255 255 255");
				DispatchKeyValue(instructor, "hint_caption", sMessage);
				DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_shield");
				DispatchKeyValue(instructor, "hint_timeout", "10");
				
				ClientCommand(client, "gameinstructor_enable 1");
				DispatchSpawn(instructor);
				AcceptEntityInput(instructor, "ShowHint", client);
				
				CreateTimer(10.0, timerEndHint, instructor);
			}
		}
	}
	
	if(GetClientTeam(client) == 3)
	{
		switch(GetConVarInt(g_cvarAdvertInfected))
		{
			case 1:
			{
				PrintToChat(client, "\x04 %s is the chosen one, kill him to win!", sName);
			}
			case 2:
			{
				PrintHintText(client, "%s is the chosen one, kill him to win!", sName);
			}
			case 3:
			{
				PrintCenterText(client, "%s is the chosen one, kill him to win!", sName);
			}
			case 4:
			{
				Format(sMessage, sizeof(sMessage), "%s is the chosen one, kill him to win!", sName);
				IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
				new instructor  = CreateEntityByName("env_instructor_hint");
				DispatchKeyValue(client, "targetname", sName);
				DispatchKeyValue(instructor, "hint_target", sName);
				DispatchKeyValue(instructor, "hint_color", "255 255 255");
				DispatchKeyValue(instructor, "hint_caption", sMessage);
				DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_skull");
				DispatchKeyValue(instructor, "hint_timeout", "10");
				
				ClientCommand(client, "gameinstructor_enable 1");
				DispatchSpawn(instructor);
				AcceptEntityInput(instructor, "ShowHint", client);
				
				CreateTimer(10.0, timerEndHint, instructor);
			}
		}
	}
}

Alert(client)
{
	decl String:sUser[32], String:sMessage[256], sName[256];
	GetClientName(g_iChoosedClient, sName, sizeof(sName));
	Format(sMessage, sizeof(sMessage), "The chosen one is in trouble!!!", sName);
	IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
	new instructor  = CreateEntityByName("env_instructor_hint");
	DispatchKeyValue(client, "targetname", sName);
	DispatchKeyValue(instructor, "hint_target", sName);
	DispatchKeyValue(instructor, "hint_color", "255 255 255");
	DispatchKeyValue(instructor, "hint_caption", sMessage);
	DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_skull");
	DispatchKeyValue(instructor, "hint_pulseoption", "3");
	DispatchKeyValue(instructor, "hint_timeout", "10");
	
	ClientCommand(client, "gameinstructor_enable 1");
	DispatchSpawn(instructor);
	AcceptEntityInput(instructor, "ShowHint", client);
	CreateTimer(10.0, timerEndHint, instructor);
}

YouAreHurt(client)
{
	decl String:sUser[32], String:sMessage[256], sName[256];
	GetClientName(g_iChoosedClient, sName, sizeof(sName));
	Format(sMessage, sizeof(sMessage), "Get near the chosen one to stop receiving pain!!");
	IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
	new instructor  = CreateEntityByName("env_instructor_hint");
	DispatchKeyValue(client, "targetname", sName);
	DispatchKeyValue(instructor, "hint_target", sName);
	DispatchKeyValue(instructor, "hint_color", "255 255 255");
	DispatchKeyValue(instructor, "hint_caption", sMessage);
	DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_skull");
	DispatchKeyValue(instructor, "hint_pulseoption", "1");
	DispatchKeyValue(instructor, "hint_timeout", "10");
	
	ClientCommand(client, "gameinstructor_enable 1");
	DispatchSpawn(instructor);
	AcceptEntityInput(instructor, "ShowHint", client);
	CreateTimer(10.0, timerEndHint, instructor);
}

YouAreFreezed(client)
{
	decl String:sUser[32], String:sMessage[256], sName[256];
	GetClientName(g_iChoosedClient, sName, sizeof(sName));
	Format(sMessage, sizeof(sMessage), "You were too far from the chosen one for too long, you are now frozen!");
	IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
	new instructor  = CreateEntityByName("env_instructor_hint");
	DispatchKeyValue(client, "targetname", sName);
	DispatchKeyValue(instructor, "hint_target", sName);
	DispatchKeyValue(instructor, "hint_color", "255 255 255");
	DispatchKeyValue(instructor, "hint_caption", sMessage);
	DispatchKeyValue(instructor, "hint_icon_onscreen", "icon_skull");
	DispatchKeyValue(instructor, "hint_pulseoption", "1");
	DispatchKeyValue(instructor, "hint_timeout", "10");
	
	ClientCommand(client, "gameinstructor_enable 1");
	DispatchSpawn(instructor);
	AcceptEntityInput(instructor, "ShowHint", client);
	CreateTimer(10.0, timerEndHint, instructor);
}


public Action:timerEndHint(Handle:timer, any:entity)
{
	RemoveEdict(entity);
}

public Action:timerBeep(Handle:timer)
{
	if(GetEntProp(g_iChoosedClient, Prop_Send, "m_currentReviveCount") == g_hSurvivorMaxIncapCount - 1)
	{
		return Plugin_Continue;
	}
	else
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				StopSound(i, -1, BEEPSOUND);
			}
		}
		return Plugin_Stop;
	}
}

EmitAlert()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && i != g_iChoosedClient)
		{
			EmitSoundToClient(i, ALERTSOUND, g_iChoosedClient, _, _, _, 0.56);
		}
	}
}
EmitBeep()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && i != g_iChoosedClient)
		{
			EmitSoundToClient(i, BEEPSOUND, g_iChoosedClient);
		}
	}
}

CheckDistance(client, Float:position[3])
{
	decl Float:tpos[3], Float:distance[3], Float:realdistance;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", tpos);
	distance[0] = (position[0] - tpos[0]);
	distance[1] = (position[1] - tpos[1]);
	distance[2] = (position[2] - tpos[2]);
	realdistance = SquareRoot(FloatMul(distance[0],distance[0])+FloatMul(distance[1],distance[1]));
	return realdistance;
}

HurtPlayer(client, damage, Float:interval)
{
	new Handle:hurtpack = CreateDataPack();
	WritePackCell(hurtpack, client);
	WritePackCell(hurtpack, damage);
	CreateTimer(interval, timerHurtPlayer, hurtpack, TIMER_REPEAT);
}

public Action:timerHurtPlayer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	if(g_bInRadius[client])
	{
		return Plugin_Stop;
	}
	else
	{
		new health = GetClientHealth(client);
		new total = health-damage;
		if(total <= 0)
		{
			IncapSurvivor(client, client);
		}
		else
		{
			SetEntityHealth(client, total);
		}
		return Plugin_Continue;
	}
}

FreezePlayer(client)
{
	new g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	SetEntDataFloat(client, g_flLagMovement, 0.0, true);
	CreateTimer(1.0, timerMaintainSpeed, client, TIMER_REPEAT);
}

public Action:timerMaintainSpeed(Handle:timer, any:client)
{
	if(g_bInRadius[client])
	{
		new g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
		SetEntDataFloat(client, g_flLagMovement, 1.0, true);
		return Plugin_Handled;
	}
	else if(!g_bAct)
	{
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

SpawnPack(client)
{
	decl String:spawninfected[256]; //string
	GetConVarString(g_cvarAttachInfected, spawninfected, sizeof(spawninfected));
	if(StrContains(spawninfected, "boomer") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "boomer");
		}
	}
	if(StrContains(spawninfected, "smoker") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "smoker");
		}
	}
	if(StrContains(spawninfected, "jockey") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "jockey");
		}
	}
	if(StrContains(spawninfected, "spitter") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "spitter");
		}
	}
	if(StrContains(spawninfected, "hunter") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "hunter");
		}
	}
	if(StrContains(spawninfected, "charger") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "charger");
		}
	}
	if(StrContains(spawninfected, "tank") != -1)
	{
		new infbot = CreateFakeClient("Infected Bot");
		if (infbot > 0)
		{
			ChangeClientTeam(infbot, 3);
			CreateTimer(0.1, timerRemoveBot, infbot);
			CheatCommand(client, "z_spawn", "tank");
		}
	}
}

public Action:timerRemoveBot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsClientInKickQueue(client))
	{
		if (IsFakeClient(client)) 
		{
			KickClient(client);
		}
	}
}

ChangePlayer(target, sender)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is not available anymore");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Cannot set a spectator as The Choosen One!");
		return;
	}
	if(GetClientTeam(target) == 3)
	{
		PrintToChat(sender, "[SM]Cannot set an infected as The Choosen One!");
		return;
	}
	new oldclient = g_iChoosedClient;
	new newuserid = GetClientUserId(target);
	new newclient = target;
	g_iChoosedClient = newclient;
	g_iChoosedUserId = newuserid;
	g_bIsTracked[newclient] = true;
	g_bIsTracked[oldclient] = false;
	#if DEBUG
	PrintToChatAll("Client %i replaced %i as the Chosen One", newclient, oldclient);
	#endif
	for(new i=1;i<=MaxClients;i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && !IsFakeClient(i))
		{
			Announce(i);
		}
	}
}

GetTarget(String:targetname[])
{
	for(new i=1; i<=MaxClients; i++)
	{
		decl String:name[256];
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			GetClientName(i, name, sizeof(name));
			if(StrEqual(targetname, name))
			{
				return i;
			}
		}
	}
	return -1;
}

//Using commands that need sv_cheats 1 on them.
CheatCommand(client, String:command[], String:arguments[])
{
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsValidEntity(client)) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags (command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}
//*******************************************ADMIN MENU*******************************
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hTopMenu) return;
	g_hTopMenu = topmenu;
	new TopMenuObject:players_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	// now we add the function ...
	if (players_commands != INVALID_TOPMENUOBJECT && GetConVarBool(g_cvarAdmin))
	{
		AddToTopMenu (g_hTopMenu, "l4d2selectchosen", TopMenuObject_Item, MenuItem_SelectChosen, players_commands, "l4d2selectchosen", ADMFLAG_SLAY);
	}
}

public MenuItem_SelectChosen(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Select Chosen One", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplaySelectChosenMenu(param);
	}
}

DisplaySelectChosenMenu(client)
{
	new Handle:menu2 = CreateMenu(MenuHandler_ChosenPlayer);
	SetMenuTitle(menu2, "Select Player:");
	SetMenuExitBackButton(menu2, true);
	AddTargetsToMenu2(menu2, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu2, client, MENU_TIME_FOREVER);
}

public MenuHandler_ChosenPlayer(Handle:menu2, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		GetMenuItem(menu2, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		ChangePlayer(target, param1);
		DisplaySelectChosenMenu(param1);
	}
}

public Action:timerCarryTimeOut(Handle:timer)
{
	#if DEBUG
	PrintToChatAll("Chosen one carry time out!");
	#endif
	g_bCarried = false;
	g_hCarryTimeOut = INVALID_HANDLE;
}

public Action:timerHitTimeOut(Handle:timer)
{
	g_bHit = false;
	g_hHitTimeOut = INVALID_HANDLE;
}

public Action:timerTankedTimeOut(Handle:timer)
{
	g_bTanked = false;
	g_hTankedTimeOut = INVALID_HANDLE;
}