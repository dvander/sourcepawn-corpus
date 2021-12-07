#include <sourcemod>
#include <sdktools>
#define DEF_STRINGSIZE 32

#pragma semicolon 1

#define VERSION "1.2"

static const String:Models[][]={"arse", "bastard", "bitch", "dick", "faggot", "shit", "wanker", "penis", "dildo", "motherfucker", "cocksucker", "fag"};	
									
new Handle:kick = INVALID_HANDLE;
new Handle:h_mode = INVALID_HANDLE;
new bool:random;
new bool:remove;
new bool:ignore;
new bool:bForceModel[MAXPLAYERS + 1];
new String:sForceModel[MAXPLAYERS +1][DEF_STRINGSIZE];
new String:g_sModel[DEF_STRINGSIZE];
public Plugin:myinfo = 
{
	name = "Halo Models",
	author = "GOERGE",
	description = "Randomly replace a halo model with a badword, or delete them, or do nothing",
	version = VERSION,
	url = "http://fpsbanana.com"
}

public OnPluginStart()
{
	kick = CreateConVar("haloreplace_kick", "1", "Kick clients who who have downloads disabled", FCVAR_PLUGIN);
	h_mode = CreateConVar("haloreplace_mode", "random", 
		"The mode the plugin runs.  If not \"random\", \"none\" or \"remove\", then specify the name of a word to replace.\nValidWords = \"arse\", \"bastard\", \"bitch\", \"dick\", \"fag\", \"faggot\", \"shit\", \"wanker\", \"penis\", \"dildo\", \"motherfucker\", \"cocksucker\"\n Invalid model names leaves the halo intact",
		FCVAR_PLUGIN|FCVAR_NOTIFY);
		
	RegAdminCmd("sm_sethalo", cmd_SetHalo, ADMFLAG_RCON, "Sets a client's halo");
	HookConVarChange(h_mode, change_Callback);
	CreateConVar("haloreplace_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("post_inventory_application", hook, EventHookMode_Post);
	HookEvent("player_spawn", hook, EventHookMode_Post);
	//HookEvent("player_death", hook_Death, EventHookMode_Post);
	LoadTranslations("common.phrases");
}

/*
public Action:hook_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt;
	if ((iEnt = (HasHalo(GetClientOfUserId(GetEventInt(event, "userid"))))))
		RemoveEdict(iEnt);

}*/

public change_Callback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	random = false;
	remove = false;
	ignore = false;
	if (StrEqual(newValue, "remove", false))
		remove = true;
	else if (StrEqual(newValue, "random", false))
		random = true;
	else if (StrEqual(newValue, "none", false))
		ignore = true;
	else if (IsValid(newValue))
		strcopy(g_sModel, sizeof(g_sModel), newValue);
	else
		ignore = true;
}

public Action:cmd_SetHalo(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_sethalo <client|#id|@target> <modelName|remove|clear>");
		return Plugin_Handled;
	}
	new String:target[MAX_NAME_LENGTH], String:model[DEF_STRINGSIZE], bool:Remove = false, bool:clear = false, bool:tn_is_ml, String:targetName[MAX_NAME_LENGTH],
				targetList[MAXPLAYERS], targetCount;
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, model, sizeof(model));
	
	if (StrEqual(model, "remove", false))
		Remove = true;
	else if (StrEqual(model, "clear", false))
		clear = true;
	else if (!IsValid(model, true))
	{
		ReplyToCommand(client, "That model does not exist on this server");
		return Plugin_Handled;
	}		
	if (!(targetCount = ProcessTargetString(target,
                           client, 
                           targetList,
                           sizeof(targetList),
                           COMMAND_FILTER_ALIVE,
                           targetName,
                           sizeof(targetName),
                           tn_is_ml)))
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	else
	{
		new iEnt, bool:consoleMessage = false;
		for (new i = 0; i < targetCount; i++)
		{
			if (clear)
			{
				bForceModel[targetList[i]] = false;
				sForceModel[targetList[i]] = "";
				continue;
			}
			else
			{
				bForceModel[targetList[i]] = true;
				strcopy(sForceModel[targetList[i]], DEF_STRINGSIZE, model);
			}
			
			if ((iEnt = HasHalo(targetList[i])))
			{
				if (Remove)				
					AcceptEntityInput(iEnt, "Kill");					
				else
					SetModel(iEnt, model);			
			}
			else
			{
				consoleMessage = true;
				PrintToConsole(client, "Client \"%N\" does not have a halo", targetList[i]);
			}
		}
		if (clear)
			ShowActivity(client, "Reset the halo settings for %s", targetName);
		else if (Remove)
			ShowActivity(client, "Removed any halo belonging to %s", targetName);
		else
			ShowActivity(client, "Set %s to use halo model %s", targetName, model);
		LogAction(client, -1, "\"%L\" executed sm_sethalo %s %s", client, target, model);
		if (consoleMessage && GetCmdReplySource())
			ReplyToCommand(client, "See console for more information");	
	}
	return Plugin_Handled;
}

HasHalo(client)
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable_item")) != -1 )
	{
		if (IsValidEntity(iEnt) && GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex") == 125)
		{		
			if (GetEntDataEnt2(iEnt, FindSendPropOffs("CTFWearableItem", "m_hOwnerEntity")) == client)
				return iEnt;
		}
	}
	return 0;
}

/**
* checks if a model exists and its precached
* if not precached, than it precaches
* if buildPath is specified, then build the path to models/sourcemod/
*/
bool:IsValid(const String:model[], bool:buildPath = false )
{
	decl String:path[200];
	if (buildPath)
	{
		Format(path, sizeof(path), "models/sourcemod/%s.mdl", model);
		if (FileExists(path))
		{
			if (IsModelPrecached(path))
				PrecacheModel(path);
			return true;
		}
		return false;
	}
	if (FileExists(model))
		return true;
	return false;
}

public OnConfigsExecuted()
{
	new String:s_mode[64];
	GetConVarString(h_mode, s_mode, 64);
	random = false;
	remove = false;
	if (StrEqual(s_mode, "remove", false))
		remove = true;
	else if (StrEqual(s_mode, "random", false))
		random = true;
	else	
		strcopy(g_sModel, sizeof(g_sModel), s_mode);	
}		

public Action:hook(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!ignore || bForceModel[client])
		CheckHalo(client);
	return Plugin_Continue;
}

CheckHalo(client)
{
	if (IsFakeClient(client))
		return;
		
	new iEnt;
	if (!(iEnt = HasHalo(client)))
		return;
		
	if (bForceModel[client])
	{
		if (StrEqual(sForceModel[client], "remove", false))
			AcceptEntityInput(iEnt, "Kill");
		else
			SetModel(iEnt, sForceModel[client]);
		return;
	}
	
	if (remove)
	{
		AcceptEntityInput(iEnt, "Kill");
		return;
	}
	
	if (random)
	{
		new rand = GetRandomInt(0, (sizeof(Models) - 1));
		SetModel(iEnt, Models[rand]);
	}	
	else
		SetModel(iEnt, g_sModel);
	return;	
}

public OnClientConnected(client)
{
	bForceModel[client] = false;
	sForceModel[client] = "";
}

stock SetModel(ent, const String:model[])
{
	decl String:path[200];
	Format(path, sizeof(path), "models/sourcemod/%s.mdl", model);
	if (IsValid(path))
		SetEntityModel(ent, path);
}

public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client) && GetConVarBool(kick))
	{
		QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:ClientConVar, client);
	}
}

public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (StrEqual(cvarValue, "none", true))
	{
		KickClient(client, "You must have downloads enabled to join this server");
		LogAction(client, -1, "Kicked client \"%L\" for having downloads disabled", client);
	}
}

public OnMapStart()
{
	new String:path[250];
	decl String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	for (new i = 0; i < sizeof(Models); i++)
	{
		for (new x=0; x < sizeof(extensions); x++)
		{
			Format(path, 250, "models/sourcemod/%s%s", Models[i], extensions[x]);
			if (FileExists(path))
			{
				AddFileToDownloadsTable(path);
				if (!x)
					PrecacheModel(path, true);
			}
			else
				LogError("File does not exist: %s", path);
		}
	}
	decl String:material[120] = "materials/sourcemod/gold.vtf";
	if (FileExists(material))
		AddFileToDownloadsTable(material);
	else
		LogError("Meterial does not exist: %s", material);
	material = "materials/sourcemod/gold.vmt";
	if (FileExists(material))
		AddFileToDownloadsTable(material);
	else
		LogError("Meterial does not exist: %s", material);
}
