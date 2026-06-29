#include <sourcemod>
#include <sdktools>
#define PluginVersion "1.0.1"

new Float:LastEyeAngle[MAXPLAYERS+1][3];
new Float:LastPosition[MAXPLAYERS+1][3];
new Float:LastMovementTime[MAXPLAYERS+1] = {0.0, ...};
new Float:LastCheckTime[MAXPLAYERS+1] = {0.0, ...};
new bool:Ignored[MAXPLAYERS+1] = {false, ...};
new Handle:TimerDelay = INVALID_HANDLE;
new Handle:MaxAfkTime = INVALID_HANDLE;
new Handle:AdminImmune = INVALID_HANDLE;
new MaxPlayers = 0;

public Plugin:myinfo = 
{
	name = "Sammy's Afker Kicker",
	author = "NBK - Sammy-ROCK!",
	description = "Kicks afking users",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	AdminImmune= CreateConVar("sammysafkerkicker_adminimmune",	"1", "Should Sammy's Afker Kicker skip admins?", 0, true, 0.0, true, 1.0);
	CreateConVar("sammysafkerkicker_version", PluginVersion, "Sammy's Afker Kicker version.", 0);
	TimerDelay = CreateConVar("sammysafkerkicker_check_delay", "10.0", "Delay between checks. How low it is heavier is the plugin.", 0, true, 1.0);
	MaxAfkTime = CreateConVar("sammysafkerkicker_time_needed", "300.0", "How long player can stay afk (away from keyboard) before getting kicked", 0, true, 0.1);
	RegAdminCmd("sm_ignoreplayer", Command_IgnorePlayer, ADMFLAG_GENERIC, "Makes Afker Kicker ignore this player.");
	LoadTranslations("common.phrases");
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
	for(new player=1;player<=MaxPlayers;player++)
	{
		if(IsClientInGame(player))
                	CreateTimer(GetConVarFloat(TimerDelay), CheckUser, player);
	}
}

public OnClientPutInServer(client)
{
	if(client > 0)
	{
		LastCheckTime[client] = 0.0;
		Ignored[client] = false;
                CreateTimer(GetConVarFloat(TimerDelay), CheckUser, client);
	}
}

public OnClientDisconnect(client)
{
	LastCheckTime[client] = 0.0;
	Ignored[client] = false;
}

public Action:CheckUser(Handle:timer,any:index)
{
	if(index <= 0 || Ignored[index] || !IsClientInGame(index))
		return;
	new Float:fElapsed = GetEngineTime() - LastCheckTime[index];
	if(fElapsed > GetConVarFloat(TimerDelay) - 2.0)
	{
		CreateTimer(GetConVarFloat(TimerDelay),CheckUser,index);
		LastCheckTime[index] = GetEngineTime();
	}
	else
		return;
	if(GetConVarInt(AdminImmune) && GetUserFlagBits(index))
		return;
	if(CheckPosition(index) && CheckEyeAngle(index))
	{
		new Float:EngineTime = GetEngineTime();
		new Float:TimeNeeded = GetConVarFloat(MaxAfkTime);
		if(EngineTime - LastMovementTime[index] >= TimeNeeded)
		{
			KickClient(index, "Away from keyboard");
			LastMovementTime[index] = GetEngineTime();
		}
		else if(EngineTime - LastMovementTime[index] >= TimeNeeded - 30.0)
		{
			PrintToChat(index, "Warning: Your about to be kicked for afking.");
			PrintToConsole(index, "Warning: Your about to be kicked for afking.");
		}
		return;
	}
	LastMovementTime[index] = GetEngineTime();
}

stock bool:CheckPosition(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	if(pos[0] == LastPosition[client][0] && pos[1] == LastPosition[client][1] && pos[2] == LastPosition[client][2])
		return true;
	LastPosition[client][0] = pos[0];
	LastPosition[client][1] = pos[1];
	LastPosition[client][2] = pos[2];
	return false;
}

stock bool:CheckEyeAngle(client)
{
	decl Float:angle[3];
	GetClientEyeAngles(client, angle);
	if(angle[0] == LastEyeAngle[client][0] && angle[1] == LastEyeAngle[client][1] && angle[2] == LastEyeAngle[client][2])
		return true;
	LastEyeAngle[client][0] = angle[0];
	LastEyeAngle[client][1] = angle[1];
	LastEyeAngle[client][2] = angle[2];
	return false;
}

public Action:Command_IgnorePlayer(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: \"sm_ignoreplayer player\"");
		return Plugin_Handled;
	}
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
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
		new target = target_list[i];
		decl String:Name[MAX_NAME_LENGTH];
		GetClientName(target, Name, sizeof(Name));
		if(Ignored[target])
		{
			Ignored[target] = false;
			ReplyToCommand(client, "\"%s\" will not be ignored by the system.", Name);
		}
		else
		{
			Ignored[target] = true;
			ReplyToCommand(client, "\"%s\" will be ignored by the system.", Name);
		}
	}
	return Plugin_Handled;
}