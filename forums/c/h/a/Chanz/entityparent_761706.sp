/********************************************
* 
* entity parent/ attach version "1.1.5"
* 
* This plugin let you pair/parent/attach a entity with yourself.
* 
* Commands:
* - sm_parent [target] [x] [y] [z] - look at the entity you like to attach or omit the target to deattach only the entity you look at. By using the xyz coordinates you can specify the position of the entity relative to yourself, means you are pos 0x 0y 0z and if you use sm_parent @me 100 0 0 then the entity gets teleported infront of you and then attached to you.
* - sm_clearparent <target> - deattach all entitys from you
* 
* Todo:
* - Menu to deattach a single entity form you.
* - A more accurate function for the xyz coordinates when using sm_parent.
* 
* Known Bugs:
* - The Positions when using sm_parent with xyz coordinates isn't always accurate.
* - NPCs and Players won't stay in position if you move too fast or jump/duck.
* - All entitys kinda lag if you move.
* - Entitys won't move up if you look up. (but NPCs and Players do )
* - Collision between entitys is disabled as long they are attached to the player (well not really a bug, but looks stupid sometimes).
* 
* Changelog:
* v1.1.5
* + sm_parent [target] [x] [y] [z] - the entity first gets teleportet at the coordinates xyz (your position is 0x 0y 0z) and then attached to you.
* performance fix
* ep_version changed to entityparent_version
* Physik entitys won't return anymore after sm_clearparent to the place where they got attached (they just stay in midair until you move it a littlebit).
* v1.0.0
* release
* 
* Thank you...
* Berni
* Manni
* SWAT_88 and the guys who helped him withSM Parachute
* 
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

#define PLUGIN_VERSION "1.1.5"
#define MAXENTITYS 2000

/*****************************************************************


P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = 
{
	name = "EntityParent",
	author = "Chanz",
	description = "Attatch something to yourself",
	version = PLUGIN_VERSION,
	url = "www.mannisfunhouse.eu"
}

/*****************************************************************


G L O B A L   V A R S


*****************************************************************/

new parent[MAXENTITYS] = { 0, ...};
new Handle:entityparent_version = INVALID_HANDLE;

/*****************************************************************


F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart(){
	entityparent_version = CreateConVar("entityparent_version", PLUGIN_VERSION, "EntityParent Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(entityparent_version, PLUGIN_VERSION);
	
	RegAdminCmd("sm_parent", Command_Parent, ADMFLAG_ROOT, "[target] [x] [y] [z] - attach something to yourself (only enter 'sm_parent' to see more infomation");
	RegAdminCmd("sm_clearparent", Command_ClearParent, ADMFLAG_ROOT, "<target> - deattach all entitys from you");
}

public OnPluginEnd(){
	
	for(new entity=0;entity<=MAXENTITYS;entity++){
		
		if(IsValidEntity(entity)){
			
			if(parent[entity] != 0){
				
				RemoveParent(entity);
			}
		}
	}
}

public OnClientDisconnect(client){
	
	for(new entity=0;entity<=MAXENTITYS;entity++){
		
		if(IsValidEntity(entity)){
			
			if(parent[entity] == client){
				
				RemoveParent(entity);
			}
		}
	}
}

/****************************************************************


C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_Parent(client, args) {
	
	new entity = GetClientAimTarget(client, false);
	
	if(!IsValidEntity(entity)){
		ReplyToCommand(client, "[SM] Not a valid entity.");
		return Plugin_Handled;
	}
	
	if(args < 1) {
		RemoveParent(entity);
		ReplyToCommand(client, "[SM] You unset the parent for the entity you looked at.");
		return Plugin_Handled;
	}
	
	
	decl String:target[MAX_TARGET_LENGTH];
	decl String:arg2[MAX_TARGET_LENGTH];
	decl String:arg3[MAX_TARGET_LENGTH];
	decl String:arg4[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	
	new x = StringToInt(arg2);
	new y = StringToInt(arg3);
	new z = StringToInt(arg4);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
	target,
	client,
	target_list,
	sizeof(target_list),
	COMMAND_FILTER_ALIVE,
	target_name,
	sizeof(target_name),
	tn_is_ml
	);
	
	if (target_count <= 0) {
		
		ReplyToCommand(client, "[SM] Error noone found");
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		
		if((parent[entity] != 0) && (parent[entity] != target_list[i])){
			ReplyToCommand(client, "[SM] You can't parent this to %N its already parent at %N else.",target_list[i], parent[entity]);
		}
		else {
			SetParent(target_list[i], entity, x, y, z);
		}
	}
	PrintToChat(client, "[SM] You set the parent for the entity you looked at to player %s", target);
	
	return Plugin_Handled;
}


public Action:Command_ClearParent(client, args){
	
	
	new String:command[64];
	GetCmdArg(0, command, sizeof(command));
	
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: %s <target> - it removes all parent items from the target", command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
	target,
	client,
	target_list,
	sizeof(target_list),
	COMMAND_FILTER_ALIVE,
	target_name,
	sizeof(target_name),
	tn_is_ml
	);
	
	if (target_count <= 0) {
		
		ReplyToCommand(client, "[SM] Error noone found");
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		
		for(new entity=0;entity<MAXENTITYS;entity++){
			
			if(parent[entity] == target_list[i]){
				
				RemoveParent(entity);
			}
		}
	}
	PrintToChat(client, "[SM] You cleared all parents for player %s", target);
	return Plugin_Handled;
}

/*****************************************************************


P L U G I N   F U N C T I O N S


*****************************************************************/

RemoveParent(entity){
	
	if(IsValidEntity(entity)){
		
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
		
		SetVariantString("");
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);
		
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		
		parent[entity] = 0;
	}
}

bool:SetParent(client, entity, ix=0, iy=0, iz=0){
	
	if(IsValidEntity(entity) && IsClientInGame(client) && IsPlayerAlive(client)){
		
		RemoveParent(entity);
		
		if(ix != 0 || iy != 0 || iz != 0){
			new Float:origin[3];
			new Float:angles[3];
			
			GetClientEyeAngles(client, angles);
			GetClientAbsOrigin(client, origin);
			
			new Float:alpha = DegToRad(angles[1]);
			new Float:cosAlpha = Cosine(alpha);
			new Float:sinAlpha = Sine(alpha);
			new Float:x;
			new Float:y;
			
 			x = ((ix * cosAlpha) + (iy * sinAlpha));
			y = ((iy * cosAlpha) - (ix * sinAlpha));
			
			//PrintToChatAll("x: %f - y: %f - z: %i - alpha: %f - Cosine(alpha): %f - Sine(alpha): %f", x,y,iz,alpha,cosAlpha,sinAlpha);
			//PrintToChatAll("angles: %fx - %fy - %fz",angles[0],angles[1],angles[2]);
			
			origin[0] += x;
			origin[1] += y;
			origin[2] += iz;
			
			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		}
		
		new String:steamid[20];
		GetClientAuthString(client, steamid, sizeof(steamid));
		DispatchKeyValue(client, "targetname", steamid);
		SetVariantString(steamid);
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);
		//SetVariantString("primary");
		//AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset", -1, -1, 0);
		parent[entity] = client;
		return true;
	}
	return false;
}









