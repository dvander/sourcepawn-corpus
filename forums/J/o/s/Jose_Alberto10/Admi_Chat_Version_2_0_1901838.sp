#include <sourcemod>
#include <cssclantags>
#include <cstrike>


#define DATA "v1.0"
new Handle:Tag = INVALID_HANDLE;
new Handle:Color1 = INVALID_HANDLE;
new Handle:Color2 = INVALID_HANDLE;
new Handle:Color3 = INVALID_HANDLE;


public Plugin:myinfo =
{
    name = "Admin Chat",
    author = "Jose Alberto steam: tudo98",
    description = "<- Chat for Admin ->",
    version = DATA,
    url = "<- servers-cfg.foroactivo.com ->"
}
 
public OnPluginStart()
{
    RegConsoleCmd("say", SayHook);  
	CreateConVar("sm_chat_admin", "", "");
	Tag = CreateConVar("sm_tag", "ADMIN |", "tag for admin");
	Color1 = CreateConVar("sm_color1", "#01DF0", "selec color");
	Color2 = CreateConVar("sm_color2", "#FA58A", "selec color 2");
	Color3 = CreateConVar("sm_color3", "#FA58A", "selec color 3");
	AutoExecConfig(true, "Admin Chat by jose alberto");
	
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
		
	// string for mensagge chat and KeyHinText
	decl String:text[128];
	decl String:color2[128];
	decl String:color3[128];
	GetConVarString(Color1, text, sizeof(text));
	GetConVarString(Color2, color2, sizeof(color2));
	GetConVarString(Color3, color3, sizeof(color3));
	
	new String:Msg[256];
	new String:Name[MAX_NAME_LENGTH];
	GetClientName(client, Name, sizeof(Name));
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-1] = '\0';
	PrintToChatAll("\x07%s(ADMIN) \x07%s%s: \x07%s%s", text, color2, Name, color3, Msg[1]);
	
	return Plugin_Handled;
}