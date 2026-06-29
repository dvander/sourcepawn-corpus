#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <ToggleEffects>
#include <zombiereloaded>

#define PLUGIN_NAME "[ANY] Hats"
#define PLUGIN_AUTHOR "Zephyrus"
#define PLUGIN_VERSION "1.0.4c"
#define PLUGIN_DESCRIPTION "Hats for everyone, so what?!"
#define PLUGIN_URL ""

#define MAX_CATEGORIES 16
#define MAX_HATS 256
#define MESS "\x04[Hats]\x03 "

enum Hat
{
	String:Name[64],
	String:ModelPath[PLATFORM_MAX_PATH],
	Float:Position[3],
	Float:Angles[3],
	Flags,
	Team,
	Category
}

new Handle:g_hLookupAttachment = INVALID_HANDLE;
new Handle:g_hEquippedHats[MAX_CATEGORIES] = {INVALID_HANDLE, ...};
new Handle:g_hCvarRemove = INVALID_HANDLE;

new bool:g_bToggleEffects = false;
new bool:g_bZombieReloaded = false;
new bool:g_bRemove = false;

new g_iHatCache[MAXPLAYERS+1][MAX_CATEGORIES];
new g_iHats[MAXPLAYERS+1][MAX_CATEGORIES];
new g_iDefaults[MAX_CATEGORIES] = {-1, ...}
new g_iNumHats = 0;
new g_iCategories = 0;

new g_eHats[MAX_HATS][Hat];

new String:g_sCategories[MAX_CATEGORIES][64];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	RegConsoleCmd("sm_hats", Command_Hats);
	
	RegServerCmd("sm_hats_default", Command_Default);
	
	g_hCvarRemove = CreateConVar("sm_hats_remove", "0", "Whether to remove hats on death");
	
	HookConVarChange(g_hCvarRemove, Callback_ConVarChanged);
	
	AutoExecConfig();
	
	new String:tmp[64];
	for(new i=0;i<MAX_CATEGORIES;++i)
	{
		Format(tmp, 64, "EquippedHatSlot%d", i);
		g_hEquippedHats[i] = RegClientCookie(tmp, tmp, CookieAccess_Private);
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_bToggleEffects = LibraryExists("ToggleEffects");
	g_bZombieReloaded = LibraryExists("zombiereloaded");
	
	new Handle:hGameConf = LoadGameConfigFile("hats.gamedata");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hLookupAttachment = EndPrepSDKCall();
}

public OnMapStart()
{
	LoadHats();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("ZR_IsClientHuman"); 
	MarkNativeAsOptional("ZR_IsClientZombie"); 
	return APLRes_Success;
}

public Callback_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hCvarRemove)
		g_bRemove = GetConVarBool(convar);
}

public OnClientConnected(client)
{
	for(new i=0;i<MAX_CATEGORIES;++i)
		g_iHatCache[client][i]=-1;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	for(new i=0;i<MAX_CATEGORIES;++i)
		g_iHatCache[client][i]=-1;
		
	RemoveHats(client);
}

public OnClientCookiesCached(client)
{
	new String:model[PLATFORM_MAX_PATH];
	for(new i=0;i<MAX_CATEGORIES;++i)
	{
		GetClientCookie(client, g_hEquippedHats[i], model, sizeof(model));
		
		g_iHatCache[client][i] = ItemExists_Hat(model);
		
		if(g_iHatCache[client][i]==-1)
		{
			SetClientCookie(client, g_hEquippedHats[i], "");
			g_iHatCache[client][i]=g_iDefaults[i];
		}
	}
}

stock LookupAttachment(client, String:point[])
{
    if(g_hLookupAttachment==INVALID_HANDLE) return 0;
    if( client<=0 || !IsClientInGame(client) ) return 0;
    return SDKCall(g_hLookupAttachment, client, point);
}

public LoadHats()
{
	g_iCategories = 0;
	g_iNumHats = 0;

	for(new i=0;i<MAX_CATEGORIES;++i)
		g_sCategories[i]="";
	for(new i=0;i<MAX_HATS;++i)
		g_eHats[i][Category]=-1;
	
	new String:sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/hats.txt");
	
	new Handle:kv = CreateKeyValues("Hats");
	FileToKeyValues(kv, sConfig);

	new Float:temp[3];
	new String:sTemp[2];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, g_sCategories[g_iCategories], 64);
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, g_eHats[g_iNumHats][Name], 64);
					KvGetString(kv, "model", g_eHats[g_iNumHats][ModelPath], PLATFORM_MAX_PATH);
					KvGetString(kv, "flag", sTemp, 2);
					g_eHats[g_iNumHats][Flags] = ReadFlagString(sTemp);
					KvGetVector(kv, "position", temp);
					g_eHats[g_iNumHats][Position] = temp;
					KvGetVector(kv, "angles", temp);
					g_eHats[g_iNumHats][Angles] = temp;
					g_eHats[g_iNumHats][Team] = KvGetNum(kv, "team");
					g_eHats[g_iNumHats][Category] = g_iCategories;
					
					if(strcmp(g_eHats[g_iNumHats][ModelPath], "")!=0 && (FileExists(g_eHats[g_iNumHats][ModelPath]) || FileExists(g_eHats[g_iNumHats][ModelPath], true)))
						PrecacheModel(g_eHats[g_iNumHats][ModelPath], true);
					
					++g_iNumHats;
				} while (KvGotoNextKey(kv));
			}
			KvGoBack(kv);
			g_iCategories++;
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	RemoveHats(client);
		
	CreateTimer(0.0, Timer_SpawnPostPost, client);
	
	return Plugin_Continue;
}

public Action:Timer_SpawnPostPost(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			for(new i=0;i<MAX_CATEGORIES;++i)
				if(g_iHatCache[client][i]!=-1)
					CreateHat(client, i);
		}
	}
		
	return Plugin_Stop;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	RemoveHats(client);
	
	return Plugin_Continue;
}

public Action:Command_Default(args)
{
	if(args != 2)
	{
		ReplyToCommand(0, "Usage: sm_hats_default <slot> <model>");
		return Plugin_Handled;
	}
	
	new String:sId[4];
	GetCmdArg(1, sId, 4);
	
	new cat = StringToInt(sId);
	if(cat > g_iCategories-1)
	{
		ReplyToCommand(0, "Invalid slot value (max is %d)", g_iCategories);
		return Plugin_Handled;
	}
	
	new String:sModel[PLATFORM_MAX_PATH];
	GetCmdArg(2, sModel, PLATFORM_MAX_PATH);
	
	g_iDefaults[cat] = ItemExists_Hat(sModel);
	
	return Plugin_Handled;
}

public Action:Command_Hats(client, args)
{
	if(!LookupAttachment(client, "forward"))
	{
		PrintToChat(client, "%sSorry, but the model you are using doesn't support hats.", MESS)
		return Plugin_Handled;
	}
	if(GetNumHats(client, -1) == 0)
	{
		PrintToChat(client, "%sSorry, there aren't any hats in the menu.", MESS)
		return Plugin_Handled;
	}
	DisplayMenu(CreateHatsMenu(client, -1), client, 0);
	return Plugin_Handled;
}

public Handle:CreateHatsMenu(client, category)
{	
	new Handle:hMenu = CreateMenu(Handler_Hats);
	new String:id[11];
	
	if(category==-1)
	{
		new cat;
		if(GetNumCategories(client, cat)==1)
		{
			return CreateHatsMenu(client, cat);
		}
		else
		{
			SetMenuTitle(hMenu, "Hats Menu");
			for(new i=0;i<MAX_CATEGORIES;++i)
			{			
				if(GetNumHats(client, i)==0)
					continue;
					
				IntToString((i+1)*-1, id, sizeof(id));
				
				AddMenuItem(hMenu, id, g_sCategories[i]);
			}
		}
	}
	else
	{
		if(g_iCategories>1)
			SetMenuExitBackButton(hMenu, true);
			
		SetMenuTitle(hMenu, g_sCategories[category]);
	
		for(new i=0;i<MAX_HATS;++i)
		{
			if(g_eHats[i][Category]!=category)
				continue;
				
			IntToString(i, id, sizeof(id));
			
			if(!CompareTeam(client, g_eHats[i][Team]))
				continue;
		
			if(g_eHats[i][Flags] != 0 && (!(GetUserFlagBits(client) & g_eHats[i][Flags]) && !(GetUserFlagBits(client) & ADMFLAG_ROOT)))
				continue;
			
			AddMenuItem(hMenu, id, g_eHats[i][Name], (i==g_iHatCache[client][g_eHats[i][Category]]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT));
		}
	}
	
	return hMenu;
}

public Handler_Hats(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:id[11];
		GetMenuItem(menu, param2, id, sizeof(id));
		
		new i = StringToInt(id);
		
		if(i<0)
		{
			i=(i+1)*-1;
			DisplayMenu(CreateHatsMenu(client, i), client, 0);
		}
		else
		{
			g_iHatCache[client][g_eHats[i][Category]] = i;
			SetClientCookie(client, g_hEquippedHats[g_eHats[i][Category]], g_eHats[i][ModelPath]);

			if(IsPlayerAlive(client))
				RemoveHat(client, g_eHats[i][Category]);
					
			
			if(IsPlayerAlive(client) && strcmp(g_eHats[i][ModelPath], "")!=0)
			{
				CreateHat(client, g_eHats[i][Category]);
				PrintToChat(client, "%sYou have successfully equipped the \x04%s\x03.", MESS, g_eHats[i][Name]);
			}
			
			DisplayMenu(CreateHatsMenu(client, g_eHats[i][Category]), client, 0);
		}
	}
	else if ((action == MenuAction_Cancel))
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayMenu(CreateHatsMenu(client, -1), client, 0);
		}
	} else if ((action == MenuAction_End))
	{
		CloseHandle(menu);
	}
}

CreateHat(client, slot)
{	
	if(!LookupAttachment(client, "forward"))
		return;

	if(g_eHats[g_iHatCache[client][slot]][Team] != 0 && GetClientTeam(client) != g_eHats[g_iHatCache[client][slot]][Team])
		return;

	new Float:or[3];
	new Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	GetClientAbsOrigin(client,or);
	GetClientAbsAngles(client,ang);
	
	ang[0] += g_eHats[g_iHatCache[client][slot]][Angles][0];
	ang[1] += g_eHats[g_iHatCache[client][slot]][Angles][1];
	ang[2] += g_eHats[g_iHatCache[client][slot]][Angles][2];

	new Float:fOffset[3];
	fOffset[0] = g_eHats[g_iHatCache[client][slot]][Position][0];
	fOffset[1] = g_eHats[g_iHatCache[client][slot]][Position][1];
	fOffset[2] = g_eHats[g_iHatCache[client][slot]][Position][2];

	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
	
	new ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", g_eHats[g_iHatCache[client][slot]][ModelPath]);
	DispatchKeyValue(ent, "spawnflags", "4");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);	
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	
	g_iHats[client][slot]=ent;
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	
	TeleportEntity(ent, or, ang, NULL_VECTOR); 
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	SetVariantString("forward");
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
}

RemoveHats(client)
{
	for(new i=0;i<MAX_CATEGORIES;++i)
	{
		RemoveHat(client, i);
	}
}

RemoveHat(client, slot)
{
	if(IsValidEntity(g_iHats[client][slot]) && g_iHats[client][slot] > MaxClients)
	{
		SDKUnhook(g_iHats[client][slot], SDKHook_SetTransmit, ShouldHide);
		AcceptEntityInput(g_iHats[client][slot], "Kill");
	}
	g_iHats[client][slot]=0;
}

public Action:ShouldHide(ent, client)
{
	if(g_bToggleEffects)
		if(!ShowClientEffects(client))
			return Plugin_Handled;
			
	for(new i=0;i<MAX_CATEGORIES;++i)
		if(ent == g_iHats[client][i])
			return Plugin_Handled;
			
	if(IsClientInGame(client))
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")>=0)
			for(new i=0;i<MAX_CATEGORIES;++i)
				if(ent == g_iHats[GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")][i])
					return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(!g_bRemove)
		if(GetClientHealth(victim)-damage<=0)
		{
			for(new i=0;i<MAX_CATEGORIES;++i)
			{
				if(IsValidEdict(g_iHats[victim][i]) && g_iHats[victim][i] > MaxClients)
				{
					new String:sModel[PLATFORM_MAX_PATH];
					GetEntPropString(g_iHats[victim][i], Prop_Data, "m_ModelName", sModel, PLATFORM_MAX_PATH);
					new Float:fPos[3];
					GetClientEyePosition(victim, fPos);
					
					new ent = CreateEntityByName("prop_physics");
					SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
					SetEntityModel(ent, sModel);
					DispatchSpawn(ent);
					
					TeleportEntity(ent, fPos, NULL_VECTOR, damageForce);
				}
			}
		}
	return Plugin_Continue;
}

public ItemExists_Hat(const String:data[])
{
	for(new i=0;i<MAX_HATS;++i)
	{
		if(strcmp(g_eHats[i][ModelPath], data)==0 && strcmp(data, "")!=0)
			return i;
	}
	return -1;
}

GetNumCategories(client, &category=0)
{
	new count = 0;

	for(new i=0;i<g_iCategories;++i)
		if(GetNumHats(client, i)>0)
		{
			category=i;
			count++;
		}
			
	return count;
}

GetNumHats(client, category)
{
	new flags = GetUserFlagBits(client);
	new count = 0;

	if(category==-1)
	{
		for(new i=0;i<g_iCategories;++i)
			count+=GetNumHats(client, i);
	}
	else
	{		
		for(new i=0;i<g_iNumHats;++i)
		{
			if(g_eHats[i][Category] == category && (g_eHats[i][Flags]==0?true:bool:(flags & g_eHats[i][Flags])) && CompareTeam(client, g_eHats[i][Team]))
				count++;
		}
	}
	
	return count;
}

bool:CompareTeam(client, team)
{
	new cteam = GetClientTeam(client);
	if(team==0)
		return true;
	if(g_bZombieReloaded)
	{
		if(team==2 && ZR_IsClientZombie(client) || team==3 && ZR_IsClientHuman(client))
		{
			return true;
		}
	}
	else
	{
		if(cteam == team)
		{
			return true;
		}
	}
	return false;
}