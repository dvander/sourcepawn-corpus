#pragma semicolon 1
#include <tf2_stocks>
#include <morecolors>

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo =
{
	name = "Fake and Force Unlimited",
	author = "MasterOfTheXP",
	description = "Fake stuff, force stuff...what more could you want?",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

// These limits are already insane. But if you really need to increase them...
#define ANNOUNCE_MAXITEMS 16
#define ANNOUNCE_ITEMNAME_LEN 96

new Handle:hConfig;

new Handle:cvarImmunity;

new Float:NextUseTime[MAXPLAYERS + 1];

public OnPluginStart()
{
	new String:Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "configs/fakeandforce.txt");
	hConfig = CreateKeyValues("FakeAndForce");
	if (!FileToKeyValues(hConfig, Path))
		SetFailState("Ohe nose! Fake and Force can't find its config at %s, and it can't run without it! Would you kindly make sure the config is installed?", Path);
	
	KvGotoFirstSubKey(hConfig);
	do {
		new String:cmd[96];
		KvGetSectionName(hConfig, cmd, sizeof(cmd));
		RegAdminCmd(cmd, CommandCallback, 0);
		
		for (new i = 0; i <= 1; i++)
		{
			new String:Sound[PLATFORM_MAX_PATH];
			KvGetString(hConfig, i ? "emit" : "sound", Sound, sizeof(Sound));
			if (strlen(Sound))
			{
				PrecacheSound(Sound, true);
				if (!FileExists(Sound, true))
				{
					new String:str[PLATFORM_MAX_PATH];
					Format(str, sizeof(str), "sound/%s", Sound);
					AddFileToDownloadsTable(str);
				}
			}
		}
		
		
	} while (KvGotoNextKey(hConfig));
	
	CreateConVar("sm_fakeandforce_version", PLUGIN_VERSION, "Plugin version. Please don't touch.", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarImmunity = CreateConVar("sm_fakeandforce_immunity", "1", "If 1, immunity applies to announce commands.", _, true, 0.0, true, 1.0);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public Action:CommandCallback(client, args)
{
	new String:cmd[192];
	GetCmdArg(0, cmd, sizeof(cmd));
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, cmd);
	
	new String:override[96], String:override_admin[96], bool:donator;
	KvGetString(hConfig, "override", override, sizeof(override));
	KvGetString(hConfig, "override_admin", override_admin, sizeof(override_admin));
	
	if (!CheckCommandAccess(client, override_admin, ADMFLAG_ROOT))
	{
		if (!CheckCommandAccess(client, override, ADMFLAG_ROOT))
		{
			ReplyToCommand(client, "[SM] %t.", "No Access");
			return Plugin_Handled;
		}
		donator = true;
	}
	
	if (donator)
	{
		new Float:time = GetTickedTime();
		if (NextUseTime[client] > time)
		{
			new next = RoundFloat(NextUseTime[client]-time);
			ReplyToCommand(client, "[SM] You must wait %i second%s before using Fake and Force again.", next, next != 1 ? "s" : "");
			return Plugin_Handled;
		}
	}
	
	new String:type[25];
	KvGetString(hConfig, "type", type, sizeof(type));
	if (!strlen(type)) ThrowError("FaF command %s does not have a type", cmd);
	
	if (StrEqual(type, "announce", false))
	{
		new items = KvGetNum(hConfig, "items", 1);
		if (items > ANNOUNCE_MAXITEMS) ThrowError("FaF command %s has %i arguments. The limit is %i. Change ANNOUNCE_MAXITEMS and recompile the plugin if you really need more for some reason...", cmd, items, ANNOUNCE_MAXITEMS);
		
		if ((args < items && donator) || (args < items+1 && !donator))
		{
			new String:usage[192];
			Format(usage, sizeof(usage), "[SM] Usage: %s%s%s", cmd, !donator ? " <client>" : "", items == 1 ? " <item>" : "");
			if (items > 1)
				for (new i = 1; i <= items; i++)
					Format(usage, sizeof(usage), "%s <\"item %i\">", usage, i);
			ReplyToCommand(client, usage);
			return Plugin_Handled;
		}
		
		new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		new String:item_names[ANNOUNCE_MAXITEMS][ANNOUNCE_ITEMNAME_LEN];
		
		if (items == 1)
		{
			if (!donator)
			{
				new String:argstr[MAX_TARGET_LENGTH+192], String:arg1[MAX_TARGET_LENGTH];
				GetCmdArgString(argstr, sizeof(argstr));
				new len = BreakString(argstr, arg1, sizeof(arg1));
				if (len == -1)
				{
					len = 0;
					argstr[0] = '\0';
				}
				Format(item_names[0], sizeof(item_names[]), argstr[len]);
				StripQuotes(item_names[0]);
				
				if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, (GetConVarBool(cvarImmunity) ? 0 : COMMAND_FILTER_NO_IMMUNITY), target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(client, target_count);
					return Plugin_Handled;
				}
			}
			else
			{
				GetClientName(client, target_name, sizeof(target_name));
				target_list[0] = client, target_count = 1;
				GetCmdArgString(item_names[0], sizeof(item_names[]));
			}
		}
		else // Either more than one, or no items.
		{
			if (!donator)
			{
				new String:arg1[MAX_TARGET_LENGTH+1];
				GetCmdArg(1, arg1, sizeof(arg1));
				
				if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, (GetConVarBool(cvarImmunity) ? 0 : COMMAND_FILTER_NO_IMMUNITY), target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(client, target_count);
					return Plugin_Handled;
				}
			}
			else
			{
				GetClientName(client, target_name, sizeof(target_name));
				target_list[0] = client, target_count = 1;
			}
			
			for (new i = 0; i < items; i++)
				GetCmdArg(i + (donator ? 1 : 2), item_names[i], sizeof(item_names[]));
		}
		
		new String:text[193], String:particle[64], String:sound[PLATFORM_MAX_PATH],
		String:emit[PLATFORM_MAX_PATH], String:playgamesound[PLATFORM_MAX_PATH], bool:noteam = bool:KvGetNum(hConfig, "noteam"),
		Float:particle_life = KvGetFloat(hConfig, "particle_life", 10.0), Float:particle_offs[3], forceCase = KvGetNum(hConfig, "case", -1);
		KvGetString(hConfig, "text", text, sizeof(text));
		KvGetString(hConfig, "sound", sound, sizeof(sound));
		KvGetString(hConfig, "emit", emit, sizeof(emit));
		KvGetString(hConfig, "playgamesound", playgamesound, sizeof(playgamesound));
		KvGetString(hConfig, "particle", particle, sizeof(particle));
		KvGetVector(hConfig, "particle_offs", particle_offs);
		
		if (KvGetNum(hConfig, "quality"))
		{
			for (new i = 0; i < items; i++)
			{
				new bool:unique;
				if (!StrContains(item_names[i], "Vintage Tyrolean", false) ||
				!StrContains(item_names[i], "Vintage Merryweather", false) ||
				!StrContains(item_names[i], "Strange Part", false) ||
				!StrContains(item_names[i], "Haunted Hat", false)) unique = true;
				else if (!StrContains(item_names[i], "Vintage ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Vintage ", "\x07576291", _, _, false);
				else if (!StrContains(item_names[i], "Strange ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Strange ", "\x07CF6A32", _, _, false);
				else if (!StrContains(item_names[i], "Genuine ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Genuine ", "\x074D7455", _, _, false);
				else if (!StrContains(item_names[i], "Unusual ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Unusual ", "\x078650AC", _, _, false);
				else if (!StrContains(item_names[i], "Haunted ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Haunted ", "\x0738F3AB", _, _, false);
				else if (!StrContains(item_names[i], "Valve ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Valve ", "\x07A50F79", _, _, false);
				else if (!StrContains(item_names[i], "Community ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Community ", "\x0770B04A", _, _, false);
				else if (!StrContains(item_names[i], "Self-Made ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Self-Made ", "\x0770B04A", _, _, false);
				else if (!StrContains(item_names[i], "Collector's ", false)) ReplaceStringEx(item_names[i], sizeof(item_names[]), "Collector's ", "\x07830000", _, _, false);
				else unique = true;
				
				if (unique) Format(item_names[i], sizeof(item_names[]), "\x07FFD700%s", item_names[i]);
			}
		}
		
		if (forceCase > -1)
		{
			for (new i = 0; i < items; i++)
			{
				new len = strlen(item_names[i]);
				for (new j = 0; j < len; j++)
				{
					if (forceCase && IsCharLower(item_names[i][j])) item_names[i][j] = CharToUpper(item_names[i][j]);
					else if (!forceCase && IsCharUpper(item_names[i][j])) item_names[i][j] = CharToLower(item_names[i][j]);
				}
			}
		}
		
		for (new i = 0; i < target_count; i++)
		{
			new target = target_list[i];
			new String:name[MAX_NAME_LENGTH+10], String:str[193];
			if (!noteam)
			{
				switch (GetClientTeam(target))
				{
					case (_:TFTeam_Spectator): Format(name, sizeof(name), "\x07CCCCCC%N\x01", target);
					case (_:TFTeam_Red): Format(name, sizeof(name), "\x07FF4040%N\x01", target);
					case (_:TFTeam_Blue): Format(name, sizeof(name), "\x0799CCFF%N\x01", target);
				}
			}
			else GetClientName(target, name, sizeof(name));
			
			Format(str, sizeof(str), text);
			if (strlen(str))
			{
				ReplaceString(str, sizeof(str), "{PLAYER}", name);
				for (new j = 0; j < items; j++)
				{
					new String:key[20];
					Format(key, sizeof(key), "{ITEM%i}", j+1);
					ReplaceString(str, sizeof(str), key, item_names[j]);
				}
				ReplaceString(str, sizeof(str), "{UNIQUE}", "\x07FFD700");
				ReplaceString(str, sizeof(str), "{VINTAGE}", "\x07576291");
				ReplaceString(str, sizeof(str), "{STRANGE}", "\x07CF6A32");
				ReplaceString(str, sizeof(str), "{GENUINE}", "\x074D7455");
				ReplaceString(str, sizeof(str), "{UNUSUAL}", "\x078650AC");
				ReplaceString(str, sizeof(str), "{HAUNTED}", "\x0738F3AB");
				ReplaceString(str, sizeof(str), "{VALVE}", "\x07A50F79");
				ReplaceString(str, sizeof(str), "{COMMUNITY}", "\x0770B04A");
				ReplaceString(str, sizeof(str), "{COLLECTOR}", "\x07830000");
				
				CPrintToChatAll(str);
			}
			
			if (strlen(emit)) EmitSoundToAll(emit, target);
			
			if (strlen(particle))
			{
				new particle_ent = CreateEntityByName("info_particle_system");
				DispatchKeyValue(particle_ent, "effect_name", particle);
				new Float:pos[3];
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
				for (new j = 0; j <= 2; j++)
					pos[j] += particle_offs[j];
				TeleportEntity(particle_ent, pos, NULL_VECTOR, NULL_VECTOR);
				SetVariantString("!activator");
				AcceptEntityInput(particle_ent, "SetParent", target);
				DispatchSpawn(particle_ent);
				ActivateEntity(particle_ent);
				AcceptEntityInput(particle_ent, "Start");
				CreateTimer(particle_life, Timer_RemoveEntity, EntIndexToEntRef(particle_ent), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if (strlen(sound)) EmitSoundToAll(sound);
		
		if (strlen(playgamesound))
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				if (IsFakeClient(i)) continue;
				ClientCommand(i, "playgamesound %s", playgamesound);
			}
		}
	}
	else if (StrEqual(type, "command", false))
	{
		new String:cmd_string[256];
		KvGetString(hConfig, "cmd", cmd_string, sizeof(cmd_string));
		
		if ((!args && donator) || (args < 2 && !donator))
		{
			if (StrContains(cmd_string, "{PARAMS}") > -1)
			{
				ReplyToCommand(client, "[SM] Usage: %s%s <arguments>", cmd, !donator ? " <client>" : "");
				return Plugin_Handled;
			}
		}
		
		// Compiler doesn't like these using the same variable names as above. Bug?
		new String:targetName[MAX_TARGET_LENGTH], targetList[MAXPLAYERS], targetCount, bool:tnIsML;
		new String:custom_params[96];
		
		if (!donator)
		{
			new String:argstr[MAX_TARGET_LENGTH+192], String:arg1[MAX_TARGET_LENGTH];
			GetCmdArgString(argstr, sizeof(argstr));
			new len = BreakString(argstr, arg1, sizeof(arg1));
			if (len == -1)
			{
				len = 0;
				argstr[0] = '\0';
			}
			Format(custom_params, sizeof(custom_params), argstr[len]);
			StripQuotes(custom_params);
			
			if ((targetCount = ProcessTargetString(arg1, client, targetList, MAXPLAYERS, (GetConVarBool(cvarImmunity) ? 0 : COMMAND_FILTER_NO_IMMUNITY), targetName, sizeof(targetName), tnIsML)) <= 0)
			{
				ReplyToTargetError(client, targetCount);
				return Plugin_Handled;
			}
		}
		else
		{
			GetClientName(client, target_name, sizeof(target_name));
			targetList[0] = client, targetCount = 1;
			GetCmdArgString(custom_params, sizeof(custom_params));
		}
		
		new bool:force = bool:KvGetNum(hConfig, "force");
		
		for (new i = 0; i < targetCount; i++)
		{
			new target = targetList[i];
			new String:name[MAX_NAME_LENGTH+1], String:strUid[7], String:str[288];
			GetClientName(target, name, sizeof(name));
			Format(strUid, sizeof(strUid), "%i", GetClientUserId(target));
			
			Format(str, sizeof(str), cmd_string);
			ReplaceString(str, sizeof(str), "{PARAMS}", custom_params);
			ReplaceString(str, sizeof(str), "{PLAYER}", name);
			ReplaceString(str, sizeof(str), "{PLAYERUID}", strUid);
			
			if (!force) FakeClientCommand(target, str);
			else ClientCommand(target, str);
		}
	}
	else ThrowError("FaF command %s uses an invalid type: %s", cmd, type);
	
	if (donator) NextUseTime[client] = GetTickedTime()+KvGetNum(hConfig, "cooldown");
	return Plugin_Handled;
}

public Action:Timer_RemoveEntity(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent <= MaxClients) return;
	AcceptEntityInput(ent, "Kill");
}

public OnClientConnected(client)
	NextUseTime[client] = 0.0;