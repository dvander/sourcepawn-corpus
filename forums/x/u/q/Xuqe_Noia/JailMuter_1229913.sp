#include <sourcemod>
#include <sdktools>

#define JAILMUTER_VERSION "1.1"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

new Handle:jailmuter_enabled;
new Handle:jailmuter_msg;
new Handle:jailmuter_adm;

public Plugin:myinfo = {
	name = "Jail Muter",
	author = "Xuqe Noia",
	description = "Mute the dead player, good for jail maps",
	version = JAILMUTER_VERSION,
	url = "http://LiquidBR.com"
};

public OnPluginStart() {
	CreateConVar( "sm_jailmuter_version", JAILMUTER_VERSION, "Jail Muter Version", CVAR_FLAGS );
	jailmuter_enabled = CreateConVar("sm_jailmuter_enabled", "1", "Enable or disable the Jail Muter; 0 - disabled, 1 - enabled");
	jailmuter_msg = CreateConVar("sm_jailmuter_msg", "1", "Enable or disable the Jail Muter Messages; 0 - disabled, 1 - enabled");
	jailmuter_adm = CreateConVar("sm_jailmuter_adm", "0", "Enable or disable mute admins; 0 - Admins won't be muted, 1 - Admins will be muted");
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_start", RoundStart);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(jailmuter_enabled) == 1) {
		new index = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetConVarInt(jailmuter_adm) == 0) {
			new flags = GetUserFlagBits(index); 
			if(flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT || flags & ADMFLAG_SLAY || flags & ADMFLAG_CHEATS) {
				return Plugin_Continue; 
			} else {
				SetClientListeningFlags(index, VOICE_MUTED);
			}
		}
		if (GetConVarInt(jailmuter_msg) == 1) {
			PrintToChat(index, "\x04[Jail Muter] \x01You are \x05muted\x01, you will be \x05unmuted\x01 in the next round");
		}
	}
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(jailmuter_enabled) == 1) {
		new index = GetClientOfUserId(GetEventInt(event, "userid"));
		SetClientListeningFlags(index, VOICE_NORMAL);
	}
	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(jailmuter_enabled) == 1) {
		if (GetConVarInt(jailmuter_msg) == 1) {
			PrintToChatAll("\x04[Jail Muter] \x01All the players are \x05unmuted\x01")
		}
	}
	return Plugin_Continue;
}