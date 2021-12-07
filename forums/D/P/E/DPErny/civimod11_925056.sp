#include <sourcemod>
#include <tf2_stocks>
 
public Plugin:myinfo =
{
	name = "CiviMod",
	author = "DPErny",
	description = "Allows Civilian on any class, any time",
	version = "1.0",
	url = "ubercharged.net/forum/index"
};
 
public OnPluginStart()
{
	CreateConVar("sm_civimod_version", "1.0", "CiviMod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("civil_all", "1", "Set to 1 to allow players to Civilize themselves.");
	CreateConVar("civil_heavyonly", "0", "Set to 1 to allow civilian Heavies only");
	AutoExecConfig();
	
	RegConsoleCmd("sm_civilizeme", command_clcivilize, "Makes you into a Civilian");
	RegAdminCmd("sm_civilize", command_admcivilize, ADMFLAG_SLAY, "Make anyone Civilian. Note: can be undone through resupply");
}

public Action:command_clcivilize(client, args)
{
	new cando = FindConVar ("civil_all");

	if (cando == 1)
	{
		TF2_RemoveAllWeapons(client);
		PrintToChat (client, "[CiviMod] You have been Civilized. Please note that using a resupply cabinet will uncivilize you.");
		new heavyonly = FindConVar ("civil_heavyonly");
		new TFClassType:heavy = TFClass_Heavy;
		if ((TF2_GetPlayerClass(client) != heavy) && (heavyonly == 1))
		{
			PrintToChat (client, "[CiviMod] You must be a Heavy to do that.");
		}
	}
	else
	{
		PrintToChat (client, "[CiviMod] You do not have access to that.");
	}  

}

public Action:command_admcivilize(client, args)
{
	new String:civitarget[32];
	GetCmdArg(1, civitarget, sizeof(civitarget));
	new i = FindTarget(client, civitarget);

	TF2_RemoveAllWeapons(i);
	PrintToChat(i, "You have been Civilized.");
	PrintToChat(i, "The target has been Civilized.");
}