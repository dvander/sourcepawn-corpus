#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

new buildingModeOffsets[4];

public Plugin:myinfo = 
{
	name = "Another Engie Building Exploit Fix",
	author = "Fox",
	description = "TF2 - If engineer tries to build more than 1 of the same object then it is destroyed",
	version = "1.01",
	url = "www.rtdgaming.com"
}

public OnPluginStart()
{
	HookEvent("player_builtobject", Event_Player_BuiltObject);
	
	buildingModeOffsets[0] = FindSendPropOffs("CObjectDispenser","m_iObjectMode");
	buildingModeOffsets[1] = FindSendPropOffs("CObjectTeleporter","m_iObjectMode");
	buildingModeOffsets[2] = FindSendPropOffs("CObjectSentrygun","m_iObjectMode");
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;
	
	new object = GetEventInt(event, "object");
	new index = GetEventInt(event, "index");
	
	if(object > 2)
		return;
	
	new mode = GetEntData(index,buildingModeOffsets[object]);
	new ent = -1;
	
	decl String:classname[32];
	GetEdictClassname(index, classname, sizeof(classname));
	
	if(StrEqual(classname, "obj_attachment_sapper"))
		return;
	
	//class other than engies is building something
	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		AcceptEntityInput(index, "kill");
		PunishClient(client);
		return;
	}
	
	if( object == 0 && mode > 0 ||object == 1 && mode > 1 || object == 2 && mode > 0 || mode < 0 || mode > 2)
	{
		AcceptEntityInput(index, "kill");
		PunishClient(client);
	}
	
	
	//now lets make sure there is only 1 object with the same mode
	while ((ent = FindEntityByClassname(ent, classname)) != -1)
	{
		if(client == GetEntPropEnt(ent, Prop_Send, "m_hBuilder") && ent != index )
		{
			if((object == 1 && mode == GetEntData(ent,buildingModeOffsets[object])) || object != 1)
			{
				AcceptEntityInput(index, "kill");
				PunishClient(client);
				return;
			}
		}
	}
}

public PunishClient(client)
{
	new String:ConUsrSteamID[128];
	new String:userName[128];
	
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	GetClientName(client, userName, sizeof(userName));
	
	//do other stuff here, like alerts
	LogAction(client, -1, "%s (%s) attempted building exploit.", userName,ConUsrSteamID);
	PrintToChatAll("%s (%s) attempted building exploit.", userName,ConUsrSteamID);
}

