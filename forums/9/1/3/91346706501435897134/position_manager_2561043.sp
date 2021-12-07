#include <sourcemod>
#include <sdktools>
#include <tf2>

#pragma newdecls					required
#pragma semicolon					1

#define TFCOND_TELEPORTEDGLOW_TIME	10.0

EngineVersion EV;

char kv_path[PLATFORM_MAX_PATH];

float	client_position[MAXPLAYERS+1][3],
		client_angle[MAXPLAYERS+1][3],
		client_velocity[MAXPLAYERS+1][3],
		current_client_position[MAXPLAYERS+1][3],
		client_position_old[MAXPLAYERS+1][3];

public Plugin myinfo={
	name="[ANY] Position Manager",
	author="91346706501435897134",
	description="A position manager.",
	version="1.4",
	url="http://steamcommunity.com/profiles/76561198356491749"
};

public void OnPluginStart(){
	EV=GetEngineVersion();
	if(GetClientCount(true)>0){ReconnectAllClients();}
	CreateDirectory("addons/sourcemod/data/position_manager",1023);
	BuildPath(Path_SM,kv_path,sizeof(kv_path),"data/position_manager/player_positions.txt");
	RegAdminCmd("sm_posmenu",cmd_posmenu,ADMFLAG_ROOT,"Opens the Position Manager menu.");
	RegAdminCmd("sm_savepos",cmd_savepos,ADMFLAG_ROOT,"Saves current position.");
	RegAdminCmd("sm_loadpos",cmd_loadpos,ADMFLAG_ROOT,"Loads saved position.");
	RegAdminCmd("sm_currentpos",cmd_currentpos,ADMFLAG_ROOT,"Displays current position.");
	RegAdminCmd("sm_savedpos",cmd_savedpos,ADMFLAG_ROOT,"Displays saved position.");
	RegAdminCmd("sm_deletepos",cmd_deletepos,ADMFLAG_ROOT,"Deletes saved position");
	RegAdminCmd("sm_getpos",cmd_getpos,ADMFLAG_ROOT,"Retrieves position of a client.");
	RegAdminCmd("sm_goto",cmd_goto,ADMFLAG_ROOT,"Gets target position and teleports you to it.");
	RegAdminCmd("sm_bring",cmd_bring,ADMFLAG_ROOT,"Teleports a player to you.");
	/*RegAdminCmd("sm_setpos",cmd_setpos,ADMFLAG_ROOT);*/
}

void ReconnectAllClients(){
	PrintToServer("[POSMGR] : Forcing all players to reconnect...");
	for(int i=1;i<=MaxClients;i++){
		if(!IsClientInGame(i)){continue;}
		ReconnectClient(i);
	}
}

public void OnMapStart(){PrecacheSound("weapons/teleporter_send.wav", true);}

void save_player_info(int client,bool connecting)
{
	Handle DB=CreateKeyValues("player_positions");
	FileToKeyValues(DB,kv_path);
	char steam_id[32];
	GetClientAuthId(client,AuthId_Steam3,steam_id,sizeof(steam_id),true);
	if(connecting){
		if(KvJumpToKey(DB,steam_id,true)){
			char player_name[MAX_NAME_LENGTH];
			GetClientName(client,player_name,sizeof(player_name));
			KvSetString(DB,"player_name",player_name);
			client_position[client][0]=KvGetFloat(DB,"xpos",0.0);
			client_position[client][1]=KvGetFloat(DB,"ypos",0.0);
			client_position[client][2]=KvGetFloat(DB,"zpos",0.0);
			KvSetFloat(DB,"xpos",client_position[client][0]);
			KvSetFloat(DB,"ypos",client_position[client][1]);
			KvSetFloat(DB,"zpos",client_position[client][2]);
			client_angle[client][0]=KvGetFloat(DB,"xang",0.0);
			client_angle[client][1]=KvGetFloat(DB,"yang",0.0);
			client_angle[client][2]=KvGetFloat(DB,"zang",0.0);
			KvSetFloat(DB,"xang",client_angle[client][0]);
			KvSetFloat(DB,"yang",client_angle[client][1]);
			KvSetFloat(DB,"zang",client_angle[client][2]);
		}
	}
	else if(!connecting){
		if(KvJumpToKey(DB,steam_id,true)){
			KvSetFloat(DB,"xpos",client_position[client][0]);
			KvSetFloat(DB,"ypos",client_position[client][1]);
			KvSetFloat(DB,"zpos",client_position[client][2]);
			KvSetFloat(DB,"xang",client_angle[client][0]);
			KvSetFloat(DB,"yang",client_angle[client][1]);
			KvSetFloat(DB,"zang",client_angle[client][2]);
		}
	}
	KvRewind(DB);
	KeyValuesToFile(DB, kv_path);
	CloseHandle(DB);
}

public void OnClientPutInServer(int client){save_player_info(client,true);}
public void OnClientDisconnect(int client){save_player_info(client,false);}

public Action cmd_posmenu(int client,int args){
	Handle menu=CreateMenu(posmenu);
	SetMenuTitle(menu,"Position Manager menu (v2.0)");
	AddMenuItem(menu,"option1","Save current position");
	AddMenuItem(menu,"option2","Load saved position");
	AddMenuItem(menu,"option3","Display current position");
	AddMenuItem(menu,"option4","Display saved position");
	AddMenuItem(menu,"option5","Delete saved position");
	SetMenuExitButton(menu,true);
	DisplayMenu(menu,client,30);
	return Plugin_Handled;
}

void RedrawMenu(int client){cmd_posmenu(client,0);}

public int posmenu(Menu menu,MenuAction action,int client,int selection){
	switch(action){
		case MenuAction_Select:{
			char item[64];
			GetMenuItem(menu,selection,item,sizeof(item));

			if(StrEqual(item,"option1",true)){cmd_savepos(client,0);}
			else if(StrEqual(item,"option2",true)){cmd_loadpos(client,0);}
			else if(StrEqual(item,"option3",true)){cmd_currentpos(client,0);}
			else if(StrEqual(item,"option4",true)){cmd_savedpos(client,0);}
			else if(StrEqual(item,"option5",true)){cmd_deletepos(client,0);}
			RedrawMenu(client);
		}
		case MenuAction_End:{CancelMenu(menu);}
	}
}

public Action cmd_savepos(int client,int args){
	if(!client){
		ReplyToCommand(client,">> You must be in game to use this command.");
		return Plugin_Handled;
	}
	else if(!GetClientTeam(client)){
		ReplyToCommand(client,">> You must be in a team to save your current position.");
		return Plugin_Handled;
	}
	else if(IsClientObserver(client)){
		ReplyToCommand(client,">> Cannot save position while in spectator.");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client)){
		ReplyToCommand(client,">> You must be alive to save your position.");
		return Plugin_Handled;
	}
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", client_velocity[client]);
	if(client_velocity[client][0]!=0.0||client_velocity[client][1]!=0.0||client_velocity[client][2]!=0.0){
		ReplyToCommand(client,">> Cannot save position while moving.");
		reset_client_velocity(client);
		return Plugin_Handled;
	}
	else if(GetEntProp(client,Prop_Send,"m_bDucked")){
		ReplyToCommand(client,">> Cannot save your position when ducked.");
		return Plugin_Handled;
	}
	GetClientAbsOrigin(client,client_position[client]);
	if(client_position[client][0]==0.0&&client_position[client][1]==0.0&&client_position[client][2]==0.0){
		ReplyToCommand(client,">> Cannot save to world origin.");
		return Plugin_Handled;
	}
	GetClientEyeAngles(client, client_angle[client]);
	ReplyToCommand(client,">> Saved current position (%f %f %f)",client_position[client][0],client_position[client][1],client_position[client][2]);
	return Plugin_Handled;
}

public Action cmd_loadpos(int client,int args){
	if(!client){
		ReplyToCommand(client,">> You must be in game to use this command.");
		return Plugin_Handled;
	}
	else if(client_position[client][0]==0.0&&client_position[client][1]==0.0&&client_position[client][2]==0.0){
		ReplyToCommand(client,">> No position saved.");
		return Plugin_Handled;
	}
	else if(!GetClientTeam(client)){
		ReplyToCommand(client,">> You must be in a team to load your saved position.");
		return Plugin_Handled;
	}
	else if(IsClientObserver(client)){
		ReplyToCommand(client,">> Cannot load position while in spectator.");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client)){
		ReplyToCommand(client,">> You must be alive to load your position.");
		return Plugin_Handled;
	}
	TeleportEntity(client,client_position[client],client_angle[client],client_velocity[client]);
	ReplyToCommand(client,">> Teleported to %f %f %f",client_position[client][0],client_position[client][1],client_position[client][2]);
	if(EV==Engine_TF2){EmitSoundToClient(client,"weapons/teleporter_send.wav");TF2_AddCondition(client,TFCond_TeleportedGlow,TFCOND_TELEPORTEDGLOW_TIME);}
	return Plugin_Handled;
}

public Action cmd_currentpos(int client,int args){
	if(!client){
		ReplyToCommand(client,">> You must be in game to use this command.");
		return Plugin_Handled;
	}
	GetClientAbsOrigin(client,current_client_position[client]);
	ReplyToCommand(client,">> Current position: %f %f %f",current_client_position[client][0],current_client_position[client][1],current_client_position[client][2]);
	reset_current_client_pos(client);
	return Plugin_Handled;
}

public Action cmd_savedpos(int client,int args){
	if(!client){
		ReplyToCommand(client,">> You must be in game to use this command.");
		return Plugin_Handled;
	}
	else if(client_position[client][0]==0.0&&client_position[client][1]==0.0&&client_position[client][2]==0.0){
		ReplyToCommand(client,">> No saved position found.");
		return Plugin_Handled;
	}
	ReplyToCommand(client,">> Current saved position: %f %f %f",client_position[client][0],client_position[client][1],client_position[client][2]);
	return Plugin_Handled;
}

public Action cmd_deletepos(int client,int args){
	if(!client){
		ReplyToCommand(client,">> You must be in game to use this command.");
		return Plugin_Handled;
	}
	else if(client_position[client][0]==0.0&&client_position[client][1]==0.0&&client_position[client][2]==0.0){
		ReplyToCommand(client,">> No saved position found.");
		return Plugin_Handled;
	}
	client_position_old[client]=client_position[client];
	reset_client_position(client);
	reset_client_angle(client);
	ReplyToCommand(client,">> Saved position deleted (%f %f %f)",client_position_old[client][0],client_position_old[client][1],client_position_old[client][2]);
	reset_client_position_old(client);
	return Plugin_Handled;
}

public Action cmd_getpos(int client,int args){
	char arg1[255];
	if(args<1){
		ReplyToCommand(client,">> Usage: sm_getpos <name|#userid>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS+1];
	int target_count;
	bool tn_is_ml;
	if((target_count=ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_BOTS,target_name,sizeof(target_name),tn_is_ml))<=0){
		ReplyToCommand(client,">> No matching client was found.");
		return Plugin_Handled;
	}
	char name[MAX_NAME_LENGTH][MAXPLAYERS+1];
	float target_position[MAXPLAYERS+1][3];
	ReplyToCommand(client,">>\tName\t\tPosition");
	for(int i=0;i<target_count;i++){
		GetClientName(target_list[i],name[i],sizeof(name));
		GetClientAbsOrigin(target_list[i],target_position[i]);
		ReplyToCommand(client,">>\t%s\t%f %f %f",name[i],target_position[i][0],target_position[i][1],target_position[i][2]);
	}
	return Plugin_Handled;
}

public Action cmd_goto(int client,int args)
{
	char arg1[255];
	if(args<1){
		ReplyToCommand(client, ">> Usage: sm_goto <name|#userid>");
		return Plugin_Handled;
	}
	GetCmdArg(1,arg1,sizeof(arg1));
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	if((target_count=ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_BOTS,target_name,sizeof(target_name),tn_is_ml))<=0){
		ReplyToCommand(client,">> No matching client was found.");
		return Plugin_Handled;
	}
	if(target_count>1){
		ReplyToCommand(client,">> Cannot teleport to multiple targets.");
		return Plugin_Handled;
	}
	char name[MAX_NAME_LENGTH][MAXPLAYERS+1];
	float target_position[MAXPLAYERS+1][3];
	float target_angle[MAXPLAYERS+1][3];
	for(int i=0;i<target_count;i++){
		GetClientName(target_list[i],name[i],sizeof(name));
		GetClientAbsOrigin(target_list[i],target_position[i]);
		target_position[i][2]+=100.0;
		GetClientEyeAngles(target_list[i],target_angle[i]);
		target_angle[i][0]=0.0;
		TeleportEntity(client,target_position[i],target_angle[i],NULL_VECTOR);
		ReplyToCommand(client,">> Teleported to %s.",name[i]);
	}
	return Plugin_Handled;
}

public Action cmd_bring(int client,int args){
	char arg1[255];
	if(args<1){
		ReplyToCommand(client,">> Usage: sm_bring <name|#userid>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	if((target_count=ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_BOTS,target_name,sizeof(target_name),tn_is_ml))<=0){
		ReplyToCommand(client,">> No matching client was found.");
		return Plugin_Handled;
	}
	if(target_count>1){
		ReplyToCommand(client,">> Cannot bring multiple targets.");
		return Plugin_Handled;
	}
	char name[MAX_NAME_LENGTH][MAXPLAYERS+1];
	float bring_position[MAXPLAYERS+1][3];
	float bring_angle[MAXPLAYERS+1][3];
	for(int i=0;i<target_count;i++){
		GetClientName(target_list[i],name[i],sizeof(name));
		GetClientAbsOrigin(client,bring_position[i]);
		bring_position[i][2]+=100.0;
		GetClientEyeAngles(client,bring_angle[i]);
		bring_angle[i][0]=0.0;
		TeleportEntity(target_list[i],bring_position[i],bring_angle[i],NULL_VECTOR);
		ReplyToCommand(client,">> Teleported %s.",name[i]);
	}
	return Plugin_Handled;
}

/*
public Action cmd_setpos(int client, int args)
{
	...



	return Plugin_Handled;
}
*/

public void OnPluginEnd(){if(GetClientCount(true)>0){SavePlayerInfoForEveryone();}}

void SavePlayerInfoForEveryone(){
	PrintToServer("[POSMGR] : Saving player information...");
	PrintToChatAll("[POSMGR] : Saving player information...");
	for(int i=1;i<=MaxClients;i++){
		if(!IsClientInGame(i)){continue;}
		save_player_info(i, false);
	}
	PrintToServer("[POSMGR] : Player information saved!");
	PrintToChatAll("[POSMGR] : Player information saved!");
}

void reset_client_position(int client){
	client_position[client][0]=0.0;
	client_position[client][1]=0.0;
	client_position[client][2]=0.0;
}

void reset_current_client_pos(int client){
	current_client_position[client][0]=0.0;
	current_client_position[client][1]=0.0;
	current_client_position[client][2]=0.0;
}

void reset_client_angle(int client){
	client_angle[client][0]=0.0;
	client_angle[client][1]=0.0;
	client_angle[client][2]=0.0;
}

void reset_client_velocity(int client){
	client_velocity[client][0]=0.0;
	client_velocity[client][1]=0.0;
	client_velocity[client][2]=0.0;
}

void reset_client_position_old(int client){
	client_position_old[client][0]=0.0;
	client_position_old[client][1]=0.0;
	client_position_old[client][2]=0.0;
}