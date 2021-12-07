//Thirdperson by DarthNinja, Edited by Twin_Future

/*****************************************************************


			L I B R A R Y   I N C L U D E S


*****************************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.2.0"

/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

new bool:g_bThirdPersonEnabled[MAXPLAYERS+1] = false;

/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo =
{
	name = "[TF2] Thirdperson",
	author = "DarthNinja, Edited by Twin_Future",
	description = "Allows players to use thirdperson without having to enable client sv_cheats",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart()
{
	//LoadTranslations("thirdperson.phrases");
	CreateConVar("thirdperson_version", PLUGIN_VERSION, "Plugin Version",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_thirdperson", EnableThirdperson, ADMFLAG_BAN, "Usage: sm_thirdperson <#userid|name>");
	RegAdminCmd("tp", EnableThirdperson, 0, "Usage: sm_thirdperson");
	RegAdminCmd("sm_firstperson", DisableThirdperson, ADMFLAG_BAN, "Usage: sm_firstperson <#userid|name>");
	RegAdminCmd("fp", DisableThirdperson, 0, "Usage: sm_firstperson");
	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_class", OnPlayerSpawned);
}

public OnClientDisconnect(client)
{
	g_bThirdPersonEnabled[client] = false;
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	if (g_bThirdPersonEnabled[GetClientOfUserId(userid)])
		CreateTimer(0.2, SetViewOnSpawn, userid);
}

public Action:SetViewOnSpawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client != 0)	//Checked g_bThirdPersonEnabled in hook callback, dont need to do it here~
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

public Action:EnableThirdperson(client, args)
{
	decl String:target[32];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	//validate args
	if (args < 1)
	{
		new String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PerformThirdPerson(client,client);
		ShowActivity2(client, "[SM] ", "%s 3rd Person Enabled", name);
		return Plugin_Handled;
	}
	else
	{
		if (!CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN))
		{	
			ReplyToCommand(client, "[SM] Usage: tp");
			return Plugin_Handled;
		}
		else
		{
			//get argument
			GetCmdArg(1, target, sizeof(target));		
			
			//get target(s)
			if ((target_count = ProcessTargetString(
					target,
					client,
					target_list,
					MAXPLAYERS,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for (new i = 0; i < target_count; i++)
			{
				PerformThirdPerson(client,target_list[i]);
			}
			
			ShowActivity2(client, "[SM] ", "%s 3rd Person Enabled", target_name);
			return Plugin_Handled;
		}
	}
}

public Action:DisableThirdperson(client, args)
{
	decl String:target[32];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//validate args
	if (args < 1)
	{
		new String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PerformFirstPerson(client,client);
		ShowActivity2(client, "[SM] ", "%s 1st Person Enabled", name);
		return Plugin_Handled;
	}
	else
	{
		if (!CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN))
		{		
			ReplyToCommand(client, "[SM] Usage: fp");
			return Plugin_Handled;
		}
		else
		{
			//get argument
			GetCmdArg(1, target, sizeof(target));		
			
			//get target(s)
			if ((target_count = ProcessTargetString(
					target,
					client,
					target_list,
					MAXPLAYERS,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for (new i = 0; i < target_count; i++)
			{
				PerformFirstPerson(client,target_list[i]);
			}
			
			// Translated version
			//ShowActivity2(client, "[SM] ", "%t", "3rd Person Enabled", target_name);
			ShowActivity2(client, "[SM] ", "%s 1st Person Enabled", target_name);
			return Plugin_Handled;
		}
	}
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

PerformThirdPerson(client, target)
{
	SetVariantInt(1);
	AcceptEntityInput(target, "SetForcedTauntCam");
	g_bThirdPersonEnabled[target] = true;
	LogAction(client,target, "\"%L\" 3rd Person Enabled \"%L\"" , client, target);
}

PerformFirstPerson(client, target)
{
	SetVariantInt(0);
	AcceptEntityInput(target, "SetForcedTauntCam");
	g_bThirdPersonEnabled[target] = false;
	LogAction(client,target, "\"%L\" 1st Person Enabled \"%L\"" , client, target);
}
