#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = {
    name = "tf2 funny mind control",
    author = "ABCDEFGH23",
    description = "have fun",
    version = "No version",
    url = "No url"
};

Handle hFollowEntity;

Handle hStopFollowingEntity;

int g_FollowTarget[MAXPLAYERS+1] = {-1, ...};

public void OnPluginStart(){

Handle Config = LoadGameConfigFile("tf2.funny_mind_control");

StartPrepSDKCall(SDKCall_Entity);
PrepSDKCall_SetFromConf(Config, SDKConf_Signature, "CBaseEntity::FollowEntity");
PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
hFollowEntity = EndPrepSDKCall();

StartPrepSDKCall(SDKCall_Entity);
PrepSDKCall_SetFromConf(Config, SDKConf_Signature, "CBaseEntity::StopFollowingEntity");
hStopFollowingEntity = EndPrepSDKCall();

CloseHandle(Config);

RegAdminCmd("sm_funny_mind_control", funny_mind_control, ADMFLAG_CHEATS);
RegAdminCmd("sm_stop_funny_mc", stop_funny_mc, ADMFLAG_CHEATS);

}

void StopFollowingEntity(int target){

SDKCall(hStopFollowingEntity, target);

}

void FollowEntity(int target, int owner, bool bone_merge=true){

SDKCall(hFollowEntity, target, owner, bone_merge);

}

public void OnClientDisconnect(int client){

for(int target = 1; target <= MaxClients; target++)
if(g_FollowTarget[target] == client){
StopFollowingEntity(target);
SDKUnhook(target, SDKHook_PreThink, TargetThink);
SetEntityMoveType(target, MOVETYPE_WALK);
TF2_RemoveCondition(target, TFCond_FreezeInput);
SetEntProp(target, Prop_Data, "m_takedamage", 2); //from DarthNinja's God Mode plugins
g_FollowTarget[target] = -1;
}

}

public Action stop_funny_mc(int client, int args){

if(args != 1){
PrintToChat(client, "[SM] sm_stop_funny_mc <target>");
return Plugin_Handled;
}

char arg1[50];

GetCmdArg(1, arg1 ,sizeof(arg1)); //target

char target_name[MAX_TARGET_LENGTH];
int target_list[MAXPLAYERS], target_count;
bool tn_is_ml;

if((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml)) <= 0){
ReplyToTargetError(client, target_count);
return Plugin_Handled;
}

char TargetName[70];

for(int i = 0; i < target_count; i++){
	
	StopFollowingEntity(target_list[i]);
	
	SDKUnhook(target_list[i], SDKHook_PreThink, TargetThink);
	TF2_RemoveCondition(target_list[i], TFCond_FreezeInput);

	g_FollowTarget[target_list[i]] = -1;
	
	SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2);
	
	SetEntityMoveType(target_list[i], MOVETYPE_WALK);
	
	
	GetClientName(target_list[i], TargetName, sizeof(TargetName));
	PrintToChat(client, "%s Control stopped", TargetName);
	
}

return Plugin_Handled;

}

public Action funny_mind_control(int client, int args){

if(args != 2){
PrintToChat(client, "[SM] sm_funny_mind_control <owner> <target> <bone_merge:1>");
return Plugin_Handled;
}

char arg1[50], arg2[50], arg3[50];

GetCmdArg(1, arg1 ,sizeof(arg1)); //owner

GetCmdArg(2, arg2 ,sizeof(arg2)); //target

GetCmdArg(3, arg3 ,sizeof(arg3)); //bone_merge

if(arg3[0] == 0)arg3[0] = '1';





//-----------------------------------owner------------------------------------------------

char target_name[MAX_TARGET_LENGTH];
int target_list[MAXPLAYERS], target_count;
bool tn_is_ml;

if((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml)) <= 0){
ReplyToTargetError(client, target_count);
return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------






//-----------------------------------target----------------------------------------------------

int target_list2[MAXPLAYERS], target_count2;
 
if((target_count2 = ProcessTargetString(arg2,client,target_list2,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml)) <= 0){
ReplyToTargetError(client, target_count);
return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------





char TargetName[70];

bool bone_merge = view_as<bool>(StringToInt(arg3));

for(int i = 0; i < target_count; i++){

	for(int i2 = 0; i2 < target_count2; i2++){
		
		GetClientName(target_list2[i2], TargetName, sizeof(TargetName));
		
		FollowEntity(target_list2[i2], target_list[i], bone_merge);
		
		g_FollowTarget[target_list2[i2]] = target_list[i];
		
		SDKHook(target_list2[i2], SDKHook_PreThink, TargetThink);
		SetEntProp(target_list2[i], Prop_Data, "m_takedamage", 0);
		
		PrintToChat(target_list[i], "you are controlling %s", TargetName);
		
	}

}

return Plugin_Handled;

}

public void TargetThink(int target){

if(!TF2_IsPlayerInCondition(target, TFCond_FreezeInput))
TF2_AddCondition(target, TFCond_FreezeInput, TFCondDuration_Infinite, 0);

}
