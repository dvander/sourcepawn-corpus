#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define NUPGRADES 32
#define NVALID 21

new bool:Hooked = false;
new Handle:RemoveUpgrade = INVALID_HANDLE;
new bool:bBlockUntilRoundStart;
new String:UpgradeShort[NVALID][256];
new String:UpgradeLong[NVALID][1056];
new bool:bBlockTankSpawn;
new Handle:AddUpgrade = INVALID_HANDLE;
new Handle:WitchKilled = INVALID_HANDLE;
new Handle:WitchKilledKiller = INVALID_HANDLE;
new Handle:TankKilled = INVALID_HANDLE;
new Handle:TankKilledKiller = INVALID_HANDLE;
new Handle:UpgradesAtSpawn = INVALID_HANDLE;
new Handle:TankSpawnUpgrades = INVALID_HANDLE;
new Handle:UpgradeAllowed[NVALID];
new Handle:ME2 = INVALID_HANDLE;
new bool:bClientHasUpgrade[MAXPLAYERS+1][NVALID];
new bool:bBotControlled[MAXPLAYERS+1];
new bool:bUpgraded[MAXPLAYERS+1];
new IndexToUpgrade[NVALID];
new Handle:AlwaysLaser = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	//Try the windows version first.
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\xA1****\x83***\x57\x8B\xF9\x0F*****\x8B***\x56\x51\xE8****\x8B\xF0\x83\xC4\x04", 34))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType", 0);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	AddUpgrade = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x51\x53\x55\x8B***\x8B\xD9\x56\x8B\xCD\x83\xE1\x1F\xBE\x01\x00\x00\x00\x57\xD3\xE6\x8B\xFD\xC1\xFF\x05\x89***", 32))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType", 0);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	RemoveUpgrade = EndPrepSDKCall();

	//StartPrepSDKCall(SDKCall_Player);
	//if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x83\xEC\x18\xA1****\x56\x33\xF6\x39\x70\x30\x89***\x0F*****\x53\x55\x57\x33\xED\x33\xDB\x33\xFF", 33))
	//{
	//	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer17GiveRandomUpgradeEv", 0);	
	//}
	//GiveRandomUpgrade = EndPrepSDKCall();
	IndexToUpgrade[0] = 1;
	UpgradeShort[0] = "\x03 You have the revive_2X upgrade!";
	UpgradeLong[0] = "you can revive people 2X as faster than usuall";
	UpgradeAllowed[0] = CreateConVar("revive_2X", "1", "if it enabled the upgrade or not", FCVAR_PLUGIN);

	IndexToUpgrade[1] = 8;
	UpgradeShort[1] = "\x03 you have the reload_2X_faster upgrade!";
	UpgradeLong[1] = "this allows you to reload 2X as faster than usuall";
	UpgradeAllowed[1] = CreateConVar("reload_2X", "1", "enables this upgrade", FCVAR_PLUGIN);
	
	IndexToUpgrade[2] = 11;
	UpgradeShort[2] = "\x03 you have the run_2X_faster upgrade!";
	UpgradeLong[2] = "you can run 2X as faster as usuall";
	UpgradeAllowed[2] = CreateConVar("run_2x_faster", "1", "toggle the upgrade", FCVAR_PLUGIN);
	
	IndexToUpgrade[3] = 12;
	UpgradeLong[3] = "you can reload your gun way faster";
	UpgradeShort[3] = "\x03 you have reload_faster upgrade";
	UpgradeAllowed[3] = CreateConVar("reload_3X_faster", "1", "enables the upgrade", FCVAR_PLUGIN);
	
	IndexToUpgrade[4] = 13;
	UpgradeShort[4] = "\x03 you have sprint upgrade";
	UpgradeLong[4] = "makes sprint on the ground";
	UpgradeAllowed[4] = CreateConVar("sprint", "1", "enable sprint", FCVAR_PLUGIN);
	
	IndexToUpgrade[5] = 17;
	UpgradeShort[5] = "\x04 this upgrade makes it so you can see through boomer vomit";
	UpgradeLong[5] = "the rain coat upgrade makes it so you can see trhough boomer vomit";
	UpgradeAllowed[5] = CreateConVar("rain_coat", "1", "enables raincoat", FCVAR_PLUGIN);

	IndexToUpgrade[6] = 19;
	UpgradeShort[6] = "this will make your gun shoot 2X faster as usuall";
	UpgradeLong[6] = "this makes your gun shoot 2X as faster";
	UpgradeAllowed[6] = CreateConVar("\x03 doublebuble", "1", "enables double_tap", FCVAR_PLUGIN);

	IndexToUpgrade[7] = 20;
	UpgradeShort[7] = "\x03 this will mae it so you can climb up ledges!";
	UpgradeLong[7] = "makes you so you can climb up edges";
	UpgradeAllowed[7] = CreateConVar("UPGRADE_climb_chalk", "1", "the upgrade for climb chalk", FCVAR_PLUGIN);

	IndexToUpgrade[8] = 23;
	UpgradeShort[8] = "\x03 you have the wind upgrade that makes you self revive";
	UpgradeLong[8] = "you have the wind upgrade";
	UpgradeAllowed[8] = CreateConVar("UPGRADE_wind", "1", "enables the wind upgrade", FCVAR_PLUGIN);

	IndexToUpgrade[9] = 25;
	UpgradeShort[9] = "\x03 you have the knife upgrade";
	UpgradeLong[9] = "the knife can be used to escape from special infected pulls";
	UpgradeAllowed[9] = CreateConVar("UPGRADE_knife", "1", "enables the knife", FCVAR_PLUGIN);

	//convars (alot)
	CreateConVar("UPGRADE_version", PLUGIN_VERSION, "The version of Survivor Upgrades plugin.", FCVAR_PLUGIN);
	AlwaysLaser = CreateConVar("sm_always_laser", "1", "toggles the laser is always on!", FCVAR_PLUGIN);
	UpgradesAtSpawn = CreateConVar("upgrades_at_spawn", "3", "how many upgrades there is at spawn", FCVAR_PLUGIN);
	TankKilled = CreateConVar("tank_killed_all_upgrades", "1", "number of upgrades when a tank is dead by the whole team", FCVAR_PLUGIN);
	TankKilledKiller = CreateConVar("tank_killed_killer_upgrades", "2", "number of upgrades for the killer of the tank", FCVAR_PLUGIN);
	TankSpawnUpgrades = CreateConVar("tank_spawn_upgrades", "1", "number of upgrades when a tank is spawned", FCVAR_PLUGIN);
	WitchKilled = CreateConVar("witch_killed_all_upgrades", "1", "number of upgrades when a witch is killed by the whole team", FCVAR_PLUGIN);
	WitchKilledKiller = CreateConVar("witch_killed_killer_upgrades", "2", "number of upgrades for the witch killer", FCVAR_PLUGIN);
	ME2 = CreateConVar("Me2_messages", "2", "the maxiam of messages that describes the upgrade", FCVAR_PLUGIN);

	//console cmds
	RegAdminCmd("adduprade", addUpgrade1, ADMFLAG_ROOT);
	RegAdminCmd("removeupgrade", removeupgrade1, ADMFLAG_ROOT);
	RegAdminCmd("randomupgrade", randomupgrade1, ADMFLAG_ROOT);

	AutoExecConfig(true, "l4d2_survivor_upgrades");

	//consolecmds
}

public Plugin:myinfo =
{
	name = "random upgrades",
	author = "gamemann",
	description = "makes a upgrade where you can revive 2X faster",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public Action:SayTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:message[1024];
	BfReadByte(bf);
	BfReadByte(bf);
	BfReadString(bf, message, 1024);

	if(StrContains(message, "prevent_it_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 1);
		return Plugin_Handled;
	}			
	if(StrContains(message, "ledge_save_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 2);
		return Plugin_Handled;
	}
	if(StrContains(message, "revive_self_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 3);
		return Plugin_Handled;
	}
	if(StrContains(message, "knife_expire")!=-1)
	{
		CreateTimer(0.1, DelayPrintExpire, 4);
		return Plugin_Handled;
	}
	
	if(StrContains(message, "laser_sight_expire")!= -1)
	{
		return Plugin_Handled;
	}

	if(StrContains(message, "_expire")!= -1)
	{
		return Plugin_Handled;
	}

	if(StrContains(message, "#L4D_Upgrade_")!=-1)
	{
		if(StrContains(message, "description")!=-1)
		{
			return Plugin_Handled;
		}
	}
	
	if(StrContains(message, "NOTIFY_VOMIT_ON") != -1)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:DelayPrintExpire(Handle:hTimer, any:text)
{
	if(GetConVarInt(ME2) > 0)
	{
		if(text == 1)
		{
			PrintToChatAll("\x01Boomer vomit was stopped by a (now ruined) \x05Raincoat\x01!");
		}
		if(text == 2)
		{
			PrintToChatAll("\x05Climbing Chalk\x01 was used to climb back up from a ledge!");
		}
		if(text == 3)
		{
			PrintToChatAll("\x01A survivor got their \x05Second Wind\x01 and stood back up!");
		}
		if(text == 4)
		{
			PrintToChatAll("\x01A \x05Knife\x01 was used to escape!");
		}
	}
}


public ActiveHooks()
{
	if(!Hooked)
	{
	Hooked = true;
	HookEvent("tank_spawn", Event_Tank_Spawned);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("witch_killed", Event_Witch_Killed);
	HookEvent("tank_killed", Event_Tank_Killed);
	HookEvent("round_end", Event_Round_End);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("bot_player_replace", Event_Bot_Player_Replace);
	HookEvent("player_entered_start_area", Event_PlayerEnteredStartArea);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	}
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	bBlockUntilRoundStart = false;
	for(new i=1;i< GetMaxClients(); ++i)
	{
		CreateTimer(1.0, GiveInitialUpgrades, i);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Bot replaced a player.
	new playerClient = GetClientOfUserId(GetEventInt(event, "player"));
	new botClient = GetClientOfUserId(GetEventInt(event, "bot"));
	bUpgraded[botClient] = bUpgraded[playerClient];
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[botClient][i] = bClientHasUpgrade[playerClient][i];
	}
	bBotControlled[botClient] = true;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	if(attacker == 0)
	{
		return Plugin_Continue
	}
	new client = GetClientOfUserId(attacker);
	if (!bClientHasUpgrade[client][10])
	{
		return Plugin_Continue;
	}
	if (GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}
	new infected = GetEventInt(event, "userid");
	new infectedClient = GetClientOfUserId(infected);
	if (GetClientTeam(infectedClient) != 3)
	{
		return Plugin_Continue;
	}
	new damagetype = GetEventInt(event, "type");
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infectedClient, 360.0, false);
	}
	return Plugin_Continue;
}

public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	new client = GetClientOfUserId(attacker);
	if (!bClientHasUpgrade[client][10])
	{
		return Plugin_Continue;
	}
	if(GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}
	new infected = GetEventInt(event, "entityid");
	new damagetype = GetEventInt(event, "type");
	if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
	{
		IgniteEntity(infected, 360.0, false);
	}
	return Plugin_Continue;
}

public ResetValues()
{
	bBlockTankSpawn = false;
	for(new i=1; i < GetMaxClients(); ++i)
	{
		bUpgraded[i] = false;
		bBotControlled[i] = false;
		for(new j = 0; j < NVALID; ++j)
		{
			bClientHasUpgrade[i][j] = false;
		}
	}
}	

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	bBlockUntilRoundStart = true;
	return Plugin_Handled;
}


public Action:Event_Tank_Spawned(Handle:event, const String:name[], bool:dontBroadcast)
{	if(bBlockTankSpawn)
	{
		return Plugin_Handled;
	}
	else
	{
		CreateTimer(10.0, UnblockTankSpawn);
		bBlockTankSpawn = true;
	}
	new NumUpgrades = GetConVarInt(TankSpawnUpgrades);
	if(NumUpgrades > 0)
	{
		if(GetConVarInt(ME2)>2)
		{
			PrintToChatAll("a tank has been spawned! you are 	getting upgrades!");
			for(new i=1;i<GetMaxClients();i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				GiveClientUpgrades(i, NumUpgrades);
			}
		}
	}
	return Plugin_Continue;
}

public Action:UnblockTankSpawn(Handle:hTimer)
{
	bBlockTankSpawn = false;
}

public Action:Event_Tank_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new NumUpgradesAll = GetConVarInt(TankKilled);
	new NumUpgradesKiller = GetConVarInt(TankKilledKiller);
	new KillerUserId = GetEventInt(event, "attacker");
	new KillerClient = GetClientOfUserId(KillerUserId);

	if (NumUpgradesAll > 0 || (NumUpgradesKiller > 0 && KillerClient != 0))
	{
		if(GetConVarInt(ME2)>1)
		{
			PrintToChatAll("the tank is dead now! All survivors will get upgrades..!");
		}
		if(NumUpgradesKiller > 0)
		{
			if(KillerClient !=0)
			{
				if(GetConVarInt(ME2)>2)
				{
					PrintToChatAll("The primary killer gets:");
				}
				else if (GetConVarInt(ME2)>1)
				{
					PrintToChat(KillerClient, "As a primary attacker: you also get extra upgrades or lower upgrades:");
				}
				GiveClientUpgrades(KillerClient, NumUpgradesKiller);
			}
			else
			{
				if(GetConVarInt(ME2)>1)
				{
					PrintToChatAll("there was no primary attacker so: nobody gets extra upgrades");
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:GiveClientUpgrades(client, numUpgrades)
{
	decl String:name[64];
	GetClientName(client, name, 64);
	for(new num=0; num<numUpgrades; ++num)
	{
		new numOwned = GetNumUpgrades(client);
		if(numOwned == NVALID)
		{
			if(GetConVarInt(ME2)>1)
			{
				PrintToChatAll("\x04%s\x01 would have gotten an upgrade but already has them all.", name);
			}
			return;
		}
	}
}

public Action:Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new NumUpgradesAll = GetConVarInt(WitchKilled);
	new NumUpgradesKiller = GetConVarInt(WitchKilledKiller);
	new KillerUserId = GetEventInt(event, "attacker");
	new KillerClient = GetClientOfUserId(KillerUserId);
	
	if (NumUpgradesAll > 0 || (NumUpgradesKiller > 0 && KillerClient != 0))
	{
		if(GetConVarInt(ME2)> 1)
		{
			PrintToChatAll("the witch is dead! All Players get upgrades!");
		}
		if(NumUpgradesAll > 0)
		{
			for(new i=1;i<GetMaxClients();i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				GiveClientUpgrades(i, NumUpgradesAll);
			}
		}
		if(NumUpgradesKiller > 0)
		{
			if(KillerClient != 0)
			{
				if(GetConVarInt(ME2)>2)
				{
					PrintToChatAll("the primary attacker also gets:");
				}
				else if (GetConVarInt(ME2)>1)
				{
					PrintToChat(KillerClient, "as a primary witch killer you also get extra upgrades:");
				}
				if(GetConVarInt(ME2)>1)
				{
					PrintToChatAll("there is no primary attacker so: nobody gets extra upgrades!");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "team")==2)
	{
		CreateTimer(5.0, GiveInitialUpgrades, playerClient);
	}
	if(GetEventInt(event, "oldteam")==2)
	{
		CreateTimer(4.0, ClearOldUpgradeInfo, playerClient);
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	CreateTimer(5.0, GiveInitialUpgrades, client);
}

public Action:ClearOldUpgradeInfo(Handle:hTimer, any:playerClient)
{
	// This is an attempt to prevent bots from getting extra upgrades... :)
	if(bBotControlled[playerClient])
	{
		return;
	}
	bUpgraded[playerClient] = false;
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[playerClient][i] = false;
	}
}

public Action:Event_Bot_Replaced(Handle:event, const String:name[], bool:dontBroadcast)
{
	new PlayerClient = GetClientOfUserId(GetEventInt(event, "player"));
	new BotClient = GetClientOfUserId(GetEventInt(event, "bot"));	
	bUpgraded[BotClient] = bUpgraded[PlayerClient];
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[BotClient][i] = bClientHasUpgrade[PlayerClient][i];
	}
	bBotControlled[BotClient] = true;
}

public Action:Event_Bot_Player_Replace(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Player replaced a bot.
	new playerClient = GetClientOfUserId(GetEventInt(event, "player"));
	new botClient = GetClientOfUserId(GetEventInt(event, "bot"));
	bUpgraded[playerClient] = bUpgraded[botClient];
	for(new i = 0; i < NVALID; ++i)
	{
		bClientHasUpgrade[playerClient][i] = bClientHasUpgrade[botClient][i];
	}
	ListMyTeamUpgrades(playerClient, true);
	bBotControlled[botClient] = false;
}


public ListMyTeamUpgrades(client, bool:brief)
{
	if(GetConVarInt(ME2)>2)
	{
		for(new i=1;i<GetMaxClients();i++)
		{
			if(client == i) continue;
			if(!IsClientInGame(i)) continue;
			if(GetClientTeam(i) != 2) continue;
			
			decl String:name[64];
			GetClientName(i, name, 64);
			for(new upgrade=0; upgrade < NVALID; ++upgrade)
			{
				if(bClientHasUpgrade[client][upgrade])
				{
					PrintToChat(client, "hahahaahah", name);
				}
			}
		}
	}
	ListMyUpgrades(client, brief);
}

public ListMyUpgrades(client, bool:brief)
{
	if(GetConVarInt(ME2)>1)
	{
		decl String:name[64];
		GetClientName(client, name, 64);
		for(new upgrade=0; upgrade < NVALID; ++upgrade)
		{
			if(bClientHasUpgrade[client][upgrade])
			{
				PrintToChat(client, "\x04%s\x01 got an upgrade.", name);
				if(GetConVarInt(ME2)>2 || !brief)
				{
					PrintToChat(client, "none", name);
				}
			}
		}
	}
}

public Action:Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(5.0, GiveInitialUpgrades, playerClient);
}

public OnConfigsExecuted()
{
	new Handle:SU_CVAR = FindConVar("survivor_upgrades");
	SetConVarInt(SU_CVAR, 1);
		
	SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
	
	SetConVarInt(FindConVar("sv_vote_issue_change_difficulty_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_change_map_now_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_change_mission_allowed"), 1, true, false);
	SetConVarInt(FindConVar("sv_vote_issue_restart_game_allowed"), 1, true, false);
}

public Action:GiveInitialUpgrades(Handle:hTimer, any:client)
{
	if(bBlockUntilRoundStart) return;
	if(!IsClientInGame(client)) return;
	if(GetClientTeam(client) != 2) return;
	if(bUpgraded[client]) return;
	bUpgraded[client] = true;
	for(new i=0; i<NVALID; ++i)
	{
		if(GetConVarInt(UpgradeAllowed[i])==2)
		{
			GiveClientSpecificUpgrade(client, i);
		}
	}
	if (GetConVarInt(AlwaysLaser)!=0 && !bClientHasUpgrade[client][6])
	{
		GiveClientSpecificUpgrade(client, 6);
	}
	new numStarting = GetConVarInt(UpgradesAtSpawn)
	if(numStarting > 0)
	{
		GiveClientUpgrades(client, numStarting);
	}
}

public GiveClientSpecificUpgrade(any:client, upgrade)
{
	decl String:name[64];
	GetClientName(client, name, 64);
	new ME2Val = GetConVarInt(ME2);
	if(ME2Val > 2)
	{
		PrintToChatAll("\x04%s\x01 got %s\x01.", name);
		PrintToChat(client, "%s");
	}
	else if (ME2Val > 1)
	{
		PrintToChat(client, "\x04%s\x01 got %s\x01.", name);
	}
	SDKCall(AddUpgrade, client, IndexToUpgrade[upgrade]);
	// We're just doing this for the sound effect, remove it immediately...
	bClientHasUpgrade[client][upgrade]=true;
}

public TakeClientSpecificUpgrade(any:client, upgrade)
{
	SDKCall(RemoveUpgrade, client, IndexToUpgrade[upgrade]);
	bClientHasUpgrade[client][upgrade] = false;
}

public GetNumUpgrades(client)
{
	new num = 0;
	for(new i = 0; i < NVALID; ++i)
	{
		if(bClientHasUpgrade[client][i] || GetConVarInt(UpgradeAllowed[i])!=1)
		{
			++num;
		}
	}
	return num;
}

public Action:removeupgrade1(client, args)
{
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: removeUpgrade [upgrade id] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS]
	new targetCount = 1;
	targetList[0] = client;
	if(GetCmdArgs() > 1)
	{
		targetCount = 0;
		for(new i = 2; i<=GetCmdArgs(); ++i)
		{
			decl String:arg[65];
			GetCmdArg(i, arg, sizeof(arg));
			
			decl String:subTargetName[MAX_TARGET_LENGTH];
			decl subTargetList[MAXPLAYERS], subTargetCount, bool:tn_is_ml;
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE,
				subTargetName, sizeof(subTargetName), tn_is_ml);
			
			for(new j = 0; j < subTargetCount; ++j)
			{
				new bool:bAdd = true;
				for(new k = 0; k < targetCount; ++k)
				{
					if(targetList[k] == subTargetList[j])
					{
						bAdd = false;
					}
				}
				if(bAdd)
				{
					targetList[targetCount] = subTargetList[j];
					++targetCount;
				}
			}
		}
	}
	if(targetCount == 0)
	{
		ReplyToCommand(client, "No players found that matched the targets you specified.");
		return Plugin_Handled;
	}
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	new upgrade = StringToInt(arg)-1;
	if(upgrade<0 || upgrade >= NVALID)
	{
		ReplyToCommand(client, "Invalid upgrade index.  Valid values are 1 to %d.", NVALID);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < targetCount; ++i)
	{
		TakeClientSpecificUpgrade(targetList[i], upgrade);
	}
	return Plugin_Handled;
}

public Action:randomupgrade1(client, args)
{
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: giveRandomUpgrades [number of Upgrades] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS]
	new targetCount = 1;
	targetList[0] = client;
	if(GetCmdArgs() > 1)
	{
		targetCount = 0;
		for(new i = 2; i<=GetCmdArgs(); ++i)
		{
			decl String:arg[65];
			GetCmdArg(i, arg, sizeof(arg));
			
			decl String:subTargetName[MAX_TARGET_LENGTH];
			decl subTargetList[MAXPLAYERS], subTargetCount, bool:tn_is_ml;
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE,
				subTargetName, sizeof(subTargetName), tn_is_ml);
			
			for(new j = 0; j < subTargetCount; ++j)
			{
				new bool:bAdd = true;
				for(new k = 0; k < targetCount; ++k)
				{
					if(targetList[k] == subTargetList[j])
					{
						bAdd = false;
					}
				}
				if(bAdd)
				{
					targetList[targetCount] = subTargetList[j];
					++targetCount;
				}
			}
		}
	}
	if(targetCount == 0)
	{
		ReplyToCommand(client, "No players found that matched the targets you specified.");
		return Plugin_Handled;
	}
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	new upgrade = StringToInt(arg);
	
	for(new i = 0; i < targetCount; ++i)
	{
		GiveClientUpgrades(targetList[i], upgrade);
	}
	return Plugin_Handled;		
}

public Action:addUpgrade1(client, args)
{
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: addUpgrade [upgrade id] <user id | name> <user id | name> ...");
		return Plugin_Handled;
	}
	decl targetList[MAXPLAYERS]
	new targetCount = 1;
	targetList[0] = client;
	if(GetCmdArgs() > 1)
	{
		targetCount = 0;
		for(new i = 2; i<=GetCmdArgs(); ++i)
		{
			decl String:arg[65];
			GetCmdArg(i, arg, sizeof(arg));
			
			decl String:subTargetName[MAX_TARGET_LENGTH];
			decl subTargetList[MAXPLAYERS], subTargetCount, bool:tn_is_ml;
			
			subTargetCount = ProcessTargetString(arg, client, subTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE,
				subTargetName, sizeof(subTargetName), tn_is_ml);

			for(new j = 0; j < subTargetCount; ++j)
			{
				new bool:bAdd = true;
				for(new k = 0; k < targetCount; ++k)
				{
					if(targetList[k] == subTargetList[j])
					{
						bAdd = false;
					}
				}
				if(bAdd)
				{
					targetList[targetCount] = subTargetList[j];
					++targetCount;
				}
			}
		}
	}
	if(targetCount == 0)
	{
		ReplyToCommand(client, "No players found that matched the targets you specified.");
		return Plugin_Handled;
	}
	
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	new upgrade = StringToInt(arg)-1;
	if(upgrade<0 || upgrade >= NVALID)
	{
		ReplyToCommand(client, "Invalid upgrade index.  Valid values are 1 to %d.", NVALID);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < targetCount; ++i)
	{
		GiveClientSpecificUpgrade(targetList[i], upgrade);
	}
	return Plugin_Handled;		
}




			
		







	
	
	
