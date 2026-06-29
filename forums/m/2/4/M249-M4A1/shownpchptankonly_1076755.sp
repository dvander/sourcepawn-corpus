
/********************************************
* 
* Show NPC Health Version "1.3.13"
* 
* Description:
* Shows the health of a NPC to a players hud in the left down corner. Useful for coop servers.
* 
* ConVars:
* with "sm_shownpchp_enable 1" you can enable or disable the hole plugin.
* with "sm_shownpchp_hud 1" this sets the display mode 1 means HintBox, 0 Means HudMessage.
* 
* NOTICE: - go to addons/sourcemod/configs/shownpchp.cfg to change any of the convars above.
*         - IF YOU UPDATE THIS PLUGING BE SURE TO DELETE THE 'shownpchp.cfg'		
* 
* Changelog:
* v1.3.13 - Fixed: A small bug with the HudMessages.
* v1.3.12 - Added: Support for L4D2 and other games.
*         - Added: Automated usage of ShowHudText or PrintHintText last is prefered by this plugin
*         - Added: Relationship Suppot, this means you can see if a NPC or Player is Friend or Foe.
* v1.1.2  - First char in name is now upper case
* v1.1.1  - Small bugfix for player health
* v1.1.0  - First Public Release
* 
* 
* Thank you Berni, Manni, Mannis FUN House Community and SourceMod/AlliedModders-Team
* 
* *************************************************/

/****************************************************************
P R E C O M P I L E R   D E F I N I T I O N S
*****************************************************************/

// enforce semicolons after each code statement
#pragma semicolon 1

/****************************************************************
I N C L U D E S
*****************************************************************/

#include <sourcemod>
#include <sdktools>


/****************************************************************
P L U G I N   C O N S T A N T S
*****************************************************************/

#define PLUGIN_VERSION 				"1.3.13"
#define HUD_INTERVALL 				0.03

#define MAX_RELATIONSHIP_LENGTH 	64
#define MAX_HEALTH_LENGTH 			32

#define REPORT_DEAD 				"DEAD"
#define RELATIONSHIP_NONE 			"None"
#define RELATIONSHIP_ENEMY 			"Enemy"
#define RELATIONSHIP_FRIEND 		"Friend"
#define RELATIONSHIP_NEUTRAL 		"Neutral"
#define RELATIONSHIP_UNSURE			"Unknown"

/*****************************************************************
P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = 
{
	name = "Show NPC HP",
	author = "Chanz",
	description = "Shows the Health Points of Players and NPCs",
	version = PLUGIN_VERSION,
	url = "www.mannisfunhouse.eu / "
}

/*****************************************************************
G L O B A L   V A R S
*****************************************************************/

new Handle:g_cvar_version 		= INVALID_HANDLE;
new Handle:g_cvar_enable 		= INVALID_HANDLE;
new Handle:g_cvar_hud			= INVALID_HANDLE;

new String:g_sExcludeNPC[][] = {
	
	"npc_grenade_frag"
};

new String:g_sIncludeNPC[][] = {
	
        // left this part in just so i dont have to edit it anywhere else in code (waste of 4 bytes sue me)
	"tank"
};

new String:g_sRemoveFromName[][] = {
	"npc_"
};

/*****************************************************************
F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart(){
	g_cvar_version = CreateConVar("sm_shownpchp_version", PLUGIN_VERSION, "Show NPC Health Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_enable = CreateConVar("sm_shownpchp_enable", "1", "Enable/Disable: Show NPC Health (0=off/1=on)", FCVAR_PLUGIN);
	g_cvar_hud = CreateConVar("sm_shownpchp_hud", "1", "0=HudText, 1=HintText", FCVAR_PLUGIN);
	AutoExecConfig(true, "shownpchp");
	
	CreateTimer(HUD_INTERVALL, Timer_DisplayHud, 0, TIMER_REPEAT);
}

public OnConfigsExecuted(){
	
	SetConVarString(g_cvar_version, PLUGIN_VERSION);	
}

public Action:Timer_DisplayHud(Handle:timer) {
	
	for (new client=1; client<=MaxClients; ++client) {
		
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
			
			new aimTarget = GetClientAimTarget(client, false);
			
			if((aimTarget != -1) && IsValidEntity(aimTarget)) {
				
				ShowHPInfo(client, aimTarget);
			}
		}
	}
	
	return Plugin_Continue;
}

public ShowHPInfo(client, target) {
	
	if (!GetConVarBool(g_cvar_enable)) {
		return;
	}
	
	new String:targetname[MAX_TARGET_LENGTH];
	
	GetEntityName(target,targetname,sizeof(targetname));
	
	if(!IsPlayer(target)){
		
		new size = sizeof(g_sExcludeNPC);
		
		for(new i=0;i<size;i++){
			
			if(StrContains(targetname,g_sExcludeNPC[i],false) == 0){
				
				return;
			}
		}
		
		size = sizeof(g_sIncludeNPC);
		
		new bool:included = false;
		
		for(new i=0;i<size;i++){
			
			new found = StrContains(targetname,g_sIncludeNPC[i],false);
			if(found == 0){
				
				included = true;
				break;
			}
		}
		
		if(!included){
			return;
		}
	}
	
	new String:relationship[MAX_RELATIONSHIP_LENGTH] = RELATIONSHIP_NONE;
	new String:strHealth[MAX_HEALTH_LENGTH];
	new health = GetEntityHealth(target);
	
	if(health < 1){
		strcopy(strHealth,MAX_HEALTH_LENGTH,REPORT_DEAD);
	}
	else {
		Format(strHealth,MAX_HEALTH_LENGTH,"%d HP",health);
	}
	
	GetEntityRelationship(client,target,relationship,sizeof(relationship));
	
	new size = sizeof(g_sRemoveFromName);
	
	for(new i=0;i<size;i++){
		ReplaceString(targetname,sizeof(targetname),g_sRemoveFromName[i],"",false);
	}
	UpperFirstCharInString(targetname);
	
	switch(GetConVarInt(g_cvar_hud)){
		case 1:{
			
			PrintHintText(client,"%s (%s)\nRelationship: %s",targetname,strHealth,relationship);
		}
		case 0:{
			
			SetHudTextParams(0.015, 0.08, HUD_INTERVALL, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
			ShowHudText(client, -1, "%s (%s)\nRelationship: %s",targetname,strHealth,relationship);
		}
		default: return;
	}
}

stock UpperFirstCharInString(String:string[]){
	
	string[0] = CharToUpper(string[0]);
}

stock bool:IsPlayer(client) {
	
	if (client >= 1 && client <= MaxClients) {
		if(IsValidEntity(client)){
			return true;
		}
	}
	
	return false;
}

stock GetEntityHealth(entity){
	
	new health = 0;
	
	if(IsPlayer(entity)){
		health = GetClientHealth(entity);
	}
	else {
		health = GetEntProp(entity, Prop_Data, "m_iHealth", 1);
	}
	
	return health;
}

stock GetEntityRelationship(client,entity,String:relationship[],maxlen){
	
	if(IsPlayer(entity)){
		
		new playerTeam=GetClientTeam(entity);
		new clientTeam=GetClientTeam(client);
		
		if(playerTeam == clientTeam){
			strcopy(relationship,maxlen,RELATIONSHIP_FRIEND);
		}
		else {
			strcopy(relationship,maxlen,RELATIONSHIP_ENEMY);
		}
	}
	else {
		
		strcopy(relationship,maxlen,RELATIONSHIP_UNSURE);
		
		//GetEntPropString(entity, Prop_Data, "m_RelationshipString", relationship, maxlen);
		//PrintToServer("Relship: %s",relationship);
	}
	
	if(StrEqual(relationship,"",false)){
		strcopy(relationship,maxlen,RELATIONSHIP_NONE);
	}
}
	
stock GetEntityName(entity, String:name[], maxlen){
	
	if(IsPlayer(entity)){
		
		GetClientName(entity,name,maxlen);
		
		if(IsFakeClient(entity)){
			Format(name,maxlen,"(BOT) %s",name);
		}
	}
	else {
		
		GetEdictClassname(entity, name, maxlen);
		
		return;
	}
}
	
	
	
	
