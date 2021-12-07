#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MODEL_DECOYT "models/player/t_arctic.mdl"
#define MODEL_DECOYCT "models/player/ct_urban.mdl"
#define PLUGIN_VERSION "0.6"
#define SOUND_PLACE "weapons/pinpull.wav"

public Plugin:myinfo =
{
	name = "Cr(+)sshair's Decoy Mod",
	author = "Cr(+)sshair",
	description = "Type !decoy in chat to place a decoy!",
	version = PLUGIN_VERSION,
	url = "http://www.hellsgamers.com/"
};

new Float:gDecoyWait[MAXPLAYERS+1];
new Handle:cvarDecoyDeploy = INVALID_HANDLE;
new Handle:cvarDecoyLife = INVALID_HANDLE;
new Handle:cvarDecoyDamage = INVALID_HANDLE;
new Handle:cvarDecoyRadius = INVALID_HANDLE;
new Handle:cvarDecoyModelT = INVALID_HANDLE;
new Handle:cvarDecoyModelCT = INVALID_HANDLE;
new String:decoymodelT[256];
new String:decoymodelCT[256];

public OnPluginStart()
{
	RegConsoleCmd("decoy", Command_Decoy);
	HookEvent("round_start", EvRoundStart);
	CreateConVar("sm_decoy_version", PLUGIN_VERSION, "Decoy Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarDecoyDeploy = CreateConVar("sm_decoy_wait", "240", "Decoy deploy time restriction.Def240");
	cvarDecoyLife = CreateConVar("sm_decoy_exists", "60", "Countdown until explosion. Def60");
	cvarDecoyDamage = CreateConVar("sm_decoydamage", "25", "Explosion damage");
	cvarDecoyRadius = CreateConVar("sm_decoyshrapnel", "25", "Shrapnel range.");
	cvarDecoyModelT = CreateConVar("sm_model_of_decoyT", MODEL_DECOYT, "Terrorist Skin Model");
	cvarDecoyModelCT = CreateConVar("sm_model_of_decoyCT", MODEL_DECOYCT, "CT Skin Model");
	
	AutoExecConfig(true);
	
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		gDecoyWait[i] = -1000.0;
	}
	PrecacheSound(SOUND_PLACE, true);
}

public OnConfigsExecuted()
{
	GetConVarString(cvarDecoyModelT, decoymodelT, sizeof(decoymodelT));
	PrecacheModel(decoymodelT, true);
	GetConVarString(cvarDecoyModelCT, decoymodelCT, sizeof(decoymodelCT));
	PrecacheModel(decoymodelCT, true);
}

public EvRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, Display);
}

public Action:Display(Handle:timer)
{
	
	PrintToChatAll("\x04[Cr(+)sshair's Decoy Mod]\x01 Type !decoy in chat to deploy a decoy hologram trap!");
}

public Action:Command_Decoy(client, args) 
{
	if (!IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	new Float:time = GetEngineTime();
	
	if (time<gDecoyWait[client])
	{
		PrintToChat(client, "\x04[Cr(+)sshair's Decoy Mod]\x01 You must wait another %d seconds to use a holographic decoy trap!", RoundToCeil(gDecoyWait[client]-time));
		return Plugin_Handled;
	}
	gDecoyWait[client] = time + GetConVarFloat(cvarDecoyDeploy);
	
	new Float:place[3];
	
	GetClientAbsOrigin(client, place);
	
	new Float:angle[3];
	new Float:place2[3];
	new Float:secondpos[3];
	
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, secondpos, NULL_VECTOR, NULL_VECTOR);
	
	place[0] += 100.0;
	place2[0] = 0.0;
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", secondpos);
	AddVectors(place2, secondpos, place2);
	
	new team = GetClientTeam(client);  
	
	if (!IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	new entity = CreateEntityByName("prop_dynamic");
	
	if (IsValidEntity(entity))
	{
		if (team == 2)
		{
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 0, 0, 255);
		new String:temp[256];
		SetEntityModel(entity, decoymodelT);
		SetEntityMoveType(entity, MOVETYPE_NONE);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 5);
		SetEntProp(entity, Prop_Data, "m_usSolidFlags", 16);
		SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
		SetEntityGravity(entity, 10.0);
		DispatchSpawn(entity);
		TeleportEntity(entity, place, NULL_VECTOR, place2);
		SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client);
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:break::%f:1", GetConVarFloat(cvarDecoyLife));
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		GetConVarString(cvarDecoyRadius, temp, sizeof(temp));
		DispatchKeyValue(entity, "ExplodeRadius", temp);
		GetConVarString(cvarDecoyDamage, temp, sizeof(temp));
		DispatchKeyValue(entity, "ExplodeDamage", temp);
		Format(temp, sizeof(temp), "!self,Break,,0,-1");
		DispatchKeyValue(entity, "OnHealthChanged", temp);
		Format(temp, sizeof(temp), "!self,Kill,,0,-1");
		DispatchKeyValue(entity, "OnBreak", temp);
		EmitSoundToAll(SOUND_PLACE, client);
			}
			else
			{
		
		new entity2 = CreateEntityByName("prop_dynamic");
		SetEntityRenderMode(entity2, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity2, 0, 0, 255, 255);
		
		new String:temp[256];
		
		SetEntityModel(entity2, decoymodelCT);
		SetEntityMoveType(entity2, MOVETYPE_NONE);
		SetEntProp(entity2, Prop_Data, "m_CollisionGroup", 5);
		SetEntProp(entity2, Prop_Data, "m_usSolidFlags", 16);
		SetEntProp(entity2, Prop_Data, "m_nSolidType", 6);
		SetEntityGravity(entity2, 10.0);
		DispatchSpawn(entity2);
		TeleportEntity(entity2, place, NULL_VECTOR, place2);
		SetEntPropEnt(entity2, Prop_Data, "m_hLastAttacker", client);
		
		new String:addoutput[64];
		
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:break::%f:1", GetConVarFloat(cvarDecoyLife));
		SetVariantString(addoutput);
		AcceptEntityInput(entity2, "AddOutput");
		AcceptEntityInput(entity2, "FireUser1");
		GetConVarString(cvarDecoyRadius, temp, sizeof(temp));
		DispatchKeyValue(entity2, "ExplodeRadius", temp);
		GetConVarString(cvarDecoyDamage, temp, sizeof(temp));
		DispatchKeyValue(entity2, "ExplodeDamage", temp);
		Format(temp, sizeof(temp), "!self,Break,,0,-1");
		DispatchKeyValue(entity2, "OnHealthChanged", temp);
		Format(temp, sizeof(temp), "!self,Kill,,0,-1");
		DispatchKeyValue(entity2, "OnBreak", temp);
		}	
	}
	return Plugin_Handled;
}

