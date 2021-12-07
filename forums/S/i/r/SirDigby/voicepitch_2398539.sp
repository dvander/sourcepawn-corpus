#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.1"
#define VOICE_PITCH_HARDMAX 255 //Cannot exceed these limits.
#define VOICE_PITCH_HARDMIN 1
#define VOICE_PITCH_DEFAULT 100

new Handle:h_cvarEnabled = null;
new Handle:h_iPubMin = null;
new Handle:h_iPubMax = null;

bool g_VoicePitchActive[MAXPLAYERS+1] = {false, ...};
int	g_VoicePitchValue[MAXPLAYERS+1];


//Commands, Overrides and CVars
/*****************
sm_voice
sm_voicepitch_access

voicepitch_dig_version
sm_voicepitch_enabled
sm_voicepitch_max
sm_voicepitch_min
*****************/

public Plugin:myinfo =
{
	name = "[TF2] Voice Commands Pitch",
	author = "SirDigby",
	description = "Set the Pitch for Voice Commands",
	version = PLUGIN_VERSION,
	url = "",
};


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases.txt");

	CreateConVar("voicepitch_dig_version", PLUGIN_VERSION, "Voice Pitch version. Do Not Touch!", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_cvarEnabled = CreateConVar("sm_voicepitch_enabled", "1", "Enable Voice Pitch Control. \n0 - Disabled\n1 - Enabled\n2 - Admin Only", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	h_iPubMin = CreateConVar("sm_voicepitch_min", "50", "Voice Pitch Public Minimum", FCVAR_PLUGIN, true, 1.0, true, 255.0);
	h_iPubMax = CreateConVar("sm_voicepitch_max", "200", "Voice Pitch Public Maximum", FCVAR_PLUGIN, true, 1.0, true, 255.0);
	
	RegAdminCmd("sm_voice", Command_Pitch, ADMFLAG_GENERIC, "sm_voice <pitch>");
	AddNormalSoundHook(NormalSoundHook);
}


public OnClientDisconnect_Post(client)
{
	g_VoicePitchActive[client] = false;
	g_VoicePitchValue[client] = VOICE_PITCH_DEFAULT;
}


public Action:Command_Pitch(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	int isEnabled = GetConVarInt(h_cvarEnabled);
	bool isAdminOrHigher = CheckCommandAccess(client, "sm_voicepitch_access", ADMFLAG_BAN, false);
	if(isEnabled == 0)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Voice Pitch is Disabled.");
		return Plugin_Handled;
	}
	else if(isEnabled == 2 && !isAdminOrHigher)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Voice Pitch is Disabled for \x05Non-Admins\x01.");
		return Plugin_Handled;
	}
	
	int voiceMin, voiceMax; //Here for scope
	if(isAdminOrHigher)
	{
		voiceMin = VOICE_PITCH_HARDMIN;
		voiceMax = VOICE_PITCH_HARDMAX;
	}
	else
	{
		voiceMin = GetConVarInt(h_iPubMin);
		voiceMax = GetConVarInt(h_iPubMax);
	}
	
	char arg1[MAX_NAME_LENGTH], arg2[4];
	
	if(args > 2)
	{
		ReplyToCommand(client, "\x04[SM]\x05 Syntax\x01: sm_voice <\x05%i\x01-\x05%i\x01>", voiceMin, voiceMax);
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		int voiceValue = StringToInt(arg1);
		
		if(voiceValue >= voiceMin && voiceValue <= voiceMax)
		{
			g_VoicePitchValue[client] = voiceValue;
			g_VoicePitchActive[client] = true;
			ReplyToCommand(client, "\x04[SM]\x01 Voice Pitch Set to \x05%i%%\x01.", voiceValue);
		}
		else
			ReplyToCommand(client, "\x04[SM]\x01 Invalid Pitch. Use a value between \x05%i \x01and \x05%i\x01.", voiceMin, voiceMax);
	}
	else if(args == 0)
	{
		if(g_VoicePitchActive[client])
		{
			g_VoicePitchActive[client] = false;
			g_VoicePitchValue[client] = VOICE_PITCH_DEFAULT;
			ReplyToCommand(client, "\x04[SM]\x01 Voice Pitch \x05Reset\x01.");
		}
		else
			ReplyToCommand(client, "\x04[SM]\x05 Syntax\x01: sm_voice <\x05%i\x01-\x05%i\x01>", voiceMin, voiceMax);
		return Plugin_Handled;
	}
	else if(args == 2)
	{
		if(!isAdminOrHigher)
		{
			ReplyToCommand(client, "\x04[SM]\x01 You do not have access to this command.");
			return Plugin_Handled;
		}
		//Order is because targeting is least frequent.
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		int voiceValue = StringToInt(arg2);
		
		if(voiceValue < voiceMin || voiceValue > voiceMax)
		{
			ReplyToCommand(client, "\x04[SM]\x01 Invalid Pitch. Use a value between \x05%i \x01and \x05%i\x01.", voiceMin, voiceMax);
			return Plugin_Handled;
		}
		
		int target_count, target_list[MAXPLAYERS];
		bool tn_is_ml;
		char target_name[MAX_TARGET_LENGTH];
		if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(int i = 0; i <= target_count; i++)
		{
			if(IsValidClient(target_list[i]))
			{
				g_VoicePitchActive[target_list[i]] = true;
				g_VoicePitchValue[target_list[i]] = voiceValue;
			}
		}
		ShowActivity2(client, "\x04[SM]\x01 ", "\x05%s\x01's Voice Pitch Set to \x05%i%%\x01.", target_name, voiceValue);
	}
	return Plugin_Handled;
}

public Action:NormalSoundHook(clients[64], &numClients, String:sSample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	//entity = client
	if(channel == SNDCHAN_VOICE && entity >= 1 && entity <= MaxClients)
	{
		if(g_VoicePitchActive[entity])
		{
			pitch = g_VoicePitchValue[entity];
			flags |= SND_CHANGEPITCH;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

bool IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}