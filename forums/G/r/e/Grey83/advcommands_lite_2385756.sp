#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "include/advcommands.inc"

#define PLUGIN_VERSION "0.16_reduced"

public Plugin:myinfo = 
{
	name = "Advanced admin commands",
	author = "3sigma", // aka X@IDER
	description = "Many useful commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
#if defined ALLOWDEAD
#define FILTER_ALIVE	FILTER_REAL
#else
#define FILTER_ALIVE	COMMAND_FILTER_ALIVE
#endif

#define YELLOW               "\x01"
#define NAME_TEAMCOLOR       "\x02"
#define TEAMCOLOR            "\x03"
#define GREEN                "\x04"

#define GAME_UNKNOWN	0
#define GAME_CSTRIKE	1
#define GAME_DOD		2
#define GAME_TF2		4
#define GAME_HL2MP		8
#define GAME_LEFT4DEAD	16
#define GAME_LEFT4DEAD2	32

#define MAX_CLIENTS		129
#define MAX_ID			32
#define MAX_NAME		96
#define MAX_BUFF_SM		128
#define MAX_BUFF		512

new game = GAME_UNKNOWN;
new bool:g_bSilent = false;
new Handle:hSilent = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Notify", AdvNotify);
	CreateNative("Notify2", AdvNotify2);
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("advcommands");

	CreateConVar("sm_adv_version", PLUGIN_VERSION, "Sourcemod Advanced version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	hSilent = CreateConVar("sm_adv_silent", "0",	"Suppress all notifications", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(hSilent,UpdateCvars);

	decl String:gdir[PLATFORM_MAX_PATH];
	GetGameFolderName(gdir,sizeof(gdir));
	if (StrEqual(gdir,"cstrike",false))		game = GAME_CSTRIKE;	else
	if (StrEqual(gdir,"dod",false))			game = GAME_DOD;		else
	if (StrEqual(gdir,"tf",false))			game = GAME_TF2;		else
	if (StrEqual(gdir,"hl2mp",false))		game = GAME_HL2MP;		else
	if (StrEqual(gdir,"left4dead",false))	game = GAME_LEFT4DEAD;	else
	if (StrEqual(gdir,"left4dead2",false))	game = GAME_LEFT4DEAD2;

	AutoExecConfig(true,"advcommands");

	SetRandomSeed(GetSysTickCount());
}

public UpdateCvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bSilent = GetConVarBool(hSilent);
}

public PrintToChatEx(from,to,const String:format[],any:...)
{
	decl String:message[MAX_BUFF];
	VFormat(message,sizeof(message),format,4);
	
	if ((game == GAME_DOD) || !to)
	{
		PrintToChat(to,message);
		return;
	}

	new Handle:hBf = StartMessageOne("SayText2",to);
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}

public PrintToChatAllEx(from,const String:format[], any:...)
{
	decl String:message[MAX_BUFF];
	VFormat(message,sizeof(message),format,3);
	
	if (game == GAME_DOD)
	{
		PrintToChatAll(message);
		return;
	}

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}

public AdvNotify(Handle:plugin,numParams)
{
	if (g_bSilent) return;

	new admin = GetNativeCell(1);
	new target = GetNativeCell(2);
	decl String:admname[MAX_NAME],String:tagname[MAX_NAME];

	GetClientName(target,tagname,sizeof(tagname));

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i) && FormatActivitySource(admin,i,admname,sizeof(admname)))
	{
		Call_StartFunction(INVALID_HANDLE,PrintToChatEx);
		Call_PushCell(admin);
		Call_PushCell(i);
		Call_PushString("%t");
		Call_PushCell(GetNativeCell(3));
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		Call_PushString(admname);
		Call_PushString(YELLOW);
		Call_PushString(TEAMCOLOR);
		Call_PushString(tagname);
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		for (new j = 4; j <= numParams; j++) Call_PushCell(GetNativeCell(j));
		Call_PushString(YELLOW);
		Call_Finish();
	}
}

public AdvNotify2(Handle:plugin,numParams)
{
	if (g_bSilent) return;

	new admin = GetNativeCell(1);
	decl String:admname[MAX_NAME],String:tagname[MAX_NAME];
	GetNativeString(2,tagname,sizeof(tagname));

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i) && FormatActivitySource(admin,i,admname,sizeof(admname)))
	{
		Call_StartFunction(INVALID_HANDLE,PrintToChatEx);
		Call_PushCell(admin);
		Call_PushCell(i);
		Call_PushString("%t");
		Call_PushCell(GetNativeCell(3));
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		Call_PushString(admname);
		Call_PushString(YELLOW);
		Call_PushString(TEAMCOLOR);
		Call_PushString(tagname);
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		for (new j = 4; j <= numParams; j++) Call_PushCell(GetNativeCell(j));
		Call_PushString(YELLOW);
		Call_Finish();
	}
}

public Action:Command_Give(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_give <target> <entity>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:ent[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[MAX_CLIENTS],bool:ml = false;
	decl String:weapon[MAX_NAME];
	GetCmdArg(2,weapon,sizeof(weapon));

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		if ((GivePlayerItem(t,weapon) == -1) && StrEqual(ent,weapon))
		{
			Format(weapon,sizeof(weapon),"weapon_%s",ent);
			i--;
			continue;
		} else
		{
			if (!ml) Notify(client,t,"Give Notify",ent);
		}
	}
	if (ml) Notify2(client,buffer,"Give Notify",ent);

	return Plugin_Handled;
}

public Action:Command_Speed(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_speed <target> <multiplier>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:mul[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,mul,sizeof(mul));
	new Float:mult = StringToFloat(mul);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		SetEntPropFloat(t, Prop_Data, "m_flLaggedMovementValue", mult);
		if (!ml) Notify(client,t,"Speed Notify",mult);
	}
	if (ml) Notify2(client,buffer,"Speed Notify",mult);


	return Plugin_Handled;
}