#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	"0.1"
#define MAX_STR_LEN		256

public Plugin:myinfo = {
	name = "silencenades",
	author = "grif_ssa",
	description = "The silence nades plugin makes no 'Fire in the hole' sound, special for http://forums.alliedmods.net/showpost.php?p=1041674&postcount=77",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart(){
	new UserMsg:g_umSendAudio;

	CreateConVar("sm_silence_nades_version", PLUGIN_VERSION, "silence nades version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//um: SendAudio
	if((g_umSendAudio=GetUserMessageId("SendAudio")) != INVALID_MESSAGE_ID)
		HookUserMessage(g_umSendAudio, UserMsgSendAudio, true);
	else
		SetFailState("GetUserMessageId for SendAudio");
}

//no snd
public Action:UserMsgSendAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){
	decl String:msg_str[MAX_STR_LEN];

	BfReadString(bf, msg_str, sizeof(msg_str));

	if(!strcmp(msg_str, "Radio.FireInTheHole", false))
		return Plugin_Handled;

	return Plugin_Continue;
}
