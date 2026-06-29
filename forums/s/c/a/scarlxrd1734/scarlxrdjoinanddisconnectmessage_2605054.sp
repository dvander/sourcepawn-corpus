/*                                 THAT IS MY FIRST PLUGIN                                           */
/*                        IF THERE IS ANY ERROR PLEASE CONTACT ME                                    */
/*                   IF YOU WANT DONATE ME ON PAYPAL OR SKINS OF GAMES IN STEAM                      */

#include <sourcemod>
#include <colors>

#define PLUGIN_NAME "Player connect and disconnect message"
#define PLUGIN_AUTHOR "SCARLXRD"
#define PLUGIN_DESCRIPTION "Chat message when players join or disconnect from the server"
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
name = PLUGIN_NAME,
author = PLUGIN_AUTHOR,
description = PLUGIN_DESCRIPTION,
version = PLUGIN_VERSION,
url = "",
};


public OnClientPutInServer(client)
{
decl String:name[128];

GetClientName(client, name, sizeof(name));
CPrintToChatAll("{red}• ➜ {default}Player: {green}%s", name);

}

public OnClientDisconnect(client)
{
decl String:name[128];

GetClientName(client, name, sizeof(name));

CPrintToChatAll("{red}• ➜ {default}O jogador {green}%s saiu do servidor.", name);
}