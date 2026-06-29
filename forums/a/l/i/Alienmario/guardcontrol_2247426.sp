#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define angry1 "npc/antlion_guard/angry1.wav"
#define angry2 "npc/antlion_guard/angry2.wav"
#define angry3 "npc/antlion_guard/angry3.wav"
#define die1 "npc/antlion_guard/antlion_guard_die1.wav"
#define die2 "npc/antlion_guard/antlion_guard_die2.wav"
#define confused1 "npc/antlion_guard/confused1.wav"
#define growl_idle "npc/antlion_guard/growl_idle.wav"
#define growl_high "npc/antlion_guard/growl_high.wav"
#define shove1 "npc/antlion_guard/shove1.wav"
#define foot_heavy1 "npc/antlion_guard/foot_heavy1.wav"
#define foot_heavy2 "npc/antlion_guard/foot_heavy2.wav"
#define foot_light1 "npc/antlion_guard/foot_light1.wav"
#define foot_light2 "npc/antlion_guard/foot_light2.wav"

#define SOUND_TAKECONTROL "ambient/machines/teleport3.wav"
#define SOUND_TAKECONTROL_POST "ambient/machines/thumper_hit.wav"

#define speed_walk 1.35 //must be lower than speed_run_tolerance
#define speed_blocked 0.0
#define speed_back 0.9 //+ left,right
#define speed_uncrouch 0.4
#define speed_run 1.5
#define speed_run_tolerance 1.4 // speed at which is guard considered charging, must be lower than speed_run

//attack1
#define FORCE  750.0
#define RADIUS  220.0 //was 240.0
#define DAMAGE  100.0
#define DAMAGE_HUMANS  200.0 // was 80.0
#define ATTACK_COOLDOWN 1.8

//various
#define EXPL_STUN_COOLDOWN 25.0 //do explosive-damage stun every x seconds 
#define DAMAGE_CLAMP 100.0 //Maximum one-time damage to the guard
#define SHARP_TURN 0.8 //prevent sharp turns while charging; 0.0 to 1.0, where 1.0 = block all turns and 0.0 = disabled
#define MAX_GUARDS 3 //Maximum controlled guards
#define MIN_HUMAN_PLAYERS 3 //Minimum human players
#define MAX_TAKEOVERS 1 //Maximum takeovers by pressing the E button (in mode2 only) for player per map
// a client guard will not spawn if the number of guards is at maximum AND if number of human players would be less than defined

//charge push away (called rapidly)
#define FORCE_CHARGE  500.0
#define RADIUS_CHARGE  180.0
#define DAMAGE_CHARGE  2.0
#define DAMAGE_HUMANS_CHARGE  3.0
#define MAXPUSHANGLE_CHARGE  25.0

//crash
#define FORCE_CRASH  600.0
#define RADIUS_CRASH  300.0
#define DAMAGE_CRASH  5.0
#define DAMAGE_HUMANS_CRASH  10.0
#define MAXPUSHANGLE_CRASH  250.0

// maximum thirdperson camera distance
#define TP_DISTANCE  175.0 

//antlion summon settings (mouse2)
#define SUMMON 4 // number of antlions to spawn on each summon
#define SUMMON_MAX 4 // maximum alive spawned antlions
#define SUMMON_DISTANCE 120.0 // distance from player to spawn ants at
#define SUMMON_COOLDOWN 20.0 // cooldown time until next summon

/******************************************************************
*******************************************************************
*******************************************************************/
//m_takedamage
#define DAMAGE_NO		0
#define DAMAGE_EVENTS_ONLY	1	// Call damage functions, but don't modify health
#define DAMAGE_YES		2
#define DAMAGE_AIM		3

//internal flags
#define G_ANIMATING		(1 << 0) //blocking other animations
#define G_CHARGESTOP			(1 << 1) // returning from charging
#define G_FOOT			(1 << 2) // bool for next foot sound type
#define G_SUMMONSOUND		(1 << 3) // summon sound is looping
#define G_THIRDPERSON			(1 << 4) // desired mode; 1=thirdperson desired
#define G_CAM_MAX		(1 << 5) // thirdperson camera is already at maximum distance
#define G_FPFORCED			(1 << 6) // camera forced a firstperson mode
#define G_DIESOUND		(1 << 7) // is guard waiting for die sound
#define G_DUCKING	(1 << 8) // fully ducked and idle
#define G_ATTACKING	(1 << 9) // tiny time between button press and damage

#define G_ANIMATIONSTATE G_ANIMATING|G_CHARGESTOP|G_DUCKING

new fl[MAXPLAYERS+1]; // flags
new guardNpc[MAXPLAYERS+1] = {-1, ...};
new guardModel[MAXPLAYERS+1] = {-1, ...};
new guardCam[MAXPLAYERS+1] = {-1, ...};

new Handle:animTimers[MAXPLAYERS+1];
new Handle:dmgTimers[MAXPLAYERS+1];
new bullets[MAXPLAYERS+1];
new lastButton[MAXPLAYERS+1] = {-1,...};
new prevTeam[MAXPLAYERS+1] = {3,...};
new takeOvers[MAXPLAYERS+1];
new Float:dmgCount[MAXPLAYERS+1];

new Handle:Ants[MAXPLAYERS+1];
new Float:nextSummon[MAXPLAYERS+1];
new Float:nextAttack[MAXPLAYERS+1];
new Float:nextBlastStun[MAXPLAYERS+1];
new Float:nextVelCheck[MAXPLAYERS+1];

new Handle:sm_guardcontrol_takeover;

public OnPluginStart(){
	RegAdminCmd("sm_remguard", Command_rem, ADMFLAG_KICK, "remove antlionguard of target");
	RegAdminCmd("sm_spawnguard", Command_spawn, ADMFLAG_KICK, "spawn antlionguard as self or at target");
	AddNormalSoundHook(FootSteps);
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	AddCommandListener(BlockKill, "kill"); 
	AddCommandListener(BlockKill, "explode"); 
	sm_guardcontrol_takeover = CreateConVar("sm_guardcontrol_takeover", "2.0", "Takeover mode of new guards, 1=choose random player if the conditions are right, 2=players need to use E to takeover, 0=disabled", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 2.0);

	LoadTranslations("common.phrases");
}

public Action:Command_spawn(client, args){
	if(args==1){
		new String:buff[64];
		GetCmdArg(1, buff, sizeof(buff));
		new target = FindTarget(client, buff, true, false);
		if(target!=-1){
			if(!CreateGuard(target, -1)) ReplyToCommand(client, "Spawn on %N failed", target);
			else ReplyToCommand(client, "Spawning guard on %N", target);
		}
	}else if(args==0 && client!=0){
		if(!CreateGuard(client, -1)) ReplyToCommand(client, "Spawn failed");
	}
	else ReplyToCommand(client, "Usage: !spawnguard target");
	return Plugin_Handled;
}

public Action:Command_rem(client, args){
	if(args==1){
		new String:buff[64];
		GetCmdArg(1, buff, sizeof(buff));
		new target = FindTarget(client, buff, true, false);
		if(target!=-1){
			RemoveGuard(target);
			ReplyToCommand(client, "Removing guard on %N", target);
		}
	}else ReplyToCommand(client, "Usage: !remguard target");
	return Plugin_Handled;
}

public OnConfigsExecuted(){
	PrecacheSound(angry1, true);
	PrecacheSound(angry2, true);
	PrecacheSound(angry3, true);
	PrecacheSound(growl_idle, true);
	PrecacheSound(growl_high, true);
	PrecacheSound(confused1, true);
	PrecacheSound(die1, true);
	PrecacheSound(die2, true);
	PrecacheSound(shove1, true);
  	PrecacheSound(foot_heavy1, true);
	PrecacheSound(foot_heavy2, true);
	PrecacheSound(foot_light1, true);
	PrecacheSound(foot_light2, true);
	PrecacheSound(SOUND_TAKECONTROL, true);
	PrecacheSound(SOUND_TAKECONTROL_POST, true);
	Team_SetName(1, "Antlion guard");
}

public OnEntityCreated(entity, const String:classname[]){
	if(StrEqual(classname, "npc_antlionguard")){
		if(!StartTransitionPre(entity))
			CreateTimer(0.2, tStartTransitionPre, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	if(!StrContains(classname, "item_")){
		SDKHook(entity, SDKHook_Touch, TouchItems);
	}
}

public Action:tStartTransitionPre(Handle:timer, any:guard_entref){	
	new guard = EntRefToEntIndex(guard_entref);
	if(guard == -1)
		return Plugin_Stop;
	else if(StartTransitionPre(guard))
		return Plugin_Stop;
	return Plugin_Continue;
}

/***********************************************************************
	return 0 
		if can't get LOS (keep trying)
	return 1 
		if starting transition 
		if other conditions are not met (don't keep trying)
***********************************************************************/
bool:StartTransitionPre(guard){
	if(GetConVarInt(sm_guardcontrol_takeover)==1){
		new clients[MaxClients];
		new size = GetGuardCandidates(clients);
		if(size>0 && spawnConditions()) {
			if(!AnyLineOfSight(guard)) return false;
			new rClient = clients[Math_GetRandomInt(0,size-1)];
			EmitSoundToClient(rClient, SOUND_TAKECONTROL);
			new Handle:pack;
			CreateDataTimer(0.4, StartTransition, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE );
			WritePackCell(pack, EntIndexToEntRef(guard));
			WritePackCell(pack, GetClientUserId(rClient));
		}
	}
	return true;
}

bool:spawnConditions(){
	return GetClientCount()-GetGuardCount()>MIN_HUMAN_PLAYERS && GetGuardCount()<MAX_GUARDS
}

/* true if at least one client can have a line to the entity */
bool:AnyLineOfSight(entity){
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i) && IsPlayerAlive(i) && LineOfSight(i, entity, true)){
			return true;
		}
	}
	return false;
}

bool:LineOfSight(client, entity, bool:ignoreClients){
	// trace with playerclip -- won't spawn client guards in inaccessible area!			
	new Float:clEyePos[3]; GetClientEyePosition(client, clEyePos);
	new Float:entPos[3]; GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entPos);
	if(ignoreClients)
		TR_TraceRayFilter(clEyePos, entPos, MASK_PLAYERSOLID, RayType_EndPoint, FilterNoClients);
	else
		TR_TraceRayFilter(clEyePos, entPos, MASK_PLAYERSOLID, RayType_EndPoint, FilterNoSelf, client);
	return TR_GetEntityIndex()==entity;
}

public bool:FilterNoClients(entity, contentsMask, any:data){
	if(0<entity<=MaxClients) return false;
	return true;
}

public bool:FilterNoSelf(entity, contentsMask, any:data){
	if(entity==data) return false;
	return true;
}

public Action:StartTransition(Handle:timer, Handle:pack){	
	ResetPack(pack);
	new entref = ReadPackCell(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	if(client!=0){
 		if(CreateGuard(client, entref)){
			PrintToChatAll("\x07adff2f[Guard Control] \x07ffee00%N \x07ffe4b5is now controlling the Antlion Guard", client);
		}
	}
	return Plugin_Stop;
}

GetGuardCandidates(clients[]){
	new size;
	for(new i=1;i<=MaxClients;i++){
		if(guardModel[i] == -1 && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)>1 && GetClientTime(i)>5.0){
			clients[size++]=i;
		}
	}
	return size;
}

GetGuardCount(){
	new size;
	for(new i=1;i<=MaxClients;i++){
		if(guardModel[i] != -1 && IsClientInGame(i)){
			size++;
		}
	}
	return size;
}

stock bool:CreateGuard(client, npcguard_entref=-1, health_override=-1){
	if(guardModel[client]!=-1) return false;
	if(!IsClientValid(client) || !IsPlayerAlive(client) || GetClientTeam(client)<2) return false;
	
	new hp=1500;
	new Float:vec[3];
	new Float:angle[3];
	
	/****************************************************
		Overriding a npc (but not actually using it)
	****************************************************/
	if(npcguard_entref!=-1){
		new guard_ent = EntRefToEntIndex(npcguard_entref);
		if(guard_ent==-1) return false;
		guardNpc[client]=npcguard_entref;
		
		//set position, solidity, parent and etc..
		GetEntPropVector(guard_ent, Prop_Data, "m_angAbsRotation", angle);
		GetEntPropVector(guard_ent, Prop_Send, "m_vecOrigin", vec);
		TeleportEntity(client, vec, angle, NULL_VECTOR);
		Entity_SetSolidType(guard_ent, SOLID_NONE);
		SetEntityMoveType(guard_ent, MOVETYPE_NOCLIP);
		SetEntityRenderMode(guard_ent, RENDER_NONE);
		DispatchKeyValue(guard_ent, "disableshadows", "1");
		SetEntProp(guard_ent, Prop_Data, "m_nNextThinkTick", GetEngineTime()+9999999.0);
		SetEntProp(guard_ent, Prop_Data, "m_takedamage", DAMAGE_NO);
		SetVariantString("!activator");
		AcceptEntityInput(guard_ent, "SetParent", client);		
		hp = GetEntProp(guard_ent, Prop_Data, "m_iHealth");
	}else{
		GetClientAbsOrigin(client, vec); GetClientAbsAngles(client, angle);
	}
	/****************************************************
		Creating a model for visuals
	****************************************************/
	new model = CreateEntityByName("prop_dynamic");
	if(model!=-1){
		DispatchKeyValue(model, "model", "models/antlion_guard.mdl");
		DispatchKeyValue(model, "DefaultAnim", "alertidle");
		DispatchKeyValue(model, "solid", "0");

		DispatchSpawn(model);
		TeleportEntity(model, vec, angle, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(model, "SetParent", client);
		
		SDKHook(model, SDKHook_SetTransmit, SetTransmitModel);
		guardModel[client]=EntIndexToEntRef(model);
	}
	else {
		RemoveGuard(client);
		return false;
	} 
	/****************************************************
		Create Thirperson Camera
	****************************************************/
	new camera = CreateEntityByName("prop_dynamic");
	if(camera!=-1){
		new Float:eyePos[3], Float:ClAngles[3], Float:fwd[3];
		GetClientEyePosition(client, eyePos);
		GetClientAbsAngles(client, ClAngles);
		GetAngleVectors(ClAngles, fwd, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fwd, -TP_DISTANCE);
		AddVectors(eyePos, fwd, fwd);
		DispatchKeyValue(camera, "model", "models/editor/camera.mdl");
		DispatchKeyValue(camera, "solid", "0");
		DispatchKeyValue(camera, "disableshadows", "1");
		DispatchSpawn(camera);
		TeleportEntity(camera, fwd, ClAngles, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(camera, "SetParent", client);
		SetEntityRenderMode(camera, RENDER_NONE);
		SetEntityRenderColor(camera, 0, 0, 0, 0);
		guardCam[client]=EntIndexToEntRef(camera);
	}
	else {
		RemoveGuard(client);
		return false;
	} 
	/****************************************************
		Prepare client settings
	****************************************************/
	{
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.4);
		DispatchSpawn(client); // let engine update phys scale
		
		TeleportEntity(client, vec, angle, NULL_VECTOR);
		SetEntityGravity(client, 0.6);
		
		if(health_override>0) hp = health_override;
		SetEntityHealth(client, hp);
		
		AcceptEntityInput(client, "ForceDropPhysObjects");
		
		new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD");
		hudflags |= HIDEHUD_HEALTH; // hide red blood screen
		SetEntProp(client, Prop_Send, "m_iHideHUD", hudflags);
		
		Client_RemoveAllWeapons(client);
		SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitch);
		SDKHook(client, SDKHook_WeaponCanUse, BlockPickup);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_PreThink, PreThink);
		SetEntityFlags(client, GetEntityFlags(client)|FL_NOTARGET);
		
		Ants[client] = CreateArray();
		
		SetEntProp(client, Prop_Send, "m_iFOV", 70);
		prevTeam[client] = GetEntProp (client, Prop_Send, "m_iTeamNum");
		SetEntProp(client, Prop_Send, "m_iTeamNum", 1);
		SetThirdPerson(client, true, true);
		SetEntityRenderMode(client, RENDER_NONE);
		SetEntityRenderColor(client, 0, 0, 0, 0);
		DispatchKeyValue(client, "disableshadows", "1");
		new Handle:steps = FindConVar("sv_footsteps");
		if(steps!=INVALID_HANDLE) SendConVarValue(client, steps, "0");
		
		EmitSoundToAll(SOUND_TAKECONTROL_POST, client);
	}

	CreateTimer(3.5, HintText, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return true;
}

public Action:HintText(Handle:timer, any:userid){
	PrintHintText(GetClientOfUserId(userid), "Reload = Change view");
	CreateTimer(6.0, HintText2, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:HintText2(Handle:timer, any:userid){
	PrintHintText(GetClientOfUserId(userid), "ʃ'ʅ = Attack|Summon");
	CreateTimer(5.0, HintText3, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:HintText3(Handle:timer, any:userid){
	PrintHintText(GetClientOfUserId(userid), "");
}

public Event_Death (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(guardModel[client]!=-1){
		new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(ragdoll!=-1) AcceptEntityInput(ragdoll, "kill");
		RemoveGuard(client, false);
	}
}

public OnMapEnd(){
	for (new i = 1; i <= MaxClients; i++){
		//if(guardModel[i]!=-1) RemoveGuard(i, false);
		resetVars(i);
	}
}

/****************************************************
	Kill guard and reset
	death is always needed, only set slay to false when coming from death event
****************************************************/
stock RemoveGuard(client, bool:slay=true){		
	if(IsClientValid(client)){
		if(slay && guardModel[client]!=-1){
			ForcePlayerSuicide(client);
			return;
		}
		new IndexGuardNpc=-1;
		if(guardNpc[client]!=-1){
			IndexGuardNpc = EntRefToEntIndex(guardNpc[client]);
			if(IndexGuardNpc!=-1){
				SetEntProp(IndexGuardNpc, Prop_Data, "m_nNextThinkTick", GetGameTime()+0.01);
				SetEntProp(IndexGuardNpc, Prop_Data, "m_takedamage", DAMAGE_YES);
				SetVariantInt(-1);
				AcceptEntityInput(IndexGuardNpc, "SetHealth");
				CreateTimer(1.0, NPCKill, guardNpc[client], TIMER_FLAG_NO_MAPCHANGE);
			}
		}
 		if(guardModel[client]!=-1){
			RemoveAnimQueue(client, false);
			SetVariantString("death01");
			AcceptEntityInput(guardModel[client], "SetAnimation");
			AcceptEntityInput(guardModel[client], "ClearParent");
			CreateTimer(2.5, Ragdoll, guardModel[client], TIMER_FLAG_NO_MAPCHANGE);
			if(IndexGuardNpc==-1) fl[client]=0|G_DIESOUND;
			StopSound(client, SNDCHAN_ITEM, confused1);
			
			for(new i=0;i<GetArraySize(Ants[client]); i++){
				AcceptEntityInput(GetArrayCell(Ants[client], i), "BurrowAway");
			}
			CloseHandle(Ants[client]);

			DoStats(client);
	
			new flags = GetEntityFlags(client);
			flags &=~FL_NOTARGET; SetEntityFlags(client, flags);
			
			SetEntityGravity(client, 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
			SetEntityRenderMode(client, RENDER_NORMAL);
			new Handle:steps = FindConVar("sv_footsteps");
			if(steps!=INVALID_HANDLE) SendConVarValue(client, steps, "1");
			SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponCanUse, BlockPickup);
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_PreThink, PreThink);
			SetThirdPerson(client, false, true);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityHealth(client, 100);
			ClientCommand(client, "r_screenoverlay null");
			SetEntProp(client, Prop_Send, "m_iTeamNum", prevTeam[client]);
		}
		if(guardCam[client]!=-1) AcceptEntityInput(guardCam[client], "kill");
	}
	resetVars(client);
}

public OnClientPutInServer(client){
	resetVars(client);
	takeOvers[client]=0;
}

resetVars(client){
	
	prevTeam[client]=3;
	guardNpc[client] = -1;
	guardModel[client] = -1;
	guardCam[client] = -1;
	bullets[client] = 0;
	dmgCount[client] = 0.0;
	lastButton[client] = -1;
	nextAttack[client] = 0.0;
	nextSummon[client] = 0.0;
	nextBlastStun[client] = 0.0;
	nextVelCheck[client] = 0.0;
	if(fl[client]!=0|G_DIESOUND) fl[client]=0;
}

public Action:NPCKill(Handle:timer, any:ref){
	AcceptEntityInput(ref, "kill");
	return Plugin_Handled;
}

public Action:Ragdoll(Handle:timer, any:ref){
	AcceptEntityInput(ref, "BecomeRagdoll");
	return Plugin_Handled;
}

public Action:WeaponSwitch(client, weapon){
	return Plugin_Handled;
}

public Action:BlockPickup(client, weapon){
	return Plugin_Handled;
}

DoStats(client){
	new score = RoundToNearest(dmgCount[client]);
	new String:recordHolder[32];
	new record = GetRecord(recordHolder);
	if(record<score){
		new String:name[32], String:steamid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamid, sizeof(steamid));
		SaveRecord(score, name, steamid);
		PrintToChatAll("\x07adff2f[Guard Control] \x07ffee00%s \x07ffe4b5has done \x07ff0000%d damage\x07ffe4b5 and broke previous record %d by \x07ffee00%s\x07ffe4b5!", name, score, record, recordHolder);
	}else{
		PrintToChatAll("\x07adff2f[Guard Control] \x07ffee00%N \x07ffe4b5has done %d damage (The record stands %d by \x07ffee00%s\x07ffe4b5)", client, score, record, recordHolder);
	}
}

#define SMPath "data/guardcontrol_record.txt"
GetRecord(String:recordHolder[32]){
	new String:path[PLATFORM_MAX_PATH]; BuildPath(Path_SM, path, sizeof(path), SMPath);
	if(!FileExists(path)){
		recordHolder = "No record";
		return -1;
	}
	new Handle:file = OpenFile(path, "r");
	if(file == INVALID_HANDLE){
		recordHolder = "No record";
		return -1;
	}
	new String:line[32];
	if(ReadFileLine(file, line, sizeof(line))) 
	{
		TrimString(line);
		strcopy(recordHolder, sizeof(recordHolder), line);
		
		if(ReadFileLine(file, line, sizeof(line))) 
		{
			TrimString(line);
			CloseHandle(file); 
			new record = StringToInt(line);
			return record;
		}
	}
	CloseHandle(file);
	recordHolder = "No record";
	return -1;
}

SaveRecord(score, String:name[32], String:steamid[32]){
	new String:path[PLATFORM_MAX_PATH]; BuildPath(Path_SM, path, sizeof(path), SMPath);
	new Handle:file = OpenFile(path, "w");
	if(file!=INVALID_HANDLE){
		WriteFileLine(file, name);
		WriteFileLine(file, "%d", score);
		WriteFileLine(file, steamid);
		CloseHandle(file);
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom){
 	if(guardModel[client] != -1) {
		if(damagetype & DMG_BULLET || damagetype & DMG_BUCKSHOT || damagetype & DMG_GENERIC || damagetype & DMG_CLUB){
			bullets[client]++;
			CreateTimer(0.5, delayDelete, showParticle(damagePosition, "blood_impact_antlion_01", -1), TIMER_FLAG_NO_MAPCHANGE);
			if(bullets[client]%60==0 && !(fl[client] & G_DUCKING)){
				RemoveAnimQueue(client, true);
				setAnimation(client, "pain", 0.7);
			}
		}
		else if(damagetype & DMG_BLAST){
			if(GetGameTime()>nextBlastStun[client]){
				nextBlastStun[client] = GetGameTime()+EXPL_STUN_COOLDOWN;
				
				RemoveAnimQueue(client, true);
				setAnimation(client, "physhit_rl", 2.2, 0.005);
				freeze(client);
				CreateTimer(2.0, delayDelete, showParticle(damagePosition, "AntlionGib", -1), TIMER_FLAG_NO_MAPCHANGE);
				
				new Float:dmgAngle[3];
				GetVectorAngles(damageForce, dmgAngle);
				dmgAngle[0]=-60.0;
				dmgAngle[1]=dmgAngle[1]/5.0;
				dmgAngle[2]=dmgAngle[1]/7.0;
				SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", dmgAngle);//[0] +front|-back (x); [1] around (z axis); [2] to the side (y axis)
			}
		}
		else if(damagetype & DMG_DISSOLVE){
			return Plugin_Handled;
		}
		if(damage>DAMAGE_CLAMP){
			damage=DAMAGE_CLAMP;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public PreThink(client){
	/****************************************************
		thirdperson camera collisions
	****************************************************/
 	new camera=EntRefToEntIndex(guardCam[client]);
	if(camera!=-1){
		new Float:CamPos[3], Float:EyePos[3], Float:EndPos[3], Float:traceAngle[3];
		GetClientEyePosition(client, EyePos);
		GetEntPropVector(camera, Prop_Data, "m_vecAbsOrigin", CamPos);

		//get how much free space eyes>...>camera
		MakeVectorFromPoints(EyePos, CamPos, traceAngle);
		GetVectorAngles(traceAngle, traceAngle);
		TR_TraceRayFilter(EyePos, traceAngle, MASK_SHOT, RayType_Infinite, FilterNoGuard, client);
		TR_GetEndPosition(EndPos);
		
		new Float:distanceTrace = GetVectorDistance(EyePos, EndPos)-50.0;
		new Float:distanceTraceClamped=distanceTrace;

		if(distanceTrace<TP_DISTANCE || !(fl[client] & G_CAM_MAX) ){
			if(distanceTrace>=TP_DISTANCE){
				distanceTraceClamped=TP_DISTANCE;
				fl[client] |= G_CAM_MAX;
			}else fl[client] &= ~G_CAM_MAX;
			
			if(distanceTraceClamped<=95.0){
				if(!(fl[client] & G_FPFORCED)){
					fl[client] |= G_FPFORCED;
					SetThirdPerson(client, false, false); // set firstperson but don't change preference flag
				}
				return;
			} else if (fl[client] & G_FPFORCED){
				if(fl[client] & G_THIRDPERSON) SetThirdPerson(client, true, false);
				fl[client] &= ~G_FPFORCED;
			}
			
			new Float:ClAngles[3], Float:fwd[3];
			GetClientAbsAngles(client, ClAngles);
			GetAngleVectors(ClAngles, fwd, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(fwd, -distanceTraceClamped);
			AddVectors(EyePos, fwd, fwd);
			AcceptEntityInput(camera, "ClearParent");
			TeleportEntity(camera, fwd, ClAngles, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(camera, "SetParent", client);
		}else if (fl[client] & G_FPFORCED){
			if(fl[client] & G_THIRDPERSON) SetThirdPerson(client, true, false);
			fl[client] &= ~G_FPFORCED;
		}
	}
}

public bool:FilterNoGuard(entity, contentsMask, any:client){
	if(EntRefToEntIndex(guardCam[client])==entity) return false;
	if(EntRefToEntIndex(guardModel[client])==entity) return false;
	if(EntRefToEntIndex(guardNpc[client])==entity) return false;
	if(client==entity) return false;
	return true;
}

public Action:SetTransmitModel(ent, client){
	if( !(fl[client] & G_THIRDPERSON) && EntRefToEntIndex(guardModel[client])==ent) return Plugin_Handled;
	if( fl[client] & G_FPFORCED && EntRefToEntIndex(guardModel[client])==ent) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:SetTransmitItems(ent, client){
	if(guardModel[client]!=-1) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:SetTransmitClient(ent, client){
	if(ent==client) return Plugin_Continue;
	return Plugin_Handled;
}

public Action:TouchItems(ent, other){
	if(other<=MAXPLAYERS && guardModel[other]!=-1) return Plugin_Handled;
	return Plugin_Continue;
}

stock SetThirdPerson(client, bool:turnOn, bool:setFlag=true){
	if(turnOn){
		if(setFlag) fl[client] |= G_THIRDPERSON;
		//ClientCommand(client, "r_screenoverlay null");
		SetClientViewEntity(client, EntRefToEntIndex(guardCam[client]));
		SetEntProp(client, Prop_Send, "m_bZooming", 0);
	}else{
		//ClientCommand(client, "r_screenoverlay effects/tp_refract");
		SetClientViewEntity(client, client);
		SetEntProp(client, Prop_Send, "m_bZooming", 1);
		if(setFlag) fl[client] &= ~G_THIRDPERSON;	
	}
}

public Action:FootSteps(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags){
	if(0<entity<=MaxClients) {
		if(!StrContains(sample, "npc/combine_soldier/gear") || !StrContains(sample, "npc/metropolice/gear") || !StrContains(sample, "npc/footsteps/hardboot_generic")){
			if( guardModel[entity] != -1 ){
				if(GetEntPropFloat(entity, Prop_Send, "m_flLaggedMovementValue")>=speed_run){
					if(fl[entity] & G_FOOT)
						EmitSoundToAll(foot_heavy1, entity, channel, level, flags, volume, pitch);
					else
						EmitSoundToAll(foot_heavy2, entity, channel, level, flags, volume, pitch);
				}else{
					if(fl[entity] & G_FOOT)
						EmitSoundToAll(foot_light1, entity, channel, level, flags, volume, pitch);
					else
						EmitSoundToAll(foot_light2, entity, channel, level, flags, volume, pitch);
				}
				fl[entity] ^= G_FOOT;
				return Plugin_Handled;
			}
		}
		//death sound
		else if(fl[entity] & G_DIESOUND && (!StrContains(sample, "npc/combine_soldier/die") || StrContains(sample, "pain")!=-1) ){
			if(GetRandomInt(0,1)==1) {
				EmitSoundToAll(die1, entity, channel, level, flags, volume, pitch);
			}
			else {
				EmitSoundToAll(die2, entity, channel, level, flags, volume, pitch);
			}
			fl[entity] ^= G_DIESOUND;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

#define bits_SUIT_DEVICE_SPRINT		0x00000001
#define IN_NONE 0
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{	
	/****************************************************
	// if client can see guard, rope off
	****************************************************/
/* 	for(new i=1;i<=MaxClients;i++){
		if(guardModel[i] != -1){
			if(i==client){
				FakeClientCommand(client, "-hook")
				FakeClientCommand(client, "-rope")
			}
			else if(LineOfSight(client, i, false)){
				FakeClientCommand(client, "-hook")
				FakeClientCommand(client, "-rope")
			}
		}
	} */
	
	/****************************************************
	// if someone wants to take over a guard npc
	****************************************************/
	new oldButtons = GetEntProp(client, Prop_Data, "m_nOldButtons");
	if(oldButtons & IN_USE && !(buttons & IN_USE) && guardModel[client]==-1 && GetConVarInt(sm_guardcontrol_takeover)==2 && spawnConditions()){
		new target = GetClientAimTarget(client, false);
		if(IsValidEdict(target)){
			decl String:classname[32];
			if(GetEdictClassname(target, classname, sizeof(classname))){
				if(StrEqual(classname, "npc_antlionguard")){
					if(takeOvers[client]<MAX_TAKEOVERS){
						if(CreateGuard(client, EntIndexToEntRef(target))){
							PrintToChatAll("\x07adff2f[Guard Control] \x07ffee00%N \x07ffe4b5is now controlling the Antlion Guard", client);
							takeOvers[client]++;
						}
					}else{
						PrintToChat(client, "\x07adff2f[Guard Control] \x07ffe4b5You've reached maximum takeovers per map");
					}
				}
			}
		}
	}
	
	if(guardModel[client]!=-1){
		/****************************************************
		// prepare data for use below
		****************************************************/
		new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
		new entFlags = GetEntityFlags(client);
		
		new Float:dp;
		new Float:AbsVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", AbsVel);
		if(GetGameTime()>nextVelCheck[client]){
			decl Float:temp[3];
			static Float:oldVel[MAXPLAYERS+1][3];
			NormalizeVector(AbsVel, temp);
			dp = FloatAbs(GetVectorDotProduct(oldVel[client], temp));
			oldVel[client]=temp;
			nextVelCheck[client]=GetGameTime()+0.1;
		}
		/****************************************************
		// block +use
		****************************************************/
		if(buttons & IN_USE){
			buttons &=~ IN_USE;
			SetEntProp(client, Prop_Data, "m_nButtons", buttons);
		}
		/****************************************************
		// ladder block
		****************************************************/
		SetEntProp(client, Prop_Send, "m_hLadder", -1); 
		/****************************************************
		// infinite suit sprint
		****************************************************/
		new m_bitsActiveDevices = GetEntProp(client, Prop_Send, "m_bitsActiveDevices");
		if(m_bitsActiveDevices & bits_SUIT_DEVICE_SPRINT){
			SetEntPropFloat(client, Prop_Data, "m_flSuitPowerLoad", 0.0);
			SetEntProp(client, Prop_Send, "m_bitsActiveDevices", m_bitsActiveDevices & ~bits_SUIT_DEVICE_SPRINT);
		}
		/****************************************************
		// thirdperson switcher
		****************************************************/
		if(buttons & IN_RELOAD && !(oldButtons & IN_RELOAD) && !(fl[client] & G_FPFORCED)){
			if(fl[client] & G_THIRDPERSON){
				SetThirdPerson(client, false);
			}
			else if (guardCam[client]!=-1){
				SetThirdPerson(client, true);
			}
		}
		/****************************************************
		// charge push away
		****************************************************/	
		if(speed>=speed_run_tolerance && !(fl[client] & G_CHARGESTOP)){
			PushAway(client, DAMAGE_HUMANS_CHARGE, DAMAGE_CHARGE, FORCE_CHARGE, RADIUS_CHARGE, MAXPUSHANGLE_CHARGE, false, false);
		}
		/****************************************************
		// charge crash check (clever way)
		****************************************************/	
		if (!(fl[client] & G_CHARGESTOP)
		&& speed>=speed_run_tolerance
		&& entFlags & FL_ONGROUND
		&& GetVectorLength(AbsVel)<120.0)
		{
			RemoveAnimQueue(client, true);
			setAnimation(client, "charge_crash02", 2.8, 0.01);//charge_crash charge_crash02 charge_crash03
			freeze(client);
			
			new Float:dmgAngle[3];
			dmgAngle[0]=50.0;
			dmgAngle[1]=GetRandomFloat(-40.0, 40.0);
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", dmgAngle);
			if(!PushAway(client, DAMAGE_HUMANS_CRASH, DAMAGE_CRASH, FORCE_CRASH, RADIUS_CRASH, MAXPUSHANGLE_CRASH)){
				EmitSoundToAll(shove1, client, SNDCHAN_BODY, 90);
			}
		}
		/****************************************************
		// charge stop handler
		****************************************************/
		static Float:chargeStopVel[MAXPLAYERS+1]; // temp var for handling charge stop slowdown		
		if(fl[client] & G_CHARGESTOP) { 
			vel[1]=0.0;
			vel[0]=chargeStopVel[client];
			SetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
			chargeStopVel[client]-=6.5;
			if(buttons & IN_FORWARD){
				if(chargeStopVel[client]<=200.0) {
					fl[client] &= ~G_CHARGESTOP;
					SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed_back);	
				}
			}
			else if(chargeStopVel[client]<=0.0){
				fl[client] &= ~G_CHARGESTOP;
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed_back);	
			}
			return Plugin_Continue;
		}
		if(! (fl[client] & G_ANIMATING) ){
		/****************************************************
		// ready for inputs : animations (ordered)
		****************************************************/
			/****************************************************
			// check for sounds to be stopped
			****************************************************/
			if(fl[client] & G_SUMMONSOUND) {
				StopSound(client, SNDCHAN_ITEM, confused1);
			}
			/****************************************************
			// do we need to stop charging?
			****************************************************/
			//reason 1: keys changed
			//reason 2: too steep turns! //TODO: SET FORCESTOP FLAG!
			//reason 3: no powah!
			//reason 4: Too slow!
			if( (lastButton[client]==IN_SPEED && !(buttons & IN_FORWARD && buttons & IN_SPEED) && speed>=speed_run_tolerance) 
			|| (speed>=speed_run_tolerance && dp<SHARP_TURN && dp!=0.0)
			|| (speed>=speed_run_tolerance && GetVectorLength(AbsVel)<50.0)){
				{
					lastButton[client]=IN_NONE;
					setAnimationNoBlock(client, "charge_stop"); //blocked by chargestop flag 
					fl[client] |= G_CHARGESTOP;
					chargeStopVel[client]=450.0;
					return Plugin_Continue;
				}
			}
			if (buttons & IN_ATTACK && entFlags & FL_ONGROUND && GetGameTime()>nextAttack[client]) {
				lastButton[client] = IN_ATTACK;
				shove(client);
				return Plugin_Continue;
			}
			if (buttons & IN_ATTACK2 && entFlags & FL_ONGROUND 
			&& GetArraySize(Ants[client])<SUMMON_MAX
			&& GetGameTime()>nextSummon[client]) {
				lastButton[client] = IN_ATTACK2;
				summon(client);
				return Plugin_Continue;
			}
			
			if (buttons & IN_DUCK && entFlags & FL_ONGROUND) {
				if(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT){
					if(lastButton[client]!=IN_DUCK|IN_FORWARD || fl[client] & G_DUCKING){
						lastButton[client] = IN_DUCK|IN_FORWARD;
						setAnimationNoBlock(client, "cover_creep1");
						fl[client] &= ~G_DUCKING;
					}
				}
				else if (entFlags & FL_DUCKING ){
					setAnimationNoBlock(client, "cover_loop");
					fl[client]|=G_DUCKING;
				}
				else if(lastButton[client]!=IN_DUCK){
					lastButton[client] = IN_DUCK;
					setAnimationNoBlock(client, "cover_enter");
				}
				setSpeed(client, speed_walk);
				return Plugin_Continue;
			} else {
				if(lastButton[client] & IN_DUCK || fl[client] & G_DUCKING){
					lastButton[client]=IN_NONE;
					fl[client] &= ~G_DUCKING;
					setAnimation(client, "cover_exit", 0.4, speed_uncrouch);
					return Plugin_Continue;
				}
			}
			if (buttons & IN_FORWARD && buttons & IN_SPEED && GetEntProp(client, Prop_Send, "m_fIsSprinting")) {
				if(lastButton[client]!=IN_SPEED && entFlags & FL_ONGROUND){
					lastButton[client] = IN_SPEED;
					setAnimationTransition(client, "charge_startfast", 0.7, "charge_loop", 0.0);
					EmitSoundToAll(angry3, client, SNDCHAN_VOICE, 100);
				}
				setSpeed(client, speed_run);
				vel[1]=0.0;
				SetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
				if(entFlags & FL_ONGROUND) Client_Shake(client, SHAKE_START, 2.5, 5.0, 0.2);
				return Plugin_Continue;
			}
			if (buttons & IN_FORWARD) {
				if(lastButton[client]!=IN_FORWARD){
					lastButton[client] = IN_FORWARD;
					setAnimationNoBlock(client, "walkN");
				}
				setSpeed(client, speed_walk);
				return Plugin_Continue;
			}
			if (buttons & IN_BACK) {
				if(lastButton[client]!=IN_BACK){
					lastButton[client] = IN_BACK;
					setAnimationNoBlock(client, "walk1");
				}
				setSpeed(client, speed_back);
				return Plugin_Continue;
			}
			if (buttons & IN_MOVELEFT && !(buttons & IN_MOVERIGHT)) {
				if(lastButton[client]!=IN_MOVELEFT){
					lastButton[client] = IN_MOVELEFT;
					setAnimationNoBlock(client, "walkE");
				}
				setSpeed(client, speed_back);
				return Plugin_Continue;
			}
			if (buttons & IN_MOVERIGHT && !(buttons & IN_MOVELEFT)) {
				if(lastButton[client]!=IN_MOVERIGHT){
					lastButton[client] = IN_MOVERIGHT;
					setAnimationNoBlock(client, "walkW");
				}
				setSpeed(client, speed_back);
				return Plugin_Continue;
			}
			if(lastButton[client]!=IN_NONE){
				setAnimationNoBlock(client, "alertidle");
				lastButton[client]=IN_NONE;
			}
			setSpeed(client, speed_walk);
		}
	}
	return Plugin_Continue;
}

/* called in a loop */
setSpeed(client, Float:goal){
	new Float:speed=GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
	if(speed<goal){
		speed+=0.05;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
	}
	else if(speed>goal){
		speed-=0.05;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
	}
}

freeze(client){
	SetEntityFlags(client, GetEntityFlags(client)|FL_FROZEN);
}

unfreeze(client){
	new flags=GetEntityFlags(client); flags &=~FL_FROZEN;
	SetEntityFlags(client, flags);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,0.0}); // no flying please
}

shove (client){
	new r = GetRandomInt(0,1);
	switch (r){
		case 0:
		{
			setAnimation(client, "shove", 0.8, 0.4); //the speed of punch is defined by speed // yeah, that sounds stupid
			EmitSoundToAll(angry1, client, SNDCHAN_VOICE, 100);
		}
		case 1:
		{
			setAnimation(client, "physthrow", 0.8, 0.4);
			EmitSoundToAll(angry2, client, SNDCHAN_VOICE, 100);
		}
	}
	nextAttack[client] = GetGameTime()+ATTACK_COOLDOWN;
	fl[client]|=G_ATTACKING;
	/* freeze(client); */
	
	if( !(fl[client] & G_THIRDPERSON) || fl[client] & G_FPFORCED){
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", Float:{600.0,0.0,0.0});
	}
	dmgTimers[client]=CreateTimer(0.4, dmg, client, TIMER_FLAG_NO_MAPCHANGE);
}

/****************************************************
// spawn antlions at 0, 90, 180, 270 angles around the player
// increment by 15 5 times so most of the circle is covered
// (eg second loop would be 15, 105, 195, 285) 
// stop after fifth loop has finished (>blocked path-can't spawn all)
// or when all have been spawned
****************************************************/
summon(client){
	setAnimation(client, "bark", 2.2);
	EmitSoundToAll(confused1, client, SNDCHAN_ITEM, 90);
	fl[client] |= G_SUMMONSOUND;
	nextSummon[client] = GetGameTime()+SUMMON_COOLDOWN;
	
	new toSpawn=SUMMON_MAX-GetArraySize(Ants[client]);
	if(SUMMON<toSpawn) toSpawn=SUMMON;
	if(toSpawn<=0) return;
	
	new Float:clEyePos[3]; GetClientEyePosition(client, clEyePos);
	new Float:clAngle[3]; GetClientAbsAngles(client, clAngle);
	new Float:angle[3]={0.0,0.0,0.0}, Float:fwd[3];
	
	for(new i=0;i<5;i++){
		for(new j=0;j<4;j++){
			angle[1]=i*15.0 + j*90.0;
			GetAngleVectors(angle, fwd, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fwd, SUMMON_DISTANCE);
			AddVectors(clEyePos, fwd, fwd);
			
			TR_TraceRayFilter(clEyePos, fwd, MASK_NPCSOLID, RayType_EndPoint, FilterNoGuard, client);
			if(!TR_DidHit()){
				new ant = CreateEntityByName("npc_antlion");
				if(ant!=-1){
					DispatchKeyValue(ant, "startburrowed", "1");
					DispatchKeyValue(ant, "spawnflags", "516");
					DispatchKeyValue(ant, "skin", "2");
					DispatchKeyValueVector(ant, "origin", fwd);
					DispatchKeyValueVector(ant, "angles", clAngle);
					DispatchSpawn(ant);
					AcceptEntityInput(ant, "unburrow");
					SetVariantString("!activator");
					AcceptEntityInput(ant, "FightToPosition", guardModel[client]); // client is notarget
			
					HookSingleEntityOutput(ant, "OnDeath", AntDeath, true);
					PushArrayCell(Ants[client], EntIndexToEntRef(ant));

					if(--toSpawn==0) return;
				}
			}
		}
	}
}

public AntDeath(const String:output[], caller, activator, Float:delay){
	new caller_ref = EntIndexToEntRef(caller);
	for(new i=1; i<=MaxClients; i++){
		if(IsClientInGame(i) && guardModel[i]!=-1){
			new arrayIndex=FindValueInArray(Ants[i], caller_ref);
			if(arrayIndex!=-1){
				RemoveFromArray(Ants[i], arrayIndex);
				return;
			}
		}
	}
}

setAnimationTransition(client, String:animation1[], Float:wait, String:animation2[], Float:newspeed){
	fl[client] |= G_ANIMATING;
	new Handle:pack;
	animTimers[client]=CreateDataTimer(wait, preAnimFinished, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(pack, GetClientUserId(client));
	WritePackFloat(pack, newspeed);
	WritePackString(pack, animation2);
	setAnimationNoBlock(client, animation1);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed_blocked);
}

stock setAnimation(client, String:animation[], Float:wait, Float:speed=0.0){
	fl[client] |= G_ANIMATING;
	if(speed>=0.0)
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
		
	animTimers[client]=CreateTimer(wait, unBlock, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	setAnimationNoBlock(client, animation);
}

public Action:preAnimFinished(Handle:timer, any:pack){
	ResetPack(pack);
	new id = ReadPackCell(pack);
	new client = GetClientOfUserId(id);
	if(client!=0){
		new Float:speed = ReadPackFloat(pack);
		new String:animation[32]; ReadPackString(pack, animation, sizeof(animation));

		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
		setAnimationNoBlock(client, animation);
		unBlock(INVALID_HANDLE, id);
	}
}

setAnimationNoBlock(client, String:animation[]){
	SetVariantString(animation);
	AcceptEntityInput(EntRefToEntIndex(guardModel[client]), "SetAnimation");
}

RemoveAnimQueue(client, bool:revertToIdle){
	if(animTimers[client]!=INVALID_HANDLE){
		KillTimer(animTimers[client]);
		animTimers[client]=INVALID_HANDLE;
	}
	if(dmgTimers[client]!=INVALID_HANDLE){
		KillTimer(dmgTimers[client]);
		dmgTimers[client]=INVALID_HANDLE;
		fl[client] &= ~G_ATTACKING;
		unfreeze(client);
	}
	if(revertToIdle){
		lastButton[client]=IN_NONE;
		fl[client] &= ~G_ANIMATIONSTATE;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed_walk);
	}else
		fl[client] &= ~G_ANIMATING;
}

public Action:unBlock(Handle:timer, any:id){
	new client = GetClientOfUserId(id); 
	if(client!=0){
		fl[client] &= ~G_ANIMATING;
		animTimers[client]=INVALID_HANDLE;
		unfreeze(client);
	}
}

public Action:dmg(Handle:timer, any:client){
	dmgTimers[client]=INVALID_HANDLE;
	fl[client] &= ~G_ATTACKING;
	if( !(fl[client] & G_THIRDPERSON) || fl[client] & G_FPFORCED){
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.2);
		new Float:punch[3]; GetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", punch);
		punch[0]=-600.0;
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", punch);
	}
	unfreeze(client);
	PushAway(client, DAMAGE_HUMANS, DAMAGE, FORCE, RADIUS);
}

stock bool:PushAway(client, Float:dmg_humans, Float:dmg, Float:force, Float:radius, Float:maxAngle=30.0, bool:pushZ=true, bool:sound=true){
	new bool:hit;
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	for (new i = 1; i <= MaxClients; i++){
		if(guardModel[i] == -1 && IsClientInGame(i) && IsPlayerAlive(i)){
			new Float:entPos[3];
			GetClientAbsOrigin(i, entPos);
			decl Float:distance[3];
			MakeVectorFromPoints(entPos, clientPos, distance);
			
			if (CheckDistance(distance, radius) && IsClientFacing(client, i, maxAngle))
			{
				decl Float: addAmount[3];
				decl Float: ratio[2];
				
				ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));
				ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));

				addAmount[0] = FloatMul( ratio[0]*-1, force);//multiply negative = away
				addAmount[1] = FloatMul( ratio[1]*-1, force);
				if(pushZ) addAmount[2] = force/2.0; else addAmount[2] = 0.0;

				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, addAmount);
				SDKHooks_TakeDamage(i, client, client, dmg_humans, DMG_CRUSH, -1, addAmount, clientPos);
				
				dmgCount[client]+=dmg_humans;
				
				Client_Shake(i, SHAKE_START, 20.0, 10.0, 0.4);
				hit=true;
			}
		}
	}
	new maxEnts=GetMaxEntities();
	for (new i = (MaxClients+1); i < maxEnts; i++)
	{
		if (IsEntNetworkable(i))
		{
			decl Float:entPos[3];
			new offset = GetEntSendPropOffs(i, "m_vecOrigin", true);
			if(offset>0){
				GetEntDataVector(i, offset, entPos);
			}else continue;
			
			decl Float:distance[3];
			MakeVectorFromPoints(entPos, clientPos, distance);
			
			if (CheckDistance(distance, radius) && IsClientFacing(client, i, maxAngle))
			{
				decl Float: addAmount[3];
				decl Float: ratio[2];
				
				ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));
				ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));

				addAmount[0] = FloatMul( ratio[0]*-1, force);//multiply negative = away
				addAmount[1] = FloatMul( ratio[1]*-1, force);
				if(pushZ)addAmount[2] = force/2.0; else addAmount[2] = 0.0;
				
				decl String:classname[14];
				new MoveType:movetype = GetEntityMoveType(i);
				new bool:projectile;
				if(GetEntityClassname(i, classname, sizeof(classname))){
					if(StrEqual(classname, "rpg_missile") || StrEqual(classname, "crossbow_bolt") || StrEqual(classname, "plasma")){
						projectile=true;
					}
				}
				
				if(movetype != MOVETYPE_PUSH && !projectile){ //<bad ent filter
					TeleportEntity(i, entPos, NULL_VECTOR, addAmount);
					SDKHooks_TakeDamage(i, client, client, dmg, DMG_CRUSH, -1, addAmount, clientPos);
					
					if(!(GetEntityFlags(i) & FL_NPC))
						SetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", Float:{0.0,0.0,0.0}); // velocity (trampoline) fix
					else hit=true; // hit sound for npcs
				}
				if(movetype == MOVETYPE_VPHYSICS) hit=true;
			}
		}
	}
	if(hit){
		Client_Shake(client, SHAKE_START, 10.0, 10.0, 0.2);
		if(sound) EmitSoundToAll(shove1, client, SNDCHAN_BODY, 90);
		return true;
	}
	return false;
}

bool:CheckDistance(Float:distance[3], Float:radius){
	if (SquareRoot( FloatMul(distance[0],distance[0]) + FloatMul(distance[1],distance[1]) + FloatMul(distance[2],distance[2])) <= radius) return true;
	return false;
}

stock bool:IsClientFacing (client, entity, Float:maxAngle=30.0, bool:ignoreZ=true){
	decl Float:clientOrigin[3]; decl Float:entOrigin[3];
	decl Float:eyeAngles[3]; decl Float:directAngles[3];
	
	GetClientEyePosition(client, clientOrigin); GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entOrigin);
	// Get the vector from player to the entity
	MakeVectorFromPoints(clientOrigin, entOrigin, directAngles); 
	
	GetVectorAngles(directAngles, directAngles);
	
	GetClientEyeAngles(client, eyeAngles);

	if(ignoreZ){
		eyeAngles[0]=0.0; directAngles[0]=0.0;
	}
	
	if(GetDifferenceBetweenAngles(eyeAngles, directAngles)>maxAngle){
		return false;
	}
	return true;
}

Float:GetDifferenceBetweenAngles(Float:fA[3], Float:fB[3])
{
    decl Float:fFwdA[3]; GetAngleVectors(fA, fFwdA, NULL_VECTOR, NULL_VECTOR);
    decl Float:fFwdB[3]; GetAngleVectors(fB, fFwdB, NULL_VECTOR, NULL_VECTOR);
    return RadToDeg(ArcCosine(fFwdA[0] * fFwdB[0] + fFwdA[1] * fFwdB[1] + fFwdA[2] * fFwdB[2]));
}

bool:IsClientValid(client)
{ 	if (client < 1) return false;
 	if (client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}

public Action:BlockKill(client, const String:command[], argc) {
	if(guardModel[client]!=-1)
		return Plugin_Handled;
	return Plugin_Continue;
} 

stock showParticle(const Float:pos[3], String:particlename[], parentEnt=-1)
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

public Action:delayDelete(Handle:timer, any:data){
	AcceptEntityInput(data, "kill");
}