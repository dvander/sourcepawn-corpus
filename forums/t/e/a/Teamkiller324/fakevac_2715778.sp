#pragma		semicolon	1
#pragma		newdecls	required

#define		PLUGIN_VERSION	"1.0"

char	arg1[MAX_TARGET_LENGTH],
		target_name[MAX_NAME_LENGTH];
int		target_list[MAXPLAYERS],
		target_count;
bool	tn_is_ml;
ConVar	Enabled;

Plugin myinfo	=	{
	name        =	"[ANY] Fake Vac-Ban",
	author      =	"Tk /id/Teamkiller324",
	description =	"Sends out a fake vac ban",
	version     =	PLUGIN_VERSION,
	url         =	"https://steamcommunity.com/id/Teamkiller324"
};


public void OnPluginStart()	{
	LoadTranslations("common.phrases");
	CreateConVar("fakevac_version",	PLUGIN_VERSION,		"The Fake Vac-Ban Version");
	Enabled		=	CreateConVar("fakevac_enabled",	"1",	"Enable or disable Fake Vac", _, true, 0.0, true, 1.0);
	RegAdminCmd("sm_fv",			Command_FakeVac,	ADMFLAG_GENERIC,	"Send out a fake vac ban via targeting user");
	RegAdminCmd("sm_fakevac",		Command_FakeVac,	ADMFLAG_GENERIC,	"Send out a fake vac ban via targeting user");
	RegAdminCmd("sm_fv2",			Command_FakeVac2,	ADMFLAG_GENERIC,	"Send out a fake csgo ban via targeting user");
	RegAdminCmd("sm_fakevac2",		Command_FakeVac2,	ADMFLAG_GENERIC,	"Send out a fake csgo ban via targeting user");
}

Action Command_FakeVac(int client, int args)	{
	if(Enabled.IntValue != 1)
		return Plugin_Handled;
	
	if (args < 1)	{
		ReplyToCommand(client, "Usage: sm_fakevac <#userid|target>");
		return Plugin_Handled;
	}
		
	GetCmdArg(1, arg1, sizeof(arg1));
	if ((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i ++)
	{
		KickClient(target_list[i], "VAC-Banned from Secure Servers.");
	}
	
	return Plugin_Handled;
}

Action Command_FakeVac2(int client, int args)	{
	if(Enabled.IntValue != 1)
		return Plugin_Handled;
		
	if (args < 1)	{
		ReplyToCommand(client, "Usage: sm_fakevac2 <#userid|target>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	if ((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i ++)
	{
		PrintToChatAll("\x07%N has been permanently banned from official CS:GO servers.", target_list[i]);
		KickClient(target_list[i], "Your account is currently untrusted.");
	}
	
	return Plugin_Handled;
}