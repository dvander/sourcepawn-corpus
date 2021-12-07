#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name		= "DropWep",
	author		= "Potato Uno (compiled/edited by Cheddar)",
	description	= "Drops a Weapon at your feet",
	version		= "1",
	url			= "https://forums.alliedmods.net/showthread.php?p=2316384"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_dropwep", DropWeapon, "Spawns a dropped weapon at your feet. Usage: sm_drop [item index]");
}

public OnMapStart()
{
    PrecacheModel("models/weapons/c_models/c_directhit/c_directhit.mdl", true);
    // Need to add more precaches here
}

public Action DropWeapon(iClient, nArgs)
{
    char index[10];
    GetCmdArg(1, index, 10);
    int Entity = CreateEntityByName("tf_dropped_weapon");
    SetEntProp(Entity, Prop_Send, "m_iItemDefinitionIndex", StringToInt(index));
//    SetEntProp(Entity, Prop_Send, "m_nModelIndex", 662);         Don't think this is needed.
    SetEntProp(Entity, Prop_Send, "m_iEntityLevel", 5);
    SetEntProp(Entity, Prop_Send, "m_iEntityQuality", 6);
    SetEntProp(Entity, Prop_Send, "m_bInitialized", 1);
    float coordinates[3];
    GetClientAbsOrigin(iClient, coordinates);
    GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", coordinates);
    TeleportEntity(Entity, coordinates, NULL_VECTOR, NULL_VECTOR);
    SetEntityModel(Entity, "models/weapons/c_models/c_directhit/c_directhit.mdl");
    DispatchSpawn(Entity);
}  