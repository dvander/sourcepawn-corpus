#include <sourcemod>
#define Version "1.0"
#define CVarFlags FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_PLUGIN
new Handle:Ads = INVALID_HANDLE;
new Handle:AdsDelay = INVALID_HANDLE;
new String:ServerIP[20] = "localhost"; //Default for not messing player

public Plugin:myinfo = 
{
	name = "Server Binder",
	author = "NBK - Sammy-ROCK!",
	description = "Let's players bind the server",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	new Handle:ConVar = FindConVar("ip"); //Gets handler of "ip" convar
	if(ConVar == INVALID_HANDLE)
		SetFailState("Could not retrieve server ip."); //Why would we keep if we can't do a thing?
	GetConVarString(ConVar, ServerIP, sizeof(ServerIP)); //Gets server ip
	RegConsoleCmd("sm_bindserver", Command_BindServer); //Registers our command
	Ads = CreateConVar("sm_server_binder_ads_enabled","1","Enables Server Binder to advertise to players.", CVarFlags, true, 0.0, true, 1.0);
	AdsDelay = CreateConVar("sm_server_binder_ads_delay","300.0","Delay between Advertises.", CVarFlags, true, 1.0);
	AutoExecConfig(true, "serverbinder"); //Stores the convar value
	CreateConVar("sm_server_binder_version", Version, "Version of Server Binder plugin.", CVarFlags); //Called after so stored sm_server_binder_version won't mess with the real version
	SetAds(); //Starts Ads timer
}

public Action:Command_BindServer(client, args)
{
	if(args < 1) {
		ReplyToCommand(client, "Usage: !bindserver <key>");
		return Plugin_Continue;
	}
	decl String:Key[50];
	GetCmdArg(1, Key, sizeof(Key));
	ClientCommand(client, "bind \"%s\" \"connect %s\"", Key, ServerIP);
	ReplyToCommand(client, "You've succesfully binded %s to our server. Thank you.", Key);
	if(GetConVarInt(Ads)) //Only says the person binded if ads is enabled
		PrintToChatAll("%N likes the server so much that he binded us!", client);
	return Plugin_Handled;
}

public SetAds() //Updates if AdsDelay was changed
{
	new Float:Time = GetConVarFloat(AdsDelay);
	if(Time < 1.0) //In case of error uses default delay
		Time = 300.0;
	CreateTimer(Time, Timer_AdsBind);
}

public Action:Timer_AdsBind(Handle:timer)
{
	SetAds(); //Called before so if you decide to enable after disabling it'll work
	if(GetConVarInt(Ads)) //Checks if ads is enabled
		PrintToChatAll("If you like the server and wanna come back again later say \"!bindserver <key>\".");
}