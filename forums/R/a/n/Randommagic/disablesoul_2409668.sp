#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "disablesoul",
	author = "TAKE 2",
	description = "할로윈소울 없애기/Disabling Halloween souls",
	version = "1.0",
	url = "http://steamcommunity.com/id/ssssssssaaaaaaazzzzzxxc/"
}

public OnEntityCreated(entity, const String:classname[])
{
if(IsValidEntity(entity) && StrEqual(classname,"halloween_souls_pack"))
{
SDKHook(entity, SDKHook_Spawn, soul);
}
}

public soul(entity)
 AcceptEntityInput(entity,"Kill");
