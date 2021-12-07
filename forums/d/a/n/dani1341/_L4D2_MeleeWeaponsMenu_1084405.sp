#pragma semicolon 1 
#include <sourcemod> 
#include <sdktools>

#define PLUGIN_VERSION "1.0" 

#define DEBUG 0

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY

#define advertising IsClientInGame(client) && GetConVarInt(cvar_meleeannounce)

#define MODEL_BASEBALLBAT_W "models/weapons/melee/w_bat.mdl"
#define MODEL_BASEBALLBAT_V "models/weapons/melee/v_bat.mdl"
#define MODEL_CRICKETBAT_W "models/weapons/melee/w_cricket_bat.mdl"
#define MODEL_CRICKETBAT_V "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_CROWBAR_W "models/weapons/melee/w_crowbar.mdl"
#define MODEL_CROWBAR_V "models/weapons/melee/v_crowbar.mdl"
#define MODEL_ELECTRICGUITAR_W "models/weapons/melee/w_electric_guitar.mdl"
#define MODEL_ELECTRICGUITAR_V "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_FIREAXE_W "models/weapons/melee/w_fireaxe.mdl"
#define MODEL_FIREAXE_V "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_FRYINGPAN_W "models/weapons/melee/w_frying_pan.mdl"
#define MODEL_FRYINGPAN_V "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_GOLFCLUB_W "models/weapons/melee/w_golfclub.mdl"
#define MODEL_GOLFCLUB_V "models/weapons/melee/v_golfclub.mdl"
#define MODEL_KATANA_W "models/weapons/melee/w_katana.mdl"
#define MODEL_KATANA_V "models/weapons/melee/v_katana.mdl"
#define MODEL_KNIFE_W "models/w_models/weapons/w_knife_t.mdl"
#define MODEL_KNIFE_V "models/v_models/v_knife_t.mdl"
#define MODEL_MACHETE_W "models/weapons/melee/w_machete.mdl"
#define MODEL_MACHETE_V "models/weapons/melee/v_machete.mdl"
#define MODEL_TONFA_W "models/weapons/melee/w_tonfa.mdl"
#define MODEL_TONFA_V "models/weapons/melee/v_tonfa.mdl"
#define MODEL_RIOTSHIELD_W "models/weapons/melee/w_riotshield.mdl"
#define MODEL_RIOTSHIELD_V "models/weapons/melee/v_riotshield.mdl"

new Handle:cvar_maxweaponstotal = INVALID_HANDLE; 
new Handle:cvar_maxweaponsclient = INVALID_HANDLE; 
new Handle:cvar_meleeannounce = INVALID_HANDLE;
new numweaponstotal; 
new numweaponsclient[MAXPLAYERS + 1]; 

public Plugin:myinfo =  
{ 
    name = "[L4D2]MeleeWeponsMenu", 
    author = "dani1341", 
    description = "Allows Clients To Get Melee Weapons From The Melee Weapon Menu", 
    version = PLUGIN_VERSION, 
    url = "" 
}

public OnPluginStart() 
{ 
    //melee weapons menu cvar 
    RegConsoleCmd("sm_melee", MeleeMenu); 
    //plugin version 
    CreateConVar("melee_version", PLUGIN_VERSION, "L4D 2 Melee Weapons Menu version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 

    cvar_maxweaponstotal = CreateConVar("melee_max", "40", "How much times all players can get melee weapons per map", FCVAR_PLUGIN|FCVAR_NOTIFY); 
    cvar_maxweaponsclient = CreateConVar("melee_playermax", "10", "How much times one player can get melee weapons", FCVAR_PLUGIN|FCVAR_NOTIFY); 

    // Announce cvar
    cvar_meleeannounce = CreateConVar("melee_announce", "3", "Should the plugin advertise itself? 1 chat box message, 2 hint text message, 3 both, 0 for none.",CVAR_FLAGS,true,0.0,true,3.0);

    HookEvent("round_end", Event_RoundEnd); 
    //autoexec 
    AutoExecConfig(true, "l4d2_melee"); 
} 

public OnMapStart() 
{ 
    PrecacheModel(MODEL_BASEBALLBAT_W, true);
    PrecacheModel(MODEL_BASEBALLBAT_V, true);
    PrecacheModel(MODEL_CRICKETBAT_W, true);
    PrecacheModel(MODEL_CRICKETBAT_V, true);
    PrecacheModel(MODEL_CROWBAR_W, true);
    PrecacheModel(MODEL_CROWBAR_V, true);
    PrecacheModel(MODEL_ELECTRICGUITAR_W, true);
    PrecacheModel(MODEL_ELECTRICGUITAR_V, true);
    PrecacheModel(MODEL_FIREAXE_W, true);
    PrecacheModel(MODEL_FIREAXE_V, true);
    PrecacheModel(MODEL_FRYINGPAN_W, true);
    PrecacheModel(MODEL_FRYINGPAN_V, true);
    PrecacheModel(MODEL_GOLFCLUB_W, true);
    PrecacheModel(MODEL_GOLFCLUB_V, true);
    PrecacheModel(MODEL_KATANA_W, true);
    PrecacheModel(MODEL_KATANA_V, true);
    PrecacheModel(MODEL_GOLFCLUB_W, true);
    PrecacheModel(MODEL_GOLFCLUB_V, true);
    PrecacheModel(MODEL_KNIFE_W, true);
    PrecacheModel(MODEL_KNIFE_V, true);
    PrecacheModel(MODEL_MACHETE_W, true);
    PrecacheModel(MODEL_MACHETE_V, true);
    PrecacheModel(MODEL_TONFA_W, true);
    PrecacheModel(MODEL_TONFA_V, true);
    PrecacheModel(MODEL_RIOTSHIELD_W, true);
    PrecacheModel(MODEL_RIOTSHIELD_V, true);
        
    numweaponstotal = 0; 
    for(new i = 1; i <= MAXPLAYERS; i++) 
        numweaponsclient[i] = 0; 
} 

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    numweaponstotal = 0; 
    for(new i = 1; i <= MAXPLAYERS; i++) 
        numweaponsclient[i] = 0; 
} 

public OnClientPostAdminCheck(client) 
{ 
    for(new i = 1; i <= MAXPLAYERS; i++) 
        numweaponsclient[i] = 0; 
} 

public OnClientPutInServer(client)
{
    if (client)
    {
        if (GetConVarBool(cvar_meleeannounce))
            CreateTimer(30.0, AnnounceMelee, client);
    }
}

public Action:MeleeMenu(client,args) 
{ 
    if(!client || !IsClientInGame(client))  
        return Plugin_Handled; 

    if(GetClientTeam(client) != 2) 
    { 
        PrintToChat(client, "Melee Weapons Menu is only available to survivors."); 
        return Plugin_Handled; 
    } 

    if(numweaponstotal >= GetConVarInt(cvar_maxweaponstotal))  
    { 
        PrintToChat(client, "Limit of %i total melee weapons for this map has been reached.", GetConVarInt(cvar_maxweaponstotal)); 
        return Plugin_Handled; 
    } 

    if(numweaponsclient[client] >= GetConVarInt(cvar_maxweaponsclient))  
    { 
        PrintToChat(client, "You have reached your limit of %i for this map.", GetConVarInt(cvar_maxweaponsclient)); 
        return Plugin_Handled; 
    } 

    Melee(client); 

    return Plugin_Handled; 
} 

public Action:Melee(clientId) 
{ 
    new Handle:menu = CreateMenu(MeleeMenuHandler); 
    SetMenuTitle(menu, "Melee Weapons Menu"); 
    AddMenuItem(menu, "option1", "Baseball Bat"); 
    AddMenuItem(menu, "option2", "Crowbar"); 
    AddMenuItem(menu, "option3", "Cricket Bat"); 
    AddMenuItem(menu, "option4", "Electric Guitar"); 
    AddMenuItem(menu, "option5", "Fire Axe"); 
    AddMenuItem(menu, "option6", "Frying Pan"); 
    AddMenuItem(menu, "option7", "Golf Club"); 
    AddMenuItem(menu, "option8", "Katana"); 
    AddMenuItem(menu, "option9", "Knife"); 
    AddMenuItem(menu, "option10", "Machete"); 
    AddMenuItem(menu, "option11", "Magnum"); 
    AddMenuItem(menu, "option12", "Night Stick"); 
    AddMenuItem(menu, "option13", "Pistol"); 
    AddMenuItem(menu, "option14", "Riot Shield"); 
    SetMenuExitButton(menu, true); 
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER); 

    return Plugin_Handled; 
} 

public Action:AnnounceMelee(Handle:timer, any:client)
{
    if(advertising == 3)
    {
        PrintToChatAll("[SM] If you want a melee weapon write !melee or /melee in chat");
        PrintHintTextToAll("If you want a melee weapon write !melee or /melee in chat");
    }
    else if(advertising == 2)
    {
        PrintHintTextToAll("If you want a melee weapon write !melee or /melee in chat");
    }
    else if(advertising == 1)
    {
        PrintToChatAll("[SM] If you want a melee weapon write !melee or /melee in chat");
    }
}

public MeleeMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{ 
    //Strip the CHEAT flag off of the "give" command 
    new flags = GetCommandFlags("give"); 
    SetCommandFlags("give", flags & ~FCVAR_CHEAT); 

    if ( action == MenuAction_Select ) { 

        switch (itemNum) 
        { 
            case 0: //Baseball Bat 
            { 
                //Give the player a Baseball Bat 
                FakeClientCommand(client, "give baseballbat"); 
            } 
            case 1: //Crowbar 
            { 
                //Give the player a Crowbar 
                FakeClientCommand(client, "give crowbar"); 
            } 
            case 2: //Cricket Bat 
            { 
                //Give the player a Cricket Bat 
                FakeClientCommand(client, "give cricket_bat"); 
            } 
            case 3: //Electric Guitar 
            { 
                //Give the player a Electric Guitar 
                FakeClientCommand(client, "give electric_guitar"); 
            } 
            case 4: //Fire Axe 
            { 
                //Give the player a Fire Axe 
                FakeClientCommand(client, "give fireaxe"); 
            } 
            case 5: //Frying Pan 
            { 
                //Give the player a Frying Pan 
                FakeClientCommand(client, "give frying_pan"); 
            } 
            case 6: //Golf Club 
            { 
                //Give the player a Golf Club 
                FakeClientCommand(client, "give golfclub"); 
            } 
            case 7: //Katana 
            { 
                //Give the player a Katana 
                FakeClientCommand(client, "give katana"); 
            } 
            case 8: //Knife 
            { 
                //Give the player a Knife 
                FakeClientCommand(client, "give hunting_knife"); 
            } 
            case 9: //Machete 
            { 
                //Give the player a Machete 
                FakeClientCommand(client, "give machete"); 
            } 
            case 10: //Magnum 
            { 
                //Give the player a Magnum 
                FakeClientCommand(client, "give pistol_magnum"); 
            } 
            case 11: //Night Stick 
            { 
                //Give the player a Night Stick 
                FakeClientCommand(client, "give tonfa"); 
            } 
            case 12: //Pistol 
            { 
                //Give the player a Pistol 
                FakeClientCommand(client, "give pistol"); 
            } 
            case 13: //Riot Shield 
            { 
                //Give the player a Riot Shield 
                FakeClientCommand(client, "give riotshield"); 
            } 
        } 
        numweaponstotal++; 
        numweaponsclient[client]++; 
    } 

    //Add the CHEAT flag back to "give" command 
    SetCommandFlags("give", flags|FCVAR_CHEAT); 
}  