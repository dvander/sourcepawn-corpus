#include <sourcemod>
#define Version "1.1"
new String:DisabledNote[] = "Please note that the admin disabled Single Versus for now.";
new String:Explanation[] = "In any server that runs the Single Versus plugin you can play as zombies against survivor bots. Also if the server has 4 or less peoples we don't really need someone in survivor's team.";
new String:Ads[] = "This server is running Single Versus plugin!\nSay !singleversus for more info.";
new Handle:Allowed = INVALID_HANDLE;
new Handle:AdsHndl = INVALID_HANDLE;
new Handle:AdsDelay = INVALID_HANDLE;
new Handle:AllBotTeam = INVALID_HANDLE;
new CurrentPlayers = 0;
new MaxPlayers = 0;

public Plugin:myinfo = 
{
	name = "L4D Single Versus",
	author = "NBK - Sammy-ROCK!",
	description = "Allows players to play versus in single player.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false))
		SetFailState("This plugin is for left4dead only."); //Prevent errors on wrong mods
	RegConsoleCmd("sm_singleversus", Command_Explain); //Command to get more infos
	AllBotTeam = FindConVar("sb_all_bot_team"); //So we don't have to find it again
	Allowed = CreateConVar("sm_all_bot_team", "1", "Should we control All Bot Team."); //ConVar for control
	AdsHndl = CreateConVar("sm_all_bot_team_ads_enabled", "1", "Should we advertise server's modified gameplay possibility."); //ConVar for advertises control
	AdsDelay = CreateConVar("sm_all_bot_team_ads_delay", "300.0", "Delay between advertisements.", FCVAR_PLUGIN, true, 10.0); //ConVar for advertises time control
	HookConVarChange(Allowed, ConVarChangedAllowed); //So we know if the admin disabled or enabled it.
	AutoExecConfig(true, "singleversus"); //Saves the settings
	CreateConVar("sm_single_versus_version", Version, "Version of Single versus plugin.", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	CreateTimer(GetConVarFloat(AdsDelay), Timer_AdsVersus);
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		CurrentPlayers++;
		if(CurrentPlayers == 1) //Why 1? Save CPU so it won't constantly set to 1 every time someone joins
		{
			if(GetConVarInt(Allowed)) //Only sets if it's allowed
				SetConVarInt(AllBotTeam, 1, true, false);
		}
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client) && GetConVarInt(Allowed))
	{
		CurrentPlayers--;
		if(CurrentPlayers == 0) //When the server gets empty we gotta turn off so we don't get stuck in the map or never hibernate.
		{
			SetConVarInt(AllBotTeam, 0, true, false);
		}
	}
}

public CountPlayers() //Why not use GetClientCount? I'm not sure if it count bots.
{
	CurrentPlayers = 0;
	for(new i=1; i<= MaxPlayers; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
			CurrentPlayers++;
	}
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
	CountPlayers(); //Just updates the player count so you can reload the plugin
}

public Action:Command_Explain(client, args)
{
	//Client only so he can't spam server with this.
	PrintToChat(client, Explanation);
	PrintToConsole(client, Explanation);
	if(!GetConVarInt(Allowed)) {
		PrintToChat(client, DisabledNote);
		PrintToConsole(client, DisabledNote);
	}
}

public Action:Timer_AdsVersus(Handle:timer)
{
	CreateTimer(GetConVarFloat(AdsDelay), Timer_AdsVersus);
	if(GetConVarInt(AdsHndl) && GetConVarInt(Allowed)) //Why would we ads it if it's disabled?
		PrintToChatAll(Ads);
}

public ConVarChangedAllowed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(Allowed) && CurrentPlayers >= 1)
		SetConVarInt(AllBotTeam, 1, true, false);
	else
		SetConVarInt(AllBotTeam, 0, true, false);
}