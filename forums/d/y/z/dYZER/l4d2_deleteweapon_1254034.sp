#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.01"
public Plugin:myinfo =
{
	name = "[L4D2] Weapon Remove",
	author = "Rain_orel",
	description = "Removes weapon spawn",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new ent_table[64][2];
new new_ent_counter = 0;
new Handle:hCount;

public OnPluginStart()
{
	CreateConVar("l4d2_deleteweapon_version", PLUGIN_VERSION, "[L4D2] Weapon Remover defines how many times a weapon spawns", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("spawner_give_item", Event_SpawnerGiveItem);
	hCount = CreateConVar("l4d2_usecount", "1", "How many times a weapon spawn can be used before it will be removed.", FCVAR_PLUGIN);
//dyzer-adds
	AutoExecConfig(true, "l4d2_deleteweapon");

}

public OnMapStart()
{
	for(new i=0;i<63;i++)
	{
	ent_table[i][0]=-1;
	ent_table[i][1]=-1;
	}
	new_ent_counter = 0
}

public OnMapEnd(){}

public Event_SpawnerGiveItem(Handle:event, const String:name[], bool:dontBroadcast)
{
   //decl String:item_name[32]
   //GetEventString(event, "item", item_name, 32);  No need yet
   new entity_id = GetEventInt(event, "spawner")
   
   
   if(GetUseCount(entity_id)==-1)
   {
   ent_table[new_ent_counter][0]=entity_id;
   ent_table[new_ent_counter][1]=0;
   new_ent_counter++;
   }
   
   SetUseCount(entity_id);
   
   if(GetUseCount(entity_id)==GetConVarInt(hCount))RemoveEdict(entity_id);
}

GetUseCount(entid)
{
	for(new i=0;i<63;i++)
	{
	if(ent_table[i][0]==entid)return ent_table[i][1]
	}
	return -1
}

SetUseCount(entid)
{
	for(new j=0;j<63;j++)
	{
	if(ent_table[j][0]==entid)ent_table[j][1]++;
	}
}
	
	