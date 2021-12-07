#include <sourcemod>
#include <sdktools>

static g_offOwnerEnt;
new g_LeaderOffset;

new pets[MAXPLAYERS + 1];
new pets_tmp[MAXPLAYERS + 1];

public OnPluginStart()
{
	g_offOwnerEnt = FindSendPropInfo("CDynamicProp", "m_hOwnerEntity");
	g_LeaderOffset = FindSendPropOffs("CHostage", "m_leader");
	
	HookEvent("hostage_hurt", OnHostageHurt, EventHookMode_Pre);
	HookEvent("hostage_follows", Event_Hostage_Follows,EventHookMode_Pre);
	HookEvent("hostage_stops_following", Event_Hostage_Follows,EventHookMode_Pre);
	HookEvent("hostage_killed", OnHostageKilled, EventHookMode_Pre);
	
	RegConsoleCmd("sm_s", Command_S);
}

public OnMapStart()
{
	//프리캐시
	PrecacheModel("models/Characters/Hostage_01.mdl");
	PrecacheModel("models/Characters/Hostage_02.mdl");
	PrecacheModel("models/Characters/hostage_03.mdl");
	PrecacheModel("models/Characters/hostage_04.mdl");
	PrecacheModel("models/seagull.mdl");
	PrecacheModel("models/blackout.mdl");
}

public OnClientDisconnect(entity)
{
	DeletePet(entity); //플레이어가 나갈시 펫도 같이 삭제한다.
}

public Action:BaseNPC_HookHostageSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags){ return Plugin_Stop; }

public Action:OnHostageHurt(Handle:event, const String:name[], bool:dontBroadcast){ return Plugin_Handled; }

public Action:Event_Hostage_Follows(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hostage = GetEventInt(event, "hostage");
	new entity = CreateEntityByName("prop_physics"); //엔티티 종류를 prop_physics로 해줌
	SetEntDataEnt2(hostage, g_LeaderOffset, entity);
	return Plugin_Changed;
}

public Action:OnHostageKilled(Handle:event, const String:name[], bool:dontBroadcast){ return Plugin_Handled; }

public Action:Command_S(client, Arguments) //펫소환 커맨드
{
	Seagull_Spawn(client);
}

public Seagull_Spawn(client){
	decl Float:eyepos[3], Float:eyeangle[3], Float:anglevector[3], Float:resultvecpos[3], Float:position[3];
	GetClientEyePosition(client, eyepos);
	GetClientEyeAngles(client, eyeangle);
	eyeangle[0] = 0.0;
	GetAngleVectors(eyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, -50.0);
	AddVectors(eyepos, anglevector, resultvecpos);

	CreatePet(client, resultvecpos, "models/seagull.mdl", "Fly");
	
	if (GetPlayerEye(client, position))
	{
		position[2] += 25; //프롭의 소환되는 높이를 설정
		PrecacheModel("models/props_junk/wood_crate001a.mdl", true); //프롭을 프리캐시
		new entity = CreateEntityByName("prop_physics"); //엔티티 종류를 prop_physics로 해줌
		DispatchKeyValue(entity, "model", "models/props_junk/wood_crate001a.mdl"); //프롭을 소환
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
		TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR); //아까 잡힌 위치로 프롭을 이동
	}
}

stock CreatePet(client, Float:vEntPosition[3], String:model[128], String:idleAnimation[] = "idle"){
	DeletePet(client);

	decl String:entIndex[6];

	new pet = CreateEntityByName("hostage_entity");
	new pet_tmp = CreateEntityByName("prop_dynamic_ornament");

	IntToString(pet_tmp, entIndex, sizeof(entIndex)-1);

	DispatchKeyValue(pet, "targetname", entIndex);
	DispatchKeyValue(pet, "disableshadows", "1");
	DispatchKeyValueFloat(pet, "friction", 1.0);
	SetEntPropEnt(pet, Prop_Send, "m_hOwnerEntity", client);
	DispatchSpawn(pet);
	SetEntityMoveType(pet, MOVETYPE_FLY);
	SetEntProp(pet, Prop_Data, "m_takedamage", 0, 1);
	SetEntProp(pet, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(pet, Prop_Send, "m_hOwnerEntity", client);
	SetEntityModel(pet, "models/blackout.mdl");

	DispatchKeyValue(pet_tmp, "model", model);
	DispatchKeyValue(pet_tmp, "DefaultAnim", idleAnimation);
	DispatchSpawn(pet_tmp);

	TeleportEntity(pet, vEntPosition, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(entIndex);
	AcceptEntityInput(pet_tmp, "SetParent");
	SetVariantString(entIndex);
	AcceptEntityInput(pet_tmp, "SetAttached");

	TeleportEntity(pet, vEntPosition, NULL_VECTOR, NULL_VECTOR);

	pets[client] = pet;
	pets_tmp[client] = pet_tmp;

	SetEntDataEnt2(pet, g_offOwnerEnt, client, true);
}

public DeletePet(entity){
	if(IsValidEntity(pets[entity]) && pets[entity] != 0){
		new String:entityclass[128];
		GetEdictClassname(pets[entity], entityclass, sizeof(entityclass));
		if(StrEqual(entityclass, "prop_physics")){
			AcceptEntityInput(pets[entity], "Kill");
			pets[entity] = 0;
		}
	}

	if(IsValidEntity(pets_tmp[entity]) && pets_tmp[entity] != 0){
		new String:entityclass[128];
		GetEdictClassname(pets_tmp[entity], entityclass, sizeof(entityclass));
		if(StrEqual(entityclass, "prop_dynamic_ornament")){
			AcceptEntityInput(pets_tmp[entity], "Kill");
			pets_tmp[entity] = 0;
		}
	}
}

stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

public bool:tracerayfilterdefault(entity, mask, any:data){
	if(entity != data){
		return true;
	}else{
		return false;
	}
}
