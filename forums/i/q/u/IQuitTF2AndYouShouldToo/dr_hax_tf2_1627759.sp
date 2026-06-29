#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <smlib\server>

#define PLUGIN_VERSION "1.0"

new Handle:cHaxEnabled = INVALID_HANDLE;

#define DISTANCE 40.0
#define FORCE 50000.0

#define HAX_MODEL "models/props_lab/monitor01a.mdl"
#define HAX_SOUND "vo/npc/male01/hacks01.wav"

public Plugin:myinfo =
{
	name = "Dr.Hax",
	author = "Push (modified by none of your business)",
	description = "Fell yourself as Dr.Hax",
	version = PLUGIN_VERSION,
	url = "http://css-quad.ru"
};

public OnPluginStart()
{
	cHaxEnabled = CreateConVar("drhax_enabled", "1", "Enable the plugin");
	
	CreateConVar("drhax_version", PLUGIN_VERSION, "Dr.Hax", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_hax", Command_Hax, ADMFLAG_BAN);
}

public OnConfigsExecuted()
{
	PrecacheModel(HAX_MODEL);
	PrecacheSound(HAX_SOUND, true);
}

public Action:Command_Hax(client, args)
{
	if(GetConVarBool(cHaxEnabled))
	{
		if(IsPlayerAlive(client))
		{
			new Float:fPlayerPos[3];
			new Float:fPlayerAngles[3];
			new Float:fThrowingVector[3];
			
			GetClientEyeAngles(client, fPlayerAngles);
			GetClientEyePosition(client, fPlayerPos);
			
			EmitAmbientSound(HAX_SOUND, fPlayerPos, _, _, _, 3.0);
			
			new Float:fLen = DISTANCE * Sine(DegToRad(fPlayerAngles[0] + 90.0));
		
			fPlayerPos[0] = fPlayerPos[0] + fLen * Cosine(DegToRad(fPlayerAngles[1]));
			fPlayerPos[1] = fPlayerPos[1] + fLen * Sine(DegToRad(fPlayerAngles[1]));
			fPlayerPos[2] = fPlayerPos[2] + DISTANCE * Sine(DegToRad(-1 * fPlayerAngles[0]));
			
			new Entity = CreateEntityByName("prop_physics");
			
			DispatchKeyValue(Entity, "model", HAX_MODEL);
			DispatchKeyValue(Entity, "Mass Scale", "5000");
			
			DispatchSpawn(Entity);
			ActivateEntity(Entity);
		
			fThrowingVector[0] = Cosine(DegToRad(fPlayerAngles[1]));
			fThrowingVector[1] = Sine(DegToRad(fPlayerAngles[1]));
			fThrowingVector[2] = Sine(DegToRad(-1 * fPlayerAngles[0]));
			
			new Float:fScal = FORCE * Sine(DegToRad(fPlayerAngles[0] + 90.0));
			
			fThrowingVector[0] *= fScal;
			fThrowingVector[1] *= fScal;
			fThrowingVector[2] = FORCE * Sine(DegToRad(-1 * fPlayerAngles[0]));
			
			TeleportEntity(Entity, fPlayerPos, fPlayerAngles, fThrowingVector);
			
			CreateTimer(3.0, OnTimerTick, Entity);
		}
	}
	return Plugin_Handled;
}

public Action:OnTimerTick(Handle:hTimer, any:data)
{
	Dissolve(data);
	
	return Plugin_Continue;
}

stock void:Dissolve(edict)
{
	if(IsValidEntity(edict))
	{
		new String:dname[32], ent = CreateEntityByName("env_entity_dissolver");
		
		Format(dname, sizeof(dname), "dis_%d", edict);
		
		if (ent > 0)
		{
			DispatchKeyValue(edict, "targetname", dname);
			DispatchKeyValue(ent, "dissolvetype", "3");
			DispatchKeyValue(ent, "target", dname);
			AcceptEntityInput(ent, "Dissolve");
			AcceptEntityInput(ent, "kill");
		}
	}
}
