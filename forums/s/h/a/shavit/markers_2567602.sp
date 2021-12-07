#include <sourcemod>
#include <sdktools>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

enum
{
	bMarkerDrawing,
	bMarkerDisplay,
	iMarkerColor,
	MARKERSETTINGS_SIZE
}

int gI_Colors[] =
{
	16777215,
	16757690,
	16768954,
	16777146,
	12255177,
	12247551
};

char gS_Colors[][] =
{
	"White",
	"Pink",
	"Orange",
	"Yellow",
	"Lime",
	"Light Blue"
};

Menu gH_MarkerMenu = null;
any gA_MarkerSettings[MAXPLAYERS+1][MARKERSETTINGS_SIZE];
float gF_MarkerPoints[MAXPLAYERS+1][2][3]; // 1/2, x/y/z

int gI_BeamSprite = -1;
int gI_HaloSprite = -1;

public Plugin myinfo =
{
	name = "Jailbreak Markers",
	author = "shavit",
	description = "Marker setup for Jailbreak servers.",
	version = PLUGIN_VERSION,
	url = "https://github.com/shavitush"
}

public void OnPluginStart()
{
	CreateConVar("markers_version", PLUGIN_VERSION, "Plugin version.", (FCVAR_NOTIFY | FCVAR_DONTRECORD));

	RegConsoleCmd("sm_marker", Command_MarkerMenu, "Open the marker menu.");
	RegConsoleCmd("+marker", Command_Marker, "Start marking.");
	RegConsoleCmd("-marker", Command_Marker, "Stop marking.");

	HookEvent("player_spawn", Player_Spawn);

	gH_MarkerMenu = new Menu(MenuHandler_Marker, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
	gH_MarkerMenu.SetTitle("Marker menu: \n ");
	gH_MarkerMenu.AddItem("marker", "");
	gH_MarkerMenu.AddItem("display", "");
	gH_MarkerMenu.AddItem("color", "");
	gH_MarkerMenu.ExitButton = true;

	CreateTimer(0.1, Timer_DrawAll, 0, TIMER_REPEAT);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClientTiny(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart()
{
	if(GetEngineVersion() == Engine_CSGO)
	{
		gI_BeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
		gI_HaloSprite = PrecacheModel("sprites/glow01.vmt", true);
	}

	else
	{
		gI_BeamSprite = PrecacheModel("sprites/laser.vmt", true);
		gI_HaloSprite = PrecacheModel("sprites/halo01.vmt", true);
	}
}

public void OnClientPutInServer(int client)
{	
	gA_MarkerSettings[client][bMarkerDrawing] = false;
	gA_MarkerSettings[client][bMarkerDisplay] = true;
	gA_MarkerSettings[client][iMarkerColor] = 0;
	gF_MarkerPoints[client][0] = NULL_VECTOR;
	gF_MarkerPoints[client][1] = NULL_VECTOR;
}

public void Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	OnClientPutInServer(GetClientOfUserId(event.GetInt("userid")));
}

public Action Command_Marker(int client, int args)
{
	if(!CanUseMarker(client))
	{
		return Plugin_Handled;
	}

	char[] command = new char[16];
	GetCmdArg(0, command, 16);

	ToggleDrawing(client, command[0] == '+');

	return Plugin_Handled;
}

public Action Command_MarkerMenu(int client, int args)
{
	if(!CanUseMarker(client))
	{
		return Plugin_Handled;
	}

	gH_MarkerMenu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int MenuHandler_Marker(Menu menu, MenuAction action, int param1, int param2)
{
	if(!CanUseMarker(param1))
	{
		return 0;
	}

	char[] sInfo = new char[16];

	if(action == MenuAction_Select)
	{
		menu.GetItem(param2, sInfo, 16);

		if(StrEqual(sInfo, "marker"))
		{
			ToggleDrawing(param1, !gA_MarkerSettings[param1][bMarkerDrawing]);
		}

		else if(StrEqual(sInfo, "display"))
		{
			gA_MarkerSettings[param1][bMarkerDisplay] = !gA_MarkerSettings[param1][bMarkerDisplay];
		}

		else if(StrEqual(sInfo, "color"))
		{
			gA_MarkerSettings[param1][iMarkerColor] = (++gA_MarkerSettings[param1][iMarkerColor] % sizeof(gI_Colors));
		}

		gH_MarkerMenu.Display(param1, MENU_TIME_FOREVER);
	}

	else if(action == MenuAction_DisplayItem)
	{
		menu.GetItem(param2, sInfo, 16);

		char[] sDisplay = new char[64];

		if(StrEqual(sInfo, "marker"))
		{
			strcopy(sDisplay, 64, (gA_MarkerSettings[param1][bMarkerDrawing])? "-marker":"+marker");
		}

		else if(StrEqual(sInfo, "display"))
		{
			strcopy(sDisplay, 64, (gA_MarkerSettings[param1][bMarkerDisplay])? "Hide marker":"Display marker");
		}

		else if(StrEqual(sInfo, "color"))
		{
			FormatEx(sDisplay, 64, "Color: %s", gS_Colors[gA_MarkerSettings[param1][iMarkerColor]]);
		}

		return RedrawMenuItem(sDisplay);
	}

	return 0;
}

public Action Timer_DrawAll(Handle Timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClientTiny(i) || !IsPlayerAlive(i) || !CanUseMarker(i))
		{
			continue;
		}

		if(gA_MarkerSettings[i][bMarkerDrawing])
		{
			gF_MarkerPoints[i][1] = GetAimPosition(i);
		}

		float dist = GetVectorDistance(gF_MarkerPoints[i][0], gF_MarkerPoints[i][1]) * 2.0;
		int clr = gI_Colors[gA_MarkerSettings[i][iMarkerColor]];

		int color[4];
		color[0] = clr >> 16;
		color[1] = clr >> 8;
		color[2] = clr;
		color[3] = 255;

		TE_SetupBeamRingPoint(gF_MarkerPoints[i][0], dist - 0.1, dist, gI_BeamSprite, gI_HaloSprite, 0, 60, 0.1, 5.0, 0.00, color, 10, 0);

		if(gA_MarkerSettings[i][bMarkerDisplay])
		{
			TE_SendToAll(0.0);
		}

		else
		{
			TE_SendToClient(i, 0.0);
		}
	}

	return Plugin_Continue;
}

void ToggleDrawing(int client, bool status)
{
	gA_MarkerSettings[client][bMarkerDrawing] = status;

	if(gA_MarkerSettings[client][bMarkerDrawing])
	{
		gF_MarkerPoints[client][0] = GetAimPosition(client);
	}
}

public bool TraceFilter_NoClients(int entity, int contentsMask, any data)
{
	return (entity != data && !IsValidClientTiny(data));
}

float[] GetAimPosition(int client)
{
	float pos[3];
	GetClientEyePosition(client, pos);

	float angles[3];
	GetClientEyeAngles(client, angles);

	TR_TraceRayFilter(pos, angles, MASK_SHOT, RayType_Infinite, TraceFilter_NoClients, client);

	if(TR_DidHit())
	{
		float end[3];
		TR_GetEndPosition(end);

		float final[3];
		final = end;
		
		final[0] = float(RoundToNearest(end[0] / 16) * 16);
		final[1] = float(RoundToNearest(end[1] / 16) * 16);
		final[2] = end[2];

		TE_SetupEnergySplash(gF_MarkerPoints[client][0], NULL_VECTOR, false);
		TE_SendToAll(0.0);

		return final;
	}

	return pos;
}

#define CS_TEAM_CT 3

bool CanUseMarker(int client)
{
	return (IsPlayerAlive(client) && (GetClientTeam(client) == CS_TEAM_CT || CheckCommandAccess(client, "sm_adminmarker", ADMFLAG_GENERIC)));
}

bool IsValidClientTiny(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}
