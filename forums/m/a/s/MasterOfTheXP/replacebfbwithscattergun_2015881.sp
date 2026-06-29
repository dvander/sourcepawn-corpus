#include <tf2items>
#include <tf2items_giveweapon>

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, ent)
{
	switch (index)
	{
		case 772: // Baby Face's Blaster
			TF2Items_GiveWeapon(client, 13);
	}
}