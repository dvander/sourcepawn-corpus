#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.6" 

public Plugin myinfo =  
{ 
    name = "VIP AWP-CrossHair", 
    author = "GenaEscobar, Cruze", 
    description = "", 
    version = PLUGIN_VERSION, 
    url = "www.steamcommunity.com/id/genaescobar" 
} 

bool g_bEnabled[MAXPLAYERS + 1] = {false, ...}, g_bOverlay[MAXPLAYERS+1] = {false, ...};
char g_sOverlayPath[256];
ConVar g_hCrosshair;

public void OnPluginStart()
{
	RegConsoleCmd("sm_crosshair", Command_Crosshair);
	RegConsoleCmd("sm_cross", Command_Crosshair);

	HookEvent("round_start", Event_RoundStart);

	g_hCrosshair = CreateConVar("sm_awp_crosshair_path", "materials/traplife/AWPcrosshair", "Path to overlay without .vmt/.vtf");
}

public void OnMapStart()
{
	 make_files_ready();
}

public void OnClientPostAdminCheck(int client)
{
	g_bEnabled[client] = false;
	g_bOverlay[client] = false;
	SDKHook(client, SDKHook_PreThink, Hook_PreThink);
}

public void OnClientDisconnect(int client)
{
	g_bEnabled[client] = false;
	g_bOverlay[client] = false;
}

public Action Command_Crosshair(int client, int args)
{
    if(client && IsClientInGame(client))
    {
        g_bEnabled[client] = !g_bEnabled[client];
        PrintToChat(client, "[SM] \x08You have %s\x08 AWP Crosshair.", g_bEnabled[client] ? "\x04enabled":"\x07disabled");
    }
    return Plugin_Handled;
}

public Action Event_RoundStart(Event ev, const char[] name, bool dbc)
{
	for(int i = 0; i < MaxClients; i++)
	{
		 g_bOverlay[i] = false;
	}
}

public Action Hook_PreThink(int client)
{
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	if(!g_bEnabled[client])
	{
		return Plugin_Continue;
	}
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char sClassname[64];
	
	if(iWeapon == -1)
	{
		return Plugin_Continue;
	}
	
	if(!GetEntityClassname(iWeapon, sClassname, 64))
	{
		return Plugin_Continue;
	}
	
	if(strcmp(sClassname, "weapon_awp") == 0)
	{
		if(GetEntProp(client, Prop_Send, "m_bIsScoped"))
		{
			if(!g_bOverlay[client])
			{
				ShowOverlay(client, g_sOverlayPath);
				g_bOverlay[client] = true;
			}
		}
		else
		{
			if(g_bOverlay[client])
			{
				ShowOverlay(client, "");
				g_bOverlay[client] = false;
			}
		}
	}
	else
	{
		if(g_bOverlay[client])
		{
			ShowOverlay(client, "");
			g_bOverlay[client] = false;
		}
	}
	return Plugin_Continue;
}

void ShowOverlay(int client, const char[] overlaypath) {
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

/******************/
/* download stuff */

void make_files_ready() {
	// i hope this works XD 
	
	char sBuffer[256];
	g_hCrosshair.GetString(sBuffer, 256);
	
	Format(sBuffer, 256, "%s.vmt");
	
	PrecacheModel(sBuffer, true);
	AddFileToDownloadsTable(sBuffer);
	
	ReplaceString(sBuffer, 356, ".vmt", ".vtf");
	
	PrecacheModel(sBuffer, true);
	AddFileToDownloadsTable(sBuffer);
	
	Format(g_sOverlayPath, 256, "%s", sBuffer);
	Format(g_sOverlayPath, 256, "%s", g_sOverlayPath[10]);
}