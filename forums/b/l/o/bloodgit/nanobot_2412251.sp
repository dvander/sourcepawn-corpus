/* ===================================
*				Heading
* ==================================== */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL "http://nanochip.me/myplugins/nanobot/updatefile.txt"

/* ===================================
*			Initialize Variables
* ==================================== */
// cvars
new Handle:cvarEnable, Handle:cvarAirblastNear, Handle:cvarBotName, Handle:cvarModel, Handle:cvarVoteMode, Handle:cvarVoteTime, Handle:cvarVoteTimeDelay, Handle:cvarVotePercentage, Handle:cvarVictorySpeed, Handle:cvarMinPlayers, Handle:cvarMaxPlayers, Handle:cvarAutoReflect;

// plugin logic
new bool:NanobotEnabled = false; // check if the mode is actually enabled
new bool:allowed[MAXPLAYERS+1] = {false, ...}; // aka autoreflect
new bool:MapChanged; // check if the map changed
new bool:BotBeaten; // check if the bot was beaten somehow
new bool:commandEnable; // check if we can use the nanobot command
new bool:commandDisable; // ^

// pvb vote settings
new nVoters = 0; // see how many players can vote
new nVotes = 0; // how many votes we have recieved
new nVotesNeeded = 0; // how many votes we need
new bool:bVoted[MAXPLAYERS+1] = {false, ...}; // check which players have voted
new bool:AllowedVote; // check if we can vote

new rocketSpeed = 0; // speed of the rocket
new String:botName[MAX_NAME_LENGTH]; // name of the bot

/* ===================================
*			Plugin Information
* ==================================== */
#define PLUGIN_VERSION	"1.4"

public Plugin:myinfo = {
	name		= "Nanobot (Dodgeball Bot)",
	author		= "Nanochip",
	description= "Play dodgeball against a bot!",
	version	= PLUGIN_VERSION,
	url			= "http://thecubeserver.org/"
};

/* ===================================
*			Start the Awesomeness
* ==================================== */
public OnPluginStart()
{
	// check if the server has updater
	if (LibraryExists("updater")) Updater_AddPlugin(UPDATE_URL);
	
	// generic translations
	LoadTranslations("common.phrases");
	
	// Create some server console variables for the plugin
	CreateConVar("sm_nanobot_version", PLUGIN_VERSION, "Nanobot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_nanobot_enable", "1", "Enable the plugin? 1 = Yes, 0 = No.", 0, true, 0.0, true, 1.0);
	cvarAirblastNear = CreateConVar("sm_nanobot_airblastnear", "1", "When players are near the bot, Should Nanobot airblast them away? 1 = Yes, 0 = No.", 0, true, 0.0, true, 1.0);
	cvarBotName = CreateConVar("sm_nanobot_name", "Nanobot", "What should the name of the bot be?", 0);
	cvarModel = CreateConVar("sm_nanobot_model", "models/bots/pyro/bot_pyro.mdl", "What model should the bot have? Default: Pyro Robot (models/bots/pyro/bot_pyro.mdl). Leave this CVAR blank if you do not want a custom model.", 0);
	cvarVoteMode = CreateConVar("sm_nanobot_vote_mode", "3", "Player vs Bot voting. 0 = No voting, 1 = Generic chat vote, 2 = Menu vote, 3 = Both (Generic chat first, then Menu vote).", 0, true, 0.0, true, 3.0);
	cvarVoteTime = CreateConVar("sm_nanobot_vote_time", "25.0", "Time in seconds the vote menu should last.", 0);
	cvarVoteTimeDelay = CreateConVar("sm_nanobot_vote_delay", "60.0", "Time in seconds before players can initiate another PvB vote.", 0);
	cvarVotePercentage = CreateConVar("sm_nanobot_vote_percentage", "0.60", "How many players are required for the vote to pass? 0.60 = 60%.", 0, true, 0.05, true, 1.0);
	cvarMinPlayers = CreateConVar("sm_nanobot_minplayers", "1", "When there are a minimum of X amount of players or less, enable Nanobot. 0 = No Enable, 1 = Enables at 1 player... 10 = Enables at 10 players.", 0);
	cvarMaxPlayers = CreateConVar("sm_nanobot_maxplayers", "2", "When there are a maximum of X amount of players or more, Nanobot will disable. 0 = No disable, 2 = Disables at 2 players... 10 = Disables at 10 players.", 0);
	cvarVictorySpeed = CreateConVar("sm_nanobot_victory_speed", "250", "When the rocket reaches greater than or equal to this speed, in MPH, Nanobot will not deflect the rocket and the other team wins. Put this value to 0 if you do not want Nanobot to lose (unbeatable...ish).", 0);
	cvarAutoReflect = CreateConVar("sm_nanobot_enable_autoreflect", "1", "When enabled, It will use autoreflect inside the plugin, If 0 it will detect /autoreflect as a unknown command for other plugins to be used.", 0);
	
	// add some commands for admins and users
	RegAdminCmd("sm_nanobot", Nanobot_Cmd, ADMFLAG_RCON, "Force enable/disable PvB.");
	RegAdminCmd("sm_pvb", Nanobot_Cmd, ADMFLAG_RCON, "Force enable/disable PvB.");
	RegAdminCmd("sm_autoreflect", AutoReflect_Cmd, ADMFLAG_CHEATS, "Assign auto reflect on a player.");
	RegConsoleCmd("sm_votepvb", VotePvB_Cmd, "Vote to enable/disable PvB");
	
	// create the nanobot config (tf/cfg/sourcemod/Nanobot.cfg)
	AutoExecConfig(true, "Nanobot");
	
	// hook some game events
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	
	// set the bot's name
	GetConVarString(cvarBotName, botName, sizeof(botName));
}

// add nanobot plugin to updater
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater")) Updater_AddPlugin(UPDATE_URL);
}

public Updater_OnPluginUpdated()
{
	PrintToServer("[Player VS Bot] Successfully updated. This is a sexy update, I swear!");
	ReloadPlugin();
}

/* ===================================
*				Commands
* ==================================== */
public Action:VotePvB_Cmd(client, args)
{
	if (!GetConVarBool(cvarEnable) || GetConVarInt(cvarVoteMode) == 0) return Plugin_Handled;
	//check which vote mode we can do
	if (GetConVarInt(cvarVoteMode) != 2) AttemptPvBVotes(client);
	else
	{
		PvBVoteMenu();
	}
	return Plugin_Handled;
}

// this adds the ability to use commands without ! or /
public OnClientSayCommand_Post(client, const String:command[], const String:sArgs[])
{
	if (!GetConVarBool(cvarEnable) || GetConVarInt(cvarVoteMode) == 0) return;
	if (strcmp(sArgs, "votepvb", false) == 0 || strcmp(sArgs, "vpvb", false) == 0)
	{
		new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		
		if (GetConVarInt(cvarVoteMode) != 2) AttemptPvBVotes(client);
		else
		{
			PvBVoteMenu();
		}
		
		SetCmdReplySource(old);
	}
}

// auto reflect :D
public Action:AutoReflect_Cmd(client, args)
{
	if (!GetConVarBool(cvarAutoReflect)) {
		return Plugin_Handled; }
		else
	if (args < 1)
	{		
		if (!allowed[client]) 
		{
			allowed[client] = true;
			ReplyToCommand(client, "\x01[\x03%s\x01]\x04 Enabled auto reflect on yourself.", botName);
		} else {
			allowed[client] = false;
			ReplyToCommand(client, "\x01[\x03%s\x01]\x04 Disabled auto reflect on yourself.", botName);
		}
		return Plugin_Handled;
	}
	
	new String:tempName[MAX_NAME_LENGTH], String:name[MAX_NAME_LENGTH];
	GetCmdArg(1, tempName, sizeof(tempName));
	
	new target = FindTarget(client, tempName, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	GetClientName(target, name, sizeof(name));
	
	if (!allowed[target])
	{
		allowed[target] = true;
		ReplyToCommand(client, "\x01[\x03%s\x01]\x04 Autoreflect enabled on %s.", botName, name);
	} else {
		ReplyToCommand(client, "\x01[\x03%s\x01]\x04 Autoreflect disabled on %s.", botName, name);
		allowed[target] = false;
	}
	return Plugin_Handled;
}

public Action:Nanobot_Cmd(client, args)
{
	if (!GetConVarBool(cvarEnable)) return Plugin_Handled;
	if (!NanobotEnabled) 
	{
		EnableNanobot();
		commandEnable = true;
		commandDisable = false;
	}
	else 
	{
		DisableNanobot();
		ServerCommand("mp_scrambleteams");
		commandDisable = true;
		commandEnable = false;
	}
	return Plugin_Handled;
}

EnableNanobot()
{
	ServerCommand("sv_cheats 1");
	ServerCommand("bot_kill all");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("bot -class pyro -team red");
	ServerCommand("tf_bot_keep_class_after_death 1");
	ServerCommand("tf_bot_taunt_victim_chance 0");
	ServerCommand("tf_bot_join_after_player 0");
	ServerCommand("mp_waitingforplayers_cancel 1");
	ServerCommand("sv_cheats 0");
	ServerCommand("sm_rb_max 10000");
	ServerCommand("cvar tf_flamethrower_burstammo 0");
	ServerCommand("sm_cvar tf_flamethrower_burstammo 0");
	PrintToChatAll("\x01[\x03%s\x01]\x04 Player VS Bot has been enabled!", botName);
	NanobotEnabled = true;
}

DisableNanobot()
{
	ServerCommand("sv_cheats 1");
	ServerCommand("bot_kick all");
	ServerCommand("sv_cheats 0");
	PrintToChatAll("\x01[\x03%s\x01]\x04 Player VS Bot has been disabled!", botName);
	NanobotEnabled = false;
}

/* ===================================
*				Events
* ==================================== */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnable)) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsClientBot(client))
	{
		if (BotBeaten)
		{
			PrintToChatAll("\x01[\x03%s\x01]\x04 %N has beaten %s by getting up to %d MPH!", botName, attacker, botName, rocketSpeed);
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnable)) return;
	if (BotBeaten) BotBeaten = false;
}
public OnMapEnd()
{
	if (!GetConVarBool(cvarEnable)) return;
	MapChanged = true;
}

public OnClientConnected(client)
{
	if (!GetConVarBool(cvarEnable)) return;
	if (IsFakeClient(client)) return;
	
	bVoted[client] = false;
	nVoters++;
	nVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercentage));
}

public OnClientDisconnect(client)
{
	if (!GetConVarBool(cvarEnable)) return;
	if (IsFakeClient(client)) return;
	if (allowed[client]) allowed[client] = false;
	
	if (bVoted[client]) nVotes--;
	nVoters--;
	nVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercentage));
}

AttemptPvBVotes(client)
{
	if (!GetConVarBool(cvarEnable)) return;
	
	if (!AllowedVote)
	{
		ReplyToCommand(client, "\x01[\x03%s\x01]\x04 Sorry! Player VS Bot is currently on cooldown, check back later.", botName);
		return;
	}
	
	if (bVoted[client])
	{
		ReplyToCommand(client, "\x01[\x03%s\x01]\x04 You have already voted. Sorry!", botName);
		return;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	nVotes++;
	bVoted[client] = true;
	if (!NanobotEnabled)
	{
		PrintToChatAll("\x01[\x03%s\x01]\x04 %s Wants to enable Player Vs Bot. (%d votes, %d required)", botName, name, nVotes, nVotesNeeded);
	} else {
		PrintToChatAll("\x01[\x03%s\x01]\x04 %s Wants to disable Player Vs Bot. (%d votes, %d required)", botName, name, nVotes, nVotesNeeded);
	}
	
	if (nVotes >= nVotesNeeded)
	{
		StartPvBVotes();
	}
}

StartPvBVotes()
{
	if (GetConVarInt(cvarVoteMode) == 1)
	{
		if (!NanobotEnabled)
		{
			PrintToChatAll("\x01[\x03%s\x01]\x04 Enabling Player vs Bot...", botName);
			EnableNanobot();
			commandEnable = true;
			commandDisable = false;
		} else {
			PrintToChatAll("\x01[\x03%s\x01]\x04 Disabling Player vs Bot...", botName);
			DisableNanobot();
			commandDisable = true;
			commandEnable = false;
			ServerCommand("mp_scrambleteams");
		}
	}
	if (GetConVarInt(cvarVoteMode) == 3)
	{
		PvBVoteMenu();
	}
	ResetPvBVotes();
	AllowedVote = false;
	CreateTimer(GetConVarFloat(cvarVoteTimeDelay), Timer_Delay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Delay(Handle:timer)
{
	AllowedVote = true;
}

PvBVoteMenu()
{
	if (IsVoteInProgress()) return;
	if (GetConVarInt(cvarVoteMode) == 2)
	{
		AllowedVote = false;
		CreateTimer(GetConVarFloat(cvarVoteTimeDelay), Timer_Delay, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	new Handle:vm = CreateMenu(PvBVoteMenuHandler, MenuAction:MENU_ACTIONS_ALL);
	SetVoteResultCallback(vm, Handle_VoteResults);
	if (!NanobotEnabled)
	{
		SetMenuTitle(vm, "Enable Player vs Bot?");
		AddMenuItem(vm, "yes", "Yes");
		AddMenuItem(vm, "no", "No");
	} else {
		SetMenuTitle(vm, "Disable Player vs Bot?");
		AddMenuItem(vm, "yes", "Yes");
		AddMenuItem(vm, "no", "No");
	}
	SetMenuExitButton(vm, false);
	VoteMenuToAll(vm, GetConVarInt(cvarVoteTime));
}

public Handle_VoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	new winner = 0;
	if (num_items > 1
	    && (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES]))
	{
		winner = GetRandomInt(0, 1);
	}
	
	new String:winInfo[32];
	GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], winInfo, sizeof(winInfo));
	
	if (!NanobotEnabled)
	{
		if (StrEqual(winInfo, "yes"))
		{
			PrintToChatAll("\x01[\x03%s\x01]\x04 Majority voted \"Yes\", enabling Player vs Bot...", botName);
			EnableNanobot();
			commandEnable = true;
			commandDisable = false;
		} else {
			PrintToChatAll("\x01[\x03%s\x01]\x04 Majority voted \"No\", aborted operation.", botName);
		}
	} else {
		if (StrEqual(winInfo, "yes"))
		{
			PrintToChatAll("\x01[\x03%s\x01]\x04 Majority voted \"Yes\", disabling Player vs Bot...", botName);
			DisableNanobot();
			commandDisable = true;
			commandEnable = false;
			ServerCommand("mp_scrambleteams");
		} else {
			PrintToChatAll("\x01[\x03%s\x01]\x04 Majority voted \"No\", aborted operation.", botName);
		}
	}
	
}

public PvBVoteMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
}

ResetPvBVotes()
{
	nVotes = 0;
	for (new i = 1; i <= MAXPLAYERS; i++) bVoted[i] = false;
}

public OnMapStart()
{
	if (!GetConVarBool(cvarEnable)) return;
	
	nVoters = 0;
	nVotesNeeded = 0;
	nVotes = 0;
	AllowedVote = true;
	commandEnable = false;
	commandDisable = false;
	
	decl String:mdl[PLATFORM_MAX_PATH];
	GetConVarString(cvarModel, mdl, sizeof(mdl));
	if (!StrEqual(mdl, ""))
	{
		PrecacheModel(mdl, true);
		AddFileToDownloadsTable(mdl);
	}
	
	CreateTimer(5.0, Timer_MapStart);
}

public Action:Timer_MapStart(Handle:timer)
{
	MapChanged = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!GetConVarBool(cvarEnable) || !IsPlayerAlive(client)) return Plugin_Continue;
	
	if ((NanobotEnabled && IsClientBot(client)) || allowed[client])
	{
		new rocket = INVALID_ENT_REFERENCE;
		new ent = INVALID_ENT_REFERENCE;

		decl Float:fClientEyePosition[3];
		GetClientEyePosition(client, fClientEyePosition);
		ModRateOfFire(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
		
		// Rocket handling.
		while ((rocket = FindEntityByClassname(rocket, "tf_projectile_rocket")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntProp(rocket, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
			{
				decl Float:entityLocation[3];
				GetEntPropVector(rocket, Prop_Data,"m_vecOrigin",entityLocation);
				
				// Handle victory speed cvar.
				if (GetConVarInt(cvarVictorySpeed) != 0)
				{
					decl Float:entityVelocity[3];
					GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", entityVelocity);
					new entityMPH = RoundFloat(GetVectorLength(entityVelocity) * (15.0/352.0));
					if (entityMPH >= GetConVarInt(cvarVictorySpeed) && !allowed[client])
					{
						BotBeaten = true;
						rocketSpeed = entityMPH;
						return Plugin_Continue;
					}
				}
				
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				decl Float:angle[3];
				angle[0] = 0.0 - RadToDeg(ArcTangent((entityLocation[2] - fClientEyePosition[2]) / (FloatAbs(SquareRoot(Pow(fClientEyePosition[0] - entityLocation[0], 2.0) + Pow(entityLocation[1] - fClientEyePosition[1], 2.0))))));
				angle[1] = GetAngle(fClientEyePosition, entityLocation);
				
				
				TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);
				
				if (GetVectorDistance(pos, entityLocation) < 190.0)
				{
					buttons |= IN_ATTACK2;
				}
			}
			
			// Airblast near players away from the bot.
			if (GetConVarBool(cvarAirblastNear) && !allowed[client])
			{
				for (new i = 1 ; i <= MaxClients ;i++)
				{
					if (IsClientInGame(i) && IsClientConnected(i) && !IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(client))
					{
						decl Float:fClientLocation[3];
						GetClientAbsOrigin(i, fClientLocation);
						
						fClientLocation[2] += 90;
						
						decl Float:fDistance[3];
						MakeVectorFromPoints(fClientLocation, fClientEyePosition, fDistance);
						
						decl Float:angle[3];
						GetVectorAngles(fDistance, angle);
						angle[0] *= -1.0;
						angle[1] += 180.0;
						
						if (GetVectorLength(fDistance) < 190.0)
						{
							TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);
							buttons |= IN_ATTACK2;
						}
					}
				}
			}
		}
		
		// Projectile Handling such as flares.
		while ((ent = FindEntityByClassname(ent, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
			{
			
				decl Float:fEntityLocation[3];
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntityLocation);

				decl Float:fVector[3];
				MakeVectorFromPoints(fEntityLocation, fClientEyePosition, fVector);

				decl Float:angle[3];
				GetVectorAngles(fVector, angle);
				angle[0] *= -1.0;
				angle[1] += 180.0;
				
				if(GetVectorLength(fVector) < 190.0)
				{
					TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);
					buttons |= IN_ATTACK2;
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnGameFrame()
{
	if (!GetConVarBool(cvarEnable)) return;
	ChangePlayerTeam();
	SetupNanobot();
	new onlineClients = GetRealClientCount(false);
	
	// If there is more than one bot on the server, kick them and disable Nanobot. (Rare)
	if (GetFakeClientCount(false) > 1) DisableNanobot();
	
	// If there are no players on the server and Nanobot is enabled, disable Nanobot.
	if (onlineClients == 0 && NanobotEnabled) 
	{
		DisableNanobot();
		if (commandEnable) commandEnable = false;
		if (commandDisable) commandDisable = false;
	}
	// If the map changed and nanobot is enabled, disable nanobot. Not even sure if this is needed, but I was encountering issues where there were 2 bots.
	if (MapChanged && NanobotEnabled) DisableNanobot();
	
	new min = GetConVarInt(cvarMinPlayers);
	new max = GetConVarInt(cvarMaxPlayers);
	if (min >= max)
	{
		PrintToServer("[Nanobot] ERROR! There's an issue with your min & max player cvars, make sure minplayers is less than maxplayers.");
		return;
	}
	// Handle min players cvar
	if (min != 0 && onlineClients != 0 && onlineClients <= min && !NanobotEnabled && !commandDisable && !MapChanged)
	{
		PrintToChatAll("\x01[\x03%s\x01]\x04 There is a minimum of %d players, enabling Player vs. Bot...", botName, onlineClients);
		EnableNanobot();
		commandEnable = false;
	}
	
	// Handle max players cvar
	if (max != 0 && onlineClients != 0 && onlineClients >= max && NanobotEnabled && !commandEnable && !MapChanged)
	{
		PrintToChatAll("\x01[\x03%s\x01]\x04 There is a maximum of %d players, disabling Player vs. Bot...", botName, onlineClients);
		DisableNanobot();
		commandDisable = false;
	}
}

/* ===================================
*				Stocks
* ==================================== */
stock SetupNanobot()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i))
		{
			// Change Nanobot's name.
			SetClientInfo(i, "name", botName);
			
			// Change Nanobot's player model.
			decl String:mdl[PLATFORM_MAX_PATH];
			GetConVarString(cvarModel, mdl, sizeof(mdl));
			if (!StrEqual(mdl, ""))
			{
				SetVariantString(mdl);
				AcceptEntityInput(i, "SetCustomModel");
				SetEntProp(i, Prop_Send, "m_bUseClassAnimations", 1);
			}
			
			// Change Nanobot's team
			if (GetClientTeam(i) != 3)
			{
				ChangeClientTeam(i, 3);
				TF2_RespawnPlayer(i);
			}
		}
	}
}

stock ChangePlayerTeam()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientObserver(i) && NanobotEnabled && GetClientTeam(i) != 2)
		{
			ChangeClientTeam(i, 2);
			TF2_RespawnPlayer(i);
		}
	}
}

stock bool:IsClientBot(client)
{
	return IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client);
}

stock Float:GetAngle(const Float:coords1[3], const Float:coords2[3])
{
	new Float:angle = RadToDeg(ArcTangent((coords2[1] - coords1[1]) / (coords2[0] - coords1[0])));
	if (coords2[0] < coords1[0])
	{
		if (angle > 0.0) angle -= 180.0;
		else angle += 180.0;
	}
	return angle;
}

stock GetRealClientCount( bool:inGameOnly = true ) 
{
	new clients = 0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (((inGameOnly) ? IsClientInGame(i) : IsClientConnected(i)) && !IsFakeClient(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) 
		{
			clients++;
		}
	}
	return clients;
}

stock GetFakeClientCount(bool:inGameOnly = true)
{
	new clients = 0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (((inGameOnly) ? IsClientInGame(i) : IsClientConnected(i)) && IsFakeClient(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) 
		{
			clients++;
		}
	}
	return clients;
}

stock ModRateOfFire(weapon)
{
	new Float:m_flNextPrimaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	new Float:m_flNextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 10.0);

	new Float:fGameTime = GetGameTime();
	new Float:fPrimaryTime = ((m_flNextPrimaryAttack - fGameTime) - 0.99);
	new Float:fSecondaryTime = ((m_flNextSecondaryAttack - fGameTime) - 0.99);

	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", fPrimaryTime + fGameTime);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}

public OnAllPluginsLoaded()
{
	ServerCommand("sm plugins refresh");
	ServerCommand("sm_plugins_refresh");
}