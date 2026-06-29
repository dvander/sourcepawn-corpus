#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0.3"
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
	CreateConVar("sm_spawnbuilding", PLUGIN_VERSION, "SpawnBuilding version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd("sm_sbuild", BuildMenuCMD,ADMFLAG_CHEATS);
	RegAdminCmd("sm_sdestroy", DestroyCMD,ADMFLAG_CHEATS); 
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
}
public Action:DestroyCMD(client,args)
{
	if(args < 1){
		ReplyToCommand(client,"Usage:sm_sdestroy [all-d|all-s|all|aim]");
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
	if(StrEqual(arg1,"aim",false)){
		new ent=GetClientAimTarget(client,false);
		if(GetEntPropEnt(ent,Prop_Send,"m_hBuilder") == client){
			SetVariantInt(9999);
			AcceptEntityInput(ent, "RemoveHealth");
		}
		else {
			ReplyToCommand(client,"This sentry/dispenser is not yours!");
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
	if(args < 2){
		BuildMenu(client);
		return Plugin_Handled;
	}
	decl String:arg1[10];
	decl String:arg2[10];
	new type;
	new level;
	if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1)))
	{
		type = StringToInt(arg1);
	}
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		level = StringToInt(arg2);
	}
	if(type < 1 || type > 2 || level < 1 || level > 3)
	{
		ReplyToCommand(client,"[SM]Usage:sm_sbuild <1|2> <level 1-3> (1 = dispenser|2 = sentry)");
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
		BuildSentry(client,flEndPos,flAng,level);
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
	DisplayMenu(menu,client,30);
}
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	new String:name[32];
	new String:info[32];
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
		BuildMenu(param1);
	}
}
public Action:BuildSentry(iBuilder,Float:fOrigin[3], Float:fAngle[3],iLevel)
{
	fAngle[0] = 0.0;
	decl String:name[60];
	GetClientName(iBuilder,name,sizeof(name));
	ShowActivity2(iBuilder,"[SM]","Spawned a sentry(lvl %d)", iLevel);
	decl String:sModel[64];
	new iTeam = GetClientTeam(iBuilder);
    
	new iShells, iHealth, iRockets;
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
	
	SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShells);
	SetEntProp(iSentry, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(iSentry, Prop_Send, "m_iMaxHealth", iHealth);
	SetEntProp(iSentry, Prop_Send, "m_iObjectType", _:TFObject_Sentry);
	SetEntProp(iSentry, Prop_Send, "m_iState", 1);
		
	SetEntProp(iSentry, Prop_Send, "m_iTeamNum", iTeam);
	SetEntProp(iSentry, Prop_Send, "m_nSkin", iTeam-2);
	SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
	SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", iRockets);
		
	SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", iBuilder);
		
	SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed", 1.0);
	SetEntProp(iSentry, Prop_Send, "m_bPlayerControlled", 1);
	SetEntProp(iSentry, Prop_Send, "m_bHasSapper", 0);
	return Plugin_Handled;
}
public Action:BuildDispenser(iBuilder, Float:flOrigin[3], Float:flAngles[3], iLevel)
{
	new String:strModel[100];
	flAngles[0] = 0.0;
	decl String:name[60];
	GetClientName(iBuilder,name,sizeof(name));
	ShowActivity2(iBuilder,"[SM]","Spawned a dispenser(lvl %d)", iLevel);
	new iTeam = GetClientTeam(iBuilder);
	new iHealth;
	new iAmmo = 400;
	if(iLevel == 2)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
		iHealth = 180;
	}
	else if(iLevel == 3)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
		iHealth = 216;
	}
	else
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
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
		
		SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", iAmmo);
		SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
		SetEntProp(iDispenser, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iDispenser, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntPropFloat(iDispenser, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", iBuilder);		
	}
	return Plugin_Handled;
}
public bool:TraceFilterIgnorePlayers(entity, contentsMask, any:client)
{
	if(entity >= 1 && entity <= MaxClients)
	{
		return false;
	}
	
	return true;
}
	