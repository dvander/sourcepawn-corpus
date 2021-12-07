#pragma semicolon 1 // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <console>

#define REQUIRE_EXTENSIONS

#define PLUGIN_NAME              "[TF2] Target Practice"
#define PLUGIN_AUTHOR            "JLHack7"
#define PLUGIN_DESCRIPTION		 "Adds targets from TF2's Training Mode"
#define PLUGIN_VERSION           "1.1"
#define PLUGIN_CONTACT           "JLHack7@teamblu.org"
#define PLUGIN_URL				 "http://teamblu.org"

public Plugin:myinfo = {
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

new String:targetclass[128] = "prop_physics";

public OnPluginStart()
{
	RegAdminCmd("sm_addtarget", Command_AddTarget, ADMFLAG_SLAY, "Add a target for practice.");
	PrecacheModel("models/props_training/target_scout.mdl", true);
	PrecacheModel("models/props_training/target_soldier.mdl", true);
	PrecacheModel("models/props_training/target_pyro.mdl", true);
	PrecacheModel("models/props_training/target_demoman.mdl", true);
	PrecacheModel("models/props_training/target_heavy.mdl", true);
	PrecacheModel("models/props_training/target_engineer.mdl", true);
	PrecacheModel("models/props_training/target_medic.mdl", true);
	PrecacheModel("models/props_training/target_sniper.mdl", true);
	PrecacheModel("models/props_training/target_spy.mdl", true);
}

public Action:Command_AddTarget(client, args)
{	
	new tempRand; //This is going to be the "class" of the target, engy, soldier, etc
	//Check and see if the user specified a class number
	
	//Note: Class numbers can be found by hitting your change class key
	if (GetCmdArgs() != 0)
	{
		//If he did, we'll use that
		new String:arg1str[64];
		GetCmdArg(1, arg1str, sizeof(arg1str));
		tempRand = StringToInt(arg1str, _);
		
		//If he specified an invalid class number, fall back to a random class
		if (tempRand < 1 || tempRand > 9)
		{
			ReplyToCommand(client, "Invalid class number %d, selecting random class", tempRand);
			tempRand = -1;
		}
	}
	else
	{
		//If he didn't, we'll tell it to pick a random class.
		tempRand = -1;
	}
	
	if (tempRand == -1)
	{
		//Pick a random class.
		tempRand = GetRandomInt(1, 9);
	}
	new Float:eyePos[3];
	new Float:eyeAng[3];
	new Float:aimPos[3];
	
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	new Handle:testtrace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceFilterPlayer);
	
	if (TR_DidHit(testtrace))
	{

		TR_GetEndPosition(aimPos, testtrace);

		CloseHandle(testtrace);
		
		new target = CreateEntityByName(targetclass, -1);
		new String:tempStr[128];

		/*
			The targets have half the health of the class (rounded down)
			Scout has 125 health, so the target of the Scout has 62 health.
		*/
		switch (tempRand)
		{
			case 1:
			{
				tempStr = "models/props_training/target_scout.mdl";
			}
			case 2:
			{
				tempStr = "models/props_training/target_soldier.mdl";
			}
			case 3:
			{
				tempStr = "models/props_training/target_pyro.mdl";
			}
			case 4:
			{
				tempStr = "models/props_training/target_demoman.mdl";
			}
			case 5:
			{
				tempStr = "models/props_training/target_heavy.mdl";
			}
			case 6:
			{
				tempStr = "models/props_training/target_engineer.mdl";
			}
			case 7:
			{
				tempStr = "models/props_training/target_medic.mdl";
			}
			case 8:
			{
				tempStr = "models/props_training/target_sniper.mdl";
			}
			case 9:
			{
				tempStr = "models/props_training/target_spy.mdl";
			}
		}
		
		DispatchKeyValue(target, "model", tempStr);
		DispatchSpawn(target);
		AcceptEntityInput(target, "DisableMotion", _, _, _);
		
		//Set the angle of the target so that it's facing whoever spawned it

		new Float:tempAng[3];
		if (eyeAng[1] >= 180.0)
		{
			tempAng[1] = eyeAng[1] - 180.0;
		}
		if (eyeAng[1] < 180.0)
		{
			tempAng[1] = eyeAng[1] + 180.0;
		}
		
		TeleportEntity(target, aimPos, tempAng, NULL_VECTOR);
		return Plugin_Handled;
	}
	else
	{
		CloseHandle(testtrace);
		ReplyToCommand(client, "D'oh! Trace error");
		
		return Plugin_Continue;
	}

}

public bool:TraceFilterPlayer(entity, mask)
{
	return (entity > MaxClients);
}