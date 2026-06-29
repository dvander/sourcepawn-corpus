#include <sourcemod>

#define PLUGIN_VERSION "1.2.0.0"

new specialOffset
new maxSpecialOffset
new Handle:bCaptureBonusEnabled		= INVALID_HANDLE
new Handle:iCaptureBonusPercentage	= INVALID_HANDLE
new Handle:hServerTags					= INVALID_HANDLE
new bool:bIsEnabled = true


public Plugin:myinfo =
{
name			= "Chest Capture Bonus",
author			= "An00bis",
description	= "Capturing a chest will award specialpoints.",
version		= PLUGIN_VERSION,
url			= "https://forums.alliedmods.net/member.php?u=153377"
};
 
public OnPluginStart()
{
	CreateConVar("sm_chestcapturebonus_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	bCaptureBonusEnabled		= CreateConVar("sm_chestcapturebonus_enabled", "1", "Enabled/Disabled", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	iCaptureBonusPercentage	= CreateConVar("sm_chestcapturebonus_percentage", "25.0", "How much should the specialbar fill up - in percent", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	HookEvent("chest_capture", OnChestCapture);
}

public OnMapStart()
{
	HookConVarChange(bCaptureBonusEnabled, OnEnabledChange);
	specialOffset = FindSendPropInfo("CPVK2Player", "m_iSpecial");
	maxSpecialOffset = FindSendPropInfo("CPVK2Player", "m_iMaxSpecial");
	hServerTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hServerTags, tags, sizeof(tags));
	if(StrEqual(tags, "", false))
	{
		SetConVarString(hServerTags, "Chest Capture Bonus");
	}
	else
	{
		if(StrContains(tags, "Chest Capture Bonus", false) == -1)
		{
			decl String:newtags[255];
			Format(newtags, sizeof(newtags), "%s, Chest Capture Bonus", tags);
			SetConVarString(hServerTags, newtags);
		}
	}
	if(hServerTags != INVALID_HANDLE)
		CloseHandle(hServerTags);
}

public OnMapEnd()
{
	UnhookConVarChange(bCaptureBonusEnabled, OnEnabledChange);
	//CloseHandle(hServerTags);
}

public OnEventShutdown()
{
	UnhookEvent("chest_capture", OnChestCapture);
}

public Action:OnChestCapture(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bIsEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new maxvalue;
		new newvalue;
		new oldvalue;
		maxvalue = GetEntData(client, maxSpecialOffset);
		oldvalue = GetEntData(client, specialOffset);
		if(oldvalue != maxvalue)
		{
			newvalue = doMath(maxvalue, oldvalue);
			SetEntData(client, specialOffset, newvalue);
			if(newvalue == maxvalue && newvalue != oldvalue)
			{
				ClientCommand(client, "playgamesound player/special.wav");
			}
		}
	}
}

public doMath(maxvalue, oldvalue)
{
	decl Float:x;
	x = maxvalue / 100.0 * GetConVarFloat(iCaptureBonusPercentage) + oldvalue;
	if(x >= maxvalue)
	{ return maxvalue; }
	else 
	{ return RoundToZero(x); }
}

public OnEnabledChange(Handle:cvar, const String:oldval[], const String:newval[])
{
	if(StringToInt(newval) == 0)
	{
		bIsEnabled = false;
		PrintToServer("Chest Capture Bonus Disabled");
		LogMessage("Chest Capture Bonus is now %d", bIsEnabled);
	}
	else
	{
		bIsEnabled = true;
		PrintToServer("Chest Capture Bonus Enabled");
		LogMessage("Chest Capture Bonus is now %d", bIsEnabled);
	}
}