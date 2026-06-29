#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Mithat Guner" //Thanks To shanapu https://forums.alliedmods.net/member.php?u=259929
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>

ConVar hud_red;
ConVar hud_green;
ConVar hud_blue;
ConVar hud_xpos;
ConVar hud_ypos;

public Plugin myinfo = 
{
	name = "HUD Write",
	author = PLUGIN_AUTHOR,
	description = "HUD Write",
	version = PLUGIN_VERSION,
	url = "pluginler.com"
};

public void OnPluginStart()
{
	hud_red = CreateConVar("mithat_hud_red", "255", "RGB RED Color");
	hud_green = CreateConVar("mithat_hud_blue", "0", "RGB BLUE Color");
	hud_blue = CreateConVar("mithat_hud_green", "0", "RGB GREEN Color");
	hud_xpos = CreateConVar("mithat_hud_x", "0.45", "HUD X POS");
	hud_ypos = CreateConVar("mithat_hud_y", "0.350", "HUD Y POS");
	AutoExecConfig(true, "mithat_hudwrite");
	RegAdminCmd("sm_hwrite", write, ADMFLAG_GENERIC, "HUD Write - Mithat Guner");

}
public Action write(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Use: sm_hwrite <text>");
		return Plugin_Handled;
	}

	char text[192];
	GetCmdArgString(text, sizeof(text));

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, GetConVarInt(hud_red), GetConVarInt(hud_blue), GetConVarInt(hud_green), 255, 0, 0.25, 0.5, 0.3);
			
			if (StrContains(text[0], "@r", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@r", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, 255, 0, 0, 255, 0, 0.25, 0.5, 0.3);
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@g", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@g", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, 0, 255, 0, 255, 0, 0.25, 0.5, 0.3);
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@b", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@b", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, 0, 0, 255, 255, 0, 0.25, 0.5, 0.3);
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@w", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@w", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, 255, 255, 255, 255, 0, 0.25, 0.5, 0.3);
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@y", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@y", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, 255, 255, 51, 255, 0, 0.25, 0.5, 0.3);
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@bl", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@bl", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), 3.0, 0, 0, 0, 255, 0, 0.25, 0.5, 0.3);
				ShowHudText(i, 1, text);
			}
			
			ShowHudText(i, 1, text);
		}
	}
	return Plugin_Handled;
}