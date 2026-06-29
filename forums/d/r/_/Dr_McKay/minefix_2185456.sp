#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <sourcebans>
#include <sourceirc>

public Plugin:myinfo = {
	name		= "[TF2] MineFix",
	author		= "Dr. McKay",
	description	= "Fixes a bug that allows players to create mines",
	version		= "1.0.1",
	url			= "http://www.doctormckay.com"
};

new Handle:g_RocketTouch;

new Handle:g_cvarBanDetections;
new Handle:g_cvarBanDetectionCooldown;
new Handle:g_cvarBanTime;
new Handle:g_cvarBanReason;

new g_NumDetections[MAXPLAYERS + 1];

public OnPluginStart() {
	new Handle:gamedata = LoadGameConfigFile("minefix.games");
	if(gamedata == INVALID_HANDLE) {
		SetFailState("Gamedata is not present");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "RocketTouch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
	g_RocketTouch = EndPrepSDKCall();
	CloseHandle(gamedata);
	
	g_cvarBanDetections = CreateConVar("minefix_ban_detections", "0", "Number of times a client has to be detected trying to exploit the mine glitch before being banned, or 0 to never ban", _, true, 0.0);
	g_cvarBanDetectionCooldown = CreateConVar("minfix_ban_detection_cooldown", "5", "Time in minutes after which a detection expires", _, true, 0.0);
	g_cvarBanTime = CreateConVar("minefix_ban_time", "0", "Minutes to ban players who have been detected as exploiting the mine glitch, 0 for permanent", _, true, 0.0);
	g_cvarBanReason = CreateConVar("minefix_ban_reason", "Rocket mine exploit detected", "Reason to use when banning players for exploiting the mine glitch");
}

public OnClientConnected(client) {
	g_NumDetections[client] = 0;
}

public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, "tf_projectile_stun_ball")) {
		SDKHook(entity, SDKHook_TouchPost, OnBallTouch);
	}
}

public OnBallTouch(entity, other) {
	decl String:classname[64];
	GetEntityClassname(other, classname, sizeof(classname));
	if(StrEqual(classname, "tf_projectile_rocket")) {
		SDKCall(g_RocketTouch, other, 0);
		RequestFrame(Frame_KillRocket, EntIndexToEntRef(other));
		
		new launcher = GetEntPropEnt(other, Prop_Send, "m_hLauncher");
		new client = GetEntPropEnt(launcher, Prop_Send, "m_hOwner");
		g_NumDetections[client]++;
		
		new Float:cooldown = GetConVarFloat(g_cvarBanDetectionCooldown);
		if(cooldown > 0.0) {
			CreateTimer(cooldown * 60.0, Timer_ExpireDetection, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		LogAction(client, -1, "\"%L\" attempted to exploit the rocket mine glitch (detection #%d)", client, g_NumDetections[client]);
		new required = GetConVarInt(g_cvarBanDetections);
		
		if(LibraryExists("sourceirc")) {
			IRC_MsgFlaggedChannels("ticket", "%N is suspected of exploiting the rocket mine glitch (detection #%d)", client, g_NumDetections[client]);
		}
		
		if(required > 0 && g_NumDetections[client] >= required) {
			decl String:reason[256];
			GetConVarString(g_cvarBanReason, reason, sizeof(reason));
			LogAction(0, client, "Banning \"%L\" for attempting to exploit the rocket mine glitch (%d detections)", client, g_NumDetections[client]);
			if(LibraryExists("sourcebans")) {
				SBBanPlayer(0, client, GetConVarInt(g_cvarBanTime), reason);
			} else {
				BanClient(client, GetConVarInt(g_cvarBanTime), BANFLAG_AUTO, reason, reason, "minefix");
			}
		}
	}
}

public Action:Timer_ExpireDetection(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client != 0) {
		g_NumDetections[client]--;
		if(g_NumDetections[client] < 0) {
			g_NumDetections[client] = 0;
		}
	}
}

public Frame_KillRocket(entref) {
	new ent = EntRefToEntIndex(entref);
	if(!IsValidEntity(ent)) {
		return;
	}
	
	// Kill the entity if the detonation fails
	AcceptEntityInput(ent, "Kill");
}