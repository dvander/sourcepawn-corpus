#include <sourcemod>

#define PLUGIN_VERSION "1.1.0"

new lcClient;
new Float:distance[MAXPLAYERS+1] = 0.0;

new Handle:g_hTargetSelf = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Distance Targeting",
	author = "SoulSharD",
	description = "Adds distance specific target filters.",
	version = PLUGIN_VERSION,
	url = "tf2lottery.com"
};

public OnPluginStart()
{
	CreateConVar("sm_distancetarget_version", PLUGIN_VERSION, "Distance Target Filters: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hTargetSelf = CreateConVar("sm_distancetarget_self", "0", "Determine whether or not distance targeting includes yourself. 1=Enable | 0=Disable");
	
	RegAdminCmd("sm_setdistance", Command_SetDistance, ADMFLAG_GENERIC);
	AddMultiTargetFilter("@distance", FilterDistance, "all within specific distance", false);
	AddMultiTargetFilter("@!distance", FilterDistance, "all outwith specific distance", false); // It's scottish...
}

public OnPluginEnd()
{
	RemoveMultiTargetFilter("@distance", FilterDistance);
	RemoveMultiTargetFilter("@!distance", FilterDistance);
}

public Action:OnClientCommand(client, args)
{
	lcClient = client;
}

public OnClientDisconnect(client)
{
	distance[client] = 0.0;
}

public Action:Command_SetDistance(client, args)
{
	decl String:arg1[5];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	distance[client] = FloatAbs(StringToFloat(arg1));
	
	ReplyToCommand(client, "[SM] Set distance filter to: %f", distance[client]);
	return Plugin_Handled;
}

public bool:FilterDistance(const String:strPattern[], Handle:hClients)
{
	new client = lcClient;
	
	new Float:vecOrigin1[3];
	new Float:vecOrigin2[3];
	
	new bool:opposite;
	if(strPattern[1] == '!') opposite = true; 
	
	GetClientAbsOrigin(client, vecOrigin1);	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(i == client && GetConVarInt(g_hTargetSelf) == 1)
				continue;
				
			GetClientAbsOrigin(i, vecOrigin2);
			if((GetVectorDistance(vecOrigin1, vecOrigin2) <= distance[client]) == !opposite) 
                PushArrayCell(hClients, i);			
		}
	}
	return true;
}