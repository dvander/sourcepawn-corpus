#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "PrivateMenuSay",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Implements private menu messages: sm_pmsay.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_pmsay_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_pmsay", Command_SmPMsay, ADMFLAG_CHAT, "sm_pmsay <target> <message> - sends message as a menu panel to one client");
	LoadTranslations("common.phrases");
}

public Action:Command_SmPMsay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pmsay <target> <message>");
		return Plugin_Handled;	
	}
	
	decl String:sTarget[192];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	new target = FindTarget(client, sTarget, true);
	
	if(target == -1)
		return Plugin_Handled;
	
	decl String:text[192];
	GetCmdArg(2, text, sizeof(text));

	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	
	decl String:title[100];
	Format(title, 64, "%s:", name);
	
	ReplaceString(text, 192, "\\n", "\n");
	
	new Handle:mSayPanel = CreatePanel();
	SetPanelTitle(mSayPanel, title);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(mSayPanel, text);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);

	if(IsClientInGame(target) && !IsFakeClient(target))
	{
		SendPanelToClient(mSayPanel, target, Handler_DoNothing, 10);
	}

	CloseHandle(mSayPanel);

	LogAction(client, target, "%L triggered sm_pmsay (text %s)", client, text);
	
	return Plugin_Handled;		
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}