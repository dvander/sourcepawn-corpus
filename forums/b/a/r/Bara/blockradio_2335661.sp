#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "2.0.3"

new Handle:gH_Enabled = INVALID_HANDLE,
	Handle:gH_Message = INVALID_HANDLE,
	Handle:gH_Nade = INVALID_HANDLE,
	Handle:gH_Ignorenade = INVALID_HANDLE;

new bool:gB_Enabled,
	bool:gB_Message,
	bool:gB_Nade;

new String:RadioCMDS[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog",
	"getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin",
	"getout", "negative","enemydown", "compliment", "thanks", "cheer"};

public Plugin:myinfo = 
{
	name = "[CS:S] Block Radio",
	author = "TimeBomb",
	description = "Blocks all of the radio commucations.",
	version = PLUGIN_VERSION,
	url = "http://hl2.co.il/"
}

public OnPluginStart()
{	
	LoadTranslations("blockradio.phrases");
	
	if(GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("[Block Radio] Failed to load because the only game supported is CS:S/CS:GO.");
	}
	
	for(new i; i < sizeof(RadioCMDS); i++)
	{
		AddCommandListener(BlockRadio, RadioCMDS[i]);
	}
	
	// Console Variables
	gH_Enabled = CreateConVar("sm_blockradio_enabled", "1", "Is \"Block Radio\" enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Enabled = true;
	HookConVarChange(gH_Enabled, ConVarChanged);
	
	gH_Message = CreateConVar("sm_blockradio_message", "1", "Is notifying about blocked radio messages enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Message = true;
	HookConVarChange(gH_Message, ConVarChanged);
	
	gH_Nade = CreateConVar("sm_blockradio_grenade", "1", "Is \"Fire in the hole\" radio sound is supressed?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Nade = true;
	HookConVarChange(gH_Nade, ConVarChanged);
	
	gH_Ignorenade = FindConVar("sv_ignoregrenaderadio");
	SetConVarInt(gH_Ignorenade, 1);
	
	new Handle:Version = CreateConVar("sm_blockradio_version", PLUGIN_VERSION, "\"Block Radio\" plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	AutoExecConfig();
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Nade)
	{
		gB_Nade = StringToInt(newVal)? true:false;
		SetConVarInt(gH_Ignorenade, gB_Nade? 1:0);
	}
	
	else if(cvar == gH_Message)
	{
		gB_Message = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
	}
}

public Action:BlockRadio(client, const String:command[], args) 
{
	if(gB_Enabled)
	{
		if(gB_Message)
		{
			if(IsClientInGame(client))
			{
				PrintToChat(client, "\x04[SM]\x01 %t", "Blocked");
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}