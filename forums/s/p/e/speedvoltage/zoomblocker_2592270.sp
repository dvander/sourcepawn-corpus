#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Zoom Blocker",
	author = "Peter Brev",
	description = "Blocks +zoom and toggle_zoom",
	version = "1.0",
	url = "https://peterbrev.info/"
};

public void OnPluginStart()
{
    AddCommandListener(ZoomCallback, "toggle_zoom");
}
 
public Action ZoomCallback(int client, const char[] command, int argc)
{
    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
    if ((buttons & IN_ZOOM) == IN_ZOOM)
    {
        buttons &= ~IN_ZOOM;
    }
    return Plugin_Continue;
}