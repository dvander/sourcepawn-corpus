#include <sourcemod>
#include <sdktools>
#include <tf2>

new Handle:g_Enabled = INVALID_HANDLE;

public OnPluginStart()
{
	g_Enabled  = CreateConVar("invincibledispencers_enabled", "1", "Enable/Disable Invincible Dispencers");
	HookEvent("player_builtobject", Object_Built);
}

public Action:Object_Built(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_Enabled))
	{
		if(GetEventInt(event, "object") == _:TFObject_Dispenser)
		{
			SetEntProp(GetEventInt(event, "index"), Prop_Data, "m_takedamage", 0);
		}
	}
	return Plugin_Handled;
}