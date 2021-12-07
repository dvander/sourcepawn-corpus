#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#pragma semicolon 1
 
#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_NAME "Knife Upgrade"
#define CS_TEAM_SPECTATOR 1
 
new Handle:g_cookieKnife;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hSpawnMessage = INVALID_HANDLE;
new Handle:g_hSpawnMenu = INVALID_HANDLE;
new Handle:g_hWelcomeMessage = INVALID_HANDLE;
new Handle:g_hWelcomeMenu = INVALID_HANDLE;
new Handle:g_hWelcomeMessageTimer = INVALID_HANDLE;
new Handle:g_hWelcomeMenuTimer = INVALID_HANDLE;
new Handle:g_hKnifeChosenMessage = INVALID_HANDLE;
//new Handle:g_hNoKnifeMapDisable = INVALID_HANDLE;
new Handle:g_hNeedsAccess = INVALID_HANDLE;
new Handle:g_hEnableGoldKnife = INVALID_HANDLE;
 
new knife_choice[MAXPLAYERS+1];
 
public Plugin:myinfo =
{
        name = PLUGIN_NAME,
        author = "Klexen",
        description = "Choose and a save custom knife skin for this server.",
        version = PLUGIN_VERSION
}
 
public OnPluginStart()
{
       
        CreateConVar("sm_knifeupgrade_version", PLUGIN_VERSION, "Knife Upgrade Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
        g_hEnabled = CreateConVar("sm_knifeupgrade_on", "1", "Enable / Disable Plugin", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hSpawnMessage = CreateConVar("sm_knifeupgrade_spawn_message", "0", "Show Plugin Message on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hSpawnMenu = CreateConVar("sm_knifeupgrade_spawn_menu", "0", "Show Knife Menu on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hWelcomeMessage = CreateConVar("sm_knifeupgrade_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hWelcomeMessageTimer = CreateConVar("sm_knifeupgrade_welcome_message_timer", "12.0", "When (in seconds) the message should be displayed after the player joins the server.", FCVAR_NONE, true, 12.0, true, 90.0);
        g_hWelcomeMenuTimer = CreateConVar("sm_knifeupgrade_welcome_menu_timer", "15.0", "When (in seconds) the knife menu should be displayed after the player joins the server.", FCVAR_NONE, true, 12.0, true, 90.0);
        g_hWelcomeMenu = CreateConVar("sm_knifeupgrade_welcome_menu", "0", "Show Knife Menu on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hKnifeChosenMessage = CreateConVar("sm_knifeupgrade_chosen_message", "1", "Show message to player when player chooses a knife.", FCVAR_NONE, true, 0.0, true, 1.0);
        //g_hNoKnifeMapDisable = CreateConVar("sm_knifeupgrade_map_disable", "0", "Set to 1 to disable knife on maps not meant to have knives", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hNeedsAccess = CreateConVar("sm_knifeupgrade_needs_access", "0", "Set to 1 to if you want to Restrict access. (Access Requires 'a' flag.)", FCVAR_NONE, true, 0.0, true, 1.0);
        g_hEnableGoldKnife = CreateConVar("sm_knifeupgrade_gold_knife", "0", "Enable / Disable Golden Knife", FCVAR_NONE, true, 0.0, true, 1.0);
       
        g_cookieKnife = RegClientCookie("knife_choice", "", CookieAccess_Private);
       
        AutoExecConfig(true, "sm_knifeupgrade");
 
        AddCommandListener(Event_Say, "say");
        AddCommandListener(Event_Say, "say_team");
        HookEvent("player_spawn", PlayerSpawn);
       
        for (new i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
                        OnClientCookiesCached(i);
                }
        }
}
 
public OnClientCookiesCached(client)
{
        decl String:value[12];
        GetClientCookie(client, g_cookieKnife, value, sizeof(value));
        knife_choice[client] = StringToInt(value);
}
 
public Action:Event_Say(clientIndex, const String:command[], arg)
{
        if (clientIndex != 0 && GetConVarBool(g_hEnabled))
        {
                decl String:text[24];
                GetCmdArgString(text, sizeof(text));
                StripQuotes(text);
                TrimString(text);
               
                if (StrEqual(text, "!knife", false) || StrEqual(text, "!knief", false) || StrEqual(text, "!knifes", false) || StrEqual(text, "!knfie", false) || StrEqual(text, "!knfie", false) || StrEqual(text, "!knifw", false) || StrEqual(text, "!knives", false) || StrEqual(text, "!knives", false) || StrEqual(text, "!knif", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                KnifeMenu(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
               
                //Knife Shortcut Triggers
                //Bayonet
                if (StrEqual(text, "!bayonet", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetBayonet(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Gut
                if (StrEqual(text, "!gut", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetGut(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Flip
                if (StrEqual(text, "!flip", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetFlip(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //M9
                if (StrEqual(text, "!m9", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetM9(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Karambit
                if (StrEqual(text, "!karambit", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetKarambit(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Huntsman
                if (StrEqual(text, "!huntsman", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetHuntsman(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Butterfly
                if (StrEqual(text, "!butterfly", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetButterfly(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Default
                if (StrEqual(text, "!default", false))
                {
                        if (IsValidClient(clientIndex))
                        {
                                SetDefault(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
                //Golden Knife
                if (StrEqual(text, "!golden", false))
                {
                        if (IsValidClient(clientIndex) && GetConVarBool(g_hEnableGoldKnife))
                        {
                                SetGolden(clientIndex);
                        } else {PrintToChat(clientIndex, " \x07You do not have access to this command.");}
                        return Plugin_Handled;
                }
        }
        return Plugin_Continue;
}
 
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
       
        if(!IsValidClient(client)) return;
       
        CreateTimer(0.3, OnSpawn, client);
}
 
public Action:OnSpawn(Handle:timer, any:client)
{
        Equipknife(client);
       
        if (GetConVarBool(g_hSpawnMessage))
        {
                PrintToChat(client, "Type \x04!knife \x01or \x07chat triggers \x01to select a new knife skin.");
                if (GetConVarBool(g_hEnableGoldKnife))
                {
                        PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !golden !default");
                } else {PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !default");}
        }
        if (GetConVarBool(g_hSpawnMenu)) KnifeMenu(client);
       
}
 
Equipknife(client)
{      
        if(!IsValidClient(client) || !GetConVarBool(g_hEnabled) || !IsPlayerAlive(client)) return;
       
        new iWeapon = GetPlayerWeaponSlot(client, 2);
        if(iWeapon != INVALID_ENT_REFERENCE) //If player already have a knife, remove it.
        {
                RemovePlayerItem(client, iWeapon);
                AcceptEntityInput(iWeapon, "Kill");
        }
       
        if (knife_choice[client] < 1) knife_choice[client] = 8;
       
        new iItem;
        switch(knife_choice[client]) {
                case 1:{iItem = GivePlayerItem(client, "weapon_bayonet");}
                case 2:{iItem = GivePlayerItem(client, "weapon_knife_gut");}
                case 3:{iItem = GivePlayerItem(client, "weapon_knife_flip");}
                case 4:{iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");}
                case 5:{iItem = GivePlayerItem(client, "weapon_knife_karambit");}
                case 6:{iItem = GivePlayerItem(client, "weapon_knife_tactical");}
                case 7:{iItem = GivePlayerItem(client, "weapon_knife_butterfly");}
                case 8:{iItem = GivePlayerItem(client, "weapon_knife");}
                case 9:
                {
                        if (GetConVarBool(g_hEnableGoldKnife))
                        {
                                iItem = GivePlayerItem(client, "weapon_knifegg");
                        } else {iItem = GivePlayerItem(client, "weapon_knife");}
                       
                }
                default: {return;}
        }
        if (iItem > 0 && IsValidClient(client) && IsPlayerAlive(client)) EquipPlayerWeapon(client, iItem);
        else {return;}
 
}
 
public OnClientPostAdminCheck(client)
{
        new Float:WelcomeMessageTimer = GetConVarFloat(g_hWelcomeMessageTimer);
        new Float:WelcomeMenuTimer = GetConVarFloat(g_hWelcomeMenuTimer);
 
        if (GetConVarBool(g_hWelcomeMessage) && GetConVarBool(g_hWelcomeMenu))
        {
                if (WelcomeMessageTimer == WelcomeMenuTimer)
                {
                        WelcomeMessageTimer += 1.0;
                        WelcomeMenuTimer -= 1.0;
                }
        }
       
        if (IsValidClient(client))
        {
                if (GetConVarBool(g_hWelcomeMessage)) CreateTimer(WelcomeMessageTimer, Timer_Welcome_Message, client);
                if (GetConVarBool(g_hWelcomeMenu)) CreateTimer(WelcomeMenuTimer, Timer_Welcome_Menu, client);
        }
}
 
public Action:Timer_Welcome_Message(Handle:timer, any:client)
{
        if (GetConVarBool(g_hWelcomeMessage) && IsValidClient(client))
        {
                PrintToChat(client, "Type \x04!knife \x01or \x07chat triggers \x01to select a new knife skin.");
                if (GetConVarBool(g_hEnableGoldKnife))
                {
                        PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !golden !default");
                } else {PrintToChat(client, "Triggers: \x07!bayonet !gut !flip !m9 !karambit !huntsman !butterfly !default");}
        }              
}
 
public Action:Timer_Welcome_Menu(Handle:timer, any:client)
{
        if (GetConVarBool(g_hWelcomeMenu) && IsValidClient(client)) KnifeMenu(client);
}
 
KnifeMenu(client)
{
        if(!IsValidClient(client)) return;
        DID(client);
        PrintToConsole(client, "Knife Menu is open");
}
 
SetBayonet(client)
{
        knife_choice[client] = 1;
        new String:knifeValue[] = "1";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Bayonet!");
}
 
SetGut(client)
{
        knife_choice[client] = 2;
        new String:knifeValue[] = "2";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Gut knife!");
}
 
SetFlip(client)
{
        knife_choice[client] = 3;
        new String:knifeValue[] = "3";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);                 
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Flip knife!");
}
 
SetM9(client)
{
        knife_choice[client] = 4;
        new String:knifeValue[] = "4";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the M9-Bayonet!");
}
 
SetKarambit(client)
{
        knife_choice[client] = 5;
        new String:knifeValue[] = "5";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Karambit!");
}
 
SetHuntsman(client)
{
        knife_choice[client] = 6;
        new String:knifeValue[] = "6";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client); 
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Huntsman knife!");
}
 
SetButterfly(client)
{
        knife_choice[client] = 7;
        new String:knifeValue[] = "7";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Butterfly knife!");
}
 
SetDefault(client)
{
        knife_choice[client] = 8;
        new String:knifeValue[] = "8";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Default knife!");
}
 
SetGolden(client)
{
        knife_choice[client] = 9;
        new String:knifeValue[] = "9";                         
        SetClientCookie(client, g_cookieKnife, knifeValue);
        OnClientCookiesCached(client);
        Equipknife(client);    
        if (GetConVarBool(g_hKnifeChosenMessage)) PrintToChat(client, " \x04You have chosen the Golden knife!");
}
 
public Action:DID(clientId)
{
        new Handle:menu = CreateMenu(DIDMenuHandler);
        SetMenuTitle(menu, "Choose your knife");
        AddMenuItem(menu, "option2", "!Bayonet");
        AddMenuItem(menu, "option3", "!Gut");
        AddMenuItem(menu, "option4", "!Flip");
        AddMenuItem(menu, "option5", "!M9");
        AddMenuItem(menu, "option6", "!Karambit");
        AddMenuItem(menu, "option7", "!Huntsman");
        AddMenuItem(menu, "option8", "!Butterfly");
        AddMenuItem(menu, "option9", "!Default");
        if (GetConVarBool(g_hEnableGoldKnife)) AddMenuItem(menu, "option10", "!Golden");
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, clientId, 0);
        return Plugin_Handled;
}
 
public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
        if ( action == MenuAction_Select )
        {
                new String:info[32];
                GetMenuItem(menu, itemNum, info, sizeof(info));
                //Bayonet
                if ( strcmp(info,"option2") == 0 ) {SetBayonet(client);}
                //Gut
                else if ( strcmp(info,"option3") == 0 ) {SetGut(client);}      
                //Flip
                else if ( strcmp(info,"option4") == 0 ) {SetFlip(client);}
                //M9-Bayonet
                else if ( strcmp(info,"option5") == 0 ) {SetM9(client);}
                //Karambit
                else if ( strcmp(info,"option6") == 0 ) {SetKarambit(client);}
                //Huntsman
                else if ( strcmp(info,"option7") == 0 ) {SetHuntsman(client);}
                //Butterfly
                else if ( strcmp(info,"option8") == 0 ) {SetButterfly(client);}
                //Default
                else if ( strcmp(info,"option9") == 0 ) {SetDefault(client);}
                //Golden
                else if ( strcmp(info,"option10") == 0 ) {SetGolden(client);}
        }
        else if (action == MenuAction_End) {CloseHandle(menu);}
}
 
bool:IsValidClient(client)
{
        if (!(client >= 1 && client <= MaxClients)) return false;  
        if (!IsClientConnected(client) || !IsClientInGame(client)) return false;
        if (IsFakeClient(client)) return false;
        if (!CheckCommandAccess(client, "sm_knifeupgrade", ADMFLAG_RESERVATION, true) && GetConVarBool(g_hNeedsAccess)) return false;
        return true;
}