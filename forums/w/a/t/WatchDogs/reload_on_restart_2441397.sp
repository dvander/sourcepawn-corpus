#include <sourcemod>
new bool:do_once = false;

public Plugin:myinfo = 
{
	name = "Reload Map After Restart",
	author = "[W]atch [D]ogs",
	description = "Reloads map at every server retarts & crashes for SourceTv connection.",
	version = "0.4"
};

public OnConfigsExecuted()
{
	if(!do_once) 
	{
		new String:map[128]; 
		GetCurrentMap(map, sizeof(map));
		ForceChangeLevel(map, "Reloadmap on Restart");
		do_once = true;
	}
}