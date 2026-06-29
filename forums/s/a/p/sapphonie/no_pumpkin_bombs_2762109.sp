#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tf_pumpkin_bomb"))
    {
        RemoveEntity(entity);
    }
}
