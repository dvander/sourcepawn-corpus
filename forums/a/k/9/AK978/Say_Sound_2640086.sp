#pragma semicolon 1
//#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define DD	"buttons/blip1.wav"

int blocktext;
new Handle:g_isEnabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[any]chat trigger sound",
	author = "AK978",
	version = "1.1"
}

public void OnPluginStart()
{
	g_isEnabled = CreateConVar("sm_saysound_enable", "1", "(1 = ON ; 0 = OFF)", 0);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
    
	blocktext = false;
}

public OnMapStart()
{
	PrecacheSound(DD, true);
	
	blocktext = false;
}

public RemoveSymbol(char[] buffer)
{   
	char str[3];
	char new_str[3];
	int new_str_count = 0;  
	
	strcopy(str, 3, buffer);   
   
	for (int i = 0, len = 2; i <len; i++)
	{
		if (('!' == str[i]) || ('/' == str[i]))
		{
			new_str[new_str_count] = str[i];
			new_str_count++;
		}	
	}
	strcopy(buffer, 3, new_str); 	
}

public Action Command_Say(client, const String:command[], args)
{
    if(!g_isEnabled) return Plugin_Stop;

    if (!blocktext)
    {
		blocktext = true;
		
		char isay[3];
		if (GetCmdArgString(isay, sizeof(isay)) >= 1)
		{
			RemoveSymbol(isay);
			//PrintToChatAll("%s", isay);
			if ((isay[0] == '!')
			|| (isay[0] == '/'))			
			{
				blocktext = false;
				return Plugin_Stop;
			}
			EmitSoundToAll(DD);
		}
		CreateTimer(0.0, UnblockText);
    }
    return Plugin_Continue;
}

public Action UnblockText(Handle timer)
{
    blocktext = false;
}