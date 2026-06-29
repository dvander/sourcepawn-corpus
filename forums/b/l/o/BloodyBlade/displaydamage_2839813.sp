#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define Version "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY
#define BaseMode 2
#define AdMsg "Say !displaymode <0/1/2/3> to change the damage display mode."

ConVar Allowed, Ads, DefaultMode, Delay, MsgMode;
bool bHooked = false, AdvertMsgEnable = false;
float fDelay = 0.0, LastMsgTime[MAXPLAYERS + 1] = {0.0, ...};
int iDefaultMode = 0, iMsgMode = 0, Damage[MAXPLAYERS + 1][MAXPLAYERS + 1], DisplayMode[MAXPLAYERS + 1] = {BaseMode, ...};

public Plugin myinfo = 
{
	name = "Display Damage",
	author = "NBK - Sammy-ROCK!",
	description = "Display the damage that the player did.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("sm_display_damage_version", Version, "Version of Display Damage plugin.", CVAR_FLAGS|FCVAR_DONTRECORD);
    Ads = CreateConVar("sm_display_damage_ads", "1", "Enables Display Damage to advertise to players.", CVAR_FLAGS, true, 0.0, true, 1.0);
    Allowed = CreateConVar("sm_display_damage_enabled", "1", "Enables Display Damage to players.", CVAR_FLAGS, true, 0.0, true, 1.0);
    DefaultMode = CreateConVar("sm_display_damage_default", "2", "Default Display Damage mode. 1 = all; 2 = damage done; 3 = damage token; any other = no display.", CVAR_FLAGS, true, 0.0, true, 3.0);
    Delay = CreateConVar("sm_display_damage_delay", "1.0", "Minimum delay between damage displays.", CVAR_FLAGS, true, 0.0, true, 60.0);
    MsgMode = CreateConVar("sm_display_damage_mode", "1", "Mode to display damage to players. 1=Hint Text; 2=Center Text; 3=Chat Text;", FCVAR_NOTIFY, true, 1.0, true, 3.0);

    AutoExecConfig(true, "displaydamage");

    Allowed.AddChangeHook(OnConVarPluginOnChange);
    Ads.AddChangeHook(ConVarChanged_Cvars);
    DefaultMode.AddChangeHook(ConVarChanged_Cvars);
    Delay.AddChangeHook(ConVarChanged_Cvars);
    MsgMode.AddChangeHook(ConVarChanged_Cvars);

    RegConsoleCmd("sm_displaymode", Command_DisplayMode);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	AdvertMsgEnable = Ads.BoolValue;
	iDefaultMode = DefaultMode.IntValue;
	fDelay = Delay.FloatValue;
	iMsgMode = MsgMode.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = Allowed.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		ConVarChanged_Cvars(null, "", "");
		HookEvent("infected_hurt", Event_InfectedHurt);
		HookEvent("player_hurt", Event_PlayerHurt);
		HookEvent("player_death", Event_PlayerDeath);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("infected_hurt", Event_InfectedHurt);
		UnhookEvent("player_hurt", Event_PlayerHurt);
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

public void OnClientPutInServer(int client)
{
    if(bHooked && client > 0)
    {
        if(!IsFakeClient(client))
        {
            DisplayMode[client] = iDefaultMode;
            CreateTimer(3.0, Timer_AdsPlugin);
        }
        else
        {
            DisplayMode[client] = 0;
        }
    }
}

Action Command_DisplayMode(int client, int args)
{
    if(bHooked && client > 0)
    {
        if(args < 1)
        {
            DisplayMode[client] = iDefaultMode;
        }
        else
        {
            char arg[10];
            GetCmdArg(1, arg, sizeof(arg));
            DisplayMode[client] = StringToInt(arg);
        }

        switch(DisplayMode[client])
        {
            case  1: ReplyToCommand(client, "Any damage will be displayed. (%i)", DisplayMode[client]);
            case  2: ReplyToCommand(client, "Damage you've done will be displayed. (%i)", DisplayMode[client]);
            case  3: ReplyToCommand(client, "Damage you've received will be displayed. (%i)", DisplayMode[client]);
            default: ReplyToCommand(client, "Damage will not be displayed. (%i)", DisplayMode[client]);
        }
    }
    return Plugin_Handled;
}

stock bool EnoughtTime(int client)
{
	float Time = GetEngineTime();
	if(Time - LastMsgTime[client] > fDelay)
	{
		LastMsgTime[client] = Time;
		return true;
	}
	else
	{
		return false;
	}
}

Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("attacker"));
    if(client > 0)
    {
        Damage[client][0] += event.GetInt("amount"); //0 means horde
        if(EnoughtTime(client))
        {
            Display(client, iMsgMode, "You hurt Horde in %i HP.", Damage[client][0]);
        }
    }
    return Plugin_Continue;
}

Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int Dmg_HP = event.GetInt("dmg_health"); //Belive or not but l4d seems to be ready to have armor
    if(Dmg_HP < 1000) //BugFix for tanker death extra dmg
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        Damage[attacker][client] += Dmg_HP;
        if(client > 0 && attacker > 0)
        {
            if(DisplayMode[client] == 1 || DisplayMode[client] == 3 && EnoughtTime(client))
            {
                Display(client, iMsgMode, "%N hurt you in %i HP.", attacker, Damage[attacker][client]);
            }

            if(DisplayMode[attacker] == 1 || DisplayMode[attacker] == 2 && EnoughtTime(attacker))
            {
                Display(attacker, iMsgMode, "You hurt %N in %i HP.", client, Damage[attacker][client]);
            }
        }
        else if(client)
        {
            if(DisplayMode[client] == 1 || DisplayMode[client] == 3 && EnoughtTime(client))
            {
                Display(client, iMsgMode, "The Horde hurt you in %i HP.", Damage[attacker][client]);
            }
        }
    }
    return Plugin_Continue;
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client > 0)
    {
        int TotalDamage = 0;
        for(int i = 0; i <= MaxClients; i++)
        {
            if(DisplayMode[client] == 1 || DisplayMode[client] == 2)
            {
                TotalDamage += Damage[client][i];
            }
            else if(DisplayMode[client] == 3)
            {
                TotalDamage += Damage[i][client];
            }
            Damage[client][i] = 0; //Clears damage done since your dead
        }

        if(DisplayMode[client] == 1 || DisplayMode[client] == 2)
        {
            Display(client, iMsgMode, "You've done %i damage to the enemy team.", TotalDamage);
        }
        else if(DisplayMode[client] == 3)
        {
            Display(client, iMsgMode, "The enemy team have done %i damage to you.", TotalDamage);
        }
    }
    return Plugin_Continue;
}

Action Timer_AdsPlugin(Handle timer)
{
	if(bHooked && AdvertMsgEnable)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			Display(i, iMsgMode, AdMsg);
		}
	}
	return Plugin_Stop;
}

stock void Display(int client, int Mode, const char[] format, any ...)
{
	char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 4);
	switch(Mode)
	{
		case 1: PrintHintText(client, buffer);
		case 2: PrintCenterText(client, buffer);
		case 3: PrintToChat(client, buffer);
	}
}
