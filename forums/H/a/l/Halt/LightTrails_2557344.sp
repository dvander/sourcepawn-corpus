#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Light Trails",
	author = "bSun Halt",
	description = "Gives a light trail",
	version = "Light Trails 1.0",
	url = "http://sourcemod.net"
}

static SpriteTrail[33];

public void OnPluginStart()
{
	RegAdminCmd("sm_trail", Command_Trail, ADMFLAG_GENERIC, "sm_trail <color>");
}

public void OnClientPutInServer(int Client)
{
	SpriteTrail[Client] = -1;
}


public Action Command_Trail(int Client, int Args)
{
	if (Args < 1 || Args > 1)
	{
		PrintToChat(Client, "[SM] sm_trail <color>");
		return Plugin_Handled;
	}
	
	char TrailColor[32];
	char ClientName[128];
	Format(ClientName, sizeof(ClientName), "customname_%i", Client);
	DispatchKeyValue(Client, "targetname", ClientName);
	int Trail = CreateEntityByName("env_spritetrail");
	DispatchKeyValue(Trail, "renderamt", "255");
	DispatchKeyValue(Trail, "rendermode", "1");
	DispatchKeyValue(Trail, "spritename", "materials/sprites/spotlight.vmt");
	DispatchKeyValue(Trail, "lifetime", "3.0");
	DispatchKeyValue(Trail, "startwidth", "8.0");
	DispatchKeyValue(Trail, "endwidth", "0.1");
	
	GetCmdArg(1, TrailColor, sizeof(TrailColor))
	
	if (SpriteTrail[Client] != -1)
		AcceptEntityInput(SpriteTrail[Client], "Kill");
	
	if (StrEqual(TrailColor, "red", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "255, 0, 0");
	}
	else if(StrEqual(TrailColor, "blue", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "0, 0, 255");
	}
	else if(StrEqual(TrailColor, "yellow", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "255 255 0");
	}
	else if(StrEqual(TrailColor, "green", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "0 255 0");
	}
	else if(StrEqual(TrailColor, "purple", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "255 0 255");
	}
	else if(StrEqual(TrailColor, "orange", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "255 153 0");
	}
	else if(StrEqual(TrailColor, "cyan", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "0 255 255");
	}
	else if(StrEqual(TrailColor, "pink", false))
	{
		DispatchKeyValue(Trail, "rendercolor", "255 0 102");
	}
	else if(StrEqual(TrailColor, "off", false))
	{
		if (SpriteTrail[Client] != -1)
		{
			AcceptEntityInput(Trail, "Kill");
			SpriteTrail[Client] = -1;
		}
		
		return Plugin_Handled;
	}
	
	DispatchSpawn(Trail);
	SpriteTrail[Client] = Trail;
	
	float CurrentOrigin[3];
	GetClientAbsOrigin(Client, CurrentOrigin);
	CurrentOrigin[2] += 10.0;
	TeleportEntity(Trail, CurrentOrigin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(ClientName);
	
	AcceptEntityInput(Trail, "SetParent", -1, -1);
	AcceptEntityInput(Trail, "showsprite", -1, -1);
	
	PrintToChat(Client, "[SM] You've been given a %s trail!", TrailColor);
	
	return Plugin_Handled;
}