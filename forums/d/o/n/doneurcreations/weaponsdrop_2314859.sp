#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Block weapons drop on death",
	description = "Block weapons drop on death, after the new Gun Mettle Update.",
	author = "DoneurCreations"
};

public OnEntityCreated(entity, const String:classname[])
{
    if(StrEqual(classname, "tf_dropped_weapon"))
    {
        AcceptEntityInput(entity, "Kill");
    }
}