
#include <sdkhooks>

public OnPluginStart()
{
	for( new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
	SDKHook(client, SDKHook_StartTouchPost, StartTouchPost);
}

new bool:noblock[MAXPLAYERS+1];

public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	//PrintToServer("ShouldCollide(entity %i, collisiongroup %i, contentsmask %i, bool:originalResult %s", entity, collisiongroup, contentsmask, originalResult ? "true":"false");
	if(collisiongroup == 8 && noblock[entity])
	{
		return false;
	}
	return originalResult;
}

public StartTouchPost(entity, other)
{
	//PrintToServer("Action:TouchPost(entity %i, other %i)", entity, other);
	if(other > 0 && other <= MaxClients)
	{
		if(GetClientTeam(entity) == GetClientTeam(other))
		{
			noblock[entity] = true;
		}
		else
		{
			noblock[entity] = false;
		}
	}
}
