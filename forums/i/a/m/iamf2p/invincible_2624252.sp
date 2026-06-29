#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <entity_prop_stocks>
#include <sdkhooks>
#include <tf2items>
#include <sdktools>
#define MAX_LEN 60
/*

My first piece of plugin!

*/


public Plugin:myinfo = {
name = "firstmanpower",description = "firstmanpower",url = "firstmanpower"
};

public void OnPluginStart(){

RegAdminCmd("sm_invincible", invinsible, ADMFLAG_SLAY);

}

public Action invinsible(int client, int args){
	char arg1[32], arg2[32];
	int damage;
	GetCmdArg(1, arg1, sizeof(arg1));
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		damage = StringToInt(arg2);
	}
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (int i = 0; i < target_count; i++)
	{
		char name[MAX_LEN];
		GetClientName(target_list[i], name, MAX_LEN);
		if(damage >= 1){
		if(IsPlayerAlive(target_list[i]) != true){
		if(TF2_GetClientTeam(target_list[i]) == TFTeam_Red){
		TF2_RespawnPlayer(target_list[i]);
		}
		if(TF2_GetClientTeam(target_list[i]) == TFTeam_Blue){
		TF2_RespawnPlayer(target_list[i]);
		}
		if(TF2_GetClientTeam(target_list[i]) == TFTeam_Spectator){
		return Plugin_Handled;
		}
		}		
		PrintToChat(client, "\x03[SM]\x04 UBER INVINCIBLE: \x05ON TO\x05 %s", name); // zhank you sourcemod!
		PrintHintText(target_list[i], "[SM]UBER INVINCIBLE ON");
		SDKHook(target_list[i], SDKHook_OnTakeDamage, callback);
		}
		if(damage <= 0){
		PrintToChat(client, "\x03[SM]\x04 UBER INVINCIBLE: \x05OFF TO\x05 %s", name);
		PrintHintText(target_list[i], "[SM]UBER INVINCIBLE OFF");
		SDKUnhook(target_list[i], SDKHook_OnTakeDamage, callback);
		}
	}
return Plugin_Handled;
}

public Action callback(int victim, int& attacker, int& inflictor, float& damage, int& damagetype){
TF2_AddCondition(victim, TFCond_UberchargedCanteen, 0.5, 0);
}