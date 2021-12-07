#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.4"

public Plugin:myinfo =
{
	name = "C4 Model Changer",
	author = "Mitch",
	description = "Changes the default c4 model to what ever model you desire.",
	version = PLUGIN_VERSION,
	url = "http://snbx.info/"
};

enum C4Characteristics
{
	String:Model[512],
	Float:Size
};
new C4Prop[C4Characteristics];

new Handle:C4Model = INVALID_HANDLE;
new Handle:C4Size = INVALID_HANDLE;
new Handle:updaterCvar = INVALID_HANDLE;

public OnPluginStart()
{
	updaterCvar = CreateConVar("sm_c4model_auto_update", "1", "Enables automatic updating (has no effect if Updater is not installed)");
	C4Model = CreateConVar("c4_model", "models/weapons/w_c4_planted.mdl", "Model for C4 bomb.");
	C4Size = CreateConVar("c4_size", "1.0", "Size of the C4 Model.", 0, true, 0.1, true, 10.0);
	AutoExecConfig();
	HookEvent("bomb_planted", BomPlanted_Event);
	HookConVarChange(C4Model, ConvarChange_c4);
	HookConVarChange(C4Size, ConvarChange_c4);
}
public ConvarChange_c4(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	GetConVarString(C4Model, C4Prop[Model], 512);
	if(!StrEqual(C4Prop[Model], "")) PrecacheModel(C4Prop[Model], false);
	C4Prop[Size] = GetConVarFloat(C4Size);
}

public OnAllPluginsLoaded() {
	CreateConVar("sm_c4model_version", PLUGIN_VERSION, "C4Model Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);	
}
public OnConfigsExecuted()
{
	GetConVarString(C4Model, C4Prop[Model], 512);
	if(!StrEqual(C4Prop[Model], "")) PrecacheModel(C4Prop[Model], true);
	C4Prop[Size] = GetConVarFloat(C4Size);
}

public Action:BomPlanted_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new c4 = -1;
	while((c4 = FindEntityByClassname(c4, "planted_c4"))!=-1)
	{
		if((!StrEqual(C4Prop[Model], "")) || (!StrEqual(C4Prop[Model], "models/weapons/w_c4_planted.mdl")))
			SetEntityModel(c4, C4Prop[Model]);
		if(C4Prop[Size] != 1.0)
			SetEntPropFloat(c4, Prop_Send, "m_flModelScale", C4Prop[Size]);
	}
	return Plugin_Continue;
}