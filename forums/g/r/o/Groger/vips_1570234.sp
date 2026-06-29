#include <sourcemod> 
#pragma semicolon 1 

new Handle:AdminListEnabled = INVALID_HANDLE; 
new Handle:AdminListMode = INVALID_HANDLE; 
new Handle:AdminListMenu = INVALID_HANDLE; 
new Handle:AdminListAdminFlag = INVALID_HANDLE; 

new bool:g_bHidden[MAXPLAYERS+1] = {false,...}; 

public Plugin:myinfo =  
{ 
    name = "Admin List", 
    author = "Fredd", 
    description = "prints admins to clients", 
    version = "1.3c", 
    url = "www.sourcemod.net" 
} 

public OnPluginStart() 
{ 
    CreateConVar("adminlist_version", "1.3c", "Admin List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
    AdminListEnabled = CreateConVar("adminlist_on", "1", "turns on and off admin list, 1=on ,0=off"); 
    AdminListMode = CreateConVar("adminlist_mode", "1", "mode that changes how the list appears.."); 
    AdminListAdminFlag = CreateConVar("adminlist_adminflag", "o", "vip flag to use for list. must be in char format"); // edited 
    RegConsoleCmd("sm_vips", Command_Vips, "Displays VIP to players"); // edited 
    RegAdminCmd("sm_vipon", Command_VipOn, ADMFLAG_GENERIC, "Show you on the public !vips list."); 
    RegAdminCmd("sm_vipoff", Command_VipOff, ADMFLAG_GENERIC, "Hide you from the public !vips list."); 
    AutoExecConfig(true, "plugin.viplist"); // edited 
} 

public OnClientDisconnect(client) 
{ 
    g_bHidden[client] = false; 
} 

public Action:Command_VipOff(client, args) 
{ 
    if(!client) 
    { 
        ReplyToCommand(client, "This is an ingame only command."); 
        return Plugin_Handled; 
    } 
    g_bHidden[client] = true; 
    ReplyToCommand(client, "\x04You're no longer shown on the !vips list."); 
    return Plugin_Handled; 
} 

public Action:Command_VipOn(client, args) 
{ 
    if(!client) 
    { 
        ReplyToCommand(client, "This is an ingame only command."); 
        return Plugin_Handled; 
    } 
    g_bHidden[client] = false; 
    ReplyToCommand(client, "\x04You will be shown on the !vips list again."); 
    return Plugin_Handled; 
} 

public Action:Command_Vips(client, args) 
{ 
    if (GetConVarBool(AdminListEnabled)) { 
        switch(GetConVarInt(AdminListMode)) { 
            case 1: 
            { 
                decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1]; 
                new count = 0; 
                for(new i = 1 ; i <= MaxClients;i++) { 
                    if(IsClientInGame(i) && !g_bHidden[i] && IsAdmin(i)) { 
                        GetClientName(i, AdminNames[count], sizeof(AdminNames[])); 
                        count++; 
                    }  
                } 
                decl String:buffer[1024]; 
                ImplodeStrings(AdminNames, count, ",", buffer, sizeof(buffer)); 
                PrintToChatAll("\x04VIPs online are: %s", buffer); // edited 
            } 
            case 2: 
            { 
                decl String:AdminName[MAX_NAME_LENGTH]; 
                AdminListMenu = CreateMenu(MenuListHandler); 
                SetMenuTitle(AdminListMenu, "VIPs Online:");    // edited                         
                for(new i = 1; i <= MaxClients; i++) { 
                    if(IsClientInGame(i) && !g_bHidden[i] && IsAdmin(i)) { 
                        GetClientName(i, AdminName, sizeof(AdminName)); 
                        AddMenuItem(AdminListMenu, AdminName, AdminName); 
                    }  
                } 
                SetMenuExitButton(AdminListMenu, true); 
                DisplayMenu(AdminListMenu, client, 15); 
            } 
        } 
    } 
    return Plugin_Handled; 
} 
public MenuListHandler(Handle:menu, MenuAction:action, param1, param2) 
{ 
    if (action == MenuAction_End) 
        CloseHandle(menu); 
} 

stock bool:IsAdmin(client) 
{ 
    decl String:flags[64]; 
    GetConVarString(AdminListAdminFlag, flags, sizeof(flags)); 
    new ibFlags = ReadFlagString(flags); 
    if ((GetUserFlagBits(client) & ibFlags) == ibFlags) 
        return true; 

        // not root flags 

    //if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
    //    return true; 

        // edited 

    return false; 
}  