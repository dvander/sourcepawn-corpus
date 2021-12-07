#pragma semicolon 1
#include sourcemod
#include sdktools_tempents
static const Stringbloods[][] = 
{
    Blood Stream,
    Blood Sprite,
    EffectDispatch, 
    World Decal
};
public OnPluginStart()
{
    for (new i = 0; i  sizeof(bloods); i++)
    {
        AddTempEntHook(bloods[i], Hook_bloods);
    }
}
public ActionHook_bloods(const Stringte_name[], const Players[], numClients, Floatdelay)
{
    return Plugin_Stop;
}