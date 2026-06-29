#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <menus>

#pragma semicolon 1

#define EFFECTSFILE                "unusuals_body.cfg"

new particle;
new particle2;
new particle3;
new particle4;
new particle5;
new particle6;
new particle7;
new particle8;
new particle9;
new particle10;
new particle11;
new particle12;
new particle13;
new particle14;
new particle15;
new String:effectArg[64];
new String:EffectsList[PLATFORM_MAX_PATH];

#define PLUGIN_VERSION      "1.00"

public Plugin:myinfo =
{
    name        = "Unusuals Players",
    author      = "Master Xykon",
    description = "Apply Custom Unusual Effects",
    version     = PLUGIN_VERSION
};

public OnPluginStart()
{
    CreateConVar("sm_unusual_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);

    RegConsoleCmd("sm_unusual_body_spawn", ApplyUnusual, "Become Unusual");
    RegConsoleCmd("sm_selfmade", ApplySelfMade, "Become Unusual");
    RegConsoleCmd("selfmade", ApplySelfMade, "Become Unusual");
    RegConsoleCmd("sm_sparkles", ApplySelfMade, "Become Unusual");
    RegConsoleCmd("sparkles", ApplySelfMade, "Become Unusual");
    RegConsoleCmd("sm_b_unusual", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_b_unusuals", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_ub", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_unusual_body_delete", DeleteParticle, "Remove Unusual");
    RegConsoleCmd("unusual_body_delete", DeleteParticle, "Remove Unusual");
    RegConsoleCmd("sm_ubd", DeleteParticle, "Remove Unusual");
}

public OnClientDisconnect(client)
{
    DeleteParticle(client, particle);
}

public Action:ApplySelfMade(client, args)
{
    CreateParticle(client, "community_sparkle", 300.0);
    
    PrintToChat(client, "[Self-Made] You've become Self-Made!");

    return Plugin_Handled;
}

public Action:ApplyUnusual(client, args)
{
    if(args == 1)
    {
        GetCmdArgString(effectArg, sizeof(effectArg));

        CreateParticle(client, effectArg, 300.0);
        
        PrintToChat(client, "[Unusual Player] You've become Unusual!");
        
        return Plugin_Handled;
    }

    PrintToConsole(client, "[Unusual Player] Usage: sm_unusual_spawn <effect_name>");
    
    return Plugin_Handled;
}

public Action:UnusualOff(client)
{
    DeleteParticle(client, particle);
    PrintToChat(client, "[Self-Made] Your effect wore off!");

    return Plugin_Handled;
}

stock Handle:CreateParticle(client, String:type[], Float:time)
{
    particle = CreateEntityByName("info_particle_system");
    particle2 = CreateEntityByName("info_particle_system");
    particle3 = CreateEntityByName("info_particle_system");
    particle4 = CreateEntityByName("info_particle_system");
    particle5 = CreateEntityByName("info_particle_system");
    particle6 = CreateEntityByName("info_particle_system");
    particle7 = CreateEntityByName("info_particle_system");
    particle8 = CreateEntityByName("info_particle_system");
    particle9 = CreateEntityByName("info_particle_system");
    particle10 = CreateEntityByName("info_particle_system");
    particle11 = CreateEntityByName("info_particle_system");
    particle12 = CreateEntityByName("info_particle_system");
    particle13 = CreateEntityByName("info_particle_system");
    particle14 = CreateEntityByName("info_particle_system");
    particle15 = CreateEntityByName("info_particle_system");


    if (IsValidEdict(particle) && IsValidEdict(particle2) && IsValidEdict(particle3) && IsValidEdict(particle4) && IsValidEdict(particle5) && IsValidEdict(particle6) && IsValidEdict(particle7) && IsValidEdict(particle8) && IsValidEdict(particle9) && IsValidEdict(particle10) && IsValidEdict(particle11) && IsValidEdict(particle12))
    {
        decl Float:pos[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);



        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", type);
        
        TeleportEntity(particle2, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle2, "effect_name", type);
        
        TeleportEntity(particle3, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle3, "effect_name", type);
        
        TeleportEntity(particle4, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle4, "effect_name", type);
        
        TeleportEntity(particle5, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle5, "effect_name", type);
        
        TeleportEntity(particle6, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle6, "effect_name", type);
        
        TeleportEntity(particle7, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle7, "effect_name", type);
        
        TeleportEntity(particle8, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle8, "effect_name", type);
        
        TeleportEntity(particle9, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle9, "effect_name", type);
        
        TeleportEntity(particle10, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle10, "effect_name", type);
        
        TeleportEntity(particle11, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle11, "effect_name", type);
        
        TeleportEntity(particle12, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle12, "effect_name", type);

        TeleportEntity(particle13, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle13, "effect_name", type);

        TeleportEntity(particle14, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle14, "effect_name", type);

        TeleportEntity(particle15, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle15, "effect_name", type);


        SetVariantString("!activator");
        AcceptEntityInput(particle, "SetParent", client, particle, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle2, "SetParent", client, particle2, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle3, "SetParent", client, particle3, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle3, "SetParent", client, particle3, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle4, "SetParent", client, particle4, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle5, "SetParent", client, particle5, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle6, "SetParent", client, particle6, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle7, "SetParent", client, particle7, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle8, "SetParent", client, particle8, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle9, "SetParent", client, particle9, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle10, "SetParent", client, particle10, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle11, "SetParent", client, particle11, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle12, "SetParent", client, particle12, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle13, "SetParent", client, particle13, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle14, "SetParent", client, particle14, 0);

        SetVariantString("!activator");
        AcceptEntityInput(particle15, "SetParent", client, particle15, 0);


        new String:t_Name[128];
        Format(t_Name, sizeof(t_Name), "target%i", client);


        SetVariantString("head");
        AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);

        DispatchKeyValue(particle, "targetname", t_Name);
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "Start");
        
        
        
        SetVariantString("flag");
        AcceptEntityInput(particle2, "SetParentAttachment", particle2, particle2, 0);

        DispatchKeyValue(particle2, "targetname", t_Name);
        DispatchSpawn(particle2);
        ActivateEntity(particle2);
        AcceptEntityInput(particle2, "Start");
        

        SetVariantString("weapon_bone_1");
        AcceptEntityInput(particle3, "SetParentAttachment", particle3, particle3, 0);

        DispatchKeyValue(particle3, "targetname", t_Name);
        DispatchSpawn(particle3);
        ActivateEntity(particle3);
        AcceptEntityInput(particle3, "Start");
        
        
        
        SetVariantString("handle_bone");
        AcceptEntityInput(particle4, "SetParentAttachment", particle4, particle4, 0);

        DispatchKeyValue(particle4, "targetname", t_Name);
        DispatchSpawn(particle4);
        ActivateEntity(particle4);
        AcceptEntityInput(particle4, "Start");
        

        
        
        SetVariantString("weapon_bone");
        AcceptEntityInput(particle5, "SetParentAttachment", particle5, particle5, 0);

        DispatchKeyValue(particle5, "targetname", t_Name);
        DispatchSpawn(particle5);
        ActivateEntity(particle5);
        AcceptEntityInput(particle5, "Start");
        
        
        
        SetVariantString("weapon_bone_L");
        AcceptEntityInput(particle6, "SetParentAttachment", particle6, particle6, 0);

        DispatchKeyValue(particle6, "targetname", t_Name);
        DispatchSpawn(particle6);
        ActivateEntity(particle6);
        AcceptEntityInput(particle6, "Start");
        
        
        
        SetVariantString("partyhat");
        AcceptEntityInput(particle7, "SetParentAttachment", particle7, particle7, 0);

        DispatchKeyValue(particle7, "targetname", t_Name);
        DispatchSpawn(particle7);
        ActivateEntity(particle7);
        AcceptEntityInput(particle7, "Start");
        
        
        
        SetVariantString("foot_L");
        AcceptEntityInput(particle8, "SetParentAttachment", particle8, particle8, 0);

        DispatchKeyValue(particle8, "targetname", t_Name);
        DispatchSpawn(particle8);
        ActivateEntity(particle8);
        AcceptEntityInput(particle8, "Start");
        
        
        
        SetVariantString("foot_R");
        AcceptEntityInput(particle9, "SetParentAttachment", particle9, particle9, 0);

        DispatchKeyValue(particle9, "targetname", t_Name);
        DispatchSpawn(particle9);
        ActivateEntity(particle9);
        AcceptEntityInput(particle9, "Start");
        
        
        
        SetVariantString("lefteye");
        AcceptEntityInput(particle10, "SetParentAttachment", particle10, particle10, 0);

        DispatchKeyValue(particle10, "targetname", t_Name);
        DispatchSpawn(particle10);
        ActivateEntity(particle10);
        AcceptEntityInput(particle10, "Start");
        
        
        
        SetVariantString("righteye");
        AcceptEntityInput(particle11, "SetParentAttachment", particle11, particle11, 0);

        DispatchKeyValue(particle11, "targetname", t_Name);
        DispatchSpawn(particle11);
        ActivateEntity(particle11);
        AcceptEntityInput(particle11, "Start");
        
        
        
        SetVariantString("eyes");
        AcceptEntityInput(particle12, "SetParentAttachment", particle12, particle12, 0);

        DispatchKeyValue(particle12, "targetname", t_Name);
        DispatchSpawn(particle12);
        ActivateEntity(particle12);
        AcceptEntityInput(particle12, "Start");



        SetVariantString("weapon_bone_2");
        AcceptEntityInput(particle13, "SetParentAttachment", particle13, particle13, 0);

        DispatchKeyValue(particle13, "targetname", t_Name);
        DispatchSpawn(particle13);
        ActivateEntity(particle13);
        AcceptEntityInput(particle13, "Start");



        SetVariantString("weapon_bone_3");
        AcceptEntityInput(particle14, "SetParentAttachment", particle14, particle14, 0);

        DispatchKeyValue(particle14, "targetname", t_Name);
        DispatchSpawn(particle14);
        ActivateEntity(particle14);
        AcceptEntityInput(particle14, "Start");



        SetVariantString("weapon_bone_4");
        AcceptEntityInput(particle15, "SetParentAttachment", particle15, particle15, 0);

        DispatchKeyValue(particle15, "targetname", t_Name);
        DispatchSpawn(particle15);
        ActivateEntity(particle15);
        AcceptEntityInput(particle15, "Start");
    }
    else
    {
        LogError("(CreateParticle): Could not create info_particle_system");
    }
    
    return INVALID_HANDLE;
}

public Action:DeleteParticle(client, any)
{
    if (IsValidEdict(particle))
    {
        while ((FindEntityByClassname(particle, "info_particle_system")) != -1)
        {
             RemoveEdict(particle);
             RemoveEdict(particle2);
             RemoveEdict(particle3);
             RemoveEdict(particle4);
             RemoveEdict(particle5);
             RemoveEdict(particle6);
             RemoveEdict(particle7);
             RemoveEdict(particle8);
             RemoveEdict(particle9);
             RemoveEdict(particle10);
             RemoveEdict(particle11);
             RemoveEdict(particle12);
             RemoveEdict(particle13);
             RemoveEdict(particle14);
        }
    }
}

public MenuHandler1(Handle:menu, MenuAction:action, iClient, param1)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        new String:info[32];
        GetMenuItem(menu, param1, info, sizeof(info));
        PrintToConsole(iClient, "[Self-Made] You selected effect: %d", info);
        FakeClientCommandEx(iClient, "sm_unusual_body_spawn %s", info);
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if (action == MenuAction_Cancel)
    {
        PrintToServer("Client's Unusual menu was cancelled.  Reason: %d", param1);
    }
    /* If the menu has ended, destroy it */
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

/*
public Action:UnusualMenu(client, args)
{
    new Handle:menu = CreateMenu(MenuHandler1);
    SetMenuTitle(menu, "Unusual Effects");
    AddMenuItem(menu, "none", "CANCEL");
    AddMenuItem(menu, "gabe", "Gabe");
    AddMenuItem(menu, "fluttershy", "Fluttershy");
    AddMenuItem(menu, "derpy", "Derpy");
    AddMenuItem(menu, "rd", "Rainbow Dash");
    AddMenuItem(menu, "unusual_cake", "Cake");
    AddMenuItem(menu, "unusual_energyball", "Energy Ball");
    AddMenuItem(menu, "unusual_fireball", "Fire Ball");
    AddMenuItem(menu, "unusual_health", "Health");
    AddMenuItem(menu, "unusual_jarate", "Jarate");
    AddMenuItem(menu, "unusual_knife", "Knife");
    AddMenuItem(menu, "superrare_circling_skull", "[Valve Unused] Circling Skull");
    AddMenuItem(menu, "unusual_storm_blood", "[Valve Unused] Blood Rain");
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 20);
 
    return Plugin_Handled;
}
*/

public Event_RemoveItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    DeleteParticle(iClient, particle);
}

public Action:UnusualMenu(client, args)
{
    new String:EffectID[128];
    new String:EffectName[128];
    new String:Line[255];
    new Len = 0, NameLen = 0, IDLen = 0;
    new i,j,data,count = 0;

    new Handle:h_UnusualMenu = CreateMenu(MenuHandler1);
    SetMenuTitle(h_UnusualMenu, "Custom Unusual effect :");
    
    new Handle:file = OpenFile(EffectsList, "rt");
    if (file == INVALID_HANDLE)
    {
        LogError("[Self-Made] Could not open file %s", EFFECTSFILE);
        CloseHandle(file);
        return Plugin_Handled;
    }

    while (!IsEndOfFile(file))
    {
        count++;
        ReadFileLine(file, Line, sizeof(Line));
        Len = strlen(Line);
        data = 0;
        TrimString(Line);
        if(Line[0] == '"')
        {
            for (i=0; i<Len; i++)
            {
                if (Line[i] == '"')
                {
                    i++;
                    data++;
                    j = i;
                    while(Line[j] != '"' && j < Len)
                    {
                        if(data == 1)
                        {
                            EffectName[j-i] = Line[j];
                            NameLen = j-i;
                        }
                        else
                        {
                            EffectID[j-i] = Line[j];
                            IDLen = j-i;
                        }
                        j++;
                    }
                    i = j;
                }    
            } 
        }
        if(data != 0 && j <= Len)
            AddMenuItem(h_UnusualMenu, EffectID, EffectName);
        else if(Line[0] != '*' && Line[0] != '/')
            LogError("[Self-Made] %s can't read line : %i ",EFFECTSFILE, count);
            
        for(i = 0; i <= NameLen; i++)
            EffectName[i] = '\0';
        for(i = 0; i <= IDLen; i++)
            EffectID[i] = '\0';
    }
    CloseHandle(file);

    SetMenuExitButton(h_UnusualMenu, true);
    DisplayMenu(h_UnusualMenu, client, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}