#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SoupSpy!"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

ConVar plugin_durum;

public Plugin myinfo = 
{
	name = "Afk Plugini",
	author = PLUGIN_AUTHOR,
	description = "!afk ve !unafk",
	version = PLUGIN_VERSION,
	url = ""
};

bool takim[66];

public void OnPluginStart()
{
    
    CreateConVar("soup_afk_versiyon", PLUGIN_VERSION, "Plugin Versiyonu", FCVAR_NOTIFY);
    plugin_durum = CreateConVar("soup_afk_aktif", "1", "0 = disabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    
    RegConsoleCmd( "say", afk ); RegConsoleCmd( "say_team", afk );
    
}


public void OnClientDisconnect_Post(client)
{

if (plugin_durum.BoolValue)
{
takim[client] = false;
}

}

public Action afk(client, args)
{
    if(plugin_durum.BoolValue)
    {
        char yaz[128];
        GetCmdArg(1, yaz,sizeof(yaz));
        StripQuotes(yaz);
        TrimString(yaz);
        
        char isim[32];
        GetClientName(client, isim, sizeof(isim));
        
        if(StrEqual(yaz, "!afk"))
        {
        if(GetClientTeam(client) == 1) {
           
           CPrintToChat(client, "{darkred}[VortéX] {red}You need to be in a team {white}to use this command!");
           return Plugin_Handled;
           
        } else {
            
            int hp = GetClientHealth(client);
            
            if(hp < 70 && IsPlayerAlive(client)) {
                CPrintToChat(client, "{darkred}[VortéX] {white}Your hp needs to be over {orange}70 {white}or you need to be {red}dead {white}to use this command.");
                return Plugin_Handled;
            }
        
        takim[client] = GetClientTeam(client);
        ChangeClientTeam(client, 1);
        CPrintToChat(client, "{darkred}[VortéX] {white}You are now {green}AFK.");
        CPrintToChatAll("{darkred}[VortéX] {orange}%s {white}is now {green}AFK.", isim);

        }
        
        }else
        if(StrEqual(yaz, "!unafk"))
        {
            if(GetClientTeam(client) != 1)
            {
                
           CPrintToChat(client, "{darkred}[VortéX] {red}You must be in the spectators team {white}to use this command!");
                return Plugin_Handled;
                
            } else {
            
            if(takim[client]) {
            
                ChangeClientTeam(client, takim[client]);
                CPrintToChat(client, "{darkred}[VortéX] {white}You've been returned to your {red}old team.");
                CPrintToChatAll("{darkred}[VortéX] {orange}%s {white}is {red}no longer AFK", isim);
                
            } else {
           
                int takimlar[7] = {2,3};
                int random = GetRandomInt(0, 1);
                ChangeClientTeam(client, takimlar[random]);
                CPrintToChat(client, "{darkred}[VortéX] {white}You've been moved to a random team.");     

            }
           }
        }
    }
    return Plugin_Continue;
}
