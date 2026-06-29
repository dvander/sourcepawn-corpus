#include <sourcemod>
#include <sdktools>
#define MAX_PLAYERS 64

new Float:playercords[64+1][3];
new Handle:cvarEnable;
new userused[64+1];
new Float:globalcords[3];

public Plugin:myinfo =
{
    name = "Self Punisher",
    author = "TimberM",
    description = "Punish Your Self!",
    version = "1.10",
    url = "http://www.timberm-gaming.com"
}
public OnClientPutInServer(client)
{
	userused[client] = 0;
}
public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
        RegConsoleCmd("say_team", Command_Say);
	cvarEnable = CreateConVar("selfpunisher", "0", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("selfpunisherversion", "1.10", "The Save location plugin's version", FCVAR_REPLICATED , true, 0.0, true, 1.0);
}
public Action:Command_Say(client, args)
{
	if (!GetConVarInt(cvarEnable))
	{
		PrintToChat(client,"[Self Punisher] Sorry but the plugin is currently disabled");
		return Plugin_Continue;
	}
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
	
	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	if (StrEqual(text[startidx], "!saveme"))
	{
		SaveClientLocation(client);
	}
	if (StrEqual(text[startidx], "!teleportme"))
	{
		TeleClient(client);
		PrintToChat(client,"[Self Punisher] You just teleported to your save location.")
	}
        if (strcmp(text[startidx], "!killme") == 0)
        {
              ForcePlayerSuicide(client);
	PrintToChat(client,"[Self Punisher] You just Killed your Self.")
        }
        if (strcmp(text[startidx], "!burnme") == 0)
        {
              IgniteEntity(client, 10.0);
	PrintToChat(client,"[Self Punisher] You just Burned your Self.")
        }
        if (strcmp(text[startidx], "!slapme") == 0)
        {
              SlapPlayer(client);
	PrintToChat(client,"[Self Punisher] You just Slaped your Self.")
        }
        if (strcmp(text[startidx], "!freezeme") == 0)
        {
              FreezePlayer(client, 10.0);
	PrintToChat(client,"[Self Punisher] You just Froze your Self.")
        }
	/* Let say continue normally */
	return Plugin_Continue
}
public SaveClientLocation(client)
{
	userused[client] = 1;
	GetClientAbsOrigin(client,playercords[client]);
	PrintToChat(client,"[Self Punisher] You just saved your location.")
}
public TeleClient(client)
{
	if (userused[client] == 0)
		return;
	
	
	
	TeleportEntity(client, playercords[client],NULL_VECTOR,NULL_VECTOR)
	
}
stock FreezePlayer(client, Float:time)
{
    if (!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    new MoveType:oldMoveType = GetEntityMoveType(client);
    SetEntityMoveType(client, MOVETYPE_NONE);

    new Handle:datapack = CreateDataPack();
    WritePackCell(datapack, client);
    WritePackCell(datapack, _:oldMoveType);

    CreateTimer(time, UnFreezePlayer, datapack);
}

public Action:UnFreezePlayer(Handle:timer, any:datapack)
{
    ResetPack(datapack);
    new client = ReadPackCell(datapack);
    new oldMoveType = ReadPackCell(datapack);
    CloseHandle(datapack);

    SetEntityMoveType(client, MoveType:oldMoveType);
} 