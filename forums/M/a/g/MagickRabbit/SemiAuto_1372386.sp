// Semi-automatic weapons (only for BattleGrounds 2 mod)
// by MagickRabbit

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[BG2] Semi-automatic weapons",
	author = "MagickRabbit",
	description = "Enable all weapons of the game to be semi-automatic for every players.",
	version = "1.1",
	url = ""
};

new Handle:enablecvar = INVALID_HANDLE;
new PluginEnabled = 0;
new clip;


public OnPluginStart()
{
    //Get the clip variable from CBaseCombatWeapon class.
    clip = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	
    //Create the cvar to activate the semi-automatic mod.
    enablecvar = CreateConVar("sm_semiauto", "0", "Enable/Disable '1/0' Semi-automatic guns for everyone");

    //When the cvar is activated/desactivated we call the function Enable.
    HookConVarChange(enablecvar, Enable);

    //Check if the semi-automatic mod is already activated
    PluginEnabled = GetConVarBool(enablecvar);
}

public OnGameFrame()
{
    if(PluginEnabled)
    {
        //Always try to give one bullet to everyone.
        GiveAmmoToEveryone();
    }
}

public GiveAmmo(client)
{
    //Check if the client is able to receive his bullet.
    if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))		
    {
        //Get the current weapon of the player
        new activeweapon = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
    	new CurrentWeapon = GetEntDataEnt2(client, activeweapon);

	if(IsValidEntity(CurrentWeapon))	
	{	
            //Set the player clip to one bullet (maximum)			    
	    SetEntData(CurrentWeapon, clip, 1, 4, true)			
	}
    }
}

public GiveAmmoToEveryone()
{
    if (PluginEnabled)
    {
        for (new i = 1; i <= MaxClients; i++)	
        {			
            GiveAmmo(i);                           
        }
    } 
}

public Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new OldStatus = StringToInt(oldValue);
	new NewStatus = StringToInt(newValue);

        //If semi-automatic was desactivated, activate it.
	if (NewStatus == 1 && OldStatus == 0)
	{	
		PluginEnabled = 1;
		PrintToChatAll("\x04[SM] \x01Semi-Automatic Enabled");		 
	}
        //If semi-automatic was activated, desactivate it.
	else if (NewStatus == 0 && OldStatus == 1)
	{	
		PluginEnabled = 0;
		PrintToChatAll("\x04[SM] \x01Semi-Automatic Disabled");

	}
}