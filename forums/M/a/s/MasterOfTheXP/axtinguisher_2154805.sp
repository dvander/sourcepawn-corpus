#include <tf2items>
#include <tf2attributes>

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, entity)
{
	switch (index)
	{
		case 38, 457, 1000: // Axtinguisher item indexes
		{
			TF2Attrib_SetByName(entity, "axtinguisher properties", 0.0); // Remove its new mechanic
			TF2Attrib_SetByName(entity, "crit vs burning players", 1.0); // Add this one back in
		}
	}
}