#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.2"

public Plugin:myinfo = 
{
  name = "TF Tools",
  author = "Nican132",
  description = "Make cool advanced tools for TF2",
  version = PL_VERSION,
  url = "http://sourcemod.net/"
};       

new maxents, maxplayers;
new SentryModel[4];
new SentryShells[4] = {0, 100, 120, 144};
new Handle:hGameConf, Handle:OffsetSentryModel;
new ResourceEnt;

new TF_TRoffsets[8];
#define TURRET_LEVEL 0
#define TURRET_STATE 1
#define TURRET_SHELLS 2
#define TURRET_ROCKETS 3
#define TURRET_BULDING 4
#define TURRET_HEALTH 5
#define TURRET_OWNED 6
#define TURRET_MODEL 7

new TF_Resourceoffsets[3];
#define RESOURCES_CLASS 0
#define RESOURCES_MAXHEALTH 1
#define RESOURCES_TLSCORE 2

public OnPluginStart(){
	CreateConVar("sm_tf_tools", PL_VERSION, "TF2 tools", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new i;
	
	TF_TRoffsets[TURRET_LEVEL] = FindSendPropOffs("CObjectSentrygun", "m_iUpgradeLevel");
	TF_TRoffsets[TURRET_STATE] = FindSendPropOffs("CObjectSentrygun", "m_iState");
	TF_TRoffsets[TURRET_SHELLS] = FindSendPropOffs("CObjectSentrygun", "m_iAmmoShells");
	TF_TRoffsets[TURRET_ROCKETS] = FindSendPropOffs("CObjectSentrygun", "m_iAmmoRockets");
	TF_TRoffsets[TURRET_BULDING] = FindSendPropOffs("CObjectSentrygun", "m_bBuilding");
	TF_TRoffsets[TURRET_HEALTH] = FindSendPropOffs("CObjectSentrygun", "m_iMaxHealth");
	TF_TRoffsets[TURRET_OWNED] = FindSendPropOffs("CObjectSentrygun", "m_hBuilder");
	TF_TRoffsets[TURRET_MODEL] = FindSendPropOffs("CObjectSentrygun", "m_nModelIndex");
	
	TF_Resourceoffsets[RESOURCES_CLASS] = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");	
	TF_Resourceoffsets[RESOURCES_MAXHEALTH] = FindSendPropOffs("CTFPlayerResource", "m_iHealth");	
	TF_Resourceoffsets[RESOURCES_TLSCORE] = FindSendPropOffs("CTFPlayerResource", "m_iTotalScore");	
	
	for(i = TURRET_LEVEL; i<= TURRET_MODEL; i++){
		if(TF_TRoffsets[i] == -1)
			SetFailState("A turret offset could not be found! Check for updates"); 
	}
	
	hGameConf = LoadGameConfigFile("nican.offsets");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	OffsetSentryModel = EndPrepSDKCall();	
}

public OnMapStart(){
	SentryModel[0] = 0;
	
	maxplayers = GetMaxClients();
	maxents = GetMaxEntities();
	ResourceEnt = FindResourceObject();
	
	if(ResourceEnt == 0)
		LogMessage("Attetion! Server could not find player data table");
}

stock FindResourceObject(){
	new i, String:classname[64];
	
	//Isen't there a easier way?
	for(i = maxplayers; i <= maxents; i++){
	 	if(IsValidEntity(i)){
			GetEntityNetClass(i, classname, 64);
			if(StrEqual(classname, "CTFPlayerResource")){
					return i;
			}
		}
	}
	return 0;
}


public bool:AskPluginLoad(Handle:myself, bool:late, String:Error[])
{
  // General
  CreateNative("TF_TurretLevel", SetTurretLevel);
  CreateNative("TF_EyeTurret", GetPlayerEyes);
  
  CreateNative("TF_GetClass", GetClientClass);
  CreateNative("TF_GetMaxHealth", GetClientMaxHealth);
  CreateNative("TF_TotalScore", GetClientTotalScore);
  
  CreateNative("TF_GetResource", GetResource);

  return true;
}

public SetTurretLevel(Handle:plugin,argc){
	if(argc==2){
		new index, level;
		index = GetNativeCell(1);
		
		//Oh uh... Find sentry if player index is giving
		if(index <= maxplayers){
		 	//LogMessage("B");
			if(!IsClientInGame(index))
				return 5;
				
			index = FindSentryByOwner(index);
			if(index == 0)
				return 4;
		}else{
		 	//LogMessage("D");
		 	new String:classname[64];
			GetEntityNetClass(index, classname, 64);
			if(!StrEqual(classname, "CObjectSentrygun"))
				//Idiot, that is not a turret
				return 3;
		}
		//LogMessage("E");
		
		//The sentry is builiding, can't change level :/
		if(GetEntData(index, TF_TRoffsets[TURRET_BULDING], 1)  == 1)
 			return 2;
 			
 		//LogMessage("F");
 			
 		level = GetNativeCell(2);
 		
 		if( level < 1 || level > 3)
 			return 6;
 			
 		//LogMessage("G");	
 			
 		if(SentryModel[0] == 0){	
			DiscoverModel(GetEntData(index, TF_TRoffsets[TURRET_LEVEL], 4), GetEntData(index, TF_TRoffsets[TURRET_MODEL], 2), GetEntData(index, TF_TRoffsets[TURRET_STATE], 4));
		}
		
		SetEntData(index, TF_TRoffsets[TURRET_LEVEL], level, 4); //level
		if(OffsetSentryModel == INVALID_HANDLE)
			SetEntData(index,TF_TRoffsets[TURRET_MODEL], SentryModel[level], 4);
		else
			SDKCall(OffsetSentryModel, index, SentryModel[level]); //model, Use SDK or the render will bug :/
		SetEntData(index,TF_TRoffsets[TURRET_SHELLS], SentryShells[level], 4); //shells 100-120-144
		SetEntData(index,TF_TRoffsets[TURRET_ROCKETS], level == 3 ? 20 : 0, 4); //rockets
		SetEntData(index,TF_TRoffsets[TURRET_HEALTH], level == 3 ? 180 : 150, 4); //health 150-150-180
	 
		return 0;	
	}
	return 1;
}

//I found a patterent between the model index
//I hope it does not change :O
stock DiscoverModel(levela, ida, statea){
	if(levela == 0 || ida == 0)
		return;
 
	if(statea == 0 && levela == 1){
		SentryModel[0] = ida;
	} else if(statea == 1){
		if(levela == 1){
			SentryModel[0] = ida + 5;
		} else if(levela == 2){
				SentryModel[0] = ida - 1;
		} else if(levela == 3){
				SentryModel[0] = ida - 7;
		}
	}
	
	if(SentryModel[0] != 0){
		SentryModel[1] = SentryModel[0] - 5;
		SentryModel[2] = SentryModel[0] + 1;
		SentryModel[3] = SentryModel[0] + 7;
	}
}

stock FindSentryByOwner(index){
	new i, String:classname[64];
	
	//Isen't there a easier way?
	for(i = maxplayers; i <= maxents; i++){
	 	if(IsValidEntity(i)){
			GetEntityNetClass(i, classname, 64);
			if(StrEqual(classname, "CObjectSentrygun")){
				if(GetEntData(i, TF_TRoffsets[TURRET_OWNED], 1) == index)
					return i;
			}
		}
	}
	return 0;
}


public GetPlayerEyes(Handle:plugin,argc){
 	if(argc==1){
		new client;
		client= GetNativeCell(1);
		
		if(!IsClientInGame(client))
			return false;
			
		new Float:vAngles[3], Float:vOrigin[3];
		GetClientEyePosition(client,vOrigin);
		GetClientEyeAngles(client, vAngles);
		
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterSentry);
		
		if(TR_DidHit(trace)){
			return TR_GetEntityIndex(trace);
		}
 	}
	return 0;
}

public bool:TraceEntityFilterSentry(entity, contentsMask){
 	new String:classname[64];
 	GetEntityNetClass(entity, classname, 64);
 	return StrEqual(classname, "CObjectSentrygun");
}

	/*
	OMG! same as TFC
	1= scout
	2=sniper
	3=soldier
	4=demoman
	5=medic
	6=HW
	7=pyro
	8=spy
	9=Eng	
	*/

stock GetPlayerClass(client){
	return GetEntData(ResourceEnt, TF_Resourceoffsets[RESOURCES_CLASS] + (client*4), 4);
}

public GetClientClass(Handle:plugin,argc){
	if(argc == 1){
	 	new client = GetNativeCell(1);
	 	if(IsClientConnected(client))
			return GetPlayerClass(client);	
	}
	return -1; 
}

stock GetPlayerMaxHealth(client){
	return GetEntData(ResourceEnt, TF_Resourceoffsets[RESOURCES_MAXHEALTH] + (client*4), 4);
}

public GetClientMaxHealth(Handle:plugin,argc){
	if(argc == 1){
	 	new client = GetNativeCell(1);
	 	if(IsClientConnected(client))
			return GetPlayerMaxHealth(client);	
	}
	return -1; 
}

stock GetPlayerTotalScore(client){
	return GetEntData(ResourceEnt, TF_Resourceoffsets[RESOURCES_TLSCORE] + (client*4), 4);
}

public GetClientTotalScore(Handle:plugin,argc){
	if(argc == 1){
	 	new client = GetNativeCell(1);
	 	if(IsClientConnected(client))
			return GetPlayerTotalScore(client);	
	}
	return -1; 
}

public GetResource(Handle:plugin,argc){
	if(argc == 0){
	 	return ResourceEnt;
	}
	return -1; 
}