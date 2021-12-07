/**
 * Cyt0's TF2 Achievement Plugin (Bots + no sv_cheats notify)
 */


#include <sourcemod>

public Plugin:myinfo = 
{
	name = "TF2 Achievement Cheats",
	author = "Carlos Averett",
	description = "Enable bots and cheat commands",
	version = "1.0",
	url = "http://www.corecodec.com/"
};


public OnPluginStart()
{
// Find sv_cheats and remove notify
new Handle:sv_cheats;
new Handle:bot_saveme;
new sv_cheats_flags;
new bot_saveme_flags;

sv_cheats = FindConVar ("sv_cheats");
sv_cheats_flags = GetConVarFlags (sv_cheats);
sv_cheats_flags &= ~FCVAR_CHEAT;
SetConVarFlags (sv_cheats, sv_cheats_flags);

bot_saveme = FindConVar ("bot_saveme");
bot_saveme_flags = GetConVarFlags (bot_saveme);
bot_saveme_flags &= ~FCVAR_CHEAT;
SetConVarFlags (bot_saveme, bot_saveme_flags);


// Find bot command and remove cheat flag
new flags;
flags  = GetCommandFlags("bot");
flags &= ~FCVAR_CHEAT;
flags &= ~FCVAR_SPONLY;
SetCommandFlags("bot", flags);

flags  = GetCommandFlags("bot_command");
flags &= ~FCVAR_CHEAT;
flags &= ~FCVAR_SPONLY;
SetCommandFlags("bot_command", flags); 

flags  = GetCommandFlags("bot_kill");
flags &= ~FCVAR_CHEAT;
flags &= ~FCVAR_SPONLY;
SetCommandFlags("bot_kill", flags); 
}