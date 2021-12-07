// base grab code taken from http://forums.alliedmods.net/showthread.php?t=157075

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define SOUND_GRAB "weapons/physcannon/physcannon_pickup.wav"
#define SOUND_TOSS "weapons/physcannon/superphys_launch3.wav"
#define SOUND_DROP "weapons/physcannon/physcannon_drop.wav"

#define THROW_FORCE 1000.0
#define GRAB_DISTANCE 150.0

#define PLUGIN_NAME     "Admin Grabber"
#define PLUGIN_AUTHOR   "Friagram"
#define PLUGIN_VERSION  "1.0.2"
#define PLUGIN_DESCRIP  "Allows Admins to Grab Stuff"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIP,
	version = PLUGIN_VERSION
};

new g_grabbed[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};              // track client's grabbed object
new Float:gDistance[MAXPLAYERS+1];        // track distance of grabbed object
new bool:g_access[MAXPLAYERS+1];

//////////////////////////////////////////////////////////////////////
/////////////                    Setup                   /////////////
//////////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	CreateConVar("admingrab_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);

	HookEvent("player_death", OnPlayerSpawn);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_team", OnPlayerSpawn);
	HookEvent("entity_killed", OnEntityKilled);
	HookEvent("break_breakable", OnEntityBroke);
	HookEvent("break_prop", OnEntityBroke);

	for (new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public OnConfigsExecuted()
{
	PrecacheSound(SOUND_GRAB, true);
	PrecacheSound(SOUND_TOSS, true);
	PrecacheSound(SOUND_DROP, true);
}

public OnClientPostAdminCheck(client)
{
	if(CheckCommandAccess(client, "admin_grab", ADMFLAG_KICK))
	{
		g_access[client] = true;
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
}

public OnClientPutInServer(client)
{
	g_access[client] = false;
	g_grabbed[client] = INVALID_ENT_REFERENCE;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(g_access[client]){
		char sWeapon[32];
		GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		
		new grabbed = EntRefToEntIndex(g_grabbed[client]);
		if(StrEqual(sWeapon, "weapon_grabber")){
			int active = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			
			if(grabbed != INVALID_ENT_REFERENCE)
			{
				if(buttons & IN_ATTACK){
					TossObject(client, grabbed, true);
					CG_PlaySecondaryAttack(active);
					CG_SetPlayerAnimation(client, PLAYER_ATTACK1);
				}
				else if (buttons & IN_ATTACK2 && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_ATTACK2)){
					TossObject(client, grabbed, false);
					CG_PlayPrimaryAttack(active);
				}
			}
			else
			{
				if(buttons & IN_ATTACK2 && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_ATTACK2)){
					GrabObject(client);
					CG_PlayPrimaryAttack(active);
				}
				else if (buttons & IN_ATTACK && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_ATTACK)){
					GrabObject(client);
					if(grabbed != INVALID_ENT_REFERENCE){
						TossObject(client, grabbed, true);
						CG_PlaySecondaryAttack(active);
						CG_SetPlayerAnimation(client, PLAYER_ATTACK1);
					}
				}
			}
		} else {
			if(grabbed != INVALID_ENT_REFERENCE)
			{
				TossObject(client, grabbed, false);
			}
		}
	}
}

GrabObject(int client)
{
	new grabbed = TraceToObject(client);		// -1 for no collision, 0 for world

	if (grabbed > 0)
	{
		if(IsGrabbed(grabbed))
		{
			return;
		}
		
		if(grabbed <= MaxClients)
		{
			if(!CanAdminTarget(GetUserAdmin(client), GetUserAdmin(grabbed)))
			{
				return;															// can they grab players and admin immunity checks out?
			}

			SetEntityMoveType(grabbed, MOVETYPE_WALK);

			PrintHintText(client,"Grabbing %N",grabbed);
			PrintHintText(grabbed,"%N is grabbing you!",client);
		}
		else
		{
			AcceptEntityInput(grabbed, "EnableMotion");
		}

/* 		if(GetClientButtons(client) & IN_ATTACK2)				// Store and maintain distance
		{
			decl Float:VecPos_grabbed[3], Float:VecPos_client[3];
			GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", VecPos_grabbed);
			GetClientEyePosition(client, VecPos_client);
			gDistance[client] = GetVectorDistance(VecPos_grabbed, VecPos_client);
		}
		else */
		
		gDistance[client] = GRAB_DISTANCE;				// Use prefab distance

		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});

		g_grabbed[client] = EntIndexToEntRef(grabbed);

		EmitSoundToAll(SOUND_GRAB, client);
	}
}


TossObject(client, grabbed, bool:toss)
{
	if(toss)
	{
		new Float:vecView[3], Float:vecFwd[3], Float:vecPos[3], Float:vecVel[3];

		GetClientEyeAngles(client, vecView);
		GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);

		vecPos[0]+=vecFwd[0]*THROW_FORCE;
		vecPos[1]+=vecFwd[1]*THROW_FORCE;
		vecPos[2]+=vecFwd[2]*THROW_FORCE;

		GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", vecFwd);

		SubtractVectors(vecPos, vecFwd, vecVel);
		ScaleVector(vecVel, 10.0);

		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
		
		if(GetEntityMoveType(grabbed) == MOVETYPE_VPHYSICS){
			SetEntPropVector(grabbed, Prop_Data, "m_vecAbsVelocity", Float:{0.0,0.0,0.0}); // velocity (trampoline) fix
		}
	}

	EmitSoundToAll(toss? SOUND_TOSS:SOUND_DROP, client);

	g_grabbed[client] = INVALID_ENT_REFERENCE;
}

//////////////////////////////////////////////////////////////////////
/////////////                  Prethink                  /////////////
//////////////////////////////////////////////////////////////////////

public OnPreThink(client)
{
	new grabbed = EntRefToEntIndex(g_grabbed[client]);
	if (grabbed != INVALID_ENT_REFERENCE)
	{
		decl Float:vecView[3], Float:vecFwd[3], Float:vecPos[3], Float:vecVel[3];

		GetClientEyeAngles(client, vecView);
		GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);

		vecPos[0]+=vecFwd[0]*gDistance[client];
		vecPos[1]+=vecFwd[1]*gDistance[client];
		vecPos[2]+=vecFwd[2]*gDistance[client];

		GetEntPropVector(grabbed, Prop_Send, "m_vecOrigin", vecFwd);

		SubtractVectors(vecPos, vecFwd, vecVel);
		ScaleVector(vecVel, 10.0);

		TeleportEntity(grabbed, NULL_VECTOR, NULL_VECTOR, vecVel);
	}
}

//////////////////////////////////////////////////////////////////////
/////////////                    Events                  /////////////
//////////////////////////////////////////////////////////////////////

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		g_grabbed[client] = INVALID_ENT_REFERENCE;				// Clear their grabs

		for(new i=1; i<=MaxClients; i++)
		{
			if(EntRefToEntIndex(g_grabbed[i]) == client)
			{
				g_grabbed[i] = INVALID_ENT_REFERENCE;				// Clear grabs on them
			}
		}
	}

	return;
}

public OnEntityKilled(Handle event, char[] name, bool dontBroadcast)
{
	int entity = GetEventInt(event, "entindex_killed");
	for(int i=1; i<=MaxClients; i++)
	{
		if(EntRefToEntIndex(g_grabbed[i]) == entity)
		{
			TossObject(i, entity, false);
			return;
		}
	}
	
}

public OnEntityBroke(Handle event, char[] name, bool dontBroadcast)
{
	int entity = GetEventInt(event, "entindex");
	for(int i=1; i<=MaxClients; i++)
	{
		if(EntRefToEntIndex(g_grabbed[i]) == entity)
		{
			TossObject(i, entity, false);
			return;
		}
	}
	
}

bool IsGrabbed(int entity){
	int entref = EntIndexToEntRef(entity);

	for(int i=1; i<=MaxClients; i++)
	{
		if(g_grabbed[i] == entref)
		{
			return true;
		}
	}
	return false;
}

//////////////////////////////////////////////////////////////////////
/////////////                    Trace                   /////////////
//////////////////////////////////////////////////////////////////////

public TraceToObject(client)
{
	new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_SHOT, RayType_Infinite, TraceRayGrab, client);
	return TR_GetEntityIndex(INVALID_HANDLE);
}

public bool:TraceRayGrab(entityhit, mask, any:self)
{
	if( 0 < entityhit <= MaxClients)
	{
		if(IsPlayerAlive(entityhit) && entityhit != self)
		{
			return true;
		}
	}
	else
	{	
		MoveType mtype = GetEntityMoveType(entityhit);
		return mtype == MOVETYPE_VPHYSICS || mtype == MOVETYPE_STEP;
/* 		decl String:classname[13];
		if(GetEntityClassname(entityhit, classname, 13) && (!StrContains(classname, "prop_physics")))
		{
			return true;
		} */
	}

	return false;
}