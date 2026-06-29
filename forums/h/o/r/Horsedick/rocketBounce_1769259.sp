#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.3"

public Plugin:myinfo = {
	name = "ProjectileBawnce (formerly RawketBawnce)",
	author = "Asher \"asherkin\" Baker",
	description	= "Yep. You're screwed.",
	version = PLUGIN_VERSION,
	url = "http://limetech.org/"
};

#define	MAX_EDICT_BITS	11
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

#define BOUNCE_ROCKET		(1 << 0)
#define BOUNCE_FLARE		(1 << 1)
#define BOUNCE_ARROW		(1 << 2)
#define BOUNCE_HEALINGBOLT	(1 << 3)
#define BOUNCE_SENTRYROCKET	(1 << 4)


new g_nBounces[MAX_EDICTS];

new bool:isRockedbounced[MAXPLAYERS + 1] = {false, ...};
new Handle:g_hMaxBouncesConVar;
new Handle:g_hEverythingConVar;
new g_config_iMaxBounces = 2;
new g_config_iEverything = 0;
new Handle:g_hIncrementDeflect = INVALID_HANDLE;


public OnPluginStart()
{
	CreateConVar("rocketbounce_version", PLUGIN_VERSION, "Corners, how do they work?", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_rb_clear", Command_ClearRockets, ADMFLAG_ROOT, "Sets all currently existing projectiles to explode on their next bounce");
	RegAdminCmd("sm_rocketbounce", Command_RocketBounce, ADMFLAG_CUSTOM1, "Bouncing Rockets!");
	
	g_hMaxBouncesConVar = CreateConVar("sm_rb_max", "2", "Max number of times a rocket will bounce.", FCVAR_NONE, true, 0.0, false);
	g_config_iMaxBounces = GetConVarInt(g_hMaxBouncesConVar);
	HookConVarChange(g_hMaxBouncesConVar, config_iMaxBounces_changed);

	g_hEverythingConVar = CreateConVar("sm_rb_which", "0", "Add up: 1-rocket, 2-flare, 4-arrow, 8-crossbow, 16-sentryrocket", FCVAR_NONE, true, 0.0, true, 31.0);
	g_config_iEverything = GetConVarInt(g_hEverythingConVar);
	HookConVarChange(g_hEverythingConVar, config_iEverything_changed);
	
	new Handle:g_hGameConf = LoadGameConfigFile("tf2.rocketbounce");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Could not locate tf2.rocketbounce.txt in gamedata folder");
		return;
	}
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Virtual, "CTFProjectile_Arrow::IncrementDeflect");
	g_hIncrementDeflect = EndPrepSDKCall();
	if(g_hIncrementDeflect == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call for CTFProjectile_Arrow::IncrementDeflect");
		CloseHandle(g_hGameConf);
		return;
	}
	CloseHandle(g_hGameConf);
}

public Action:Command_RocketBounce(client, args) {
	if(args != 0 && args != 1 && args != 2) {
		ReplyToCommand(client, "[SM] Usage: sm_rocketbounce <target> [1/0]");
		return Plugin_Handled;
	}
	if(args == 0) {
		if(isRockedbounced[client]) {
			isRockedbounced[client] = false;
		} else {
			isRockedbounced[client] = true;
		}
		
		LogAction(client, client, "%L toggled rocket bounce on themself", client);
		return Plugin_Handled;
	}
	if(!CheckCommandAccess(client, "RockedBounceTargetOthers", ADMFLAG_CHAT)) {
		ReplyToCommand(client, "[SM] Usage: sm_rocketbounce");
		return Plugin_Handled;
	}
	if(args == 1) {
		decl String:target_name[MAX_NAME_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		decl String:arg1[MAX_NAME_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));
		if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(new i = 0; i < target_count; i++) {
			if(isRockedbounced[target_list[i]]) {
				isRockedbounced[target_list[i]] = false;
			} else {
				isRockedbounced[target_list[i]] = true;
			}
			LogAction(client, target_list[i], "%L toggled rocked bounce on %L", client, target_list[i]);
		}
		
		return Plugin_Handled;
	}
	if(args == 2) {
		decl String:target_name[MAX_NAME_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		decl String:arg1[MAX_NAME_LENGTH], String:arg2[4];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		new iState = StringToInt(arg2);
		if(iState != 0 && iState != 1) {
			ReplyToCommand(client, "[SM] Usage: sm_rocketbounce <target> [1/0]");
			return Plugin_Handled;
		}
		new bool:bState = false;
		if(iState == 1) {
			bState = true;
		}
		decl String:sState[8];
		if(bState) {
			strcopy(sState, sizeof(sState), "on");
		} else {
			strcopy(sState, sizeof(sState), "off");
		}
		if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(new i = 0; i < target_count; i++) {
			isRockedbounced[target_list[i]] = bState;
			LogAction(client, target_list[i], "%L set rocketbounce on %L %s", client, target_list[i], sState);
		}
		
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] An unknown error occurred.");
	return Plugin_Handled;
}


public config_iMaxBounces_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_config_iMaxBounces = StringToInt(newValue);
}
public config_iEverything_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_config_iEverything = StringToInt(newValue);
}
public OnEntityCreated(entity, const String:classname[])
{
/*	if (!StrEqual(classname, "tf_projectile_rocket", false))
		return;*/
	if (NotProjectile(classname))
		return;

	g_nBounces[entity] = 0;
	SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
}




public Action:Command_ClearRockets(client, args)
{
	for (new i = MaxClients + 1; i < MAX_EDICTS; i++)
	{
		decl String:classname[32];
		if (!IsValidEdict(i)) continue;
		if (!GetEdictClassname(i, classname, sizeof(classname))) continue;
		if (NotProjectile(classname, true)) continue;
		g_nBounces[i] = g_config_iMaxBounces + 1;
	}
	return Plugin_Handled;
}
public Action:OnStartTouch(entity, other)
{
	decl String:classname[32];
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;

	// Only allow a rocket to bounce x times.
	if (g_nBounces[entity] >= g_config_iMaxBounces)
		return Plugin_Continue;

	if (GetEdictClassname(other, classname, sizeof(classname)) && strncmp(classname, "obj_", 4, false) == 0)
		return Plugin_Continue;

	if (GetEdictClassname(entity, classname, sizeof(classname)))
	{
		if ((StrEqual(classname, "tf_projectile_rocket", false) || StrEqual(classname, "tf_projectile_sentryrocket", false)) && IsRocketNearClient(entity))
			return Plugin_Continue;

/*		if (StrEqual(classname, "tf_projectile_pipe_remote", false))
			SetEntProp(entity, Prop_Send, "m_bTouched", 0);*/

		if ((StrEqual(classname, "tf_projectile_arrow", false) || StrEqual(classname, "tf_projectisle_healing_bolt", false)) && g_nBounces[entity] % 5 == 0)
		{
			SDKCall(g_hIncrementDeflect, entity);
			SetEntProp(entity, Prop_Send, "m_iDeflected", GetEntProp(entity, Prop_Send, "m_iDeflected") - 1);
		}
	}
	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action:OnTouch(entity, other)
{
	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, entity);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);

	g_nBounces[entity]++;
	
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}
stock bool:IsRocketNearClient(rocket)
{
	decl Float:vOrigin[3];
	decl Float:vClientOrigin[3];
	GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", vOrigin);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
//		decl Float:vClientOrigin[3];
		GetClientAbsOrigin(client, vClientOrigin);
		new Float:distance = GetVectorDistance(vOrigin, vClientOrigin);
//		PrintToChatAll("d %.2f", distance);
		if (distance < 83.00) return true;
	}
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "obj_sentrygun")) != -1)
	{
//		decl Float:vClientOrigin[3];
		GetEntPropVector(edict, Prop_Send, "m_vecOrigin", vClientOrigin);
		new Float:distance = GetVectorDistance(vOrigin, vClientOrigin);
//		PrintToChatAll("d %.2f", distance);
		if (distance < 83.00) return true;
	}
	edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "obj_dispenser")) != -1)
	{
//		decl Float:vClientOrigin[3];
		GetEntPropVector(edict, Prop_Send, "m_vecOrigin", vClientOrigin);
		new Float:distance = GetVectorDistance(vOrigin, vClientOrigin);
//		PrintToChatAll("d %.2f", distance);
		if (distance < 83.00) return true;
	}
	edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "obj_teleporter")) != -1)
	{
//		decl Float:vClientOrigin[3];
		GetEntPropVector(edict, Prop_Send, "m_vecOrigin", vClientOrigin);
		new Float:distance = GetVectorDistance(vOrigin, vClientOrigin);
//		PrintToChatAll("d %.2f", distance);
		if (distance < 83.00) return true;
	}
	return false;
}
stock bool:NotProjectile(const String:classname[], bool:checkall = false)
{
	if (checkall)
	{
		if (!StrEqual(classname, "tf_projectile_rocket", false)
		&& !StrEqual(classname, "tf_projectile_flare", false)
		&& !StrEqual(classname, "tf_projectile_arrow", false)
		&& !StrEqual(classname, "tf_projectile_healing_bolt", false)
		&& !StrEqual(classname, "tf_projectile_sentryrocket", false)
//		&& !StrEqual(classname, "tf_projectile_jar", false)
//		&& !StrEqual(classname, "tf_projectile_pipe_remote", false)
//		&& !StrEqual(classname, "tf_projectile_pipe", false)
//		&& !StrEqual(classname, "tf_flame_rocket", false)
//		&& !StrEqual(classname, "tf_projectile_stun_ball", false)
		) return true;
	}
	else
	{
		if ((g_config_iEverything & BOUNCE_ROCKET) && StrEqual(classname, "tf_projectile_rocket", false)) return false;
		if ((g_config_iEverything & BOUNCE_FLARE) && StrEqual(classname, "tf_projectile_flare", false)) return false;
		if ((g_config_iEverything & BOUNCE_ARROW) && StrEqual(classname, "tf_projectile_arrow", false)) return false;
		if ((g_config_iEverything & BOUNCE_HEALINGBOLT) && StrEqual(classname, "tf_projectile_healing_bolt", false)) return false;
		if ((g_config_iEverything & BOUNCE_SENTRYROCKET) && StrEqual(classname, "tf_projectile_sentryrocket", false)) return false;
		return true;
	}
	return false;
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}