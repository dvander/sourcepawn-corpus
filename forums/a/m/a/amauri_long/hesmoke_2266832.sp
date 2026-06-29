#include <sourcemod>
#include <core>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <rpmlib>

public Plugin:myinfo =
{
    name = "hesmoke",
    description = "Provides every player on spawn with a Grenade",
    author = "AMAURI BUENO DOS SANTOS",
    version = "1.3",
    url = "http://www.bzm.96.lt/"
};

new Handle:g_Cvar_aeEnabled;

new hasNinja[MAXPLAYERS+1];
new bool:onninja[MAXPLAYERS+1];
new bool:canuse[MAXPLAYERS+1];

new Handle:cvar_quant = INVALID_HANDLE;
new Handle:cvar_cost = INVALID_HANDLE;
new Handle:cvar_shop = INVALID_HANDLE;

public OnPluginStart()
{
    g_Cvar_aeEnabled = CreateConVar("sm_hesmoke_enabled", "1", "Enable Auto Equip - 1=Enabled");
    cvar_quant = CreateConVar("sm_hesmoke_quant", "3", "Quantity of he or smoke a player will recieve during the round");
    HookEvent("player_spawn", Event_Playerspawn, EventHookMode:1);
    RegConsoleCmd("sm_f", faca);
    RegConsoleCmd("sm_smoke", smoke);
    RegConsoleCmd("sm_he", he);
    RegConsoleCmd("sm_hesmoke",Hhesmoke);
    
    for(new i = 1; i <= MaxClients; i++)
    {
        if(rpm_Check(i))
        {
            onninja[i] = false;
            canuse[i] = true;
            if(GetConVarInt(cvar_shop) == 0)
            {
                hasNinja[i] = GetConVarInt(cvar_quant);
            }
            else
            {
                hasNinja[i] = 0;
                rpm_PrintToChatTag(i, "HESMOKE", "Write !hesmoke or !he or !smoke Cost: %i", GetConVarInt(cvar_cost));
            }
        }
    }
}

public OnMapStart()
{
    AddFileToDownloadsTable("sound/admin_plugin/holyshit.wav");
    PrecacheSound("admin_plugin/holyshit.wav", true);
    AddFileToDownloadsTable("sound/admin_plugin/groovey.wav");
    PrecacheSound("admin_plugin/groovey.wav", true);
    AddFileToDownloadsTable("sound/admin_plugin/yeah.wav");
    PrecacheSound("admin_plugin/yeah.wav", true);
    AddFileToDownloadsTable("sound/admin_plugin/scream.wav");
    PrecacheSound("admin_plugin/scream.wav", true);
    return 0;
}

public Action:Event_Playerspawn(Handle:Event, String:name[], bool:dontbroadcast)
{
    if (GetConVarBool(g_Cvar_aeEnabled))
    {
        new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
        
        if (Client && IsClientInGame(Client))
        {
            CreateTimer(0.5, Timer_GiveWeapons, Client, 0);
        }
    }
    return Action:0;
}

public Action:Timer_GiveWeapons(Handle:Timer, any:client)
{
    GivePlayerItem(client, "item_assaultsuit", 0);
    for(new i = 1; i <= MaxClients; i++)
    {
        if(rpm_Check(i))
        {
            onninja[i] = false;
            canuse[i] = true;
            hasNinja[i] = GetConVarInt(cvar_quant);
        }
    }
}

public Action:faca(client, args)
{
    EmitSoundToAll("admin_plugin/scream.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
    PrintHintTextToAll("ZOMBIES COME stabbing \n press (U) keyboard and write !f or /f ", client);
    return Action:0;
}

public Action:smoke(client, args)
{
    
    if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
    {
        GivePlayerItem(client, "weapon_smokegrenade", 0);
        EmitSoundToAll("admin_plugin/groovey.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        hasNinja[client]--;
        PrintHintTextToAll("BUY SMOKE !smoke\n freezes the zombie bag!", client);
    }
    else
    {
        PrintHintTextToAll("I HAVE JUST A SMOKE!", client);
    }
    return Action:0;
}

public Action:he(client, args)
{
    
    if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
    {
        EmitSoundToAll("admin_plugin/yeah.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        GivePlayerItem(client, "weapon_hegrenade", 0);
        hasNinja[client]--;
        PrintHintTextToAll("BUY grenade !he\n set fire to the zombie!", client);
    }
    else
    {
        PrintHintTextToAll("OUT OF grenade!", client);
    }
    return Action:0;
}

public Action:Hhesmoke(client, args)
{
    
    if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
    {
        EmitSoundToAll("admin_plugin/yeah.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        GivePlayerItem(client, "weapon_hegrenade", 0);
        PrintHintTextToAll("GRANADA AND SMOKE SHOP !hesmoke\n puts fire in the zombie and freezes his ass. :D", client);
        GivePlayerItem(client, "weapon_smokegrenade", 0);
        hasNinja[client]--;
        hasNinja[client]--;
        EmitSoundToAll("admin_plugin/groovey.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
    }
    else
    {
        PrintHintTextToAll("I HAVE JUST GRENADE AND A SMOKE!", client);
    }
    return Action:0;
}