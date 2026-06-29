#include <sourcemod>

#define PLUGIN_VERSION	"0.5"

public Plugin:myinfo =
{
    name = "Shamusi Music Plugin",
    author = "Shamusi.com",
    description = "Listen to 1000s of radio stations while you are playing.",
    version = PLUGIN_VERSION,
    url = "http://www.shamusi.com/"
};

new String:StartMusicPage[255] = "http://shamusi.com/index.html";
new String:StopMusicPage[255] = "http://shamusi.com/index.html";

public OnPluginStart()
{
    CreateConVar("sm_radio_version", PLUGIN_VERSION, "SourceMod Radio version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
}

public OnClientPutInServer(client)
{
    if((client == 0) || !IsClientConnected(client))
        return;

    CreateTimer(30.0, WelcomeRadioTimer, client);
}

public Action:RadioOn(client)
{
    ShowMOTDPanel(client, "Shamusi.com", StartMusicPage, MOTDPANEL_TYPE_URL);
    return Plugin_Continue;
}

public Action:RadioOff(client)
{
    ShowMOTDPanel(client, "Shamusi.com", StopMusicPage, MOTDPANEL_TYPE_URL);
    return Plugin_Continue;
}

public Action:Command_Say(client,args){
	if(client != 0){
			
		decl String:szText[192];
		GetCmdArgString(szText, sizeof(szText));

		if(szText[strlen(szText)-1] == '"')
		{
			szText[strlen(szText)-1] = '\0';
			strcopy(szText, 192, szText[1]);
		}

		if((strcmp(szText,"!music",false) == 0) || (strcmp(szText,"/music",false) == 0) || (strcmp(szText,"!radio",false) == 0) || (strcmp(szText,"/radio",false) == 0) || (strcmp(szText,"!musik",false) == 0) || (strcmp(szText,"/musik",false) == 0)){
			RadioOn(client);
			return Plugin_Handled;
		}
		if((strcmp(szText,"!stopmusic",false) == 0) || (strcmp(szText,"/stopmusic",false) == 0) || (strcmp(szText,"!stopradio",false) == 0) || (strcmp(szText,"/stopradio",false) == 0) || (strcmp(szText,"!stopmusik",false) == 0) || (strcmp(szText,"/stopmusik",false) == 0) || (strcmp(szText,"!musicoff",false) == 0) || (strcmp(szText,"/musicoff",false) == 0)){
			RadioOff(client);
			return Plugin_Handled;
		}

		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

public Action:WelcomeRadioTimer(Handle:timer, any:client)
{
    decl String:szClientName[MAX_NAME_LENGTH] = "";

    if(IsClientConnected(client) && IsClientInGame(client))
    {
        GetClientName(client, szClientName, sizeof(szClientName));
        PrintToChat(client, "\x01\x04[Shamusi.com]\x01 Type '!music' in chat to listen to 1000s of radio stations. Type '!stopmusic' to turn it off.");
    }

    return Plugin_Continue;
}