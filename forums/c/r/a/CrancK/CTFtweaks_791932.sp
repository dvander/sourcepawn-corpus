#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <dukehacks>
#define PLUGIN_VERSION "1.1"
public Plugin:myinfo = 
{
	name = "CTFTweaks",
	author = "CrancK",
	description = "Tweak CTF in TF2.",
	version = PLUGIN_VERSION,
	url = ""
}
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;
new Handle:g_hTouch = INVALID_HANDLE;
new bool:g_bTouch = true;
new Handle:g_hHome = INVALID_HANDLE;
new bool:g_bHome = false;
new Handle:g_hTimer = INVALID_HANDLE;
new g_iTimer = 15;
new Handle:g_hThrow = INVALID_HANDLE;
new bool:g_bThrow = true;
new Handle:g_hThrowS = INVALID_HANDLE;
new Float:g_fThrowS = 400.0;
new Handle:g_hDist = INVALID_HANDLE;
new Float:g_fDist = 10.0;
new Handle:g_hBounce = INVALID_HANDLE;
new bool:g_bBounce = false;
new Float:g_vecDown[3] = {90.0, 0.0, 0.0};
new Handle:g_hFlags = INVALID_HANDLE;
new Handle:g_hFlagO = INVALID_HANDLE;
new Handle:g_hFlagC = INVALID_HANDLE;
public OnPluginStart() {
	CreateConVar("ctft_version", PLUGIN_VERSION, "CTFTweaks version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("ctft_enable", "1", "Enable/disable CTFTweaks.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hTouch = CreateConVar("ctft_touch", "1", "Does touch return flag?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hHome = CreateConVar("ctft_home", "0", "Can only cap with flag home.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hTimer = CreateConVar("ctft_timer", "15", "Flag return timer, in seconds.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hThrow = CreateConVar("ctft_throw", "1", "Can you throw the flag?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hThrowS = CreateConVar("ctft_throws", "400.0", "Flag throw speed.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDist = CreateConVar("ctft_dist", "10.0", "Distance before flag is considered to be on the ground.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hBounce = CreateConVar("ctft_bounce", "0", "Does the flag bounce when thrown?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegConsoleCmd("throwitem", Command_throwitem);
	HookEvent("teamplay_round_start", Event_round_start);
	HookEntityOutput("item_teamflag", "OnDrop", Ent_OnDrop);
	HookEntityOutput("item_teamflag", "OnPickUp", Ent_OnPickup);
	HookEntityOutput("item_teamflag", "OnCapture", Ent_OnReturn);
	HookEntityOutput("item_teamflag", "OnReturn", Ent_OnReturn);
	HookConVarChange(g_hEnabled, Cvar_enabled);
	HookConVarChange(g_hTouch, Cvar_touch);
	HookConVarChange(g_hHome, Cvar_home);
	HookConVarChange(g_hTimer, Cvar_timer);
	HookConVarChange(g_hThrow, Cvar_throw);
	HookConVarChange(g_hThrowS, Cvar_throws);
	HookConVarChange(g_hDist, Cvar_dist);
	HookConVarChange(g_hBounce, Cvar_bounce);
	g_hFlags = CreateArray(5);
	g_hFlagO = CreateArray(3);
	g_hFlagC = CreateArray(2);
}
public OnMapStart() {
	PrecacheModel("models/flag/briefcase.mdl", true);
}
public OnConfigsExected() {
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bTouch = GetConVarBool(g_hTouch);
	g_bHome = GetConVarBool(g_hHome);
	g_iTimer = GetConVarInt(g_hTimer);
	g_bThrow = GetConVarBool(g_hThrow);
	g_fThrowS = GetConVarFloat(g_hThrowS);
	g_fDist = GetConVarFloat(g_hDist);
	g_bBounce = GetConVarBool(g_hBounce);
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Cvar_touch(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bTouch = GetConVarBool(g_hTouch);
}
public Cvar_home(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bHome = GetConVarBool(g_hHome);
}
public Cvar_timer(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iTimer = GetConVarInt(g_hTimer);
}
public Cvar_throw(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bThrow = GetConVarBool(g_hThrow);
}
public Cvar_throws(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fThrowS = GetConVarFloat(g_hThrowS);
}
public Cvar_dist(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDist = GetConVarFloat(g_hDist);
}
public Cvar_bounce(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bBounce = GetConVarBool(g_hBounce);
}
public Action:ThinkHook(entity) {
	new idx = FindFlag(entity, 3);
	if(idx!=-1) {
		if(!g_bBounce && DistFromGround(entity)<g_fDist) {
			AcceptEntityInput(GetArrayCell(g_hFlags, idx), "ClearParent");
			RemoveEdict(entity);
			return Plugin_Handled;
		}
		decl Float:flagorigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flagorigin);
		flagorigin[2] += 82;
		TeleportEntity(GetArrayCell(g_hFlags, idx, 4), flagorigin, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Continue;
}
public Action:TouchHook(ent, other) {
	if(g_bEnabled && g_bTouch && GetFlagState(ent)==2 && other>0 && other<=MaxClients && GetClientTeam(other)==GetEntProp(ent, Prop_Data, "m_iTeamNum")) {
		new idx = FindFlag(ent);
		AcceptEntityInput(GetArrayCell(g_hFlags, idx, 4), "kill");
		decl Float:origin[3];
		GetArrayArray(g_hFlagO, idx, origin);
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)) {
				if(GetEntProp(ent, Prop_Data, "m_iTeamNum")==GetClientTeam(i)) {
					new rint = GetRandomInt(1, 3);
					if(rint==1) {
						EmitSoundToClient(i, "vo/intel_enemyreturned.wav", _, _, _, _, 0.75);
					} else {
						decl String:buffer[128];
						Format(buffer, sizeof(buffer), "vo/intel_enemyreturned%i.wav", rint);
						EmitSoundToClient(i, buffer, _, _, _, _, 0.75);
					}
				} else {
					EmitSoundToClient(i, "vo/intel_teamreturned.wav", _, _, _, _, 0.75);
				}
			}
		}
		SetFlagState(ent, 0);
		SetEntProp(ent, Prop_Send, "m_nFlagStatus", 0);
	}
	return Plugin_Continue;
}
public ResultType:dhOnEntitySpawned(edict) {
	new String:classname[64];
	GetEdictClassname(edict, classname, sizeof(classname)); 
	if(StrEqual(classname, "item_teamflag_return_icon")) {
		decl Float:flagorigin[3], Float:iconorigin[3];
		GetEntPropVector(edict, Prop_Send, "m_vecOrigin", iconorigin);
		new size = GetArraySize(g_hFlags);
		for(new i=0;i<size;i++) {
			GetEntPropVector(GetArrayCell(g_hFlags, i), Prop_Send, "m_vecOrigin", flagorigin);
			if(flagorigin[0]==iconorigin[0] && flagorigin[1]==iconorigin[1]) {
				SetArrayCell(g_hFlags, i, edict, 4);
				break;
			}
		}
	}
	return;
}
public Action:Command_throwitem(client, args) {
	if(g_bEnabled && g_bThrow) {
		new idx = FindFlag(client, 2);
		if(idx!=-1) {
			new Float:vecStart[3], Float:vecAng[3];
			GetClientEyePosition(client, vecStart);
			GetClientEyeAngles(client, vecAng);
			vecStart[0] += 32.0*Cosine(0.0174532925*vecAng[1]);
			vecStart[1] += 32.0*Sine(0.0174532925*vecAng[1]);
			new Float:playerspeed[3];
			decl Float:velocity[3], Float:ang[3], Float:ang2[3];
			GetClientEyeAngles(client, ang);
			ang2[0] = ang[0];
			ang2[1] = ang[1];
			ang2[2] = ang[2];
			ang[0] *= -1.0;
			ang[0] = DegToRad(ang[0]);
			ang[1] = DegToRad(ang[1]);
			velocity[0] = g_fThrowS*Cosine(ang[0])*Cosine(ang[1]);
			velocity[1] = g_fThrowS*Cosine(ang[0])*Sine(ang[1]);
			velocity[2] = g_fThrowS*Sine(ang[0]);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
			AddVectors(velocity, playerspeed, velocity);
			FakeClientCommand(client, "dropitem");
			new ent = CreateEntityByName("prop_physics_override");
			SetArrayCell(g_hFlags, idx, ent, 3);
			if(IsValidEntity(ent)) {
				new flag = GetArrayCell(g_hFlags, idx);
				SetEntityModel(ent, "models/flag/briefcase.mdl");
				SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
				SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
				//SetEntProp(ent, Prop_Data, "m_usSolidFlags", 16);
				//SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
				DispatchSpawn(ent);
				TeleportEntity(flag, vecStart, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(ent, vecStart, NULL_VECTOR, velocity);
				new String:tName[64];
				Format(tName, sizeof(tName), "TFlag%d", ent);
				DispatchKeyValue(ent, "targetname", tName);
				DispatchKeyValue(ent, "disableshadows", "1");
				SetVariantString(tName);
				AcceptEntityInput(flag, "SetParent");
				AcceptEntityInput(ent, "DisableDamageForces");
				SetEntityRenderMode(ent, RENDER_ENVIRONMENTAL);
				dhHookEntity(ent, EHK_VPhysicsUpdate, ThinkHook);
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Ent_OnDrop(const String:output[], caller, activator, Float:delay) {
	SetFlagState(caller, 2);
}
public Ent_OnPickup(const String:output[], caller, activator, Float:delay) {
	SetFlagState(caller, 1, GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity"));
}
public Ent_OnReturn(const String:output[], caller, activator, Float:delay) {
	SetFlagState(caller, 0);
}
GetFlagState(ent) {
	new idx = FindFlag(ent);
	if(idx!=-1)
		return GetArrayCell(g_hFlags, idx, 1);
	return -1;
}
SetFlagState(ent, value, carrier=-1) {
	new idx = FindFlag(ent);
	if(idx!=-1) {
		SetArrayCell(g_hFlags, idx, value, 1);
		SetArrayCell(g_hFlags, idx, carrier, 2);
		if(value!=2) {
			new physprop = GetArrayCell(g_hFlags, idx, 3);
			if(IsValidEntity(physprop)) {
				if(value==0)
					AcceptEntityInput(GetArrayCell(g_hFlags, idx), "ClearParent");
				RemoveEdict(physprop);
			}
		}
	}
	if(g_bHome) {
		new size = GetArraySize(g_hFlagC), cap, team;
		for(new i=0;i<size;i++) {
			cap = GetArrayCell(g_hFlagC, i);
			team = GetArrayCell(g_hFlagC, i, 1);
			if(team==GetEntProp(ent, Prop_Data, "m_iTeamNum"))
				AcceptEntityInput(cap, value==0?"Enable":"Disable");
		}
	}
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	ClearArray(g_hFlagC);
	new cap = MaxClients+1, capinfo[2];
	while((cap = FindEntityByClassname(cap, "func_capturezone"))!=-1) {
		capinfo[0] = cap;
		capinfo[1] = GetEntProp(cap, Prop_Data, "m_iTeamNum");
		PushArrayArray(g_hFlagC, capinfo);
	}
	CreateTimer(0.01, SetupFlags);
}
public Action:SetupFlags(Handle:timer) {
	ClearArray(g_hFlags);
	ClearArray(g_hFlagO);
	new flag = MaxClients+1, flaginfo[5];
	while((flag = FindEntityByClassname(flag, "item_teamflag"))!=-1) {
		decl String:buffer[32], Float:origin[3];
		Format(buffer, sizeof(buffer), "ReturnTime %i", g_iTimer);
		SetVariantString(buffer);
		AcceptEntityInput(flag, "AddOutput");
		GetEntPropVector(flag, Prop_Send, "m_vecOrigin", origin);
		dhHookEntity(flag, EHK_Touch, TouchHook);
		flaginfo[0] = flag;
		flaginfo[1] = 0;
		flaginfo[2] = -1;
		flaginfo[3] = -1;
		flaginfo[4] = -1;
		PushArrayArray(g_hFlags, flaginfo);
		PushArrayArray(g_hFlagO, origin);
	}
}
Float:DistFromGround(ent) {
	decl Float:vecOrigin[3], Float:vecPos[3], Float:dist; 
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
	new Handle:trace = TR_TraceRayFilterEx(vecOrigin, g_vecDown, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayers, ent); 
	if(TR_DidHit(trace)) { 
		TR_GetEndPosition(vecPos, trace);
		dist = vecOrigin[2]-vecPos[2];
	} else {
		dist = -1.0;
	}
	CloseHandle(trace);
	return dist;
}
FindFlag(comp, block=0) {
	new size = GetArraySize(g_hFlags);
	for(new i=0;i<size;i++)
		if(GetArrayCell(g_hFlags, i, block)==comp)
			return i;
	return -1;
}
public bool:TraceEntityFilterPlayers(entity, contentsMask, any:ent) {
	new idx = FindFlag(ent, 3);
	if(idx!=-1) {
		if(entity==ent || entity==GetArrayCell(g_hFlags, idx) || entity<=MaxClients) {
			return false;
		}
	}
	return true;
}