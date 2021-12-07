#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PL_VERSION "1.1"
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;
new Handle:g_hImba = INVALID_HANDLE;
new bool:g_bImba = true;
new bool:g_arena;
new g_imba = 0;
new bool:g_spec[MAXPLAYERS+1] = {true, ...};
public Plugin:myinfo = 
{
	name = "Arena Teams",
	author = "MikeJS",
	description = "Fills teams in arena.",
	version = PL_VERSION,
	url = "http://mikejs.byethost18.com/"
};
public OnPluginStart() {
	CreateConVar("sm_arenateams_version", PL_VERSION, "Arena Teams version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_arenateams", "1", "Enable full arena teams.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hImba = CreateConVar("sm_arenateams_imba", "0", "Enable imbalancing of arena teams.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegConsoleCmd("jointeam", Command_jointeam);
	HookEvent("teamplay_round_start", Event_round_start);
	HookEvent("player_team", Event_player_team);
	HookConVarChange(g_hEnabled, Cvar_enabled);
	HookConVarChange(g_hImba, Cvar_imba);
}
public OnMapStart() {
	g_arena = true;
	if(FindEntityByClassname(MaxClients+1, "tf_logic_arena")==-1) {
		g_arena = false;
	}
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bImba = GetConVarBool(g_hImba);
}
public OnClientDisconnect(client) {
	g_spec[client] = true;
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Cvar_imba(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bImba = GetConVarBool(g_hImba);
}
public Action:Command_jointeam(client, args) {
	decl String:argstr[16];
	GetCmdArgString(argstr, sizeof(argstr));
	if(StrEqual(argstr, "spectatearena")) {
		g_spec[client] = true;
	} else {
		g_spec[client] = false;
	}
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_bEnabled && g_arena) {
		for(new i=1;i<=MaxClients;i++) {
			if(!g_spec[i] && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==1) {
				new cred = GetTeamClientCount(2);
				new cblue = GetTeamClientCount(3);
				if(cred>cblue) {
					ChangeClientTeam(i, 3);
				} else if(cblue<cred) {
					ChangeClientTeam(i, 2);
				} else if(GetTeamClientCount(1)>1) {
					ChangeClientTeam(i, GetRandomInt(2, 3));
				} else if(g_bImba) {
					if(g_imba==0) {
						new rand = GetRandomInt(2, 3);
						ChangeClientTeam(i, rand);
						g_imba = rand;
					} else if(g_imba==2) {
						ChangeClientTeam(i, 3);
						g_imba = 3;
					} else {
						ChangeClientTeam(i, 2);
						g_imba = 2;
					}
				}
			}
		}
	}
}
public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetEventInt(event, "team")>1) {
		g_spec[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
	}
}