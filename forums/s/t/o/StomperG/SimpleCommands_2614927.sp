#include <sourcemod>
#include <sdktools>
#pragma newdecls required
 
public Plugin myinfo =
{
    name = "[HiddenGaming] Simple Commands",
    author = "StomperG",
    description = "This plugin do a simple commands.",
    version = "1.0.0",
    url = "http://hiddengaming.gq"
};
 
 
public void OnPluginStart()
{
    RegConsoleCmd("sm_grupo", Cmd_Group);
    RegConsoleCmd("sm_vip", Cmd_Vip);
    RegConsoleCmd("sm_discord", Cmd_Discord);
    RegConsoleCmd("sm_comandos", Cmd_Commands);
    RegConsoleCmd("sm_pinto", Cmd_Pinto);
    RegConsoleCmd("sm_fox", Cmd_Fox);
    RegConsoleCmd("sm_scorpion", Cmd_Scorpion);
    RegConsoleCmd("sm_stomper", Cmd_Stomper);
}
 
public Action Cmd_Group(int client, int args)
{
    PrintToChat(client, "»  \x08Entra no nosso grupo!: \x04https://steamcommunity.com/id/StomperG14twitch/");
}  
 
public Action Cmd_Vip(int client, int args)
{
    PrintToChat(client, "»  \x08Vê as vantagens vip!: \x04https://steamcommunity.com/groups/hiddengamingoficial/discussions/0/1738841319813317175/");
}
 
public Action Cmd_Discord(int client, int args)
{
    PrintToChat(client, "»  \x08Discord: \x04https://discord.gg/6vpM7A5");
}
 
public Action Cmd_Commands(int client, int args)
{
    PrintToChat(client, "»  \x08Os comandos são: \x04!stomper, !fox, !scorpion, !scorpion, !discord, !grupo, !vip");
}
 
public Action Cmd_Pinto(int client, int args)
{
    PrintToChat(client, "- Discord: KRG Pinto#7371");
    PrintToChat(client, "- Steam: https://steamcommunity.com/id/OfficialPinto/");
}
 
public Action Cmd_Fox(int client, int args)
{
    PrintToChat(client, "- Discord: The Fox#3624");
    PrintToChat(client, "- Steam: https://steamcommunity.com/id/thefox1904");
}
 
public Action Cmd_Scorpion(int client, int args)
{
    PrintToChat(client, "- Discord: ScorpioN#5365");
    PrintToChat(client, "- Steam: https://steamcommunity.com/id/imscorpion_1337");
}
 
public Action Cmd_Stomper(int client, int args)
{
    PrintToChat(client, "- Discord: Croassainte#2475");
    PrintToChat(client, "- Steam: https://steamcommunity.com/id/StomperG14twitch/");
}