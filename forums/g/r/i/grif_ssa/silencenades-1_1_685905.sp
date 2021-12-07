/*
silencenades.sp

Description:
                The silence nades plugin removes "Fire in the hole" text and sound

Versions:
                1.0
                                * Initial Release
                1.1
                                * Fix radio w/o location
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION  "1.1"
#define STRLEN                  256

// Plugin definitions
public Plugin:myinfo = {
        name = "silencenades",
        author = "grif_ssa",
        description = "The silence nades plugin removes 'Fire in the hole' text and sound",
        version = PLUGIN_VERSION,
        url = "http://forums.alliedmods.net"
};

new UserMsg:umRadioText;
new UserMsg:umSendAudio;

public OnPluginStart(){
        CreateConVar("sm_silence_nades_version", PLUGIN_VERSION, "silence nades version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        //um: RadioText
        if((umRadioText=GetUserMessageId("RadioText")) != INVALID_MESSAGE_ID)
                HookUserMessage(umRadioText, UserMsgRadioText, true);
        else
                SetFailState("GetUserMessageId of RadioText");

        //um: RadioText
        if((umSendAudio=GetUserMessageId("SendAudio")) != INVALID_MESSAGE_ID)
                HookUserMessage(umSendAudio, UserMsgSendAudio, true);
        else
                SetFailState("GetUserMessageId of SendAudio");
}

public Action:UserMsgSendAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){
        decl String:msg_str[STRLEN];

        BfReadString(bf, msg_str, sizeof(msg_str));

        if(!strcmp(msg_str, "Radio.FireInTheHole", false))
                return Plugin_Handled;

        return Plugin_Continue;
}

public Action:UserMsgRadioText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){
        decl String:radio_text[STRLEN];

        BfReadWord(bf);
        BfReadString(bf, radio_text, sizeof(radio_text));
        if(!strcmp(radio_text, "#Game_radio_location", false))
                BfReadString(bf, radio_text, sizeof(radio_text));
        BfReadString(bf, radio_text, sizeof(radio_text));
        BfReadString(bf, radio_text, sizeof(radio_text));

        if(!strcmp(radio_text, "#Cstrike_TitlesTXT_Fire_in_the_hole", false))
                return Plugin_Handled;

        return Plugin_Continue;
}
