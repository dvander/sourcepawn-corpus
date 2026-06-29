/******************************************************************************
 CREDITS FOR SHANAPU TO CREATE THIS ICON MODULE IN HIS MYJAILBREAK!
******************************************************************************/


//Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <autoexecconfig>
#include <shavit>


//Compiler Options
#pragma semicolon 1
#pragma newdecls required


//Console Variables
ConVar gc_bIconShavit;


//Integers
int g_iIcon[MAXPLAYERS + 1] = {-1, ...};

public Plugin myinfo =
{
	name = "[shavit] Best Map Record Icon",
	description = "It shows an icon in the top of the player who has the map's best record",
	author = "Hallucinogenic Troll (just an edit), shavit (for his help), shanapu (module) and Bara ",
	version = "1.0",
	url = "PTFun.net"
}


//Start
public void OnPluginStart()
{
	//AutoExecConfig
	gc_bIconShavit = AutoExecConfig_CreateConVar("sm_wshavit_icon_enable", "1", "0 - disabled, 1 - enable the icon above the wardens head", _, true,  0.0, true, 1.0);
	
	
	//Hooks
	HookEvent("round_poststart", Icon_Event_PostRoundStart);
	HookEvent("player_death", Icon_Event_PlayerDeathTeam);
	HookEvent("player_team", Icon_Event_PlayerDeathTeam);
}

public void OnMapStart()
{
	if (gc_bIconShavit.BoolValue)
	{
		AddFileToDownloadsTable("materials/decals/ptfun/wr/world_record.vmt");
		AddFileToDownloadsTable("materials/decals/ptfun/wr/world_record.vtf");
		PrecacheModel("materials/decals/ptfun/wr/world_record.vmt");
	}
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public void Icon_Event_PostRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_Delay);
}


public void Icon_Event_PlayerDeathTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));  //Get the dead clients id
	RemoveIcon(client);
}


public void OnClientDisconnect(int client)
{
	RemoveIcon(client);
}


/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/


public void Shavit_OnWorldRecord(int client, BhopStyle style, float time, int jumps, int strafes, float sync)
{
	CreateTimer(0.1, Timer_Delay);
}


public Action Timer_Delay(Handle timer, Handle pack)
{
	for (int i = MaxClients; 0 <= i; i--)
	{
		if(!IsValidClient(i))
		{
			continue;
		}
		SpawnIcon(i);
	}
}


/******************************************************************************
                   FUNCTIONS
******************************************************************************/

public Action Should_TransmitWR(int entity, int client)
{
	char m_ModelName[PLATFORM_MAX_PATH];
	char iconbuffer[256];
	Format(iconbuffer, sizeof(iconbuffer), "materials/decals/ptfun/wr/world_record.vmt");
	GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	if (StrEqual(iconbuffer, m_ModelName))
			return Plugin_Continue;
	return Plugin_Handled;
}


/******************************************************************************
                   STOCKS
******************************************************************************/


int SpawnIcon(int client)
{
	BhopStyle style = view_as<BhopStyle>(0);
	float WRTime1;
	float WRTime2;
	Shavit_GetWRTime(style, WRTime1);
	Shavit_GetPlayerPB(client, style, WRTime2);
	
	RemoveIcon(client);
	
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	g_iIcon[client] = CreateEntityByName("env_sprite");

	if (!g_iIcon[client]) return -1;
	char iconbuffer[256];
	if (WRTime1 == WRTime2)
	{
			Format(iconbuffer, sizeof(iconbuffer), "materials/decals/ptfun/wr/world_record.vmt");
			DispatchKeyValue(g_iIcon[client], "model", iconbuffer);
			DispatchKeyValue(g_iIcon[client], "classname", "env_sprite");
			DispatchKeyValue(g_iIcon[client], "spawnflags", "1");
			DispatchKeyValue(g_iIcon[client], "scale", "0.3");
			DispatchKeyValue(g_iIcon[client], "rendermode", "1");
			DispatchKeyValue(g_iIcon[client], "rendercolor", "255 255 255");
			DispatchSpawn(g_iIcon[client]);
	}
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] = origin[2] + 90.0;
	
	TeleportEntity(g_iIcon[client], origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(g_iIcon[client], "SetParent", g_iIcon[client], g_iIcon[client], 0);
	if (WRTime1 == WRTime2) 
	{
		SDKHook(g_iIcon[client], SDKHook_SetTransmit, Should_TransmitWR);
	}
	return g_iIcon[client];
}


stock void RemoveIcon(int client) 
{
	if (g_iIcon[client] > 0 && IsValidEdict(g_iIcon[client]))
	{
		AcceptEntityInput(g_iIcon[client], "Kill");
		g_iIcon[client] = -1;
	}
}