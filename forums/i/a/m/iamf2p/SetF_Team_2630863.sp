#include <sourcemod>
#include <sdktools>
#include <entity>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

/*

made by firstmanpower


*/


public void OnPluginStart()
{
	AddCommandListener(SayCallback, "kill");
	AddCommandListener(SayCallback_1, "explode");
	AddCommandListener(SayCallback_2, "changeteam");
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_setteam", Command_setteam, ADMFLAG_SLAY, "set to client team");
}

public Action SayCallback(int client, const char[] command, int argc)
{
	if(TF2_GetClientTeam(client) != TFTeam_Spectator){
	
	return Plugin_Continue;
	
	}else{
	
    return Plugin_Handled;
	
	}
}
public Action SayCallback_1(int client, const char[] command, int argc)
{
	if(TF2_GetClientTeam(client) != TFTeam_Spectator){
	
	return Plugin_Continue;
	
	}
	if(TF2_GetClientTeam(client) == TFTeam_Spectator){
	
	return Plugin_Handled;
	
	}
	else{
	
    return Plugin_Handled;
	
	}
}
public Action SayCallback_2(int client, const char[] command, int argc)
{
	if(TF2_GetClientTeam(client) != TFTeam_Spectator){
	
	return Plugin_Continue;
	
	}else{
	
    return Plugin_Handled;
	
	}
}

public Action Command_setteam(int client, int args)
{
	char arg1[32], arg2[32];
	int number;
	int check_number = 0;
	GetCmdArg(1, arg1, sizeof(arg1));
	if(args < 2){

	PrintToChat(client, "Usage: sm_setteam <target> <team number or red blue spec>");
	
	return Plugin_Handled;
	
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if(StrEqual(arg2, "red", false)){
	
	check_number = 1;
	number = 2;
	
	}
	if(StrEqual(arg2, "blue", false)){
	check_number = 1;
	number = 3;
	
	}
	if(StrEqual(arg2, "spec", false)){
	
	check_number = 1;
	number = 1;
	
	}
	
	if(check_number != 1){
	number = StringToInt(arg2);
	}

	if(args > 3){
	
	PrintToChat(client, "NO");
	
	return Plugin_Handled;
	}
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 

	
	for (int i = 0; i < target_count; i++)
	{
	
	if(IsPlayerAlive(target_list[i]) != true){
	
	TF2_RespawnPlayer(target_list[i]);
	
	}
	
	SetTeam(target_list[i], number);
	
	if(number == 1){
	
	SDKHook(target_list[i], SDKHook_OnTakeDamage, callback);
	
	}
	if(number != 1){
	
	SDKUnhook(target_list[i], SDKHook_OnTakeDamage, callback);
	
	}
	
	}
 
	return Plugin_Handled;


}

public Action callback(int victim, int& attacker, int& inflictor, float& damage, int& damagetype){

TF2_AddCondition(victim, TFCond_UberchargedHidden,0.4, 0);

}


//--------------------functions---------------------



/*
stock SetModelScale_F(int client, float value){

if(IsPlayerAlive(client) != true){

ReplyToCommand(client, "NO");

}
if(IsPlayerAlive(client) != false){

SetEntPropFloat(client, Prop_Send, "m_flModelScale", value, 4);

}

}

stock SetClip_Firs(int client, int value, int weaponslot){

int weapon = GetPlayerWeaponSlot(client, weaponslot);

if(!IsValidEntity(weapon)){
		ReplyToCommand(client, "NO");
}
if(IsPlayerAlive(client) != true){

ReplyToCommand(client, "NO");

}
if(IsPlayerAlive(client) != false){

SetEntProp(weapon, Prop_Send, "m_iClip1", value, 8);

}

}
*/


stock SetTeam(int client, int value){

if(!IsValidEntity(client)){
ReplyToCommand(client, "NO");
}

if(IsValidEntity(client) == true){

if(value <= -1){

ReplyToCommand(client, "NO");

}

if(value >= 4){
ReplyToCommand(client, "NO");
}
if(value <= 3 && (value <= -1) != true){

SetEntProp(client, Prop_Send, "m_iTeamNum", value, 8);

}



}

}


/*

	if(number == 2){
	
	TF2_ChangeClientTeam(target_list[i], TFTeam_Red);
	TF2_SetPlayerClass(target_list[i], TFClass_Scout, false, false);
	
	}
	if(number == 3){
	
	TF2_ChangeClientTeam(target_list[i], TFTeam_Blue);
	TF2_SetPlayerClass(target_list[i], TFClass_Scout, false, false);
	
	}
	*/
	
//m_iTeamNum
//m_flPlaybackRate
//m_flNextAttack


