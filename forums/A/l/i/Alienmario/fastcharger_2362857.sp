#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "fastcharger",
	author = "Alienmario",
	description = "faster suit chargers",
	version = "1.0"
};

new Handle:pack=INVALID_HANDLE;
new Handle:pack_brush=INVALID_HANDLE;

new Handle:sm_suitcharger_speed=INVALID_HANDLE;
new Handle:sm_suitcharger_speed_brush=INVALID_HANDLE;
new Float:speed;
new Float:speed_brush;

public OnPluginStart(){
	pack=CreateArray(1);
	pack_brush=CreateArray(1);
	sm_suitcharger_speed = CreateConVar("sm_suitcharger_speed","5.0","sets suitchargers speed",FCVAR_PLUGIN, true, 0.0, true, 12.0);
	sm_suitcharger_speed_brush = CreateConVar("sm_suitcharger_speed_brush","5.0","sets suitchargers speed",FCVAR_PLUGIN, true, 0.0, true, 12.0);
	HookConVarChange(sm_suitcharger_speed, changeSpeed);
	HookConVarChange(sm_suitcharger_speed_brush, changeSpeed_brush);
}

public OnConfigsExecuted(){
	speed=GetConVarFloat(sm_suitcharger_speed);
	speed_brush=GetConVarFloat(sm_suitcharger_speed_brush);
}

public changeSpeed(Handle:cvar, const String:oldVal[], const String:newVal[]){
	speed=StringToFloat(newVal);
}

public changeSpeed_brush(Handle:cvar, const String:oldVal[], const String:newVal[]){
	speed_brush=StringToFloat(newVal);
}

public OnEntityCreated(entity, const String:classname[]){
	if(StrEqual(classname, "item_suitcharger") || StrEqual(classname, "item_healthcharger")){
		PushArrayCell(pack, EntIndexToEntRef(entity));
	}else if(StrEqual(classname, "func_recharge")){
		PushArrayCell(pack_brush, EntIndexToEntRef(entity));
	}
}

public OnEntityDestroyed(entity){
	if(IsValidEdict(entity)){
		new val=FindValueInArray(pack, EntIndexToEntRef(entity));
		if(val!=-1) RemoveFromArray(pack, val);
		else{
			val=FindValueInArray(pack_brush, EntIndexToEntRef(entity));
			if(val!=-1) RemoveFromArray(pack_brush, val);
		}
	}
}

public OnMapEnd(){
	ClearArray(pack);
	ClearArray(pack_brush);
}

public OnGameFrame()
{
	new size=GetArraySize(pack);
	for (new i=0;i<size;i++){
		ChangeSpeed(GetArrayCell(pack,i), speed);
	}
	size=GetArraySize(pack_brush);
	for (new i=0;i<size;i++){
		ChangeSpeed(GetArrayCell(pack_brush,i), speed_brush);
	}
}

ChangeSpeed(ent, Float:s)
{
		new Float:m_flNextPrimaryAttack = GetEntPropFloat(ent, Prop_Data, "m_flNextCharge");

		new Float:GameTime = GetGameTime();
		
		new Float:PeTime = (m_flNextPrimaryAttack - GameTime) - ((s - 1.0) / 50);

		SetEntPropFloat(ent, Prop_Data, "m_flNextCharge", PeTime+GameTime);
}