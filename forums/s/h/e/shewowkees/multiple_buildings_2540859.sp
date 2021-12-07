#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clients>
#include <sdkhooks>

int OwnerOffset;
ConVar sm_dispenser_limit;
ConVar sm_sentry_limit;
ConVar sm_instant_upgrade;

public Plugin myinfo ={
	name = "Multiple buildings",
	author = "shewowkees",
	description = "self explanatory",
	version = "1.1",
	url = "noSiteYet"
};

public void OnPluginStart(){

	sm_dispenser_limit = CreateConVar("sm_dispenser_limit", "1", "Self explanatory");
	sm_sentry_limit = CreateConVar("sm_sentry_limit", "1", "Self explanatory");
	sm_instant_upgrade = CreateConVar("sm_instant_upgrade","0","Self explanatory");

	HookEvent("player_builtobject",Evt_BuiltObject,EventHookMode_Pre);

	RegConsoleCmd("sm_destroy_dispensers", Command_destroy_dispensers);
	RegConsoleCmd("sm_destroy_sentries", Command_destroy_sentries);

	OwnerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");

	for(int client=1;client<MaxClients;client++){
		if(!IsValidEntity(client)){
			continue;
		}
		if(!IsClientConnected(client)){
			continue;
		}

		SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
		SDKHookEx(client, SDKHook_WeaponSwitch, WeaponSwitch);
	}
}



public void OnClientPostAdminCheck(client){
    SDKHookEx(client, SDKHook_WeaponSwitch, WeaponSwitch);
}
public Action Evt_BuiltObject(Event event, const char[] name, bool dontBroadcast){
	int ObjIndex = event .GetInt("index");

	if(GetConVarInt(sm_instant_upgrade)>0){

		SetEntProp(ObjIndex, Prop_Send, "m_iUpgradeMetal", 600);
		SetEntProp(ObjIndex,Prop_Send,"m_iUpgradeMetalRequired",0);

	}



	return Plugin_Continue;
}


public Action WeaponSwitch(client, weapon){
	//Safety Checks
	if(!IsClientInGame(client)){
		return Plugin_Continue;
	}
	if(TF2_GetPlayerClass(client)!=TFClass_Engineer){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,1))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,3))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,4))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(weapon)){
		return Plugin_Continue;
	}

	//if the building pda is opened
	//Switches some buildings to sappers so the game doesn't count them as engie buildings
	if(GetPlayerWeaponSlot(client,3)==weapon){
		function_AllowBuilding(client);
		return Plugin_Continue;
	}//else if the client is not holding the building tool
	else if(GetEntProp(weapon,Prop_Send,"m_iItemDefinitionIndex")!=28){
		function_AllowDestroying(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;

}






public Action Command_destroy_dispensers(int client, int args){

	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if ( !strcmp(netclass, "CObjectDispenser") == 0){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}
		SetVariantInt(9999);
		AcceptEntityInput(i,"RemoveHealth");
	}

	return Plugin_Handled;


}

public Action Command_destroy_sentries(int client, int args){

	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if ( !(strcmp(netclass, "CObjectSentrygun") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}
		SetVariantInt(9999);
		AcceptEntityInput(i,"RemoveHealth");
	}

	return Plugin_Handled;

}

public void function_AllowBuilding(int client){

	int DispenserLimit = GetConVarInt(sm_dispenser_limit);
	int SentryLimit = GetConVarInt(sm_sentry_limit);

	int DispenserCount = 0;
	int SentryCount = 0;

	for(int i=0;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}


		int type=view_as<int>(function_GetBuildingType(i));

		//Switching the dispenser to a sapper type
		if(type==view_as<int>(TFObject_Dispenser)){
			DispenserCount=DispenserCount+1;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(DispenserCount>=DispenserLimit){
				//if the limit is reached, disallow building
				SetEntProp(i, Prop_Send, "m_iObjectType", type);

			}

		//not a dispenser,
		}else if(type==view_as<int>(TFObject_Sentry)){
			SentryCount++;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(SentryCount>=SentryLimit){
				//if the limit is reached, disallow building
				SetEntProp(i, Prop_Send, "m_iObjectType", type);
			}
		}
	//every building is in the desired state


	}
}
public void function_AllowDestroying(int client){
	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}

		SetEntProp(i, Prop_Send, "m_iObjectType", function_GetBuildingType(i));
	}

}

public TFObjectType function_GetBuildingType(int entIndex){
	//This function relies on Netclass rather than building type since building type
	//gets changed
	decl String:netclass[32];
	GetEntityNetClass(entIndex, netclass, sizeof(netclass));

	if(strcmp(netclass, "CObjectSentrygun") == 0){
		return TFObject_Sentry;
	}
	if(strcmp(netclass, "CObjectDispenser") == 0){
		return TFObject_Dispenser;
	}

	return TFObject_Sapper;


}
