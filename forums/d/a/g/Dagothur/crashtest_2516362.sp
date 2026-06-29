#include <sdktools>

public OnPluginStart()
{
	for (new i = 0;i<3000;i++)
	{
		new ent=CreateEntityByName("trigger_push");
		DispatchSpawn(ent);
	}
}