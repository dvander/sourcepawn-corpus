#include <sourcemod>
#define Version "1.2"
#define BaseMode 2
#define AdMsg "Say !displaymode <0/1/2/3> to change the damage display mode."
new Handle:Allowed = INVALID_HANDLE;
new Handle:Ads = INVALID_HANDLE;
new Handle:DefaultMode = INVALID_HANDLE;
new Handle:Delay = INVALID_HANDLE;
new Handle:MsgMode = INVALID_HANDLE;
new Float:LastMsgTime[MAXPLAYERS+1] = {0.0, ...};
new Damage[MAXPLAYERS+1][MAXPLAYERS+1];
new DisplayMode[MAXPLAYERS+1] = {BaseMode, ...};
new MaxPlayers = 0;

public Plugin:myinfo = 
{
	name = "Display Damage",
	author = "NBK - Sammy-ROCK!",
	description = "Display the damage that the player did.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false))
		SetFailState("This plugin is for left4dead only.");
	HookEvent("infected_hurt", Event_InfectedHurt); //Events we need to hook
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	Ads = CreateConVar("sm_display_damage_ads","1","Enables Display Damage to advertise to players.");
	Allowed = CreateConVar("sm_display_damage_enabled","1","Enables Display Damage to players.");
	DefaultMode = CreateConVar("sm_display_damage_default","2","Default Display Damage mode. 1 = all; 2 = damage done; 3 = damage token; any other = no display.");
	Delay = CreateConVar("sm_display_damage_delay","1.0","Minimum delay between damage displays.");
	MsgMode = CreateConVar("sm_display_damage_mode","1","Mode to display damage to players. 1=Hint Text; 2=Center Text; 3=Chat Text;", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 3.0);
	RegConsoleCmd("sm_displaymode", Command_DisplayMode);
	AutoExecConfig(true, "displaydamage");
	CreateTimer(GetRandomFloat(250.0, 350.0), Timer_AdsPlugin);
	CreateConVar("sm_display_damage_version", Version, "Version of Display Damage plugin.", FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		DisplayMode[client] = GetConVarInt(DefaultMode);
	else
		DisplayMode[client] = 0;
}

public Action:Command_DisplayMode(client, args)
{
	if(args < 1)
		DisplayMode[client] = GetConVarInt(DefaultMode);
	else {
		decl String:arg[10];
		GetCmdArg(1, arg, sizeof(arg))
		DisplayMode[client] = StringToInt(arg);
	}
	switch(DisplayMode[client]) {
		case  1: ReplyToCommand(client, "Any damage will be displayed. (%i)", DisplayMode[client]);
		case  2: ReplyToCommand(client, "Damage you've done will be displayed. (%i)", DisplayMode[client]);
		case  3: ReplyToCommand(client, "Damage you've received will be displayed. (%i)", DisplayMode[client]);
		default: ReplyToCommand(client, "Damage will not be displayed. (%i)", DisplayMode[client]);
	}
	return Plugin_Handled;
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
}

stock bool:EnoughtTime(client)
{
	new Float:Time = GetEngineTime();
	new Float:Needed = GetConVarFloat(Delay);
	if(Time - LastMsgTime[client] > Needed)
	{
		LastMsgTime[client] = Time;
		return true;
	}
	else
		return false;
}

public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(client)
		{
			new Dmg_HP = GetEventInt(event, "amount");
			Damage[client][0] += Dmg_HP; //0 means horde
			if(EnoughtTime(client))
				Display(client, GetConVarInt(MsgMode), "You hurt Horde in %i HP.", Damage[client][0]);
		}
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new Dmg_HP = GetEventInt(event, "dmg_health"); //Belive or not but l4d seems to be ready to have armor
		if(Dmg_HP < 1000) //BugFix for tanker death extra dmg
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			Damage[attacker][client] += Dmg_HP;
			new Mode = GetConVarInt(MsgMode);
			if(client && attacker) {
				if(DisplayMode[client] == 1 || DisplayMode[client] == 3 && EnoughtTime(client))
					Display(client, Mode, "%N hurt you in %i HP.", attacker, Damage[attacker][client]);
				if(DisplayMode[attacker] == 1 || DisplayMode[attacker] == 2 && EnoughtTime(attacker))
					Display(attacker, Mode, "You hurt %N in %i HP.", client, Damage[attacker][client]);
			} else if(client) {
				if(DisplayMode[client] == 1 || DisplayMode[client] == 3 && EnoughtTime(client))
					Display(client, Mode, "The Horde hurt you in %i HP.", Damage[attacker][client]);
			}
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client)
		{
			new TotalDamage = 0;
			for(new i=0; i<=MaxPlayers; i++)
			{
				if(DisplayMode[client] == 1 || DisplayMode[client] == 2)
					TotalDamage += Damage[client][i];
				else if(DisplayMode[client] == 3)
					TotalDamage += Damage[i][client];
				Damage[client][i] = 0; //Clears damage done since your dead
			}
			new Mode = GetConVarInt(MsgMode);
			if(DisplayMode[client] == 1 || DisplayMode[client] == 2)
				Display(client, Mode, "You've done %i damage to the enemy team.", TotalDamage);
			else if(DisplayMode[client] == 3)
				Display(client, Mode, "The enemy team have done %i damage to you.", TotalDamage);
		}
	}
}

public Action:Timer_AdsPlugin(Handle:timer)
{
	if(GetConVarInt(Allowed) && GetConVarInt(Ads))
	{
		new Mode = GetConVarInt(MsgMode);
		for(new i=1; i<=MaxPlayers; i++)
		{
			Display(i, Mode, AdMsg);
		}
	}
}

stock Display(client, Mode, const String:format[], any:...)
{
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), format, 4);
	switch(Mode)
	{
		case 1: PrintHintText(client, buffer);
		case 2: PrintCenterText(client, buffer);
		case 3: PrintToChat(client, buffer);
	}
}