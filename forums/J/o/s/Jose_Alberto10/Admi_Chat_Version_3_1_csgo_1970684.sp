#include <sourcemod>
#include <cssclantags>
#include <cstrike>
#define DATA "v1.0"

new Handle:Tag = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Admin Chat in csgo",
    author = "Jose Alberto steam: tudo98",
    description = "<- Chat for Admin ->",
    version = DATA,
    url = "<- servers-cfg.foroactivo.com ->"
}
 
public OnPluginStart()
{
    RegConsoleCmd("say", SayHook);  
	CreateConVar("sm_chat_admin",DATA, "");
	Tag = CreateConVar("sm_tag", "ADMIN |", "tag for admin");
}      

public OnClientPostAdminCheck(client)
{      
    new AdminId:AdminID = GetUserAdmin(client);
    if(AdminID != INVALID_ADMIN_ID)
    {
	
        new String:tag_str[32];
        Format(tag_str, sizeof(tag_str), "%s", Tag);
        CS_SetClientClanTag(client, tag_str);
	}
}    
 public Action:SayHook(client, args)
 {
	
	new AdminId:AdminID = GetUserAdmin(client);
    if(AdminID == INVALID_ADMIN_ID)
		return Plugin_Continue;
	
	new String:Msg[256];
	new String:Name[MAX_NAME_LENGTH];
	GetClientName(client, Name, sizeof(Name));
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-1] = '\0';
	PrintToChatAll("\x04(ADMIN) \x06%s: \x04%s", Name, Msg[1]);
	
	return Plugin_Handled;
}