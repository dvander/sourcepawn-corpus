#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"
#define PLUGIN_PREFIX "\x04[Block Trading]\x01"

public Plugin:myinfo = 
{
	name = "Block Trading",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

enum TFItemFound{
    TFItemFound_Drop=0,
    TFItemFound_Craft=1,
    TFItemFound_Trade=2,
    TFItemFound_Purchase=3,
    TFItemFound_Unbox=4,
    TFItemFound_Gift=5,
    TFItemFound_Support=6,
    TFItemFound_Promotion=7,
    TFItemFound_Earn=8,
    TFItemFound_Refund=9
} 

new bool:started;

new Handle:cv_enable;
new Handle:cv_craft;
new Handle:cv_allow_spec;

public OnPluginStart(){
	CreateConVar("sm_blocktrading_version", PLUGIN_VERSION, "Block Trading Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cv_enable = CreateConVar("sm_blocktrading_enable", "1", "Enables Block Trading",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cv_enable, CC_Enable);
	
	cv_craft = CreateConVar("sm_blocktrading_craft", "0", "Allows crafting",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_allow_spec = CreateConVar("sm_blocktrading_allow_spec", "1", "Allow spectators to trade/craft",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	if(GetConVarBool(cv_enable)){
		StartPlugin();
	}else{
		StopPlugin();
	}
}

public CC_Enable(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarBool(cv_enable)){
		StartPlugin();
	}else{
		StopPlugin();
	}
}

public StartPlugin(){
	if(started) return;
	started=true;
	
	HookEvent("item_found", item_found);
	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("teamplay_setup_finished", teamplay_setup_finished);
	
}

public StopPlugin(){
	if(!started) return;
	started=false;
	
	UnhookEvent("item_found", item_found);
	UnhookEvent("teamplay_round_active", teamplay_round_active);
	UnhookEvent("teamplay_setup_finished", teamplay_setup_finished);
}

public Action:item_found(Handle:event, String:name[], bool:dontBroadcast){
	new ent=FindEntityByClassname(-1, "tf_gamerules");
	if(ent==-1) return;
	new bool:inSetup = InSetup();
	if(inSetup) return;
	
	new client = GetEventInt(event, "player");
	
	if(GetConVarBool(cv_allow_spec) && GetClientTeam(client)<2){
		return;
	}
	new bool:isAdmin = GetAdminFlag(GetUserAdmin(client), Admin_Reservation);
	if(isAdmin) return;
	
	new TFItemFound:method = TFItemFound:GetEventInt(event, "method");
	if(method==TFItemFound_Trade){
		BanClient(client, 5, BANFLAG_AUTO, "Trading when not in setup", "You cannot trade while not in setup");
	}else if(method==TFItemFound_Craft && !GetConVarBool(cv_craft)){
		BanClient(client, 5, BANFLAG_AUTO, "Crafting when not in setup", "You cannot craft while not in setup");
	}
}

public Action:teamplay_round_active(Handle:event, String:name[], bool:dontBroadcast){
	new ent=FindEntityByClassname(-1, "tf_gamerules");
	if(ent==-1) return;
	new bool:inSetup = bool:GetEntProp(ent, Prop_Send, "m_bInSetup");
	if(!inSetup) return;
	
	PrintToChatAll("%s Trading is allowed for now, only during the setup", PLUGIN_PREFIX);
}

public Action:teamplay_setup_finished(Handle:event, String:name[], bool:dontBroadcast){
	PrintToChatAll("%s Trading is no longer allowed, any trades starting from now will result in ban", PLUGIN_PREFIX);
}

stock bool:InSetup(){
	new ent=FindEntityByClassname(-1, "team_round_timer");
	if(ent==-1) return false;
	return GetEntProp(ent, Prop_Send, "m_nState")==0;
}