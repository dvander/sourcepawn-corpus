#include <sourcemod>
#include <sdktools>

new Handle:g_hCvarMethod;
new g_iMethod = 1;

public Plugin:myinfo = 
{
	name = "Block +left and +right",
	author = "Afronanny",
	description = "Block people from using +left and +right",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=132310"
}

public OnPluginStart()
{
	g_hCvarMethod = CreateConVar("sm_leftright_method", "1", "1 for block, 2 for kick");
	HookConVarChange(g_hCvarMethod, ConVarChanged_Method);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_iMethod == 1)
	{
		buttons &= ~IN_LEFT;
		buttons &= ~IN_RIGHT;
	} else {
		if (buttons & IN_LEFT || buttons & IN_RIGHT)
			KickClient(client, "You cannot use +left or +right");
	}
}

public ConVarChanged_Method(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Value = StringToInt(newValue);
	
	switch (Value)
	{
		case 1: g_iMethod = 1;
		case 2: g_iMethod = 2;
		default:g_iMethod = 1;
	}
}
