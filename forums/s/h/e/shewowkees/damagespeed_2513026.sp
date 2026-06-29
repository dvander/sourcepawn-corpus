#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clients>
#include <sdkhooks>

ConVar sm_dmgspeed_speed_multiplier = null;
ConVar sm_dmgspeed_team_restriction = null;


public Plugin myinfo ={
	name = "damage speed",
	author = "shewowkees",
	description = "adds an option to multiply the force caused by damege",
	version = "1.0",
	url = "noSiteYet"
};

public void OnPluginStart (){
	PrintToServer("damage speed V1.O by shewowkees.");

	//CONVARS
	sm_dmgspeed_speed_multiplier = CreateConVar("sm_dmgspeed_speed_multiplier","50.0","by how much the damage forces are multiplied");
	sm_dmgspeed_team_restriction = CreateConVar("sm_dmgspeed_team_restriction","-1","selects the team to be affected by the augmented forces -1 for all teams");
	AutoExecConfig(true, "plugin_dmgspeed");
}

public OnMapStart(){


	HookEvent("player_spawn",Evt_PlayerSpawnChangeClass,EventHookMode_Post);



}

public void OnClientPostAdminCheck(int client){

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

}


public Action Evt_PlayerSpawnChangeClass(Event event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(event .GetInt("userid"));
	SetEntPropFloat(client, Prop_Data, "m_flFriction", 0.0);

}

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
		float mult = GetConVarFloat(sm_dmgspeed_speed_multiplier);
		int team = GetConVarInt(sm_dmgspeed_team_restriction);
    if(victim==attacker){
			return Plugin_Continue;
		}
		if(IsClientInGame(victim)){
			if(GetClientTeam(victim)==team || team==-1){
				float victimPos[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin",victimPos);
				float attackerPos[3];
				GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);

				for(int i=0;i<3;i++){
					victimPos[i]=(victimPos[i]-attackerPos[i]);
				}
				NormalizeVector(victimPos, victimPos);
				for(int i=0;i<3;i++){
					victimPos[i]=damage*mult*victimPos[i]
				}
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, victimPos)
			}

		}


    return Plugin_Continue;
}
