#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new bool:is_tesla[2048];

public Plugin:myinfo = 
{
	name = "Blue Tentalce Lasers?",
	author = "",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_tesla", Command_Tesla, ADMFLAG_ROOT);
	RegAdminCmd("sm_removetesla", Command_RemoveTesla, ADMFLAG_ROOT);
}

public Action:Command_Tesla(client, args)
{
	new laserent = CreateEntityByName("point_tesla");
	new String:sz_lasername[32];
	Format(sz_lasername, sizeof(sz_lasername), "laser_%i", laserent);
	DispatchKeyValue(laserent, "targetname", sz_lasername);
	new String:steamid[20];
	
	GetClientAuthString(client, steamid, sizeof(steamid));
	DispatchKeyValue(client, "targetname", steamid);
	DispatchKeyValue(laserent, "parentname", steamid);
	DispatchKeyValue(laserent, "m_flRadius", "96.0");
	DispatchKeyValue(laserent, "m_SoundName", "DoSpark");
	DispatchKeyValue(laserent, "beamcount_min", "4");
	DispatchKeyValue(laserent, "beamcount_max", "6");
	DispatchKeyValue(laserent, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(laserent, "m_Color", "255 255 255");
	DispatchKeyValue(laserent, "thick_min", "1.0");
	DispatchKeyValue(laserent, "thick_max", "10.0");
	DispatchKeyValue(laserent, "lifetime_min", "0.3");
	DispatchKeyValue(laserent, "lifetime_max", "0.3");
	DispatchKeyValue(laserent, "interval_min", "0.1");
	DispatchKeyValue(laserent, "interval_max", "0.2");
	DispatchSpawn(laserent);
	SetEntityRenderColor(laserent,200,0,0,255);
	
	AcceptEntityInput(laserent, "TurnOn");  
	AcceptEntityInput(laserent, "DoSpark");  
	new Float:loc[3];
	GetClientAbsOrigin(client,loc);
	loc[2] += 48.0;
	ActivateEntity(laserent);
	AcceptEntityInput(laserent, "TurnOn");  
	TeleportEntity(laserent,loc,NULL_VECTOR,NULL_VECTOR);
	decl String:Buffer[64];
	Format(Buffer, sizeof(Buffer), "Client%d", client);
	DispatchKeyValue(client, "targetname", Buffer);
	SetVariantString(Buffer);
	AcceptEntityInput(laserent, "SetParent");
	ReplyToCommand(client, "Created a tesla");
	is_tesla[laserent] = true;
	return Plugin_Handled;
}

public Action:Command_RemoveTesla(client, args)
{
	for(new i=GetMaxClients();i<2048;i++)
	{
		if(is_tesla[i])
			RemoveEdict(i);
	}
	return Plugin_Handled;
}