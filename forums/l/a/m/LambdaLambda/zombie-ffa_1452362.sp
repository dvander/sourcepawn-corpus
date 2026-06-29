#include <sourcemod>

public Plugin:myinfo = 
{
    name = "-",
    author = "-",
    description = "-",
    version = "-",
    url = "-"
}

public OnPluginStart()
{
    MapCycle();
}

public OnMapStart()
{    
    MapCycle();
}

public MapCycle()
{

    new String:x[4];     
    FormatTime(x,sizeof(x),"%H",GetTime());
    new time;
    time = StringToInt(x);
    
    if ( time >= 0 || time < 8 )
    {
        ServerCommand("zombie_mode 1");
    }
    else if ( time >= 8 || time < 0 )
    {
        ServerCommand("zombie_mode 0");
    }
    
}