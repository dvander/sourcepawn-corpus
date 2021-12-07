#pragma semicolon 1

#include <admin>
#include <sourcemod>
#include <sdktools>
#include <console>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "3.0"
#define PLUGIN_PREFIX "\x04[LCS]\x01"

#define BLOCK_TIME 600.0
#define INITIAL_SKILL_DURATION 90.0
#define TICK_TIME 10.0
#define DEFAULT_SKILL_DURATION 120.0

#define CP_SKILL 15

public Plugin:myinfo = 
{
	name = "Limit Class by Skill",
	author = "Matheus28",
	description = "Players must have at least some skill to play certain classes",
	version = PLUGIN_VERSION,
	url = ""
}

new bool:started=false;
new skill[MAXPLAYERS+1][10];
new mSkill[MAXPLAYERS+1]={0};

new bool:resetSkill[MAXPLAYERS+1]={false};
new bool:block[MAXPLAYERS+1][10];
new bool:inCp[MAXPLAYERS+1];
new Handle:tickTimer;

new bool:inSetup=false;
new bool:playing=true;
new setupTime=0;

new String:lastPlayerAuth[32];
new bool:lastPlayerBlock[10];
new lastPlayerSkill[10];

new Handle:cv_enable;
new Handle:cv_print;
new Handle:cv_default;
new Handle:cv_minplayers;

new Handle:cv_sniper;
new Handle:cv_spy;

new Handle:cv_sniper_max;
new Handle:cv_spy_max;

public OnPluginStart(){
	CreateConVar("sm_limitskill_version",
	PLUGIN_VERSION, "Limit Class by Skill Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY,
	true, StringToFloat(PLUGIN_VERSION), true, StringToFloat(PLUGIN_VERSION));
	
	cv_enable	=	CreateConVar("sm_limitskill_enable",
	"1",	"Enable (1) or Disable (0) Limit Class by Skill.",
	FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cv_enable, OnEnableChange);
	
	cv_print	=	CreateConVar("sm_limitskill_print",
	"1",	"Print skill level to clients.",
	FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_default	=	CreateConVar("sm_limitskill_default",
	"7",	"Class to switch players to when they get blocked from using another class (1 = Scout, 2 = Soldier, etc.)",
	FCVAR_PLUGIN | FCVAR_NOTIFY, true, 1.0, true, 9.0);
	
	cv_minplayers=	CreateConVar("sm_limitskill_minplayers",
	"8",	"Minimum number players to start blocking classes.",
	FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0);
	
	cv_sniper	=	CreateConVar("sm_limitskill_sniper",	"0",
	"Skill needed to use sniper",	FCVAR_PLUGIN | FCVAR_NOTIFY, true);
	
	cv_spy		=	CreateConVar("sm_limitskill_spy",		"0",
	"Skill needed to use spy",		FCVAR_PLUGIN | FCVAR_NOTIFY, true);
	
	cv_sniper_max	=	CreateConVar("sm_limitskill_sniper_max",		
	"0", "Maximum number of snipers in one team before start blocking them",
	FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0);
	
	cv_spy_max		=	CreateConVar("sm_limitskill_spy_max",		
	"0", "Maximum number of spies in one team before start blocking them",
	FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0);
	
	
	StartPlugin();
}

public StartPlugin(){
	if(started) return;
	started=true;
	
	for(new i=1;i<=MaxClients;++i){
		ResetClientVars(i);
		if(IsValid(i)){
			ResetSkill(i);
		}
	}
	
	OnMapStart();
	
	SetConVarInt(FindConVar("mp_restartround"),1);
	PrintToChatAll("%s Starting Plugin...", PLUGIN_PREFIX);
	
	tickTimer=CreateTimer(TICK_TIME, Timer_Tick, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_setup_finished", teamplay_setup_finished);
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	HookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	HookEvent("object_destroyed", object_destroyed);
	HookEvent("teamplay_flag_event", teamplay_flag_event);
	HookEvent("teamplay_capture_blocked", teamplay_capture_blocked);
	HookEvent("teamplay_point_captured", teamplay_point_captured);
	HookEvent("controlpoint_starttouch", controlpoint_starttouch);
	HookEvent("controlpoint_endtouch", controlpoint_endtouch);
	
	
}
public StopPlugin(){
	if(!started) return;
	started=false;
	
	KillTimer(tickTimer);
	
	UnhookEvent("teamplay_round_start", teamplay_round_start);
	UnhookEvent("teamplay_round_active", teamplay_round_active);
	UnhookEvent("teamplay_round_win", teamplay_round_win);
	UnhookEvent("teamplay_setup_finished", teamplay_setup_finished);
	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("player_death", player_death);
	UnhookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	UnhookEvent("object_destroyed", object_destroyed);
	UnhookEvent("teamplay_flag_event", teamplay_flag_event);
	UnhookEvent("teamplay_capture_blocked", teamplay_capture_blocked);
	UnhookEvent("teamplay_point_captured", teamplay_point_captured);
	UnhookEvent("controlpoint_starttouch", controlpoint_starttouch);
	UnhookEvent("controlpoint_endtouch", controlpoint_endtouch);
	
	
}

public OnEnableChange(Handle:cvar, const String:oldVal[], const String:newVal[]){
	if(StringToInt(newVal)>0){
		StartPlugin();
	}else{
		StopPlugin();
	}
}

public ResetClientVars(i){
	for(new j=0;j<10;++j){
		block[i][j]=false;
	}
	for(new j=0;j<10;++j){
		skill[i][j]=0;
	}
	mSkill[i]=0;
	resetSkill[i]=true;
	inCp[i]=false;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen){
	ResetClientVars(client);
	
	return true;
}

public OnClientAuthorized(client, const String:auth[]){
	if(StrEqual(auth, lastPlayerAuth)){
		block[client]=lastPlayerBlock;
		skill[client]=lastPlayerSkill;
	}
}

public OnClientDisconnect(client){
	GetClientAuthString(client, lastPlayerAuth, sizeof(lastPlayerAuth));
	lastPlayerBlock=block[client];
	lastPlayerSkill=skill[client];
	ResetClientVars(client);
}

public OnMapStart(){
	inSetup=false;
	playing=false;
	CalculateSetupTime();
}

public OnMapEnd(){
	lastPlayerAuth="";
}

public Action:Timer_Tick(Handle:timer){
	if(!inSetup){
		for(new i=1;i<=MaxClients;++i){
			if(IsValid(i) && IsPlayerAlive(i)){
				new class=ClassTypeToId(TF2_GetPlayerClass(i));
				//skill[i][class]-=1;
				if(skill[i][class]<0){
					skill[i][class]=0;
				}
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////

public Action:teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast){
	CalculateSetupTime();
	playing=false;
}

public Action:teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast){
	playing=true;
	CalculateSetupTime();
	if(setupTime > 0){
		inSetup=true;
	}else{
		inSetup=false;
	}
}

public Action:teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast){
	playing=false;
}

public Action:teamplay_setup_finished(Handle:event,  const String:name[], bool:dontBroadcast) {
    inSetup=false;
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new TFClassType:class=TF2_GetPlayerClass(client);
	
	OnExitCp(client);
	
	if(block[client][class]){
		TF2_SetPlayerClass(client, GetConvarTFClass(cv_default));
		TF2_RespawnPlayer(client);
		return;
	}
	
	if(resetSkill[client]){
		ResetSkill(client);
	}
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(!playing) return;
	
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class=TF2_GetPlayerClass(client);
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister=GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(GetEventBool(event, "feign_death")) return;
	
	if(GetSkill(client)<GetClassDefaultSkill(class) && CanBlock(client)){
		BlockClass(client, class);
		PrintToChat(client, "%s You can't use this class for some minutes because you aren't good enough with it.", PLUGIN_PREFIX);
		TF2_SetPlayerClass(client, GetConvarTFClass(cv_default));
		
		OnExitCp(client);
	}
	
	if(IsValid(attacker) && attacker != client){
		AddSkill(attacker, 5);
		if(GetEventBool(event, "dominated")){
			AddSkill(attacker, 6);
		}
	}
	
	if(IsValid(assister) && assister != client){
		if(TF2_GetPlayerClass(assister)==TFClass_Medic){
			AddSkill(assister, 5);
		}else{
			AddSkill(assister, 4);
		}
		if(GetEventBool(event, "assister_dominated")){
			AddSkill(attacker, 6);
		}
	}
	
}

public Action:player_changeclass(Handle:event, const String:name[], bool:dontBroadcast){
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new TFClassType:class=ClassIdToType(GetClientOfUserId(GetEventInt(event,"class")));
	
	if(block[client][class]){
		PrintToChat(client, "%s You can't use this class for some minutes because you aren't good enough with it.", PLUGIN_PREFIX);
		TF2_SetPlayerClass(client, GetConvarTFClass(cv_default));
		return Plugin_Stop;
	}
	
	resetSkill[client]=true;
	return Plugin_Continue;
}

public Action:object_destroyed(Handle:event, const String:name[], bool:dontBroadcast){
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister=GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(IsValid(attacker)){
		AddSkill(attacker, 5);
	}
	
	if(IsValid(assister)){
		if(TF2_GetPlayerClass(assister)==TFClass_Medic){
			AddSkill(assister, 5);
		}else if(TF2_GetPlayerClass(assister)==TFClass_Spy){
			AddSkill(assister, 5);
		}else{
			AddSkill(assister, 5);
		}
	}
}

public Action:teamplay_flag_event(Handle:event, const String:name[], bool:dontBroadcast){
	new eventtype=GetEventInt(event, "eventtype");
	new carrier=GetClientOfUserId(GetEventInt(event,"carrier"));
	new player=GetClientOfUserId(GetEventInt(event,"player"));
	
	
	if(eventtype==TF_FLAGEVENT_CAPTURED && IsValid(carrier)){
		AddSkill(carrier, 15);
	}
	if(eventtype==TF_FLAGEVENT_DEFENDED && IsValid(player)){
		AddSkill(player, 5);
	}
}

public Action:teamplay_capture_blocked(Handle:event, const String:name[], bool:dontBroadcast){
	new blocker=GetClientOfUserId(GetEventInt(event,"blocker"));
	if(IsValid(blocker)){
		AddSkill(blocker, 2);
	}
}

public Action:teamplay_point_captured(Handle:event, const String:name[], bool:dontBroadcast){
	AddSkillToTeam(GetEventInt(event, "team"), 10);
}


public Action:controlpoint_starttouch(Handle:event, const String:name[], bool:dontBroadcast){
	new client=GetEventInt(event, "player");
	if(!IsValid(client)) return;
	OnEnterCp(client);
}

public Action:controlpoint_endtouch(Handle:event, const String:name[], bool:dontBroadcast){
	new client=GetEventInt(event, "player");
	if(!IsValid(client)) return;
	if(!inCp[client]) return;
	inCp[client]=false;
	
}


///////////////////////////////////////////////////////////////////////////////

stock OnEnterCp(client){
	if(inCp[client]) return;
	inCp[client]=true;
	AddSkill(client, CP_SKILL, 0.0);
}

stock OnExitCp(client){
	if(!inCp[client]) return;
	inCp[client]=false;
	new Handle:pack;
	CreateDataTimer(0.5, Timer_RemoveSkill, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, GetClientUserId(client));
	WritePackCell(pack, CP_SKILL);
	WritePackCell(pack, ClassTypeToId(TF2_GetPlayerClass(client)));
}

stock bool:CanBlock(client){
	if(!IsValid(client)) return false;
	if(GetClientCount()<GetConVarInt(cv_minplayers)) return false;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if(GetClassTeamCount(GetClientTeam(client), class)<=GetClassLimit(class)) return false;
	if(GetClassDefaultSkill(TF2_GetPlayerClass(client))<=0) return false;
	new AdminId:useradmin=GetUserAdmin(client);
	if(GetAdminFlag(useradmin,Admin_Reservation) || GetAdminFlag(useradmin,Admin_Root)) return false;
	return true;
}

stock PrintSkill(client){
	if(!GetConVarBool(cv_print)) return;
	new class=ClassTypeToId(TF2_GetPlayerClass(client));
	if(CanBlock(client)){
		new limit=GetClassDefaultSkill(TF2_GetPlayerClass(client));
		PrintToChat(client, "%s \x03Skill: %d/%d", PLUGIN_PREFIX, skill[client][class], limit);
	}else{
		PrintToChat(client, "%s \x03Skill: %d", PLUGIN_PREFIX, skill[client][class]);
	}
}

stock ResetSkill(client){
	new TFClassType:class=TF2_GetPlayerClass(client);
	mSkill[client]=0;
	new Float:duration = INITIAL_SKILL_DURATION;
	if(!playing || inSetup){
		duration+=float(setupTime);
	}
	AddMinimumSkill(client, GetClassDefaultSkill(class), duration);
}

stock GetSkill(client){
	new class=ClassTypeToId(TF2_GetPlayerClass(client));
	if(skill[client][class]>mSkill[client]){
		return skill[client][class];
	}else{
		return mSkill[client];
	}
}

stock AddSkillToTeam(team, n, Float:duration=DEFAULT_SKILL_DURATION, bool:show=true){
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i) && GetClientTeam(i)==team){
			AddSkill(i, n, duration, show);
		}
	}
}

stock RemoveSkill(client, n, Float:duration=DEFAULT_SKILL_DURATION, bool:show=true){
	AddSkill(client, -n, duration, show);
}

stock AddSkill(client, n, Float:duration=DEFAULT_SKILL_DURATION, bool:show=true){
	if(!IsValid(client)) return;
	
	new class=ClassTypeToId(TF2_GetPlayerClass(client));
	new userid=GetClientUserId(client);
	skill[client][class]+=n;
	if(skill[client][class]<0){
		skill[client][class]=0;
	}
	
	if(show){
		PrintSkill(client);
	}
	
	if(duration>0.0){
		new Handle:pack;
		CreateDataTimer(duration, Timer_RemoveSkill, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, userid);
		WritePackCell(pack, n);
		WritePackCell(pack, class);
	}
}

public Action:Timer_RemoveSkill(Handle:timer, Handle:pack){
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new userid = ReadPackCell(pack);
	new n = ReadPackCell(pack);
	new TFClassType:class = ClassIdToType(ReadPackCell(pack));
	
	if(!IsValid(client)){
		return;
	}
	if(GetClientUserId(client)!=userid){
		return;
	}
	new classn=ClassTypeToId(class);
	skill[client][classn]-=n;
	if(skill[client][classn]<0){
		skill[client][classn]=0;
	}
}

stock AddMinimumSkill(client, n, Float:duration=0.0){
	if(!IsValid(client)) return;
	new userid=GetClientUserId(client);
	mSkill[client]+=n;
	if(mSkill[client]<0){
		mSkill[client]=0;
	}
	
	if(duration>0.0){
		new Handle:pack;
		CreateDataTimer(duration, Timer_RemoveMinimumSkill, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, userid);
		WritePackCell(pack, n);
		WritePackCell(pack, ClassTypeToId(TF2_GetPlayerClass(client)));
	}
}

public Action:Timer_RemoveMinimumSkill(Handle:timer, Handle:pack){
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new userid = ReadPackCell(pack);
	new n = ReadPackCell(pack);
	new TFClassType:class = ClassIdToType(ReadPackCell(pack));
	
	if(!IsValid(client)){
		return;
	}
	if(GetClientUserId(client)!=userid){
		return;
	}
	if(class!=TF2_GetPlayerClass(client)){
		return;
	}
	
	mSkill[client]-=n;
	if(mSkill[client]<0){
		mSkill[client]=0;
	}
}
stock BlockClass(client, TFClassType:class){
	if(!IsValid(client)) return;
	block[client][class]=true;
	
	new userid=GetClientUserId(client);
	new Handle:pack;
	CreateDataTimer(BLOCK_TIME, Timer_RemoveSkill, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, userid);
	WritePackCell(pack, ClassTypeToId(class));
}

public Action:Timer_UnBlockClass(Handle:timer, Handle:pack){
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new userid = ReadPackCell(pack);
	new TFClassType:class = ClassIdToType(ReadPackCell(pack));
	
	if(!IsValid(client)){
		return;
	}
	if(GetClientUserId(client)!=userid){
		return;
	}
	
	block[client][class]=false;
	skill[client][class]=0;
}

stock TFClassType:GetConvarTFClass(Handle:cv){
	return ClassNumToType(GetConVarInt(cv));
}

stock TFClassType:ClassNumToType(n){
	switch(n){
		case 1:{ return TFClass_Scout;}
		case 2:{ return TFClass_Soldier;}
		case 3:{ return TFClass_Pyro;}
		case 4:{ return TFClass_DemoMan;}
		case 5:{ return TFClass_Heavy;}
		case 6:{ return TFClass_Engineer;}
		case 7:{ return TFClass_Medic;}
		case 8:{ return TFClass_Sniper;}
		case 9:{ return TFClass_Spy;}
	}
	return TFClass_Unknown;
}

stock TFClassType:ClassIdToType(n){
	return TFClassType:n;
}

stock ClassTypeToId(TFClassType:class){
	return _:class;
}

stock GetClassDefaultSkill(TFClassType:class){
	switch(class){
		case TFClass_Sniper:{return GetConVarInt(cv_sniper);}
		case TFClass_Spy:{return GetConVarInt(cv_spy);}
	}
	return 0;
}

stock GetClassLimit(TFClassType:class){
	switch(class){
		case TFClass_Sniper:{return GetConVarInt(cv_sniper_max);}
		case TFClass_Spy:{return GetConVarInt(cv_spy_max);}
	}
	return 0;
}

stock GetClassTeamCount(team,TFClassType:class){
	new count=0;
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i)&&GetClientTeam(i)==team&&TF2_GetPlayerClass(i)==class){
			++count;
		}
	}
	return count;
}

stock CalculateSetupTime(){
	new m_nSetupTimeLength = FindSendPropOffs("CTeamRoundTimer", "m_nSetupTimeLength");    
	new i = -1;
	new team_round_timer = FindEntityByClassname(i, "team_round_timer");
	if (IsValidEntity(team_round_timer)){
		setupTime = GetEntData(team_round_timer,m_nSetupTimeLength);
	}
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

//