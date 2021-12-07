#include <sourcemod>
#include <sdktools>
#include <tf2>

public Plugin:myinfo = 
{
	name = "Teleporter health exploit fix",
	author = "linux_lover",
	description = "Teleporter max health isn't reset when a tele is rebuilt and the link is destroyed.",
	version = "0.1",
	url = "https://www.youtube.com/watch?v=Uk9ZpbBiXdE"
};

public OnPluginStart()
{
	HookEvent("object_removed", Event_BuiltObject);
}

public Event_BuiltObject(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && TFObjectType:GetEventInt(hEvent, "objecttype") == TFObject_Teleporter)
	{
		// Find all teleporters that belong to the same owner as the tele just destroyed and set their maxhealth to 150 (this should normally happen whenever a teleporter is destroyed)
		new iTele = MaxClients+1;
		while((iTele = FindEntityByClassname(iTele, "obj_teleporter")) > MaxClients)
		{
			if(GetEntPropEnt(iTele, Prop_Send, "m_hBuilder") == client)
			{
				//PrintToServer("m_iUpgradeLevel = %d m_iMaxHealth = %d m_bMatchBuilding = %d", GetEntProp(iTele, Prop_Send, "m_iUpgradeLevel"), GetEntProp(iTele, Prop_Send, "m_iMaxHealth"), GetEntProp(iTele, Prop_Send, "m_bMatchBuilding"));
				if(GetEntProp(iTele, Prop_Send, "m_iHealth") > 150) SetEntProp(iTele, Prop_Send, "m_iHealth", 150);
				SetEntProp(iTele, Prop_Send, "m_iMaxHealth", 150);
				SetEntProp(iTele, Prop_Send, "m_iUpgradeLevel", 1);
			}
		}
	}
}