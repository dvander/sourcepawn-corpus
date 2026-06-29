#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.11"

new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[TF2] Horseless Headless Horsemann",
	author = "Geit (modified by FlaminSarge)",
	description = "Spawn Horseless Headless Horsemann where you're looking. Can set its model.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_horsemann_version", PL_VERSION, "Horsemann Spawner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_horsemann", Command_Spawn, ADMFLAG_RCON);
//	RegAdminCmd("sm_getentdata", Command_GetEntData, ADMFLAG_RCON);
}

public OnMapStart()
{
	PrecacheModel("models/bots/headless_hatman.mdl"); 
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("vo/halloween_boss/knight_alert.wav");
	PrecacheSound("vo/halloween_boss/knight_alert01.wav");
	PrecacheSound("vo/halloween_boss/knight_alert02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack01.wav");
	PrecacheSound("vo/halloween_boss/knight_attack02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack03.wav");
	PrecacheSound("vo/halloween_boss/knight_attack04.wav");
	PrecacheSound("vo/halloween_boss/knight_death01.wav");
	PrecacheSound("vo/halloween_boss/knight_death02.wav");
	PrecacheSound("vo/halloween_boss/knight_dying.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
	PrecacheSound("vo/halloween_boss/knight_pain01.wav");
	PrecacheSound("vo/halloween_boss/knight_pain02.wav");
	PrecacheSound("vo/halloween_boss/knight_pain03.wav");
	PrecacheSound("vo/halloween_boss/knight_spawn.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");
	PrecacheSound("ui/halloween_boss_chosen_it.wav");
	PrecacheSound("ui/halloween_boss_defeated_fx.wav");
	PrecacheSound("ui/halloween_boss_player_becomes_it.wav");
	PrecacheSound("ui/halloween_boss_summoned_fx.wav");
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
	PrecacheModel("models/props_halloween/ghost.mdl");
	PrecacheModel("models/props_halloween/halloween_gift.mdl");
	PrecacheModel("models/props_halloween/halloween_medkit_large.mdl");
	PrecacheModel("models/props_halloween/halloween_medkit_medium.mdl");
	PrecacheModel("models/props_halloween/halloween_medkit_small.mdl");
	PrecacheModel("models/props_halloween/pumpkin_loot.mdl");
	PrecacheModel("models/props_manor/tractor_01.mdl");
	PrecacheModel("models/props_manor/baby_grand_01.mdl");
}

// FUNCTIONS
/*public OnGameFrame(){
	new Float:position[3];
	for(new i = 0; i < 10; i++){
		//position[0] = GetRandomFloat(-1000.0, 1000.0);
		//position[1] = GetRandomFloat(-1000.0, 1000.0);
		position[0] = -921.0;
		position[1] = 3365.0;
		//position[2] = 0-GetRandomFloat(0, 1000);
		position[2] = -971.0;
		TE_SetupMetalSparks(position, Float:{0.0,0.0,0.0});	
		TE_SendToAll();
	}
}*/

public Action:Command_Spawn(client, args)
{
	new String:modelname[64];
	new bool:changemodel = false;
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkin lords. Change maps.");
		return Plugin_Handled;
	}
	if (args != 0)
	{
		GetCmdArgString(modelname, sizeof(modelname));
		if (FileExists(modelname, true) && IsModelPrecached(modelname)) changemodel = true;
		else
		{
			ReplyToCommand(client, "[SM] Model is invalid. sm_horsemann [modelname].");
			return Plugin_Handled;
		}
	}
	new entity = CreateEntityByName("headless_hatman");
	if(IsValidEntity(entity))
	{
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		if (changemodel) SetEntityModel(entity, modelname);
	}
	return Plugin_Handled;
}

/*public Action:Command_GetEntData(client, args)
{
	decl String:Derp[256];
	new int;// = GetClientAimTarget(client, false);
	new Float:client_position[3], Float:client_rotation[3], Float:position[3];
	
	GetClientEyePosition(client, client_position);
	GetClientEyeAngles(client, client_rotation);
	
	TR_TraceRayFilter(client_position, client_rotation, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit()){
		int = TR_GetEntityIndex();
		TR_GetEndPosition(position);
		TE_SetupMetalSparks(position, Float:{0.0,0.0,0.0});
		TE_SendToAll();
	
	} else {
		PrintToChatAll("Fuckin tracerays how do they work?");
	}
				
	if (int > 0)
	{
		GetEntityNetClass(int, Derp, sizeof(Derp));
		PrintToChatAll("Networkable class name: %s (entity %i)", Derp, int);
	} else {
		PrintToChatAll("I blame goat", Derp);
		
	}
	return Plugin_Handled;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	decl String:Derp[256];
	GetEntityNetClass(entity, Derp, sizeof(Derp));
	PrintToChatAll("durrNetworkable class name: %s (entity %i)", Derp, entity);
	return entity != data;
}*/

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

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}
