#include <sourcemod>
#include <sdktools>
#include <adt_array>

#define PLUGIN_VERSION "1.3.5"

new	Handle:weapons_list,
	Handle:cvar_centertext,
	Handle:cvar_chattext,
	Handle:cvar_hinttext,
	Handle:cvar_sound,
	Handle:cvar_restrictall,
	Handle:cvar_restrictallbutknife;

public Plugin:myinfo = 
{
        name = "Simple Restrictions",
        author = "karuru",
        description = "Restricts any item, wich can be bought via the buy command.",
        version = PLUGIN_VERSION,
        url = "http://www.sourcemod.com/" 
}


public OnPluginStart()
{
        AddFileToDownloadsTable("sound/admin_plugin/actions/restrictedweapon.wav");
   
        RegAdminCmd("sm_restrict", command_restrict, ADMFLAG_CHEATS);
        RegAdminCmd("sm_unrestrict", command_unrestrict, ADMFLAG_CHEATS);
        
        RegConsoleCmd("restrictions",  command_listrestrict);
        RegConsoleCmd("buy", command_bought);
         
        cvar_centertext = CreateConVar("sm_restrict_centertext","1","Displays the restrict message in the CenterText.", FCVAR_NOTIFY);
        cvar_chattext = CreateConVar("sm_restrict_chattext","0","Displays the restrict message in the Chat.", FCVAR_NOTIFY);
        cvar_hinttext = CreateConVar("sm_restrict_hinttext","0","Displays the restrict message in the HintText.", FCVAR_NOTIFY);
        cvar_sound = CreateConVar("sm_restrict_sound","1","Emits sound to player.", FCVAR_NOTIFY);
        cvar_restrictall = CreateConVar("sm_restrict_all","0","Restricts all weapons.", FCVAR_NOTIFY);
	cvar_restrictallbutknife = CreateConVar("sm_restrict_knife","0","Does not restrict the knife when sm_restrict_all is active.", FCVAR_NOTIFY);
	
        CreateConVar("sm_simplerestrictions_version",PLUGIN_VERSION,"The version of the plugin.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
         
        HookEvent("item_pickup", event_pickup, EventHookMode_Post);
	HookEvent("round_start", event_roundstart, EventHookMode_Post);
	
        AutoExecConfig(true, "simple_restrictions");

        weapons_list = CreateArray(50);
}

public OnMapStart()
{
        PrecacheSound("admin_plugin/actions/restrictedweapon.wav");
}

public Action:command_bought(client, args)
{
	decl String:bought[50];
        GetCmdArgString(bought, sizeof(bought));
        new position = StrContains(bought, "_" )
	
	if( GetConVarBool(cvar_restrictall) )
	{
		event_restrictresponse(client, bought);
		return Plugin_Handled;
	}
	
        if(FindStringInArray(weapons_list, bought[position+1]) >= 0)
        {
                event_restrictresponse(client, bought);
                return Plugin_Handled;
        }
        return Plugin_Continue
}

public Action:command_restrict(client, args)
{
	if(GetConVarBool(cvar_restrictall))
	{
		ReplyToCommand(client, "[SM] You can't restrict a weapon if sm_restrict_all is set to 1.");
                return Plugin_Handled;
	}
	
        if(args < 1)
        {
                ReplyToCommand(client, "[SM] Usage: sm_restrict <item>");
                return Plugin_Handled;
        }
        
        new String:restricted_weapon[50];
        GetCmdArgString(restricted_weapon, sizeof(restricted_weapon));
	new position = StrContains(restricted_weapon, "_");
        PushArrayString(weapons_list, restricted_weapon[position+1]);
        return Plugin_Handled;
}

public  Action:command_unrestrict(client, args)
{
	if(GetConVarBool(cvar_restrictall))
	{
		ReplyToCommand(client, "[SM] You can't unrestrict a weapon if sm_restrict_all is set to 1.");
                return Plugin_Handled;
	}
	
        new String:unrestricted_weapon[50];
        GetCmdArgString(unrestricted_weapon, sizeof(unrestricted_weapon));
	
        if(args < 1)
        {
                ReplyToCommand(client, "[SM] Usage: sm_unrestrict <item>");
                return Plugin_Handled;
        }

	if (strcmp(unrestricted_weapon, "all", false) == 0)
	{
		ClearArray(weapons_list);
	}

	else
	{
		new position = StrContains(unrestricted_weapon, "_");
		new line = FindStringInArray(weapons_list,  unrestricted_weapon[position+1]);
		if(line != -1)
		{
			RemoveFromArray(weapons_list, line);
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public  Action:command_listrestrict(client, args)
{
	if(GetConVarBool(cvar_restrictallbutknife))
	{
		PrintToChat(client, "Every weapon but knife is restricted.");
                return Plugin_Handled;
	}
	
	if(GetConVarBool(cvar_restrictall))
	{
		PrintToChat(client, "Every weapon is restricted.");
                return Plugin_Handled;
	}

        new String:array_string[50];
        new array_size = GetArraySize(weapons_list);

        if(array_size == 0)
        {
		PrintToChat(client, "No weapon is restricted", array_string);
        }
        else
        {
		PrintToChat(client, "The following weapons are restricted:", array_string);
		for(new idx = 0; idx < array_size; idx++)
		{
			GetArrayString(weapons_list, idx, array_string, sizeof(array_string));
			PrintToChat(client, array_string);
		}
	}
        return Plugin_Handled;
}

event_restrictall(client)
{
	new wepIdx;
	for(new i = 0; i <= 5; i++)
	{
		while((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, wepIdx);
			}
	}
	ClientCommand(client, "lastinv");
}

event_restrictallbutknife(client)
{
	new wepIdx;
	for(new i = 0; i <= 5; i++)
	{
		if(i == 2) continue;
		while((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, wepIdx);
			}
	}
	ClientCommand(client, "lastinv");
}

event_stripweapon(client)
{
        new entindex;
        new String: slot_weapon[50];
        for(new i = 0; i <= 5; i++)
        {
                entindex = GetPlayerWeaponSlot(client, i);
                GetEdictClassname(entindex, slot_weapon, sizeof(slot_weapon));
                new position = StrContains(slot_weapon, "_");
                if(FindStringInArray(weapons_list, slot_weapon[position+1]) != -1)
                {
                        event_restrictresponse(client, slot_weapon);       
                        RemovePlayerItem(client, entindex);
                        ClientCommand(client, "lastinv");
                }
        }
}

public event_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt( event, "userid"));
	if(GetConVarBool(cvar_restrictall))
	{
		if(GetConVarBool(cvar_restrictallbutknife))
		{
			event_restrictallbutknife(client);
			return;	
		}
		event_restrictall(client);
                return;
	}
	event_stripweapon(client)
}

public event_roundstart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarBool(cvar_restrictall))
	{
		if(GetConVarBool(cvar_restrictallbutknife))
		{
			event_restrictallbutknife(client);
			return;	
		}
		event_restrictall(client);
                return;
	}
	event_stripweapon(client)
}

event_restrictresponse(client, String:bought[])
{
        if(GetConVarBool(cvar_centertext))
                {
                        PrintCenterText(client, "The weapon %s is restricted on this server!", bought);
                }

        if(GetConVarBool(cvar_chattext))
                {
                        PrintToChat(client, "The  weapon %s is restricted on this server!", bought);
                }

	if(GetConVarBool(cvar_hinttext))
                {
                        PrintHintText(client, "The  weapon %s is restricted on this server!", bought);
                }

	if(GetConVarBool(cvar_sound))
                {
                        EmitSoundToClient(client, "admin_plugin/actions/restrictedweapon.wav");
                }
}