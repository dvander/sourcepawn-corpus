#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "goback teleport system",
	author = "Alienmario",
	description = "A teleport system with teleport back feature",
	version = "1.0",
	url = "http://bouncyball.eu"
}

#define SOUND_READY "npc/scanner/combat_scan2.wav"
#define SOUND_CP "ambient/water/drip4.wav"
#define SOUND_TELEPORTING "weapons/physcannon/physcannon_charge.wav"
#define PARTICLE1 "fire_medium_heatwave"
#define PARTICLE2 "embers_small_01"

new Handle:sm_goback_enable = INVALID_HANDLE;
new Handle:sm_goback_timeout = INVALID_HANDLE;
new Handle:sm_goback_cooldown = INVALID_HANDLE;

new Float:plOrigin[MAXPLAYERS+1][3];
new Float:plAngles[MAXPLAYERS+1][3];
new bool:has[MAXPLAYERS+1];
new bool:hasCP[MAXPLAYERS+1];
new bool:can[MAXPLAYERS+1];
new bool:canButton[MAXPLAYERS+1];
new particles[MAXPLAYERS+1];
new particles2[MAXPLAYERS+1];

new Handle:enableTimers[MAXPLAYERS+1];
new Handle:holdTimers[MAXPLAYERS+1];

public OnPluginStart(){
	sm_goback_enable = CreateConVar("sm_goback_enable","1","Enable go back plugin",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	sm_goback_timeout = CreateConVar("sm_goback_timeout","10","Time after spawn, when go back can be used",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);	
	sm_goback_cooldown = CreateConVar("sm_goback_cooldown","5","Time until teleport can be reused again",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);	
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Spawn);
	RegConsoleCmd("sm_goback",goBack,"Teleports to last known position or checkpoint");
	RegConsoleCmd("sm_gb",goBack,"Teleports to last known position or checkpoint");
	RegConsoleCmd("sm_go",goBack,"Teleports to last known position or checkpoint");
	RegConsoleCmd("sm_cp",makeCP,"Make a manual checkpoint");
	RegConsoleCmd("sm_acp",unCP,"Remove manual checkpoint, use automatic");
	RegConsoleCmd("sm_ucp",unCP,"Remove manual checkpoint, use automatic");
}

public OnMapStart(){
	for (new i=0;i<=MAXPLAYERS;i++){
		has[i]=false;
		hasCP[i]=false;
		can[i]=false;
		canButton[i]=false;
	}
	PrecacheSound(SOUND_TELEPORTING, true);
	PrecacheSound(SOUND_READY, true);
	PrecacheSound(SOUND_CP, true);
	PrecacheParticleSystem(PARTICLE1);
	PrecacheParticleSystem(PARTICLE2);
}

public Action:Event_Death (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[32]; GetEventString(event, "weapon", weapon, 32);
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//PrintToChatAll("%d, %s", attacker, weapon);
	if(enableTimers[client]!=INVALID_HANDLE){
		KillTimer(enableTimers[client]);
		enableTimers[client]=INVALID_HANDLE;
	}
	SDKUnhook(client, SDKHook_FireBulletsPost, FireBulletsPost);
	if(client<1) return Plugin_Continue;
	if(	!IsClientInGame(client) 
		|| StrEqual(weapon, "trigger_hurt") 
		|| StrEqual(weapon, "trigger_waterydeath") 
		|| StrEqual(weapon, "trigger_physics_trap") 
		|| StrEqual(weapon, "worldspawn") )
	{ 
		return Plugin_Continue;
	}
	if(!hasCP[client]){
		GetClientAbsOrigin(client, plOrigin[client]);
		GetClientEyeAngles(client, plAngles[client]);
	}
	has[client]=true;
	can[client]=false;
	canButton[client]=false;
	return Plugin_Continue;
}

public Action:Event_Spawn (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(enableTimers[client]!=INVALID_HANDLE){
			KillTimer(enableTimers[client]);
			enableTimers[client]=INVALID_HANDLE;
	}
	enableTimers[client]=CreateTimer(GetConVarFloat(sm_goback_timeout), tEnable, client, TIMER_FLAG_NO_MAPCHANGE);
	SDKUnhook(client, SDKHook_FireBulletsPost, FireBulletsPost);
	
	return Plugin_Continue;
}

public Action:tEnable(Handle:timer, any:client){
	can[client]=true;
	canButton[client]=true;
	SDKHook(client, SDKHook_FireBulletsPost, FireBulletsPost);
	if(GetConVarBool(sm_goback_enable) && has[client]){
		PrintToChat(client, "\x07FFFF66[Hold Reload to teleport back]");
		EmitSoundToClient(client, SOUND_READY);
	}
	enableTimers[client]=INVALID_HANDLE;
}

public Action:tEnable2(Handle:timer, any:client){
	can[client]=true;
	SDKUnhook(client, SDKHook_FireBulletsPost, FireBulletsPost);
	enableTimers[client]=INVALID_HANDLE;
}

public FireBulletsPost(client, shots, const String:weaponname[]){
	if(canButton[client]){
		//PrintToChat(client, "\x07FFFF66[Teleport disabled]");
		canButton[client]=false;
	}
	SDKUnhook(client, SDKHook_FireBulletsPost, FireBulletsPost);
}

public OnClientDisconnect(client){
	if(enableTimers[client]!=INVALID_HANDLE){
		KillTimer(enableTimers[client]);
		enableTimers[client]=INVALID_HANDLE;
	}
}

public OnClientDisconnect_Post(client){
	has[client]=false;
	hasCP[client]=false;
	can[client]=false;
	canButton[client]=false;
	stopParticle(particles[client]);
	stopParticle(particles2[client]);
}

public Action:makeCP(client, args){
	if(!GetConVarBool(sm_goback_enable)){
		ReplyToCommand(client, "[Feature disabled]");
		return Plugin_Handled;
	}
	if( !IsPlayerAlive(client) || client<1){
		ReplyToCommand(client, "[You need to be alive to make a checkpoint!]");
		return Plugin_Handled;
	}
	GetClientAbsOrigin(client, plOrigin[client]);
	GetClientEyeAngles(client, plAngles[client]);
	if(!has[client]){ //if first time
		can[client]=true;
	}
	has[client]=true;
	hasCP[client]=true;
	EmitSoundToClient(client, SOUND_CP);
	ReplyToCommand(client, "[Checkpoint saved] Type /ucp to remove it.");
	return Plugin_Handled;
}

public Action:unCP(client, args){
	has[client]=false;
	hasCP[client]=false;
	ReplyToCommand(client, "[Checkpoint removed]");
	return Plugin_Handled;
}

public Action:goBack(client, args){
	if(!GetConVarBool(sm_goback_enable)){
		ReplyToCommand(client, "[Feature disabled]");
		return Plugin_Handled;
	}
	if( !IsPlayerAlive(client) || client<1){
		ReplyToCommand(client, "[You need to be alive to teleport!]");
		return Plugin_Handled;
	}
	if(!has[client]){
		ReplyToCommand(client, "[Nowhere to teleport!]");
		return Plugin_Handled;
	}
	if(!can[client]){
		ReplyToCommand(client, "[Can't teleport yet!]");
		return Plugin_Handled;
	}
	if(doTP(client)){
		can[client]=false;
		canButton[client]=false;
		if(enableTimers[client]!=INVALID_HANDLE){
			KillTimer(enableTimers[client]);
			enableTimers[client]=INVALID_HANDLE;
		}
		enableTimers[client]=CreateTimer(GetConVarFloat(sm_goback_cooldown), tEnable2, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &Buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if(has[client] && canButton[client] && IsPlayerAlive(client) && Buttons & IN_RELOAD && GetConVarBool(sm_goback_enable)){
		if(holdTimers[client]==INVALID_HANDLE){
			holdTimers[client]=CreateTimer(1.3, tHeld, client, TIMER_FLAG_NO_MAPCHANGE);
			EmitSoundToClient(client, SOUND_TELEPORTING);
			
			decl Float:origin[3];
			GetClientAbsOrigin(client, origin);
			particles2[client]=showParticle(plOrigin[client], PARTICLE2);
			particles[client]=showParticle(origin, PARTICLE1, client);
		}
	}else{
		if(holdTimers[client]!=INVALID_HANDLE){
			KillTimer(holdTimers[client]);
			holdTimers[client]=INVALID_HANDLE;
			StopSound(client, SNDCHAN_AUTO, SOUND_TELEPORTING);
			stopParticle(particles[client]);
			stopParticle(particles2[client]);
		}
	}
	return Plugin_Continue;
}

public Action:tHeld(Handle:timer, any:client){
	if(doTP(client)){
		can[client]=false;
		canButton[client]=false;
		if(enableTimers[client]!=INVALID_HANDLE){
			KillTimer(enableTimers[client]);
			enableTimers[client]=INVALID_HANDLE;
		}
		enableTimers[client]=CreateTimer(GetConVarFloat(sm_goback_cooldown), tEnable2, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	stopParticle(particles[client]);
	stopParticle(particles2[client]);
	holdTimers[client]=INVALID_HANDLE;
}

bool:doTP(client){
	new m_hVehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if(m_hVehicle==-1){//not in vehicle
		if(tpIsBlocked(client)){
			PrintToChat(client, "\x07FF0000[Something is blocking the teleport]");
			return false;
		}
		TeleportEntity(client,plOrigin[client],plAngles[client],NULL_VECTOR);
		return true;
	}
	else{//in vehicle
		new String:buffer[32];
		GetEntityClassname(m_hVehicle,buffer,32);
		if(StrEqual(buffer,"prop_vehicle",false)||StrEqual(buffer,"prop_vehicle_airboat",false)||StrEqual(buffer,"prop_vehicle_driveable",false)||StrEqual(buffer,"prop_vehicle_jeep",false))
		{
			TeleportEntity(m_hVehicle,plOrigin[client],plAngles[client],NULL_VECTOR);
			return true;
		}
		else{
			PrintToChat(client, "[Teleport in this vehicle is not supported]");
			return false;
		}
	}
}

bool:tpIsBlocked(client){
	decl Float:vecMin[3], Float:vecMax[3]

	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);

	TR_TraceHullFilter(plOrigin[client], plOrigin[client], vecMin, vecMax, MASK_PLAYERSOLID|CONTENTS_HITBOX, TraceFilter);
	return TR_DidHit();
}

public bool:TraceFilter(entity, mask, any:data) {
	if(entity>0 && entity <=MAXPLAYERS)
		return false;
	new String:buf[10];
	if(GetEdictClassname(entity, buf, sizeof(buf))){
		if(!StrContains(buf, "weapon_") || !StrContains(buf, "item_")){
			return false;
		}
	}
	return true;
}

stock showParticle(Float:pos[3], String:particlename[], parentEnt=-1)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		if(parentEnt!=-1){
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", parentEnt);
		}
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		return EntIndexToEntRef(particle);
    }  
	return -1;
}

stopParticle (&ent){
	delEnt(ent);
	ent=INVALID_ENT_REFERENCE;
}

delEnt(index){
	if (index != INVALID_ENT_REFERENCE && index !=0) {
		AcceptEntityInput(index, "Kill");
	}
}

/* FROM SMLIB */
stock PrecacheParticleSystem(const String:particleSystem[])
{
	static particleEffectNames = INVALID_STRING_TABLE;

	if (particleEffectNames == INVALID_STRING_TABLE) {
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
			return INVALID_STRING_INDEX;
		}
	}

	new index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX) {
		new numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
			return INVALID_STRING_INDEX;
		}
		
		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}
	
	return index;
}

stock FindStringIndex2(tableidx, const String:str[])
{
	decl String:buf[1024];

	new numStrings = GetStringTableNumStrings(tableidx);
	for (new i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		
		if (StrEqual(buf, str)) {
			return i;
		}
	}
	
	return INVALID_STRING_INDEX;
}