#include <sourcemod>

new Handle:show = INVALID_HANDLE;
new Handle:g_Enable;
new Handle:text_color = INVALID_HANDLE;
new Handle:skype_color = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Show Admin skype",
	author = "ilga80",
	description = "Показ в чате скайпа главного админа.",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=212046"
}

public OnPluginStart()
{
	RegConsoleCmd("skype", skype);
	g_Enable = CreateConVar("sm_skype_enable", "1", "Включить/Отключить плагин", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	show = CreateConVar("sm_skype", "admin", "Ваш скайп");
	text_color = CreateConVar("text_color", "FFFF00", "Цвет текста");
	skype_color = CreateConVar("skype_color", "00FFFF", "Цвет скайпа");
	AutoExecConfig(true, "show_skype");
}

public Action:skype(client, args)
{
	if (GetConVarBool(g_Enable))
	{
		if (client > 0)
		{
			decl String:Skype[64];
			decl String:Text_color[128];
			decl String:Skype_color[32];
			GetConVarString(show, Skype, sizeof(Skype));
			GetConVarString(text_color, Text_color, sizeof(Text_color));
			GetConVarString(skype_color, Skype_color, sizeof(Skype_color));
			PrintToChat(client, "\x07%sSkype Главного админа: \x07%s %s", Text_color, Skype_color, Skype);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}