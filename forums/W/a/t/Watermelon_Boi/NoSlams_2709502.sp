// Made to make maps less noobie & more enjoyable
#include <sdktools_entinput.inc>

public OnEntityCreated(int ent, char[] classname)
{
    if (IsValidEntity(ent) && StrEqual(classname, "weapon_slam"))
    {
        AcceptEntityInput(ent, "Kill");
    }

    return Plugin_Continue;
}