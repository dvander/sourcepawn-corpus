#include <tf2items>

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], itemDefinitionIndex, &Handle:hItem)
{
	if(itemDefinitionIndex == 583)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}