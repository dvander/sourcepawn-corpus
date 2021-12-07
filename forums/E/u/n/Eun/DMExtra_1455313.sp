#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <menus>
#define PLUGIN_VERSION "1.28"
#pragma semicolon 1


public Plugin:myinfo = 
{
	name = "DMExtra",
	author = "Eun",
	description = "DMExtra Plugin",
	version = PLUGIN_VERSION,
	url = "eun.su.am"
}

new String:g_curMap[255] = "";
new bool:g_EndRound = false;
new Handle:g_mapList = INVALID_HANDLE;
new Handle:g_Timelimit = INVALID_HANDLE;
new Handle:g_MapMenu = INVALID_HANDLE;
new Handle:g_NextLevel = INVALID_HANDLE;

new Handle:var_enabled;
new Handle:var_vote;
new Handle:var_damage;
new Handle:var_nextmap;
new Handle:var_timeleft;
new Handle:var_balance;
new Handle:mp_roundtime;
new Handle:mp_timelimit;
new bool:g_bEnabled = false;
new bool:g_bVote = false;
new bool:g_bDamage = false;
new bool:g_bNextmap = false;
new bool:g_bTimeleft = false;
new bool:g_bBalance = false;
new bool:g_bPause = true;
new bool:g_bInf = false;
	
new Handle:g_lastmaps = INVALID_HANDLE;


new tScore;
new ctScore;

new g_WeaponParent;

public OnPluginStart()
{

	CreateConVar("DMExtra", PLUGIN_VERSION, "DMExtra Plugin", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// for weapon removal
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
	// Extend roundtime
	mp_roundtime = FindConVar("mp_roundtime");
	SetConVarBounds(mp_roundtime, ConVarBound_Upper, true, 346.0);
	SetConVarBounds(mp_roundtime, ConVarBound_Lower, true, 0.0);
	mp_timelimit = FindConVar("mp_timelimit");
	
	if (GetConVarFloat(mp_roundtime) == 0)
	{
		g_bInf = true;
	}
	else
	{
		g_bInf = false;
	}
	

	
	// get Maplist
	new g_mapSerial = -1;	
	g_mapList = CreateArray(32);
	ReadMapList(g_mapList, g_mapSerial);
	
	g_lastmaps = CreateArray(32);
	
	tScore = 0;
	ctScore = 0;
	g_bPause = true;
	
	// hook events
	HookEvent("round_start", RoundStart, EventHookMode_Pre);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Post);
	HookEvent("player_say", PlayerChat, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);
	
	AddCommandListener(jointeam, "jointeam");
	AddCommandListener(spectate, "spectate");
	
	// hook timeleft
	AddCommandListener(Timeleft, "timeleft");
	
	
	// create convars
	var_enabled = CreateConVar("dmextra_enabled", "1", "enable disable the plugin", FCVAR_PLUGIN);
	var_vote = CreateConVar("dmextra_vote", "1", "allow map vote at the end of round", FCVAR_PLUGIN);
	var_damage = CreateConVar("dmextra_damage", "1", "show damage", FCVAR_PLUGIN);
	var_nextmap = CreateConVar("dmextra_nextmap", "1", "allow nextmap / nextlevel command", FCVAR_PLUGIN);
	var_timeleft = CreateConVar("dmextra_timeleft", "1", "allow timeleft command", FCVAR_PLUGIN);
	var_balance = CreateConVar("dmextra_teambalance", "1", "do teambalance", FCVAR_PLUGIN);
	
	
	// hook var changes
	HookConVarChange(var_enabled, Cvar_Changed);
	HookConVarChange(var_vote, Cvar_Changed);
	HookConVarChange(var_damage, Cvar_Changed);
	HookConVarChange(var_nextmap, Cvar_Changed);
	HookConVarChange(var_timeleft, Cvar_Changed);
	HookConVarChange(var_balance, Cvar_Changed);
	HookConVarChange(mp_roundtime, Cvar_Changed);
	
	g_bEnabled = GetConVarBool(var_enabled);
	g_bVote = GetConVarBool(var_vote);
	g_bDamage = GetConVarBool(var_damage);
	g_bNextmap = GetConVarBool(var_nextmap);
	g_bTimeleft = GetConVarBool(var_timeleft);
	g_bBalance = GetConVarBool(var_balance);
	
	// essential
	ServerCommand("mp_freezetime 0");
	
}


stock GetClientCount2()
{
	new clients = 0;
	for( new i = 1; i <= MaxClients; i++ ) 
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			clients++;
		}
	}
	return clients;
}



public OnMapStart()
{
	// if enabled
	if (g_bEnabled)
	{
		// essential
		ServerCommand("mp_freezetime 0");
		
		GetCurrentMap(g_curMap, sizeof(g_curMap));
		
		g_NextLevel = FindConVar("nextlevel");
		
		
		if (SetNextLevel() == false)
		{
			new mapcount = GetArraySize(g_mapList)-1;
			if (mapcount > 0)
			{
				new String:mapname[255];
				GetArrayString(g_mapList, 0, mapname, sizeof(mapname));
				ServerCommand("changelevel %s", mapname);
				return;
			}
		}
		
		if (GetConVarFloat(mp_roundtime) == 0)
		{
			g_bInf = true;
		}
		else
		{
			g_bInf = false;
		}
	
	
		SetConVarFloat(mp_timelimit, GetConVarFloat(mp_roundtime));
	
		
		
		g_EndRound = false;
		
		
		

		PushArrayString(g_lastmaps, g_curMap);
		
		g_MapMenu = BuildMapMenu();
		
		
		new clients = GetClientCount2();
		if (clients > 0)
		{
			// start game
			g_Timelimit = CreateTimer(10.0, checkTimelimit, _, TIMER_REPEAT);
			g_bPause = false;
		}
		else
		{
			g_bPause = true;
		}
		
		
	}
}

public OnMapEnd()
{	
	if (g_bEnabled && g_MapMenu != INVALID_HANDLE)
	{
		CloseHandle(g_MapMenu);
		g_MapMenu = INVALID_HANDLE;
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		tScore = 0;
		ctScore = 0;
		RemoveStuff();
		ServerCommand("mp_ignore_round_win_conditions 1");
	}
	else
	{
		ServerCommand("mp_ignore_round_win_conditions 0");
	}
	return Plugin_Continue;
}


public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		// block the stupid "round draw" text
		dontBroadcast = true;
		if (g_Timelimit != INVALID_HANDLE)
		{
			KillTimer(g_Timelimit);
			g_Timelimit = INVALID_HANDLE;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}  


public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bDamage || !g_bEnabled)
		return Plugin_Continue;
	new attackerId = GetEventInt(event, "attacker");
	new damage = GetEventInt(event, "dmg_health");
 
	new attacker = GetClientOfUserId(attackerId);
	
	if (attacker<=0)
	{
		return Plugin_Continue;
	}
 
	PrintHintText(attacker,"Damage : %i",damage);
	return Plugin_Continue;
}
public Action:PlayerChat(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}
	new String:saytext[191];
	GetEventString(event, "text", saytext, sizeof(saytext));
	if (g_bNextmap && !strcmp(saytext, "nextmap") || !strcmp(saytext, "nextlevel")) {
		new String:nextlevel[64];
		GetConVarString(g_NextLevel, nextlevel, 64);
		PrintToChatAll("\x4Nextmap is \x3%s\x4.",nextlevel);
	}
	else if (g_bTimeleft && !strcmp(saytext, "timeleft")) {
		PrintTimeLeft(-1);
	}
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	new userid = GetEventInt(event, "userid");
	new attacker = GetEventInt(event, "attacker");
	new uid = GetClientOfUserId(userid);
	new aid = GetClientOfUserId(attacker);
	
	if (uid == 0 || aid == 0)
	{
		return Plugin_Continue;
	}
	
	new uteam = GetClientTeam(uid);
	new ateam = GetClientTeam(aid);
	new scoreChanged = 0;
	if (uteam == ateam)
	{
	
		if (ateam == CS_TEAM_CT)
		{
			scoreChanged = 1;
			ctScore--;
		}
		else if (ateam == CS_TEAM_T)
		{
			scoreChanged = 1;
			tScore--;
		}
	}
	else
	{
		if (ateam == CS_TEAM_CT)
		{
			scoreChanged = 1;
			ctScore++;
		}
		else if (ateam == CS_TEAM_T)
		{
			scoreChanged = 1;
			tScore++;
		}	
	}
	
	if (scoreChanged == 1)
		SetScore();
		
	if (g_bBalance == true)
	{
		BalanceTeams(uid);
	}
		
	return Plugin_Continue;
}



public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled && g_bPause == true)
	{	
		// resume game
		g_bPause = false;
		g_Timelimit = CreateTimer(10.0, checkTimelimit, _, TIMER_REPEAT);
		ServerCommand("mp_restartgame 1");				
	}
	return Plugin_Continue;
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		new clients = GetClientCount2();
		if (clients <= 1)
		{
			// stop game
			g_bPause = true;
			if (g_Timelimit != INVALID_HANDLE)
			{
				KillTimer(g_Timelimit);
				g_Timelimit = INVALID_HANDLE;
			}
		}
		new userid = GetEventInt(event, "userid");
		new uid = GetClientOfUserId(userid);
		if (g_bBalance == true)
		{
			BalanceTeams2(uid, true);
		}
	}
	return Plugin_Continue;
}


public Action:jointeam(client, const String:command[], argc) 
{
	if (!g_bEnabled || !client || !IsClientInGame(client) || argc < 1)
	{
		return Plugin_Continue;
	}
	
	new SourceTEAM = GetClientTeam(client);
	new String:strCommand[5];
	GetCmdArg(1, strCommand, sizeof(strCommand));
	if(strcmp(strCommand, "1", false) == 0)
	{
		if (SourceTEAM == CS_TEAM_CT || SourceTEAM == CS_TEAM_T)
		{
			BalanceTeams2(client, true);
		}
	}
	return Plugin_Continue;
}


public Action:spectate(client, const String:command[], argc) 
{
	if (!g_bEnabled || !client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	new SourceTEAM = GetClientTeam(client);
	if (SourceTEAM == CS_TEAM_CT || SourceTEAM == CS_TEAM_T)
	{
		BalanceTeams2(client, true);
	}		

	return Plugin_Continue;
}
public Action:Timeleft(client, const String:command[], argc) 
{
	if (!g_bTimeleft)
	{
		return Plugin_Handled;
	}
	PrintTimeLeft(client);
	return Plugin_Handled;
}

public PrintTimeLeft(client)
{
	new timeleft;
	if (GetClientCount2() <= 0)
	{
		return;
	}
	else
	{
		GetMapTimeLeft(timeleft);
	}
	
	if (g_bInf)
	{
		if (client == -1)
			PrintToChatAll("\x4There is no Timelimit set.");
		else if (client == 0)
			PrintToServer("There is no Timelimit set.");
		else
			PrintToChat(client, "There is no Timelimit set.");
		return;
	}
	
	new m  = timeleft;
	new s = timeleft;
	m = s / 60;
	s = s % 60;
	if (m < 0)
	{
		m = 0;
	}
	if (s < 0)
	{
		s = 0;
	}
	if (client == -1)
		PrintToChatAll("\x4Time remaining: \x3%02d:%02d\x4.", m, s);
	else if (client == 0)
		PrintToServer("Time remaining: %02d:%02d.", m, s);
	else
		PrintToChat(client, "\x4Time remaining: \x3%02d:%02d\x4.", m, s);
}

public Action:checkTimelimit(Handle:timer)
{
	if (g_bInf == false && GetClientCount2() > 0)
	{
		new timeleft;
		GetMapTimeLeft(timeleft);
		if(g_EndRound == false && timeleft < 1)
		{
			endround();
		}
	}
	
	return Plugin_Continue;
}



public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == var_enabled)
	{
		g_bEnabled = GetConVarBool(var_enabled);
	}
	else if (convar == var_vote)
	{
		g_bVote = GetConVarBool(var_vote);
	}
	else if (convar == var_damage)
	{
		g_bDamage = GetConVarBool(var_damage);
	}
	else if (convar == var_nextmap)
	{
		g_bNextmap = GetConVarBool(var_nextmap);
	}
	else if (convar == var_timeleft)
	{
		g_bTimeleft = GetConVarBool(var_timeleft);
	}
	else if (convar == var_balance)
	{
		g_bBalance = GetConVarBool(var_balance);
	}
	else if (convar == mp_roundtime)
	{
		// server.cfg was loaded
		if (g_Timelimit != INVALID_HANDLE)
		{
			KillTimer(g_Timelimit);
			g_Timelimit = INVALID_HANDLE;
		}
		if (g_MapMenu != INVALID_HANDLE)
		{
			CloseHandle(g_MapMenu);
			g_MapMenu = INVALID_HANDLE;
		}
		
		// reinit all
		OnMapStart();
	}
}

public VoteHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public VoteResults(Handle:menu, 
			num_votes, 
			num_clients, 
			const client_info[][2], 
			num_items, 
			const item_info[][2])
{
	/* See if there were multiple winners */
	new winner = 0;
	if (num_items > 1
	    && (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES]))
	{
		winner = GetRandomInt(0, 1);
	}
 
	new String:map[255];
	GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], map, sizeof(map));
	//ServerCommand("nextlevel %s", map);
	SetConVarString(g_NextLevel, map);
}

Handle:BuildMapMenu()
{
	new mapcount = GetArraySize(g_mapList)-1;
	new Handle:menu = CreateMenu(VoteHandler);
	SetVoteResultCallback(menu, VoteResults);
	new String:mapname[255];
	new AddedMaps = 0;

	
	if (mapcount == 0)
	{
		return INVALID_HANDLE;
	}
	
	for (new i = 0; i < mapcount; i++)
	{
	
		if (AddedMaps > 6)
			break;
		
		GetArrayString(g_mapList, i, mapname, sizeof(mapname));
		if (strcmp(g_curMap, mapname) && (FindStringInArray(g_lastmaps, mapname)  == -1))
		{
			AddMenuItem(menu, mapname, mapname);
			AddedMaps++;
		}
	}
	
	while (AddedMaps < 7)
	{
		GetArrayString(g_lastmaps, 0, mapname, sizeof(mapname));
		if (strcmp(g_curMap, mapname))
		{
			AddMenuItem(menu, mapname, mapname);
			AddedMaps++;
		}
		RemoveFromArray(g_lastmaps, 0);
	}
 
	SetMenuTitle(menu, "Vote for the Nextmap!");
	return menu;
}


ExecuteCheatCommand(const String:sCmdName[])
{
    new iFlags = GetCommandFlags(sCmdName);
    SetCommandFlags(sCmdName, iFlags ^ FCVAR_CHEAT); // Remove cheat flag
    ServerCommand(sCmdName);
    new Handle:pack;
    CreateDataTimer(0.1, tmr, pack);
    WritePackCell(pack, iFlags);
    WritePackString(pack, sCmdName);
}

public Action:tmr(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    new iFlags = ReadPackCell(pack);
    decl String:sCmdName[64];
    ReadPackString(pack, sCmdName, 64);
    SetCommandFlags(sCmdName, iFlags | FCVAR_CHEAT); // Restore cheat flag
} 

public endround()
{
	g_EndRound = true;
	ExecuteCheatCommand("endround");
	if (g_bVote && g_MapMenu != INVALID_HANDLE)
	{
		new nVoteTime = GetConVarInt(FindConVar("mp_chattime"))-1;
		if (nVoteTime > 0)
			VoteMenuToAll(g_MapMenu, nVoteTime);
	}
	
	
}


// if cur map is not on maplist change to a "valid map"
public bool:SetNextLevel()
{
	new mapcount = GetArraySize(g_mapList)-1;
	new String:map[255];
	if (mapcount > 0)
	{
		for (new i = mapcount; i >= 0; i--)
		{
			GetArrayString(g_mapList, i, map, sizeof(map));
			if (!strcmp(map, g_curMap))
			{
				if (i < mapcount)
				{
					GetArrayString(g_mapList, i+1, map, sizeof(map));
				}
				else
				{
					GetArrayString(g_mapList, 0, map, sizeof(map));
				}
				SetConVarString(g_NextLevel, map);
				return true;
			}
		}
	}
	return false;
}

public RemoveStuff()
{
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (((StrContains(weapon, "weapon_") != -1) ||
				(StrContains(weapon, "item_") != -1)  ||
				(StrContains(weapon, "func_buyzone") != -1)  ||
				(StrContains(weapon, "func_bomb_target") != -1)  ||
				(StrContains(weapon, "func_escapezone") != -1)  ||
				(StrContains(weapon, "func_vip_safteyzone") != -1)  ||
				(StrContains(weapon, "func_vip_start") != -1)  ||
				(StrContains(weapon, "func_hostage_rescue") != -1)  ||
				(StrContains(weapon, "hostage_entity") != -1) || 
				(StrContains(weapon, "game_weapon_manager") != -1) || 
				(StrContains(weapon, "game_player_equip") != -1) || 
				(StrContains(weapon, "point_servercommand") != -1))
				&& (GetEntDataEnt2(i, g_WeaponParent) == -1))
			{
					RemoveEdict(i);
			}
		}
	}	
}
public BalanceTeams(uid)
{
	BalanceTeams2(uid, false);
}
public BalanceTeams2(uid, bool:disco)
{
	new cts = GetTeamClientCount(CS_TEAM_CT);
	new ts = GetTeamClientCount(CS_TEAM_T);
	if (disco == true)
	{
		if (GetClientTeam(uid) == CS_TEAM_CT)
		{
			cts--;
		}
		else if (GetClientTeam(uid) == CS_TEAM_T)
		{
			ts--;
		}
		if (cts == 2 && ts == 0)
		{
			for( new i = 1; i <= MaxClients; i++ ) 
			{
				if (i != uid && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					ChangeClientTeam(i, CS_TEAM_T);
					return;
				}
			}
		}
		else if (cts == 0 && ts == 2)
		{
			for( new i = 1; i <= MaxClients; i++ ) 
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
				{
					ChangeClientTeam(i, CS_TEAM_CT);
					return;
				}
			}
		}
	}
	else
	{
		if (cts > ts + 1)
		{
			new Handle:pack = CreateDataPack();
			WritePackCell(pack, uid);
			WritePackCell(pack, CS_TEAM_T);
			CreateTimer(0.1, Timer_ChangeClientTeam, pack);
		}
		else if (ts > cts + 1)
		{
			new Handle:pack = CreateDataPack();
			WritePackCell(pack, uid);
			WritePackCell(pack, CS_TEAM_CT);
			CreateTimer(0.1, Timer_ChangeClientTeam, pack);
		}
	}
	
}

public Action:Timer_ChangeClientTeam(Handle:timer, any:pack)
{
    ResetPack(pack);
    new client = ReadPackCell(pack);
    new team = ReadPackCell(pack);
    CloseHandle(pack);
    CS_SwitchTeam(client, team);
}

public SetScore()
{	
	Team_SetScore(CS_TEAM_CT, ctScore);
	Team_SetScore(CS_TEAM_T, tScore);
}

stock bool:Team_SetScore(index, score)
{
    new edict = Team_GetEdict(index);
    
    if (edict == -1)
	{
        return false;
    }

    SetEntProp(edict, Prop_Send, "m_iScore", score);
    ChangeEdictState(edict, GetEntSendPropOffs(edict, "m_iScore"));
    
    return true;
}

stock Team_EdictGetNum(edict)
{
    return GetEntProp(edict, Prop_Send, "m_iTeamNum");
}


stock Team_GetEdict(index)
{
    new maxEntities = GetMaxEntities();
    for (new entity=MaxClients+1; entity < maxEntities; entity++) {
        
        if (!IsValidEntity(entity)) {
            continue;
        }
        
        if (!Entity_CheckClassName(entity, "cs_team_manager", true)) {
            continue;
        }
        
        if (Team_EdictGetNum(entity) == index) {
            return entity;
        }
    }
    
    return -1;
}

stock bool:Entity_CheckClassName(entity, const String:className[], partialMatch=false)
{
    decl String:entity_className[64];
    GetEdictClassname(entity, entity_className, sizeof(entity_className));

    if (partialMatch) {
        return (StrContains(entity_className, className) != -1);
    }
    
    return StrEqual(entity_className, className);
}  
