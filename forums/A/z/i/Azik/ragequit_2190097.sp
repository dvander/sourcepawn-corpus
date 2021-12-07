#include <sourcemod>
#include <colors>

new String:sPath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{	
	name = "Rage [CS:GO/S]",
	description = "Rage [CS:GO/S]",
	author = "Azik",
	version = "1.0",
	url = "www.balkanstar.fr"
};

public OnPluginStart()
{
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rage/ragequit.cfg");
	RegConsoleCmd("sm_rage", Command_Rage);
	LoadTranslations("ragequit.phrases");
}

public Action:Command_Rage(Client, args)
{ 
	
	new Handle:hKv = CreateKeyValues("Reasons");
	FileToKeyValues(hKv, sPath);
	
	if(!KvGotoFirstSubKey(hKv))
		return Plugin_Continue;
		
	new Handle:hMenu = CreateMenu(MenuHandler);
	SetMenuTitle(hMenu, "%t", "MENU_TITLE");
	  
	new String:Number[8];
	new String:Reason[64];

	do
	{
		KvGetSectionName(hKv, Number, sizeof(Number));    
		KvGetString(hKv, "reason", Reason, sizeof(Reason));
		AddMenuItem(hMenu, Number, Reason);    
		
	}while(KvGotoNextKey(hKv));
	CloseHandle(hKv);  
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;  
}

public MenuHandler(Handle:menu, MenuAction:action, Client, param1)
{
    if(action == MenuAction_Select)
    {             
        new Handle:hKv = CreateKeyValues("Reasons");   
        FileToKeyValues(hKv, sPath);
        
        if(!KvGotoFirstSubKey(hKv))
		    CloseHandle(menu);       

        new String:sBuffer[128];
        new String:sInfo[128];
        GetMenuItem(menu, param1, sInfo, sizeof(sInfo));     
        
        do
        {   
            KvGetSectionName(hKv, sBuffer, sizeof(sBuffer));
            if(StrEqual(sBuffer, sInfo))
            {
				new String:Reason[64];
				new String:Name[MAX_NAME_LENGTH];
				
				GetClientName(Client, Name, sizeof(Name));
				KvGetString(hKv, "reason", Reason, sizeof(Reason));
				KickClient(Client, Reason);
				CPrintToChatAll("%t", "RAGEQUIT_REASON", Name, Reason);
            }
        } while(KvGotoNextKey(hKv));
        CloseHandle(hKv);           
    }
    else if(action == MenuAction_End)
		CloseHandle(menu);
}

