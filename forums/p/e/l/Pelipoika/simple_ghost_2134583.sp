#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#pragma semicolon 1

new bool:g_bInvisible[2049];
new MapStarted = false;

new Handle:fwdCanBeScared = INVALID_HANDLE;

new Handle:g_hCvarMinVisible,	Float:g_flCvarMinVisible;
new Handle:g_hCvarMaxVisible,	Float:g_flCvarMaxVisible;

new Handle:g_hCvarMinInVisible,	Float:g_flCvarMinInVisible;
new Handle:g_hCvarMaxInVisible,	Float:g_flCvarMaxInVisible;

new Handle:g_hCvarStunDur,		Float:g_flCvarStunDur;
new Handle:g_hCvarCheckDelay,	Float:g_flCvarCheckDelay;
new Handle:g_hCvarCheckDistance,Float:g_flCvarCheckDistance;

static const String:strGhostMoans[][64] = 
{
	"vo/halloween_moan1.wav",
	"vo/halloween_moan2.wav",
	"vo/halloween_moan3.wav",
	"vo/halloween_moan4.wav"
};
static const String:strGhostBoos[][64] = 
{
	"vo/halloween_boo1.wav",
	"vo/halloween_boo2.wav",
	"vo/halloween_boo3.wav",
	"vo/halloween_boo4.wav",
	"vo/halloween_boo5.wav",
	"vo/halloween_boo6.wav",
	"vo/halloween_boo7.wav"
};
static const String:strGhostEffects[][64] = 
{
	"vo/halloween_haunted1.wav",
	"vo/halloween_haunted2.wav",
	"vo/halloween_haunted3.wav",
	"vo/halloween_haunted4.wav",
	"vo/halloween_haunted5.wav"
};

public Plugin:myinfo = 
{
	name = "[TF2] Simple_Ghost",
	author = "Pelipoika",
	description = "Allows you to spawn a simple_bot & ghost hybrid",
	version = "1.3",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_simpleghost", Command_SpawnBot, ADMFLAG_ROOT);
	RegAdminCmd("sm_killghost", Command_KillBot, ADMFLAG_ROOT);
	
	g_hCvarMinVisible = CreateConVar("sm_ghost_minvistime", "5.0", "Minimum duration to stay visible", FCVAR_PLUGIN, true, 0.0);
	g_flCvarMinVisible = GetConVarFloat(g_hCvarMinVisible);
	HookConVarChange(g_hCvarMinVisible, OnConVarChange);
	
	g_hCvarMaxVisible = CreateConVar("sm_ghost_maxvistime", "10.0", "Maximum duration to stay visible", FCVAR_PLUGIN, true, 0.0);
	g_flCvarMaxVisible = GetConVarFloat(g_hCvarMaxVisible);
	HookConVarChange(g_hCvarMaxVisible, OnConVarChange);

//	----------------------------------------------------------------------------------------------------------------------------------
	
	g_hCvarMinInVisible = CreateConVar("sm_ghost_mininvistime", "60.0", "Minimum duration to stay invisible", FCVAR_PLUGIN, true, 0.0);
	g_flCvarMinInVisible = GetConVarFloat(g_hCvarMinInVisible);
	HookConVarChange(g_hCvarMinInVisible, OnConVarChange);
	
	g_hCvarMaxInVisible = CreateConVar("sm_ghost_maxinvistime", "120.0", "Maximum duration to stay invisible", FCVAR_PLUGIN, true, 0.0);
	g_flCvarMaxInVisible = GetConVarFloat(g_hCvarMaxInVisible);
	HookConVarChange(g_hCvarMaxInVisible, OnConVarChange);
	
//	----------------------------------------------------------------------------------------------------------------------------------
	
	g_hCvarStunDur = CreateConVar("sm_ghost_stunduration", "5.0", "Duration of the 'BOO!' condition on client", FCVAR_PLUGIN, true, 0.0);
	g_flCvarStunDur = GetConVarFloat(g_hCvarStunDur);
	HookConVarChange(g_hCvarStunDur, OnConVarChange);
	
	g_hCvarCheckDelay = CreateConVar("sm_ghost_checkdelay", "0.1", "How often to check for nearby clients to Spook", FCVAR_PLUGIN, true, 0.0);
	g_flCvarCheckDelay = GetConVarFloat(g_hCvarCheckDelay);
	HookConVarChange(g_hCvarCheckDelay, OnConVarChange);
	
	g_hCvarCheckDistance = CreateConVar("sm_ghost_checkdistance", "240.0", "How far away to stun clients", FCVAR_PLUGIN, true, 0.0);
	g_flCvarCheckDistance = GetConVarFloat(g_hCvarCheckDistance);
	HookConVarChange(g_hCvarCheckDistance, OnConVarChange);
	
	AutoExecConfig(true, "simple_ghost");
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	g_flCvarMaxVisible = GetConVarFloat(g_hCvarMaxVisible);
	g_flCvarMinVisible = GetConVarFloat(g_hCvarMinVisible);
	
	g_flCvarMaxInVisible = GetConVarFloat(g_hCvarMaxInVisible);
	g_flCvarMinInVisible = GetConVarFloat(g_hCvarMinInVisible);
	
	g_flCvarStunDur = GetConVarFloat(g_hCvarStunDur);
	g_flCvarCheckDelay = GetConVarFloat(g_hCvarCheckDelay);
	g_flCvarCheckDistance = GetConVarFloat(g_hCvarCheckDistance);
}

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	fwdCanBeScared = CreateGlobalForward("TF2SG_CanBeScared", ET_Hook, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public OnMapStart() 
{ 
	PrecacheModel("models/humans/group01/female_01.mdl", true); //Simple_bots default model
	PrecacheModel("models/props_halloween/ghost.mdl", true);	//Ghost model itself
	PrecacheModel("ghost_appearation", true);					//Ghost appear & disappear particle

	PrecacheSounds(strGhostMoans, sizeof(strGhostMoans));
	PrecacheSounds(strGhostBoos, sizeof(strGhostBoos));
	PrecacheSounds(strGhostEffects, sizeof(strGhostEffects));
	
	MapStarted = true;
}

public OnMapEnd()
{
	MapStarted = false;
}

public Action:Command_SpawnBot(client, args)
{
	if(IsValidClient(client))
	{
		new Float:pos[3]; 
		GetClientEyePosition(client, pos); 
		new Ghost = CreateEntityByName("simple_bot"); 
		if(Ghost > 0 || Ghost < 2048) 
		{
			DispatchKeyValue(Ghost, "targetname", "spookyghostthatcanberemoved");  
			DispatchSpawn(Ghost); 
			SetEntProp(Ghost, Prop_Data, "m_takedamage", 0, 1);
			SetEntProp(Ghost, Prop_Send, "m_CollisionGroup", 2);
			TeleportEntity(Ghost, pos, NULL_VECTOR, NULL_VECTOR); 
			AttachParticle(Ghost, "ghost_appearation", _, 5.0);
			SetEntityModel(Ghost, "models/props_halloween/ghost.mdl");
			g_bInvisible[Ghost] = false;
			CreateTimer(GetRandomFloat(g_flCvarMinVisible, g_flCvarMaxVisible), Timer_ToggleInvis, EntIndexToEntRef(Ghost));
			new flags = GetEntityFlags(Ghost) | FL_NOTARGET;
			SetEntityFlags(Ghost, flags);
			SDKHook(Ghost, SDKHook_Touch, GhostThink); 
		} 
	}
	
	return Plugin_Handled;
}

public Action:Command_KillBot(client, args)
{
	if(IsValidClient(client))
	{
		new ghost = -1;
		while ((ghost = FindEntityByClassname(ghost, "simple_bot")) != -1)
		{
			if (IsValidEntity(ghost))
			{
				decl String:name[32];
				GetEntPropString(ghost, Prop_Data, "m_iName", name, 128, 0);
				if(StrEqual(name, "spookyghostthatcanberemoved")) 
				{
					PrintToChat(client, "Deleted Ghost..");
					AcceptEntityInput(ghost, "Kill");
				}
			}
		}
	}
	return Plugin_Handled;
}

public GhostThink(entity)
{
	if(!IsValidEntity(entity))
	{
		SDKUnhook(entity, SDKHook_Touch, GhostThink);
		return;
	}
	
	if (entity <= 0 || entity > 2048) return;
	
	static Float:flLastCall;
	if(GetEngineTime() - g_flCvarCheckDelay <= flLastCall)
		return;
	
	flLastCall = GetEngineTime();
	
	new iClient, Float:vecGhostOrigin[3], Float:vecClientOrigin[3], Float:flDistance;
	
	if (IsValidEntity(entity) && !g_bInvisible[entity])
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecGhostOrigin); 
		
		for(iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsValidClient(iClient))
			{
				GetClientAbsOrigin(iClient, vecClientOrigin);
				flDistance = GetVectorDistance(vecGhostOrigin, vecClientOrigin);
				if(flDistance < 0)
					flDistance *= -1.0;
				if(flDistance <= g_flCvarCheckDistance)
					ScarePlayer(entity, iClient);
			}
		}
	}
}

public Action:Timer_ToggleInvis(Handle:timer, any:entity) 
{
	new ent = EntRefToEntIndex(entity);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		decl String:sClass[32];
		GetEntityClassname(ent, sClass, sizeof(sClass));
	
		if(StrEqual(sClass, "simple_bot"))
		{
			//new Float:rand = GetRandomFloat(5.0, 10.0);
		
			if(!g_bInvisible[ent])	//Invisible
			{
				AttachParticle(ent, "ghost_appearation", _, 5.0);
				
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, _, _, _, 0);
				SetVariantString("ParticleEffectStop");
				AcceptEntityInput(ent, "DispatchEffect");
				
				EmitSoundToAll(strGhostEffects[GetRandomInt(0, sizeof(strGhostEffects)-1)], ent);
				SetEntityModel(ent, "models/humans/group01/female_01.mdl");
				
				CreateTimer(GetRandomFloat(g_flCvarMinInVisible, g_flCvarMaxInVisible), Timer_ToggleInvis, EntIndexToEntRef(ent));
				//PrintToChatAll("[INVISIBLE] Turning visible in %.1f seconds", rand);
				//CreateTimer(rand, Timer_ToggleInvis, EntIndexToEntRef(ent));
				
				g_bInvisible[ent] = true;
			}
			else					//Visible
			{
				SetEntityModel(ent, "models/props_halloween/ghost.mdl");
				
				AttachParticle(ent, "ghost_appearation", _, 5.0);
				
				SetEntityRenderColor(ent, _, _, _, 255);
				SetEntityRenderMode(ent, RENDER_NORMAL);
				
				EmitSoundToAll(strGhostMoans[GetRandomInt(0, sizeof(strGhostMoans)-1)], ent);
				EmitSoundToAll(strGhostEffects[GetRandomInt(0, sizeof(strGhostEffects)-1)], ent);
				
				CreateTimer(GetRandomFloat(g_flCvarMinVisible, g_flCvarMaxVisible), Timer_ToggleInvis, EntIndexToEntRef(ent));
				//PrintToChatAll("[VISIBLE] Turning invisible in %.1f seconds", rand);
				//CreateTimer(rand, Timer_ToggleInvis, EntIndexToEntRef(ent));
				
				g_bInvisible[ent] = false;
			}
		}
	}
}

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flZOffset=0.0, Float:flSelfDestruct=0.0) 
{ 
	if (MapStarted)
	{
		new iParticle = CreateEntityByName("info_particle_system"); 
		if(!IsValidEdict(iParticle))
			return 0; 
		 
		new Float:flPos[3]; 
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos); 
		flPos[2] += flZOffset; 
		 
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR); 
		
		DispatchKeyValue(iParticle, "targetname", "killme%dp@later");
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect); 
		DispatchSpawn(iParticle); 
		 
		SetVariantString("!activator"); 
		AcceptEntityInput(iParticle, "SetParent", iEntity); 
		ActivateEntity(iParticle); 
		 
		if(strlen(strAttachPoint)) 
		{ 
			SetVariantString(strAttachPoint); 
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset"); 
		} 
		
		AcceptEntityInput(iParticle, "start");

		if(flSelfDestruct > 0.0) 
			CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle)); 

		return iParticle; 
	}
	return 0;
} 

public Action:Timer_DeleteParticle(Handle:timer, any:iRefEnt) 
{ 
    new iEntity = EntRefToEntIndex(iRefEnt); 
    if(iEntity > MaxClients) 
        AcceptEntityInput(iEntity, "Kill"); 
     
    return Plugin_Handled; 
}

ScarePlayer(iGhost, iClient)	//From Leonardos 'Be The Ghost' Plugin
{
	static Float:flLastScare[MAXPLAYERS+1];
	static Float:flLastBoo;
	
	if(!IsValidEntity(iGhost) || !IsValidClient(iClient))
		return;
	
	new Action:result;
	Call_StartForward(fwdCanBeScared);
	Call_PushCell(iGhost);
	Call_PushCell(iClient);
	Call_Finish(result);
	if(result >= Plugin_Handled)
		return;
	
	if((GetEngineTime() - g_flCvarStunDur) <= flLastScare[iClient])
		return;
	flLastScare[iClient] = GetEngineTime();
	
	if( GetEngineTime() - 1.0 > flLastBoo )
	{
		flLastBoo = GetEngineTime();
		EmitSoundToAll( strGhostBoos[ GetRandomInt( 0, sizeof(strGhostBoos)-1 ) ], iGhost );
	}
	
	new Handle:hData;
	CreateDataTimer( 0.5, Timer_StunPlayer, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE );
	WritePackCell( hData, iClient );
}

public Action:Timer_StunPlayer(Handle:hTimer, any:hData)	//From Leonardos 'Be The Ghost' Plugin
{
	ResetPack(hData);
	new iClient = ReadPackCell(hData);
	if(IsValidClient(iClient))
		TF2_StunPlayer(iClient, g_flCvarStunDur, _, TF_STUNFLAGS_GHOSTSCARE);
		
	return Plugin_Stop;
}

stock PrecacheSounds(const String:strSounds[][], iArraySize)
{
	for(new i = 0; i < iArraySize; i++)
		if(!PrecacheSound(strSounds[i]))
			PrintToChatAll("Faild to precache sound: %s", strSounds[i]);
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}