#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
    name = "MuteOnJoin",
    author = "Pede",
    description = "Mute's clients when they join.",
    version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198004774752/"
}

public OnClientPostAdminCheck(client){
    if(IsFakeClient(client))
	{
        return;
	}
    else
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			return;
		}else{
			SetClientListeningFlags(client, VOICE_MUTED);
		}
	}
}  