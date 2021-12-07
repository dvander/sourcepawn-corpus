#include <sourcemod>

#define PLUGIN_VERSION "2"

public Plugin:myinfo =
{
    name = "nmrih_emptyrotate",
    author = "SilverPeak",
    description = "keep rotating through maps at a preset time interval until a player joined",
    version = PLUGIN_VERSION,
    url = "wasted24.com"
};

 
public void OnPluginStart()
{
ConVar rotatetime;
rotatetime = CreateConVar("emptyrotate_time", "500.0", "map change interval", _, true, 20.0, false);
float set_time;
set_time = rotatetime.FloatValue;
CreateTimer(set_time, rotate, _, TIMER_REPEAT);
}

public Action rotate(Handle timer)
{
if (GetClientCount() == 0){
char nextmap[PLATFORM_MAX_PATH]; 
GetNextMap(nextmap, sizeof(nextmap));
//ForceChangeLevel(nextmap, ""); /** https://forums.alliedmods.net/showthread.php?t=282821 */
ServerCommand("changelevel %s", nextmap);
}
return Plugin_Continue;
}