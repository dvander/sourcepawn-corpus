#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma newdecls required

#define SOUND_LAUNCH	"misc/doomsday_missile_launch.wav"
#define SOUND_EXPLODE	"misc/doomsday_missile_explosion.wav"

ConVar g_hCvarRadDam;
ConVar g_hCvarNDelay;

public void OnPluginStart()
{
	RegAdminCmd("sm_nuke", Command_Nuke, ADMFLAG_ROOT);
	
	g_hCvarRadDam = CreateConVar("sm_radiation_damage", "10.0", "How much damage to take from the radiation? (Seconds)", _, true, 0.0);
	g_hCvarNDelay = CreateConVar("sm_nuke_delay", "6.1", "How long does it take for the nuke to go boom? (Seconds)", _, true, 0.0);
	
	AutoExecConfig(true, "dd_nuke");
}

public Plugin myinfo = 
{
	name = "[TF2] Doomsday nuke",
	author = "Pelipoika",
	description = "The nuke from sd_doomsday",
	version = "1.2",
	url = "http://www.sourcemod.net/"
}

public void OnMapStart()
{
	PrecacheSound(SOUND_LAUNCH);
	PrecacheSound(SOUND_EXPLODE);
	
	PrecacheGeneric("dooms_nuke_collumn");
	PrecacheGeneric("base_destroyed_smoke_doomsday");
	PrecacheGeneric("flash_doomsday");
	PrecacheGeneric("ping_circle");
	PrecacheGeneric("smoke_marker");
}

public Action Command_Nuke(int client, int args)
{
	float Position[3];
	if(!SetTeleportEndPoint(client, Position))
	{
		PrintToChat(client, "Could not find place.");
		return Plugin_Handled;
	}
	
	//PrintCenterTextAll("A nuke will go off at %.0f%, %.0f%, %.0f% in %.1f% seconds.", Position[0], Position[1], Position[2], g_flCvarNDelay);
	
	int shaker = CreateEntityByName("env_shake");
	if(shaker != -1)
	{
		DispatchKeyValue(shaker, "amplitude", "16");
		DispatchKeyValue(shaker, "radius", "8000");
		DispatchKeyValue(shaker, "duration", "4");
		DispatchKeyValue(shaker, "frequency", "20");
		DispatchKeyValue(shaker, "spawnflags", "4");
		
		TeleportEntity(shaker, Position, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(shaker);
		AcceptEntityInput(shaker, "StartShake");
		CreateTimer(10.0, Timer_Delete, EntIndexToEntRef(shaker)); 
	}
	
	EmitSoundToAll(SOUND_LAUNCH);
	ShowParticle(Position, "ping_circle", 5.0);
	ShowParticle(Position, "smoke_marker", 5.0);
	
	DataPack pack;
	CreateDataTimer(g_hCvarNDelay.FloatValue, Timer_NukeHitsHere, pack);
	pack.WriteFloat(Position[0]);	//Position of effects
	pack.WriteFloat(Position[1]);
	pack.WriteFloat(Position[2]);

	return Plugin_Handled;
}

public Action Timer_NukeHitsHere(Handle timer, DataPack pack)
{
	pack.Reset();

	float pos[3], Flash[3], Collumn[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	Flash[0] = pos[0];
	Flash[1] = pos[1];
	Flash[2] = pos[2];
	
	Collumn[0] = pos[0];
	Collumn[1] = pos[1];
	Collumn[2] = pos[2];
	
	pos[2] += 6.0;
	Flash[2] += 236.0;
	Collumn[2] += 1652.0;

	EmitSoundToAll(SOUND_EXPLODE);

	ShowParticle(pos, "base_destroyed_smoke_doomsday", 30.0);
	ShowParticle(Flash, "flash_doomsday", 10.0);
	ShowParticle(Collumn, "dooms_nuke_collumn", 30.0);

	int shaker = CreateEntityByName("env_shake");
	if(shaker != -1)
	{
		DispatchKeyValue(shaker, "amplitude", "50");
		DispatchKeyValue(shaker, "radius", "8000");
		DispatchKeyValue(shaker, "duration", "4");
		DispatchKeyValue(shaker, "frequency", "50");
		DispatchKeyValue(shaker, "spawnflags", "4");

		TeleportEntity(shaker, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(shaker, "StartShake");
		DispatchSpawn(shaker);
		
		CreateTimer(10.0, Timer_Delete, EntIndexToEntRef(shaker)); 
	}
	
	int iBomb = CreateEntityByName("tf_generic_bomb");
	DispatchKeyValueVector(iBomb, "origin", pos);
	DispatchKeyValueFloat(iBomb, "damage", 999999.0);
	DispatchKeyValueFloat(iBomb, "radius", 1200.0);
	DispatchKeyValue(iBomb, "health", "1");
	DispatchSpawn(iBomb);

	AcceptEntityInput(iBomb, "Detonate");

	if(GetConVarFloat(g_hCvarRadDam) != 0.0)
	{
		DataPack radiation;
		CreateDataTimer(0.2, Timer_PerformRadiation, radiation, TIMER_REPEAT); // the timer will repeat each 1.0 second until it returns Plugin_Stop
		radiation.WriteFloat(pos[0]);	//Position of effects
		radiation.WriteFloat(pos[1]);
		radiation.WriteFloat(pos[2]);
		radiation.WriteCell(18);		//Remaining repeats
	}
}

public Action Timer_PerformRadiation(Handle timer, DataPack radiation) 
{
	radiation.Reset();
	
	float pos[3];
	int repeats = radiation.ReadCell();
	
	pos[0] = radiation.ReadFloat();
	pos[1] = radiation.ReadFloat();
	pos[2] = radiation.ReadFloat();
	
	if (repeats == 0) return Plugin_Stop; // return Plugin_Stop if we've finished radiating
	repeats -= 1;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		float zPos[3];
		GetClientAbsOrigin(i, zPos);
		float Dist = GetDistanceTotal(pos, zPos);
		if (Dist > 1200.0) continue;
		SDKHooks_TakeDamage(i, i, i, g_hCvarRadDam.FloatValue, DMG_PREVENT_PHYSICS_FORCE|DMG_RADIATION);
	}
	
	radiation.Reset(true);
	radiation.WriteFloat(pos[0]);	//Position of effects
	radiation.WriteFloat(pos[1]);
	radiation.WriteFloat(pos[2]);
	radiation.WriteCell(repeats);		//Remaining repeats

	return Plugin_Continue;
}

public void ShowParticle(float pos[3], char[] particlename, float time)
{
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
}

public Action DeleteParticles(Handle timer, any particle)
{
	int ent = EntRefToEntIndex(particle);

	if (ent != INVALID_ENT_REFERENCE)
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			AcceptEntityInput(ent, "kill");
	}
}

public Action Timer_Delete(Handle hTimer, any iRefEnt) 
{ 
	int iEntity = EntRefToEntIndex(iRefEnt); 
	if(iEntity > MaxClients) 
	{
		AcceptEntityInput(iEntity, "Kill"); 
		AcceptEntityInput(iEntity, "StopShake");
	}
	 
	return Plugin_Handled; 
}

stock float GetDistanceTotal(float vec1[3], float vec2[3])
{
	float vec[3];
	for (int i = 0; i < 3; i++)
	{
		vec[i] = (vec1[i] > vec2[i]) ? vec1[i] - vec2[i] : vec2[i] - vec1[i];
	}
	
	return SquareRoot(Pow(vec[0], 2.0) + Pow(vec[1], 2.0) + Pow(vec[2], 2.0));
}

bool SetTeleportEndPoint(int client, float Position[3])
{
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer2);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		Position[0] = vStart[0] + (vBuffer[0]*Distance);
		Position[1] = vStart[1] + (vBuffer[1]*Distance);
		Position[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool TraceEntityFilterPlayer2(int entity, int contentsMask)
{
	return entity > GetMaxClients() || !entity;
}