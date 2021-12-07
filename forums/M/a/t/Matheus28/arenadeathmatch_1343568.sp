#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.7"
#define PLUGIN_PREFIX "\x04[Arena DM]\x01"
#define PLUGIN_PREFIX_NC "[Arena DM]"

#define CFG_MIN_SPAWN_TIME 0.5

#define TEAM_UNSIG 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3
#define MAX_TEAMS 4

new bool:started=false;
new Float:tickInterval;

new Handle:cv_enable;
new Handle:cv_respawn_time;
new Handle:cv_spawn_protection;
new Handle:cv_disable_cps;
new Handle:cv_frag_limit;
new Handle:cv_allcrit;
new Handle:cv_class;

new Handle:t_disableCps;
new Handle:t_announce;

new Float:respawn[MAXPLAYERS+1];
new bool:killPlayer[MAXPLAYERS+1];
new bool:allowSpawn[MAXPLAYERS+1];
new classRotation[MAXPLAYERS+1];
new fragcount[MAXPLAYERS+1];
new TFClassType:nextclass[MAXPLAYERS+1];
new bool:playing;
new bool:allcrit;

public Plugin:myinfo = {
	name = "TF2 Arena DeathMatch",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart(){
	tickInterval=GetTickInterval();
	
	ResetConVar(CreateConVar("sm_arenadm_version", PLUGIN_VERSION, "TF2 Arena DeathMatch Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), true, true);
	
	cv_enable = CreateConVar("sm_arenadm_enable", "1.0", "Enables/Disables Arena DeathMatch",
	FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookConVarChange(cv_enable, CC_Enable);
	
	cv_respawn_time = CreateConVar("sm_arenadm_respawn", "6.0", "Respawn Time",
	FCVAR_PLUGIN, true, CFG_MIN_SPAWN_TIME, true, 20.0);
	
	cv_spawn_protection = CreateConVar("sm_arenadm_spawn_protection", "3.0", "Spawn Protection duration",
	FCVAR_PLUGIN, true, 0.0, true, 10.0);
	
	cv_disable_cps = CreateConVar("sm_arenadm_disable_cps", "1.0", "Disable control points",
	FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cv_frag_limit = CreateConVar("sm_arenadm_frag_limit", "100.0", "Number of frags that a player needs to win",
	FCVAR_PLUGIN, true, 0.0, true, 500.0);
	
	cv_allcrit = CreateConVar("sm_arenadm_allcrit_chance", "10.0", "Chance that a match will be allcrit",
	FCVAR_PLUGIN, true, 0.0, true, 100.0);
	
	cv_class = CreateConVar("sm_arenadm_class", "1.0", "0 = Players can choose class; 1 = Players spawn as a random class; 2 = When a player dies, he'll spawn as the next class (not random)",
	FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	RegConsoleCmd("sm_class", Cmd_Class);
}

public StartPlugin(){
	if(started) return;
	started=true;
	
	t_disableCps = CreateTimer(5.0, Timer_DisableCps, _, TIMER_REPEAT);
	t_announce = CreateTimer(60.0, Timer_Announce, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_waiting_begins", teamplay_waiting_begins);
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
}

public StopPlugin(){
	if(!started) return;
	started=false;
	
	KillTimer(t_disableCps);
	KillTimer(t_announce);
	
	UnhookEvent("teamplay_round_start", teamplay_round_start);
	UnhookEvent("teamplay_round_win", teamplay_round_win);
	UnhookEvent("teamplay_waiting_begins", teamplay_waiting_begins);
	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("player_death", player_death);
}

public OnMapStart(){
	allcrit=false;
	playing=true;
	CheckEnable();
}

public OnClientConnected(client){
	ResetClientVars(client);
}

public OnClientDisconnected(client){
	ResetClientVars(client);
}

public OnClientPutInServer(client){
	respawn[client]=1.0;
}

public ResetClientVars(i){
	respawn[i]=0.0;
	killPlayer[i]=false;
	allowSpawn[i]=false;
	fragcount[i]=0;
	classRotation[i]=GetRandomInt(1,9);
	nextclass[i]=TFClass_Unknown;
}

public OnRoundEnd(){
	
}

public CC_Enable(Handle:convar, const String:oldValue[], const String:newValue[]){
	CheckEnable();
}

public CheckEnable(){
	if(IsArenaMap() && GetConVarBool(cv_enable)){
		StartPlugin();
	}else{
		StopPlugin();
	}
}

//////////////////////////////////////////////////////////////////////////////

public Action:Timer_DisableCps(Handle:timer){
	DisableCps();
}
public Action:Timer_Announce(Handle:timer){
	if(GetConVarInt(cv_class)!=0){
		return;
	}
	PrintToChatAll("%s Type \x03/class <class>\x01 to change your class", PLUGIN_PREFIX);
}

//////////////////////////////////////////////////////////////////////////////

public Action:Cmd_Class(client, args){
	if(!started) return Plugin_Continue;
	if(args<1){
		if(GetCmdReplySource()==SM_REPLY_TO_CHAT){
			ReplyToCommand(client, "%s Usage: \x03/class <class>\x01", PLUGIN_PREFIX);
		}else{
			ReplyToCommand(client, "%s Usage: sm_class <class>", PLUGIN_PREFIX_NC);
		}
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new TFClassType:class = TF2_GetClass(arg1);
	
	if(class==TFClass_Unknown){
		if(GetCmdReplySource()==SM_REPLY_TO_CHAT){
			ReplyToCommand(client, "%s Class not found", PLUGIN_PREFIX);
		}else{
			ReplyToCommand(client, "%s Class not found", PLUGIN_PREFIX_NC);
		}
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "%s You'll change your class when you respawn", PLUGIN_PREFIX);
	nextclass[client]=class;
	
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////////////////

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result){
	if(!allcrit) return Plugin_Continue;
	result=true;
	return Plugin_Handled;
}

public OnGameFrame(){
	if(!started) return;
	if(GetClientCount()<2) return;
	
	new rot=GetConVarInt(cv_class);
	for(new i=1;i<=MaxClients;++i){
		if(!IsValid(i)) continue;
		
		new alive=IsPlayerAlive(i);
		
		if(!alive){
			if(allowSpawn[i]){
				if(rot==2){
					++classRotation[i];
					if(classRotation[i]>9 || classRotation[i]<=0){
						classRotation[i]=1;
					}
					TF2_SetPlayerClass(i, TFClassType:classRotation[i]);
				}else if(rot==1){
					TF2_SetPlayerClass(i, TFClassType:GetRandomInt(1,9));
				}else if(nextclass[i]!=TFClass_Unknown){
					TF2_SetPlayerClass(i, nextclass[i]);
					nextclass[i]=TFClass_Unknown;
				}
				RespawnPlayer(i);
				continue;
			}
		}
		
		if(!alive && playing){
			if(IsClientSpec(i)){
				respawn[i] -= tickInterval;
				
				if(respawn[i]<=0.0){
					respawn[i]=0.0;
					allowSpawn[i]=true;
					ChangeClientTeam(i, GetAvaliableTeam());
				}
			}else{
				ChangeClientTeam(i, TEAM_SPEC);
			}
		}
		
		if(alive && allcrit){
			TF2_AddCondition(i, TFCond_Kritzkrieged, 1.0);
		}
	}
}

//////////////////////////////////////////////////////////////////////////////

public Action:teamplay_round_start(Handle:event,  const String:name[], bool:dontBroadcast) {
	playing=true;
	for(new i=1;i<=MaxClients;++i){
		ResetClientVars(i);
	}
	new fraglimit=GetConVarInt(cv_frag_limit);
	if(fraglimit>0){
		PrintToChatAll("%s Frag Limit is %d, the first player to reach it win!", PLUGIN_PREFIX, fraglimit);
	}
	
	if(GetConVarFloat(cv_allcrit)>GetRandomFloat(0.0, 100.0)){
		PrintToChatAll("%s All Crits Match! Prepare for the spamfest!", PLUGIN_PREFIX);
		allcrit=true;
	}else{
		allcrit=false;
	}
}

public Action:teamplay_round_win(Handle:event,  const String:name[], bool:dontBroadcast) {
	playing=false;
	OnRoundEnd();
}

public Action:teamplay_waiting_begins(Handle:event,  const String:name[], bool:dontBroadcast) {
	playing=false;
	OnRoundEnd();
}

public Action:player_spawn(Handle:event,  const String:name[], bool:dontBroadcast) {
	if(!playing) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!allowSpawn[client]){
		KillPlayer(client);
		PrintToChat(client, "%s You cannot respawn yet", PLUGIN_PREFIX);
		return;
	}
	allowSpawn[client]=false;
	
	new Float:dur = GetConVarFloat(cv_spawn_protection);
	if(dur>0.0){
		PrintHintText(client, "Spawn Protection for %.1f seconds", dur);
		TF2_AddCondition(client, TFCond_Ubercharged, dur);
	}
}

public Action:player_death(Handle:event,  const String:name[], bool:dontBroadcast) {
	if(!playing) return Plugin_Continue;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(killPlayer[victim]){
		killPlayer[victim]=false;
		return Plugin_Handled;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	new team=GetClientTeam(victim);
	new red=GetTeamClientCount(TEAM_RED);
	new blue=GetTeamClientCount(TEAM_BLUE);
	if(team==TEAM_RED) red-=1;
	if(team==TEAM_BLUE) blue-=1;
	
	if(red<=0 || blue<=0){
		respawn[victim] = CFG_MIN_SPAWN_TIME;
	}else{
		new Float:dur = GetConVarFloat(cv_respawn_time);
		PrintHintText(victim, "Respawning in %.1f seconds", dur);
		respawn[victim] = dur;
	}
	
	if(attacker!=victim && IsValid(attacker)){
		fragcount[attacker]+=1;
		CheckFrag(attacker);
	}
	
	if(assister!=victim && IsValid(assister)){
		fragcount[assister]+=1;
		CheckFrag(assister);
	}
	
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////////////////

stock CheckFrag(client){
	new fraglimit = GetConVarInt(cv_frag_limit);
	new myfrags=fragcount[client];
	if(fraglimit>0 && myfrags>=fraglimit){
		PrintToChatAll("%s \x03%N\x01 won this match!", PLUGIN_PREFIX, client);
		PlayerWin(client);
	}else{
		new bool:highest=true;
		
		for(new i=1;i<=MaxClients;++i){
			if(IsValid(i) && i!=client && fragcount[i]>=myfrags){
				highest=false;
			}
		}
		
		if(highest){
			PrintToChatAll("%s \x03%N\x01 is the leader with \x03%d\x01 kills!", PLUGIN_PREFIX, client, myfrags);
		}else{
			PrintToChat(client, "%s You already killed \x03%d\x01 enemies!", PLUGIN_PREFIX, myfrags);
		}
	}
}

stock PlayerWin(client){
	new team=GetClientTeam(client);
	/*
	new opTeam;
	if(team==TEAM_RED) opTeam=TEAM_BLUE;
	if(team==TEAM_BLUE) opTeam=TEAM_RED;
	
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i) && i!=client){
			teleport[i]=true;
			GetClientAbsOrigin(i, teleportPos[i]);
			GetClientEyeAngles(i, teleportAng[i]);
			KillPlayer(i);
			ChangeClientTeam(i, opTeam);
			allowSpawn[i]=true;
			noProtection[i]=true;
		}
	}*/
	
	MakeTeamWin(team);
}

stock RespawnPlayer(i){
	respawn[i]=0.0;
	allowSpawn[i]=true;
	TF2_RespawnPlayer(i);
}

stock DisableCps(){
	if(!GetConVarBool(cv_disable_cps)) return;
	
	new i = -1;
	new CP = 0;
	
	for (new n = 0; n <= 16; n++){
		CP = FindEntityByClassname(i, "trigger_capture_area");
		if(IsValidEntity(CP)){
			AcceptEntityInput(CP, "Disable");
			i = CP;
		}else{
			break;
		}
	}
}

stock MakeTeamWin(team){
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i) && GetClientTeam(i) != team && !IsClientSpec(i) && IsPlayerAlive(i)){
			KillPlayer(i);
		}
	}
	
	/*
	new ent = CreateEntityByName("game_round_win");
	if(ent>0) {
		SetVariantInt(team);
		AcceptEntityInput(ent, "SetTeam");
		AcceptEntityInput(ent, "RoundWin");
		AcceptEntityInput(ent, "kill");
	}
	
	new edict_index = FindEntityByClassname(-1, "team_control_point_master");
	if (edict_index == -1){
		new g_ctf = CreateEntityByName("team_control_point_master");
		DispatchSpawn(g_ctf);
		AcceptEntityInput(g_ctf, "Enable");
	}
	new search = FindEntityByClassname(-1, "team_control_point_master");
	SetVariantInt(team);
	AcceptEntityInput(search, "SetWinner");
	*/
}

stock GetAvaliableTeam(){
	new red=GetTeamClientCount(TEAM_RED);
	new blue=GetTeamClientCount(TEAM_BLUE);
	if(red>blue){
		return TEAM_BLUE;
	}else{
		return TEAM_RED;
	}
}
stock bool:IsClientSpec(client){
	new team=GetClientTeam(client);
	return (team==TEAM_UNSIG) || (team==TEAM_SPEC)
}
stock bool:IsArenaMap(){
	decl String:curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	return strncmp("arena_", curMap, 6, false)==0;
}

stock IsValid(client){
	if(client<=0){
		return false;
	}
	if(client>MaxClients){
		return false;
	}
	if(!IsClientConnected(client)){
		return false;
	}
	if(!IsClientInGame(client)){
		return false;
	}
	return true;
}

stock KillPlayer(i){
	if(!IsPlayerAlive(i)) return;
	killPlayer[i]=true;
	ForcePlayerSuicide(i);
}