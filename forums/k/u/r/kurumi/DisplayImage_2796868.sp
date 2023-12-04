#include <sourcemod>

#define MAX_STRING_LEN 255

public Plugin myinfo =
{
	name			= "DisplayImage",
	author		= "kurumi",
	description = "Allow admins to display images.",
	version		= "1.0",
	url			= "https://github.com/tokKurumi"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_image", DisplayImage_Command, ADMFLAG_GENERIC, "Display image to players by url.");
	RegAdminCmd("sm_clearimage", AdminClearImage_Command, ADMFLAG_GENERIC, "Remove image from showing to players.");
	RegConsoleCmd("sm_climg", UserClearImage_commad, "Remove current image.");
}

public Action DisplayImage_Command(int client, int args)
{
	if (args < 2)
	{
		PrintToConsole(client, "Usage: sm_image <duration> <url>");
		return Plugin_Handled;
	}

	char durationString[MAX_STRING_LEN];
	GetCmdArg(1, durationString, sizeof(durationString));
	float duration = StringToFloat(durationString);

	char url[MAX_STRING_LEN];
	GetCmdArg(2, url, sizeof(url));

	char htmlElement[MAX_STRING_LEN + MAX_STRING_LEN];
	Format(htmlElement, sizeof(htmlElement), "<img width=\"500\" height=\"600\" src=\"https://%s\"> ", url);

	Event showImage = CreateEvent("cs_win_panel_round");
	showImage.SetString("funfact_token", htmlElement);

	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			showImage.FireToClient(i);
		}
	}

	CreateTimer(duration, clearImageAdmin);

	return Plugin_Handled;
}

public Action AdminClearImage_Command(int client, int args)
{
	CreateTimer(0.1, clearImageAdmin);

	return Plugin_Handled;
}

public Action UserClearImage_commad(int client, int args)
{
	Event clearImgUser = CreateEvent("cs_win_panel_round");
	clearImgUser.SetString("funfact_token", "");

	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		clearImgUser.FireToClient(client);
	}

	return Plugin_Handled;
}

public Action clearImageAdmin(Handle timer)
{
	Event clearImgAdmin = CreateEvent("cs_win_panel_round");
	clearImgAdmin.SetString("funfact_token", "");

	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			clearImgAdmin.FireToClient(i);
		}
	}
}