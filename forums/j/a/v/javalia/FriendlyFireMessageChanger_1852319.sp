#include <sourcemod>
#include <sdktools>

new const String:PluginVersion[60] = "1.0.0.0";

public Plugin:myinfo = {
	
	name = "FriendlyFireMessageChanger",
	author = "javalia",
	description = "disable or fix friendly fire message in CSS",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

new Handle:cvar_ffwarning = INVALID_HANDLE;

new Handle:msgpack = INVALID_HANDLE;

public OnPluginStart(){

	CreateConVar("FriendlyFireMessageChanger_version", PluginVersion, "plugin info cvar", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	cvar_ffwarning = CreateConVar("FriendlyFireMessageChanger_friendlyfirewarning", "1", "0 = disable msg, 1 = fix it with correct translations");
	
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsgHook, true, TextMsgPostHook);
	
}

public OnMapStart(){
	
	AutoExecConfig();

}

public Action:TextMsgHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){

	BfReadByte(bf);
	decl String:message[256];
	BfReadString(bf, message, sizeof(message));
	
	if(StrEqual(message, "#Game_teammate_attack", false)){
		
		if(GetConVarBool(cvar_ffwarning)){
		
			msgpack = CreateDataPack();
			BfReadString(bf, message, sizeof(message));
			WritePackString(msgpack,message);
			WritePackCell(msgpack, players[0]);
			ResetPack(msgpack);
			
		}
		
		return Plugin_Handled;
	
	}
	
	return Plugin_Continue;

}

public TextMsgPostHook(UserMsg:msg_id, bool:sent){

	if(msgpack != INVALID_HANDLE){
		
		new String:name[255];
		ReadPackString(msgpack, name, 255);
		new target = ReadPackCell(msgpack);
		CloseHandle(msgpack);
		msgpack = INVALID_HANDLE;
		
		new Handle:bf = StartMessageOne("SayText2", target);
		BfWriteByte(bf, target);
		BfWriteByte(bf, 1);
		BfWriteString(bf, "Cstrike_TitlesTXT_Game_teammate_attack");
		BfWriteString(bf, name);
		EndMessage();
	
	}

}