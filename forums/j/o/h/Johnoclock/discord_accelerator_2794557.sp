#include <sourcemod>
#include <discord>
#include <files>

// The code formatting rules we wish to follow
#pragma semicolon 1
#pragma newdecls required

ConVar g_hWebhook;

char g_sWebhook[255];
char path[128];
char path2[128];
char sCrashID[64];
char sStoredCrashID[15];

Handle Hlogs;
Handle Hdata;

int index;

public Plugin myinfo = 
{
    name = "Discord Accelerator",
    author = "johnoclock",
    description = "Sends discord message when server crashed.",
    version = "1.1",
    url = ""
}

public void OnPluginStart()
{
    RegPluginLibrary("discord-api");

    g_hWebhook = CreateConVar("discord_webhook_crashlogger", "", "yourewebhook", FCVAR_PROTECTED);

    GetConVarString(g_hWebhook, g_sWebhook, 255);

    BuildPath(Path_SM, path, sizeof(path), "/logs/accelerator.log");
    BuildPath(Path_SM, path2, sizeof(path2), "/data/Stored_data.txt");

    Hlogs = OpenFile(path, "r", false);
    Hdata = OpenFile(path2, "a+", false);

    AutoExecConfig(true, "Discord_Accelerator");

}

public void OnConfigsExecuted()
{

    //Get last Crash id after restart
    if (!Hlogs)
    return;

    FileSeek(Hlogs, -sizeof(sCrashID), SEEK_END);
    ReadFileString(Hlogs, sCrashID, sizeof(sCrashID));
    index = StrContains(sCrashID, "Crash ID: ");
    sCrashID[index + 10 + 14] = '\0';

    if(index == -1)
    return;

    ReplaceString(sCrashID[index], sizeof(sCrashID), "Crash ID: ", "", false);
    TrimString(sCrashID[index]);

    char sLine[128];
    while(!IsEndOfFile(Hdata) && ReadFileLine(Hdata, sLine, sizeof(sLine)))
    {
        //Get Stored Crash id after restart 
        if (!Hdata)
        return;

        ReadFileLine(Hdata, sStoredCrashID, sizeof(sStoredCrashID));
    }

    PrintToServer("sStoredCrashID = %s and sCrashID = %s", sStoredCrashID, sCrashID[index]);

    if(!StrEqual(sStoredCrashID, sCrashID[index]))
    {

        PrintToServer("we sendt something to discord");
        PrintToDiscord();
    }
}

public void PrintToDiscord()
{
        char sLink[128];
        char sHostname[64];

        ConVar cvHostname = FindConVar("hostname");
        GetConVarString(cvHostname, sHostname, sizeof(sHostname));


        Format(sLink, sizeof(sLink), "[Click here](https://crash.limetech.org/?id=%s)", sCrashID[index]);

        DiscordWebHook hook = new DiscordWebHook(g_sWebhook);
        
        MessageEmbed Embed = new MessageEmbed();
        
        Embed.SetTitle(sHostname);
        Embed.SetColor("#ffffff");

        hook.SetUsername("Crash logger");

        Embed.AddField("Crash ID", sCrashID[index], true);
        Embed.AddField("Link", sLink, true);
        hook.SlackMode = true;
        hook.Embed(Embed);
        hook.Send();

        WriteFileLine(Hdata, "%s", sCrashID[index]);

        delete hook;
}