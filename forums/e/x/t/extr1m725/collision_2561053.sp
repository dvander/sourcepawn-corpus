#include <collisionhook>
#include <zombiereloaded>
new bool:enable;

public OnPluginStart()
{
	new Handle:hRegister = CreateConVar("zr_collision_enable", "0");
	enable = GetConVarBool(hRegister);
	HookConVarChange(hRegister, OnEnableChange);
	CloseHandle(hRegister);
}

public Action:CH_PassFilter( ent1, ent2, &bool:result ) 
{ 
    // No client-client collisions 
    if (enable && 1 <= ent1 <= MaxClients && 1 <= ent2 <= MaxClients && IsClientInGame(ent2) && IsPlayerAlive(ent2) && ZR_IsClientHuman(ent1) == ZR_IsClientHuman(ent2)) 
    { 
        result = false; 
        return Plugin_Handled; 
    } 
     
    return Plugin_Continue; 
} 

public OnEnableChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	enable = GetConVarBool(hCvar)
}