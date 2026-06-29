#include <sourcemod>
#include <scp>
#include <morecolors>

new String:player_tag[40] = "\x4[VIP]\x0";
new bool:have_tag[MAXPLAYERS+1] = false;

public Plugin:myinfo =
{
    name		=	"VIP tag ON/OFF",
    author		=	"Arkarr",
    description	=	"Display a simple tag before your name,",
    version		=	"1.0",
    url			=	"http://www.sourcemod.net"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_tagon", CMD_ActivateTag, "Activate the tag before your name");
	RegConsoleCmd("sm_tagoff", CMD_DeactivateTag, "Dectivate the tag before your name");
}

public Action:CMD_ActivateTag(client, args)
{
	if(have_tag[client])
	{
		CPrintToChat(client, "{green}[TAG]{default} You have alread your tag! Use !tagoff to disable it !");
		return Plugin_Handled;
	}
	
	have_tag[client] = true;
	CPrintToChat(client, "{green}[TAG]{default} Your tag is now enabled !");
	return Plugin_Handled;
}

public Action:CMD_DeactivateTag(client, args)
{
	if(!have_tag[client])
	{
		CPrintToChat(client, "{green}[TAG]{default} Your tag is already disabled ! Use !tagon to enable it !");
		return Plugin_Handled;
	}
	
	have_tag[client] = false;
	CPrintToChat(client, "{green}[TAG]{default} Your tag is now disabled !");
	return Plugin_Handled;
}

public Action:OnChatMessage(&author, Handle:recepients, String:name[], String:message[]) 
{
	if(have_tag[author])
	{
		Format(name, 100, "%s %s", player_tag, name);
	}
	return Plugin_Continue;
}