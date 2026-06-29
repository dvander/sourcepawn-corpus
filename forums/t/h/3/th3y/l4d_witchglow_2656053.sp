#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new iGlowEnt[2048];
new Handle:g_WitchTimer[2048] = INVALID_HANDLE;
new Handle:hWGlowTeam = INVALID_HANDLE;

static bool:IsValidEntRef(entity)
{
	return entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE; 
}

public Plugin:myinfo =
{
	name = "L4D1 Witch Glow!",
	author = "Rahzel [JNC]",
	description = "Set glow on witch",
	version = "0.4",
	url = "http://steamcommunity.com/profiles/76561198015203990/"
};

public OnPluginStart()
{
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("witch_killed", Event_WitchKilled);
	hWGlowTeam = CreateConVar("l4d_witchglow_team", "3", "-1: All Teams, 1: Only Spectator, 2:  Survivor, 3: Infected");
} 

public OnMapStart()
{
	PrecacheModel("models/infected/witch.mdl");
}

public Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new WitchID = GetEventInt(event, "witchid");
	CreatePGlow(WitchID);
}

CreatePGlow(witch)
{
	decl Float:vPos[3], Float:vAng[3], String:sTeam[4];
	GetEntPropVector(witch, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(witch, Prop_Send, "m_angRotation", vAng);
	new prop = CreateEntityByName("prop_glowing_object");
	
	if (prop != 1) {
		
		DispatchKeyValue(prop, "model", "models/infected/witch.mdl");
		DispatchKeyValue(prop, "StartGlowing", "1");
		
		GetConVarString(hWGlowTeam, sTeam, sizeof(sTeam));
		DispatchKeyValue(prop, "GlowForTeam", sTeam);
		DispatchKeyValue(prop, "DefaultAnim", "Idle_Sitting");
		DispatchKeyValue(prop, "fadescale", "1");
		DispatchKeyValue(prop, "fademindist", "3000");
		DispatchKeyValue(prop, "fademaxdist", "3200");
		
		DispatchSpawn(prop);
		TeleportEntity(prop, vPos, vAng, NULL_VECTOR);
		SetEntityRenderFx(prop, RENDERFX_FADE_FAST);
		
		ActivateEntity(prop);
		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", witch);
		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetAttached", witch);
		
		iGlowEnt[witch] = EntIndexToEntRef(prop);
		g_WitchTimer[witch] = CreateTimer(0.1, tFollowAnim, witch, TIMER_REPEAT  | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:tFollowAnim(Handle:timer, any:witch)
{	
	if (IsValidEntity(witch) && IsValidEntRef(iGlowEnt[witch])) {
		decl Float:fPosePam[5], Float:fCycle;
		new nSequence, nAnimTime;

		fPosePam[0] = GetEntPropFloat( witch, Prop_Send, "m_flPoseParameter", 0 ); 
		fPosePam[1] = GetEntPropFloat( witch, Prop_Send, "m_flPoseParameter", 1 ); 
		fPosePam[2] = GetEntPropFloat( witch, Prop_Send, "m_flPoseParameter", 2 ); 
		fPosePam[3] = GetEntPropFloat( witch, Prop_Send, "m_flPoseParameter", 3 ); 
		fPosePam[4] = GetEntPropFloat( witch, Prop_Send, "m_flPoseParameter", 4 ); 
		
		fCycle = GetEntPropFloat( witch, Prop_Send, "m_flCycle");
		nSequence = GetEntProp(witch, Prop_Send, "m_nSequence");
		nAnimTime = GetEntProp( witch, Prop_Send, "m_flAnimTime"); 
		
		SetEntPropFloat(iGlowEnt[witch], Prop_Send, "m_flPoseParameter", fPosePam[0], 0);
		SetEntPropFloat(iGlowEnt[witch], Prop_Send, "m_flPoseParameter", fPosePam[1], 1);
		SetEntPropFloat(iGlowEnt[witch], Prop_Send, "m_flPoseParameter", fPosePam[2], 2);
		SetEntPropFloat(iGlowEnt[witch], Prop_Send, "m_flPoseParameter", fPosePam[3], 3);
		SetEntPropFloat(iGlowEnt[witch], Prop_Send, "m_flPoseParameter", fPosePam[4], 4);

		SetEntPropFloat(iGlowEnt[witch], Prop_Send, "m_flCycle", fCycle);
		SetEntProp(iGlowEnt[witch], Prop_Send, "m_nSequence", nSequence);
		SetEntProp(iGlowEnt[witch], Prop_Send, "m_flAnimTime", nAnimTime);
		
	}else {
		
		if (IsValidEntRef(iGlowEnt[witch])){
			AcceptEntityInput(iGlowEnt[witch], "Kill");
			iGlowEnt[witch] = 0;
			//PrintToServer("removing %i", iGlowEnt[witch]);
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new WitchID = GetEventInt(event, "witchid");
	if (IsValidEntRef(iGlowEnt[WitchID])) {
		KillGlowTimer(WitchID);
		//AcceptEntityInput("Kill")(iGlowEnt[WitchID]);
		AcceptEntityInput(iGlowEnt[WitchID], "Kill");
		//PrintToServer("removing from kill %i", iGlowEnt[WitchID]);
		iGlowEnt[WitchID] = 0;
	}
}


KillGlowTimer(entity)
{
	if (g_WitchTimer[entity] != INVALID_HANDLE) {
		KillTimer(g_WitchTimer[entity], false);
		g_WitchTimer[entity] = INVALID_HANDLE;
	}	
}
