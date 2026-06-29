#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new Handle:trial_time  = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Premium Membership Trial",
    author = "Mortdredd",
    description = "Allows users to Trial Premium membership",
    version = "0.2",
    url = "http://www.sourcemod.net/"
}
 
public OnPluginStart()
{
    // Check Game //
    decl String:game[32];
    GetGameFolderName(game, sizeof(game));
    if(StrEqual(game, "tf"))
    {
        LogMessage("Premium Members Trial Mod loaded successfully.");
    }
    else
    {
        SetFailState("Team Fortress 2 Only.");
    }
    
    // Premium Member Commands //
    RegConsoleCmd("trial", Command_trial);
    
	//Create CVARS//
	CreateConVar("PremiumTrial_version",    "0.2", "Premium Trial Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	trial_time = CreateConVar("trial_duration", "1800", "How long Trial lasts in seconds");
}

public Action:Command_trial(client, args)
{
    new AdminId:admin = CreateAdmin("Donator");
	SetAdminFlag(admin, Admin_Custom1, true);
	SetAdminImmunityLevel(admin, 5);
	SetUserAdmin(client, admin);
	PrintCenterText(client, "YOUR 30 MINUTE TRIAL BEGINS NOW")
	CreateTrial(client)
}

CreateTrial(client)
{
	new Duration = GetConVarFloat(trial_time);
	CreateTimer(Duration, Timer_Regen, client);	
}

public Action:Timer_Regen(Handle:timer, any:value)
{
	new AdminId:admin
	RemoveAdmin(admin)
}