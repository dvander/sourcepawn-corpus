#pragma semicolon 1
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"
public Plugin myinfo = {
	name = "C4 Model Changer",
	author = "Mitch",
	description = "Changes the default c4 model to what ever model you desire.",
	version = PLUGIN_VERSION,
	url = "mtch.tech"
};

ConVar cModel;
ConVar cSize;

public OnPluginStart() {
	CreateConVar("sm_c4model_version", PLUGIN_VERSION, "C4Model Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cModel = CreateConVar("c4_model", "models/weapons/w_c4_planted.mdl", "Model for C4 bomb.");
	cSize = CreateConVar("c4_size", "1.0", "Size of the C4 Model.", 0, true, 0.1, true, 10.0);
	AutoExecConfig();
	HookEvent("bomb_planted", BomPlanted_Event);
	cModel.AddChangeHook(ConvarChange_Model);
}

public ConvarChange_Model(ConVar cvar, const char[] oldVal, const char[] newVal) {
	if(!StrEqual(newVal, "")) {
		PrecacheModel(newVal, false);
	}
}

public OnConfigsExecuted() {
	char sModel[512];
	GetConVarString(cModel, sModel, sizeof(sModel));
	if(!StrEqual(sModel, "") && !StrEqual(sModel, "models/weapons/w_c4_planted.mdl")) {
		PrecacheModel(sModel, true);
	}
}

public Action BomPlanted_Event(Event event, const char[] name, bool dontBroadcast) {
	char sModel[512];
	bool changeModel = (!StrEqual(sModel, "") && !StrEqual(sModel, "models/weapons/w_c4_planted.mdl"));
	float fSize = cSize.FloatValue;
	int c4 = -1;
	while((c4 = FindEntityByClassname(c4, "planted_c4")) != -1) {
		if(changeModel) {
			SetEntityModel(c4, sModel);
		}
		if(fSize != 1.0) {
			SetEntPropFloat(c4, Prop_Send, "m_flModelScale", fSize);
		}
	}
	return Plugin_Continue;
}