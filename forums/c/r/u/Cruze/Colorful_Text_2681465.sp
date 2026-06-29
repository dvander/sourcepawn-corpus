#include <sourcemod>
#include <sdktools>
#include <store>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

ConVar g_ConVar_Credits;
ConVar g_ConVar_NameColor;
ConVar g_ConVar_TextColor;
ConVar g_ConVar_Sound;

public Plugin myinfo = 
{
	name = "Colorful text",
	author = "Swolly, Cruze",
	description = "Type !colorfultext <message>.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=320930"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_colorfultext", Colorful_Text, "Colorful writing using market credits");

	g_ConVar_Credits = CreateConVar("sm_colored_text_price", "100", "Price for !colorfultext command.");
	g_ConVar_NameColor = CreateConVar("sm_colorful_text_name_color", "darkblue", "Name color? (default - purple - lightblue - darkblue - green - lightgreen - olive - orchid - lime - yellow - orange - lightred - lightred2 - darkred - bluegrey - grey - grey2)");
	g_ConVar_TextColor = CreateConVar("sm_colorful_text_write_color", "lightred", "Write color? (default - purple - lightblue - darkblue - green - lightgreen - olive - orchid - lime - yellow - orange - lightred - lightred2 - darkred - bluegrey - grey - grey2)");
	g_ConVar_Sound = CreateConVar("sm_colorful_text_sound", "1", "Enable or Disable Blip Sound.");
	
	AutoExecConfig(true, "Colorful_Text"); 	
}

public void OnMapStart()
{
	PrecacheSound("ui/beepclear.wav");
}

public Action Colorful_Text(int client, int args)
{
	if(!g_ConVar_Credits.IntValue)
	{
		ReplyToCommand(client, " \x10This command is \x02disabled.");
		return Plugin_Handled;
	}
	if(!args)
	{
		ReplyToCommand(client, " \x10Usage: \x0e!colorful <message>");
		return Plugin_Handled;
	}
	if(Store_GetClientCredits(client) < g_ConVar_Credits.IntValue)
	{
		PrintToChat(client, " \x10You must atleast have \x0e%d \x0fcredits to use this command.", g_ConVar_Credits.IntValue);
		return Plugin_Handled;
	}
	char Message[256], szNameColor[16], szTextColor[16];
	g_ConVar_NameColor.GetString(szNameColor, sizeof(szNameColor));
	g_ConVar_TextColor.GetString(szTextColor, sizeof(szTextColor));	
	GetCmdArgString(Message, sizeof(Message));
	CPrintToChatAll("{%s}%N {default}: {%s}%s", szNameColor, client, szTextColor, Message);
	Store_SetClientCredits(client, Store_GetClientCredits(client) - g_ConVar_Credits.IntValue);
	if(g_ConVar_Sound.BoolValue)
		EmitSoundToAll("ui/beepclear.wav");
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{	
	if(StrContains(sArgs, "!colorfultext", false) == 0)
		return Plugin_Handled;
	return Plugin_Continue;
}