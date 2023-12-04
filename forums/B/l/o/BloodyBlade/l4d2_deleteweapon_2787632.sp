#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
 
public Plugin myinfo =
{
	name = "[L4D2] Weapon Remove",
	author = "Rain_orel",
	description = "Removes weapon spawn",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

int ent_table[64][2];
int new_ent_counter = 0;
ConVar hCount;

public void OnPluginStart()
{
	HookEvent("spawner_give_item", Event_SpawnerGiveItem);
	hCount = CreateConVar("l4d2_usecount", "1", "How many times a weapon spawn can be used before it will be removed.");
}

public void OnMapStart()
{
	for(int i = 0; i < 63; i++)
	{
		ent_table[i][0] = -1;
		ent_table[i][1] = -1;
	}
	new_ent_counter = 0;
}

public void OnMapEnd(){}

public void Event_SpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
{
    //char item_name[32]
    //event.GetString("item", item_name, 32);  No need yet
    int entity_id = event.GetInt("spawner");

    if(GetUseCount(entity_id) == -1)
	{
		ent_table[new_ent_counter][0] = entity_id;
		ent_table[new_ent_counter][1] = 0;
		new_ent_counter++;
	}

    SetUseCount(entity_id);

    if(GetUseCount(entity_id) == hCount.IntValue)
	{
		RemoveEdict(entity_id);
	}
}

int GetUseCount(int entid)
{
	for(int i = 0; i < 63; i++)
	{
		if(ent_table[i][0] == entid)
		{
			return ent_table[i][1];
		}
	}
	return -1;
}

void SetUseCount(int entid)
{
	for(int j = 0; j < 63; j++)
	{
		if(ent_table[j][0] == entid)
		{
			ent_table[j][1]++;
		}
	}
}
