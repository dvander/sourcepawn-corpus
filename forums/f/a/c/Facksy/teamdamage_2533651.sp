#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

bool TDEnabled;

public Plugin myinfo ={
	name = "Team Damage",
	author = "Facksy",
	description = "Take damage if you shot your allies",
	version = "1.0.1",
	url = "http://steamcommunity.com/id/iamfacksy/"
};

public void OnPluginStart(){
	CreateConVar("sm_team_damage_version", "1.0.1", "Team Damage version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	char Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
		SetFailState("This plugin only works for TF2");
	
	RegAdminCmd("sm_teamdamage", Cmd_Teamdamage, ADMFLAG_CHEATS, "Toggle team damage");
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
}

public Action Cmd_Teamdamage(int client, int args){
	if(!args){
		TDEnabled = !TDEnabled;
		PrintToChat(client, "[SM] Team Damage is now %s.", TDEnabled ? "enabled" : "disabled");
	}
	else
		ReplyToCommand(client, "No args");
	return Plugin_Handled;
}

public Action Event_Player_Hurt(Event event, const char[] name, bool dontBroadcast){
	int victimId = GetClientOfUserId(event.GetInt("userid"));
	int attackerId = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("damageamount");
	if(TDEnabled && victimId != 0 && attackerId != 0){
		if(GetClientTeam(victimId) == GetClientTeam(attackerId)){
			SDKHooks_TakeDamage(attackerId, 0, 0, float(damage));	    
			SetEntityHealth(victimId, GetClientHealth(victimId) + damage);
		}
	}
}