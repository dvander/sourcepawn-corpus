#include <sourcemod>  
#include <sdktools>

public Plugin myinfo =  
{  
    name = "CSS Change Name",  
    author = "SniperHero",  
    description = "Changes the name with !name",  
    version = "1.0",  
    url = ""  
};  

public OnPluginStart()  
{  
	RegConsoleCmd("sm_name", CMD_Name, "Changes Name");
}  

void ChangeTheName(int client, char[] newname)
{
	SetClientName(client, newname);
}

public Action CMD_Name(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_name [newname]");
		return Plugin_Handled;
	}

	decl String:name[192];
	GetCmdArgString(name, sizeof(name));
	
	ChangeTheName(client, name);
	
	
	return Plugin_Handled;
}