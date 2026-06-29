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
	name = "Afk Plugini",
	author = PLUGIN_AUTHOR,
	description = "!afk ve !unafk",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/vortexcss"
};

bool takim[66];

public void OnPluginStart()
{
    
    CreateConVar("soup_afk_versiyon", PLUGIN_VERSION, "Plugin Versiyonu", FCVAR_NOTIFY);
    plugin_durum = CreateConVar("soup_afk_aktif", "1", "0 = kapatır", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    
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
           
           CPrintToChat(client, "{darkred}[VortéX] {white}Bu komutu kullanabilmek için {red}bir takımda olman gerekmekte!");
           Plugin_Handled;
        } else {
        
        takim[client] = GetClientTeam(client);
        ChangeClientTeam(client, 1);
        CPrintToChat(client, "{darkred}[VortéX] {white}Başarıyla {green}AFK oldun!");
        CPrintToChatAll("{darkred}[VortéX] {orange}%s {white}kişisi {green}AFK oldu.", isim);

        }
        
        }else
        if(StrEqual(yaz, "!unafk"))
        {
            if(GetClientTeam(client) != 1)
            {
                
                CPrintToChat(client, "{darkred}[VortéX] {white}Bunu yapabilmek için {green}İzleyicide olman gerek!");
                
            } else {
            
            if(takim[client]) {
      
                ChangeClientTeam(client, takim[client]);
                CPrintToChat(client, "{darkred}[VortéX] {white}Başarıyla {green}eski takımına {white}geri dönderildin!");
                CPrintToChatAll("{darkred}[VortéX] {orange}%s {white}kişisi artık {red}AFK değil.", isim);
                
            } else {
           
                bool takimlar[7] = {2,3};
                bool random = GetRandomInt(0, 1);
                ChangeClientTeam(client, takimlar[random]);
                CPrintToChat(client, "{darkred}[VortéX] {white}Rastgele bir takıma atandın!");     

            }
           }
        }
    }
}
