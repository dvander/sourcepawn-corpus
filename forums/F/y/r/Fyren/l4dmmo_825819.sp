#include <sourcemod>
#include <sdktools>

#define NSKILLS 16
#define NUPGRADES 31

//CTerrorPlayer::SetSkill(SurvivorSkillType, bool)
//setting the bool = true only makes it bail early?
//_ZN13CTerrorPlayer8SetSkillE17SurvivorSkillTypeb
new Handle:SetSkill = INVALID_HANDLE;

//SkillToString(SurvivorSkillType)
//_Z13SkillToString17SurvivorSkillType
new Handle:GetSkillName = INVALID_HANDLE;

//CTerrorPlayer::AddUpgrade(SurvivorUpgradeType)
//_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType
new Handle:AddUpgrade = INVALID_HANDLE;

//CTerrorPlayer::RemoveUpgrade(SurvivorUpgradeType)
//_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType
new Handle:RemoveUpgrade = INVALID_HANDLE;

//CTerrorPlayer::RemoveAllUpgrades()
//_ZN13CTerrorPlayer17RemoveAllUpgradesEv
new Handle:RemoveAllUpgrades = INVALID_HANDLE;

//UpgradeToString(SurvivorUpgradeType)
//_Z15UpgradeToString19SurvivorUpgradeType
new Handle:GetUpgradeName = INVALID_HANDLE;

public OnPluginStart()
{

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer8SetSkillE17SurvivorSkillTypeb", 0);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	SetSkill = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_Z13SkillToString17SurvivorSkillType", 0);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	GetSkillName = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType", 0);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	AddUpgrade = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType", 0);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	RemoveUpgrade = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer17RemoveAllUpgradesEv", 0);
	RemoveAllUpgrades = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_Z15UpgradeToString19SurvivorUpgradeType", 0);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	GetUpgradeName = EndPrepSDKCall();

	RegConsoleCmd("setskill", setSkill);
	RegConsoleCmd("skillname", skillName);
	RegConsoleCmd("addupgrade", addUpgrade);
	RegConsoleCmd("removeupgrade", removeUpgrade);
	RegConsoleCmd("removeallupgrades", removeAllUpgrades);
	RegConsoleCmd("upgradename", upgradeName);

	RegConsoleCmd("dumpskills", dumpSkills);
	RegConsoleCmd("dumpupgrades", dumpUpgrades);
}

public Action:setSkill(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new skill = StringToInt(arg);

	if ((skill < 0) || (skill > NSKILLS)) 
	{
		PrintToChat(client, "Bad skill number");
		return Plugin_Handled;
	}

	SDKCall(SetSkill, client, skill, false);

	return Plugin_Handled;
}

public Action:skillName(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new skill = StringToInt(arg);

	if ((skill < 0) || (skill > NSKILLS)) 
	{
		PrintToChat(client, "Bad skill number");
		return Plugin_Handled;
	}

	decl String:name[64];
	SDKCall(GetSkillName, name, sizeof(name), skill);

	PrintToChat(client, "Skill %d is %s", skill, name);

	return Plugin_Handled;
}

public Action:addUpgrade(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new upgrade = StringToInt(arg);

	if ((upgrade < 0) || (upgrade > NUPGRADES)) 
	{
		PrintToChat(client, "Bad upgrade number");
		return Plugin_Handled;
	}

	SDKCall(AddUpgrade, client, upgrade);

	return Plugin_Handled;
}

public Action:removeUpgrade(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new upgrade = StringToInt(arg);

	if ((upgrade < 0) || (upgrade > NUPGRADES)) 
	{
		PrintToChat(client, "Bad upgrade number");
		return Plugin_Handled;
	}

	SDKCall(RemoveUpgrade, client, upgrade);

	return Plugin_Handled;
}

public Action:removeAllUpgrades(client, args)
{
	SDKCall(RemoveAllUpgrades, client);

	return Plugin_Handled;
}

public Action:upgradeName(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new upgrade = StringToInt(arg);

	if ((upgrade < 0) || (upgrade > NUPGRADES)) 
	{
		PrintToChat(client, "Bad upgrade number");
		return Plugin_Handled;
	}

	decl String:name[64];
	SDKCall(GetUpgradeName, name, sizeof(name), upgrade);

	PrintToChat(client, "Upgrade %d is %s", upgrade, name);

	return Plugin_Handled;
}

public Action:dumpUpgrades(client, args)
{
	new upgrade;
	decl String:name[64];

	PrintToChat(client, "Upgrades:");
	while (upgrade < NUPGRADES)
	{
		SDKCall(GetUpgradeName, name, sizeof(name), upgrade);

		PrintToChat(client, "  %d: %s", upgrade, name);

		upgrade++;
	}

	return Plugin_Handled;
}

public Action:dumpSkills(client, args)
{
	new skill;
	decl String:name[64];

	PrintToChat(client, "Skills:");
	while (skill < NSKILLS)
	{
		SDKCall(GetSkillName, name, sizeof(name), skill);

		PrintToChat(client, "  %d: %s", skill, name);

		skill++;
	}

	return Plugin_Handled;
}

