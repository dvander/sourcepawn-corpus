#pragma semicolon 1 

#include <sourcemod> 
#include <SteamWorks> 

#define PLUGIN_VERSION "1.0.0" 

public Plugin myinfo = { 
    name        = "Free2BeKicked - CS:GO", 
    author      = "Asher \"asherkin\" Baker, psychonic", 
    description = "Automatically kicks non-premium players.", 
    version     = PLUGIN_VERSION, 
    url         = "http://limetech.org/" 
}; 

public OnPluginStart() 
{ 
    CreateConVar("anti_f2p_version", PLUGIN_VERSION, "Free2BeKicked", FCVAR_DONTRECORD|FCVAR_NOTIFY); 
} 

public void OnClientPostAdminCheck(int client) 
{ 
if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true) || CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_GENERIC, true) || CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_RESERVATION, true)) 
    /*if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true))*/
    { 
        return; 
    } 
     
    if (k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820)) 
    { 
        KickClient(client, "Você precisa ter o jogo comprado ou level 21 para jogar em nossos servidores, desculpe :)"); 
        return; 
    } 
     
    return; 
}  