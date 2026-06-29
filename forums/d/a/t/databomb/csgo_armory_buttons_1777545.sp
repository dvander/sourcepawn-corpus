#include <sourcemod>
#include <sdktools>

new Handle:gH_TargetBegin = INVALID_HANDLE;

public OnPluginStart()
{
	HookEntityOutput("func_button", "OnPressed", OnPushed);
	gH_TargetBegin = CreateConVar("sm_csgo_button_targetname", "dispenser:", "The text before the weapon name for the armory button.");
}

/**
 * Called when an entity output is fired.
 *
 * @param output		Name of the output that fired.
 * @param caller		Entity index of the caller.
 * @param activator		Entity index of the activator.
 * @param delay			Delay in seconds? before the event gets fired.
 */
public OnPushed(const String:output[], caller, activator, Float:delay)
{
	if (activator > MaxClients && activator <= 0)
	{
		return;
	}
	
	decl String:sTargetName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName))
	
	decl String:sTargetBegin[32];
	GetConVarString(gH_TargetBegin, sTargetBegin, sizeof(sTargetBegin));
	new found = ReplaceString(sTargetName, sizeof(sTargetName), sTargetBegin, "");
	if (found)
	{
		decl String:sWeapon[64];
		Format(sWeapon, sizeof(sWeapon), "weapon_%s", sTargetName);
		PrintToChat(activator, "[SM] You've been given a %s.", sTargetName);
		GivePlayerItem(activator, sWeapon);
	}
}