#include <tf2>
#include <tf2_stocks>

#define VERSION "1.0"

public Plugin myinfo =
{
	name = "[TF2] Bumper Car Fix",
	author = "Bloomstorm",
	description = "Fixed the double-fire shot glith when a player leaving the bumper car",
	version = VERSION,
	url = "https://bloomstorm.su/"
};

public void OnPluginStart()
{
    CreateConVar("sm_bumpercar_fix_version", VERSION, "Plugin version", FCVAR_NOTIFY);
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
    if (cond == TFCond_HalloweenKart)
    {
        SetEntProp(client, Prop_Data, "m_bPredictWeapons", true);
    }
}
