#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.4"

new Handle:burnAnim;
new Handle:sillyDeaths;
new Handle:cvar_burnAnimChance;

// DEVELOPMENT INFO
// Scout - "primary_death_burning" - 88 frames
// Soldier - "primary_death_burning" - 116 frames
// Pyro - No burning taunt
// Demoman - "PRIMARY_death_burning" - 67 frames
// Heavy - "PRIMARY_death_burning" - 92 frames
// Engineer - "PRIMARY_death_burning" - 103 frames
// Medic - "primary_death_burning" - 100 frames
// Sniper - "primary_death_burning" - 131 frames
// Spy - "primary_death_burning" - 57 frames

new const String:g_Animations[][] = { 
	"primary_death_burning",
	"PRIMARY_death_burning"
};

new isMVM = true;

//These values are used mainly to time when the final ragdoll will be made.
//They can be adjusted to provide a cleaner transition should a better one not be possible.

new const Float:g_AnimationTimes[][] = {
	{ 0.0 } /* Unknown */,
	{ /* 2:28 */ 3.2 } /* Scout */,
	{ /* 4:11 */ 4.7 } /* Sniper */, 	
	{ /* 3:26 */ 4.2 } /* Soldier */,
	{ /* 2:07 */ 2.5 } /* Demoman */,
	{ /* 3:10 */ 3.6 } /* Medic */, 
	{ /* 3:02 */ 3.5 } /* Heavy */,	
	{ /* 0:00 */ 0.0 } /* Pyro */,
	{ /* 1:27 */ 2.2 } /* Spy */,
	{ /* 3:13 */ 3.8 } /* Engineer */
};

new g_ClientAnimEntity[MAXPLAYERS+1] = 0;


public Plugin:myinfo = 
{
	name = "[TF2] Burning Death Animations",
	author = "404: User Not Found / Rowedahelicon",
	description = "Adds in the unused burning death animations.",
	version = PLUGIN_VERSION,
	url = "http://www.unfgaming.net / http://www.rowedahelicon.com"
};

public OnPluginStart()
{	
	CreateConVar("sm_burnanim_version", PLUGIN_VERSION, "[TF2] Burning Death Animations", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	burnAnim = CreateConVar("sm_burnanim", "1", "Enables the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	sillyDeaths = CreateConVar("sm_sillydeaths", "1", "Enables death anims for the scout and the demo.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_burnAnimChance = CreateConVar("sm_burnanim_chance", "1.0", "Chance of animation to play on death (0.0 - 1.0)", FCVAR_PLUGIN);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart() {

	PrecacheGeneric("particles/burningplayer.pcf", true); //This may not be needed, but was at the recommendation to code changes seen in CS:GO.
	isMVM = IsMVM();
}

//-----------------------------------------------------------------------------
// Purpose: Hooking player_death event
//-----------------------------------------------------------------------------
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:rand = GetRandomFloat(0.0, 1.0);
	
	if(GetConVarInt(burnAnim) == 1 && GetConVarFloat(cvar_burnAnimChance) >= rand){
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new customkill = GetEventInt(event, "customkill"); 
	
	// Check if victim is a Pyro
	new TFClassType:victimClass = TF2_GetPlayerClass(victim);
	new team = GetClientTeam(victim);

	if(isMVM){
		if (team == 3) return Plugin_Continue;
	}
	
	
	if (victimClass == TFClass_Pyro || !IsValidClient(attacker) || !(GetEntityFlags(victim) & FL_ONGROUND)) //Will not fire if the victim is a pyro or died in the sky.
	{}else if (GetConVarInt(sillyDeaths) == 0 && (victimClass == TFClass_Scout || victimClass == TFClass_DemoMan)){}else{ //For Silly deaths turned off
	
	// Check if attacker was a Pyro
	
	new TFClassType:attackerClass = TF2_GetPlayerClass(attacker);
	if (attackerClass == TFClass_Pyro)
	{
		switch (customkill)
		{
			case 3, 8, 17, 46, 47, 53: // Burning, Burning Flare, Burning Arrow, Plasma, Plasma Charged, Flare Pellet
			{
				new g_BurnAnim = 0;
				CreateTimer(0.0, RemoveBody, victim);
				AttachNewPlayerModel(victim, g_BurnAnim);
				CreateTimer(g_AnimationTimes[TF2_GetPlayerClass(victim)][g_BurnAnim], Timer_EndBurningDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			}
			default:
			{
			}
		}
	}

	}
	}
	return Plugin_Continue; //Plugin continue needs to happen here otherwise it will hide the event from the killfeed regardless.
}

public Action:RemoveBody(Handle:Timer, any:Client)
{
	decl BodyRagdoll;
	BodyRagdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");
	
	if(IsValidEdict(BodyRagdoll))
	{
		AcceptEntityInput(BodyRagdoll, "kill");
	}
}


//-----------------------------------------------------------------------------
// Purpose: Create fake player model
//-----------------------------------------------------------------------------
public AttachNewPlayerModel(client, g_BurnAnim)
{	
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	if (playerClass == TFClass_Engineer || playerClass == TFClass_DemoMan || playerClass == TFClass_Heavy)
	{
		g_BurnAnim+=1;
	}
		
	new model = CreateEntityByName("prop_dynamic_override");
	if (IsValidEdict(model))
	{
		new Float:pos[3], Float:angles[3];
		decl String:clientmodel[256], String:skin[2];
		
		GetClientModel(client, clientmodel, sizeof(clientmodel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(GetClientTeam(client)-2, skin, sizeof(skin));
		
		DispatchKeyValue(model, "skin", skin);
		DispatchKeyValue(model, "model", clientmodel);
		DispatchKeyValue(model, "DefaultAnim", g_Animations[g_BurnAnim]);	
		DispatchKeyValueVector(model, "angles", angles);
		
		DispatchSpawn(model);
		
		SetVariantString(g_Animations[g_BurnAnim]);
		AcceptEntityInput(model, "SetAnimation");
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(model, "AddOutput");
		
		decl String:SelfDeleteStr[128];
		Format(SelfDeleteStr, sizeof(SelfDeleteStr), "OnUser1 !self:KillHierarchy::%f:1", g_AnimationTimes[TF2_GetPlayerClass(client)][0]+0.1); 
		SetVariantString(SelfDeleteStr);
		AcceptEntityInput(model, "AddOutput");
		
		SetVariantString("");
		AcceptEntityInput(model, "FireUser1");
		
		g_ClientAnimEntity[client] = model;
		
		if (TE_SetupTFParticle("burningplayer_corpse", pos, _, _, model, 3, 0, false))
		TE_SendToAll(0.0); //See note at bottom	
		
		CreateTimer(g_AnimationTimes[TF2_GetPlayerClass(client)][0]-0.4, createNewRagdoll, client);
		
	}
}

public Action:createNewRagdoll(Handle:timer, any:client)
{
	new vteam = GetClientTeam(client);
	new vclass = view_as<int>(TF2_GetPlayerClass(client));
	decl Ent;
	Ent = CreateEntityByName("tf_ragdoll");

	new Float:Vel[3];
	Vel[0] = -18000.552734;
	Vel[1] = -8000.552734;
	Vel[2] = 8000.552734;
	
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", Vel);
	SetEntPropVector(Ent, Prop_Send, "m_vecForce", Vel);

	decl Float:ClientOrigin[3];
	
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin); 
	SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(Ent, Prop_Send, "m_iTeam", vteam);
	SetEntProp(Ent, Prop_Send, "m_iClass", vclass);
	SetEntProp(Ent, Prop_Send, "m_nForceBone", 1);

	SetEntProp(Ent, Prop_Send, "m_bBurning", 1);
	SetEntProp(Ent, Prop_Send, "m_bBecomeAsh", 1);
	DispatchSpawn(Ent);
	CreateTimer(5.0, RemoveRagdoll, Ent);
}

public Action:RemoveRagdoll(Handle:Timer, any:Ent)
{
	if(IsValidEntity(Ent))
	{
		decl String:Classname[64];
		GetEdictClassname(Ent, Classname, sizeof(Classname));
		if(StrEqual(Classname, "tf_ragdoll", false))
		{
			AcceptEntityInput(Ent, "kill");
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose: End burning death timer
//-----------------------------------------------------------------------------
public Action:Timer_EndBurningDeath(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);

	// Kill the prop_dynamic
	if(g_ClientAnimEntity[client] > 0 && IsValidEdict(g_ClientAnimEntity[client]))
	{
		AcceptEntityInput(g_ClientAnimEntity[client], "Kill");
	}
}

//-----------------------------------------------------------------------------
// Purpose: Valid client check stock
//-----------------------------------------------------------------------------

stock bool:IsValidClient(iClient)
	{
		if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
		return true;
	}

//-----------------------------------------------------------------------------
// Purpose: Check if the mode running is MVM
//-----------------------------------------------------------------------------

stock bool:IsMVM()
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i))
		return true;
		return false;
	}

//-----------------------------------------------------------------------------
// Purpose: Gives fire particles to anim models
//-----------------------------------------------------------------------------

stock bool:TE_SetupTFParticle(String:Name[],
			Float:origin[3] = NULL_VECTOR,
			Float:start[3] = NULL_VECTOR,
			Float:angles[3] = NULL_VECTOR,
			entindex = -1,
			attachtype = -1,
			attachpoint = -1,
			bool:resetParticles = true)
	{
	// find string table
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return false;
	}
	
	// find particle index
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	for (new i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return false;
	}
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	
	if (entindex != -1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype != -1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", 1);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
	return true;
	}