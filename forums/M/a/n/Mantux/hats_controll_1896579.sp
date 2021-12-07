public OnPluginStart() 
{ 
RegAdminCmd("sm_storeang",    CmdAng,            ADMFLAG_ROOT,    "Brings up a menu allowing you to adjust the hat angles (affects all hats/players)." ); 
RegAdminCmd("sm_storepos",    CmdPos,            ADMFLAG_ROOT,    "Brings up a menu allowing you to adjust the hat position (affects all hats/players)." );
} 



// ==================================================================================================== 
//                    sm_hatang 
// ==================================================================================================== 
public Action:CmdAng(client, args) 
{ 
    ShowAngMenu(client); 
    return Plugin_Handled; 
} 

ShowAngMenu(client) 
{ 
    if( !IsValidClient(client) ) 
    { 
        ReplyToCommand(client, "%sYou do not have access to this command!", CHAT_TAG); 
        return; 
    } 

    new Handle:menu = CreateMenu(AngMenuHandler); 

    AddMenuItem(menu, "", "X + 10.0"); 
    AddMenuItem(menu, "", "Y + 10.0"); 
    AddMenuItem(menu, "", "Z + 10.0"); 
    AddMenuItem(menu, "", ""); 
    AddMenuItem(menu, "", "X - 10.0"); 
    AddMenuItem(menu, "", "Y - 10.0"); 
    AddMenuItem(menu, "", "Z - 10.0"); 

    SetMenuTitle(menu, "Set hat angle."); 
    SetMenuExitButton(menu, true); 
    DisplayMenu(menu, client, MENU_TIME_FOREVER); 
} 

public AngMenuHandler(Handle:menu, MenuAction:action, client, index) 
{ 
    if( action == MenuAction_End ) 
        CloseHandle(menu); 
    if( action == MenuAction_Cancel ) 
    { 
        if( index == MenuCancel_ExitBack ) 
            ShowAngMenu(client); 
    } 
    else if( action == MenuAction_Select ) 
    { 
        if( IsValidClient(client) ) 
        { 
            ShowAngMenu(client); 

            new Float:vAng[3], ent; 
            for( new i = 1; i <= MaxClients; i++ ) 
            { 
                if( IsValidClient(i) ) 
                { 
                    ent = g_iHatIndex[i]; 
                    if( ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE ) 
                    { 
                        GetEntPropVector(ent, Prop_Send, "m_angRotation", vAng); 
                        if( index == 0 ) vAng[0] += 10.0; 
                        else if( index == 1 ) vAng[1] += 10.0; 
                        else if( index == 2 ) vAng[2] += 10.0; 
                        else if( index == 4 ) vAng[0] -= 10.0; 
                        else if( index == 5 ) vAng[1] -= 10.0; 
                        else if( index == 6 ) vAng[2] -= 10.0; 
                        TeleportEntity(ent, NULL_VECTOR, vAng, NULL_VECTOR); 
                    } 
                } 
            } 
            PrintToChat(client, "%sNew hat origin: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]); 
        } 
    } 
} 

// ==================================================================================================== 
//                    sm_hatpos 
// ==================================================================================================== 
public Action:CmdPos(client, args) 
{ 
    ShowPosMenu(client); 
    return Plugin_Handled; 
} 

ShowPosMenu(client) 
{ 
    if( !IsValidClient(client) ) 
    { 
        ReplyToCommand(client, "%sYou do not have access to this command!", CHAT_TAG); 
        return; 
    } 

    new Handle:menu = CreateMenu(PosMenuHandler); 

    AddMenuItem(menu, "", "X + 0.5"); 
    AddMenuItem(menu, "", "Y + 0.5"); 
    AddMenuItem(menu, "", "Z + 0.5"); 
    AddMenuItem(menu, "", ""); 
    AddMenuItem(menu, "", "X - 0.5"); 
    AddMenuItem(menu, "", "Y - 0.5"); 
    AddMenuItem(menu, "", "Z - 0.5"); 

    SetMenuTitle(menu, "Set hat position."); 
    SetMenuExitButton(menu, true); 
    DisplayMenu(menu, client, MENU_TIME_FOREVER); 
} 

public PosMenuHandler(Handle:menu, MenuAction:action, client, index) 
{ 
    if( action == MenuAction_End ) 
        CloseHandle(menu); 
    if( action == MenuAction_Cancel ) 
    { 
        if( index == MenuCancel_ExitBack ) 
            ShowPosMenu(client); 
    } 
    else if( action == MenuAction_Select ) 
    { 
        if( IsValidClient(client) ) 
        { 
            ShowPosMenu(client); 

            new Float:vPos[3], ent; 
            for( new i = 1; i <= MaxClients; i++ ) 
            { 
                if( IsValidClient(i) ) 
                { 
                    ent = g_iHatIndex[i]; 
                    if( ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE ) 
                    { 
                        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos); 
                        if( index == 0 ) vPos[0] += 0.5; 
                        else if( index == 1 ) vPos[1] += 0.5; 
                        else if( index == 2 ) vPos[2] += 0.5; 
                        else if( index == 4 ) vPos[0] -= 0.5; 
                        else if( index == 5 ) vPos[1] -= 0.5; 
                        else if( index == 6 ) vPos[2] -= 0.5; 
                        TeleportEntity(ent, vPos, NULL_VECTOR, NULL_VECTOR); 
                    } 
                } 
            } 
            PrintToChat(client, "%sNew hat origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]); 
        } 
    } 
}  