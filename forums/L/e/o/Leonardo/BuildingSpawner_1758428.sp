#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"
#define MODEL_SENTRY_LVL1 "models/buildables/sentry1.mdl"
#define MODEL_SENTRY_LVL2 "models/buildables/sentry2.mdl"
#define MODEL_SENTRY_LVL3 "models/buildables/sentry3.mdl"
#define MODEL_DISPENSER_LVL1 "models/buildables/dispenser.mdl"
#define MODEL_DISPENSER_LVL2 "models/buildables/dispenser_lvl2.mdl"
#define MODEL_DISPENSER_LVL3 "models/buildables/dispenser_lvl3.mdl"

public Plugin:myinfo =
{
	name = "BuildingsSpawner",
	author = "X3Mano (edit by Leonardo)",
	description = "Let's see if u can sap my sentrIES NOW!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
public OnPluginStart()
{
	LoadTranslations("spawnbuilding.phrases");
	CreateConVar("sm_spawnbuilding", PLUGIN_VERSION, "SpawnBuilding version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd("sm_sbuild", BuildMenuCMD,ADMFLAG_CHEATS);
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
}
public OnMapStart()
{
	PrecacheModel( MODEL_SENTRY_LVL1, true );
	PrecacheModel( MODEL_SENTRY_LVL2, true );
	PrecacheModel( MODEL_SENTRY_LVL3, true );
	PrecacheModel( MODEL_DISPENSER_LVL1, true );
	PrecacheModel( MODEL_DISPENSER_LVL2, true );
	PrecacheModel( MODEL_DISPENSER_LVL3, true );
}
public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new index = -1;
	while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	index = -1;
	while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	return Plugin_Continue;
}
public OnClientDisconnect(client)
{
	new index = -1;
	while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	index = -1;
	while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
}
public Action:BuildMenuCMD(client, args)
{
	if(args <= 0)
	{
		BuildMenu(client);
		return Plugin_Handled;
	}
	decl String:arg0[32];
	decl String:arg1[4];
	decl String:arg2[4];
	GetCmdArg(0, arg0, sizeof(arg0));
	new type;
	new level;
	if (args >= 1)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		type = StringToInt(arg1);
	}
	if (args >= 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		level = StringToInt(arg2);
	}
	if(type < 1 || type > 2 || level < 1 || level > 3)
	{
		ReplyToCommand( client, "Usage: %s <1|2> <level 1-3> (1 = dispenser|2 = sentry)", arg0 );
		return Plugin_Handled;
	}
	new Float:flEndPos[3];
	new Float:flPos[3];
	new Float:flAng[3];
	GetClientEyePosition(client, flPos);
	GetClientEyeAngles(client, flAng);
	new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
	if(hTrace != INVALID_HANDLE)
	{
		if(TR_DidHit(hTrace))
		{
			TR_GetEndPosition(flEndPos, hTrace);
			flEndPos[2] += 5.0;
		}
		CloseHandle(hTrace);
	}
	if(type == 1)
		BuildDispenser(client,flEndPos,flAng,level);
	else if(type == 2)
		BuildSentry(client,flEndPos,flAng,level);
	return Plugin_Handled;
}
BuildMenu(iClient)
{
	if( iClient == 0 )
		return;
	new Handle:hMenu = CreateMenu(MenuHandler1);
	decl String:strBuffer[96];
	Format( strBuffer, sizeof(strBuffer), "%T:", "Building menu", iClient );
	SetMenuTitle(hMenu,strBuffer);
	Format( strBuffer, sizeof(strBuffer), "%T", "Sentry lvl 1", iClient );
	AddMenuItem(hMenu,"slvl1",strBuffer);
	Format( strBuffer, sizeof(strBuffer), "%T", "Sentry lvl 2", iClient );
	AddMenuItem(hMenu,"slvl2",strBuffer);
	Format( strBuffer, sizeof(strBuffer), "%T", "Sentry lvl 3", iClient );
	AddMenuItem(hMenu,"slvl3",strBuffer);
	//Format( strBuffer, sizeof(strBuffer), "%T", "Sentry mini", iClient );
	//AddMenuItem(hMenu,"smini",strBuffer);
	Format( strBuffer, sizeof(strBuffer), "%T", "Dispenser lvl 1", iClient );
	AddMenuItem(hMenu,"dlvl1",strBuffer);
	Format( strBuffer, sizeof(strBuffer), "%T", "Dispenser lvl 2", iClient );
	AddMenuItem(hMenu,"dlvl2",strBuffer);
	Format( strBuffer, sizeof(strBuffer), "%T", "Dispenser lvl 3", iClient );
	AddMenuItem(hMenu,"dlvl3",strBuffer);
	DisplayMenu(hMenu,iClient,30);
}
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	new String:info[32];
	GetMenuItem(menu, param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		new Float:flEndPos[3];
		new Float:flPos[3];
		new Float:flAng[3];
		GetClientEyePosition(param1, flPos);
		GetClientEyeAngles(param1, flAng);
		new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, param1);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				TR_GetEndPosition(flEndPos, hTrace);
				flEndPos[2] += 5.0;
			}
			CloseHandle(hTrace);
		}
		if(StrEqual(info,"slvl1"))
			BuildSentry(param1,flEndPos,flAng,1);
		else if(StrEqual(info,"slvl2"))
			BuildSentry(param1,flEndPos,flAng,2);
		else if(StrEqual(info,"slvl3"))
			BuildSentry(param1,flEndPos,flAng,3);
		else if(StrEqual(info,"smini"))
			BuildSentry(param1,flEndPos,flAng,1,true);
		else if(StrEqual(info,"dlvl1"))
			BuildDispenser(param1,flEndPos,flAng,1);
		else if(StrEqual(info,"dlvl2"))
			BuildDispenser(param1,flEndPos,flAng,2);
		else if(StrEqual(info,"dlvl3"))
			BuildDispenser(param1,flEndPos,flAng,3);
		BuildMenu(param1);
	}
}
BuildSentry(iBuilder,Float:fOrigin[3],Float:fAngle[3],iLevel,bool:bMini=false)
{
	if( iBuilder <= 0 || iBuilder > MaxClients || !IsClientInGame(iBuilder) )
		return -1;
	fAngle[0] = 0.0;
	if(bMini)
		ShowActivity2( iBuilder,"[SM] ", "has spawned a mini sentry", iLevel );
	else
		ShowActivity2( iBuilder,"[SM] ", "has spawned a sentry (lvl %d)", iLevel );
	decl String:sModel[PLATFORM_MAX_PATH];
	new iTeam = GetClientTeam(iBuilder);
	new iShells, iHealth, iRockets;
	if(bMini)
	{
		// unfinished!
		strcopy( sModel, sizeof(sModel), MODEL_SENTRY_LVL1 );
		iShells = 100;
		iHealth = 100;
		iLevel = 1;
	}
	else if(iLevel == 2)
	{
		strcopy( sModel, sizeof(sModel), MODEL_SENTRY_LVL2 );
		iShells = 120;
		iHealth = 180;
	}
	else if(iLevel == 3)
	{
		strcopy( sModel, sizeof(sModel), MODEL_SENTRY_LVL3 );
		iShells = 144;
		iHealth = 216;
		iRockets = 20;
	}
	else
	{
		strcopy( sModel, sizeof(sModel), MODEL_SENTRY_LVL1 );
		iShells = 100;
		iHealth = 150;
	}
	new iSentry = CreateEntityByName("obj_sentrygun");
	if(iSentry > MaxClients && IsValidEntity(iSentry))
	{
		DispatchSpawn(iSentry);
		TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
		SetEntityModel(iSentry,sModel);
		
		SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShells);
		SetEntProp(iSentry, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iObjectType", _:TFObject_Sentry);
		SetEntProp(iSentry, Prop_Send, "m_iState", 1);
			
		SetEntProp(iSentry, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iTeam-(bMini?0:2));
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", iRockets);
			
		SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", iBuilder);
			
		SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntProp(iSentry, Prop_Send, "m_bPlayerControlled", 1);
		SetEntProp(iSentry, Prop_Send, "m_bHasSapper", 0);
		return iSentry;
	}
	return -1;
}
BuildDispenser(iBuilder,Float:flOrigin[3],Float:flAngles[3],iLevel)
{
	if( iBuilder <= 0 || iBuilder > MaxClients || !IsClientInGame(iBuilder) )
		return -1;
	new String:strModel[PLATFORM_MAX_PATH];
	flAngles[0] = 0.0;
	ShowActivity2( iBuilder,"[SM] ", "has spawned a dispenser (lvl %d)", iLevel );
	new iTeam = GetClientTeam(iBuilder);
	new iHealth;
	if(iLevel == 2)
	{
		strcopy( strModel, sizeof(strModel), MODEL_DISPENSER_LVL2 );
		iHealth = 180;
	}
	else if(iLevel == 3)
	{
		strcopy( strModel, sizeof(strModel), MODEL_DISPENSER_LVL3 );
		iHealth = 216;
	}
	else
	{
		strcopy( strModel, sizeof(strModel), MODEL_DISPENSER_LVL1 );
		iHealth = 150;		
	}
	
	new iDispenser = CreateEntityByName("obj_dispenser");
	if(iDispenser > MaxClients && IsValidEntity(iDispenser))
	{
		DispatchSpawn(iDispenser);
		TeleportEntity(iDispenser, flOrigin, flAngles, NULL_VECTOR);
		SetEntityModel(iDispenser, strModel);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "TeamNum");
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "SetTeam");
		
		ActivateEntity(iDispenser);
		
		//SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", 400);
		SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
		SetEntProp(iDispenser, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iDispenser, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntPropFloat(iDispenser, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", iBuilder);	

		return iDispenser;
	}
	return -1;
}
public bool:TraceFilterIgnorePlayers(entity, contentsMask, any:client)
{
	if(entity >= 1 && entity <= MaxClients)
	{
		return false;
	}
	
	return true;
}
	