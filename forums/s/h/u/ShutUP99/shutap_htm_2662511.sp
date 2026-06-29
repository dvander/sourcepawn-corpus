#pragma semicolon 1

#define DEBUG

#include <sourcemod> 
#include <colors>
#include <sdktools>

#pragma newdecls required 

/* CONVARS */
ConVar g_htm_flag;
ConVar g_htm_cvar_holdtime;

ConVar g_htm_cvar_red;
ConVar g_htm_cvar_green;
ConVar g_htm_cvar_blue;
ConVar g_htm_cvar_transparency;

ConVar g_htm_cvar_x;
ConVar g_htm_cvar_y;

ConVar g_htm_cvar_effecttype;

ConVar g_htm_cvar_effectduration;
ConVar g_htm_cvar_fadeinduration;
ConVar g_htm_cvar_fadeoutduration;

float htm_holdtime;

/* CONVARS */
int i_htm_flag;

/* HANDLES */
Handle HTM;

char EmptyFlag[32] = "";
char sFlag[32];

public Plugin myinfo = 
{
	name = "Hud Text Message",
	author = "ShutAP",
	description = "This plugin send a message in the HUD with the arg message.",
	version = "1.0",
	url = "https://steamcommunity.com/id/ShutAP1337"
};

public void OnPluginStart() 
{ 
	g_htm_flag = CreateConVar("sm_htm_flag", "o", "Flag needed for command usage.");
	g_htm_cvar_x = CreateConVar("sm_htm_x", "-1.0", "Horizontal Position to show the displayed message (To be centered, set as -1.0).", _, true, -1.0, true, 1.0);
	g_htm_cvar_y = CreateConVar("sm_htm_y", "0.1", "Vertical Position to show the displayed message (To be centered, set as -1.0).", _, true, -1.0, true, 1.0);
	g_htm_cvar_holdtime = CreateConVar("sm_htm_holdtime", "2.0", "Time that the message is shown.", _, true, 0.0, true, 5.0);
	g_htm_cvar_red = CreateConVar("sm_htm_r", "255", "RGB Red Color to the displayed message.", _, true, 0.0, true, 255.0);
	g_htm_cvar_green = CreateConVar("sm_htm_g", "255", "RGB Green Color to the displayed message.", _, true, 0.0, true, 255.0);
	g_htm_cvar_blue = CreateConVar("sm_htm_b", "255", "RGB Blue Color to the displayed message.", _, true, 0.0, true, 255.0);
	g_htm_cvar_transparency = CreateConVar("sm_htm_transparency", "100", "Message Transparency Value.");	
	g_htm_cvar_effecttype = CreateConVar("sm_htm_effect", "1.0", "0 - Fade In; 1 - Fade out; 2 - Flash", _, true, 0.0, true, 2.0);
	g_htm_cvar_effectduration = CreateConVar("sm_htm_effectduration", "0.5", "Duration of the selected effect. Not always aplicable");
	g_htm_cvar_fadeinduration = CreateConVar("sm_htm_fadeinduration", "0.5", "Duration of the selected effect.");
	g_htm_cvar_fadeoutduration = CreateConVar("sm_htm_fadeoutduration", "0.5", "Duration of the selected effect.");	
	
	i_htm_flag = GetConVarInt(g_htm_flag);
	
	IntToString(i_htm_flag, sFlag, sizeof(sFlag));
	if (StrEqual(sFlag, EmptyFlag))
	{
		RegConsoleCmd("sm_hudtext", Command_HTM);
		RegConsoleCmd("sm_htm", Command_HTM);
		
		HTM = CreateHudSynchronizer();
		
		AutoExecConfig(true, "plugin.shutap_htm");
	}
		
	RegAdminCmd("sm_hudtext", Command_HTM, i_htm_flag);
	RegAdminCmd("sm_htm", Command_HTM, i_htm_flag);
	HTM = CreateHudSynchronizer(); 
	
	AutoExecConfig(true, "plugin.shutap_htm");
} 

public void OnConfigsExecuted()
{
	htm_holdtime = GetConVarFloat(g_htm_cvar_holdtime);
}

public Action Command_HTM(int client, int args)
{ 
	int htm_red = GetConVarInt(g_htm_cvar_red);
	int htm_green = GetConVarInt(g_htm_cvar_green);
	int htm_blue = GetConVarInt(g_htm_cvar_blue);
	int htm_transparency = GetConVarInt(g_htm_cvar_transparency);
	int htm_effect = GetConVarInt(g_htm_cvar_effecttype);
	float htm_x = GetConVarFloat(g_htm_cvar_x);
	float htm_y = GetConVarFloat(g_htm_cvar_y);
	float htm_effectduration = GetConVarFloat(g_htm_cvar_effectduration);
	float htm_fadein = GetConVarFloat(g_htm_cvar_fadeinduration);
	float htm_fadeout = GetConVarFloat(g_htm_cvar_fadeoutduration);

	if (args == 0)
	{
		PrintToChat(client, "\x01[\x04SM\x01] \x01Please use: \x07!htm \x03<message>");
		return Plugin_Handled;
	}
	
	char message[512];
	GetCmdArgString(message, sizeof(message));
	
	if(client == 0)
	{
		ReplyToCommand(client, "This command is only available in game.");
		return Plugin_Handled;
	}
	
	SetHudTextParams(htm_x, htm_y, htm_holdtime, htm_red, htm_green, htm_blue, htm_transparency, htm_effect, htm_effectduration, htm_fadein, htm_fadeout);
	for (int i = 1; i <= MaxClients;i++) 
	{ 
	    if (!IsClientInGame(i) || IsFakeClient(i))continue; 
     
	    ShowSyncHudText(i, HTM, message); 
	}
	return Plugin_Handled;
}