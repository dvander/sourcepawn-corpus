#include <tf2_stocks>
#include <tf2items>

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, entity)
{
	switch (index)
	{
		case 735, 736, 810, 831, 933:
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(entity));
	}
}

public Action:Timer_RemoveEntity(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if (entity <= MaxClients) return;
	AcceptEntityInput(entity, "Kill");
}