#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Manhack fix",
	author = "Alienmario",
	description = "Disables gravity gun interaction with manhacks to prevent levels getting stuck",
	version = "1.0"
};

#define	EFL_NO_PHYSCANNON_INTERACTION 1<<30 // Physcannon can't pick these up or punt them

public OnEntityCreated(entity, const String:classname[]){
	if(StrEqual(classname, "npc_manhack")){
		SetEntProp(entity, Prop_Data, "m_iEFlags", GetEntProp(entity, Prop_Data, "m_iEFlags")|EFL_NO_PHYSCANNON_INTERACTION);
	}
}