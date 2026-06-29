#include <cstrike>
#include <sdktools>

public void OnMapStart()
{
    if (FindEntityByClassname(-1, "func_hostage_rescue") == -1)
    {
        CreateEntityByName("func_hostage_rescue");
    }
}