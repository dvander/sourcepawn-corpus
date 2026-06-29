#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>

#define PLUGIN_VERSION "1.2"
#define MeetChester_MDL "models/workshop/player/items/all_class/taunt_burstchester/taunt_burstchester_heavy.mdl"
int iChester[MAXPLAYERS+1] = -1;
bool MoveUp[1500] = false;
bool MoveUpBig[1500] = false;
int MoveUpFloat[1500] = 0;
int MoveUpFloatBig[1500] = 0;
int LastUsed[MAXPLAYERS+1];
public Plugin myinfo = 
{
	name = "[TF2] Chester Spawner",
	author = "TonyBaretta",
	description = "Meet Chester",
	version = "1.1",
	url = "http://www.wantedgov.it"
}
public void OnMapStart()
{
	PrecacheModel(MeetChester_MDL, true);
	PrecacheSound("misc/halloween/spell_skeleton_horde_rise.wav", true);
}
public void OnPluginStart()
{
	RegAdminCmd("sm_chester", Command_Chester, ADMFLAG_ROOT);
	RegAdminCmd("sm_bigchester", Command_BigChester, ADMFLAG_ROOT);
	RegAdminCmd("sm_bchester", Command_BigChester, ADMFLAG_ROOT);
	RegAdminCmd("sm_chesterme", Command_ChesterMe, ADMFLAG_CUSTOM1);
	CreateConVar("chester_spawner_version", PLUGIN_VERSION, "Current burstchester_taunt version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases.txt");
}
public Action Command_Chester(int client, int args)
{
	char target[65];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] Usage: sm_chester <#userid|name>");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
				
		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]))
			{
				ChesterSpawnEvent(target_list[i]);
			}
		}
		EmitSoundToAll("misc/halloween/spell_skeleton_horde_rise.wav");
		return Plugin_Handled;
	}
}

public Action Command_BigChester(int client, int args)
{
	char target[65];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] Usage: sm_bigchester <#userid|name> or sm_bchester <#userid|name> ");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
				
		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]))
			{
				SpawnBigChester(target_list[i]);
			}
		}
		EmitSoundToAll("misc/halloween/spell_skeleton_horde_rise.wav");
		return Plugin_Handled;
	}
}
public Action Command_ChesterMe(int client, int args){
	if(IsValidClient(client) && IsPlayerAlive(client)){
		int currentTimevictim = GetTime();
		if (currentTimevictim - LastUsed[client] < 3){
			PrintToChat(client, "\x03[SM] You are flooding the chat");
			return Plugin_Handled;
		}
		LastUsed[client] = GetTime();
		ChesterSpawnEvent(client);
		EmitSoundToClient(client, "misc/halloween/spell_skeleton_horde_rise.wav");
	}
	return Plugin_Handled;
}
public Action ChesterSpawnEvent(int Target) {
	float posg[3];
	if (IsValidClient(Target) && IsPlayerAlive(Target)) {
		GetClientGroundPosition(Target, posg);
		float ang[3];
		ang[0] = -90.0;
		ang[1] = GetRandomFloat(-180.0 , 180.0);
		iChester[Target] = CreateEntityByName("prop_dynamic");
		if(IsValidEntity(iChester[Target])){
			DispatchKeyValue(iChester[Target], "modelscale", "4.0");
			DispatchKeyValue(iChester[Target], "model", MeetChester_MDL);
			DispatchKeyValue(iChester[Target], "targetname", "chester_ent"); 
			SetEntProp(iChester[Target], Prop_Send, "m_nSolidType", 2);
			DispatchSpawn(iChester[Target]);
			char addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", 5.0);
			SetVariantString(addoutput);
			AcceptEntityInput(iChester[Target], "AddOutput");
			AcceptEntityInput(iChester[Target], "FireUser1"); 
			posg[2] = (posg[2] - 80.0);
			TeleportEntity(iChester[Target], posg, ang, NULL_VECTOR);
			int Rent = EntRefToEntIndex(iChester[Target]);
			CreateTimer(2.0, Timer_RemoveTarget, Rent );
			MoveUp[iChester[Target]] = true;
			ChesterParticle(iChester[Target], "ghost_appearation", 2.0);
			ChesterParticle(iChester[Target], "utaunt_lightning_parent", 2.0);
			SDKHook(iChester[Target], SDKHook_StartTouch, OnTouchChester);
		}
	}
}
public Action SpawnBigChester(int Target) {
	float posg[3];
	if (IsValidClient(Target) && IsPlayerAlive(Target)) {
		GetClientGroundPosition(Target, posg);
		float ang[3];
		ang[0] = -90.0;
		ang[1] = GetRandomFloat(-180.0 , 180.0);
		iChester[Target] = CreateEntityByName("prop_dynamic");
		if(IsValidEntity(iChester[Target])){
			DispatchKeyValue(iChester[Target], "modelscale", "9.0");
			DispatchKeyValue(iChester[Target], "model", MeetChester_MDL);
			SetEntProp(iChester[Target], Prop_Send, "m_nSolidType", 2);
			DispatchKeyValue(iChester[Target], "targetname", "chester_ent"); 
			DispatchSpawn(iChester[Target]);
			char addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", 5.0);
			SetVariantString(addoutput);
			AcceptEntityInput(iChester[Target], "AddOutput");
			AcceptEntityInput(iChester[Target], "FireUser1");
			posg[2] = (posg[2] - 80.0);
			TeleportEntity(iChester[Target], posg, ang, NULL_VECTOR);
			int Rent = EntRefToEntIndex(iChester[Target]);
			CreateTimer(2.0, Timer_RemoveTarget, Rent );
			MoveUpBig[iChester[Target]] = true;
			ChesterParticle(iChester[Target], "ghost_appearation", 2.0);
			SDKHook(iChester[Target], SDKHook_StartTouch, OnTouchChester);
		}
	}
}
public void OnGameFrame(){
	for (int i=0; i<sizeof(iChester); i++)
	{
		if(IsValidEntity(iChester[i])){
			char classname[64];
			GetEdictClassname(iChester[i], classname, sizeof(classname));
			if (StrEqual(classname, "prop_dynamic")) {
				if (MoveUp[iChester[i]] && MoveUpFloat[iChester[i]] < 30) {
					MoveUpFloat[iChester[i]] += 5;
					MeetChester_Pos(iChester[i]);
				}
				if (!MoveUp[iChester[i]]  && MoveUpFloat[iChester[i]] > 0) {
					MoveUpFloat[iChester[i]] -= 5;
					MeetChester_Pos(iChester[i]);
				}
				if (MoveUpBig[iChester[i]] && MoveUpFloatBig[iChester[i]] < 32) {
					MoveUpFloatBig[iChester[i]] += 5;
					ChesterBig_Pos(iChester[i]);
				}
				if (MoveUpBig[iChester[i]] == false && MoveUpFloatBig[iChester[i]] > 0) {
					MoveUpFloatBig[iChester[i]] -= 5;
					ChesterBig_Pos(iChester[i]);
				}
			}
		}
	}
}
int MeetChester_Pos(iEntity){
	float pos[3];
	if(IsValidEntity(iEntity)){
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", pos);
		if (MoveUp[iEntity]){
			pos[2] = pos[2] + float(MoveUpFloat[iEntity]);
		}
		if (!MoveUp[iEntity]){
			pos[2] = pos[2] - float(MoveUpFloat[iEntity]);
		}
		TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	}
}
int ChesterBig_Pos(iEntity){
	float pos[3];
	if(IsValidEntity(iEntity)){
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", pos);
		if (MoveUpBig[iEntity]){
			pos[2] = pos[2] + float(MoveUpFloatBig[iEntity]);
		}
		if (!MoveUpBig[iEntity]){
			pos[2] = pos[2] - float(MoveUpFloatBig[iEntity]);
		}
		TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action Timer_RemoveTarget(Handle timer, any iEntity) {
	if(IsValidEntity(iEntity)){
		MoveUp[iEntity] = false;
		MoveUpBig[iEntity] = false;
	}
}
public Action OnTouchChester(int iEnt, int client){
	char classname[64];
	GetEdictClassname(iEnt, classname, sizeof(classname));
	if (StrEqual(classname, "prop_dynamic")) {
		if(client <0 || client > MAXPLAYERS)return Plugin_Changed;
		FakeClientCommand(client,"explode");	
	}
	return Plugin_Continue;
}
public bool GetClientGroundPosition(int iClient, float fGround[3]){
	float fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	
	float fAngles[3] = {90.0, 0.0, 0.0};
	TR_TraceRayFilter(fOrigin, fAngles, MASK_SOLID, RayType_Infinite, TraceRay_DontHitSelf, iClient);
	if(TR_DidHit()){
		TR_GetEndPosition(fGround);
		return true;
	}	
	return false;
}

public bool TraceRay_DontHitSelf (int iTarget, iMask, int iClient) { return (iTarget != iClient); }

stock bool:IsValidClient(iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}
stock int ChesterParticle(int iEntity, char effect[128], float time)
{
	
	int strIParticle = CreateEntityByName("info_particle_system");
	char strName[128];
	if (IsValidEdict(strIParticle))
	{
		float strflPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", strflPos);
		strflPos[2] = strflPos[2] + 80.0;
		TeleportEntity(strIParticle, strflPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(strName, sizeof(strName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", strName);
		
		DispatchKeyValue(strIParticle, "targetname", "tf2particle");
		DispatchKeyValue(strIParticle, "parentname", strName);
		DispatchKeyValue(strIParticle, "effect_name", effect);
		DispatchSpawn(strIParticle);
		char addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", 5.0);
		SetVariantString(addoutput);
		AcceptEntityInput(strIParticle, "AddOutput");
		AcceptEntityInput(strIParticle, "FireUser1"); 
		SetVariantString(strName);
		//AcceptEntityInput(strIParticle, "SetParent", strIParticle, strIParticle, 0);
		ActivateEntity(strIParticle);
		AcceptEntityInput(strIParticle, "start");
	}
}