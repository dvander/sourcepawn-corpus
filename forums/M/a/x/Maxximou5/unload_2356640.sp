public void OnMapStart()
{
    char curmap[64];
    GetCurrentMap(curmap, sizeof(curmap));
    if(StrEqual(curmap, "surf_lt_omnific_fix"))
    {
        ServerCommand("sm plugins unload store-skins");
        ServerCommand("sm plugins unload store-trails");
    }
}

public void OnMapEnd()
{
    char nextmap[64];
    GetNextMap(nextmap, sizeof(nextmap));
    if(StrEqual(nextmap,"surf_lt_omnific_fix"))
    {
        ServerCommand("sm plugins unload store-skins");
        ServerCommand("sm plugins unload store-trails");
    }
}