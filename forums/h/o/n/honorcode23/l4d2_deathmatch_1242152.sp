//Include needed code from sourcemod xd
#include <sourcemod>
#include <sdktools>
#define GETVERSION "1.0"
#define EXP_SOUND "ambient/explosions/explode_1.wav"
#define EXP_SOUND2 "ambient/explosions/explode_2.wav"

//Integers, strings or floats that will be needed in the future
new team[MAXPLAYERS+1] = 0;
new score[MAXPLAYERS+1] = 0;
new deaths[MAXPLAYERS+1] = 0;
new kills[MAXPLAYERS+1] = 0;
new allowmusic[MAXPLAYERS+1] = 1;
new killcount[MAXPLAYERS+1] = 0;
new enablereward[MAXPLAYERS+1] = 0;
new zombieclass[MAXPLAYERS+1] = 0;
new deathmatch = 0;
new numprint = 70;

new Handle:hDifficulty = INVALID_HANDLE;
new Handle:hIncapCount = INVALID_HANDLE;
new Handle:hGlowSurvivor = INVALID_HANDLE;
new Handle:hAllBot = INVALID_HANDLE;

new Handle:g_Score = INVALID_HANDLE;
new Handle:g_Reward = INVALID_HANDLE;

new Handle:begindmtimer = INVALID_HANDLE;
new Handle:enddmtimer = INVALID_HANDLE;

new Handle:CvarWaitTimer = INVALID_HANDLE;
new Handle:CvarDMDuration = INVALID_HANDLE;
new Handle:CvarRespawnTimer = INVALID_HANDLE;
new Handle:CvarSpawnInfected = INVALID_HANDLE;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hBecomeGhost = INVALID_HANDLE;
static Handle:hState_Transition = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;




public Plugin:myinfo = 
{
	name = "[L4D2]Deathmatch",
	author = "honorcode23",
	description = "Creates a deathmatch game",
	version = GETVERSION,
	url = "private"
}

public OnPluginStart()
{
	
	hGameConf = LoadGameConfigFile("l4drespawn");
	
	RegAdminCmd("sm_deathmatch", CmdDeathMatch, ADMFLAG_SLAY, "Creates a deathmatch game");
	RegAdminCmd("sm_deathmatch0", CmdDeathMatch0, ADMFLAG_SLAY, "Stops a deathmatch game");
	RegAdminCmd("sm_testpos", CmdTestPosition, ADMFLAG_SLAY, "Tests all available spots on this map");
	RegAdminCmd("sm_entityinfo", CmdEntityInfo, ADMFLAG_SLAY, "Returns the aiming entity classname");
	RegAdminCmd("sm_testscore", CmdTestScores, ADMFLAG_SLAY, "Tests the score menu");
	RegAdminCmd("sm_randommap", CmdRandomMap, ADMFLAG_SLAY, "Tests the random map function");
	RegAdminCmd("sm_rewardon", CmdRewardOn, ADMFLAG_SLAY, "Forces a reward");
	RegAdminCmd("sm_putbomb", CmdPutBombs, ADMFLAG_SLAY, "Deploys the bomb");
	
	RegConsoleCmd("sm_scores", CmdScores, "Prints the current score to players");
	RegConsoleCmd("sm_reward", CmdReward, "Prints the ability menu to a player, only if they are enabled");
	RegConsoleCmd("sm_nomusic", CmdNoMusic, "No music for me please!");
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("dead_survivor_visible", SeesDeathPlayer);
	HookEvent("player_hurt", OnPlayerHurt);
	
	hDifficulty = FindConVar("z_difficulty");
	hIncapCount = FindConVar("survivor_max_incapacitated_count");
	hGlowSurvivor = FindConVar("sv_disable_glow_survivors");
	hAllBot = FindConVar("sb_all_bot_team");
	
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhost = EndPrepSDKCall();
		if (hBecomeGhost == INVALID_HANDLE) LogError("L4D_SM_Respawn: BecomeGhost Signature broken");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hState_Transition = EndPrepSDKCall();
		if (hState_Transition == INVALID_HANDLE) LogError("L4D_SM_Respawn: State_Transition Signature broken");
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}
}

public Action:CmdTestScores(client, args)
{
	g_Score = BuildScoreMenu();
	DisplayMenu(g_Score, client, MENU_TIME_FOREVER);
}
public Action:CmdRewardOn(client, args)
{
	enablereward[client] = 1;
	killcount[client] = 0;
	PrintToChat(client, "\x04 4 Asesinatos seguidos!, escribe !reward para usar tu recompenza!");
	PrintHintText(client, "4 Asesinatos seguidos!, escribe !reward para usar tu recompenza!");
}

public Action:CmdNoMusic(client, args)
{
	PrintHintText(client, "Vuelve a utilizar este comando para activarlo o desactivarlo!");
	if(allowmusic[client] == 1)
	{
		allowmusic[client] = 0;
		PrintToChat(client, "La musica de fondo esta ahora \x03 Activada");
	}
	else if(allowmusic[client] == 0)
	{
		allowmusic[client] = 1;
		PrintToChat(client, "La musica de fondo esta ahora \x03 Desactivada");
	}
}

public Action:CmdPutBombs(client, args)
{
	PutBombs(client);
}

public Action:CmdScores(client, args)
{
	g_Score = BuildScoreMenu();
	DisplayMenu(g_Score, client, MENU_TIME_FOREVER);
	PrintToChat(client, "\x04Asesinatos: %i ##, Muertes: %i ## Puntaje: %i", kills[client], deaths[client], score[client]);
}
public Action:CmdEntityInfo(client, args)
{
	decl String:Classname[128];
	new entity = GetClientAimTarget(client, false);

	if ((entity == -1) || (!IsValidEntity (entity)))
	{
		ReplyToCommand (client, "Invalid entity, or looking to nothing");
	}
	GetEdictClassname(entity, Classname, sizeof(Classname));
	PrintToChat(client, "Classname: %s", Classname);
}

public Action:CmdRandomMap(client, args)
{
	decl String:mapname[256];
	GetRandomValidMap(mapname, sizeof(mapname));
	PrintToChat(client, "NEXT MAP: %s", mapname);
}

public Action:CmdTestPosition(client, args)
{
	decl Float:pos[3];
	pos = GetRandomRespawnPos()
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public OnMapStart()
{
	PrecacheSound(EXP_SOUND);
	PrecacheSound(EXP_SOUND2);
	hDifficulty = FindConVar("z_difficulty");
	g_Score = BuildScoreMenu();	
	for(new i=1; i<=MaxClients; i++)
	{
		kills[i] = 0;
		score[i] = 0;
		deaths[i] = 0;
	}
	deathmatch = 0;
	CreateTimer(1.0, CheckDM, _, TIMER_REPEAT);
	CreateTimer(15.0, WipeEnt);
	numprint = 70;
	begindmtimer = CreateTimer(1.0, BeginDM, _, TIMER_REPEAT);
}

public Action:WipeEnt(Handle:timer)
{
	CheatCommand(_, "ent_remove_all", "trigger_finale");
	CheatCommand(_, "ent_remove_all", "func_button");
	CheatCommand(_, "ent_fire", "checkpoint_entrance close");
	CheatCommand(_, "ent_fire", "checkpoint_entrance disable");
	CheatCommand(_, "ent_fire", "checkpoint_exit lock");
}
public OnMapEnd()
{
	if (g_Score != INVALID_HANDLE)
	{
		CloseHandle(g_Score);
		g_Score = INVALID_HANDLE;
	}
	
	for(new i=1; i<=MaxClients; i++)
	{
		kills[i] = 0;
		score[i] = 0;
		deaths[i] = 0;
	}
	if(begindmtimer != INVALID_HANDLE)
	{
		KillTimer(begindmtimer);
		begindmtimer = INVALID_HANDLE;
	}
	if(enddmtimer != INVALID_HANDLE)
	{
		KillTimer(enddmtimer);
		enddmtimer = INVALID_HANDLE;
	}
}

public Action:CmdReward(client, args)
{
	g_Reward = BuildRewardMenu();
	DisplayMenu(g_Reward, client, MENU_TIME_FOREVER);
}

BuildRewardMenu()
{
	new Handle:menu = CreateMenu(Menu_Reward);
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "spawntank", "Tank de la victoria");
	AddMenuItem(menu, "spawnhorde", "Caos infeccioso");
	AddMenuItem(menu, "airbombs", "Bombardeo!");
	SetMenuTitle(menu, "Selecciona una recompenza");
	return menu;
}

public Menu_Scores(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		return;
	}
}

BuildScoreMenu()
{
	new Handle:menu = CreateMenu(Menu_Scores);
	decl String:player[256];
	decl String:info[256];
	
	for(new i=1; i<=MaxClients; i++)
	{
		
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			team[i] = GetClientTeam(i);
			if(team[i] == 2 && !IsFakeClient(i))
			{
				GetClientName(i, player, sizeof(player));
				Format(info, sizeof(info), "%i -- %s", score[i], player);
				AddMenuItem(menu, "new player", info);
			}
		}
	}
	SetMenuTitle(menu, "Puntajes");
	return menu;
}

public Menu_Reward(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			SpawnFriendlyTank(param1);
			case 1:
			SpawnHorde(param1);
			case 2:
			PutBombs(param1);
		}
	}
}

public Action:SpawnFriendlyTank(client)
{
	CheatCommand(client, "z_spawn", "tank auto");
}

public Action:SpawnHorde(client)
{
	if(enablereward[client] == 0)
	{
		PrintToChat(client, "No tienes ninguna recompenza!");
		return;
	}
	CheatCommand(client, "director_start", "director_start");
	CheatCommand(client, "z_spawn", "mob");
	CreateTimer(3.0, DisableDir, client);
	enablereward[client] = 0;
}

public Action:DisableDir(Handle:timer, any:client)
{
	CheatCommand(client, "director_stop", "director_stop");
}

public Action:PutBombs(client)
{
	if(enablereward[client] == 0)
	{
		PrintToChat(client, "No tienes ninguna recompenza!");
		return;
	}
	decl Float:flPos[3];
	GetClientAbsOrigin(client, flPos);
	PrintToChat(client, "La bomba explotara en 5 segundos, alejate!");
	new ex_entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(ex_entity, "effect_name", "FluidExplosion_fps");
	DispatchSpawn(ex_entity);
	TeleportEntity(ex_entity, flPos, NULL_VECTOR, NULL_VECTOR);
	
	new ht_entity = CreateEntityByName("point_hurt");
	DispatchKeyValue(ht_entity, "Damage", "30");
	DispatchKeyValue(ht_entity, "DamageRadius", "695");
	DispatchKeyValue(ht_entity, "DamageType", "8");
	DispatchSpawn(ht_entity);
	TeleportEntity(ht_entity, flPos, NULL_VECTOR, NULL_VECTOR);
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, ex_entity);
	WritePackCell(pack, ht_entity);
	CreateTimer(5.0, ShowExplosion, pack);
}

public Action:ShowExplosion(Handle:timer, Handle:pack)
{
	ResetPack(pack)
	new ex_entity = ReadPackCell(pack);
	new ht_entity = ReadPackCell(pack);
	CloseHandle(pack);
	AcceptEntityInput(ex_entity, "Start");
	AcceptEntityInput(ht_entity, "Hurt");
	PrecacheSound(EXP_SOUND);
	PrecacheSound(EXP_SOUND2);
	EmitSoundToAll(EXP_SOUND, ex_entity);
	EmitSoundToAll(EXP_SOUND2, ex_entity);
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, ex_entity);
	WritePackCell(pack, ht_entity);
	CreateTimer(10.0, KillExp, pack);
}

public Action:KillExp(Handle:timer, Handle:pack)
{
	ResetPack(pack)
	new ex_entity = ReadPackCell(pack);
	new ht_entity = ReadPackCell(pack);
	CloseHandle(pack);
	RemoveEdict(ex_entity);
	RemoveEdict(ht_entity);
}

public OnPlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	decl String:weapon[160];
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(IsValidEntity(entity))
	{
		GetEntityNetClass(entity, weapon, sizeof(weapon));
	}
	team[victim] = GetClientTeam(victim);
	
	if(StrEqual(weapon, "CGrenadeLauncher"))
	{
		if(team[victim] == 2)
		{
			SetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
		}
	}
	if(StrEqual(weapon, "CCTerrorMeleeWeapon"))
	{
		new health = GetClientHealth(victim)
		if(team[victim] == 2 && health >= 1)
		{
			SetEntityHealth(victim, 1);
		}
	}
}
public OnPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(client != 0)
	{
		team[client] = GetClientTeam(client);
	}
	if(attacker != 0)
	{
		team[attacker] = GetClientTeam(attacker);
	}
	if(team[client] == 2 && team[attacker] == 2)
	{
		if(IsFakeClient(client))
		{
			kills[attacker]+=1;
			score[attacker]+=1;
		}
		if(!IsFakeClient(client))
		{
			kills[attacker]+=1;
			deaths[client]+=1;
			score[attacker]+=8;
			if(enablereward[attacker] != 1)
			{
				killcount[attacker]+=1;
			}
			killcount[client] = 0;
		}
	}
	if(killcount[attacker] == 4)
	{
		enablereward[attacker] = 1;
		killcount[attacker] = 0;
		PrintToChat(attacker, "\x04 4 Asesinatos seguidos!, escribe !reward para usar tu recompenza!");
		PrintHintText(attacker, "4 Asesinatos seguidos!, escribe !reward para usar tu recompenza!");
	}
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		zombieclass[client] = GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	
	if(deathmatch != 1 || zombieclass[client] == 8)
	{
		return;
	}
	CreateTimer(5.0, RespawnClient, client);
}


public SeesDeathPlayer(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(deathmatch == 0)
	{
		return;
	}
	new entity = GetEventInt(event, "subject");
	CreateTimer(5.0, RemoveEntity, entity);
}

public Action:RemoveEntity(Handle:timer, any:client)
{
	AcceptEntityInput(client, "Kill");
}

public Action:RespawnClient(Handle:timer, any:client)
{
	SDKCall(hRoundRespawn, client);
	decl Float:pos[3];
	pos = GetRandomRespawnPos();
	if(!IsValidEntity(client))
	{
		return;
	}
	if(zombieclass[client] == 8)
	{
		return;
	}
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public Action:CmdDeathMatch(client, args)
{
	CreateDeathmatch(_)
}

public Action:CmdDeathMatch0(client, args)
{
	if(enddmtimer != INVALID_HANDLE)
	{
		KillTimer(enddmtimer);
		enddmtimer = INVALID_HANDLE;
	}
	StopDeathmatch();
}

stock CreateDeathmatch(client = 0)
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	if(begindmtimer != INVALID_HANDLE)
	{
		KillTimer(begindmtimer);
		begindmtimer = INVALID_HANDLE;
	}
	
	deathmatch = 1;
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	PrecacheSound("music/flu/concert/onebadman.wav");
	if(StrEqual(map, "c1m4_atrium"))
	{
		CheatCommand(client, "ent_fire", "button_elev_3rdfloor kill");
		CheatCommand(client, "ent_fire", "trigger_finale disable");
	}
	PrintToChatAll("\x04Deathmatch ha comenzado, asesinense!");
	PrintHintTextToAll("Deathmatch ha comenzado, asesinense!");
	
	SetConVarString(hDifficulty, "Impossible", true, false);
	//ServerCommand("z_difficulty Impossible");
	SetConVarInt(hIncapCount, 0, true, false);
	//ServerCommand("sm_cvar survivor_max_incapacitated_count 0");
	SetConVarInt(hGlowSurvivor, 1, true, false);
	//ServerCommand("sm_cvar sv_disable_glow_survivors 1");
	SetConVarInt(hAllBot, 1, true, false);
	//ServerCommand("sm_cvar sb_all_bot_team 1");
	CheatCommand(client, "director_stop", "director_stop");
	
	enddmtimer = CreateTimer(1.0, Timer_EndDM, _, TIMER_REPEAT);
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			return;
		}
		if(allowmusic[i] == 0)
		{
			switch(GetRandomInt(1,2))
			{
				case 1:
				{
					ClientCommand(i, "play music/flu/concert/onebadman.wav");
				}
				case 2:
				{
					ClientCommand(i, "play music/flu/concert/midnighttride.wav");
				}
			}
		}
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		decl Float:pos[3];
		pos = GetRandomRespawnPos();
		TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:StopDeathmatch()
{
	g_Score = BuildScoreMenu();
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
		{		
			ClientCommand(i, "play music/safe/themonsterswithout.wav");
			DisplayMenu(g_Score, i, MENU_TIME_FOREVER);
			SetEntDataFloat(i, FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue"), 0.0, true);
			PrintToChat(i, "\x03Deathmatch ha terminado!");
			PrintToChat(i, "\x04Asesinatos: %i , Muertes: %i , Puntaje: %i", kills[i], deaths[i], score[i]);
			PrintHintTextToAll("Deathmatch ha terminado!");
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(20.0, ChangeMap);
		}
	}
}

public Action:ChangeMap(Handle:timer)
{
	decl String:mapname[256]
	GetRandomValidMap(mapname, sizeof(mapname));
	ServerCommand("changelevel %s", mapname);
}

GetRandomValidMap(String:map[], maxlen)
{
	new number = GetRandomInt(1,23);
	switch(number)
	{
		case 1:
		{
			Format(map, maxlen, "c1m4_atrium");
		}
		case 2:
		{
			Format(map, maxlen, "c2m1_highway");
		}
		case 3:
		{
			Format(map, maxlen, "c2m2_fairgrounds");
		}
		case 4:
		{
			Format(map, maxlen, "c2m3_coaster");
		}
		case 5:
		{
			Format(map, maxlen, "c2m4_barns");
		}
		case 6:
		{
			Format(map, maxlen, "c2m5_concert");
		}
		case 7:
		{
			Format(map, maxlen, "c3m1_plankcountry");
		}
		case 8:
		{
			Format(map, maxlen, "c3m2_swamp");
		}
		case 9:
		{
			Format(map, maxlen, "c3m3_shantytown");
		}
		case 10:
		{
			Format(map, maxlen, "c3m4_plantation");
		}
		case 11:
		{
			Format(map, maxlen, "c4m1_milltown_a");
		}
		case 12:
		{
			Format(map, maxlen, "c4m2_sugarmill_a");
		}
		case 13:
		{
			Format(map, maxlen, "c4m3_sugarmill_b");
		}
		case 14:
		{
			Format(map, maxlen, "c4m4_milltown_b");
		}
		case 15:
		{
			Format(map, maxlen, "c4m5_milltown_escape");
		}
		case 16:
		{
			Format(map, maxlen, "c5m1_waterfront");
		}
		case 17:
		{
			Format(map, maxlen, "c5m2_park");
		}
		case 18:
		{
			Format(map, maxlen, "c5m3_cemetery");
		}
		case 19:
		{
			Format(map, maxlen, "c5m4_quarter");
		}
		case 20:
		{
			Format(map, maxlen, "c5m5_bridge");
		}
		case 21:
		{
			Format(map, maxlen, "c6m1_riverbank");
		}
		case 22:
		{
			Format(map, maxlen, "c6m2_bedlam");
		}
		case 23:
		{
			Format(map, maxlen, "c6m3_port");
		}
		case 24:
		{
			Format(map, maxlen, "c1m1_hotel");
		}
		case 25:
		{
			Format(map, maxlen, "c1m2_streets");
		}
		case 26:
		{
			Format(map, maxlen, "c1m3_mall");
		}
	}
	return map;
}
//GetRandomItem()

GetRandomRespawnPos()
{
	decl Float:pos[3];
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	
	if(StrEqual(map, "c1m1_hotel"))
	{
		switch(GetRandomInt(1,12))
		{
			case 1:
			{
				pos[0] = 532.0;
				pos[1] = 6204.0;
				pos[2] = 2656.0;
			}
			case 2:
			{
				pos[0] = 573.0;
				pos[1] = 5292.0;
				pos[2] = 2656.0;
			}
			case 3:
			{
				pos[0] = 1164.0;
				pos[1] = 6085.0;
				pos[2] = 2656.0;
			}
			case 4:
			{
				pos[0] = 2212.0;
				pos[1] = 6059.0;
				pos[2] = 2656.0;
			}
			case 5:
			{
				pos[0] = 2062.0;
				pos[1] = 6942.0;
				pos[2] = 2656.0;
			}
			case 6:
			{
				pos[0] = 2005.0;
				pos[1] = 7782.0;
				pos[2] = 2560.0;
			}
			case 7:
			{
				pos[0] = 2191.0;
				pos[1] = 7216.0;
				pos[2] = 2464.0;
			}
			case 8:
			{
				pos[0] = 1990.0;
				pos[1] = 6849.0;
				pos[2] = 2464.0;
			}
			case 9:
			{
				pos[0] = 2236.0;
				pos[1] = 6085.0;
				pos[2] = 2464.0;
			}
			case 10:
			{
				pos[0] = 1502.0;
				pos[1] = 5058.0;
				pos[2] = 2464.0;
			}
			case 11:
			{
				pos[0] = 2490.0;
				pos[1] = 5364.0;
				pos[2] = 2464.0;
			}
			case 12:
			{
				pos[0] = 2165.0;
				pos[1] = 5829.0;
				pos[2] = 2464.0;
			}
		}
	}
	
	else if(StrEqual(map, "c1m2_streets"))
	{
		switch(GetRandomInt(1,10))
		{
			case 1:
			{
				pos[0] = -3598.0;
				pos[1] = 2185.0;
				pos[2] = 320.0;
			}
			case 2:
			{
				pos[0] = -3773.0;
				pos[1] = 2207.0;
				pos[2] = 128.0;
			}
			case 3:
			{
				pos[0] = -2587.0;
				pos[1] = 1286.0;
				pos[2] = 0.0;
			}
			case 4:
			{
				pos[0] = -2792.0;
				pos[1] = 3004.0;
				pos[2] = 0.0;
			}
			case 5:
			{
				pos[0] = -2215.0;
				pos[1] = 1037.0;
				pos[2] = 41.0;
			}
			case 6:
			{
				pos[0] = -1206.0;
				pos[1] = 4254.0;
				pos[2] = 138.0;
			}
			case 7:
			{
				pos[0] = -905.0;
				pos[1] = 2381.0;
				pos[2] = 324.0;
			}
			case 8:
			{
				pos[0] = 3609.0;
				pos[1] = 2559.0;
				pos[2] = 444.0;
			}
			case 9:
			{
				pos[0] = 903.0;
				pos[1] = 4876.0;
				pos[2] = 448.0;
			}
			case 10:
			{
				pos[0] = 2010.0;
				pos[1] = 4547.0;
				pos[2] = 455.0;
			}
		}
	}
	if(StrEqual(map, "c1m3_mall"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = 7297.0;
				pos[1] = -2372.0;
				pos[2] = 24.0;
			}
			case 2:
			{
				pos[0] = 6456.0;
				pos[1] = -3590.0;
				pos[2] = 24.0;
			}
			case 3:
			{
				pos[0] = 5443.0;
				pos[1] = -3509.0;
				pos[2] = 0.0;
			}
			case 4:
			{
				pos[0] = 7321.0;
				pos[1] = -2433.0;
				pos[2] = 280.0;
			}
			case 5:
			{
				pos[0] = 7468.0;
				pos[1] = -3332.0;
				pos[2] = 280.0;
			}
			case 6:
			{
				pos[0] = 6088.0;
				pos[1] = -3299.0;
				pos[2] = 280.0;
			}
			case 7:
			{
				pos[0] = 5316.0;
				pos[1] = -1794.0;
				pos[2] = 280.0;
			}
			case 8:
			{
				pos[0] = 2961.0;
				pos[1] = -2249.0;
				pos[2] = 280.0;
			}
			case 9:
			{
				pos[0] = 2951.0;
				pos[1] = -3011.0;
				pos[2] = 0.0;
			}
			case 10:
			{
				pos[0] = 3985.0;
				pos[1] = -290.0;
				pos[2] = 0.0;
			}
			case 11:
			{
				pos[0] = 2270.0;
				pos[1] = -478.0;
				pos[2] = 64.0;
			}
			case 12:
			{
				pos[0] = 1901.0;
				pos[1] = -1930.0;
				pos[2] = 280.0;
			}
			case 13:
			{
				pos[0] = 1873.0;
				pos[1] = 235.0;
				pos[2] = 280.0;
			}
		}
	}
		
	if(StrEqual(map, "c1m4_atrium"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = -4718.0;
				pos[1] = -4284.0;
				pos[2] = 792.0;
			}
			case 2:
			{
				pos[0] = -6045.0;
				pos[1] = -3435.0;
				pos[2] = 536.0;
			}
			case 3:
			{
				pos[0] = -3913.0;
				pos[1] = -3039.0;
				pos[2] = 536.0;
			}
			case 4:
			{
				pos[0] = -3405.0;
				pos[1] = -4337.0;
				pos[2] = 536.0;
			}
			case 5:
			{
				pos[0] = -2983.0;
				pos[1] = -4356.0;
				pos[2] = 280.0;
			}
			case 6:
			{
				pos[0] = -2468.0;
				pos[1] = -3390.0;
				pos[2] = 280.0;
			}
			case 7:
			{
				pos[0] = -2886.0;
				pos[1] = -3840.0;
				pos[2] = 0.0;
			}
			case 8:
			{
				pos[0] = -3398.0;
				pos[1] = -3340.0;
				pos[2] = 15.0;
			}
			case 9:
			{
				pos[0] = -4093.0;
				pos[1] = -2397.0;
				pos[2] = 0.0;
			}
			case 10:
			{
				pos[0] = -4728.0;
				pos[1] = -2401.0;
				pos[2] = 0.0;
			}
			case 11:
			{
				pos[0] = -6014.0;
				pos[1] = -3322.0;
				pos[2] = 0.0;
			}
			case 12:
			{
				pos[0] = -5358.0;
				pos[1] = -4394.0;
				pos[2] = 0.0;
			}
			case 13:
			{
				pos[0] = -5341.0;
				pos[1] = -4391.0;
				pos[2] = 0.0;
			}
		}
	}
	
	else if(StrEqual(map, "c2m1_highway"))
	{
		switch(GetRandomInt(1,8))
		{
			case 1:
			{
				pos[0] = 701.0;
				pos[1] = 5303.0;
				pos[2] = -906.0;

			}
			case 2:
			{
				pos[0] = 1817.0;
				pos[1] = 5784.0;
				pos[2] = -905.0;

			}
			case 3:
			{
				pos[0] = 3398.0;
				pos[1] = 7034.0;
				pos[2] = -945.0;

			}
			case 4:
			{
				pos[0] = 2053.0;
				pos[1] = 3219.0;
				pos[2] = -800.0;

			}
			case 5:
			{
				pos[0] = 1191.0;
				pos[1] = 3220.0;
				pos[2] = -745.0;

			}
			case 6:
			{
				pos[0] = 3827.0;
				pos[1] = 8391.0;
				pos[2] = -869.0;

			}
			case 7:
			{
				pos[0] = 4635.0;
				pos[1] = 7505.0;
				pos[2] = -683.0;

			}
			case 8:
			{
				pos[0] = 1589.0;
				pos[1] = 6895.0;
				pos[2] = -641.0;

			}
			
		}
	}
	else if(StrEqual(map, "c2m2_fairgrounds"))
	{
		switch(GetRandomInt(1,10))
		{
			case 1:
			{
				pos[0] = -625.0;
				pos[1] = 1363.0;
				pos[2] = -127.0;
			}
			case 2:
			{
				pos[0] = -2445.0;
				pos[1] = 1501.0;
				pos[2] = -115.0;
			}
			case 3:
			{
				pos[0] = -3618.0;
				pos[1] = 726.0;
				pos[2] = -127.0;
			}
			case 4:
			{
				pos[0] = -3673.0;
				pos[1] = 1050.0;
				pos[2] = -127.0;
			}
			case 5:
			{
				pos[0] = -3014.0;
				pos[1] = -1075.0;
				pos[2] = -56.0;
			}
			case 6:
			{
				pos[0] = -2754.0;
				pos[1] = 1428.0;
				pos[2] = -100.0;
			}
			case 7:
			{
				pos[0] = -3514.0;
				pos[1] = -1971.0;
				pos[2] = -127.0;
			}
			case 8:
			{
				pos[0] = 845.0;
				pos[1] = -50.0;
				pos[2] = 0.0;
			}
			case 9:
			{
				pos[0] = 193.0;
				pos[1] = -1011.0;
				pos[2] = 0.0;
			}
			case 10:
			{
				pos[0] = -711.0;
				pos[1] = 1329.0;
				pos[2] = -70.0;
			}
		}
	}
	else if(StrEqual(map, "c2m3_coaster"))
	{
		switch(GetRandomInt(1,9))
		{
			case 1:
			{
				pos[0] = 2821.0;
				pos[1] = 1839.0;
				pos[2] = -7.0;
			}
			case 2:
			{
				pos[0] = 1614.0;
				pos[1] = 2026.0;
				pos[2] = -7.0;
			}
			case 3:
			{
				pos[0] = 3249.0;
				pos[1] = 2857.0;
				pos[2] = -7.0;
			}
			case 4:
			{
				pos[0] = 2171.0;
				pos[1] = 3720.0;
				pos[2] = -7.0;
			}
			case 5:
			{
				pos[0] = 2172.0;
				pos[1] = 3704.0;
				pos[2] = -7.0;
			}
			case 6:
			{
				pos[0] = 590.0;
				pos[1] = 4202.0;
				pos[2] = -7.0;
			}
			case 7:
			{
				pos[0] = 434.0;
				pos[1] = 4813.0;
				pos[2] = 124.0;
			}
			case 8:
			{
				pos[0] = -350.0;
				pos[1] = 4521.0;
				pos[2] = 128.0;
			}
			case 9:
			{
				pos[0] = 271.0;
				pos[1] = 3914.0;
				pos[2] = 218.0;
			}
		}
	}
	
	else if(StrEqual(map, "c2m4_barns"))
	{
		switch(GetRandomInt(1,8))
		{
			case 1:
			{
				pos[0] = -1994.0;
				pos[1] = 843.0;
				pos[2] = -183.0;
			}
			case 2:
			{
				pos[0] = 48.0;
				pos[1] = 672.0;
				pos[2] = -191.0;
			}
			case 3:
			{
				pos[0] = 857.0;
				pos[1] = 2364.0;
				pos[2] = -191.0;
			}
			case 4:
			{
				pos[0] = 1158.0;
				pos[1] = 2062.0;
				pos[2] = -159.0;
			}
			case 5:
			{
				pos[0] = 1798.0;
				pos[1] = 2318.0;
				pos[2] = -191.0;
			}
			case 6:
			{
				pos[0] = 2933.0;
				pos[1] = 2324.0;
				pos[2] = -191.0;
			}
			case 7:
			{
				pos[0] = 3195.0;
				pos[1] = 1440.0;
				pos[2] = -183.0;
			}
			case 8:
			{
				pos[0] = 2804.0;
				pos[1] = 3899.0;
				pos[2] = -183.0;
			}
		}
	}
	else if(StrEqual(map, "c2m5_concert"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = -1918.0;
				pos[1] = 2373.0;
				pos[2] = -255.0;
			}
			case 2:
			{
				pos[0] = -1559.0;
				pos[1] = 2435.0;
				pos[2] = -255.0;
			}
			case 3:
			{
				pos[0] = -1556.0;
				pos[1] = 2325.0;
				pos[2] = -255.0;
			}
			case 4:
			{
				pos[0] = -1800.0;
				pos[1] = 1799.0;
				pos[2] = -255.0;
			}
			case 5:
			{
				pos[0] = -2733.0;
				pos[1] = 2067.0;
				pos[2] = -255.0;
			}
			case 6:
			{
				pos[0] = -3158.0;
				pos[1] = 1829.0;
				pos[2] = -255.0;
			}
			case 7:
			{
				pos[0] = -3657.0;
				pos[1] = 2762.0;
				pos[2] = -255.0;
			}
			case 8:
			{
				pos[0] = -3727.0;
				pos[1] = 3392.0;
				pos[2] = -255.0;
			}
			case 9:
			{
				pos[0] = -2856.0;
				pos[1] = 3675.0;
				pos[2] = -255.0;
			}
			case 10:
			{
				pos[0] = -2299.0;
				pos[1] = 3637.0;
				pos[2] = -175.0;
			}
			case 11:
			{
				pos[0] = -1197.0;
				pos[1] = 3640.0;
				pos[2] = -255.0;
			}
			case 12:
			{
				pos[0] = -1800.0;
				pos[1] = 1892.0;
				pos[2] = 128.0;
			}
			case 13:
			{
				pos[0] = -2961.0;
				pos[1] = 1820.0;
				pos[2] = 128.0;
			}
		}
	}
	
	else if(StrEqual(map, "c3m1_plankcountry"))
	{
		switch(GetRandomInt(1,8))
		{
			case 1:
			{
				pos[0] = -10632.0;
				pos[1] = 8711.0;
				pos[2] = 160.0;
			}
			case 2:
			{
				pos[0] = -10813.0;
				pos[1] = 10640.0;
				pos[2] = 160.0;
			}
			case 3:
			{
				pos[0] = -8816.0;
				pos[1] = 9970.0;
				pos[2] = 96.0;
			}
			case 4:
			{
				pos[0] = -7832.0;
				pos[1] = 8812.0;
				pos[2] = 64.0;
			}
			case 5:
			{
				pos[0] = -9175.0;
				pos[1] = 7610.0;
				pos[2] = 138.0;
			}
			case 6:
			{
				pos[0] = -9025.0;
				pos[1] = 6836.0;
				pos[2] = 109.0;
			}
			case 7:
			{
				pos[0] = -6903.0;
				pos[1] = 6228.0;
				pos[2] = 32.0;
			}
			case 8:
			{
				pos[0] = -6285.0;
				pos[1] = 6064.0;
				pos[2] = 32.0;
			}
		}
	}
	
	else if(StrEqual(map, "c3m2_swamp"))
	{
		switch(GetRandomInt(1,10))
		{
			case 1:
			{
				pos[0] = -2094.0;
				pos[1] = 2504.0;
				pos[2] = -15.0;
			}
			case 2:
			{
				pos[0] = -2842.0;
				pos[1] = 1836.0;
				pos[2] = -15.0;
			}
			case 3:
			{
				pos[0] = -3083.0;
				pos[1] = 3179.0;
				pos[2] = 14.0;
			}
			case 4:
			{
				pos[0] = -3588.0;
				pos[1] = 4007.0;
				pos[2] = -1.0;
			}
			case 5:
			{
				pos[0] = -4879.0;
				pos[1] = 5344.0;
				pos[2] = 16.0;
			}
			case 6:
			{
				pos[0] = -6273.0;
				pos[1] = 5603.0;
				pos[2] = 5.0;
			}
			case 7:
			{
				pos[0] = -6429.0;
				pos[1] = 3187.0;
				pos[2] = 16.0;
			}
			case 8:
			{
				pos[0] = -8678.0;
				pos[1] = 4789.0;
				pos[2] = 16.0;
			}
			case 9:
			{
				pos[0] = -8772.0;
				pos[1] = 6564.0;
				pos[2] = 16.0;
			}
			case 10:
			{
				pos[0] = -7681.0;
				pos[1] = 6592.0;
				pos[2] = -31.0;
			}
		}
	}
	else if(StrEqual(map, "c3m3_shantytown"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = -4718.0;
				pos[1] = -4284.0;
				pos[2] = 792.0;
			}
			case 2:
			{
				pos[0] = -6045.0;
				pos[1] = -3435.0;
				pos[2] = 536.0;
			}
			case 3:
			{
				pos[0] = -3913.0;
				pos[1] = -3039.0;
				pos[2] = 536.0;
			}
			case 4:
			{
				pos[0] = -3405.0;
				pos[1] = -4337.0;
				pos[2] = 536.0;
			}
			case 5:
			{
				pos[0] = -2983.0;
				pos[1] = -4356.0;
				pos[2] = 280.0;
			}
			case 6:
			{
				pos[0] = -2468.0;
				pos[1] = -3390.0;
				pos[2] = 280.0;
			}
			case 7:
			{
				pos[0] = -2886.0;
				pos[1] = -3840.0;
				pos[2] = 0.0;
			}
			case 8:
			{
				pos[0] = -3398.0;
				pos[1] = -3340.0;
				pos[2] = 15.0;
			}
			case 9:
			{
				pos[0] = -4093.0;
				pos[1] = -2397.0;
				pos[2] = 0.0;
			}
			case 10:
			{
				pos[0] = -4728.0;
				pos[1] = -2401.0;
				pos[2] = 0.0;
			}
			case 11:
			{
				pos[0] = -6014.0;
				pos[1] = -3322.0;
				pos[2] = 0.0;
			}
			case 12:
			{
				pos[0] = -5358.0;
				pos[1] = -4394.0;
				pos[2] = 0.0;
			}
			case 13:
			{
				pos[0] = -5341.0;
				pos[1] = -4391.0;
				pos[2] = 0.0;
			}
		}
	}
	
	else if(StrEqual(map, "c3m4_plantation"))
	{
		switch(GetRandomInt(1,12))
		{
			case 1:
			{
				pos[0] = 860.407043;
				pos[1] = 1620.0;
				pos[2] = 129.0;
			}
			case 2:
			{
				pos[0] = 600.0;
				pos[1] = 321.0;
				pos[2] = 131.0;
			}
			case 3:
			{
				pos[0] = 2299.0;
				pos[1] = 112.0;
				pos[2] = 132.0;
			}
			case 4:
			{
				pos[0] = 2978.0;
				pos[1] = 1638.0;
				pos[2] = 140.0;
			}
			case 5:
			{
				pos[0] = 2615.0;
				pos[1] = 126.0;
				pos[2] = 224.0;
			}
			case 6:
			{
				pos[0] = 2097.0;
				pos[1] = 9.0;
				pos[2] = 224.0;
			}
			case 7:
			{
				pos[0] = 1189.0;
				pos[1] = -485.0;
				pos[2] = 224.0;
			}
			case 8:
			{
				pos[0] = 2018.0;
				pos[1] = -411.0;
				pos[2] = 224.0;
			}
			case 9:
			{
				pos[0] = 2745.0;
				pos[1] = -457.0;
				pos[2] = 416.0;
			}
			case 10:
			{
				pos[0] = 1879.0;
				pos[1] = 202.0;
				pos[2] = 416.0;
			}
			case 11:
			{
				pos[0] = 1237.0;
				pos[1] = 118.0;
				pos[2] = 416.0;
			}
			case 12:
			{
				pos[0] = 1989.0;
				pos[1] = -61.0;
				pos[2] = 600.0;
			}
		}
	}
	
	else if(StrEqual(map, "c4m1_milltown_a"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = -3311.0;
				pos[1] = 7676.0;
				pos[2] = 104.0;
			}
			case 2:
			{
				pos[0] = -1782.0;
				pos[1] = 8013.0;
				pos[2] = 95.0;
			}
			case 3:
			{
				pos[0] = -2065.0;
				pos[1] = 5746.0;
				pos[2] = 98.0;
			}
			case 4:
			{
				pos[0] = -462.0;
				pos[1] = 6334.0;
				pos[2] = 264.0;
			}
			case 5:
			{
				pos[0] = -847.0;
				pos[1] = 5684.0;
				pos[2] = 264.0;
			}
			case 6:
			{
				pos[0] = 196.0;
				pos[1] = 4429.0;
				pos[2] = 104.0;
			}
			case 7:
			{
				pos[0] = 139.0;
				pos[1] = 2642.0;
				pos[2] = 101.0;
			}
			case 8:
			{
				pos[0] = 2221.0;
				pos[1] = 2482.0;
				pos[2] = 104.0;
			}
			case 9:
			{
				pos[0] = 4214.0;
				pos[1] = 3478.0;
				pos[2] = 96.0;
			}
			case 10:
			{
				pos[0] = 4089.0;
				pos[1] = 1653.0;
				pos[2] = 184.0;
			}
			case 11:
			{
				pos[0] = 4262.0;
				pos[1] = -364.0;
				pos[2] = 104.0;
			}
			case 12:
			{
				pos[0] = 3977.0;
				pos[1] = -672.0;
				pos[2] = 96.0;
			}
			case 13:
			{
				pos[0] = 4461.0;
				pos[1] = -333.0;
				pos[2] = 96.0;
			}
		}
	}
	
	else if(StrEqual(map, "c4m2_sugarmill_a"))
	{
		switch(GetRandomInt(1,16))
		{
			case 1:
			{
				pos[0] = 2499.0;
				pos[1] = -4679.0;
				pos[2] = 123.0;
			}
			case 2:
			{
				pos[0] = 2796.0;
				pos[1] = -3704.0;
				pos[2] = 100.0;
			}
			case 3:
			{
				pos[0] = 1085.0;
				pos[1] = -3974.0;
				pos[2] =96.0;
			}
			case 4:
			{
				pos[0] = 335.0;
				pos[1] = -4452.0;
				pos[2] = 96.0;
			}
			case 5:
			{
				pos[0] = 2824.0;
				pos[1] = -5528.0;
				pos[2] = 106.0;
			}
			case 6:
			{
				pos[0] = 1442.0;
				pos[1] = -6223.0;
				pos[2] = 104.0;
			}
			case 7:
			{
				pos[0] = 1748.0;
				pos[1] = -5446.0;
				pos[2] = 106.0;
			}
			case 8:
			{
				pos[0] = 304.0;
				pos[1] = -5336.0;
				pos[2] = 96.0;
			}
			case 9:
			{
				pos[0] = 120.0;
				pos[1] = -5776.0;
				pos[2] = 102.0;
			}
			case 10:
			{
				pos[0] = -478.0;
				pos[1] = -6548.0;
				pos[2] = 113.0;
			}
			case 11:
			{
				pos[0] = -1282.0;
				pos[1] = -8314.0;
				pos[2] = 96.0;
			}
			case 12:
			{
				pos[0] = -459.0;
				pos[1] = -8812.0;
				pos[2] = 97.0;
			}
			case 13:
			{
				pos[0] = -1835.0;
				pos[1] = -8559.0;
				pos[2] = 368.0;
			}
			case 14:
			{
				pos[0] = -457.0;
				pos[1] = -8632.0;
				pos[2] = 612.0;
			}
			case 15:
			{
				pos[0] = -520.0;
				pos[1] = -9288.0;
				pos[2] = 608.0;
			}
			case 16:
			{
				pos[0] = -1828.0;
				pos[1] = -8993.0;
				pos[2] = 608.0;
			}
		}
	}
	
	else if(StrEqual(map, "c4m3_sugarmill_b"))
	{
		switch(GetRandomInt(1,10))
		{
			case 1:
			{
				pos[0] = -1671.0;
				pos[1] = -9331.0;
				pos[2] = 608.0;
			}
			case 2:
			{
				pos[0] = -716.0;
				pos[1] = -8613.0;
				pos[2] = 608.0;
			}
			case 3:
			{
				pos[0] = -470.0;
				pos[1] = -8603.0;
				pos[2] = 353.0;
			}
			case 4:
			{
				pos[0] = -1251.0;
				pos[1] = -8196.0;
				pos[2] = 96.0;
			}
			case 5:
			{
				pos[0] = 564.0;
				pos[1] = -8489.0;
				pos[2] = 96.0;
			}
			case 6:
			{
				pos[0] = 619.0;
				pos[1] = -7294.0;
				pos[2] = 107.0;
			}
			case 7:
			{
				pos[0] = 137.0;
				pos[1] = -5657.0;
				pos[2] = 101.0;
			}
			case 8:
			{
				pos[0] = 497.0;
				pos[1] = -5757.0;
				pos[2] = 104.0;
			}
			case 9:
			{
				pos[0] = 1609.0;
				pos[1] = -6230.0;
				pos[2] = 104.0;
			}
			case 10:
			{
				pos[0] = 1438.0;
				pos[1] = -5428.0;
				pos[2] = 228.0;
			}
		}
	}
	
	else if(StrEqual(map, "c4m4_milltown_b"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = 1825.0;
				pos[1] = 3189.0;
				pos[2] = 298.0;
			}
			case 2:
			{
				pos[0] = 1546.0;
				pos[1] = 4516.0;
				pos[2] = 217.0;
			}
			case 3:
			{
				pos[0] = 1639.0;
				pos[1] = 4397.0;
				pos[2] = 217.0;
			}
			case 4:
			{
				pos[0] = 199.0;
				pos[1] = 4225.0;
				pos[2] = 104.0;
			}
			case 5:
			{
				pos[0] = -323.0;
				pos[1] = 4598.0;
				pos[2] = 104.0;
			}
			case 6:
			{
				pos[0] = 1759.0;
				pos[1] = 5053.0;
				pos[2] = 125.0;
			}
			case 7:
			{
				pos[0] = 1322.0;
				pos[1] = 6589.0;
				pos[2] = 120.0;
			}
			case 8:
			{
				pos[0] = 1659.0;
				pos[1] = 7149.0;
				pos[2] = 224.0;
			}
			case 9:
			{
				pos[0] = -367.0;
				pos[1] = 6354.0;
				pos[2] = 264.0;
			}
			case 10:
			{
				pos[0] = -448.0;
				pos[1] = 5685.0;
				pos[2] = 104.0;
			}
			case 11:
			{
				pos[0] = -1514.0;
				pos[1] = 6740.0;
				pos[2] = 121.0;
			}
			case 12:
			{
				pos[0] = -2024.0;
				pos[1] = 5384.0;
				pos[2] = 97.0;
			}
			case 13:
			{
				pos[0] = -1693.0;
				pos[1] = 7703.0;
				pos[2] = 96.0;
			}
		}
	}
	
	else if(StrEqual(map, "c4m5_milltown_escape"))
	{
		switch(GetRandomInt(1,11))
		{
			case 1:
			{
				pos[0] = -4131.0;
				pos[1] = 7712.0;
				pos[2] = 97.0;
			}
			case 2:
			{
				pos[0] = -4163.0;
				pos[1] = 6757.0;
				pos[2] = 97.0;
			}
			case 3:
			{
				pos[0] = -4694.0;
				pos[1] = 7151.0;
				pos[2] = 140.0;
			}
			case 4:
			{
				pos[0] = -4612.0;
				pos[1] = 8412.0;
				pos[2] = 97.0;
			}
			case 5:
			{
				pos[0] = -6103.0;
				pos[1] = 8967.0;
				pos[2] = 96.0;
			}
			case 6:
			{
				pos[0] = -6312.0;
				pos[1] = 8004.0;
				pos[2] = 95.0;
			}
			case 7:
			{
				pos[0] = -6159.0;
				pos[1] = 7736.0;
				pos[2] = 104.0;
			}
			case 8:
			{
				pos[0] = -6910.0;
				pos[1] = 7122.0;
				pos[2] = 95.0;
			}
			case 9:
			{
				pos[0] = -6598.0;
				pos[1] = 6657.0;
				pos[2] = 96.0;
			}
			case 10:
			{
				pos[0] = -6693.0;
				pos[1] = 8515.0;
				pos[2] = 97.0;
			}
			case 11:
			{
				pos[0] = -7143.0;
				pos[1] = 8506.0;
				pos[2] = 116.0;
			}
		}
	}
	
	else if(StrEqual(map, "c5m1_waterfront"))
	{
		switch(GetRandomInt(1,15))
		{
			case 1:
			{
				pos[0] = 202.0;
				pos[1] = -761.0;
				pos[2] = -367.0;
			}
			case 2:
			{
				pos[0] = 234.0;
				pos[1] = 996.0;
				pos[2] = -375.0;
			}
			case 3:
			{
				pos[0] = -479.0;
				pos[1] = 99.0;
				pos[2] = -370.0;
			}
			case 4:
			{
				pos[0] = -1571.0;
				pos[1] = -46.0;
				pos[2] = -375.0;
			}
			case 5:
			{
				pos[0] = -1599.0;
				pos[1] = -905.0;
				pos[2] = -215.0;
			}
			case 6:
			{
				pos[0] = -727.0;
				pos[1] = -1434.0;
				pos[2] = -375.0;
			}
			case 7:
			{
				pos[0] = -1544.0;
				pos[1] = -1714.0;
				pos[2] = -375.0;
			}
			case 8:
			{
				pos[0] = -3041.0;
				pos[1] = -2332.0;
				pos[2] = -375.0;
			}
			case 9:
			{
				pos[0] = -1750.0;
				pos[1] = -1442.0;
				pos[2] = -374.0;
			}
			case 10:
			{
				pos[0] = -2693.0;
				pos[1] = -1603.0;
				pos[2] = -375.0;
			}
			case 11:
			{
				pos[0] = -2086.0;
				pos[1] = -382.0;
				pos[2] = -336.0;
			}
			case 12:
			{
				pos[0] = -2263.0;
				pos[1] = -14.0;
				pos[2] = -367.0;
			}
			case 13:
			{
				pos[0] = -2503.0;
				pos[1] = -84.0;
				pos[2] = -367.0;
			}
			case 14:
			{
				pos[0] = -3180.0;
				pos[1] = 489.0;
				pos[2] = -375.0;
			}
			case 15:
			{
				pos[0] = -3284.0;
				pos[1] = -1144.0;
				pos[2] = -375.0;
			}
		}
	}
	
	else if(StrEqual(map, "c5m2_park"))
	{
		switch(GetRandomInt(1,14))
		{
			case 1:
			{
				pos[0] = -3283.0;
				pos[1] = -2889.0;
				pos[2] = -375.0;
			}
			case 2:
			{
				pos[0] = -3266.0;
				pos[1] = -1317.0;
				pos[2] = -375.0;
			}
			case 3:
			{
				pos[0] = -4552.0;
				pos[1] = -3017.0;
				pos[2] = -191.0;
			}
			case 4:
			{
				pos[0] = -4727.0;
				pos[1] = -1475.0;
				pos[2] = -191.0;
			}
			case 5:
			{
				pos[0] = -5009.0;
				pos[1] = -2206.0;
				pos[2] = -303.0;
			}
			case 6:
			{
				pos[0] = -5672.0;
				pos[1] = -3212.0;
				pos[2] = -254.0;
			}
			case 7:
			{
				pos[0] = -6616.0;
				pos[1] = -3223.0;
				pos[2] = -255.0;
			}
			case 8:
			{
				pos[0] = -8048.0;
				pos[1] = -3606.0;
				pos[2] = -244.0;
			}
			case 9:
			{
				pos[0] = -7352.0;
				pos[1] = -2112.0;
				pos[2] = -255.0;
			}
			case 10:
			{
				pos[0] = -7702.0;
				pos[1] = -937.0;
				pos[2] = -255.0;
			}
			case 11:
			{
				pos[0] = -7686.0;
				pos[1] = -707.0;
				pos[2] = -255.0;
			}
			case 12:
			{
				pos[0] = -7601.0;
				pos[1] = -257.0;
				pos[2] = -246.0;
			}
			case 13:
			{
				pos[0] = -8526.0;
				pos[1] = -2117.0;
				pos[2] = -247.0;
			}
			case 14:
			{
				pos[0] = -8648.0;
				pos[1] = -4105.0;
				pos[2] = -247.0;
			}
		}
	}
	
	else if(StrEqual(map, "c5m3_cemetery"))
	{
		switch(GetRandomInt(1,11))
		{
			case 1:
			{
				pos[0] = 3086.0;
				pos[1] = 5606.0;
				pos[2] = 0.0;
			}
			case 2:
			{
				pos[0] = 3701.0;
				pos[1] = 5166.0;
				pos[2] = 164.0;
			}
			case 3:
			{
				pos[0] = 3447.0;
				pos[1] = 4972.0;
				pos[2] = 8.0;
			}
			case 4:
			{
				pos[0] = 5089.0;
				pos[1] = 5076.0;
				pos[2] = 1.0;
			}
			case 5:
			{
				pos[0] = 4895.0;
				pos[1] = 3820.0;
				pos[2] = 2.0;
			}
			case 6:
			{
				pos[0] = 3129.0;
				pos[1] = 3713.0;
				pos[2] = 3.0;
			}
			case 7:
			{
				pos[0] = 4912.0;
				pos[1] = 3290.0;
				pos[2] = 2.0;
			}
			case 8:
			{
				pos[0] = 4654.0;
				pos[1] = 2298.0;
				pos[2] = 5.0;
			}
			case 9:
			{
				pos[0] = 3454.0;
				pos[1] = 3274.0;
				pos[2] = 32.0;
			}
			case 10:
			{
				pos[0] = 3350.0;
				pos[1] = 2487.0;
				pos[2] = 176.0;
			}
			case 11:
			{
				pos[0] = 2898.0;
				pos[1] = 2517.0;
				pos[2] = 176.0;
			}
		}
	}
	
	else if(StrEqual(map, "c5m4_quarter"))
	{
		switch(GetRandomInt(1,15))
		{
			case 1:
			{
				pos[0] = -2872.0;
				pos[1] = 4036.0;
				pos[2] = 80.0;
			}
			case 2:
			{
				pos[0] = -3437.0;
				pos[1] = 3482.0;
				pos[2] = 68.0;
			}
			case 3:
			{
				pos[0] = -3300.0;
				pos[1] = 3194.0;
				pos[2] = 224.0;
			}
			case 4:
			{
				pos[0] = -2209.0;
				pos[1] = 3113.0;
				pos[2] = 64.0;
			}
			case 5:
			{
				pos[0] = -3684.0;
				pos[1] = 3122.0;
				pos[2] = 64.0;
			}
			case 6:
			{
				pos[0] = -2357.0;
				pos[1] = 2280.0;
				pos[2] = 64.0;
			}
			case 7:
			{
				pos[0] = -1509.0;
				pos[1] = 3215.0;
				pos[2] = 64.0;
			}
			case 8:
			{
				pos[0] = -189.0;
				pos[1] = 2072.0;
				pos[2] = 64.0;
			}
			case 9:
			{
				pos[0] = -971.0;
				pos[1] = 2420.0;
				pos[2] = 64.0;
			}
			case 10:
			{
				pos[0] = -919.0;
				pos[1] = 1779.0;
				pos[2] = 80.0;
			}
			case 11:
			{
				pos[0] = -684.0;
				pos[1] = 2016.0;
				pos[2] = 224.0;
			}
			case 12:
			{
				pos[0] = -1104.0;
				pos[1] = 2392.0;
				pos[2] = 72.0;
			}
			case 13:
			{
				pos[0] = -1088.0;
				pos[1] = -2052.0;
				pos[2] = 72.0;
			}
			case 14:
			{
				pos[0] = -1131.0;
				pos[1] = 1817.0;
				pos[2] = 64.0;
			}
			case 15:
			{
				pos[0] = -976.0;
				pos[1] = -1468.0;
				pos[2] = 96.0;
			}
		}
	}
	
	else if(StrEqual(map, "c5m5_bridge"))
	{
		switch(GetRandomInt(1,14))
		{
			case 1:
			{
				pos[0] = -8807.0;
				pos[1] = 6307.0;
				pos[2] = 456.0;
			}
			case 2:
			{
				pos[0] = -7529.0;
				pos[1] = 6368.0;
				pos[2] = 456.0;
			}
			case 3:
			{
				pos[0] = -6803.0;
				pos[1] = 6110.0;
				pos[2] = 470.0;
			}
			case 4:
			{
				pos[0] = -5797.0;
				pos[1] = 6303.0;
				pos[2] = 456.0;
			}
			case 5:
			{
				pos[0] = -4352.0;
				pos[1] = 6198.0;
				pos[2] = 456.0;
			}
			case 6:
			{
				pos[0] = -4148.0;
				pos[1] = 6231.0;
				pos[2] = 790.0;
			}
			case 7:
			{
				pos[0] = -2350.0;
				pos[1] = 6519.0;
				pos[2] = 460.0;
			}
			case 8:
			{
				pos[0] = -1463.0;
				pos[1] = 6106.0;
				pos[2] = 470.0;
			}
			case 9:
			{
				pos[0] = 218.0;
				pos[1] = 6654.0;
				pos[2] = 480.0;
			}
			case 10:
			{
				pos[0] = 2228.0;
				pos[1] = 6515.0;
				pos[2] = 460.0;
			}
			case 11:
			{
				pos[0] = 6723.0;
				pos[1] = 6521.0;
				pos[2] = 459.0;
			}
			case 12:
			{
				pos[0] = 9257.0;
				pos[1] = 6357.0;
				pos[2] = 456.0;
			}
			case 13:
			{
				pos[0] = 9356.0;
				pos[1] = 1703.0;
				pos[2] = 217.0;
			}
			case 14:
			{
				pos[0] = 9466.0;
				pos[1] = 2570.0;
				pos[2] = 393.0;
			}
		}
	}
	
	else if(StrEqual(map, "c6m1_riverbank"))
	{
		switch(GetRandomInt(1,15))
		{
			case 1:
			{
				pos[0] = 2385.0;
				pos[1] = 3195.0;
				pos[2] = -31.0;
			}
			case 2:
			{
				pos[0] = 3965.0;
				pos[1] = 2701.0;
				pos[2] = 31.0;
			}
			case 3:
			{
				pos[0] = 3245.0;
				pos[1] = 2043.0;
				pos[2] = 56.0;
			}
			case 4:
			{
				pos[0] = 3465.0;
				pos[1] = 2065.0;
				pos[2] = 56.0;
			}
			case 5:
			{
				pos[0] = 3151.0;
				pos[1] = 2527.0;
				pos[2] = 200.0;
			}
			case 6:
			{
				pos[0] = 3781.0;
				pos[1] = 1887.0;
				pos[2] = 200.0;
			}
			case 7:
			{
				pos[0] = 4508.0;
				pos[1] = 905.0;
				pos[2] = 158.0;
			}
			case 8:
			{
				pos[0] = 2399.0;
				pos[1] = 1058.0;
				pos[2] = 197.0;
			}
			case 9:
			{
				pos[0] = 1317.0;
				pos[1] = 1347.0;
				pos[2] = 199.0;
			}
			case 10:
			{
				pos[0] = -1304.0;
				pos[1] = 1189.0;
				pos[2] = 194.0;
			}
			case 11:
			{
				pos[0] = 2356.0;
				pos[1] = 1905.0;
				pos[2] = 352.0;
			}
			case 12:
			{
				pos[0] = 1584.0;
				pos[1] = 2228.0;
				pos[2] = 352.0;
			}
			case 13:
			{
				pos[0] = 2378.0;
				pos[1] = 2237.0;
				pos[2] = 512.0;
			}
			case 14:
			{
				pos[0] = 835.0;
				pos[1] = 1943.0;
				pos[2] = 512.0;
			}
			case 15:
			{
				pos[0] = 144.0;
				pos[1] = 717.0;
				pos[2] = 523.0;
			}
		}
	}
	
	else if(StrEqual(map, "c6m2_bedlam"))
	{
		switch(GetRandomInt(1,14))
		{
			case 1:
			{
				pos[0] = 1530.0;
				pos[1] = -1674.0;
				pos[2] = 32.0;
			}
			case 2:
			{
				pos[0] = 1553.0;
				pos[1] = -306.0;
				pos[2] = 64.0;
			}
			case 3:
			{
				pos[0] = 2412.0;
				pos[1] = 38.0;
				pos[2] = -15.0;
			}
			case 4:
			{
				pos[0] = 761.0;
				pos[1] = 116.0;
				pos[2] = -27.0;
			}
			case 5:
			{
				pos[0] = 734.0;
				pos[1] = 482.0;
				pos[2] = -15.0;
			}
			case 6:
			{
				pos[0] = 2080.0;
				pos[1] = 1530.0;
				pos[2] = -185.0;
			}
			case 7:
			{
				pos[0] = -313.0;
				pos[1] = 1437.0;
				pos[2] = -71.0;
			}
			case 8:
			{
				pos[0] = 188.0;
				pos[1] = 2838.0;
				pos[2] = -151.0;
			}
			case 9:
			{
				pos[0] = 360.0;
				pos[1] = 2733.0;
				pos[2] = -151.0;
			}
			case 10:
			{
				pos[0] = 112.0;
				pos[1] = 2264.0;
				pos[2] = 16.0;
			}
			case 11:
			{
				pos[0] = 143.0;
				pos[1] = 2364.0;
				pos[2] = 176.0;
			}
			case 12:
			{
				pos[0] = 90.0;
				pos[1] = 3389.0;
				pos[2] = 8.0;
			}
			case 13:
			{
				pos[0] = 1244.0;
				pos[1] = 5011.0;
				pos[2] = 32.0;
			}
			case 14:
			{
				pos[0] = 2166.0;
				pos[1] = 4121.0;
				pos[2] = -158.0;
			}
		}
	}
	
	else if(StrEqual(map, "c6m3_port"))
	{
		switch(GetRandomInt(1,13))
		{
			case 1:
			{
				pos[0] = -1444.0;
				pos[1] = -483.0;
				pos[2] = 0.0;
			}
			case 2:
			{
				pos[0] = -1087.0;
				pos[1] = -341.0;
				pos[2] = 160.0;
			}
			case 3:
			{
				pos[0] = -731.0;
				pos[1] = 165.0;
				pos[2] = 160.0;
			}
			case 4:
			{
				pos[0] = -1561.0;
				pos[1] = -763.0;
				pos[2] = 160.0;
			}
			case 5:
			{
				pos[0] = -1822.0;
				pos[1] = 1824.0;
				pos[2] = 160.0;
			}
			case 6:
			{
				pos[0] = -931.0;
				pos[1] = 2114.0;
				pos[2] = 320.0;
			}
			case 7:
			{
				pos[0] = -2512.0;
				pos[1] = 434.0;
				pos[2] = 3.0;
			}
			case 8:
			{
				pos[0] = 474.0;
				pos[1] = 2026.0;
				pos[2] = 160.0;
			}
			case 9:
			{
				pos[0] = 870.0;
				pos[1] = 964.0;
				pos[2] = 0.0;
			}
			case 10:
			{
				pos[0] = 1837.0;
				pos[1] = 1206.0;
				pos[2] = -95.0;
			}
			case 11:
			{
				pos[0] = 1986.0;
				pos[1] = -621.0;
				pos[2] = 0.0;
			}
			case 12:
			{
				pos[0] = 665.0;
				pos[1] = -603.0;
				pos[2] = 160.0;
			}
			case 13:
			{
				pos[0] = 256.0;
				pos[1] = -1083.0;
				pos[2] = 414.0;
			}
		}
	}
	
	return pos;
}
//GetRandomItemPos()

public Action:BeginDM(Handle:timer)
{
	static NumPrinted = 90
	if (NumPrinted-- <= 0)
	{
		CheatCommand(_, "say", "/deathmatch");
		NumPrinted = 90;
 
		return Plugin_Stop
	}
	PrintHintTextToAll("Deathmatch comenzara en %i segundos. Preparate!", NumPrinted);
	return Plugin_Continue
}

public Action:Timer_EndDM(Handle:timer)
{
	static Countdown = 420
	if(Countdown-- <= 0)
	{
		CheatCommand(_, "say", "/deathmatch0");
		deathmatch = 0;
		Countdown = 420;
		return Plugin_Stop
	}
	return Plugin_Continue
}

public Action:CheckDM(Handle:timer)
{
	if(deathmatch == 1)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsValidEntity(i) && IsClientInGame(i))
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}
		return Plugin_Stop
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
	}
	return Plugin_Continue
}

stock CheatCommand(client = 0, String:command[], String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}