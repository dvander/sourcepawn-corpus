#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SoupSpy!"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>
//#include <sdkhooks>

ConVar plugin_durum;

public Plugin myinfo = 
{
	name = "An AFK Plugin",
	author = PLUGIN_AUTHOR,
	description = "!afk & !unafk",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/vortexcss"
};

bool takim[66];

public void OnPluginStart()
{
    
    CreateConVar("soup_afk_version", PLUGIN_VERSION, "Plugin Versiyonu", FCVAR_NOTIFY);
    plugin_durum = CreateConVar("soup_afk_enable", "1", "0 = kapatır", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    
    RegConsoleCmd( "say", afk ); RegConsoleCmd( "say_team", afk );
    
}


public void OnClientDisconnect_Post(client)
{

	if (plugin_durum.BoolValue)
	{
		takim[client] = false;
	}

}

public Action afk(int client, int args)
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
           
           CPrintToChat(client, "{darkred}[VortéX] {white}To use this {red}you must be in a team");
           Plugin_Handled;
        } else {
        
        takim[client] = GetClientTeam(client);
        ChangeClientTeam(client, 1);
        CPrintToChat(client, "{darkred}[VortéX] {white}You are now {green}AFK!");
        CPrintToChatAll("{darkred}[VortéX] {orange}%s {white}is now {green}AFK.", isim);

        }
        
        }else
        if(StrEqual(yaz, "!unafk"))
        {
            if(GetClientTeam(client) != 1)
            {
                
                CPrintToChat(client, "{darkred}[VortéX] {white}To use this {green}you must be in the spectators team!");
                
            } else {
            
            if(takim[client]) {
            
                ChangeClientTeam(client, takim[client]);
                CPrintToChat(client, "{darkred}[VortéX] {white}You have returned to {green}your old team!");
                CPrintToChatAll("{darkred}[VortéX] {orange}%s {white}is no longer {red}AFK.", isim);
                
            } else {
           
                bool takimlar[7] = {2,3};
                bool random = GetRandomInt(0, 1);
                ChangeClientTeam(client, takimlar[random]);
                CPrintToChat(client, "{darkred}[VortéX] {white}You've moved to a random team!");     

            }
           }
        }
    }
}
