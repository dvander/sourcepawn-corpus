#include <sourcemod>
#include <sdktools>
#include <tf2>

public OnPluginStart()
{
     HookEvent("player_builtobject", Object_Built);
}

public Action:Object_Built(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(FindConVar("hale_enabled")))
	{
		if(GetEventInt(event, "object") == _:TFObject_Dispenser)
		{
			SetEntProp(GetEventInt(event, "index"), Prop_Data, "m_takedamage", 0);
		}
	}
	return Plugin_Handled;
}