#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#pragma semicolon 1

#define PORTAL_MDL "models/props_gameplay/door_slide_door.mdl"
#define PORTAL_SND_ENTER "portal/enter.wav"
#define PORTAL_SND_FIRE "portal/fire.wav"

new orange;
new blue;
new orangeLight;
new blueLight;
new Float:blueLoc[3];
new Float:orangeLoc[3];
new bool:hasPortalGun[MAXPLAYERS+1];
new bool:cooldown[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Portal Gun",
	author = "",
	description = "Portal in TF2",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_portal", Command_Portal, ADMFLAG_ROOT);
	PrecacheStuff();
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i))
			continue;
		hasPortalGun[i] = false;
		cooldown[i] = false;
	}
}

public OnPluginEnd()
{
	RemovePortal(blue);
	RemovePortal(orange);
}

public OnMapStart()
{
	PrecacheStuff();
}

public OnClientPutInServer(client)
{
	hasPortalGun[client] = false;
	cooldown[client] = false;
}

public Action:Command_Portal(client, args)
{
	hasPortalGun[client] = !hasPortalGun[client];
	switch(hasPortalGun[client])
	{
		case true: ReplyToCommand(client, "Portal Gun enabled");
		case false:
		{
			ReplyToCommand(client, "Portal Gun disabled");
		}
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!hasPortalGun[client])
		return Plugin_Continue;
	if((buttons & IN_ATTACK || buttons & IN_ATTACK2 || buttons & IN_RELOAD) && !cooldown[client])
	{
		decl Float:loc[3];
		GetAimOrigin(client, loc);
		decl Float:ang[3];
		GetClientAbsAngles(client, ang);
		ang[1] += 90.0;
		loc[2] += 64.0;
		
		if(buttons & IN_ATTACK) //BLUE
		{
			CreatePortal(client, 1, loc, ang);
			buttons &= ~IN_ATTACK;
		}
		else if(buttons & IN_ATTACK2) //ORANGE
		{
			CreatePortal(client, 2, loc, ang);
			buttons &= ~IN_ATTACK2;
		}
		else if(buttons & IN_RELOAD) //CLEAR
		{
			RemovePortal(blue);
			RemovePortal(orange);
			buttons &= ~IN_RELOAD;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnTouch(ent, client)
{
	if(ent == blue || ent == orange)
	{
		if(ent == blue)
		{
			SetEntProp(orange, Prop_Send, "m_nSolidType", 0);
			CreateTimer(1.4, Timer_Collision, orange);
			TeleportEntity(client, orangeLoc, NULL_VECTOR, NULL_VECTOR);
		}
		else if(ent == orange)
		{
			SetEntProp(blue, Prop_Send, "m_nSolidType", 0);
			CreateTimer(1.4, Timer_Collision, blue);
			TeleportEntity(client, blueLoc, NULL_VECTOR, NULL_VECTOR);
		}
		new random = GetRandomInt(70, 130);
		EmitSoundToClient(client, PORTAL_SND_ENTER, _, _, _, _, _, random);
	}
}

public Action:Timer_Cooldown(Handle:timer, any:client)
{
	cooldown[client] = false;
}

public Action:Timer_Collision(Handle:timer, any:entity)
{
	SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
}

CreatePortal(client, id, Float:loc[3], Float:ang[3])
{
	new ent = CreateEntityByName("prop_physics_override");
	SetEntityModel(ent, PORTAL_MDL);
	DispatchSpawn(ent);
	TeleportEntity(ent, loc, ang, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "Enable");
	SDKHook(ent, SDKHook_StartTouch, OnTouch);
	
	new light = CreateEntityByName("light_dynamic");
	DispatchKeyValue(light, "inner_cone", "0");
	DispatchKeyValue(light, "cone", "80");
	DispatchKeyValue(light, "brightness", "3");
	DispatchKeyValueFloat(light, "spotlight_radius", 512.0);
	DispatchKeyValueFloat(light, "distance", 512.0);
	DispatchKeyValue(light, "pitch", "-90");
	DispatchKeyValue(light, "style", "5");
	DispatchKeyValue(light, "_light", "100 100 255 100");
	
	switch(id)
	{
		case 1: //BLUE
		{
			RemovePortal(blue);
			blue = ent;
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", blueLoc);
			blueLoc[2] -= 64.0;
			SetEntityRenderColor(ent, 100, 100, 255, 255);
			DispatchKeyValue(light, "_light", "100 100 255 300");
			blueLight = light;
			CPrintToChat(client, "{blue}Placed a blue portal");
		}
		case 2: //ORANGE
		{
			RemovePortal(orange);
			orange = ent;
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", orangeLoc);
			orangeLoc[2] -= 64.0;
			SetEntityRenderColor(ent, 255, 140, 60, 255);
			DispatchKeyValue(light, "_light", "255 140 60 300");
			orangeLight = light;
			CPrintToChat(client, "{blue}Placed a orange portal");
		}
	}
	
	DispatchSpawn(light);
	TeleportEntity(light, loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(light, "TurnOn");

	cooldown[client] = true;
	CreateTimer(0.6, Timer_Cooldown, client);
	EmitSoundToAll(PORTAL_SND_FIRE);
}

RemovePortal(color)
{
	if(IsValidEdict(color) && color != 0) RemoveEdict(color);
	
	if(color == blue && blueLight != 0 && IsValidEdict(blueLight)) RemoveEdict(blueLight);
	else if(color == orange && orangeLight != 0 && IsValidEdict(orangeLight)) RemoveEdict(orangeLight);
}

PrecacheStuff()
{
	PrecacheModel(PORTAL_MDL);
	PrecacheSound(PORTAL_SND_ENTER);
	PrecacheSound(PORTAL_SND_FIRE);
}

GetAimOrigin(client, Float:hOrigin[3]) 
{
    new Float:vAngles[3], Float:fOrigin[3];
    GetClientEyePosition(client,fOrigin);
    GetClientEyeAngles(client, vAngles);

    new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

    if(TR_DidHit(trace)) 
    {
        TR_GetEndPosition(hOrigin, trace);
        CloseHandle(trace);
        return 1;
    }

    CloseHandle(trace);
    return 0;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
    return entity > GetMaxClients();
}  