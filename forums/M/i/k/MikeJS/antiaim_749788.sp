#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PL_VERSION "1.3"
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;
new Handle:g_hSnap = INVALID_HANDLE;
new Float:g_fSnap;
new Handle:g_hIrc = INVALID_HANDLE;
new g_iIrc = 0;
new Handle:g_hLog = INVALID_HANDLE;
new String:g_sLog[128];
new g_iWarn[MAXPLAYERS+1];
new bool:g_bCheck[MAXPLAYERS+1];
new Float:g_vOldAng[MAXPLAYERS+1][3];
public Plugin:myinfo =
{
	name = "AntiAim",
	author = "Mike", 
	description = "Helps block the more obvious aimbots.",
	version = PL_VERSION,
	url = "http://mikejs.byethost18.com/"
};
public OnPluginStart() {
	CreateConVar("sm_antiaim_version", PL_VERSION, "AntiAim version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_antiaim", "1", "Enable/disable AntiAim.", FCVAR_PLUGIN);
	g_hSnap = CreateConVar("sm_antiaim_snap", "60.0", "Snap distance for a warning.", FCVAR_PLUGIN);
	g_hIrc = CreateConVar("sm_antiaim_irc", "0", "Enable/disable IRC Relay support.", FCVAR_PLUGIN);
	g_hLog = CreateConVar("sm_antiaim_log", "logs/antiaim.txt", "Enable/disable logging or choose log file.", FCVAR_PLUGIN);
	RegAdminCmd("sm_antiaim_list", Command_list, ADMFLAG_KICK, "Print AntiAim stats.");
	RegConsoleCmd("say", Command_say);
	HookEvent("player_death", Event_player_death);
	HookEvent("player_spawn", Event_player_spawn);
	HookConVarChange(g_hEnabled, Cvar_enabled);
	HookConVarChange(g_hSnap, Cvar_snap);
	HookConVarChange(g_hIrc, Cvar_irc);
	HookConVarChange(g_hLog, Cvar_log);
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fSnap = GetConVarFloat(g_hSnap);
	g_iIrc = GetConVarInt(g_hIrc);
	GetConVarString(g_hLog, g_sLog, sizeof(g_sLog));
	if(!StrEqual(g_sLog, "0") && !StrEqual(g_sLog, "1")) {
		BuildPath(Path_SM, g_sLog, sizeof(g_sLog), g_sLog);
	}
	for(new i=0;i<=MaxClients;i++) {
		g_iWarn[i] = 0;
		for(new j=0;j<3;j++) {
			g_vOldAng[i][j] = 0.0;
		}
	}
}
public OnGameFrame() {
	if(g_bEnabled) {
		decl Float:vAng[3];
		decl Float:vNewAng[3];
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)) {
				if(IsPlayerAlive(i)) {
					GetClientEyeAngles(i, vAng);
					for(new j=0;j<3;j++) {
						vAng[j] = FloatAbs(vAng[j]);
					}
					if(g_bCheck[i]) {
						SubtractVectors(vAng, g_vOldAng[i], vNewAng);
						new Float:snap = FloatAbs(vNewAng[0])+FloatAbs(vNewAng[1]);
						if(snap>g_fSnap) {
							g_iWarn[i]++;
							decl String:steamid[32];
							decl String:wpn[64];
							GetClientAuthString(i, steamid, sizeof(steamid));
							GetClientWeapon(i, wpn, sizeof(wpn));
							PrintToServer("[SM] Possible aimbot: %N (%s) [%i]", i, steamid, g_iWarn[i]);
							PrintToServer("     snap dist: %.2f (max %.2f)", snap, g_fSnap);
							PrintToServer("     weapon: %s", wpn);
							for(new j=1;j<=MaxClients;j++) {
								if(IsClientInGame(j) && GetUserAdmin(j)!=INVALID_ADMIN_ID) {
									PrintToChat(j, "\x01[SM] Possible aimbot: %N (%s) [\x04%i\x01]", i, steamid, g_iWarn[i]);
									PrintToChat(j, "\x01         snap dist: \x04%.2f\x01 (max %.2f)", snap, g_fSnap);
									PrintToChat(j, "\x01         weapon: \x04%s", wpn);
								}
							}
							if(g_iIrc>0) {
								ServerCommand("say %sPossible aimbot: %N (%s) [%i] - snap dist: %.2f (max %.2f) - weapon: %s", g_iIrc==1?"/irc ":"", i, steamid, g_iWarn[i], snap, g_fSnap, wpn);
							}
							if(!StrEqual(g_sLog, "0")) {
								if(StrEqual(g_sLog, "1")) {
									LogMessage("Possible aimbot: %N (%s) [%i] - snap dist: %.2f (max %.2f) - weapon: %s", i, steamid, g_iWarn[i], snap, g_fSnap, wpn);
								} else {
									LogToFileEx(g_sLog, "Possible aimbot: %N (%s) [%i] - snap dist: %.2f (max %.2f) - weapon: %s", i, steamid, g_iWarn[i], snap, g_fSnap, wpn);
								}
							}
						}
					}
					g_vOldAng[i] = vAng;
				}
			}
		}
	}
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Cvar_snap(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fSnap = GetConVarFloat(g_hSnap);
}
public Cvar_irc(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iIrc = GetConVarInt(g_hIrc);
}
public Cvar_log(Handle:convar, const String:oldValue[], const String:newValue[]) {
	GetConVarString(g_hLog, g_sLog, sizeof(g_sLog));
	if(!StrEqual(g_sLog, "0") && !StrEqual(g_sLog, "1")) {
		BuildPath(Path_SM, g_sLog, sizeof(g_sLog), g_sLog);
	}
}
public Action:Command_list(client, args) {
	decl String:steamid[32];
	for(new i=1;i<=MaxClients;i++) {
		if(g_iWarn[i]>0) {
			GetClientAuthString(i, steamid, sizeof(steamid));
			ReplyToCommand(client, "%N (%s): %i", i, steamid, g_iWarn[i]);
		}
	}
	return Plugin_Handled;
}
public Action:Command_say(client, args) {
	if(client>0) {
		return Plugin_Continue;
	}
	decl String:text[192];
	if(IsChatTrigger() || GetCmdArgString(text, sizeof(text))<1) {
		return Plugin_Continue;
	}
	new startidx = 0;
	if(text[0]== '"') {
		startidx = 1;
	}
	if(!StrContains(text[startidx], "] - snap dist: ", false)) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:StartCheck(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		g_bCheck[client] = true;
	}
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	g_bCheck[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(0.5, StartCheck, GetClientOfUserId(GetEventInt(event, "userid")));
}