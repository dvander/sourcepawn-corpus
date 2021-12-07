#pragma		semicolon			1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#define		PLUGIN_VERSION		"1.2"

#define		STAGE_NONE			0
#define		STAGE_NEW			1
#define		STAGE_ACTIVE		2

#define		INFO_NEXT_DETECT	0
#define		INFO_FIRE_STAGE		1
#define		INFO_BLEEDING_STAGE	2
#define		INFO_NEXT_VCMD		3

public Plugin:myinfo = 
{
	name = "Discovered Effect",
	author = "Aderic",
	description = "Adds a sound and visual effect when a cloaked spy is discovered.",
	version = PLUGIN_VERSION
}

new Handle:CVAR_pluginVersion;

new Handle:CVAR_bumpCooldown;
new VAR_bumpCooldown;

new Handle:CVAR_bumpEnabled;
new bool:VAR_bumpEnabled;

new Handle:CVAR_detectionRange;
new Float:VAR_detectionRange;

new Handle:CVAR_shoutCooldown;
new VAR_shoutCooldown;

new clientLastVCMD;
new clientVCMDPrimary;
new clientVCMDSecondary;

new clientInfo[MAXPLAYERS+1][4];
new OFFSET_FOV;

public OnPluginStart()
{
	CVAR_pluginVersion =  	CreateConVar("sm_discovered_version",		PLUGIN_VERSION,		"Current version of the plugin. Read Only", 										FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	CVAR_bumpCooldown = 	CreateConVar("sm_discovered_bump_cooldown",			"8.0",		"Amount of seconds required to elapse for effect.",									FCVAR_NONE);
	CVAR_bumpEnabled =		CreateConVar("sm_discovered_bump_enabled",			"1.0",		"If 1, bumping into a cloaked spy will play the effect.",							FCVAR_NONE, true, 0.0, false, 1.0);
	CVAR_detectionRange	=	CreateConVar("sm_discovered_shout_range",			"500.0",	"Distance required to detect a spy using the spy shout. Set to 0 to disable.",		FCVAR_NONE);
	CVAR_shoutCooldown	=	CreateConVar("sm_discovered_shout_cooldown",		"14.0",		"Amount of seconds required to elapse to shout spy to detect.",						FCVAR_NONE);
	
	HookUserMessage(GetUserMessageId("VoiceSubtitle"), OnVoiceCommand, false, OnVoiceCommandSent);
	AddCommandListener(OnShoutCommand, 	"voicemenu");
	
	OFFSET_FOV = FindSendPropOffs("CTFPlayer", "m_iDefaultFOV");
	
	AutoExecConfig(true, "discovered_effect");
}

public OnConfigsExecuted() {
	
	HookConVarChange(CVAR_pluginVersion, 	OnCVARChanged);
	
	HookConVarChange(CVAR_bumpCooldown, 	OnCVARChanged);
	VAR_bumpCooldown =		GetConVarInt(CVAR_bumpCooldown);
	
	HookConVarChange(CVAR_bumpEnabled, 		OnCVARChanged);
	VAR_bumpEnabled =		GetConVarBool(CVAR_bumpEnabled);
	
	HookConVarChange(CVAR_detectionRange, 	OnCVARChanged);
	VAR_detectionRange = 	GetConVarFloat(CVAR_detectionRange);
	
	HookConVarChange(CVAR_shoutCooldown, 	OnCVARChanged);
	VAR_shoutCooldown = 	GetConVarInt(CVAR_shoutCooldown);
}

public Action:OnShoutCommand(client, const String:command[], argc) {
	if (argc < 2)
		return Plugin_Continue;
	
	clientLastVCMD = client;
	
	decl String:voiceCmd[2];
	GetCmdArg(1, voiceCmd, sizeof(voiceCmd));
	clientVCMDPrimary = 	StringToInt(voiceCmd);
	
	GetCmdArg(2, voiceCmd, sizeof(voiceCmd));
	clientVCMDSecondary = 	StringToInt(voiceCmd);
	
	return Plugin_Continue;
}
// Fires when someone screams something from the voice menu.
public Action:OnVoiceCommand(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {
	new client = BfReadByte(bf);
	
	clientVCMDPrimary = BfReadByte(bf);
	clientVCMDSecondary = BfReadByte(bf);
	clientLastVCMD = client;
	
	return Plugin_Continue;
}
// Post event of OnVoiceCommand.
public OnVoiceCommandSent(UserMsg:msg_id, bool:sent) {
	if (VAR_detectionRange == 0.0 || clientVCMDPrimary != 1 || clientVCMDSecondary != 1)
		return;
	
	new time = GetTime();
	
	if (time < clientInfo[clientLastVCMD][INFO_NEXT_VCMD])
		return;
	
	decl Float:vAngles[3];
	GetClientEyeAngles(clientLastVCMD,		vAngles);
	
	decl Float:vOrigin[3];
	GetClientEyePosition(clientLastVCMD,	vOrigin);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, FilterPlayersOnly);
    	
	if (TR_DidHit(trace) == false) {
		CloseHandle(trace);
		return;
	}
	
	new clientHit = TR_GetEntityIndex(trace);
	
	if (clientHit < 1) {
		CloseHandle(trace);
		return;
	}
	
	decl Float:outVector[3];
   	TR_GetEndPosition(outVector, trace);
	
	// If out of range, quit.
	if (GetVectorDistance(vOrigin, outVector) > VAR_detectionRange) {
		CloseHandle(trace);
		return;
	}
	
	if (IsClientInGame(clientHit) && IsPlayerAlive(clientHit) && GetClientTeam(clientLastVCMD) != GetClientTeam(clientHit) && (TF2_IsPlayerInCondition(clientHit, TFCond_Disguised) || TF2_IsPlayerInCondition(clientHit, TFCond_Cloaked))) {
		clientInfo[clientLastVCMD][INFO_NEXT_VCMD] = time+VAR_shoutCooldown;
		PlayEffect(clientHit, time);
	}
	
	CloseHandle(trace);
}

public bool:FilterPlayersOnly(entity, contentMask) {
	return (entity >= 1 && entity <= MaxClients && entity != clientLastVCMD);
}

// Reset cooldown for all clients.
public OnCVARChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cvar == CVAR_pluginVersion) {
		if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
			// Set it back to the way it was supposed to be.
			SetConVarString(cvar, PLUGIN_VERSION);
		}
	}
	else if (cvar == CVAR_bumpCooldown) {
		VAR_bumpCooldown = GetConVarInt(cvar);
		for (new client = 1; client <= MaxClients; client++) {
			clientInfo[client][INFO_NEXT_DETECT] = 0;
		}
	}
	else if (cvar == CVAR_bumpEnabled)
		VAR_bumpEnabled = GetConVarBool(cvar);
	else if (cvar == CVAR_detectionRange)
		VAR_detectionRange = GetConVarFloat(cvar);
	else if (cvar == CVAR_shoutCooldown) {
		VAR_shoutCooldown = GetConVarInt(cvar);
		for (new client = 1; client <= MaxClients; client++) {
			clientInfo[client][INFO_NEXT_VCMD] = 0;
		}
	}
}

public OnMapStart() {
	AddFileToDownloadsTable("sound/alert_sound.mp3");
	AddFileToDownloadsTable("materials/sprites/alert.vmt");
	AddFileToDownloadsTable("materials/sprites/alert.vtf");
	
	PrecacheSound	("alert_sound.mp3", 				true);
	PrecacheGeneric	("materials/sprites/alert.vmt", 	true);
	PrecacheDecal	("materials/sprites/alert.vtf", 	true);
}

public TF2_OnConditionAdded(client, TFCond:condition) {
	if (VAR_bumpEnabled == false)
		return;
	
	if (condition == TFCond_OnFire) {
		clientInfo[client][INFO_FIRE_STAGE] = STAGE_NEW; 
	}
	else if (condition == TFCond_Bleeding) {
		clientInfo[client][INFO_BLEEDING_STAGE] = STAGE_NEW; 
	}
	else if (condition == TFCond_CloakFlicker && clientInfo[client][INFO_FIRE_STAGE] != STAGE_ACTIVE && clientInfo[client][INFO_BLEEDING_STAGE] != STAGE_ACTIVE) {
		new time = GetTime();
		
		if (time >= clientInfo[client][INFO_NEXT_DETECT]) {
			if (clientInfo[client][INFO_FIRE_STAGE] == STAGE_NEW)
				clientInfo[client][INFO_FIRE_STAGE] = STAGE_ACTIVE;
			
			if (clientInfo[client][INFO_BLEEDING_STAGE] == STAGE_NEW)
				clientInfo[client][INFO_BLEEDING_STAGE] = STAGE_ACTIVE;
			
			if (GetClientWhoCollided(client) > 0) {
				PlayEffect(client, time);
			}
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition) {
	if (VAR_bumpEnabled == false)
		return;
	
	if (condition == TFCond_OnFire) {
		clientInfo[client][INFO_FIRE_STAGE] = STAGE_NONE; 
	}
	else if (condition == TFCond_Bleeding) {
		clientInfo[client][INFO_BLEEDING_STAGE] = STAGE_NONE; 
	}
}


public SpawnSprite(client) {
	new spriteEnt = CreateEntityByName("env_sprite");
	DispatchKeyValue(spriteEnt, "model", 		"materials/sprites/alert.vmt");
	DispatchKeyValue(spriteEnt, "rendermode", 	"1");
	DispatchSpawn(spriteEnt);
	
	decl Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	clientPos[2] += 105.0;
	TeleportEntity(spriteEnt, clientPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("OnUser1 !self:kill::1.25:1");
	AcceptEntityInput(spriteEnt, "AddOutput");
	AcceptEntityInput(spriteEnt, "FireUser1");
}

public PlayEffect(client, time) {
	clientInfo[client][INFO_NEXT_DETECT] = time + VAR_bumpCooldown;
	EmitSoundToAll("alert_sound.mp3", client);
	EmitSoundToAll("alert_sound.mp3", client);
	SpawnSprite(client);
}

GetClientWhoCollided(const client) {
	decl Float:clientPosition[3];
	GetClientEyePosition(client, clientPosition);
	
	new clientTeam = GetClientTeam(client);
	
	decl Float:targetPosition[3];
	
	for (new target = 1; target <= MaxClients; target++) {
		if (client == target || IsClientInGame(target) == false || IsPlayerAlive(target) == false || GetClientTeam(target) == clientTeam)
			continue;
		
		GetClientEyePosition(target, targetPosition);
		
		if (GetVectorDistance(clientPosition, targetPosition) < 97.0) {
			if (IsClientInFOV(target, client))
				return target;
			else 
				return -1;
		}
	}
	
	return -1;
}

stock bool:IsClientInFOV(const client, const target)
{
	new Float:clientFOV = float(GetEntData(client, OFFSET_FOV)) * 0.78;
	
	decl Float:clientPosition[3];
	GetClientEyePosition(client, clientPosition);
	
	decl Float:targetPosition[3];
	GetClientEyePosition(target, targetPosition);
	
	decl Float:clientAngles[3];
	decl Float:clientAnglesForward[3];
	GetClientEyeAngles(client, clientAngles);
	GetAngleVectors(clientAngles, clientAnglesForward, NULL_VECTOR, NULL_VECTOR);
	
	decl Float:targetVector[3];
	TR_TraceRayFilter(clientPosition, clientAngles, MASK_SOLID, RayType_Infinite, FilterPlayersOnly);
	TR_GetEndPosition(targetVector);

	NormalizeVector(clientAnglesForward, clientAnglesForward);
	
	MakeVectorFromPoints(clientPosition, targetPosition, targetVector);
	
	NormalizeVector(targetVector, targetVector);
	
	return (RadToDeg(ArcCosine(GetVectorDotProduct(targetVector, clientAnglesForward))) < clientFOV);
}
