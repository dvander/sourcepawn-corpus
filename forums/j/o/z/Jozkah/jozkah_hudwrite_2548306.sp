#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

//Criar umas coisinhas cutes aqui ^^
#define PLUGIN_AUTHOR "Jozkah"
#define PLUGIN_VERSION "1.7"

//Cute Infobox
public Plugin myinfo = 
{
	name = "Jozkah HUD Writer",
	author = "PLUGIN_AUTHOR",
	description = "HUD Writer made by Jozkah",
	version = "PLUGIN_VERSION",
};
 
//SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), GetConVarInt(hud_red), GetConVarInt(hud_blue), GetConVarInt(hud_green), 255, 0, 0.25, 0.5, 0.3)//
//SetHudTextParams(float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut)//
//Os comandinhos aqui
ConVar hud_red;
ConVar hud_green;
ConVar hud_blue;
ConVar hud_xpos;
ConVar hud_ypos;
ConVar hud_time;
ConVar hud_fadein;
ConVar hud_fadeout;
ConVar hud_transparency;
ConVar hud_effect;
ConVar hud_fxtime;

//ConfigFile cfg/sourcemod/jozkah/
public void OnPluginStart()
{
	hud_red = CreateConVar("jozkah_hud_red", "255", "Color RED - RGB", ADMFLAG_ROOT, true , 0, true, 255);
	hud_green = CreateConVar("jozkah_hud_blue", "255", "Color GREEN - RGB", ADMFLAG_ROOT , true, 0, true, 255);
	hud_blue = CreateConVar("jozkah_hud_green", "255", "Color BLUE - RGB", ADMFLAG_ROOT , true, 0, true, 255);
	hud_xpos = CreateConVar("jozkah_hud_x", "0.25", "HUD POS X (LEFT/RIGHT)", ADMFLAG_ROOT , true, 0.0, true, 0.50);
	hud_ypos = CreateConVar("jozkah_hud_y", "0.15", "HUD POS Y (UP/DOWN)", ADMFLAG_ROOT , true, 0.0, true, 0.50);
	hud_time = CreateConVar("jozkah_hud_time", "3.0", "Time of the text on screen", ADMFLAG_ROOT , true, 0.0, true, 5.0);
	hud_fadein = CreateConVar("jozkah_hud_fadein", "0.5", "Time of FadeIn Effect", ADMFLAG_ROOT , true, 0.0, true, 1.0);
	hud_fadeout = CreateConVar("jozkah_hud_fadeout", "0.3", "Time of FadeOut Effect", ADMFLAG_ROOT , true, 0, true, 2.0);
	hud_transparency = CreateConVar("jozkah_hud_transparency", "255", "Alpha Transparency Value", ADMFLAG_ROOT , true, 0, true, 255);
	hud_effect = CreateConVar("jozkah_hud_effect", "0", "Effect of the text(0/1 FadeIn/Out, 2 Flash)", ADMFLAG_ROOT , true, 0, true, 2);
	hud_fxtime = CreateConVar("jozkah_hud_fxtime", "0.25", "Duration of the effect (may not apply to all effects)", ADMFLAG_ROOT , true, 0, true, 5.0);
	AutoExecConfig(true, "/jozkah/jozkah_hudwriter");
	RegAdminCmd("sm_hwrite", write, ADMFLAG_ROOT, "HUD WRITER");
	RegAdminCmd("sm_hw", write, ADMFLAG_ROOT, "HUD WRITER");
}
// 255 transparency, 0 effect , 0.25 fxtime,
//SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), GetConVarInt(hud_red), GetConVarInt(hud_blue), GetConVarInt(hud_green), 255, 0, 0.25, GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout)//
//SetHudTextParams(float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut)//
//Escrever comando errado= say ReplyToCommand
public Action write(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Use: sm_hwrite <text>");
		return Plugin_Handled;
	}

	//Ler <text>
	char text[192];
	GetCmdArgString(text, sizeof(text));

	//SetHudTextParams(float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut)//
	//As vezes até funcionam...
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), GetConVarInt(hud_red), GetConVarInt(hud_blue), GetConVarInt(hud_green), GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
			
			if (StrContains(text[0], "@red", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@red", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 255, 0, 0, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@green", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@green", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 0, 255, 0, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@blue", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@blue", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 0, 0, 255, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@white", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@white", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 255, 255, 255, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@yellow", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@yellow", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 255, 255, 0, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime),GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}
			
			if (StrContains(text[0], "@black", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@black", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 0, 0, 0, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}

			if (StrContains(text[0], "@orange", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@orange", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 255, 125, 0, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}

			if (StrContains(text[0], "@pink", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@pink", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 255, 0, 255, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}

			if (StrContains(text[0], "@purple", false) == 0)
			{
				ReplaceString(text, sizeof(text), "@purple", "");
				SetHudTextParams(GetConVarFloat(hud_xpos), GetConVarFloat(hud_ypos), GetConVarFloat(hud_time), 138, 43, 226, GetConVarInt(hud_transparency), GetConVarInt(hud_effect), GetConVarFloat(hud_fxtime), GetConVarFloat(hud_fadein), GetConVarFloat(hud_fadeout));
				ShowHudText(i, 1, text);
			}			
			
			ShowHudText(i, 1, text);
		}
	}
	return Plugin_Handled;
} 

//
//                 Changelog
//----------------------------------------------
//V1.1 - Added color change cvars
//----------------------------------------------
//V1.2 - Added position change cvar
//     - Added @r @g @b commands
//----------------------------------------------
//V1.3 - Changed to new syntax
//     - Added more colors @w @y @bl 
//       (White, Yellow, Black)
//-----------------------------------------------
//V1.4 - More Colores added (Purpe, Pink, Orange)
//-----------------------------------------------
//V1.5 - Changed @r @g @bl @p 
//     - To @red @green @black @purple
//          (On every single color)
//-----------------------------------------------
//V1.6 - Added message time(hud_time)
//-----------------------------------------------
//V1.7 - Added the FadeIn/Out Effects
//-----------------------------------------------
//V1.8 - Added transparency change cvars
//     - Added effect change cvars
//     - Added duration of the effect(hud_fxtime)
//-----------------------------------------------
//V1.9 - 
//-----------------------------------------------
//