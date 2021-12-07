#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new BossTeam=_:TFTeam_Blue;
new Float:fOrigin[3];
new Float:fAngle[3];

public Plugin:myinfo = {
	name = "Freak Fortress 2: rage_sentry",
	author = "Jery0987",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3,Timer_GetBossTeam);
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_sentry"))
		CreateTimer(1.5,Timer_Sentry,index);
	return Plugin_Continue;
}

public Action:Timer_Sentry(Handle:hTimer,any:index)
{
	Rage_Sentry(index);
}

Rage_Sentry(index, iLevel=3)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:fBuildMaxs[3];
	fBuildMaxs[0] = 24.0;
	fBuildMaxs[1] = 24.0;
	fBuildMaxs[2] = 66.0;

	new Float:fMdlWidth[3];
	fMdlWidth[0] = 1.0;
	fMdlWidth[1] = 0.5;
	fMdlWidth[2] = 0.0;
	
	new String:sModel[64];
	
	new iTeam = GetClientTeam(Boss);
	
	new iShells, iHealth, iRockets;
	
	iShells = iHealth = iRockets;
	if(iLevel == 1)
	{
		sModel = "models/buildables/sentry1.mdl";
		iShells = 100;
		iHealth = 150;
	}
	else if(iLevel == 2)
	{
		sModel = "models/buildables/sentry2.mdl";
		iShells = 120;
		iHealth = 180;
	}
	else if(iLevel == 3)
	{
		sModel = "models/buildables/sentry3.mdl";
		iShells = 144;
		iHealth = 216;
		iRockets = 20;
	}
	
	
	new iSentry = CreateEntityByName("obj_sentrygun");
	
	DispatchSpawn(iSentry);
	
	TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
	
	SetEntityModel(iSentry,sModel);
	
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"), 				51, 4 , true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity"), 		4, 4 , true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity"), 		4, 4 , true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") , 				iShells, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"), 				iHealth, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iHealth"), 					iHealth, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bBuilding"), 				0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bPlacing"), 					0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bDisabled"), 				0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iObjectType"), 				3, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iState"), 					1, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal"), 			0, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"), 				0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSkin"), 					(iTeam-2), 1, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement"), 	1, 1, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"), 			iLevel, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets"), 				iRockets, 4, true);
	
	SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSequence"), 0, true);
	SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"), 	Boss, true);
	
	SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flCycle"), 					0.0, true);
	SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate"), 			1.0, true);
	SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed"), 	1.0, true);
	
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"), 			fOrigin, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"), 		fAngle, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"), 		fBuildMaxs, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"), 	fMdlWidth, true);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0); 
}