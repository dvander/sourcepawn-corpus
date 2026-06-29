#include <sdktools>
new Float:g_fLocations[MAXPLAYERS+1][3];
new bool:g_bSaved[MAXPLAYERS+1];

public OnPluginStart()
{
	RegAdminCmd("sm_teleportme", teleport, ADMFLAG_RESERVATION, "Text here");
}

public Action:teleport(client, args)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if(args == 0)
	{
		if(g_bSaved[client])
		{
			TeleportEntity(client, g_fLocations[client], NULL_VECTOR, NULL_VECTOR);
			ShowActivity2(client, "[SM]", "Teleported last saved location: %0.2f %0.2f %0.2f", g_fLocations[client][0], g_fLocations[client][1], g_fLocations[client][2]);
			LogAction(client, -1, "%L Teleported last saved location: %0.2f %0.2f %0.2f", client, g_fLocations[client][0], g_fLocations[client][1], g_fLocations[client][2]);
		}
		else
		{
			ReplyToCommand(client, "Save your location first: sm_teleportme save");
		}
	}
	else if(args == 1)
	{
		new String:arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		if(StrEqual(arg, "save", false))
		{
			GetClientAbsOrigin(client, g_fLocations[client]);
			g_bSaved[client] = true;
			ReplyToCommand(client, "Location saved %0.2f %0.2f %0.2f", g_fLocations[client][0], g_fLocations[client][1], g_fLocations[client][2]);
		}
		return Plugin_Handled;
	}
	else if(args == 3)
	{
		new String:arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		g_fLocations[client][0] = StringToFloat(arg);
		GetCmdArg(2, arg, sizeof(arg));
		g_fLocations[client][1] = StringToFloat(arg);
		GetCmdArg(3, arg, sizeof(arg));
		g_fLocations[client][2] = StringToFloat(arg);
		TeleportEntity(client, g_fLocations[client], NULL_VECTOR, NULL_VECTOR);
		ShowActivity2(client, "[SM]", "Teleported location: %0.2f %0.2f %0.2f", g_fLocations[client][0], g_fLocations[client][1], g_fLocations[client][2]);
		LogAction(client, -1, "%L Teleported location: %0.2f %0.2f %0.2f", client, g_fLocations[client][0], g_fLocations[client][1], g_fLocations[client][2]);
	}
	return Plugin_Handled;
}

public OnClientConnected(client)
{
	g_bSaved[client] = false;
}