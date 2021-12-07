#include <sourcemod>
#include <morecolors>

#pragma semicolon 1

new Handle:g_h_CVAR_Enable = INVALID_HANDLE;
new Handle:g_h_CVAR_ATag = INVALID_HANDLE;
new Handle:g_h_CVAR_VTag = INVALID_HANDLE;

new Handle:g_h_CVAR_CATag = INVALID_HANDLE;
new Handle:g_h_CVAR_CAName = INVALID_HANDLE;
new Handle:g_h_CVAR_CAText = INVALID_HANDLE;

new Handle:g_h_CVAR_CVTag = INVALID_HANDLE;
new Handle:g_h_CVAR_CVName = INVALID_HANDLE;
new Handle:g_h_CVAR_CVText = INVALID_HANDLE;

new Handle:g_hCvarADM;
new Handle:g_hCvarVIP;

new String:g_strADM[255];
new String:g_strVIP[255];

new String:IDs[][]=
{
	"STEAM_x:x:xxxxxxxx",	"STEAM_x:x:xxxxxxxx",	"STEAM_x:x:xxxxxxxx",
	"STEAM_x:x:xxxxxxxx"
};


public Plugin:myinfo = 
{
	name = "[NMRiH] ADM/VIP Chat Color",
	author = "IZUMI WING",
	description = "Based on eXceeder's Admin Chat,but this can be set for both Admin and VIP.",
	version = "1.1",
	url = "www.sourcemod.net"
}


public OnPluginStart()
{
	g_h_CVAR_Enable = CreateConVar("sm_enable", "1", "Turn On/Off the plugin. (0 = Off | 1 = On)");
	g_h_CVAR_ATag = CreateConVar("sm_adminchat_atag", "[ADMIN]", "Tag for the Admin Chat");
	g_h_CVAR_CATag = CreateConVar("sm_color_atag", "lime", "Color for the Admin Tag");
	g_h_CVAR_CAName = CreateConVar("sm_color_aname", "fullred", "Color for the Name of the Admin");
	g_h_CVAR_CAText = CreateConVar("sm_color_atext", "deepskyblue", "Color for the Text which the Admin has written");
	g_h_CVAR_VTag = CreateConVar("sm_adminchat_vtag", "[VIP]", "Tag for the VIP Chat");
	g_h_CVAR_CVTag = CreateConVar("sm_color_vtag", "lime", "Color for the VIP Tag");
	g_h_CVAR_CVName = CreateConVar("sm_color_vname", "fullred", "Color for the Name of the VIP");
	g_h_CVAR_CVText = CreateConVar("sm_color_vtext", "deepskyblue", "Color for the Text which the player has written");
	
	AutoExecConfig(true, "nmrih_cc.cfg");
	
	RegConsoleCmd("say", Say_Hook);
	g_hCvarADM = CreateConVar("adminchat_admin_flag", "z", "Color for the Text which the Admin has written");
	GetConVarString(g_hCvarADM, g_strADM, sizeof(g_strADM));
	g_hCvarVIP = CreateConVar("adminchat_vip_flag", "a", "Color for the Text which the VIP has written");
	GetConVarString(g_hCvarVIP, g_strVIP, sizeof(g_strVIP));
}


public Action:Say_Hook(client, args)
{
	new Enable = GetConVarInt(g_h_CVAR_Enable);
	if(Enable != 1)
	{
		return Plugin_Continue;
	}
	
	decl String:sText[192];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);

	new bool:bAdmin = CheckCommandAccess(client, "adminchat_admin_flag", ADMFLAG_GENERIC);
	new bool:bSpecial = CheckCommandAccess(client, "adminchat_vip_flag", ADMFLAG_RESERVATION);
	
	if(bAdmin || (g_strVIP[0] != '\0' && bSpecial))
		{
		decl String:strType[255];
			if(bAdmin)
				AdminChat(client,sText);
			else
				VIPChat(client,sText);
			
		return Plugin_Handled;
		}
	return Plugin_Continue;
}
AdminChat(client, String:sText[192])
{
	new String:sTag[20];
	GetConVarString(g_h_CVAR_ATag, sTag, sizeof(sTag));
	
	new String:Color_Tag[20];
	GetConVarString(g_h_CVAR_CATag, Color_Tag, sizeof(Color_Tag));
	
	new String:Color_Name[20];
	GetConVarString(g_h_CVAR_CAName, Color_Name, sizeof(Color_Name));
	
	new String:Color_Text[20];
	GetConVarString(g_h_CVAR_CAText, Color_Text, sizeof(Color_Text));
	
	CPrintToChatAll("{%s}%s{%s}%N: {%s}%s", Color_Tag, sTag, Color_Name, client, Color_Text, sText);
}

VIPChat(client, String:sText[192])
{
	new String:sTag[20];
	GetConVarString(g_h_CVAR_VTag, sTag, sizeof(sTag));
	
	new String:Color_Tag[20];
	GetConVarString(g_h_CVAR_CVTag, Color_Tag, sizeof(Color_Tag));
	
	new String:Color_Name[20];
	GetConVarString(g_h_CVAR_CVName, Color_Name, sizeof(Color_Name));
	
	new String:Color_Text[20];
	GetConVarString(g_h_CVAR_CVText, Color_Text, sizeof(Color_Text));
	
	CPrintToChatAll("{%s}%s{%s}%N: {%s}%s", Color_Tag, sTag, Color_Name, client, Color_Text, sText);
}


// --------------------------------- STOCKS --------------------------------- //


stock bool:IsClientValid(i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
	{
		return true;
	}
	
	return false;
}