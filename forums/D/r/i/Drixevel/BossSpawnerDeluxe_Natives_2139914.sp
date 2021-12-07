// TO DO
// Health bar tracking for all spawned entities
// Set up Red, Blue and Orange Skeleton spawning
// Model Scale arguments
// Testing

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

#pragma semicolon 1

#define PLUGIN_VERSION "2.0.0"

new Float:g_pos[3];

// Model Scale Stuff
new Handle:g_hBounds = INVALID_HANDLE;
new Float:g_fBoundMin;
new Float:g_fBoundMax;
new String:g_szBoundMin[16];
new String:g_szBoundMax[16];

// Health Bar Stuff
#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
new g_NumClients;
new g_trackEntity = -1;
new g_healthBar = -1;

// Boss Stuff
#define MERASMUS "merasmus"
#define HORSEMANN "headless_hatman"
#define MONOCULUS "eyeball_boss"
#define SKELETON "tf_zombie"
#define SKELETON2 "tf_zombie_spawner"

public Plugin:myinfo = {
	name = "Halloween Boss Spawner",
	author = "abrandnewday",
	description = "Enables the ability for admins to spawn Halloween bosses",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=165383"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	CreateNative("TF2_SpawnHatman", Native_SpawnHatman);
	CreateNative("TF2_SpawnEyeboss", Native_SpawnEyeboss);
	CreateNative("TF2_SpawnMerasmus", Native_SpawnMerasmus);
	CreateNative("TF2_SpawnSkeleton", Native_SpawnSkeleton);
	CreateNative("TF2_SpawnSkeletonKing", Native_SpawnSkeletonKing);
	
	return APLRes_Success;
}

public OnPluginStart() {
	LoadTranslations("common.phrases");
	CreateConVar("sm_bsd_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hBounds = CreateConVar("sm_bsd_bounds", "0.1, 5.0", "Lower (optional) and upper bounds for resizing, separated with a comma.", 0);
	HookConVarChange(g_hBounds, ConVarBoundsChanged);
	ParseConVarToLimits(g_hBounds, g_szBoundMin, sizeof(g_szBoundMin), g_fBoundMin, g_szBoundMax, sizeof(g_szBoundMax), g_fBoundMax);
	
	RegAdminCmd("sm_hatman", Command_SpawnHatman, ADMFLAG_GENERIC, "Spawns the Horsemann - Usage: sm_hatman");
	RegAdminCmd("sm_eyeboss", Command_SpawnEyeBoss, ADMFLAG_GENERIC, "Spawns the MONOCULUS! - Usage: sm_eyeboss");
	RegAdminCmd("sm_eyeboss_red", Command_SpawnEyeBossRED, ADMFLAG_GENERIC, "Spawns the RED Spectral MONOCULUS! - Usage: sm_eyeboss_red");
	RegAdminCmd("sm_eyeboss_blue", Command_SpawnEyeBossBLU, ADMFLAG_GENERIC, "Spawns the BLU Spectral MONOCULUS! - Usage: sm_eyeboss_blue");
	RegAdminCmd("sm_merasmus", Command_SpawnMerasmus, ADMFLAG_GENERIC, "Spawns Merasmus - Usage: sm_merasmus");
	RegAdminCmd("sm_skelegreen", Command_SpawnGreenSkeleton, ADMFLAG_GENERIC, "Spawns a Green Skeleton - Usage: sm_skelegreen");
	RegAdminCmd("sm_skelered", Command_SpawnREDSkeleton, ADMFLAG_GENERIC, "Spawns a RED Skeleton - Usage: sm_skelered");
	RegAdminCmd("sm_skeleblue", Command_SpawnBLUSkeleton, ADMFLAG_GENERIC, "Spawns a BLU Skeleton - Usage: sm_skeleblue");
	RegAdminCmd("sm_skeleking", Command_SpawnSkeletonKing, ADMFLAG_GENERIC, "Spawns a Skeleton King - Usage: sm_skeleking");
	
	RegAdminCmd("sm_slayhatman", Command_SlayHatman, ADMFLAG_GENERIC, "Slays all Horsemenn on the map - Usage: sm_slayhatman");
	RegAdminCmd("sm_slayeyeboss", Command_SlayEyeBoss, ADMFLAG_GENERIC, "Slays all MONOCULUS! on the map - Usage: sm_slayeyeboss");
	RegAdminCmd("sm_slayeyeboss_red", Command_SlayEyeBossRED, ADMFLAG_GENERIC, "Slays all RED Spectral MONOCULUS! on the map - Usage: sm_slayeyeboss_red");
	RegAdminCmd("sm_slayeyeboss_blue", Command_SlayEyeBossBLU, ADMFLAG_GENERIC, "Slays all BLU Spectral MONOCULUS! on the map - Usage: sm_slayeyeboss_blue");
	RegAdminCmd("sm_slaymerasmus", Command_SlayMerasmus, ADMFLAG_GENERIC, "Slays all Merasmus on the map - Usage: sm_slaymerasmus");
	RegAdminCmd("sm_slayskelegreen", Command_SlayGreenSkeleton, ADMFLAG_GENERIC, "Slays all Green Skeletons on the map - Usage: sm_slayskelegreen");
	RegAdminCmd("sm_slayskelered", Command_SlayREDSkeleton, ADMFLAG_GENERIC, "Slays all RED Skeletons on the map - Usage: sm_slayskelered");
	RegAdminCmd("sm_slayskeleblue", Command_SlayBLUSkeleton, ADMFLAG_GENERIC, "Slays all BLU Skeletons on the map - Usage: sm_slayskeleblue");
//	RegAdminCmd("sm_slayskeleking", Command_SlaySkeletonKing, ADMFLAG_GENERIC, "Slays all Skeleton Kings on the map - Usage: sm_slayskeleking");
}

// On plugin end, kill all present bosses
public OnPluginEnd() {
	new entity = -1;
	while((entity = FindEntityByClassname(entity, HORSEMANN)) != -1) {
		if(IsValidEntity(entity)) {
			new Handle:g_Event = CreateEvent("pumpkin_lord_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
		}
	}
	while((entity = FindEntityByClassname(entity, MONOCULUS)) != -1) {
		if(IsValidEntity(entity)) {
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
		}
	}
	while((entity = FindEntityByClassname(entity, MERASMUS)) != -1) {
		if(IsValidEntity(entity)) {
			new Handle:g_Event = CreateEvent("merasmus_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
		}
	}
	while((entity = FindEntityByClassname(entity, SKELETON)) != -1) {
		if(IsValidEntity(entity)) {
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public OnMapStart() {
	PrecacheHatman();
	PrecacheEyeBoss();
	PrecacheMerasmus();
	PrecacheSkeleton();
	FindHealthBar();
	g_NumClients = 0;
}

public OnClientConnected(client) {
	if(!IsFakeClient(client)) g_NumClients++;
}

public OnClientDisconnect(client) {
	if(!IsFakeClient(client)) g_NumClients--;
}

// ConVar Changed: Bounds
public ConVarBoundsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) {
	ParseConVarToLimits(g_hBounds, g_szBoundMin, sizeof(g_szBoundMin), g_fBoundMin, g_szBoundMax, sizeof(g_szBoundMax), g_fBoundMax);
}

// Parse ConVar to Limits
stock ParseConVarToLimits(const Handle:hConvar, String:szMinString[], const iMinStringLength, &Float:fMin, String:szMaxString[], const iMaxStringLength, &Float:fMax) {
	new iSplitResult;
	decl String:szBounds[256];
	GetConVarString(hConvar, szBounds, sizeof(szBounds));
	
	if ((iSplitResult = SplitString(szBounds, ",", szMinString, iMinStringLength)) != -1 && (fMin = StringToFloat(szMinString)) >= 0.0) {
		TrimString(szMinString);
		strcopy(szMaxString, iMaxStringLength, szBounds[iSplitResult]);
	}
	else {
		strcopy(szMinString, iMinStringLength, "0.0");
		fMin = 0.0;
		strcopy(szMaxString, iMaxStringLength, szBounds);
	}
	TrimString(szMaxString);
	fMax = StringToFloat(szMaxString);
	
	new iMarkInMin = FindCharInString(szMinString, '.'), iMarkInMax = FindCharInString(szMaxString, '.');
	Format(szMinString, iMinStringLength, "%s%s%s", (iMarkInMin == 0 ? "0" : ""), szMinString, (iMarkInMin == -1 ? ".0" : (iMarkInMin == (strlen(szMinString) - 1) ? "0" : "")));
	Format(szMaxString, iMaxStringLength, "%s%s%s", (iMarkInMax == 0 ? "0" : ""), szMaxString, (iMarkInMax == -1 ? ".0" : (iMarkInMax == (strlen(szMaxString) - 1) ? "0" : "")));
	
	if (fMin > fMax) {
		new Float:fTemp = fMax;
		fMax = fMin;
		fMin = fTemp;
	}
}

// Command: Spawn Horseless Headless Horsemann
public Action:Command_SpawnHatman(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnHorseman(fScale))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}Horseless Headless Horsemann!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Horseless Headless Horsemann", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {unusual}Horseless Headless Horsemann!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {unusual}Horseless Headless Horsemann!{default} for some reason.");
	}
	
	return Plugin_Handled;
}

bool:SpawnHorseman(Float:scale)
{
	new entity = CreateEntityByName(HORSEMANN);
	if(IsValidEntity(entity)) {
		DispatchSpawn(entity);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", fScale);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	return false;
}

// Command: Spawn MONOCULUS!
public Action:Command_SpawnEyeBoss(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnMonoculus(fScale)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}MONOCULUS!", client);
		LogAction(client, -1, "\"%L\" spawned boss: MONOCULUS", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {unusual}MONOCULUS!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {unusual}MONOCULUS!{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

// Command: Spawn RED Spectral MONOCULUS!
public Action:Command_SpawnEyeBossRED(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnMonoculus(fScale, 2)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {red}RED Spectral MONOCULUS!", client);
		LogAction(client, -1, "\"%L\" spawned boss: RED Spectral MONOCULUS", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {red}RED Spectral MONOCULUS!");
	}
	else
	{
		CReplyToCommand("{unusual}[BOSS] {default}Couldn't spawn {red}RED Spectral MONOCULUS!{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

// Command: Spawn BLU Spectral MONOCULUS!
public Action:Command_SpawnEyeBossBLU(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnMonoculus(fScale, 1)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {blue}BLU Spectral MONOCULUS!", client);
		LogAction(client, -1, "\"%L\" spawned boss: BLU Spectral MONOCULUS", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {blue}BLU Spectral MONOCULUS!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {blue}BLU Spectral MONOCULUS!{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

bool:SpawnMonoculus(Float:scale, team = 5)
{
	new entity = CreateEntityByName(MONOCULUS);
	if (IsValidEntity(entity)) {
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
		g_pos[2] += 50.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	return false;
}

// Command: Spawn Merasmus
public Action:Command_SpawnMerasmus(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnMerasmus(fScale)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned {unusual}Merasmus!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Merasmus", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {unusual}Merasmus!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {unusual}Merasmus!{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

bool:SpawnMerasmus(Float:scale)
{
	new entity = CreateEntityByName(MERASMUS);
	if (IsValidEntity(entity)) {
		DispatchSpawn(entity);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	return false;
}

public Action:Command_SpawnGreenSkeleton(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnSkeleton(fScale, "0", 1)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {community}Green Skeleton!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Green Skeleton", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {community}Green Skeleton!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {community}Green Skeleton{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_SpawnREDSkeleton(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnSkeleton(fScale, "1", 2)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {red}RED Skeleton!", client);
		LogAction(client, -1, "\"%L\" spawned boss: RED Skeleton", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {red}RED Skeleton!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {red}RED Skeleton{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_SpawnBLUSkeleton(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	if (args < 1) fScale = 1.0;
	if (SpawnSkeleton(fScale, "2", 3)
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {blue}BLU Skeleton!", client);
		LogAction(client, -1, "\"%L\" spawned boss: BLU Skeleton", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {blue}BLU Skeleton!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {blue}BLU Skeleton{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

bool:SpawnSkeleton(Float:scale, String:skin[1] = "0", team = 1)
{
	new entity = CreateEntityByName(SKELETON);
	if (IsValidEntity(entity)) {
		DispatchKeyValue(entity, "skin", skin);
		SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
		DispatchSpawn(entity);
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	return false;
}

// Command: Spawn Skeleton King
public Action:Command_SpawnSkeletonKing(client, args) {
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
/*
	
	new String:szScale[16] = "0.0";
	new Float:fScale = 0.0;
	if (args >= 1) {
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (fScale <= 0.0) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax)) {
			CReplyToCommand(client, "{unusual}[BOSS] {default}Size must be between %s and %s", g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
	}
	*/
	
	if(!SetTeleportEndPoint(client)) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		CReplyToCommand(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	
	//if (args < 1) fScale = 1.0;
	if (SpawnSkeletonKing())
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {unusual}Skeleton King!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Skeleton King", client);
		CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {unusual}Skeleton King!");
	}
	else
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {unusual}Skeleton King{default} for some reason.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

bool:SpawnSkeletonKing()
{
	new entity = CreateEntityByName(SKELETON2);
	if (IsValidEntity(entity)) {
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_nSkeletonType", 1);
		AcceptEntityInput(entity, "Enable");
		CreateTimer(1.0, Timer_KillSpawner, entity);
		return true;
	}
	return false;
}

//-----------------------------------------------------------------------------//
// SLAY COMMANDS
//-----------------------------------------------------------------------------//

// Command: Slay Horseless Headless Horsemann
public Action:Command_SlayHatman(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, HORSEMANN)) != -1) {
			if(IsValidEntity(entity)) {
				new Handle:g_Event = CreateEvent("pumpkin_lord_killed", true);
				FireEvent(g_Event);
				AcceptEntityInput(entity, "Kill");
				CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {unusual}Horseless Headless Horsemann", client);
				LogAction(client, -1, "\"%L\" slayed boss: Horseless Headless Horsemann", client);
				CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {unusual}Horseless Headless Horsemann");
			}
			else {
				CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {unusual}Horseless Headless Horsemann{default} for some reason.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay MONOCULUS!
public Action:Command_SlayEyeBoss(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, MONOCULUS)) != -1) {
			if(IsValidEntity(entity)) {
				new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
				if (m_iTeamNum == 5) {
					new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
					FireEvent(g_Event);
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {unusual}MONOCULUS!", client);
					LogAction(client, -1, "\"%L\" slayed boss: MONOCULUS", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {unusual}MONOCULUS!");
				}
				else {
					CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {unusual}MONOCULUS!{default} for some reason.");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay RED Spectral MONOCULUS!
public Action:Command_SlayEyeBossRED(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, MONOCULUS)) != -1) {
			if(IsValidEntity(entity)) {
				new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
				if (m_iTeamNum == 2) {
					new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
					FireEvent(g_Event);
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {red}RED Spectral MONOCULUS!", client);
					LogAction(client, -1, "\"%L\" slayed boss: RED Spectral MONOCULUS", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {red}RED Spectral MONOCULUS!");
				}
				else {
					CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {red}RED Spectral MONOCULUS!{default} for some reason.");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay BLU Spectral MONOCULUS!
public Action:Command_SlayEyeBossBLU(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, MONOCULUS)) != -1) {
			if(IsValidEntity(entity)) {
				new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
				if (m_iTeamNum == 1) {
					new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
					FireEvent(g_Event);
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {blue}BLU Spectral MONOCULUS!", client);
					LogAction(client, -1, "\"%L\" slayed boss: BLU Spectral MONOCULUS", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {blue}BLU Spectral MONOCULUS!");
				}
				else {
					CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {blue}BLU Spectral MONOCULUS!{default} for some reason.");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay Merasmus
public Action:Command_SlayMerasmus(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while((entity = FindEntityByClassname(entity, MERASMUS)) != -1) {
			if(IsValidEntity(entity)) {
				new Handle:g_Event = CreateEvent("merasmus_killed", true);
				FireEvent(g_Event);
				AcceptEntityInput(entity, "Kill");
				CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed {unusual}Merasmus", client);
				LogAction(client, -1, "\"%L\" slayed boss: Merasmus", client);
				CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {unusual}Merasmus");
			}
			else {
				CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay {unusual}Merasmus{default} for some reason.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay Green Skeleton
public Action:Command_SlayGreenSkeleton(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, SKELETON)) != -1) {
			if(IsValidEntity(entity)) {
				new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
				if (m_iTeamNum == 1) {
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {community}Green Skeleton!", client);
					LogAction(client, -1, "\"%L\" slayed boss: Green Skeleton", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {community}Green Skeleton");
				}
			}
			else {
				CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {community}Green Skeleton{default} for some reason.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay RED Skeleton
public Action:Command_SlayREDSkeleton(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, SKELETON)) != -1) {
			if(IsValidEntity(entity)) {
				new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
				if (m_iTeamNum == 2) {
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {red}RED Skeleton!", client);
					LogAction(client, -1, "\"%L\" slayed boss: RED Skeleton", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {red}RED Skeleton");
				}
			}
			else {
				CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {red}RED Skeleton{default} for some reason.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay BLU Skeleton
public Action:Command_SlayBLUSkeleton(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, SKELETON)) != -1) {
			if(IsValidEntity(entity)) {
				new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
				if (m_iTeamNum == 3) {
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {blue}BLU Skeleton!", client);
					LogAction(client, -1, "\"%L\" slayed boss: BLU Skeleton", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {blue}BLU Skeleton");
				}
			}
			else {
				CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {blue}BLU Skeleton{default} for some reason.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

// Command: Slay Skeleton King
/*
public Action:Command_SlaySkeletonKing(client, args)
{
	if(IsValidClient(client)) {
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, SKELETON2)) != -1) {
			if(IsValidEntity(entity)) {
				new SkeletonType = GetEntProp(entity, Prop_Data, "m_nSkeletonType");
				if (SkeletonType == 1) {
					AcceptEntityInput(entity, "Kill");
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {unusual}Skeleton King!", client);
					LogAction(client, -1, "\"%L\" slayed boss: Skeleton King", client);
					CReplyToCommand(client, "{unusual}[BOSS] {default}You've slayed the {unusual}Skeleton King");
				}
			}
			else {
				CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't slay the {unusual}Skeleton King{default} for some reason.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}
*/

// Timer: Kill Skeleton Spawner
public Action:Timer_KillSpawner(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		RemoveEdict(entity);
	}
}

// Function: Set Teleport End Point
SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else {
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

// Function: Trace Entity, Filter Player
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

// Function: Find Health Bat
FindHealthBar() {
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(g_healthBar == -1) {
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
		if(g_healthBar != -1) {
			DispatchSpawn(g_healthBar);
		}
	}
}

// Function: On Entity Created
public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, HEALTHBAR_CLASS)) {
		g_healthBar = entity;
	}
	else if (g_trackEntity == -1 && StrEqual(classname, HORSEMANN)) {
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
	}
	else if (g_trackEntity == -1 && StrEqual(classname, MONOCULUS)) {
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMonoculusDamaged);
	}
	else if (g_trackEntity == -1 && StrEqual(classname, MERASMUS)) {
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
	}
	else if (g_trackEntity == -1 && StrEqual(classname, SKELETON2)) {
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnSkeletonKingDamaged);
	}
}

// Function: On Entity Destroyed
public OnEntityDestroyed(entity) {
	if (entity == -1) return;
	else if (entity == g_trackEntity) {
		g_trackEntity = FindEntityByClassname(-1, HORSEMANN);
		if (g_trackEntity == entity) {
			g_trackEntity = FindEntityByClassname(entity, HORSEMANN);
		}
		if (g_trackEntity > -1) {
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	else if (entity == g_trackEntity) {
		g_trackEntity = FindEntityByClassname(-1, MONOCULUS);
		if (g_trackEntity == entity) {
			g_trackEntity = FindEntityByClassname(entity, MONOCULUS);
		}
		if (g_trackEntity > -1) {
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnMonoculusDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	else if (entity == g_trackEntity) {
		g_trackEntity = FindEntityByClassname(-1, MERASMUS);
		if (g_trackEntity == entity) {
			g_trackEntity = FindEntityByClassname(entity, MERASMUS);
		}
		if (g_trackEntity > -1) {
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	else if (entity == g_trackEntity) {
		g_trackEntity = FindEntityByClassname(-1, SKELETON2);
		if (g_trackEntity == entity) {
			g_trackEntity = FindEntityByClassname(entity, SKELETON2);
		}
		if (g_trackEntity > -1) {
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnSkeletonKingDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
}

// Function: On Horsemann Damaged
public OnHorsemannDamaged(victim, attacker, inflictor, Float:damage, damagetype) {
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

// Function: On MONOCULUS! Damaged
public OnMonoculusDamaged(victim, attacker, inflictor, Float:damage, damagetype) {
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

// Function: On Merasmus Damaged
public OnMerasmusDamaged(victim, attacker, inflictor, Float:damage, damagetype) {
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

// Function: On Skeleton King Damaged
public OnSkeletonKingDamaged(victim, attacker, inflictor, Float:damage, damagetype) {
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

// Function: Update Death Event
public UpdateDeathEvent(entity) {
	if(IsValidEntity(entity)) {
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if(HP <= (maxHP * 0.75)) {
			SetEntProp(entity, Prop_Data, "m_iHealth", 0);
			if(HP <= -1) {
				SetEntProp(entity, Prop_Data, "m_takedamage", 0);
			}
		}
	}
}

// Function: Update Boss Health
public UpdateBossHealth(entity) {
	if (g_healthBar == -1) return;
	new percentage;
	if (IsValidEntity(entity)) {
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if (HP <= 0) {
			percentage = 0;
		}
		else {
			percentage = RoundToCeil(float(HP) / (maxHP / 4) * HEALTHBAR_MAX);
		}
	}
	else {
		percentage = 0;
	}	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, percentage);
}

/************************************/
public Native_SpawnHatman(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client != 0 && !IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Hatman, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new float:scale = GetNativeCell(6);
	
	if (SpawnHorseman(scale))
	{
		if (spew)
		{
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}Horseless Headless Horsemann via natives!", client);
			LogAction(client, -1, "\"%L\" spawned boss via natives: Horseless Headless Horsemann", client);
			CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {unusual}Horseless Headless Horsemann via natives!");
		}
	}
	else
	{
		if (spew)
		{
			CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {unusual}Horseless Headless Horsemann!{default} for some reason via natives.");
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Hatman, could not spawn Hatman.");
	}
}

public Native_SpawnEyeboss(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client != 0 && !IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new Float:scale = Float:GetNativeCell(6);
	new type = GetNativeCell(7);
	
	if (SpawnMonoculus(scale, type))
	{
		if (spew)
		{
			switch (type)
			{
				case 0:
					{
						CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}MONOCULUS via natives!", client);
						LogAction(client, -1, "\"%L\" spawned boss via natives: MONOCULUS", client);
						CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {unusual}MONOCULUS via natives!");
					}
				case 1:
					{
						CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {red}RED Spectral MONOCULUS via natives!", client);
						LogAction(client, -1, "\"%L\" spawned boss via natives: RED Spectral MONOCULUS", client);
						CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {red}RED Spectral MONOCULUS via natives!");
					}
				case 2:
					{
						CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {blue}BLU Spectral MONOCULUS via natives!", client);
						LogAction(client, -1, "\"%L\" spawned boss via natives: BLU Spectral MONOCULUS", client);
						CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned the {blue}BLU Spectral MONOCULUS via natives!");
					}
			}
		}
	}
	else
	{
		switch (type)
		{
		case 0:
			{
				if (spew) CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {unusual}MONOCULUS!{default} for some reason via natives.");
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'regular', could not spawn Eyeboss 'regular'.");
			}
		case 1:
			{
				if (spew) CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {red}RED Spectral MONOCULUS!{default} for some reason via natives.");
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'red', could not spawn Eyeboss 'red'.");
			}
		case 2:
			{
				if (spew) CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {blue}BLU Spectral MONOCULUS!{default} for some reason via natives.");
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'blue', could not spawn Eyeboss 'blue'.");
			}
		}
	}
}

public Native_SpawnMerasmus(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client != 0 && !IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Merasmus, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new float:scale = GetNativeCell(6);
	
	if (SpawnMerasmus(scale))
	{
		if (spew)
		{
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned {unusual}Merasmus via natives!", client);
			LogAction(client, -1, "\"%L\" spawned boss via natives: Merasmus", client);
			CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {unusual}Merasmus via natives!");
		}
	}
	else
	{
		if (spew)
		{
			CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn {unusual}Merasmus!{default} for some reason via natives.");
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Merasmus, could not spawn Merasmus.");
	}
}

public Native_SpawnSkeleton(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client != 0 && !IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new Float:scale = Float:GetNativeCell(6);
	new type = GetNativeCell(7);
	
	new skin = 0, String:sSkin[1] = "0";
	
	switch (type)
	{
		case 1:	Format(sSkin, sizeof(sSkin), "0");
		case 2:	Format(sSkin, sizeof(sSkin), "1");
		case 3:	Format(sSkin, sizeof(sSkin), "2");
	}
	
	if (SpawnSkeleton(scale, sSkin, type))
	{
		if (spew)
		{
			switch (type)
			{
				case 0:
					{
						CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {community}Green Skeleton via natives!", client);
						LogAction(client, -1, "\"%L\" spawned boss via natives: Green Skeleton", client);
						CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {community}Green Skeleton via natives!");
					}
				case 1:
					{
						CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {red}RED Skeleton via natives!", client);
						LogAction(client, -1, "\"%L\" spawned boss via natives: RED Skeleton", client);
						CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {red}RED Skeleton via natives!");
					}
				case 2:
					{
						CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {blue}BLU Skeleton via natives!", client);
						LogAction(client, -1, "\"%L\" spawned boss via natives: BLU Skeleton", client);
						CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {blue}BLU Skeleton via natives!");
					}
			}
		}
	}
	else
	{
		switch (type)
		{
		case 0:
			{
				if (spew) CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {community}Green Skeleton{default} for some reason via natives.");
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Green', could not spawn Eyeboss 'Green'.");
			}
		case 1:
			{
				if (spew) CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {red}RED Skeleton{default} for some reason via natives.");
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Red', could not spawn Eyeboss 'Red'.");
			}
		case 2:
			{
				if (spew) CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {blue}BLU Skeleton{default} for some reason via natives.");
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Blue', could not spawn Eyeboss 'Blue'.");
			}
		}
	}
}
	
public Native_SpawnSkeletonKing(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client != 0 && !IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton King, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	
	if (SpawnSkeletonKing())
	{
		if (spew)
		{
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {unusual}Skeleton King via natives!", client);
			LogAction(client, -1, "\"%L\" spawned boss via natives: Skeleton King", client);
			CReplyToCommand(client, "{unusual}[BOSS] {default}You've spawned {unusual}Skeleton King via natives!");
		}
	}
	else
	{
		if (spew)
		{
			CReplyToCommand(client, "{unusual}[BOSS] {default}Couldn't spawn the {unusual}Skeleton King{default} for some reason via natives.");
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton King, could not spawn Skeleton King.");
	}
}
/************************************/

// Generic "Is Client Valid" check
stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}

// Precache Horseless Headless Horsemann files
// Thanks to Chaosxk for a wonderful example of how to make precaching sounds better
PrecacheHatman()
{
	PrecacheModel("models/bots/headless_hatman.mdl", true); 
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
	
	for(new i = 1; i <= 2; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_alert0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 4; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_attack0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 2; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_death0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 4; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_laugh0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_pain0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
	PrecacheSound("vo/halloween_boss/knight_dying.wav", true);
	PrecacheSound("vo/halloween_boss/knight_spawn.wav", true);
	PrecacheSound("vo/halloween_boss/knight_alert.wav", true);
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav", true);
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav", true);
}

// Precache Monoculus files
// Thanks to Chaosxk for a wonderful example of how to make precaching sounds better
PrecacheEyeBoss()
{
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl", true);
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl", true);
	
	for(new i = 1; i <= 3; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball_laugh0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball_mad0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 13; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav", true);
	PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
	PrecacheSound("ui/halloween_boss_chosen_it.wav", true);
	PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);
	PrecacheSound("ui/halloween_boss_defeated.wav", true);
	PrecacheSound("ui/halloween_boss_player_becomes_it.wav", true);
	PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
	PrecacheSound("ui/halloween_boss_summoned.wav", true);
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
	PrecacheSound("ui/halloween_boss_escape.wav", true);
	PrecacheSound("ui/halloween_boss_escape_sixty.wav", true);
	PrecacheSound("ui/halloween_boss_escape_ten.wav", true);
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
}

// Precache Merasmus files
// Thanks to Chaosxk for a wonderful example of how to make precaching sounds better
PrecacheMerasmus()
{
	PrecacheModel("models/bots/merasmus/merasmus.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl", true);
	
	for(new i = 1; i <= 17; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 11; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 54; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 33; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 2; i <= 4; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_island0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_skullhat0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 1; i <= 2; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_combat_idle0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 12; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 9; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_found0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 3; i <= 6; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_grenades0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 26; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 19; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal10%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal1%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 49; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 16; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 5; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_pain0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 4; i <= 8; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_ranged_attack0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 2; i <= 13; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic%d.wav", i);
		if(FileExists(iString))	{
			PrecacheSound(iString, true);
		}
	}
	
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav", true);
	
	PrecacheSound("misc/halloween/merasmus_appear.wav", true);
	PrecacheSound("misc/halloween/merasmus_death.wav", true);
	PrecacheSound("misc/halloween/merasmus_disappear.wav", true);
	PrecacheSound("misc/halloween/merasmus_float.wav", true);
	PrecacheSound("misc/halloween/merasmus_hiding_explode.wav", true);
	PrecacheSound("misc/halloween/merasmus_spell.wav", true);
	PrecacheSound("misc/halloween/merasmus_stun.wav", true);
}

// Precache Skeleton files
PrecacheSkeleton()
{
	PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper.mdl", true);
	PrecacheModel("models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl", true);
}