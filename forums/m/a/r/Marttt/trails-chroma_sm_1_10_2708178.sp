#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define TRAIL_NONE -1
// #define DEBUG

enum TrailSettings
{
	iRedChannel,
	iGreenChannel,
	iBlueChannel,
	iSpecialColor,
	iAlphaChannel
}

/* CVars */

ConVar gCV_PluginEnabled = null;
ConVar gCV_AdminsOnly = null;
ConVar gCV_AllowHide = null;
ConVar gCV_CheapTrails = null;
ConVar gCV_BeamLife = null;
ConVar gCV_BeamWidth = null;
ConVar gCV_RespawnDisable = null;

/* Cached CVars */

bool gB_PluginEnabled = true;
bool gB_AdminsOnly = true;
bool gB_AllowHide = true;
bool gB_CheapTrails = false;
float gF_BeamLife = 1.5;
float gF_BeamWidth = 1.5;
bool gB_RespawnDisable = false;

/* Global variables */

int gI_BeamSprite;
int gI_SelectedTrail[MAXPLAYERS + 1] = {TRAIL_NONE, ...};
float gF_LastPosition[MAXPLAYERS + 1][3];

// Hiding trails globals
bool gB_HidingTrails[MAXPLAYERS + 1];
ArrayList aL_Clients = null;

// KeyValue globals
int gI_TrailAmount;
char gS_TrailTitle[128][128];
//int gI_TrailSettings[128][TrailSettings];
int gI_TrailSettings[128][5];

// Spectrum cycle globals
int gI_CycleColor[MAXPLAYERS + 1][4];
bool gB_RedToYellow[MAXPLAYERS + 1];
bool gB_YellowToGreen[MAXPLAYERS + 1];
bool gB_GreenToCyan[MAXPLAYERS + 1];
bool gB_CyanToBlue[MAXPLAYERS + 1];
bool gB_BlueToMagenta[MAXPLAYERS + 1];
bool gB_MagentaToRed[MAXPLAYERS + 1];

// Cheap trail globals
int gI_TickCounter[MAXPLAYERS + 1];
float gF_PlayerOrigin[MAXPLAYERS + 1][3];

// Cookie handles
Handle gH_TrailChoiceCookie;
Handle gH_TrailHidingCookie;

EngineVersion gEV_Type = Engine_Unknown;

public Plugin myinfo =
{
	name = "Trails Chroma",
	author = "Nickelony",
	description = "Adds colorful player trails with special effects.",
	version = "2.4",
	url = "steamcommunity.com/id/nickelony"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	
	RegConsoleCmd("sm_trail", Command_Trail, "Opens the 'Trail Selection' menu.");
	RegConsoleCmd("sm_trails", Command_Trail, "Opens the 'Trail Selection' menu.");
	RegConsoleCmd("sm_hide", Command_Hide, "Hides other players' trails.");
	
	gCV_PluginEnabled = CreateConVar("sm_trails_enable", "1", "Enable or Disable all features of the plugin.", 0, true, 0.0, true, 1.0);
	gCV_AdminsOnly = CreateConVar("sm_trails_admins_only", "1", "Enable trails for admins only.", 0, true, 0.0, true, 1.0);
	gCV_AllowHide = CreateConVar("sm_trails_allow_hide", "1", "Allow hiding other players' trails.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCV_CheapTrails = CreateConVar("sm_trails_cheap", "0", "Force cheap trails (lower quality in exchange for more FPS).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCV_BeamLife = CreateConVar("sm_trails_life", "1.5", "Time duration of the trails.", FCVAR_NOTIFY, true, 0.0);
	gCV_BeamWidth = CreateConVar("sm_trails_width", "1.5", "Width of the trail beams.", FCVAR_NOTIFY, true, 0.0);
	gCV_RespawnDisable = CreateConVar("sm_trails_respawn_disable", "0", "Disable the player's trail after respawning.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	gCV_PluginEnabled.AddChangeHook(OnConVarChanged);
	gCV_AdminsOnly.AddChangeHook(OnConVarChanged);
	gCV_AllowHide.AddChangeHook(OnConVarChanged);
	gCV_CheapTrails.AddChangeHook(OnConVarChanged);
	gCV_BeamLife.AddChangeHook(OnConVarChanged);
	gCV_BeamWidth.AddChangeHook(OnConVarChanged);
	gCV_RespawnDisable.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig();
	
	gH_TrailChoiceCookie = RegClientCookie("trail_choice", "Trail Choice Cookie", CookieAccess_Protected);
	gH_TrailHidingCookie = RegClientCookie("trail_hiding", "Trail Hiding Cookie", CookieAccess_Protected);
	
	aL_Clients = new ArrayList();
	gEV_Type = GetEngineVersion();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gB_PluginEnabled = gCV_PluginEnabled.BoolValue;
	gB_AdminsOnly = gCV_AdminsOnly.BoolValue;
	gB_AllowHide = gCV_AllowHide.BoolValue;
	gB_CheapTrails = gCV_CheapTrails.BoolValue;
	gF_BeamLife = gCV_BeamLife.FloatValue;
	gF_BeamWidth = gCV_BeamWidth.FloatValue;
	gB_RespawnDisable = gCV_RespawnDisable.BoolValue;
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	char[] sChoiceCookie = new char[8];
	GetClientCookie(client, gH_TrailChoiceCookie, sChoiceCookie, 8);
	
	bool bNoAccess = gB_AdminsOnly && !CheckCommandAccess(client, "sm_trails_override", ADMFLAG_RESERVATION);
	
	if(sChoiceCookie[0] == '\0' || bNoAccess) // If the cookie is empty or the player doesn't have access
	{
		IntToString(TRAIL_NONE, sChoiceCookie, 8);
		SetClientCookie(client, gH_TrailChoiceCookie, sChoiceCookie);
	}
	else
	{
		gI_SelectedTrail[client] = StringToInt(sChoiceCookie);
	}
	
	char[] sHidingCookie = new char[8];
	GetClientCookie(client, gH_TrailHidingCookie, sHidingCookie, 8);
	gB_HidingTrails[client] = StringToInt(sHidingCookie) == 1;
	
	if(IsValidClient(client) && !gB_HidingTrails[client] && aL_Clients.FindValue(client) == -1) // Only works after reloading the plugin
	{
		aL_Clients.Push(client);
	}
}

public void OnMapStart()
{
	if(!LoadColorsConfig())
	{
		SetFailState("Failed load \"configs/trails-colors.cfg\". File missing or invalid.");
	}
	
	//gI_BeamSprite = PrecacheModel("materials/effects/laser1.vmt", true); //For L4D/L4D2, native sprite.
	
	gI_BeamSprite = PrecacheModel("materials/trails/beam_01.vmt", true);
	
	AddFileToDownloadsTable("materials/trails/beam_01.vmt");
	AddFileToDownloadsTable("materials/trails/beam_01.vtf");
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!IsValidClient(client))
	{
		return;
	}
	
	if(!gB_HidingTrails[client] && aL_Clients.FindValue(client) == -1) // If the client isn't hiding trails, but somehow isn't on the list
	{
		aL_Clients.Push(client);
	}
	
	if(gB_RespawnDisable) // Reset trail on respawn
	{
		gI_SelectedTrail[client] = TRAIL_NONE;
	}
}

bool LoadColorsConfig()
{
	char[] sPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/trails-colors.cfg");
	KeyValues kv = new KeyValues("trails-colors");
	
	if(!kv.ImportFromFile(sPath) || !kv.GotoFirstSubKey())
	{
		delete kv;
		return false;
	}
	
	int i = 0;
	
	do
	{
		kv.GetString("name", gS_TrailTitle[i], 128, "<MISSING TRAIL NAME>");
		
		gI_TrailSettings[i][iRedChannel] = kv.GetNum("red", 255);
		gI_TrailSettings[i][iGreenChannel] = kv.GetNum("green", 255);
		gI_TrailSettings[i][iBlueChannel] = kv.GetNum("blue", 255);
		gI_TrailSettings[i][iSpecialColor] = kv.GetNum("special", 0);
		gI_TrailSettings[i][iAlphaChannel] = kv.GetNum("alpha", 128);
		
		i++;
	}
	while(kv.GotoNextKey());
	
	delete kv;
	gI_TrailAmount = i;
	return true;
}

public Action Command_Hide(int client, int args)
{
	if(!gB_PluginEnabled || !gB_AllowHide || !IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	gB_HidingTrails[client] = !gB_HidingTrails[client]; // Toggle it
	
	if(gB_HidingTrails[client])
	{
		int index = aL_Clients.FindValue(client);
		
		if(index != -1) // If the index is valid and the player was found on the list
		{
			aL_Clients.Erase(index);
		}
		
		if(gEV_Type == Engine_CSGO) // CS:GO supports HTML
		{
			PrintCenterText(client, "Other players' trails are now <font color='#FF00FF' face=''>Hidden</font>.");
		}
		else
		{
			PrintCenterText(client, "Other players' trails are now Hidden.");
		}
		
		SetClientCookie(client, gH_TrailHidingCookie, "0");
	}
	else
	{
		aL_Clients.Push(client);
		
		if(gEV_Type == Engine_CSGO)
		{
			PrintCenterText(client, "Other players' trails are now <font color='#FFFF00' face=''>Visible</font>.");
		}
		else
		{
			PrintCenterText(client, "Other players' trails are now Visible.");
		}
		
		SetClientCookie(client, gH_TrailHidingCookie, "1");
	}
	
	return Plugin_Handled;
}

public Action Command_Trail(int client, int args)
{
	if(!gB_PluginEnabled || !IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(gB_AdminsOnly && !CheckCommandAccess(client, "sm_trails_override", ADMFLAG_RESERVATION))
	{
		PrintCenterText(client, "You do not have permission to use this command.");
		return Plugin_Handled;
	}
	
	return OpenTrailMenu(client, 0);
}

Action OpenTrailMenu(int client, int page)
{
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("Choose a trail:\n ");
	
	char[] sNone = new char[8];
	IntToString(TRAIL_NONE, sNone, 8);
	
	menu.AddItem(sNone, "None", (gI_SelectedTrail[client] == TRAIL_NONE)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	for(int i = 0; i < gI_TrailAmount; i++)
	{
		char[] sInfo = new char[8];
		IntToString(i, sInfo, 8);
		
		if(StrEqual(gS_TrailTitle[i], "/empty/") || StrEqual(gS_TrailTitle[i], "/EMPTY/") || StrEqual(gS_TrailTitle[i], "{empty}") || StrEqual(gS_TrailTitle[i], "{EMPTY}"))
		{
			menu.AddItem("", "", ITEMDRAW_SPACER); // Empty line support
		}
		else
		{
			menu.AddItem(sInfo, gS_TrailTitle[i], (gI_SelectedTrail[client] == i)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitButton = true;
	menu.DisplayAt(client, page, 60);
	
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char[] sInfo = new char[8];
		menu.GetItem(param2, sInfo, 8);
		
		MenuSelection(param1, sInfo);
		OpenTrailMenu(param1, GetMenuSelectionPosition());
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	
	return 0;
}

void MenuSelection(int client, char[] info)
{
	int choice = StringToInt(info);
	
	if(choice == TRAIL_NONE)
	{
		if(gEV_Type == Engine_CSGO) // CS:GO supports HTML
		{
			PrintCenterText(client, "Your trail is now <font color='#FF0000' face=''>DISABLED</font>.");
		}
		else
		{
			PrintCenterText(client, "Your trail is now DISABLED.");
		}
		
		StopSpectrumCycle(client);
	}
	else
	{
		int color[3];
		color[0] = gI_TrailSettings[choice][iRedChannel];
		color[1] = gI_TrailSettings[choice][iGreenChannel];
		color[2] = gI_TrailSettings[choice][iBlueChannel];
		
		char[] sHexColor = new char[16];
		FormatEx(sHexColor, 16, "#%02x%02x%02x", color[0], color[1], color[2]);
		
		if(gI_SelectedTrail[client] == TRAIL_NONE)
		{
			if(gEV_Type == Engine_CSGO)
			{
				PrintCenterText(client, "Your trail is now <font color='#00FF00' face=''>ENABLED</font>.\nYour beam color is: <font color='%s' face=''>%s</font>.", sHexColor, gS_TrailTitle[choice]);
			}
			else
			{
				PrintCenterText(client, "Your trail is now ENABLED.\nYour beam color is: %s.", gS_TrailTitle[choice]);
			}
		}
		else
		{
			if(gEV_Type == Engine_CSGO)
			{
				PrintCenterText(client, "Your beam color is now: <font color='%s' face=''>%s</font>.", sHexColor, gS_TrailTitle[choice]);
			}
			else
			{
				PrintCenterText(client, "Your beam color is now: %s.", gS_TrailTitle[choice]);
			}
		}
		
		if(gI_TrailSettings[choice][iSpecialColor] == 1 || gI_TrailSettings[choice][iSpecialColor] == 2)
		{
			gI_CycleColor[client][0] = 0;
			gI_CycleColor[client][1] = 0;
			gI_CycleColor[client][2] = 0;
			gB_RedToYellow[client] = true;
		}
		else
		{
			StopSpectrumCycle(client);
		}
	}
	
	gI_SelectedTrail[client] = choice;
	SetClientCookie(client, gH_TrailChoiceCookie, info);
}

void StopSpectrumCycle(int client)
{
	gB_RedToYellow[client] = false;
	gB_YellowToGreen[client] = false;
	gB_GreenToCyan[client] = false;
	gB_CyanToBlue[client] = false;
	gB_BlueToMagenta[client] = false;
	gB_MagentaToRed[client] = false;
}

public Action OnPlayerRunCmd(int client)
{
	if(gB_CheapTrails)
	{
		ForceCheapTrails(client);
	}
	else
	{
		ForceExpensiveTrails(client);
	}
	
	return Plugin_Continue;
}

void ForceCheapTrails(int client)
{
	if(gI_TickCounter[client] == 0)
	{
		float fOrigin[3];
		GetClientAbsOrigin(client, fOrigin);
		
		gF_PlayerOrigin[client][0] = fOrigin[0];
		gF_PlayerOrigin[client][1] = fOrigin[1];
		gF_PlayerOrigin[client][2] = fOrigin[2];
	}
	
	gI_TickCounter[client]++;
	
	if(gI_TickCounter[client] <= 1)
	{
		return; // Skip 1 frame. That's 50% less sprites to render
	}
	
	gI_TickCounter[client] = 0;
	
	CreatePlayerTrail(client, gF_PlayerOrigin[client]);
	gF_LastPosition[client] = gF_PlayerOrigin[client];
}

void ForceExpensiveTrails(int client)
{
	float fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	
	CreatePlayerTrail(client, fOrigin);
	gF_LastPosition[client] = fOrigin;
}

void CreatePlayerTrail(int client, float origin[3])
{
	bool bClientTeleported = GetVectorDistance(origin, gF_LastPosition[client], false) > 50.0;
	
	if(!gB_PluginEnabled || gI_SelectedTrail[client] == TRAIL_NONE || !IsPlayerAlive(client) || bClientTeleported)
	{
		return;
	}
	
	if(gB_AdminsOnly && !CheckCommandAccess(client, "sm_trails_override", ADMFLAG_RESERVATION))
	{
		return;
	}
	
	if(gEV_Type == Engine_TF2)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) // If the Spy is invisible
		{
			return;
		}
	}
	
	float fFirstPos[3];
	fFirstPos[0] = origin[0];
	fFirstPos[1] = origin[1];
	fFirstPos[2] = origin[2] + 5.0;
	
	float fSecondPos[3];
	fSecondPos[0] = gF_LastPosition[client][0];
	fSecondPos[1] = gF_LastPosition[client][1];
	fSecondPos[2] = gF_LastPosition[client][2] + 5.0;
	
	int color[4];
	//GetClientTrailColors(client, color);
	color = GetClientTrailColors(client, color);
	
	TE_SetupBeamPoints(fFirstPos, fSecondPos, gI_BeamSprite, 0, 0, 0, gF_BeamLife, gF_BeamWidth, gF_BeamWidth, 10, 0.0, color, 0);
	SendTempEntity(client); // Oh damn...
}

//int[] GetClientTrailColors(int client, int[] color)
int[] GetClientTrailColors(int client, int[] color2)
{
	int color[4];
	color[0] = color2[0];
	color[1] = color2[1];
	color[2] = color2[2];
	color[3] = color2[3];
	
	int choice = gI_SelectedTrail[client];
	color[3] = gI_TrailSettings[choice][iAlphaChannel];
	int stepsize = 0;
	
	if(gI_TrailSettings[choice][iSpecialColor] == 1) // Spectrum trail
	{
		stepsize = 1;
		DrawSpectrumTrail(client, stepsize);
		
		color[0] = gI_CycleColor[client][0];
		color[1] = gI_CycleColor[client][1];
		color[2] = gI_CycleColor[client][2];
	}
	else if(gI_TrailSettings[choice][iSpecialColor] == 2) // Wave trail
	{
		stepsize = 15;
		DrawSpectrumTrail(client, stepsize);
		
		color[0] = gI_CycleColor[client][0];
		color[1] = gI_CycleColor[client][1];
		color[2] = gI_CycleColor[client][2];
	}
	else if(gI_TrailSettings[choice][iSpecialColor] == 3) // Velocity trail
	{
		float fAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
		float fCurrentSpeed = SquareRoot(Pow(fAbsVelocity[0], 2.0) + Pow(fAbsVelocity[1], 2.0));
		
		DrawVelocityTrail(client, fCurrentSpeed);
		
		color[0] = gI_CycleColor[client][0];
		color[1] = gI_CycleColor[client][1];
		color[2] = gI_CycleColor[client][2];
	}
	else
	{
		color[0] = gI_TrailSettings[choice][iRedChannel];
		color[1] = gI_TrailSettings[choice][iGreenChannel];
		color[2] = gI_TrailSettings[choice][iBlueChannel];
	}
	
	#if defined DEBUG
	PrintHintText(client, "%i\n%i\n%i", color[0], color[1], color[2]);
	#endif
	
	return color;
}

void SendTempEntity(int client)
{
	if(gB_HidingTrails[client]) // If the player is hiding other players' trails
	{
		if(aL_Clients.Length == 0) // If there's nobody on the list (everyone has hiding enabled)
		{
			TE_SendToClient(client); // Send the trail to the current client only
		}
		else
		{
			int[] clientList = new int[aL_Clients.Length + 1];
			int arrayIndex = 0;
			
			for(int i = 0; i < aL_Clients.Length; i++) // That's basically "foreach(int clientIndex in aL_Clients)"
			{
				clientList[arrayIndex] = aL_Clients.Get(i);
				arrayIndex++;
			}
			
			clientList[arrayIndex] = client; // Add the current client to the array so he can see his own trail
			
			TE_Send(clientList, aL_Clients.Length + 1); // The client will send the trail to everyone but won't recieve any other trails
		}
	}
	else
	{
		if(aL_Clients.Length == 0) // If there's nobody on the list
		{
			return;
		}
		
		int[] clientList = new int[aL_Clients.Length];
		int arrayIndex = 0;
		
		for(int i = 0; i < aL_Clients.Length; i++) // foreach(int clientIndex in aL_Clients)
		{
			clientList[arrayIndex] = aL_Clients.Get(i);
			arrayIndex++;
		}
		
		TE_Send(clientList, aL_Clients.Length); // The client will send the trail to everyone and will revieve other players' trails as well
	}
}

void DrawSpectrumTrail(int client, int stepsize)
{
	if(gB_RedToYellow[client])
	{
		gB_MagentaToRed[client] = false;
		gI_CycleColor[client][0] = 255; gI_CycleColor[client][1] += stepsize; gI_CycleColor[client][2] = 0;
		
		if(gI_CycleColor[client][0] >= 255 && gI_CycleColor[client][1] >= 255 && gI_CycleColor[client][2] <= 0)
			gB_YellowToGreen[client] = true;
	}
	
	if(gB_YellowToGreen[client])
	{
		gB_RedToYellow[client] = false;
		gI_CycleColor[client][0] -= stepsize; gI_CycleColor[client][1] = 255; gI_CycleColor[client][2] = 0;
		
		if(gI_CycleColor[client][0] <= 0 && gI_CycleColor[client][1] >= 255 && gI_CycleColor[client][2] <= 0)
			gB_GreenToCyan[client] = true;
	}
	
	if(gB_GreenToCyan[client])
	{
		gB_YellowToGreen[client] = false;
		gI_CycleColor[client][0] = 0; gI_CycleColor[client][1] = 255; gI_CycleColor[client][2] += stepsize;
		
		if(gI_CycleColor[client][0] <= 0 && gI_CycleColor[client][1] >= 255 && gI_CycleColor[client][2] >= 255)
			gB_CyanToBlue[client] = true;
	}
	
	if(gB_CyanToBlue[client])
	{
		gB_GreenToCyan[client] = false;
		gI_CycleColor[client][0] = 0; gI_CycleColor[client][1] -= stepsize; gI_CycleColor[client][2] = 255;
		
		if(gI_CycleColor[client][0] <= 0 && gI_CycleColor[client][1] <= 0 && gI_CycleColor[client][2] >= 255)
			gB_BlueToMagenta[client] = true;
	}
	
	if(gB_BlueToMagenta[client])
	{
		gB_CyanToBlue[client] = false;
		gI_CycleColor[client][0] += stepsize; gI_CycleColor[client][1] = 0; gI_CycleColor[client][2] = 255;
		
		if(gI_CycleColor[client][0] >= 255 && gI_CycleColor[client][1] <= 0 && gI_CycleColor[client][2] >= 255)
			gB_MagentaToRed[client] = true;
	}
	
	if(gB_MagentaToRed[client])
	{
		gB_BlueToMagenta[client] = false;
		
		gI_CycleColor[client][0] = 255; gI_CycleColor[client][1] = 0; gI_CycleColor[client][2] -= stepsize;
		
		if(gI_CycleColor[client][0] >= 255 && gI_CycleColor[client][1] <= 0 && gI_CycleColor[client][2] <= 0)
			gB_RedToYellow[client] = true;
	}
}

void DrawVelocityTrail(int client, float currentspeed)
{
	int stepsize = 0;
	
	if(currentspeed <= 255.0)
	{
		gI_CycleColor[client][0] = 0; gI_CycleColor[client][1] = 0; gI_CycleColor[client][2] = 255;
	}
	else if(currentspeed > 255.0 && currentspeed <= 510.0)
	{
		stepsize = RoundToFloor(currentspeed) - 255;
		gI_CycleColor[client][0] = 0; gI_CycleColor[client][1] = stepsize; gI_CycleColor[client][2] = 255;
	}
	else if(currentspeed > 510.0 && currentspeed <= 765.0)
	{
		stepsize = RoundToFloor(-currentspeed) + 510;
		gI_CycleColor[client][0] = 0; gI_CycleColor[client][1] = 255; gI_CycleColor[client][2] = stepsize;
	}
	else if(currentspeed > 765.0 && currentspeed <= 1020.0)
	{
		stepsize = RoundToFloor(currentspeed) - 765;
		gI_CycleColor[client][0] = stepsize; gI_CycleColor[client][1] = 255; gI_CycleColor[client][2] = 0;
	}
	else if(currentspeed > 1020.0 && currentspeed <= 1275.0)
	{
		stepsize = RoundToFloor(-currentspeed) + 1020;
		gI_CycleColor[client][0] = 255; gI_CycleColor[client][1] = stepsize; gI_CycleColor[client][2] = 0;
	}
	else if(currentspeed > 1275.0 && currentspeed <= 1530.0)
	{
		stepsize = RoundToFloor(currentspeed) - 1275;
		gI_CycleColor[client][0] = 255; gI_CycleColor[client][1] = 0; gI_CycleColor[client][2] = stepsize;
	}
	else if(currentspeed > 1530.0 && currentspeed <= 1655.0)
	{
		stepsize = RoundToFloor(-currentspeed) + 1530;
		gI_CycleColor[client][0] = stepsize; gI_CycleColor[client][1] = 0; gI_CycleColor[client][2] = 255;
	}
	else
	{
		gI_CycleColor[client][0] = 125; gI_CycleColor[client][1] = 0; gI_CycleColor[client][2] = 255;
	}
}

public void OnClientDisconnect(int client)
{
	int index = aL_Clients.FindValue(client);
	
	if(index != -1) // If the index is valid and the player was found on the list
	{
		aL_Clients.Erase(index);
	}
}

public void OnMapEnd()
{
	aL_Clients.Clear();
}

bool IsValidClient(int client)
{
	return 1 <= client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}
