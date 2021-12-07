#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

new bool:JoinGame[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = "Motd Sound",
	author = "ArtDesire, thx to klausenbusk",
	description = "Play Sound when player reading MOTD",
	version = "1.0.0.0",
	url = "http://top-5ive.net/"
};
public OnPluginStart()
{
	AddCommandListener(Command_Joingame, "joingame");
}
public OnConfigsExecuted()
{
	PrecacheSound("motd/motd.mp3", true);
	AddFileToDownloadsTable("sound/motd/motd.mp3");
}
public OnClientPostAdminCheck(client)
{
EmitSoundToClient(client, "motd/motd.mp3");
}

public Action:Command_Joingame(client, const String:command[], args)
{
    if (!JoinGame[client])
    {
        StopSound(client, SNDCHAN_AUTO, "motd/motd.mp3");
        JoinGame[client] = true; // to prvent, people write joingame in console again :)
    }
    return Plugin_Continue;
}
public OnClientDisconnect(client)
{
    JoinGame[client] = false;
}  