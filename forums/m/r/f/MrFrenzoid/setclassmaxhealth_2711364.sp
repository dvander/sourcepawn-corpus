#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

// Plugin metadata.
public Plugin:myinfo =  
{  
    name = "[TF2] Set class max health",
    author = "MrFrenzoid",
    description = "Change default max health on each class, or all classed via additive health.",
    version = "5.0",                                                             
    url = "http://www.sourcemod.net/"
}; 

// Declaring cvars variables that we'll use to store the cvars values and use them later.
new Handle:g_cvHEnabled;
new Handle:g_cvHMode;
new Handle:g_cvHTeam;
new Handle:g_cvHIncrement;

new Handle:g_cvHSoldier;
new Handle:g_cvHPyro;
new Handle:g_cvHSpy;
new Handle:g_cvHDemoman;
new Handle:g_cvHSniper;
new Handle:g_cvHEngineer;
new Handle:g_cvHHeavy;
new Handle:g_cvHScout;
new Handle:g_cvHMedic;

// Executed when the plugins first launches.
public OnPluginStart()
{       
    // Creating cvars, and associating their value to each variable.
    g_cvHEnabled = CreateConVar("sm_mhenabled", "1", "Sets whether the plugin is enabled.");

    g_cvHMode = CreateConVar("sm_mhmode", "0", "Sets plugins mode, 0: sm_mhincrement = additive value to the default max health for each class for everyone, 1: Custom health value for each class from each ones cvar");
    g_cvHTeam = CreateConVar("sm_mhteam", "1", "0: apply to all teams, 1: Only RED, 2: Only Blue");

    g_cvHIncrement = CreateConVar("sm_mhincrement", "100", "Additive health added to everyone.");

    g_cvHSoldier = CreateConVar("sm_mhsoldier", "100", "Health to increase Soldiers max health");
    g_cvHPyro = CreateConVar("sm_mhpyro", "100", "Health to increase Pyros max health");
    g_cvHSpy = CreateConVar("sm_mhspy", "100", "Health to increase Spys  max health");
    g_cvHDemoman = CreateConVar("sm_mhdemoman", "100", "Health to increase Demomans max health");
    g_cvHSniper = CreateConVar("sm_mhsniper", "100", "Health to increase Sniers max health");
    g_cvHEngineer = CreateConVar("sm_mhengineer", "100", "Health to increase Engineers max health");
    g_cvHHeavy = CreateConVar("sm_mhheavy", "100", "Health to increase Heavys max health");
    g_cvHScout = CreateConVar("sm_mhscout", "100", "Health to increase Scouts max health");
    g_cvHMedic = CreateConVar("sm_mhmedic", "100", "Health to increase Medics max health");

    // Autogenerates a config file on cfg/sourcemod.
    AutoExecConfig(true, "setclassmaxhealth");

    // Hook an event, when the event "player_spawn" or "player_changeclass" triggers, call the function Event_UpdateMaxHp.
    HookEvent("player_spawn", Event_UpdateMaxHp);
}
 
// Executed when the player event "player_spawn" gets triggered.
public Action:Event_UpdateMaxHp(Handle:event, const String:name[], bool:dontBroadcast)
{
    // If the plugin is off, just continue.
    //  return plugin didn't change gameplay state.
    if (!GetConVarBool(g_cvHEnabled))
            return Plugin_Continue;

    // Get client's index number.
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Get players class and team.
    new TFClassType:PlayerClass = TF2_GetPlayerClass(client);
    new TFTeam:PlayerTeam = TFTeam:GetClientTeam(client);
    
    // If the player is from any other team that g_cvHTeam is setted to, dont do anything.
    //  Return plugin didn't change gameplay state.
    if ((GetConVarInt(g_cvHTeam) == 1 && PlayerTeam != TFTeam_Red) || (GetConVarInt(g_cvHTeam) == 2 && PlayerTeam != TFTeam_Blue))
        return Plugin_Continue;

    // Depending on the mode, set everyones max hp depending on g_cvHIncrement's value, or set each class specifically its own max health based on the cvars.
    // If mode is 0:
    if (!GetConVarBool(g_cvHMode))
    {
        // current max health + sm_mhincrement values.
        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHIncrement));
    }
    // If mode is 1:
    else
    {   // Depending on the player's class, set a different value for their max health.
        switch(PlayerClass)
        {
            case TFClass_Heavy:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHHeavy));
            }
            case TFClass_Soldier:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHSoldier));
            }
            case TFClass_Pyro:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHPyro));
            }
            case TFClass_Spy:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHSpy));
            }
            case TFClass_Sniper:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHSniper));
            }
            case TFClass_DemoMan:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHDemoman));
            }
            case TFClass_Scout:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHScout));
            }
            case TFClass_Engineer:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHEngineer));
            }
            case TFClass_Medic:
            {
		        TF2Attrib_SetByName(client, "max health additive bonus", GetConVarFloat(g_cvHMedic));
            }
        }
    }

    // Return plugin changed gameplay state.
    return Plugin_Changed;
}