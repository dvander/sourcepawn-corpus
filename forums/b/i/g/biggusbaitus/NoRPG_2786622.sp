#include <sdktools_entinput.inc>

public OnEntityCreated(int ent, char[] classname)
{
    if (IsValidEntity(ent) && StrEqual(classname, "weapon_rpg"))
    {
        AcceptEntityInput(ent, "Kill");
    }

    return Plugin_Continue;
}