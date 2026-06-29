#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN 
#include <autoupdate>

#define PLUGIN_VERSION "1.0.0"

new hLeaderVotes = 0;
new hPlayerReady = 0;

new Handle:cLockSkill = INVALID_HANDLE;
new bool:LockSkill = false;
new Handle:cServerCfgFix = INVALID_HANDLE;
new bool:ServerCfgFix = false;
new Handle:cImmunityLvl = INVALID_HANDLE;
new ImmunityLvl = 0;
new Handle:cLeaderLvl = INVALID_HANDLE;
new LeaderLvl = 0;
new bool:IgnoreLeaderBlock = false;

new Handle:cAswSkill = INVALID_HANDLE;
new Handle:cMmState = INVALID_HANDLE;
new MmState = 0;

new entGameRules;

public Plugin:myinfo = {
	name = "Alien Swarm Tools",
	author = "KawMAN",
	description = "Usefull tools for Alien Swarm",
	version = PLUGIN_VERSION,
	url = "http://kawman.tk/SourceMOD"
};

public OnPluginStart()
{
	//Only for Alien Swarm
	new String:game_description[64];
	GetGameDescription(game_description, sizeof(game_description), true);
	if (StrContains(game_description, "Alien Swarm", false) == -1) {
		new String:game_folder[128];
		GetGameFolderName(game_folder, sizeof(game_folder));
		if (StrContains(game_folder, "swarm", false) == -1) {
			SetFailState("Plugin for Alien Swarm only [%s-%s]", game_description,game_folder);
		}
	}
	
	//Offset
	hLeaderVotes = FindSendPropInfo("CASW_Game_Resource", "m_iLeaderVotes");
	hPlayerReady = FindSendPropInfo("CASW_Game_Resource", "m_bPlayerReady");
	if (hLeaderVotes <= 0||hPlayerReady <= 0) {
		SetFailState("* FATAL ERROR: Failed to get some offset");
	}
	entGameRules = _FindEntityByClassname(MaxClients, "asw_game_resource");
	
	MarkNativeAsOptional("AutoUpdate_AddPlugin");
	MarkNativeAsOptional("AutoUpdate_RemovePlugin");
	
	//Load Languages
	LoadTranslations("common.phrases");
	
	//Commands
	RegAdminCmd("sm_setleader", cmdSetLeader, ADMFLAG_GENERIC, "Set Lobby Leader");
	RegAdminCmd("sm_setready", cmdSetReady, ADMFLAG_GENERIC, "Set player Ready state");
	
	//Cvars
	cLockSkill = CreateConVar("sm_lock_difficulty", "0", "Lock difficulty (skill) on state, 0=Off 1-4=Lock on this state", FCVAR_PLUGIN,true,0.0,true,4.0); 
	cServerCfgFix = CreateConVar("sm_servercfg_fix", "0", "Execute server.cfg every map start", FCVAR_PLUGIN,true,0.0,true,1.0); 
	cImmunityLvl = CreateConVar("sm_as_kick_immunity", "10", "Block possibility to kick players with >= immunty lvl, 0=off", FCVAR_PLUGIN); 
	cLeaderLvl = CreateConVar("sm_disable_leadervote", "-1", "-1 -Enable Leader Vote, 0 -Diable Leader Vote, >0 -Disable if leader have immunity equal or higer than this", FCVAR_PLUGIN); 
	
	AutoExecConfig(true, "alienswarm_tools");
	
	cAswSkill = FindConVar("asw_skill");
	cMmState = FindConVar("mm_swarm_state");
	
	//Commands hook
	AddCommandListener(cmdClSkill, "cl_skill");
	AddCommandListener(cmdClKick, "cl_kickvote");
	AddCommandListener(cmdClLeader, "cl_leadervote");
	
	//Hooks
	HookConVarChange(cLockSkill, MyCVARChange);
	HookConVarChange(cAswSkill, MyCVARChange);
	HookConVarChange(cMmState, MyCVARChange);
	HookConVarChange(cServerCfgFix, MyCVARChange);
	HookConVarChange(cImmunityLvl, MyCVARChange);
	HookConVarChange(cLeaderLvl, MyCVARChange);
	
	UpdateState();
}

public OnAllPluginsLoaded() { 
	if(LibraryExists("pluginautoupdate")) { 
			AutoUpdate_AddPlugin("kawman.tk", "/SourceMOD/astools.xml", PLUGIN_VERSION);
	} 
}

public OnPluginEnd() { 
	if(LibraryExists("pluginautoupdate")) { 
		AutoUpdate_RemovePlugin(); 
	} 
}

public MyCVARChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl oldVal, newVal;
	oldVal = StringToInt(oldValue);
	newVal = StringToInt(newValue);
	if(convar==cLockSkill) {
		if(oldVal != newVal) {
			if(newVal>=0 && newVal<=4) {
				SetupSkill(newVal);
			} else {
				SetConVarString(convar,oldValue);
			}
		}
	}
	else if(convar==cAswSkill) {
		if(LockSkill) {
			LockSkill = false;
			SetConVarString(cAswSkill,newValue);
			LockSkill = true;
		}
	}
	else if(convar==cMmState) {
		if(newValue[0]=='i') { //ingame
			MmState = 0;
		}
		else if(newValue[0]=='b') { //birefing
			MmState = 1;
		}
	}
	else if(convar==cServerCfgFix) {
		ServerCfgFix = GetConVarBool(cServerCfgFix);
	}
	else if(convar==cImmunityLvl) {
		ImmunityLvl = GetConVarInt(cImmunityLvl);
	}
	else if(convar==cLeaderLvl) {
		LeaderLvl = GetConVarInt(cLeaderLvl);
	}
}

public Action:DelayedMapStart(Handle:timer, any:client)
{
	decl Handle:cvar, String:tmp[16];
	cvar = FindConVar("sm_astools");
	if(cvar != INVALID_HANDLE) {
		GetConVarString(cvar, tmp, sizeof(tmp));
		SetConVarString(cvar, tmp, false, false);
		CloseHandle(cvar);
	} else {
		CreateConVar("sm_astools", PLUGIN_VERSION, "Alien Swarm tools version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	}
}

public OnMapStart()
{
	entGameRules = _FindEntityByClassname(MaxClients, "asw_game_resource");
	CreateTimer(5.0, DelayedMapStart);
	
	if(ServerCfgFix) {
		ServerCommand("exec server.cfg");
	}
}

//------------------------------------ COMMANDS ---------------------------------------//
public Action:cmdSetReady(client, args)
{
	if(MmState!=1) {
		ReplyToCommand(client,"Command available only when briefing or debriefing");
		return Plugin_Handled;
	}
	if(args==0) { //Simple switch 
		if(client==0) {
			ReplyToCommand(client,"Wrong Server Console syntax. sm_setready <1|0> <#userid|name|partname>");
			return Plugin_Handled;
		}
		FakeClientCommand(client, "cl_ready", client);
	}
	else if(args>=1) {
		decl String:StrArg[64],tostate;
		GetCmdArg(1, StrArg, sizeof(StrArg));
		
		if(StrArg[0]=='1') {
			tostate = 1;
		}
		else if(StrArg[0]=='0') {
			tostate = 0;
		}
		else if(StrArg[0]=='-') {
			tostate = -1;
		}
		else {
			ReplyToCommand(client,"Wrong syntax. sm_setready [-|1|0] [#userid|name|partname]");
			return Plugin_Handled;
		}
		
		if(args==1) {
			SetClientReady(client, tostate);
			return Plugin_Handled;
		}
		
		GetCmdArg(2, StrArg, sizeof(StrArg));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(
				StrArg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (new i = 0; i < target_count; i++)
		{
			SetClientReady(target_list[i], tostate);
		}
	}
	
	return Plugin_Handled;
}

public Action:cmdSetLeader(client, args)
{
	decl val;
	if(args<0||args>1) {
		ReplyToCommand(client,"sm_setleader [#userid|name|partname]");
		return Plugin_Handled;
	}
	if(args==1) {
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml);
		
		if(target_count!=1) {
			ReplyToCommand(client,"None or more than one match");
			return Plugin_Handled;
		}
		
		val = MakeLeader(target_list[0]);

	} 
	else if(args==0) {
		val = MakeLeader(client);
	}
	
	if(val==-1) {
		ReplyToCommand(client, "Can't find required enitity");
	}
	else if(val==0) {
		ReplyToCommand(client, "Selected player is already leader");
	}
	
	return Plugin_Handled;
}



public Action:cmdClSkill(client, const String:command[], argc) {
	if(LockSkill) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:cmdClKick(client, const String:command[], argc) {
	if(ImmunityLvl>0) {
		decl String:StrArg[64], newVal, AdminId:targetadm;
		GetCmdArg(1, StrArg, sizeof(StrArg));
		newVal = StringToInt(StrArg);
		if(newVal>0) { //cl_kickvote -1 = unselect
			targetadm = GetUserAdmin(newVal);
			newVal = GetAdminImmunityLevel(targetadm);
			if(newVal>=ImmunityLvl) {
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:cmdClLeader(client, const String:command[], argc) {
	if(IgnoreLeaderBlock) {
		return Plugin_Continue;
	}
	if(LeaderLvl==0) {
		return Plugin_Handled;
	}
	decl leader;
	leader = GetEntProp(entGameRules, Prop_Send, "m_iLeaderIndex");
	if(leader!=0&&IsClientConnected(leader)&&LeaderLvl>0) {
		decl AdminId:targetadm, newVal;
		targetadm = GetUserAdmin(leader);
		if(targetadm!=INVALID_ADMIN_ID) { 
			newVal = GetAdminImmunityLevel(targetadm);
			if(newVal>=LeaderLvl) {
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

//------------------------------------ FUNCTIONS ---------------------------------------//
/*PrintReadyList() {
	decl ready;
	if(entGameRules == -1) {
		return -2;
	}
	for (new i = 0; i<=7; i++) {
		ready = GetEntData(entGameRules, hPlayerReady + i,1);
		PrintToServer("READY for %d %d", i, ready);
	}
	return 1;
}
*/
SetClientReady(client, tostate=-1) {
	//hPlayerReady = CASW_Game_Resource::m_bPlayerReady
	decl ready;
	if(entGameRules == -1) {
		return -2;
	}
	
	ready = GetEntData(entGameRules, hPlayerReady + (client-1),1);
	if(tostate==-1) {
		if(ready!=1) {
			SetEntData(entGameRules, hPlayerReady + (client-1), 1, 1, true);
			return 1;
		} else {
			SetEntData(entGameRules, hPlayerReady + (client-1), 0, 1, true);
			return 0;
		}
	}
	else if(tostate==1&&ready==0) {
		SetEntData(entGameRules, hPlayerReady + (client-1), 1, 1, true);
		return 1;
	}
	else if(tostate==0&&ready==1) {
		SetEntData(entGameRules, hPlayerReady + (client-1), 0, 1, true);
		return 0;
	}
	return -1;
}

SetupSkill( mystate = 0 ) { //0 = Unlock, 1-4 = lock on state

	if(mystate<0) mystate=0;
	if(mystate>4) mystate=4;
	
	if(mystate==0) {
		LockSkill = false;
	}
	else {
		SetConVarInt(cAswSkill, mystate);
		LockSkill = true;
	}
}

MakeLeader(client) {
	decl val;

	if(entGameRules == -1) {
		return -1;
	}
	
	if(client==0||!IsClientInGame(client)||IsFakeClient(client)) return 0;
	
	val = GetEntProp(entGameRules, Prop_Send, "m_iLeaderIndex");
	if(val==client) return 0;
	
	val = 0;
	for(new i = 1 ; i<=MaxClients; i++) {
		if(client==i) continue;
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;
		SetEntProp(i,Prop_Send,"m_iLeaderVoteIndex", client);
		val++;
	}
	//Slien Votes
	SetEntData(entGameRules, hLeaderVotes + ((client-1)*4),val, _ ,true);
	
	//Last Vote must be 'Noise'
	IgnoreLeaderBlock = true;
	FakeClientCommand(client, "cl_leadervote %d", client);
	IgnoreLeaderBlock = false;
	
	SetEntProp(entGameRules, Prop_Send, "m_iLeaderIndex", client);
	return 1;
}

UpdateState() {
	decl newVal,String:StrArg[64];
	newVal = GetConVarInt(cLockSkill);
	SetupSkill(newVal);
	
	GetConVarString(cMmState,StrArg, sizeof(StrArg));
	if(StrArg[0]=='i') { //ingame
		MmState = 0;
	}
	else if(StrArg[0]=='b') { //birefing
		MmState = 1;
	}
	ServerCfgFix = GetConVarBool(cServerCfgFix);
	ImmunityLvl = GetConVarInt(cImmunityLvl);
	LeaderLvl = GetConVarInt(cLeaderLvl);
}

//SourceMOD funciton not working, yet
_FindEntityByClassname(startEnt=0, String:classname2[], bool:caseSens=true) {
	decl t, String:classname[64];
	t = GetMaxEntities();
	for(new i = startEnt; i<=t;i++) {
		if(!IsValidEdict(i)) continue;
		GetEdictClassname(i, classname, sizeof(classname));
		if(StrEqual(classname,classname2, caseSens)) {
			return i;
		}
	}
	return -1;
}
