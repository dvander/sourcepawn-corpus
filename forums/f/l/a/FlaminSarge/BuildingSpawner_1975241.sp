#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0.31"
public Plugin:myinfo =
{
	name = "BuildingsSpawner",
	author = "X3Mano",
	description = "Let's see if u can sap my sentrIES NOW!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
public OnPluginStart()
{
	CreateConVar("sm_spawnbuilding", PLUGIN_VERSION, "SpawnBuilding version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_sbuild", BuildMenuCMD,ADMFLAG_CHEATS);
	RegAdminCmd("sm_sdestroy", DestroyCMD,ADMFLAG_CHEATS);
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
}
public Action:DestroyCMD(client,args)
{
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_sdestroy [all-d|all-s|all|aim]");
		return Plugin_Handled;
	}
	decl String:arg1[10];
	GetCmdArg(1,arg1,sizeof(arg1));
	if(StrEqual(arg1,"all-d",false)){
		new index=-1;
		while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
		{
			if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
			}
		}
		return Plugin_Handled;
	}
	if(StrEqual(arg1,"all-s",false)){
		new index=-1;
		while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
		{
			if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
			}
		}
		return Plugin_Handled;
	}
	if(StrEqual(arg1,"all",false)){
		new index=-1;
		while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
		{
			if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
			}
		}
		index=-1;
		while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
		{
			if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
			}
		}
		return Plugin_Handled;
	}
	if (StrEqual(arg1,"aim",false)) {
		new ent=GetClientAimTarget(client,false);
		if (!IsValidEntity(ent))
		{
			ReplyToCommand(client, "[SM] No building found at aim.");
			return Plugin_Handled;
		}
		if (GetEntPropEnt(ent,Prop_Send,"m_hBuilder") == client) {
			SetVariantInt(9999);
			AcceptEntityInput(ent, "RemoveHealth");
		}
		else {
			ReplyToCommand(client, "[SM] This sentry/dispenser is not yours!");
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast) //Destroys a player's sentries/dispensers when he changes teams
{
	new client = GetEventInt(event,"userid");
	new index = -1;
	while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	}
	while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	}
	return Plugin_Continue;
}
public OnClientDisconnect(client) //Destroys a player's sentries/dispensers on disconnect
{
	new index = -1;
	while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	}
	while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	}
}
public Action:BuildMenuCMD(client, args)
{
	if(args < 2)
	{
		BuildMenu(client);
		return Plugin_Handled;
	}
	decl String:arg1[10];
	decl String:arg2[10];
	new type, level, bool:mini;
	if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1)))
	{
		type = StringToInt(arg1);
	}
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		level = StringToInt(arg2);
	}
	if (args >= 3 && GetCmdArg(3, arg2, sizeof(arg2)))
	{
		mini = !!StringToInt(arg2);
	}
	if(type < 1 || type > 2 || level < 1 || level > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sbuild <1=sentry|2=disp> <level 1-3> <mini(sentry only)>");
		return Plugin_Handled;
	}
	new Float:flEndPos[3];
	new Float:flPos[3];
	new Float:flAng[3];
	GetClientEyePosition(client, flPos);
	GetClientEyeAngles(client, flAng);
	new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
	{
		TR_GetEndPosition(flEndPos, hTrace);
		flEndPos[2] += 5.0;
	}
	if(type == 1)
	{
		BuildDispenser(client,flEndPos,flAng,level);
		return Plugin_Handled;
	}
	if(type == 2)
	{
		BuildSentry(client,flEndPos,flAng,level, mini);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:BuildMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu,"Building menu");
	AddMenuItem(menu,"slvl1","Sentry lvl 1");
	AddMenuItem(menu,"slvl2","Sentry lvl 2");
	AddMenuItem(menu,"slvl3","Sentry lvl 3");
	AddMenuItem(menu,"dlvl1","Dispenser lvl 1");
	AddMenuItem(menu,"dlvl2","Dispenser lvl 2");
	AddMenuItem(menu,"dlvl3","Dispenser lvl 3");
	AddMenuItem(menu,"mslvl1","Mini Sentry lvl 1");
	AddMenuItem(menu,"mslvl2","Mini Sentry lvl 2");
	AddMenuItem(menu,"mslvl3","Mini Sentry lvl 3");
	DisplayMenu(menu,client,30);
}
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	new String:name[32];
	new String:info[32];
	if (param1 <= 0 || param1 > MaxClients || !IsClientInGame(param1)) return;
	GetClientName(param1, name, 80);
	GetMenuItem(menu, param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		new Float:flEndPos[3];
		new Float:flPos[3];
		new Float:flAng[3];
		GetClientEyePosition(param1, flPos);
		GetClientEyeAngles(param1, flAng);
		new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, param1);
		if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
		{
			TR_GetEndPosition(flEndPos, hTrace);
			flEndPos[2] += 5.0;
		}
		if(StrEqual(info,"slvl1"))
		{
			BuildSentry(param1,flEndPos,flAng,1);
		}
		else if(StrEqual(info,"slvl2"))
		{
			BuildSentry(param1,flEndPos,flAng,2);
		}
		else if(StrEqual(info,"slvl3"))
		{
			BuildSentry(param1,flEndPos,flAng,3);
		}
		else if(StrEqual(info,"dlvl1"))
		{
			BuildDispenser(param1,flEndPos,flAng,1);
		}
		else if(StrEqual(info,"dlvl2"))
		{
			BuildDispenser(param1,flEndPos,flAng,2);
		}
		else if(StrEqual(info,"dlvl3"))
		{
			BuildDispenser(param1,flEndPos,flAng,3);
		}
		else if(StrEqual(info,"mslvl1"))
		{
			BuildSentry(param1,flEndPos,flAng,1, true);
		}
		else if(StrEqual(info,"mslvl2"))
		{
			BuildSentry(param1,flEndPos,flAng,2, true);
		}
		else if(StrEqual(info,"mslvl3"))
		{
			BuildSentry(param1,flEndPos,flAng,3, true);
		}
		BuildMenu(param1);
	}
}
stock BuildSentry(iBuilder,Float:fOrigin[3], Float:fAngle[3],iLevel, bool:bMini = false)
{
	fAngle[0] = 0.0;
	ShowActivity2(iBuilder, "[SM] ","Spawned a sentry (lvl %d%s)", iLevel, bMini ? ", mini" : "");
	decl String:sModel[64];
	new iTeam = GetClientTeam(iBuilder);
//	new fireattach[3];

	new iShells, iHealth, iRockets;
	switch (iLevel)
	{
		case 1:
		{
			sModel = "models/buildables/sentry1.mdl";
			iShells = 100;
			iHealth = 150;
	//		fireattach[0] = 4;
			if (bMini)
			{
				iShells = 100;
				iHealth = 100;
			}
		}
		case 2:
		{
			sModel = "models/buildables/sentry2.mdl";
			iShells = 120;
			iHealth = 180;
	//		fireattach[0] = 1;
	//		fireattach[1] = 2;
			if (bMini)
			{
				iShells = 120;
				iHealth = 120;
			}
		}
		case 3:
		{
			sModel = "models/buildables/sentry3.mdl";
			iShells = 144;
			iHealth = 216;
			iRockets = 20;
	//		fireattach[0] = 1;
	//		fireattach[1] = 2;
	//		fireattach[2] = 4;
			if (bMini)
			{
				iShells = 144;
				iHealth = 180;
				iRockets = 20;
			}
		}
	}

	new entity = CreateEntityByName("obj_sentrygun");
	if (entity < MaxClients || !IsValidEntity(entity)) return;
	DispatchSpawn(entity);
	TeleportEntity(entity, fOrigin, fAngle, NULL_VECTOR);
	SetEntityModel(entity,sModel);

	SetEntProp(entity, Prop_Send, "m_iAmmoShells", iShells);
	SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iObjectType", _:TFObject_Sentry);

	SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
	new iSkin = iTeam-2;
	if (bMini && iLevel == 1)
	{
		iSkin = iTeam;
	}

	SetEntProp(entity, Prop_Send, "m_nSkin", iSkin);
	SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iAmmoRockets", iRockets);

	SetEntPropEnt(entity, Prop_Send, "m_hBuilder", iBuilder);

	SetEntProp(entity, Prop_Send, "m_iState", 3);
	SetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed", iLevel == 1 ? 0.99 : 1.0);
	if (iLevel == 1) SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
	SetEntProp(entity, Prop_Send, "m_bPlayerControlled", 1);
	SetEntProp(entity, Prop_Send, "m_bHasSapper", 0);
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", Float:{ 24.0, 24.0, 66.0 });
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMins", Float:{ -24.0, -24.0, 0.0 });
	if (bMini)
	{
		SetEntProp(entity, Prop_Send, "m_bMiniBuilding", 1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.75);
	}
	new offs = FindSendPropInfo("CObjectSentrygun", "m_iDesiredBuildRotations");	//2608
	if (offs <= 0) return;
	SetEntData(entity, offs-12, 1, 1, true);
/*	new offs = FindSendPropInfo("CObjectSentrygun", "m_nShieldLevel");
	if (offs <= 0) return Plugin_Handled;
	SetEntData(entity, offs+12, fireattach[0]);
	SetEntData(entity, offs+16, fireattach[1]);
	SetEntData(entity, offs+20, fireattach[2]);*/
}
stock BuildDispenser(iBuilder, Float:flOrigin[3], Float:flAngles[3], iLevel)
{
	new String:strModel[100];
	flAngles[0] = 0.0;
	ShowActivity2(iBuilder, "[SM] ", "Spawned a dispenser (lvl %d)", iLevel);
	new iTeam = GetClientTeam(iBuilder);
	new iHealth;
	new iAmmo = 400;
	switch (iLevel)
	{
		case 3:
		{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
			iHealth = 216;
		}
		case 2:
		{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
			iHealth = 180;
		}
		default:
		{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
			iHealth = 150;
		}
	}

	new entity = CreateEntityByName("obj_dispenser");
	if (entity < MaxClients || !IsValidEntity(entity)) return;
	DispatchSpawn(entity);

	TeleportEntity(entity, flOrigin, flAngles, NULL_VECTOR);

	SetVariantInt(iTeam);
	AcceptEntityInput(entity, "TeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(entity, "SetTeam");

	ActivateEntity(entity);

	SetEntProp(entity, Prop_Send, "m_iAmmoMetal", iAmmo);
	SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
	SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
	SetEntProp(entity, Prop_Send, "m_nSkin", iTeam-2);
	SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iState", 3);
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", Float:{ 24.0, 24.0, 55.0 });
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMins", Float:{ -24.0, -24.0, 0.0 });
	SetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed", iLevel == 1 ? 0.99 : 1.0);
	if (iLevel == 1) SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
	SetEntPropEnt(entity, Prop_Send, "m_hBuilder", iBuilder);
	SetEntityModel(entity, strModel);
	new offs = FindSendPropInfo("CObjectDispenser", "m_iDesiredBuildRotations");	//2608
	if (offs <= 0) return;
	SetEntData(entity, offs-12, 1, 1, true);
}
public bool:TraceFilterIgnorePlayers(entity, contentsMask, any:client)
{
	return (entity <= 0 || entity > MaxClients);
}