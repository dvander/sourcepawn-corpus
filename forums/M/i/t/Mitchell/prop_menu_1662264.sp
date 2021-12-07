#include <sourcemod>
#include <sdktools>

new Handle:g_hPropList;
new Handle:g_hKV;

public OnPluginStart()
{
	RegConsoleCmd("sm_prop", Cmd_Prop, "Lets a person buy a prop.");
	HookEvent("round_start", Event_OnRoundStart);
}

public OnMapStart()
{
	ParsePropList();
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("\x04[!prop]: Type !prop to buy barricade items.");
}

public Action:Cmd_Prop(client, args)
{
	if(!client)
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04You must be alive to do this.");
		return Plugin_Handled;
	}
	DisplayMenu(g_hPropList, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

ParsePropList()
{
	decl String:sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/proplist.cfg");
	
	if(!FileExists(sFile))
		SetFailState("Config file %s does not exists.", sFile);
	
	g_hKV = CreateKeyValues("proplist");
	FileToKeyValues(g_hKV, sFile);
	
	if(!KvGotoFirstSubKey(g_hKV))
		SetFailState("Error parsing config file %s.", sFile);
	
	g_hPropList = CreateMenu(Menu_SpawnProp);
	SetMenuTitle(g_hPropList, "[Spawn A Prop]\nPlease select a prop you'd wish to spawn.\n--------------------");
	SetMenuExitButton(g_hPropList, true);
	decl String:sBuffer[PLATFORM_MAX_PATH], String:sName[64];
	do
	{
		KvGetSectionName(g_hKV, sName, sizeof(sName));
		Format(sBuffer, sizeof(sBuffer), "%s ($%d)", sName, KvGetNum(g_hKV, "cost"));
		AddMenuItem(g_hPropList, sName, sBuffer);
		
		KvGetString(g_hKV, "directory", sBuffer, sizeof(sBuffer));
		PrecacheModel(sBuffer, true);
	}
	while(KvGotoNextKey(g_hKV));
	
	KvRewind(g_hKV);
}

public Menu_SpawnProp(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		KvJumpToKey(g_hKV, info);
		
		new iCosts = KvGetNum(g_hKV, "cost");
		new iMoney = GetEntProp(param1, Prop_Send, "m_iAccount"); 
		
		if(iMoney < iCosts)
		{
			PrintToChat(param1, "\x04You can not afford that right now.");
		}
		else
		{
			decl String:sBuffer[PLATFORM_MAX_PATH];
			
			decl Float:pos[3], Float:normal[3];
			if(GetPlayerEye2(param1, pos, normal))
			{
				SetEntProp(param1, Prop_Send, "m_iAccount", (iMoney - iCosts));
				
				new iEnt = CreateEntityByName("prop_physics");
				if(iEnt != -1)
				{
					KvGetString(g_hKV, "directory", sBuffer, sizeof(sBuffer));
					new Float:AddZ = KvGetFloat(g_hKV, "add-z");
					SetEntityModel(iEnt, sBuffer);
					pos[2] += AddZ;
					TeleportEntity(iEnt, pos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(iEnt);
					ActivateEntity(iEnt);
				}
				
			}
			DisplayMenu(g_hPropList, param1, MENU_TIME_FOREVER);
		}
		KvRewind(g_hKV);
	}
}

stock bool:GetPlayerEye2(client, Float:pos[3], Float:normal[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		TR_GetPlaneNormal(trace, normal);
		GetVectorAngles(normal, normal);
		normal[0] += 90.0;
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}